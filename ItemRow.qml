import QtQuick
import qs.Commons
import qs.Ui
import "model/Shelf.js" as Shelf
import "model/Format.js" as Format

// One thing set down on the shelf. Clicking it copies it — the file itself,
// so a paste lands a copy. Dragging happens from the bar icon instead: an
// open panel covers the screen with the surface that catches the dismissing
// click, and a drag leaving the panel lands on that rather than on the window
// underneath.
Item {
  id: root

  property var item: null
  property string home: ""
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family
  property bool copied: false
  property bool gone: false

  signal copyRequested()
  signal removeRequested()

  readonly property color dim: Qt.darker(foreground, 1.45)
  readonly property bool isImage: item ? Shelf.isImage(item) : false

  // A row for a file that is not there any more is still worth showing: you
  // put it down for a reason, and being told it is gone is the point. It just
  // stops looking like something you can use.
  opacity: gone ? 0.45 : 1
  Behavior on opacity { NumberAnimation { duration: 160 } }

  width: parent ? parent.width : implicitWidth
  implicitHeight: Math.max(Style.space(34), labels.implicitHeight + Style.space(8))

  Rectangle {
    anchors.fill: parent
    radius: Style.cornerRadius
    color: hover.containsMouse
      ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.07)
      : "transparent"
  }

  Item {
    id: preview
    anchors.left: parent.left
    anchors.leftMargin: Style.space(6)
    anchors.verticalCenter: parent.verticalCenter
    width: Style.space(26)
    height: Style.space(26)

    Image {
      anchors.fill: parent
      visible: root.isImage
      source: root.isImage ? "file://" + root.item.path : ""
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      sourceSize.width: 64
      sourceSize.height: 64
    }

    Text {
      anchors.centerIn: parent
      visible: !root.isImage
      text: root.item && root.item.kind === "link" ? "󰌷"
          : root.item && root.item.kind === "text" ? "󰦨" : "󰈔"
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.icon
    }
  }

  Column {
    id: labels
    anchors.left: preview.right
    anchors.leftMargin: Style.space(10)
    anchors.right: removeButton.left
    anchors.rightMargin: Style.space(8)
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.space(1)

    Text {
      width: parent.width
      text: root.item ? root.item.name : ""
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
      // A file name loses its meaning from the middle out; a sentence loses
      // it from the end.
      elide: root.item && root.item.kind === "file" ? Text.ElideMiddle : Text.ElideRight
    }

    Text {
      width: parent.width
      visible: text !== ""
      text: root.copied ? "Copied" : Format.subtitle(root.item, root.home, root.gone)
      color: root.copied ? Color.accent : root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      elide: Text.ElideMiddle
    }
  }

  PanelActionButton {
    id: removeButton
    anchors.right: parent.right
    anchors.rightMargin: Style.space(4)
    anchors.verticalCenter: parent.verticalCenter
    iconText: "󰅖"
    tooltipText: "Take off the shelf"
    foreground: root.foreground
    fontFamily: root.fontFamily
    onClicked: root.removeRequested()
  }

  MouseArea {
    id: hover
    anchors.left: parent.left
    anchors.right: removeButton.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.copyRequested()
  }
}
