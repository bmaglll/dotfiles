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
    property real cpuPercent: 0.0

    // previous /proc/stat values for delta calculation
    property var prevIdle: 0
    property var prevTotal: 0
    property bool hasPrev: false

    readonly property color iconColor: {
        if (root.cpuPercent >= root.criticalThreshold) return root.colCritical
        if (root.cpuPercent >= root.warningThreshold) return root.colWarning
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
            text: "\u{f0ee0}"  // nf-md-cpu_64_bit
        }

        Text {
            id: pctText
            visible: true
            font.family: root.fontFamily
            font.pixelSize: root.fontSize
            color: root.iconColor
            text: Math.round(root.cpuPercent) + "%"
        }
    }

    Process {
        id: statProc
        stdout: StdioCollector {
            onStreamFinished: {
                var line = this.text.trim()
                var parts = line.split(/\s+/)
                if (parts.length < 11) return

                var fields = []
                for (var i = 1; i <= 10; i++)
                    fields.push(parseInt(parts[i]))

                var idle = fields[3] + fields[4]
                var total = 0
                for (var j = 0; j < fields.length; j++)
                    total += fields[j]

                if (root.hasPrev) {
                    var dTotal = total - root.prevTotal
                    var dIdle = idle - root.prevIdle
                    if (dTotal > 0)
                        root.cpuPercent = (1.0 - dIdle / dTotal) * 100
                }

                root.prevIdle = idle
                root.prevTotal = total
                root.hasPrev = true
            }
        }
    }

    Timer {
        interval: root.pollInterval
        repeat: true
        running: true
        triggeredOnStart: true

        onTriggered: {
            if (!statProc.running) {
                statProc.exec({ command: ["head", "-1", "/proc/stat"] })
            }
        }
    }
}
