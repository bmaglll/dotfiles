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

    // hover
    property color hoverBg: "transparent"
    property int hoverRadius: 10
    property int paddingH: 6
    property int paddingV: 2

    // polling
    property int pollInterval: 2000

    // thresholds (percentage)
    property real warningThreshold: 70
    property real criticalThreshold: 90

    // CPU state
    property real cpuPercent: 0.0
    property var prevIdle: 0
    property var prevTotal: 0
    property bool hasPrev: false

    // RAM state
    property real ramPercent: 0.0

    readonly property color cpuColor: {
        if (root.cpuPercent >= root.criticalThreshold) return root.colCritical
        if (root.cpuPercent >= root.warningThreshold) return root.colWarning
        return root.colNormal
    }

    readonly property color ramColor: {
        if (root.ramPercent >= root.criticalThreshold) return root.colCritical
        if (root.ramPercent >= root.warningThreshold) return root.colWarning
        return root.colNormal
    }

    implicitWidth: bg.width
    implicitHeight: bg.height

    Rectangle {
        id: bg
        width: row.implicitWidth + root.paddingH * 2
        height: row.implicitHeight + root.paddingV * 2
        radius: root.hoverRadius
        color: mouse.containsMouse ? root.hoverBg : "transparent"

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                btopLauncher.exec({ command: ["hyprctl", "dispatch", "exec", "[float;size 80% 80%;center] ghostty -e btop"] })
            }
        }

        Row {
            id: row
            spacing: root.gap
            anchors.centerIn: parent

            Text {
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                color: root.cpuColor
                text: "\u{f0ee0}"
            }

            Text {
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                color: root.cpuColor
                text: Math.round(root.cpuPercent) + "%"
            }

            Text {
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                color: root.ramColor
                text: "\u{efc5}"
            }

            Text {
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                color: root.ramColor
                text: Math.round(root.ramPercent) + "%"
            }
        }
    }

    Process { id: btopLauncher }

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
            if (!statProc.running)
                statProc.exec({ command: ["head", "-1", "/proc/stat"] })
            if (!memProc.running)
                memProc.exec({ command: ["head", "-3", "/proc/meminfo"] })
        }
    }
}
