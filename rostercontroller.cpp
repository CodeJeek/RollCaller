#include "rostercontroller.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QCryptographicHash>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonParseError>
#include <QSaveFile>
#include <QSettings>
#include <QRandomGenerator>
#include <QSet>
#include <QStandardPaths>

#include "xlsxdocument.h"
#include "xlsxworksheet.h"

RosterController::RosterController(QObject *parent)
    : QObject(parent)
{
    // AppDataLocation 在 Windows 对应当前用户的 Roaming 应用数据目录。
    const QString appDataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(appDataPath);
    m_dataFilePath = appDataPath + QStringLiteral("/classes.json");
    m_configFilePath = appDataPath + QStringLiteral("/config.ini");
    loadConfiguration();
    if (!QFile::exists(m_configFilePath))
        saveConfiguration();

    m_reloadTimer.setSingleShot(true);
    m_reloadTimer.setInterval(150);
    connect(&m_reloadTimer, &QTimer::timeout, this, &RosterController::reloadFromDisk);
    connect(&m_fileWatcher, &QFileSystemWatcher::fileChanged, this, &RosterController::scheduleReload);
    connect(&m_fileWatcher, &QFileSystemWatcher::directoryChanged, this, &RosterController::scheduleReload);

    if (QFile::exists(m_dataFilePath))
        reloadFromDisk();
    else
        initializeFile();
    updateFileWatch();
}

QVariantList RosterController::classes() const
{
    QVariantList result;
    for (const QJsonValue &value : m_classes) {
        const QJsonObject object = value.toObject();
        QVariantMap item;
        item.insert(QStringLiteral("name"), object.value(QStringLiteral("name")).toString());
        item.insert(QStringLiteral("students"), object.value(QStringLiteral("students")).toArray().toVariantList());
        result.append(item);
    }
    return result;
}

QString RosterController::dataFilePath() const
{
    return m_dataFilePath;
}

QString RosterController::configFilePath() const
{
    return m_configFilePath;
}

QString RosterController::lastError() const
{
    return m_lastError;
}

bool RosterController::darkTheme() const
{
    return m_darkTheme;
}

bool RosterController::avoidRepeatByDefault() const
{
    return m_avoidRepeatByDefault;
}

bool RosterController::privateKeyBound() const
{
    return !m_privateKeyFingerprint.isEmpty();
}

QVariantList RosterController::excelPreviewData() const
{
    return m_excelPreviewData;
}

int RosterController::excelPreviewStartRow() const
{
    return m_excelPreviewStartRow;
}

int RosterController::excelPreviewLastRow() const
{
    return m_excelPreviewLastRow;
}

int RosterController::excelPreviewFirstColumn() const
{
    return m_excelPreviewFirstColumn;
}

int RosterController::excelPreviewColumnCount() const
{
    return m_excelPreviewColumnCount;
}

int RosterController::excelPreviewNameColumn() const
{
    return m_excelPreviewNameColumn;
}

void RosterController::loadConfiguration()
{
    QSettings settings(m_configFilePath, QSettings::IniFormat);
    m_darkTheme = settings.value(QStringLiteral("appearance/darkTheme"), false).toBool();
    m_avoidRepeatByDefault = settings.value(QStringLiteral("rollCall/avoidRepeatByDefault"), false).toBool();
    m_privateKeyFingerprint = settings.value(QStringLiteral("security/privateKeySha256")).toString();
}

bool RosterController::saveConfiguration()
{
    QSettings settings(m_configFilePath, QSettings::IniFormat);
    settings.setValue(QStringLiteral("appearance/darkTheme"), m_darkTheme);
    settings.setValue(QStringLiteral("rollCall/avoidRepeatByDefault"), m_avoidRepeatByDefault);
    settings.setValue(QStringLiteral("security/privateKeySha256"), m_privateKeyFingerprint);
    settings.sync();
    if (settings.status() != QSettings::NoError) {
        setError(QStringLiteral("无法保存应用设置。"));
        return false;
    }
    return true;
}

bool RosterController::setDarkTheme(bool enabled)
{
    if (m_darkTheme == enabled)
        return true;
    const bool previousValue = m_darkTheme;
    m_darkTheme = enabled;
    if (!saveConfiguration()) {
        m_darkTheme = previousValue;
        return false;
    }
    emit preferencesChanged();
    return true;
}

bool RosterController::setAvoidRepeatByDefault(bool enabled)
{
    if (m_avoidRepeatByDefault == enabled)
        return true;
    const bool previousValue = m_avoidRepeatByDefault;
    m_avoidRepeatByDefault = enabled;
    if (!saveConfiguration()) {
        m_avoidRepeatByDefault = previousValue;
        return false;
    }
    emit preferencesChanged();
    return true;
}

