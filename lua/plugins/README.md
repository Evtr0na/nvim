# lua/plugins/ —— 插件声明

lazy.nvim 会扫描本目录下的 `*.lua`，每个文件返回一个（或一组）插件声明。
当前 27 个文件，约 1851 行。

## 停用插件：改后缀为 `.md`

这是本仓库的约定 —— **想看某个插件的配置，但暂时不想加载它，
就把 `xxx.lua` 改名成 `xxx.lua.md`**。lazy 只认 `*.lua`，`.md` 会被静默忽略。

当前停用的 7 个：

| 文件 | 原始插件 |
| --- | --- |
| `appman.lua.md` | 本机应用启动器 |
| `avante.lua.md` | AI 助手（avante.nvim） |
| `codecompanion.lua.md` | AI 助手（codecompanion.nvim） |
| `dashboard.lua.md` | 备用启动页 |
| `opencode.lua.md` | AI 助手（opencode.nvim） |
| `telescope.lua.md` | 模糊查找（已被 fzf-lua 取代） |
| `theme_koda.lua.md` | 备用配色主题 |

**改回 `.lua` 即可启用**，配置本身是完整可用的，不用改内容。

> 注意：`.md` 后缀会丢掉 Lua 语法高亮、luals 补全和 stylua 格式化。
> 如果需要编辑这些停用配置，临时改回 `.lua` 再改回去更舒服。
>
> 另外这三个 AI 插件目前是「配置停用了但插件本体还装着」的状态
> （仍在 `lazy-lock.json` 里）。想彻底移除要跑 `:Lazy clean`。

## 文件结构

每个文件返回 lazy.nvim 的插件 spec：

```lua
return {
    "作者/仓库名",
    event = "VeryLazy",         -- 加载时机：启动时/事件/按键/ft
    keys = { ... },             -- 按键（会触发按需加载）
    dependencies = { ... },
    opts = { ... },             -- 传给插件 setup() 的表
    config = function(_, opts)  -- 需要写命令时用它代替 opts
        require("插件名").setup(opts)
    end,
}
```

也可以返回一个列表来在一个文件里放多个相关插件（见 `gdscript.lua`，
它同时声明了 `godot-instance.nvim` 和 `godotdev.nvim`）。

## 放这里的判断标准

- **是这个插件自己的配置** → 放这里
- **是插件调用的业务逻辑** → 放 `lua/util/`，这里只留一行 `require` 调用
- **与插件无关的全局设置** → 放 `lua/config/`

例如 `flash.lua` 只有 89 行，因为它把 315 行的自定义跳转逻辑放在了
`lua/util/flash_jump.lua`，这里只负责声明插件和按键。

## 相关

| 内容 | 位置 |
| --- | --- |
| 插件版本锁定 | 配置根目录 `lazy-lock.json`（**要提交进 git**） |
| `Untitled` | 本目录下的历史遗留日志文件（codecompanion 的 WARN 输出），可删 |
| treesitter parser | 不在插件目录，在配置根目录 `ts/` |
