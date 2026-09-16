-- 模糊搜索
--
-- fd     -> 查找文件
-- rg     -> 搜索文本
-- fzf    -> 模糊匹配
-- fzf-lua -> Neovim UI / LSP / buffers / zoxide 等

-- =========================================================
-- Godot 项目检测 -- 只检查工作区根目录
-- =========================================================

local function get_godot_root()
    local cwd = vim.fn.getcwd()
    local project_file = vim.fs.joinpath(cwd, "project.godot")

    if vim.uv.fs_stat(project_file) then
        return cwd
    end

    return nil
end

-- =========================================================
-- 普通项目参数
-- =========================================================

local normal_fd_opts = table.concat({
    "--color=never",
    "--type f",
    "--type l",
    "--hidden",
    "--follow",
    "--exclude .git",
}, " ")

local normal_rg_files_opts = table.concat({
    "--color=never",
    "--files",
    "--hidden",
    "--follow",
    '-g "!.git"',
}, " ")

local normal_rg_grep_opts = table.concat({
    "--column",
    "--line-number",
    "--no-heading",
    "--color=always",
    "--smart-case",
    "--hidden",
    "--follow",
    "--max-columns=4096",
    '-g "!.git"',
    "-e",
}, " ")

-- =========================================================
-- Godot 项目参数
--
-- 只搜索：
--   *.gd
--   *.gdshader
--   *.gdshaderinc
-- =========================================================

local godot_fd_opts = table.concat({
    "--color=never",
    "--type f",
    "--type l",
    "--hidden",
    "--follow",

    "--exclude .git",
    "--exclude addons",

    "--extension gd",
    "--extension glsl",
    "--extension gdshader",
    "--extension gdshaderinc",
}, " ")

local godot_rg_files_opts = table.concat({
    "--color=never",
    "--files",
    "--hidden",
    "--follow",

	--屏蔽.git addons	
    '-g "!.git"',
    '-g "!addons"',

	--显示.git addons	
    '-g "*.gd"',
    '-g "*.glsl"',
    '-g "*.gdshader"',
    '-g "*.gdshaderinc"',
}, " ")

local godot_rg_grep_opts = table.concat({
    "--column",
    "--line-number",
    "--no-heading",
    "--color=always",
    "--smart-case",
    "--hidden",
    "--follow",
    "--max-columns=4096",

    '-g "!.git"',
    '-g "!.addons"',

    '-g "*.gd"',
    '-g "*.glsl"',
    '-g "*.gdshader"',
    '-g "*.gdshaderinc"',

    "-e",
}, " ")

-- =========================================================
-- Find Files
-- =========================================================

local function find_files()
    local fzf = require("fzf-lua")
    local root = get_godot_root()

    if root then
        fzf.files({
            cwd = root,

            fd_opts = godot_fd_opts,
            rg_opts = godot_rg_files_opts,

            multiprocess = false,
        })

        return
    end

    fzf.files({
        fd_opts = normal_fd_opts,
        rg_opts = normal_rg_files_opts,

        multiprocess = false,
    })
end

-- =========================================================
-- Live Grep
-- =========================================================

local function live_grep()
    local fzf = require("fzf-lua")
    local root = get_godot_root()

    if root then
        fzf.live_grep({
            cwd = root,
            rg_opts = godot_rg_grep_opts,

            multiprocess = false,
        })

        return
    end

    fzf.live_grep({
        rg_opts = normal_rg_grep_opts,

        multiprocess = false,
    })
end

-- =========================================================
-- Grep 当前光标下的单词
-- =========================================================

local function grep_cword()
    local fzf = require("fzf-lua")
    local root = get_godot_root()

    if root then
        fzf.grep_cword({
            cwd = root,
            rg_opts = godot_rg_grep_opts,

            multiprocess = false,
        })

        return
    end

    fzf.grep_cword({
        rg_opts = normal_rg_grep_opts,

        multiprocess = false,
    })
end

-- =========================================================
-- Plugin
-- =========================================================

return {
    "ibhagwan/fzf-lua",

    -- enabled = false,
    -- 不需要 telescope
    -- 不需要 telescope-fzf-native
    -- 不需要 telescope-zoxide
    -- 不需要 plenary
    dependencies = {},

    keys = {
        -- =====================================================
        -- 文件 / 文本
        -- =====================================================

        {
            "<leader>f",
            find_files,
            desc = "Find File",
        },

        {
            "<leader>j",
            live_grep,
            desc = "Search Text",
        },

        {
            "gR",
            grep_cword,
            desc = "Grep Word",
        },

        -- =====================================================
        -- Buffers
        -- =====================================================

        {
            "<leader>b",
            function()
                require("fzf-lua").buffers()
            end,
            desc = "List Buffers",
        },

        -- =====================================================
        -- LSP
        -- =====================================================

        {
            "gd",
            function()
                require("fzf-lua").lsp_definitions({
                    jump1 = false,
                })
            end,
            desc = "List Definitions",
        },

        {
            "<leader>o",
            function()
                require("fzf-lua").lsp_document_symbols()
            end,
            desc = "Document Symbols",
        },

        -- =====================================================
        -- Zoxide
        -- =====================================================

        {
            "<leader>z",
            function()
                require("fzf-lua").zoxide()
            end,
            desc = "Zoxide Jump",
        },

        -- =====================================================
        -- 恢复上一次 picker
        -- =====================================================

        {
            "<leader>F",
            function()
                require("fzf-lua").resume()
            end,
            desc = "Resume Search",
        },
    },

    config = function()
        require("fzf-lua").setup({

            -- 你的 fzf.exe 已经在 PATH 中
            fzf_bin = "fzf",

            -- 先不使用图标，排除 devicons/mini.icons 干扰
            file_icons = false,
            color_icons = false,

            -- =================================================
            -- UI
            -- =================================================

            fzf_opts = {
                ["--layout"] = "reverse",
            },

            winopts = {
                height = 0.85,
                width = 0.80,

                -- 真正居中
                row = 0.5,
                col = 0.5,

				backdrop = 100,

                preview = {
                    layout = "flex",

                    horizontal = "right:60%",
                    vertical = "down:45%",

                    flip_columns = 100,
                },
            },

            -- =================================================
            -- Files
            -- =================================================

            files = {
                -- raw_cmd = "fd --type f --hidden --follow --exclude .git",

                multiprocess = true,
                file_icons = false,
                color_icons = false,
                git_icons = false,
                formatter = "path.filename_first",
                -- previewer = false,

                fd_opts = normal_fd_opts,
                rg_opts = normal_rg_files_opts,

                file_ignore_patterns = {
                    "%.ttf$",
                    "%.png$",
                    "%.glb$",
                    "%.svg$",
                },
            },

            -- =================================================
            -- Grep
            -- =================================================

            grep = {
                multiprocess = false,
                rg_opts = normal_rg_grep_opts,
            },

            -- =================================================
            -- LSP
            -- =================================================

            lsp = {
                jump1 = false,
            },
        })
    end,
}
