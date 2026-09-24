#!/usr/bin/env bash
#==============================================================================
# Stage dotfiles to home directory
# Creates symlinks from the dotfiles repo to $HOME and $HOME/.config
#
# Usage:
#   ./stage-dotfiles.sh        # auto-detects platform
#   ./stage-dotfiles.sh --dry-run  # preview without making changes
#
# Supports: macOS (Darwin) and Linux (Debian/Ubuntu/etc.)
#==============================================================================

set -euo pipefail

# ── Colors ──────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ── Paths ───────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="$HOME"
BACKUP_DIR="$HOME_DIR/dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

# ── Platform Detection ──────────────────────
OS="$(uname -s)"
IS_MACOS=false
IS_LINUX=false
case "$OS" in
    Darwin) IS_MACOS=true ;;
    Linux)  IS_LINUX=true ;;
    *)      echo -e "${RED}Warning: Unknown OS '$OS' — proceeding with best-effort${NC}" ;;
esac

echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     AGXA Dotfiles — Stage Installer     ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Platform: ${GREEN}$OS${NC}"
echo -e "  Source:   ${GREEN}$SCRIPT_DIR${NC}"
echo -e "  Target:   ${GREEN}$HOME_DIR${NC}"
$DRY_RUN && echo -e "  Mode:     ${YELLOW}DRY RUN (no changes)${NC}"
echo ""

# ── Files to symlink to $HOME ──────────────
DOTFILES=(
    ".bashrc"
    ".tmux.conf"
    ".zprofile"
    ".zshenv"
    ".zshrc"
)

# ── Scripts to symlink to $HOME (+chmod) ───
SCRIPTS=(
    "asp-tmux-fzf.sh"
    "clssh.sh"
    "tmux-dashboard.sh"
)

# macOS-only scripts (skipped on Linux)
if $IS_MACOS; then
    SCRIPTS+=("kitty-quake.sh")
fi

# ── Files to symlink to $HOME/.config ──────
# (plain assignments — macOS /bin/bash is 3.2, no associative arrays)

# ── Directories to symlink to $HOME/.config ─
CONFIG_DIRS=(
    "btop"
    "cava"
    "gh"
    "kitty"
    "neofetch"
    "wtf"
)

# macOS-only configs (skipped on Linux)
if $IS_MACOS; then
    CONFIG_DIRS+=("macos")
    # macmon.json — macOS system monitor (would go to its own path)
    :
fi

# ── Helpers ─────────────────────────────────

backup_file() {
    local target="$1"
    if [[ -e "$target" ]] && [[ ! -L "$target" ]]; then
        local dest="$BACKUP_DIR/${target#$HOME_DIR/}"
        echo -e "  ${YELLOW}↳ backing up: $target${NC}"
        $DRY_RUN || { mkdir -p "$(dirname "$dest")" && cp -r "$target" "$dest"; }
    fi
}

create_symlink() {
    local source="$1"
    local target="$2"

    if $DRY_RUN; then
        echo -e "  ${GREEN}→ would link: $target → $source${NC}"
        return
    fi

    # Remove existing
    if [[ -L "$target" ]]; then
        rm -f "$target"
    elif [[ -d "$target" ]]; then
        rm -rf "$target"
    elif [[ -e "$target" ]]; then
        rm -f "$target"
    fi

    mkdir -p "$(dirname "$target")"
    ln -s "$source" "$target"
    echo -e "  ${GREEN}✓ linked: $target → $source${NC}"
}

# ── Main ────────────────────────────────────

# -- Dotfiles --
echo -e "${GREEN}[dotfiles → ~]${NC}"
for file in "${DOTFILES[@]}"; do
    src="$SCRIPT_DIR/$file"
    tgt="$HOME_DIR/$file"
    [[ -f "$src" ]] || { echo -e "  ${RED}✗ missing: $src${NC}"; continue; }
    backup_file "$tgt"
    create_symlink "$src" "$tgt"
done

# -- Scripts --
echo ""
echo -e "${GREEN}[scripts → ~]${NC}"
for script in "${SCRIPTS[@]}"; do
    src="$SCRIPT_DIR/$script"
    tgt="$HOME_DIR/$script"
    [[ -f "$src" ]] || { echo -e "  ${RED}✗ missing: $src${NC}"; continue; }
    backup_file "$tgt"
    create_symlink "$src" "$tgt"
    $DRY_RUN || chmod +x "$src"
done

# -- macOS desktop helper (subdir → ~/desktop.sh) --
if $IS_MACOS; then
    echo ""
    echo -e "${GREEN}[macos scripts → ~]${NC}"
    src="$SCRIPT_DIR/macos/desktop.sh"
    tgt="$HOME_DIR/desktop.sh"
    if [[ -f "$src" ]]; then
        backup_file "$tgt"
        create_symlink "$src" "$tgt"
        $DRY_RUN || chmod +x "$src"
        $DRY_RUN || chmod +x "$SCRIPT_DIR"/macos/raycast/*.sh 2>/dev/null || true
    else
        echo -e "  ${RED}✗ missing: $src${NC}"
    fi

    src="$SCRIPT_DIR/macos/wallpaper-uhd.sh"
    tgt="$HOME_DIR/wallpaper-uhd.sh"
    if [[ -f "$src" ]]; then
        backup_file "$tgt"
        create_symlink "$src" "$tgt"
        $DRY_RUN || chmod +x "$src"
    else
        echo -e "  ${RED}✗ missing: $src${NC}"
    fi
fi

# -- Special files --
echo ""
echo -e "${GREEN}[special → ~/.config]${NC}"
src="$SCRIPT_DIR/starship.toml"
tgt="$HOME_DIR/.config/starship.toml"
if [[ -f "$src" ]]; then
    backup_file "$tgt"
    create_symlink "$src" "$tgt"
else
    echo -e "  ${RED}✗ missing: $src${NC}"
fi

# -- Config directories --
echo ""
echo -e "${GREEN}[config dirs → ~/.config]${NC}"
for dir in "${CONFIG_DIRS[@]}"; do
    src="$SCRIPT_DIR/$dir"
    tgt="$HOME_DIR/.config/$dir"
    [[ -d "$src" ]] || { echo -e "  ${RED}✗ missing: $src${NC}"; continue; }
    backup_file "$tgt"
    create_symlink "$src" "$tgt"
done

# ── Summary ─────────────────────────────────
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Done!${NC}"
$DRY_RUN && echo -e "  ${YELLOW}(dry run — no changes made)${NC}"
echo ""

if [[ -d "$BACKUP_DIR" ]]; then
    echo -e "  ${YELLOW}Backups: $BACKUP_DIR${NC}"
fi

echo ""
echo -e "  ${BLUE}Next steps:${NC}"
echo -e "    tmux:   tmux source-file ~/.tmux.conf"
echo -e "    zsh:    source ~/.zshrc"
if $IS_MACOS; then
    echo -e "    spaces: desktop.sh doctor && desktop.sh apply"
    echo -e "    raycast: add ~/.config/macos/raycast as a Script Commands folder"
fi
if $IS_LINUX; then
    echo ""
    echo -e "  ${BLUE}Debian prerequisites (run once):${NC}"
    echo -e "    sudo apt install -y zsh tmux btop cava neofetch fzf starship"
    echo -e "    # Kitty terminal (optional):"
    echo -e "    curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin"
fi
echo ""
