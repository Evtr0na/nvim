-- lua/plugins/todo.lua
return {
    -- {
    "folke/todo-comments.nvim",
    event = "BufReadPre",
    opts = {},
    -- },
    -- {
    --     "folke/trouble.nvim",
    --     opts = {},
    --     dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
        { "<leader>sT", "<cmd>Trouble todo toggle filter.buf=0<cr>" },
        { "<leader>st", "<cmd>Trouble todo toggle<cr>" },
    },
    -- },
}
