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

-----------------------------------------
-- listen to Godot 127.0.0.1:6666 
-----------------------------------------
--Godot / Text Editor / External
-- Exec Path :     C:\Users\SDD\AppData\Local\nvim\lua\tools\godot-nvim.cmd
-- Exec Flags :    "{file}" {line} {col}

local project_root = vim.fn.getcwd()
local godot_project = project_root .. "/project.godot"

if vim.fn.filereadable(godot_project) == 1 then
    local godot_server = "127.0.0.1:6666"

    local ok, result = pcall(vim.fn.serverstart, godot_server)

    if ok then
        vim.notify("Godot editor server: " .. result)
    else
        vim.notify(
            "Failed to start Godot editor server: " .. tostring(result),
            vim.log.levels.WARN
        )
    end
end

