--左侧代码树

return {
    "nvim-neo-tree/neo-tree.nvim",
    keys = {
        { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle NeoTree" },
    },
    dependencies = {
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
        -- "nvim-tree/nvim-web-devicons",
    },
    opts = {
        close_if_last_window = true,
        default_component_configs = {
            icon = {
                folder_closed = "",
                folder_open = "",
                folder_empty = "",
                default = "", -- 这里设置默认文件图标，替代 *
            },
        },
        filesystem = {
            --隐藏文件
            filtered_items = {
                visible = false,
                hide_by_name = {
                    -- ".git",
                },
                hide_by_pattern = {
                    "*.tscn",
                    "*.uid",
                    "*.godot",
                },
            },
            follow_current_file = {
                enabled = true,
            },
            hijack_netrw_behavior = "open_default",
        },
    },
}
