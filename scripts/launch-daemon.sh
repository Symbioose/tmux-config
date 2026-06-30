#!/usr/bin/env bash
# Lance status-daemon.sh DÉTACHÉ (nohup) pour qu'il survive indépendamment du
# job-control de tmux. Idempotent (singleton via pidfile). Hérite de $TMUX donc
# vise le bon serveur ; le démon s'arrête seul quand ce serveur disparaît.
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
srv=$(tmux display-message -p '#{pid}' 2>/dev/null)   # pidfile par SERVEUR tmux
PIDF="/tmp/tmux-statusd-$(id -u)-${srv:-x}.pid"
if [ -f "$PIDF" ] && kill -0 "$(cat "$PIDF" 2>/dev/null)" 2>/dev/null; then exit 0; fi
nohup "$SCRIPTS/status-daemon.sh" </dev/null >/dev/null 2>&1 &
disown 2>/dev/null || true
exit 0
