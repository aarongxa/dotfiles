#!/usr/bin/env bash
#==============================================================================
# AGXA wallpaper pipeline — 14″ Liquid Retina XDR
#
# The ~1280×720 frame is generated in the current Cursor session.
# This script does not generate images and does not start a background worker.
#
#   1280×720  →  Real-ESRGAN x4plus (local ncnn)  →  5120×2880 master
#             →  sips cover-crop                   →  3024×1964
#
# Only the 3024×1964 file is written to ~/Documents/WallpapersUHD.
# Masters stay in ~/Documents/WallpaperMasters.
#
# Usage:
#   wallpaper-uhd.sh image.png [more.png ...]
#   wallpaper-uhd.sh raw/                 # every png/jpg/webp in the folder
#
# Overrides:
#   WALLPAPER_OUT      delivery dir (default ~/Documents/WallpapersUHD)
#   WALLPAPER_MASTERS  5120×2880 dir (default ~/Documents/WallpaperMasters)
#   REALESRGAN_ROOT    folder that contains realesrgan-ncnn-vulkan and models/
#==============================================================================

set -euo pipefail

GEN_W=1280
GEN_H=720
MASTER_W=5120
MASTER_H=2880
DELIVER_W=3024
DELIVER_H=1964
# round(5120 * 1964 / 2880) — same sips -z the NeoTokyo v2 export used
SCALED_W=$(( (MASTER_W * DELIVER_H + MASTER_H / 2) / MASTER_H ))

OUT_DIR="${WALLPAPER_OUT:-$HOME/Documents/WallpapersUHD}"
MASTER_DIR="${WALLPAPER_MASTERS:-$HOME/Documents/WallpaperMasters}"
ESR_ROOT="${REALESRGAN_ROOT:-$HOME/Documents/MacWallpapers-NeoTokyo-v2/tools/realesrgan-ncnn-vulkan}"
ESR_BIN="$ESR_ROOT/realesrgan-ncnn-vulkan"
ESR_MODELS="$ESR_ROOT/models"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { printf '%s %s\n' "$(date +%Y-%m-%dT%H:%M:%S%z)" "$*"; }
die() { echo -e "${RED}$*${NC}" >&2; exit 1; }

usage() {
    cat <<EOF
Usage: wallpaper-uhd.sh IMAGE [IMAGE ...]
       wallpaper-uhd.sh DIRECTORY

Takes ~1280×720 frames (generated in this session), upscales with
Real-ESRGAN x4plus to ${MASTER_W}×${MASTER_H}, and writes only
${DELIVER_W}×${DELIVER_H} into:
  $OUT_DIR
EOF
}

