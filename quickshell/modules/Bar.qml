import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower

import "."

PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    anchors.top: true
    anchors.left: true
    anchors.right: true

    color: "#00ffffff"
    implicitHeight: 24

    // explicit state
    property bool mediaPopupVisible: false

    QtObject {
        id: vars
        readonly property color colWhite: "#ffffff"
        property string fontFamily: "JetBrainsMono Nerd Font"
        property int iFontSz: 12
    }

    RowLayout {
        id: bar
        anchors.fill: parent
        anchors.margins: 2
        spacing: 4

        // ----- LEFT -----
        RowLayout {
            id: leftBlocks
            Workspaces { vars: vars }
        }

        // ----- CENTER -----
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            spacing: 4

            Item {
                id: mprisAnchor
                Layout.alignment: Qt.AlignVCenter

                implicitWidth: mprisMini.implicitWidth
                implicitHeight: mprisMini.implicitHeight

                MprisMini {
                    id: mprisMini
                    anchors.fill: parent
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.mediaPopupVisible = !root.mediaPopupVisible;
                    }
                }
            }

            ActiveWindow {
                Layout.fillWidth: true
            }
        }

        // ----- RIGHT -----
        RowLayout {
            id: rightBlocks
            spacing: 4

            Tray { panelWindow: root }

            VolumeWidget {
                fontFamily: vars.fontFamily
                fontSize: vars.iFontSz
                wiremixCommand: ["ghostty", "-e", "wiremix"]
            }

            Battery {
                fontFamily: vars.fontFamily
                fontSize: vars.iFontSz
            }

            Clock { vars: vars }
        }
    }

    MediaPopup {
        id: mediaPopup
        anchorItem: mprisAnchor
        barWidth: bar.width
        popupHeight: 400
        widthRatio: 0.45
        show: root.mediaPopupVisible

        // close when clicking outside
        onRequestClose: {
            root.mediaPopupVisible = false;
        }
    }
}

