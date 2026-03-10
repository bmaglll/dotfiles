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
                var space = Math.floor(root.width - (rightRow.implicitWidth + leftRow.implicitWidth))
                return Math.floor(space / vars.iFontSz)
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
                }

                CpuMonitor {
                    fontFamily: vars.fontFamily
                    fontSize: vars.iFontSz
                    pollInterval: 2000
                    showPercent: statusCluster.toggled || statusCluster.hovered || statusCluster.rightPressed
                }

                RamMonitor {
                    fontFamily: vars.fontFamily
                    fontSize: vars.iFontSz
                    pollInterval: 2000
                    showPercent: statusCluster.toggled || statusCluster.hovered || statusCluster.rightPressed
                }

                VolumeDisplay {
                    fontFamily: vars.fontFamily
                    fontSize: vars.iFontSz
		    pollInterval: 800
		    showPercent: statusCluster.toggled || statusCluster.hovered || statusCluster.rightPressed
                    }

                Battery {
                    vars: vars
                    fontFamily: vars.fontFamily
                    fontSize: vars.iFontSz
                    colCharging: "#00ff00"
                    colLow: "#ff5555"
                    colWarning: "#ffaa00"
                    showPercent: statusCluster.toggled || statusCluster.hovered || statusCluster.rightPressed
                }

                Clock {
		    id: clock
		    vars: vars
		    showExpanded: statusCluster.rightPressed
                }
            }
        }
    }
}
