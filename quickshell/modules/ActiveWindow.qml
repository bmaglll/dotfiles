import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Text {
    id: windowTitle
    text: "No active window"
    color: "#ffffff"
    font.pixelSize: 14
    elide: Text.ElideRight
    maximumLineCount: 1

    Process {
        id: titleProc
        command: ["hyprctl", "activewindow", "-j"]
        
        // This handler fires when the process has data ready to be read.
        onReadyReadStandardOutput: {
            // Read all available data from the standard output buffer
            var output = titleProc.readAllStandardOutput();
            
            try {
                // Parse the JSON output from Hyprland
                var data = JSON.parse(output);
                
                // Set the text to the window title, handling null/empty focus
                windowTitle.text = data.title ? data.title : "";
            } catch (err) {
                // Keep the text clear on error
                windowTitle.text = "";
            }
        }
        
        // 🛑 REMOVED: The problematic 'onFinished' handler is gone.
    }

    Connections {
        target: Hyprland
        
        function onRawEvent(event) {
            // Check for focus change or title update events
            if (event.name === "activewindow" || event.name === "activewindowv2" || event.name === "windowtitle") {
                // Run the process to update the title
                titleProc.running = true; 
            }
        }
    }

    // Initial fetch when the bar loads
    Component.onCompleted: titleProc.running = true
}
