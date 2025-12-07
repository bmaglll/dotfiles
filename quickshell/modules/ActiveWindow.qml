import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Hyprland
// Note: Remove the import "../" unless you have a custom component there

Text { // Renamed from BarText to standard Text for compatibility
    id: activeWindowTitleDisplay

    property int chopLength: 40 // Set a default value
    property string activeWindowTitle: ""

    text: {
        var str = activeWindowTitle
        // Truncate the title if it exceeds chopLength, or return the full title
        return str.length > chopLength ? str.slice(0, chopLength) + '...' : str;
    }
    
    // Set your display properties
    color: "#ffffff"
    font.pixelSize: 14 
    verticalAlignment: Text.AlignVCenter

    // --- Process to run hyprctl and parse the output ---
    Process {
        id: titleProc
        command: ["sh", "-c", "hyprctl activewindow | grep title: | sed 's/^[^:]*: //'"]
        property bool isFetching: false

        running: isFetching
        
        stdout: SplitParser {
            onRead: data => activeWindowTitleDisplay.activeWindowTitle = data.trim()
        }
        
        onRunningChanged: {
            if (!titleProc.running) {
                isFetching = false;
            }
        }
    }

    // --- Event Connection to Hyprland ---
    Component.onCompleted: {
        Hyprland.rawEvent.connect(hyprEvent)
        titleProc.isFetching = true
    }

    function hyprEvent(e) {
        if (e.name === "activewindow" || e.name === "activewindowv2" || e.name === "windowtitle") {
            if (!titleProc.isFetching) {
                titleProc.isFetching = true
            }
        }
    }
}
