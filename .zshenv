# uv
export PATH="/Users/aaron/.local/bin:$PATH"

# CRITICAL: Fix TERM in tmux before ANY other initialization
# This must be in .zshenv because it's sourced first (works with sh syntax)
if [ -n "$TMUX" ]; then
    case "$TERM" in
        screen*|xterm*|*256color*)
            # Already good
            ;;
        *)
            export TERM="screen-256color"
            ;;
    esac
fi

# Disable Ghostty shell integration when inside tmux to prevent escape sequence issues
if [ -n "$TMUX" ]; then
    export GHOSTTY_SHELL_INTEGRATION=0
fi
