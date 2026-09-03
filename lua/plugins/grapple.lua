return {
    {
        "cbochs/grapple.nvim",

        event = {
            "BufReadPost",
            "BufNewFile",
        },

        cmd = "Grapple",

        opts = {

            -- 每个 Git 项目一套书签
            scope = "git",

            -- 纯字符，不使用 Nerd Font / icon
            icons = false,

            status = true,

            -- 只显示文件名
            style = "basename",

            -- 菜单里按 1~9 快速跳转
            quick_select = "123456789",

            win_opts = {
                border = "rounded",
                title = " Grapple ",
                title_pos = "center",
            },
        },


        keys = function()
            local keys = {
                {
                    "<leader>ha",
                    "<cmd>Grapple toggle<cr>",
                    desc = "Grapple: Toggle File",
                },

                {
                    "<leader>hh",
                    "<cmd>Grapple toggle_tags<cr>",
                    desc = "Grapple: Tags",
                },

                {
                    "<leader>hn",
                    "<cmd>Grapple cycle_tags next<cr>",
                    desc = "Grapple: Next",
                },

                {
                    "<leader>hp",
                    "<cmd>Grapple cycle_tags prev<cr>",
                    desc = "Grapple: Previous",
                },

                {
                    "<leader>hs",
                    "<cmd>Grapple toggle_scopes<cr>",
                    desc = "Grapple: Scopes",
                },
            }

            for i = 1, 9 do
                table.insert(keys, {
                    "<leader>" .. i,
                    "<cmd>Grapple select index=" .. i .. "<cr>",
                    desc = "Grapple: File " .. i,
                })
            end

            return keys
        end,

        config = function(_, opts)
            vim.api.nvim_create_autocmd("FileType", {
                pattern = "grapple",
                callback = function(event)
                    vim.keymap.set("n", "J", ":m .+1<CR>==", {
                        buffer = event.buf,
                        silent = true,
                        desc = "Move Grapple tag down",
                    })

                    vim.keymap.set("n", "K", ":m .-2<CR>==", {
                        buffer = event.buf,
                        silent = true,
                        desc = "Move Grapple tag up",
                    })
                end,
            })

        require("grapple").setup(opts)
        end,
    },
}
