import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
    id: root

    // Styling
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 12
    property color textColor: "#ffffff"
    property color sliderColor: "#a1ede8"
    property color sliderBgColor: "#40ffffff"

    width: 250
    height: 100  // Fixed height to avoid Hyprland input region bug
    radius: 12
    color: "#99111111"
    border.width: 1
    border.color: "#33ffffff"

    // State
    property real volumeFrac: 0.0
    property bool muted: false
    property real brightnessFrac: 1.0

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // Volume row
        RowLayout {
            id: volumeRow
            spacing: 8
            Layout.fillWidth: true

            // Volume icon
            Text {
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                color: root.muted ? "#ff5555" : root.textColor
                text: {
                    if (root.muted || root.volumeFrac <= 0.01) return "󰝟"
                    else if (root.volumeFrac < 0.33) return "󰕿"
                    else if (root.volumeFrac < 0.66) return "󰖀"
                    else return "󰕾"
                }
                Layout.minimumWidth: 20
            }

            // Custom slider using MouseArea (QtQuick.Controls Slider has issues in popups)
            Item {
                id: volumeSlider
                Layout.fillWidth: true
                implicitHeight: 20

                property real value: root.volumeFrac
                property bool pressed: volumeSliderMouse.pressed

                Rectangle {
                    id: volumeTrack
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 4
                    radius: 2
                    color: root.sliderBgColor

                    Rectangle {
                        width: root.volumeFrac * parent.width
                        height: parent.height
                        radius: 2
                        color: root.sliderColor
                    }
                }

                Rectangle {
                    id: volumeHandle
                    x: root.volumeFrac * (parent.width - width)
                    anchors.verticalCenter: parent.verticalCenter
                    width: 12
                    height: 12
                    radius: 6
                    color: volumeSliderMouse.pressed ? Qt.lighter(root.sliderColor) : root.sliderColor
                }

                MouseArea {
                    id: volumeSliderMouse
                    anchors.fill: parent
                    hoverEnabled: true

                    onPressed: function(mouse) {
                        updateVolume(mouse.x)
                    }

                    onPositionChanged: function(mouse) {
                        if (pressed) {
                            updateVolume(mouse.x)
                        }
                    }

                    onWheel: function(wheel) {
                        var delta = wheel.angleDelta.y > 0 ? 0.01 : -0.01
                        var newVal = Math.max(0, Math.min(1, root.volumeFrac + delta))
                        root.volumeFrac = newVal  // Immediate UI update
                        volumeSetProc.exec({ command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", newVal.toFixed(2)] })
                    }

                    function updateVolume(mouseX) {
                        var newVal = Math.max(0, Math.min(1, mouseX / width))
                        root.volumeFrac = newVal  // Immediate UI update
                        volumeSetProc.exec({ command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", newVal.toFixed(2)] })
                    }
                }
            }

            Text {
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                color: root.muted ? "#ff5555" : root.textColor
                text: Math.round(root.volumeFrac * 100) + "%"
                Layout.minimumWidth: 40
                horizontalAlignment: Text.AlignRight
            }
        }

        // Brightness row
        RowLayout {
            id: brightnessRow
            spacing: 8
            Layout.fillWidth: true

            // Brightness icon
            Text {
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                color: root.textColor
                text: root.brightnessFrac < 0.3 ? "󰃞" : "󰃠"
                Layout.minimumWidth: 20
            }

            // Custom slider using MouseArea
            Item {
                id: brightnessSlider
                Layout.fillWidth: true
                implicitHeight: 20

                property real value: root.brightnessFrac
                property bool pressed: brightnessSliderMouse.pressed

                Rectangle {
                    id: brightnessTrack
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 4
                    radius: 2
                    color: root.sliderBgColor

                    Rectangle {
                        width: root.brightnessFrac * parent.width
                        height: parent.height
                        radius: 2
                        color: root.sliderColor
                    }
                }

                Rectangle {
                    id: brightnessHandle
                    x: root.brightnessFrac * (parent.width - width)
                    anchors.verticalCenter: parent.verticalCenter
                    width: 12
                    height: 12
                    radius: 6
                    color: brightnessSliderMouse.pressed ? Qt.lighter(root.sliderColor) : root.sliderColor
                }

                MouseArea {
                    id: brightnessSliderMouse
                    anchors.fill: parent
                    hoverEnabled: true

                    onPressed: function(mouse) {
                        updateBrightness(mouse.x)
                    }

                    onPositionChanged: function(mouse) {
                        if (pressed) {
                            updateBrightness(mouse.x)
                        }
                    }

                    onWheel: function(wheel) {
                        var delta = wheel.angleDelta.y > 0 ? 0.01 : -0.01
                        var newVal = Math.max(0.05, Math.min(1, root.brightnessFrac + delta))
                        root.brightnessFrac = newVal  // Immediate UI update
                        var pct = Math.round(newVal * 100)
                        brightnessSetProc.exec({ command: ["brightnessctl", "s", pct + "%"] })
                    }

                    function updateBrightness(mouseX) {
                        var newVal = Math.max(0.05, Math.min(1, mouseX / width))
                        root.brightnessFrac = newVal  // Immediate UI update
                        var pct = Math.round(newVal * 100)
                        brightnessSetProc.exec({ command: ["brightnessctl", "s", pct + "%"] })
                    }
                }
            }

            Text {
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                color: root.textColor
                text: Math.round(root.brightnessFrac * 100) + "%"
                Layout.minimumWidth: 40
                horizontalAlignment: Text.AlignRight
            }
        }
    }

    // Volume polling
    Process {
        id: volumeGetProc
        stdout: StdioCollector {
            onStreamFinished: {
                var s = this.text.trim()
                var m = s.match(/Volume:\s*([0-9]*\.?[0-9]+)/)
                if (m && m.length >= 2) {
                    var v = parseFloat(m[1])
                    if (!isNaN(v)) {
                        if (v < 0.0) v = 0.0
                        if (v > 1.0) v = 1.0
                        root.volumeFrac = v
                    }
                }
                root.muted = (s.indexOf("MUTED") !== -1)
            }
        }
    }

    Process {
        id: volumeSetProc
    }

    Timer {
        interval: 200
        repeat: true
        running: root.visible
        triggeredOnStart: true
        onTriggered: {
            if (!volumeGetProc.running) {
                volumeGetProc.exec({ command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"] })
            }
        }
    }

    // Brightness polling
    property int brightnessMax: 100
    property int brightnessCurrent: 100

    Process {
        id: brightnessMaxProc
        stdout: StdioCollector {
            onStreamFinished: {
                var val = parseInt(this.text.trim())
                if (!isNaN(val) && val > 0) {
                    root.brightnessMax = val
                }
            }
        }
    }

    Process {
        id: brightnessGetProc
        stdout: StdioCollector {
            onStreamFinished: {
                var val = parseInt(this.text.trim())
                if (!isNaN(val)) {
                    root.brightnessCurrent = val
                    root.brightnessFrac = root.brightnessMax > 0 ? val / root.brightnessMax : 1.0
                }
            }
        }
    }

    Process {
        id: brightnessSetProc
    }

    Timer {
        interval: 200
        repeat: true
        running: root.visible
        triggeredOnStart: true
        onTriggered: {
            if (!brightnessMaxProc.running) {
                brightnessMaxProc.exec({ command: ["brightnessctl", "m"] })
            }
            if (!brightnessGetProc.running) {
                brightnessGetProc.exec({ command: ["brightnessctl", "g"] })
            }
        }
    }
}
