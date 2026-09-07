# Project Aura RNG TheKing HUB — 开发手册 (DevLog)

> 维护铁律: **每次开发会话收工前必须追加一条**, 写给下一个接手的 AI。
> changelog 记发布了什么; 本文件记怎么做的、为什么、验证结果、遗留。

---

## 条目格式 (复制使用)

```
## [YYYY-MM-DD | 会话N | vX.Y.Z | lib v?] <一句话主题>

### 目标
### 改动明细 (函数级定位)
### 决策记录 (为什么这么改)
### 验证
### 遗留问题 / 下一步
```

---

## [2026-09-07 | 会话2 | v0.2.0 | lib v2.5.1] 主要 Tab 三个自动

### 目标
用户要第一个 Tab 叫「主要」, 做自动领索引 / 装备最佳 / 升级天赋树。

### 改动明细
| 文件 | 位置 | 改动 |
|---|---|---|
| games/project-aura-rng/hub.luau | Pack `S` | bind/createClient + tickIndex/tickEquip/tickUpgrade |
| games/project-aura-rng/intel.md | 协议/Remote | 补 fire 参数与 ClientUser 单例 |

### 决策记录
- L1: 只发 UI 按钮同款包, 不 hook。
- 升级按 `canUpgrade.success` 每次只点 1 个节点, 避免一轮刷 97 个。
- 索引先无参 ClaimAll 里程碑, 再按 view 逐条 Discovery; `getAffordableUpgradeCount` 作废。

### 验证
- `python tools/check_hub.py games/project-aura-rng/hub.luau` 通过。
- 未在局内开开关实发 (会改阵容/花碎片), 等热替换自测。

### 遗留问题 / 下一步
- [ ] 热替换后开三个开关: 图鉴 CLAIM 应变 CLAIMED, 装备最佳应换阵, 天赋应扣碎片
- [ ] 未做反作弊侦察
- [ ] 自动抽 / 跳滚动 / 探索 / 防挂机仍未做

---

## [2026-09-07 | 会话1 | v0.1.0 | lib v2.5.1] 建档 + 侦察

### 目标
用户「启动引擎, 开新游戏」。钾客户端 pid=24672, 商店页名带拍卖前缀, 官方名 Project Aura RNG。

### 改动明细
| 文件 | 改动 |
|---|---|
| games/project-aura-rng/intel.md | 新建, pv6760, roblox-ts/Flamework + 184 具名 remote |
| games/project-aura-rng/hub.luau | 骨架, GameName 与 intel `game:` 一致 |
| games/project-aura-rng/changelog.md | v0.1.0 |
| docs/patterns/rng.md | 同类型第 2 个 RNG 游戏, 建模式库 |

### 决策记录
- 目录 `project-aura-rng`, 显示名不用 LiveOps 中文标题, 避免热替换键随标题变。
- 通信层与 Heroes RNG 不同 (具名 Remote vs 字符串分发), 模式库只收「进 RNG 先找什么」, 不把 Heroes 的 Network API 抄过来。
- 官方已有 AutoEnchant / AutoPotion / ExplorationAutoToggle — 功能优先级: 先白嫖官方开关, 再自制循环。

### 验证
- 钾 print 对齐 placeId=129619503633658 / universeId=9971332199 / placeVersion=6760。
- `python tools/check_hub.py games/project-aura-rng/hub.luau` 通过 (主块峰值 1)。

### 遗留问题 / 下一步
- [ ] 未测任何 Request 参数; 未 require TS 模块
- [ ] 未做反作弊侦察 (钾无 dump-anticheat-hooks)
- [ ] 等用户点功能: 自动抽 / 跳过滚动 / 探索 / 官方自动附魔药水 / 防挂机 / 回地块

## 踩坑黑名单

(开工先读, 只增不删)
