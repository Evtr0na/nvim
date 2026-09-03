return {
    "voylin/godot_color_theme",
    -- priority = 1000,
    lazy = true,
    config = function()
        -- 1. 启动 Godot 主题
        -- vim.cmd.colorscheme("godot")

        -- 2. 统一管理所有的高亮覆盖设置
        local highlights = {

            -- 行号设置 (fg: 文字颜色, bg: 背景颜色)
            LineNr = { fg = "#7f8c8d", bg = "NONE" },
            CursorLineNr = { fg = "#f1c40f", bg = "NONE", bold = true },

            -- 其他区域设置 (需要时取消注释)
            -- SignColumn = { bg = "NONE" },
            -- StatusLine = { bg = "NONE" },
            -- StatusLineNC = { bg = "NONE" },
        }

        -- 3. 循环应用配置
        for group, opts in pairs(highlights) do
            vim.api.nvim_set_hl(0, group, opts)
        end
    end,
}
