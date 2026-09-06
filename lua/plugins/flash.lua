------------------------------------------------------------
--- lazy.nvim
------------------------------------------------------------
return {
    "folke/flash.nvim",

    -- event = "VeryLazy",
		keys = {
			{
				"s",
				function()
    require("config.flash_jump").jump()
				end,
				mode = { "n", "v" },
				desc = "Flash Jump",
			},
		},
    opts = {
        prompt = {
            prefix = {
                {
                    " > ",
                    "FlashPromptIcon",
                },
            },
        },

        ----------------------------------------------------
        -- label 直接覆盖匹配字符
        ----------------------------------------------------

        label = {
            after = false,
            before = { 0, 0 },
            style = "overlay",
        },

        highlight = {
            backdrop = true,
            matches = false,

            groups = {
                -- 最近目标也使用 FlashLabel
                current = "FlashLabel",
            },
        },

        modes = {
            jump = {
                search = {
                    mode = "search",
                },
            },
        },
    },


    config = function(_, opts)
    ----------------------------------------------------
    -- 整个背景变灰
    ----------------------------------------------------

    vim.api.nvim_set_hl(0, "FlashBackdrop", {
        fg = "#393939",
    })

    ----------------------------------------------------
    -- 可直接跳转的单字母 label = 红色
    ----------------------------------------------------

    vim.api.nvim_set_hl(0, "FlashLabel", {
        fg = "#ff0000",
        bold = true,
    })

    ----------------------------------------------------
    -- 搜索大小写
    ----------------------------------------------------

    vim.o.ignorecase = true
    vim.o.smartcase = true

    ----------------------------------------------------
    -- 加载 Flash
    ----------------------------------------------------

    require("flash").setup(opts)
    end,
}
