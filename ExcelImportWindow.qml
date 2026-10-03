import QtQuick 2.15
import QtQuick.Window 2.15

Window {
    id: root
    property var palette
    property var controller
    property string className: ""
    property int selectedNameColumn: 0
    property int firstRow: 1
    property int lastRow: 1
    property bool firstRowIsHeader: true
    property bool headerChoiceManual: false

    function detectHeader() {
        var rows = root.controller.excelPreviewData
        if (rows.length === 0 || root.selectedNameColumn >= rows[0].cells.length)
            return false
        var value = String(rows[0].cells[root.selectedNameColumn]).trim().toLowerCase()
        return ["姓名", "学生姓名", "学生", "name", "student"].indexOf(value) >= 0
    }

    width: 1040
    height: 650
    minimumWidth: 860
    minimumHeight: 560
    x: (Screen.width - width) / 2
    y: (Screen.height - height) / 2
    visible: false
    color: "transparent"
    flags: Qt.Dialog | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    modality: Qt.ApplicationModal
    transientParent: null

    function openForClass(targetClass) {
        className = targetClass
        selectedNameColumn = controller.excelPreviewNameColumn
        firstRow = controller.excelPreviewStartRow
        lastRow = controller.excelPreviewLastRow
        headerChoiceManual = false
        firstRowIsHeader = detectHeader()
        startRowInput.text = String(firstRow)
        endRowInput.text = String(lastRow)
        show()
        raise()
    }

    function columnName(columnIndex) {
        // 将 Excel 的从 1 开始列号转换为 A、B……AA 这样的列字母。
        var value = controller.excelPreviewFirstColumn + columnIndex
        var label = ""
        while (value > 0) {
            var remainder = (value - 1) % 26
            label = String.fromCharCode(65 + remainder) + label
            value = Math.floor((value - 1) / 26)
        }
        return label
    }

    function confirmImport() {
        // 只有范围有效且姓名列已由老师确认，控制器才会写入 JSON。
        var start = Math.floor(Number(firstRow))
        var end = Math.floor(Number(lastRow))
        if (!controller.confirmExcelImport(className, selectedNameColumn, start, end, firstRowIsHeader))
            return
        hide()
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 8
        radius: 12
        color: root.palette.surface
        border.width: 1
        border.color: root.palette.border

        Text {
            x: 26
            y: 20
            text: "导入名单预览"
            color: root.palette.text
            font.family: "Segoe UI"
            font.pixelSize: 17
            font.weight: Font.DemiBold
        }
        Text {
            x: 26
            y: 49
            text: root.className + "  ·  选择姓名列并确认导入范围"
            color: root.palette.secondaryText
            font.family: "Segoe UI"
            font.pixelSize: 11
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

        Text {
            x: 26
            y: 82
            width: parent.width - 52
            text: root.controller.lastError.length > 0
                  ? root.controller.lastError
                  : "点击列标题选择姓名列 · 表格展示选定范围的全部行，导入上限 5000 行"
            color: root.controller.lastError.length > 0 ? "#c65b52" : root.palette.secondaryText
            font.family: "Segoe UI"
            font.pixelSize: 10
            elide: Text.ElideRight
        }

        Rectangle {
            id: previewPanel
            x: 24
            y: 108
            width: parent.width - 48
            height: parent.height - 212
            radius: 8
            color: root.palette.reel
            border.width: 1
            border.color: root.palette.border
            clip: true

            Flickable {
                id: previewFlickable
                anchors.fill: parent
                anchors.margins: 1
                clip: true
                contentWidth: Math.max(width, (root.controller.excelPreviewColumnCount + 1) * 148)
                contentHeight: height
                flickableDirection: Flickable.HorizontalFlick
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: previewGrid
                    width: Math.max(previewFlickable.width, (root.controller.excelPreviewColumnCount + 1) * 148)
                    height: previewFlickable.height
                    Row {
                        width: parent.width
                        height: 42
                        spacing: 0
                        Rectangle {
                            width: 64
                            height: parent.height
                            color: root.palette.surfaceAlt
                            Text { anchors.centerIn: parent; text: "行"; color: root.palette.mutedText; font.family: "Segoe UI"; font.pixelSize: 10 }
                        }
                        Repeater {
                            model: root.controller.excelPreviewColumnCount
                            delegate: Rectangle {
                                required property int index
                                width: 148
                                height: 42
                                color: index === root.selectedNameColumn ? root.palette.selected : root.palette.surfaceAlt
                                border.width: 1
                                border.color: root.palette.border
                                Row {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text {
                                        text: root.columnName(index)
                                        color: index === root.selectedNameColumn ? root.palette.accentText : root.palette.text
                                        font.family: "Segoe UI"
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }
                                    Text {
                                        text: index === root.selectedNameColumn ? "姓名列  ✓" : "设为姓名列"
                                        color: index === root.selectedNameColumn ? root.palette.accentText : root.palette.secondaryText
                                        font.family: "Segoe UI"
                                        font.pixelSize: 10
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.selectedNameColumn = index
                                        if (!root.headerChoiceManual)
                                            root.firstRowIsHeader = root.detectHeader()
                                    }
                                }
                            }
                        }
                    }

                    ListView {
                        width: parent.width
                        height: parent.height - 42
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: root.controller.excelPreviewData
                        delegate: Row {
                            required property var modelData
                            height: 38
                            spacing: 0
                            Rectangle {
                                width: 64
                                height: parent.height
                                color: root.palette.surfaceAlt
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.row
                                    color: root.palette.mutedText
                                    font.family: "Segoe UI"
                                    font.pixelSize: 10
                                }
                            }
                            Repeater {
                                model: modelData.cells
                                delegate: Rectangle {
                                    required property int index
                                    required property string modelData
                                    width: 148
                                    height: 38
                                    color: index === root.selectedNameColumn ? root.palette.selected : root.palette.surface
                                    border.width: 1
                                    border.color: root.palette.border
                                    Text {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        verticalAlignment: Text.AlignVCenter
                                        text: modelData
                                        color: index === root.selectedNameColumn ? root.palette.accentText : root.palette.text
                                        font.family: "Segoe UI"
                                        font.pixelSize: 10
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Row {
            x: 26
            y: parent.height - 86
            height: 38
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "导入行"
                color: root.palette.secondaryText
                font.family: "Segoe UI"
                font.pixelSize: 11
            }
            Rectangle {
                width: 76
                height: 34
                radius: 5
                color: root.palette.surfaceAlt
                border.width: 1
                border.color: root.palette.border
                TextInput {
                    id: startRowInput
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    verticalAlignment: TextInput.AlignVCenter
                    text: String(root.firstRow)
                    color: root.palette.text
                    font.family: "Segoe UI"
                    font.pixelSize: 11
                    selectByMouse: true
                    validator: IntValidator { bottom: root.controller.excelPreviewStartRow; top: root.controller.excelPreviewLastRow }
                    onTextChanged: {
                        if (acceptableInput && text.length > 0)
                            root.firstRow = Number(text)
                    }
                    onEditingFinished: {
                        if (root.controller.updateExcelPreviewRange(root.firstRow, root.lastRow)
                            && !root.headerChoiceManual)
                            root.firstRowIsHeader = root.detectHeader()
                    }
                }
            }
            Text { anchors.verticalCenter: parent.verticalCenter; text: "至"; color: root.palette.secondaryText; font.family: "Segoe UI"; font.pixelSize: 11 }
            Rectangle {
                width: 76
                height: 34
                radius: 5
                color: root.palette.surfaceAlt
                border.width: 1
                border.color: root.palette.border
                TextInput {
                    id: endRowInput
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    verticalAlignment: TextInput.AlignVCenter
                    text: String(root.lastRow)
                    color: root.palette.text
                    font.family: "Segoe UI"
                    font.pixelSize: 11
                    selectByMouse: true
                    validator: IntValidator { bottom: root.controller.excelPreviewStartRow; top: root.controller.excelPreviewLastRow }
                    onTextChanged: {
                        if (acceptableInput && text.length > 0)
                            root.lastRow = Number(text)
                    }
                    onEditingFinished: {
                        if (root.controller.updateExcelPreviewRange(root.firstRow, root.lastRow)
                            && !root.headerChoiceManual)
                            root.firstRowIsHeader = root.detectHeader()
                    }
                }
            }
            Rectangle {
                width: 132
                height: 34
                radius: 5
                color: root.firstRowIsHeader ? root.palette.selected : root.palette.surfaceAlt
                border.width: 1
                border.color: root.palette.border
                Text {
                    anchors.centerIn: parent
                    text: root.firstRowIsHeader ? "✓  首行是表头" : "首行包含姓名"
                    color: root.palette.text
                    font.family: "Segoe UI"
                    font.pixelSize: 10
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.firstRowIsHeader = !root.firstRowIsHeader
                        root.headerChoiceManual = true
                    }
                }
            }
        }

        Rectangle {
            width: 94
            height: 36
            anchors.right: parent.right
            anchors.rightMargin: 24
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 20
            radius: 5
            color: root.palette.surfaceAlt
            Text { anchors.centerIn: parent; text: "取消"; color: root.palette.text; font.family: "Segoe UI"; font.pixelSize: 11 }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.hide() }
        }
        Rectangle {
            width: 118
            height: 36
            anchors.right: parent.right
            anchors.rightMargin: 130
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 20
            radius: 5
            color: root.palette.accent
            Text { anchors.centerIn: parent; text: "确认导入"; color: "#ffffff"; font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.DemiBold }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.confirmImport() }
        }
    }
}