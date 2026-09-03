vim.lsp.config("gdshader_lsp", {
    cmd = {
        "D:/2zhuomian/app/neovim-tool/gdshader-lsp-cpp/gdshader_lsp_release_windows.exe",

        "--stdio",
    },
    filetypes = {
        "gdshader",
        "gdshaderinc",
    },
    root_markers = {
        "project.godot",
        ".git",
    },
})

vim.lsp.enable("gdshader_lsp")
