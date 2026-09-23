# after/ —— Vim runtime 覆盖层

`after/` 与 `lua/` 平级，是 Neovim `runtimepath` 里**排在最后**的一段。
放这里的文件会在所有插件和内置 runtime 加载完之后才生效，
用来**覆盖**别人的定义。

## 什么时候才需要 after/

只有一种情况：**内置或插件已经提供了同名文件，你要改它的行为，
但不想直接改插件源码。**

如果是新功能（内置没有、插件也没有），放 `lua/` 或 `ftplugin/` 就行，
不需要 `after/`。

| 需求 | 放哪 |
| --- | --- |
| 内置已有 `syntax/foo.vim`，想补充规则 | `after/syntax/foo.vim` ✅ |
| 内置已有 `ftplugin/foo.vim`，想改缩进 | `after/ftplugin/foo.lua` ✅ |
| 给一个内置**没有**的文件类型写语法 | 直接放 `syntax/`，不用 after |
| 全局选项、快捷键 | `lua/config/`，跟 after 无关 |
| 插件配置 | `lua/plugins/` |

## 现有内容

```
after/syntax/gdshaderinc.vim      ← 目前唯一的文件，见该目录的 README
```

## 目前没有的目录

`after/ftplugin/`、`after/indent/`、`after/parser/` 都还没建。
需要时直接创建即可，Neovim 会自动识别。

> 注意 `parser/`：treesitter 的 parser **不要**放 `after/parser/`。
> 那些 `.so` 在配置根目录的 `ts/` 下，由 `lua/config/lazy.lua` 挂载。

## 为什么 after/ 的加载顺序重要

Neovim 的 runtimepath 大致是：

```
~/.config/nvim              ← 你的配置（get_runtime_file 优先命中）
~/.config/nvim/after        ← 覆盖层，最后加载
(lazy 管理的各插件)
$VIMRUNTIME                 ← Neovim 内置
```

所以 `after/` 里的定义能盖住内置的，反过来不行。这也是
`after/syntax/gdshaderinc.vim` 能生效的原因 —— 它要复用内置的
`syntax/gdshader.vim`，必须等内置的先加载。
