import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 12
    property int gap: 6

    property color colNormal: "white"
    property color colActive: "#ffaa00"

    property color hoverBg: "transparent"
    property int hoverRadius: 10
    property int paddingH: 5
    property int paddingV: 2

    property int durationSeconds: 3600
    property int pollInterval: 1000

    property bool active: false
    property int remainingSeconds: 0

    readonly property string helperScript: Qt.resolvedUrl("keep-awake.sh").toString().replace("file://", "")
    readonly property string remainingLabel: {
        if (!root.active)
            return ""

        var totalMinutes = Math.ceil(root.remainingSeconds / 60)
        if (totalMinutes >= 60) {
            var hours = Math.floor(totalMinutes / 60)
            var minutes = totalMinutes % 60
            return minutes > 0 ? hours + "h " + minutes + "m" : hours + "h"
        }

        return totalMinutes + "m"
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
                if (toggleProc.running)
                    return

                var action = root.active ? "stop" : "start"
                var command = action === "start"
                    ? ["bash", root.helperScript, action, String(root.durationSeconds)]
                    : ["bash", root.helperScript, action]

                toggleProc.exec({ command: command })
            }
        }

        Row {
            id: row
            spacing: root.gap
            anchors.centerIn: parent

            Text {
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                color: root.active ? root.colActive : root.colNormal
                text: "\uf0f4"
            }

            Text {
                visible: root.active
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                color: root.colActive
                text: root.remainingLabel
            }
        }
    }

    Process {
        id: statusProc
        stdout: StdioCollector {
            onStreamFinished: {
                var s = this.text.trim()
                var activeMatch = s.match(/active:(\d+)/)
                var remainingMatch = s.match(/remaining:(\d+)/)

                root.active = activeMatch !== null && parseInt(activeMatch[1]) > 0
                root.remainingSeconds = remainingMatch !== null ? parseInt(remainingMatch[1]) : 0
            }
        }
    }

    Process {
        id: toggleProc
        onRunningChanged: {
            if (!running && !statusProc.running)
                statusProc.exec({ command: ["bash", root.helperScript, "status"] })
        }
    }

    Timer {
        interval: root.pollInterval
        repeat: true
        running: true
        triggeredOnStart: true

        onTriggered: {
            if (!statusProc.running)
                statusProc.exec({ command: ["bash", root.helperScript, "status"] })
        }
    }
}
