-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
--
--
--
--
--
--

--  彻底禁用原生 runtime 插件（节省 ~10ms）
-- 在你的 init.lua 最最顶端（require("lazy") 之前）加入禁用列表：
local disabled_builtins = {
    "netrw",
    "netrwPlugin",
    "netrwSettings",
    "netrwFileHandlers",
    "gzip",
    "zip",
    "zipPlugin",
    "tar",
    "tarPlugin",
    "getscript",
    "getscriptPlugin",
    "vimball",
    "vimballPlugin",
    "2html_plugin",
    "logipat",
    "rrhelper",
    "spellfile_plugin",
    "matchit",
}

for _, plugin in ipairs(disabled_builtins) do
    vim.g["loaded_" .. plugin] = 1
end

---------------------------------------------------------------------------
-- 修复nvim的cmd乱码
---------------------------------------------------------------------------

vim.api.nvim_create_autocmd("TermOpen", {
    callback = function(args)
        -- 不要给 yazi / lazygit 等 TUI 乱发 shell 命令
        if vim.bo[args.buf].filetype == "yazi" then
            return
        end

        local name = vim.api.nvim_buf_get_name(args.buf):lower()

        -- 只处理真正的 cmd.exe
        if not name:find("cmd%.exe") then
            return
        end

        local job_id = vim.b[args.buf].terminal_job_id
        if job_id then
            vim.fn.chansend(job_id, "chcp 65001 >nul\r")
        end
    end,
})
