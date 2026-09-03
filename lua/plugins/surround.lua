return {
    "kylechui/nvim-surround",
    version = "*", -- 使用最新的稳定版
    event = {"VeryLazy"},
    config = function()
        require("nvim-surround").setup({})
    end,
}
