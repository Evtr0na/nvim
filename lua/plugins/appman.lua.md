return {
    dir = "D:/2zhuomian/app/source/appman",

    event = "VeryLazy",
    -- "path/to/appman", -- 指向本插件目录
    config = function()
        require("appman").setup({
            apps = {
                obsidian = {
                    name = "Obsidian",
                    path = [[D:\Apps\Obsidian\Obsidian.exe]],
                    singleton = true,
                },
            },
        })
    end,
}
