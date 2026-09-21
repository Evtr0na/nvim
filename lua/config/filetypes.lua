vim.filetype.add({
    extension = {
        gdshader = "gdshader",
        gdshaderinc = "gdshaderinc",
        -- 部分 Godot 插件（如 shadowglass）用 .glslinc 放纯 GLSL 头文件，
        -- Neovim 内置的 filetype 表里没有这个扩展名，不映射就完全没高亮。
        glslinc = "glsl",
    },
})
