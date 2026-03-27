import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    // styling
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 12
    property int gap: 6
    property color colNormal: "white"
    property color colMuted: "#ff5555"

    // polling
    property int pollInterval: 800

    // UI behavior — percent always visible

    // state
    property real volumeFrac: 0.0
    property bool muted: false

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        spacing: root.gap

        Text {
            id: iconText
            font.family: root.fontFamily
            font.pixelSize: root.fontSize
            color: root.muted ? root.colMuted : root.colNormal
            text: {
                if (root.muted || root.volumeFrac <= 0.01) {
                    return "󰝟"
                } else if (root.volumeFrac < 0.33) {
                    return "󰕿"
                } else if (root.volumeFrac < 0.66) {
                    return "󰖀"
                } else {
                    return "󰕾"
                }
            }
        }

        Text {
            id: pctText
            visible: true
            font.family: root.fontFamily
            font.pixelSize: root.fontSize
            color: root.muted ? root.colMuted : root.colNormal
            text: Math.round(root.volumeFrac * 100) + "%"
        }
    }

    Process {
        id: wpctlProc
        stdout: StdioCollector {
            onStreamFinished: {
                var s = this.text.trim()

                var m = s.match(/Volume:\s*([0-9]*\.?[0-9]+)/)
                if (m && m.length >= 2) {
                    var v = parseFloat(m[1])
                    if (!isNaN(v)) {
                        if (v < 0.0) v = 0.0
                        if (v > 1.0) v = 1.0
                        root.volumeFrac = v
                    }
                }

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
            if (!wpctlProc.running) {
                wpctlProc.exec({ command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"] })
            }
        }
    }
}
