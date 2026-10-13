# AGXA Dotfiles

Personal dotfiles — shell, tmux, terminal, and tool configs.  
Maintained for **macOS** and **Debian/Ubuntu Linux**.

## Quick Start

```bash
git clone https://github.com/aarongxa/dotfiles.git ~/dotfiles
cd ~/dotfiles
./stage-dotfiles.sh          # symlink everything into place
./stage-dotfiles.sh --dry-run  # preview first
```

## What's Included

| Area | Files | Notes |
|------|-------|-------|
| **Shell** | `.zshrc`, `.zshenv`, `.zprofile`, `.bashrc` | Zsh primary, Bash fallback |
| **Prompt** | `starship.toml` | Starship with pastel neo-tokyo palette |
| **tmux** | `.tmux.conf` | Catppuccin Macchiato theme, TPM plugins |
| **Terminal** | `kitty/` (kitty.conf) | Kitty with Dracula colors, quake mode |
| **Monitoring** | `btop/`, `cava/`, `wtf/` | System monitor, audio vis, dashboard |
| **GitHub** | `gh/` | gh CLI config + hosts |
| **AWS** | `asp-tmux-fzf.sh` | Profile/region selector with fzf + tmux |
| **Tools** | `clssh.sh`, `tmux-dashboard.sh`, `pdfc.sh` | Cluster SSH, dashboard layout, PDF compression |
| **macOS** | `macos/` (`desktop.sh`, WhichSpace) | Named desktops: Zen, Cursor, Ghostty, Studio, Office, Music |

## tmux Configuration

- **Theme**: Catppuccin Macchiato with rounded window style
- **Plugins** (TPM): sensible, resurrect, continuum, yank, pain-control, vim-tmux-navigator, fzf, tilit
- **Status bar**: session + directory (left), user@host + datetime (right)
- **Pane sync indicator**: mauve badge appears when panes are synchronized (`prefix a`)
- **Auto-save**: continuum saves every 15 minutes, restores on start

### tmux Key Bindings

| Key | Action |
|-----|--------|
| `prefix a` | Toggle pane synchronization |
| `prefix r` | Reload config |
| `prefix \|` | Split horizontal |
| `prefix -` | Split vertical |
| `Ctrl-f` | fzf launcher |
| `Ctrl-t` | SSH to host (prompt) |
| `Ctrl-e` | Cluster SSH (prompt) |
| `Alt-→/←` | Next/previous window |

## PDF Compression (pdfc)

Compress PDF files with Ghostscript.

**Requirement**: `brew install ghostscript`

**Install**: Symlink to a directory in your PATH  
```bash
ln -s "$PWD/pdfc.sh" /opt/homebrew/bin/pdfc
```

**Usage**:  
```bash
pdfc file.pdf [ebook|printer|prepress|screen|custom]
```

Running without arguments shows an interactive menu with quality options.

**Output**: `file_compressed.pdf` (original file is never modified)

**Quality Levels**:
- `ebook`: good quality, smaller (default)
- `printer`: high quality, 300 dpi
- `prepress`: best quality, keeps color profiles
- `screen`: smallest, 72 dpi
- `custom`: pick a custom dpi value

## Platform Notes

### macOS
- Kitty quake mode (`kitty-quake.sh`) uses AppleScript — macOS only
- Homebrew shellenv loaded automatically in `.zprofile`
- Named desktops (`macos/desktop.sh`) talk to [WhichSpace](https://github.com/gechr/WhichSpace) — see `macos/README.md`

```bash
desktop.sh doctor        # WhichSpace + Space count + apps
desktop.sh apply         # label Spaces: Zen / Cursor / Term / …
desk zen                 # switch and focus Zen Browser
```

### Debian/Ubuntu

```bash
# Install prerequisites
sudo apt install -y zsh tmux btop cava neofetch fzf

# Starship prompt
curl -sS https://starship.rs/install.sh | sh

# Kitty terminal (optional)
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin

# Install TPM (tmux plugin manager)
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Then run the stager
cd ~/dotfiles && ./stage-dotfiles.sh
```

After installing TPM, start tmux and press `prefix + I` to install plugins.

### Fonts

Kitty uses **Hack Nerd Font Mono**. Catppuccin status icons require a Nerd Font.  
Install: `brew install font-hack-nerd-font` (macOS) or download from [nerdfonts.com](https://www.nerdfonts.com).

## File Layout

```
dotfiles/
├── .bashrc              # Bash config (starship or fallback PS1)
├── .zshrc               # Zsh config (starship, kitty/ghostty integration)
├── .zshenv              # Zsh environment (PATH, TERM detection)
├── .zprofile            # Login shell (brew, nvm)
├── .tmux.conf           # tmux config (catppuccin + TPM plugins)
├── starship.toml        # Starship prompt config
├── stage-dotfiles.sh    # Symlink installer
├── asp-tmux-fzf.sh      # AWS profile/region selector
├── clssh.sh             # Cluster SSH launcher
├── pdfc.sh              # PDF compression with Ghostscript
├── tmux-dashboard.sh    # Multi-pane dashboard layout
├── kitty-quake.sh       # macOS-only quake terminal toggle
├── macos/               # WhichSpace named desktops + Raycast scripts
├── btop/                # btop system monitor config
├── cava/                # cava audio visualizer configs
├── gh/                  # GitHub CLI config
├── kitty/               # Kitty terminal config + quake session
├── neofetch/            # Neofetch config
├── wtf/                 # wtfutil dashboard config
└── macmon.json          # macOS system monitor gauge
```

## Updating

```bash
cd ~/dotfiles
git pull
./stage-dotfiles.sh      # re-symlink any new files
```

Changes to symlinked files update automatically — no re-staging needed.
