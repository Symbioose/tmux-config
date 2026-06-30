#!/usr/bin/env bash
# Affiche / masque la colonne sidebar dans toutes les fenêtres (prefix + b).
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"

enabled=$(tmux show-options -gqv @sidebar_enabled); enabled=${enabled:-1}

if [ "$enabled" = "1" ]; then
  tmux set-option -g @sidebar_enabled 0
  tmux list-panes -a -F '#{pane_id} #{@is_sidebar}' \
    | awk '$2==1{print $1}' \
    | while IFS= read -r p; do tmux kill-pane -t "$p" 2>/dev/null; done
  tmux display-message "sidebar: off"
else
  tmux set-option -g @sidebar_enabled 1
  tmux list-windows -a -F '#{window_id}' \
    | while IFS= read -r wi; do "$SCRIPTS/ensure-sidebar.sh" "$wi"; done
  tmux display-message "sidebar: on"
fi
