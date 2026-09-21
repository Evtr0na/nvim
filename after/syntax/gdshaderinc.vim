" Neovim 只内置了 syntax/gdshader.vim（文件头声明 Filenames: *.gdshader），
" 没有 syntax/gdshaderinc.vim，所以 ft=gdshaderinc 时 b:current_syntax 一直是空的。
" gdshader-nvim-support 也只提供 ftplugin，不提供语法文件。
" 这里直接复用 gdshader 的语法规则（两者语法基本一致）。

runtime! syntax/gdshader.vim
