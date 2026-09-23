-- Treesitter 高亮（主分支 nvim-treesitter，Neovim 0.12 原生 API）
--
-- 这个插件只负责「装 parser / queries」，高亮本身由 Neovim 内置的
-- vim.treesitter.start() 提供，所以必须自己挂 FileType autocmd。
--
-- parser 和 queries 放在配置文件目录的 ts/ 下（见 config/treesitter_path.lua），
-- 不走 nvim-treesitter 默认的 stdpath("data")/site。

local LANGUAGES = {
    "glsl",
    "c", -- glsl 的 5 个 query 文件全是 `; inherits: c`，没有它高亮只剩一小部分
}

return {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    -- 不挂 build = ":TSUpdate"：本项目的 parser 放在 ts/ 下（见 README），
    -- :TSUpdate 只认 stdpath("data")/site，挂上去只会造成"更新过了"的错觉。

    config = function()
        ------------------------------------------------------------
        -- 高亮接管
        ------------------------------------------------------------
        -- glsl 文件类型：
        --   .glsl / .vert / .frag / .comp / .glslinc
        -- gdshader / gdshaderinc 暂不接管 —— Neovim 自带的
        -- syntax/gdshader.vim 质量已经够用，加进来收益不大。
        vim.api.nvim_create_autocmd("FileType", {
            pattern = { "glsl" },
            callback = function()
                -- 解析器缺失时静默跳过，而不是每次开文件都弹错。
                if not vim.treesitter.language.add("glsl") then
                    return
                end

                vim.treesitter.start()
            end,
        })

        ------------------------------------------------------------
        -- 可选：缩进也交给 treesitter
        ------------------------------------------------------------
        -- 先不默认开启。glsl 的 indents.scm 只有 14 字节（`; inherits: c`），
        -- 走的完全是 C 的缩进规则，对 GLSL 的 layout(...) 折行未必友好。
        -- 想试的话把下面打开，对比一下再决定：
        --
        -- vim.api.nvim_create_autocmd("FileType", {
        --     pattern = { "glsl" },
        --     callback = function()
        --         vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        --     end,
        -- })

        ------------------------------------------------------------
        -- 安装 / 更新
        ------------------------------------------------------------
        -- 本机沙箱环境下 nvim 无法派生子进程，这里不做自动安装。
        -- 需要装语言时手动跑：
        --
        --     :lua require("nvim-treesitter").install({ "glsl", "c" })
        --
        -- 注意：它会用 curl 下载源码再用 tree-sitter CLI 编译，
        -- 装到 stdpath("data")/site —— 想跟配置放一起就手动编译后
        -- 把 .so 丢进 ts/parser/。检查状态用 :checkhealth nvim-treesitter。
    end,
}
