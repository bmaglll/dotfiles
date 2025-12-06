//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Hyprland
import QtQuick.Layouts
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower

import "modules"

PanelWindow {
    id: root

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

    anchors.top: true
    anchors.left: true
    anchors.right: true

    color: "#00ffffff"
    implicitHeight: 24

    RowLayout {
        anchors.fill: parent
        anchors.margins: 2
        spacing: 0

        // ----- LEFT: workspaces -----
        RowLayout {
            id: leftRow
            spacing: 0
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

            WorkspacesBar {
                vars: vars
            }
        }

        // ----- CENTER: placeholder row (for future modules) -----
        RowLayout {
            id: centerRow
            spacing: 4
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

            // add center modules later if you want
        }

        // ----- RIGHT: tray + battery + clock -----
        RowLayout {
            id: rightRow
            spacing: 4
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

            TrayBar {
                panelWindow: root
            }

            BatteryWidget {
                fontFamily: vars.fontFamily
                fontSize: vars.iFontSz
                colNormal: vars.colWhite
                colCharging: "#00ff00"
                colLow: "#ff5555"
            }

            ClockWidget {
                vars: vars
            }
        }
    }
}

