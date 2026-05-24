#!/usr/bin/env bash
#
# Kitty Quake-style Terminal Toggle Script
# Bind this to a global hotkey (e.g., cmd+` or F12) using:
# - macOS Shortcuts/Automator
# - Hammerspoon
# - BetterTouchTool
# - Alfred, etc.
#

set -euo pipefail

QUAKE_WINDOW_NAME="kitty-quake"

# Check if kitty quake window is already running
if pgrep -f "$QUAKE_WINDOW_NAME" > /dev/null; then
    # Window exists, check if it's focused
    # Use AppleScript to toggle visibility
    osascript <<EOF
        tell application "System Events"
            set kittyRunning to (name of processes) contains "kitty"
            if kittyRunning then
                tell process "kitty"
                    set frontmost to true
                end tell
            end if
        end tell
EOF
else
    # Launch new kitty window with Quake configuration
    open -na /Applications/kitty.app --args \
        --name="$QUAKE_WINDOW_NAME" \
        --session="$HOME/.config/kitty/quake.session" \
        --override initial_window_width=100c \
        --override initial_window_height=30c \
        --override remember_window_size=no
fi




