import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

Item {
    id: root

    // Make it obviously visible in the bar
    implicitHeight: 24
    implicitWidth: row.implicitWidth + 16

    // Gray background so you can SEE it
    Rectangle {
        anchors.fill: parent
        color: "#333333"
        radius: 4
    }

    // Current player: pick the first one if the model is ready
    property var player: (
        Mpris.players && typeof Mpris.players.count !== "undefined" && Mpris.players.count > 0
            ? Mpris.players.get(0)
            : null
    )

    // Click to toggle play/pause
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        onClicked: {
            if (!root.player) {
                return;
            }

            if (root.player.canTogglePlaying) {
                root.player.togglePlaying();
            } else if (root.player.canPlay || root.player.canPause) {
                root.player.isPlaying = !root.player.isPlaying;
            }
        }
    }

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.margins: 4
        spacing: 6

        // Icon
        Text {
            Layout.alignment: Qt.AlignVCenter

            text: {
                if (!root.player) {
                    return "⏹";      // no player
                }
                return root.player.isPlaying ? "⏸" : "▶";
            }

            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            color: "white"
            verticalAlignment: Text.AlignVCenter
        }

        // Artist - Title
        Text {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true

            text: {
                if (!root.player) {
                    return "No MPRIS player";
                }

                const artist = root.player.trackArtist || "Unknown Artist";
                const title  = root.player.trackTitle  || "Unknown Title";
                return artist + " - " + title;
            }

            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            color: "white"

            elide: Text.ElideRight
            maximumLineCount: 1
            verticalAlignment: Text.AlignVCenter
        }
    }
}

