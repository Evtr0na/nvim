--终端文件管理
return {
    "mikavilpas/yazi.nvim",
    -- event = "VeryLazy",
    keys = {
        -- 快捷键打开 yazi
        {
            "<leader>y",
            "<cmd>Yazi<cr>",
            desc = "打开 Yazi 文件管理器",
        },
        {
            "<leader>Y",
            "<cmd>Yazi cwd<cr>",
            desc = "在工作根目录打开 Yazi",
        },
    },
    opts = {
        -- 浮窗大小
        size = {
            width = 0.9,
            height = 0.8,
        },
        open_for_directories = false, -- 关闭时用 yazi 替代 netrw
        floating_window = {
            border = "rounded",
        },
    },
}
