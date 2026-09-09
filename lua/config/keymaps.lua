-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
-- ~/.config/nvim/lua/config/keymaps.lua

local map = vim.keymap.set

-- =========================================================
--"smjonas/inc-rename.nvim",
-- =========================================================

map("n", "<leader>rn", function()
    local ft = vim.bo.filetype

    if ft == "gdshader" or ft == "gdshaderinc" then
        vim.cmd("GDShaderRename")
        return
    end

    vim.cmd("IncRename " .. vim.fn.expand("<cword>"))
end, {
    desc = "Incremental Rename",
})

-- Ctrl+上下：调整窗口高度
map("n", "<C-Down>", "<cmd>resize +2<cr>", { desc = "增大窗口高度", noremap = true, silent = true })
map("n", "<C-Up>", "<cmd>resize -2<cr>", { desc = "减小窗口高度", noremap = true, silent = true })

-- Ctrl+左右：调整窗口宽度
map("n", "<C-Right>", "<cmd>vertical resize -2<cr>", { desc = "减小窗口宽度", noremap = true, silent = true })
map("n", "<C-Left>", "<cmd>vertical resize +2<cr>", { desc = "增大窗口宽度", noremap = true, silent = true })

-- 默认 y/d/p 和系统剪贴板共享 (+寄存器 = Ctrl+C剪贴板)
vim.opt.clipboard = "unnamedplus"
-- local del = vim.keymap.del

-- =========================================================
-- 基础设置
-- =========================================================

-- 你 VS Code 里的 jj -> Esc
--
--

--
map("i", "jj", "<Esc>", { desc = "Exit Insert Mode" })

-- =========================================================
-- VS Code 风格快捷键
-- =========================================================

map("n", "<C-a>", "ggVG", { desc = "Select All" })
map("x", "<C-a>", "<Esc>ggVG", { desc = "Select All" })

map("n", "<leader>q", "<C-w>c", {
    desc = "Close Window",
})

map("n", "Q", "<cmd>confirm bdelete<cr>", {
    desc = "Close Buffer",
})

-- =========================================================
-- Ctrl + H/J/K/L
-- =========================================================

