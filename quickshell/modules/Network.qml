import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    // styling
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 12
    property int gap: 4

    // hover
    property color hoverBg: "transparent"
    property int hoverRadius: 10
    property int paddingH: 5
    property int paddingV: 2

    // polling
    property int pollInterval: 500

    // state
    property bool expanded: false
    property string ifaceName: ""
    property string ssid: ""
    property bool isWifi: false
    property real rxSpeed: 0.0
    property real txSpeed: 0.0
    property var prevRx: 0
    property var prevTx: 0
    property var prevTime: 0
    property bool hasPrev: false
    property string signalDbm: ""

    // NerdFont icons
    readonly property string wifiIcon: "\u{f1eb}"
    readonly property string ethernetIcon: "\u{f0200}"

    function formatSpeed(bytesPerSec) {
        if (bytesPerSec >= 1073741824)
            return (bytesPerSec / 1073741824).toFixed(1) + "GB/s"
        if (bytesPerSec >= 1048576)
            return (bytesPerSec / 1048576).toFixed(1) + "MB/s"
        if (bytesPerSec >= 1024)
            return (bytesPerSec / 1024).toFixed(1) + "KB/s"
        return bytesPerSec.toFixed(1) + "B/s"
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
            onClicked: root.expanded = !root.expanded
        }

        Row {
            id: row
            spacing: root.gap
            anchors.centerIn: parent

            Text {
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                color: "white"
                text: {
                    if (root.ifaceName === "") return ""
                    var label = root.isWifi && root.ssid !== "" ? root.ssid : root.ifaceName
                    return label
                }
                visible: root.ifaceName !== ""
            }

            Text {
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                color: "white"
                text: root.isWifi ? root.wifiIcon : root.ethernetIcon
                visible: root.ifaceName !== ""
            }

            Text {
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                color: "white"
                text: {
                    var parts = []
                    if (root.isWifi && root.signalDbm !== "")
                        parts.push("dBm " + root.signalDbm)
                    parts.push(root.ifaceName)
                    return ": " + parts.join(" : ") + " \u2193" + formatSpeed(root.rxSpeed) + " \u2191" + formatSpeed(root.txSpeed)
                }
                visible: root.expanded && root.ifaceName !== ""
            }
        }
    }

    // Detect active interface and connection name
    Process {
        id: ifaceProc
        stdout: StdioCollector {
            onStreamFinished: {
                var line = this.text.trim()
                var m = line.match(/dev\s+(\S+)/)
                if (m && m.length >= 2) {
                    root.ifaceName = m[1]
                    root.isWifi = (m[1].indexOf("wl") === 0)
                    if (!connNameProc.running)
                        connNameProc.exec({ command: ["nmcli", "-t", "-f", "NAME,DEVICE", "connection", "show", "--active"] })
                    if (root.isWifi && !signalProc.running)
                        signalProc.exec({ command: ["cat", "/proc/net/wireless"] })
                    else
                        root.signalDbm = ""
                }
            }
        }
    }

    Process {
        id: connNameProc
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n")
                root.ssid = ""
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split(":")
                    if (parts.length >= 2 && parts[1] === root.ifaceName) {
                        root.ssid = parts[0]
                        break
                    }
                }
            }
        }
    }

    Process {
        id: signalProc
        stdout: StdioCollector {
            onStreamFinished: {
                var m = this.text.match(/wlan\S*:\s+\S+\s+\S+\s+(-?\d+)\./)
                root.signalDbm = (m && m.length >= 2) ? m[1] : ""
            }
        }
    }

    // Read /proc/net/dev for throughput
    Process {
        id: netProc
        stdout: StdioCollector {
            onStreamFinished: {
                var now = Date.now()
                var lines = this.text.trim().split("\n")
                var totalRx = 0
                var totalTx = 0

                for (var i = 2; i < lines.length; i++) {
                    var line = lines[i].trim()
                    var colonIdx = line.indexOf(":")
                    if (colonIdx < 0) continue

                    var iface = line.substring(0, colonIdx).trim()
                    if (iface === "lo") continue

                    var fields = line.substring(colonIdx + 1).trim().split(/\s+/)
                    if (fields.length < 10) continue

                    totalRx += parseInt(fields[0])
                    totalTx += parseInt(fields[8])
                }

                if (root.hasPrev) {
                    var elapsed = (now - root.prevTime) / 1000
                    if (elapsed > 0) {
                        root.rxSpeed = (totalRx - root.prevRx) / elapsed
                        root.txSpeed = (totalTx - root.prevTx) / elapsed
                    }
                }

                root.prevRx = totalRx
                root.prevTx = totalTx
                root.prevTime = now
                root.hasPrev = true
            }
        }
    }

    // Poll interface/SSID every 5 seconds, throughput at pollInterval
    Timer {
        interval: 5000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            if (!ifaceProc.running)
                ifaceProc.exec({ command: ["ip", "route", "show", "default"] })
        }
    }

    Timer {
        interval: root.pollInterval
        repeat: true
        running: root.expanded
        triggeredOnStart: true
        onTriggered: {
            if (!netProc.running)
                netProc.exec({ command: ["cat", "/proc/net/dev"] })
        }
    }
}
