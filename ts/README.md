# ts/ —— Treesitter parser 与 queries

这个目录是 Neovim 的 runtimepath 的一部分（由 `lua/config/lazy.lua` 里的
`performance.rtp.paths` 挂上）。
目录布局就是 Neovim 的标准布局：

```
ts/
├── parser/
│   ├── README.md           编译产物的说明；换机器要重编（平台相关）
│   └── glsl.so             ← 二进制，898 KB
└── queries/
    ├── README.md           查询规则的说明；纯文本，跨平台通用
    ├── glsl/               5 个 .scm，当前实际使用
    └── c/                  glsl 的规则靠它（`; inherits: c`）
```

两个子目录各自有 README，分别讲编译和查询规则。本文件讲整体取舍。

## 为什么不用 nvim-treesitter 默认的安装目录

`nvim-treesitter` 主分支默认把 parser 装到 `stdpath("data")/site/`，
那份目录不在本仓库里。放在这里的两个好处：

1. 跟着配置走，换机器/重装不用重新想「我之前装过什么」；
2. 可以进版本库（`.so` 除外，见下）。

代价：`require("nvim-treesitter").install()` 和 `:TSUpdate` 仍然只认
`stdpath("data")/site/`，不会碰这个目录。更新 parser 要手动编译（见下）。

## 当前已装

| 语言 | 版本 / revision | 来源 |
| --- | --- | --- |
| `glsl` | `24a6c8ef698e4480fecf8340d771fbcb5de8fbb4` | https://github.com/tree-sitter-grammars/tree-sitter-glsl |
| `c` | 未装 parser | queries 来自 nvim-treesitter 内置 |

`c` **只有 queries 没有 parser**：glsl 的 5 个 query 文件内容全是
`; inherits: c`，所以需要 C 的 query 规则；但 Neovim 自带 C 的 parser
（高亮 `*.c` 本来就能用），无需重复编译。

## 重新编译 glsl parser

`.so` 与平台和 CPU 架构绑定，**换机器必须重编**。Windows + MinGW 下：

```powershell
$rev = "24a6c8ef698e4480fecf8340d771fbcb5de8fbb4"
$work = "$env:TEMP\ts-glsl"

git clone https://github.com/tree-sitter-grammars/tree-sitter-glsl $work
git -C $work checkout $rev

# 必须用 gcc，不要用 MSVC 的 cl.exe：
# parser.so 是给 libnvim（GCC 构建）dlopen 的，编译器不匹配会崩。
gcc -O2 -shared -fPIC -I "$work\src" -o "$PWD\ts\parser\glsl.so" "$work\src\parser.c"
```

验证符号导出（应该看到 `tree_sitter_glsl`）：

```powershell
gcc -shared -fPIC -I "$work\src" -Wl,--output-def,"$work\glsl.def" -o NUL "$work\src\parser.c"
Select-String -Path "$work\glsl.def" -Pattern tree_sitter_
```

为什么不用 `tree-sitter build`：那个 CLI 会在 `%LOCALAPPDATA%\tree-sitter\lock\`
下建锁文件，配合 `tree-sitter.json` 才能改路径；直接 gcc 更可控，
而且不依赖 tree-sitter CLI 是否装好。

## 更新 queries

queries 直接抄 `nvim-treesitter` 内置的那份：

```powershell
$tsq = "$env:LOCALAPPDATA\nvim-data\lazy\nvim-treesitter\runtime\queries"
Copy-Item "$tsq\glsl\*" ".\ts\queries\glsl\" -Force
Copy-Item "$tsq\c\*"    ".\ts\queries\c\"    -Force
```

注意：`glsl/folds.scm`、`indents.scm`、`injections.scm`、`locals.scm`
都只有 14 字节（就是 `; inherits: c`），实际规则全来自 `c/`。

## 加新语言

1. 编译 `<lang>.so` 放进 `ts/parser/`；
2. 把 queries 放进 `ts/queries/<lang>/`；
3. 在 `lua/plugins/nvim-treesitter.lua` 的 `FileType` autocmd 里加上文件类型。

## 验证

```vim
:checkhealth nvim-treesitter
```

或者开一个 `.glsl` 文件，`current_syntax` 变成空、`b.ts_highlight` 为 `true`
就说明 treesitter 已经接管（legacy 正则高亮会主动让位）。
