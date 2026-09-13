return {
    "chentoast/marks.nvim",
    event = "VeryLazy",

    opts = {
        default_mappings = false,


        cyclic = true,
        force_write_shada = false,
        refresh_interval = 250,

        sign_priority = {
            lower = 10,
            upper = 15,
            builtin = 8,
            bookmark = 20,
        },

        excluded_filetypes = {
            "neo-tree",
            "NvimTree",
            "TelescopePrompt",
            "lazy",
            "mason",
        },

        excluded_buftypes = {
            "nofile",
            "terminal",
            "prompt",
        },

        mappings = {
            set_next = "m,",
            toggle = "m;",

            delete_line = "dm-",
            delete_buf = "dm<Space>",

            next = "]m",
            prev = "[m",

            preview = "m:",
            set = "m",
            delete = "dm",
        },
    },

    config = function(_, opts)
        vim.opt.signcolumn = "yes"
        require("marks").setup(opts)

        -- mark 所在行不要特殊高亮/加粗行号
        vim.api.nvim_set_hl(0, "MarkSignNumHL", {
            link = "LineNr",
		})	
    end,
}
