import QtQuick 2.15
import QtQuick.Dialogs 1.3

Item {
    id: root
    property var palette
    property var controller
    property string selectedClass: ""
    property bool classMenuOpen: false
    property bool editorClassMenuOpen: false
    property bool editorOpen: false
    property bool authPromptOpen: false
    signal selectedClassChangedByUser(string className)
    signal settingsRequested()

    function requestEditorAccess() {
        if (controller.privateKeyBound)
            authPromptOpen = true
        else
            settingsRequested()
    }

    function verifyTeacherKey(filePath) {
        if (controller.authorizeTeacherKey(filePath)) {
            authPromptOpen = false
            editorClassMenuOpen = false
            editorOpen = true
        }
    }

    function chooseClass(name) {
        selectedClass = name
        classMenuOpen = false
        editorClassMenuOpen = false
        selectedClassChangedByUser(name)
    }

    // 班级名单只在控制器维护；页面根据当前班级即时读取，不另存一份可过期的数据。
    function classStudents() {
        var allClasses = controller.classes
        for (var i = 0; i < allClasses.length; ++i) {
            if (allClasses[i].name === selectedClass)
                return allClasses[i].students
        }
        return []
    }

    function synchronizeSelection() {
        // 外部 JSON 更新或删除当前班级后，自动回退到仍然存在的第一个班级。
        var allClasses = controller.classes
        var found = false
        for (var i = 0; i < allClasses.length; ++i) {
            if (allClasses[i].name === selectedClass)
                found = true
        }
        if (!found && allClasses.length > 0)
            chooseClass(allClasses[0].name)
    }

    Connections {
        target: root.controller
        onClassesChanged: root.synchronizeSelection()
    }

    Component.onCompleted: synchronizeSelection()

    Item {
        anchors.fill: parent
        visible: !root.editorOpen && !root.authPromptOpen

        Text {
            id: rosterTitle
            anchors.left: parent.left
            anchors.top: parent.top
            text: "班级名单"
            color: root.palette.text
            font.family: "Segoe UI"
            font.pixelSize: 23
            font.weight: Font.DemiBold
        }
        Text {
            anchors.left: parent.left
            anchors.top: rosterTitle.bottom
            anchors.topMargin: 6
            text: root.classStudents().length + " 位学生"
            color: root.palette.secondaryText
            font.family: "Segoe UI"
            font.pixelSize: 12
        }

        Rectangle {
            id: editButton
            width: 130
            height: 38
            anchors.right: parent.right
            anchors.top: parent.top
            radius: 6
            color: root.palette.accent
            scale: editButtonMouse.pressed ? 0.98 : 1
            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
            Row {
                anchors.centerIn: parent
                spacing: 6
                Text {
                    text: "\uE70F"
                    color: "#ffffff"
                    font.family: "Segoe Fluent Icons"
                    font.pixelSize: 13
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "名单设置"
                    color: "#ffffff"
                    font.family: "Segoe UI"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Behavior on color { ColorAnimation { duration: 160 } }
            MouseArea {
                id: editButtonMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.requestEditorAccess()
            }
        }

        Rectangle {
            id: classSelector
            width: 208
            height: 38
            anchors.right: editButton.left
            anchors.rightMargin: 10
            anchors.top: parent.top
            radius: 6
            color: root.palette.surface
            border.width: 1
            border.color: root.classMenuOpen ? root.palette.accent : root.palette.border
            Text {
                x: 13
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 42
                text: root.selectedClass
                color: root.palette.text
                font.family: "Segoe UI"
                font.pixelSize: 12
                elide: Text.ElideRight
            }
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: "\uE70D"
                color: root.palette.secondaryText
                font.family: "Segoe Fluent Icons"
                font.pixelSize: 12
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.classMenuOpen = !root.classMenuOpen
            }
        }

        Rectangle {
            id: classMenu
            z: 5
            width: classSelector.width
            height: Math.min(220, Math.max(1, root.controller.classes.length * 38))
            anchors.left: classSelector.left
            anchors.top: classSelector.bottom
            anchors.topMargin: 4
            radius: 6
            color: root.palette.surface
            border.width: 1
            border.color: root.palette.border
            visible: root.classMenuOpen && root.controller.classes.length > 0
            clip: true
            Column {
                anchors.fill: parent
                Repeater {
                    model: root.controller.classes
                    delegate: Rectangle {
                        required property var modelData
                        width: classMenu.width
                        height: 38
                        color: classItemMouse.containsMouse ? root.palette.hover : root.palette.surface
                        Text {
                            x: 13
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.name
                            color: root.palette.text
                            font.family: "Segoe UI"
                            font.pixelSize: 12
                        }
                        MouseArea {
                            id: classItemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.chooseClass(modelData.name)
                        }
                    }
                }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 74
            anchors.bottom: parent.bottom
            radius: 8
            color: root.palette.surface
            border.width: 1
            border.color: root.palette.border
            Text {
                anchors.centerIn: parent
                visible: root.classStudents().length === 0
                text: "名单还是空的\n点击右上角「名单设置」添加或导入学生"
                horizontalAlignment: Text.AlignHCenter
                color: root.palette.mutedText
                font.family: "Segoe UI"
                font.pixelSize: 13
                lineHeight: 1.5
            }
            Flickable {
                anchors.fill: parent
                anchors.margins: 12
                clip: true
                contentHeight: rosterList.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                Column {
                    id: rosterList
                    width: parent.width
                    Repeater {
                        model: root.classStudents()
                        delegate: Rectangle {
                            required property int index
                            required property string modelData
                            width: rosterList.width
                            height: 52
                            opacity: 0
                            color: rosterRowMouse.containsMouse ? root.palette.hover : index % 2 === 0 ? root.palette.surface : root.palette.surfaceAlt
                            Behavior on color { ColorAnimation { duration: 140 } }
                            SequentialAnimation on opacity {
                                running: true
                                PauseAnimation { duration: index * 22 }
                                NumberAnimation { to: 1; duration: 200; easing.type: Easing.OutCubic }
                            }
                            MouseArea {
                                id: rosterRowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.NoButton
                            }
                            Rectangle { width: parent.width; height: 1; color: root.palette.border }
                            Text {
                                x: 18
                                y: 17
                                text: index + 1 < 10 ? "0" + (index + 1) : String(index + 1)
                                color: root.palette.mutedText
                                font.family: "Segoe UI"
                                font.pixelSize: 11
                            }
                            Text {
                                x: 64
                                y: 16
                                text: "\uE77B"
                                color: root.palette.accent
                                font.family: "Segoe Fluent Icons"
                                font.pixelSize: 16
                            }
                            Text {
                                x: 96
                                y: 16
                                text: modelData
                                color: root.palette.text
                                font.family: "Segoe UI"
                                font.pixelSize: 13
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        id: editor
        anchors.fill: parent
        visible: root.editorOpen
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.Linear } }

        Rectangle {
            id: backButton
            width: 92
            height: 34
            anchors.left: parent.left
            anchors.top: parent.top
            radius: 5
            color: root.palette.selected
            scale: backButtonMouse.pressed ? 0.98 : 1
            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
            Row {
                anchors.centerIn: parent
                spacing: 5
                Text {
                    text: "\uE72B"
                    color: root.palette.accentText
                    font.family: "Segoe Fluent Icons"
                    font.pixelSize: 12
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "返回名单"
                    color: root.palette.accentText
                    font.family: "Segoe UI"
                    font.pixelSize: 11
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Behavior on color { ColorAnimation { duration: 160 } }
            MouseArea {
                id: backButtonMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.editorClassMenuOpen = false
                    root.editorOpen = false
                }
            }
        }
        Text {
            anchors.left: backButton.right
            anchors.leftMargin: 16
            anchors.verticalCenter: backButton.verticalCenter
            text: root.selectedClass + "  ·  " + root.classStudents().length + " 位学生"
            color: root.palette.secondaryText
            font.family: "Segoe UI"
            font.pixelSize: 12
        }

        Item {
            id: actions
            z: 5
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 50
            height: 84

            Row {
                id: classActions
                width: parent.width
                height: 38
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 7

                Rectangle {
                    id: editorClassPicker
                    width: 150
                    height: 36
                    radius: 5
                    color: root.palette.surface
                    border.width: 1
                    border.color: root.editorClassMenuOpen ? root.palette.accent : root.palette.border
                    Text {
                        x: 10
                        width: parent.width - 34
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.selectedClass
                        color: root.palette.text
                        font.family: "Segoe UI"
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\uE70D"
                        color: root.palette.secondaryText
                        font.family: "Segoe Fluent Icons"
                        font.pixelSize: 11
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.editorClassMenuOpen = !root.editorClassMenuOpen
                    }
                }

                Rectangle {
                    width: 132
                    height: 36
                    radius: 5
                    color: root.palette.surface
                    border.width: 1
                    border.color: root.palette.border
                    TextInput {
                        id: renameClassName
                        x: 9
                        width: parent.width - 18
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.palette.text
                        font.family: "Segoe UI"
                        font.pixelSize: 10
                        selectByMouse: true
                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: "重命名当前班级"
                            color: root.palette.mutedText
                            font: renameClassName.font
                            visible: renameClassName.text.length === 0
                        }
                    }
                }
                Rectangle {
                    width: 70
                    height: 36
                    radius: 5
                    color: root.palette.selected
                    Text { anchors.centerIn: parent; text: "重命名"; color: root.palette.accentText; font.family: "Segoe UI"; font.pixelSize: 10 }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var name = renameClassName.text.trim()
                            if (root.controller.renameClass(root.selectedClass, name)) {
                                root.chooseClass(name)
                                renameClassName.text = ""
                            }
                        }
                    }
                }

                Rectangle {
                    width: 132
                    height: 36
                    radius: 5
                    color: root.palette.surface
                    border.width: 1
                    border.color: root.palette.border
                    TextInput {
                        id: newClassName
                        x: 9
                        width: parent.width - 18
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.palette.text
                        font.family: "Segoe UI"
                        font.pixelSize: 10
                        selectByMouse: true
                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: "新班级名称"
                            color: root.palette.mutedText
                            font: newClassName.font
                            visible: newClassName.text.length === 0
                        }
                    }
                }
                Rectangle {
                    width: 70
                    height: 36
                    radius: 5
                    color: root.palette.surfaceAlt
                    Text { anchors.centerIn: parent; text: "添加班级"; color: root.palette.text; font.family: "Segoe UI"; font.pixelSize: 10 }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var name = newClassName.text.trim()
                            if (root.controller.addClass(name)) {
                                root.chooseClass(name)
                                newClassName.text = ""
                            }
                        }
                    }
                }
                Rectangle {
                    width: 70
                    height: 36
                    radius: 5
                    color: root.palette.mix("#fcebea", "#472b2b")
                    Text { anchors.centerIn: parent; text: "删除班级"; color: "#c65b52"; font.family: "Segoe UI"; font.pixelSize: 10 }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.controller.removeClass(root.selectedClass))
                                root.synchronizeSelection()
                        }
                    }
                }
            }

            Row {
                id: studentActions
                width: parent.width
                height: 38
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: classActions.bottom
                anchors.topMargin: 8
                spacing: 7

                Rectangle {
                    width: 190
                    height: 36
                    radius: 5
                    color: root.palette.surface
                    border.width: 1
                    border.color: root.palette.border
                    TextInput {
                        id: newStudentName
                        x: 10
                        width: parent.width - 20
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.palette.text
                        font.family: "Segoe UI"
                        font.pixelSize: 11
                        selectByMouse: true
                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: "输入姓名后添加学生"
                            color: root.palette.mutedText
                            font: newStudentName.font
                            visible: newStudentName.text.length === 0
                        }
                    }
                }
                Rectangle {
                    width: 90
                    height: 36
                    radius: 5
                    color: root.palette.accent
                    Text { anchors.centerIn: parent; text: "添加学生"; color: "white"; font.family: "Segoe UI"; font.pixelSize: 11 }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.controller.addStudent(root.selectedClass, newStudentName.text))
                                newStudentName.text = ""
                        }
                    }
                }
                Rectangle {
                    width: 118
                    height: 36
                    radius: 5
                    color: root.palette.selected
                    Row {
                        anchors.centerIn: parent
                        spacing: 5
                        Text { text: "\uE896"; color: root.palette.accentText; font.family: "Segoe Fluent Icons"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "导入 Excel"; color: root.palette.accentText; font.family: "Segoe UI"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: excelDialog.open()
                    }
                }
            }

            Rectangle {
                id: editorClassMenu
                z: 10
                width: editorClassPicker.width
                height: Math.min(190, Math.max(1, root.controller.classes.length * 34))
                anchors.left: editorClassPicker.left
                anchors.top: editorClassPicker.bottom
                anchors.topMargin: 3
                visible: root.editorClassMenuOpen
                         && root.editorOpen
                         && root.controller.classes.length > 0
                radius: 5
                color: root.palette.surface
                border.width: 1
                border.color: root.palette.border
                clip: true
                Column {
                    anchors.fill: parent
                    Repeater {
                        model: root.controller.classes
                        delegate: Rectangle {
                            required property var modelData
                            width: editorClassMenu.width
                            height: 34
                            color: menuClassMouse.containsMouse ? root.palette.hover : root.palette.surface
                            Text {
                                x: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.name
                                color: root.palette.text
                                font.family: "Segoe UI"
                                font.pixelSize: 10
                            }
                            MouseArea {
                                id: menuClassMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.chooseClass(modelData.name)
                                    root.editorClassMenuOpen = false
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: actions.bottom
            anchors.topMargin: 14
            anchors.bottom: parent.bottom
            radius: 8
            color: root.palette.surface
            border.width: 1
            border.color: root.palette.border
            Row {
                x: 16
                y: 14
                width: parent.width - 32
                height: 26
                Text { width: 50; text: "序号"; color: root.palette.mutedText; font.family: "Segoe UI"; font.pixelSize: 10 }
                Text { width: parent.width - 94; text: "姓名（可直接修改）"; color: root.palette.mutedText; font.family: "Segoe UI"; font.pixelSize: 10 }
                Text { width: 44; text: "操作"; color: root.palette.mutedText; font.family: "Segoe UI"; font.pixelSize: 10 }
            }
            Rectangle { x: 16; y: 42; width: parent.width - 32; height: 1; color: root.palette.border }
            Flickable {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 47
                anchors.bottom: parent.bottom
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                clip: true
                contentHeight: editList.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                Column {
                    id: editList
                    width: parent.width
                    Repeater {
                        model: root.classStudents()
                        delegate: Item {
                            required property int index
                            required property string modelData
                            width: editList.width
                            height: 46
                            Rectangle { width: parent.width; height: 1; color: root.palette.border }
                            Text { y: 15; width: 50; text: index + 1; color: root.palette.mutedText; font.family: "Segoe UI"; font.pixelSize: 10 }
                            TextInput {
                                x: 50
                                y: 8
                                width: parent.width - 120
                                height: 30
                                text: modelData
                                color: root.palette.text
                                font.family: "Segoe UI"
                                font.pixelSize: 11
                                selectByMouse: true
                                onEditingFinished: root.controller.setStudentName(root.selectedClass, index, text)
                            }
                            Rectangle {
                                width: 34
                                height: 30
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                y: 7
                                radius: 4
                                color: deleteMouse.containsMouse ? root.palette.mix("#fcebea", "#472b2b") : "transparent"
                                Text { anchors.centerIn: parent; text: "\uE74D"; color: "#c65b52"; font.family: "Segoe Fluent Icons"; font.pixelSize: 15 }
                                MouseArea {
                                    id: deleteMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.controller.removeStudent(root.selectedClass, index)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: authorizationMask
        z: 40
        anchors.fill: parent
        visible: root.authPromptOpen
        color: root.palette.mix("#a9000000", "#d9000000")
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Rectangle {
            width: 420
            height: 226
            anchors.centerIn: parent
            radius: 10
            color: root.palette.surface
            border.width: 1
            border.color: root.palette.border

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 34
                text: "\uE72E"
                color: root.palette.accent
                font.family: "Segoe Fluent Icons"
                font.pixelSize: 30
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 82
                text: "名单已锁定"
                color: root.palette.text
                font.family: "Segoe UI"
                font.pixelSize: 17
                font.weight: Font.DemiBold
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 114
                width: parent.width - 44
                text: root.controller.lastError.length > 0
                      ? root.controller.lastError
                      : "选择已绑定的教师私钥文件以继续编辑名单"
                horizontalAlignment: Text.AlignHCenter
                color: root.controller.lastError.length > 0 ? "#c65b52" : root.palette.secondaryText
                font.family: "Segoe UI"
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }
            Rectangle {
                width: 144
                height: 38
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 18
                radius: 5
                color: root.palette.accent
                Text {
                    anchors.centerIn: parent
                    text: "选择私钥文件"
                    color: "#ffffff"
                    font.family: "Segoe UI"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: privateKeyDialog.open()
                }
            }
            Rectangle {
                width: 30
                height: 30
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.top: parent.top
                anchors.topMargin: 10
                radius: 5
                color: closeAuthMouse.containsMouse ? root.palette.hover : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "\uE711"
                    color: root.palette.secondaryText
                    font.family: "Segoe Fluent Icons"
                    font.pixelSize: 12
                }
                MouseArea {
                    id: closeAuthMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.authPromptOpen = false
                }
            }
        }
    }

    FileDialog {
        id: privateKeyDialog
        title: root.controller.privateKeyBound ? "验证教师私钥" : "绑定教师私钥"
        selectExisting: true
        nameFilters: ["私钥文件 (*.pem *.key *.ppk)", "所有文件 (*)"]
        onAccepted: root.verifyTeacherKey(fileUrl.toLocalFile())
    }

    FileDialog {
        id: excelDialog
        title: "导入 Excel 班级名单"
        selectExisting: true
        nameFilters: ["Excel 工作簿 (*.xlsx)"]
        onAccepted: {
            if (root.controller.loadExcelPreview(fileUrl.toLocalFile()))
                excelImportWindow.openForClass(root.selectedClass)
        }
    }

    ExcelImportWindow {
        id: excelImportWindow
        palette: root.palette
        controller: root.controller
    }
}