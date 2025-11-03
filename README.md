# Dotfiles

This repository contains my shell configuration files for macOS with zsh, tmux, and Ghostty terminal emulator.

## Overview

My shell setup works with:
- **macOS** (using native zsh)
- **Ghostty** terminal emulator
- **tmux** for terminal multiplexing
- **zsh** as the primary shell
- **Starship** prompt for simple, fast, and informative prompts

## Files Overview

### `.tmux.conf`
tmux configuration file with settings for better productivity:
- **Prefix Key**: `Ctrl+b` (default)
- **Terminal Type**: `screen-256color` for zsh compatibility
- **Features**:
  - Window and pane indexing starts at 1 (not 0)
  - Vi-like copy mode
  - Mouse support enabled
  - 50,000 line scrollback buffer
  - Custom status bar with session name, sync status, AWS profile/region
  - Custom key bindings for SSH, cluster SSH, shellgen, etc.

**Key Bindings (no prefix required)**:
- `Ctrl+t` - SSH to a host
- `Ctrl+e` - Cluster SSH (requires `~/clssh.sh`)
- `Ctrl+p` - Paste latest buffer
- `Ctrl+f` - Launch tmux-fzf
- `Ctrl+g` - ShellGen (requires ollama and `~/shellgen.sh`)
- `Alt+Left/Right` - Switch windows
- `F9` - Rename window

**Key Bindings (with prefix `Ctrl+b`)**:
- `|` - Split window horizontally
- `-` - Split window vertically
- `a` - Toggle synchronize panes
- `r` - Reload tmux config
- `/` - Display man page in horizontal split

### `.zshrc`
Zsh interactive shell configuration:
- Initializes Starship prompt (must be first)
- Disables Ghostty shell integration when inside tmux to prevent escape sequence issues
- Sources `.zprofile` for additional configuration
- Clears bash PS1 so Starship takes precedence

### `.zshenv`
Zsh environment variables (sourced by all zsh instances, loads FIRST):
- Adds `~/.local/bin` to PATH (for pipx/uv installations)
- **CRITICAL**: Fixes TERM to `screen-256color` when inside tmux (must happen before Starship checks TERM)
- Disables Ghostty shell integration when inside tmux

### `.zprofile`
Zsh login shell profile:
- Sources `.bashrc` for shared configuration
- Sets up Homebrew environment
- Loads nvm (Node Version Manager)

### `.bashrc`
Bash configuration (also sourced by zsh via `.zprofile`):
- Loads Ghostty bash integration only when running bash
- Initializes Starship prompt for bash (if available), otherwise uses custom colored prompt
- Only sets PS1 when actually running bash (not zsh)
- `shellgen()` function uses ollama (local LLM) to generate shell commands from natural language (requires ollama with glm4:9b model)
- Sets PATH and other environment variables

### `starship.toml`
Starship prompt configuration file (located at `~/.config/starship.toml`):
- **Prompt Format**: `username:directory git_branch git_status ❯`
- **Color Palette**: Pastel Neo Tokyo theme
- **Modules Enabled**:
  - Username (always shown, blue)
  - Hostname (always shown, purple)
  - Directory (cyan, full path shown)
  - Git branch and status (yellow/red)
  - Battery status (when below threshold)
  - AWS profile and region (yellow)
  - Python version and virtualenv (green)
  - Node.js version (green)
- Custom symbols and styling for each module

## Installation

1. **Backup existing files**:
   ```bash
   mkdir -p ~/backup-shell-config
   cp ~/.tmux.conf ~/.zshrc ~/.zshenv ~/.zprofile ~/.bashrc ~/backup-shell-config/ 2>/dev/null
   ```

2. **Copy files to home directory**:
   ```bash
   cp dotfiles/.tmux.conf ~/
   cp dotfiles/.zshrc ~/
   cp dotfiles/.zshenv ~/
   cp dotfiles/.zprofile ~/
   cp dotfiles/.bashrc ~/
   
   # Create starship config directory and copy config
   mkdir -p ~/.config
   cp dotfiles/starship.toml ~/.config/
   ```

3. **Install Starship** (if not already installed):
   ```bash
   # Using Homebrew (recommended for macOS)
   brew install starship
   
   # Or using the official installer
   curl -sS https://starship.rs/install.sh | sh
   ```

4. **Reload configurations**:
   ```bash
   # For tmux
   tmux source-file ~/.tmux.conf
   # Or restart tmux completely
   tmux kill-server && tmux
   
   # For zsh
   source ~/.zshrc
   ```

## Key Features & Fixes

### Ghostty + tmux + zsh Compatibility

This setup fixes compatibility issues between Ghostty terminal, tmux, and zsh:

**Problem**: Ghostty's shell integration was causing escape sequences like `\[\e]133;B\a\]\[\e[5 q\]\[\e]2;\w\a\]` to appear in tmux sessions, and bash integration was failing with errors about missing `bash-preexec.sh`.

**Solutions**:
1. `.tmux.conf` uses `screen-256color` terminal type for escape sequence handling
2. `.bashrc` only loads Ghostty bash integration when actually running bash
3. `.zshenv` fixes `TERM=screen-256color` in tmux (critical for Starship - prevents TERM=dumb issue)
4. `.zshenv` and `.zshrc` disable Ghostty shell integration when inside tmux (detected via `$TMUX` variable)

