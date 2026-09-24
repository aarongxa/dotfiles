#!/usr/bin/env bash
# @raycast.schemaVersion 1
# @raycast.title Desktop: Status
# @raycast.mode fullOutput
# @raycast.packageName AGXA Desktops
# @raycast.icon 🖥
# @raycast.description Show WhichSpace desktop map

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DESK="${HOME}/desktop.sh"
[[ -x "$DESK" ]] || DESK="$ROOT/desktop.sh"
exec "$DESK" status
