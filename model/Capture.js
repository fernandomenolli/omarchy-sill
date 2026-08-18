.pragma library

// Hyprland announces every screen capture, a call and a screenshot alike, as
// `screencastv2` with `state,kind,label`. A screenshot is the one that starts
// and stops again immediately, which is what tells the two apart without
// watching any directory.
function parseEvent(name, data) {
  if (String(name) !== "screencastv2") return null

  var raw = String(data || "")
  var comma = raw.indexOf(",")
  if (comma < 0) return null

  var state = raw.slice(0, comma).trim()
  if (state !== "0" && state !== "1") return null

  return { starting: state === "1" }
}

// A capture this short was a screenshot. A call, a recording or a shared
// window lasts longer than anyone can click.
function wasScreenshot(startedAt, endedAt, longestMs) {
  if (!startedAt || !endedAt || endedAt < startedAt) return false
  return (endedAt - startedAt) <= longestMs
}
