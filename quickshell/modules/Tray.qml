import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray

RowLayout {
    id: trayBar
    spacing: 4

    // PanelWindow from shell.qml (root)
    property var panelWindow

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: trayItem
            width: 22
            height: 22
            y: -2    // raise icons a bit

            Image {
                anchors.fill: parent
                anchors.margins: 2
                source: modelData.icon
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onClicked: function(mouse) {
                    if (mouse.button === Qt.LeftButton) {
                        modelData.activate()
                        return
                    }

                    if (mouse.button === Qt.RightButton && modelData.hasMenu && panelWindow) {
                        // Map click → window coords
                        var p = trayItem.mapToItem(panelWindow.contentItem, mouse.x, mouse.y)
                        var menuX = Math.round(p.x)
                        var menuY = Math.round(p.y + trayItem.height)

                        modelData.display(panelWindow, menuX, menuY)
                    }
                }

                onWheel: function(wheel) {
                    modelData.scroll(wheel.angleDelta.y, false)
                }
            }
        }
    }
}

