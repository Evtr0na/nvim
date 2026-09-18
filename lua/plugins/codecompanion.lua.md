return {
    "olimorris/codecompanion.nvim",
	enabled = false,
    -- 你现在这里是 false，一定要改成 true

    cmd = {
        "CodeCompanionChat",
    },

    dependencies = {
        "nvim-lua/plenary.nvim",
    },

    keys = {
        -- 新开一个 DSH Chat
        {
            "<leader>ao",
            "<cmd>CodeCompanionChat adapter=dsh<cr>",
            mode = { "n", "v" },
            desc = "DSH Agent",
        },

        -- 显示/隐藏当前 Chat
        {
            "<leader>ac",
            "<cmd>CodeCompanionChat Toggle<cr>",
            mode = { "n", "v" },
            desc = "Toggle DSH Chat",
        },

        -- 把选中的代码加入当前 Chat
        {
            "<leader>ad",
            "<cmd>CodeCompanionChat Add<cr>",
            mode = "v",
            desc = "Add Selection to DSH",
        },
    },

    opts = {
        adapters = {
            acp = {
                dsh = function()
                    local helpers =
                        require("codecompanion.adapters.acp.helpers")

                    local command

                    if vim.fn.has("win32") == 1 then
                        -- Windows:
                        -- npm 安装的 dsh 一般实际是 dsh.cmd，
                        -- 因此通过 cmd.exe 启动最稳。
                        command = {
                            vim.env.COMSPEC or "cmd.exe",
                            "/d",
                            "/s",
                            "/c",
                            "dsh --profile acp",
                        }
                    else
                        command = {
                            "dsh",
                            "--profile",
                            "acp",
                        }
                    end

                    return {
                        name = "dsh",
                        formatted_name = "DeepSeek Harness",
                        type = "acp",

                        roles = {
                            llm = "assistant",
                            user = "user",
                        },

                        commands = {
                            default = command,
                        },

                        defaults = {
                            mcpServers = {},
                            timeout = 20000,
                        },

                        parameters = {
                            protocolVersion = 1,

                            clientCapabilities = {
                                fs = {
                                    readTextFile = true,
                                    writeTextFile = true,
                                },
                            },

                            clientInfo = {
                                name = "CodeCompanion.nvim",
                                version = "1.0.0",
                            },
                        },

                        handlers = {
                            setup = function(self)
                                return true
                            end,

                            -- DSH ACP 本身不要求客户端认证
                            auth = function(self)
                                return true
                            end,

                            form_messages = function(
                                self,
                                messages,
                                capabilities
                            )
                                return helpers.form_messages(
                                    self,
                                    messages,
                                    capabilities
                                )
                            end,

                            on_exit = function(self, code)
                            end,
                        },
                    }
                end,
            },
        },

        interactions = {
            -- 唯一使用的 interaction
            chat = {
                adapter = "dsh",
            },
        },

        opts = {
            -- 调试时可以改成 DEBUG
            log_level = "ERROR",
        },
    },
}
