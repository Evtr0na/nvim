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


local godot_server = "127.0.0.1:6666"

local function start_godot_server(buf)
    buf = buf or 0

    -- 从当前文件向父目录寻找 project.godot
    local root = vim.fs.root(buf, "project.godot")

    -- 不是 Godot 项目
    if not root then
        return
    end

    -- 已经监听 6666 就不要重复启动
    if vim.tbl_contains(vim.fn.serverlist(), godot_server) then
        return
    end

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

local group = vim.api.nvim_create_augroup("godot_external_editor", {
    clear = true,
})

vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function(args)
        start_godot_server(args.buf)
    end,
})

-- autocmds.lua 加载时，当前 buffer 可能已经触发过一次 BufEnter
-- 所以这里主动检查一次
start_godot_server(0)
