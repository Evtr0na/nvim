# lua/util/ —— 按需调用的工具模块

放「**被某个插件或按键触发才执行**」的逻辑。这里没有 `init.lua` 引用，
每个文件都是自己 `return M` 的模块，被 `require` 时才加载。

## 现有文件

| 文件 | 行数 | 被谁调用 |
| --- | --- | --- |
| `flash_jump.lua` | 315 | `plugins/flash.lua` 的 `s` 键 |
| `mc_mode.lua` | 268 | `plugins/multicursor.lua` 的 `<leader>m` 和 `<Esc>` |

**`flash_jump.lua`** —— 自定义的 flash 跳转：给非目标文字加灰色 virtual text
降低干扰，目标字符显示进度式提示，跳转完成后恢复。属于「对 flash.nvim 的包装」。

**`mc_mode.lua`** —— multicursor 的自定义选择模式：进入后可以用原生 Normal
操作逐个添加光标，`<Esc>` 退出时保留已选光标（而不是像默认那样清空）。
用 `vim.cmd("normal! ...")` 故意绕过用户自己的 mappings。

## 判断标准

问自己：**这个东西是不是只在特定时机才需要？**

- 是 → `util/`
- 打开 Neovim 就该生效 → `config/`
- 只对某类文件生效 → `lang/`

`util/` 的文件可以 `require` 插件（例如 `require("multicursor-nvim")`），
因为它们只在插件加载后才被调用。`config/` 里的文件**不能**这样做。

## 引用方式

从插件配置里引用时写完整模块路径：

```lua
-- lua/plugins/flash.lua
keys = {
    {
        "s",
        function()
            require("util.flash_jump").jump()
        end,
        desc = "Flash Jump",
    },
},
```

改动文件名后记得全局搜一遍旧路径：

```powershell
Get-ChildItem "$env:LOCALAPPDATA\nvim\lua" -Recurse -Filter *.lua |
    Select-String -Pattern 'config\.flash_jump|config\.mc_mode'
```

> 这两个文件原来放在 `config/` 下。搬过来的原因：它们不是启动期设置，
> 每次启动都躺在「配置」里会让人误以为启动时执行了它们。
