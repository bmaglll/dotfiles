import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Text {
    id: windowTitle
    text: "" 
    color: "#ffffff" // Set your text color
    font.pixelSize: 14
    
    // Limit width if titles get too long (optional)
    elide: Text.ElideRight 
    maximumLineCount: 1

    // 1. Process to fetch the title securely via JSON
    Process {
        id: titleProc
        // We use -j (JSON) to avoid issues with commas/symbols in titles
        command: ["hyprctl", "activewindow", "-j"]
        
        stdout: function(output) {
            try {
                // Parse the JSON output from Hyprland
                var data = JSON.parse(output);
                
                // Set the text to the window title, or empty if none
                windowTitle.text = data.title ? data.title : "";
            } catch (err) {
                windowTitle.text = "";
            }
        }
    }

    // 2. Listen for focus changes to update the title
    Connections {
        target: Hyprland
        
        function onRawEvent(event) {
            // "activewindow" event means focus changed
            // "windowtitle" event means the title of a window changed
            if (event.name === "activewindow" || event.name === "activewindowv2" || event.name === "windowtitle") {
                titleProc.running = true;
            }
        }
    }

    // 3. Update immediately on load
    Component.onCompleted: titleProc.running = true
}
