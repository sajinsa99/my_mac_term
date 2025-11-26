" Version compatible avec Vim 9 et simplifié
" Désactive la compatibilité avec Vi
set nocompatible

" Configuration de l'encodage
set encoding=utf-8

" Configuration des couleurs
set termguicolors " Active les vraies couleurs si supportées
set background=dark
colorscheme wildcharm

" Gestion des polices
if has("gui_running")
    set guifont=Monaco:h13
endif

" Résout un problème de terminaison de ligne dans certains fichiers
set display+=lastline

" Remet le curseur à la dernière position à l'ouverture d'un fichier
augroup RestoreCursor
    autocmd!
    autocmd BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | execute "normal! g`\"" | endif
augroup END

" Ne pas découper les lignes automatiquement
set nowrap

" Notifications visuelles au lieu des bips
set visualbell
set noerrorbells

" Gestion de la complétion intelligente
set wildmenu
set wildmode=longest:full,list:full
set omnifunc=syntaxcomplete#Complete

" Activer la numérotation des lignes
set number

" Sauvegarder automatiquement avant de quitter un buffer
set autowrite

" Recharger un fichier modifié à l'extérieur
set autoread

" Empêcher la création de fichiers d'échange
set noswapfile
set nobackup

" Tabs et indentations
set tabstop=4
set shiftwidth=4
set expandtab " Convertit les tabulations en espaces
set autoindent
set smartindent

" Recherche interactive et surlignage
set incsearch
set hlsearch
highlight Search ctermbg=yellow ctermfg=red

" Activer la correspondance des parenthèses
set showmatch

" Historique et annulations
set history=1000
set undolevels=1000

" Ignorer certains fichiers
set wildignore+=*.o,*.obj,*.exe,*.dll,*.jpg,*.png,*.gif,*.zip,*.tar.gz

" Optimisations pour les macros
set lazyredraw

" Barre de statut simplifiée
set laststatus=2
set statusline=%f\ [%Y]\ [%{&fileencoding}]

" Activer la souris
set mouse=a

" Configuration des replis
set foldmethod=indent
set nofoldenable

" Mappages utiles
let mapleader="," " Définit la virgule comme leader
nnoremap <leader>pp :setlocal paste!<CR>
nnoremap Y y$
cnoreabbrev w!! w !sudo tee % >/dev/null

" Plugins essentiels
syntax enable
filetype plugin indent on

" ---------------------------
" Plugins ajoutés (ordre recommandé)
" ---------------------------

" Utilise un gestionnaire de plugins (exemple vim-plug). Installation séparée.
" Si tu utilises un autre gestionnaire, adapte les lignes ci-dessous.
call plug#begin('~/.vim/plugged')

" vim-surround — gère rapidement 'surroundings' : ajouter/supprimer/modifier paires (quotes, (), {}, <>).
" Commandes principales : ys{motion}{char} (yank surround), cs{old}{new} (change surround), ds{char} (delete surround)
" Exemples : ysiw)  -> entoure mot courant de (), cs"' -> change " en '
Plug 'tpope/vim-surround'

" vim-commentary — commenter/décommenter rapidement une ligne ou une sélection.
" Raccourcis : gcc -> commenter/décommenter la ligne courante (normal mode)
"             gc{motion} -> commenter le mouvement (ex: gcw)
"             gc (en visual) -> commenter la sélection
Plug 'tpope/vim-commentary'

" vim-airline — barre d'état moderne et légère avec info fichier, encodage, branche git si disponible.
" Raccourcis : (pas de mappings par défaut essentiels) -> configuration via airline settings si besoin.
" Exemples de commandes utiles : :AirlineToggle pour afficher/masquer (selon installation)
Plug 'vim-airline/vim-airline'

" coc.nvim — client LSP complet (autocompletion, diagnostics, go-to, code-actions).
" Rappels principaux (mappings fournis ci-dessous) :
"   gd  -> go to definition
"   gr  -> find references
"   gi  -> go to implementation
"   K   -> show documentation (hover)
"   [g  / ]g -> diagnostic prev / next
"   <leader>rn -> rename symbol
"   <leader>ca -> code action
" Note : coc nécessite Node.js ; branch 'release' recommandée.
Plug 'neoclide/coc.nvim', {'branch': 'release'}

call plug#end()

" ---------------------------
" Mappings recommandés pour coc.nvim (désactivés si tu veux config manuelle)
" ---------------------------
" Normal mode mappings for coc.nvim features
" go-to / navigation
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Hover documentation
nnoremap <silent> K :call CocActionAsync('doHover')<CR>

" Diagnostics navigation
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" Code actions & rename
nmap <leader>ca <Plug>(coc-codeaction)
nmap <leader>rn <Plug>(coc-rename)

" Use <CR> to confirm completion in insert mode (optionnel — active si tu veux ce comportement)
" inoremap <silent><expr> <CR> pumvisible() ? coc#_select_confirm() : "\<CR>"

" ---------------------------
" Fin plugins ajoutés
" ---------------------------

" Afficher les espaces et tabulations
set list
set listchars=tab:»─,trail:·,eol:¬,space:·,extends:>,precedes:<

" Barre de statut avec des informations détaillées
set statusline=%f\ [%Y]\ [%{&fileencoding}]\ %l/%L\ [%p%%]

" Certaines options inutiles ou redondantes ont été désactivées pour simplification
" Exemple :
" set t_Co=256 " Redondant avec termguicolors
" let base16colorspace=256 " Spécifique à certains schémas, souvent inutile

" Explications des suppressions de directives "set":
" 1. set backspace=eol,indent,start
"    -> Supprimé car cette option est activée par défaut dans les versions récentes de Vim.
" 2. set complete+=kspell
"    -> Supprimé car l'inclusion des suggestions orthographiques est spécifique aux besoins d'édition de texte,
"       et peut ralentir la complétion dans de gros fichiers.
" 3. set completeopt=menuone,longest
"    -> Supprimé pour simplifier, mais peut être réintégré si vous souhaitez une gestion fine de la complétion.
" 4. set confirm
"    -> Supprimé car la confirmation explicite peut être redondante avec les habitudes d'enregistrement et d'utilisation.
" 5. set copyindent
"    -> Supprimé car redondant avec des options comme autoindent et smartindent, qui gèrent déjà l'indentation.
" 6. set cursorline
"    -> Supprimé pour alléger l'interface visuelle, mais utile si vous voulez une meilleure lisibilité du curseur.
