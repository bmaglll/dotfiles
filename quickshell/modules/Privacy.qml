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
    property color colAmber: "#ffaa00"
    property color colNormal: "white"
    property color colDisconnected: "#606060"

    // hover
    property color hoverBg: "transparent"
    property int hoverRadius: 10
    property int paddingH: 5
    property int paddingV: 2

    // polling
    property int pollInterval: 2000

    // mic state
    property bool micHwPresent: false   // Audio/Source exists in PipeWire
    property bool micHwOn: true         // hardware switch allows signal (fail-open)
    property bool micMuted: false       // software mute via wpctl
    property bool micActive: false      // Stream/Input/Audio exists
    property int micHwOffStreak: 0      // consecutive "off" reads from framework-mic-switch
    readonly property int micHwOffThreshold: 3

    // cam state
    property bool camConnected: false
    property bool camActive: false

    readonly property bool anyActive: micActive || camActive
    readonly property bool allOff: !micHwOn && !camConnected

    visible: !allOff
    Layout.alignment: Qt.AlignVCenter
    implicitWidth: allOff ? 0 : bg.width
    implicitHeight: allOff ? 0 : bg.height

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

            // Mic icon — 6 states
            Text {
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                text: (!root.micHwOn || root.micMuted) ? "\uf131" : "\uf130"
                color: {
                    if (!root.micHwOn)
                        return root.colDisconnected
                    if (root.micMuted)
                        return root.colAmber
                    if (root.micActive)
                        return root.colAlert
                    return root.colNormal
                }
                opacity: micFlash.running ? micFlash.currentValue : 1.0

                SequentialAnimation {
                    id: micFlash
                    running: root.micActive && root.micHwOn
                    loops: Animation.Infinite
                    property real currentValue: 1.0
                    NumberAnimation { target: micFlash; property: "currentValue"; from: 1.0; to: 0.3; duration: 600 }
                    NumberAnimation { target: micFlash; property: "currentValue"; from: 0.3; to: 1.0; duration: 600 }
                }
            }

            // Cam icon
            Text {
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                color: root.camActive ? root.colAlert
                     : root.camConnected ? root.colNormal
                     : root.colDisconnected
                text: root.camConnected ? "\uf03d" : "\uedad"
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
                var micMuteMatch = s.match(/mic_mute:(\d+)/)
                var hwSwitchMatch = s.match(/hw_switch:(\w+)/)

                root.micHwPresent = (micHwMatch !== null && parseInt(micHwMatch[1]) > 0)
                root.micActive = (micMatch !== null && parseInt(micMatch[1]) > 0)
                root.micMuted = (micMuteMatch !== null && parseInt(micMuteMatch[1]) > 0)
                // If software muted, capture reads silence — can't detect hw switch, assume on
                // Otherwise debounce: require N consecutive "off" reads before declaring off,
                // since a quiet room also reads as silence.
                var rawHwOff = (hwSwitchMatch !== null && hwSwitchMatch[1] === "off")
                if (root.micMuted) {
                    root.micHwOffStreak = 0
                    root.micHwOn = true
                } else if (rawHwOff) {
                    root.micHwOffStreak = root.micHwOffStreak + 1
                    if (root.micHwOffStreak >= root.micHwOffThreshold)
                        root.micHwOn = false
                } else {
                    root.micHwOffStreak = 0
                    root.micHwOn = true
                }

                root.camConnected = (camHwMatch !== null && parseInt(camHwMatch[1]) > 0)
                root.camActive = (vidMatch !== null && parseInt(vidMatch[1]) > 0)

                //console.log("Privacy:", s, "micHwOn:", root.micHwOn, "micMuted:", root.micMuted, "micAct:", root.micActive, "camConn:", root.camConnected, "camAct:", root.camActive)
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
                        "mic_mute=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep -c MUTED); " +
                        "hw_switch=$(framework-mic-switch 2>/dev/null || echo 'hw_switch:error'); " +
                        "echo \"mic:${mic:-0} vid:${vid:-0} mic_hw:${mic_hw:-0} cam_hw:${cam_hw:-0} mic_mute:${mic_mute:-0} ${hw_switch}\""
                    ]
                })
            }
        }
    }
}
