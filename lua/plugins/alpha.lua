--终端指令：
--img2art "lboli.jpg" --scale 0.1 --alpha --quant 16 --save-raw "C:\Users\SDD\AppData\Local\nvim\lua\alpha_images\iboli.lua"
--img2art "lboli.jpg" --scale 0.15 --alpha --quant 16  --mapping "@%#*+=-:. "   --save-raw "C:\Users\SDD\AppData\Local\nvim\lua\alpha_images\iboli2.lua"
--img2art "liboli3333.jpg" --scale 0.2 --alpha --quant 3  --save-raw "C:\Users\SDD\AppData\Local\nvim\lua\alpha_images\liboli111.lua"
--参考：https://github.com/NexohLab/LightningNvim/blob/master/lua/plugins/ui/alpha.lua-
--img2art: https://github.com/Asthestarsfalll/img2art
--
--参数:
--img2art "rem.jpg" \
--scale 0.15 \           # 调小图片尺寸
--alpha \                # 生成 alpha-nvim 格式
--quant 16 \             # 减少颜色数，缩小文件
--mapping "@%#*+=-:. " \ # 用纯 ASCII 字符（如果你喜欢这种风格）
--save-raw "C:\Users\SDD\AppData\Local\nvim\lua\header.lua"
--
--目前可以选壁纸：
--Ram
--iboli
return {
    "goolord/alpha-nvim",
    event = "VimEnter",
    config = function()
        local alpha = require("alpha")
        local dashboard = require("alpha.themes.dashboard")

        -- 固定加载 header
        local header = require("alpha_images.eva") -- header.lua 在 lua/ 下

        -- 自定义布局
        dashboard.config.layout = {
            { type = "padding", val = 3 },
            header, -- 直接使用
            { type = "padding", val = 2 },
            -- dashboard.section.buttons, -- 如果有按钮
            { type = "padding", val = 2 },
            dashboard.section.footer,
        }

        -- 关键：覆盖 opts.layout
        dashboard.opts.layout = dashboard.config.layout

        alpha.setup(dashboard.opts)
    end,
}
