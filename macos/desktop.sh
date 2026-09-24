#!/usr/bin/env bash
#==============================================================================
# AGXA macOS desktop helper — WhichSpace named Spaces
#
# Bind from Raycast / Shortcuts the same way kitty-quake.sh is bound.
# Does not create Mission Control Spaces (macOS has no public API for that).
#
# Usage:
#   desktop.sh                 # status
#   desktop.sh zen             # switch to that desktop and focus its app
#   desktop.sh go cursor       # switch only
#   desktop.sh send term       # send front window, stay put
#   desktop.sh move studio     # send front window and follow
#   desktop.sh apply           # set WhichSpace labels + badges
#   desktop.sh setup           # apply + place each app on its Space
#   desktop.sh doctor          # check WhichSpace, Spaces, and apps
#==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$SCRIPT_DIR/desktops.conf"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ── Config ──────────────────────────────────

if [[ ! -f "$CONF" ]]; then
    echo "desktop.sh: missing $CONF" >&2
    exit 1
fi
# shellcheck disable=SC1090
source "$CONF"

# ── Lookup ──────────────────────────────────

desktop_row() {
    local needle="$1" name index
    for row in "${DESKTOPS[@]}"; do
        IFS='|' read -r name index _ <<< "$row"
        if [[ "$name" == "$needle" || "$index" == "$needle" ]]; then
            printf '%s\n' "$row"
            return 0
        fi
    done
    return 1
}

alias_row() {
    local needle="$1" alias_name
    for row in "${SECONDARIES[@]}"; do
        IFS='|' read -r alias_name _ <<< "$row"
        if [[ "$alias_name" == "$needle" ]]; then
            printf '%s\n' "$row"
            return 0
        fi
    done
    return 1
}

# ── WhichSpace ──────────────────────────────

whichspace_installed() {
    [[ -d /Applications/WhichSpace.app ]]
}

whichspace_running() {
    osascript -e 'tell application "System Events" to (name of processes) contains "WhichSpace"' 2>/dev/null | grep -q true
}

ensure_whichspace() {
    if ! whichspace_installed; then
        echo -e "${RED}WhichSpace.app is not in /Applications.${NC}" >&2
        echo "  brew install --cask whichspace" >&2
        return 1
    fi
    if ! whichspace_running; then
        open -a WhichSpace
        local i
        for i in 1 2 3 4 5 6 7 8; do
            whichspace_running && break
            sleep 0.25
        done
    fi
    if ! whichspace_running; then
        echo -e "${RED}WhichSpace did not start.${NC}" >&2
        return 1
    fi
}

ws() {
    osascript -e "tell application \"WhichSpace\" to $*"
}

ws_count() {
    ws 'count spaces'
}

ws_current() {
    ws 'get current space number'
}

ws_labels() {
    ws 'get label of every space'
}

ws_switch() {
    local n="$1"
    ws "switch to space number ${n}"
}

ws_send() {
    local n="$1"
    ws "send front window to space number ${n}"
}

ws_move() {
    local n="$1"
    ws "move front window to space number ${n}"
}

space_label() {
    local n="$1"
    ws "get label of space ${n}"
}

is_fullscreen_space() {
    local label
    label="$(space_label "$1" 2>/dev/null || true)"
    [[ "$label" == "F" ]]
}

space_exists() {
    local n="$1" count
    count="$(ws_count)"
    [[ "$n" -ge 1 && "$n" -le "$count" ]]
}

# ── Apps ────────────────────────────────────

app_installed() {
    local bundle="$1"
    mdfind "kMDItemCFBundleIdentifier == '$bundle'" 2>/dev/null | grep -q .
}

open_app() {
    local app="$1" bundle="${2:-}"
    if [[ -n "$bundle" ]]; then
        open -b "$bundle" 2>/dev/null && return 0
    fi
    open -a "$app"
}

# ── Resolve a name / alias / number ─────────

# Prints: kind name index label badge app bundle color symbol
# kind is "desktop" or "alias"
resolve_target() {
    local raw="$1" row name index label badge app bundle color symbol
    local alias_name desk_name

    raw="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]')"

    if row="$(desktop_row "$raw")"; then
        IFS='|' read -r name index label badge app bundle color symbol <<< "$row"
        printf 'desktop|%s|%s|%s|%s|%s|%s|%s|%s\n' \
            "$name" "$index" "$label" "$badge" "$app" "$bundle" "$color" "$symbol"
        return 0
    fi

    if row="$(alias_row "$raw")"; then
        IFS='|' read -r alias_name desk_name app bundle <<< "$row"
        if ! row="$(desktop_row "$desk_name")"; then
            echo "desktop.sh: alias '$alias_name' points at unknown desktop '$desk_name'" >&2
            return 1
        fi
        IFS='|' read -r name index label badge _ _ color symbol <<< "$row"
        printf 'alias|%s|%s|%s|%s|%s|%s|%s|%s\n' \
            "$name" "$index" "$label" "$badge" "$app" "$bundle" "$color" "$symbol"
        return 0
    fi

    echo -e "${RED}Unknown desktop: $1${NC}" >&2
    echo "  Known: $(desktop_names)" >&2
    return 1
}

