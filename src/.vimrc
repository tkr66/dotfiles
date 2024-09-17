" Setup vim-plug https://github.com/junegunn/vim-plug/wiki/tips#automatic-installation
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin()
Plug 'cocopon/iceberg.vim'
Plug 'vim-airline/vim-airline'
Plug 'easymotion/vim-easymotion'
Plug 'thinca/vim-quickrun'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-fugitive'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'guns/xterm-color-table.vim'
Plug 'prabirshrestha/vim-lsp'
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'
Plug 'sqls-server/sqls.vim'
Plug 'hrsh7th/vim-vsnip'
Plug 'hrsh7th/vim-vsnip-integ'
Plug 'sebdah/vim-delve'
Plug 'elixir-editors/vim-elixir'
Plug 'godlygeek/tabular'
Plug 'preservim/vim-markdown'
call plug#end()

let mapleader = " "
let &t_SI = "\e[3 q"
let &t_EI = "\e[1 q"
autocmd! CmdlineEnter * call echoraw(&t_SI)
autocmd! CmdlineLeave * call echoraw(&t_EI)
let g:airline_section_b = '%{strftime("%c")}'

set encoding=utf-8
set showcmd
set showmatch
set scrolloff=0
set ignorecase
set smartcase
set hlsearch
set incsearch
set splitright
set splitbelow
set wildmenu
set wildmode=longest,list,full
set backspace=indent,eol,start
set list listchars=tab:\\u00BB\\x20,trail:\\u2601
set expandtab
set tabstop=2
set shiftwidth=0
" Always display
set showtabline=2
set confirm

fun! GetPopupId(n)
  let pops = popup_list()
  if len(pops) == 0
    return -1
  endif
  return pops[a:n]
endfun

fun! PopupScroll(id,n)
  let pos = popup_getpos(a:id)
  let firstline = pos.firstline + a:n
  if firstline < 1
    let firstline = 1
  elseif firstline > pos.lastline
    let firstline = pos.lastline
  endif
  call popup_setoptions(a:id, {'firstline': firstline})
endfun

fun! PopupFilterScroll(id, key)
  if a:key == "j"
    call PopupScroll(a:id,1)
    return 1
  endif
  if a:key == "\<C-D>"
    call PopupScroll(a:id,10)
    return 1
  endif
  if a:key == "k"
    call PopupScroll(a:id,-1)
    return 1
  endif
  if a:key == "\<C-U>"
    call PopupScroll(a:id,-10)
    return 1
  endif
  if a:key =="x"
    call popup_close(a:id)
    return 1
  endif
  return 1
endfun

