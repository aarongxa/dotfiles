#!/usr/bin/env bash
# @raycast.schemaVersion 1
# @raycast.title Desktop: Send Window
# @raycast.mode compact
# @raycast.packageName AGXA Desktops
# @raycast.icon ➡️
# @raycast.description Send the front window to a named desktop (stay put)
# @raycast.argument1 { "type": "dropdown", "placeholder": "Desktop", "data": [{"title": "Zen", "value": "zen"}, {"title": "Cursor", "value": "cursor"}, {"title": "Term", "value": "term"}, {"title": "Studio", "value": "studio"}, {"title": "Office", "value": "office"}, {"title": "Music", "value": "music"}] }

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DESK="${HOME}/desktop.sh"
[[ -x "$DESK" ]] || DESK="$ROOT/desktop.sh"
exec "$DESK" send "$1"
