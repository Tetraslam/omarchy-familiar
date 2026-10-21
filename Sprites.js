.pragma library

// A little fox, 15×10 pixels, facing right, with three spare columns on the
// right for props (laptop, popcorn, berries). One character per pixel; '.' is
// empty. Frames are composed from the base sit pose plus small edits, so the
// fox stays the same fox in every frame.

var W = 18
var H = 10

var PALETTE = {
  o: "#e07b3c", // fur
  e: "#a8521f", // closed eye
  c: "#f4e3cf", // cream
  k: "#2b1f22", // eyes, nose
  q: "#5a3a2e", // paws
  p: "#ff9fb0", // blush, open mouth
  h: "#d46a7a", // headphones
  L: "#9fd3ff", // laptop screen
  l: "#8a8f99", // laptop body
  y: "#fff2b3", // popcorn
  r: "#d9474f", // popcorn box
  w: "#f7f4f1", // popcorn box stripe
  R: "#c2185b", // berry
  g: "#6fae5a", // berry leaf
  b: "#7e8ba3", // blanket
  B: "#c9cfdb"  // blanket dots
}

function pad(rows) {
  return rows.map(function(r) { return (r + "..................").slice(0, W) })
}

function edit(rows, cells) {
  var out = rows.slice()
  for (var i = 0; i < cells.length; i++) {
    var r = cells[i][0], c = cells[i][1], ch = cells[i][2]
    out[r] = out[r].slice(0, c) + ch + out[r].slice(c + 1)
  }
  return out
}

function row(rows, index, text) {
  var out = rows.slice()
  out[index] = (text + "..................").slice(0, W)
  return out
}

var SIT = pad([
  "..........o.o..",
  ".........ooooo.",
  ".........oooko.",
  "c........occcck",
  "co...oooooocc..",
  ".oooooooooocc..",
  "..oooooooooo...",
  "...o.o...o.o...",
  "...q.q...q.q...",
  "..............."
])

var BLINK = edit(SIT, [[2, 12, "e"]])
var WAG = edit(SIT, [[3, 0, "."], [3, 1, "c"], [4, 0, "."], [4, 1, "c"], [4, 2, "o"]])
var HAPPY = edit(SIT, [[2, 12, "e"], [3, 11, "p"]])
var HAPPY_WAG = edit(WAG, [[2, 12, "e"], [3, 11, "p"]])
var YAWN = edit(SIT, [[2, 12, "e"], [3, 12, "p"], [3, 13, "p"]])
var CHEW = edit(SIT, [[3, 13, "o"], [3, 12, "p"]])
var WALK_A = SIT
var WALK_B = row(row(SIT, 7, "....o.o...o.o.."), 8, "....q.q...q.q..")
var TYPE_A = edit(row(row(SIT, 7, "...o.o...o..o.."), 8, "...q.q...q..q.."),
                  [[4, 16, "L"], [5, 16, "L"], [6, 16, "L"], [7, 14, "l"], [7, 15, "l"], [7, 16, "l"], [7, 17, "l"]])
var TYPE_B = edit(SIT, [[6, 12, "o"], [6, 13, "q"],
                  [4, 16, "L"], [5, 16, "L"], [6, 16, "L"], [7, 14, "l"], [7, 15, "l"], [7, 16, "l"], [7, 17, "l"]])

var SLEEP_A = pad([
  "...............",
  "...............",
  "...............",
  "........o.o....",
  ".....oooooooo..",
  "...ooooooooeoo.",
  "..occooooooooc.",
  "..cccccoooooo..",
  "...ccc.........",
  "..............."
])
var SLEEP_B = row(SLEEP_A, 4, "....oooooooooo.")
var TIRED = edit(SLEEP_A, [[5, 11, "k"]])
var NAP = row(row(row(SLEEP_A, 6, ".bbbbbbbbbbbbb."), 7, ".bBbbBbbBbbBbb."), 8, ".bbbbbbbbbbbbb.")

// Props drawn over a frame.
var HEADPHONES = [[0, 10, "h"], [0, 11, "h"], [0, 12, "h"], [1, 9, "h"], [2, 9, "h"]]
var POPCORN_A = [[5, 16, "y"], [6, 15, "y"], [6, 16, "y"], [6, 17, "y"],
                 [7, 15, "r"], [7, 16, "w"], [7, 17, "r"], [8, 15, "r"], [8, 16, "w"], [8, 17, "r"]]
var POPCORN_B = [[4, 15, "y"], [5, 17, "y"], [6, 15, "y"], [6, 16, "y"], [6, 17, "y"],
                 [7, 15, "r"], [7, 16, "w"], [7, 17, "r"], [8, 15, "r"], [8, 16, "w"], [8, 17, "r"]]
var BERRY = [[2, 16, "g"], [3, 15, "R"], [3, 16, "R"], [4, 15, "R"], [4, 16, "R"]]

var FRAMES = {
  sit: SIT, blink: BLINK, wag: WAG, happy: HAPPY, happyWag: HAPPY_WAG, yawn: YAWN, chew: CHEW,
  walkA: WALK_A, walkB: WALK_B, typeA: TYPE_A, typeB: TYPE_B,
  sleepA: SLEEP_A, sleepB: SLEEP_B, tired: TIRED, nap: NAP
}

var PROPS = { headphones: HEADPHONES, popcornA: POPCORN_A, popcornB: POPCORN_B, berry: BERRY }
