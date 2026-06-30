#!/usr/bin/env bash
# Crée une session IA bien formée (prefix + n). Lancé dans un popup -E.
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"

printf '\033[1m  Nouvelle session IA\033[0m\n\n'

printf 'Nom de la session : '
read -r name
[ -z "$name" ] && exit 0

# --- Dossier : tous les dossiers sous ~/Developer + frappe libre ---------
# --print-query : si tu tapes un chemin absent de la liste, il est utilisé
# (et créé) -> permet d'ouvrir/créer n'importe quel dossier.
list=$(find "$HOME/Developer" -maxdepth 5 -type d \
        \( -name node_modules -o -name .git -o -name .venv -o -name dist \) -prune \
        -o -type d -print 2>/dev/null | sed "s|^$HOME/|~/|" | sort)
out=$(printf '%s\n' "$list" | fzf --reverse --print-query \
        --prompt='dossier  ' \
        --header='filtre fuzzy · ou tape un chemin (créé si absent) · Entrée')
query=$(printf '%s\n' "$out" | sed -n 1p)
pick=$(printf '%s\n'  "$out" | sed -n 2p)
dir="${pick:-$query}"
dir="${dir/#\~/$HOME}"
[ -z "$dir" ] && dir="$HOME"
[ -d "$dir" ] || mkdir -p "$dir" 2>/dev/null || dir="$HOME"

# --- Agent : liste courante + frappe libre -------------------------------
agent=$(printf 'claude\ndevin\naider\ncodex\ngoose\nopencode\ncursor\n' \
        | fzf --reverse --print-query --prompt='agent  ' \
              --header='choisis ou tape la commande · Entrée' \
        | sed -n '$p')
agent=${agent:-claude}

if tmux has-session -t "=$name" 2>/dev/null; then
  tmux switch-client -t "$name"; exit 0
fi

tmux new-session -d -s "$name" -c "$dir"
tmux set-option -t "$name" @agent "$agent"
win=$(tmux display-message -p -t "$name" '#{window_id}')
"$SCRIPTS/ensure-sidebar.sh" "$win"
tmux send-keys -t "$name" "$agent" Enter
tmux switch-client -t "$name"
