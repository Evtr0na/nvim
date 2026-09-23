# lua/config/ —— 启动期设置

只放「**打开 Neovim 就该生效**」的东西。这里每个文件都在 `init.lua`
里被 require 一次，按固定顺序执行。

## 现有文件

| 文件 | 作用 |
| --- | --- |
| `lazy.lua` | lazy.nvim 启动；把 `ts/` 挂到 runtimepath。**必须最后执行** |
| `options.lua` | `vim.opt.*` 选项、sessionoptions、颜色方案事件 |
| `keymaps.lua` | 快捷键（45 个）。不依赖任何模块 |
| `builtins.lua` | 禁用内置 runtime 插件（netrw、tar、zip 等），省约 10ms |
| `commands.lua` | 自定义 `:命令`（`:Math`、复制光标位置、路径转换等） |
| `filetypes.lua` | 扩展名 → filetype 映射（`.gdshader`、`.glslinc`） |
| `diagnostics.lua` | `vim.diagnostic.config()` 显示样式 |

## 加新文件时

放进来的东西必须满足：**启动时执行一次，且不需要任何插件**。

如果要依赖插件（比如需要 `nvim-treesitter` 提供的函数），就别放这里 ——
`config.*` 全部在 `lazy.setup()` 之前跑，那时插件还没加载。

正确的归属：

| 想做的事 | 放哪 |
| --- | --- |
| 加一个选项 / 快捷键 / 命令 | 这里 |
| 加一个插件用到的回调逻辑 | `lua/util/` |
| 加某种文件类型的处理（autocmd） | `lua/lang/` 或对应插件配置 |
| 加插件本身 | `lua/plugins/` |

## 加载顺序

`init.lua` 里的顺序是有意的，改动前先看一眼：

```
bootstrap                  ← lazy.nvim 本体，必须最先
config.options
config.keymaps
config.builtins
config.commands
config.filetypes
config.diagnostics
lang.glslang               ← 注册自己的 autocmd / 命令
config.lazy                ← lazy.setup()，放最后
```

`config.lazy` 必须在最后：lazy 会整体重写 runtimepath 并接管插件加载，
跑在它后面的东西容易被它重置掉（`ts/` 的挂载就是这么踩出来的坑，
详细注释在 `lazy.lua` 里）。

## 命名注意

`builtins.lua` 是从 `autocmds.lua` 改过来的 —— 它里面**没有任何 autocmd**，
全是 `vim.g.loaded_netrw = 1` 这类禁用内置插件的代码。叫 `autocmds` 会误导人
去里面找 autocmd。同理，加文件时名字要反映实际内容。
