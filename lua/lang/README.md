# lua/lang/ —— 语言子系统

放「**某种语言的完整处理逻辑**」。一个语言一个文件，文件里可以包含
autocmd、用户命令、解析器、外部工具调用 —— 只要它们服务的是同一种语言。

## 现有文件

| 文件 | 作用 |
| --- | --- |
| `glslang.lua` | GLSL / Godot RDShaderFile 的校验器（707 行） |

`glslang.lua` 干了这些事：

- 调用外部 `glslangValidator`（需自行安装，不在 PATH 里会 `vim.notify_once` 提示）
- 从文件名 / 文件头 / 源码特征推断 shader 阶段（vert / frag / comp / …）
- 识别 Godot 的 `#[vertex]` / `#[fragment]` 分段格式，分段后逐段校验
- 把 glslang 的输出解析成 `vim.diagnostic`，行号与源文件对齐
- 注册 3 事件 × 11 扩展名的 autocmd（`BufReadPost` / `BufWritePost` / `InsertLeave`）
- 提供 `:GLSLang` 手动触发

## 和 `config/` 的区别

两者都在启动时执行，区别在**触发方式**：

- `config/` 里的东西启动即生效，跟你在编辑什么文件无关；
- `lang/` 里的东西启动时只是**注册**（autocmd / 命令），真正干活是在
  你打开或保存对应类型的文件时。

所以判断标准：**这个逻辑是不是只对某类文件有意义？** 是 → 放这里。

## 加新语言时

比如要给 GDScript 加一套自定义检查：

1. 新建 `lua/lang/gdscript.lua`
2. 在 `init.lua` 的「语言子系统」段落里 `require("lang.gdscript")`
3. 文件内部自己注册 autocmd，用 `pattern = { "gd", "gdscript" }` 之类限定范围

不要在这个文件里塞通用的东西（选项、全局快捷键）—— 那些属于 `config/`。

## 与其他目录的边界

容易混淆的几处：

| 相关功能 | 在哪 | 为什么不在 lang/ |
| --- | --- | --- |
| 扩展名 → filetype 映射 | `lua/config/filetypes.lua` | 只是一张映射表，没有逻辑 |
| treesitter parser / queries | 配置根目录 `ts/` | 是二进制和数据，不是逻辑 |
| 语言服务器的启动配置 | `lua/plugins/nvim-lspconfig.lua` | 属于插件声明 |
| 某文件类型的 ftplugin | 目前没有 | 如需要，建 `after/ftplugin/<ft>.lua` |
