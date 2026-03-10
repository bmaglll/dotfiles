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

    // UI behavior
    property bool showPercent: false

    // size based on text
    implicitWidth: icon.width + (showPercent ? percent.width + 6 : 0)
    implicitHeight: percent.implicitHeight

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

    // icon
    Text {
        id: icon
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter

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

    // percentage text
    Text {
        id: percent
        visible: batteryRoot.showPercent
        anchors.left: icon.right
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter

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

    function batteryIcon(p) {
        if (p <= 10) return "";
        if (p <= 30) return "";
        if (p <= 60) return "";
        if (p <= 85) return "";
        return "";
    }
}


