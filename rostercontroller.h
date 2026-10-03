#ifndef ROSTERCONTROLLER_H
#define ROSTERCONTROLLER_H

#include <QFileSystemWatcher>
#include <QObject>
#include <QJsonArray>
#include <QTimer>
#include <QVariantList>

class RosterController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList classes READ classes NOTIFY classesChanged)
    Q_PROPERTY(QString dataFilePath READ dataFilePath CONSTANT)
    Q_PROPERTY(QString configFilePath READ configFilePath CONSTANT)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)
    Q_PROPERTY(bool darkTheme READ darkTheme NOTIFY preferencesChanged)
    Q_PROPERTY(bool avoidRepeatByDefault READ avoidRepeatByDefault NOTIFY preferencesChanged)
    Q_PROPERTY(bool privateKeyBound READ privateKeyBound NOTIFY preferencesChanged)
    Q_PROPERTY(QVariantList excelPreviewData READ excelPreviewData NOTIFY excelPreviewChanged)
    Q_PROPERTY(int excelPreviewStartRow READ excelPreviewStartRow NOTIFY excelPreviewChanged)
    Q_PROPERTY(int excelPreviewLastRow READ excelPreviewLastRow NOTIFY excelPreviewChanged)
    Q_PROPERTY(int excelPreviewFirstColumn READ excelPreviewFirstColumn NOTIFY excelPreviewChanged)
    Q_PROPERTY(int excelPreviewColumnCount READ excelPreviewColumnCount NOTIFY excelPreviewChanged)
    Q_PROPERTY(int excelPreviewNameColumn READ excelPreviewNameColumn NOTIFY excelPreviewChanged)

public:
    explicit RosterController(QObject *parent = nullptr);

    // 提供给 QML 的名单快照；增删改写入成功后通过 classesChanged 通知界面刷新。
    QVariantList classes() const;
    QString dataFilePath() const;
    QString configFilePath() const;
    QString lastError() const;
    bool darkTheme() const;
    bool avoidRepeatByDefault() const;
    bool privateKeyBound() const;
    QVariantList excelPreviewData() const;
    int excelPreviewStartRow() const;
    int excelPreviewLastRow() const;
    int excelPreviewFirstColumn() const;
    int excelPreviewColumnCount() const;
    int excelPreviewNameColumn() const;

    Q_INVOKABLE bool addClass(const QString &name);
    Q_INVOKABLE bool renameClass(const QString &oldName, const QString &newName);
    Q_INVOKABLE bool removeClass(const QString &name);
    Q_INVOKABLE bool addStudent(const QString &className, const QString &studentName);
    Q_INVOKABLE bool setStudentName(const QString &className, int index, const QString &studentName);
    Q_INVOKABLE bool removeStudent(const QString &className, int index);
    Q_INVOKABLE bool importExcel(const QString &className, const QString &filePath);
    Q_INVOKABLE bool loadExcelPreview(const QString &filePath);
    Q_INVOKABLE bool updateExcelPreviewRange(int firstRow, int lastRow);
    Q_INVOKABLE bool confirmExcelImport(const QString &className, int nameColumn,
                                        int firstRow, int lastRow, bool firstRowIsHeader);
    Q_INVOKABLE bool generateTeacherKey(const QString &filePath);
    Q_INVOKABLE bool authorizeTeacherKey(const QString &filePath);
    Q_INVOKABLE bool setDarkTheme(bool enabled);
    Q_INVOKABLE bool setAvoidRepeatByDefault(bool enabled);
    Q_INVOKABLE void requestLessonStart();
    Q_INVOKABLE void clearError();

signals:
    // 文件重载或名单成功修改后发出，供页面更新班级与学生模型。
    void classesChanged();
    void lastErrorChanged();
    void preferencesChanged();
    void excelPreviewChanged();
    // 主页按钮只发起请求，实际窗口切换由 QML 槽统一处理。
    void lessonRequested();

private slots:
    void scheduleReload();
    void reloadFromDisk();

private:
    void initializeFile();
    void loadConfiguration();
    bool saveConfiguration();
    // 通过 QSaveFile 写入临时文件并原子替换，避免中断写入破坏原名单。
    bool saveClasses();
    bool persistChanges(const QJsonArray &previousClasses);
    int classIndex(const QString &name) const;
    void setError(const QString &message);
    void updateFileWatch();

    QString m_dataFilePath;
    QString m_configFilePath;
    QString m_lastError;
    QString m_privateKeyFingerprint;
    QString m_excelPreviewFilePath;
    bool m_darkTheme = false;
    bool m_avoidRepeatByDefault = false;
    int m_excelPreviewStartRow = 1;
    int m_excelPreviewLastRow = 0;
    int m_excelPreviewFirstColumn = 1;
    int m_excelPreviewColumnCount = 0;
    int m_excelPreviewNameColumn = 0;
    QVariantList m_excelPreviewData;
    // 内存中始终保留已校验的 JSON 班级数组。
    QJsonArray m_classes;
    // 同时监听文件与目录：QSaveFile 原子替换后文件监视句柄可能失效。
    QFileSystemWatcher m_fileWatcher;
    QTimer m_reloadTimer;
};

#endif // ROSTERCONTROLLER_H