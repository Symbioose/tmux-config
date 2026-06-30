#!/usr/bin/env bash
# Réconcilie la colonne sidebar : chaque fenêtre doit avoir EXACTEMENT un pane
# sidebar épinglé à gauche. Idempotent + auto-réparateur. Appelé par les hooks.
#   $1 (optionnel) : window_id à traiter seul. Sinon : toutes les fenêtres.
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
MIN_W=34   # largeur mini d'une fenêtre pour héberger la colonne

# Largeur de la colonne : ~1/7 de la fenêtre, bornée 14..18 (fine, constante).
sidebar_width() {
  ww="$1"; w=$(( ww / 7 ))
  [ "$w" -lt 14 ] && w=14
  [ "$w" -gt 18 ] && w=18
  printf '%s' "$w"
}

[ "$(tmux show-options -gqv @sidebar_enabled)" = "0" ] && exit 0

# Mutex atomique (mkdir) : notre propre split déclenche after-split-window, qui
# rappelle ce script. Sans verrou ATOMIQUE, deux invocations concurrentes créent
# des colonnes en double. mkdir échoue atomiquement si le verrou existe déjà.
LOCK="/tmp/tmux-sidebar-$(id -u).lock"
if ! mkdir "$LOCK" 2>/dev/null; then
  age=$(( $(date +%s) - $(stat -f %m "$LOCK" 2>/dev/null || echo 0) ))
  if [ "$age" -gt 10 ]; then rmdir "$LOCK" 2>/dev/null; mkdir "$LOCK" 2>/dev/null || exit 0
  else exit 0; fi
fi
trap 'rmdir "$LOCK" 2>/dev/null' EXIT INT TERM

reconcile_window() {
  win="$1"
  ww=$(tmux display-message -p -t "$win" '#{window_width}')
  width=$(sidebar_width "${ww:-100}")
  sbs=$(tmux list-panes -t "$win" -F '#{pane_id} #{@is_sidebar}' 2>/dev/null | awk '$2==1{print $1}')
  first=""; n=0
  for p in $sbs; do n=$((n + 1)); [ -z "$first" ] && first="$p"; done

  if [ "$n" -eq 0 ]; then
    [ "${ww:-0}" -lt "$MIN_W" ] && return
    first=$(tmux split-window -t "$win" -hbd -l "$width" -P -F '#{pane_id}' \
              "exec $SCRIPTS/sidebar.sh" 2>/dev/null) || return
    tmux set-option -p -t "$first" @is_sidebar 1
  elif [ "$n" -gt 1 ]; then
    # auto-réparation : ne garder que le premier
    for p in $sbs; do [ "$p" = "$first" ] || tmux kill-pane -t "$p" 2>/dev/null; done
  fi
  [ -n "$first" ] && tmux resize-pane -t "$first" -x "$width" 2>/dev/null
}

if [ -n "$1" ] && tmux list-panes -t "$1" >/dev/null 2>&1; then
  reconcile_window "$1"
else
  while IFS= read -r w; do reconcile_window "$w"; done \
    < <(tmux list-windows -a -F '#{window_id}')
fi

# garde le démon de statut vivant (idempotent)
"$SCRIPTS/launch-daemon.sh" >/dev/null 2>&1 &
