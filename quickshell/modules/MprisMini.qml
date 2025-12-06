import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

Item {
    id: root

    // Size for the bar; tweak as needed
    implicitHeight: row.implicitHeight
    implicitWidth: row.implicitWidth

    // Pick the first available MPRIS player.
    // This binding re-evaluates when players.count changes.
    property var player: (Mpris.players.count > 0 ? Mpris.players.get(0) : null)

    // Hide if nothing is playing / no player
    visible: player !== null

    MouseArea {
        id: clickArea
        anchors.fill: parent
        hoverEnabled: true

        onClicked: {
            if (!root.player)
                return;

            // Prefer the official toggle API if the player supports it
            if (root.player.canTogglePlaying) {
                root.player.togglePlaying();
            } else if (root.player.canPlay || root.player.canPause) {
                // Fallback: flip isPlaying
                root.player.isPlaying = !root.player.isPlaying;
            }
        }
    }

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.margins: 4
        spacing: 6

        // Play / pause icon
        Text {
            id: stateIcon
            Layout.alignment: Qt.AlignVCenter

            text: {
                if (!root.player) {
                    return "⏹";        // no player
                }
                return root.player.isPlaying ? "⏸" : "▶";
            }

            // plug your font variables in here if you want
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            verticalAlignment: Text.AlignVCenter
        }

        // Artist - Title text
        Text {
            id: trackLabel
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true

            text: {
                if (!root.player) {
                    return "";
                }

                const artist = root.player.trackArtist || "Unknown Artist";
                const title  = root.player.trackTitle  || "Unknown Title";
                return artist + " - " + title;
            }

            elide: Text.ElideRight
            maximumLineCount: 1
            verticalAlignment: Text.AlignVCenter

            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
        }
    }
}

