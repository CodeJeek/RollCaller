import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Dialogs 1.3

Window {
    id: mainWindow
    width: 1280
    height: 820
    minimumWidth: 1000
    minimumHeight: 680
    visible: true
    title: "Roll Caller"
    color: themePalette.background

    property int selectedPage: 0
    property int displayPage: 0
    property int transitionDirection: -1
    property bool lessonMode: false
    property string currentStudent: ""
    // 仅在浮窗开启“避免重复”时记录本堂课已经抽中的姓名。
    property var drawnStudents: []

    ThemePalette { id: themePalette }

    FontLoader {
        id: iconFont
        source: "qrc:/fonts/resources/fonts/SegoeFluentIcons.ttf"
    }

    Component.onCompleted: {
        // 初始值直接落位，避免启动时从浅色再播放一段不必要的主题动画。
        themePalette.setInitialTheme(rosterController.darkTheme)
        floatWindow.avoidRepeat = rosterController.avoidRepeatByDefault
    }

    function startLessonMode() {
        lessonMode = true
        // 让演示画面恢复前台，点名浮窗保持置顶且独立显示。
        mainWindow.showMinimized()
        floatWindow.show()
        floatWindow.raise()
    }

    function closeLessonMode() {
        lessonMode = false
        floatWindow.hide()
        drawWindow.hide()
        mainWindow.showNormal()
        mainWindow.raise()
        mainWindow.requestActivate()
    }

    function beginDraw() {
        var sourceStudents = rosterPage.classStudents()
        if (sourceStudents.length === 0) {
            drawWindow.startDraw([], "名单为空")
            return
        }

        // 先按防重复设置筛选候选，再从剩余姓名中等概率抽取。
        var candidates = sourceStudents
        if (floatWindow.avoidRepeat) {
            candidates = sourceStudents.filter(function(name) {
                return mainWindow.drawnStudents.indexOf(name) < 0
            })
            if (candidates.length === 0) {
                drawnStudents = []
                candidates = sourceStudents
            }
        }
        var winner = candidates[Math.floor(Math.random() * candidates.length)]
        drawWindow.startDraw(sourceStudents, winner)
    }

    function recordDraw(name) {
        if (name === "名单为空")
            return
        currentStudent = name
        // 只在动画完成信号到达后登记中奖者，不把滚动过程中的临时姓名记入历史。
        if (floatWindow.avoidRepeat && drawnStudents.indexOf(name) < 0)
            drawnStudents = drawnStudents.concat([name])
    }

    function navigateTo(index) {
        if (selectedPage === index && !navigationAnimation.running)
            return
        if (navigationAnimation.running) {
            // 连续切页时先收敛当前动画，避免旧动画覆盖新的目标页面。
            navigationAnimation.stop()
            displayPage = selectedPage
            pageContent.opacity = 1
            pageContent.x = 0
        }
        transitionDirection = index > displayPage ? -1 : 1
        if (index !== 1) {
            rosterPage.editorOpen = false
            rosterPage.editorClassMenuOpen = false
        }
        selectedPage = index
        navigationAnimation.start()
    }

    Connections {
        target: rosterController
        onLessonRequested: mainWindow.startLessonMode()
    }

    Sidebar {
        id: sidebar
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        palette: themePalette
        selectedPage: mainWindow.selectedPage
        onNavigate: mainWindow.navigateTo(page)
    }

    Item {
        id: workspace
        anchors.left: sidebar.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        Rectangle {
            id: topBar
            height: 68
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            color: themePalette.background
            Text {
                x: 32
                anchors.verticalCenter: parent.verticalCenter
                text: mainWindow.selectedPage === 1 && rosterPage.editorOpen ? "名单设置" : ["主页", "班级名单", "设置"][mainWindow.selectedPage]
                color: themePalette.text
                font.family: "Segoe UI"
                font.pixelSize: 20
                font.weight: Font.DemiBold
            }
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 32
                anchors.verticalCenter: parent.verticalCenter
                text: "\uE8D7"
                color: themePalette.secondaryText
                font.family: "Segoe Fluent Icons"
                font.pixelSize: 18
            }
        }

        Item {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: topBar.bottom
            anchors.bottom: parent.bottom
            clip: true
            Item {
                id: pageContent
                width: parent.width
                height: parent.height

                SequentialAnimation {
                    id: navigationAnimation
                    ParallelAnimation {
                        NumberAnimation { target: pageContent; property: "x"; to: mainWindow.transitionDirection * 34; duration: 140; easing.type: Easing.Linear }
                        NumberAnimation { target: pageContent; property: "opacity"; to: 0; duration: 140; easing.type: Easing.Linear }
                    }
                    ScriptAction {
                        script: {
                            mainWindow.displayPage = mainWindow.selectedPage
                            pageContent.x = -mainWindow.transitionDirection * 34
                        }
                    }
                    ParallelAnimation {
                        NumberAnimation { target: pageContent; property: "x"; to: 0; duration: 240; easing.type: Easing.OutCubic }
                        NumberAnimation { target: pageContent; property: "opacity"; to: 1; duration: 240; easing.type: Easing.Linear }
                    }
                }

                HomePage {
                    anchors.fill: parent
                    anchors.leftMargin: 36
                    anchors.rightMargin: 36
                    anchors.topMargin: 26
                    anchors.bottomMargin: 28
                    palette: themePalette
                    className: rosterPage.selectedClass
                    studentCount: rosterPage.classStudents().length
                    lessonActive: mainWindow.lessonMode
                    visible: mainWindow.displayPage === 0
                    onStartLesson: rosterController.requestLessonStart()
                    onStopLesson: mainWindow.closeLessonMode()
                }

                RosterPage {
                    id: rosterPage
                    anchors.fill: parent
                    anchors.leftMargin: 32
                    anchors.rightMargin: 32
                    anchors.topMargin: 22
                    anchors.bottomMargin: 24
                    palette: themePalette
                    controller: rosterController
                    visible: mainWindow.displayPage === 1
                    onSelectedClassChangedByUser: mainWindow.drawnStudents = []
                    onSettingsRequested: mainWindow.navigateTo(2)
                }

                SettingsPage {
                    anchors.fill: parent
                    anchors.leftMargin: 36
                    anchors.rightMargin: 36
                    anchors.topMargin: 24
                    palette: themePalette
                    dataFilePath: rosterController.dataFilePath
                    configFilePath: rosterController.configFilePath
                    avoidRepeatByDefault: rosterController.avoidRepeatByDefault
                    privateKeyBound: rosterController.privateKeyBound
                    visible: mainWindow.displayPage === 2
                    onToggleTheme: {
                        themePalette.toggle()
                        if (!rosterController.setDarkTheme(themePalette.dark))
                            themePalette.toggle()
                    }
                    onChangeAvoidRepeatDefault: {
                        if (rosterController.setAvoidRepeatByDefault(enabled)) {
                            floatWindow.avoidRepeat = enabled
                            drawnStudents = []
                        }
                    }
                    onGenerateTeacherKey: keySaveDialog.open()
                }
            }
        }
    }

    FloatingRollWindow {
        id: floatWindow
        palette: themePalette
        onDrawRequested: mainWindow.beginDraw()
        onReturnRequested: mainWindow.closeLessonMode()
    }

    Connections {
        target: floatWindow
        onAvoidRepeatChanged: rosterController.setAvoidRepeatByDefault(floatWindow.avoidRepeat)
    }

    FileDialog {
        id: keySaveDialog
        title: "生成并保存教师私钥"
        selectExisting: false
        nameFilters: ["RollCaller 私钥 (*.pem)", "所有文件 (*)"]
        onAccepted: rosterController.generateTeacherKey(fileUrl.toLocalFile())
    }

    DrawWindow {
        id: drawWindow
        palette: themePalette
        onSelected: mainWindow.recordDraw(studentName)
        onReplayRequested: mainWindow.beginDraw()
    }

    Rectangle {
        width: 380
        height: 44
        z: 30
        anchors.right: workspace.right
        anchors.rightMargin: 24
        anchors.bottom: workspace.bottom
        anchors.bottomMargin: 20
        radius: 6
        color: themePalette.surfaceAlt
        border.width: 1
        border.color: themePalette.border
        visible: rosterController.lastError.length > 0
        Text {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            verticalAlignment: Text.AlignVCenter
            text: rosterController.lastError
            color: themePalette.text
            font.family: "Segoe UI"
            font.pixelSize: 11
            elide: Text.ElideRight
        }
    }

    Timer {
        id: toastTimer
        interval: 4000
        onTriggered: rosterController.clearError()
    }
    Connections {
        target: rosterController
        onLastErrorChanged: {
            if (rosterController.lastError.length > 0)
                toastTimer.restart()
        }
    }
}