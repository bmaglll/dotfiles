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

        // Hover effect
        readonly property color hoverBg:   Qt.rgba(1, 1, 1, 0.12)
        readonly property color pressedBg: Qt.rgba(1, 1, 1, 0.16)
        readonly property int hoverRadius: 10
    }

    Item {
        anchors.fill: parent
        anchors.margins: 2

        // ----- LEFT: workspaces -----
        RowLayout {
            id: leftRow
            spacing: 0
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            Workspaces {
                vars: vars
            }

            MprisMini {
                vars: vars
            }
        }

        // ----- CENTER: clock -----
        RowLayout {
            id: centerRow
            spacing: 4
            anchors.centerIn: parent

            Clock {
                id: clock
                vars: vars
            }
        }

        // ----- RIGHT: tray + status -----
        RowLayout {
            id: rightRow
            spacing: 8
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            Tray {
                panelWindow: root
            }

            CpuMonitor {
                fontFamily: vars.fontFamily
                fontSize: vars.iFontSz
                pollInterval: 2000
            }

            RamMonitor {
                fontFamily: vars.fontFamily
                fontSize: vars.iFontSz
                pollInterval: 2000
            }

            VolumeDisplay {
                fontFamily: vars.fontFamily
                fontSize: vars.iFontSz
                pollInterval: 800
            }

            Battery {
                vars: vars
                fontFamily: vars.fontFamily
                fontSize: vars.iFontSz
                colCharging: "#00ff00"
                colLow: "#ff5555"
                colWarning: "#ffaa00"
            }
        }
    }
}
