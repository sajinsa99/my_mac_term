#!/usr/bin/env bash
set -euo pipefail

info(){ printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
err(){ printf '\033[1;31m[ERROR]\033[0m %s\n' "$*"; exit 1; }

cmd_exists(){ command -v "$1" >/dev/null 2>&1; }

# --- Check brew
if ! cmd_exists brew; then
  err "Homebrew introuvable. Installe-le et relance."
fi

# --- Ensure vim + node + curl/wget
ensure_pkg() {
  local bin="$1"
  local pkg="$2"

  if cmd_exists "$bin"; then
    info "$bin déjà installé."
  else
    info "$bin manquant → installation via brew ($pkg)..."
    brew install "$pkg" || err "Échec installation $pkg"
  fi
}

ensure_pkg vim vim
ensure_pkg node node
# curl est souvent déjà présent sur macOS, mais on check proprement
if ! cmd_exists curl && ! cmd_exists wget; then
  info "curl et wget absents → installation de curl."
  brew install curl || err "Échec installation curl"
else
  info "curl ou wget dispo."
fi

# --- Install vim-plug
PLUG_PATH="${HOME}/.vim/autoload/plug.vim"
if [ -f "$PLUG_PATH" ]; then
  info "vim-plug déjà installé."
else
  info "Installation de vim-plug..."
  if cmd_exists curl; then
    curl -fLo "$PLUG_PATH" --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  else
    wget -O "$PLUG_PATH" --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  fi
  info "vim-plug installé."
fi

# --- Check .vimrc exists
VIMRC="${HOME}/.vimrc"
if [ ! -f "$VIMRC" ]; then
  warn "~/.vimrc manquant. Le script suppose qu'il contient tes Plug '...'"
fi

# --- Install vim plugins
info "Exécution de PlugInstall..."
vim +PlugInstall +qall || warn "PlugInstall a retourné un code non nul."

# --- Install coc extensions
COC_EXTS=(coc-ansible coc-css coc-docker coc-eslint coc-highlight coc-html coc-java coc-json coc-just-complete coc-markdownlint coc-markdown-preview-enhanced coc-perl coc-phpactor coc-prettier coc-pylsp coc-pyright coc-sh coc-tsserver coc-xml coc-yaml)
info "Installation extensions coc : ${COC_EXTS[*]}"
vim -c "CocInstall -sync ${COC_EXTS[*]}" -c q \
  || warn "CocInstall en erreur. Réessaye en manuel."

# --- Post notes
info "Terminé. Ouvrir vim pour laisser coc.nvim finaliser les installations si nécessaire."
info "Remarques utiles :"
printf "  - Certaines extensions coc invoquent des language servers ou outils externes (ex: ruff, eslint, shellcheck). Installe-les si tu veux lint/format local.\n"
printf "  - Pour installer manuellement des extensions plus tard : ouvrez vim et exécutez :CocInstall <extension>\n"
 
 
exit 0

