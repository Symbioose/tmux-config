# Design — tmux : sidebar de sessions IA, transparent & minimaliste

Date : 2026-06-29 · Statut : approuvé

## Objectif

Configurer tmux pour piloter de nombreuses sessions d'agents IA (Claude, aider,
codex, n'importe lequel) avec un rendu **transparent et minimaliste** calqué sur
Ghostty (`background-opacity = 0.2`, blur). L'utilisateur veut voir en permanence,
pour chaque session : statut (dont « terminée »), repo, feature/branche, nom de la
conf, agent — et switcher très vite avec des raccourcis simples sans conflit avec
les `Cmd+…` de Ghostty.

## Décisions (validées)

1. **Affichage** : colonne permanente à gauche (~24 col) **+** popup fzf de switch
   rapide **+** status-line minimale. La colonne couvre « je vois tout », le popup
   couvre « je switch en 2 touches ».
2. **Statut** : auto par défaut + hook zsh optionnel pour un running/idle exact ;
   `prefix+m` marque « terminée » à la main.
3. **Dépendances** : TPM (sessionist, resurrect, continuum). Colonne, switcher et
   thème = scripts maison (fzf + jq déjà présents) pour garder la transparence.

## Architecture

- **`scripts/sessions.sh`** — source unique de vérité. Énumère les sessions et
  dérive automatiquement : nom (= nom de session), repo (git toplevel), branche
  (`git branch --show-current`), agent (`pane_current_command` ou `@agent`),
  statut. Deux sorties : `tsv` (machine) et `pretty` (colorisé pour fzf). Toute
  l'UI lit cette même source → cohérence garantie.
- **Modèle de statut** : `@status` (hook/manuel) prioritaire ; sinon `@launched=1`
  + shell ⇒ `done`, `@launched=1` + process ⇒ `running` ; sinon agent connu ⇒
  `running`, shell ⇒ `shell`, autre ⇒ `app`. Glyphes ● ○ ✓ · ◦.
- **Colonne permanente** — tmux n'a pas de pane « global » : un script
  `ensure-sidebar.sh` est appelé par les hooks `after-new-window`,
  `after-split-window`, `after-new-session`, `session-window-changed`,
  `client-attached`. Il injecte (si absent) un pane gauche `-hbd -l 24` exécutant
  `sidebar.sh`, le marque `@is_sidebar=1` et ré-épingle sa largeur (idempotent).
  `toggle-sidebar.sh` (`prefix+b`) bascule `@sidebar_enabled` et ajoute/retire la
  colonne dans toutes les fenêtres.
- **`sidebar.sh`** — boucle 1.5 s : lit `sessions.sh tsv`, rend deux lignes par
  session (glyphe+nom, puis repo/branche en gris), met en avant la session du pane
  courant. Repaint via `\033[H … \033[J` (pas de full clear → pas de flicker).
- **`switcher.sh`** (`prefix+a`) — `display-popup -E` + fzf sur `sessions.sh
  pretty`. enter = `switch-client` ; `^d` mark done ; `^x` kill ; `^n` nouvelle.
- **`new-ai-session.sh`** (`prefix+n`) — popup : nom + dossier (fzf des repos git
  de `~/Developer`) + commande agent ; crée la session détachée, pose `@agent` /
  `@launched`, lance l'agent, switch dessus.
- **Thème** — `bg=default` partout (transparence Ghostty traverse), bordures fines
  `colour237`/`colour109`, status-line gauche vide, droite = branche git + heure.
  Aucun plugin de thème (fond opaque ⇒ tuerait la transparence).
- **Persistance** — resurrect + continuum (save auto 15 min, restore au boot).

## Raccourcis

prefix `C-a`. `a` switcher · `n` nouvelle IA · `j/k` sessions · `Tab` dernière ·
`m/M` done/auto · `b` colonne · `c | -` fenêtre/splits · flèches+`h/l` panes ·
`H/J/K/L` resize · `r` reload. Aucun conflit avec les `Cmd+…` de Ghostty (jamais
transmis à tmux). `macos-option-as-alt` laissé désactivé (accents FR préservés).

## Installation / structure

Repo versionné `~/Developer/tools/tmux`, symlinké en `~/.config/tmux`.
`install.sh` : sauvegarde `~/.tmux.conf`, pose le symlink, clone TPM, installe les
plugins. TPM vit hors repo (`~/.tmux/plugins`).

## Risque assumé

La colonne permanente (injection par fenêtre via hooks) peut avoir des cas limites
sur des layouts exotiques ou redimensionnements. Mitigations : ré-épinglage
idempotent, `prefix+b` pour réinitialiser, et le switcher `prefix+a` comme voie de
switch rock-solid indépendante de la colonne.