fun! AttachPopupScroller(id) abort
  " Want to handle the time when a popup window is opened.
  " There is a possibility that the first element might be not
  " opened popup window.
  let winid = GetPopupId(0)
  if winid > 0
    call timer_stop(a:id)
    call popup_setoptions(winid, #{filter: 'PopupFilterScroll'})
  endif
endfun

set t_Co=256
syntax on
autocmd! ColorScheme iceberg
      \ hi LineNr ctermfg=140
colorscheme iceberg
set background=dark

" Meta and special keys listed with ':map'
hi! link SpecialKey Special

augroup vb
  au! BufReadPost *.bas,*.cls,*.dcm,*.frm edit ++enc=cp932 %
augroup END
augroup git
  au!
  autocmd FileType gitconfig
        \ set noexpandtab
augroup END
autocmd! BufReadPre *.go
      \ let g:go_highlight_functions = 1 |
      \ let g:go_highlight_function_calls = 1 |
      \ let g:go_highlight_types = 1 |
      \ let g:go_highlight_operators = 1 |

fun! s:on_go_loaded() abort
  hi goFunction ctermfg=214
  hi goFunctionCall ctermfg=110
  hi goTypeName ctermfg=140
  hi goTypeConstructor ctermfg=140
  hi goOperator ctermfg=110
  syntax match Bracket /\[\|\]/
  hi Bracket ctermfg=185
endfun
autocmd! FileType go call s:on_go_loaded()

if !empty(globpath(&rtp, 'autoload/lsp.vim'))
  fun! s:on_lsp_buffer_enabled() abort
    let g:vsnip_snippet_dir = '$HOME/.vim/snippets'
    setlocal omnifunc=lsp#complete
    setlocal signcolumn=yes
    if exists('+tagfunc') | setlocal tagfunc=lsp#tagfunc | endif
    nmap <buffer> cd <plug>(lsp-rename)
    nmap <buffer> gd <plug>(lsp-peek-definition)
          \ :call timer_start(100, 'AttachPopupScroller', {})<CR>
    nmap <buffer> gD <plug>(lsp-definition)
    nmap <buffer> gh <plug>(lsp-hover)
          \ :call timer_start(100, 'AttachPopupScroller', {})<CR>
    nmap <buffer> gi <plug>(lsp-implementation)
    nmap <buffer> gk <plug>(lsp-code-action)
    nmap <buffer> gr <plug>(lsp-references)
    nmap <buffer> gt <plug>(lsp-type-definition)
    nmap <buffer> gs <plug>(lsp-document-symbol-search)
    nmap <buffer> gS <plug>(lsp-workspace-symbol-search)
    nmap <buffer> = <plug>(lsp-document-format)
    " lsp_float_opend and lsp#document_hover_preview_winid
    " did not work as expected with lsp-peek-definition.
    nmap <buffer> g[ <plug>(lsp-previous-diagnostic)
    nmap <buffer> g] <plug>(lsp-previous-diagnostic)
    inoremap <expr> <CR> pumvisible() ? asyncomplete#close_popup() : "\<CR>"
    autocmd! BufWritePre <buffer>
          \ call execute('LspCodeActionSync source.organizeImports') |
          \ LspDocumentFormatSync
  endfun

  if executable('gopls')
    au User lsp_setup call lsp#register_server({
          \ 'name': 'gopls',
          \ 'cmd': {server_info->['gopls']},
          \ 'allowlist': ['go'],
          \ })
  endif
  if executable('pylsp')
    au User lsp_setup call lsp#register_server({
          \ 'name': 'pylsp',
          \ 'cmd': {server_info->['pylsp']},
          \ 'allowlist': ['python'],
          \ 'config': {'pylsp': {'plugins': {'autopep8': {'enabled': v:false}}}},
          \ })
  endif  
  if executable('elixir-ls')
    au User lsp_setup call lsp#register_server({
          \ 'name': 'elixir-ls',
          \ 'cmd': {server_info->['elixir-ls']},
          \ 'allowlist': ['elixir'],
          \ 'semantic_highlight': v:true,
          \ })
  endif  
  if executable('rust-analyzer')
    au User lsp_setup call lsp#register_server({
          \ 'name': 'rust-analyzer',
          \ 'cmd': {server_info->['rust-analyzer']},
          \ 'whitelist': ['rust'],
          \ 'initialization_options': {
          \ 'cargo': {
          \ 'buildScripts': {
          \ 'enable': v:true,
          \ },
          \ 'check': {
          \ 'command': 'clippy',
          \ },
          \ },
          \ 'procMacro': {
          \ 'enable': v:true,
          \ },
          \ }
          \ })
  endif
  if executable('sqls')
    au User lsp_setup call lsp#register_server({
          \ 'name': 'sqls',
          \ 'cmd': {server_info->['sqls']},
          \ 'whitelist': ['sql'],
          \ })
  endif  

  augroup lsp_install
    au!
    autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
  augroup END

  command! LspDebug
        \ let lsp_log_verbose=1 |
        \ let lsp_log_file = expand('~/lsp.log') |
        \ :vnew | execute "ter ++curwin tail -f " . expand('~/lsp.log') |
        \ :wincmd p
  let g:lsp_diagnostics_enabled = 1
  let g:lsp_inlay_hints_enabled = 1
  let g:lsp_diagnostics_virtual_text_enabled = 1
  let g:lsp_diagnostics_virtual_text_insert_mode_enabled = 0
  let g:lsp_diagnostics_virtual_text_align = "after"
  let g:lsp_diagnostics_virtual_text_wrap = "wrap"
endif

