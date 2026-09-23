# lua/assets/ —— 静态数据

放「**是数据不是逻辑**」的东西。这里没有函数、没有 autocmd，
全是 `return { ... }` 的大表格。

## 现有内容

```
assets/alpha/          alpha 启动页的 ASCII 图，每张图一个 .lua 文件
├── eva.lua            73 KB / 503 行   ← 当前使用
├── iboli.lua          16 KB / 200 行
├── iboli2.lua         72 KB / 129 行
├── iboli3.lua         33 KB / 365 行
├── iboli4.lua         22 KB / 130 行
├── liboli111.lua     227 KB / 461 行
└── Rem.lua           193 KB / 1379 行
```

一共约 1.4 MB，是整个配置里体积最大的部分。字母密度越高文件越大
（`liboli111.lua` 和 `Rem.lua` 用的是细字符集，所以特别大）。

## 怎么切换启动页的图

改 `lua/plugins/alpha.lua` 里这一行的模块名：

```lua
local header = require("assets.alpha.eva")   -- 换成 iboli / iboli2 / …
```

## 怎么生成新图

用 [img2art](https://github.com/Asthestarsfalll/img2art)，注意输出路径要指向
`lua/assets/alpha/`。完整的命令行示例在 `lua/plugins/alpha.lua` 开头的注释里。

## 注意事项

**这里的文件会被 Neovim 当模块加载**，所以：

- 文件名必须是合法 Lua 标识符（不能有空格、`-`、中文）
- 文件顶层不要写副作用代码（不要 `vim.cmd(...)`、不要 `print`）
- 必须 `return` 一个表

**加载时机**：`alpha.lua` 在 `VimEnter` 时 require，所以这些 1.4 MB 的表
只在启动页显示时才读进内存，不影响日常启动速度。

如果把 `alpha-nvim` 换成别的启动页插件（或停用），这个目录会变成死数据 ——
到时候整个 `assets/alpha/` 可以直接删掉，没有别的地方引用。
