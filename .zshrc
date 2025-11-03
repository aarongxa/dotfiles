# .zshrc - Zsh configuration

# CRITICAL: Fix TERM first before anything else (especially for tmux)
if [[ -n "$TMUX" ]]; then
    export TERM="screen-256color"
fi

# Initialize Starship prompt - MUST be before .zprofile sources .bashrc
# Remove any existing prompt first
unset PROMPT PS1 2>/dev/null

if [[ -o interactive ]] && command -v starship &> /dev/null 2>&1 && [[ "$TERM" != "dumb" ]]; then
    # Initialize Starship - make sure TERM is correct first (should be from .zshenv)
    eval "$(starship init zsh)"
    
    # Verify Starship actually initialized by checking if it set precmd
    if ! (( ${+precmd_functions} )) || ! [[ "${precmd_functions[@]}" =~ "starship_precmd" ]]; then
        # Starship didn't initialize properly, use fallback
        PROMPT='%F{cyan}%n@%m%f:%F{blue}%~%f %# '
    fi
else
    # Fallback prompt if Starship not available or dumb terminal
    PROMPT='%F{cyan}%n@%m%f:%F{blue}%~%f %# '
fi

# Disable Ghostty shell integration escape sequences when inside tmux
# This prevents escape sequences like [\e]133;B\a][\e[5 q][\e]2;\w\a] from appearing
if [ -n "$TMUX" ]; then
    # Inside tmux - disable Ghostty shell integration
    export GHOSTTY_SHELL_INTEGRATION=0
    
    # Also unset any precmd/preexec hooks that might send escape sequences
    # Check if we have Ghostty integration loaded and disable it
    if [[ -n "${GHOSTTY_RESOURCES_DIR}" ]]; then
        # Remove any Ghostty-specific hooks
        unfunction _ghostty_precmd 2>/dev/null
        unfunction _ghostty_preexec 2>/dev/null
        # Clear precmd and preexec arrays if they contain Ghostty functions
        precmd_functions=(${precmd_functions[@]/_ghostty_*/})
        preexec_functions=(${preexec_functions[@]/_ghostty_*/})
    fi
fi

# Source .zprofile for additional configuration
if [ -f ~/.zprofile ]; then
    source ~/.zprofile
fi

# Unset bash PS1 if it was set by .bashrc (starship will handle the prompt)
unset PS1 2>/dev/null || true

# Ensure we have a prompt even if everything else fails
if [[ -z "$PROMPT" ]] && [[ -z "$PS1" ]]; then
    PROMPT='%F{cyan}%n@%m%f:%F{blue}%~%f %# '
fi

