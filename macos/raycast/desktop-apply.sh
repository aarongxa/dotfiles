#!/usr/bin/env bash
# @raycast.schemaVersion 1
# @raycast.title Desktop: Apply Labels
# @raycast.mode compact
# @raycast.packageName AGXA Desktops
# @raycast.icon 🏷
# @raycast.description Set WhichSpace labels and badges from the AGXA map

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DESK="${HOME}/desktop.sh"
[[ -x "$DESK" ]] || DESK="$ROOT/desktop.sh"
exec "$DESK" apply
