import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

Item {
    id: root

    implicitHeight: row.implicitHeight
    implicitWidth: row.implicitWidth

    // The currently selected player (we'll pick the first one)
    property var player: null

    // ---- Helper to choose a player safely ----
    function updatePlayer() {
        // Mpris or players not ready yet
        if (!Mpris.players || typeof Mpris.players.count === "undefined") {
            console.log("MprisMini: players model not ready:", Mpris.players)
            root.player = null
            return
        }

        console.log("MprisMini: players count:", Mpris.players.count)

        if (Mpris.players.count > 0) {
            root.player = Mpris.players.get(0)
        } else {
            root.player = null
        }
    }

    Component.onCompleted: {
        updatePlayer()
    }

    // React when the Mpris singleton says its players changed
    Connections {
        target: Mpris
        function onPlayersChanged() {
            root.updatePlayer()
        }
    }

    MouseArea {
        id: clickArea
        anchors.fill: parent
        hoverEnabled: true

        onClicked: {
            if (!root.player)
                return

            if (root.player.canTogglePlaying) {
                root.player.togglePlaying()
            } else if (root.player.canPlay || root.player.canPause) {
                root.player.isPlaying = !root.player.isPlaying
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
                    return "⏹" // no player
                }
                return root.player.isPlaying ? "⏸" : "▶"
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
                    return "No MPRIS player"
                }

                const artist = root.player.trackArtist || "Unknown Artist"
                const title  = root.player.trackTitle  || "Unknown Title"
                return artist + " - " + title
            }

            elide: Text.ElideRight
            maximumLineCount: 1
            verticalAlignment: Text.AlignVCenter

            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
        }
    }
}

