import QtQuick
import Quickshell

PopupWindow {
    id: popup

    // The bar item this popup should attach to (the MprisMini wrapper)
    required property Item anchorItem

    // Width of the bar row (passed from Bar.qml)
    property int barWidth: 800

    // External control: set this from Bar.qml
    property bool show: false

    // Height in px
    property int popupHeight: 400

    // Width ratio of the bar width (0.0–1.0)
    property real widthRatio: 0.4

    // Expose whether the mouse is over the popup
    property bool hovered: hoverArea.containsMouse

    // Use this to drive visibility
    visible: show

    // Size: width is a ratio of the bar width, clamped to a sane range
    implicitWidth: {
        var w = barWidth * widthRatio;
        if (w < 320) w = 320;   // minimum width
        if (w > 700) w = 700;   // maximum width
        return w;
    }

    implicitHeight: popupHeight

    // Let the compositor blur behind this
    color: "transparent"
    z: 999

    // Simple anchor: attach to the bottom-left of the MPRIS block
    anchor.item: anchorItem
    anchor.edges: Edges.Bottom | Edges.Left
    anchor.gravity: Edges.Top | Edges.Left

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: "#00000080"   // semi-transparent black, should blur nicely
    }

    // Hover catcher (no buttons, so it doesn't eat clicks yet)
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    // Placeholder content for now
    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        Text {
            text: "Media popup placeholder"
            font.pixelSize: 14
            color: "white"
        }
    }
}

