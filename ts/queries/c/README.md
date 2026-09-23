# ts/queries/c/

C 语言的 treesitter 查询规则，**从 `nvim-treesitter` 内置版本复制而来**。

## 为什么 GLSL 需要这个目录

`../glsl/` 的 5 个规则文件全部以 `; inherits: c` 开头，Neovim 加载
GLSL 规则时会连带加载本目录的规则。GLSL 高亮里绝大部分捕获
（`type.builtin`、`function.call`、`number`、`punctuation.*`、`comment` …）
实际都由这里提供。

**删掉本目录会导致 `.glsl` 几乎失去高亮。**

## 注意两点

**1. 这里只需要 queries，不需要 `parser/c.so`**

Neovim 内核自带 C 的 parser（打开 `.c` 文件本来就能高亮），
所以 `ts/parser/` 下没有 `c.so` 是正常的，不是漏装。

**2. 本目录同时影响 `.c` / `.h` 文件的高亮**

如果你编辑 C 代码时发现高亮行为变了，检查这里 —— 它排在
`$VIMRUNTIME/queries/c/` 之前被命中，会覆盖内置规则。

## 更新

```powershell
Copy-Item "$env:LOCALAPPDATA\nvim-data\lazy\nvim-treesitter\runtime\queries\c\*" `
          "$env:LOCALAPPDATA\nvim\ts\queries\c\" -Force
```

除非是为了修 GLSL 的某个高亮问题，否则**不建议改这里的内容** ——
改内部规则属于「连带影响 `.c` 文件」，不如改 `../glsl/highlights.scm`
加一条 GLSL 专属规则。
