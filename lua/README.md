# lua/ —— 配置主体

Neovim 从这里加载所有 Lua 代码。`init.lua` 在配置根目录，本目录下的
模块用 `require("config.options")` 这种形式引用（路径中的 `/` 换成 `.`，
且**不带 `.lua` 后缀**）。

## 五个子目录的职责

| 目录 | 放什么 | 什么时候执行 |
| --- | --- | --- |
| `config/` | 启动期必须执行一次的设置 | 每次启动 |
| `lang/` | 某种语言的完整子系统 | 每次启动（注册 autocmd） |
| `util/` | 按需调用的工具模块 | 被 require 时 |
| `assets/` | 静态数据（图片转成的 Lua 表） | 被 require 时 |
| `plugins/` | lazy.nvim 的插件声明 | 由 lazy 调度 |

## 怎么决定新文件放哪

按「**谁触发它**」判断，不是按「它跟什么有关」：

- 打开 Neovim 就该生效 → `config/`
- 打开某类文件、或写完文件才跑 → `lang/`
- 按了某个键、或某个插件调用它才跑 → `util/`
- 是数据不是逻辑 → `assets/`
- 是某个插件的配置 → `plugins/`

举几个容易放错的例子：

| 文件 | 该放哪 | 为什么 |
| --- | --- | --- |
| 一段给 flash.nvim 用的自定义跳转逻辑 | `util/` | 由 `plugins/flash.lua` 的按键触发 |
| multicursor 的自定义选择模式 | `util/` | 由 `<leader>m` 触发 |
| glslang 校验器（含 autocmd + 命令） | `lang/` | 按文件类型触发 |
| 快捷键表 | `config/` | 启动就该就位 |
| 某个插件的 `opts` | `plugins/` | 属于插件声明 |

**最常见的放错**：把「插件用到的工具函数」塞进 `config/`。
`config/` 里应该只有启动期跑一次的东西，塞进去会让「启动做了什么」
变得很难看清。

## 本目录根下的文件

- `bootstrap.lua` —— 只负责下载 / 定位 lazy.nvim 本体并在 init.lua
  最开头加载它。不放进 `config/`，因为它必须在所有 `config.*`
  之前执行，混在一起容易看不出这个先后关系。

## 相关

- 目录约定的总览写在配置根目录的 `init.lua` 头部注释里。
- treesitter parser 与 queries 不在本目录，在配置根目录的 `ts/`。
- `after/` 是 Vim runtime 覆盖层，与 `lua/` 平级，加载顺序不同。
