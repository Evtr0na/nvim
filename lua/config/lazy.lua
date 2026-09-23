-- ============================================================
-- lazy.nvim 启动
-- ============================================================
-- init.lua 最后才 require 这个模块 —— lazy 的 rtp 处理必须在
-- 所有 config.* 模块之后跑，否则会被它重置掉。

local M = {}

-- ============================================================
-- treesitter parser / queries 目录
-- ============================================================
-- 默认该放 stdpath("data")/site，那份目录不在本仓库里，换机器就得重编。
-- 放在配置目录下的 ts/，跟着配置走。目录结构与标准 rtp 一致：
--
--     ts/parser/<lang>.so
--     ts/queries/<lang>/highlights.scm
--
-- 重建 parser 的方法见 ts/README.md。
M.treesitter_path = vim.fn.stdpath("config") .. "/ts"

require("lazy").setup("plugins", {
    performance = {
        rtp = {
            -- 挂载 ts/ 必须走这里，不能在 init.lua 里手动
            -- `vim.opt.runtimepath:prepend(...)`：
            --
            -- lazy.nvim 在 core/loader.lua 里是 `vim.opt.rtp = rtp`，
            -- 整体重写 runtimepath 而不是 append。手动加的路径当时有效、
            -- 但 lazy 一加载就被冲掉（现象是 parser 一时找得到一时找不到）。
            --
            -- `performance.rtp.paths` 是 lazy 在完成重置之后才 append 的，
            -- 所以是唯一稳定的挂载点。
            paths = { M.treesitter_path },
        },
    },
})

return M