desktop_names() {
    local name alias_name names=() out
    for row in "${DESKTOPS[@]}"; do
        IFS='|' read -r name _ <<< "$row"
        names+=("$name")
    done
    for row in "${SECONDARIES[@]}"; do
        IFS='|' read -r alias_name _ <<< "$row"
        names+=("$alias_name")
    done
    printf -v out '%s, ' "${names[@]}"
    printf '%s' "${out%, }"
}

require_space() {
    local index="$1" name="$2"
    if ! space_exists "$index"; then
        echo -e "${YELLOW}Space ${index} (${name}) does not exist yet.${NC}" >&2
        echo "  Mission Control (Control-Up) → click + until you have $(expected_count) desktops." >&2
        echo "  Then: desktop.sh apply" >&2
        return 1
    fi
    if is_fullscreen_space "$index"; then
        echo -e "${YELLOW}Space ${index} is a fullscreen app (WhichSpace shows F).${NC}" >&2
        echo "  Exit fullscreen so ${name} can own a real desktop." >&2
        return 1
    fi
}

expected_count() {
    printf '%s\n' "${#DESKTOPS[@]}"
}

# ── Commands ────────────────────────────────

cmd_status() {
    ensure_whichspace
    local current count labels
    current="$(ws_current)"
    count="$(ws_count)"
    labels="$(ws_labels)"

    echo -e "${BLUE}WhichSpace${NC}  display: ${DESKTOP_DISPLAY}"
    echo -e "  current: ${GREEN}${current}${NC}   spaces: ${count}   labels: ${labels}"
    echo ""
    printf "  ${CYAN}%-8s %-5s %-8s %-6s %s${NC}\n" "NAME" "SPACE" "LABEL" "BADGE" "APP"
    local name index label badge app bundle current_mark
    for row in "${DESKTOPS[@]}"; do
        IFS='|' read -r name index label badge app bundle _ <<< "$row"
        current_mark=" "
        if [[ "$index" == "$current" ]]; then
            current_mark="*"
        fi
        if ! space_exists "$index"; then
            printf "  %s%-8s %-5s %-8s %-6s %s ${YELLOW}(missing space)${NC}\n" \
                "$current_mark" "$name" "$index" "$label" "$badge" "$app"
        elif is_fullscreen_space "$index"; then
            printf "  %s%-8s %-5s %-8s %-6s %s ${YELLOW}(fullscreen)${NC}\n" \
                "$current_mark" "$name" "$index" "$label" "$badge" "$app"
        else
            printf "  %s%-8s %-5s %-8s %-6s %s\n" \
                "$current_mark" "$name" "$index" "$label" "$badge" "$app"
        fi
    done
    echo ""
    echo "  kitty-quake stays global (any Space). Ghostty owns Term."
}

cmd_list() {
    local name index label badge app
    for row in "${DESKTOPS[@]}"; do
        IFS='|' read -r name index label badge app _ <<< "$row"
        printf '%s\t%s\t%s\t%s\t%s\n' "$name" "$index" "$label" "$badge" "$app"
    done
}

cmd_apply() {
    ensure_whichspace
    local name index label badge applied=0 skipped=0
    for row in "${DESKTOPS[@]}"; do
        IFS='|' read -r name index label badge _ <<< "$row"
        if ! space_exists "$index"; then
            echo -e "  ${YELLOW}skip ${name}: no space ${index}${NC}"
            skipped=$((skipped + 1))
            continue
        fi
        if is_fullscreen_space "$index"; then
            echo -e "  ${YELLOW}skip ${name}: space ${index} is fullscreen${NC}"
            skipped=$((skipped + 1))
            continue
        fi
        ws "set label of space ${index} to \"${label}\""
        ws "set badge of space ${index} to \"${badge}\""
        echo -e "  ${GREEN}✓${NC} space ${index} → ${label} [${badge}]"
        applied=$((applied + 1))
    done
    echo ""
    echo -e "  labeled ${GREEN}${applied}${NC}, skipped ${YELLOW}${skipped}${NC}"
    if [[ "$skipped" -gt 0 ]]; then
        echo "  Create the missing desktops in Mission Control, then re-run apply."
    fi
}

cmd_reset() {
    ensure_whichspace
    ws 'reset all space labels'
    ws 'reset all space badges'
    echo -e "${GREEN}WhichSpace labels and badges reset.${NC}"
}

