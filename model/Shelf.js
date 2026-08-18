.pragma library

// A drop arrives as a list of URLs, a blob of text, or both. What comes back
// is a list of records the shelf can hold: a file keeps its path, anything
// else keeps its text. The key is what makes a second drop of the same thing
// a no-op rather than a duplicate.
function parseDrop(urls, text) {
  var items = []

  for (var i = 0; i < (urls || []).length; i++) {
    var url = String(urls[i])
    if (url.indexOf("file://") !== 0) {
      items.push(linkItem(url))
      continue
    }
    items.push(fileItem(decodeURIComponent(url.slice("file://".length))))
  }

  var trimmed = String(text || "").trim()
  if (items.length === 0 && trimmed !== "") {
    items.push(/^[a-z][a-z0-9+.-]*:\/\//i.test(trimmed) ? linkItem(trimmed) : textItem(trimmed))
  }

  return items
}

function fileItem(path) {
  return { key: "file:" + path, kind: "file", path: path, name: basename(path), folder: dirname(path) }
}

function linkItem(url) {
  return { key: "link:" + url, kind: "link", path: url, name: hostOf(url), folder: url }
}

function textItem(text) {
  return { key: "text:" + text, kind: "text", path: text, name: firstLine(text), folder: "" }
}

function basename(path) {
  var parts = String(path).split("/")
  return parts[parts.length - 1] || path
}

function dirname(path) {
  var parts = String(path).split("/")
  parts.pop()
  return parts.join("/") || "/"
}

function hostOf(url) {
  var match = String(url).match(/^[a-z][a-z0-9+.-]*:\/\/([^\/?#]+)/i)
  return match ? match[1] : String(url)
}

function firstLine(text) {
  var line = String(text).split("\n")[0].trim()
  return line.length > 60 ? line.slice(0, 57) + "…" : line
}

// Newest first, because the thing you just set down is the thing you are
// about to pick up.
function add(items, incoming, limit) {
  var result = (incoming || []).slice()
  var seen = {}
  for (var i = 0; i < result.length; i++) seen[result[i].key] = true

  for (var j = 0; j < (items || []).length; j++) {
    if (seen[items[j].key]) continue
    seen[items[j].key] = true
    result.push(items[j])
  }

  return limit > 0 ? result.slice(0, limit) : result
}

function remove(items, key) {
  return (items || []).filter(function(item) { return item.key !== key })
}

function filePaths(items) {
  return (items || []).filter(function(item) { return item.kind === "file" }).map(function(item) { return item.path })
}

function isImage(item) {
  return item.kind === "file" && /\.(png|jpe?g|gif|webp|bmp|svg|avif)$/i.test(item.path)
}

// A path becomes a URI for the drag: percent-encoded, because a folder with a
// space in it is normal and a raw space in a uri-list is not. The CRLF is
// what the spec asks for and what file managers look for.
function fileUri(path) {
  return "file://" + encodeURI(String(path)).replace(/#/g, "%23") + "\r\n"
}

// What a row hands over when dragged. A file is offered as a file so the
// destination copies it; everything else is offered as the text it is.
function dragData(item) {
  if (!item) return ({})
  if (item.kind === "file") return ({ "text/uri-list": fileUri(item.path) })
  return ({ "text/plain": String(item.path) })
}

// Everything on the shelf, as one uri-list. Dragging the icon carries the
// whole shelf, which is what it was filled for.
function dragAll(items) {
  var uris = filePaths(items).map(fileUri).join("")
  return uris === "" ? ({}) : ({ "text/uri-list": uris })
}
