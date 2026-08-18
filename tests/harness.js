// The model files are QML `.pragma library` scripts, which have no module
// system: just top-level declarations. Stripping the two QML-only directives
// and running what is left in this realm turns those declarations into
// globals, and collecting the names each file added gives back something
// shaped like a module. A fresh VM context would be tidier, but its arrays
// would carry that context's prototypes and every deepStrictEqual would fail
// on realm alone.

const fs = require("fs")
const path = require("path")
const vm = require("vm")
const assert = require("assert")

const MODEL = path.join(__dirname, "..", "model")

function load(file) {
  const source = fs.readFileSync(path.join(MODEL, file), "utf8")
    .replace(/^\s*\.pragma\s+library\s*$/m, "")
    .replace(/^\s*\.import\s+.*$/gm, "")

  const before = new Set(Object.getOwnPropertyNames(globalThis))
  vm.runInThisContext(source, { filename: "model/" + file })

  const module = {}
  for (const name of Object.getOwnPropertyNames(globalThis)) {
    if (!before.has(name)) module[name] = globalThis[name]
  }
  return module
}

let passed = 0
const failures = []

function test(name, fn) {
  try {
    fn()
    passed++
  } catch (error) {
    failures.push({ name, error })
  }
}

function eq(actual, expected) {
  assert.deepStrictEqual(actual, expected)
}

function report() {
  for (const { name, error } of failures) {
    console.error(`FAIL  ${name}`)
    console.error(`      ${error.message.split("\n").join("\n      ")}`)
  }
  console.log(`${passed} passed, ${failures.length} failed`)
  return failures.length === 0 ? 0 : 1
}

module.exports = { load, test, eq, report }
