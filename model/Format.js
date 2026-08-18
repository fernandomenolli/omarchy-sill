.pragma library

// The folder a file came from, shortened the way a shell prompt shortens it:
// home is a tilde, and a deep path keeps only the tail that identifies it.
function folderLabel(folder, home) {
  var path = String(folder || "")
  if (path === "") return ""
  if (home && path.indexOf(home) === 0) path = "~" + path.slice(home.length)

  var parts = path.split("/").filter(function(part) { return part !== "" })
  if (parts.length <= 2) return path
  return (path.indexOf("~") === 0 ? "~/…/" : "…/") + parts.slice(-2).join("/")
}

function countLabel(count) {
  if (count === 0) return "Empty"
  return count + (count === 1 ? " item" : " items")
}

// The second line of a row. A file says where it came from; a link says where
// it goes; a line of text has already said everything it has to say.
function subtitle(item, home) {
  if (!item) return ""
  if (item.kind === "file") return folderLabel(item.folder, home)
  if (item.kind === "link") return String(item.path).replace(/^[a-z][a-z0-9+.-]*:\/\//i, "").replace(/\/$/, "")
  return ""
}
