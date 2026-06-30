#!/usr/bin/env bash
# Ouvre une nouvelle session (un terminal), nommée d'après le dossier, sans
# aucune question. L'agent que tu lances dedans est détecté automatiquement.
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"

dir="${1:-$PWD}"
[ -d "$dir" ] || dir="$HOME"
base=$(basename "$dir"); [ -z "$base" ] && base=term

# nom unique : repo, repo-2, repo-3…
name="$base"; i=2
while tmux has-session -t "=$name" 2>/dev/null; do name="$base-$i"; i=$((i + 1)); done

tmux new-session -d -s "$name" -c "$dir"
"$SCRIPTS/ensure-sidebar.sh" "$(tmux display-message -p -t "$name" '#{window_id}')" >/dev/null 2>&1 &
tmux switch-client -t "$name"
