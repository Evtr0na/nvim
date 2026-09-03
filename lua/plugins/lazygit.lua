return {
    "kdheepak/lazygit.nvim",

    cmd = {
        "LazyGit",
        "LazyGitConfig",
        "LazyGitCurrentFile",
        "LazyGitFilter",
        "LazyGitFilterCurrentFile",
    },

    dependencies = {
        "nvim-lua/plenary.nvim",
    },

    init = function()
        vim.g.lazygit_floating_window_winblend = 0
        vim.g.lazygit_floating_window_scaling_factor = 0.95

        vim.g.lazygit_floating_window_border_chars = {
            "─",
            "│",
            "─",
            "│",
            "╭",
            "╮",
            "╯",
            "╰",
        }

        vim.g.lazygit_floating_window_use_plenary = 1
    end,

    keys = {
        {
            "<leader>gg",
            "<cmd>LazyGitCurrentFile<cr>",
            desc = "Lazygit",
        },
        {
            "<leader>gf",
            "<cmd>LazyGitFilterCurrentFile<cr>",
            desc = "Git history current file",
        },
    },
}
