const { load, test, eq } = require("../harness.js")
const Capture = load("Capture.js")

test("parseEvent reads the capture state", () => {
  eq(Capture.parseEvent("screencastv2", "1,0,Firefox").starting, true)
  eq(Capture.parseEvent("screencastv2", "0,0,Firefox").starting, false)
  eq(Capture.parseEvent("screencast", "1,0"), null)
  eq(Capture.parseEvent("screencastv2", "nonsense"), null)
})

test("a capture is a screenshot when it barely happened", () => {
  eq(Capture.wasScreenshot(1000, 1400, 2000), true)
  eq(Capture.wasScreenshot(1000, 9000, 2000), false)
  eq(Capture.wasScreenshot(0, 1400, 2000), false)
})
