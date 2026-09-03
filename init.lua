require("bootstrap")

------------------------------------------------------------
-- 基础配置
------------------------------------------------------------
require("config.options") --setting
require("config.keymaps") --keymaps
require("config.autocmds") --auto do commands
require("config.commands") --custom commands
require("config.filetypes") -- gdshader

------------------------------------------------------------
-- Diagnostic
------------------------------------------------------------
require("config.diagnostics") --custom warning look like

------------------------------------------------------------
-- Plugins
------------------------------------------------------------
require("lazy").setup("plugins") --auto load plugins

------------------------------------------------------------
-- 自定义 LSP
------------------------------------------------------------
-- 放到 lazy.setup 后面，
-- 确保 blink.cmp 已经初始化 LSP capabilities
-- vim.lsp.enable("gdshader_lsp")
