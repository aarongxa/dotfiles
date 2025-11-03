# Ghostty shell integration for Bash. This should be at the top of your bashrc!
# Only load bash integration when actually running bash (not zsh)
if [ -n "${GHOSTTY_RESOURCES_DIR}" ] && [ -n "${BASH_VERSION}" ] && [ -z "${ZSH_VERSION}" ]; then
    builtin source "${GHOSTTY_RESOURCES_DIR}/shell-integration/bash/ghostty.bash" 2>/dev/null || true
fi

# Created by `pipx` on 2023-09-08 18:50:14
export PATH="$PATH:/Users/aaron/.local/bin"

# Only set PS1 when actually running bash (not zsh)
# In zsh, starship will handle the prompt
if [ -n "${BASH_VERSION}" ] && [ -z "${ZSH_VERSION}" ]; then
    # Initialize Starship for bash if available, otherwise use custom PS1
    if command -v starship &> /dev/null; then
        eval "$(starship init bash)"
    else
        export PS1="\[$(tput setaf 39)\]\u\[$(tput setaf 45)\]@\[$(tput setaf 51)\]mac \[$(tput setaf 195)\]\w \[$(tput sgr0)\]$ "
    fi
fi

        if [[ "$TERM_PROGRAM" == "ghostty" ]]; then
            export TERM=xterm-256color
        fi

# shellgen: Generate exact shell command from natural language; no execution; globbing disabled; prints and adds to history
shellgen() {
  set -f # disable globbing
  local query="$*"
  local prompt="You are a command line expert. User query: ${query}. Output ONLY the exact shell command. No explanations, no markdown, no extra text—just the raw command."
  local cmd
  cmd=$(curl -s http://localhost:11434/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d "{\"model\": \"glm4:9b\", \"messages\": [{\"role\": \"user\", \"content\": \"$prompt\"}], \"stream\": false}" | \
    jq -r '.choices[0].message.content' | \
    sed -e 's/^```[a-z]*//' -e 's/```$//' -e 's/^`//' -e 's/`$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | \
    tr -d '\000-\037')
  set +f # re-enable globbing
  history -s "$cmd"
  printf '\n'
  printf '\033[1;32m =❯ \033[0m%s\n\n' "$cmd"
}

# Disable bracketed past ghosty
printf '\e[?2004l'

