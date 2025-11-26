#!/usr/bin/env bash
set -euo pipefail

# install_vim_and_coc_exts.sh
# Installe vim-plug (si manquant), lance PlugInstall, puis installe des extensions coc.nvim.
# Prérequis : vim présent et Node.js (tu as Node 25.x via brew — OK).

# --- Helpers
info(){ printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
err(){ printf '\033[1;31m[ERROR]\033[0m %s\n' "$*"; exit 1; }

cmd_exists(){ command -v "$1" >/dev/null 2>&1; }

# --- Preconditions
cmd_exists vim || err "vim introuvable. Installe vim et réessaie."
cmd_exists node || err "node introuvable. Coc.nvim nécessite Node.js."

# --- Ensure curl or wget
cmd_exists curl || cmd_exists wget || err "curl ou wget requis."

# --- Install vim-plug if missing
PLUG_PATH="${HOME}/.vim/autoload/plug.vim"
if [ -f "$PLUG_PATH" ]; then
  info "vim-plug déjà installé."
else
  info "Installation de vim-plug..."
  if cmd_exists curl; then
    curl -fLo "$PLUG_PATH" --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
      || err "Échec du téléchargement via curl."
  else
    wget -O "$PLUG_PATH" --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
      || err "Échec du téléchargement via wget."
  fi
  info "vim-plug installé."
fi

# --- Verify ~/.vimrc contains Plug entries for the plugins (best-effort check)
VIMRC="${HOME}/.vimrc"
if [ ! -f "$VIMRC" ]; then
  warn "~/.vimrc introuvable — crée le avant d'exécuter ce script (doit contenir Plug '...' pour les plugins)."
fi

# --- Run PlugInstall (headless)
info "Exécution de PlugInstall (Vim va s'ouvrir en tâche de fond)..."
vim +PlugInstall +qall || warn "PlugInstall a retourné un code non nul."

# --- Install coc extensions (non interactif)
COC_EXTS=(coc-pyright coc-perl coc-eslint coc-json coc-tsserver coc-sh coc-yaml coc-snippets)
info "Installation des extensions coc.nvim : ${COC_EXTS[*]}"
# Use CocInstall -sync so the command blocks until finished
vim -c "CocInstall -sync ${COC_EXTS[*]}" -c 'q' || warn "CocInstall a retourné un code non nul. Vérifie la connexion réseau ou relance manuellement : :CocInstall ${COC_EXTS[*]}"

# --- Post notes
info "Terminé. Ouvrir vim pour laisser coc.nvim finaliser les installations si nécessaire."
info "Remarques utiles :"
printf "  - Certaines extensions coc invoquent des language servers ou outils externes (ex: ruff, eslint, shellcheck). Installe-les si tu veux lint/format local.\n"
printf "  - Pour installer manuellement des extensions plus tard : ouvrez vim et exécutez :CocInstall <extension>\n"

exit 0
