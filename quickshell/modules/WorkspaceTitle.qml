import QtQuick
import Quickshell
import Quickshell.Hyprland

Text {
    // Check if a workspace is focused; if so, show its name. 
    // Otherwise, show a placeholder or empty string.
    text: Hyprland.focusedWorkspace 
          ? Hyprland.focusedWorkspace.name 
          : ""

    color: "white" // Change to your preferred color
    font.pixelSize: 16
    
    // Optional: Vertical alignment if inside a Bar
    verticalAlignment: Text.AlignVCenter
}
