-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
-- ~/.config/nvim/lua/config/keymaps.lua

local map = vim.keymap.set

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

-- Space + =
-- 格式化
map("n", "<leader>=", function()
    vim.lsp.buf.format({ async = true })
end, { desc = "Format Document" })

-- =========================================================
-- Visual 模式
-- =========================================================

-- p：粘贴后不覆盖寄存器
map("x", "p", '"_dP', {
    desc = "Paste Without Overwriting Register",
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
