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
    property color colAlert: "#ff5555"
    property color colNormal: "white"
    property color colDisconnected: "#606060"

    // hover
    property color hoverBg: "transparent"
    property int hoverRadius: 10
    property int paddingH: 5
    property int paddingV: 2

    // polling
    property int pollInterval: 2000

    // state
    property bool micConnected: false
    property bool micActive: false
    property bool camConnected: false
    property bool camActive: false
    readonly property bool anyActive: micActive || camActive

    Layout.alignment: Qt.AlignVCenter
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
            acceptedButtons: Qt.NoButton
        }

        Row {
            id: row
            spacing: root.gap
            anchors.centerIn: parent

            Text {
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                color: root.micActive ? root.colAlert
                     : root.micConnected ? root.colNormal
                     : root.colDisconnected
                text: root.micConnected ? "\uf130" : "\uf131"
                opacity: micFlash.running ? micFlash.currentValue : 1.0

                SequentialAnimation {
                    id: micFlash
                    running: root.micActive
                    loops: Animation.Infinite
                    property real currentValue: 1.0
                    NumberAnimation { target: micFlash; property: "currentValue"; from: 1.0; to: 0.3; duration: 600 }
                    NumberAnimation { target: micFlash; property: "currentValue"; from: 0.3; to: 1.0; duration: 600 }
                }
            }

            Text {
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                color: root.camActive ? root.colAlert
                     : root.camConnected ? root.colNormal
                     : root.colDisconnected
                text: root.camConnected ? "\uf03d" : "󰗆"
                opacity: camFlash.running ? camFlash.currentValue : 1.0

                SequentialAnimation {
                    id: camFlash
                    running: root.camActive
                    loops: Animation.Infinite
                    property real currentValue: 1.0
                    NumberAnimation { target: camFlash; property: "currentValue"; from: 1.0; to: 0.3; duration: 600 }
                    NumberAnimation { target: camFlash; property: "currentValue"; from: 0.3; to: 1.0; duration: 600 }
                }
            }
        }
    }

    Process {
        id: privacyProc
        stdout: StdioCollector {
            onStreamFinished: {
                var s = this.text.trim()
                var micMatch = s.match(/mic:(\d+)/)
                var vidMatch = s.match(/vid:(\d+)/)
                var micHwMatch = s.match(/mic_hw:(\d+)/)
                var camHwMatch = s.match(/cam_hw:(\d+)/)

                root.micConnected = (micHwMatch !== null && parseInt(micHwMatch[1]) > 0)
                root.micActive = (micMatch !== null && parseInt(micMatch[1]) > 0)

                root.camConnected = (camHwMatch !== null && parseInt(camHwMatch[1]) > 0)
                root.camActive = (vidMatch !== null && parseInt(vidMatch[1]) > 0)

                console.log("Privacy:", s, "micConn:", root.micConnected, "camConn:", root.camConnected, "micAct:", root.micActive, "camAct:", root.camActive)
            }
        }
    }

    Timer {
        interval: root.pollInterval
        repeat: true
        running: true
        triggeredOnStart: true

        onTriggered: {
            if (!privacyProc.running) {
                privacyProc.exec({
                    command: ["sh", "-c",
                        "pw_out=$(pw-cli list-objects Node 2>/dev/null); " +
                        "mic=$(echo \"$pw_out\" | grep -c 'media.class = \"Stream/Input/Audio\"'); " +
                        "vid=$(ls -la /proc/[0-9]*/fd/* 2>/dev/null | grep -c /dev/video); " +
                        "mic_hw=$(echo \"$pw_out\" | grep -c 'media.class = \"Audio/Source\"'); " +
                        "cam_hw=$(ls /dev/video* 2>/dev/null | wc -l); " +
                        "echo \"mic:${mic:-0} vid:${vid:-0} mic_hw:${mic_hw:-0} cam_hw:${cam_hw:-0}\""
                    ]
                })
            }
        }
    }
}
