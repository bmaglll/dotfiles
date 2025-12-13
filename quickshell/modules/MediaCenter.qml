import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
PanelWindow {
  id: barModule
  color: "transparent"
  implicitHeight: 28

  anchors {
    left: true
    top: true
    right: true
  }

  // Clickable text in the bar
  Text {
    id: nowPlayingText
    anchors.centerIn: parent
    text: "Now Playing: (click me)"
  }
  // Open On click
  MouseArea {
    anchors.fill: nowPlayingText
    onClicked: popup.visible = !popup.visible
  }
  // Close on click other than popup
 // HyprlandFocusGrab {
  //id: grab
  //windows: [ popup ]
  //active: popup.visible
  //onCleared: popup.visible = false
  //}

  // Floating overlay window (does NOT reserve space)
  PopupWindow {
    id: popup
    color: "transparent"	
    HyprlandWindow.opacity: 0.4 // any number or binding
    // attach to your bar's top-level window so it positions correctly
    anchor.window: barModule

    // start hidden; we toggle it
    visible: true

    implicitWidth: 500
    implicitHeight: 300

    // Basic positioning: top center under the bar
    anchor.rect: Qt.rect(
      (barModule.width - implicitWidth) / 2,
      barModule.implicitHeight + 8,
      implicitWidth,
      implicitHeight
    )

    // close on Escape
    Keys.onEscapePressed: popup.visible = false

    // click outside to close (simple version)
    Rectangle {
      anchors.fill: parent
      radius: 16
      // use a real background so you can see it
      color: "#cc111111"
      border.width: 1
      border.color: "#33ffffff"

      Text {
        anchors.centerIn: parent
        color: "white"
        text: "Popup window (floating)"
      }
    }
  }
}

