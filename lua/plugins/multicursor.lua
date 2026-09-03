return {
    "jake-stewart/multicursor.nvim",
    branch = "1.0",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
        local mc = require("multicursor-nvim")
        mc.setup()
        vim.keymap.set({ "n", "x" }, "<leader>ml", mc.toggleCursor)

        vim.keymap.set("n", "<C-LeftMouse>", mc.handleMouse)
        vim.keymap.set("n", "<C-LeftDrag>", mc.handleMouseDrag)
        vim.keymap.set("n", "<C-LeftRelease>", mc.handleMouseRelease)

        -- vim.keymap.set("n", "<leader>mc", function()
        --     require("multicursor-nvim").clearCursors()
        -- end, { desc = "Clear multicursors" })

        -- ---------------------------------------------------------------------------
        -- -- 1. 按相同单词 / Visual 选区添加光标
        -- ---------------------------------------------------------------------------
        --
        -- -- 下一个相同内容
        -- map({ "n", "x" }, "<leader>mn", function()
        --     mc.matchAddCursor(1)
        -- end, { desc = "Multicursor: Next match" })
        --
        -- -- 上一个相同内容
        -- map({ "n", "x" }, "<leader>mN", function()
        --     mc.matchAddCursor(-1)
        -- end, { desc = "Multicursor: Previous match" })
        --
        -- -- 跳过当前匹配，继续找下一个
        -- map({ "n", "x" }, "<leader>ms", function()
        --     mc.matchSkipCursor(1)
        -- end, { desc = "Multicursor: Skip next match" })
        --
        -- -- 跳过当前匹配，向前找
        -- map({ "n", "x" }, "<leader>mS", function()
        --     mc.matchSkipCursor(-1)
        -- end, { desc = "Multicursor: Skip previous match" })
        --
        -- 一次选中当前单词 / Visual 选区的所有匹配
        -- map({ "n", "x" }, "<leader>ma", mc.matchAllAddCursors, {
        --     desc = "Multicursor: Select all matches",
        -- })

        vim.keymap.set({ "n", "x" }, "<leader>ma", mc.matchAllAddCursors)

        --
        -- ---------------------------------------------------------------------------
        -- -- 2. 上下添加光标
        -- ---------------------------------------------------------------------------
        --
        -- map({ "n", "x" }, "<leader>mj", function()
        --     mc.lineAddCursor(1)
        -- end, { desc = "Multicursor: Add cursor below" })
        --
        -- map({ "n", "x" }, "<leader>mk", function()
        --     mc.lineAddCursor(-1)
        -- end, { desc = "Multicursor: Add cursor above" })
        --
        -- -- 跳过一行
        -- map({ "n", "x" }, "<leader>mJ", function()
        --     mc.lineSkipCursor(1)
        -- end, { desc = "Multicursor: Skip line below" })
        --
        -- map({ "n", "x" }, "<leader>mK", function()
        --     mc.lineSkipCursor(-1)
        -- end, { desc = "Multicursor: Skip line above" })
        --
        -- ---------------------------------------------------------------------------
        -- -- 3. 鼠标添加 / 删除光标
        -- ---------------------------------------------------------------------------
        --
        -- map("n", "<C-LeftMouse>", mc.handleMouse, {
        --     desc = "Multicursor: Mouse add/remove cursor",
        -- })
        --
        -- map("n", "<C-LeftDrag>", mc.handleMouseDrag)
        --
        -- map("n", "<C-LeftRelease>", mc.handleMouseRelease)
        --
        -- ---------------------------------------------------------------------------
        -- -- 4. 其它常用操作
        -- ---------------------------------------------------------------------------
        --
        -- -- 暂时禁用所有副光标，只移动主光标
        -- map({ "n", "x" }, "<leader>mt", mc.toggleCursor, {
        --     desc = "Multicursor: Toggle cursors",
        -- })
        --
        -- -- 对齐所有光标所在列
        -- map("n", "<leader>ml", mc.alignCursors, {
        --     desc = "Multicursor: Align cursors",
        -- })
        --
        -- -- 恢复刚刚清除的光标
        -- map("n", "<leader>mr", mc.restoreCursors, {
        --     desc = "Multicursor: Restore cursors",
        -- })
        --
        -- ---------------------------------------------------------------------------
        -- -- 5. 只有存在多光标时才生效
        -- ---------------------------------------------------------------------------
        --
        mc.addKeymapLayer(function(layerSet)
            -- -- 切换哪个光标是主光标
            -- layerSet({ "n", "x" }, "]m", mc.nextCursor)
            -- layerSet({ "n", "x" }, "[m", mc.prevCursor)
            --
            -- 删除当前主光标
            layerSet({ "n", "x" }, "<leader>mx", mc.deleteCursor)

            -- Esc：
            -- 如果光标被禁用 -> 重新启用
            -- 如果光标正常启用 -> 清除所有副光标
            layerSet("n", "<Esc>", function()
                if not mc.cursorsEnabled() then
                    mc.enableCursors()
                else
                    mc.clearCursors()
                end
            end)
        end)
    end,
}
