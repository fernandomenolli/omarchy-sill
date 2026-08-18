// Every tests/model/*.test.js is picked up automatically, so a new model file
// means a new test file rather than an edit here.
//
//   node tests/run.js
//
// No dependencies and no framework: the plugin ships no package.json and is
// not built, so a suite that needed installing would not get run.

const fs = require("fs")
const path = require("path")
const harness = require("./harness.js")

const dir = path.join(__dirname, "model")
const files = fs.readdirSync(dir).filter(name => name.endsWith(".test.js")).sort()

if (files.length === 0) {
  console.error("no test files found in tests/model/")
  process.exit(1)
}

for (const file of files) require(path.join(dir, file))

process.exit(harness.report())
