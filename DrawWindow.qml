import QtQuick 2.15
import QtQuick.Window 2.15

Window {
    id: root
    property var palette
    property string winner: ""
    property var reelNames: []
    property int winnerCardIndex: 52
    property int drawGeneration: 0
    property int pendingDrawGeneration: 0
    property bool animationFinished: false
    property real trackX: 0
    property real targetX: 0
    signal selected(string studentName)
    signal replayRequested()

    width: 1180
    height: 470
    minimumWidth: 900
    minimumHeight: 420
    x: (Screen.width - width) / 2
    y: (Screen.height - height) / 2
    visible: false
    color: "transparent"
    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    transientParent: null

    function startDraw(studentNames, selectedName) {
        layoutTimer.stop()
        drawGeneration += 1
        var requestGeneration = drawGeneration
        winner = selectedName
        // 每次重抽先清除高亮状态，中奖卡必须等轨道停下后才突出显示。
        animationFinished = false
        reelAnimation.stop()
        if (studentNames.length === 0) {
            reelNames = [selectedName]
            winnerCardIndex = 0
            visible = true
            raise()
            pendingDrawGeneration = requestGeneration
            layoutTimer.start()
            return
        }

        // 中奖位置固定在轨道中段，前后随机姓名形成完整的滚动序列。
        // 固定中奖卡位置，并在前后填入随机姓名，让首轮与后续抽取走同一条轨道。
        var targetIndex = 52
        var names = []
        for (var i = 0; i < 56; ++i) {
            names.push(i === targetIndex
                       ? selectedName
                       : studentNames[Math.floor(Math.random() * studentNames.length)])
        }
        reelNames = names
        winnerCardIndex = targetIndex

        // 先将轨道复位，再显示窗口，避免上一轮终点在首帧闪现。
        trackX = 0
        targetX = 0
        visible = true
        raise()
        // 让下一轮事件循环先完成窗口布局，再读取首轮也可靠的 viewport 实际宽度。
        pendingDrawGeneration = requestGeneration
        layoutTimer.start()
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 8
        radius: 14
        color: root.palette.surface
        border.width: 1
        border.color: root.palette.border

        Text {
            x: 28
            y: 20
            text: "课堂随机点名"
            color: root.palette.text
            font.family: "Segoe UI"
            font.pixelSize: 15
            font.weight: Font.DemiBold
        }
        Rectangle {
            width: 36
            height: 36
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.top: parent.top
            anchors.topMargin: 12
            radius: 6
            color: closeMouse.containsMouse ? root.palette.hover : "transparent"
            Text {
                anchors.centerIn: parent
                text: "\uE711"
                color: root.palette.secondaryText
                font.family: "Segoe Fluent Icons"
                font.pixelSize: 14
            }
            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.hide()
            }
        }

        Rectangle {
            id: reelViewport
            x: 28
            y: 70
            width: parent.width - 56
            height: 250
            radius: 10
            color: root.palette.reel
            clip: true
            property real cardStride: 192

            Rectangle {
                width: 3
                height: parent.height - 24
                radius: 2
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                color: root.palette.accent
                opacity: 0.9
                z: 2
            }
            Row {
                id: reelTrack
                x: root.trackX
                anchors.verticalCenter: parent.verticalCenter
                spacing: reelViewport.cardStride - 176
                height: 174
                Repeater {
                    model: 56
                    delegate: Rectangle {
                        required property int index
                        property bool highlighted: root.animationFinished && index === root.winnerCardIndex
                        width: 176
                        height: highlighted ? 174 : 156
                        y: (reelTrack.height - height) / 2
                        radius: 9
                        color: highlighted ? root.palette.reelWinner : root.palette.reelCard
                        border.width: highlighted ? 2 : 1
                        border.color: highlighted ? root.palette.accent : root.palette.border
                        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        Behavior on border.width { NumberAnimation { duration: 180 } }
                        Text {
                            anchors.centerIn: parent
                            width: parent.width - 18
                            text: root.reelNames.length > index ? root.reelNames[index] : ""
                            horizontalAlignment: Text.AlignHCenter
                            color: highlighted ? root.palette.accentText : root.palette.secondaryText
                            font.family: "Segoe UI"
                            font.pixelSize: highlighted ? 36 : 20
                            font.weight: highlighted ? Font.DemiBold : Font.Normal
                            elide: Text.ElideRight
                            Behavior on color { ColorAnimation { duration: 240 } }
                            Behavior on font.pixelSize { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 337
            text: reelAnimation.running ? "正在抽取" : "本次点到：" + root.winner
            color: root.palette.secondaryText
            font.family: "Segoe UI"
            font.pixelSize: reelAnimation.running ? 13 : 20
            font.weight: reelAnimation.running ? Font.Normal : Font.DemiBold
        }
        Rectangle {
            width: 124
            height: 38
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
            radius: 6
            color: root.palette.accent
            Text {
                anchors.centerIn: parent
                text: reelAnimation.running ? "抽取中" : "再抽一次"
                color: "#ffffff"
                font.family: "Segoe UI"
                font.pixelSize: 12
            }
            MouseArea {
                anchors.fill: parent
                enabled: !reelAnimation.running
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.replayRequested()
            }
        }
    }

    Timer {
        id: layoutTimer
        interval: 50
        repeat: false
        onTriggered: {
            if (root.pendingDrawGeneration !== root.drawGeneration)
                return
            if (root.winner === "名单为空") {
                root.trackX = reelViewport.width / 2 - 88
                root.targetX = root.trackX
                root.animationFinished = true
                return
            }
            root.trackX = 0
            root.targetX = reelViewport.width / 2
                    - root.winnerCardIndex * reelViewport.cardStride - 88
            reelAnimation.from = 0
            reelAnimation.to = root.targetX
            reelAnimation.start()
        }
    }

    NumberAnimation {
        id: reelAnimation
        target: root
        property: "trackX"
        from: 0
        to: root.targetX
        duration: 6200
        easing.type: Easing.OutQuart
        onFinished: {
            // 先结束滚动并高亮中奖卡，再向主窗口发送最终选中信号。
            root.animationFinished = true
            root.selected(root.winner)
        }
    }
}