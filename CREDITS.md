# 致谢与引用来源

本 mod 的装卸机原型、玩法设计与美术资源提取自 **Krastorio 2**，在此向原作者致谢。

## 原 mod

- 名称：Krastorio 2
- 作者：Linver、Krastor、raiguard
- 发布页：https://mods.factorio.com/mod/Krastorio2
- 本工程参考的源码：`E:\code\Krastorio2_2.1.4`（版本 2.1.4）
- 许可证：GNU Lesser General Public License v3.0（见 `LICENSE`）

## 引用与改编的源文件

装卸机原型与数值参考：

- `prototypes/buildings/loader.lua`
- `prototypes/buildings/fast-loader.lua`
- `prototypes/buildings/express-loader.lua`
- `prototypes/buildings/advanced-loader.lua`
- `prototypes/buildings/superior-loader.lua`

运行时装卸机吸附逻辑改编：

- `scripts/loader-snapping.lua` → 本 mod 的 `scripts/loader-snapping.lua`
  - 移除了 flib 依赖，改为自包含的方向与坐标辅助函数。

美术资源（来自 Krastorio2Assets 2.1.0，LGPL-3.0）：

- `graphics/loader/kr-loader.png`
- `graphics/loader/kr-loader-mask.png`
- `graphics/loader/kr-loader-rust.png`
- `graphics/icons/loader.png`
- `graphics/icons/fast-loader.png`
- `graphics/icons/express-loader.png`
- `graphics/icons/advanced-loader.png`
- `graphics/icons/superior-loader.png`

## 本 mod 的改动

- 装卸机不再硬编码为 Krastorio 2 的 5 个档位，而是在 `data-final-fixes` 阶段扫描所有 `transport-belt` 原型，按速度去重后动态生成。
- 配方改用对应传送带 + 前一级装卸机 + 通用齿轮 / 钢板，避免依赖 Krastorio 2 专属材料。
- 科技解锁自动挂到解锁对应传送带的科技上。
- 保留 Krastorio 2 装卸机的过滤、快速替换、升级链与自动吸附翻转行为。
- 通过 `! Krastorio2` 依赖声明与 Krastorio 2 互斥。

## 许可证

本 mod 作为 Krastorio 2 的衍生作品，按 **GNU LGPL v3.0** 分发，许可证全文见 `LICENSE`。
如果重新发布或再分发，请保留本文件、`LICENSE` 以及 `info.json` 中的致谢信息。
