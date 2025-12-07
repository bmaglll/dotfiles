import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Text {
    id: root
    
    // This property will hold the actual title
    text: "..."
    color: "white"
    font.pixelSize: 16
    verticalAlignment: Text.AlignVCenter

    // 1. A Process to run 'hyprctl activewindow -j'
    // We use -j (JSON) so we can safely parse titles with weird characters
    Process {
        id: activeWindowQuery
        command: ["hyprctl", "activewindow", "-j"]
        
        // When the command finishes, parse the output
        stdout: function(output) {
            try {
                const data = JSON.parse(output);
                // Hyprland returns an empty object {} if nothing is focused
                // We check if 'title' exists
                if (data && data.title) {
                    root.text = data.title;
                } else {
                    root.text = ""; // Clear text if desktop/nothing focused
                }
            } catch (e) {
                // Ignore parse errors (e.g. valid empty output)
                root.text = "";
            }
        }
    }

    // 2. Listen for Hyprland events to trigger the update
    Connections {
        target: Hyprland
        
        function onRawEvent(event) {
            // "activewindow" event fires when focus changes
            if (event.name === "activewindow") {
                activeWindowQuery.running = true;
            }
        }
    }

    // 3. Initial fetch when the bar loads
    Component.onCompleted: activeWindowQuery.running = true
}