[[ "$(uname -s)" == "Darwin" ]] || die "macOS only (needs sips and the local Real-ESRGAN binary)."
[[ $# -ge 1 ]] || { usage >&2; exit 1; }
[[ "$1" != "-h" && "$1" != "--help" ]] || { usage; exit 0; }

command -v sips >/dev/null || die "sips not found."
[[ -x "$ESR_BIN" ]] || die "Real-ESRGAN binary not executable: $ESR_BIN"
[[ -f "$ESR_MODELS/realesrgan-x4plus.param" ]] || die "Missing x4plus model in $ESR_MODELS"

dims() {
    sips -g pixelWidth -g pixelHeight "$1" | awk '/pixelWidth/{w=$2} /pixelHeight/{h=$2} END{print w, h}'
}

# Cover-crop to exactly 1280×720 so x4plus lands on 5120×2880.
fit_gen() {
    local src="$1" dest="$2" w h sw sh tmp
    read -r w h <<< "$(dims "$src")"
    if [[ "$w" == "$GEN_W" && "$h" == "$GEN_H" ]]; then
        cp "$src" "$dest"
        return
    fi
    tmp="${dest}.fit.png"
    if [[ $((w * GEN_H)) -ge $((h * GEN_W)) ]]; then
        sw=$(( (w * GEN_H + h / 2) / h ))
        sips -z "$GEN_H" "$sw" "$src" --out "$tmp" >/dev/null
    else
        sh=$(( (h * GEN_W + w / 2) / w ))
        sips -z "$sh" "$GEN_W" "$src" --out "$tmp" >/dev/null
    fi
    sips -c "$GEN_H" "$GEN_W" "$tmp" --out "$dest" >/dev/null
    rm -f "$tmp"
}

# 5120×2880 → 3024×1964, center crop. sips -z matches the v2 native export.
deliver() {
    local src="$1" dest="$2" tmp
    tmp="$(mktemp -t wallpaper-uhd)"
    sips -z "$DELIVER_H" "$SCALED_W" "$src" --out "${tmp}.png" >/dev/null
    sips -c "$DELIVER_H" "$DELIVER_W" "${tmp}.png" --out "$dest" >/dev/null
    rm -f "$tmp" "${tmp}.png"
}

WORK="$(mktemp -d -t wallpaper-uhd)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/raw" "$OUT_DIR" "$MASTER_DIR"

inputs=()
for arg in "$@"; do
    if [[ -d "$arg" ]]; then
        while IFS= read -r src; do
            [[ -n "$src" ]] || continue
            inputs+=("$src")
        done <<EOF
$(find "$arg" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) | sort)
EOF
    elif [[ -f "$arg" ]]; then
        inputs+=("$arg")
    else
        die "Not a file or directory: $arg"
    fi
done

[[ ${#inputs[@]} -gt 0 ]] || die "No images found."

n=0
for src in "${inputs[@]}"; do
    base="$(basename "$src")"
    ext="$(printf '%s' "$base" | tr '[:upper:]' '[:lower:]')"
    case "$ext" in
        *.png|*.jpg|*.jpeg|*.webp) ;;
        *) die "Unsupported type: $src" ;;
    esac
    name="${base%.*}.png"
    if [[ -e "$WORK/raw/$name" ]]; then
        die "Duplicate name: $name"
    fi
    fit_gen "$src" "$WORK/raw/$name"
    read -r w h <<< "$(dims "$WORK/raw/$name")"
    [[ "$w" == "$GEN_W" && "$h" == "$GEN_H" ]] || die "Fit failed for $src (${w}×${h})"
    n=$((n + 1))
done

[[ "$n" -gt 0 ]] || die "No images found."

log "start n=$n model=realesrgan-x4plus ${GEN_W}x${GEN_H} -> ${MASTER_W}x${MASTER_H}"
"$ESR_BIN" \
    -i "$WORK/raw" \
    -o "$MASTER_DIR" \
    -n realesrgan-x4plus \
    -s 4 \
    -f png \
    -m "$ESR_MODELS"
log "upscale_done"

shopt -s nullglob
for src in "$WORK/raw"/*.png; do
    name="$(basename "$src")"
    master="$MASTER_DIR/$name"
    [[ -f "$master" ]] || die "Missing master: $master"
    read -r w h <<< "$(dims "$master")"
    [[ "$w" == "$MASTER_W" && "$h" == "$MASTER_H" ]] || die "Master $name is ${w}×${h}, expected ${MASTER_W}×${MASTER_H}"
    deliver "$master" "$OUT_DIR/$name"
    read -r w h <<< "$(dims "$OUT_DIR/$name")"
    [[ "$w" == "$DELIVER_W" && "$h" == "$DELIVER_H" ]] || die "Delivery $name is ${w}×${h}, expected ${DELIVER_W}×${DELIVER_H}"
    log "exported $name"
done

log "all_done out=$OUT_DIR masters=$MASTER_DIR"
echo -e "${GREEN}${n} wallpaper(s) → ${OUT_DIR}${NC} (${DELIVER_W}×${DELIVER_H})"
echo -e "${BLUE}masters → ${MASTER_DIR}${NC} (${MASTER_W}×${MASTER_H})"
