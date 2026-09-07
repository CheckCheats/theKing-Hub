---
genre: rng
game: "Project Aura RNG"
placeId: 129619503633658
universeId: 9971332199
placeVersion: 6760
created: 2026-09-07
updated: 2026-09-07
script: "games/project-aura-rng/hub.luau"
status: active
---

# 游戏情报档案 — Project Aura RNG

> **AI 铁律**:
> 1. 会话开始必须先读本文件, 禁止对已有结论重新逆向。
> 2. 钾没有 remember-game: 结论当场写本文件。
> 3. 每条结论必须带条目头: `[日期 | pv<placeVersion> | 来源]`。
> 4. 游戏更新 (placeVersion 变更) 时: 受影响条目移入「待复核」区并标注新 pv, 不删除。
> 5. 结论被证伪时: 移到「已证伪」区保留原文 + 写明证伪原因, 不静默删除。

展示名随 LiveOps 会带前缀 (当前商店页: `[🎉拍卖] 项目光环随机生成`), 档案 `game:` 固定官方名 **Project Aura RNG**, 与 hub `GameName` 逐字一致。制作组 Rival Ducks。

## 协议与通信

## [2026-09-07 | pv6760 | 钾 execute_script 侦察]
- 客户端是 **roblox-ts + Flamework**: `ReplicatedStorage.TS` (assets/constants/events/flamework/middleware/modules/network/registry/types/utils) + `rbxts_include` (Promise / RuntimeLib / node_modules)。
- 业务 Remote 几乎全部挂在 `ReplicatedStorage.shared/network/GlobalEvents@GlobalEvents`, 共 **184** 个, 命名即语义 (`XxxRequest` / `XxxResult` / `XxxRejected` / `XxxBroadcast`)。另有 `ShowcaseEvents@ShowcaseGlobalEvents`。
- **不是** Heroes RNG 那种 `Network.FireServer(字符串名)` 分发; 这里是每条业务一个具名 RemoteEvent。找调用处先 `FindFirstChild` 该文件夹再按名取。
- `Pintail*` 前缀 remote 偏埋点/引导/商店屏 (ClientError / ClientPerformance / Guide* / Shop*), 不要当玩法发包通道。
- Cmdr 管理端: `ReplicatedStorage.CmdrClient` (`CmdrEvent` / `CmdrFunction`) — 玩家侧禁止当功能用。
- 数据同步: `UserSync` + `UserSyncRequest`。改功能前先确认玩家态是从哪边刷新的。

## Remote 清单

## [2026-09-07 | pv6760 | 钾 enumerate | 参数未验证]
路径除非另注: `ReplicatedStorage.shared/network/GlobalEvents@GlobalEvents.<Name>`

| Remote | 类型 | 猜测用途 | 参数 |
|---|---|---|---|
| AuraRollRequest / AuraRollResult / AuraRollRejected | RE | 抽光环 | 未验证 |
| InstantRollResult | RE | 可能是跳过滚动动画的结果通道 | 未验证 |
| DiceRollRequest / DiceRollResult / DiceRollRejected / DiceRollBroadcast | RE | 骰子抽 | 未验证 |
| EquipAuraRequest / UnequipAuraRequest | RE | 装备光环 | 未验证 |
| EquipBestCharactersRequest | RE | 物品栏 EQUIP BEST | **无参** `createClient().fire()` (pv6760 对照 UserPlotModule.equipBestCharacters) |
| EquipCharacterRequest / EquipCharacterToSlotRequest / UnequipCharacterRequest / UnequipAllCharactersRequest | RE | 角色上阵 | 未验证 |
| MergeCharactersRequest / MergeResult / MergeRejected | RE | 融合 | 未验证 |
| DeleteCharactersRequest | RE | 删角色 | 未验证 |
| ExplorationStartRequest / Deploy / Undeploy / Cancel / Claim / AutoToggle / TeamSelect | RE | 探索派遣 (游戏自带 AutoToggle) | 未验证 |
| AutoEnchantToggleRequest / AutoEnchantTargetsRequest / AutoEnchantAcknowledgeRequest | RE | 官方自动附魔 | 未验证 |
| AutoPotionSetRequest / AutoFeedAddRequest / AutoFeedRemoveRequest | RE | 官方自动药水/喂食 | 未验证 |
| EnchantRequest / CraftRequest / AwakeningRequest / StatRerollRequest | RE | 附魔/合成/觉醒/洗属性 | 未验证 |
| UpgradeRequest | RE | 天赋树点节点 | **string nodeKind** (如 `Damage4`), 与 UpgradeRegistry.content 键一致 |
| IndexClaimAllMilestonesRequest | RE | 图鉴一键领里程碑 | **无参** |
| IndexClaimDiscoveryRequest | RE | 图鉴发现奖励 | **string entryId** (如 `Character_SorcererSlayer`) |
| IndexClaimMilestoneRequest | RE | 单条图鉴里程碑 | **string entryId** |
| RuneEquipRequest / RuneUnequipRequest | RE | 符文 | 未验证 |
| TeleportToPlotRequest | RE | 回地块 (优先走这条, 别瞎写 CFrame) | 未验证 |
| AntiIdleTeleportRequest | RE | 防挂机传送 — 对标 Heroes 的 AfkRejoin | 未验证 |
| CodeRedeemRequest / CodeComposerSendRequest | RE | 兑换码 | 未验证 |
| OfflineEarningClaimRequest | RE | 离线收益领取 | 未验证 |
| QuestClaimRequest / QuestDailyBonusClaimRequest | RE | 任务 | 未验证 |
| MailClaimRequest / MailClaimAllRequest | RE | 邮件 | 未验证 |
| PlotCrystalDropRedeemRequest | RE | 地块水晶掉落领取 | 未验证 |
| PlotCrystalDamageBroadcast 等 | URE | 地块战斗表现, 客户端别当伤害权威 | — |

