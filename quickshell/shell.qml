//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Hyprland
import QtQuick.Layouts
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower



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

        // ----- LEFT: workspaces -----
        Repeater {
            model: 5

            Text {
                property var ws: Hyprland.workspaces.values.find(w => w.id == index + 1)
                property bool isActive: Hyprland.focusedWorkspace?.id == (index + 1)

                text: index + 1

                color: isActive
                       ? vars.colWhite
                       : (ws ? vars.colLightGrey : vars.colDarkGrey)

                font.family: vars.fontFamily
                font.pixelSize: vars.iFontSz
                font.bold: true

                MouseArea {
                    anchors.fill: parent
                    onClicked: Hyprland.dispatch("workspace " + (index + 1))
                }
            }
        }

        // ----- CENTER: spacer -----
        Item {
            Layout.fillWidth: true
        }

        // ----- RIGHT: system tray + clock -----
        RowLayout {
            spacing: 4
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

            // System tray
            Repeater {
                model: SystemTray.items

                delegate: Item {
                    id: trayItem
                    width: 22
                    height: 22

                    // Raise icons 2px
                    y: -2

                    Image {
                        anchors.fill: parent
                        anchors.margins: 2
                        source: modelData.icon
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }

                    MouseArea {
    			anchors.fill: parent
    			acceptedButtons: Qt.LeftButton | Qt.RightButton

    			onClicked: function(mouse) {
        			if (mouse.button === Qt.LeftButton) {
            				// primary action
            				modelData.activate()
            				return
        			}

        			if (mouse.button === Qt.RightButton && modelData.hasMenu) {
                			// Map click position on trayItem → window content coordinates
                			var p = trayItem.mapToItem(root.contentItem, mouse.x, mouse.y)		             				// Put menu just below the icon, near the click
               				var menuX = Math.round(p.x)
                			var menuY = Math.round(p.y + trayItem.height)

					// parent = trayItem (QQuickItem), coords relative to it
            				modelData.display(root, menuX, menuY)
        			}
    			}

    		    onWheel: function(wheel) {
        		modelData.scroll(wheel.angleDelta.y, false)
    			}
		    }
		}
            }
	                // ----- BATTERY -----
            Item {
                id: batteryRoot
                Layout.alignment: Qt.AlignVCenter | Qt.AlignVRight

                // use UPower's aggregate display device
                property var dev: UPower.displayDevice

                // UPowerDevice.percentage is 0–1 in current Quickshell → convert to 0–100
                readonly property int perc: dev && dev.ready
                                            ? Math.round(dev.percentage * 100)
                                            : -1

                readonly property bool isCharging:
                    dev && (dev.state === UPowerDeviceState.Charging
                            || dev.state === UPowerDeviceState.PendingCharge)

                readonly property bool isLow: perc >= 0 && perc <= 30
                readonly property bool isCritical: perc >= 0 && perc <= 15

                // colors
                property color colNormal:  vars.colWhite
                property color colCharging: "#00ff00"
                property color colLow:     "#ff5555"

                // flash when critically low and not charging
                opacity: 1.0
                NumberAnimation on opacity {
                    from: 1.0
                    to: 0.3
                    duration: 600
                    loops: Animation.Infinite
                    running: batteryRoot.isCritical && !batteryRoot.isCharging
                }

                RowLayout {
                    anchors.fill: parent
                    spacing: 4

                    // battery icon (Nerd Font)
                    Text {
                        text: batteryRoot.perc >= 0
                              ? batteryRoot.batteryIcon(batteryRoot.perc)
                              : ""

                        color: batteryRoot.isCharging
                               ? batteryRoot.colCharging
                               : (batteryRoot.isLow
                                   ? batteryRoot.colLow
                                   : batteryRoot.colNormal)

                        font.family: vars.fontFamily
                        font.pixelSize: vars.iFontSz
                        font.bold: true
                    }

                    // percentage text
                    Text {
                        text: batteryRoot.perc >= 0
                              ? batteryRoot.perc + "%"
                              : ""

                        color: batteryRoot.isCharging
                               ? batteryRoot.colCharging
                               : (batteryRoot.isLow
                                   ? batteryRoot.colLow
                                   : batteryRoot.colNormal)

                        font.family: vars.fontFamily
                        font.pixelSize: vars.iFontSz
                        font.bold: true
                    }
                }

                function batteryIcon(p) {
                    if (p < 0) return "";
                    if (p <= 10) return "";
                    if (p <= 30) return "";
                    if (p <= 60) return "";
                    if (p <= 85) return "";
                    return "";
                }
            }

            // CLOCK (to the right of tray)
            Text {
                id: clockText

                // false = show time, true = show date
                property bool showDate: false

                text: showDate
                      ? Qt.formatDate(new Date(), "MM-dd-yyyy")
                      : Qt.formatTime(new Date(), "hh:mm")

                color: vars.colWhite
                font.family: vars.fontFamily
                font.pixelSize: vars.iFontSz
                font.bold: true
                Layout.alignment: Qt.AlignVCenter

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: {
                        clockText.text = clockText.showDate
                            ? Qt.formatDate(new Date(), "MM-dd-yyyy")
                            : Qt.formatTime(new Date(), "hh:mm")
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: clockText.showDate = !clockText.showDate
                }
            }
        }
    }
}

