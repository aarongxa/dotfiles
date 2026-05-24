#!/bin/bash
#
# tmux Dashboard Script with Precise Layout Control
# Similar to kitty's layout system, this script provides fine-grained control
# over pane sizes and arrangements.
#
# Usage:
#   ./tmux-dashboard.sh
#
# Customization:
#   Edit the LAYOUT CONFIGURATION section below to adjust pane sizes
#   Use percentages (-p), absolute sizes (-x/-y), or relative adjustments (+/-)
#

SESSION_NAME="dashboard"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Window index (adjust if your tmux base-index is different)
# Check your .tmux.conf: if base-index is 1, use 1; if 0, use 0
WINDOW_INDEX=1  # Changed to 1 because your config has base-index 1

# Get the current pane index (useful for dynamic pane tracking)
get_current_pane() {
    tmux display-message -t "$SESSION_NAME:$WINDOW_INDEX" -p '#{pane_index}'
}

# Split window with precise control
# Usage: split_pane <direction> <size> <command> [target_pane]
# direction: h (horizontal) or v (vertical)
# size: percentage (-p) or absolute (-x/-y)
# command: command to run in new pane
split_pane() {
    local direction=$1
    local size=$2
    local command=$3
    local target=${4:-}
    
    if [[ -n "$target" ]]; then
        tmux split-window -$direction $size -t "$SESSION_NAME:$WINDOW_INDEX.$target" "$command"
    else
        tmux split-window -$direction $size -t "$SESSION_NAME:$WINDOW_INDEX" "$command"
    fi
}

# Resize a specific pane
# Usage: resize_pane <pane_index> <x_size> <y_size>
# sizes can be: percentage (e.g., "60%"), absolute (e.g., "80"), or relative (e.g., "+10")
# Note: pane_index starts at 1 if pane-base-index is 1 in your config
resize_pane() {
    local pane=$1
    local x_size=$2
    local y_size=$3
    
    local args=(-t "$SESSION_NAME:$WINDOW_INDEX.$pane")
    [[ -n "$x_size" ]] && args+=(-x "$x_size")
    [[ -n "$y_size" ]] && args+=(-y "$y_size")
    
    tmux resize-pane "${args[@]}"
}

# Select a specific pane
# Note: pane_index starts at 1 if pane-base-index is 1 in your config
select_pane() {
    local pane=$1
    tmux select-pane -t "$SESSION_NAME:$WINDOW_INDEX.$pane"
}

# ============================================================================
# LAYOUT CONFIGURATION
# ============================================================================
# Define your layout here. You can use:
#   - Percentages: -p 40 (40% of available space)
#   - Absolute sizes: -x 80 -y 25 (80 columns wide, 25 lines tall)
#   - Mixed: combine percentages and absolute sizes
# ============================================================================

# Main pane sizes (left side - neofetch)
NEOFETCH_WIDTH_PCT=60        # Percentage of total width
NEOFETCH_HEIGHT_PCT=100      # Percentage of total height

# Right side splits
CAVA_WIDTH_PCT=40            # Remaining width after neofetch
CAVA_HEIGHT_PCT=100          # Full height initially

# Top right quadrant (cmatrix)
CMATRIX_HEIGHT_PCT=50        # Half of right side height

# Bottom right quadrant splits
BTOP_HEIGHT_PCT=60           # 60% of bottom right
MACMON_WIDTH_PCT=50          # Half of bottom right width
DF_HEIGHT_PCT=40             # Remaining height after btop

# ============================================================================
# SESSION CREATION
# ============================================================================

# Kill existing session if it exists
tmux has-session -t $SESSION_NAME 2>/dev/null && tmux kill-session -t $SESSION_NAME

# Start a new detached session with neofetch
tmux new-session -d -s $SESSION_NAME -x 200 -y 50 "neofetch"

# Verify session and window exist
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "Error: Failed to create tmux session '$SESSION_NAME'" >&2
    exit 1
fi

# Small delay to ensure session is ready
sleep 0.1

# ============================================================================
# LAYOUT CONSTRUCTION
# ============================================================================
# Build the layout step by step with precise control
# 
# Pane numbering after each step (starting from 1 due to pane-base-index 1):
#   1: neofetch (left)
#   2: cava (right, after step 1)
#   3: cmatrix (top right, after step 2)
#   4: btop (middle right, after step 3)
#   5: macmon (bottom right left, after step 4)
#   6: df watch (above macmon, after step 5)
#   7: cava (bottom right right, renumbered after splits)
# ============================================================================

# Step 1: Split horizontally for cava (right side)
# This creates: [neofetch (60%) | cava (40%)]
# Pane 1: neofetch, Pane 2: cava
split_pane "h" "-p $CAVA_WIDTH_PCT" "cava" "1"

# Step 2: Select right pane (cava) and split vertically for cmatrix (top right)
# This creates: [neofetch | cmatrix (top) / cava (bottom)]
# Pane 1: neofetch, Pane 2: cmatrix, Pane 3: cava
select_pane "2"
split_pane "v" "-p $CMATRIX_HEIGHT_PCT" "cmatrix" "2"

