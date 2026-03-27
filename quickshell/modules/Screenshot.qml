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

    property var panelWindow

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
                popup.visible = !popup.visible
            }
        }

        Text {
            id: label
            anchors.centerIn: parent
            font.family: root.fontFamily
            font.pixelSize: root.fontSize
            color: "white"
            text: "\u{eada}"
        }
    }

    PopupWindow {
        id: popup
        visible: false

        anchor {
            window: root.panelWindow
            rect.x: root.mapToItem(root.panelWindow.contentItem, 0, 0).x - (popupContent.width - root.width) / 2
            rect.y: root.mapToItem(root.panelWindow.contentItem, 0, 0).y + root.height
            edges: Edges.Bottom
        }

        color: "transparent"

        Rectangle {
            id: popupContent
            width: menuColumn.width + 24
            height: menuColumn.height + 20
            color: Qt.rgba(17/255, 17/255, 27/255, 0.85)
            radius: 12
            border.width: 2
            border.color: Qt.rgba(205/255, 214/255, 244/255, 0.2)

            Column {
                id: menuColumn
                anchors.centerIn: parent
                spacing: 2

                Text {
                    text: "Screenshot"
                    font.family: root.fontFamily
                    font.pixelSize: 11
                    font.bold: true
                    color: Qt.rgba(1, 1, 1, 0.5)
                    leftPadding: 12
                    bottomPadding: 4
                }

                Repeater {
                    model: [
                        { label: "Fullscreen (clipboard)", cmd: "hyprshot -m output --clipboard-only" },
                        { label: "Region (clipboard)",     cmd: "hyprshot -m region --clipboard-only" },
                        { label: "Window (clipboard)",     cmd: "hyprshot -m window --clipboard-only" },
                        { label: "Fullscreen (save)",      cmd: "hyprshot -m output" },
                        { label: "Region (save)",          cmd: "hyprshot -m region" },
                        { label: "Window (save)",          cmd: "hyprshot -m window" }
                    ]

                    delegate: Rectangle {
                        id: entryBg
                        width: entryText.implicitWidth + 24
                        height: entryText.implicitHeight + 12
                        radius: 8
                        color: entryMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"

                        Text {
                            id: entryText
                            anchors.centerIn: parent
                            text: modelData.label
                            font.family: root.fontFamily
                            font.pixelSize: 13
                            color: "#cdd6f4"
                        }

                        MouseArea {
                            id: entryMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                popup.visible = false
                                screenshotProc.exec({ command: ["sh", "-c", modelData.cmd] })
                            }
                        }
                    }
                }
            }
        }

        Keys.onEscapePressed: {
            popup.visible = false
        }
    }

    Process { id: screenshotProc }
}
