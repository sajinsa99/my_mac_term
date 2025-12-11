#!/usr/bin/env bash
# update_vim_plugins.sh
# Met à jour les plugins gérés par vim-plug et les extensions coc.nvim (pour Vim, pas Neovim).
# Ajout : option --dry-run pour afficher ce qui serait fait sans exécuter.
# Usage :
#   ./update_vim_plugins.sh            # exécution réelle
#   ./update_vim_plugins.sh --dry-run  # simulation (aucune commande destructive exécutée)
set -euo pipefail

# -----------------------
# Fonctions utilitaires
# -----------------------
info()    { printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
warn()    { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
success() { printf '\033[1;32m[OK]\033[0m %s\n' "$*"; }
err()     { printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2; exit 1; }

# Exécute ou affiche la commande selon dry_run
run_cmd() {
  if [ "${DRY_RUN:-false}" = true ]; then
    printf '\033[1;36m[DRY-RUN]\033[0m %s\n' "$*"
  else
    eval "$@"
  fi
}

# -----------------------
# Parse args
# -----------------------
DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) DRY_RUN=true ;;
    --help|-h) printf 'Usage: %s [--dry-run]\n' "$0"; exit 0 ;;
    *) err "Argument inconnu: $arg" ;;
  esac
done

# -----------------------
# Pré-conditions
# -----------------------
cmd_exists() { command -v "$1" >/dev/null 2>&1; }

cmd_exists vim || err "vim introuvable dans PATH. Installe vim avant d'exécuter ce script."
if ! cmd_exists git; then
  warn "git introuvable — les mises à jour via git ne fonctionneront pas."
fi
if ! cmd_exists node; then
  warn "node introuvable — coc.nvim peut nécessiter node pour mettre à jour ses extensions."
fi

PLUG_VIM="${HOME}/.vim/autoload/plug.vim"
PLUGGED_DIR="${HOME}/.vim/plugged"
VIMRC="${HOME}/.vimrc"

# -----------------------
# Information initiale
# -----------------------
if [ "${DRY_RUN}" = true ]; then
  info "Mode DRY-RUN activé. Aucune commande ne sera exécutée."
else
  info "Mode réel. Les commandes seront exécutées."
fi

info "Vérifications initiales :"
info " - vim: $(command -v vim || printf 'absent')"
info " - git: $(command -v git || printf 'absent')"
info " - node: $(command -v node || printf 'absent')"
info " - vim-plug: ${PLUG_VIM}"
info " - plugins dir: ${PLUGGED_DIR}"
info " - vimrc: ${VIMRC}"
printf '\n'

# -----------------------
# 1) Mise à jour via vim-plug
# -----------------------
if [ -f "${PLUG_VIM}" ]; then
  info "Lancement PlugUpgrade -> PlugUpdate -> PlugClean via vim."
  # utiliser run_cmd pour afficher ou exécuter
  run_cmd "vim +PlugUpgrade +PlugUpdate +PlugClean +qall"
  if [ "${DRY_RUN}" = false ]; then
    success "vim-plug : PlugUpgrade/PlugUpdate/PlugClean exécutés."
  else
    success "vim-plug : commandes affichées (dry-run)."
  fi
else
  warn "vim-plug introuvable (${PLUG_VIM}). Ignorer étape PlugUpdate."
fi

# -----------------------
# 2) Mise à jour git directe dans ~/.vim/plugged (fast-forward only)
# -----------------------
if [ -d "${PLUGGED_DIR}" ] && cmd_exists git; then
  info "Parcours des plugins dans ${PLUGGED_DIR} pour tentative de git fetch + ff merge."
  # find | while loop
  find "${PLUGGED_DIR}" -mindepth 1 -maxdepth 1 -type d -print0 |
  while IFS= read -r -d '' dir; do
    # skip if not a git repo
    if [ -d "${dir}/.git" ]; then
      repo_name="$(basename "$dir")"
      info "Traitement: ${repo_name}"
      if [ "${DRY_RUN}" = true ]; then
        printf '[DRY-RUN] git -C %s fetch --all --prune\n' "$dir"
        printf '[DRY-RUN] git -C %s merge --ff-only @{u}  (si upstream configuré)\n' "$dir"
        continue
      fi

      # réel : fetch
      if git -C "$dir" fetch --all --prune >/dev/null 2>&1; then
        # tenter fast-forward merge depuis upstream si configuré
        if git -C "$dir" rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
          if git -C "$dir" merge --ff-only '@{u}' >/dev/null 2>&1; then
            success "git (ff) OK : ${repo_name}"
          else
            warn "git merge --ff-only a échoué (modifs locales ou divergence) pour ${repo_name}"
          fi
        else
          warn "Aucun upstream configuré pour ${repo_name} — saut du merge."
        fi
      else
        warn "Échec du git fetch pour ${repo_name}."
      fi
    else
      info "Saut (pas un repo git) : $(basename "$dir")"
    fi
  done
else
  warn "Répertoire ${PLUGGED_DIR} absent ou git manquant — saut mise à jour git directe."
fi

# -----------------------
# 3) Mise à jour des extensions coc.nvim
# -----------------------
COC_PRESENT=false
if [ -d "${PLUGGED_DIR}/coc.nvim" ] || ( [ -f "${VIMRC}" ] && grep -q "coc.nvim" "${VIMRC}" ); then
  COC_PRESENT=true
fi

if [ "${COC_PRESENT}" = true ]; then
  info "coc.nvim détecté : tentative de mise à jour des extensions via :CocUpdate -sync"
  if [ "${DRY_RUN}" = true ]; then
    printf '[DRY-RUN] vim -u %s -c "CocUpdate -sync" -c "qall"\n' "${VIMRC}"
  else
    if vim -u "${VIMRC}" -c 'CocUpdate -sync' -c 'qall' >/dev/null 2>&1; then
      success "coc.nvim : extensions mises à jour."
    else
      warn "CocUpdate a retourné une erreur. Ouvre vim et exécute :CocUpdate pour plus d'infos."
    fi
  fi
else
  warn "coc.nvim non détecté dans ${PLUGGED_DIR} ou absent du ${VIMRC} — saut mise à jour coc."
fi

# -----------------------
# 4) Vérifications / nettoyage node_modules (optionnel, non exécuté en dry-run)
# -----------------------
if [ -d "${PLUGGED_DIR}/coc.nvim" ]; then
  if [ "${DRY_RUN}" = true ]; then
    printf '[DRY-RUN] du -sh %s/coc.nvim/node_modules  (si existe)\n' "${PLUGGED_DIR}"
  else
    if [ -d "${PLUGGED_DIR}/coc.nvim/node_modules" ]; then
      info "Taille node_modules de coc.nvim :"
      du -sh "${PLUGGED_DIR}/coc.nvim/node_modules" 2>/dev/null || true
      info "Si nécessaire, pour réinstaller proprement : (cd ${PLUGGED_DIR}/coc.nvim && rm -rf node_modules && npm install --production)"
    fi
  fi
fi

success "Opération terminée."
exit 0
