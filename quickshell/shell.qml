//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Hyprland
import QtQuick.Layouts
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Services.Mpris
import Quickshell.Io

import "modules"

Scope {
    id: shellRoot

    // Shared buddy model — one scan for all bars
    ListModel { id: sharedBuddyModel }

    Process {
        id: buddyScanProc
        stdout: StdioCollector {
            onStreamFinished: {
                var files = this.text.trim().split("\n").filter(function(f) { return f !== "" })
                for (var i = sharedBuddyModel.count - 1; i >= 0; i--) {
                    if (files.indexOf(sharedBuddyModel.get(i).filePath) === -1)
                        sharedBuddyModel.remove(i)
                }
                for (var j = 0; j < files.length; j++) {
                    var found = false
                    for (var k = 0; k < sharedBuddyModel.count; k++) {
                        if (sharedBuddyModel.get(k).filePath === files[j]) { found = true; break }
                    }
                    if (!found)
                        sharedBuddyModel.append({ filePath: files[j] })
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!buddyScanProc.running)
                buddyScanProc.exec({ command: ["bash", "-c", "find /tmp -maxdepth 1 -name 'agent-buddy-*' -newer /proc/1/cmdline 2>/dev/null | sort"] })
        }
    }

    Variants {
        model: Quickshell.screens

        // create one Bar per screen
        Bar {
            // modelData is provided by Variants
            modelData: modelData
            buddyModel: sharedBuddyModel
        }
    }
}
