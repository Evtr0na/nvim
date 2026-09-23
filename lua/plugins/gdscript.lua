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
		-- "Evtr0na/godot-instance.nvim"
        dir = "D:/2zhuomian/app/source/godot-instance.nvim",

        -- 启动时就加载：VimEnter 的自动绑定必须在启动阶段注册好。
        -- 插件本身很便宜（纯 Lua，~2ms），godotdev 依然是按需加载的。
        lazy = false,

        opts = {
            godot_path = GODOT_PATH,

            ------------------------------------------------------------
            -- 调试日志：Godot 编辑器里按 F5/F6 的报错
            ------------------------------------------------------------
            -- 编辑器启动的游戏，stdout 被编辑器吞掉，Nvim 看不到。Godot 桌面
            -- 平台默认会把游戏输出写进 user://logs/godot.log，插件 tail 它，
            -- 并把报错解析成真正的 vim.diagnostic —— 于是 Trouble / 跳转 /
            -- 行号符号全都直接可用。实现见 godot-instance/debuglog.lua。
            debuglog = {
                -- 插件默认不占键位，这里显式指定（和下面的 <leader>g* 一套）
                keymap = "<leader>gD",        -- 开关调试日志面板
                -- keymap_errors = "<leader>gQ", -- 报错列表（Trouble 优先，quickfix 兜底）
            },
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

            -- 实时控制台：把 Godot 的 stdout/stderr 抓进 Neovim。
            --
            -- 用 :GodotRunProject / :GodotRunCurrentScene 从 Neovim 启动游戏后，
            -- GDScript 运行时错误、push_error/push_warning、堆栈回溯会逐行
            -- 实时追加到 godotdev://console 这个 buffer（底部 30% 分屏）。
            --
            -- 代价（官方 README 也点明了）：开启后 :GodotRun* 不再是 detached
            -- 启动，游戏进程由 Neovim 托管 —— 退出 Neovim 会连带结束游戏。
            run = {
                console = {
                    enabled = true,
                    renderer = "buffer",
                    buffer = {
                        position = "bottom",
                        size = 0.3,
                    },
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

            ------------------------------------------------------------
            -- 运行 + 实时控制台
            ------------------------------------------------------------
            -- 从 Neovim 启动的游戏才会被控制台捕获（因为 Neovim 是父进程）。
            vim.keymap.set("n", "<leader>gr", "<cmd>GodotRunProject<cr>", {
                desc = "Godot: Run Project（输出进控制台）",
            })

            vim.keymap.set("n", "<leader>gR", "<cmd>GodotRunCurrentScene<cr>", {
                desc = "Godot: Run Current Scene（输出进控制台）",
            })

            -- 控制台 buffer 被关掉后用它重新调出来，不会重新启动游戏。
            vim.keymap.set("n", "<leader>gl", "<cmd>GodotShowConsole<cr>", {
                desc = "Godot: Show Run Console",
            })

            ------------------------------------------------------------
            -- DAP 调试
            ------------------------------------------------------------
            -- godotdev 只注册 adapter/configuration，刻意不带快捷键，
            -- 所以这里补一套最小的，否则 nvim-dap 根本没法从界面启动。
            -- 断点命中时 dap-ui 会显示堆栈/变量，报错也走同一条通道。
            vim.keymap.set("n", "<leader>gd", "<cmd>DapContinue<cr>", {
                desc = "Godot: DAP 启动/继续",
            })

            vim.keymap.set("n", "<leader>gb", "<cmd>DapToggleBreakpoint<cr>", {
                desc = "Godot: DAP 切换断点",
            })

            vim.keymap.set("n", "<leader>gi", "<cmd>DapStepInto<cr>", {
                desc = "Godot: DAP 单步进入",
            })

            vim.keymap.set("n", "<leader>go", "<cmd>DapStepOver<cr>", {
                desc = "Godot: DAP 单步跳过",
            })

            vim.keymap.set("n", "<leader>gu", function()
                require("dapui").toggle()
            end, { desc = "Godot: DAP UI 开关" })

            vim.keymap.set("n", "<leader>gt", "<cmd>DapTerminate<cr>", {
                desc = "Godot: DAP 结束会话",
            })
        end,
    },
}
