--模糊搜索，

return {
    "nvim-telescope/telescope.nvim",

    keys = {
        { "<leader>f", "<cmd>Telescope find_files<cr>", desc = "Find File" },
        { "<leader>j", "<cmd>Telescope live_grep<cr>", desc = "Search Text" },
        { "<leader>b", "<cmd>Telescope buffers<cr>", desc = "List Buffers" },
        -- { "<leader>h", "<cmd>Telescope help_tags<cr>", desc = "Help Tags" },
        { "gr", "<cmd>Telescope lsp_references<cr>", desc = "lise reference" },
        { "gR", "<cmd>Telescope grep_string<cr>", desc = "lise reference" },

        { "gd", "<cmd>Telescope lsp_definitions<cr>", desc = "lise reference" },
        { "<leader>o", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Document Symbols" },
        -- 针对扩展扩展（Zoxide）的懒加载函数写法
        {
            "<leader>z",
            function()
                require("telescope").extensions.zoxide.list()
            end,
            desc = "Zoxide jump",
        },
    },
    dependencies = {
        "nvim-lua/plenary.nvim",

        -- fzf 原生排序器（已手动构建，此处保留 build 以便日后更新）
        {
            "nvim-telescope/telescope-fzf-native.nvim",
            build = function()
                if vim.fn.has("win32") == 1 then
                    return "mingw32-make"
                else
                    return "make"
                end
            end,
        },

        -- zoxide 智能目录跳转
        "jvgrootveld/telescope-zoxide",
    },

    opts = {
        defaults = {
            --屏蔽.tscn等文件
            file_ignore_patterns = {

                "vimdow", -- godot
                "%.uid$", -- godot
                -- "%.tscn$", -- godot
            },
            path_display = { "smart" },
            vimgrep_arguments = {
                "rg",
                "--follow",
                "--hidden",
                "--no-heading",
                "--with-filename",
                "--line-number",
                "--column",
                "--smart-case",
            },
            find_command = vim.fn.executable("fd") == 1 and { "fd", "--type", "f", "--hidden", "--follow" } or nil,
        },

        extensions = {
            fzf = {
                fuzzy = true,
                override_generic_sorter = true,
                override_file_sorter = true,
                case_mode = "smart_case",
            },
            zoxide = {
                prompt_title = "[ Zoxide ]",
                score = true,
            },
        },
    },

    config = function(_, opts)
        require("telescope").setup(opts)

        -- 直接加载 fzf 扩展（无需检查 fzf 命令，因为扩展本身不依赖它）
        require("telescope").load_extension("fzf")

        -- 加载 zoxide 扩展
        require("telescope").load_extension("zoxide")

        --  快捷键已移除（按你的要求，不配置）
        -- 如果你以后想添加，可以在这里自行添加 vim.keymap.set(...)
    end,
}
