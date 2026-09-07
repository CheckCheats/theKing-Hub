---
genre: rng
game: "Heroes RNG"
placeId: 108307565942574
universeId: 10153098880
placeVersion: 53
created: 2026-08-25
updated: 2026-08-25
script: "games/heroes-rng/hub.luau"
status: active
---

# 游戏情报档案 — Heroes RNG

> **AI 铁律**:
> 1. 会话开始必须先读本文件 + recall-game-memory, 禁止对已有结论重新逆向。
> 2. 开发中新发现: 当场 remember-game (运行时召回), 收工前回写本文件 (持久归档)。
> 3. 每条结论必须带条目头: [日期 | pv<placeVersion> | 来源脚本@版本]。
> 4. 游戏更新 (placeVersion 变更) 时: 受影响条目移入「待复核」区并标注新 pv, 不删除。
> 5. 结论被证伪时: 移到「已证伪」区保留原文 + 写明证伪原因, 不静默删除。

## 协议与通信

## [2026-08-25 | pv53 | heroes-rng-nl.luau v0.0.6 -> hub.luau v1.0.0]
- 网络层: 游戏统一走 Network.FireServer(name, ...) / Network.InvokeServer(name, ...)
  (require ReplicatedStorage.client.Network.Network), 业务 remote 按名字字符串分发。
- 服务器限速表 (Config.RemoteRateLimits):
  - ReportClickAttack = {15, 1} — 攻击循环全局速率不得超过
  - RequestZoneTeleport = {5, 5}; EnterTower = {5, 5} -> 传送统一 5 秒冷却
  - PrestigeRequested = {5, 1} -> 转生后 60 秒冷却防连发
  - EquipHero / UnequipHero = {30, 1} -> 每轮最多处理 2 个装备操作 (间隔 1.5s)
- 点击攻击伤害公式 (客户端预计算, 服务器确认):
  dmg = 1 + ClickAttackDpsFraction(默认0.05) * 总DPS, 暴击概率 ClickAttackCritChance。
  本地 Enemies.ApplyLocalDamage + 视觉/音效, 然后 FireServer("ReportClickAttack", zone, slot, pos)。
- 力量系统: InvokeServer("GetPowerState") -> {charge, capacity, armed};
  FireServer("SetPowerArmed", true) 使用力量; FireServer("SetSetting", "AutoPower"/"AutoEquip", false) 可关游戏内置自动化。
- 升级树: Shared.Upgrades.Order() 全节点 + GetState(id, owned, gold) == "Affordable" 判可买,
  FireServer("PurchaseUpgrade", id) 购买 (与 UI 点击同 remote)。
- 声望: PrestigeClient.CanPrestige() / Request() -> FireServer("PrestigeRequested")。

## Remote 清单

## [2026-08-25 | pv53 | hub.luau v1.0.0]
| Remote | 方向 | 参数 | 用途 |
|---|---|---|---|
| ReportClickAttack | Fire | (zone, slot, pos) | 点击攻击确认 |
| RequestZoneTeleport | Invoke | (zoneName) -> bool | 12 地区传送 |
| RequestArenaTeleport | Invoke | ("Join"/"Leave") | BOSS 竞技场进出 |
| PurchaseUpgrade | Fire | (id) | 天赋购买 |
| PrestigeRequested | Fire | () | 声望转生 |
| EquipHero | Fire | (heroId, size, stars, instanceId) | 装备英雄 (instanceId 必须真实) |
| UnequipHero | Fire | (heroId, size, instanceId) | 卸下英雄 |
| SetPowerArmed | Fire | (true) | 使用力量 |
| SetSetting | Fire | (key, bool) | 关游戏内置自动化 |
| GetPowerState | Invoke | () -> table | 力量充能状态 |
| RequestAfkRejoin | Fire | () | 挂机切服 (防挂机功能吞掉此包) |

## NPC / 地点坐标

