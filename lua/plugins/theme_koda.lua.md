return {
    "oskarnurm/koda.nvim",
    lazy = false,
	enable = false,
    -- priority = 1000,

    config = function()
        require("koda").setup({
            colors = {
                func = "#d6d6d6",
                string = "#d6d6d6",
                char = "#d6d6d6",
                special = "#d6d6d6",
                emphasis = "#d6d6d6",
            },
        })

        vim.cmd.colorscheme("koda-dark")
    end,
}
