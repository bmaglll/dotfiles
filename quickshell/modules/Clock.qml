import QtQuick
import QtQuick.Layouts

Item {
    id: clockRoot
    Layout.alignment: Qt.AlignVCenter

    property var vars
    property bool showExpanded: false
    property bool _toggled: false

    implicitWidth: clockText.implicitWidth
    implicitHeight: clockText.implicitHeight

    property date now: new Date()

    Text {
        id: clockText

        text: (clockRoot.showExpanded || clockRoot._toggled)
              ? Qt.formatDateTime(clockRoot.now, "ddd MMM dd yyyy  -  hh:mm:ss AP")
              : Qt.formatTime(clockRoot.now, "hh:mm AP")

        color: vars.colWhite
        font.family: vars.fontFamily
        font.pixelSize: vars.iFontSz
        font.bold: false

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: clockRoot.now = new Date()
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: clockRoot._toggled = !clockRoot._toggled
    }
}
