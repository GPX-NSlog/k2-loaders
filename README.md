# K2 装卸机（独立版）

从 [Krastorio 2](https://mods.factorio.com/mod/Krastorio2) 中提取出来的 1x1 装卸机，做成可单独使用的 Factorio 2.1 mod，并针对 Pyanodons 等大型 mod 做了适配。

- 游戏版本：Factorio 2.1（支持 Space Age）
- mod 名称：`k2-loaders`
- 与 Krastorio 2 **互斥**，无法同时启用

## 功能

- 自动扫描游戏中的每一档 `transport-belt`，按速度去重后为每档生成一个装载机，档位名称、速度、图标与贴图跟随对应传送带。
- 支持原版（黄带 / 红带 / 蓝带 / 涡轮带）、Space Age 以及 Pyanodons、Bob's、Angel's 等 mod 添加的传送带。
- 配方跟随对应传送带的配方：继承其 `categories`（例如 Py 的流体制作类别）与 `surface_conditions`。
- 科技解锁跟随传送带：挂到解锁该传送带的科技上；起始即可用的传送带则挂到 `logistics` 科技。
- 保留 K2 装卸机的原始特性：1x1 体积、5 个过滤器槽位、与传送带快速替换、放置时自动吸附并翻转方向。
- 沿用 Krastorio 2 的原型名称（`kr-loader`、`kr-fast-loader`、`kr-express-loader`、`kr-advanced-loader`、`kr-superior-loader`），K2 存档里的蓝图可以直接粘贴使用。
- 支持 `max_belt_stack_size`，与 Py 的传送带堆叠机制兼容。

## 设置项（启动设置）

| 设置 | 默认值 | 说明 |
| --- | --- | --- |
| `k2-loaders-all-belts` | 开 | 开启时所有 mod 的传送带都会生成装卸机；关闭时只生成原版四档。 |
| `k2-loaders-need-power` | 关 | 开启时装卸机需要供电；关闭时装卸机无需电力，也没有耗电与待机功耗。 |

## 安装

1. 从 [Mod Portal](https://mods.factorio.com/mod/k2-loaders)（发布后）下载，或使用 `dist/` 中的 zip。
2. 将 zip 放入 Factorio 的 `mods` 目录，或在游戏内「模组」界面安装。
3. 与 Krastorio 2 同时启用会直接报错，请二选一。

## 仓库结构

```
info.json                  mod 元数据
settings.lua               启动设置
data.lua                   数据阶段入口
data-final-fixes.lua       在最后阶段生成装卸机原型
prototypes/loaders.lua     装卸机 item / recipe / entity 生成器
prototypes/loader-graphics.lua  贴图与图层配置
scripts/loader-snapping.lua     放置时自动吸附与翻转
control.lua                运行时事件注册与远程接口
locale/                    中英文文本
graphics/                  贴图与图标
tools/package.ps1          打包脚本
tools/publish.ps1          发布到 Mod Portal 的脚本
```

## 打包与发布

打包（读取 `info.json` 版本，校验 `changelog.txt` 首条版本一致，输出 `dist/k2-loaders_<版本>.zip`）：

```powershell
.\tools\package.ps1
```

发布到 Factorio Mod Portal（API Key 来自 <https://factorio.com/profile>）：

```powershell
$env:FACTORIO_API_KEY = '<你的 API Key>'
.\tools\publish.ps1 -Mode new       # 首次创建 mod
.\tools\publish.ps1 -Mode release   # 后续版本
```

也可以把 `$ApiKey = '...'` 写进 `tools/config.local.ps1`（已被 `.gitignore` 忽略）。

## 致谢与引用来源

- 原型、数值与玩法来自 **Krastorio 2**，作者：Linver、Krastor、raiguard（LGPL-3.0）。
- 装卸机实体、配方与吸附逻辑改编自 Krastorio 2 源码中的 `prototypes/buildings/*loader*.lua` 与 `scripts/loader-snapping.lua`。
- 装卸机结构贴图与图标来自 **Krastorio2Assets**（LGPL-3.0）。

详细来源、引用文件清单与许可证说明见 [CREDITS.md](CREDITS.md)。

## 许可证

本项目沿用上游许可证：[GNU LGPL v3.0](LICENSE)。
