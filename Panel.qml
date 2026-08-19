import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Ui
import "model/Shelf.js" as Shelf
import "model/Capture.js" as Capture
import "model/Format.js" as Format

// A shelf on the bar. Drag a file up to it from anywhere and let go; the bar
// is on every workspace, which is the one place a drag can always reach. Take
// things off it by copying them out — the files themselves, not their paths.
Panel {
  id: root
  moduleName: "io.github.fernandomenolli.sill"
  ipcTarget: "io.github.fernandomenolli.sill"

  readonly property bool openOnDrag: setting("openOnDrag", true)
  readonly property bool clearOnCopy: setting("clearOnCopy", false)
  readonly property int maxItems: setting("maxItems", 25)

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property bool vertical: bar ? bar.vertical : false
  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string clipPath: Qt.resolvedUrl("bin/sill-clip").toString().replace("file://", "")

  property string copiedKey: ""
  property string notice: ""

  // Paths a check found gone, by path. The shelf holds references and not
  // copies, so a file can be moved or deleted from under it at any time, and
  // the worst moment to discover that is when you paste and nothing arrives.
  property var missing: ({})
  readonly property string checkPath: Qt.resolvedUrl("bin/sill-check").toString().replace("file://", "")
  readonly property string shotPath: Qt.resolvedUrl("bin/sill-latest-shot").toString().replace("file://", "")

  // Off by default, because nothing else here arrives without you putting it
  // there and that promise is worth more than the convenience. It is the one
  // exception, and it earns it: a screenshot is already on the clipboard, but
  // the clipboard holds one, and three screenshots meant for the same message
  // is the case it cannot serve.
  readonly property bool catchScreenshots: setting("catchScreenshots", false)
  property real captureStartedAt: 0


  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function copyItem(item) {
    if (item.kind === "file" && root.missing[item.path]) {
      notice = "that file is no longer there"
      noticeReset.restart()
      return
    }

    if (item.kind === "file") Quickshell.execDetached([clipPath, "files", item.path])
    else Quickshell.execDetached([clipPath, "text", item.path])

    copiedKey = item.key
    copiedReset.restart()
  }

  function copyEverything() {
    var paths = Shelf.filePaths(shelf.items, root.missing)
    if (paths.length === 0) {
      if (Shelf.checkablePaths(shelf.items).length > 0) {
        notice = "none of those files are there any more"
        noticeReset.restart()
      }
      return
    }

    Quickshell.execDetached([clipPath, "files"].concat(paths))
    notice = paths.length === 1 ? "1 file on the clipboard" : paths.length + " files on the clipboard"
    noticeReset.restart()
    if (clearOnCopy) shelf.clear()
  }

  function openItem(item) {
    Quickshell.execDetached(["xdg-open", item.path])
  }

  ShelfStore {
    id: shelf
    limit: root.maxItems
    onAdded: function(howMany) {
      root.notice = howMany === 1 ? "1 item set down" : howMany + " items set down"
      noticeReset.restart()
    }
  }

  Timer { id: copiedReset; interval: 1600; onTriggered: root.copiedKey = "" }
  Timer { id: noticeReset; interval: 2200; onTriggered: root.notice = "" }

  // Hyprland announces a screenshot as a capture, the same way it announces a
  // call, so nothing has to watch a directory: a capture that starts and stops
  // again immediately was somebody pressing the screenshot key.
  Connections {
    target: Hyprland
    enabled: root.catchScreenshots

    function onRawEvent(event) {
      if (!event) return

      var parsed = Capture.parseEvent(event.name, event.data)
      if (!parsed) return

      if (parsed.starting) { root.captureStartedAt = Date.now(); return }
      if (!Capture.wasScreenshot(root.captureStartedAt, Date.now(), 2000)) return

      root.captureStartedAt = 0
      if (!shot.running) shot.running = true
    }
  }

  Process {
    id: shot
    command: [root.shotPath, "10"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var path = String(text).trim()
        if (path === "") return
        if (shelf.addFromDrop(["file://" + path], "") > 0) {
          root.notice = "screenshot set down"
          noticeReset.restart()
        }
      }
    }
  }

  // Asked once each time the shelf is opened, which is the only moment the
  // answer is looked at. Nothing runs while the panel is shut.
  Process {
    id: check
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var gone = {}
        var lines = String(text).split("\n")
        for (var i = 0; i < lines.length; i++) {
          var path = lines[i].trim()
          if (path !== "") gone[path] = true
        }
        root.missing = gone
      }
    }
  }

  onOpenedChanged: {
    if (!opened) return
    var paths = Shelf.checkablePaths(shelf.items)
    if (paths.length === 0) { root.missing = ({}); return }
    if (check.running) return
    check.command = [root.checkPath].concat(paths)
    check.running = true
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    // Empty is an outline, holding something is filled in. The shelf has no
    // urgency to report — nothing here is waiting on you or going wrong — so
    // it says how full it is by weight rather than by turning the colour every
    // other widget uses to mean something is the matter.
    readonly property string mark: shelf.count === 0 ? "󱈎" : "󰀼"
    text: root.vertical || shelf.count === 0 ? mark : mark + " " + shelf.count
    tooltipText: shelf.count === 0
      ? "Sill — drag a file here to set it down"
      : Format.countLabel(shelf.count) + " on the shelf"
    // The bar owns pointer input on its own strip and delivers it here, not to
    // any MouseArea stacked on top. This is the only handler that runs.
    onPressed: function(b) {
      if (b === Qt.RightButton && shelf.count > 0) root.copyEverything()
      else root.toggle()
    }
    // The icon is the drop target, and a drag reaching it opens the shelf so
    // the rest of the panel becomes target too. A bar icon is a small thing
    // to aim a file at.
    DropArea {
      anchors.fill: parent
      onContainsDragChanged: if (containsDrag && root.openOnDrag && !root.opened) root.open()
      onDropped: function(drop) {
        shelf.addFromDrop(drop.urls, drop.text)
        drop.accept()
      }
    }

  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(560))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onActivateRequested: root.copyEverything()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      // The whole panel takes a drop, not just the list: an empty shelf has no
      // rows to aim at, and that is exactly when you are dropping the first
      // thing onto it.
      DropArea {
        anchors.fill: parent
        onDropped: function(drop) {
          shelf.addFromDrop(drop.urls, drop.text)
          drop.accept()
        }
      }

      Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
          id: column
          width: flick.width
          spacing: Style.space(10)

          PanelHero {
            foreground: root.foreground
            fontFamily: root.fontFamily
            title: "Sill"
            meta: root.notice !== "" ? root.notice : Format.countLabel(shelf.count)
            iconComponent: Component {
              Text {
                text: shelf.count === 0 ? "󱈎" : "󰀼"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.display
              }
            }
          }

          PanelSeparator { foreground: root.foreground }

          Text {
            visible: shelf.count === 0
            width: parent.width
            wrapMode: Text.Wrap
            text: "Drag a file onto the bar icon and let go. It waits here until you copy it out — across workspaces, across apps."
            color: Qt.darker(root.foreground, 1.6)
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
          }

          Column {
            width: parent.width
            spacing: Style.space(2)

            Repeater {
              model: shelf.items

              ItemRow {
                required property var modelData
                item: modelData
                home: root.home
                foreground: root.foreground
                fontFamily: root.fontFamily
                copied: root.copiedKey === modelData.key
                gone: root.missing[modelData.path] === true
                onCopyRequested: root.copyItem(modelData)
                onRemoveRequested: shelf.remove(modelData.key)
              }
            }
          }

          PanelSeparator { foreground: root.foreground; visible: shelf.count > 0 }

          // What a row does is not guessable: it looks like a list, and a list
          // invites dragging. Saying it costs one quiet line.
          Text {
            visible: shelf.count > 0
            width: parent.width
            wrapMode: Text.Wrap
            text: "Click an item to copy it — the file itself, not its path, so a paste lands a copy."
            color: Qt.darker(root.foreground, 1.65)
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }

          // Omarchy has no settings screen, so a setting is a key in shell.json and
          // the honest thing a panel can do is take you to it. Nothing here writes
          // that file: a plugin editing the config of the person running it is not
          // a favour, however small the edit.
          Button {
            width: parent.width
            text: "Settings"
            iconText: "\uf013"
            foreground: root.foreground
            fontFamily: root.fontFamily
            onClicked: Quickshell.execDetached(["omarchy-launch-config-editor",
              (Quickshell.env("HOME") || "") + "/.config/omarchy/shell.json"])
          }

          Row {
            visible: shelf.count > 0
            width: parent.width
            spacing: Style.space(8)

            Button {
              width: (parent.width - Style.space(8)) / 2
              text: "Copy all"
              iconText: "󰆏"
              bordered: true
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: root.copyEverything()
            }

            Button {
              width: (parent.width - Style.space(8)) / 2
              text: "Clear"
              iconText: "󰎟"
              bordered: true
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: shelf.clear()
            }
          }
        }
      }
    }
  }
}
