-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
-- lua/config/options.lua



--------------------------------
-- auto-session
--------------------------------
vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

--------------------------------
--vim
--------------------------------
-- 始终保持 Sign Column 展开（推荐设为 yes，或者指定固定宽度 "yes:1" / "yes:2"）
vim.o.signcolumn = "yes"
-- 关闭右下角的横竖号数
vim.opt.ruler = false
-- vim.opt.autochdir = true
vim.g.mapleader = " "
vim.g.maplocalleader = " "
--vim.o.guifont = "Sarasa Term SC:h14"

vim.opt.number = true -- 显示当前行的绝对行号
vim.opt.relativenumber = true -- 显示相对行号（光标上下行显示距离）

--------------------------------
-- neovide
--------------------------------

if vim.g.neovide then
    vim.g.neovide_cursor_animation_length = 0
    vim.g.neovide_cursor_short_animation_length = 0
    vim.g.neovide_scroll_animation_length = 0
    vim.g.neovide_cursor_animate_in_insert_mode = false
    vim.g.neovide_cursor_animate_command_line = false
end
-- 下面继续你原来的 options

--------------------------------
-- 缩进
--------------------------------

-- 1. 讲 Tab 键自动转换为空格 (Spaces)
-- vim.o.expandtab = true
-- 2. 设置按一次 Tab 键插入的空格数量为 2
vim.o.softtabstop = 2

-- 3. 设置自动缩进 (<< / >> 或换行) 时的空格数量为 2
vim.o.shiftwidth = 2

-- 4. 设置 1 个 \t 制表符在屏幕上渲染时只占用 2 个字符宽度
vim.o.tabstop = 2

--------------------------------
-- Lazy.nvim Add_On_MangerBlackGround_Color
--------------------------------
vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "*",
    callback = function()
        -- 自定义 Lazy 界面背景底色
        vim.api.nvim_set_hl(0, "LazyNormal", { bg = "#181818" })
        -- vim.api.nvim_set_hl(0, "LazyBorder", { bg = "#181818", fg = "#b4befe" })
        vim.api.nvim_set_hl(0, "LazyBorder", { bg = "#181818" })
    end,
})
