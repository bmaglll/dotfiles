import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    // Reap any inhibitor orphaned by a previous quickshell session (or the
    // old detached-sleep implementation) so we never start with a stuck lid
    // lock, then refresh status once it's done.
    Component.onCompleted: cleanupProc.exec({ command: ["bash", root.helperScript, "cleanup"] })

    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 12
    property int gap: 6
    property var panelWindow

    property color colNormal: "#8f8f8f"
    property color colActive: "#ffaa00"
    property color colIndefinite: "#ff5555"

    property color hoverBg: "transparent"
    property int hoverRadius: 10
    property int paddingH: 5
    property int paddingV: 2

    property int durationSeconds: 3600
    property int pollInterval: 1000

    property bool active: false
    property int remainingSeconds: 0
    property string mode: "off"

    readonly property string helperScript: Qt.resolvedUrl("keep-awake.sh").toString().replace("file://", "")
    readonly property string remainingLabel: {
        if (!root.active)
            return ""
        if (root.mode === "indefinite")
            return "off"

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
                popup.visible = !popup.visible
            }
        }

        Row {
            id: row
            spacing: root.gap
            anchors.centerIn: parent

            Text {
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                color: root.mode === "indefinite"
                    ? root.colIndefinite
                    : root.active ? root.colActive : root.colNormal
                text: "\uf0f4"
            }

            Text {
                visible: root.active
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                color: root.mode === "indefinite" ? root.colIndefinite : root.colActive
                text: root.remainingLabel
            }
        }
    }

    PopupWindow {
        id: popup
        visible: false
        width: 220
        height: popupContent.height
        color: "transparent"

        anchor {
            window: root.panelWindow
            edges: Edges.Top | Edges.Left
            gravity: Edges.Bottom | Edges.Right
            onAnchoring: {
                var pos = root.mapToItem(root.panelWindow.contentItem, 0, 0)
                anchor.rect.x = pos.x + (root.width / 2) - (popup.width / 2)
                anchor.rect.y = pos.y + root.height
            }
        }

        Rectangle {
            id: popupContent
            width: popup.width
            height: menuColumn.height + 20
            color: Qt.rgba(17 / 255, 17 / 255, 27 / 255, 0.85)
            radius: 12
            border.width: 2
            border.color: Qt.rgba(205 / 255, 214 / 255, 244 / 255, 0.2)

            Column {
                id: menuColumn
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 10
                spacing: 2

                Text {
                    text: {
                        if (root.mode === "indefinite")
                            return "Keep Awake: auto-lock off"
                        if (root.active)
                            return "Keep Awake: " + root.remainingLabel + " left"
                        return "Keep Awake"
                    }
                    font.family: root.fontFamily
                    font.pixelSize: 11
                    font.bold: true
                    color: Qt.rgba(1, 1, 1, 0.5)
                    leftPadding: 4
                    bottomPadding: 2
                }

                Repeater {
                    model: [
                        { label: "5 seconds", seconds: 5, action: "start" },
                        { label: "30 minutes", seconds: 1800, action: "start" },
                        { label: "1 hour", seconds: 3600, action: "start" },
                        { label: "2 hours", seconds: 7200, action: "start" },
                        { label: "4 hours", seconds: 14400, action: "start" },
                        { label: "8 hours", seconds: 28800, action: "start" },
                        { label: "Auto-lock off", seconds: 0, action: "indefinite" },
                        { label: "Restore normal idle", seconds: 0, action: "stop" }
                    ]

                    delegate: Rectangle {
                        width: menuColumn.width
                        height: entryText.implicitHeight + 12
                        radius: 8
                        color: entryMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"

                        Text {
                            id: entryText
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            text: modelData.label
                            font.family: root.fontFamily
                            font.pixelSize: 13
                            color: modelData.action === "stop"
                                ? "#a6e3a1"
                                : modelData.action === "indefinite" ? "#f38ba8" : "#cdd6f4"
                        }

                        MouseArea {
                            id: entryMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: !toggleProc.running
                            onClicked: {
                                popup.visible = false

                                var command
                                if (modelData.action === "start")
                                    command = ["bash", root.helperScript, "start", String(modelData.seconds)]
                                else if (modelData.action === "indefinite")
                                    command = ["bash", root.helperScript, "start", "indefinite"]
                                else
                                    command = ["bash", root.helperScript, "stop"]

                                toggleProc.exec({ command: command })
                            }
                        }
                    }
                }
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
                var modeMatch = s.match(/mode:(\w+)/)

                root.active = activeMatch !== null && parseInt(activeMatch[1]) > 0
                root.remainingSeconds = remainingMatch !== null ? parseInt(remainingMatch[1]) : 0
                root.mode = modeMatch !== null ? modeMatch[1] : "off"
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

    Process {
        id: cleanupProc
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
