import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 12
    property var panelWindow

    property color hoverBg: "transparent"
    property int hoverRadius: 10
    property int paddingH: 5
    property int paddingV: 2

    property int pollInterval: 30000
    property int fetchInterval: 300000

    property string repoPath: "/home/bmag/nixos-config"

    // Raw state
    property string systemRev: ""
    property string headRev: ""
    property string headShort: ""
    property string headSubject: ""
    property string headBody: ""
    property string headRelTime: ""
    property bool dirty: false
    property int localAhead: 0
    property int originAhead: 0
    property bool hasUpstream: true

    readonly property bool systemMatchesHead: systemRev.length > 0 && headRev.length > 0
                                              && systemRev.indexOf(headRev.substring(0, 12)) === 0

    // Derived status: one of synced | buildOnly | dirty | ahead | behind | diverged | unknown
    readonly property string status: {
        if (headRev === "")
            return "unknown"
        if (dirty)
            return "dirty"
        if (hasUpstream && localAhead > 0 && originAhead > 0)
            return "diverged"
        if (hasUpstream && originAhead > 0)
            return "behind"
        if (hasUpstream && localAhead > 0)
            return "ahead"
        if (!systemMatchesHead)
            return "buildOnly"
        return "synced"
    }

    readonly property color statusColor: {
        switch (status) {
            case "synced":    return "#a6e3a1"
            case "buildOnly": return "#f9e2af"
            case "dirty":     return "#f9e2af"
            case "ahead":     return "#f9e2af"
            case "behind":    return "#f38ba8"
            case "diverged":  return "#f38ba8"
        }
        return "#8f8f8f"
    }

    readonly property string statusMessage: {
        switch (status) {
            case "synced":    return "In sync"
            case "buildOnly": return "Rebuild needed — run: nx build"
            case "dirty":     return "Uncommitted changes — run: nx push"
            case "ahead":     return "Ahead of origin by " + localAhead + " — run: nx push"
            case "behind":    return "Behind origin by " + originAhead + " — run: nx pull"
            case "diverged":  return "Diverged from origin (" + localAhead + " ahead, " + originAhead + " behind) — resolve manually"
        }
        return "Loading…"
    }

    implicitWidth: bg.width
    implicitHeight: bg.height

    Rectangle {
        id: bg
        width: iconText.implicitWidth + root.paddingH * 2
        height: iconText.implicitHeight + root.paddingV * 2
        radius: root.hoverRadius
        color: mouse.containsMouse ? root.hoverBg : "transparent"

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: popup.visible = !popup.visible
        }

        Text {
            id: iconText
            anchors.centerIn: parent
            font.family: root.fontFamily
            font.pixelSize: root.fontSize
            font.bold: true
            color: root.statusColor
            text: ""
        }
    }

    PopupWindow {
        id: popup
        visible: false
        width: 320
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
                spacing: 4

                Text {
                    text: root.statusMessage
                    font.family: root.fontFamily
                    font.pixelSize: 11
                    font.bold: true
                    color: root.statusColor
                    leftPadding: 4
                    wrapMode: Text.WordWrap
                    width: menuColumn.width
                }

                Rectangle {
                    width: menuColumn.width
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.1)
                }

                Rectangle {
                    id: commitRow
                    width: menuColumn.width
                    height: commitCol.implicitHeight + 12
                    radius: 8
                    color: commitMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

                    Column {
                        id: commitCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 2

                        Text {
                            text: root.headShort + "  " + (commitMouse.containsMouse && root.headBody.length > 0
                                                           ? root.headBody
                                                           : root.headSubject)
                            font.family: root.fontFamily
                            font.pixelSize: 12
                            color: "#cdd6f4"
                            wrapMode: Text.WordWrap
                            width: commitCol.width
                        }

                        Text {
                            text: root.headRelTime
                            font.family: root.fontFamily
                            font.pixelSize: 10
                            color: Qt.rgba(1, 1, 1, 0.5)
                        }
                    }

                    MouseArea {
                        id: commitMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                }
            }
        }
    }

    Process {
        id: sysRevProc
        stdout: StdioCollector {
            onStreamFinished: {
                var s = this.text.trim()
                root.systemRev = (s === "unknown" || s === "") ? "" : s
            }
        }
    }

    Process {
        id: headProc
        stdout: StdioCollector {
            onStreamFinished: {
                var s = this.text
                if (s.length === 0) return
                // fields separated by \x1f (unit separator), records by \n at end
                var parts = s.replace(/\n$/, "").split("\x1f")
                if (parts.length >= 5) {
                    root.headRev = parts[0]
                    root.headShort = parts[1]
                    root.headSubject = parts[2]
                    root.headBody = parts[3].trim()
                    root.headRelTime = parts[4]
                }
            }
        }
    }

    Process {
        id: dirtyProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.dirty = this.text.trim().length > 0
            }
        }
    }

    Process {
        id: divergeProc
        stdout: StdioCollector {
            onStreamFinished: {
                var s = this.text.trim()
                if (s.length === 0) {
                    root.hasUpstream = false
                    root.localAhead = 0
                    root.originAhead = 0
                    return
                }
                var parts = s.split(/\s+/)
                if (parts.length >= 2) {
                    root.hasUpstream = true
                    root.localAhead = parseInt(parts[0]) || 0
                    root.originAhead = parseInt(parts[1]) || 0
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.indexOf("no upstream") >= 0)
                    root.hasUpstream = false
            }
        }
    }

    Process {
        id: fetchProc
        onRunningChanged: {
            if (!running && !divergeProc.running)
                divergeProc.exec({
                    command: ["git", "-C", root.repoPath, "rev-list",
                              "--left-right", "--count", "HEAD...@{u}"]
                })
        }
    }

    function pollLocal() {
        if (!sysRevProc.running)
            sysRevProc.exec({ command: ["nixos-version", "--configuration-revision"] })
        if (!headProc.running)
            headProc.exec({
                command: ["git", "-C", root.repoPath, "log", "-1",
                          "--format=%H\x1f%h\x1f%s\x1f%B\x1f%cr"]
            })
        if (!dirtyProc.running)
            dirtyProc.exec({ command: ["git", "-C", root.repoPath, "status", "--porcelain"] })
        if (!divergeProc.running)
            divergeProc.exec({
                command: ["git", "-C", root.repoPath, "rev-list",
                          "--left-right", "--count", "HEAD...@{u}"]
            })
    }

    Timer {
        interval: root.pollInterval
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.pollLocal()
    }

    Timer {
        interval: root.fetchInterval
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            if (!fetchProc.running)
                fetchProc.exec({ command: ["git", "-C", root.repoPath, "fetch", "--quiet"] })
        }
    }
}
