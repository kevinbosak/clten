if &cp | set nocp | endif
map  h_
let s:cpo_save=&cpo
set cpo&vim
map <NL> j_
map  k_
map  l_
map  :r ~/notes/basic.pod
noremap  :Tidy
vmap P p :call setreg('"', getreg('0')) 
xmap S <Plug>VSurround
nmap \pd :e `perldoc -ml <cword>`
nmap \pf :!perldoc -f <cword>
vmap <silent> \x <Plug>VisualTraditional
vmap <silent> \c <Plug>VisualTraditionalj
nmap <silent> \x <Plug>Traditional
nmap <silent> \c <Plug>Traditionalj
map \jt :%!json_xs -f json -t json-pretty
nmap cs <Plug>Csurround
nmap ds <Plug>Dsurround
nmap gx <Plug>NetrwBrowseX
xmap s <Plug>Vsurround
nmap ySS <Plug>YSsurround
nmap ySs <Plug>YSsurround
nmap yss <Plug>Yssurround
nmap yS <Plug>YSurround
nmap ys <Plug>Ysurround
nnoremap <silent> <Plug>NetrwBrowseX :call netrw#NetrwBrowseX(expand("<cWORD>"),0)
noremap <Plug>VisualFirstLine :call EnhancedCommentify('', 'first',				    line("'<"), line("'>"))
noremap <Plug>VisualTraditional :call EnhancedCommentify('', 'guess',				    line("'<"), line("'>"))
noremap <Plug>VisualDeComment :call EnhancedCommentify('', 'decomment',				    line("'<"), line("'>"))
noremap <Plug>VisualComment :call EnhancedCommentify('', 'comment',				    line("'<"), line("'>"))
noremap <Plug>FirstLine :call EnhancedCommentify('', 'first')
noremap <Plug>Traditional :call EnhancedCommentify('', 'guess')
noremap <Plug>DeComment :call EnhancedCommentify('', 'decomment')
noremap <Plug>Comment :call EnhancedCommentify('', 'comment')
map <F5> :set list!
map <F4> :set wrap!
map <F3> :set number!
inoremap  yiW<End>==0
imap S <Plug>ISurround
imap s <Plug>Isurround
imap  <Plug>Isurround
imap <silent> \x <Plug>Traditional
imap <silent> \c <Plug>Traditionalji
iabbr udd use Data::Dumper;
cabbr jsc !js /home/kbosak/bin/check_js.js "`cat %`" | /home/kbosak/bin/format_lint_output.py | more
let &cpo=s:cpo_save
unlet s:cpo_save
set autoindent
set background=dark
set backspace=eol,indent,start
set cindent
set cinkeys=0{,0},0),:,!^F,o,O,e
set comments=:#
set expandtab
set fileencodings=ucs-bom,utf-8,default,latin1
set helplang=en
set history=50
set hlsearch
set incsearch
set isfname=@,48-57,/,.,-,_,+,,,#,$,%,~,=,:
set iskeyword=@,48-57,_,192-255,:
set makeprg=perl\ -c\ %
set nomodeline
set pastetoggle=<F2>
set ruler
set runtimepath=~/.vim,/var/lib/vim/addons,/usr/share/vim/vimfiles,/usr/share/vim/vim74,/usr/share/vim/vimfiles/after,/var/lib/vim/addons/after,~/.vim/after
set shiftround
set shiftwidth=4
set showmatch
set smartcase
set suffixes=.bak,~,.swp,.o,.info,.aux,.log,.dvi,.bbl,.blg,.brf,.cb,.ind,.idx,.ilg,.inx,.out,.toc
set tabstop=4
set viminfo='20,\"50
set winminheight=0
" vim: set ft=vim :
