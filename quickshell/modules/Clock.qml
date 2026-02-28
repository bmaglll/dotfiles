import QtQuick
import QtQuick.Layouts

Item {
    id: clockRoot
    Layout.alignment: Qt.AlignVCenter

    property var vars

    implicitWidth: clockText.implicitWidth
    implicitHeight: clockText.implicitHeight

    property date now: new Date()

    function toggleDateTime() {
        clockText.showDateTime = !clockText.showDateTime
    }

    Text {
        id: clockText
        property bool showDateTime: false

        text: showDateTime
              ? Qt.formatDateTime(clockRoot.now, "MM-dd-yyyy  hh:mm:ss AP")
              : Qt.formatTime(clockRoot.now, "hh:mm AP")

        color: vars.colWhite
        font.family: vars.fontFamily
        font.pixelSize: vars.iFontSz
        font.bold: true

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: clockRoot.now = new Date()
        }

        MouseArea {
            anchors.fill: parent
            onClicked: clockRoot.toggleDateTime()
        }
    }
}
