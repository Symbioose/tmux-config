#!/usr/bin/env bash
# Installe la config : sauvegarde l'existant, symlinke ~/.config/tmux, bootstrap TPM.
set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"
ts=$(date +%Y%m%d-%H%M%S)

echo "▶ Installation tmux depuis $ROOT"

# 1. ~/.tmux.conf : on le neutralise pour que tmux lise ~/.config/tmux/tmux.conf
if [ -L "$HOME/.tmux.conf" ]; then
  rm -f "$HOME/.tmux.conf"
elif [ -e "$HOME/.tmux.conf" ]; then
  mv "$HOME/.tmux.conf" "$HOME/.tmux.conf.bak-$ts"
  echo "  ↳ ~/.tmux.conf → ~/.tmux.conf.bak-$ts"
fi

# 2. symlink ~/.config/tmux -> repo
mkdir -p "$HOME/.config"
if [ -L "$HOME/.config/tmux" ]; then
  rm -f "$HOME/.config/tmux"
elif [ -e "$HOME/.config/tmux" ]; then
  mv "$HOME/.config/tmux" "$HOME/.config/tmux.bak-$ts"
  echo "  ↳ ~/.config/tmux existant → ~/.config/tmux.bak-$ts"
fi
ln -sfn "$ROOT" "$HOME/.config/tmux"
echo "  ↳ ~/.config/tmux → $ROOT"

# 3. bit exécutable
chmod +x "$ROOT"/scripts/*.sh "$ROOT/install.sh"

# 4. TPM (dans le chemin XDG, cohérent avec là où TPM installe les plugins)
TPM="$HOME/.config/tmux/plugins/tpm"
if [ ! -d "$TPM" ]; then
  git clone -q https://github.com/tmux-plugins/tpm "$TPM"
  echo "  ↳ TPM cloné"
fi

# 5. Installe les plugins. install_plugins lit la liste @plugin sur un serveur
#    qui a chargé la config -> on amorce un serveur temporaire le temps du clone.
started=""
if ! tmux info >/dev/null 2>&1; then
  tmux new-session -d -s _tpm_bootstrap >/dev/null 2>&1 && started=1
fi
tmux source-file "$HOME/.config/tmux/tmux.conf" >/dev/null 2>&1 || true
"$TPM/bin/install_plugins" >/dev/null 2>&1 || true
if [ -n "$started" ]; then tmux kill-server >/dev/null 2>&1 || true; fi
echo "  ↳ plugins : $(ls ~/.tmux/plugins 2>/dev/null | tr '\n' ' ')"

echo "✓ Terminé."
echo "  Démarre :  tmux"
echo "  Déjà ouvert :  tmux kill-server && tmux"
