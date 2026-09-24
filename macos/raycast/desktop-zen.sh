#!/usr/bin/env bash
# @raycast.schemaVersion 1
# @raycast.title Desktop: Zen
# @raycast.mode silent
# @raycast.packageName AGXA Desktops
# @raycast.icon 🌀
# @raycast.description Switch to the Zen Browser desktop

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DESK="${HOME}/desktop.sh"
[[ -x "$DESK" ]] || DESK="$ROOT/desktop.sh"
exec "$DESK" zen
