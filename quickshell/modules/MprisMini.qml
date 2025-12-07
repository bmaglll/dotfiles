import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

Item {
    id: root

    // Make it visibly present
    implicitHeight: 24
    implicitWidth: row.implicitWidth + 16

    // Background so you can clearly see it
    Rectangle {
        anchors.fill: parent
        color: "#333333"
        radius: 4
    }

    // Currently selected player (we pick the first usable one)
    property var player: null
    property int playersLen: 0

    function updatePlayer() {
        if (!Mpris.players || !Mpris.players.values) {
            console.log("MprisMini: updatePlayer -> no players model")
            root.player = null
            root.playersLen = 0
            return
        }

        const vals = Mpris.players.values
        root.playersLen = vals.length
        console.log("MprisMini: updatePlayer -> values length =", vals.length)

        if (vals.length === 0) {
            root.player = null
            return
        }

        // Naive: just pick the first one for now
        // (we can later prefer spotify over playerctld/firefox)
        root.player = vals[0]

        console.log("MprisMini: using player dbusName =", root.player.dbusName,
                    "identity =", root.player.identity)
    }

    Component.onCompleted: {
        if (Mpris.players && Mpris.players.values) {
            console.log("MprisMini: initial values length =", Mpris.players.values.length)
        } else {
            console.log("MprisMini: initial players model not ready")
        }
        updatePlayer()
    }

    Connections {
        target: Mpris.players

        // Fired whenever the list of players changes
        function onValuesChanged() {
            const len = Mpris.players.values.length
            console.log("MprisMini: players values changed, length =", len)
            root.updatePlayer()
        }
    }

    MouseArea {
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
            Layout.alignment: Qt.AlignVCenter
            visible: true

            text: {
                if (!root.player) {
                    return "⏹"
                }
                return root.player.isPlaying ? "⏸" : "▶"
            }

            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            color: "white"
            verticalAlignment: Text.AlignVCenter
        }

        // Artist - Title or debug fallback
        Text {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true

            text: {
                if (!root.player) {
                    // show length so we know what the model sees
                    return "No MPRIS player (len=" + root.playersLen + ")"
                }

                const artist = root.player.trackArtist || "Unknown Artist"
                const title  = root.player.trackTitle  || "Unknown Title"
                return artist + " - " + title
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