bool RosterController::authorizeTeacherKey(const QString &filePath)
{
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly)) {
        setError(QStringLiteral("无法读取教师私钥文件：%1").arg(file.errorString()));
        return false;
    }
    if (file.size() <= 0 || file.size() > 4 * 1024 * 1024) {
        setError(QStringLiteral("私钥文件为空或超过 4 MiB。"));
        return false;
    }

    const QByteArray privateKeyData = file.readAll();
    const bool isPemPrivateKey = privateKeyData.contains("PRIVATE KEY");
    const bool isPuttyPrivateKey = privateKeyData.startsWith("PuTTY-User-Key-File-");
    if (!isPemPrivateKey && !isPuttyPrivateKey) {
        setError(QStringLiteral("所选文件不是可识别的 PEM、OpenSSH 或 PuTTY 私钥。"));
        return false;
    }
    const QByteArray fingerprint = QCryptographicHash::hash(privateKeyData, QCryptographicHash::Sha256).toHex();

    if (m_privateKeyFingerprint.isEmpty()) {
        m_privateKeyFingerprint = QString::fromLatin1(fingerprint);
        if (!saveConfiguration()) {
            m_privateKeyFingerprint.clear();
            return false;
        }
        emit preferencesChanged();
    } else if (m_privateKeyFingerprint.toLatin1() != fingerprint) {
        setError(QStringLiteral("私钥校验失败，未进入名单编辑。"));
        return false;
    }

    setError(QString());
    return true;
}

bool RosterController::generateTeacherKey(const QString &filePath)
{
    if (!m_privateKeyFingerprint.isEmpty()) {
        setError(QStringLiteral("教师私钥已经绑定，不能直接覆盖。"));
        return false;
    }
    if (filePath.trimmed().isEmpty()) {
        setError(QStringLiteral("请先选择密钥文件保存位置。"));
        return false;
    }

    // QRandomGenerator::system 使用系统随机源，生成 256-bit 不可预测的授权秘密。
    QByteArray secret;
    secret.reserve(32);
    QRandomGenerator *random = QRandomGenerator::system();
    for (int i = 0; i < 8; ++i) {
        const quint32 word = random->generate();
        secret.append(static_cast<char>((word >> 24) & 0xff));
        secret.append(static_cast<char>((word >> 16) & 0xff));
        secret.append(static_cast<char>((word >> 8) & 0xff));
        secret.append(static_cast<char>(word & 0xff));
    }

    const QByteArray encoded = secret.toBase64();
    QByteArray keyFileData("-----BEGIN ROLLCALLER PRIVATE KEY-----\n");
    for (int offset = 0; offset < encoded.size(); offset += 64)
        keyFileData.append(encoded.mid(offset, 64) + '\n');
    keyFileData.append("-----END ROLLCALLER PRIVATE KEY-----\n");

    QSaveFile file(filePath);
    if (!file.open(QIODevice::WriteOnly) || file.write(keyFileData) != keyFileData.size() || !file.commit()) {
        setError(QStringLiteral("无法写入教师密钥文件：%1").arg(file.errorString()));
        file.cancelWriting();
        return false;
    }

    m_privateKeyFingerprint = QString::fromLatin1(
                QCryptographicHash::hash(keyFileData, QCryptographicHash::Sha256).toHex());
    if (!saveConfiguration()) {
        m_privateKeyFingerprint.clear();
        return false;
    }
    emit preferencesChanged();
    setError(QStringLiteral("教师密钥已生成并绑定，请妥善保管该文件。"));
    return true;
}

bool RosterController::addClass(const QString &name)
{
    const QString cleanName = name.trimmed();
    if (cleanName.isEmpty()) {
        setError(QStringLiteral("班级名称不能为空。"));
        return false;
    }
    if (classIndex(cleanName) >= 0) {
        setError(QStringLiteral("该班级已存在。"));
        return false;
    }

    const QJsonArray previous = m_classes;
    QJsonObject object;
    object.insert(QStringLiteral("name"), cleanName);
    object.insert(QStringLiteral("students"), QJsonArray());
    m_classes.append(object);
    return persistChanges(previous);
}

bool RosterController::renameClass(const QString &oldName, const QString &newName)
{
    const QString cleanName = newName.trimmed();
    const int index = classIndex(oldName);
    if (index < 0 || cleanName.isEmpty()) {
        setError(QStringLiteral("班级名称不能为空。"));
        return false;
    }
    const int existingIndex = classIndex(cleanName);
    if (existingIndex >= 0 && existingIndex != index) {
        setError(QStringLiteral("该班级名称已被使用。"));
        return false;
    }

    const QJsonArray previous = m_classes;
    QJsonObject object = m_classes.at(index).toObject();
    object.insert(QStringLiteral("name"), cleanName);
    m_classes.replace(index, object);
    return persistChanges(previous);
}

