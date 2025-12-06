import QtQuick

Item {
    id: clockRoot
    Layout.alignment: Qt.AlignVCenter

    // pass color + font from vars
    property var vars

    implicitWidth: clockText.implicitWidth
    implicitHeight: clockText.implicitHeight

    Text {
        id: clockText

        property bool showDate: false

        text: showDate
              ? Qt.formatDate(new Date(), "MM-dd-yyyy")
              : Qt.formatTime(new Date(), "hh:mm")

        color: vars.colWhite
        font.family: vars.fontFamily
        font.pixelSize: vars.iFontSz
        font.bold: true

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: {
                clockText.text = clockText.showDate
                    ? Qt.formatDate(new Date(), "MM-dd-yyyy")
                    : Qt.formatTime(new Date(), "hh:mm")
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: clockText.showDate = !clockText.showDate
        }
    }
}


