import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower

// sibling modules in the same dir
import "."

PanelWindow {
    id: root

    // injected by Variants in shell.qml
    required property var modelData
    screen: modelData

    anchors.top: true
    anchors.left: true
    anchors.right: true

    color: "#00ffffff"
    implicitHeight: 24

    // ---- Color & font variables ----
    QtObject {
        id: vars

        // Colors
        readonly property color colWhite:       "#ffffff"
        readonly property color lightSeaGreen:  "#a1ede8"
        readonly property color colLightGrey:   "#bbbababa"
        readonly property color colDarkGrey:    "#80606060"

        // Font settings
        property string fontFamily: "JetBrainsMono Nerd Font"
        property int iFontSz: 12
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 2
        spacing: 0

        // ----- LEFT: workspaces -----
        RowLayout {
            id: leftRow
            spacing: 0
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

            Workspaces {
                vars: vars
            }
        }

        // ----- CENTER: (empty for now) -----

 RowLayout {
            id: centerBlocks
            spacing: 4
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

            // Anchor for the popup
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
                    id: mprisHover
                    anchors.fill: parent
                    hoverEnabled: true
                }
            }

            ActiveWindow {
                Layout.leftMargin: 10
                Layout.fillWidth: true

                // Prevent overlap with left/right blocks
                chopLength: {
                    var space = Math.floor(bar.width - (rightBlocks.implicitWidth + leftBlocks.implicitWidth));
                    if (space < 0) {
                        space = 0;
                    }
                    var px = activeWindowTitleDisplay.font.pixelSize || 10;
                    return Math.floor(space / px);
                }
            }
        }


        // ----- RIGHT: tray + battery + clock -----
        RowLayout {
            id: rightRow
            spacing: 4
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

            Tray {
                panelWindow: root
            }

            VolumeWidget {
                Layout.alignment: Qt.AlignVCenter
                fontFamily: "JetBrainsMono Nerd Font"
                fontSize: 12
                // adjust if you prefer kitty or something else
                wiremixCommand: ["ghostty", "-e", "wiremix"]
            }
            Battery {
                fontFamily: vars.fontFamily
                fontSize: vars.iFontSz
                colNormal: vars.colWhite
                colCharging: "#00ff00"
                colLow: "#ff5555"
            }

            Clock {
                vars: vars
            }
        }
      }
    MediaPopup {
        id: mediaPopup
        anchorItem: mprisAnchor
        barWidth: root.width
        popupHeight: 400
        widthRatio: 0.4
        show: mprisHover.containsMouse
    }
}

