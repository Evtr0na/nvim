--主题
return {
    {
        "catppuccin/nvim",
        lazy = true,
        name = "catppuccin",
        -- priority = 1000,
        config = function()
            require("catppuccin").setup({})
            -- vim.cmd("colorscheme catppuccin")
            vim.cmd.hi("Statusline guibg=NONE")
            vim.cmd.hi("Comment gui=none")
        end,
    },
    -- 这里可以继续写其他插件
}
