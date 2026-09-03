return {
    {
        "blazkowolf/gruber-darker.nvim",
        lazy = false,
        priority = 1000,

        opts = {
            bold = true,

            italic = {
                strings = false,
                comments = false,
                operators = false,
                folds = false,
            },
        },

        config = function(_, opts)
            require("gruber-darker").setup(opts)
            vim.cmd.colorscheme("gruber-darker")

            local highlights = {
                -- 行号设置 (fg: 文字颜色, bg: 背景颜色)
                LineNr = { fg = "#616161", bg = "NONE" },
                CursorLineNr = { bg = "NONE" },
                -- 其他区域设置 (需要时取消注释)
                SignColumn = { bg = "NONE" },

                ----------------------------------------
                -- Ufo color
                ----------------------------------------

                -- 真正的 Neovim 折叠行背景
                Folded = {
                    bg = "#181818",
                },
                --
                -- UFO 普通折叠行
                UfoFoldedBg = {
                    bg = "#181818",
                },
            }

            -- 应用自定义高亮
            for group, opts in pairs(highlights) do
                vim.api.nvim_set_hl(0, group, opts)
            end

            -- 延迟再次应用，确保覆盖主题设置
            vim.schedule(function()
                for group, opts in pairs(highlights) do
                    vim.api.nvim_set_hl(0, group, opts)
                end
            end)
        end,
    },
}
