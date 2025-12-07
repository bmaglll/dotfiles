import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Text {
    id: windowTitle
    text: ""
    color: "#ffffff" 
    font.pixelSize: 14
    elide: Text.ElideRight 
    maximumLineCount: 1

    Process {
        id: titleProc
        command: ["hyprctl", "activewindow", "-j"]
        
        // 🛑 FIX: Use the 'onStdout' signal handler syntax 
        // to receive the process output as a string 'output'.
        onStdout: function(output) {
            try {
                // The rest of your logic remains the same
                var data = JSON.parse(output);
                
                windowTitle.text = data.title ? data.title : "";
            } catch (err) {
                windowTitle.text = "";
            }
        }
    }

    Connections {
        target: Hyprland
        
        function onRawEvent(event) {
            if (event.name === "activewindow" || event.name === "activewindowv2" || event.name === "windowtitle") {
                // Setting running = true restarts/runs the process
                titleProc.running = true; 
            }
        }
    }

    Component.onCompleted: titleProc.running = true
}
