-- 跳转
------------------------------------------------------------
--- virtual text grey + progressive next-char hint
------------------------------------------------------------

local flash_dim_ns = vim.api.nvim_create_namespace("FlashDimVirtualText")
local flash_hint_ns = vim.api.nvim_create_namespace("FlashNextCharHint")

------------------------------------------------------------
-- 收集 virtual text 使用的高亮组
------------------------------------------------------------

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

        if details and details.virt_text then
            for _, chunk in ipairs(details.virt_text) do
                add_hl(chunk[2])
            end
        end
    end
end

------------------------------------------------------------
-- 从当前主题取得 yellow
------------------------------------------------------------

local function set_flash_next_char_hl()
    local fg

    -- 优先使用主题自己的 Yellow。
    -- 没有 Yellow 时退到 DiagnosticWarn / WarningMsg。
    for _, group in ipairs({
        "yellow",
        "DiagnosticWarn",
        "WarningMsg",
    }) do
        local ok, hl = pcall(vim.api.nvim_get_hl, 0, {
            name = group,
            link = false,
        })

        if ok and hl and hl.fg then
            fg = hl.fg
            break
        end
    end

    vim.api.nvim_set_hl(flash_dim_ns, "FlashNextChar", {
        fg = fg or "#e0af68",
				bold = true,
    })
end

------------------------------------------------------------
-- 创建 progressive labeler
--
-- 有 Flash label：
--     红色 label，什么都不做
--
-- 没有 Flash label：
--     高亮当前搜索结果之后的下一个字符
------------------------------------------------------------

local function make_progressive_labeler()
    local builtin_labeler

    -- 本轮 Flash 中，我们自己添加过黄色 extmark 的 buffer
    local touched_bufs = {}

    local function clear_hints()
        for buf in pairs(touched_bufs) do
            if vim.api.nvim_buf_is_valid(buf) then
                pcall(
                    vim.api.nvim_buf_clear_namespace,
                    buf,
                    flash_hint_ns,
                    0,
                    -1
                )
            end
        end

        touched_bufs = {}
    end

    local function add_next_char_hint(match, state)
        -- 已经获得单字母 label：
        -- 让 Flash 自己显示红色 label
        if match.label ~= nil then
            return
        end

        -- fold 中的隐藏匹配不处理
        if match.fold then
            return
        end

        local buf = vim.api.nvim_win_get_buf(match.win)

        if not vim.api.nvim_buf_is_loaded(buf) then
            return
        end

        local Util = require("flash.util")

        -- Flash 的 end_pos 指向匹配结果最后一个字符，
        -- 所以 +1 character 就是下一次应该继续输入的字符。
        local next_pos = Util.offset_pos(
            buf,
            match.end_pos,
            { 0, 1 }
        )

        local row = next_pos[1]
        local col = next_pos[2]

        local line = vim.api.nvim_buf_get_lines(
            buf,
            row - 1,
            row,
            false
        )[1]

        if not line or col >= #line then
            return
        end

        -- col 是 byte index。
        -- 这里兼容 UTF-8，不直接 col + 1。
        local char_index = vim.fn.charidx(line, col)

        if char_index < 0 then
            return
        end

        local char = vim.fn.strcharpart(
            line,
            char_index,
            1
        )

        if char == "" then
            return
        end

        touched_bufs[buf] = true

        vim.api.nvim_buf_set_extmark(
            buf,
            flash_hint_ns,
            row - 1,
            col,
            {
                end_col = col + #char,

                hl_group = "FlashNextChar",

                -- FlashBackdrop 是 priority
                -- Flash match 是 +1
                -- Flash label 是 +2
                --
                -- 黄色提示必须压过灰色 backdrop
                priority = state.opts.highlight.priority + 3,

                strict = false,
            }
        )
    end

    local function labeler(matches, state)
        --------------------------------------------------------
        -- 1. 先清掉上一轮黄色提示
        --------------------------------------------------------

        clear_hints()

        --------------------------------------------------------
        -- 2. 完整执行 Flash 原来的 label 分配逻辑
        --------------------------------------------------------

        if not builtin_labeler then
            builtin_labeler =
                require("flash.labeler")
                .new(state)
                :labeler()
        end

        builtin_labeler()

        --------------------------------------------------------
        -- 3. 尚未输入任何搜索字符时，不提示
        --------------------------------------------------------

        if state.pattern() == "" then
            return
        end

        --------------------------------------------------------
        -- 4. 只处理没拿到单字母 label 的结果
        --------------------------------------------------------

        for _, match in ipairs(matches) do
            add_next_char_hint(match, state)
        end
    end

    return labeler, clear_hints
