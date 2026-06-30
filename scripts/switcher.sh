#!/usr/bin/env bash
# Popup fuzzy de switch de session (prefix + a).
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
PRETTY="$SCRIPTS/sessions.sh pretty"

sel=$("$SCRIPTS/sessions.sh" pretty | fzf \
  --ansi --no-sort --reverse --info=inline \
  --delimiter='\t' --with-nth=2 \
  --prompt='  ' --pointer='▌' \
  --header='enter: switch    ^d: terminé    ^x: kill    ^n: nouvelle' \
  --bind "ctrl-d:execute-silent(tmux set-option -t {1} @status done)+reload($PRETTY)" \
  --bind "ctrl-x:execute-silent(tmux kill-session -t {1})+reload($PRETTY)" \
  --bind "ctrl-n:execute(tmux display-popup -E -w 60% -h 55% '$SCRIPTS/new-ai-session.sh')+reload($PRETTY)" \
) || exit 0

name=$(printf '%s' "$sel" | cut -f1)
[ -n "$name" ] && tmux switch-client -t "$name"