cmd_go() {
    local target="$1" resolved kind name index label badge app bundle
    ensure_whichspace
    resolved="$(resolve_target "$target")" || return 1
    IFS='|' read -r kind name index label badge app bundle _ <<< "$resolved"
    require_space "$index" "$name" || return 1
    ws_switch "$index"
    echo -e "→ ${GREEN}${label}${NC} (space ${index})"
}

cmd_focus() {
    local target="$1" resolved kind name index label badge app bundle
    ensure_whichspace
    resolved="$(resolve_target "$target")" || return 1
    IFS='|' read -r kind name index label badge app bundle _ <<< "$resolved"
    require_space "$index" "$name" || return 1
    open_app "$app" "$bundle"
    sleep 0.45
    ws_move "$index" || ws_switch "$index"
    echo -e "→ ${GREEN}${label}${NC}  ${app}"
}

cmd_send() {
    local target="$1" resolved kind name index label badge app bundle
    ensure_whichspace
    resolved="$(resolve_target "$target")" || return 1
    IFS='|' read -r kind name index label badge app bundle _ <<< "$resolved"
    require_space "$index" "$name" || return 1
    ws_send "$index"
    echo -e "sent window → ${GREEN}${label}${NC} (space ${index})"
}

cmd_move() {
    local target="$1" resolved kind name index label badge app bundle
    ensure_whichspace
    resolved="$(resolve_target "$target")" || return 1
    IFS='|' read -r kind name index label badge app bundle _ <<< "$resolved"
    require_space "$index" "$name" || return 1
    ws_move "$index"
    echo -e "moved window → ${GREEN}${label}${NC} (space ${index})"
}

cmd_left() {
    ensure_whichspace
    ws 'switch left'
}

cmd_right() {
    ensure_whichspace
    ws 'switch right'
}

cmd_prev() {
    ensure_whichspace
    ws 'switch to previous space'
}

cmd_theme() {
    ensure_whichspace
    local name index label badge color symbol
    echo "Applying labels/badges, then trying WhichSpace colors/symbols…"
    cmd_apply
    echo ""
    for row in "${DESKTOPS[@]}"; do
        IFS='|' read -r name index label badge _ _ color symbol <<< "$row"
        space_exists "$index" || continue
        is_fullscreen_space "$index" && continue

        if osascript >/dev/null 2>&1 <<EOF
tell application "WhichSpace"
    set foreground color of space ${index} to "${color}"
    set background color of space ${index} to "${DESKTOP_BG}"
    set symbol of space ${index} to "${symbol}"
end tell
EOF
        then
            echo -e "  ${GREEN}✓${NC} ${label}: #${color}  ${symbol}"
        else
            echo -e "  ${YELLOW}•${NC} ${label}: set in WhichSpace Settings → fg #${color}  bg #${DESKTOP_BG}  symbol ${symbol}"
        fi
    done
    echo ""
    echo "  WhichSpace 1.3.8 scripts labels/badges only. Colors are a Settings click."
}

cmd_setup() {
    local include_all=false
    [[ "${1:-}" == "--all" ]] && include_all=true

    ensure_whichspace
    cmd_apply
    echo ""

    local name index label badge app bundle skip
    for row in "${DESKTOPS[@]}"; do
        IFS='|' read -r name index label badge app bundle _ <<< "$row"
        skip=false
        if [[ "$CORE_DESKTOPS" != *"$name"* ]] && ! $include_all; then
            skip=true
        fi
        if $skip; then
            echo -e "  ${YELLOW}skip ${name}${NC} (optional — pass --all to place it)"
            continue
        fi
        if ! space_exists "$index" || is_fullscreen_space "$index"; then
            echo -e "  ${YELLOW}skip ${name}${NC}: space ${index} not ready"
            continue
        fi
        if ! app_installed "$bundle"; then
            echo -e "  ${YELLOW}skip ${name}${NC}: ${app} is not installed"
            continue
        fi
        echo -e "  placing ${CYAN}${app}${NC} on ${label}…"
        open_app "$app" "$bundle"
        sleep 0.7
        ws_send "$index" || true
    done

    echo ""
    echo "  Done. Optional extras: desktop.sh setup --all"
    echo "  kitty-quake.sh is unchanged — it overlays every Space."
}