map("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })

-- =========================================================
-- 搜索-Search--转移到telescope里了
-- =========================================================
-- map("n", "<leader>z", function()
--     require("telescope").extensions.zoxide.list()
-- end, { desc = "Zoxide jump" })
--
-- map("n", "<leader>b", function()
--     require("telescope.builtin").buffers()
-- end, { desc = "List Buffers" })
--
-- map("n", "<leader>h", function()
--     require("telescope.builtin").help_tags()
-- end, { desc = "Help Tags" })
--
-- map("n", "<leader>z", function()
--     require("telescope").extensions.zoxide.list()
-- end, { desc = "Zoxide jump" })
--
-- map("n", "<leader>o", function()
--     require("telescope.builtin").lsp_document_symbols()
-- end, { desc = "Document Symbols" })
--
-- -- Space + F
-- map("n", "<leader>f", function()
--     require("telescope.builtin").find_files()
-- end, { desc = "Find File" })
--
-- -- Space + J
-- map("n", "<leader>j", function()
--     require("telescope.builtin").live_grep()
-- end, { desc = "Search Text" })

-- Ctrl+N 清掉搜索高亮
map("n", "<C-n>", "<cmd>nohlsearch<cr>", { desc = "Clear Search Highlight" })

-- =========================================================
-- 文件
-- =========================================================

-- Space + W 保存
-- map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save File" })
map("n", "<C-s>", "<cmd>w<cr>", { desc = "Save File" })
-- Space + E Explorer
--
--转移到了插件里
-- map("n", "<leader>e", "<cmd>Neotree toggle reveal<cr>", {
--     desc = "Explorer",
-- })

-- =========================================================
-- 编辑
-- =========================================================

-- Space + C 注释

-- normal 模式下按 Ctrl+/ 注释当前行，并保持在 Insert 模式
map("n", "<C-/>", "gcc", { remap = true, desc = "Comment Line" })
map("n", "<C-_>", "gcc", { remap = true, desc = "Comment Line" })

-- visual 模式下按 Ctrl+/ 注释当前行，并保持在 Insert 模式
map("v", "<C-/>", "gc", { remap = true, desc = "Comment Selection" })
map("v", "<C-_>", "gc", { remap = true, desc = "Comment Selection" })

-- Insert 模式下按 Ctrl+/ 注释当前行，并保持在 Insert 模式
map("i", "<C-/>", "<C-o>gcc", { remap = true, desc = "Comment Line in Insert Mode" })
map("i", "<C-_>", "<C-o>gcc", { remap = true, desc = "Comment Line in Insert Mode" })

-- Space + R 重命名
map("n", "<leader>r", vim.lsp.buf.rename, {
    desc = "Rename Symbol",
})


-- =========================================================
-- Visual Line：y / Y / p / P 保持原来的列
-- =========================================================

-- 把光标移动到指定行，同时尽量保持原来的“屏幕列”
local function set_vcol(row, vcol)
    if row < 1 then
        return
    end

    -- 把屏幕列转换成目标行上的 byte column
    local col = vim.fn.virtcol2col(0, row, vcol)

    -- 空行时 virtcol2col() 可能返回 0
    if col < 1 then
        col = 1
    end

    -- cursor({ lnum, col, off, curswant })
    -- 最后的 vcol 同时保存上下移动时想保持的列
    vim.fn.cursor({
        row,
        col,
        0,
        vcol,
    })
end

-- ---------------------------------------------------------
-- Visual yank
-- V -> y
-- V -> Y
-- 都保持原来的列
-- ---------------------------------------------------------
local function visual_yank_keep_col()
    local vcol = vim.fn.virtcol(".")
    local reg = vim.v.register

    -- normal! 绕过映射，避免递归
    vim.cmd.normal({
        args = {
            '"' .. reg .. "y",
        },
        bang = true,
    })

    -- yank 完以后，让 Neovim 自己决定停在哪一行，
    -- 我们只恢复列
    local row = vim.fn.line(".")

    set_vcol(row, vcol)
end

map("x", "y", visual_yank_keep_col, {
    desc = "Yank and Keep Column",
})

map("x", "Y", visual_yank_keep_col, {
    desc = "Yank and Keep Column",
})

-- =========================================================
-- Normal mode p / P
-- linewise paste 后保持原来的列
-- =========================================================

local function normal_paste_keep_col(key)
    -- 保存粘贴前的屏幕列
    local vcol = vim.fn.virtcol(".")

    -- 当前指定的寄存器
    --
    -- 普通 p   -> "
    -- "0p      -> 0
    -- "ap      -> a
    -- "+p      -> +
    local reg = vim.v.register

    -- 支持 2p / 3p 等 count
    local count = vim.v.count
    local count_prefix = count > 0 and tostring(count) or ""

    -- 如果用户没有显式指定寄存器，
    -- 不要人为补上 ""，让 Neovim 自己处理
    -- clipboard=unnamedplus 等默认行为
    local reg_prefix = ""

    if reg ~= '"' then
        reg_prefix = '"' .. reg
    end

    -- 真正执行原生 p / P
    vim.cmd.normal({
        args = {
            reg_prefix .. count_prefix .. key,
        },
        bang = true,
    })

    -- 对 linewise paste 来说，
    -- 此时 Neovim 已经把光标放在新粘贴出来的行
    local row = vim.fn.line(".")

    -- 把原来的屏幕列转换成当前行的实际 byte column
    local col = vim.fn.virtcol2col(0, row, vcol)

    if col < 1 then
        col = 1
    end

    -- 恢复原来的列
    vim.fn.cursor({
        row,
        col,
        0,
        vcol,
    })
end

map("n", "p", function()
    normal_paste_keep_col("p")
end, {
    desc = "Paste Below and Keep Column",
})

map("n", "P", function()
    normal_paste_keep_col("P")
end, {
    desc = "Paste Above and Keep Column",
})

-- >
map("x", ">", ">gv", {
    desc = "Indent",
})

-- <
map("x", "<", "<gv", {
    desc = "Outdent",
})

-- J：选中行向下移动
map("x", "J", ":m '>+1<CR>gv=gv", {
    desc = "Move Selection Down",
})

-- K：选中行向上移动
map("x", "K", ":m '<-2<CR>gv=gv", {
    desc = "Move Selection Up",
})

-- =========================================================
-- 标签 / Buffer
-- =========================================================
map("n", "<S-h>", "<cmd>bprevious<cr>", {
    desc = "Previous Buffer",
})

map("n", "<S-l>", "<cmd>bnext<cr>", {
    desc = "Next Buffer",
})

-- gh / gl
map("n", "gh", "<cmd>bprevious<cr>", {
    desc = "Previous Buffer",
})

map("n", "gl", "<cmd>bnext<cr>", {
    desc = "Next Buffer",
})

-- =========================================================
-- 分屏
-- =========================================================

-- Space + s + v
map("n", "<leader>sv", "<cmd>vsplit<cr>", {
    desc = "Split Right",
})

-- Space + s + h
map("n", "<leader>sh", "<cmd>split<cr>", {
    desc = "Split Down",
})

-- Space + s + m
-- VS Code toggleMaximizeEditorGroup
map("n", "<leader>sm", "<cmd>MaximizerToggle<cr>", {
    desc = "Toggle Maximize Window",
})

-- Space + s + =
map("n", "<leader>s=", "<C-w>=", {
    desc = "Equal Window Sizes",
})

-- Space + s + .
-- 增大当前窗口
map("n", "<leader>s.", function()
    vim.cmd("resize +2")
    vim.cmd("vertical resize +4")
end, {
    desc = "Increase Window Size",
})

-- Space + s + ,
-- 减小当前窗口
map("n", "<leader>s,", function()
    vim.cmd("resize -2")
    vim.cmd("vertical resize -4")
end, {
    desc = "Decrease Window Size",
})

-- =========================================================
-- LSP
-- =========================================================

-- gr：
-- 你的 VS Code：find references
-- LazyVim 默认本来就是这个
-- map("n", "gr", vim.lsp.buf.references, {
--     desc = "References",
-- })

-- =========================================================
-- Leader + s + r
-- 当前文件批量替换
-- =========================================================

map("n", "<leader>sr", function()
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(":%s///g<Left><Left><Left>", true, false, true), "n", false)
end, {
    desc = "Search and Replace",
})

-- =========================================================
-- Undo / Redo
-- =========================================================

-- Ctrl+Z → Undo
-- map("n", "<C-z>", "u", {
--     desc = "Undo",
-- })

-- 用大写 U 作为 Redo（非常顺手且无需复杂终端协议支持）
map("n", "U", "<C-r>", { desc = "Redo" })

-- Ctrl+Shift+Z → Redo
-- map("n", "<C-S-z>", "<C-r>", { desc = "Redo" })
-- map("n", "<C-Z>", "<C-r>", { desc = "Redo" })
-- -- Visual 模式也保持一致
-- map("x", "<C-z>", "<Esc>u", {
--     desc = "Undo",
-- })

-- map("x", "<C-S-z>", "<Esc><C-r>", {
--     desc = "Redo",
-- })
