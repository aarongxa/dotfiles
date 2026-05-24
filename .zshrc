# .zshrc - Zsh configuration

# Kitty shell integration (disabled by default - set KITTY_SHELL_INTEGRATION=1 to enable)
if [[ -n "$KITTY_WINDOW_ID" ]] && [[ -z "$TMUX" ]] && [[ "${KITTY_SHELL_INTEGRATION:-0}" = "1" ]]; then
    if [[ -n "$KITTY_INSTALLATION_DIR" ]]; then
        source "$KITTY_INSTALLATION_DIR/shell-integration/zsh/kitty-integration.zsh" 2>/dev/null || true
    else
        # Fallback: manual kitty shell integration
        autoload -Uz add-zsh-hook
        function _kitty_precmd() { printf '\e]133;D;%s\033\\' "$?"; }
        function _kitty_preexec() { printf '\e]133;A\033\\'; }
        add-zsh-hook precmd _kitty_precmd
        add-zsh-hook preexec _kitty_preexec
    fi
fi

# Initialize Starship prompt (must be before .zprofile sources .bashrc)
unset PROMPT PS1 2>/dev/null
FALLBACK_PROMPT='%F{cyan}%n@%m%f:%F{blue}%~%f %# '

# Starship is preferred - always use it if available
if [[ -o interactive ]] && command -v starship &> /dev/null 2>&1 && [[ "$TERM" != "dumb" ]]; then
    eval "$(starship init zsh)"
    
    # Verify Starship initialized (should add 'starship_precmd' to precmd_functions)
    if ! (( ${+precmd_functions} )) || ! [[ "${precmd_functions[@]}" =~ "starship_precmd" ]]; then
        echo "Warning: Starship failed to initialize, using fallback prompt" >&2
        PROMPT="$FALLBACK_PROMPT"
    else
        # Set initial PROMPT from Starship
        PROMPT="$(starship prompt 2>/dev/null)" || PROMPT="$FALLBACK_PROMPT"
    fi
else
    PROMPT="$FALLBACK_PROMPT"
fi

# Handle Ghostty shell integration (controlled via GHOSTTY_SHELL_INTEGRATION in .zshenv)
if [[ -n "$TMUX" ]]; then
    export GHOSTTY_SHELL_INTEGRATION=0
    # Remove Ghostty hooks if loaded
    if [[ -n "${GHOSTTY_RESOURCES_DIR}" ]]; then
        unfunction _ghostty_precmd _ghostty_preexec 2>/dev/null
        precmd_functions=(${precmd_functions[@]/_ghostty_*/})
        preexec_functions=(${preexec_functions[@]/_ghostty_*/})
    fi
elif [[ -n "${GHOSTTY_RESOURCES_DIR}" ]] || [[ "$TERM" = "ghostty" ]]; then
    export GHOSTTY_SHELL_INTEGRATION="${GHOSTTY_SHELL_INTEGRATION:-0}"
fi

# Source .zprofile (may set PS1, but Starship will override it)
[[ -f ~/.zprofile ]] && source ~/.zprofile

# Ensure Starship always sets PROMPT (fixes disappearing prompt on empty commands)
# This hook runs AFTER starship_precmd and always regenerates PROMPT from Starship
if command -v starship &> /dev/null && [[ "$TERM" != "dumb" ]]; then
    unset PS1 2>/dev/null || true
    
    # Always regenerate PROMPT from Starship - ensures it's never empty
    function _ensure_starship_prompt() {
        # Always get fresh prompt from Starship (runs after starship_precmd)
        local starship_prompt="$(starship prompt 2>/dev/null)"
        PROMPT="${starship_prompt:-$FALLBACK_PROMPT}"
    }
    
    autoload -Uz add-zsh-hook
    add-zsh-hook precmd _ensure_starship_prompt
    
    # Ensure initial PROMPT is set from Starship
    [[ -z "$PROMPT" ]] || [[ -z "${PROMPT// }" ]] && PROMPT="$(starship prompt 2>/dev/null)" || PROMPT="$FALLBACK_PROMPT"
fi

# y2tx - YouTube to MP4 downloader with optional time range and output filename
# Usage: y2tx VIDEO_URL [TIME_RANGE] [OUTPUT_FILENAME]
y2tx() {
    # Check if video URL is provided
    if [[ -z "${1:-}" ]]; then
        echo "Error: Video URL is required" >&2
        echo "Usage: y2tx VIDEO_URL [TIME_RANGE] [OUTPUT_FILENAME]" >&2
        return 1
    fi

    local VIDEO_URL="$1"
    local TIME_RANGE="${2:-}"
    local OUTPUT_FILE="${3:-}"

    # Build yt-dlp command
    local CMD=(
        yt-dlp
        --force-keyframes-at-cuts
        -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"
        --merge-output-format mp4
        --ppa "Merger:+ffmpeg:-movflags +faststart"
    )

    # Add time range if provided
    if [[ -n "$TIME_RANGE" ]]; then
        CMD+=(--download-sections "*${TIME_RANGE}")
    fi

    # Add output filename if provided
    if [[ -n "$OUTPUT_FILE" ]]; then
        CMD+=(-o "$OUTPUT_FILE")
    fi

    # Add video URL
    CMD+=("$VIDEO_URL")

    # Execute the command
    "${CMD[@]}"
}


# Buffer API — social media scheduling
# export BUFFER_ACCESS_TOKEN="your-token-here"
