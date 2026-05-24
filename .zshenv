# uv
export PATH="$HOME/.local/bin:$PATH"

# Terminal detection and TERM configuration for kitty and ghostty
# This must be in .zshenv because it's sourced first (works with sh syntax)

# Detect terminal emulator
if [ -n "$KITTY_WINDOW_ID" ]; then
    # Kitty terminal detected
    if [ -n "$TMUX" ]; then
        # Inside tmux - use screen-256color
        export TERM="screen-256color"
        # Disable kitty shell integration in tmux
        export KITTY_SHELL_INTEGRATION=0
    else
        # Direct kitty session - use xterm-kitty for full kitty features
        export TERM="xterm-kitty"
        # Disable kitty shell integration by default (causes prompt disappearing issues)
        # Set KITTY_SHELL_INTEGRATION=1 to enable if you want to try it
        export KITTY_SHELL_INTEGRATION="${KITTY_SHELL_INTEGRATION:-0}"
    fi
elif [ -n "$GHOSTTY_RESOURCES_DIR" ] || [ "$TERM" = "ghostty" ]; then
    # Ghostty terminal detected
    if [ -n "$TMUX" ]; then
        # Inside tmux - use screen-256color
        export TERM="screen-256color"
        # Disable Ghostty shell integration when inside tmux to prevent escape sequence issues
        export GHOSTTY_SHELL_INTEGRATION=0
    else
        # Direct ghostty session - use xterm-256color or ghostty
        export TERM="${TERM:-xterm-256color}"
        # Disable Ghostty shell integration by default (can cause prompt issues)
        # Set GHOSTTY_SHELL_INTEGRATION=1 to enable if you want to try it
        export GHOSTTY_SHELL_INTEGRATION="${GHOSTTY_SHELL_INTEGRATION:-0}"
    fi
elif [ -n "$TMUX" ]; then
    # Inside tmux but terminal not explicitly detected - fix TERM
    case "$TERM" in
        screen*|xterm*|*256color*)
            # Already good
            ;;
        *)
            export TERM="screen-256color"
            ;;
    esac
    # Disable shell integrations in tmux
    export GHOSTTY_SHELL_INTEGRATION=0
fi
