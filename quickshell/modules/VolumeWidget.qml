import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Io

Item {
    id: volumeWidget
    width: iconText.implicitWidth + 10
    height: parent ? parent.height : 24

    // tweak these if you want
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 12

    // change this to your terminal if needed (kitty, foot, alacritty, etc.)
    property var wiremixCommand: ["ghostty", "-e", "wiremix"]

    // PipeWire: default sink
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink && sink.audio ? sink.audio : null
    readonly property real volume: audio ? audio.volume : 0.0
    readonly property bool muted: audio ? audio.muted : false

    // =============== ICON IN THE BAR ===============
    Text {
        id: iconText
        anchors.centerIn: parent
        font.family: volumeWidget.fontFamily
        font.pixelSize: volumeWidget.fontSize
        color: "white"

        text: {
            if (!volumeWidget.audio) {
                return "󰝟"          // no sink
            }
            if (volumeWidget.muted || volumeWidget.volume <= 0.01) {
                return "󰝟"          // muted / 0
            } else if (volumeWidget.volume < 0.33) {
                return "󰕿"          // low
            } else if (volumeWidget.volume < 0.66) {
                return "󰖀"          // medium
            } else {
                return "󰕾"          // high
            }
        }
    }

    // =============== PROCESS TO LAUNCH WIREMIX ===============
    Process {
        id: wiremixProc
        command: volumeWidget.wiremixCommand
    }

    // =============== MOUSE ON ICON ===============
    MouseArea {
        id: iconMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                // open wiremix in terminal
                wiremixProc.running = true
            } else if (mouse.button === Qt.LeftButton) {
                popup.visible = !popup.visible
            }
        }

        // scroll to change volume
        onWheel: function(wheel) {
            if (!volumeWidget.audio || !Pipewire.ready) {
                return
            }

            var step = 0.05
            var newVol = volumeWidget.volume

            if (wheel.angleDelta.y > 0) {
                newVol = newVol + step
            } else if (wheel.angleDelta.y < 0) {
                newVol = newVol - step
            }

            if (newVol < 0.0) newVol = 0.0
            if (newVol > 1.5) newVol = 1.5

            volumeWidget.audio.muted = false
            volumeWidget.audio.volume = newVol
        }

        // show popup when hovering icon
        onEntered: popup.visible = true
        onExited: {
            if (!popupMouse.containsMouse) {
                popup.visible = false
            }
        }
    }

    // =============== POPUP WINDOW WITH SLIDER ===============
    PopupWindow {
        id: popup

        // anchor to bar icon so it looks like it grows from it
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
                    text: {
                        if (!volumeWidget.audio) {
                            return "--%"
                        }
                        var pct = Math.round(volumeWidget.volume * 100)
                        return pct + "%"
                    }
                }

                Item { Layout.fillHeight: true }

                Slider {
                    id: volumeSlider
                    Layout.alignment: Qt.AlignHCenter
                    orientation: Qt.Vertical
                    from: 0.0
                    to: 1.5
                    stepSize: 0.01
                    value: volumeWidget.volume

                    onValueChanged: {
                        if (!volumeWidget.audio || !Pipewire.ready) {
                            return
                        }
                        volumeWidget.audio.muted = false
                        volumeWidget.audio.volume = value
                    }
                }
            }

            MouseArea {
                id: popupMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton

                onEntered: {
                    popup.visible = true
                }
                onExited: {
                    if (!iconMouse.containsMouse) {
                        popup.visible = false
                    }
                }
            }
        }
    }
}

