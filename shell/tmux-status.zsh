# Statut précis des sessions IA (optionnel).
# Active running/idle exact (au lieu de l'heuristique auto) pour les sessions
# créées via « prefix + n » (celles qui portent @launched=1).
#
# Activation : ajoute à la fin de ~/.zshrc
#   source ~/.config/tmux/shell/tmux-status.zsh
#
[[ -n "$TMUX" ]] || return
autoload -Uz add-zsh-hook 2>/dev/null || return

_tmux_is_ai() { [[ "$(tmux show-options -qv @launched 2>/dev/null)" == 1 ]]; }
_tmux_status_running() { _tmux_is_ai && tmux set-option @status running 2>/dev/null; }
_tmux_status_idle()    { _tmux_is_ai && tmux set-option @status idle    2>/dev/null; }

add-zsh-hook preexec _tmux_status_running   # une commande démarre  -> busy
add-zsh-hook precmd  _tmux_status_idle      # retour au prompt      -> idle
