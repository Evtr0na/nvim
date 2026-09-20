-- Godot 多开 + Godot LSP
--
-- 逻辑全部在插件 godot-instance.nvim 里：
--   复用优先（已经在跑的 Godot 直接挂上去）/ 托管实例保活 / 端口分配 /
--   项目专属 RPC 管道 / 优雅关闭。
--
-- 这里只剩两件事：
--   1. 插件本体
--   2. godotdev 的偏好设置（setup 由插件接管）


local GODOT_PATH = "D:/2zhuomian/Projects/GameDev/Engines/4.7.1-stable/Godot471.exe"

return {
    ------------------------------------------------------------
    -- Godot 实例管理器（Nvim 多开 + Godot 多开）
    ------------------------------------------------------------
    {
        dir = "D:/2zhuomian/app/source/godot-instance.nvim",

        -- 启动时就加载：VimEnter 的自动绑定必须在启动阶段注册好。
        -- 插件本身很便宜（纯 Lua，~2ms），godotdev 依然是按需加载的。
        lazy = false,

        opts = {
            godot_path = GODOT_PATH,
        },

        config = function(_, opts)
            require("godot-instance").setup(opts)
        end,
    },

    ------------------------------------------------------------
    -- godotdev.nvim（gdscript LSP 本体）
    ------------------------------------------------------------
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
            godot_path = GODOT_PATH,

            -- 必须保持 false：Godot -> Nvim 的 project-specific RPC pipe
            -- 由 godot-instance 自己管理。
            autostart_editor_server = false,

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

        -- 交给插件接管：端口注入 / 拦掉 godotdev 那次过早的
        -- vim.lsp.enable("gdscript") / DAP 端口 / 禁掉 godotdev 自带的
        -- 通用 editor-server 自动层。
        config = function(_, opts)
            require("godot-instance").godotdev(opts)

            vim.keymap.set("n", "<leader>gs", "<cmd>GodotSceneTree<cr>", {
                desc = "Godot Scene Tree",
            })
        end,
    },
}
