import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root
    height: parent ? parent.height : 24

    // styling
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 12
    property int gap: 6

    // update rate (ms)
    property int pollInterval: 800

    // state
    property real volumeFrac: 0.0     // 0.0 .. 1.0
    property bool muted: false

    width: row.implicitWidth

    Row {
        id: row
        anchors.centerIn: parent
        spacing: root.gap

        Text {
            id: iconText
            font.family: root.fontFamily
            font.pixelSize: root.fontSize
            color: "white"

            text: {
                if (root.muted || root.volumeFrac <= 0.01) {
                    return "󰝟"    // muted / 0
                } else if (root.volumeFrac < 0.33) {
                    return "󰕿"    // low
                } else if (root.volumeFrac < 0.66) {
                    return "󰖀"    // medium
                } else {
                    return "󰕾"    // high
                }
            }
        }

        Text {
            id: pctText
            font.family: root.fontFamily
            font.pixelSize: root.fontSize
            color: "white"

            text: {
                var pct = Math.round(root.volumeFrac * 100)
                return pct + "%"
            }
        }
    }

    Process {
        id: wpctlProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: false

        // Quickshell Process usually exposes stdout as "text" or via signals depending on version.
        // We'll handle both common patterns: onStdoutChanged and onFinished reading stdout.
        property string out: ""

        onReadyReadStandardOutput: {
            out += readAllStandardOutput()
        }

        onFinished: {
            var s = out
            out = ""

            // examples:
            // "Volume: 0.52"
            // "Volume: 0.52 [MUTED]"
            // sometimes includes newline
            s = s.trim()

            // parse volume float
            var m = s.match(/Volume:\s*([0-9]*\.?[0-9]+)/)
            if (m && m.length >= 2) {
                var v = parseFloat(m[1])
                if (!isNaN(v)) {
                    // clamp
                    if (v < 0.0) v = 0.0
                    if (v > 1.0) v = 1.0
                    root.volumeFrac = v
                }
            }

            // parse muted
            root.muted = (s.indexOf("MUTED") !== -1)
        }
    }

    Timer {
        id: pollTimer
        interval: root.pollInterval
        repeat: true
        running: true
        triggeredOnStart: true

        onTriggered: {
            // prevent overlapping calls
            if (!wpctlProc.running) {
                wpctlProc.start()
            }
        }
    }
}
