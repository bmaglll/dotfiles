import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

Item {
    id: root
    // vanish if no valid players exist
    visible: player !== null

    implicitHeight: 24
    implicitWidth: row.implicitWidth + 16

    Rectangle {
        anchors.fill: parent
        color: "#333333"
        radius: 4
    }

    // Model/list from Quickshell
    property var playersModel: Mpris.players
    property var players: playersModel ? playersModel.values : []

    // Choose the active player:
    //  1. Any non-playerctld that isPlaying
    //  2. Otherwise prefer spotify
    //  3. Otherwise prefer firefox
    //  4. Otherwise first non-playerctld
    property var player: {
        const vals = root.players;
        if (!vals || vals.length === 0) {
            return null;
        }

        function valid(p) {
            return p && p.dbusName.indexOf("playerctld") === -1;
        }

        // 1) any playing player (skip playerctld)
        for (let i = 0; i < vals.length; ++i) {
            const p = vals[i];
            if (valid(p) && p.isPlaying) {
                return p;
            }
        }

        // 2) prefer spotify
        for (let i = 0; i < vals.length; ++i) {
            const p = vals[i];
            if (valid(p) && p.dbusName.indexOf("spotify") !== -1) {
                return p;
            }
        }

        // 3) prefer firefox
        for (let i = 0; i < vals.length; ++i) {
            const p = vals[i];
            if (valid(p) && p.dbusName.indexOf("firefox") !== -1) {
                return p;
            }
        }

        // 4) fallback: first non-playerctld
        for (let i = 0; i < vals.length; ++i) {
            const p = vals[i];
            if (valid(p)) {
                return p;
            }
        }

        // worst case: just first
        return vals[0];
    }

    // Debug: see when active player changes
    onPlayerChanged: {
        if (player) {
            console.log("MprisMini: active player now", player.dbusName, "identity =", player.identity);
        } else {
            console.log("MprisMini: no active player");
          }
    }

    MouseArea {
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

        Text {
            Layout.alignment: Qt.AlignVCenter

            text: {
                if (!root.player) {
                    const len = root.players ? root.players.length : 0;
                    return "⏹ (" + len + ")";
	        }
	        return root.player.isPlaying ? "" : "" 
	    }

            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            color: "white"
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true

            text: {
                if (!root.player) {
                    const len = root.players ? root.players.length : 0;
                    return "No MPRIS player (len=" + len + ")";
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

