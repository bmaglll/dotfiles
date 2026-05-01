import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

RowLayout {
    id: workspacesBar
    spacing: 2

    // pass from shell.qml: QtObject with colors/fonts
    property var vars

    // sorted workspace IDs for sequential display
    property var sortedWs: Hyprland.workspaces.values
        .map(w => w.id)
        .filter(id => id > 0)
        .sort((a, b) => a - b)

    Repeater {
        model: workspacesBar.sortedWs

        Text {
            required property var modelData
            required property int index
            property bool isActive: Hyprland.focusedWorkspace?.id == modelData

            text: index + 1

            color: isActive ? vars.colWhite : vars.colLightGrey

            font.family: vars.fontFamily
            font.pixelSize: vars.iFontSz
            font.bold: true

            MouseArea {
                anchors.fill: parent
                onClicked: Hyprland.dispatch("workspace " + modelData)
            }
        }
    }

}