### ShellGen Function

The `shellgen()` function in `.bashrc` uses ollama (local LLM) to generate shell commands from natural language:
- Requires: ollama running locally with `glm4:9b` model
- Usage: `shellgen "find all python files in current directory"`
- The command is added to history but not executed automatically

### Custom Tools Dependencies

Some features require additional scripts:
- `~/clssh.sh` - For cluster SSH functionality (Ctrl+e)
- `~/shellgen.sh` - For ShellGen in tmux (Ctrl+g)
- `~/.tmux/plugins/tmux-fzf/` - For fzf integration
- `$HOME/tmux-helpers/generate_fzf_menu.sh` - For FZF menu generation

## Terminal Type Configuration

The setup uses `screen-256color` as the default terminal type in tmux because:
- Good compatibility with modern terminal emulators
- Handles escape sequences from zsh correctly
- True color support (RGB)
- Works well with Ghostty, iTerm2, and other modern terminals

## Customization

### Changing tmux Prefix Key

To change the prefix from `Ctrl+b` to something else (e.g., `Ctrl+a`):
```bash
# In .tmux.conf, change:
set-option -g prefix C-a
unbind-key C-b
bind-key C-a send-prefix
```

### Modifying Status Bar

The status bar in `.tmux.conf` shows:
- Session name
- Pane synchronization status
- AWS profile and region (requires custom scripts)

To modify, edit the `status-left` option in `.tmux.conf`.

### Prompt Customization

The prompt is managed by **Starship**. To customize:
- Edit `~/.config/starship.toml`
- Starship is initialized in both `.zshrc` (for zsh) and `.bashrc` (for bash)
- See [Starship Documentation](https://starship.rs/config/) for customization options
- The current config uses a "pastel_neo_tokyo" color palette
- Format shows: `username:directory git_info ❯`

**Common Starship Customizations**:
- Change colors: Edit the `palette` section or individual module `style` options
- Change format: Modify the `format` string in `starship.toml`
- Add/remove modules: Enable or disable modules in the config file
- Customize symbols: Change `symbol` for modules like git_branch, python, etc.

**Example**: To change the prompt format, edit the `format` line in `starship.toml`:
```toml
format = "$username@$hostname:$directory$git_branch $git_status ❯ "
```

## Troubleshooting

### Escape Sequences Still Appearing

If you still see escape sequences in tmux:
1. Make sure you're using a new tmux session (restart tmux)
2. Verify `$TMUX` is set: `echo $TMUX`
3. Check Ghostty integration is disabled: `echo $GHOSTTY_SHELL_INTEGRATION`

### Bash Integration Errors

If you see errors about `bash-preexec.sh`:
- The `.bashrc` checks for bash before loading Ghostty integration
- Make sure you're using the updated `.bashrc` from this setup

### Colors Not Working

If colors aren't displaying correctly:
- Verify terminal type: `echo $TERM` (should be `screen-256color` in tmux)
- Check terminal supports true color
- Reload tmux config: `Ctrl+b` then `r`

### Starship Prompt Not Showing

If Starship prompt isn't appearing:
1. Verify Starship is installed: `which starship`
2. Check Starship is initialized: `grep "starship init" ~/.zshrc ~/.bashrc`
3. **Check TERM variable**: `echo $TERM` (should be `screen-256color` in tmux, not `dumb`)
4. If TERM is `dumb` in tmux, make sure `.zshenv` is fixing it (this must happen before `.zshrc` loads)
5. Reload shell config: `source ~/.zshrc`
6. Verify config file exists: `test -f ~/.config/starship.toml && echo "OK"`
7. Start a new tmux session: `tmux kill-server && tmux`
8. Test Starship directly: `starship prompt` (should show output if TERM is correct)

**Important**: Starship disables itself if `TERM=dumb`. The fix in `.zshenv` ensures TERM is set to `screen-256color` before Starship checks it.

## Starship Prompt Setup

Starship is a fast, customizable prompt that works across shells. This setup includes:

**Features**:
- Fast and async rendering (doesn't slow down your shell)
- Shows git branch, status, and ahead/behind counts
- Displays current directory (with truncation for long paths)
- Shows AWS profile and region when set
- Displays Python/Node.js versions when in projects
- Battery indicator when below thresholds
- Custom "Pastel Neo Tokyo" color scheme

**Configuration**:
- Config file: `~/.config/starship.toml`
- Initialized in `.zshrc` (primary) and `.bashrc` (fallback)
- Works in tmux sessions
- **TERM Fix**: `.zshenv` sets `TERM=screen-256color` in tmux before Starship initializes (critical fix - Starship disables if TERM=dumb)

**Customization Tips**:
- The prompt format is: `username:directory git_branch git_status ❯`
- Colors can be modified in the `palette` section
- Module visibility can be toggled by setting `disabled = true`
- See [Starship Presets](https://starship.rs/presets/) for pre-made configurations

## Notes

- Window and pane indices start at 1 (not 0) for easier mental mapping
- The configuration assumes zsh is the primary shell (macOS default)
- Some features require additional dependencies (ollama, fzf, custom scripts, starship)
- AWS profile/region status requires custom helper scripts not included here
- Starship prompt works in both zsh and bash, with zsh being the primary

## Author

Aaron J. Griffith
