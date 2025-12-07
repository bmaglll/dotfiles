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
        
        // This property handles the signal that fires when the process has output data
        onReadyReadStandardOutput: {
            // Read all available data from the standard output buffer
            var output = titleProc.readAllStandardOutput();
            
            try {
                // Parse the JSON output
                var data = JSON.parse(output);
                
                // Set the text to the window title, handling null/empty focus
                windowTitle.text = data.title ? data.title : "";
            } catch (err) {
                // Handle parsing errors (e.g. non-JSON output)
                windowTitle.text = "Error reading title";
            }
        }
        
        // Ensure the text is cleared if the process fails or exits badly
        onFinished: function(exitCode) {
            if (exitCode !== 0) {
                windowTitle.text = "hyprctl error";
            }
        }
    }

    Connections {
        target: Hyprland
        
        function onRawEvent(event) {
            if (event.name === "activewindow" || event.name === "activewindowv2" || event.name === "windowtitle") {
                // Run the process to update the title
                titleProc.running = true; 
            }
        }
    }

    // Initial fetch when the bar loads
    Component.onCompleted: titleProc.running = true
}
