" ================================================================================================
" ================================================================================================
" How to use:
" 1. copy this file to ~/.vimrc
" 2. install plug.vim (install plug.vim to ~/.vim/autoload dir)
"    $curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
" 3. install plugins in vim
"    :PlugInstall
" Others:
" more plugin command see https://github.com/junegunn/vim-plug
" ================================================================================================
" ================================================================================================

call plug#begin()
Plug 'scrooloose/nerdtree'
Plug 'easymotion/vim-easymotion'
Plug 'vim-scripts/ReplaceWithRegister'
Plug 'tpope/vim-surround'
Plug 'terryma/vim-multiple-cursors'
call plug#end()

set clipboard=unnamedplus
set ignorecase
set scrolloff=30
set history=200
set number
set incsearch
set hlsearch
inoremap  <nowait> jk  <Esc>`^
let mapleader=','

" set the split operation"
nnoremap <Leader>\ <C-W>v
nnoremap <Leader>- <C-W>s
nnoremap <C-h> <C-W>h
nnoremap <C-l> <C-W>l
nnoremap <C-j> <C-W>j
nnoremap <C-k> <C-W>k
nnoremap <C-,> <C-W><
nnoremap <C-.> <C-W>>
nnoremap <C-=> <C-W>+
nnoremap <C--> <C-W>-

nnoremap <Leader>w :w<cr>
nnoremap <Leader>h :noh<cr>
nnoremap <Leader>uw :wrap!<cr>
nnoremap <Leader>q :bd<cr>
nnoremap <Leader>c :c<cr>


" ================================================================================================
" ================================================================================================
" plugin set"
" ================================================================================================
" ================================================================================================
" easymotion
map <leader>s <Plug>(easymotion-s2)

" NERDTree
nnoremap <leader>e :NERDTreeToggle<cr>
nnoremap <leader>o :NERDTreeFind<cr>

" multiple-cursors
" https://stackoverflow.com/questions/55202799/ideavim-multi-cursor-usage
" Remap multiple-cursors shortcuts to match terryma/vim-multiple-cursors
nmap <C-n> <Plug>NextWholeOccurrence
xmap <C-n> <Plug>NextWholeOccurrence
nmap g<C-n> <Plug>NextOccurrence
xmap g<C-n> <Plug>NextOccurrence
nmap <C-x> <Plug>SkipOccurrence
xmap <C-x> <Plug>SkipOccurrence
nmap <C-p> <Plug>RemoveOccurrence
xmap <C-p> <Plug>RemoveOccurrence
" Note that the default <A-n> and g<A-n> shortcuts don't work on Mac due to dead keys.
" <A-n> is used to enter accented text e.g. ñ
nmap <S-C-n> <Plug>AllWholeOccurrences
xmap <S-C-n> <Plug>AllWholeOccurrences
nmap g<S-C-n> <Plug>AllOccurrences
xmap g<S-C-n> <Plug>AllOccurrences
