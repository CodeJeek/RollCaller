import QtQuick 2.15
import QtQuick.Window 2.15

Window {
    id: root
    property var palette
    property bool avoidRepeat: false
    signal drawRequested()
    signal returnRequested()

    width: 300
    height: 62
    x: Screen.width - width - 36
    y: 90
    visible: false
    color: "transparent"
    opacity: 0.96
    flags: Qt.Window | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    transientParent: null

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: root.palette.mix("#e6212933", "#ed101419")
        border.width: 1
        border.color: root.palette.mix("#668caecc", "#665e7184")

        Rectangle {
            width: 126
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            color: "transparent"
            Row {
                anchors.centerIn: parent
                spacing: 9
                Text {
                    text: "\uE768"
                    color: "#ffffff"
                    font.family: "Segoe Fluent Icons"
                    font.pixelSize: 18
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "点名"
                    color: "#ffffff"
                    font.family: "Segoe UI"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        Rectangle {
            x: 132
            y: 13
            width: 1
            height: 36
            color: "#668caecc"
        }

        Text {
            x: 143
            y: 12
            text: "避免重复"
            color: "#ffffff"
            font.family: "Segoe UI"
            font.pixelSize: 10
        }
        Rectangle {
            x: 214
            y: 19
            width: 40
            height: 24
            radius: 12
            color: root.avoidRepeat ? "#54a8f0" : "#66727d"
            Rectangle {
                width: 18
                height: 18
                radius: 9
                anchors.verticalCenter: parent.verticalCenter
                x: root.avoidRepeat ? 19 : 3
                color: "#ffffff"
            }
        }

        MouseArea {
            id: dragArea
            anchors.fill: parent
            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
            property real pressX: 0
            property real pressY: 0
            property real offsetX: 0
            property real offsetY: 0
            property bool dragged: false
            onPressed: {
                var globalPoint = dragArea.mapToGlobal(Qt.point(mouse.x, mouse.y))
                pressX = globalPoint.x
                pressY = globalPoint.y
                offsetX = globalPoint.x - root.x
                offsetY = globalPoint.y - root.y
                dragged = false
            }
            onPositionChanged: {
                if (!pressed)
                    return
                var globalPoint = dragArea.mapToGlobal(Qt.point(mouse.x, mouse.y))
                if (Math.abs(globalPoint.x - pressX) + Math.abs(globalPoint.y - pressY) > 3)
                    dragged = true
                if (dragged) {
                    root.x = globalPoint.x - offsetX
                    root.y = globalPoint.y - offsetY
                }
            }
            onClicked: {
                if (dragged)
                    return
                if (mouse.x < 132)
                    root.drawRequested()
                else if (mouse.x < 260)
                    root.avoidRepeat = !root.avoidRepeat
                else
                    root.returnRequested()
            }
        }
    }
}