# ts/queries/glsl/

GLSL 的高亮 / 折叠等查询规则。5 个文件：

| 文件 | 大小 | 内容 |
| --- | --- | --- |
| `highlights.scm` | 468 B | GLSL 特有部分：`layout`/`uniform`/`in`/`out` 等修饰符、`subroutine`、`gl_*` 内置变量 |
| `folds.scm` | 14 B | 只有一行 `; inherits: c` |
| `indents.scm` | 14 B | 同上（缩进当前没启用） |
| `injections.scm` | 14 B | 同上 |
| `locals.scm` | 14 B | 同上 |

**关键**：`highlights.scm` 第一行也是 `; inherits: c`，意思是先加载
`../c/` 的规则再叠加本文件。所以 `float`/`vec3` 的类型高亮、函数调用、
数字、标点这些捕获全部来自 `../c/`，本文件只负责 GLSL 独有的关键字。

改本目录前请先看 `../README.md`（讲了继承机制和更新方法）。

## 快速验证改动

```vim
:lua =vim.treesitter.query.get("glsl", "highlights")   " nil 或报错 = 规则有语法错误
:Inspect                                                " 看光标处命中的捕获
```

改完需要重开缓冲区（或 `:edit`）才会重新读取规则。
