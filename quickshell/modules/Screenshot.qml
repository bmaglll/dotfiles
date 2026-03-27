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
        width: 230
        height: popupContent.height
        color: "transparent"
        grabFocus: true

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
            color: Qt.rgba(17/255, 17/255, 27/255, 0.85)
            radius: 12
            border.width: 2
            border.color: Qt.rgba(205/255, 214/255, 244/255, 0.2)

            Column {
                id: menuColumn
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 10
                spacing: 2

                Text {
                    text: "Screenshot"
                    font.family: root.fontFamily
                    font.pixelSize: 11
                    font.bold: true
                    color: Qt.rgba(1, 1, 1, 0.5)
                    leftPadding: 4
                    bottomPadding: 2
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
    }

    Process { id: screenshotProc }
}
