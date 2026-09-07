------------------------------------------------------------
--  Custom Commands
------------------------------------------------------------

------------------------------------------------------------
--  Messages
------------------------------------------------------------

vim.api.nvim_create_user_command("Msg", function(opts)
    local msg = vim.fn.execute("messages")
    if opts.args == "y" or opts.args == "copy" then
        vim.fn.setreg("+", msg)
        print("Messages copied to clipboard")
    else
        vim.cmd("vnew")
        local lines = vim.split(msg, "\n")
        vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
        vim.cmd("normal! G")
    end
end, {
    nargs = "?",
    complete = function()
        return { "y", "copy" }
    end,
    desc = "Show messages in split or copy to clipboard",
})

--Readme
--":Msg":open a buffer of messages
--":Msy y":just to yank
--":Msy copy":similar to ":Msy"

------------------------------------------------------------
-- / to \ and \ to /
------------------------------------------------------------

local function replace_in_range(line1, line2, from, to)
    local lines = vim.api.nvim_buf_get_lines(0, line1 - 1, line2, false)

    for i, line in ipairs(lines) do
        lines[i] = line:gsub(from, to)
    end

    vim.api.nvim_buf_set_lines(0, line1 - 1, line2, false, lines)
end

-- / → \
vim.api.nvim_create_user_command("SlashToBackslash", function(opts)
    replace_in_range(opts.line1, opts.line2, "/", "\\")
end, {
    range = true,
    desc = "Replace / with \\",
})

-- \ → /
vim.api.nvim_create_user_command("BackslashToSlash", function(opts)
    replace_in_range(opts.line1, opts.line2, "\\", "/")
end, {
    range = true,
    desc = "Replace \\ with /",
})


------------------------------------------------------------
-- Visual Math
--
-- Visual 选中区域后：
--   :Math *2
--   :Math /999
--   :Math *2/999
--   :Math +0.5
--   :Math *2+1
------------------------------------------------------------

do
    local current_expr = nil

    --------------------------------------------------------
    -- 格式化计算结果
    --------------------------------------------------------
    local function format_result(value, original)
        if
            value ~= value
            or value == math.huge
            or value == -math.huge
        then
            error("Math: invalid result")
        end

        -- 避免出现 -0
        if math.abs(value) < 1e-15 then
            value = 0
        end

        -- 最多 15 位有效数字，避免 0.30000000000000004
        local result = string.format("%.15g", value)

        -- 原来是 float：
        --   1.0 * 2
        -- 保持成：
        --   2.0
        -- 而不是：
        --   2
        if
            original:find("%.")
            and not result:find("[%.eE]")
        then
            result = result .. ".0"
        end

        return result
    end

    --------------------------------------------------------
    -- substitute() 调用的 Lua 函数
    --------------------------------------------------------
    _G.__visual_math_apply = function(text)
        local code =
            "return (" .. text .. ")" .. current_expr

        local fn, err = loadstring(code)

        if not fn then
            error("Math: " .. err)
        end

        local ok, value = pcall(fn)

        if not ok then
            error("Math: " .. value)
        end

        if type(value) ~= "number" then
            error("Math: result is not a number")
        end

        return format_result(value, text)
    end

    --------------------------------------------------------
    -- :Math
    --------------------------------------------------------
    vim.api.nvim_create_user_command("Math", function(opts)
        local expr = vim.trim(opts.args)

        ----------------------------------------------------
        -- 必须从运算符开始
        ----------------------------------------------------
        if
            expr == ""
            or not expr:match("^[%+%-%*/%%%^]")
        then
            vim.notify(
                "Math: expression must start with an operator, e.g. *2/999",
                vim.log.levels.ERROR
            )
            return
        end

        ----------------------------------------------------
        -- 只允许数学表达式
        ----------------------------------------------------
        if expr:find(
            "[^%d%.eE%+%-%*/%%%^%(%)%s]"
        ) then
            vim.notify(
                "Math: invalid expression",
                vim.log.levels.ERROR
            )
            return
        end

        current_expr = expr

        ----------------------------------------------------
        -- 数字匹配
        --
        -- 支持：
        --   123
        --   -123
        --   1.25
        --   .25
        --   -1.5
        --   1e-3
        --
        -- 不会把：
        --   vec3
        --   foo123
        --
        -- 中的数字当成数值修改
        ----------------------------------------------------
        local pattern =
            [[\%V\%(\k\|\.\)\@<!]]
            .. [[[-+]\?]]
            .. [[\%(\d\+\%(\.\d*\)\?\|\.\d\+\)]]
            .. [[\%([eE][-+]\?\d\+\)\?]]
            .. [[\%(\k\|\.\)\@!]]

        local command = string.format(
            [[%d,%ds#%s#\=v:lua.__visual_math_apply(submatch(0))#g]],
            opts.line1,
            opts.line2,
            pattern
        )

        -- local ok, err = pcall(vim.cmd, command)
				local ok,err = pcall(function () vim.cmd(command)
				end)

        current_expr = nil

        if not ok then
            error(err)
        end
    end, {
        nargs = "+",
        range = true,
        desc = "Apply math expression to numbers in visual selection",
    })
end
