// A little fox that lives in the bar and reacts to your day.
//
// It sleeps when you're away, types along while OpenCode agents work, wears
// headphones while music plays, gets popcorn when you watch something, hops
// when you commit, and cheers when an agent finishes. Click to pet, scroll for
// belly rubs, middle-click for a berry. Right-click tucks it into bed: a nap
// is a single still frame with every timer and poll stopped, so it costs
// nothing. With napOnBattery it naps by itself whenever you unplug.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import qs.Commons
import "Sprites.js" as Sprites

Item {
  id: root

  property var bar: null
  property var settings: ({})

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  readonly property string home: Quickshell.env("HOME")
  readonly property string name: String(setting("name", "kit"))
  readonly property bool napOnBattery: setting("napOnBattery", false) === true
  readonly property string projectsDir: String(setting("projectsDir", "~/Programming")).replace(/^~/, home)
  readonly property int yardScale: ({ "Small": 1, "Medium": 2, "Large": 3 })[String(setting("yard", "Medium"))] || 2

  readonly property int barSize: bar ? bar.barSize : Style.bar.sizeHorizontal
  readonly property bool vertical: bar ? bar.vertical : false
  readonly property int px: Math.max(1, Math.round(barSize / 13))
  readonly property int yardCells: vertical ? Sprites.W : Sprites.W * yardScale

  implicitWidth: vertical ? barSize : yardCells * px + Style.space(6)
  implicitHeight: vertical ? Sprites.H * px + Style.space(6) : barSize

  // ------------------------------------------------------------------ senses

  property var memory: ({ napping: false, pets: 0, treats: 0, day: "", lastDay: "" })
  readonly property bool napping: memory.napping === true
  readonly property bool onBattery: UPower.onBattery
  readonly property bool autoNap: napOnBattery && onBattery
  readonly property bool resting: napping || autoNap

  IdleMonitor {
    id: idle
    enabled: !root.resting
    timeout: 300
    respectInhibitors: true
  }
  readonly property bool away: !resting && idle.isIdle

  readonly property bool tired: {
    var d = UPower.displayDevice
    return onBattery && !!d && d.isPresent && d.percentage < 0.15
  }

  readonly property bool watching: {
    var ws = Hyprland.focusedWorkspace
    var tops = Hyprland.toplevels ? Hyprland.toplevels.values : []
    for (var i = 0; i < tops.length; i++)
      if (tops[i].workspace === ws && /crunchyroll|jellyfin|netflix/i.test(String(tops[i].title || ""))) return true
    return false
  }

  readonly property bool music: {
    var players = Mpris.players ? Mpris.players.values : []
    for (var i = 0; i < players.length; i++) if (players[i].isPlaying) return true
    return false
  }

  property int agents: 0

  // ------------------------------------------------------------------ memory

  function today() {
    var d = new Date()
    return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0") + "-" + String(d.getDate()).padStart(2, "0")
  }

  function remember(changes) {
    var next = Object.assign({}, memory, changes)
    if (next.day !== today()) { next.day = today(); next.pets = changes.pets !== undefined ? changes.pets : 0; next.treats = changes.treats !== undefined ? changes.treats : 0 }
    memory = next
    memoryFile.setText(JSON.stringify(next) + "\n")
  }

  FileView {
    id: memoryFile
    path: root.home + "/.local/state/omarchy-familiar/state.json"
    printErrors: false
    onLoaded: {
      try { root.memory = Object.assign({}, root.memory, JSON.parse(text())) } catch (error) {}
      root.greet()
    }
    onLoadFailed: {
      Quickshell.execDetached(["mkdir", "-p", root.home + "/.local/state/omarchy-familiar"])
      root.greet()
    }
  }

  // ------------------------------------------------------------------ body

  property int tick: 0
  property int cell: 0           // x position in sprite pixels
  property int facing: 1
  property int target: -1        // walk target, -1 while not walking
  property int restFor: 12       // ticks before wandering again
  property bool hovered: false
  property string reaction: ""
  property int reactionTicks: 0
  property int rubs: 0

  readonly property string mode: {
    if (resting) return "nap"
    if (away) return "sleep"
    if (reaction !== "") return reaction
    if (tired) return "tired"
    if (watching) return "popcorn"
    if (agents > 0) return "type"
    return target >= 0 ? "walk" : "idle"
  }

  function react(kind, ticks) {
    if (resting) return
    reaction = kind
    reactionTicks = ticks
    tick = 0
  }

  function greet() {
    if (memory.lastDay !== today() && !resting) {
      react("yawn", 6)
      spawn("☀", "#f2c94c")
      remember({ lastDay: today() })
    }
  }

  onAwayChanged: if (!away) greet()

  function pet() {
    if (napping) { wake(); return }
    if (autoNap) { spawn("z", root.dim); return }
    react("pet", 8)
    spawn("♥", "#d46a7a")
    remember({ pets: (memory.day === today() ? memory.pets : 0) + 1 })
  }

  function treat() {
    if (resting) return
    var eaten = memory.day === today() ? memory.treats : 0
    if (eaten >= 5) { react("full", 4); spawn("…", root.dim); return }
    react("treat", 10)
    remember({ treats: eaten + 1 })
  }

  function tuckIn() {
    reaction = ""
    target = -1
    remember({ napping: true })
  }

  function wake() {
    remember({ napping: false })
    react("yawn", 6)
  }

  function frameName() {
    var t = tick
    switch (mode) {
      case "nap": return "nap"
      case "sleep": return t % 2 ? "sleepB" : "sleepA"
      case "tired": return "tired"
      case "pet": return t % 2 ? "happyWag" : "happy"
      case "cheer": return t % 2 ? "happyWag" : "happy"
      case "hop": return "happy"
      case "yawn": return t < 4 ? "yawn" : "blink"
      case "full": return "blink"
      case "treat": return t < 4 ? "sit" : (t % 2 ? "chew" : "happy")
      case "popcorn": return t % 4 === 1 ? "chew" : "sit"
      case "type": return t % 2 ? "typeB" : "typeA"
      case "walk": return t % 2 ? "walkB" : "walkA"
    }
    if (t % 23 === 0) return "blink"
    if (t % 13 < 2) return "wag"
    return "sit"
  }

  function props() {
    var out = []
    if (music && ["nap", "sleep", "tired", "popcorn"].indexOf(mode) < 0) out = out.concat(Sprites.PROPS.headphones)
    if (mode === "popcorn") out = out.concat(tick % 4 === 1 ? Sprites.PROPS.popcornB : Sprites.PROPS.popcornA)
    if (mode === "treat" && tick < 4) out = out.concat(Sprites.PROPS.berry)
    return out
  }

  readonly property int hop: (mode === "hop" || mode === "cheer") && tick < 3 ? (tick === 1 ? 3 : 2)
    : (music && mode === "idle" && tick % 2 === 0 ? 1 : 0)

  function step() {
    tick++
    if (reaction !== "" && --reactionTicks <= 0) { reaction = ""; tick = 0 }

    if (mode === "sleep") {
      if (tick % 3 === 0) spawn("z", root.dim)
    } else if (mode === "walk") {
      if (cell === target) { target = -1; restFor = 10 + Math.floor(Math.random() * 30) }
      else { facing = target > cell ? 1 : -1; cell += facing }
    } else if (mode === "idle") {
      if (music && tick % 10 === 0) spawn("♪", "#d46a7a")
      var hour = new Date().getHours()
      if (hour >= 1 && hour < 5 && Math.random() < 0.015) react("yawn", 6)
      else if (!hovered && --restFor <= 0 && yardCells > Sprites.W) {
        var room = yardCells - Sprites.W
        target = Math.floor(Math.random() * (room + 1))
        if (target === cell) { target = -1; facing = -facing; restFor = 12 }
      }
    }
    if (mode === "treat" && tick === 4) spawn("♥", "#d46a7a")
    sprite.requestPaint()
  }

  Timer {
    id: clock
    running: root.visible && !root.resting
    repeat: true
    interval: root.away ? 1000 : (root.onBattery ? 400 : 250)
    onTriggered: root.step()
  }

  onModeChanged: sprite.requestPaint()
  onMusicChanged: sprite.requestPaint()

  // ------------------------------------------------------------------ polls

  // OpenCode's shared service: how many sessions are working right now.
  FileView {
    id: serviceFile
    path: root.home + "/.local/state/opencode/service.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
  }

  function pollAgents() {
    var service = null
    try { service = JSON.parse(serviceFile.text()) } catch (error) { return }
    if (!service || !service.url) return
    var request = new XMLHttpRequest()
    request.onreadystatechange = function() {
      if (request.readyState !== XMLHttpRequest.DONE || request.status !== 200) return
      var running = 0
      try {
        var data = JSON.parse(request.responseText).data || {}
        for (var id in data) if (data[id] && data[id].type === "running") running++
      } catch (error) { return }
      if (running < root.agents && !root.away) { root.react("cheer", 6); root.spawn("✓", "#8fa89a") }
      root.agents = running
    }
    request.open("GET", service.url + "/api/session/active")
    request.setRequestHeader("Authorization", "Basic " + Qt.btoa("opencode:" + (service.password || "")))
    request.send()
  }

  Timer {
    running: root.visible && !root.resting
    repeat: true
    interval: 15000
    triggeredOnStart: true
    onTriggered: root.pollAgents()
  }

  // New commits anywhere under the projects directory, from git's reflogs.
  property double lastLook: Date.now() / 1000

  Process {
    id: commitWatch
    command: ["bash", "-c",
      "find \"$1\" -maxdepth 6 -path '*/.git/*logs/HEAD' -newermt \"@$2\" 2>/dev/null | " +
      "while read -r f; do tail -n1 \"$f\" | grep -q $'\\tcommit' && echo \"$f\"; done",
      "familiar", root.projectsDir, String(Math.floor(root.lastLook))]
    stdout: StdioCollector {
      onStreamFinished: if (text.trim() !== "" && !root.away) { root.react("hop", 5); root.spawn("✦", "#f2c94c") }
    }
  }

  Timer {
    running: root.visible && !root.resting
    repeat: true
    interval: 60000
    onTriggered: {
      if (commitWatch.running) return
      commitWatch.running = true
      root.lastLook = Date.now() / 1000
    }
  }

  IpcHandler {
    target: "familiar"
    function pet(): void { root.pet() }
    function treat(): void { root.treat() }
    function nap(): void { root.tuckIn() }
    function wake(): void { root.wake() }
    function toggle(): void { root.napping ? root.wake() : root.tuckIn() }
    function state(): string {
      return JSON.stringify({ mode: root.mode, agents: root.agents, music: root.music, watching: root.watching,
                              away: root.away, napping: root.napping, autoNap: root.autoNap, memory: root.memory })
    }
  }

  // ------------------------------------------------------------------ view

  readonly property color dim: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.55)

  function tooltip() {
    var line = {
      nap: autoNap ? "napping while you're unplugged" : "tucked in · click to wake",
      sleep: "asleep until you're back",
      tired: "running on fumes",
      popcorn: "watching with you",
      type: agents === 1 ? "helping your agent" : "helping " + agents + " agents",
      walk: "wandering", idle: music ? "vibing" : "hanging out"
    }[mode] || "happy"
    var pets = memory.day === today() ? memory.pets : 0
    var treats = memory.day === today() ? memory.treats : 0
    return name + " · " + line + " · " + pets + " pets, " + treats + " treats today"
  }

  Canvas {
    id: sprite
    width: Sprites.W * root.px
    height: Sprites.H * root.px
    x: Style.space(3) + root.cell * root.px
    y: Math.round((root.barSize - height) / 2) - root.hop * root.px + root.px
    renderStrategy: Canvas.Cooperative

    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()
      var rows = Sprites.FRAMES[root.frameName()]
      var size = root.px
      var flip = root.facing < 0
      function dot(r, c, ch) {
        var color = Sprites.PALETTE[ch]
        if (!color) return
        ctx.fillStyle = color
        ctx.fillRect((flip ? Sprites.W - 1 - c : c) * size, r * size, size, size)
      }
      for (var r = 0; r < rows.length; r++)
        for (var c = 0; c < rows[r].length; c++) if (rows[r][c] !== ".") dot(r, c, rows[r][c])
      var extra = root.props()
      for (var i = 0; i < extra.length; i++) dot(extra[i][0], extra[i][1], extra[i][2])
    }
  }

  onPxChanged: sprite.requestPaint()
  onFacingChanged: sprite.requestPaint()
  Component.onCompleted: sprite.requestPaint()

  // Still "z" while napping: drawn once, nothing animates.
  Text {
    visible: root.mode === "nap"
    x: sprite.x + sprite.width * (root.facing > 0 ? 0.55 : 0.25)
    y: sprite.y - root.px
    text: "z"
    color: root.dim
    font.pixelSize: root.px * 4
    font.family: Style.font.family
  }

  // Floating hearts, notes, sparkles and z's.
  property int effectSeq: 0
  ListModel { id: effects }

  function spawn(glyph, color) {
    if (effects.count > 6) return
    var front = facing > 0 ? 0.7 : 0.15
    effects.append({ eid: ++effectSeq, glyph: glyph, tint: String(color),
                     ex: sprite.x + sprite.width * front + (Math.random() - 0.5) * px * 3 })
  }

  function dropEffect(eid) {
    for (var i = 0; i < effects.count; i++) if (effects.get(i).eid === eid) { effects.remove(i); return }
  }

  Repeater {
    model: effects
    delegate: Text {
      id: puff
      required property int eid
      required property string glyph
      required property string tint
      required property real ex
      x: ex
      y: root.barSize * 0.35
      text: glyph
      color: tint
      font.pixelSize: root.px * 4
      font.family: Style.font.family
      Component.onCompleted: rise.start()
      ParallelAnimation {
        id: rise
        NumberAnimation { target: puff; property: "y"; to: -root.px * 2; duration: 1200; easing.type: Easing.OutQuad }
        NumberAnimation { target: puff; property: "opacity"; from: 1; to: 0; duration: 1200; easing.type: Easing.InQuad }
        onFinished: root.dropEffect(puff.eid)
      }
    }
  }

  MouseArea {
    id: touch
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    cursorShape: Qt.PointingHandCursor
    onEntered: { root.hovered = true; if (root.bar) root.bar.showTooltip(touch, root.tooltip()) }
    onExited: { root.hovered = false; if (root.bar) root.bar.hideTooltip(touch) }
    onPositionChanged: function(mouse) {
      if (root.resting || root.mode === "sleep") return
      root.target = -1
      var middle = sprite.x + sprite.width / 2
      if (Math.abs(mouse.x - middle) > root.px * 2) root.facing = mouse.x < middle ? -1 : 1
    }
    onClicked: function(mouse) {
      if (root.bar) root.bar.hideTooltip(touch)
      if (mouse.button === Qt.RightButton) root.napping ? root.wake() : root.tuckIn()
      else if (mouse.button === Qt.MiddleButton) root.treat()
      else root.pet()
    }
    onWheel: function(wheel) {
      if (root.resting) return
      if (++root.rubs % 4 === 0) { root.react("pet", 4); root.spawn("♥", "#e8a6ae") }
    }
  }
}
