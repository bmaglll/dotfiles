import QtQuick
import Quickshell

PopupWindow {
    id: popup

    required property Item anchorItem
    property int barWidth: 800
    property bool show: false
    property int popupHeight: 400
    property real widthRatio: 0.45

    // emitted when clicking outside
    signal requestClose()

    visible: show
    z: 999

    implicitWidth: {
        let w = barWidth * widthRatio;
        if (w < 360) w = 360;
        if (w > 800) w = 800;
        return w;
    }

    implicitHeight: popupHeight
    color: "transparent"

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom | Edges.Left
    anchor.gravity: Edges.Top | Edges.Left

    // backdrop (glass)
    Rectangle {
        anchors.fill: parent
        radius: 16
        color: "#00000088"
    }

    // CLICK OUTSIDE TO CLOSE
    MouseArea {
        anchors.fill: parent
        propagateComposedEvents: true

        onClicked: {
            // clicks inside do nothing
        }
    }

    // Global click catcher (outside popup)
    Overlay {
        visible: popup.visible

        MouseArea {
            anchors.fill: parent
            onClicked: popup.requestClose()
        }
    }

    // Placeholder content
    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        Text {
            text: "Media popup"
            font.pixelSize: 16
            color: "white"
        }
    }
}

