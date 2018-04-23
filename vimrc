set nocompatible

"vim-plug
filetype off
call plug#begin('~/.vim/plugged')
"theme
Plug 'altercation/vim-colors-solarized'
"syntax support
Plug 'plasticboy/vim-markdown'
Plug 'othree/html5.vim'
Plug 'derekwyatt/vim-scala'
Plug 'stephpy/vim-yaml'
Plug 'lepture/vim-jinja'
Plug 'vim-ruby/vim-ruby'
Plug 'fatih/vim-go'
"productivity
Plug 'w0rp/ale'
Plug 'Shougo/deoplete.nvim', {'do': ':UpdateRemotePlugins'}
Plug 'zchee/deoplete-jedi'
Plug 'nvie/vim-flake8'
Plug 'fishbullet/deoplete-ruby'
Plug 'tpope/vim-rails'
Plug 'blackrush/vim-gocode', {'do': ':GoInstallBinaries'}
Plug 'tpope/vim-fugitive'
Plug 'rhysd/committia.vim'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'simnalamburt/vim-mundo'
Plug 'vim-airline/vim-airline'
call plug#end()
filetype plugin indent on

"Syntax highlighting.
syntax on

"Softtab -- use spaces instead tabs.
set expandtab
set tabstop=4 shiftwidth=4 sts=4
set autoindent
set smartindent
set cindent
highlight HardTab cterm=underline
autocmd BufWinEnter * 2 match HardTab /\t\+/

"clipboard
set clipboard+=unnamedplus

"Use mouse.
set mouse=a

"I dislike CRLF.
set fileformat=unix

"Make backspace works like most other applications.
set backspace=2

"Detect modeline hints.
set modeline

"Prefer UTF-8.
set encoding=utf-8 fileencodings=ucs-bom,utf-8,cp949,korea,iso-2022-kr

"These languages have their own tab/indent settings.
au FileType cpp        setl ts=2 sw=2 sts=2
au FileType javascript setl ts=2 sw=2 sts=2
au FileType ruby       setl ts=2 sw=2 sts=2
au FileType xml        setl ts=2 sw=2 sts=2
au FileType yaml       setl ts=2 sw=2 sts=2
au FileType html       setl ts=2 sw=2 sts=2
au FileType htmldjango setl ts=2 sw=2 sts=2
au FileType lua        setl ts=2 sw=2 sts=2
au FileType haml       setl ts=2 sw=2 sts=2
au FileType css        setl ts=2 sw=2 sts=2
au FileType sass       setl ts=2 sw=2 sts=2
au FileType less       setl ts=2 sw=2 sts=2
au Filetype rst        setl ts=3 sw=3 sts=3
au FileType make       setl ts=4 sw=4 sts=4 noet
au FileType gitcommit setl spell

"Some additional syntax highlighters.
au! BufRead,BufNewFile *.wsgi setfiletype python
au! BufRead,BufNewFile *.sass setfiletype sass
au! BufRead,BufNewFile *.haml setfiletype haml
au! BufRead,BufNewFile *.less setfiletype less
au! BufRead,BufNewFile *rc setfiletype conf

"Mundo -- Undo tree visualization
set undofile
set undodir=~/.vim/undo

"deoplete
let g:deoplete#enable_at_startup = 1
let g:deoplete#sources#jedi#show_docstring = 1

"FZF
nmap <leader>f :FZF<CR>
nmap <leader>/ :Lines<CR>

"vim-go specific
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_structs = 1
let g:go_highlight_operators = 1
let g:go_highlight_build_constraints = 1
au FileType go nmap <leader>r  <Plug>(go-run)
au FileType go nmap <leader>b  <Plug>(go-build)
au FileType go nmap <Leader>ds <Plug>(go-def-split)
au FileType go nmap <Leader>dv <Plug>(go-def-vertical)
au FileType go nmap <Leader>n  <Plug>(go-referrers)

"English spelling checker.
setlocal spelllang=en_us

"Keep 80 columns and dense lines.
set colorcolumn=81
highlight ColorColumn cterm=underline ctermbg=none
autocmd BufWinEnter * match Error /\%>80v.\+\|\s\+$\|^\s*\n\+\%$/

"truecolor
if has('termguicolors')
  set termguicolors
endif

"neovim-specific configurations
if has("nvim")
  colorscheme solarized
  set background=dark
  set guioptions=egmrLt
  set linespace=1
endif

"gVim-specific configurations (including MacVim).
if has("gui_running")
  colorscheme solarized
  set background=dark
  set guioptions=egmrLt
  set linespace=1
endif

"MacVim-specific configurations.
if has("gui_macvim")
  set imd
  set guifont=DejaVu_Sans_Mono:h12.00
endif
