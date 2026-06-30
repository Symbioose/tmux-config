#!/usr/bin/env bash
# Force un repaint immédiat de toutes les colonnes : envoie SIGUSR1 au process
# de chaque pane sidebar, identifié par son PID via tmux (#{pane_pid}).
# Sûr : aucune correspondance par motif (pas de pkill -f), donc rien d'autre
# ne peut être touché.
tmux list-panes -a -F '#{pane_pid} #{@is_sidebar}' 2>/dev/null \
  | awk '$2==1 {print $1}' \
  | while IFS= read -r p; do kill -USR1 "$p" 2>/dev/null; done