bool RosterController::removeClass(const QString &name)
{
    const int index = classIndex(name);
    if (index < 0 || m_classes.size() <= 1) {
        setError(QStringLiteral("至少需要保留一个班级。"));
        return false;
    }

    const QJsonArray previous = m_classes;
    m_classes.removeAt(index);
    return persistChanges(previous);
}

bool RosterController::addStudent(const QString &className, const QString &studentName)
{
    const QString cleanName = studentName.trimmed();
    const int index = classIndex(className);
    if (index < 0 || cleanName.isEmpty()) {
        setError(QStringLiteral("学生姓名不能为空。"));
        return false;
    }

    QJsonObject object = m_classes.at(index).toObject();
    QJsonArray students = object.value(QStringLiteral("students")).toArray();
    for (const QJsonValue &value : students) {
        if (value.toString().compare(cleanName, Qt::CaseInsensitive) == 0) {
            setError(QStringLiteral("该学生已在名单中。"));
            return false;
        }
    }

    const QJsonArray previous = m_classes;
    students.append(cleanName);
    object.insert(QStringLiteral("students"), students);
    m_classes.replace(index, object);
    return persistChanges(previous);
}

bool RosterController::setStudentName(const QString &className, int studentIndex, const QString &studentName)
{
    const QString cleanName = studentName.trimmed();
    const int index = classIndex(className);
    if (index < 0 || cleanName.isEmpty()) {
        setError(QStringLiteral("学生姓名不能为空。"));
        return false;
    }

    QJsonObject object = m_classes.at(index).toObject();
    QJsonArray students = object.value(QStringLiteral("students")).toArray();
    if (studentIndex < 0 || studentIndex >= students.size())
        return false;
    for (int i = 0; i < students.size(); ++i) {
        if (i != studentIndex && students.at(i).toString().compare(cleanName, Qt::CaseInsensitive) == 0) {
            setError(QStringLiteral("该学生已在名单中。"));
            return false;
        }
    }

    const QJsonArray previous = m_classes;
    students.replace(studentIndex, cleanName);
    object.insert(QStringLiteral("students"), students);
    m_classes.replace(index, object);
    return persistChanges(previous);
}

bool RosterController::removeStudent(const QString &className, int studentIndex)
{
    const int index = classIndex(className);
    if (index < 0)
        return false;
    QJsonObject object = m_classes.at(index).toObject();
    QJsonArray students = object.value(QStringLiteral("students")).toArray();
    if (studentIndex < 0 || studentIndex >= students.size())
        return false;

    const QJsonArray previous = m_classes;
    students.removeAt(studentIndex);
    object.insert(QStringLiteral("students"), students);
    m_classes.replace(index, object);
    return persistChanges(previous);
}

bool RosterController::importExcel(const QString &className, const QString &filePath)
{
    if (!loadExcelPreview(filePath))
        return false;
    return confirmExcelImport(className, m_excelPreviewNameColumn,
                              m_excelPreviewStartRow, m_excelPreviewLastRow, true);
}

bool RosterController::loadExcelPreview(const QString &filePath)
{
    QXlsx::Document workbook(filePath);
    if (!workbook.load()) {
        setError(QStringLiteral("无法读取 Excel 文件，请选择有效的 .xlsx 文件。"));
        return false;
    }

    QXlsx::Worksheet *sheet = workbook.currentWorksheet();
    if (!sheet || !sheet->dimension().isValid()) {
        setError(QStringLiteral("Excel 文件中没有可读取的单元格。"));
        return false;
    }

    const QXlsx::CellRange range = sheet->dimension();
    m_excelPreviewFilePath = filePath;
    m_excelPreviewFirstColumn = range.firstColumn();
    m_excelPreviewStartRow = range.firstRow();
    m_excelPreviewLastRow = qMin(range.lastRow(), m_excelPreviewStartRow + 4999);
    m_excelPreviewColumnCount = qMin(range.lastColumn() - range.firstColumn() + 1, 32);
    m_excelPreviewNameColumn = 0;

    const QSet<QString> headers = {
        QStringLiteral("姓名"), QStringLiteral("学生姓名"), QStringLiteral("学生"),
        QStringLiteral("name"), QStringLiteral("student")
    };
    for (int column = 0; column < m_excelPreviewColumnCount; ++column) {
        const QString header = workbook.read(m_excelPreviewStartRow, m_excelPreviewFirstColumn + column)
                                   .toString().trimmed().toCaseFolded();
        if (headers.contains(header)) {
            m_excelPreviewNameColumn = column;
            break;
        }
    }

    QVariantList previewRows;
    for (int row = m_excelPreviewStartRow; row <= m_excelPreviewLastRow; ++row) {
        QVariantList cells;
        for (int column = 0; column < m_excelPreviewColumnCount; ++column)
            cells.append(workbook.read(row, m_excelPreviewFirstColumn + column).toString());
        QVariantMap previewRow;
        previewRow.insert(QStringLiteral("row"), row);
        previewRow.insert(QStringLiteral("cells"), cells);
        previewRows.append(previewRow);
    }

    m_excelPreviewData = previewRows;
    setError(QString());
    emit excelPreviewChanged();
    return true;
}

