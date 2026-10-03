import QtQuick 2.15

Rectangle {
    id: root
    property var palette
    property int selectedPage: 0
    signal navigate(int page)

    width: 236
    color: palette.surface

    Rectangle {
        width: 1
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        color: root.palette.border
    }

    Column {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 0

        Item {
            width: parent.width
            height: 88
            Rectangle {
                x: 4
                y: 22
                width: 40
                height: 40
                radius: 10
                color: "#1769c2"
                Text {
                    anchors.centerIn: parent
                    text: "R"
                    color: "white"
                    font.family: "Segoe UI"
                    font.pixelSize: 23
                    font.bold: true
                }
            }
            Text {
                x: 56
                y: 22
                text: "RollCaller"
                color: root.palette.text
                font.family: "Segoe UI"
                font.pixelSize: 17
                font.bold: true
            }
            Text {
                x: 56
                y: 47
                text: "课堂点名工作台"
                color: root.palette.secondaryText
                font.family: "Segoe UI"
                font.pixelSize: 11
            }
        }

        Text {
            width: parent.width
            height: 36
            leftPadding: 12
            verticalAlignment: Text.AlignVCenter
            text: "工作区"
            color: root.palette.mutedText
            font.family: "Segoe UI"
            font.pixelSize: 11
        }

        Repeater {
            model: [
                { label: "主页", icon: "\uE80F" },
                { label: "班级名单", icon: "\uE716" },
                { label: "设置", icon: "\uE713" }
            ]
            delegate: Rectangle {
                required property int index
                required property var modelData
                width: parent.width
                height: 44
                radius: 6
                color: root.selectedPage === index ? root.palette.selected : navMouse.containsMouse ? root.palette.hover : "transparent"

                Rectangle {
                    width: 3
                    height: 22
                    radius: 2
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.selectedPage === index ? root.palette.accent : "transparent"
                }
                Text {
                    x: 15
                    width: 22
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.icon
                    color: root.selectedPage === index ? root.palette.accent : root.palette.secondaryText
                    font.family: "Segoe Fluent Icons"
                    font.pixelSize: 19
                    horizontalAlignment: Text.AlignHCenter
                }
                Text {
                    x: 50
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.label
                    color: root.selectedPage === index ? root.palette.accentText : root.palette.text
                    font.family: "Segoe UI"
                    font.pixelSize: 13
                    font.weight: root.selectedPage === index ? Font.DemiBold : Font.Normal
                }
                MouseArea {
                    id: navMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.navigate(index)
                }
            }
        }

        Item {
            width: 1
            height: Math.max(1, parent.height - 88 - 36 - 3 * 44)
        }

        Text {
            width: parent.width
            height: 42
            leftPadding: 12
            verticalAlignment: Text.AlignVCenter
            text: "名单自动保存在本机"
            color: root.palette.mutedText
            font.family: "Segoe UI"
            font.pixelSize: 10
        }
    }
}