end

------------------------------------------------------------
-- Flash Jump
------------------------------------------------------------

local function flash_jump()
    local wins = vim.api.nvim_tabpage_list_wins(0)
    local groups = {}
    local seen_bufs = {}

    --------------------------------------------------------
    -- 收集当前 tab 中 virtual text 使用的高亮组
    --------------------------------------------------------

    for _, win in ipairs(wins) do
        if vim.api.nvim_win_is_valid(win) then
            local buf = vim.api.nvim_win_get_buf(win)

            if
                not seen_bufs[buf]
                and vim.api.nvim_buf_is_loaded(buf)
            then
                seen_bufs[buf] = true
                get_virtual_text_hls(buf, groups)
            end
        end
    end

    --------------------------------------------------------
    -- virtual text 全部变灰
    --------------------------------------------------------

    for group in pairs(groups) do
        vim.api.nvim_set_hl(
            flash_dim_ns,
            group,
            {
                fg = "#393939",
            }
        )
    end

    --------------------------------------------------------
    -- 获取当前主题 yellow
    --------------------------------------------------------

    set_flash_next_char_hl()

    --------------------------------------------------------
    -- 保存原来的 highlight namespace
    --------------------------------------------------------

    local old_ns = {}

    for _, win in ipairs(wins) do
        if vim.api.nvim_win_is_valid(win) then
            old_ns[win] =
                vim.api.nvim_get_hl_ns({
                    winid = win,
                })

            vim.api.nvim_win_set_hl_ns(
                win,
                flash_dim_ns
            )
        end
    end

    --------------------------------------------------------
    -- progressive labeler
    --------------------------------------------------------

    local progressive_labeler, clear_hints =
        make_progressive_labeler()

    --------------------------------------------------------
    -- 执行 Flash
    --------------------------------------------------------

    local ok, err = xpcall(function()
        require("flash").jump({
            labeler = progressive_labeler,
        })
    end, debug.traceback)

    --------------------------------------------------------
    -- 删除黄色提示
    --------------------------------------------------------

    clear_hints()

    --------------------------------------------------------
    -- Flash 结束后恢复 highlight namespace
    --------------------------------------------------------

    for win, ns in pairs(old_ns) do
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_set_hl_ns(
                win,
                ns
            )
        end
    end

    if not ok then
        error(err)
    end
end

------------------------------------------------------------
--- lazy.nvim
------------------------------------------------------------

return {
    "folke/flash.nvim",

    event = "VeryLazy",

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

    keys = {
        {
            "s",
            flash_jump,
            mode = {
                "n",
                "v",
            },
            desc = "Flash Jump",
        },
    },

    config = function(_, opts)
        ----------------------------------------------------
        -- 整个背景变灰
        ----------------------------------------------------

        vim.api.nvim_set_hl(
            0,
            "FlashBackdrop",
            {
                fg = "#393939",
            }
        )

        ----------------------------------------------------
        -- 可直接跳转的单字母 label = 红色
        ----------------------------------------------------

        vim.api.nvim_set_hl(
            0,
            "FlashLabel",
            {
                fg = "#ff0000",
                bold = true,
            }
        )

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
