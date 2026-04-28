import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property var vars

    property string activeState: "idle"

    // Direction row (0=down/front-facing)
    readonly property int direction: 0

    // Per-state config matching AnimData.xml
    readonly property var stateConfig: ({
        "idle": {
            source: "../assets/agent-buddy/Idle-Anim.png",
            frameWidth: 24,
            frameHeight: 40,
            durations: [30, 16, 10, 16]
        }
    })

    readonly property var currentConfig: stateConfig[activeState] || stateConfig["idle"]
    readonly property int frameCount: currentConfig.durations.length

    property int currentFrame: 0

    Layout.alignment: Qt.AlignVCenter
    readonly property real scaleFactor: 2.0
    implicitWidth: currentConfig.frameWidth * scaleFactor
    implicitHeight: currentConfig.frameHeight * scaleFactor

    Image {
        id: sprite
        source: root.currentConfig.source
        sourceClipRect: Qt.rect(
            root.currentFrame * root.currentConfig.frameWidth,
            root.direction * root.currentConfig.frameHeight,
            root.currentConfig.frameWidth,
            root.currentConfig.frameHeight
        )
        width: root.currentConfig.frameWidth * root.scaleFactor
        height: root.currentConfig.frameHeight * root.scaleFactor
        anchors.centerIn: parent
        smooth: false
    }

    Timer {
        id: animTimer
        interval: root.currentConfig.durations[root.currentFrame] * 42
        running: true
        repeat: true
        onTriggered: {
            root.currentFrame = (root.currentFrame + 1) % root.frameCount
        }
    }
}
