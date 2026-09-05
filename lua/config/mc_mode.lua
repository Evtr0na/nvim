--------------------------------------------------
-- A custom mode used to select and add cursor 
--------------------------------------------------
local M = {}

local mc = require("multicursor-nvim")

local ns = vim.api.nvim_create_namespace("mc-select-mode")

M.active = false

--------------------------------------------------
-- 原生 Normal 操作
-- 使用 normal!，故意绕过你的所有 mappings
--------------------------------------------------

local function normal(keys)
    vim.cmd("normal! " .. keys)
end

	--------------------------------------------------
	-- custom function 
	--------------------------------------------------

local function match_add_frozen(direction)
  -- 把当前位置留下为 frozen cursor
  mc.toggleCursor()

  -- 只移动 main cursor，不创建 enabled cursor
  mc.matchSkipCursor(direction)

	--------------------------------------------------
	-- MC 模式自己的键位
	--------------------------------------------------

end

local keys = {
    -- 移动
    h = function()
        normal("h")
    end,

    j = function()
        normal("j")
    end,

    k = function()
        normal("k")
    end,

    l = function()
        normal("l")
    end,

    w = function()
        normal("w")
    end,

    b = function()
        normal("b")
    end,

    e = function()
        normal("e")
    end,

    ["0"] = function()
        normal("0")
    end,

    ["^"] = function()
        normal("^")
    end,

    ["$"] = function()
        normal("$")
    end,

    ["V"] = function()
        normal("V")
    end,

    ["v"] = function()
        normal("v")
    end,

    ["n"] = function()
        normal("n")
    end,

    ["N"] = function()
        normal("N")
    end,

    ["*"] = function()
        normal("*")
    end,
    ------------------------------------------------
    -- 多光标专属操作
    ------------------------------------------------

    J = function()
				mc.matchSkipCursor(1)
        -- normal("j")
    end,

    K = function()
				mc.matchSkipCursor(-1)
        -- normal("k")
    end,

    s = function()
        mc.toggleCursor()
    end,

    x = function()
        mc.deleteCursor()
    end,

    a = function()
			match_add_frozen(1)
    end,
    A = function()
			match_add_frozen(-1)
    end,
}

--------------------------------------------------
-- 进入模式
--------------------------------------------------

function M.enter()
    if M.active then
        return
    end

    M.active = true

    -- 如果本来已经有副光标，比如编辑过程中重新进入 MC SELECT，
    -- 才锁住现有 cursors。
    --
    -- 第一次进入、没有任何副光标时：
    -- 什么都不创建。
    if mc.hasCursors() and mc.cursorsEnabled() then
        mc.disableCursors()
    end

    vim.api.nvim_echo({
      { " MC SELECT ", "ModeMsg" },
    }, false, {})
end

--------------------------------------------------
-- 退出模式
--------------------------------------------------

function M.leave()
    if not M.active then
        return
    end

    M.active = false

    if mc.hasCursors() and not mc.cursorsEnabled() then
        mc.enableCursors()
    end

    vim.api.nvim_echo({
      { "", "ModeMsg" },
    }, false, {})
    vim.cmd("redraw")
end
--------------------------------------------------
-- 核心：自己的输入处理器
--------------------------------------------------

vim.on_key(function(key, typed)
    if not M.active then
        return
    end

    ------------------------------------------------
    -- mapping 产生出来的后续按键
    -- 一律吞掉
    ------------------------------------------------

    if typed == "" then
        return ""
    end

    -- 转成 s / <Esc> / <C-x> 这样的表示
    local k = vim.fn.keytrans(typed)

    ------------------------------------------------
    -- Esc = 离开 MC mode
    ------------------------------------------------

    if k == "<Esc>" then
        return
    end

    ------------------------------------------------
    -- MC mode 自己定义的按键
    ------------------------------------------------

    local action = keys[k]

    if action then
        action()

        -- 不继续执行原来的 mapping
        return ""
    end

    ------------------------------------------------
    -- 没有定义的键
    -- 全部屏蔽
    ------------------------------------------------

    return ""
end, ns)

return M
