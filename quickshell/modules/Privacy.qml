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

    // hover
    property color hoverBg: "transparent"
    property int hoverRadius: 10
    property int paddingH: 5
    property int paddingV: 2

    // polling
    property int pollInterval: 2000

    // state
    property bool micActive: false
    property bool camActive: false
    readonly property bool anyActive: micActive || camActive

    visible: root.anyActive
    implicitWidth: root.anyActive ? bg.width : 0
    implicitHeight: root.anyActive ? bg.height : 0

    // flash animation when active
    opacity: flashAnim.running ? flashAnim.currentValue : 1.0
    SequentialAnimation {
        id: flashAnim
        running: root.anyActive
        loops: Animation.Infinite
        property real currentValue: 1.0
        NumberAnimation { target: flashAnim; property: "currentValue"; from: 1.0; to: 0.3; duration: 600 }
        NumberAnimation { target: flashAnim; property: "currentValue"; from: 0.3; to: 1.0; duration: 600 }
    }

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
                visible: root.micActive
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                color: root.colAlert
                text: ""
            }

            Text {
                visible: root.camActive
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                color: root.colAlert
                text: ""
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
                var camMatch = s.match(/cam:(\d+)/)
                root.micActive = (micMatch !== null && parseInt(micMatch[1]) > 0)
                root.camActive = (vidMatch !== null && parseInt(vidMatch[1]) > 0)
                                 || (camMatch !== null && parseInt(camMatch[1]) > 0)
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
                        "vid=$(echo \"$pw_out\" | grep -c 'media.class = \"Stream/Input/Video\"'); " +
                        "cam=$(awk '/^uvcvideo/{print $3}' /proc/modules 2>/dev/null); " +
                        "echo \"mic:${mic:-0} vid:${vid:-0} cam:${cam:-0}\""
                    ]
                })
            }
        }
    }
}