bool RosterController::updateExcelPreviewRange(int firstRow, int lastRow)
{
    if (m_excelPreviewFilePath.isEmpty()
        || firstRow < m_excelPreviewStartRow
        || lastRow < firstRow
        || lastRow > m_excelPreviewLastRow) {
        setError(QStringLiteral("预览行范围无效。"));
        return false;
    }

    QXlsx::Document workbook(m_excelPreviewFilePath);
    if (!workbook.load()) {
        setError(QStringLiteral("无法读取预览范围，请重新载入 Excel 文件。"));
        return false;
    }

    QVariantList previewRows;
    for (int row = firstRow; row <= lastRow; ++row) {
        QVariantList cells;
        for (int column = 0; column < m_excelPreviewColumnCount; ++column)
            cells.append(workbook.read(row, m_excelPreviewFirstColumn + column).toString());
        QVariantMap previewRow;
        previewRow.insert(QStringLiteral("row"), row);
        previewRow.insert(QStringLiteral("cells"), cells);
        previewRows.append(previewRow);
    }
    m_excelPreviewData = previewRows;
    setError(QString());
    emit excelPreviewChanged();
    return true;
}

bool RosterController::confirmExcelImport(const QString &className, int nameColumn,
                                          int firstRow, int lastRow, bool firstRowIsHeader)
{
    const int index = classIndex(className);
    if (index < 0 || m_excelPreviewFilePath.isEmpty()) {
        setError(QStringLiteral("请先选择班级并载入 Excel 预览。"));
        return false;
    }
    if (nameColumn < 0 || nameColumn >= m_excelPreviewColumnCount
        || firstRow < m_excelPreviewStartRow || lastRow < firstRow
        || lastRow > m_excelPreviewLastRow) {
        setError(QStringLiteral("姓名列或导入行范围无效。"));
        return false;
    }

    QXlsx::Document workbook(m_excelPreviewFilePath);
    if (!workbook.load()) {
        setError(QStringLiteral("无法重新读取 Excel 文件，请重新载入预览。"));
        return false;
    }

    QJsonObject object = m_classes.at(index).toObject();
    QJsonArray students = object.value(QStringLiteral("students")).toArray();
    QSet<QString> existingNames;
    for (const QJsonValue &value : students)
        existingNames.insert(value.toString().toCaseFolded());

    int importedCount = 0;
    const int excelColumn = m_excelPreviewFirstColumn + nameColumn;
    for (int row = firstRow; row <= lastRow; ++row) {
        if (firstRowIsHeader && row == firstRow)
            continue;
        const QString name = workbook.read(row, excelColumn).toString().trimmed();
        const QString foldedName = name.toCaseFolded();
        if (name.isEmpty() || existingNames.contains(foldedName))
            continue;
        existingNames.insert(foldedName);
        students.append(name);
        ++importedCount;
    }

    if (importedCount == 0) {
        setError(QStringLiteral("所选区域没有新的姓名可导入，请检查预览、姓名列和行范围。"));
        return false;
    }

    const QJsonArray previous = m_classes;
    object.insert(QStringLiteral("students"), students);
    m_classes.replace(index, object);
    if (!persistChanges(previous))
        return false;

    m_excelPreviewFilePath.clear();
    m_excelPreviewData.clear();
    emit excelPreviewChanged();
    setError(QStringLiteral("已导入 %1 位学生。").arg(importedCount));
    return true;
}

void RosterController::requestLessonStart()
{
    emit lessonRequested();
}

void RosterController::clearError()
{
    setError(QString());
}

void RosterController::scheduleReload()
{
    // 编辑器保存时通常会连续触发多个文件事件，短暂合并后再读取。
    m_reloadTimer.start();
}

