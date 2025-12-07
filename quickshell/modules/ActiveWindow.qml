import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Hyprland
// Note: Remove the import "../" unless you have a custom component there

Text { // Renamed from BarText to standard Text for compatibility
    id: activeWindowTitleDisplay

    property int chopLength: 40 // Set a default value
    property string activeWindowTitle: ""

    // Set the initial text to be empty
    text: {
        var str = activeWindowTitle
        // If the title is empty (no active window), return empty string immediately
        if (str.length === 0) return "";
        
        // Otherwise, truncate the title if it exceeds chopLength
        return str.length > chopLength ? str.slice(0, chopLength) + '...' : str;
    }

    // Set your display properties
    font.family: "JetBrainsMono Nerd Font"
    font.pixelSize: 10
    color: "white"
    verticalAlignment: Text.AlignVCenter

    // --- Process to run hyprctl and parse the output ---
    Process {
        id: titleProc
        // New command:
        // 1. Run hyprctl activewindow
        // 2. Filter for 'title:'
        // 3. Strip 'title: ' prefix
        // The output will be the title string OR empty/error if no window is active/focused.
        command: ["sh", "-c", "hyprctl activewindow | grep title: | sed 's/^[^:]*: //'"]
        property bool isFetching: false

        running: isFetching
        
        // Timeout set to 100ms to prevent the shell command from hanging indefinitely 
        // if hyprctl takes too long or fails silently, though this is rare.
        timeout: 100 

        stdout: SplitParser {
            // Trim and assign the title. If the command output is empty, data.trim() 
            // will be an empty string, which handles the "no active window" case.
            onRead: data => activeWindowTitleDisplay.activeWindowTitle = data.trim()
        }

        // Add a handler for when the process finishes
        onExited: {
            isFetching = false;
            // The activeWindowTitle will already be set via stdout: SplitParser
            
            // --- CRITICAL ADDITION: Handle no output/error case ---
            // If the command failed (exitCode !== 0) or produced no output, 
            // we should assume no active window is focused and clear the text.
            // Note: This often isn't needed if stdout: SplitParser is robust, but 
            // it provides a clear fallback.
            if (exitCode !== 0) {
                activeWindowTitleDisplay.activeWindowTitle = "";
            }
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
        // Initial fetch on startup
        titleProc.isFetching = true 
    }

    function hyprEvent(e) {
        // Trigger a fetch on any event related to window activation/deactivation 
        // or title change. 'windowtitle' and 'activewindow' are the most relevant.
        if (e.name === "activewindow" || e.name === "activewindowv2" || e.name === "windowtitle") {
            if (!titleProc.isFetching) {
                titleProc.isFetching = true
            }
        }
        // You might also consider adding the 'closewindow' event to be sure 
        // it updates immediately when the last window is closed.
        if (e.name === "closewindow") {
            if (!titleProc.isFetching) {
                titleProc.isFetching = true
            }
        }
    }
}
