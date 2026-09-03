return {
    {
        "kevinhwang91/nvim-ufo",

        dependencies = {
            "kevinhwang91/promise-async",
        },

        event = {
            "BufReadPost",
            "BufNewFile",
        },

        keys = {
            {
                "zR",
                function()
                    require("ufo").openAllFolds()
                end,
                desc = "Open All Folds",
            },
            {
                "zM",
                function()
                    require("ufo").closeAllFolds()
                end,
                desc = "Close All Folds",
            },
            {
                "zK",
                function()
                    local winid = require("ufo").peekFoldedLinesUnderCursor()
                    if not winid then
                        vim.lsp.buf.hover()
                    end
                end,
                desc = "Peek Fold",
            },
        },

        init = function()
            -- vim.o.foldcolumn = "1"
            vim.o.foldlevel = 99
            vim.o.foldlevelstart = 99
            vim.o.foldenable = true
        end,

        opts = {
            provider_selector = function(_, _, buftype)
                if buftype ~= "" then
                    return ""
                end

                return {
                    "treesitter",
                    "indent",
                }
            end,

            open_fold_hl_timeout = 150,
        },

        config = function(_, opts)
            require("ufo").setup(opts)
            --
            -- -- 普通折叠行
            -- vim.api.nvim_set_hl(0, "UfoFoldedBg", {
            --     bg = "#CCD6F4",
            -- })
            --
            -- -- 光标位于折叠行时
            -- vim.api.nvim_set_hl(0, "UfoCursorFoldedLine", {
            --     bg = "#CCD6F4",
            -- })
        end,
    },
}