# Step 3: Select bottom right pane (cava) and split vertically for btop
# This creates: [neofetch | cmatrix / btop / cava]
# Pane 1: neofetch, Pane 2: cmatrix, Pane 3: btop, Pane 4: cava
select_pane "3"
split_pane "v" "-p $BTOP_HEIGHT_PCT" "btop" "3"

# Step 4: Select the btop pane and split horizontally for macmon
# This creates: [neofetch | cmatrix / btop | macmon / cava]
# Pane 1: neofetch, Pane 2: cmatrix, Pane 3: btop, Pane 4: macmon, Pane 5: cava
select_pane "3"
split_pane "h" "-p $MACMON_WIDTH_PCT" "macmon" "3"

# Step 5: Select the pane above macmon (btop) and split vertically for df watch
# This creates: [neofetch | cmatrix / df / btop | macmon / cava]
# Pane 1: neofetch, Pane 2: cmatrix, Pane 3: df, Pane 4: btop, Pane 5: macmon, Pane 6: cava
select_pane "3"
split_pane "v" "-p $DF_HEIGHT_PCT" "watch df -h" "3"

# ============================================================================
# PRECISE RESIZING
# ============================================================================
# Fine-tune individual panes with exact sizes (similar to kitty's layout control)
# 
# Size options (use with resize_pane helper or directly with tmux):
#   1. Percentages: "60%" (60% of available space)
#   2. Absolute sizes: "120" (120 columns or lines)
#   3. Relative adjustments: "+10" (add 10) or "-5" (subtract 5)
#   4. Mixed: combine x and y with different methods
#
# Examples (pane indices start at 1 due to pane-base-index 1):
#   resize_pane 1 "60%" "100%"           # Percentage-based
#   resize_pane 1 "120" "30"              # Absolute sizes (cols × lines)
#   resize_pane 1 "+10" "-5"              # Relative adjustments
#   resize_pane 1 "60%" "25"              # Mixed: 60% width, 25 lines height
# ============================================================================

# Resize neofetch pane (pane 1) - left side using percentages
resize_pane "1" "$NEOFETCH_WIDTH_PCT%" "$NEOFETCH_HEIGHT_PCT%"

# Resize cava pane (pane 6) - full height on right
resize_pane "6" "" "100%"

# ============================================================================
# ALTERNATIVE: ABSOLUTE SIZING (Kitty-style)
# ============================================================================
# Uncomment the section below to use absolute pixel/column sizes instead
# This gives you kitty-like control where you specify exact dimensions
# Pane indices: 1=neofetch, 2=cmatrix, 3=df, 4=btop, 5=macmon, 6=cava
# ============================================================================
# resize_pane "1" "120" "30"              # neofetch: 120 cols × 30 lines
# resize_pane "2" "" "15"                  # cmatrix: 15 lines tall (width auto)
# resize_pane "3" "" "20"                  # df: 20 lines tall
# resize_pane "4" "" "15"                  # btop: 15 lines tall
# resize_pane "5" "40" ""                  # macmon: 40 cols wide (height auto)
# resize_pane "6" "40" "100%"              # cava: 40 cols wide, full height

# ============================================================================
# ALTERNATIVE: RELATIVE ADJUSTMENTS
# ============================================================================
# Fine-tune by adding/subtracting from current sizes
# Useful for making small adjustments after initial layout
# ============================================================================
# resize_pane "1" "+10" ""                 # Make neofetch 10 cols wider
# resize_pane "2" "" "-5"                  # Make cmatrix 5 lines shorter
# resize_pane "3" "" "+3"                  # Make df 3 lines taller

# ============================================================================
# ALTERNATIVE: CUSTOM LAYOUT STRING (Advanced)
# ============================================================================
# For maximum control, you can use tmux's layout string format to define
# exact pixel positions and sizes for each pane. This is similar to kitty's
# layout files but uses tmux's internal format.
#
# To generate a layout string:
#   1. Create your layout manually in tmux
#   2. Run: tmux list-windows -F '#{window_layout}'
#   3. Copy the output and use it below
#
# Format: Each pane is defined as <width>x<height>,<x>,<y>
# Nested panes use braces: {pane1,pane2}
# ============================================================================
# Example custom layout (uncomment to use):
# CUSTOM_LAYOUT="a5b5,0,0,60x50,0,0{30x50,0,0{15x25,0,0,15x25,0,26},30x25,31,0{15x15,31,0,15x15,47,0},30x25,31,26}"
# tmux select-layout -t "$SESSION_NAME:$WINDOW_INDEX" "$CUSTOM_LAYOUT"
#
# To see current layout: tmux list-windows -t $SESSION_NAME -F '#{window_layout}'

# ============================================================================
# ATTACH TO SESSION
# ============================================================================

tmux attach-session -t $SESSION_NAME