void RosterController::reloadFromDisk()
{
    QFile file(m_dataFilePath);
    if (!file.exists()) {
        initializeFile();
        updateFileWatch();
        return;
    }
    if (!file.open(QIODevice::ReadOnly)) {
        setError(QStringLiteral("无法读取名单文件：%1").arg(file.errorString()));
        updateFileWatch();
        return;
    }

    // 先完整解析并校验，再整体替换内存数据，避免损坏文件覆盖有效名单。
    QJsonParseError parseError;
    const QJsonDocument document = QJsonDocument::fromJson(file.readAll(), &parseError);
    if (parseError.error != QJsonParseError::NoError || !document.isObject()
        || !document.object().value(QStringLiteral("classes")).isArray()) {
        setError(QStringLiteral("名单 JSON 格式无效：%1").arg(parseError.errorString()));
        updateFileWatch();
        return;
    }

    QJsonArray loadedClasses;
    QSet<QString> classNames;
    for (const QJsonValue &value : document.object().value(QStringLiteral("classes")).toArray()) {
        QJsonObject source = value.toObject();
        const QString name = source.value(QStringLiteral("name")).toString().trimmed();
        const QString foldedName = name.toCaseFolded();
        if (name.isEmpty() || classNames.contains(foldedName))
            continue;
        classNames.insert(foldedName);

        QJsonArray loadedStudents;
        QSet<QString> studentNames;
        for (const QJsonValue &studentValue : source.value(QStringLiteral("students")).toArray()) {
            const QString studentName = studentValue.toString().trimmed();
            const QString foldedStudentName = studentName.toCaseFolded();
            if (studentName.isEmpty() || studentNames.contains(foldedStudentName))
                continue;
            studentNames.insert(foldedStudentName);
            loadedStudents.append(studentName);
        }
        source.insert(QStringLiteral("name"), name);
        source.insert(QStringLiteral("students"), loadedStudents);
        loadedClasses.append(source);
    }

    if (loadedClasses.isEmpty()) {
        QJsonObject defaultClass;
        defaultClass.insert(QStringLiteral("name"), QStringLiteral("我的班级"));
        defaultClass.insert(QStringLiteral("students"), QJsonArray());
        loadedClasses.append(defaultClass);
    }

    m_classes = loadedClasses;
    setError(QString());
    emit classesChanged();
    updateFileWatch();
}

void RosterController::initializeFile()
{
    QJsonObject defaultClass;
    defaultClass.insert(QStringLiteral("name"), QStringLiteral("我的班级"));
    defaultClass.insert(QStringLiteral("students"), QJsonArray());
    m_classes = QJsonArray{defaultClass};
    saveClasses();
    emit classesChanged();
}

bool RosterController::saveClasses()
{
    QSaveFile file(m_dataFilePath);
    if (!file.open(QIODevice::WriteOnly)) {
        setError(QStringLiteral("无法保存名单文件：%1").arg(file.errorString()));
        return false;
    }

    QJsonObject root;
    root.insert(QStringLiteral("version"), 1);
    root.insert(QStringLiteral("classes"), m_classes);
    const QByteArray jsonData = QJsonDocument(root).toJson(QJsonDocument::Indented);
    if (file.write(jsonData) != jsonData.size()) {
        setError(QStringLiteral("名单文件写入不完整。"));
        file.cancelWriting();
        return false;
    }
    if (!file.commit()) {
        setError(QStringLiteral("无法完成名单文件保存：%1").arg(file.errorString()));
        return false;
    }
    setError(QString());
    updateFileWatch();
    return true;
}

bool RosterController::persistChanges(const QJsonArray &previousClasses)
{
    if (!saveClasses()) {
        // 落盘失败时回滚内存状态，保证界面不会显示未保存成功的数据。
        m_classes = previousClasses;
        emit classesChanged();
        return false;
    }
    emit classesChanged();
    return true;
}

int RosterController::classIndex(const QString &name) const
{
    for (int i = 0; i < m_classes.size(); ++i) {
        if (m_classes.at(i).toObject().value(QStringLiteral("name")).toString() == name)
            return i;
    }
    return -1;
}

void RosterController::setError(const QString &message)
{
    if (m_lastError == message)
        return;
    m_lastError = message;
    emit lastErrorChanged();
}

void RosterController::updateFileWatch()
{
    const QString directoryPath = QFileInfo(m_dataFilePath).absolutePath();
    if (!m_fileWatcher.directories().contains(directoryPath))
        m_fileWatcher.addPath(directoryPath);
    if (QFile::exists(m_dataFilePath) && !m_fileWatcher.files().contains(m_dataFilePath))
        m_fileWatcher.addPath(m_dataFilePath);
}