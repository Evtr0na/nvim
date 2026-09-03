--a formatting tool

return {

    "stevearc/conform.nvim",

    -- 让 gdshader-nvim-support 先加载，以便它自动注册
    -- `gdshader` formatter（见其 format.lua）。

    dependencies = {},

    -- 不使用 BufWritePre
    -- 所以保存时不会格式化
    event = {
        "BufReadPost",
        "BufNewFile",
    },
    cmd = { "ConformInfo" },
    -- Formatting 命令提前注册
    opts = {

        formatters_by_ft = {
            -- 为 lua 文件指定格式化工具为 stylua
            lua = { "stylua" },
            gdscript = { "gdscript‑formatter" },
            -- GDShader：由 gdshader-nvim-support 自动注册 formatter
            gdshader = { "gdshader" },
            gdshaderinc = { "gdshader" },
            json = { "fixjson" },
        },
        -- 保存文件时自动格式化（如果不需要自动格式化，可直接删掉 format_on_save）
        -- format_on_save = {
        --     timeout_ms = 500,
        --     lsp_fallback = true,
        -- },
        formatters = {
            ["gdscript‑formatter"] = {
                command = "gdscript-formatter",
                args = { "--safe" }, --安全模式，防止格式化意外改变代码逻辑
                stdin = true,
            },
        },
    },

---------------------------------------------------------------------------
-- Formatting when visual
---------------------------------------------------------------------------
    config = function(_, opts)
        local conform = require("conform")

        conform.setup(opts)

        -- 官方 conform.nvim recipe 的方式
        vim.api.nvim_create_user_command("Formatting", function(args)
            local range = nil

            if args.count ~= -1 then
                local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]

            range = {
                start = { args.line1, 0 },
                ["end"] = { args.line2, end_line:len() },
            }
            end

            conform.format({
                async = true,
                lsp_format = "fallback",
                range = range,
            })
        end, {
            range = true,
        })

        -- 社区/官方推荐的 Visual 方式
        -- 同时留着用于验证

        vim.keymap.set("v", "<leader>f", function()
            conform.format({
                async = true,
                lsp_format = "fallback",
            })
        end, {
            desc = "Format selection",
        })
    end,
}
