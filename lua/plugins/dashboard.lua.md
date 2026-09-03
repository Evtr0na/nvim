-- lua/plugins/dashboard.lua
return {
    "nvimdev/dashboard-nvim",
    event = "vimenter",
    config = function()
        -- 配置选项：'random' 或指定模块名（如 "img2art.header"）
        local header_mode = "random" -- 可选 "random" 或 "img2art.my_header"
        -- 如果指定，请填写模块名（相对于 lua/ 目录），例如 "img2art.foo"

        local function get_header()
            local lines = {}

            if header_mode == "random" then
                -- 在 runtimepath 中搜索 lua/img2art/*.lua
                local files = vim.api.nvim_get_runtime_file("lua/img2art/*.lua", false)
                if #files == 0 then
                    lines = { "No header file found" }
                else
                    local chosen = files[math.random(#files)]
                    -- 加载并执行该文件，获取其返回值（应为一个 table）
                    local chunk, err = loadfile(chosen)
                    if chunk then
                        local ok, result = pcall(chunk)
                        if ok and type(result) == "table" then
                            -- 将每一行内容替换为 "这是一行"，保持行数
                            for i = 1, #result do
                                lines[i] = "这是一行"
                            end
                        else
                            lines = { "Failed to load header content" }
                        end
                    else
                        lines = { "Invalid file: " .. (err or "") }
                    end
                end
            else
                -- 指定加载某个模块（例如 "img2art.header"）
                local ok, mod = pcall(require, header_mode)
                if ok and type(mod) == "table" then
                    for i = 1, #mod do
                        lines[i] = "这是一行"
                    end
                else
                    lines = { "Specified header not found: " .. header_mode }
                end
            end

            -- 如果结果为空，给出默认占位
            if vim.tbl_isempty(lines) then
                lines = { "Welcome to Neovim" }
            end
            return lines
        end

        require("dashboard").setup({
            theme = "doom",
            config = {
                header = get_header, -- 使用函数动态生成 header
                center = {
                    {
                        desc = " ", -- 可根据需要修改
                    },
                },
            },
        })
    end,
}
