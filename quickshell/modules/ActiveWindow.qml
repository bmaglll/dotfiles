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
        
        // Use the signal handler that is most likely to be exposed: onProcessFinished
        // This fires *after* the command runs and the output is ready.
        onProcessFinished: function(exitCode) {
            // Only proceed if the command executed successfully
            if (exitCode === 0) {
                // Read the output buffer directly from the process object
                var output = titleProc.readAllStandardOutput();
                
                try {
                    // Parse the JSON output from Hyprland
                    var data = JSON.parse(output);
                    
                    // Set the text to the window title, handling null/empty focus
                    windowTitle.text = data.title ? data.title : "";
                } catch (err) {
                    windowTitle.text = "";
                }
            } else {
                // Command failed (e.g., hyprctl not found)
                windowTitle.text = "hyprctl fail";
            }
        }
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
