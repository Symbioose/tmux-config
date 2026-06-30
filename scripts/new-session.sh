#!/usr/bin/env bash
# Ouvre une nouvelle session (un terminal), nommée d'après le dossier, sans
# aucune question ni message. L'agent lancé dedans est détecté automatiquement.
#   $1 = dossier de départ   $2 = tty du client (pour switch-client fiable)
# Lancé via `run-shell -b` => silencieux quoi qu'il arrive.
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"

dir="${1:-$PWD}"; client="$2"
[ -d "$dir" ] || dir="$HOME"
base=$(basename "$dir"); [ -z "$base" ] && base=term

name="$base"; i=2
while tmux has-session -t "=$name" 2>/dev/null; do name="$base-$i"; i=$((i + 1)); done

tmux new-session -d -s "$name" -c "$dir" 2>/dev/null || exit 0
"$SCRIPTS/ensure-sidebar.sh" "$(tmux display-message -p -t "$name" '#{window_id}' 2>/dev/null)" >/dev/null 2>&1

if [ -n "$client" ]; then
  tmux switch-client -c "$client" -t "$name" 2>/dev/null
else
  tmux switch-client -t "$name" 2>/dev/null
fi
exit 0
