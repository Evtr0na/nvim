--godotscript的lsp
--
--修bug：win无法打开场景树
--
--在lua/godotdev/scene_tree.lua找到:
--if not path:match("^/") then
--   absolute = root .. "/" .. path
-- end
-- 改成：
--if not path:match("^/") and not path:match("^%a:[/\\]") then
--   absolute = root .. "/" .. path
-- end
--
--
return {
    {
        "Mathijs-Bakker/godotdev.nvim",
        -- enabled = false,
        ft = { "gd", "gdshader", "gdscript" },
        dependencies = {
            "mfussenegger/nvim-dap",
            "rcarriga/nvim-dap-ui",
            "nvim-treesitter/nvim-treesitter",
        },
        config = function()
            require("godotdev").setup({
                editor_host = "127.0.0.1",
                editor_port = 6005,
                godot_path = "D:\\2zhuomian\\Projects\\GameDev\\Engines\\4.7.1-stable\\Godot471.exe",

                csharp = false,
                autostart_editor_server = false,
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

                -- 文件树快捷键
                vim.keymap.set("n", "<leader>gs", "<cmd>GodotSceneTree<cr>", {
                    desc = "Godot Scene Tree",
                }),
            })

            vim.lsp.config("gdscript", {

                filetypes = {
                    "gdscript",
                },
            })

            vim.lsp.enable("gdscript")
        end,
    },
}
