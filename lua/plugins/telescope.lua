--模糊搜索，

local function get_godot_root()
    local bufname = vim.api.nvim_buf_get_name(0)
    local start = bufname ~= "" and bufname or vim.fn.getcwd()

    return vim.fs.root(start, "project.godot")
end

local function godot_globs()
-- 在godot 项目中仅能搜索到
    return {
        "*.glsl",
        "*.gd",
        "*.gdshader",
        "*.gdshaderinc",
    }
end

return {
    "nvim-telescope/telescope.nvim",

    keys = {
        {
            "<leader>f",

            function()
                local builtin = require("telescope.builtin")
                local root = get_godot_root()

                if root then
                    -- Godot 项目：只搜索脚本和 shader
                    if vim.fn.executable("fd") == 1 then
                        builtin.find_files({
                            cwd = root,
                            find_command = {
                                "fd",
                                "--type",
                                "f",
                                "--hidden",
                                "--follow",

                                "--extension",
                                "gd",

                                "--extension",
                                "gdshader",

                                "--extension",
                                "gdshaderinc",
                            },
                        })
                    else
                        -- 没有 fd 时用 rg
                        builtin.find_files({
                            cwd = root,
                            find_command = {
                                "rg",
                                "--files",
                                "--hidden",
                                "--follow",
                                "--glob",
                                "*.gd",
                                "--glob",
                                "*.gdshader",
                                "--glob",
                                "*.gdshaderinc",
                            },
                        })
                    end

                    return
                end

                -- 普通项目
                builtin.find_files()
            end,

            desc = "Find File",
        },

        {
            "<leader>j",
            function()
                local builtin = require("telescope.builtin")
                local root = get_godot_root()

                if root then
                    builtin.live_grep({
                        cwd = root,
                        glob_pattern = godot_globs(),
                    })
                    return
                end

                builtin.live_grep()
            end,
            desc = "Search Text",
        },

        {
            "<leader>b",
            "<cmd>Telescope buffers<cr>",
            desc = "List Buffers",
        },

        {
            "gR",
            function()
                local builtin = require("telescope.builtin")
                local root = get_godot_root()

                if root then
                    builtin.grep_string({
                        cwd = root,
                        additional_args = function()
                            return {
                                "--glob",
                                "*.gd",
                                "--glob",
                                "*.gdshader",
                                "--glob",
                                "*.gdshaderinc",
                            }
                        end,
                    })
                    return
                end

                builtin.grep_string()
            end,
            desc = "Grep String",
        },

        { "<leader>b", "<cmd>Telescope buffers<cr>", desc = "List Buffers" },
        -- { "<leader>h", "<cmd>Telescope help_tags<cr>", desc = "Help Tags" },
        { "gr", "<cmd>Telescope lsp_references<cr>", desc = "lise reference" },
        { "gR", "<cmd>Telescope grep_string<cr>", desc = "lise reference" },

        { "gd", "<cmd>Telescope lsp_definitions<cr>", desc = "lise reference" },
        { "<leader>o", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Document Symbols" },
        -- 针对扩展扩展（Zoxide）的懒加载函数写法
        {
            "<leader>z",
            function()
                require("telescope").extensions.zoxide.list()
            end,
            desc = "Zoxide jump",
        },
    },
    dependencies = {
        "nvim-lua/plenary.nvim",

        -- fzf 原生排序器（已手动构建，此处保留 build 以便日后更新）
        {
            "nvim-telescope/telescope-fzf-native.nvim",
            build = vim.fn.has("win32") == 1 and "mingw32-make" or "make",
        },

        -- zoxide 智能目录跳转
        "jvgrootveld/telescope-zoxide",
    },

    opts = function()
        local find_command

        if vim.fn.executable("fd") == 1 then
            find_command = {
                "fd",
                "--type",
                "f",
                "--hidden",
                "--follow",
            }
        end

        return {
            defaults = {
                file_ignore_patterns = {
                    -- ".git",
                    --
                    -- "vimdow",
                    -- "addons",
                    --
                    -- "%.uid$",
                    -- "%.scn$",
                    -- "%.Object",
                    -- "%.md5",
                    -- "%.res$",
                    -- "%.cache$",
                    -- "%.cfg$",
                    "%.ttf$",
                    "%.png$",
                    "%.glb$",
                    -- "%.import$",
                    -- "%.tmp$",
                    -- "%.tscn$",
                    -- "%.import$",
                    "%.svg$",
                    -- "%.editorconfig$",
                },

                path_display = { "smart" },

                vimgrep_arguments = {
                    "rg",
                    "--follow",
                    "--hidden",
                    "--no-heading",
                    "--with-filename",
                    "--line-number",
                    "--column",
                    "--smart-case",
                },
            },

            pickers = {
                find_files = {
                    find_command = find_command,
                },
            },

            extensions = {
                fzf = {
                    fuzzy = true,
                    override_generic_sorter = true,
                    override_file_sorter = true,
                    case_mode = "smart_case",
                },

                zoxide = {
                    prompt_title = "[ Zoxide ]",
                    score = true,
                },
            },
        }
    end,
    config = function(_, opts)
        require("telescope").setup(opts)

        -- 直接加载 fzf 扩展（无需检查 fzf 命令，因为扩展本身不依赖它）
        require("telescope").load_extension("fzf")

        -- 加载 zoxide 扩展
        require("telescope").load_extension("zoxide")

        --  快捷键已移除（按你的要求，不配置）
        -- 如果你以后想添加，可以在这里自行添加 vim.keymap.set(...)
    end,
}
