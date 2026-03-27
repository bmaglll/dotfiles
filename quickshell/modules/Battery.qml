import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower

Item {
    id: batteryRoot
    Layout.alignment: Qt.AlignVCenter

    // parameters passed from Bar.qml
    property var vars
    property string fontFamily
    property int fontSize
    property color colCharging
    property color colLow
    property color colWarning

    // hover
    property color hoverBg: "transparent"
    property int hoverRadius: 10
    property int paddingH: 3
    property int paddingV: 2

    // size based on text
    implicitWidth: bg.width
    implicitHeight: bg.height

    // power device
    property var dev: UPower.displayDevice

    readonly property int perc: dev && dev.ready
                                ? Math.round(dev.percentage * 100)
                                : -1

    readonly property bool isCharging:
        dev && (dev.state === UPowerDeviceState.Charging
                || dev.state === UPowerDeviceState.PendingCharge)

    readonly property bool isLow: perc >= 0 && perc <= 25
    readonly property bool isWarning: perc >= 26 && perc <= 35
    readonly property bool isCritical: perc >= 0 && perc <= 15

    // flashing when critically low and not charging
    opacity: flashAnim.running ? flashAnim.currentValue : 1.0
    SequentialAnimation {
        id: flashAnim
        running: batteryRoot.isCritical && !batteryRoot.isCharging
        loops: Animation.Infinite
        property real currentValue: 1.0
        NumberAnimation { target: flashAnim; property: "currentValue"; from: 1.0; to: 0.3; duration: 600 }
        NumberAnimation { target: flashAnim; property: "currentValue"; from: 0.3; to: 1.0; duration: 600 }
    }

    Rectangle {
        id: bg
        width: row.implicitWidth + batteryRoot.paddingH * 2
        height: row.implicitHeight + batteryRoot.paddingV * 2
        radius: batteryRoot.hoverRadius
        color: mouse.containsMouse ? batteryRoot.hoverBg : "transparent"

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.NoButton
        }

        Row {
            id: row
            spacing: 4
            anchors.centerIn: parent

            Text {
                id: icon
                text: batteryRoot.perc >= 0 ? batteryIcon(batteryRoot.perc) : ""

                color: batteryRoot.isCharging
                       ? colCharging
                       : batteryRoot.isLow ? colLow
                       : batteryRoot.isWarning ? colWarning
                       : vars.colWhite

                font.family: fontFamily
                font.pixelSize: fontSize
                font.bold: true
            }

            Text {
                id: percent
                visible: true
                text: batteryRoot.perc >= 0 ? batteryRoot.perc + "%" : ""

                color: batteryRoot.isCharging
                       ? colCharging
                       : batteryRoot.isLow ? colLow
                       : batteryRoot.isWarning ? colWarning
                       : vars.colWhite

                font.family: fontFamily
                font.pixelSize: fontSize
                font.bold: true
            }
        }
    }

    function batteryIcon(p) {
        if (p <= 10) return "";
        if (p <= 30) return "";
        if (p <= 60) return "";
        if (p <= 85) return "";
        return "";
    }
}


