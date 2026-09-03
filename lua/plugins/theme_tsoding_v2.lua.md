return {
    "xLeapProtocol/ring0-dark.nvim",

    lazy = false,
    priority = 1000,

    config = function()
        ------------------------------------------------------------
        --
        ------------------------------------------------------------

        -- 然后覆盖自定义高亮（主题加载后应用才会生效）
        local color_status = "#252525"
        local highlights = {
            -- 行号设置 (fg: 文字颜色, bg: 背景颜色)
            LineNr = { fg = "#616161", bg = "NONE" },
            CursorLineNr = { bg = "NONE" },
            -- 其他区域设置 (需要时取消注释)
            SignColumn = { bg = "NONE" },
            StatusLine = { bg = color_status },
            StatusLineNC = { bg = color_status },

            ----------------------------------------
            -- Ufo color
            ----------------------------------------

            -- 真正的 Neovim 折叠行背景
            Folded = {
                bg = "#181818",
            },
            --
            -- UFO 普通折叠行
            UfoFoldedBg = {
                bg = "#181818",
            },
        }

        -- 应用自定义高亮
        for group, opts in pairs(highlights) do
            vim.api.nvim_set_hl(0, group, opts)
        end

        -- 延迟再次应用，确保覆盖主题设置
        vim.schedule(function()
            for group, opts in pairs(highlights) do
                vim.api.nvim_set_hl(0, group, opts)
            end
        end)

        ------------------------------------------------------------
        --
        ------------------------------------------------------------

        local hl = vim.api.nvim_set_hl

        -- ring0-dark + Tsoding / original Gruber Darker semantics
        --
        -- 保留 ring0-dark 的整体感觉，
        -- 但是去掉大量 italic，并恢复 Tsoding 那套语义颜色。
        local c = {
            -- ring0 normal foreground，个人认为比原版 Gruber 更舒服
            fg = "#cdd6f4",

            -- original Gruber Darker
            fg_bright = "#f4f4ff",
            bg = "#181818",
            bg_light = "#282828",

            yellow = "#ffdd33",
            green = "#73c936",
            brown = "#cc8c3c",

            quartz = "#95a99f",
            niagara = "#96a6c8",

            red = "#f43841",
        }

        local function apply_tsoding_highlights()
            ----------------------------------------------------------------
            -- UI
            ----------------------------------------------------------------

            -- ring0 原版这里居然 italic=true
            hl(0, "CursorLine", {
                bg = c.bg_light,
            })

            hl(0, "TelescopeSelection", {
                fg = c.fg,
                bg = c.bg_light,
            })

            hl(0, "StatusLine", {
                fg = c.fg,
                bg = "#252525",
            })

            hl(0, "StatusLineNC", {
                fg = "#777777",
                bg = "#252525",
            })

            hl(0, "LineNr", {
                fg = "#616161",
                bg = "NONE",
            })

            hl(0, "CursorLineNr", {
                fg = c.yellow,
                bg = "NONE",
                bold = true,
            })

            ----------------------------------------------------------------
            -- Classic Vim highlight groups
            --
            -- 这部分基本按照 Tsoding 的 gruber-darker-theme.el 映射
            ----------------------------------------------------------------

            -- comments: brown, NO italic
            hl(0, "Comment", {
                fg = c.brown,
            })

            -- strings: green, NO italic
            hl(0, "String", {
                fg = c.green,
            })

            -- constants: quartz
            hl(0, "Constant", {
                fg = c.quartz,
            })

            -- functions: Niagara blue-gray
            hl(0, "Function", {
                fg = c.niagara,
            })

            -- variables / identifiers: almost white
            hl(0, "Identifier", {
                fg = c.fg_bright,
            })

            -- types: quartz, NO bold
            hl(0, "Type", {
                fg = c.quartz,
            })

            -- if / else / return / for / while / struct ...
            hl(0, "Statement", {
                fg = c.yellow,
                bold = true,
            })

            -- #include / #define ...
            hl(0, "PreProc", {
                fg = c.quartz,
            })

            -- operators don't need to scream for attention
            hl(0, "Operator", {
                fg = c.fg,
            })

            ----------------------------------------------------------------
            -- Tree-sitter
            --
            -- Neovim 现在大量语法颜色实际上来自这些 @ capture，
            -- 所以只覆盖 Comment / Function 等还不够。
            ----------------------------------------------------------------

            local links = {
                -- comments
                ["@comment"] = "Comment",
                ["@comment.documentation"] = "Comment",

                -- strings
                ["@string"] = "String",
                ["@string.documentation"] = "String",
                ["@string.regexp"] = "String",

                -- variables
                ["@variable"] = "Identifier",
                ["@variable.builtin"] = "Identifier",
                ["@variable.parameter"] = "Identifier",
                ["@variable.member"] = "Identifier",

                -- constants / numbers
                ["@constant"] = "Constant",
                ["@constant.builtin"] = "Constant",
                ["@number"] = "Constant",
                ["@number.float"] = "Constant",
                ["@boolean"] = "Constant",

                -- functions
                ["@function"] = "Function",
                ["@function.call"] = "Function",
                ["@function.method"] = "Function",
                ["@function.method.call"] = "Function",
                ["@constructor"] = "Function",

                -- types
                ["@type"] = "Type",
                ["@type.builtin"] = "Type",
                ["@type.definition"] = "Type",

                -- keywords
                ["@keyword"] = "Statement",
                ["@keyword.function"] = "Statement",
                ["@keyword.type"] = "Statement",
                ["@keyword.modifier"] = "Statement",
                ["@keyword.conditional"] = "Statement",
                ["@keyword.repeat"] = "Statement",
                ["@keyword.return"] = "Statement",
                ["@keyword.import"] = "Statement",
                ["@keyword.exception"] = "Statement",
                ["@keyword.coroutine"] = "Statement",

                -- preprocessor
                ["@keyword.directive"] = "PreProc",
                ["@keyword.directive.define"] = "PreProc",
                ["@constant.macro"] = "PreProc",
                ["@function.macro"] = "PreProc",

                -- punctuation / operators stay quiet
                ["@operator"] = "Operator",
                ["@punctuation.delimiter"] = "Normal",
                ["@punctuation.bracket"] = "Normal",
            }

            for group, target in pairs(links) do
                hl(0, group, { link = target })
            end

            ----------------------------------------------------------------
            -- Builtins
            --
            -- Original Gruber Darker uses yellow for builtin symbols,
            -- but unlike normal keywords they aren't necessarily bold.
            ----------------------------------------------------------------

            hl(0, "TsodingBuiltin", {
                fg = c.yellow,
            })

            hl(0, "@function.builtin", {
                link = "TsodingBuiltin",
            })

            ----------------------------------------------------------------
            -- diagnostics
            ----------------------------------------------------------------

            hl(0, "DiagnosticError", {
                fg = c.red,
                bold = true,
            })

            hl(0, "DiagnosticWarn", {
                fg = c.yellow,
                bold = true,
            })
        end

        ------------------------------------------------------------------
        -- ring0dark 的 colorscheme 自己会执行 setup()
        ------------------------------------------------------------------

        vim.cmd.colorscheme("ring0dark")

        -- 当前加载立即应用
        apply_tsoding_highlights()

        -- 有些插件启动稍晚，再覆盖一次
        vim.schedule(apply_tsoding_highlights)

        -- 以后 :colorscheme ring0dark 时也不会丢失
        local group = vim.api.nvim_create_augroup("Ring0TsodingOverrides", { clear = true })

        vim.api.nvim_create_autocmd("ColorScheme", {
            group = group,
            pattern = "ring0dark",
            callback = function()
                vim.schedule(apply_tsoding_highlights)
            end,
        })
    end,
}
