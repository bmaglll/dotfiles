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
            id: centerRow
            spacing: 4
            Layout.fillWidth: true
	    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

	    MprisMini {

	    }

            ActiveWindow {
              Layout.leftMargin: 10
              Layout.fillWidth: true // Allow it to take up the middle space
            
              // This calculation ensures the title doesn't overlap other blocks
              chopLength: {
                var space = Math.floor(bar.width - (rightBlocks.implicitWidth + leftBlocks.implicitWidth))
                // You may need to adjust the divisor (e.g., /8 or /10) based on font size.
                return Math.floor(space / activeWindowTitleDisplay.font.pixelSize); 
              }
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
  }


