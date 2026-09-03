return {
    {
        "avante-corp/avante.nvim",

        event = "VeryLazy",

        tag = "v0.2.3",

        build = vim.fn.has("win32") ~= 0
                and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
            or "make",

        ---@module "avante"
        ---@type avante.Config
        opts = {
            ------------------------------------------------------------
            -- AI Provider
            ------------------------------------------------------------
            provider = "root_shell",

            providers = {
                root_shell = {
                    __inherited_from = "openai",

                    endpoint = "https://lee.root-shell.xyz/v1",

                    api_key_name = "ROOT_SHELL_API_KEY",

                    model = "deepseek-v4-flash",

                    timeout = 60000,

                    -- 第一阶段建议先关掉 tools
                    -- 先确认普通 Chat 能正常通信
                    disable_tools = true,
                },
            },

            ------------------------------------------------------------
            -- Avante 行为
            ------------------------------------------------------------
            behaviour = {
                auto_add_current_file = true,

                auto_suggestions = false,

                auto_apply_diff_after_generation = false,

                auto_approve_tool_permissions = false,

                enable_token_counting = true,
            },

            ------------------------------------------------------------
            -- 文件选择器
            ------------------------------------------------------------
            selector = {
                provider = "telescope",
            },

            ------------------------------------------------------------
            -- UI
            ------------------------------------------------------------
            windows = {
                position = "right",
                wrap = true,
                width = 35,

                input = {
                    prefix = "> ",
                    height = 8,
                },
            },
        },

        dependencies = {
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",

            "nvim-telescope/telescope.nvim",

            "nvim-tree/nvim-web-devicons",

            {
                "MeanderingProgrammer/render-markdown.nvim",

                opts = {
                    file_types = {
                        "markdown",
                        "Avante",
                    },
                },

                ft = {
                    "markdown",
                    "Avante",
                },
            },
        },
    },
}
