return {
    {
        "rmagatti/auto-session",

        -- 必须在启动阶段加载，才能自动恢复 session
				--
        lazy = false,

        opts = {
            -- 退出 Neovim 时自动保存
            auto_save = true,

            -- 进入项目时自动恢复
            auto_restore = true,

            -- 第一次进入项目时自动创建 session
            auto_create = true,

            -- 当前目录没有 session 时，不加载其他项目的 session
            auto_restore_last_session = false,

            -- :cd 时不要自动切换 session
            cwd_change_handling = false,

            -- alpha 启动页不保存
            bypass_save_filetypes = {
                "alpha",
            },

            -- 不显示恢复通知
            show_auto_restore_notif = false,
        },
    },
}