cmd_doctor() {
    echo -e "${BLUE}AGXA desktop doctor${NC}"
    echo ""

    if whichspace_installed; then
        local ver
        ver="$(defaults read /Applications/WhichSpace.app/Contents/Info.plist CFBundleShortVersionString 2>/dev/null || echo '?')"
        echo -e "  ${GREEN}✓${NC} WhichSpace ${ver}  /Applications/WhichSpace.app"
    else
        echo -e "  ${RED}✗${NC} WhichSpace is not installed"
        echo "      brew install --cask whichspace"
    fi

    if whichspace_running; then
        echo -e "  ${GREEN}✓${NC} WhichSpace is running"
    else
        echo -e "  ${YELLOW}•${NC} WhichSpace is not running (will launch on first use)"
    fi

    if whichspace_running; then
        local count current labels
        count="$(ws_count)"
        current="$(ws_current)"
        labels="$(ws_labels)"
        echo -e "  ${GREEN}✓${NC} Spaces: ${count}  current: ${current}  labels: ${labels}"
        if [[ "$count" -lt "$(expected_count)" ]]; then
            echo -e "  ${YELLOW}•${NC} Want ${#DESKTOPS[@]} desktops (Zen Cursor Term Studio Office Music)."
            echo "      Control-Up → click +  ($(( ${#DESKTOPS[@]} - count )) more)"
        fi
        if [[ "$labels" == *F* ]]; then
            echo -e "  ${YELLOW}•${NC} A fullscreen app is occupying a Space (label F)."
        fi
    fi

    echo ""
    local name app bundle
    for row in "${DESKTOPS[@]}"; do
        IFS='|' read -r name _ _ _ app bundle _ <<< "$row"
        if app_installed "$bundle"; then
            echo -e "  ${GREEN}✓${NC} ${app}  (${name})"
        else
            echo -e "  ${YELLOW}•${NC} ${app} not found  (${name})"
        fi
    done

    echo ""
    if [[ -x "$HOME/kitty-quake.sh" ]] || [[ -f "$SCRIPT_DIR/../kitty-quake.sh" ]]; then
        echo -e "  ${GREEN}✓${NC} kitty-quake.sh (global overlay, not a Space)"
    fi
    if [[ -d /Applications/Raycast.app ]]; then
        echo -e "  ${GREEN}✓${NC} Raycast — point Script Commands at:"
        echo "      $SCRIPT_DIR/raycast"
    fi
    if [[ -d /Applications/Tiles.app ]]; then
        echo -e "  ${GREEN}✓${NC} Tiles (window snapping — left alone)"
    fi
    if [[ -d /Applications/OmniWM.app ]]; then
        echo -e "  ${GREEN}✓${NC} OmniWM (left alone — Spaces stay with WhichSpace)"
    fi
}

usage() {
    cat <<'EOF'
AGXA desktop helper — named macOS Spaces via WhichSpace

Usage:
  desktop.sh                 status
  desktop.sh status
  desktop.sh list
  desktop.sh doctor

  desktop.sh zen|cursor|term|studio|office|music
  desktop.sh notes|outlook|teams|resolve|obs|spotify|…
  desktop.sh go <name|n>     switch only
  desktop.sh send <name|n>   send front window, stay
  desktop.sh move <name|n>   send front window and follow
  desktop.sh left|right|prev

  desktop.sh apply           labels + badges in WhichSpace
  desktop.sh reset           clear labels + badges
  desktop.sh theme           apply + try colors/symbols
  desktop.sh setup [--all]   apply and place apps on Spaces

Desktops (this machine):
  1 Zen      Zen Browser
  2 Cursor   Cursor IDE  (notes/obsidian)
  3 Term     Ghostty     (kitty-quake overlays every Space)
  4 Studio   DaVinci Resolve, Screen Studio, OBS
  5 Office   Word, Outlook, Teams, Excel, Calendar
  6 Music    Spotify

Create missing Spaces in Mission Control (Control-Up, click +)
before apply/setup. WhichSpace cannot create desktops.
EOF
}

# ── Main ────────────────────────────────────

main() {
    local cmd="${1:-status}"
    shift || true

    case "$cmd" in
        -h|--help|help) usage ;;
        status)         cmd_status ;;
        list)           cmd_list ;;
        doctor)         cmd_doctor ;;
        apply)          cmd_apply ;;
        reset)          cmd_reset ;;
        theme)          cmd_theme ;;
        setup)          cmd_setup "${1:-}" ;;
        go)             [[ $# -ge 1 ]] || { echo "usage: desktop.sh go <name|n>" >&2; exit 1; }
                        cmd_go "$1" ;;
        send)           [[ $# -ge 1 ]] || { echo "usage: desktop.sh send <name|n>" >&2; exit 1; }
                        cmd_send "$1" ;;
        move)           [[ $# -ge 1 ]] || { echo "usage: desktop.sh move <name|n>" >&2; exit 1; }
                        cmd_move "$1" ;;
        left)           cmd_left ;;
        right)          cmd_right ;;
        prev|previous)  cmd_prev ;;
        *)              cmd_focus "$cmd" ;;
    esac
}

main "$@"
