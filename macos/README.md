# AGXA macOS desktops (WhichSpace)

Named Spaces for this machine: **Zen Browser**, **Cursor**, **Ghostty**, plus Studio / Office / Music.

WhichSpace cannot create desktops. Create them in Mission Control first, then label and jump with these helpers.

## Layout

| Space | Name | App | Badge | Color (WhichSpace Settings) |
|------:|------|-----|:-----:|-----------------------------|
| 1 | Zen | Zen Browser | Z | `#BD93F9` |
| 2 | Cursor | Cursor IDE (Obsidian via `notes`) | C | `#8BE9FD` |
| 3 | Term | Ghostty | T | `#50FA7B` |
| 4 | Studio | DaVinci Resolve, Screen Studio, OBS | R | `#FF79C6` |
| 5 | Office | Word, Outlook, Teams, Excel, Calendar | W | `#F1FA8C` |
| 6 | Music | Spotify | S | `#FF5555` |

Background chip: `#0B0C0C` (same as kitty). Colors follow the Dracula palette already in `kitty/kitty.conf`.

**Not a Space:** `kitty-quake.sh` stays a global dropdown on every desktop.

**Not involved:** Tiles and OmniWM keep snapping windows. These helpers only talk to WhichSpace.

## One-time setup

1. Install / launch WhichSpace (already on this Mac):
   ```bash
   brew install --cask whichspace
   open -a WhichSpace
   ```
2. Stage the helpers:
   ```bash
   ./stage-dotfiles.sh
   ```
3. Create **6 desktops** on the built-in display: Control-Up → click **+**.
   Exit any fullscreen app so WhichSpace does not show an `F` slot.
4. Label the menu bar:
   ```bash
   desktop.sh apply
   ```
5. Optional — place the core apps (Zen, Cursor, Ghostty):
   ```bash
   desktop.sh setup
   desktop.sh setup --all   # also Studio / Office / Music
   ```

In WhichSpace Settings you can also set each Space to square icons (already your default) and paste the colors above. `desktop.sh theme` will try colors/symbols via AppleScript; WhichSpace **1.3.8** only applies labels and badges from scripts.

## Commands

```bash
desktop.sh                 # map + current Space
desktop.sh doctor          # WhichSpace, Space count, apps
desktop.sh zen             # switch and focus Zen
desktop.sh cursor
desktop.sh term            # Ghostty
desktop.sh studio
desktop.sh office
desktop.sh music
desktop.sh notes           # Obsidian on the Cursor Space
desktop.sh go 3            # switch only
desktop.sh send cursor     # front window goes there; you stay
desktop.sh move music      # front window goes there; you follow
desktop.sh left|right|prev
desktop.sh apply | reset | theme | setup [--all]
```

Shell: `desk zen`, `desk status` (zsh, macOS only).

## Raycast

Raycast → Extensions → Script Commands → Add Script Directory:

```
~/.config/macos/raycast
```

(or the repo path `macos/raycast` before staging)

Bind **Desktop: Zen / Cursor / Term** to hotkeys. The generic **Desktop** command is a dropdown; **Desktop: Send Window** parks the front window without switching.

## WhichSpace scripting used

This build (1.3.8) is driven through AppleScript, as in the [WhichSpace README](https://github.com/gechr/WhichSpace):

```applescript
tell application "WhichSpace"
    switch to space number 2
    set label of space 1 to "Zen"
    set badge of space 1 to "Z"
    send front window to space number 3
    move front window to space number 3
    switch to previous space
end tell
```

URL scheme fallback: `whichspace://switch/3`. Newer WhichSpace builds also accept `whichspace://space/3?symbol=safari&foreground=BD93F9` — `desktop.sh theme` tries that.
