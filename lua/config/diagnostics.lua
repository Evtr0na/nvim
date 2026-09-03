-- 1. 行号前显示诊断首字母

-- 2. 诊断显示配置
vim.diagnostic.config({
    -- 关闭行尾的大段诊断文字
    virtual_text = false,

    -- 行号左侧显示 E / W / H / I
    signs = true,

    -- 不给代码加下划线
    underline = false,

    -- 浮窗保留
    float = {
        border = "rounded",
        header = "",
        prefix = "",
    },
})
