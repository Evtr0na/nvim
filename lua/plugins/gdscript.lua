-- godotscript 的 LSP
--
-- 修 bug：Windows 无法打开场景树
--
-- 在 lua/godotdev/scene_tree.lua 找到：
--
-- if not path:match("^/") then
--     absolute = root .. "/" .. path
-- end
--
-- 改成：
--
-- if not path:match("^/") and not path:match("^%a:[/\\]") then
--     absolute = root .. "/" .. path
-- end

return {
    {
        "Mathijs-Bakker/godotdev.nvim",

        ft = {
            "gd",
            "gdscript",
        },

        dependencies = {
            "mfussenegger/nvim-dap",
            "rcarriga/nvim-dap-ui",
            "nvim-treesitter/nvim-treesitter",
        },

        opts = {
            ------------------------------------------------------------
            -- Godot
            ------------------------------------------------------------

            godot_path = "D:\\2zhuomian\\Projects\\GameDev\\Engines\\4.7.1-stable\\Godot471.exe",

            -- 这个必须保持 false。
            -- Godot -> Nvim 的 project-specific RPC pipe
            -- 由 godot_instance 自己管理。
            autostart_editor_server = false,

            ------------------------------------------------------------
            -- godotdev
            ------------------------------------------------------------

            csharp = false,
            formatter = false,

            inline_hints = {
                enabled = false,
            },

            scene_tree = {
                icons = false,

                buffer = {
                    position = "left",
                    size = 0.35,
                },
            },
        },

        config = function(_, opts)
            local instance =
                require("config.godot_instance")

            ------------------------------------------------------------
            -- 1.
            -- 必须在 godotdev.setup() 之前。
            --
            -- 这里会给“当前 Nvim”分配独立的：
            --
            -- LSP port
            -- DAP port
            --
            -- 所以不要再手写：
            --
            -- editor_port = 6005
            -- debug_port = 6006
            ------------------------------------------------------------

            opts =
                instance.godotdev_opts(opts)

            ------------------------------------------------------------
            -- 2.
            -- 正常初始化 godotdev
            ------------------------------------------------------------

            require("godotdev").setup(opts)

            ------------------------------------------------------------
            -- 3.
            -- 保留你自己的 gdscript filetype 限制
            ------------------------------------------------------------

            vim.lsp.config("gdscript", {
                filetypes = {
                    "gdscript",
                },
            })

            ------------------------------------------------------------
            -- 4.
            -- 必须在 godotdev.setup() 后执行。
            --
            -- 做三件事：
            --
            -- 1. 暂时关闭 godotdev 自动 enable 的 gdscript
            -- 2. 安装 active-project root_dir gate
            -- 3. 修正当前 godotdev 版本的动态 DAP port
            ------------------------------------------------------------

            instance.after_godotdev_setup({
                godot_path = opts.godot_path,
            })

            ------------------------------------------------------------
            -- 5.
            -- 快捷键
            ------------------------------------------------------------

            vim.keymap.set(
                "n",
                "<leader>gs",
                "<cmd>GodotSceneTree<cr>",
                {
                    desc = "Godot Scene Tree",
                }
            )

            ------------------------------------------------------------
            -- 注意：
            --
            -- 这里绝对不要再写：
            --
            -- vim.lsp.enable("gdscript")
            --
            -- LSP 会由 godot_instance 在：
            --
            --   :GodotHere
            --   :GodotProject
            --
            -- 成功启动对应 Godot Editor，
            -- 并确认 LSP port ready 后自动 enable。
            ------------------------------------------------------------
        end,
    },
}
