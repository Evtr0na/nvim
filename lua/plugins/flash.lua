--跳转
------------------------------------------------------------
--- fuction virtual text grey
------------------------------------------------------------
local flash_dim_ns = vim.api.nvim_create_namespace("FlashDimVirtualText")

local function get_virtual_text_hls(buf, groups)
    local extmarks = vim.api.nvim_buf_get_extmarks(buf, -1, 0, -1, {
        details = true,
        type = "virt_text",
        hl_name = true,
    })

    local function add_hl(hl)
        if type(hl) == "string" and hl ~= "" then
            groups[hl] = true
        elseif type(hl) == "table" then
            for _, item in ipairs(hl) do
                add_hl(item)
            end
        end
    end

    for _, mark in ipairs(extmarks) do
        local details = mark[4]

        -- 修复 need-check-nil
        if details and details.virt_text then
            for _, chunk in ipairs(details.virt_text) do
                add_hl(chunk[2])
            end
        end
    end
end

local function flash_jump()
    local wins = vim.api.nvim_tabpage_list_wins(0)
    local groups = {}
    local seen_bufs = {}

    -- 收集当前 tab 中 virtual text 使用的高亮组
    for _, win in ipairs(wins) do
        if vim.api.nvim_win_is_valid(win) then
            local buf = vim.api.nvim_win_get_buf(win)

            if not seen_bufs[buf] and vim.api.nvim_buf_is_loaded(buf) then
                seen_bufs[buf] = true
                get_virtual_text_hls(buf, groups)
            end
        end
    end

    -- 只覆盖 virtual text 的前景色
    for group in pairs(groups) do
        vim.api.nvim_set_hl(flash_dim_ns, group, {
            fg = "#393939",
        })
    end

    -- 保存原来的 highlight namespace
    local old_ns = {}

    for _, win in ipairs(wins) do
        if vim.api.nvim_win_is_valid(win) then
            old_ns[win] = vim.api.nvim_get_hl_ns({ winid = win })
            vim.api.nvim_win_set_hl_ns(win, flash_dim_ns)
        end
    end

    -- 执行 Flash
    local ok, err = xpcall(function()
        require("flash").jump()
    end, debug.traceback)

    -- Flash 结束后恢复
    for win, ns in pairs(old_ns) do
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_set_hl_ns(win, ns)
        end
    end

    if not ok then
        error(err)
    end
end
------------------------------------------------------------
---	lazy.nvim
------------------------------------------------------------

return {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
        prompt = {
            prefix = { { " > ", "FlashPromptIcon" } },
        },

        -- 关键：把跳转 label 直接覆盖到匹配字符上
        label = {
            after = false,
            before = { 0, 0 },
            style = "overlay",
        },

        highlight = {
            backdrop = true,
            matches = false,

            groups = {
                -- 当前最近目标也使用 FlashLabel，
                -- 避免出现 FlashCurrent 的另一套颜色
                current = "FlashLabel",
            },
        },

        modes = {
            jump = {
                search = { mode = "search" },
            },
        },
    },
    keys = {
        {
            "s",
            --这里的flash_jump是上面那一串function
            flash_jump,
            mode = { "n", "v" },
            desc = "Flash Jump",
        },
    },
    config = function(_, opts)
        -- 设置 FlashBackdrop 为灰色，实现"黑白"效果
        vim.api.nvim_set_hl(0, "FlashBackdrop", { fg = "#393939" })
        -- 你也可以在这里设置其他高亮组，例如让标签更醒目
        vim.api.nvim_set_hl(0, "FlashLabel", { fg = "#ff0000", bold = true })
        -- 启用忽略大小写
        vim.o.ignorecase = true
        -- 智能大小写：当搜索模式包含大写字母时，自动切换为大小写敏感
        vim.o.smartcase = true

        -- 然后加载插件
        require("flash").setup(opts)
    end,
}
