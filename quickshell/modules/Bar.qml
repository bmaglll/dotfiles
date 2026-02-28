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

    // Settings dropdown popup
    PopupWindow {
        id: settingsPopup
        color: "transparent"
        anchor.window: root

        implicitWidth: settingsDropdown.width
        implicitHeight: settingsDropdown.height

        anchor.rect: Qt.rect(
            root.width - settingsDropdown.width - 8,
            root.implicitHeight + 4,
            settingsDropdown.width,
            settingsDropdown.height
        )

        visible: statusCluster.toggled

        onVisibleChanged: {
            console.log("settingsPopup visible:", visible)
            console.log("  anchor.window:", anchor.window)
            console.log("  implicitWidth:", implicitWidth, "implicitHeight:", implicitHeight)
            console.log("  dropdown size:", settingsDropdown.width, "x", settingsDropdown.height)
        }

        SettingsDropdown {
            id: settingsDropdown
            fontFamily: vars.fontFamily
            fontSize: vars.iFontSz
        }
    }

    // Click-outside-to-close handler
    HyprlandFocusGrab {
        id: focusGrab
        windows: [settingsPopup]
        active: statusCluster.toggled

        onCleared: {
            statusCluster.toggled = false
        }
    }

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

        // ----- RIGHT: tray + battery + clock -----
        RowLayout {
            id: rightRow
            spacing: 4
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

            Tray {
                panelWindow: root
            }

	    StatusCluster {
		id: statusCluster
                fontFamily: vars.fontFamily
                fontSize: vars.iFontSz

                // optional styling tweaks
                hoverBg: Qt.rgba(1, 1, 1, 0.12)
                radius: 10
                paddingX: 10
                paddingY: 2
                innerSpacing: 8

                onClicked: function(btn) {
                    console.log("StatusCluster clicked, button:", btn)
                    console.log("  statusCluster.toggled is now:", statusCluster.toggled)
                }

                VolumeDisplay {
                    fontFamily: vars.fontFamily
                    fontSize: vars.iFontSz
		    pollInterval: 800
		    showPercent: statusCluster.toggled || statusCluster.hovered
                    }

                Battery {
                    fontFamily: vars.fontFamily
                    fontSize: vars.iFontSz
                    colNormal: vars.colWhite
                    colCharging: "#00ff00"
                    colLow: "#ff5555"
                    showPercent: statusCluster.toggled || statusCluster.hovered
                }

                Clock {
		    id: clock
		    vars: vars
                }
            }
        }
    }
}
