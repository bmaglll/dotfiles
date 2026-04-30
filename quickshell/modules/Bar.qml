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
    required property var buddyModel
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

        // ----- Agent Buddy walk area -----
        Item {
            id: buddyArea
            anchors.left: leftRow.right
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            width: buddyRepeater.count > 0 ? 120 : 0
            height: parent.height

            function getSiblingPositions(excludeFile) {
                var positions = []
                for (var i = 0; i < buddyRepeater.count; i++) {
                    var item = buddyRepeater.itemAt(i)
                    if (item && item.stateFile !== excludeFile)
                        positions.push(item.x)
                }
                return positions
            }

            Repeater {
                id: buddyRepeater
                model: root.buddyModel

                AgentBuddy {
                    vars: vars
                    stateFile: model.filePath
                    walkAreaWidth: buddyArea.width
                    siblingPositions: function() { return buddyArea.getSiblingPositions(model.filePath) }
                }
            }
        }

        // ----- CENTER: clock -----
        RowLayout {
            id: centerRow
            spacing: 4
            anchors.verticalCenter: parent.verticalCenter
            x: Math.max(
                buddyArea.x + buddyArea.width + 8,
                Math.min(
                    (parent.width - width) / 2,
                    rightRow.x - width - 8
                )
            )

            Clock {
                id: clock
                vars: vars
            }

            Screenshot {
                fontFamily: vars.fontFamily
                fontSize: vars.iFontSz
                hoverBg: vars.hoverBg
                hoverRadius: vars.hoverRadius
                panelWindow: root
            }
        }

        // ----- RIGHT: tray + status -----
        RowLayout {
            id: rightRow
            spacing: 4
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            Tray {
                panelWindow: root
            }

            Privacy {
                fontFamily: vars.fontFamily
                fontSize: vars.iFontSz
                pollInterval: 2000
                hoverBg: vars.hoverBg
                hoverRadius: vars.hoverRadius
            }

            Network {
                fontFamily: vars.fontFamily
                fontSize: vars.iFontSz
                pollInterval: 500
                hoverBg: vars.hoverBg
                hoverRadius: vars.hoverRadius
            }

            Resources {
                fontFamily: vars.fontFamily
                fontSize: vars.iFontSz
                pollInterval: 2000
                hoverBg: vars.hoverBg
                hoverRadius: vars.hoverRadius
            }

            VolumeDisplay {
                fontFamily: vars.fontFamily
                fontSize: vars.iFontSz
                pollInterval: 800
                hoverBg: vars.hoverBg
                hoverRadius: vars.hoverRadius
            }

            Battery {
                vars: vars
                fontFamily: vars.fontFamily
                fontSize: vars.iFontSz
                colCharging: "#00ff00"
                colLow: "#ff5555"
                colWarning: "#ffaa00"
                hoverBg: vars.hoverBg
                hoverRadius: vars.hoverRadius
            }
        }
    }
}
