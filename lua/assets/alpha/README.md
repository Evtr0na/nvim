# lua/assets/alpha/ —— 启动页 ASCII 图

每个文件是一张图，由 [img2art](https://github.com/Asthestarsfalll/img2art)
把图片转成 Lua 表，供 `alpha-nvim` 当 header 显示。

## 文件一览

| 文件 | 大小 | 行数 | 说明 |
| --- | --- | --- | --- |
| `eva.lua` | 73 KB | 503 | 当前使用中 |
| `iboli.lua` | 16 KB | 200 | 字符集较粗，文件小 |
| `iboli2.lua` | 72 KB | 129 | `--mapping "@%#*+=-:. "` 纯 ASCII 风格 |
| `iboli3.lua` | 33 KB | 365 | |
| `iboli4.lua` | 22 KB | 130 | |
| `liboli111.lua` | 227 KB | 461 | 细字符集，体积大但细腻 |
| `Rem.lua` | 193 KB | 1379 | 行数最多 |

## 切换

改 `lua/plugins/alpha.lua` 里的 require 模块名：

```lua
local header = require("assets.alpha.eva")
```

## 新增一张图

```powershell
# 注意 --save-raw 的输出路径必须落在本目录
img2art "你的图.jpg" --scale 0.15 --alpha --quant 16 `
    --save-raw "$env:LOCALAPPDATA\nvim\lua\assets\alpha\新名字.lua"
```

参数含义（`lua/plugins/alpha.lua` 顶部有更完整的示例）：

| 参数 | 作用 |
| --- | --- |
| `--scale` | 缩放比例，调小能显著减小文件 |
| `--alpha` | 生成 alpha-nvim 格式 |
| `--quant` | 颜色量化数，调小可减小文件 |
| `--mapping` | 字符集，`"@%#*+=-:. "` 是经典的由密到疏 |

## 约束

- **文件名必须是合法 Lua 标识符** —— 这里会被当模块 require，
  不能有空格、`-`、点号（`Rem.lua` 能工作是因为它是单个词）。
- **文件必须 `return` 一个表**，顶层不要有副作用。
- 单个文件超过 200 KB 时建议调小 `--scale`，否则会明显拖慢启动页渲染。
