import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

RowLayout {
    id: workspacesBar
    spacing: 2

    // pass from shell.qml: QtObject with colors/fonts
    property var vars

    Repeater {
        model: 5

        Text {
            property var ws: Hyprland.workspaces.values.find(w => w.id == index + 1)
            property bool isActive: Hyprland.focusedWorkspace?.id == (index + 1)

            text: index + 1

            color: isActive
                   ? vars.colWhite
                   : (ws ? vars.colLightGrey : vars.colDarkGrey)

            font.family: vars.fontFamily
            font.pixelSize: vars.iFontSz
            font.bold: true

            MouseArea {
                anchors.fill: parent
                onClicked: Hyprland.dispatch("workspace " + (index + 1))
            }
        }
    }

}

