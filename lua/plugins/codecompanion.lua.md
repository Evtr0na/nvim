-- setx DEEPSEEK_API_KEY "你的API_KEY"
return {
    "olimorris/codecompanion.nvim",

    -- 固定版本，避免以后更新突然出现 breaking change
    tag = "v19.21.0",

    -- lazy = true,
    -- event = "VeryLazy",

    cmd = {
        "CodeCompanion",
        "CodeCompanionChat",
        "CodeCompanionCmd",
        "CodeCompanionActions",
        "CodeCompanionCLI",
    },

    dependencies = {
        "nvim-lua/plenary.nvim",
    },

    keys = {
        {
            "<leader>ao",
            "<cmd>CodeCompanionChat adapter=opencode<cr>",
            mode = { "n", "v" },
            desc = "OpenCode Agent",
        },
        -- {
        --     "<leader>ao",
        --     "<cmd>CodeCompanionCLI<cr>",
        --     desc = "OpenCode",
        -- },
        {
            "<leader>aa",
            "<cmd>CodeCompanionActions<cr>",
            mode = { "n", "v" },
            desc = "AI Actions",
        },
        {
            "<leader>ac",
            "<cmd>CodeCompanionChat Toggle<cr>",
            mode = { "n", "v" },
            desc = "AI Chat",
        },
        {
            "<leader>ad",
            "<cmd>CodeCompanionChat Add<cr>",
            mode = "v",
            desc = "Add Selection to AI Chat",
        },
        {
            "<leader>ai",
            "<cmd>CodeCompanion<cr>",
            mode = "v",
            desc = "AI Inline Edit",
        },
    },

    opts = {
        adapters = {
            http = {
                root_deepseek = function()
                    return require("codecompanion.adapters").extend("deepseek", {
                        name = "root_deepseek",
                        formatted_name = "DeepSeek V4 Flash",

                        -- 你的中转地址
                        url = "https://lee.root-shell.xyz/v1/chat/completions",

                        env = {
                            -- 这里只写环境变量名，不写真实 API Key
                            api_key = "DEEPSEEK_API_KEY",
                        },

                        schema = {
                            model = {
                                default = "deepseek-v4-flash",
                            },
                        },
                    })
                end,
            },
        },

        interactions = {
            chat = {
                adapter = {
                    name = "root_deepseek",
                    model = "deepseek-v4-flash",
                },
            },

            inline = {
                adapter = {
                    name = "root_deepseek",
                    model = "deepseek-v4-flash",
                },
            },

            cmd = {
                adapter = {
                    name = "root_deepseek",
                    model = "deepseek-v4-flash",
                },
            },
            -- cli = {
            --     agent = "opencode",
            --
            --     agents = {
            --         opencode = {
            --             cmd = "opencode",
            --             args = {},
            --             description = "OpenCode CLI",
            --             provider = "terminal",
            --         },
            --     },
            -- },
        },

        opts = {
            log_level = "ERROR",
        },
    },
}
