import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root
    height: parent ? parent.height : 24
    width: row.implicitWidth

    // styling
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 12
    property int gap: 6

    // polling
    property int pollInterval: 800

    // state
    property real volumeFrac: 0.0   // 0.0 .. 1.0
    property bool muted: false

    Row {
        id: row
        anchors.centerIn: parent
        spacing: root.gap

        Text {
            font.family: root.fontFamily
            font.pixelSize: root.fontSize
            color: "white"
            text: {
                if (root.muted || root.volumeFrac <= 0.01) {
                    return "󰝟"    // muted/zero
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
            font.family: root.fontFamily
            font.pixelSize: root.fontSize
            color: "white"
            text: Math.round(root.volumeFrac * 100) + "%"
        }
    }

    Process {
        id: wpctlProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]

        // Collect stdout when the process finishes
        stdout: StdioCollector {
            onStreamFinished: {
                // examples:
                // "Volume: 0.52"
                // "Volume: 0.52 [MUTED]"
                var s = this.text.trim()

                // volume
                var m = s.match(/Volume:\s*([0-9]*\.?[0-9]+)/)
                if (m && m.length >= 2) {
                    var v = parseFloat(m[1])
                    if (!isNaN(v)) {
                        if (v < 0.0) v = 0.0
                        if (v > 1.0) v = 1.0
                        root.volumeFrac = v
                    }
                }

                // mute
                root.muted = (s.indexOf("MUTED") !== -1)
            }
        }
    }

    Timer {
        interval: root.pollInterval
        repeat: true
        running: true
        triggeredOnStart: true

        onTriggered: {
            // don't overlap runs
            if (!wpctlProc.running) {
                wpctlProc.exec({ command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"] })
            }
        }
    }
}
