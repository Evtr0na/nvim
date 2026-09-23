# ts/parser/ —— treesitter 编译产物

放 `<语言名>.so`，文件名**必须**与 Neovim 查询 parser 时用的语言名一致
（`glsl` 文件类型查 `glsl`，所以这里是 `glsl.so`）。

## 现有

| 文件 | 大小 | revision |
| --- | --- | --- |
| `glsl.so` | 898 KB | `24a6c8ef698e4480fecf8340d771fbcb5de8fbb4` |

来源：https://github.com/tree-sitter-grammars/tree-sitter-glsl

## 换机器必须重新编译

`.so` 与**平台和 CPU 架构**绑定。这个文件是在 Windows + MinGW gcc 下编出来的，
拷到 Linux / macOS / 不同的 nvim 构建上都用不了（`dlopen` 会失败）。

```powershell
$rev  = "24a6c8ef698e4480fecf8340d771fbcb5de8fbb4"
$work = "$env:TEMP\ts-glsl"

git clone https://github.com/tree-sitter-grammars/tree-sitter-glsl $work
git -C $work checkout $rev

gcc -O2 -shared -fPIC -I "$work\src" `
    -o "$env:LOCALAPPDATA\nvim\ts\parser\glsl.so" "$work\src\parser.c"
```

### 两个必须注意的点

**1. 用 gcc，不要用 MSVC 的 `cl.exe`**

这个 `.so` 是给 libnvim 加载的，而本机的 nvim 是 GCC 构建的
（`nvim-win64` 发行版）。编译器不匹配时符号/异常处理约定不一致，加载会崩。
本机 `gcc` 在 `D:\2zhuomian\app\mingw64\mingw64\bin\gcc.exe`。

**2. 验证符号导出**

编完确认里面有 `tree_sitter_glsl`：

```powershell
gcc -shared -fPIC -I "$work\src" -Wl,--output-def,"$work\glsl.def" `
    -o NUL "$work\src\parser.c"
Select-String -Path "$work\glsl.def" -Pattern tree_sitter_
```

## 为什么不装到默认位置

`nvim-treesitter` 主分支默认装到 `stdpath("data")/site/`，但那份目录
不在配置仓库里，换机器就得重新想「我之前装过什么」。

放在这里跟着配置走。代价是 `:TSInstall` / `:TSUpdate` 管不到本目录，
必须手动编译（上面的命令）。

## 加载流程

```
lua/config/lazy.lua
    performance.rtp.paths = { stdpath("config") .. "/ts" }
        ↓
Neovim 的 runtimepath 多了 <config>/ts
        ↓
vim.treesitter.language.add("glsl")
    → 在 runtimepath 的 parser/ 下找 glsl.so
        ↓
lua/plugins/nvim-treesitter.lua 的 FileType autocmd 里
    vim.treesitter.start()
```

排查"高亮没生效"时按这个链条逐段确认：

```vim
:lua =vim.api.nvim_get_runtime_file("parser/glsl.so", true)   " 非空 = 找得到
:lua =vim.treesitter.language.add("glsl")                      " true = 能加载
:lua =vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()]
```
