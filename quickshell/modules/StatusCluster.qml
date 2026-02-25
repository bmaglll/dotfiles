import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    // pass-through props
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 12

    property color hoverBg: Qt.rgba(1, 1, 1, 0.10)   // subtle white tint
    property int radius: 8
    property int paddingX: 8
    property int paddingY: 2
    property int innerSpacing: 6

    // let the parent decide what to do on click
    signal clicked(int button)

    // expose hover state if you want to use it elsewhere later
    property bool hovered: mouse.containsMouse

    implicitWidth: bg.implicitWidth
    implicitHeight: bg.implicitHeight

    Rectangle {
        id: bg
        radius: root.radius
        color: root.hovered ? root.hoverBg : Qt.rgba(0, 0, 0, 0)
        border.width: 0

        implicitWidth: content.implicitWidth + root.paddingX * 2
        implicitHeight: content.implicitHeight + root.paddingY * 2

        RowLayout {
            id: content
            anchors.centerIn: parent
            spacing: root.innerSpacing

            // Slot in whatever you want inside (Volume, Battery, Clock)
            // We'll use this wrapper to host them from Bar.qml.
        }
    }

    // This MouseArea covers the whole cluster
    MouseArea {
        id: mouse
        anchors.fill: bg
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: function(m) {
            root.clicked(m.button)
        }
    }

    // This is the important part: allow children to be placed into `content`
    default property alias children: content.children
}
