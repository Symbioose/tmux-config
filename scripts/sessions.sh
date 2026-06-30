#!/usr/bin/env bash
# Lecteur des métadonnées posées par status-daemon.sh.
#   sessions.sh tsv      -> name 0x1F state 0x1F repo 0x1F branch 0x1F agent
#   sessions.sh pretty   -> name <TAB> "<glyphe> nom   repo/branch   agent"  (fzf)
# state ∈ working | ready | idle | done   (done = marqué à la main via @status)
mode="${1:-tsv}"

glyph_of() {
  case "$1" in
    working) printf '\033[38;5;214m●\033[0m' ;;   # orange : ça bosse
    ready|done) printf '\033[38;5;42m✓\033[0m' ;;  # vert   : fini / prêt
    *)       printf '\033[38;5;240m·\033[0m' ;;    # gris   : inactif
  esac
}

tmux list-sessions -F '#{session_name}' 2>/dev/null | while IFS= read -r s; do
  IFS='|' read -r state agent repo branch manual \
    < <(tmux display-message -p -t "$s" '#{@sb_state}|#{@sb_agent}|#{@sb_repo}|#{@sb_branch}|#{@status}')
  [ -n "$manual" ] && state="$manual"      # override manuel (prefix+m)
  state=${state:-idle}
  loc="$repo"; [ -n "$branch" ] && loc="$repo/$branch"

  case "$mode" in
    pretty)
      g=$(glyph_of "$state")
      printf '%s\t%b %-12s \033[38;5;245m%-22s\033[0m \033[38;5;73m%s\033[0m\n' \
        "$s" "$g" "$s" "$loc" "$agent" ;;
    *)
      printf '%s\037%s\037%s\037%s\037%s\n' "$s" "$state" "$repo" "$branch" "$agent" ;;
  esac
done
