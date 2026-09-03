return {
    "folke/trouble.nvim",
    event = "BufReadPre",
    opts = {
        win = {
            wo = {
                -- 将 Trouble 窗口的 Normal 背景强制绑定为 NormalFloat
                winhighlight = "Normal:MyTroubleBg,NormalNC:MyTroubleBg",
            },
        },
    },

    cmd = "Trouble",

    keys = {
        --		在未特殊设置的情况在，只能针对打开的buffer报错
        {
            "<leader>xx",
            "<cmd>Trouble diagnostics toggle<cr>",
            desc = "Diagnostics (Trouble)",
        },
        {
            "<leader>xX",
            "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
            desc = "Buffer Diagnostics (Trouble)",
        },
        {
            "<leader>cs",
            "<cmd>Trouble symbols toggle focus=false<cr>",
            desc = "Symbols (Trouble)",
        },
        {
            "<leader>cl",
            "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
            desc = "LSP Definitions / references / ... (Trouble)",
        },
        {
            "<leader>xL",
            "<cmd>Trouble loclist toggle<cr>",
            desc = "Location List (Trouble)",
        },
        {
            "<leader>xQ",
            "<cmd>Trouble qflist toggle<cr>",
            desc = "Quickfix List (Trouble)",
        },
        {
            "gr",
            "<cmd>Trouble lsp_references toggle<cr>",
            desc = "LSP References (Trouble)",
        },
    },
    config = function(_, opts)
        -- 自定义一个专用的高亮组
        vim.api.nvim_set_hl(0, "MyTroubleBg", { bg = "#181818" })
        require("trouble").setup(opts)
    end,
}
