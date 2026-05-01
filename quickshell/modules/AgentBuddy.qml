import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Item {
    id: root
    property var vars
    property real walkAreaWidth: 120
    property string stateFile: "/tmp/agent-buddy-state"
    property var siblingPositions: function() { return [] }
    readonly property int cfgMinBuddySpacing: 20       // min px between buddies when stopping

    // --- Configurable Timers (ms unless noted) ---
    readonly property int cfgSleepTimeout: 60000       // idle time before sleep kicks in
    readonly property int cfgPoseDuration: 30000        // how long pose plays when completed task
    readonly property int cfgCringeDuration: 30000      // how long cringe plays when waiting for prompt
    readonly property int cfgWalkMinDuration: 5000     // min walk before activity
    readonly property int cfgWalkMaxDuration: 10000     // max walk before activity
    readonly property int cfgActivityMinDuration: 3000 // min activity duration during work
    readonly property int cfgActivityMaxDuration: 7000 // max activity duration during work
    readonly property int cfgStatePollInterval: 500    // how often to check state file
    readonly property int cfgTurnStepInterval: 100     // delay between turn animation steps
    readonly property int cfgWalkStepInterval: 50      // delay between walk position updates
    readonly property int cfgWalkSpeed: 1              // pixels per walk step
    readonly property int cfgDoneRemovalDelay: 60000   // ms before removing buddy after session ends (60s)

    property string activeState: "idle"
    property string nextState: ""
    property int currentFrame: 0

    readonly property real scaleFactor: .9
    // Per-pack scale overrides (omit to use scaleFactor)
    readonly property var packScale: ({
        "agent-buddy-jolteon": .85,
        "agent-buddy-mew": .8
    })
    readonly property real currentScale: packScale[currentPack] !== undefined ? packScale[currentPack] : scaleFactor

    // --- Sprite Pack System ---
    readonly property var packNames: [
        "agent-buddy", "agent-buddy-bulbasaur", "agent-buddy-charmander",
        "agent-buddy-chikorita", "agent-buddy-cyndaquil", "agent-buddy-flareon",
        "agent-buddy-jolteon", "agent-buddy-mew", "agent-buddy-mudkip",
        "agent-buddy-pikachu", "agent-buddy-plusle", "agent-buddy-squirtle",
        "agent-buddy-torchic", "agent-buddy-totodile", "agent-buddy-treecko",
        "agent-buddy-vulpix"
    ]

    // Per-pack animation data: { Idle: {w,h,d}, Walk: {w,h,d}, ... }
    readonly property var packData: ({
        "agent-buddy":            { Idle: {w:24,h:40,d:[30,16,10,16]}, Walk: {w:24,h:40,d:[8,10,8,10]}, Sleep: {w:24,h:40,d:[30,35]}, Eat: {w:24,h:32,d:[6,8,6,8]}, Cringe: {w:24,h:56,d:[2,8]}, Pose: {w:24,h:48,d:[8,1,3,2,8]}, EventSleep: {w:40,h:16,d:[30,35]} },
        "agent-buddy-bulbasaur":  { Idle: {w:32,h:40,d:[40,6,6]}, Walk: {w:40,h:40,d:[4,4,4,4,4,4]}, Sleep: {w:24,h:24,d:[30,35]}, Eat: {w:24,h:32,d:[6,8,6,8]}, Cringe: {w:24,h:56,d:[2,8]}, Pose: {w:24,h:32,d:[8,1,3,2,8]}, EventSleep: {w:24,h:24,d:[30,35]} },
        "agent-buddy-charmander": { Idle: {w:32,h:40,d:[12,8,8,8]}, Walk: {w:32,h:32,d:[6,8,6,8]}, Sleep: {w:32,h:24,d:[30,35]}, Eat: {w:24,h:32,d:[6,8,6,8]}, Cringe: {w:32,h:56,d:[2,8]}, Pose: {w:32,h:40,d:[12,2,8]}, EventSleep: {w:24,h:24,d:[30,35]} },
        "agent-buddy-chikorita":  { Idle: {w:24,h:48,d:[40,2,4,3,1,1]}, Walk: {w:24,h:32,d:[8,10,8,10]}, Sleep: {w:24,h:32,d:[30,35]}, Eat: {w:24,h:32,d:[6,8,6,8]}, Cringe: {w:32,h:56,d:[2,8]}, Pose: {w:24,h:32,d:[12,2,8]}, EventSleep: {w:32,h:32,d:[30,35]} },
        "agent-buddy-cyndaquil":  { Idle: {w:24,h:32,d:[40,16]}, Walk: {w:24,h:32,d:[6,8,6,8]}, Sleep: {w:24,h:24,d:[30,35]}, Eat: {w:24,h:32,d:[6,8,6,8]}, Cringe: {w:24,h:48,d:[2,8]}, Pose: {w:24,h:24,d:[12,2,8]}, EventSleep: {w:24,h:24,d:[30,35]} },
        "agent-buddy-flareon":    { Idle: {w:32,h:40,d:[12,16,12,16]}, Walk: {w:32,h:40,d:[8,8,8,8]}, Sleep: {w:32,h:32,d:[30,35]}, Eat: {w:24,h:40,d:[6,8,6,8]}, Cringe: {w:24,h:56,d:[2,8]}, Pose: {w:24,h:48,d:[8,1,3,2,8]}, EventSleep: {w:40,h:24,d:[30,35]} },
        "agent-buddy-jolteon":    { Idle: {w:32,h:40,d:[60,16]}, Walk: {w:32,h:40,d:[8,10,8,10]}, Sleep: {w:32,h:32,d:[30,35]}, Eat: {w:24,h:40,d:[6,8,6,8]}, Cringe: {w:40,h:56,d:[2,8]}, Pose: {w:32,h:48,d:[8,1,3,2,8]}, EventSleep: {w:32,h:24,d:[30,35]} },
        "agent-buddy-mew":        { Idle: {w:32,h:56,d:[12,8,12,8]}, Walk: {w:40,h:64,d:[8,8,8,8,8,8]}, Sleep: {w:24,h:56,d:[16,12,16,16,12,16]}, Eat: {w:24,h:40,d:[6,8,6,8]}, Cringe: {w:32,h:56,d:[2,8]}, Pose: {w:32,h:40,d:[12,2,8]}, EventSleep: {w:24,h:24,d:[30,35]} },
        "agent-buddy-mudkip":     { Idle: {w:24,h:40,d:[38,2,2,5,3,3,2]}, Walk: {w:32,h:40,d:[4,6,4,6,6,4]}, Sleep: {w:24,h:24,d:[30,35]}, Eat: {w:24,h:24,d:[6,8,6,8]}, Cringe: {w:32,h:56,d:[2,8]}, Pose: {w:24,h:32,d:[8,1,3,2,8]}, EventSleep: {w:24,h:24,d:[30,35]} },
        "agent-buddy-pikachu":    { Idle: {w:40,h:56,d:[40,2,3,3,3,2]}, Walk: {w:32,h:40,d:[8,10,8,10]}, Sleep: {w:32,h:40,d:[30,35]}, Eat: {w:24,h:48,d:[6,8,6,8]}, Cringe: {w:24,h:64,d:[2,8]}, Pose: {w:32,h:40,d:[12,2,8]}, EventSleep: {w:24,h:32,d:[30,35]} },
        "agent-buddy-plusle":     { Idle: {w:24,h:32,d:[30,10,6,10]}, Walk: {w:24,h:40,d:[6,4,8,4,6,4,8,4]}, Sleep: {w:24,h:32,d:[30,35]}, Eat: {w:24,h:32,d:[6,8,6,8]}, Cringe: {w:24,h:56,d:[2,8]}, Pose: {w:24,h:40,d:[8,1,3,2,8]}, EventSleep: {w:24,h:16,d:[30,35]} },
        "agent-buddy-squirtle":   { Idle: {w:32,h:32,d:[30,2,2,4,4,4,2,2]}, Walk: {w:32,h:32,d:[12,8,12,8]}, Sleep: {w:24,h:24,d:[30,35]}, Eat: {w:24,h:32,d:[6,8,6,8]}, Cringe: {w:24,h:48,d:[2,8]}, Pose: {w:24,h:32,d:[12,2,8]}, EventSleep: {w:40,h:24,d:[30,35]} },
        "agent-buddy-torchic":    { Idle: {w:24,h:40,d:[30,3,4,3,3]}, Walk: {w:24,h:32,d:[8,8,8,8]}, Sleep: {w:24,h:32,d:[30,35]}, Eat: {w:24,h:32,d:[6,8,6,8]}, Cringe: {w:32,h:56,d:[2,8]}, Pose: {w:24,h:40,d:[12,2,1,2,1,2,1,2]}, EventSleep: {w:32,h:16,d:[30,35]} },
        "agent-buddy-totodile":   { Idle: {w:32,h:48,d:[30,4,2,6,3,2,3]}, Walk: {w:24,h:32,d:[8,10,8,10]}, Sleep: {w:24,h:32,d:[30,35]}, Eat: {w:24,h:32,d:[6,8,6,8]}, Cringe: {w:24,h:56,d:[2,8]}, Pose: {w:24,h:32,d:[12,2,8]}, EventSleep: {w:24,h:24,d:[30,35]} },
        "agent-buddy-treecko":    { Idle: {w:32,h:40,d:[40,4,2]}, Walk: {w:32,h:32,d:[6,10,6,10]}, Sleep: {w:32,h:32,d:[30,35]}, Eat: {w:24,h:32,d:[6,8,6,8]}, Cringe: {w:24,h:64,d:[2,8]}, Pose: {w:24,h:32,d:[12,2,8]}, EventSleep: {w:32,h:16,d:[30,35]} },
        "agent-buddy-vulpix":     { Idle: {w:32,h:32,d:[40,12,20,12]}, Walk: {w:32,h:40,d:[6,4,4,4,6]}, Sleep: {w:24,h:24,d:[30,35]}, Eat: {w:24,h:24,d:[6,8,6,8]}, Cringe: {w:24,h:56,d:[2,8]}, Pose: {w:24,h:40,d:[8,1,3,2,8]}, EventSleep: {w:24,h:24,d:[30,35]} }
    })

    property int packIndex: {
        // Deterministic hash from stateFile so all bars pick the same pack
        var hash = 0
        for (var i = 0; i < stateFile.length; i++) {
            hash = ((hash << 5) - hash) + stateFile.charCodeAt(i)
            hash |= 0
        }
        return Math.abs(hash) % packNames.length
    }
    readonly property string currentPack: packNames[packIndex]
    readonly property var pack: packData[currentPack]
    readonly property string packPath: "../assets/" + currentPack + "/"

    function buildStateConfig() {
        var p = pack
        var path = packPath
        return {
            "idle":        { source: path+"Idle-Anim.png",   frameWidth: p.Idle.w, frameHeight: p.Idle.h, direction: 0, offsetY: 6, durations: p.Idle.d, loops: true },
            "walk_right":  { source: path+"Walk-Anim.png",   frameWidth: p.Walk.w, frameHeight: p.Walk.h, direction: 2, offsetY: 6, durations: p.Walk.d, loops: true },
            "walk_left":   { source: path+"Walk-Anim.png",   frameWidth: p.Walk.w, frameHeight: p.Walk.h, direction: 6, offsetY: 6, durations: p.Walk.d, loops: true },
            "cringe":      { source: path+"Cringe-Anim.png", frameWidth: p.Cringe.w, frameHeight: p.Cringe.h, direction: 0, offsetY: 10, durations: p.Cringe.d, loops: true },
            "sleep_sit":   { source: path+"Sleep-Anim.png",  frameWidth: p.Sleep.w, frameHeight: p.Sleep.h, direction: 0, offsetY: 6, durations: p.Sleep.d, loops: true },
            "sleep_curled":{ source: path+"EventSleep-Anim.png", frameWidth: p.EventSleep.w, frameHeight: p.EventSleep.h, direction: 0, offsetY: 4, durations: p.EventSleep.d, loops: true },
            "sleep_sit_m": { source: path+"Sleep-Anim.png",  frameWidth: p.Sleep.w, frameHeight: p.Sleep.h, direction: 0, offsetY: 6, mirror: true, durations: p.Sleep.d, loops: true },
            "sleep_curled_m":{ source: path+"EventSleep-Anim.png", frameWidth: p.EventSleep.w, frameHeight: p.EventSleep.h, direction: 0, offsetY: 4, mirror: true, durations: p.EventSleep.d, loops: true },
            "pose":        { source: path+"Pose-Anim.png",   frameWidth: p.Pose.w, frameHeight: p.Pose.h, direction: 0, offsetY: 4, durations: p.Pose.d, loops: true },
            "eat":         { source: path+"Eat-Anim.png",    frameWidth: p.Eat.w, frameHeight: p.Eat.h, direction: 0, offsetY: 6, durations: p.Eat.d, loops: true }
        }
    }

    property var stateConfig: buildStateConfig()

    function switchPack(idx) {
        packIndex = idx
        stateConfig = buildStateConfig()
        setState("idle")
    }

    // --- External state from agent hooks ---
    property string externalState: "idle"
    property real lastStateChangeTime: 0
    readonly property real sleepTimeout: cfgSleepTimeout

    Process {
        id: stateProc
        stdout: StdioCollector {
            onStreamFinished: {
                var s = this.text.trim()
                if (s !== "" && s !== root.externalState) {
                    root.externalState = s
                    root.lastStateChangeTime = Date.now()
                    root.applyExternalState(s)
                }
            }
        }
    }

    Timer {
        id: statePollTimer
        interval: root.cfgStatePollInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!stateProc.running)
                stateProc.exec({ command: ["cat", root.stateFile] })
            if ((root.externalState === "idle" || root.externalState === "done" || root.externalState === "waiting") && root.lastStateChangeTime > 0
                && (Date.now() - root.lastStateChangeTime) > root.sleepTimeout
                && root.activeState !== "sleep_sit" && root.activeState !== "sleep_curled"
                && root.activeState !== "sleep_sit_m" && root.activeState !== "sleep_curled_m") {
                root.applyExternalState("sleep")
            }
        }
    }

    // --- Done removal: delete state file after timeout ---
    Process { id: removeProc }
    Timer {
        id: doneRemovalTimer
        interval: root.cfgDoneRemovalDelay
        repeat: false
        onTriggered: {
            removeProc.exec({ command: ["rm", "-f", root.stateFile] })
        }
    }

    function applyExternalState(extState) {
        switch (extState) {
            case "working":
                doneRemovalTimer.stop()
                startWorkLoop()
                break
            case "waiting":
                doneRemovalTimer.stop()
                stopWorkLoop()
                setState("cringe")
                cringeTimer.start()
                break
            case "done":
                stopWorkLoop()
                setState("pose")
                poseTimer.start()
                doneRemovalTimer.start()
                break
            case "sleep":
                stopWorkLoop()
                setState("sleep")
                break
            case "idle":
            default:
                stopWorkLoop()
                if (activeState !== "idle")
                    setState("idle")
                break
        }
    }

    // --- Work loop: walk + activity cycling ---
    property bool workLoopActive: false
    readonly property var workActivities: ["eat", "idle"]

    function startWorkLoop() {
        if (!workLoopActive) {
            workLoopActive = true
            setState("turning_right", "walk_right")
            scheduleWorkActivity()
        }
    }

    function stopWorkLoop() {
        workLoopActive = false
        workActivityTimer.stop()
        workResumeTimer.stop()
    }

    function scheduleWorkActivity() {
        workActivityTimer.interval = root.cfgWalkMinDuration + Math.random() * (root.cfgWalkMaxDuration - root.cfgWalkMinDuration)
        workActivityTimer.start()
    }

    Timer {
        id: cringeTimer
        interval: root.cfgCringeDuration
        repeat: false
        onTriggered: {
            if (root.activeState === "cringe")
                root.setState("idle")
        }
    }

    Timer {
        id: poseTimer
        interval: root.cfgPoseDuration
        repeat: false
        onTriggered: {
            if (root.activeState === "pose")
                root.setState("idle")
        }
    }

    Timer {
        id: workActivityTimer
        repeat: false
        onTriggered: {
            if (!root.workLoopActive) return
            if (root.isTooCloseToSibling()) {
                // Too close to another buddy, keep walking a bit longer
                root.scheduleWorkActivity()
                return
            }
            var activity = root.workActivities[Math.floor(Math.random() * root.workActivities.length)]
            root.setState(activity)
            workResumeTimer.interval = root.cfgActivityMinDuration + Math.random() * (root.cfgActivityMaxDuration - root.cfgActivityMinDuration)
            workResumeTimer.start()
        }
    }

    Timer {
        id: workResumeTimer
        repeat: false
        onTriggered: {
            if (!root.workLoopActive) return
            root.setState("turning_right", "walk_right")
            root.scheduleWorkActivity()
        }
    }

    // --- Direction rows ---
    readonly property var turnSequences: ({
        "turning_right":      [0, 1, 2],
        "turning_left":       [0, 7, 6],
        "turning_right_to_left": [2, 1, 0, 7, 6],
        "turning_left_to_right": [6, 7, 0, 1, 2]
    })

    readonly property bool isTurning: turnSequences.hasOwnProperty(activeState)
    property int turnStep: 0

    readonly property var currentConfig: isTurning ? stateConfig["idle"] : (stateConfig[activeState] || stateConfig["idle"])
    readonly property int frameCount: currentConfig.durations.length

    readonly property int currentDirection: {
        if (isTurning) {
            var seq = turnSequences[activeState]
            return seq[turnStep]
        }
        return currentConfig.direction
    }

    readonly property int packStateOffset: {
        if (currentPack === "agent-buddy-mew") {
            if (activeState === "sleep_sit" || activeState === "sleep_sit_m" || activeState === "sleep_curled" || activeState === "sleep_curled_m")
                return 4
            if (activeState === "idle" || activeState === "walk_right" || activeState === "walk_left" || activeState === "pose")
                return 2
        }
        return 0
    }

    width: currentConfig.frameWidth * currentScale
    height: currentConfig.frameHeight * currentScale
    y: (parent.height - height) / 2 + (currentConfig.offsetY || 0) + packStateOffset

    readonly property var sleepVariants: ["sleep_sit", "sleep_curled", "sleep_sit_m", "sleep_curled_m"]

    Component.onCompleted: {
        // Offset spawn position if too close to an existing buddy
        var positions = siblingPositions()
        for (var i = 0; i < positions.length; i++) {
            if (Math.abs(root.x - positions[i]) < cfgMinBuddySpacing) {
                root.x = Math.min(walkAreaWidth - width, positions[i] + cfgMinBuddySpacing)
                break
            }
        }
    }

    function isTooCloseToSibling() {
        var positions = siblingPositions()
        for (var i = 0; i < positions.length; i++) {
            if (Math.abs(root.x - positions[i]) < cfgMinBuddySpacing)
                return true
        }
        return false
    }

    function setState(newState, next) {
        nextState = next || ""
        currentFrame = 0
        turnStep = 0
        if (newState === "sleep") {
            newState = sleepVariants[Math.floor(Math.random() * sleepVariants.length)]
        }
        activeState = newState
    }

    Image {
        id: sprite
        source: root.currentConfig.source
        sourceClipRect: Qt.rect(
            root.currentFrame * root.currentConfig.frameWidth,
            root.currentDirection * root.currentConfig.frameHeight,
            root.currentConfig.frameWidth,
            root.currentConfig.frameHeight
        )
        width: root.currentConfig.frameWidth * root.currentScale
        height: root.currentConfig.frameHeight * root.currentScale
        smooth: false
        mirror: root.currentConfig.mirror || false
    }

    Timer {
        id: animTimer
        interval: root.currentConfig.durations[root.currentFrame] * 42
        running: !root.isTurning
        repeat: true
        onTriggered: {
            root.currentFrame = (root.currentFrame + 1) % root.frameCount
        }
    }

    Timer {
        id: turnTimer
        interval: root.cfgTurnStepInterval
        running: root.isTurning
        repeat: true
        onTriggered: {
            var seq = root.turnSequences[root.activeState]
            root.turnStep++
            if (root.turnStep >= seq.length) {
                if (root.nextState !== "")
                    root.setState(root.nextState)
            }
        }
    }

    Timer {
        id: walkTimer
        interval: root.cfgWalkStepInterval
        running: root.activeState === "walk_right" || root.activeState === "walk_left"
        repeat: true
        onTriggered: {
            var speed = root.cfgWalkSpeed
            if (root.activeState === "walk_right") {
                root.x += speed
                if (root.x >= root.walkAreaWidth - root.width) {
                    root.setState("turning_right_to_left", "walk_left")
                }
            } else {
                root.x -= speed
                if (root.x <= 0) {
                    root.setState("turning_left_to_right", "walk_right")
                }
            }
        }
    }

    // --- Testing: left-click cycles animations, right-click cycles sprites ---
    readonly property var testStates: ["idle", "walk_right", "cringe", "sleep", "pose", "eat"]
    property int testIndex: 0

    MouseArea {
        anchors.fill: sprite
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                root.switchPack((root.packIndex + 1) % root.packNames.length)
            } else {
                root.testIndex = (root.testIndex + 1) % root.testStates.length
                var next = root.testStates[root.testIndex]
                if (next === "walk_right") {
                    root.setState("turning_right", "walk_right")
                } else if (root.activeState === "walk_right" || root.activeState === "walk_left") {
                    root.setState("turning_left_to_right", next)
                } else {
                    root.setState(next)
                }
            }
        }
    }
}
