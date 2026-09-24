#!/usr/bin/env bash
# @raycast.schemaVersion 1
# @raycast.title Desktop
# @raycast.mode compact
# @raycast.packageName AGXA Desktops
# @raycast.icon 🖥
# @raycast.description Switch to a named WhichSpace desktop
# @raycast.argument1 { "type": "dropdown", "placeholder": "Desktop", "data": [{"title": "Zen", "value": "zen"}, {"title": "Cursor", "value": "cursor"}, {"title": "Term (Ghostty)", "value": "term"}, {"title": "Studio (Resolve)", "value": "studio"}, {"title": "Office", "value": "office"}, {"title": "Music", "value": "music"}, {"title": "Notes (Obsidian)", "value": "notes"}, {"title": "Previous", "value": "prev"}] }

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DESK="${HOME}/desktop.sh"
[[ -x "$DESK" ]] || DESK="$ROOT/desktop.sh"
exec "$DESK" "$1"
