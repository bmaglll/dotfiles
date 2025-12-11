import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import Quickshell.Hyprland

Item {
    id: volumeWidget
    width: iconText.implicitWidth + 10
    height: parent ? parent.height : 24

    /* --- config knobs for you --- */
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 12

    // change this to kitty/foot/alacritty/etc as you like
    property var wiremixCommand: ["ghostty", "-e", "wiremix"]

    // Convenience shortcuts into PipeWire default sink
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink && sink.audio ? sink.audio : null
    readonly property real volume: audio ? audio.volume : 0.0
    readonly property bool muted: audio ? audio.muted : false

    /* --- icon showing current volume level --- */
    Text {
        id: iconText
        anchors.centerIn: parent
        font.family: volumeWidget.fontFamily
        font.pixelSize: volumeWidget.fontSize

        // Replace these with your preferred Nerd Font glyphs
        text: {
            if (!volumeWidget.audio) {
                return "󰝟" // no sink / fallback
            }
            if (volumeWidget.muted || volumeWidget.volume <= 0.01) {
                return "󰝟" // muted / 0
            } else if (volumeWidget.volume < 0.33) {
                return "󰕿" // low
            } else if (volumeWidget.volume < 0.66) {
                return "󰖀" // medium
            } else {
                return "󰕾" // high
            }
        }

        color: "white"
    }

    /* --- process to spawn wiremix in TUI --- */
    Process {
        id: wiremixProc
        command: volumeWidget.wiremixCommand
        // We only flip running to true on right-click; it exits on its own.
    }

    /* --- mouse handling on the icon --- */
    MouseArea {
        id: iconMouse
        anchors.fill: parent

        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                // open wiremix in a terminal
                wiremixProc.running = true
            } else if (mouse.button === Qt.LeftButton) {
                popup.visible = !popup.visible
            }
        }

        // Optional: scroll wheel to change volume
        onWheel: (wheel) => {
            if (!volumeWidget.audio || !Pipewire.ready)
                return

            // wheel.angleDelta.y > 0 = scroll up = volume up
            const step = 0.05
            let newVol = volumeWidget.audio.volume + (wheel.angleDelta.y > 0 ? step : -step)
            if (newVol < 0.0) newVol = 0.0
            if (newVol > 1.5) newVol = 1.5   // allow a bit over 100% if you like

            volumeWidget.audio.muted = false
            volumeWidget.audio.volume = newVol
        }
    }

    /* --- popup window with vertical slider --- */
    PopupWindow {
        id: popup

        // attach popup to this widget, so it “grows out” of the bar at the icon
        anchor.item: volumeWidget
        anchor.edges: Edges.Bottom | Edges.Left        // attach to bottom of the icon
        anchor.gravity: Edges.Bottom | Edges.Left      // expand downward from it
        anchor.margins.top: 0

        visible: iconMouse.containsMouse || popupMouse.containsMouse

        width: 40
        height: 140

        // No bar border: just a transparent rectangle, Hyprland blur does the rest.
        Rectangle {
            anchors.fill: parent
            radius: 8
            // semi-transparent so Hyprland blur shows through
            color: Qt.rgba(0, 0, 0, 0.35)
            border.width = 0

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
                        if (!volumeWidget.audio)
                            return "--%"
                        const pct = Math.round(volumeWidget.volume * 100)
                        return pct + "%"
                    }
                }

                // spacer
                Item { Layout.fillHeight: true }

                Slider {
                    id: volumeSlider
                    Layout.alignment: Qt.AlignHCenter
                    orientation: Qt.Vertical
                    from: 0.0
                    to: 1.5
                    stepSize: 0.01

                    // When popup appears, sync slider to current volume
                    Component.onCompleted: {
                        if (volumeWidget.audio)
                            value = volumeWidget.volume
                    }
                    onActiveFocusChanged: {
                        if (activeFocus && volumeWidget.audio)
                            value = volumeWidget.volume
                    }
                    onPressedChanged: {
                        // when user first presses, sync just in case
                        if (pressed && volumeWidget.audio)
                            value = volumeWidget.volume
                    }

                    onMoved: {
                        if (!volumeWidget.audio || !Pipewire.ready)
                            return
                        volumeWidget.audio.muted = false
                        volumeWidget.audio.volume = value
                    }
                }
            }

            MouseArea {
                id: popupMouse
                anchors.fill: parent
                hoverEnabled: true
                // let wheel events go to slider etc.
                acceptedButtons: Qt.NoButton
            }
        }
    }
}

