#!/usr/bin/env bash
# Lance status-daemon.sh DÉTACHÉ (nohup) pour qu'il survive indépendamment du
# job-control de tmux. Idempotent (singleton via pidfile). Hérite de $TMUX donc
# vise le bon serveur ; le démon s'arrête seul quand ce serveur disparaît.
PIDF="/tmp/tmux-statusd-$(id -u).pid"
if [ -f "$PIDF" ] && kill -0 "$(cat "$PIDF" 2>/dev/null)" 2>/dev/null; then exit 0; fi
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
nohup "$SCRIPTS/status-daemon.sh" </dev/null >/dev/null 2>&1 &
disown 2>/dev/null || true
exit 0
