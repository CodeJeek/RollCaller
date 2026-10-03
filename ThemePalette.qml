import QtQuick 2.15

QtObject {
    id: palette

    property real progress: 0
    property bool dark: false

    // 解析 RGB 与 ARGB 两种写法，保持 Qt 5.15 下颜色渐变可用。
    function channels(colorValue) {
        var hex = colorValue.toString().replace("#", "")
        var alpha = 1
        if (hex.length === 8) {
            alpha = parseInt(hex.substr(0, 2), 16) / 255
            hex = hex.substr(2)
        }
        return {
            r: parseInt(hex.substr(0, 2), 16) / 255,
            g: parseInt(hex.substr(2, 2), 16) / 255,
            b: parseInt(hex.substr(4, 2), 16) / 255,
            a: alpha
        }
    }

    function mix(lightColor, darkColor) {
        var light = channels(lightColor)
        var dark = channels(darkColor)
        var amount = progress
        return Qt.rgba(
                    light.r + (dark.r - light.r) * amount,
                    light.g + (dark.g - light.g) * amount,
                    light.b + (dark.b - light.b) * amount,
                    light.a + (dark.a - light.a) * amount)
    }

    function toggle() {
        // 从当前进度反向渐变，用户连续点击时也不会跳变到中间态。
        dark = !dark
        colorTransition.from = progress
        colorTransition.to = dark ? 1 : 0
        colorTransition.start()
    }

    function setInitialTheme(enabled) {
        dark = enabled
        progress = enabled ? 1 : 0
    }

    readonly property color background: mix("#f5f7f9", "#17191d")
    readonly property color surface: mix("#ffffff", "#22262b")
    readonly property color surfaceAlt: mix("#f5f7f9", "#2a2f35")
    readonly property color border: mix("#e5e9ed", "#383e46")
    readonly property color text: mix("#202428", "#f1f3f5")
    readonly property color secondaryText: mix("#747c84", "#aab2ba")
    readonly property color mutedText: mix("#858c94", "#8d969f")
    readonly property color hover: mix("#f0f4f8", "#323940")
    readonly property color selected: mix("#eaf2fb", "#24384c")
    readonly property color accent: mix("#1769c2", "#69aef5")
    readonly property color accentText: mix("#155ba5", "#8bc1fa")
    readonly property color card: mix("#ffffff", "#30363d")
    readonly property color reel: mix("#edf2f7", "#20262d")
    readonly property color reelCard: mix("#f9fbfc", "#292f36")
    readonly property color reelWinner: mix("#ffffff", "#35404b")

    property NumberAnimation colorTransition: NumberAnimation {
        target: palette
        property: "progress"
        duration: 360
        easing.type: Easing.InOutCubic
    }
}