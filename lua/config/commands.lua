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
