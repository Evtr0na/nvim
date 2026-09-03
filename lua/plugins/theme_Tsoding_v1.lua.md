return {
    "xLeapProtocol/ring0-dark.nvim",
    lazy = false,
    enable = false,
    -- priority = 1000,
    config = function()
        local ok, ring0dark = pcall(require, "ring0dark")
        if not ok then
            vim.notify("ring0dark not loaded", vim.log.levels.ERROR)
            return
        end

        -- 先应用主题
        ring0dark.setup()
        vim.cmd([[colorscheme ring0dark]])

        -- 然后覆盖自定义高亮（主题加载后应用才会生效）
        local color_status = "#252525"
        local highlights = {
            -- 行号设置 (fg: 文字颜色, bg: 背景颜色)
            LineNr = { fg = "#616161", bg = "NONE" },
            CursorLineNr = { bg = "NONE" },
            -- 其他区域设置 (需要时取消注释)
            SignColumn = { bg = "NONE" },
            StatusLine = { bg = color_status },
            StatusLineNC = { bg = color_status },

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
}
