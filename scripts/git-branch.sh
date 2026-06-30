#!/usr/bin/env bash
# Branche git du dossier passé en argument, pour la status-line. Silencieux si hors repo.
p="$1"
[ -d "$p" ] || exit 0
b=$(git -C "$p" branch --show-current 2>/dev/null)
[ -n "$b" ] && printf ' %s' "$b"
