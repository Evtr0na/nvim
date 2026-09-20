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

            -- 必须保持 false。
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
            local instance = require("config.godot_instance")

            ------------------------------------------------------------
            -- 1. 在 godotdev.setup() 之前分配当前 Nvim 独立的端口。
            ------------------------------------------------------------

            opts = instance.godotdev_opts(opts)

            ------------------------------------------------------------
            -- 2. godotdev.nvim 当前版本会在 setup() 内立刻执行：
            --
            --      vim.lsp.enable("gdscript")
            --
            -- 这时 Godot 往往还没把 LSP TCP port 启起来，Windows 下
            -- ncat 会先连接失败并留下：
            --
            --      Client gdscript quit with exit code 1
            --
            -- 这里只拦截 setup() 内这一次“过早 enable”。setup 返回后
            -- 立即恢复原函数。真正的 enable 由 godot_instance 在确认
            -- Godot LSP port 已经可连接后执行。
            ------------------------------------------------------------

            local original_lsp_enable = vim.lsp.enable

            vim.lsp.enable = function(name, enable)
                if name == "gdscript" and enable ~= false then
                    return {}
                end

                return original_lsp_enable(name, enable)
            end

            local ok, setup_error = xpcall(function()
                require("godotdev").setup(opts)
            end, debug.traceback)

            -- 无论 setup 成功还是失败都必须恢复，不能污染其它 LSP。
            vim.lsp.enable = original_lsp_enable

            if not ok then
                error(setup_error)
            end

            ------------------------------------------------------------
            -- 3. 保留你自己的 gdscript filetype 限制。
            ------------------------------------------------------------

            vim.lsp.config("gdscript", {
                filetypes = {
                    "gdscript",
                },
            })

            ------------------------------------------------------------
            -- 4. setup 后交还给实例管理器。
            --
            -- godot_instance 会：
            --   1. 保持 gdscript disabled，直到端口 ready
            --   2. 安装 active-project root_dir gate
            --   3. 修正动态 DAP port
            --   4. 禁掉 godotdev 自己的通用 editor-server 自动层
            ------------------------------------------------------------

            instance.after_godotdev_setup({
                godot_path = opts.godot_path,
            })

            ------------------------------------------------------------
            -- 5. 快捷键
            ------------------------------------------------------------

            vim.keymap.set(
                "n",
                "<leader>gs",
                "<cmd>GodotSceneTree<cr>",
                {
                    desc = "Godot Scene Tree",
                }
            )

            -- 注意：这里不要再写 vim.lsp.enable("gdscript")。
        end,
    },
}
