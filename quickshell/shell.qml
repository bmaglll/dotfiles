//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Hyprland
import QtQuick.Layouts
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Services.Mpris

import "modules"

Scope {
    id: shellRoot

    Variants {
        model: Quickshell.screens

        // create one Bar per screen
        Bar {
            // modelData is provided by Variants
            modelData: modelData
        }
    }
}

