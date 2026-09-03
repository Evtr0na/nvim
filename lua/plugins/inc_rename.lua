return {
    "smjonas/inc-rename.nvim",
    -- 启动条件 1：仅在 LSP 附加 (LspAttach) 到缓冲区时按需加载，节省启动时间
    event = "LspAttach",

    -- 启动条件 2（可选）：如果你希望输入快捷键时才强制加载，可以使用 keys 延迟加载
    -- keys = {
    --   { "<leader>rn", ":IncRename ", desc = "IncRename" },
    -- },

    opts = {
        -- 默认使用的命令名称，默认为 IncRename
        cmd_name = "IncRename",
        -- 设置为 true 时，重命名时输入框将使用当前光标下的变量名填充
        insert_inc_rename_cmd = true,
        -- 在按 <CR> 确认重命名后，自动将重命名结果记录到 undo 历史中
        show_message = true,
    },

    config = function(_, opts)
        require("inc_rename").setup(opts)

        -- 设置快捷键绑定
        -- 配合 LSP 重命名快捷键（常见为 <leader>rn）
        --
        -- gdshader / gdshaderinc 没有 LSP server，
        -- 交给 gdshader-nvim-support 的 :GDShaderRename 处理；
        -- 其余文件类型仍用 inc-rename 的 LSP 重命名。
        vim.keymap.set("n", "<leader>rn", function()
            if vim.bo.filetype == "gdshader" or vim.bo.filetype == "gdshaderinc" then
                return ":GDShaderRename<CR>"
            end

            return ":IncRename " .. vim.fn.expand("<cword>")
        end, { expr = true, desc = "Incremental Rename (LSP / GDShader)" })
    end,
}
