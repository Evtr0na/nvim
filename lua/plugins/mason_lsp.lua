return {
    {
        "neovim/nvim-lspconfig",

        event = {
            "BufReadPre",
            "BufNewFile",
        },

        dependencies = {
            ------------------------------------------------------------
            -- Blink
            ------------------------------------------------------------
            -- 确保 Blink 在 LSP 之前加载
            "saghen/blink.cmp",

            ------------------------------------------------------------
            -- Mason
            ------------------------------------------------------------
            {
                "mason-org/mason.nvim",

                build = ":MasonUpdate",

                opts = {
                    ui = {
                        border = "rounded",
                    },
                },
            },

            ------------------------------------------------------------
            -- Mason <-> LSP bridge
            ------------------------------------------------------------
            -- 这里不要写 opts = {}
            -- 我们下面自己 setup，一次就够了
            "mason-org/mason-lspconfig.nvim",
        },

        config = function()
            ------------------------------------------------------------
            -- gdshader_lsp
            ------------------------------------------------------------

            -- Neovim 原生认识 .gdshader，
            -- 但目前没有内置 .gdshaderinc 映射，
            -- 所以让 include 文件也使用 gdshader filetype。
            -- vim.filetype.add({
            --     extension = {
            --         gdshaderinc = "gdshader",
            --     },
            -- })
            --
            -- vim.lsp.config("gdshader_lsp", {
            --     cmd = {
            --         "D:/2zhuomian/app/neovim-tool/gdscript-fotmatter/gdshader_lsp_release_windows.exe",
            --         "--stdio",
            --     },
            --
            --     filetypes = {
            --         "gdshader",
            --     },
            --
            --     root_markers = {
            --         "project.godot",
            --         ".git",
            --     },
            --
                -- Blink 的 LSP completion capabilities
                -- capabilities = require("blink.cmp").get_lsp_capabilities(),
            -- })

            -- vim.lsp.enable("gdshader_lsp")

            ------------------------------------------------------------
            -- lua_ls
            ------------------------------------------------------------
            vim.lsp.config("lua_ls", {
                -- 关闭 lua_ls 的颜色显示
                on_attach = function(client, bufnr)
                    client.server_capabilities.colorProvider = false
                end,

                settings = {
                    Lua = {
                        runtime = {
                            version = "LuaJIT",
                        },

                        diagnostics = {
                            globals = {
                                "vim",
                            },
                        },

                        workspace = {
                            checkThirdParty = false,

                            library = vim.api.nvim_get_runtime_file("", true),
                        },

                        telemetry = {
                            enable = false,
                        },
                    },
                },
            })

            ------------------------------------------------------------
            -- Mason LSP
            ------------------------------------------------------------
            require("mason-lspconfig").setup({
                -- Mason 安装的 LSP 默认自动 enable
                --
                -- 但排除 ast_grep
                automatic_enable = {
                    exclude = {
                        "ast_grep",
                    },
                },
            })
        end,
    },
}
