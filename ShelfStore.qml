import QtQuick
import Quickshell
import Quickshell.Io
import "model/Shelf.js" as Shelf

// The shelf itself: what is on it, and the file it survives a restart in.
// Items are references — a path, a link, a line of text. Nothing is copied
// on disk, so clearing the shelf never loses anything.
Item {
  id: root

  property int limit: 25
  property var items: []

  readonly property string statePath:
    (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state")
    + "/omarchy/plugins/io.github.fernandomenolli.sill/shelf.json"

  readonly property int count: items.length

  signal added(int howMany)

  function addFromDrop(urls, text) {
    var incoming = Shelf.parseDrop(urls, text)
    if (incoming.length === 0) return 0

    items = Shelf.add(items, incoming, limit)
    save()
    added(incoming.length)
    return incoming.length
  }

  function remove(key) {
    items = Shelf.remove(items, key)
    save()
  }

  function clear() {
    items = []
    save()
  }

  function save() {
    stateFile.setText(JSON.stringify({ version: 1, items: items }, null, 2) + "\n")
  }

  function load() {
    var raw = stateFile.text()
    if (!raw) return

    try {
      var parsed = JSON.parse(raw)
      // A record written by an older version is dropped rather than trusted:
      // the shelf is a scratch surface, not an archive worth migrating.
      items = (parsed.items || []).filter(function(item) {
        return item && item.key && item.kind && item.path
      })
    } catch (error) {
      items = []
    }
  }

  FileView {
    id: stateFile
    path: root.statePath
    blockLoading: true
    watchChanges: false
    atomicWrites: true
    printErrors: false
  }

  Component.onCompleted: load()
}
