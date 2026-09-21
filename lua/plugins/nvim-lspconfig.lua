return {
    {
        "neovim/nvim-lspconfig",

        event = {
            "BufReadPre",
            "BufNewFile",
        },
        config = function()

            ------------------------------------------------------------
            -- GLSL
            ------------------------------------------------------------
            vim.lsp.config("glsl_analyzer", {

                filetypes = { "glsl" },

                root_markers = {
                    "project.godot",
                    ".git",
                },
            })

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
        end,
    },
}
