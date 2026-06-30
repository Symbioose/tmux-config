#!/usr/bin/env bash
# Démon de statut : calcule UNE fois pour toutes les sessions leur état et leurs
# métadonnées, et les stocke en user-options (@sb_*). La colonne et le switcher
# ne font que LIRE ces options -> pas de calcul ni de course côté rendu.
#
# État par session, déduit du process au premier plan + activité de l'écran :
#   working  l'agent produit de l'output (ça bosse)        -> ●
#   ready    un agent tourne mais l'écran est figé (fini)  -> ✓   « c'est fini »
#   idle     prompt shell, rien ne tourne                   -> ·
# Singleton (pidfile) : un seul démon, relances ignorées.

srv=$(tmux display-message -p '#{pid}' 2>/dev/null)   # un démon par SERVEUR tmux
PIDF="/tmp/tmux-statusd-$(id -u)-${srv:-x}.pid"
if [ -f "$PIDF" ] && kill -0 "$(cat "$PIDF" 2>/dev/null)" 2>/dev/null; then exit 0; fi
echo $$ >"$PIDF"
trap 'rm -f "$PIDF"' EXIT INT TERM

IDLE_TICKS=2   # nb de cycles figés avant de passer « ready »

label_of() { # cmdline complète -> nom d'agent lisible
  cmd="$1"
  for k in claude devin aider codex goose cline cursor opencode continue gemini chatgpt copilot ollama llm sgpt mods gptme interpreter; do
    if printf '%s' "$cmd" | grep -qiwE "$k"; then printf '%s' "$k"; return; fi
  done
  base=${cmd%% *}; printf '%s' "${base##*/}"   # sinon basename du binaire
}

while :; do
  tmux list-sessions >/dev/null 2>&1 || exit 0   # serveur parti -> on s'arrête

  while IFS= read -r s; do
    [ -z "$s" ] && continue
    IFS='|' read -r pane tty cpath sbhash sbidle \
      < <(tmux display-message -p -t "$s" '#{pane_id}|#{pane_tty}|#{pane_current_path}|#{@sbhash}|#{@sbidle}')
    tty=${tty#/dev/}

    # process au premier plan (état '+' sur le tty), shells exclus
    agentcmd=$(ps -t "$tty" -o stat=,args= 2>/dev/null \
      | awk '$1 ~ /\+/{sub(/^[^ ]+ +/,""); print}' \
      | grep -vE '^-?(zsh|bash|fish|sh)( |$)' | head -1)

    if [ -n "$agentcmd" ]; then
      agent=$(label_of "$agentcmd")
      h=$(tmux capture-pane -p -t "$pane" 2>/dev/null | cksum | cut -d' ' -f1)
      if [ "$h" = "$sbhash" ]; then c=$(( ${sbidle:-0} + 1 )); else c=0; fi
      [ "$c" -ge "$IDLE_TICKS" ] && state=ready || state=working
      newhash="$h"; newidle="$c"
    else
      agent=""; state=idle; newhash=""; newidle=0
    fi

    # repo + branche en un seul appel git
    gi=$(git -C "$cpath" rev-parse --show-toplevel --abbrev-ref HEAD 2>/dev/null)
    top=$(printf '%s\n' "$gi" | sed -n 1p)
    branch=$(printf '%s\n' "$gi" | sed -n 2p)
    if [ -n "$top" ]; then repo=$(basename "$top"); else repo=$(basename "$cpath"); branch=""; fi
    [ "$branch" = "HEAD" ] && branch=""

    tmux set-option -t "$s" @sb_state  "$state"  ';' \
         set-option -t "$s" @sb_agent  "$agent"  ';' \
         set-option -t "$s" @sb_repo   "$repo"   ';' \
         set-option -t "$s" @sb_branch "$branch" ';' \
         set-option -t "$s" @sbhash    "$newhash" ';' \
         set-option -t "$s" @sbidle    "$newidle" 2>/dev/null
  done < <(tmux list-sessions -F '#{session_name}' 2>/dev/null)

  sleep 1.5
done
