# 跨游戏模式库 (docs/patterns/)

> **自迭代核心**: 同类型游戏经验沉淀 → 做下一个同类型游戏时召回 → 快速开发。
> 引擎层通用坑在 `docs/engine-memory.md`; 这里只收**游戏类型级**套路 (fishing / dungeon / rng / tycoon...)。

## 目录结构

```
docs/patterns/
├── README.md          ← 本文件 (索引 + 规则)
├── fishing.md         ← 钓鱼类 (heavy-fishing, fisch)
├── dungeon.md         ← 地牢类 (dungeon-raiders, dungeon-quest-reborn)
├── rng.md             ← RNG 类 (heroes-rng, project-aura-rng)
└── <genre>.md         ← 同类型第 2 个游戏出现时新建
```

## 规则 (与 intel/devlog 分工)

| 层 | 文件 | 收什么 |
|---|---|---|
| 运行时召回 | Real `remember-game` | 会话内结论, 当场存 |
| 单游戏档案 | `games/<g>/intel.md` | 该游戏专属结论 (含坐标/remote 名) |
| **类型模式库** | **`docs/patterns/<genre>.md`** | **同类型 ≥2 游戏都成立的套路** |
| 引擎记忆 | `docs/engine-memory.md` | 跨类型引擎坑 (寄存器/绘制/注入器) |

### 提升规则 (什么时候写 patterns)

- **触发时机**: 收工前 (发布流程第 5 步之后) + 新游戏建档时。
- **判定**: 一条结论在**同类型 ≥2 个游戏**上验证过 → 提升。只有 1 个游戏的 → 留在 intel, 标 `(候选提升)`。
- **动作**: 把 intel 里通用化的条目搬到 patterns/<genre>.md, intel 原条目末尾加 `→ 已提升至 patterns/<genre>.md` (保留原文, 不删)。

### 召回规则 (什么时候读 patterns)

- **新游戏建档时**: `tools/recall.py <目录名或genre或关键词>` → 模式库命中 → 带着已知套路进逆向。
- **每次会话启动协议第 1 步**: 若当前游戏属于已有 patterns 的 genre, 顺带扫对应模式文件。

## 新游戏接入流程 (自迭代闭环)

```
新游戏 → get-game-info
  → tools/recall.py <universeId/名/genre>   ← 召回: 同类型经验秒加载
  → 无 genre 档案 → 从 intel-template 建档
  → 有 genre 档案 → 读 patterns/<genre>.md, 套路直接复用
  → 开发中 remember-game
  → 收工: intel 回写 + tools/recall.py 检查是否产生新候选
  → 同类型第 2 个游戏验证后 → 提升至 patterns/<genre>.md
```
