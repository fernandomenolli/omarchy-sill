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

**You cannot drag back out** — and the reason is worth stating precisely,
because it is not the one you would guess. Wayland is fine with it: a plain
layer-shell surface can start a drag that a file manager accepts, verified
against the protocol trace.

What blocks it is the bar. Omarchy's bar owns the pointer grab across its
whole strip, because dragging a widget along the bar is how you reorder it —
so a press inside a widget never reaches the widget. And a drag cannot leave
an open panel either: the panel keeps a full-screen surface above everything
to catch the click that dismisses it, and a drag leaving the card lands on
that instead of on the window underneath.

So the way out is copying — which for the thing this is actually for, five
files gathered from three folders, beats dragging anyway.

## Settings

Under Setup > Plugins.

| Setting | Default | What it does |
|---|---|---|
| Open the shelf when a drag reaches the bar | on | gives you the whole panel to drop into |
| Empty the shelf after copying everything | off | for people who treat it as a one-way conveyor |
| Maximum items | 25 | the oldest fall off the end |

## What it costs

Measured on the machine this was built on — AMD, 24 cores, Omarchy 4.0.0.alpha,
Hyprland 0.56.2 — by reading `utime + stime` from `/proc/<pid>/stat` for the
`omarchy-shell` process, with the plugin enabled and then disabled. The numbers
below are the difference. You can repeat it: the method is four lines of shell.

| | Shell alone | With this plugin |
|---|---|---|
| Idle, 30 seconds | 10 ms of CPU | 10 ms — no timer, nothing runs |
| 300 focus switches | 840 ms | 870 ms |
| Memory | ~500 MB | no measurable change |

The shell's own cost dominates everything here: **2.8 ms of that per focus
switch is Omarchy itself** — the bar redrawing, the active-window widget, the
workspace indicators. All five of these plugins together add 0.17 ms on top.

**It does not get heavier as it runs.** Nothing runs unless you drop something on it or click a row. A shelf holding twenty-five items costs exactly what an empty one costs, because nothing walks the list until you open the panel.

## Tests

```bash
node tests/run.js
```

No dependencies, no framework. They cover `model/` — parsing a drop into
items, deduplicating, and the labels each kind of item gets.

## Licence

MIT.
