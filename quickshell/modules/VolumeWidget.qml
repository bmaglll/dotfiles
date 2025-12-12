import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

Item {
    id: volumeWidget
    width: iconText.implicitWidth + 10
    height: parent ? parent.height : 24

    // tweak these
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 12

    // terminal + wiremix
    property var wiremixCommand: ["ghostty", "-e", "wiremix"]

    // local idea of volume (0..1). We drive the real volume via wpctl.
    property real volumeLevel: 0.5
    property bool muted: false

    // --- helpers to call wpctl ---
    Process {
        id: wpctlProc
    }

    function setVolumeFraction(f) {
        if (f < 0.0) f = 0.0;
        if (f > 1.0) f = 1.0;
        volumeLevel = f;

        var pct = Math.round(f * 100);
        wpctlProc.command = [ "wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", pct + "%" ];
        wpctlProc.startDetached();
    }

    function changeVolumeByPercent(deltaPct) {
        // we don't know the exact current value; just bump our local and send a relative wpctl
        var rel = Math.round(Math.abs(deltaPct)) + "%";
        var op  = deltaPct >= 0 ? "+" : "-";
        wpctlProc.command = [ "wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", rel + op ];
        wpctlProc.startDetached();

        // also move local estimate so icon/slider feel responsive
        var newFrac = volumeLevel + (deltaPct / 100.0);
        if (newFrac < 0.0) newFrac = 0.0;
        if (newFrac > 1.0) newFrac = 1.0;
        volumeLevel = newFrac;
    }

    function setMuted(m) {
        muted = m;
        wpctlProc.command = [ "wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", m ? "1" : "0" ];
        wpctlProc.startDetached();
    }

    // --- launch wiremix in a terminal ---
    Process {
        id: wiremixProc
        command: volumeWidget.wiremixCommand
    }

    // ================= ICON =================
    Text {
        id: iconText
        anchors.centerIn: parent
        font.family: volumeWidget.fontFamily
        font.pixelSize: volumeWidget.fontSize
        color: "white"

        text: {
            if (volumeWidget.muted || volumeWidget.volumeLevel <= 0.01) {
                return "󰝟";          // muted
            } else if (volumeWidget.volumeLevel < 0.33) {
                return "󰕿";          // low
            } else if (volumeWidget.volumeLevel < 0.66) {
                return "󰖀";          // medium
            } else {
                return "󰕾";          // high
            }
        }
    }

    // ================= MOUSE ON ICON =================
    MouseArea {
        id: iconMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                // open wiremix
                wiremixProc.startDetached();
            } else if (mouse.button === Qt.LeftButton) {
                // toggle popup
                popup.visible = !popup.visible;
            }
        }

        // scroll wheel volume
        onWheel: function(wheel) {
            if (wheel.angleDelta.y > 0) {
                changeVolumeByPercent(5);   // +5%
            } else if (wheel.angleDelta.y < 0) {
                changeVolumeByPercent(-5);  // -5%
            }
        }

        // hover shows popup
        onEntered: popup.visible = true
        onExited: {
            if (!popupMouse.containsMouse) {
                popup.visible = false;
            }
        }
    }

    // ================= POPUP WINDOW =================
    PopupWindow {
        id: popup

        // attach to the bar icon so it "grows" from it
        anchor.item: volumeWidget
        anchor.edges: Edges.Bottom | Edges.Left
        anchor.gravity: Edges.Bottom | Edges.Left
        anchor.margins.top: 0

        implicitWidth: 50
        implicitHeight: 150
        visible: false

        Rectangle {
            anchors.fill: parent
            radius: 8
            // semi-transparent so Hyprland blur shows through
            color: Qt.rgba(0, 0, 0, 0.35)
            border.width: 0

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    font.family: volumeWidget.fontFamily
                    font.pixelSize: volumeWidget.fontSize - 1
                    color: "white"
                    text: Math.round(volumeWidget.volumeLevel * 100) + "%"
                }

                Item { Layout.fillHeight: true }

                Slider {
                    id: volumeSlider
                    Layout.alignment: Qt.AlignHCenter
                    orientation: Qt.Vertical
                    from: 0.0
                    to: 1.0
                    stepSize: 0.01
                    value: volumeWidget.volumeLevel

                    onValueChanged: {
                        setVolumeFraction(value);
                        if (volumeWidget.muted && value > 0.01) {
                            setMuted(false);
                        }
                    }
                }
            }

            MouseArea {
                id: popupMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton

                onEntered: popup.visible = true
                onExited: {
                    if (!iconMouse.containsMouse) {
                        popup.visible = false;
                    }
                }
            }
        }
    }
}

