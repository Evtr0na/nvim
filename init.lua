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
require("config.glslang") -- need install glslang in pc
require("config.diagnostics") --custom warning look like

------------------------------------------------------------
-- Plugins
------------------------------------------------------------
require("lazy").setup("plugins", {
    performance = {
        rtp = {
            -- treesitter parser / queries 目录（见 lua/config/treesitter_path.lua）。
            --
            -- 必须走这里，不能在 init.lua 里手动 prepend：
            -- lazy.nvim 会在 loader.lua 里用 `vim.opt.rtp = rtp` 整体重写
            -- runtimepath，手动加的路径会被冲掉。lazy 只在重置之后才 append
            -- 这里的路径，所以是唯一稳的挂载点。
            paths = { require("config.treesitter_path") },
        },
    },
}) --auto load plugins
------------------------------------------------------------
-- 自定义 LSP
------------------------------------------------------------
-- 放到 lazy.setup 后面，
-- 确保 blink.cmp 已经初始化 LSP capabilities
-- vim.lsp.enable("gdshader_lsp")
