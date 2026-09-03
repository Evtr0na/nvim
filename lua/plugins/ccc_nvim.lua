--设置颜色插件
return {
    "uga-rosa/ccc.nvim",

    cmd = {
        "CccPick",
        "CccConvert",
    },

    keys = {
        {
            "<leader>cp",
            function()
                if vim.bo.filetype == "gdshader" then
                    vim.cmd("GDShaderEditColor")
                else
                    vim.cmd("CccPick")
                end
            end,
            desc = "Color Picker / GDShader Edit Color",
        },
    },

    config = function()
        local ccc = require("ccc")
        local utils = require("ccc.utils")

        -- 按当前通道总范围移动指定百分比
        local function shift_percent(percent)
            return function(core)
                local point = core.ui:point_at()

                if point.type == "color" then
                    local index = point.index
                    local input = core.color:input()

                    local value = input:get()[index]
                    local min = input.min[index]
                    local max = input.max[index]

                    -- 当前通道总范围的 percent%
                    local step = (max - min) * percent / 100

                    local new_value = utils.clamp(value + step, min, max)

                    input:callback(index, new_value)
                elseif point.type == "alpha" then
                    local value = core.color.alpha:get()

                    if value then
                        core.color.alpha:set(utils.clamp(value + percent / 100, 0, 1))
                    end
                end

                core.ui:update()
                core:set_color()
            end
        end

        ccc.setup({
            mappings = {
                H = shift_percent(-10),
                L = shift_percent(10),
            },
        })
    end,
}
