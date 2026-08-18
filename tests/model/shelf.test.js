const { load, test, eq } = require("../harness.js")
const Shelf = load("Shelf.js")

test("a dropped file keeps its path, name and folder", () => {
  eq(Shelf.parseDrop(["file:///home/fernando/Pictures/sunset.png"], ""), [{
    key: "file:/home/fernando/Pictures/sunset.png",
    kind: "file",
    path: "/home/fernando/Pictures/sunset.png",
    name: "sunset.png",
    folder: "/home/fernando/Pictures"
  }])
})

test("a path with spaces survives the URL it arrived in", () => {
  eq(Shelf.parseDrop(["file:///home/fernando/Notas%20de%20reuni%C3%A3o.md"], "")[0].name,
     "Notas de reunião.md")
})

test("several files in one drop become several items", () => {
  eq(Shelf.parseDrop(["file:///a/one.txt", "file:///a/two.txt"], "").length, 2)
})

test("a dropped link is kept as a link, named by its host", () => {
  eq(Shelf.parseDrop([], "https://omarchy.org/manual/shell-plugins/"), [{
    key: "link:https://omarchy.org/manual/shell-plugins/",
    kind: "link",
    path: "https://omarchy.org/manual/shell-plugins/",
    name: "omarchy.org",
    folder: "https://omarchy.org/manual/shell-plugins/"
  }])
})

test("dropped prose is kept as text, named by its first line", () => {
  const item = Shelf.parseDrop([], "primeira linha\nsegunda linha")[0]
  eq(item.kind, "text")
  eq(item.name, "primeira linha")
})

test("a long line of text is elided into a name that fits a row", () => {
  const long = "x".repeat(200)
  eq(Shelf.parseDrop([], long)[0].name.length, 58)
})

test("text riding along with files is ignored, because the files are the drop", () => {
  eq(Shelf.parseDrop(["file:///a/one.txt"], "/a/one.txt").length, 1)
})

test("an empty drop yields nothing", () => {
  eq(Shelf.parseDrop([], "   "), [])
})

test("add puts what just arrived on top", () => {
  const existing = [Shelf.fileItem("/a/old.txt")]
  const incoming = [Shelf.fileItem("/a/new.txt")]
  eq(Shelf.add(existing, incoming, 25).map(i => i.name), ["new.txt", "old.txt"])
})

test("dropping the same file twice moves it up rather than duplicating it", () => {
  const existing = [Shelf.fileItem("/a/one.txt"), Shelf.fileItem("/a/two.txt")]
  const again = [Shelf.fileItem("/a/two.txt")]
  eq(Shelf.add(existing, again, 25).map(i => i.name), ["two.txt", "one.txt"])
})

test("add drops the oldest items past the limit", () => {
  const existing = [Shelf.fileItem("/a/1"), Shelf.fileItem("/a/2"), Shelf.fileItem("/a/3")]
  eq(Shelf.add(existing, [Shelf.fileItem("/a/4")], 2).map(i => i.name), ["4", "1"])
})

test("remove takes out the one item named", () => {
  const items = [Shelf.fileItem("/a/one.txt"), Shelf.fileItem("/a/two.txt")]
  eq(Shelf.remove(items, "file:/a/one.txt").map(i => i.name), ["two.txt"])
})

test("filePaths ignores links and text, which cannot be pasted as files", () => {
  const items = [Shelf.fileItem("/a/one.txt"), Shelf.linkItem("https://x.com"), Shelf.textItem("hello")]
  eq(Shelf.filePaths(items), ["/a/one.txt"])
})

test("isImage recognises the extensions worth showing a thumbnail for", () => {
  eq(Shelf.isImage(Shelf.fileItem("/a/shot.PNG")), true)
  eq(Shelf.isImage(Shelf.fileItem("/a/notes.md")), false)
  eq(Shelf.isImage(Shelf.linkItem("https://x.com/a.png")), false)
})





