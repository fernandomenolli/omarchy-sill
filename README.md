# Sill

A shelf on the bar. Drag a file onto it from anywhere, walk away to another
workspace, and copy it out where it belongs.

The bar is the one surface a drag can always reach: it is on top of every
window, on every workspace. That is the whole idea.

## The problem it solves

Dragging a file from a folder on workspace 2 into a chat on workspace 5 is
not hard on Hyprland — it is impossible. You cannot switch workspaces with a
file held in your hand. So you copy it to a temporary folder, or you tile
both windows side by side and drag across the seam.

Sill gives you somewhere to put things down.

## Install

```bash
omarchy plugin add https://github.com/fernandomenolli/omarchy-sill.git --enable
```

Needs `wl-clipboard` (`wl-copy`), which Omarchy already installs.

## Remove

```bash
omarchy plugin remove io.github.fernandomenolli.sill
rm -rf ~/.local/state/omarchy/plugins/io.github.fernandomenolli.sill
```

## Using it

| Action | What happens |
|---|---|
| Drag a file onto the bar icon | it lands on the shelf; the panel opens so the whole panel becomes a target |
| Left click the icon | open the shelf |
| Right click the icon | copy every file on the shelf at once |
| Click a row | copy that one thing |
| Enter, with the shelf open | copy everything |
| × on a row | take it off the shelf |

**Copying a file copies the file, not its path.** It goes onto the clipboard
as `x-special/gnome-copied-files`, so `Ctrl+V` in a file manager, a file
dialog or a chat lands the file itself. Gathering five files from three
folders and pasting them in one go is the thing dragging could never do.

Links and lines of text can be dropped too, and they copy as text.

## What it does not do

**Nothing is moved or duplicated on disk.** The shelf holds references —
a path, a URL, a line of text. Clearing it never deletes anything, and a
file you delete elsewhere simply stops working from here.

**You cannot drag back out.** Starting a drag from a layer-shell surface is
not something the shell can do on Wayland today; only receiving one is. So
the way out is copying, which turned out to be better anyway.

## Settings

Under Setup > Plugins.

| Setting | Default | What it does |
|---|---|---|
| Open the shelf when a drag reaches the bar | on | gives you the whole panel to drop into |
| Empty the shelf after copying everything | off | for people who treat it as a one-way conveyor |
| Maximum items | 25 | the oldest fall off the end |

## Tests

```bash
node tests/run.js
```

No dependencies, no framework. They cover `model/` — parsing a drop into
items, deduplicating, and the labels each kind of item gets.

## Licence

MIT.
