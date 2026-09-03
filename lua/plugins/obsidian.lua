return {
    {
        "obsidian-nvim/obsidian.nvim",

        -- 使用最新稳定 release
        version = "*",

        -- 普通 Markdown 打开时加载
        ft = "markdown",

        -- 这样在非 md 文件里也可以手动执行 :Obsidian ...
        cmd = "Obsidian",

        dependencies = {
            "nvim-telescope/telescope.nvim",
        },

        -- 不使用 obsidian.nvim 自带快捷键
        -- 所有快捷键我们自己设成 buffer-local
        init = function()
            vim.g.obsidian_default_keymap = false
        end,

        ---@module "obsidian"
        ---@type obsidian.config
        opts = {
            ------------------------------------------------------------
            -- Vault
            ------------------------------------------------------------
            workspaces = {
                {
                    name = "notes",

                    -- 改成你的 Obsidian Vault 路径
                    -- Windows 推荐使用 /
                    path = "D:/2zhuomian/Study",
                },
            },

            ------------------------------------------------------------
            -- Commands
            ------------------------------------------------------------
            -- 只使用新版：
            --
            -- :Obsidian quick_switch
            --
            -- 不生成旧的：
            --
            -- :ObsidianQuickSwitch
            ------------------------------------------------------------
            legacy_commands = false,

            ------------------------------------------------------------
            -- Telescope
            ------------------------------------------------------------
            picker = {
                name = "telescope.nvim",
            },

            ------------------------------------------------------------
            -- Cache
            ------------------------------------------------------------
            -- quick_switch 会更快
            cache = {
                enabled = true,
            },

            ------------------------------------------------------------
            -- UI
            ------------------------------------------------------------
            -- 你已经使用 render-markdown.nvim，
            -- Markdown 渲染全部交给它。
            ui = {
                enable = false,
            },

            ------------------------------------------------------------
            -- 快捷键
            ------------------------------------------------------------
            callbacks = {
                enter_note = function()
                    -- 双重保证：
                    -- 只有 Markdown buffer 才设置下面这些快捷键
                    if vim.bo.filetype ~= "markdown" then
                        return
                    end

                    local buf = vim.api.nvim_get_current_buf()

                    local function map(mode, lhs, rhs, desc)
                        vim.keymap.set(mode, lhs, rhs, {
                            buffer = buf,
                            silent = true,
                            desc = desc,
                        })
                    end

                    ----------------------------------------------------
                    -- Notes
                    ----------------------------------------------------

                    -- 搜索 / 跳转 Note
                    map(
                        "n",
                        "<leader>nn",
                        "<cmd>Obsidian quick_switch<cr>",
                        "Obsidian: Notes"
                    )

                    -- 全文搜索 Vault
                    map(
                        "n",
                        "<leader>ns",
                        "<cmd>Obsidian search<cr>",
                        "Obsidian: Search"
                    )

                    -- 创建 Note
                    map(
                        "n",
                        "<leader>nc",
                        "<cmd>Obsidian new<cr>",
                        "Obsidian: New Note"
                    )

                    ----------------------------------------------------
                    -- 当前 Note
                    ----------------------------------------------------

                    -- Backlinks
                    map(
                        "n",
                        "<leader>nb",
                        "<cmd>Obsidian backlinks<cr>",
                        "Obsidian: Backlinks"
                    )

                    -- 当前 Note 里的所有链接
                    map(
                        "n",
                        "<leader>nl",
                        "<cmd>Obsidian links<cr>",
                        "Obsidian: Links"
                    )

                    -- 重命名 Note，并更新引用
                    map(
                        "n",
                        "<leader>nr",
                        "<cmd>Obsidian rename<cr>",
                        "Obsidian: Rename Note"
                    )

                    ----------------------------------------------------
                    -- Tags
                    ----------------------------------------------------

                    map(
                        "n",
                        "<leader>ng",
                        "<cmd>Obsidian tags<cr>",
                        "Obsidian: Tags"
                    )

                    ----------------------------------------------------
                    -- Daily Notes
                    ----------------------------------------------------

                    map(
                        "n",
                        "<leader>nd",
                        "<cmd>Obsidian today<cr>",
                        "Obsidian: Today"
                    )

                    map(
                        "n",
                        "<leader>nD",
                        "<cmd>Obsidian dailies<cr>",
                        "Obsidian: Daily Notes"
                    )

                    ----------------------------------------------------
                    -- Checkbox
                    ----------------------------------------------------

                    map(
                        "n",
                        "<leader>nx",
                        "<cmd>Obsidian toggle_checkbox<cr>",
                        "Obsidian: Toggle Checkbox"
                    )

                    ----------------------------------------------------
                    -- Template
                    ----------------------------------------------------

                    map(
                        "n",
                        "<leader>ni",
                        "<cmd>Obsidian template<cr>",
                        "Obsidian: Insert Template"
                    )

                    ----------------------------------------------------
                    -- Visual mode
                    ----------------------------------------------------

                    -- 把选中文字链接到已有 Note
                    map(
                        "v",
                        "<leader>nl",
                        "<cmd>Obsidian link<cr>",
                        "Obsidian: Link Selection"
                    )

                    -- 从选中文字创建新 Note
                    map(
                        "v",
                        "<leader>nc",
                        "<cmd>Obsidian link_new<cr>",
                        "Obsidian: New Note From Selection"
                    )
                end,
            },
        },
    },
}
