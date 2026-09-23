-- ============================================================
-- Neovim 配置入口
-- ============================================================
-- 目录约定（改配置前先看这里，避免又放错位置）：
--
--   lua/config/   启动期必须执行一次的设置
--                 options / keymaps / builtins / commands
--                 filetypes / diagnostics / lazy
--   lua/lang/     语言相关的完整子系统（如 glslang 校验器）
--   lua/util/     按需调用的工具模块（由插件按键触发）
--   lua/plugins/  lazy.nvim 的插件声明；*.md 后缀 = 已停用
--   lua/assets/   启动页 ASCII 图等静态数据
--   after/        Vim runtime 覆盖层（加载顺序敏感）
--   ts/           treesitter parser + queries（见 ts/README.md）
--
-- 对应关系：加设置放 config/，加插件放 plugins/，
-- 写"插件用到的工具函数"放 util/，别塞进 config/。

require("bootstrap") -- lazy.nvim 本体，必须最先

-- ------------------------------------------------------------
-- 基础设置
-- ------------------------------------------------------------
require("config.options") -- 选项
require("config.keymaps") -- 快捷键
require("config.builtins") -- 禁用内置 runtime 插件（netrw 等）
require("config.commands") -- 自定义命令
require("config.filetypes") -- .gdshader / .glslinc 等扩展名映射
require("config.diagnostics") -- 诊断显示样式

-- ------------------------------------------------------------
-- 语言子系统
-- ------------------------------------------------------------
require("lang.glslang") -- GLSL / RDShaderFile 校验器（需装 glslangValidator）

-- ------------------------------------------------------------
-- 插件管理
-- ------------------------------------------------------------
require("config.lazy") -- lazy.setup + ts/ 挂到 runtimepath
