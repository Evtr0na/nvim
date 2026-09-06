return {
    {
        "mason-org/mason.nvim",

        cmd = {
            "Mason",
            "MasonInstall",
            "MasonUninstall",
            "MasonUpdate",
            "MasonLog",
        },

        opts = {
            ui = {
                border = "rounded",
            },
        },
    },

    {
        "mason-org/mason-lspconfig.nvim",

        event = "VeryLazy",

        dependencies = {
            "mason-org/mason.nvim",
            "neovim/nvim-lspconfig",
        },

        opts = {
            automatic_enable = {
                exclude = {
                    "ast_grep",
                },
            },
        },
    },
}
