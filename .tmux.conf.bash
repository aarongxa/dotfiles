#-------------------------------------------
#
# Title: tmux config (Bash version)
# Author: Aaron J. Griffith
# Purpose: Better your command line
#
# Created: 2014
# Updated: 2017, 2023, 2025
#
# Additional Information: PREFIX is Ctrl+b
#
# Required files:
#  - clssh.sh - Cluster SSH (ensure it exists at ~/clssh.sh)
#-----------------------------------------------------

set-option -g default-terminal "screen-256color"
set-option -sa terminal-overrides ',xterm-256color:RGB'
set-option -sa terminal-overrides ',screen-256color:RGB'

set-option -g default-shell /bin/bash
set-option -g default-command "env GHOSTTY_SHELL_INTEGRATION=0 /bin/bash -l"

set -s escape-time 0
set -g history-limit 50000
set -g display-time 2000
setw -g monitor-activity on
set -g status-bg black
set -g status-fg white
set -g mouse on
set-window-option -g mode-keys vi
bind-key -T copy-mode-vi v send-keys -X begin-selection
bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
set-option -g base-index 1
setw -g pane-base-index 1
setw -g automatic-rename on
set-option -g status-left '#[fg=green][#[bg=black,fg=cyan]#S#[fg=green]] #[fg=white,bold][#{?pane_synchronized,#[fg=green]SYNC,#[fg=yellow]NO-SYNC}#[fg=white,bold]] #[fg=cyan][#{AWS_PROFILE_STATUS}]#[fg=magenta][#{AWS_REGION_STATUS}] :: '
set-option -g status-left-length 60
set-option -g status-right ''
set-option -g status-interval 2
set -g focus-events on
setw -g aggressive-resize on

### Key Bindings ###

bind / command-prompt -p "Man Page:" "split-window -h 'exec man %%'"
unbind-key t
bind-key -n C-t command-prompt -p "SSH:" "new-window -n %1 'ssh %1'"
unbind-key e
bind-key -n C-e command-prompt -p "Cluster SSH:" "new-window 'exec sh ~/clssh.sh %%'"
unbind-key %
bind-key | split-window -h
bind-key - split-window -v
bind-key -n C-p paste-buffer
bind-key -n M-Right next-window
bind-key -n M-Left previous-window
bind-key a setw synchronize-panes \; display "Pane Synchronize: #{?pane_synchronized,Enabled,Disabled}"
bind-key -n F9 command-prompt "rename-window %%"

run-shell "eval $($HOME/tmux-helpers/generate_fzf_menu.sh)"
bind-key -n C-f run-shell -b ~/.tmux/plugins/tmux-fzf/main.sh
set -g @tmux-fzf-options '-p -w 62% -h 38% -m'
unbind-key -T prefix r
bind-key -T prefix r source-file ~/.tmux.conf \; display "Reloaded tmux Config"
bind-key -n C-g command-prompt -p "ShellGen:" "split-window -v 'sh ~/shellgen.sh %%"

