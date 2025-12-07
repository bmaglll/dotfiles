
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
Item {
    id: root

    // Size for the bar
    implicitHeight: row.implicitHeight
    implicitWidth: row.implicitWidth

    // First available MPRIS player
    property var player: (Mpris.players.count > 0 ? Mpris.players.get(0) : null)

    // TEMP: always visible so we can debug.
    // Once everything works, you can switch back to: visible: player !== null
    // visible: player !== null

    Component.onCompleted: {
        console.log("MprisMini: players count on start =", Mpris.players.count)
    }

    onPlayerChanged: {
        console.log("MprisMini: player changed =", player)
    }

    MouseArea {
        id: clickArea
        anchors.fill: parent
        hoverEnabled: true

        onClicked: {
            if (!root.player)
                return;

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

        // Play / pause icon
        Text {
            id: stateIcon
            Layout.alignment: Qt.AlignVCenter

            text: {
                if (!root.player) {
                    // Show something so you know it's alive
                    return "⏹"; // no player
                }
                return root.player.isPlaying ? "⏸" : "▶";
            }

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
                    return "No MPRIS player";
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


