# tmux — sidebar de sessions IA, transparent & minimaliste

Une config tmux pour piloter plein de sessions d'agents IA (Claude, Devin,
aider, n'importe quoi) : une **colonne fine à gauche** qui montre en permanence
chaque session, son **statut** (en cours / fini / inactif) et **l'agent** qui
tourne, plus un **switcher fuzzy** pour changer de session en deux touches. Le
tout transparent pour épouser Ghostty.

```
┌────────┬───────────────────────────┐
│ SESSIONS                            │
│        │                           │
│ ● api  │   (zone de travail)       │
│  claude│                           │
│        │                           │
│ ✓ web  │                           │
│  devin │                           │
│        │                           │
│ · cli  │                           │
└────────┴───────────────────────────┘
  ●=bosse  ✓=fini  ·=inactif
```

## Installation

```sh
~/Developer/tools/tmux/install.sh   # backup ~/.tmux.conf, symlink ~/.config/tmux, TPM + plugins
tmux
```

Statut *précis* (optionnel) — ajoute à `~/.zshrc` :
`source ~/.config/tmux/shell/tmux-status.zsh`

## Raccourcis — prefix = `Ctrl-a`

On appuie sur `Ctrl-a`, on relâche, puis la touche. La souris est active.

### Sessions
| Touche | Action |
|---|---|
| `a` | **switcher fuzzy** (changer / `^x` kill / `^d` fini / `^n` nouveau) |
| `n` | **nouveau terminal** (session nommée d'après le dossier, sans question) |
| `j` / `k` | session suivante / précédente |
| `Tab` | dernière session |
| `g` | aller à une session par son nom |
| `X` | ❌ **fermer la session courante** (confirmation) |
| `m` / `M` | marquer **terminée** ✓ / repasser en auto |

### Fenêtres / panes
| Touche | Action |
|---|---|
| `c` · `1`…`9` · `w` | nouvelle fenêtre · aller à n° · lister |
| `&` | fermer la fenêtre |
| `\|` / `-` | split vertical / horizontal |
| `←↑↓→` ou `h`/`l` | naviguer · `H J K L` redimensionner |
| `z` · `x` | zoom pane · fermer pane |

### Système
| Touche | Action |
|---|---|
| `b` | afficher / masquer la colonne |
| `d` | détacher (sessions continuent en fond ; revenir : `tmux a`) |
| `r` | recharger la config |
| `C-s` / `C-r` | sauvegarder / restaurer l'environnement (resurrect) |

## Statuts

| | sens | détection |
|---|---|---|
| `●` orange | l'agent **bosse** | l'écran du pane change |
| `✓` vert | **fini / t'attend** | un agent tourne, écran figé ~3 s — ou marqué `prefix+m` |
| `·` gris | shell **inactif** | prompt, aucun programme |

Repo, branche et agent sont **auto-dérivés** — rien à saisir.

## Architecture

| Fichier | Rôle |
|---|---|
| `tmux.conf` | thème transparent, hooks, raccourcis, plugins (TPM) |
| `scripts/status-daemon.sh` | **démon** unique : calcule statut + agent + repo/branche, stocke en `@sb_*` |
| `scripts/launch-daemon.sh` | lance le démon détaché (nohup, singleton) |
| `scripts/sessions.sh` | lit les `@sb_*` → sortie `tsv` / `pretty` |
| `scripts/sidebar.sh` | rend la colonne (polling 1 s, robuste) |
| `scripts/switcher.sh` | popup fzf |
| `scripts/new-session.sh` | ouvre un nouveau terminal (session nommée d'après le dossier) |
| `scripts/ensure-sidebar.sh` | (ré)installe la colonne via hooks, largeur ~1/7 |
| `scripts/toggle-sidebar.sh` | on/off de la colonne |
| `shell/tmux-status.zsh` | hook zsh optionnel (statut exact) |

**Comment ça tient :** un démon détaché calcule l'état de toutes les sessions et
l'écrit en options tmux ; les colonnes (une par fenêtre, injectées par hooks) ne
font que *lire* et se rendre → pas de course, pas de calcul redondant.

## Limites connues

- La **colonne** est injectée par fenêtre via des hooks (tmux n'a pas de pane
  global). Robuste à l'usage ; `prefix+b` la réinitialise au besoin, et
  `prefix+a` reste la voie de switch infaillible.
- **Auto-restore désactivé** (`@continuum-restore off`) : resurrect ressuscitait
  les colonnes en doublons. Restauration manuelle via `prefix+C-r`.
- Pas de plugin de thème (fond opaque → tuerait la transparence). Thème fait main.
