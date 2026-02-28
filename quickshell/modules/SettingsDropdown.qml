import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
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
    height: content.implicitHeight + 24
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
            spacing: 8
            Layout.fillWidth: true

            // Volume icon
            Text {
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                color: root.muted ? "#ff5555" : root.textColor
                text: {
                    if (root.muted || root.volumeFrac <= 0.01) return ""
                    else if (root.volumeFrac < 0.33) return ""
                    else if (root.volumeFrac < 0.66) return ""
                    else return ""
                }
            }

            Slider {
                id: volumeSlider
                Layout.fillWidth: true
                from: 0
                to: 1
                value: root.volumeFrac

                onMoved: {
                    volumeSetProc.exec({ command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", value.toFixed(2)] })
                }

                background: Rectangle {
                    x: volumeSlider.leftPadding
                    y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                    width: volumeSlider.availableWidth
                    height: 4
                    radius: 2
                    color: root.sliderBgColor

                    Rectangle {
                        width: volumeSlider.visualPosition * parent.width
                        height: parent.height
                        radius: 2
                        color: root.sliderColor
                    }
                }

                handle: Rectangle {
                    x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                    y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                    width: 12
                    height: 12
                    radius: 6
                    color: volumeSlider.pressed ? Qt.lighter(root.sliderColor) : root.sliderColor
                }
            }

            Text {
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                color: root.muted ? "#ff5555" : root.textColor
                text: Math.round(root.volumeFrac * 100) + "%"
                Layout.minimumWidth: 35
                horizontalAlignment: Text.AlignRight
            }
        }

        // Brightness row
        RowLayout {
            spacing: 8
            Layout.fillWidth: true

            // Brightness icon
            Text {
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                color: root.textColor
                text: root.brightnessFrac < 0.3 ? "" : ""
            }

            Slider {
                id: brightnessSlider
                Layout.fillWidth: true
                from: 0.05
                to: 1
                value: root.brightnessFrac

                onMoved: {
                    var pct = Math.round(value * 100)
                    brightnessSetProc.exec({ command: ["brightnessctl", "s", pct + "%"] })
                }

                background: Rectangle {
                    x: brightnessSlider.leftPadding
                    y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
                    width: brightnessSlider.availableWidth
                    height: 4
                    radius: 2
                    color: root.sliderBgColor

                    Rectangle {
                        width: brightnessSlider.visualPosition * parent.width
                        height: parent.height
                        radius: 2
                        color: root.sliderColor
                    }
                }

                handle: Rectangle {
                    x: brightnessSlider.leftPadding + brightnessSlider.visualPosition * (brightnessSlider.availableWidth - width)
                    y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
                    width: 12
                    height: 12
                    radius: 6
                    color: brightnessSlider.pressed ? Qt.lighter(root.sliderColor) : root.sliderColor
                }
            }

            Text {
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                color: root.textColor
                text: Math.round(root.brightnessFrac * 100) + "%"
                Layout.minimumWidth: 35
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
        interval: 500
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
        interval: 500
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
