import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 12

    property color hoverBg: "transparent"
    property int hoverRadius: 10
    property int paddingH: 5
    property int paddingV: 2

    implicitWidth: bg.width
    implicitHeight: bg.height

    Rectangle {
        id: bg
        width: label.implicitWidth + root.paddingH * 2
        height: label.implicitHeight + root.paddingV * 2
        radius: root.hoverRadius
        color: mouse.containsMouse ? root.hoverBg : "transparent"

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                screenshotMenu.exec({
                    command: ["sh", "-c",
                        'sel=$(echo -e "Fullscreen (clipboard)\\nRegion (clipboard)\\nWindow (clipboard)\\nFullscreen (save)\\nRegion (save)\\nWindow (save)" | tofi --prompt-text="Screenshot: "); ' +
                        'case "$sel" in ' +
                        '"Fullscreen (clipboard)") hyprshot -m output --clipboard-only ;; ' +
                        '"Region (clipboard)") hyprshot -m region --clipboard-only ;; ' +
                        '"Window (clipboard)") hyprshot -m window --clipboard-only ;; ' +
                        '"Fullscreen (save)") hyprshot -m output ;; ' +
                        '"Region (save)") hyprshot -m region ;; ' +
                        '"Window (save)") hyprshot -m window ;; ' +
                        'esac'
                    ]
                })
            }
        }

        Text {
            id: label
            anchors.centerIn: parent
            font.family: root.fontFamily
            font.pixelSize: root.fontSize
            color: "white"
            text: "\u{f03d8}"
        }
    }

    Process { id: screenshotMenu }
}
