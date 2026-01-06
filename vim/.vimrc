set scrolloff=30
set history=200
set number
set relativenumber
set incsearch
set hlsearch
set ignorecase
set nowrap
inoremap  <nowait> jk  <Esc>`^
let mapleader=','

" set the split operation"
nnoremap <Leader>\ <C-W>v
nnoremap <Leader>- <C-W>s
nnoremap <Leader><BS> <C-W>v
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
nnoremap <Leader>uw :set wrap!<cr>
nnoremap <Leader>q :confirm q<cr>
nnoremap <Leader>c :c<cr>

" Minimal number of screen lines to keep above/below the cursor
set scrolloff=5
" Minimal number of screen columns to keep left/right of the cursor
set sidescrolloff=8


"============================================================================
" ==          Vim-Tmux Navigator Core Logic (without plugin)            ==
"============================================================================
" Only run this logic if inside a tmux session
if !empty($TMUX)
" Function to send commands to the correct tmux socket
function! TmuxNavigator_TmuxCommand(args)
  " The socket path is the first value in the comma-separated list of $TMUX.
  let tmux_socket = split($TMUX, ',')[0]
  let cmd = 'tmux -S ' . tmux_socket . ' ' . a:args
  " Use system() instead of silent ! to avoid screen flicker and messages
  call system(cmd)
endfunction!
" The main navigation function
function! TmuxNavigator_Navigate(direction)
  " Get current window number
  let current_win = winnr()
  " Try to navigate within Vim windows
  " The `wincmd` command will fail silently if it can't move
  execute 'wincmd ' . a:direction
  " If the window number is unchanged, we are at the edge of Vim.
  " Time to navigate tmux panes.
  if current_win == winnr()
    " Translate Vim's h,j,k,l to tmux's L,D,U,R
    let tmux_direction = tr(a:direction, 'hjkl', 'LDUR')
    call TmuxNavigator_TmuxCommand('select-pane -' . tmux_direction)
  endif
endfunction!
" Define user-callable commands
command! TmuxNavigateLeft  call TmuxNavigator_Navigate('h')
command! TmuxNavigateDown  call TmuxNavigator_Navigate('j')
command! TmuxNavigateUp    call TmuxNavigator_Navigate('k')
command! TmuxNavigateRight call TmuxNavigator_Navigate('l')
" Map the keys. <silent> prevents the command from being echoed.
" <C-U> clears any partial command you may have typed.
nnoremap <silent> <c-h> :<C-U>TmuxNavigateLeft<CR>
nnoremap <silent> <c-j> :<C-U>TmuxNavigateDown<CR>
nnoremap <silent> <c-k> :<C-U>TmuxNavigateUp<CR>
nnoremap <silent> <c-l> :<C-U>TmuxNavigateRight<CR>
endif
"

"============================================================================
" ==          file tree            ==
"============================================================================
" 开启文件浏览器
let g:netrw_banner = 0    " 禁用横幅
let g:netrw_liststyle = 3 " 使用树形列表样式
let g:netrw_browse_split = 4 " 在之前窗口打开文件
let g:netrw_altv = 1      " 垂直分割时在右侧打开
let g:netrw_winsize = 25  " 设置窗口宽度为25%
" 快捷键映射
nnoremap <leader>e :Lexplore<CR>


"============================================================================
" ==          nvim clipboared for remote ssh and local            ==
"============================================================================
" 基本剪贴板设置
set clipboard=unnamed,unnamedplus
" 自动检测环境并配置 OSC52 剪贴板
if !empty($SSH_CONNECTION) || !empty($SSH_CLIENT)
  function! s:AutoCopyToSystem(event)
    if a:event.operator ==# 'y'
      let text = join(a:event.regcontents, "\n")
      if !empty(text)
        call s:SendOSC52(text)
        "echom "Auto-copied to system clipboard via OSC52"
      endif
    endif
  endfunction
  " 发送 OSC52 序列的核心函数
  function! s:SendOSC52(text)
    let b64 = system('base64 -w 0', a:text)
    let b64 = substitute(b64, '\n$', '', '')
    " 关闭 more 选项并使用 redraw 避免屏幕干扰
    let save_more = &more
    set nomore
    silent execute '!printf "\033]52;c;' . b64 . '\a"'
    let &more = save_more
    redraw!
  endfunction
  " 自动复制 yanked 内容到系统剪贴板
  augroup OSC52AutoCopy
    autocmd!
    autocmd TextYankPost * call s:AutoCopyToSystem(v:event)
  augroup END
endif
" 自动同步删除的内容到剪贴板
"autocmd TextYankPost * if v:event.operator ==# 'd' | call setreg('+', v:event.regcontents) | endif


"============================================================================
" ==          toggle line number show mode            ==
"============================================================================
" 将布尔值转换为字符串的辅助函数
function! s:Bool2Str(value)
  return a:value ? "on" : "off"
endfunction
" 切换行号显示模式的函数
function! ToggleNumberMode(silent)
  let number = &number          " 局部到窗口
  let relativenumber = &relativenumber  " 局部到窗口
  if !number && !relativenumber
    set number
  elseif number && !relativenumber
    set relativenumber
  elseif number && relativenumber
    set nonumber
  else " 非number且relativenumber
    set norelativenumber
  endif
  if !a:silent
    echo "number " . s:Bool2Str(&number) . ", relativenumber " . s:Bool2Str(&relativenumber)
  endif
endfunction
" 设置映射
nnoremap <silent> <leader>un :call ToggleNumberMode(0)<CR>


"============================================================================
" ==          set buffer line show            ==
"============================================================================
" 更兼容的高亮定义，添加了 term（普通终端）和 cterm（带颜色终端）属性
highlight CurrentBuffer term=bold cterm=bold ctermfg=black ctermbg=green gui=bold guifg=black guibg=LightGreen
function! BufferList()
  let res = []
  for b in range(1, bufnr('$'))
    if buflisted(b) && getbufvar(b, '&filetype') !=# 'netrw'
      let name = bufname(b)
      if empty(name)
        let name = '[No Name]'
      else
        let name = fnamemodify(name, ':t')
      endif
      if getbufvar(b, '&modified')
        let name .= '[+]'
      endif
      if b == bufnr('%')
        let name = '%#CurrentBuffer# ' . name . ' %*'
      else
        let name = ' ' . name . ' '
      endif
      call add(res, name)
    endif
  endfor
  return join(res, '|')
endfunction
set showtabline=2
set tabline=%!BufferList()
nnoremap <silent> H :bprevious<CR>
nnoremap <silent> L :bnext<CR>
