# after/syntax/ —— 语法规则覆盖

放**补充或覆盖**内置语法规则的文件，文件名必须与 filetype 同名
（`gdshaderinc.vim` → `ft=gdshaderinc`）。

## 现有文件

### `gdshaderinc.vim`

```vim
runtime! syntax/gdshader.vim
```

只有一行，解决一个具体的缺口：

- Neovim 内置 `syntax/gdshader.vim`，文件头声明 `Filenames: *.gdshader`，
  **不覆盖 `*.gdshaderinc`**
- 所以 `ft=gdshaderinc` 时 `b:current_syntax` 一直是空的 → 完全没高亮
- `gdshader-nvim-support` 插件只提供 ftplugin，不提供语法文件
- 于是这里直接复用 `gdshader` 的规则（两者语法基本一致）

`runtime!` 的 `!` 表示「加载所有匹配的文件」，这里指内置那份。

## 加新文件时

```vim
" after/syntax/<filetype>.vim
runtime! syntax/已有语法.vim      " 复用别人的
" 或者
syn keyword 我的关键字 ...
highlight def link 我的关键字 Type
```

**优先用 `runtime!` 复用**，而不是复制粘贴一份语法规则 ——
内置语法更新时自动跟着变。

## 相关

| 内容 | 位置 |
| --- | --- |
| 扩展名 → filetype 映射 | `lua/config/filetypes.lua`（`glslinc = "glsl"` 在那儿） |
| treesitter 的语法高亮 | 配置根目录 `ts/queries/<lang>/` |
| gdshader 相关插件配置 | `lua/plugins/gdshader-nvim-support.lua` |

## 一个区别

`after/syntax/` 是 **legacy 正则高亮**（Vim 的 `:syntax` 系统）。
treesitter 的高亮走完全不同的通道（`queries/*.scm`）。

对于 `gdshader` / `gdshaderinc`，目前用的是正则高亮（内核自带，质量够用）；
对于 `glsl`，已经由 treesitter 接管。两套系统可以在不同文件类型上共存。
