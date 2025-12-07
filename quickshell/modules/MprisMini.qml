import QtQuick
import Quickshell.Services.Mpris

Item {
    id: root

    // All players as a QML list
    property var playersList: Mpris.players ? Mpris.players.values : []

    // Just use the first player for now
    property var player: (playersList && playersList.length > 0)
                         ? playersList[0]
                         : null

    // Size to content
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        anchors.fill: parent
        anchors.margins: 4
        spacing: 6

        // Play/pause “icon”
        Text {
            id: statusIcon
            visible: player !== null
            text: player && player.isPlaying ? "" : ""   // swap to your nerd icons if you want
            font.pixelSize: 12
        }

        // Artist – Title or fallback
        Text {
            id: label
            text: player
                  ? ( (player.trackArtist || "Unknown Artist")
                      + " - "
                      + (player.trackTitle || "Unknown Title") )
                  : "No MPRIS player"
            font.pixelSize: 12
            elide: Text.ElideRight
        }
    }

    // Click to toggle play/pause
    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (player && player.canTogglePlaying) {
                player.togglePlaying();
            }
        }
    }

    // Debug so we can see what Quickshell sees
    Component.onCompleted: {
        if (Mpris.players) {
            console.log("MprisMini: initial players values length =",
                        Mpris.players.values.length);
            for (let i = 0; i < Mpris.players.values.length; i++) {
                const p = Mpris.players.values[i];
                console.log("MprisMini: player", i,
                            "dbusName =", p.dbusName,
                            "identity =", p.identity);
            }
        } else {
            console.log("MprisMini: Mpris.players is null");
        }
    }

    Connections {
        target: Mpris.players
        // Fired when the underlying list changes
        function onValuesChanged() {
            const len = Mpris.players.values.length;
            console.log("MprisMini: players values changed, length =", len);
        }
    }
}

