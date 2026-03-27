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
    property color colWarning: "#ffaa00"
    property color colCritical: "#ff5555"

    // polling
    property int pollInterval: 2000

    // UI behavior — percent always visible

    // thresholds (percentage)
    property real warningThreshold: 70
    property real criticalThreshold: 90

    // state
    property real ramPercent: 0.0

    readonly property color iconColor: {
        if (root.ramPercent >= root.criticalThreshold) return root.colCritical
        if (root.ramPercent >= root.warningThreshold) return root.colWarning
        return root.colNormal
    }

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        spacing: root.gap

        Text {
            id: iconText
            font.family: root.fontFamily
            font.pixelSize: root.fontSize
            color: root.iconColor
            text: "\u{efc5}"  // nf-fa-memory
        }

        Text {
            id: pctText
            visible: true
            font.family: root.fontFamily
            font.pixelSize: root.fontSize
            color: root.iconColor
            text: Math.round(root.ramPercent) + "%"
        }
    }

    Process {
        id: memProc
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n")
                var total = 0
                var available = 0

                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split(/\s+/)
                    if (parts[0] === "MemTotal:")
                        total = parseInt(parts[1])
                    else if (parts[0] === "MemAvailable:")
                        available = parseInt(parts[1])
                }

                if (total > 0)
                    root.ramPercent = (1.0 - available / total) * 100
            }
        }
    }

    Timer {
        interval: root.pollInterval
        repeat: true
        running: true
        triggeredOnStart: true

        onTriggered: {
            if (!memProc.running) {
                memProc.exec({ command: ["head", "-3", "/proc/meminfo"] })
            }
        }
    }
}
