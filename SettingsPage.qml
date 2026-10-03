import QtQuick 2.15

Item {
    id: root
    property var palette
    property string dataFilePath: ""
    property string configFilePath: ""
    property bool avoidRepeatByDefault: false
    property bool privateKeyBound: false
    signal toggleTheme()
    signal changeAvoidRepeatDefault(bool enabled)
    signal generateTeacherKey()

    Text {
        id: heading
        anchors.left: parent.left
        anchors.top: parent.top
        text: "设置"
        color: root.palette.text
        font.family: "Segoe UI"
        font.pixelSize: 23
        font.weight: Font.DemiBold
    }
    Text {
        anchors.left: parent.left
        anchors.top: heading.bottom
        anchors.topMargin: 6
        text: "外观、点名偏好与本机安全状态"
        color: root.palette.secondaryText
        font.family: "Segoe UI"
        font.pixelSize: 12
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 76
        spacing: 12

        Rectangle {
            width: parent.width
            height: 82
            radius: 7
            color: root.palette.surface
            border.width: 1
            border.color: root.palette.border
            Text {
                x: 20
                y: 19
                text: "深色主题"
                color: root.palette.text
                font.family: "Segoe UI"
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }
            Text {
                x: 20
                y: 46
                text: "在浅色和深色外观之间平滑切换"
                color: root.palette.secondaryText
                font.family: "Segoe UI"
                font.pixelSize: 11
            }
            Rectangle {
                width: 42
                height: 24
                radius: 12
                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                color: root.palette.dark ? root.palette.accent : "#c4cbd2"
                Rectangle {
                    width: 18
                    height: 18
                    radius: 9
                    anchors.verticalCenter: parent.verticalCenter
                    x: root.palette.dark ? 21 : 3
                    color: "#ffffff"
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleTheme()
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 82
            radius: 7
            color: root.palette.surface
            border.width: 1
            border.color: root.palette.border
            Text {
                x: 20
                y: 19
                text: "默认避免重复点到"
                color: root.palette.text
                font.family: "Segoe UI"
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }
            Text {
                x: 20
                y: 46
                text: "新课堂默认启用，悬浮按钮可临时调整"
                color: root.palette.secondaryText
                font.family: "Segoe UI"
                font.pixelSize: 11
            }
            Rectangle {
                width: 42
                height: 24
                radius: 12
                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                color: root.avoidRepeatByDefault ? root.palette.accent : "#c4cbd2"
                Rectangle {
                    width: 18
                    height: 18
                    radius: 9
                    anchors.verticalCenter: parent.verticalCenter
                    x: root.avoidRepeatByDefault ? 21 : 3
                    color: "#ffffff"
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.changeAvoidRepeatDefault(!root.avoidRepeatByDefault)
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 82
            radius: 7
            color: root.palette.surface
            border.width: 1
            border.color: root.palette.border
            Text {
                x: 20
                y: 19
                text: "教师私钥"
                color: root.palette.text
                font.family: "Segoe UI"
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }
            Text {
                x: 20
                y: 46
                text: root.privateKeyBound ? "已绑定 · 编辑名单时仍需使用对应密钥文件" : "尚未绑定 · 生成随机密钥文件后即可启用编辑锁"
                color: root.palette.secondaryText
                font.family: "Segoe UI"
                font.pixelSize: 11
            }
            Rectangle {
                width: 112
                height: 34
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                radius: 5
                color: root.privateKeyBound ? root.palette.surfaceAlt : root.palette.accent
                visible: !root.privateKeyBound
                Text {
                    anchors.centerIn: parent
                    text: "生成密钥"
                    color: "#ffffff"
                    font.family: "Segoe UI"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.generateTeacherKey()
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 98
            radius: 7
            color: root.palette.surface
            border.width: 1
            border.color: root.palette.border
            Text {
                x: 20
                y: 16
                text: "本机数据位置"
                color: root.palette.text
                font.family: "Segoe UI"
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }
            Text {
                x: 20
                y: 43
                width: parent.width - 40
                text: "名单：" + root.dataFilePath + "\n设置：" + root.configFilePath
                color: root.palette.secondaryText
                font.family: "Segoe UI"
                font.pixelSize: 10
                elide: Text.ElideMiddle
            }
        }
    }
}