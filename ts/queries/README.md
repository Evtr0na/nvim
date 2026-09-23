# ts/queries/ —— treesitter 查询规则

放 `<语言名>/*.scm`，决定**语法树怎么变成高亮、折叠、缩进**。
这是纯文本规则，跨平台通用（不像 `parser/*.so` 需要重编）。

## 现有

```
queries/glsl/     ← 5 个规则文件，当前实际使用
queries/c/        ← glsl 依赖它，见下
```

## 五种 .scm 文件

| 文件 | 作用 | 谁在用 |
| --- | --- | --- |
| `highlights.scm` | 捕获节点 → 高亮组 | **Neovim 内核**（高亮主力） |
| `folds.scm` | 可折叠区域 | Neovim 内核 |
| `indents.scm` | 缩进规则 | `nvim-treesitter`（缩进没启用，见下） |
| `injections.scm` | 内嵌语言（如 Markdown 里的代码块） | Neovim 内核 |
| `locals.scm` | 变量作用域（用于引用高亮等） | 需要插件的功能 |

## 关键：`glsl/` 的实际规则全在 `c/` 里

看一下文件大小就知道：

```
queries/glsl/highlights.scm    468 bytes   ← 只有 GLSL 特有的少数关键字
queries/glsl/folds.scm          14 bytes   ← 内容就一行：; inherits: c
queries/glsl/indents.scm        14 bytes   ← 同上
queries/glsl/injections.scm     14 bytes   ← 同上
queries/glsl/locals.scm         14 bytes   ← 同上
```

`; inherits: c` 是 Neovim 的查询继承语法 —— 加载 `glsl` 的规则时，
会**先加载 `c` 的规则再叠加 glsl 自己的**。所以：

- `c/` **必须有**，否则 GLSL 高亮只剩一个 `keyword.modifier` 规则，等于没有
- `c/` 只需要 queries，**不需要 `parser/c.so`** —— Neovim 内核自带 C 的 parser
- `type.builtin`（`float`/`vec3`）、`function.call`、`number`、`punctuation.*`
  这些捕获全部来自 `c/`

## 更新

直接从 `nvim-treesitter` 内置的那份抄（它是各语言的权威版本）：

```powershell
$tsq = "$env:LOCALAPPDATA\nvim-data\lazy\nvim-treesitter\runtime\queries"
Copy-Item "$tsq\glsl\*" "$env:LOCALAPPDATA\nvim\ts\queries\glsl\" -Force
Copy-Item "$tsq\c\*"    "$env:LOCALAPPDATA\nvim\ts\queries\c\"    -Force
```

这里用的是**复制**不是软链接 —— Windows 建符号链接需要开发者模式或管理员权限，
复制更省事，代价是更新时要重跑上面的命令。

> `nvim-treesitter` 主分支的 `install()` 会尝试建 junction，
> 但它只操作 `stdpath("data")/site/queries/`，管不到本目录。

## 加新语言

1. 在 `ts/parser/` 放好 `<lang>.so`（见该目录 README）
2. 建 `ts/queries/<lang>/`，把对应 queries 复制进来
3. 若该语言的 rules 里有 `; inherits: X`，把 `queries/X/` 也一并放好
4. 在 `lua/plugins/nvim-treesitter.lua` 的 FileType autocmd 里加上文件类型

## 验证

```vim
" 查询能不能解析（语法错误会在这里暴露）
:lua =vim.treesitter.query.get("glsl", "highlights")

" 看当前缓冲区实际命中哪些捕获
:Inspect
```

## 注意

`indents.scm` 虽然存在，但缩进**没有**交给 treesitter（`lua/plugins/nvim-treesitter.lua`
里那段 `indentexpr` 是注释掉的）。因为 `glsl/indents.scm` 只是
`; inherits: c`，走的完全是 C 的缩进规则，对 GLSL 的 `layout(...)` 折行未必友好。
