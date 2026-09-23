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

