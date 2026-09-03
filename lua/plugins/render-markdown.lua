-- lua/plugins/render-markdown.lua

return {
    {
        "MeanderingProgrammer/render-markdown.nvim",

        -- 只在 Markdown 文件中加载
        ft = { "markdown" },

        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            -- "nvim-tree/nvim-web-devicons",
        },

        keys = {
            {
                "<leader>mr",
                "<cmd>RenderMarkdown toggle<cr>",
                desc = "Markdown: Toggle Render",
                ft = "markdown",
            },
            {
                "<leader>mp",
                "<cmd>RenderMarkdown preview<cr>",
                desc = "Markdown: Preview",
                ft = "markdown",
            },
        },

        ---@module "render-markdown"
        ---@type render.md.UserConfig
        opts = {
            ------------------------------------------------------------
            -- 基础
            ------------------------------------------------------------
            enabled = true,

            -- Normal 模式显示渲染结果
            -- Insert 模式自动显示原始 Markdown，方便编辑
            render_modes = { "n", "c", "t" },

            ------------------------------------------------------------
            -- blink.cmp
            ------------------------------------------------------------
            -- render-markdown 官方目前推荐使用内置 LSP completion，
            -- 可以直接和 blink.cmp 配合
            completions = {
                lsp = {
                    enabled = true,
                },
            },

            ------------------------------------------------------------
            -- 标题
            ------------------------------------------------------------
            heading = {
                enabled = true,

                -- 不占用 signcolumn
                sign = false,

                -- # 替换成图标
                position = "inline",

                -- 标题背景只包住文字，不铺满整行
                width = "block",

                left_pad = 1,
                right_pad = 1,
            },

            ------------------------------------------------------------
            -- Code Block
            ------------------------------------------------------------
            code = {
                enabled = true,

                sign = false,

                -- ```lua 代码块背景
                width = "block",

                -- 稍微留一点空间
                left_pad = 1,
                right_pad = 1,

                -- 上下边框
                border = "thin",

                -- 显示语言图标和名字
                language = true,
                language_icon = true,
                language_name = true,
            },

            ------------------------------------------------------------
            -- Markdown Table
            ------------------------------------------------------------
            pipe_table = {
                enabled = true,

                -- 圆角表格
                preset = "round",
            },

            ------------------------------------------------------------
            -- Checkbox
            ------------------------------------------------------------
            checkbox = {
                enabled = true,
                unchecked = {
                    icon = "󰄱 ",
                },
                checked = {
                    icon = "󰱒 ",
                },
            },

            ------------------------------------------------------------
            -- List
            ------------------------------------------------------------
            bullet = {
                enabled = true,
                icons = {
                    "●",
                    "○",
                    "◆",
                    "◇",
                },
            },

            ------------------------------------------------------------
            -- LaTeX
            ------------------------------------------------------------
            -- 你现在主要是普通 Markdown 的话先关闭。
            -- 以后需要数学公式再打开并安装 latex parser。
            latex = {
                enabled = false,
            },
        },
    },
}