nnoremap <silent> <C-[><C-[> :noh<CR>
nnoremap <F3> :FZF<Space>
nnoremap <F4> :Buffers<CR>
nnoremap <silent> gb :call NextBuffer(1)<CR>
nnoremap <silent> gB :call NextBuffer(-1)<CR>
nnoremap <silent> g= :set lazyredraw<CR>gg=G`'zz:set nolazyredraw<CR>
nnoremap <silent> gyy "+yy

vnoremap <silent> gy "+y

cnoremap <C-a> <C-b>

" Turn on case-insensitive feature
let g:EasyMotion_smartcase = 1
" keep cursor column when JK motion
let g:EasyMotion_startofline = 0
" Disable default mappings
let g:EasyMotion_do_mapping = 0

" Jump to anywhere you want with minimal keystrokes, with just one key binding.
" `s{char}{label}`
nmap s <Plug>(easymotion-overwin-f)
" or
" `s{char}{char}{label}`
" Need one more keystroke, but on average, it may be more comfortable.
" nmap s <Plug>(easymotion-overwin-f2)

" JK motions: Line motions
map <Leader>j <Plug>(easymotion-j)
map <Leader>k <Plug>(easymotion-k)

map <Leader>l <Plug>(easymotion-overwin-line)

fun! s:handle_imap_tab()
  if vsnip#jumpable(1)
    return "\<Plug>(vsnip-jump-next)"
  endif
  let l:compArg = getline('.')[:col('.')]
  return "\<Tab>"
endfun

imap <expr> <Tab> <SID>handle_imap_tab()
smap <expr> <Tab>   vsnip#jumpable(1)   ? '<Plug>(vsnip-jump-next)'      : '<Tab>'
smap <expr> <S-Tab> vsnip#jumpable(-1)  ? '<Plug>(vsnip-jump-prev)'      : '<S-Tab>'
imap <expr> <S-Tab> vsnip#jumpable(-1)  ? '<Plug>(vsnip-jump-prev)'      : '<S-Tab>'

fun! PrintSyntaxGroup()
  let l:s = synID(line('.'), col('.'), 1)
  echo synIDattr(l:s, 'name') . ' -> ' . synIDattr(synIDtrans(l:s), 'name')
endfun

fun! NextBuffer(idx)
  let bufs = s:get_normalbuffers()
  if len(bufs) == 0
    echo "No normal buffers available"
    return
  endif
  let dict = s:to_keybased_doubly_circularlist(bufs)
  if !has_key(dict, bufnr())
    echo printf("Current buffer %d is not a normal buffer", bufnr())
    return
  endif
  let n = -1
  if a:idx == 1
    let n = s:to_keybased_doubly_circularlist(bufs)[bufnr()].next.value
  elseif a:idx == -1
    let n = s:to_keybased_doubly_circularlist(bufs)[bufnr()].prev.value
  else
    echo "Argument idx must be 1 or -1"
    return
  endif
  execute "b" n
endfun

fun! s:get_normalbuffers()
  let arr = []
  for buf in getbufinfo({'buflisted': 1})
    " if the buf is a normal buffer and not a netrw buffer
    if getbufvar(buf.bufnr, '&buftype') == ''
          \ && getbufvar(buf.bufnr, 'netrw_browser_active') != 1
      let arr = add(arr,buf.bufnr)
    endif
  endfor
  return arr
endfun

function! s:to_keybased_doubly_circularlist(arr)
  function! s:new_node(value, prev, next)
    let n = {
          \ 'value': a:value,
          \ 'prev': a:prev,
          \ 'next': a:next
          \ }
    return n
  endfunction

  if empty(a:arr)
    return {}
  endif

  let d = {}
  let head = s:new_node(a:arr[0], {}, {})
  let d[head.value] = head

  let cur = head
  for elem in a:arr[1:]
    let node = s:new_node(elem, cur, {})
    let cur.next = node
    let cur = node
    let d[cur.value] = cur
  endfor

  let cur.next = head
  let head.prev = cur
  let d[cur.value] = cur

  return d
endfunction

" Output the circular list dictionary
function! PrintKeyBasedDoublyCircularList(dict)
  for key in keys(a:dict)
    let node = a:dict[key]
    echo printf(
          \ "Value: %s, Prev: %s, Next: %s",
          \ node.value, node.prev.value, node.next.value)
  endfor
endfunction

augroup rust
  fun! s:initialize_quickrun_config()
    if match(expand("%:p"), "examples") > -1
      let g:quickrun_config = {
            \  "rust/cargo": {
            \     "command": "cargo",
            \     "exec": "%c run --example %s:t:r",
            \     "tempfile": "%{expand('%:p:h')}/%{strftime('%Y%m%d%H%M%S')}.rs",
            \     "hook/time/enable": "1",
            \   }
            \}
      execute 'nnoremap <silent> <Leader>x :QuickRun rust/cargo<CR>'
    endif
  endfun
  au!
  autocmd BufEnter *.rs call s:initialize_quickrun_config()
augroup END

let g:quickrun_config = {
      \  "make": {
      \     "command": "make",
      \     "exec": "%c %o",
      \     "hook/time/enable": "1",
      \   }
      \}
