return {
    "kylechui/nvim-surround",
    version = "*", -- 使用最新的稳定版
    keys = {
        { "<C-g>s", mode = "i" },
        { "<C-g>S", mode = "i" },

        { "ys", mode = "n" },
        { "yss", mode = "n" },
        { "yS", mode = "n" },
        { "ySS", mode = "n" },

        { "ds", mode = "n" },
        { "cs", mode = "n" },
        { "cS", mode = "n" },

        { "S", mode = "x" },
        { "gS", mode = "x" },
    },
    config = function()
        require("nvim-surround").setup({})
    end,
}
