const { load, test, eq } = require("../harness.js")
const Format = load("Format.js")

const HOME = "/home/fernando"

test("folderLabel writes home as a tilde", () => {
  eq(Format.folderLabel("/home/fernando/Pictures", HOME), "~/Pictures")
})

test("folderLabel keeps only the tail of a deep path", () => {
  eq(Format.folderLabel("/home/fernando/Projects/risecode/tmp", HOME), "~/…/risecode/tmp")
  eq(Format.folderLabel("/usr/share/omarchy/shell/plugins", null), "…/shell/plugins")
})

test("folderLabel leaves a short path alone", () => {
  eq(Format.folderLabel("/etc", null), "/etc")
})

test("folderLabel has nothing to say about an item with no folder", () => {
  eq(Format.folderLabel("", HOME), "")
})

test("countLabel reads as a sentence, not a number", () => {
  eq(Format.countLabel(0), "Empty")
  eq(Format.countLabel(1), "1 item")
  eq(Format.countLabel(7), "7 items")
})

const item = (kind, path, folder) => ({ kind, path, folder })

test("subtitle of a file is the folder it came from", () => {
  eq(Format.subtitle(item("file", "/home/fernando/Pictures/a.png", "/home/fernando/Pictures"), HOME), "~/Pictures")
})

test("subtitle of a link is the address without the scheme noise", () => {
  eq(Format.subtitle(item("link", "https://omarchyplugins.com/develop.html", ""), HOME),
     "omarchyplugins.com/develop.html")
})

test("subtitle of a line of text is nothing — the text is already the label", () => {
  eq(Format.subtitle(item("text", "lembrete", ""), HOME), "")
})

test("subtitle says so when the file is gone", () => {
  const item = { kind: "file", path: "/a/b.txt", folder: "/a" }
  eq(Format.subtitle(item, "/home/me", true), "no longer there")
})
