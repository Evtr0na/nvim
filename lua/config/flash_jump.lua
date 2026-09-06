local M = {}

------------------------------------------------------------
-- virtual text grey + progressive next-char hint
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
------------------------------------------------------------

local function make_progressive_labeler()
    local builtin_labeler

    -- 本轮 Flash 中添加过黄色 extmark 的 buffer
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
        --------------------------------------------------------
        -- 已有 Flash label：
        -- 让 Flash 自己显示红色 label
        --------------------------------------------------------

        if match.label ~= nil then
            return
        end

        --------------------------------------------------------
        -- fold 中的隐藏匹配不处理
        --------------------------------------------------------

        if match.fold then
            return
        end

        local buf = vim.api.nvim_win_get_buf(match.win)

        if not vim.api.nvim_buf_is_loaded(buf) then
            return
        end

        local Util = require("flash.util")

        --------------------------------------------------------
        -- end_pos 是当前匹配的最后位置
        -- +1 character 得到下一次应该输入的字符
        --------------------------------------------------------

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

        --------------------------------------------------------
        -- col 是 byte index，兼容 UTF-8
        --------------------------------------------------------

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

                -- FlashBackdrop 是基础 priority
                -- match / label 会继续增加
                -- 黄色提示需要压过 backdrop
                priority = state.opts.highlight.priority + 3,

                strict = false,
            }
        )
    end

    local function labeler(matches, state)
        --------------------------------------------------------
        -- 1. 清理上一轮提示
        --------------------------------------------------------

        clear_hints()

        --------------------------------------------------------
        -- 2. 让 Flash 正常分配 label
        --------------------------------------------------------

        if not builtin_labeler then
            builtin_labeler =
                require("flash.labeler")
                .new(state)
                :labeler()
        end

        builtin_labeler()

        --------------------------------------------------------
        -- 3. 尚未输入搜索字符
        --------------------------------------------------------

        if state.pattern() == "" then
            return
        end

        --------------------------------------------------------
        -- 4. 没有得到单字符 label 的匹配
        --    显示下一字符提示
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

function M.jump()
    local wins = vim.api.nvim_tabpage_list_wins(0)
    local groups = {}
    local seen_bufs = {}

    --------------------------------------------------------
    -- 1. 收集当前 tab 中 virtual text 使用的高亮组
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
    -- 2. virtual text 全部变灰
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
    -- 3. 设置黄色 next-char highlight
    --------------------------------------------------------

    set_flash_next_char_hl()

    --------------------------------------------------------
    -- 4. 保存并切换 highlight namespace
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
    -- 5. progressive labeler
    --------------------------------------------------------

    local progressive_labeler, clear_hints =
        make_progressive_labeler()

    --------------------------------------------------------
    -- 6. 执行 Flash
    --------------------------------------------------------

    local ok, err = xpcall(function()
        require("flash").jump({
            labeler = progressive_labeler,
        })
    end, debug.traceback)

    --------------------------------------------------------
    -- 7. 清理黄色提示
    --------------------------------------------------------

    clear_hints()

    --------------------------------------------------------
    -- 8. 恢复 highlight namespace
    --------------------------------------------------------

    for win, ns in pairs(old_ns) do
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_set_hl_ns(
                win,
                ns
            )
        end
    end

    --------------------------------------------------------
    -- 9. 重新抛出 Flash 内部错误
    --------------------------------------------------------

    if not ok then
        error(err, 0)
    end
end

return M
