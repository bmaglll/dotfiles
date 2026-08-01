import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    // styling
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 12
    property int gap: 6
    property color colNormal: "white"
    property color colWarning: "#ffaa00"
    property color colCritical: "#ff5555"

    // hover / popup
    property color hoverBg: "transparent"
    property int hoverRadius: 10
    property int paddingH: 5
    property int paddingV: 2
    property var panelWindow

    // polling
    property int pollInterval: 2000
    property int tempPollInterval: 3000

    // thresholds (percentage, used for CPU/RAM)
    property real warningThreshold: 70
    property real criticalThreshold: 90

    // temperature thresholds (°C)
    property real tempWarningThreshold: 65
    property real tempCriticalThreshold: 80
    property real tempOverheatThreshold: 90

    // CPU state
    property real cpuPercent: 0.0
    property var prevIdle: 0
    property var prevTotal: 0
    property bool hasPrev: false
    property var corePercents: []          // [{index, percent}]
    property var prevCoreIdle: ({})
    property var prevCoreTotal: ({})

    // RAM state
    property real ramPercent: 0.0
    property real ramTotalKB: 0
    property real ramAvailableKB: 0
    property real ramBuffersKB: 0
    property real ramCachedKB: 0
    readonly property real ramUsedKB: Math.max(0, ramTotalKB - ramAvailableKB)

    // Temperature state
    property real tempValue: -1
    property var sensorGroups: []          // [{chipLabel, sensors:[{label, tempC}]}]

    function colorForPercent(p) {
        if (p >= root.criticalThreshold) return root.colCritical
        if (p >= root.warningThreshold) return root.colWarning
        return root.colNormal
    }

    function colorForTemp(c) {
        if (c >= root.tempCriticalThreshold) return root.colCritical
        if (c >= root.tempWarningThreshold) return root.colWarning
        return root.colNormal
    }

    function fmtGiB(kb) {
        return (kb / 1024 / 1024).toFixed(1) + " GiB"
    }

    readonly property color cpuColor: colorForPercent(root.cpuPercent)
    readonly property color ramColor: colorForPercent(root.ramPercent)

    readonly property color tempColor: {
        if (root.tempValue < 0) return root.colNormal
        return colorForTemp(root.tempValue)
    }
    readonly property bool isOverheating: root.tempValue >= root.tempOverheatThreshold

    implicitWidth: bg.width
    implicitHeight: bg.height

    SequentialAnimation {
        id: flashAnim
        running: root.isOverheating
        loops: Animation.Infinite
        property real currentValue: 1.0
        NumberAnimation { target: flashAnim; property: "currentValue"; from: 1.0; to: 0.3; duration: 600 }
        NumberAnimation { target: flashAnim; property: "currentValue"; from: 0.3; to: 1.0; duration: 600 }
    }

    Rectangle {
        id: bg
        width: row.implicitWidth + root.paddingH * 2
        height: row.implicitHeight + root.paddingV * 2
        radius: root.hoverRadius
        color: mouse.containsMouse ? root.hoverBg : "transparent"

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            onClicked: mouseEvent => {
                if (mouseEvent.button === Qt.MiddleButton) {
                    btopLauncher.exec({ command: ["hyprctl", "dispatch", "hl.dsp.exec_cmd(\"[float;size 80% 80%;center] ghostty -e btop\")"] })
                } else {
                    popup.visible = !popup.visible
                }
            }
        }

        Row {
            id: row
            spacing: root.gap
            anchors.centerIn: parent

            Text {
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                color: root.cpuColor
                text: "\u{f0ee0}"
            }

            Text {
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                color: root.cpuColor
                text: Math.round(root.cpuPercent) + "%"
            }

            Text {
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                color: root.ramColor
                text: "\u{efc5}"
            }

            Text {
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                color: root.ramColor
                text: Math.round(root.ramPercent) + "%"
            }

            Item {
                width: tempRow.implicitWidth
                height: tempRow.implicitHeight
                opacity: flashAnim.running ? flashAnim.currentValue : 1.0

                Row {
                    id: tempRow
                    spacing: root.gap

                    Text {
                        font.family: root.fontFamily
                        font.pixelSize: root.fontSize
                        color: root.tempColor
                        text: "\u{f2c9}"
                    }

                    Text {
                        font.family: root.fontFamily
                        font.pixelSize: root.fontSize
                        color: root.tempColor
                        text: root.tempValue >= 0 ? Math.round(root.tempValue) + "°C" : "--"
                    }
                }
            }
        }
    }

    PopupWindow {
        id: popup
        visible: false
        width: 300
        height: popupContent.height
        color: "transparent"

        anchor {
            window: root.panelWindow
            edges: Edges.Top | Edges.Left
            gravity: Edges.Bottom | Edges.Right
            onAnchoring: {
                var pos = root.mapToItem(root.panelWindow.contentItem, 0, 0)
                anchor.rect.x = pos.x + (root.width / 2) - (popup.width / 2)
                anchor.rect.y = pos.y + root.height
            }
        }

        Rectangle {
            id: popupContent
            width: popup.width
            height: col.height + 20
            color: Qt.rgba(17 / 255, 17 / 255, 27 / 255, 0.85)
            radius: 12
            border.width: 2
            border.color: Qt.rgba(205 / 255, 214 / 255, 244 / 255, 0.2)

            Column {
                id: col
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 10
                spacing: 8

                // ---- CPU ----
                Text {
                    text: "CPU  " + Math.round(root.cpuPercent) + "%"
                    font.family: root.fontFamily
                    font.pixelSize: 11
                    font.bold: true
                    color: root.cpuColor
                }

                Grid {
                    columns: 4
                    columnSpacing: 14
                    rowSpacing: 2
                    width: col.width

                    Repeater {
                        model: root.corePercents
                        Text {
                            text: "C" + modelData.index + " " + Math.round(modelData.percent) + "%"
                            font.family: root.fontFamily
                            font.pixelSize: 10
                            color: root.colorForPercent(modelData.percent)
                        }
                    }
                }

                Rectangle { width: col.width; height: 1; color: Qt.rgba(1, 1, 1, 0.1) }

                // ---- RAM ----
                Text {
                    text: "RAM  " + Math.round(root.ramPercent) + "%"
                    font.family: root.fontFamily
                    font.pixelSize: 11
                    font.bold: true
                    color: root.ramColor
                }

                Repeater {
                    model: [
                        { label: "Used", kb: root.ramUsedKB },
                        { label: "Available", kb: root.ramAvailableKB },
                        { label: "Buffers", kb: root.ramBuffersKB },
                        { label: "Cached", kb: root.ramCachedKB },
                        { label: "Total", kb: root.ramTotalKB }
                    ]
                    Row {
                        width: col.width
                        Text {
                            text: modelData.label
                            width: col.width - 90
                            font.family: root.fontFamily
                            font.pixelSize: 10
                            color: "#cdd6f4"
                        }
                        Text {
                            text: root.fmtGiB(modelData.kb)
                            font.family: root.fontFamily
                            font.pixelSize: 10
                            color: "#cdd6f4"
                        }
                    }
                }

                Rectangle { width: col.width; height: 1; color: Qt.rgba(1, 1, 1, 0.1) }

                // ---- Temperature ----
                Text {
                    text: "Temperature"
                    font.family: root.fontFamily
                    font.pixelSize: 11
                    font.bold: true
                    color: root.tempColor
                }

                Text {
                    visible: root.sensorGroups.length === 0
                    text: "No sensors found"
                    font.family: root.fontFamily
                    font.pixelSize: 10
                    color: "#8f8f8f"
                }

                Repeater {
                    model: root.sensorGroups
                    Column {
                        width: col.width
                        spacing: 1

                        Text {
                            text: modelData.chipLabel
                            font.family: root.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                            color: "#a6adc8"
                        }

                        Repeater {
                            model: modelData.sensors
                            Row {
                                width: col.width
                                leftPadding: 8
                                Text {
                                    text: modelData.label
                                    width: col.width - 90
                                    font.family: root.fontFamily
                                    font.pixelSize: 10
                                    color: root.colorForTemp(modelData.tempC)
                                }
                                Text {
                                    text: Math.round(modelData.tempC) + "°C"
                                    font.family: root.fontFamily
                                    font.pixelSize: 10
                                    color: root.colorForTemp(modelData.tempC)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Process { id: btopLauncher }

    Process {
        id: statProc
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n")
                if (lines.length === 0) return

                // aggregate line: "cpu  user nice system idle iowait irq softirq ..."
                var aggParts = lines[0].split(/\s+/)
                if (aggParts.length >= 11) {
                    var fields = []
                    for (var i = 1; i <= 10; i++)
                        fields.push(parseInt(aggParts[i]))

                    var idle = fields[3] + fields[4]
                    var total = 0
                    for (var j = 0; j < fields.length; j++)
                        total += fields[j]

                    if (root.hasPrev) {
                        var dTotal = total - root.prevTotal
                        var dIdle = idle - root.prevIdle
                        if (dTotal > 0)
                            root.cpuPercent = (1.0 - dIdle / dTotal) * 100
                    }

                    root.prevIdle = idle
                    root.prevTotal = total
                    root.hasPrev = true
                }

                // per-core lines: "cpu0 ...", "cpu1 ...", ...
                var cores = []
                var newPrevIdle = {}
                var newPrevTotal = {}
                for (var k = 1; k < lines.length; k++) {
                    var m = lines[k].match(/^cpu(\d+)\s+(.*)/)
                    if (!m) continue
                    var coreIdx = parseInt(m[1])
                    var coreParts = m[2].split(/\s+/)
                    if (coreParts.length < 10) continue

                    var cFields = []
                    for (var c = 0; c <= 9; c++)
                        cFields.push(parseInt(coreParts[c]))

                    var cIdle = cFields[3] + cFields[4]
                    var cTotal = 0
                    for (var d = 0; d < cFields.length; d++)
                        cTotal += cFields[d]

                    var pct = 0
                    if (root.prevCoreTotal[coreIdx] !== undefined) {
                        var dcTotal = cTotal - root.prevCoreTotal[coreIdx]
                        var dcIdle = cIdle - root.prevCoreIdle[coreIdx]
                        if (dcTotal > 0)
                            pct = (1.0 - dcIdle / dcTotal) * 100
                    }

                    cores.push({ index: coreIdx, percent: pct })
                    newPrevIdle[coreIdx] = cIdle
                    newPrevTotal[coreIdx] = cTotal
                }

                root.prevCoreIdle = newPrevIdle
                root.prevCoreTotal = newPrevTotal
                root.corePercents = cores
            }
        }
    }

    Process {
        id: memProc
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n")
                var total = 0, available = 0, buffers = 0, cached = 0

                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split(/\s+/)
                    if (parts[0] === "MemTotal:")
                        total = parseInt(parts[1])
                    else if (parts[0] === "MemAvailable:")
                        available = parseInt(parts[1])
                    else if (parts[0] === "Buffers:")
                        buffers = parseInt(parts[1])
                    else if (parts[0] === "Cached:")
                        cached = parseInt(parts[1])
                }

                if (total > 0)
                    root.ramPercent = (1.0 - available / total) * 100

                root.ramTotalKB = total
                root.ramAvailableKB = available
                root.ramBuffersKB = buffers
                root.ramCachedKB = cached
            }
        }
    }

    Process {
        id: tempProc
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n")
                var groupsOrder = []
                var groupsMap = {}
                var hottest = -1

                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split("\x1f")
                    if (parts.length < 5) continue

                    var hwmonDir = parts[0]
                    var chipName = parts[1]
                    var tempKey = parts[2]
                    var label = parts[3]
                    var milli = parseInt(parts[4])
                    if (isNaN(milli)) continue

                    var tempC = milli / 1000
                    if (tempC < -50 || tempC > 150) continue

                    var displayLabel = label && label.length > 0 ? label : tempKey
                    var groupKey = chipName + " (" + hwmonDir + ")"

                    if (!groupsMap[groupKey]) {
                        groupsMap[groupKey] = { chipLabel: groupKey, sensors: [] }
                        groupsOrder.push(groupKey)
                    }
                    groupsMap[groupKey].sensors.push({ label: displayLabel, tempC: tempC })

                    if (tempC > hottest)
                        hottest = tempC
                }

                var groups = []
                for (var g = 0; g < groupsOrder.length; g++)
                    groups.push(groupsMap[groupsOrder[g]])

                root.sensorGroups = groups
                root.tempValue = hottest
            }
        }
    }

    Timer {
        interval: root.pollInterval
        repeat: true
        running: true
        triggeredOnStart: true

        onTriggered: {
            if (!statProc.running)
                statProc.exec({ command: ["grep", "^cpu", "/proc/stat"] })
            if (!memProc.running)
                memProc.exec({ command: ["grep", "-E", "^(MemTotal|MemAvailable|Buffers|Cached):", "/proc/meminfo"] })
        }
    }

    Timer {
        interval: root.tempPollInterval
        repeat: true
        running: true
        triggeredOnStart: true

        onTriggered: {
            if (!tempProc.running)
                tempProc.exec({
                    command: ["sh", "-c",
                        "for c in /sys/class/hwmon/hwmon*; do " +
                        "h=$(basename \"$c\"); n=$(cat \"$c/name\" 2>/dev/null); " +
                        "for f in \"$c\"/temp*_input; do " +
                        "[ -e \"$f\" ] || continue; " +
                        "i=$(basename \"$f\" _input); " +
                        "lbl=$(cat \"$c/${i}_label\" 2>/dev/null); " +
                        "v=$(cat \"$f\" 2>/dev/null); " +
                        "printf '%s\\037%s\\037%s\\037%s\\037%s\\n' \"$h\" \"$n\" \"$i\" \"$lbl\" \"$v\"; " +
                        "done; done"
                    ]
                })
        }
    }
}
