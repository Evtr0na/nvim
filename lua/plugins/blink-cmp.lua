return {
    {
        "saghen/blink.cmp",
        event = {
            "InsertEnter",
            "CmdlineEnter",
        }, -- 固定使用稳定的 v1
        version = "1.*",

        dependencies = {
            "rafamadriz/friendly-snippets",
            -- Avante 的 blink.cmp source
            -- "Kaiser-Yang/blink-cmp-avante",
        },

        ---@module "blink.cmp"
        ---@type blink.cmp.Config
        opts = {
            ------------------------------------------------------------
            -- 快捷键
            ------------------------------------------------------------
            keymap = {
                -- Enter 接受补全
                preset = "enter",

                -- 保持你原来 nvim-cmp 的操作习惯：
                --
                -- 补全菜单打开时：
                --   Tab     -> 下一项
                --   S-Tab   -> 上一项
                --
                -- snippet 激活时：
                --   Tab     -> 下一个参数
                --   S-Tab   -> 上一个参数
                --
                -- 都没有时：
                --   保持普通 Tab 行为
                ["<Tab>"] = {
                    "select_next",
                    "snippet_forward",
                    "fallback",
                },

                ["<S-Tab>"] = {
                    "select_prev",
                    "snippet_backward",
                    "fallback",
                },
            },
            cmdline = {
                keymap = {
                    preset = "cmdline",
                },

                completion = {
                    menu = {
                        auto_show = false,
                    },
                },
            },

            ------------------------------------------------------------
            -- 外观
            ------------------------------------------------------------
            appearance = {
                nerd_font_variant = "mono",
            },

            ------------------------------------------------------------
            -- 补全
            ------------------------------------------------------------
            completion = {
                --------------------------------------------------------
                -- 自动触发
                --------------------------------------------------------

                trigger = {
                    -- Blink 默认是：
                    --
                    -- { " ", "\n", "\t" }
                    --
                    -- 我们允许空格作为 trigger，
                    -- 这样 "shader_type " 可以立即触发 GDShader source。
                    show_on_blocked_trigger_characters = {
                        "\n",
                        "\t",
                    },
                },

                --------------------------------------------------------
                -- 选择行为
                --------------------------------------------------------

                list = {
                    selection = {
                        preselect = true,
                        auto_insert = false,
                    },
                },

                --------------------------------------------------------
                -- 菜单
                --------------------------------------------------------

                menu = {
                    border = "rounded",
                    -- auto_show = false,
                },

                --------------------------------------------------------
                -- 文档
                --------------------------------------------------------

                documentation = {
                    auto_show = true,
                    auto_show_delay_ms = 250,

                    window = {
                        border = "rounded",
                    },
                },
            },

            ------------------------------------------------------------
            -- 补全来源
            ------------------------------------------------------------
            sources = {

                --------------------------------------------------------
                -- 普通语言
                --------------------------------------------------------

                default = {
                    -- "avante",
                    "lsp",
                    "path",
                    "snippets",
                    "buffer",
                },

                --------------------------------------------------------
                -- GDShader
                --------------------------------------------------------

                per_filetype = {
                    gdshader = {
                        "gdshader",
                        "path",
                        "snippets",
                        "buffer",
                    },

                    gdshaderinc = {
                        "gdshader",
                        "path",
                        "snippets",
                        "buffer",
                    },
                },

                --------------------------------------------------------
                -- 自定义 provider
                --------------------------------------------------------

                providers = {

                    -- avante = {
                    --     module = "blink-cmp-avante",
                    --     name = "Avante",
                    -- },

                    gdshader = {
                        name = "GDShader",
                        module = "gdshader_nvim",

                        enabled = function()
                            local line = vim.api.nvim_get_current_line()

                            -- 整行为空，或者只有空格/tab
                            if line:match("^%s*$") then
                                return false
                            end

                            return true
                        end,
                    },
                },
            },

            ------------------------------------------------------------
            -- Fuzzy matcher
            ------------------------------------------------------------
            fuzzy = {
                -- 优先使用 Blink 的 Rust matcher
                -- Windows 会自动下载对应的预编译版本
                implementation = "prefer_rust_with_warning",
            },
        },

        opts_extend = {
            "sources.default",
        },
    },
}