## [2026-08-25 | pv53 | hub.luau v1.0.0]
- 传送走服务器 remote 而非写 CFrame (L1 安全路径)。
- 设施传送 = 区域传送 + 定位设施碰撞体触发原生 Touched 打开界面:
  - 融合: Forest + workspace.Fusion (Hitbox)
  - 符文: Beach + workspace.RuneAltar (Hitbox)
  - 塔楼: Badlands + workspace.InfinityTower (Touch)
  - 制造: Arctic + workspace.CraftingTable (Hitbox)
- 两步移动法: 先传到 Hitbox 后方 8 studs, 0.15s 后进入碰撞体 (确保 Touched 触发)。
- 12 地区 (Shared.Zones 顺序): Starter, Meadows, Forest, Beach, Sea, Arctic, Jungle,
  Badlands, Shadowgrove, SerpentSands, Void, IceCave。

## 关键机制结论

## [2026-08-25 | pv53 | heroes-rng-nl v0.0.6]
- 防挂机机制: client.Afk 每 CheckInterval(5s) 检查, 闲置超过 IdleSeconds(1020s=17分钟)
  -> FireServer("RequestAfkRejoin") 切服。Roblox 引擎层另有 ~20 分钟闲置弹窗 (需模拟输入)。
- BOSS: 实体 zone="WorldBoss" slot=1000 (不可点击攻击, 只能等英雄打);
  BossesShared.GetWindow(serverTime) -> {phase="Idle"/"Warning"/"Active", spawnEpoch, bossId};
  传送入口提前 300 秒开放 (Warning 阶段); BossesClient.HasLiveFight()/IsPlayerInArena() 判状态。
- 抽取滚动: RollingView.PlayRoll/WaitForRollComplete 可被替换 (require 缓存共享, 立即生效,
  覆盖普通/自动/模拟抽取全部路径); 两函数必须成对替换 (否则 WaitForRollComplete 死循环)。 → 已提升至 patterns/rng.md
- 装备上限: Config.MaxEquippedHeroes(默认2) + 天赋 MaxEquippedHeroes 累加;
  Inventory.GetOwnedBuckets() 条目含游戏预计算的 Dps 字段。
- executor require 缓存与游戏 VM 共享 (Heroes RNG 实测可 require 全部模块) — 与 Sol's RNG 的部分隔离不同。

## L2 手段登记 (危险功能对抗手段台账)

## [2026-08-25 | pv53 | hub.luau v1.0.0 | 防挂机]
- 手段: 替换 Network.FireServer/InvokeServer 表字段 (吞 RequestAfkRejoin) + Config.AfkRejoin 阈值拉高
  + VirtualUser 模拟点击 (Idled 事件) + 8~13 分钟随机真人活动 (隐形点击/跳跃)。
- 验证: 蓝本 v0.0.6 长期挂机无切服; 本版沿用同机制。
- 信号特征: 若服务器改从其他 remote 切服, 防挂机失效 (表现为挂机中被换服)。

## [2026-08-25 | pv53 | hub.luau v1.0.0 | 防滚动]
- 手段: 替换 RollingView.PlayRoll (瞬时快照最终状态) + WaitForRollComplete (立即返回)。
- 验证: 蓝本实测抽取直接显示结果; 卸载时还原原函数。
- 信号特征: 若游戏更新 Rolling UI 结构 (Column/Slots 路径变化), 替换后抽取会黑屏/无动画。

## 可复用代码片段

## [2026-08-25 | pv53 | hub.luau v1.0.0]
- getTotalDps(): 复刻游戏英雄 DPS 全加成计算 (天赋/声望/融合/圣物/符文/公会/事件倍率)。
- tryHitEnemy(): 完整静默攻击单怪 (服务端节流 + 本地伤害 + 视觉 + 确认包)。
- snapToFacility(): 通用"传送+触发设施交互"两步法。
- 自动升级 pending 集合模式: 请求后 30s 超时重试, 防重复购买 (服务器未确认期间)。

## 待复核 (placeVersion 变更后移入)

(空)

## 已证伪

(空)
