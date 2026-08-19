import QtQuick
import Quickshell
import Quickshell.Io

// What the switches in the panel write.
//
// Not shell.json. The shell watches that file and rebuilds a widget when it
// changes, which closes the panel the switch is in: you would tap a switch and
// the settings would vanish. It is also the user's own configuration, and a
// plugin writing there without being asked is the thing the catalogue tells
// you not to do.
//
// So a preference set by hand in shell.json is the default, and a preference
// set by tapping is kept here and wins. Delete this file and the panel goes
// back to whatever shell.json says.
Item {
  id: prefs

  property string pluginId: ""
  property var values: ({})
  property int revision: 0

  readonly property string path: (Quickshell.env("XDG_STATE_HOME") !== ""
    ? Quickshell.env("XDG_STATE_HOME")
    : Quickshell.env("HOME") + "/.local/state")
    + "/omarchy/plugins/" + pluginId + "/preferences.json"

  function has(key) {
    return values && values[key] !== undefined && values[key] !== null
  }

  function get(key, fallback) {
    return has(key) ? values[key] : fallback
  }

  function set(key, value) {
    var next = {}
    for (var name in values) next[name] = values[name]
    next[key] = value
    values = next
    revision++
    file.setText(JSON.stringify({ version: 1, preferences: next }, null, 2) + "\n")
  }

  FileView {
    id: file
    path: prefs.path
    blockLoading: true
    watchChanges: false
    atomicWrites: true
    printErrors: false
    preload: true

    onLoaded: {
      try {
        var parsed = JSON.parse(text())
        prefs.values = (parsed && parsed.preferences) || ({})
      } catch (e) {
        prefs.values = ({})
      }
      prefs.revision++
    }
  }
}
