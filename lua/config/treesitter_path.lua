-- Treesitter parser / queries 的存放位置。
--
-- 为什么放在配置文件目录而不是 stdpath("data")/site：
--   那份目录不在本仓库里，换机器或重装就得重新编译一遍 parser。
--   这里把 parser 和 queries 跟配置放一起，由 init.lua 交给 lazy.nvim 挂到
--   runtimepath 上，Neovim 就按标准路径去找 parser/*.so 和 queries/<lang>/*.scm。
--
-- 目录结构（与标准 rtp 布局一致，加语言 = 加文件）：
--   ts/parser/<lang>.so
--   ts/queries/<lang>/highlights.scm  (以及 folds/indents/injections/locals)
--
-- 注意：.so 与平台绑定，换机器要重新编译，见 README。

return vim.fn.stdpath("config") .. "/ts"
