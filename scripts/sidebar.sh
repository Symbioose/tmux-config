#!/usr/bin/env bash
# Rend la colonne de sessions (compacte). Lit sessions.sh (posé par le démon).
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"

cleanup() { printf '\033[?25h'; }
trap cleanup EXIT
trap ':' USR1            # SIGUSR1 interrompt le sleep -> repaint immédiat
printf '\033[?25l\033[2J'

me=$(tmux display-message -p -t "$TMUX_PANE" '#{session_name}' 2>/dev/null)

while :; do
  w=$(tmux display-message -p -t "$TMUX_PANE" '#{pane_width}' 2>/dev/null); w=${w:-16}
  max=$((w - 3)); [ "$max" -lt 1 ] && max=1

  out=$'\033[38;5;240m  SESSIONS\033[0m\033[K\n\033[K\n'
  while IFS=$'\037' read -r name state repo branch agent; do
    [ -z "$name" ] && continue
    case "$state" in
      working)    g=$'\033[38;5;214m●\033[0m' ;;
      ready|done) g=$'\033[38;5;42m✓\033[0m'  ;;
      *)          g=$'\033[38;5;240m·\033[0m' ;;
    esac
    if [ "$name" = "$me" ]; then nm=$'\033[1;38;5;81m'"$name"$'\033[0m'
    else                         nm=$'\033[38;5;250m'"$name"$'\033[0m'; fi

    # sous-ligne : agent (ou repo) · branche, tronquée
    left="${agent:-$repo}"
    sub="$left"; [ -n "$branch" ] && { [ -n "$left" ] && sub="$left·$branch" || sub="$branch"; }
    sub=$(printf '%s' "$sub" | cut -c1-"$max")

    out+=" $g $nm"$'\033[K\n'
    [ -n "$sub" ] && out+=$'\033[38;5;243m    '"$sub"$'\033[0m\033[K\n'
    out+=$'\033[K\n'   # respiration entre sessions
  done < <("$SCRIPTS/sessions.sh" tsv)

  printf '\033[H%s\033[J' "$out"
  sleep 1.5 & swpid=$!      # sleep interruptible par SIGUSR1
  wait "$swpid" 2>/dev/null
  kill "$swpid" 2>/dev/null
done