其余 Market* / Gift* / Leaderboard* / Settings* / KeyMap* 见全量表 (184)。**发包前必须最小参数试探**, 本表只是名字语义。

## NPC / 地点坐标

## [2026-09-07 | pv6760]
- 地块传送候选: `TeleportToPlotRequest` (未验证参数)。
- 世界交互大量 `InteractionKeybindPrompt` / `PlotTeleporterBillboard`, 设施很可能靠接近 + 按键而不是纯 remote。

## 关键机制结论

## [2026-09-07 | pv6760 | 钾侦察]
- 玩法轴: 抽光环/骰子 + 角色编队 + 符文/附魔/合成/升级树 + 探索派遣 + 地块打水晶。不是纯挂机打怪 RNG。
- 游戏**自带**若干自动开关 remote (`ExplorationAutoToggle` / `AutoEnchant*` / `AutoPotionSet` / `AutoFeed*`) — 自制循环前先确认官方开关够不够, 够就走 L1 直发官方包。
- 抽卡跳过动画: 有 `InstantRollResult`, 同时 Heroes 套路是替换滚动 UI 函数; 本游戏对应模块还在 `ReplicatedStorage.TS` 里, 未定位。`(候选提升: rng)`
- 防挂机: 存在 `AntiIdleTeleportRequest`, 实现防挂机前必须摸清谁发、会不会切地块/切服。`(候选提升: rng)`
- PlayerGui 主壳: `MainScreen`; 另有 Loading / Reward / OfflineEarning / Notification / Guide*。热替换不要误杀这些。

## [2026-09-07 | pv6760 | hub v0.2.0]
- 发包入口: `require(ReplicatedStorage.TS.network.GlobalEvents).GlobalEvents.createClient()` 得到 `{ XxxRequest = { fire, predict, connect } }`, 客户端用 `.fire(...)`。
- 玩家运行时单例: `require(PlayerScripts.TS.modules.user.ClientUser).ClientUser`, 字段 `index` / `upgrades` / `plot`。
- 图鉴: `index:getEntryViews("Item")` (IndexRegistry.providers 目前只有 Item, 角色 id 带 `Character_` 前缀)。view 上有 `discoveryClaimable` / `hasClaimable` / `entryId`。Claim All 走无参 `IndexClaimAllMilestonesRequest`。
- 天赋: `upgrades:canUpgrade(kind)` 返回 `{ success, reason }`。`getAffordableUpgradeCount()` 会报 0 但 canUpgrade 仍可能 success — **不要信这个计数**, 遍历 `UpgradeRegistry.content`。
- 装备最佳: `Inventory.BottomButtons.EquipBestButton` 同款无参 `EquipBestCharactersRequest`。

## L2 手段登记 (危险功能对抗手段台账)

(空 — 尚未上任何 L2)

## 可复用代码片段

(空)

## 待复核 (placeVersion 变更后移入)

(空)

## 已证伪

(空)

## 踩坑黑名单

(空, 开工时扫)
