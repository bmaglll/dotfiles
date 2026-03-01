import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 12

    property color hoverBg: Qt.rgba(1, 1, 1, 0.10)
    property color activeBg: Qt.rgba(1, 1, 1, 0.16)   // <-- NEW
    property int radius: 8
    property int paddingX: 8
    property int paddingY: 2
    property int innerSpacing: 6

    // toggle state
    property bool toggled: false
    property bool rightPressed: false  // for showing info without dropdown

    signal clicked(int button)
    signal toggledChangedByUser(bool toggled)

    property bool hovered: mouse.containsMouse

    implicitWidth: bg.implicitWidth
    implicitHeight: bg.implicitHeight

    Rectangle {
        id: bg
        radius: root.radius
        color: root.toggled ? root.activeBg : (root.hovered ? root.hoverBg : Qt.rgba(0, 0, 0, 0))
        border.width: 0

        implicitWidth: content.implicitWidth + root.paddingX * 2
        implicitHeight: content.implicitHeight + root.paddingY * 2

        RowLayout {
            id: content
            anchors.centerIn: parent
            spacing: root.innerSpacing
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: bg
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onPressed: function(m) {
            if (m.button === Qt.RightButton) {
                root.rightPressed = true
            }
        }

        onReleased: function(m) {
            if (m.button === Qt.RightButton) {
                root.rightPressed = false
            }
        }

        onClicked: function(m) {
            root.clicked(m.button)

            // only toggle on LEFT click
            if (m.button === Qt.LeftButton) {
                root.toggled = !root.toggled
                root.toggledChangedByUser(root.toggled)
            }
        }
    }

    default property alias children: content.children
}
