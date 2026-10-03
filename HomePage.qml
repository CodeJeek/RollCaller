import QtQuick 2.15

Item {
    id: root
    property var palette
    property string className: ""
    property int studentCount: 0
    signal startLesson()
    signal stopLesson()
    property bool lessonActive: false

    Text {
        id: title
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        text: "课堂中心"
        color: root.palette.text
        font.family: "Segoe UI"
        font.pixelSize: 24
        font.weight: Font.DemiBold
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: title.bottom
        anchors.topMargin: 7
        text: root.className.length > 0 ? root.className + "  ·  " + root.studentCount + " 位学生" : "请先在班级名单中添加学生"
        color: root.palette.secondaryText
        font.family: "Segoe UI"
        font.pixelSize: 12
    }

    Item {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: title.bottom
        anchors.bottom: parent.bottom

        Rectangle {
            id: outerPulse
            width: 284
            height: 284
            radius: 142
            anchors.centerIn: startButton
            color: root.palette.accent
            opacity: 0
            SequentialAnimation on scale {
                loops: Animation.Infinite
                running: !root.lessonActive
                PauseAnimation { duration: 300 }
                ParallelAnimation {
                    NumberAnimation { from: 0.72; to: 1.33; duration: 1800; easing.type: Easing.Linear }
                    NumberAnimation { target: outerPulse; property: "opacity"; from: 0.32; to: 0; duration: 1800; easing.type: Easing.Linear }
                }
            }
        }
        Rectangle {
            id: innerPulse
            width: 234
            height: 234
            radius: 117
            anchors.centerIn: startButton
            color: root.palette.accent
            opacity: 0
            SequentialAnimation on scale {
                loops: Animation.Infinite
                running: !root.lessonActive
                PauseAnimation { duration: 1050 }
                ParallelAnimation {
                    NumberAnimation { from: 0.76; to: 1.28; duration: 1800; easing.type: Easing.Linear }
                    NumberAnimation { target: innerPulse; property: "opacity"; from: 0.24; to: 0; duration: 1800; easing.type: Easing.Linear }
                }
            }
        }
        Rectangle {
            id: startButton
            width: 184
            height: 184
            radius: 92
            anchors.centerIn: parent
            color: root.lessonActive ? "#b33b36" : "#1769c2"
            border.width: 7
            border.color: root.palette.surface
            Behavior on color { ColorAnimation { duration: 240 } }
            SequentialAnimation on scale {
                loops: Animation.Infinite
                running: !root.lessonActive
                NumberAnimation { from: 1; to: 1.045; duration: 1800; easing.type: Easing.InOutSine }
                NumberAnimation { from: 1.045; to: 1; duration: 1800; easing.type: Easing.InOutSine }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 42
                text: root.lessonActive ? "\uE71A" : "\uE768"
                color: "#ffffff"
                font.family: "Segoe Fluent Icons"
                font.pixelSize: 38
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 102
                text: root.lessonActive ? "停止上课" : "开始上课"
                color: "#ffffff"
                font.family: "Segoe UI"
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.lessonActive)
                        root.stopLesson()
                    else
                        root.startLesson()
                }
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: startButton.bottom
            anchors.topMargin: 18
            text: root.lessonActive
                ? "课程进行中 · 点击圆心按钮结束上课并收回点名浮窗"
                : "开始后主窗口最小化，点名工具独立悬浮于演示画面上方"
            color: root.palette.secondaryText
            font.family: "Segoe UI"
            font.pixelSize: 12
        }
    }
}