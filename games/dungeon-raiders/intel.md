---
genre: dungeon
game: "地下城战利品者"
placeId: 132285059959516
lobbyPlaceId: 106484206883664
afkPlaceId: 129976314326660
universeId: 9656201728
placeVersion: 1766
created: 2026-09-03
updated: 2026-09-06
script: "games/dungeon-raiders/hub.luau"
status: active
---

# 游戏情报档案 — 地下城战利品者

> **AI 铁律**:
> 1. 会话开始必须先读本文件 + `recall-game-memory`, 禁止对已有结论重新逆向。
> 2. 开发中新发现: 当场 `remember-game` (运行时召回), 收工前回写本文件 (持久归档)。
> 3. 每条结论必须带条目头: `[日期 | pv<placeVersion> | 来源脚本@版本]`。
> 4. 游戏更新 (placeVersion 变更) 时: 把受影响条目剪切到「待复核」区并标注新 pv, **不删除**。
> 5. 结论被证伪时: 移到「已证伪」区保留原文 + 写明证伪原因, 不静默删除。

> 注: 本会话注入器是 Potassium (`execute_script` / `decompile`), 没有 Real MCP 的 `remember-game` / `remote-spy`。结论全部来自实例树 + `require` 数据表 + 反编译客户端模块。Knit 客户端 RF 返回 Promise, 必须 `:await()` 且解包 `(ok, result)`。

---

## [2026-09-03 | pv1659 | 建档@0.1.0] 宇宙与分图

- Marketplace 名: `地下城战利品者 [游戏玩法]`(当前在地牢图); `game.Name=Ugc`
- `universeId=9656201728`
- `GameInfo.PlaceConfig` (require 实测):
  - `LobbyPlaceId=106484206883664`
  - `DungeonPlaceId=132285059959516` (当前客户端)
  - `AFKPlaceId=129976314326660`
  - `Environment=Main`, `IsDungeonPlace=true`, `IsLobbyPlace=false`, `IsAFKPlace=false`
- 功能开发注意: 排队/选本/商店/锻造多半在大厅图; 战斗/拾取/选箱/Replay 在地牢图。`Player` 属性 `InDungeon` / `DungeonRun` / `CurrentDungeon` / `CurrentDifficultyMode` 可区分场景。
- **[2026-09-06 | pv1766]** Marketplace 现名 `地牢掠夺者 [游戏玩法]`; 档案 `game:` / hub `GameName` 仍用 `地下城战利品者` (热替换键, 禁止改)。`PlaceConfig` 三图 ID 未变。

## [2026-09-06 | pv1766 | 会话14 钾全量复核] 版本跃迁结论

客户端: placeId=`132285059959516` (地牢图) pv**1766** (档案原 pv1659, +107)。局内曾进 **Mage / Easy**, 职业 `Unrestricted`, Aspect=`Fulmin`, Lv131 GS5103。Knit **1.7 + Comm 1.0.1** 未换; 战斗 `Inputs.*` 七件套仍在 (Attack/Skill/Parry/Block/Dash/Sprint/AirState)。

### 仍成立 (对照实测, 不必重挖)

- Knit 路径 `Packages._Index.sleitnick_knit@1.7.0.knit.Services.<名>/{RF,RE}`
- 战斗发包协议未改; 技能 CD 现比旧档更完整: `SkillN_CooldownRemaining` + **`SkillN_CooldownDuration` / `SkillN_CooldownEnd` / `SkillN_OnCooldown` / `SkillN_HasHold`** (倒置长矛 1/2/3 冷却中四件套齐全; 4 冷却好时仍可能缺 Rem, 见会话13)
- 新玩家属性: `Active_Aspect` / `Active_Class` / `SpecialForm` / `Stat_SoulBaseDamage` / `Stat_ArchetypeDamage` / `Weekend_DoubleDrops` / `Weekend_DoubleEXP`
- Replica / 大厅 `RS.Remotes` / DropService.CollectDrop / DungeonRunService Replay 链路未拆

### 新图 Mage = City of Mages (T7)

`DungeonData.Dungeons.Mage`: DisplayName=City of Mages, Theme=INT, BiomeId=**Wistoria**, MinLevel=**100**, TimeLimit=360, Lives=1, OpenWorld=**true**, MaxNPCs=18, MobsPerRoom=12, InitialNPCs=8, SpawnInterval=5, LockedRooms 1~3, LootRoomChance=0.3, LootChest=MythicLootChest。
- 解锁: `RequiresClear={DungeonId=Demon, Difficulty=Nightmare}` + 等级 100 (旧 UnlocksFrom 字段已空, 全图改走 RequiresClear)
- 战斗房数 Easy7 / Normal8 / Hard8 / NM9 (另 CombatRoomCount Min=Max=10 是估计值, 以 ByDifficulty 为准)
- 怪池: Mage Student / Mage Student 2 / Abnormal Student
- MiniBoss: **Cryomancer** (HP 84万 / Dmg 945 / Scale 2 / GruntCount 2)
- Boss: **Demagios, The Arcane Sovereign** (HeroId=Demagios, HP 105万 / 6 血条 / Dmg 1350 / Scale 2.5 / Multiplier 4)
- 难度系数 Easy 1/1 → NM 血×2 伤×4.3; 等级带 Easy 100-118 / NM 155-175
- 本表 **无 SpecialBoss 字段** (不像 Snow/Demon)
- TileData 新增 biome **Wistoria** (Mage 用地块); 模板只有 Start / Hallway / 左右转角 / Large_Room_1 / Boss_Room / Locked_Room_1 / Wall_Cap — **无 Loot tile、无 Special_Boss 房、无 Checkpoint、无第二战斗模板** (LootRoom 仍可能打属性到岔路, 未实地)
- 局内文件夹名 `Generated_Mage_<guid>` (扫描时在 Easy 局; 后结算离图 CS.Enemy=0)

### 地牢表其它可见变化

- DisplayOrder: Bandits Den → Forest Challenge → Goblins → Knights → Catacombs → Snow → Demon → **Mage**
- Theme 从 Wood/Forest 语义改成 **DEX/STR/INT/VIT** (Bandits=DEX, Goblins=STR, Knights=VIT, Catacombs=INT, Snow=STR, Demon=VIT, Mage=INT)
- **PlaceConfig 坑**: 人身在地牢图 (placeId=DungeonPlaceId, 当时 InDungeon=true) 时模块仍报 `IsLobbyPlace=true / IsDungeonPlace=false`。场景判定**不要信 PlaceConfig 布尔**, 信 `lp:GetAttribute("InDungeon")` + `Generated_*`。

### Knit 服务 76 个 (旧档 ~70+)

新出现 / 值得记:

| 服务 | 要点 |
|---|---|
| **VerticalReachAntiCheatService** | 无 RF/RE 暴露, 名字=垂直高度反作弊。**不要 hook/致盲**。功能侧: 别把角色抬到离谱高度 |
| WeekendBuffService | 周末双倍; 表 `WeekendBuffData` 周五 18:00–周日 22:00 PT, EXP×2, 掉落 +1, 属性 Weekend_DoubleEXP/Drops |
| Mutation / ClassWeaponAspect | 数据在 `GameInfo.MutationData`, 无独立 Knit 服务 |
| KeyService | `GetAllKeys` + RE KeyGranted/KeyConsumed — 钥匙库存终于有服务可读, 旧「只能扫背包 UI」待复核 |
| ConsumableService / EmoteService / StarsShopService / RunEarningsService / EventRsvpService / PVPZoneService / EnemyModelService / EntityService / ClassWeaponService / AutoAFKService | 新大厅/系统服务, 战斗光环不必碰 |
| DungeonQueueService | 新增 Pod 排队 `RequestStartPodQueue` + RE PodQueueUpdate/PodPromptRequested; `RequestSelectSkipFloor` |

GM 黑名单仍在: LevelService.AddXP/SetLevel, LootService.GiveReward/GrantCurrency, MonetizationService.GrantProduct/SetPremium, PlayerActionService SetMoney/ChangeClass/ApplyLevel/ActivateAdminFly。

### 职业 42 (旧 41)

`Class_Data.GetAllClassNames()` = 42。相对旧档新增可见: **Cryomancer** (Mage MiniBoss 同源职业)、**Dark Professor** 等是否全新以文件夹为准; 文件夹 42 职业 + Class_Data。当前号 `Current_Class=Unrestricted` 档案仍可用。

### 装备突变 + 职业武器 Aspect (新系统)

`GameInfo.MutationData`:

- 装备突变 13: Shadow / Flaming / Shiny / Divinity / Absolute / Fairy / Plasma / Demonic / Magical / Frosted / Money / Surging / Dusk
- 职业武器 Aspect (`ClassWeaponAspects`, 玩家属性 `Active_Aspect`): 普通 2.5% 与 Apex 1%

| Aspect | 触发 | 说明 |
|---|---|---|
| Fulmin | OnBasicHit | 平A 概率连环闪电 (当前号已装备) |
| Glaciel | OnBasicHit | 平A 冰缓+易伤 |
| Blaze | OnBasicHit | 火焰 DoT |
| Verdant | OnBasicHit | 叠毒 |
| Umbral | OnCrit | 暴击暗爆+眩晕 |
| Sanguine | OnHit | 吸血窗 |
| Aegis | OnParry | 拼刀放新星 |
| Tempest (Apex) | OnSkillUse | 技能叠暴风, 满层下一次技能 200% 雷暴 |
| Ruin (Apex) | OnBasicHit | 单目标破甲叠到 +75%, 换目标重置 |
| Phantom (Apex) | OnDodge | 闪避留影爆; 击杀 +25% 伤 5s |
| Alacrity (Apex) | OnBasicHit | 20% 进 10s 攻速+60% |

Aspect 是服务端效果, 杀戮光环继续发游戏自身 Attack 即可吃到, **不要伪造 Aspect 包**。

### 局内场景扫描备注

- 进 Mage 时 workspace 有 `Generated_Mage_*` + 预制 `Awakened Devil` 模型 (大厅/展示残留, 别当本局 Boss)
- 标签 `Enemy` 在空场/结算后为 0; 局内存活怪仍应用 CS tag, 空场不要当「标签系统删了」
- RS 新增: `Mutations` / `Weapons` / `Enemies` / `ServerState` / `WorldRewardNotify` / `Configuration`

### Mage 房间图 [2026-09-06 | pv1766 | 会话20 局内 Generated_Mage_*]

主链沿 -Z, 门缝 X≈-1665: **Start Room_1** (Zone≈77×107, 无 Enemy_Spawn, 仅 Exit) → **战斗 Large** (≈139×181, 9 spawn, Entry+Exit+Side×2) → **过廊** (≈37×69, 无 spawn) 循环。侧房 `IsLootRoom=true` 只 Entry, 接战斗房 Side。Room_7 较大无 spawn (可能祭坛/广场)。**Room_13 起空壳无 Zone** — 同 Demon 分段生成。Connector 是门平面上 ~0.86 立方, Look 朝房外; hub v1.19.0 路点 `doorIn` 推进房内, 不用裸 Position。
- **[hub@1.23.0 | pv1768 现场]** Exit 与下一房 Entry **世界坐标重合**。过廊 Zone 37×69 不算战斗房, 旧 nextHop 会跳过廊, 绿线从大战场穿墙连下一战场。现: 当前房认最窄 Zone; 邻房过廊插入中心+门洞三点; 抽稀不再丢门口点。
- **[hub@1.23.1]** 门口两 Zone 重叠会抖当前房 → hallKey 变 → 反复重画绿线。现: stayRoom 粘滞; 过廊 key=`to:下一房`; 距目的 <12 不再建路; 空地直线两点。
- **[hub@1.29.4]** 主链上有 **L 拐角房** (如 Room_21): Connectors 里 Entry/Exit 两轴都偏, Zone 可到 82×78 无刷怪. AABB 中心是内拐死角. 不当战斗房、不居中; 卡住沿 Exit 主轴往前顶.


### 对 hub 的影响 (未改代码)

- 通信/战斗入口兼容, v1.17.0 可继续打
- Mage 房间已解剖 (会话20); 寻路 v1.19.0 按门缝/分段生成处理, 后半图空壳实例化仍要跟跑
- 新 AC 服务: 保持贴地走位, 禁止飞天/超高 CFrame
- KeyService 可替换钥匙 UI 扫描 (未做)
- 会话13 遗留 (slot4 nil=就绪、同槽重发退避) 仍待做, 与本次更新无关
- **Boss Rush**: `Nav.isTowerRun` 会因常驻 `Challenge_Dungeons` 误判成双倍地牢爬塔; 重开走 `BossRushService.RequestReplay` 不是 ChallengeRunService; 索敌会扫到 `Enemies`/`CharacterWorld` 预制 Boss。未改 hub

## [2026-09-07 | pv1768 | hub@1.29.0] 活动 Raid「The First Test」

- 判定: 玩家 `InRaid=true`, `CurrentDungeon=The First Test` (不是 BossRush / 不是 Generated_*)
- 图: `RaidData.MAP_ROOT=Boss_Rush`, `Map=Church_Room`, `LOADING_TIME=15`, 难度 Normal/Extreme/Impossible (现场 Extreme HP 6500万 / 伤 8500)
- BOSS: `BossId=Dark Professor`, 活体在 `workspace.Raid_NPCs`, `IsBoss=true`, **无 Humanoid**, 血条 `HUD.Dungeon_Container.Boss_Info` + `RaidRunService.RE.BossHealthUpdate`
- HUD 阶段: `Timer_Canvas.Raid.Title` (`PHASE 1`..`PHASE 4` / `SURVIVE`); 局时 `Time Left`
- 服务端: `RaidRunService.RF.GetSessionState` 含 `RaidPhase`(1-4) 与 `Phase`(`Combat`/`Loading` 等) **两套**; `RE.RaidPhaseUpdate` / `PhaseChange`
- 客户端 `RaidData.Raids["The First Test"].PhaseThresholds` **空表** — 切阶段不按写死血量百分比。用户实测 PHASE 2 与 4 都可能出小弟+水晶, **不要按阶段号写机制**
- 机制实体 (Raid_NPCs): `Protective_Dome`(护罩 Part); `Mage Student` / `Mage Student 2`(小弟, IsFodder); 水晶名含 Crystal 且非 Crystal_Spawn 占位
- 护罩期 BOSS `CanAttack=false`, 破罩可 `Is_Stunned=true`
- hub v1.29.0 自助: 锁水晶>罩>小弟>BOSS; SURVIVE 躲地板.
- **[hub@1.30.9]** 连环炸期 `Protective_Dome` 能打打不破无血条, 不当「罩能打」. 躲圈只看倒计时+无小弟+无水晶. 没小弟不锁罩.

- **[hub@1.30.17]** 水晶阶段只躲盖脚全图地板, 躲完继续砸. 死后 wipe 技能锁, 观战 `RaidRunService:LeaveSpectate`. 索敌认 InRaid / The First Test / Raid_NPCs. 机制锁不上才回落 BOSS.

- **[hub@1.30.16]** 活动目标: 小弟全清 → 砸完水晶 → 再打 BOSS. 水晶/小弟阶段禁止闪避与锁 BOSS. 罩不主动打.

- **[hub@1.30.14]** 活动结算禁止点 HUD Replay (Source 常=Challenge). `tickTowerReplay` 虽挂「自动重开」但 `raidLocked` 时不得调 ChallengeRunService. 爬塔判定只认图名 Double Dungeon/Throne Room/Forest Challenge, 不认 InChallenge 单独为真.

- **[hub@1.30.13]** 活动结算重开点 HUD `ReplayButton` (官方按 Source 路由). 裸 `DungeonRunService.RequestReplay` 可能开成爬塔. `isTowerRun` 只认 `InChallenge` / Double Dungeon / Throne Room / Forest Challenge.

- **[hub@1.30.12]** 水晶阶段不把 BOSS 身上 1³ `AoE_Telegraph` 当盖脚. 小弟≥2 先清 (BOSS 会回血), 1 个仍先砸罩.

- **[hub@1.30.11]** 连环地板预警块在 BOSS `Telegraph_Root.AoE_Telegraph` (1³), 圈心≈自己时必须离点+Dash, 不能按「离 BOSS>12」过滤. 活动结算 `isTowerRun` 禁止用常驻 `Challenge_Dungeons`; 认 `InChallenge` / `Challenge_NPCs`. 官方 Replay 活动走 `DungeonRunService`.

- **[hub@1.30.10]** 真水晶名 `Damage_Crystal` (也见 `Damage Crystal`), 可挂 `Raid_NPCs` 子级且无 Humanoid. 占位 `Church_Room.Spawns.Crystal_Spawn` 不算. 有水晶时不因倒计时乱跑, 先砸水晶; 超时全图地板圈盖到人才躲并跳过剩余水晶.

- **[hub@1.30.7]** 水晶没打完会放全图地板 (可躲). 旧实现用倒计时也会躲 (已证伪, 倒计时每阶段都亮). 现只认圈盖到人.




- **[hub@1.30.2]** BOSS 技能脚下 `AoE_Telegraph` 不是连环地板, 自助不要清锁乱跑. 连环炸=落点离 BOSS>14 格 / 非 BOSS 祖先 / Meteor·Grenade. SURVIVE 仍躲.
- **[hub@1.29.3]** `isBossRush` 改认玩家 `InBossRush` / `CurrentDungeon=BossRush`. `Boss_Rush` 文件夹在 Double Dungeon 也常驻, 旧判定会让 `tickTowerReplay` 直接放弃, 爬塔结算/快刷都不重开.

## [2026-09-06 | pv1766 | 会话22 钾] Boss Rush (BOSS爬塔)

不是 Double Dungeon / Throne Room 挑战图。玩家属性 `CurrentDungeon=BossRush` + `InBossRush=true` + `BossRushLighting`。场景 `workspace.Boss_Rush` (Maps: Train / Legacy / Throne_Room / Church_Room) + 活怪在 `BossRush_NPCs`。HUD 名 **BOSS RUSH**, 计数是 **Floor** 不是 Wave。`Challenge_Dungeons` 模板仍在 workspace (空壳), **不能当爬塔判定**。

### 循环 (BossRushData)

- 满 **100 层**, 开局 3 命, 解锁等级 67, 最多 4 人; 层间休息 1.5s
- 档位: 普通 Regular; **每 5 层 Empowered** (HP×1.5 伤×1.3); **每 10 层 Enraged** (HP×2.5 伤×1.8 速×1.25) **且开箱** (`IsChestFloor`, 100 层除外)
- 箱: 每 10 层, 候选 3, 选箱窗 8s, 超时 45s; RF `SelectFloorChests`; RE `ChestSelection`
- 药: `POTION_INTERVAL=10` 寿命 15s; 撤离点同样每 10 层寿命 60s
- 普通池 Bandit Chief / Goblin Chief / Knight Lord / Verath / Valkskar / Ogge / Broken Reality / Bandit Enforcer
- 强化池 +Tenebris / Miyu; 狂暴池 Karasu / **Shadow Monarch** / Awakened Devil / **Kieru** / Forge Archon / Mimika
- 第 100 层终局自选: Cursed King / Satori / Anti Mage / Great Mage (`SelectFinalBoss` / `GetFinalBossOptions`); 地图 Train/Legacy/Throne_Room
- 血: BASE_HP 12万 × 每层 ×1.037 × 档位; 双人实测 F90 Enraged Kieru MaxHP **1,828,817**
- 跳层票 `BossRushSkipTicket` 10~50 层、步进 10、每步 5 张
- 里程碑每 5 层到 100, `ClaimMilestoneReward`; 局外 `GetProgress` (HighestFloor/TotalRuns/Season)

### 局内状态

`BossRushService.RF.GetSessionState` **直接 InvokeServer** (Knit `:await()` 会解包错成 boolean): `{CurrentFloor, BossName, BossHP, BossMaxHP, Phase=Active, Lives, PlayerCount, FinalBoss}`。RE: FloorStart/Cleared, PhaseChange, BossHealthUpdate, LivesUpdate, DungeonComplete, Replay*。重开/回城: `RequestReplay` / `RequestReturn`。

活 Boss: `BossRush_NPCs.<名>` `IsBoss=true` `BossRush=true` `ChallengeDungeon=BossRush` `HighlightPriority=1`, 可同时 `IsFodder=true`。CS.Enemy 会打到大厅/预制一堆模型, **不能裸 GetTagged 当活怪**。

### 和现有「爬塔」hub 的差

| | Double Dungeon | Boss Rush |
|---|---|---|
| 判定 | `Challenge_Dungeons` 且无 `Generated_*` | `InBossRush` / `CurrentDungeon=BossRush` / `Boss_Rush` |
| 重开 | ChallengeRunService | **BossRushService** |
| 选箱 | MidRun / 地上 DungeonChest | **SelectFloorChests** |
| 祝福 | Boost_Selection 每 10 波 | 无同款祝福循环 |
| 目标 | 波次小怪+Boss | **每层一只 Boss** (HUD 仍可能写 CLEAR MOBS) |

## 协议与通信

## [2026-09-03 | pv1659 | 建档@0.1.0] 架构

- 通信主路是 **Knit 1.7 + sleitnick Comm**: 服务挂在 `ReplicatedStorage.Packages._Index.sleitnick_knit@1.7.0.knit.Services.<Name>/{RF,RE}`
- 玩家数据同步另走 **Replica** (`ReplicatedStorage.RemoteEvents.Replica*`), 不要当业务动作 remote 去 Fire
- 战斗输入是独立 RemoteEvent, **不走 Knit**: `ReplicatedStorage.Player.Remotes.Inputs.*`
- 大厅杂项: `ReplicatedStorage.Remotes` (卖东西 / 存仓 / 传送地牢 / 转生 / 新手引导)
- 全 RS 共 **377** 个 RemoteEvent/Function (含 Knit + Replica + Cmdr)
- Knit 客户端调用形如 `Knit.GetService("DropService"):CollectDrop(...):await()`

### 战斗输入协议 (反编译 `Player.Modules.Weapon_Input`, 已核对)

路径均在 `ReplicatedStorage.Player.Remotes.Inputs`:

| Remote | 类型 | 客户端实发参数 | 说明 |
|---|---|---|---|
| Attack | RE | `FireServer(moveDir: Vector3)` | 游戏本体: 先发相机相对 WASD; 没按键才用 MoveDirection. **杀戮光环应发指向锁定的世界水平单位向量, 禁止 Fire zero** |
| Skill | RE | `FireServer(slot, "tap"\|"hold", extra)` | slot=`1..4` 或 `"E"`(大招); extra 多为相机相对移动方向 |
| Parry | RE | `FireServer()` | 点按格挡键 |
| Block | RE | `FireServer("start"\|"stop")` | 长按格挡 |
| Sprint | RE | `FireServer("start"\|"stop")` | 键盘长按, 手柄切换 |
| Dash | RE | `FireServer(dir: Vector3)` | 当前移动方向; 无输入则用相机 LookVector 水平单位向量 |
| AirState | RE | (未在 Weapon_Input 热路径展开) | 同 Inputs 夹 |

持按攻击实现: `u19=true` 后 `task.spawn` 每 **0.1s** 调 `fireAutoAttack`, 同时挂 `Animator.AnimationPlayed` 做节奏补发。服务端 `Weapon_Manager.Attack` 用 `CanAttack()` + 攻速动画 `Attack_<Turn>`; 命中在服务端 `Enemy_Manager` (客户端这份模块里有 `OnServerEvent`, 是共享模块, 命中权威在服)。

技能槽映射: `Skill1=1, Skill2=2, Skill3=3, Skill4=4, SkillE="E"`。

### Knit 业务服务 (开发优先)

进本 / 局内:

- `DungeonQueueService`: `RequestEnter`, `RequestStartSoloRun`, `RequestStartNow`, `RequestSelectDungeon`, `RequestSelectDifficulty`, `RequestSelectModifiers`, `RequestSelectMode`, `RequestPartyData`, `RequestInvite`/`Accept`/`Decline`, `RequestLeaveQueue`, `GetDungeonAccessState`, `GetUnlockedDifficulties`, Raid/BossRush 入口
- `DungeonRunService`: `GetSessionInfo`, `SelectChests`, `SelectMidRunChests`, `RequestReplay`, `RequestReturn`, `SubmitEndlessChoice`, `ConfirmSpecialBossSummon`, `RequestZoneLayout`, `RequestDungeonChange`
- `DungeonService`: 状态/Boss血/通关广播 (多为 RE)
- `DropService`: `CollectDrop(id, dropType, value, sourceId, materialId)` — 地面币/宝石/血瓶/锻造石
- `DungeonChestService`: 箱体采集 (RE: `ChestCollected` / `BookCollected` / `MimicTriggered`)
- `DungeonBuffService`: `SelectBuff` (局内选增益)
- `PotionService`: `UsePotion` / `ConsumePotion` / `EquipPotion`
- `PortalService`: `UsePortal`
- `BossRushService` / `ChallengeRunService` / `RaidRunService`: 对应模式局内

大厅经济:

- `ShopService`: `BuyItem`/`BuyWeapon`/`BuyEquipment`/`SellEquipment`/`SellAllLootStorage`/`SellLootStorageByRarity`
- `EquipmentService`: `Equip`/`Unequip`/`DeleteItem`/`ToggleLock`/`CollectAll`/`CollectSingle`
- `InventoryService`: `MoveItem` / 图鉴领奖
- `BankService`: 存取装备
- `ChestService`: 大厅箱子 `ClaimFreeChest`/`UseStoredChest`/`ConfirmRewards`
- `SummoningService`: `Spin` / 槽位锁切
- `ForgeService`: `ForgeItem`/`ReforgeItem`
- `CraftingService`: `Craft`
- `QuestService`/`AchievementService`/`BattlepassService`/`CodesService`/`PrestigeService`/`StatService`/`LoadoutService`

### 看起来像客户端可调、实际几乎必被拒的 RF (不要当功能入口)

未验证, 名字像 GM/发奖, 乱调会画像:

- `LevelService.AddXP` / `SetLevel`
- `LootService.GiveReward` / `GrantCurrency`
- `MonetizationService.GrantProduct` / `SetPremium`
- `PlayerActionService` 的 `SetMoney` / `ChangeClass` / `ApplyLevel` / `ActivateAdminFly` (RE)
- `Remotes.AdminOpenBossRush` / `AdminOpenRaid` / `AdminSoundEvent`
- `CmdrClient` 仅管理端

## Remote 清单

<!-- 战斗 Inputs 见上表; Knit 完整 70+ 服务 RF/RE 已在会话扫描, 路径规律: knit.Services.<Svc>.RF.<Name> -->

大厅 `ReplicatedStorage.Remotes` (非 Knit):

| 名 | 类型 | 推测动作 |
|---|---|---|
| TeleportToDungeon | RF | 传送进地牢图 |
| SellingFunc / SetSellStatus | RF/RE | NPC 出售 |
| DepositFunc / SetDepositStatus / GetBase | RF/RE | 仓库/基地 |
| DropFunc | RF | 丢弃 |
| Rebirth | RF | 转生 |
| ToolEvent | RE | 工具 |
| CombatFeedback | RE | 命中反馈(另有 Player.Remotes 同名) |
| DungeonStreakUpdate / EliteLuckBuff | RE | 连胜/幸运 |

## NPC / 地点坐标

## [2026-09-03 | pv1659 | 建档@0.1.0] 地牢运行时场景

当前客户端在 **Bandits Den / Normal** 局内 (`Generated_Bandits Den_<guid>`)。

Workspace 关键夹:

- `Generated_<DungeonId>_<guid>` — 本局程序生成地图
- `Dungeons` / `Challenge_Dungeons` / `Boss_Rush` — 预制
- `Loot` / `Portals` / `Traps` / `NPCs` / `ActiveProjectiles` / `SpellTelegraphs`
- `DUNGEON_START` / `SPAWN_MODEL` / `VOID_MODEL`

敌人: CollectionService 标签 **`Enemy` + `NPC`**。实测 Bandit 属性:

- `ItemId`, `Level`, `Difficulty`, `DungeonRun`, `RoomIndex`
- `HealthOverride` / `DamageOverride`
- `State` (Wandering), `IsDormant`, `CanAttack`, `IsFodder`
- MiniBoss: `IsMiniBoss=true`, `IsBoss=true` (Bandit Enforcer)
- 未进房间时 `IsDormant=true` — 自动战斗要先推进房间/唤醒

地面掉落: `DropService.SpawnDrops` 客户端生成, 走近后 `CollectDrop`。类型: `Coin` / `CoinBurst` / `Gem` / `Crystal` / `Health` 及其它。

地面装备展示: tag `FLOOR_ITEM` (ProximityPrompt 高亮, 采集走别的服务)。

大厅 NPC 对话数据: `ReplicatedStorage.DialogueData` (Blacksmith/Guide/Prestige 等)。

## 关键机制结论

## [2026-09-03 | pv1659 | 建档@0.1.0] 地牢表 `GameInfo.DungeonData`

解锁链 (需指定难度通关):

1. **Bandits Den** (`Bandit's Den`, Wood, T1) 起点
2. **Goblins** (`Goblin's Stronghold`, Forest, T2) ← Bandits Den / Hard
3. **Knights** (`Forgotten Ruins`, Castle, T3) ← Goblins / Hard
4. **Catacombs** (`The Catacombs`, T4) ← Knights / Hard
5. **Snow** (`Frostspire Bastion`, T5) ← Catacombs / Hard; 另有 SpecialBoss Awakened Devil, 召唤消耗 KeyTier=4 ×7
6. **Demon** (`Underworld Gate`, T6) ← Snow / Nightmare

### Devil Heart (恶魔心脏) 掉落来源 [2026-09-05 | pv1659 | 会话2.92 数据表实测]

- **唯一来源**: Snow 图 (Frostspire Bastion) SpecialBoss **Awakened Devil, The Azure Nightmare** 稀有掉落
- 掉率 **35%** (`SpecialBossRareDrop.Chance=0.35`), **最低难度 Nightmare** (`MinDifficulty`)
- 召唤代价: `SpecialBossSummonCost = KeyTier4 钥匙 ×7`; Boss 数值: 90000 HP / 6 血条 / 伤害 105 / Scale 2 (Multiplier 3)
- Boss 动作 (Boss_ActionData.Index["Awakened Devil"]): ClassSource=Azure Devil, 攻击冷却 0.8s, WindUp 0.25s, CombatSpeed 0.85, DefaultRange 24, Hitbox(20,12,22) — 动作模组就是玩家版蔚蓝恶魔
- 图鉴 (ItemIndexData): "Rare extract from the Awakened Devil on Frostspire (Nightmare+). Turned in to Valen and Jetstream." — Devil Hunter 称号解锁要 5 颗 + 200万金币 + 2 Exotic Ingots
- 普通怪/精英/LootChest 均不掉 (LootData/Enemy_Data/LootChestData 无 heart 条目)

### KingsCrown (国王王冠) 配方与 Exotic Shattered Armor (奇异碎片护甲) 来源 [2026-09-05 | pv1659 | 数据表实测]

- **配方** (`CraftingData.Recipes.KingsCrown`, Category=Equipment/Slot=Head): Exotic Essence ×25 + Celestial Ore ×300 + **Exotic Shattered Armor ×1**, 产物 KingsCrown (Rarity=Exotic)
- **Exotic Shattered Armor 唯一来源**: **Demon 图 (Underworld Gate, T6)** SpecialBoss **Scarlet Knight, The Crimson Revenant** 稀有掉落, **掉率 8%** (`SpecialBossRareDrop.Chance=0.08`), **最低难度 Nightmare**; 同表另有 Exotic Ore 100% 掉 (MinDifficulty 同 Nightmare)
- 召唤代价: `SpecialBossSummonCost = KeyTier5 钥匙 ×5`; Boss 数值: 150000 HP / 6 血条 / 伤害 220.5 / Scale 1.9 (Multiplier 3) — 对比 Snow 的 Awakened Devil (7×T4 钥匙, 35% 掉恶魔心脏)
- 普通怪/精英/LootChest/挑战图/raid 均不掉 (LootData/Enemy_Data/DungeonChestData/LootChestData/ChestData/ChallengeData/RaidData 全扫 0 命中)
- 结构同 Devil Heart 条目 (姊妹机制): 特殊 Boss 召唤图腾刷在 Boss 房, 推完图摸图腾召唤; 召唤位置条目可参考 (Skull_Totem 模式)

### Awakened Devil 召唤位置 [2026-09-05 | pv1659 | 会话2.92 Snow 图现场实测]

- 召唤图腾 **`Skull_Totem`** (ProximityPrompt: "Summon Special Boss" / 消耗 7×Platinum Key) **刷在主链最后一间 Boss 大房 (Room_13, 236×210) 内**, 距房中心 ~29 格, 正常 Boss (Boss_Spawn) 同房
- 即: 推完图到 Boss 房就能摸图腾召唤, 不在岔路里; 召唤出的 SpecialBoss 在 Boss 房内开战
- `SpecialBossHallway_Side_Room_12` (Zone 43×80) 是 Room_12 的 Side 通往 Room_13 的捷径走廊, 与召唤无关; Room_13 conns=Entry only (死路 Boss 房), Room_10 带 Altar_Spawn 是祝福祭坛 (Receive Blessing), 别混淆
- 图腾 God 模式确认: 名字 Skull_Totem, prompt ObjectText=7x Platinum Key (Tier-4 钥匙)

挑战图 (选本列表 `ChallengeModeDisplayOrder`): **Double Dungeon**, **Throne Room**, 均 `MinLevel=55`, `ChallengeMode=true`

隐藏: **Forest Challenge** (`Bandit's Hollow`, `HideFromSelect=true`) 是 Bandits 的波次版, 带 `Rooms[].Waves`

局内共性: `Lives=1`, `TimeLimit` 普通 300s / Double 180s, 难度档 Easy/Normal/Hard/Nightmare/Endless, 局末宝箱 `LootChestCount 1~5`, 词缀见 `ModifierData`。

局内选箱: `DungeonRunService.SelectChests` / `ChestSelection` RE; 中途箱 `SelectMidRunChests`; 通关后 `RequestReplay` / `RequestReturn`。

## [2026-09-03 | pv1659 | 建档@0.1.0] 职业

`Classes.Class_Data.GetAllClassNames()` 共 41 个。稀有度: Rare / Epic / Legendary / Mythic / Celestial / Exotic / Admin。

当前玩家: `Current_Class=Artemis` (Celestial), `PlayerLevel=10`, `Stat_GearScore=766`, `Stat_MaxHP=560`。

职业文件夹在 `ReplicatedStorage.Classes/<名>/`(技能与 VFX)。抽卡走 `SummoningService.Spin`。

## [2026-09-03 | pv1659 | 建档@0.1.0] 玩家属性 (局内可读)

战斗状态: `Weapon_Equipped`, `Block_Active`/`Block_Health`, `Sprint_Active`, `Heat`, `UltimateReady`, `SkillN_Charges`, `Dead`(攻击前检查)
局内总伤: **`Damage_Dealt`** (Player 属性, 队友客户端可读; hub v0.5.0 DPS 面板用它算总伤/DPS)

局状态: `InDungeon`, `DungeonRun`, `CurrentDungeon`, `CurrentDifficultyMode`, `Onboarding`, `DataLoaded`

数值: `Stat_*` (攻速/暴击/闪避/减伤/吸血/冷却/格挡上限等), `PlayerLevel`, `Stat_GearScore`

## [2026-09-03 | pv1659 | 建档@0.1.0] 客户端脚本入口

`PlayerScripts.Client`:

- `Controllers/` 54 个 Knit Controller (DungeonHUD / ChestSelection / Drop / Portal / Endless / Raid…)
- `UI/` 背包商店任务战令锻造
- `Gameplay/Actions` 很薄
- 战斗真正入口: `ReplicatedStorage.Player.Modules.Weapon_Input` + `Weapon_Input_Sink`

数据表全集: `ReplicatedStorage.GameInfo`(Dungeon/Enemy/Loot/Chest/Potion/Forge/Raid/BossRush/Stat/Key/Modifier…)

词缀: OnlyElites, TougherEnemies, IncreasedEnemies, MoreElites, NoParrying, DoubleHealth, NoDodging, NoSprinting。

钥匙: `KeyData` 有层级/Master Key/Mimic; 锁房间掉钥匙。

## [2026-09-03 | pv1659 | 建档@0.1.0] 反作弊观感 (未做 hook dump)

- 未跑 DataModel 元表扫描 (当前工具没有 `dump-anticheat-hooks`)
- 命中/伤害/掉落领取走服务端 RF/共享 Weapon_Manager, 改本地 HP 无效
- Knit 里有 `ModerationService`; 玩家属性 `CmdrEnabled=false`
- 功能默认 L1: 发游戏自己的 Attack/Skill/CollectDrop/选箱/Replay, 不要碰 Grant/SetLevel

## L2 手段登记 (危险功能对抗手段台账)

| 日期 | 功能 | 手段 | 目标 | 结果 |
|---|---|---|---|---|
| 2026-09-04 | Boss自动拼刀 | 读 Boss Animator/Hitbox 时机, 发游戏自身 `Inputs.Parry` | `Boss_ActionData` 名册 + IsBoss | 已进 hub v0.10.0; 进 Boss 房开光环复核掐连段 |
| 2026-09-06 | 谨慎避战 | L1: 发游戏自身 `Inputs.Dash`(Dodge/Q), 不模拟按键 | NPC `AoE_Telegraph` 粒子 Enabled(含 Attachment); 含 Boss 圈 | hub v1.18.2 |

## 可复用代码片段

```lua
-- Knit 客户端
local Knit = require(game.ReplicatedStorage.Packages.Knit)
local DropService = Knit.GetService("DropService")
local ok, res = DropService:CollectDrop(dropId, dropType, value, sourceId, materialId):await()

-- 战斗
local Inputs = game.ReplicatedStorage.Player.Remotes.Inputs
Inputs.Attack:FireServer(moveDir) -- Vector3, 可 zero
Inputs.Skill:FireServer(1, "tap", moveDir)
Inputs.Parry:FireServer()
Inputs.Block:FireServer("start") -- / "stop"
Inputs.Dash:FireServer(dir)
Inputs.Sprint:FireServer("start")

-- 场景
local lp = game.Players.LocalPlayer
local inDungeon = lp:GetAttribute("InDungeon")
local dungeonId = lp:GetAttribute("CurrentDungeon")
```

找敌人: `CollectionService:GetTagged("Enemy")`, 过滤 `IsDormant` 与距离。

## 功能可行性 (给下一轮开发排期)

按「能做且值」排序, 均未实现:

1. **自动普攻** — L1, 复用持按协议 `Attack:FireServer(dir)` + 间隔 ≥100ms (游戏自己就是 0.1s)
2. **自动吸掉落** — L1, 扫地面掉落调 `CollectDrop` (先对一颗实测服务器是否校验距离)
3. **低血喝药** — L1, `PotionService:UsePotion`
4. **通关自动选箱 / Replay** — L1, 听 `ChestSelection`/`DungeonComplete` 再 `SelectChests`/`RequestReplay` (参数要再反编译 ChestSelectionController)
5. **自动进本(大厅)** — L1, `DungeonQueueService:RequestSelectDungeon` + `RequestStartSoloRun` (必须在大厅图测)
6. **敌人/箱/门 ESP** — L1, 只读 tag
7. **自动放技能** — L1, Skill 发包; CD 看 `SkillN_Charges` 与职业模块
8. **自动格挡/拼刀** — L2, hub v0.10.0 已做 **仅 Boss 拼刀** (Parry 包); 举盾 Block 未做
9. **瞬移清图** — L2, 位置多半服务端校验房间, 优先走传送门 `UsePortal` 而不是写 CFrame

## [2026-09-03 | pv1659 | 会话2 全量功能逆向] 键位/技能/结算/场景新结论 (均已反编译+实测)

### 键位动作表 (InputMapData, 客户端可重绑, 重绑存 PlayerData.Keybinds)
| Action | 默认键 | 说明 |
|---|---|---|
| Attack | LMB(不可重绑) | 按住自动攻, 客户端 0.1s 连发 |
| Skill1/2/3/4 | 1/2/3/4 | 技能槽 |
| SkillE(Ultimate) | G | 大招(有 HasUltimate/UltimateReady) |
| Potion_Health | 5 | 喝装备血瓶 |
| Sprint | LeftShift | 按住 |
| ParryBlock | F | 点=拼刀, 长按=格挡 |
- Dodge (Q): 玩家属性 `Dodge_Cooldown_Active` / `Dodge_Cooldown_Duration`(现号 2s); 角色 `Dodge=true` 为闪避中/技能保护, **不是 CD**. 冷却条只跟 Active (hub v1.0.6).
| ShiftLock | LeftControl | 相机锁 |
| Walk | V | |

### 技能发包 (Weapon_Input 反编译核对)
- 槽映射 `u17 = {Skill1=1, Skill2=2, Skill3=3, Skill4=4, SkillE="E"}` → `Skill:FireServer(slot, "tap"|"hold", dir)`; 客户端发前查 `SkillN_Charges/_MaxCharges` 属性, 大招查 UltimateReady。
- 服务端技能数据 = **共享模块 RS.Classes.<Class>.Skills/<技能>.lua** (客户端可直接 require 读数据, 不会执行 Activate): 每个技能表含 `HitboxSize`(Vector3) `HitboxRange`(前方距离) `Cooldown` `DamageMultiplier` `MaxCharges` `MaxDuration` 等。技能 Activate 把 ClassData.HitboxSize/Range 临时替换后调 Weapon_Manager:Hitbox() 扫前方盒。**技能范围 = 客户端可读的服务端权威数值**。
- 平A范围同理: `Wep_Data.HitboxSize` + `Wep_Data.Range`(服务端 Weapon_Manager.Hitbox, Hitbox Part 焊 HRP 前 C0(0,0,-Range/2))。

### ShowHitbox "命中框调试" (SettingsController)
- 设置键名 `ShowHitbox` (SettingsService 同步)。开启后服务器攻击时创建的 `HumanoidRootPart.Hitbox` 半透明绿(ForceField Material), 命中瞬间 CombatFeedback=="Hit" → FlashHitbox 变红 0.25s。**它就是攻击判定盒的可视化**。
- hub v0.4.1 杀戮光环距离: 读该 Hitbox (Weld C0.Z + Size.Z/2); 没有盒时读 `Classes.<Current_Class>.Definition.Range` (锻造霸主=16)。不用 RangeOrder 第五段特殊距离当默认圈。
- hub v0.4.2: 闲置 Hitbox Size≈0.05 时 reach=`2*|C0.Z|`(=Range); 挥击中才用 `|C0.Z|+Size.Z/2`。
- hub v1.3.1 远程杀戮: 阿蒂米斯档案 `Ranged=true`(平A 32) 与锻造霸主弓形态(26) 会拉开到射程约 58%, 有怪时不走进房间中心。近战职业仍进中心清怪。

## [2026-09-04 | pv1659 | hub@0.4.2] 锻造霸主切武器 (平A必须跟形态)

- 3技能 **Hrunting** Activate 末尾 `ClassData.EnterBowMode(self)`: `SpecialMoveset=1`, 隐藏双剑、显示 `HRP.Holder.Left_Arm.Bow`。
- 4技能 **Supreme Cell Blades** Activate 末尾 `EnterMeleeMode`: `SpecialMoveset=0`, 藏弓、亮双剑。
- 客户端识别: `Bow.Transparency < 0.5` = 弓形态 (无 Player 属性)。
- 近战平A: `Definition.Range=16`, `HitboxSize=(15,10,17)`; 第五段才用 `RangeOrder.5=27` / `HitboxSizeOrder.5=(13,10,35)`, 不当默认圈。
- 弓形态平A: `Range + SpecialRangeBonus` = 16+10=**26**; `SpecialTurnCount=4`。
- 切形态瞬间闲置 Hitbox 的 C0 可能还是旧 Range, 杀戮光环弓形态优先信职业表, 不跟过期盒。

### 喝药链路 (UI_PotionController)
- 动作 `Potion_Health` InputBegan → `PotionService:UsePotion(1):await()` (slotIndex=1=血瓶槽)。冷却服务端权威 (POTION_ON_COOLDOWN)。**脚本低血喝药 = 直接调 UsePotion(1)**, 不等按键。

### 结算/重开/回城链路
- Boss/通关奖励 Reveal: `AccessGateService.RewardReveal` RE → `RewardRevealController:PlayEntries(entries, title)` → runCascade: 每卡 popIn(UIScale 0.5→1, 0.28s Back) + 卡间 0.15s + 尾 wait(2) + hideGroup(0.4s)。u3/u4/u5 = TopLevel.RewardReveal(CanvasGroup)/RewardsFrame/ItemsTemplate。
- 选箱: `DungeonRunService.ChestSelection` RE → ChestSelectionController._Show → _OnFinish 调 `SelectChests(表)` / MidRun→SelectMidRunChests; BossRush→SelectFloorChests。
- **重开/回城按钮在 DungeonHUDController**: `OnReplayButtonPressed` → `DungeonRunService:RequestReplay()`; `OnCloseButtonPressed`(状态 Extracted/Failed/Cleared) → `RequestReturn()`; 其它模式走 BossRushService/ChallengeRunService/RaidRunService 同名字; 均无参。
- RewardReveal 加速方案: require Client.Controllers.RewardRevealController 覆写 PlayEntries 自实现立现。

### 场景结构 (Bandits Den Normal, Generated_Bandits Den_<guid>)
- 子级: Room_1..16 / Locked_N / NPCs / `DungeonChest_<guid>`(宝箱 Model, **无 tag**) / Blessing_Altar / Potion_Station / WallCap_*。
- Potion_Station: ProximityPrompt ActionText=`Refill Potions` ObjectText=`Potion Station`; 大厅也能扫到; 靠近自动交互 = fireproximityprompt (hub v0.9.0)。
- Room 结构: Parts(装饰) / Spawns(Player_Spawn|Enemy_Spawn|Chest_Spawn) / Connectors(Exit:Part 房间出口点) / Zone(房间区域大 Part) / TileAnchor。Locked 另有 KeyModel(ProximityPrompt+Keyhole) + Door。
- tag 实测: Enemy=66, NPC=36; 宝箱非 Chest tag; Portal tag → PortalService:UsePortal(名)。

### 冰图自动寻路 [2026-09-04 | pv1659 | hub@1.1.0 / 1.1.6]
- 图 `Generated_Snow_*`, Room_N 带 Connectors `Entry`/`Exit`/`Side`. Side 是岔路小房, 主链只跟 Exit 对下一房 Entry.
- 中间走廊也有小 `Room_N`(祭坛), 无 `Enemy_Spawn`、窄边<70。寻路只把有刷怪点或 min(Zone.X,Z)≥70 的当正房。
- 房间之间 `Parts.Gate` 关闭时 CanCollide=true, MoveTo 过不去。自动寻路: 路过的门本地关碰撞, 沿绿线走。F1 仍是 `CFrame = Exit.CFrame * CFrame.new(0,3,-14)` 手动闪门。
- 顶栏 `HUD.Dungeon_Container.Completion_Progress`: 横向 `ZoneSlot` (底图 `rbxassetid://99033898265265`)。**完成标记是叠上去的星星** `Completed` (`rbxassetid://72072883813318`), `Visible=true` = 这一格已清完。`Treasure`/`Boss` 是格类型图标 (宝箱/Boss), 不是完成态。同级 `Current` 是当前位置指针, 不是星星。**清完倒数第二格后 Current 会提前贴到 Boss 格, 人还在上一战斗房** — 不能当「已进 Boss 房」. 真 Boss 房看 `Spawns.Boss_Spawn`.
- **[hub@1.29.4 | Mage pv 现场]** UI **可以**判断完成度, 但要分两层, 且顶栏一格 ≠ workspace 每一个 `Room_N` (过廊/L 拐角也占 Room, 不占星星):
  - **当前遭遇还剩几只**: `Dungeon_Container.Info` 可见时 `Mob_Counter` (`Enemies Left:` + `Progress_Text` 数字) 是服务端权威剩余。现场 Room_17 计数 27, 身边 150 格 Tagged Enemy 活怪却是 0 — 寻路扫身边怪会漏, UI 计数才是「这区还没清完」。`Info`/`Mob_Counter` 藏起来才表示这段怪计数结束 (箱/药另算)。
  - **整图房间进度**: 数顶栏亮着的星星 (`ZoneSlot.Completed.Visible`). 现场 10 格, 第 1 格星星亮=已完成; Mage 同图 `Room_*` 约 28 (战斗 7 / 过廊 11 / 其它 10). Current 最近格=当前 Zone。
  - **不要读残字**: `Objective_Frame` 关掉时 `Objective_Text` 仍可能留着 `ROOM CLEARED` / `SURVIVE THE RUSH`。必须父级 Visible。
  - **闪字不能当状态**: `Notification_Canvas.Zone_Cleared` / `Boss_Slain` 默认隐藏, 只是飘字。结算 `Completion_Info` 是整局不是单房。
  - **房间 Instance 没有 Cleared 属性** (只有 `IsCheckpoint` 等)。
  - 服务端还有 `DungeonRunService.RE.ZoneEntered` / `PlayZoneClearSound` / `RoomLayoutUpdate`; hub `Nav.uiCleared()` 读当前格星星; **v1.30.0** 自动重开下普通地牢同一格+星星数 10 分钟不变 → `Humanoid.Health=0` Roblox 重生 (本游戏上一战斗房刷出). 爬塔/BossRush/Raid 不走.
- 过廊时 Current 也可能提前跳格; 寻路进度 lastRoomN 前进只增不减, 禁止路径走完 seek 回 Room_1. **例外**: 角色死亡回上一战斗房重生时必须把 lastRoomN 对齐当前房并丢掉旧绿线, 否则会沿穿墙路点撞墙卡死 (hub@1.2.4)。
- **[hub@1.2.7]** 走廊路点左右探墙取中线; 默认不走高度差>4.5 的点 (不 Jump). 例外: 捡箱、廊中祭坛/箱、进 Boss 房。补药仍拍回当前地面。
- **[hub@1.22.1]** 连撞硬墙会从当前位置侧绕重算到原终点 (PFS 半径 5/3/2.2 + 侧点), 不再只靠跳/跳路点/回房中心。规划失败的直线 `shapePts` 仍是最后兜底, 可能穿墙。

### 死亡回上一间 [2026-09-05 | pv1659 | hub@1.2.4]
- 局内死亡会在上一间战斗房重生, 不是原地。旧路点/hallKey/leaving 仍指向后一间, 叠加上「编号更小的 Zone 当走廊」会让人沿直线钻墙。
- 信号: Health<=0 / Dead / 角色实例更换 / 水平位移>48。对齐后从当前房中心再走 Exit→下一房 Entry。
- 血瓶数量 UI: `Actions.Bottom.Actions.Health.Amount` 文本 `xN`. 寻路补药 (hub@1.2.6): 当前瓶数 < 上限 (文本 `n/max` / 属性 / 本局见过的最大数) 且本房有炼药锅就补, 少一瓶也补. hub@1.3.2: 账号上限常高于本局能灌的量, 锅边灌完(数量涨停/已满/约2秒)必须 skip 本房炼药锅并继续寻路, 不能死等 n==属性上限.
- 地上箱 Prompt `ActionText=Loot`, 未解锁 `Enabled=false`.
- 结算: 任一 `*_Container.Completion_Info` Visible 即可 `DungeonRunService:RequestReplay()`.

### 运行实测 (Potassium PID 24236)
- **WalkSpeed 28→44.8, 7s 不回落** → 移速功能常驻覆盖即可, 无需 hook (L1)。
- **keypress 合成输入不触发 UserInputService.InputBegan** (fired=0) → 自动攻击/技能/喝药/冲刺**必须 FireServer**, 不能靠模拟按键。
- Potassium keypress 参数是数字 VK 码, 非 Enum.KeyCode (报错提示)。
- 当前玩家 Class=Shinobi (Lv12), 档案里 Artemis 是历史存档。技能1=Flash Rend 2 charges。

职业表写在 `hub.luau` 的 `CLASS_ARCHIVE_RAW` (v0.9.1 起不再读 class-archive.luau)。

杀戮光环平A距离走职业档案 `MeleeRange`(=Definition.Range, 闲置触及), 挥击盒明显更长才跟实时 Hitbox。已归档:

| 职业 | 平A Range | HitboxSize | 备注 |
|---|---|---|---|
| Cursed Child | 18 | (15,10,18) | 当前角色 |
| Forge Archon | 16 / 弓26 | (15,10,17) | SpecialRangeBonus=10 |
| Shinobi | 14 | (18,10,14) | 忍者; Lv46 已补技能档案 |
| Artemis | 32 | (15,15,35) | 无 Definition 模块, 数据在 Class_Data |
| Flame Bastion | 19 | (20,10,19) | 中文「火焰据点」; Epic 长枪 |

### 忍者 (Shinobi) [2026-09-04 | pv1659 | hub@0.10.1 实测补全]

当前玩家 `Current_Class=Shinobi` Legendary Lv46, 局内 Snow。平A `Range=14` `HitboxSize=(18,10,14)` `AttackSpeed=1.1` `TurnCount=3` `DirectionalLungeStrength=2`。技能模块 **require 成功**。`Class_Data.Skills`: 1=Flash Rend / 2=Kurogiri / 3=Guillotine Drop / 4=Oni Rend。档案写了 Skills 即 SkipRequire。

| 槽 | 技能 | 判定 | 结构 |
|---|---|---|---|
| 1 | Flash Rend | Size(20,10,22) Range=18 | MaxCharges=2 cd8 MaxDuration1.2 IFrame1 单段斩 |
| 2 | Kurogiri | Size(22,10,20) Range=18 | cd7 MaxDuration2.5 DashSpeed80 IFrame0.45 烟闪连斩 |
| 3 | Guillotine Drop | AoE(28,20,28) Range=15 | cd9 MaxDuration2.5 DashSpeed70 IFrame0.8 前突后落地 AoE |
| 4 | Oni Rend | Size(20,12,20) Range=20 | cd12 MaxDuration2.5 DashSpeed80 FinalHit=4 ParryAfterHit=3 ParryDuration0.6 |

### 被诅咒的孩子 (Cursed Child) [2026-09-04 | pv1659 | 会话2.17]

当前玩家 `Current_Class=Cursed Child` Lv17。Mythic。平A `Range=18` `HitboxSize=(15,10,18)` `AttackSpeed=1` `TurnCount=5` `DirectionalLungeStrength=2.2`。无切形态。
`Classes.Cursed Child.Skills/*` 含 Activate, 钾上 `require` 失败, 判定靠反编译。

| 槽 | 技能 | 判定 | 结构 |
|---|---|---|---|
| 1 | Hollow Rush | Size(20,10,20) Range=16 | cd7 MaxDuration2 DashSpeed80 IFrame0.7, 冲刺后连斩 |
| 2 | Severance | Size(26,10,29) Range=29 | MaxCharges=3 cd8 DashSpeed95 MaxDuration1.2 宽横斩 |
| 3 | Cursed Speech | Size(28,20,35) Range=30 | cd13 StunDuration3 范围定身 (Boss 抗眩晕) |
| 4 | Cursed Love | TickSize(30,30,45) TickRange=40 | cd15 MaxDuration5 前方射线 tick, 无 HitboxRange 字段 |

### Artemis 技能判定数据 (RS.Classes.Artemis.Skills) [2026-09-04 | pv1659 | 会话2.21 实测补全]

当前玩家 `Current_Class=Artemis` Lv20, Celestial。平A `Range=32` `HitboxSize=(15,15,35)` `AttackSpeed=1.28` `TurnCount=5`。无 Definition 模块, 平A 在 Class_Data。技能模块 **require 成功** (含 Activate, 钾上未炸)。`Class_Data.Skills` 槽映射 1=Twin Bolt / 2=Moonfall / 3=Tempest Strike / 4=Stormfire; 5 为 13 级被动 Spectral Hunt。

槽位解析靠模块内 `AnimationName = "Ability_N"`。职业档案写在 hub `CLASS_ARCHIVE_RAW` (写了 Skills 即 SkipRequire)。

| 槽 | 技能 | 判定 | 结构 |
|---|---|---|---|
| 1 | Twin Bolt | Size(20,15,25) Range=25 | MaxCharges=3 cd4 MaxDuration1 DashSpeeds 60/70; hold 档 HoldRange24 HoldMaxDuration3 — 自动只发 tap |
| 2 | Moonfall | Size(28,20,28) 无 HitboxRange | **前方落箭雨** ForwardDistance=15 RainDuration3 Tick0.25 cd12 MaxDuration3; 光环距离用 15+盒半14=**29** (不是原地雨) |
| 3 | Tempest Strike | Size(40,20,30) Range=25 | MaxCharges=2 cd7 MaxDuration2 DashSpeed70 IFrame0.5 |
| 4 | Stormfire | Size(25,15,30) Range=28 | cd12 MaxDuration3.5 DashSpeed55 DashDuration0.12 多段突进; hub@1.0.2 连段跟相机扭脸, extra=视角水平方向 |

### 火焰据点 (Flame Bastion) [2026-09-04 | pv1659 | 会话2.38 实测]

当前玩家 `Current_Class=Flame Bastion` Lv33, Epic。平A `Range=19` `HitboxSize=(20,10,19)` `AttackSpeed=1` `TurnCount=4` `DirectionalLungeStrength=2.4`。技能模块 **require 成功**。`Class_Data.Skills`: 1=Pyre Cyclone / 2=Blazing Reach / 3=Ember Step / 4=Ashen Onslaught。日常 `CompleteWithClass` 文案即 `Complete 3 Dungeons using Flame Bastion` (任意图通关×3)。

| 槽 | 技能 | 判定 | 结构 |
|---|---|---|---|
| 1 | Pyre Cyclone | Range=14 AoE(20,10,20) | cd6 MaxDuration2 ParryDuration0.6 原地三连扫; Stationary |
| 2 | Blazing Reach | Size AoE(25,20,28) Range=25 | cd10 MaxDuration2 DashSpeed90 HitCount=6 长枪连突 |
| 3 | Ember Step | Size(20,10,20) 无 HitboxRange | MaxCharges=2 cd7 MaxDuration1.5 DashSpeed70 IFrame0.5 冲斩 |
| 4 | Ashen Onslaught | Size(20,10,20) | cd10 MaxDuration2.5 DashSpeed40 HitCount=5 五连推进; StationarySkills=true |

### 卡奇 (Kage) [2026-09-04 | pv1659 | 会话2.46 实测]

当前玩家 `Current_Class=Kage` Legendary。平A `Range=17` `HitboxSize=(15,15,17)`。技能模块 require 成功。

| 槽 | 技能 | 判定 | 结构 |
|---|---|---|---|
| 1 | Shadow Step | Range=28 Size(20,20,28) | cd8×3 Duration2 WarpSearch60 背后斩 Dodge 保护 |
| 2 | Heart Stab | Range=15 Size(20,15,20) | cd10 Duration8 WarpSearch60 锁血连锁背刺 |
| 3 | Devouring Gale | Size(30,30,30) Range字段0 | cd10 Duration2.5 原地旋斩 Parry1.4 |
| 4 | Fists of Ruin | Range=17 Size(15,15,17) | cd15 Duration5 Parry4 多段拳+终击 |

### 真空 (Vacio) [2026-09-05 | pv1659 | 会话2.90 实测]

`Current_Class=Vacio` Celestial, 法师系**远程** (用户确认; 技能 30~40 格但平A 21<26, 档案须显式 Ranged=true)。数据源: `RS.Classes.Class_Data` (ModuleScript, 注意已从 GameInfo 挪到 Classes 下) require `t["Vacio"]`: 平A `Range=21` `HitboxSize=(15,15,21)` `AttackSpeed=1` `TurnCount=4` `ParryDuration=0.6` `DamageType=Magic` `UseProjectile=false` (弹道字段是摆设, 平A仍是前方盒)。技能模块 `Classes.Vacio.Skills/*` 钾上 require 返回空表 (纯 Activate), 判定走 decompile:

| 槽 | 技能 | 判定 | 结构 |
|---|---|---|---|
| 1 | Flash Step | Size(25,15,30) Range=30 | cd5 MaxCharges=3 DashSpeed80 DashDuration0.15 IFrame0.6 ParryDuration0.3 MaxDuration3 PhantomSearch50 |
| 2 | Cero Blast | Size(20,20,40) Range=35 | cd12 MaxDuration3 |
| 3 | Sonido Barrage | Size(20,15,32) Range=30 | cd14 BarrageMaxDuration1.5 TickInterval0.08 MaxDuration4 Stationary 无击退 |
| 4 | Javelin Toss | Size(30,40,40) Range=40 | cd16 LiftSpeed0 MaxDuration3 Stationary |

## [2026-09-04 | pv1659 | 钾实测@Flame Bastion] 格挡 / 拼刀

F (`ParryBlock`) 两套动作, 不是同一个:

- **点按** `Inputs.Parry:FireServer()` = 拼刀。窗口看职业 `Definition.ParryDuration`(火焰据点 0.55s, 多数职业 0.5~0.65, Zero=0.75, 枪系/暗教授 0.25) + 装备 `ParryExtension`(头, 上限 0.5s) + 局内 buff Steadfast(+0.05~0.3s) + 成就 `AchBoost_ParryFrames`(上限 +3 帧)。CD 职业 `ParryCooldown` 约 1.8~2.5s; 运行时 `Parry_Cooldown_Active` / `Parry_Cooldown_Duration`。
- **长按** `Inputs.Block:FireServer("start"|"stop")` = 举盾。`Block_Active` + 盾量 `Block_Health`/`Block_MaxHealth`(与 `Stat_BlockMaxHealth` 一致, 现号 130)。装备文案: Block Strength=盾能吃多少伤才碎; Block Rate=额外挡住攻击的概率(身体, 上限 15%)。

大作用在 **拼刀**: `Boss_ActionData` 几乎所有 Boss 的 `BasicString.EndChainOnParry=true` — 拼中会掐掉连段。词缀 `NoParrying` 直接禁拼刀(只给 XPMult 0.05), 说明设计上拼刀是核心减伤/破招手段。武器形态 Aegis `Trigger=OnParry`: 成功拼刀放 18 尺 Nova、伤害 250%、眩晕 3s、自身增伤 25% 持续 5s。技能也可带短拼刀窗(如 Pyre Cyclone `ParryDuration=0.6`)。有 `ParryFX`/`Parry_Anim`/`unblockable` 动画 — 部分招式无法拼。

自动拼刀 (hub v1.3.0): 杀戮平A/技能光环任一开, 对 **精英+Boss** 出招窗发 `Inputs.Parry`. 小怪 (`IsFodder` 且不是 Boss/精英标) 不拼. Demon 图 Boss 也会带 `IsFodder=true`, 必须以 IsBoss/HighlightPriority 为先. 举盾仍不自动。词缀 NoParrying 不发。

## [2026-09-05 | pv1659 | hub@1.8.0] 岔路小房流送 + 装备攻速

- 死路小房 (仅 Entry, 大房 Side 重合): 模板常有 Enemy_Spawn + Chest_Spawn, **怪和箱要进门才刷**。门外扫 `DungeonChest_`/活怪会判空, 主链 nextHop 已把 Side 房排除, 结果直接去下一战斗房。判定改为看 Spawns 点, 进过再 `sideDone`。
- `Stat_AttackSpeed` 是穿戴汇总的攻速百分比 (Cap 60)。平A间隔 = `0.099 / (职业AttackSpeed × (1 + Stat_AttackSpeed/100))`。成就 `AchBoost_AttackSpeed` 同加。不必扫装备栏。

### 蔚蓝恶魔 (Azure Devil) [2026-09-05 | pv1659 | 会话2.91 实测]

`Current_Class=Azure Devil` Celestial, 双刀**近战**。数据源 `RS.Classes.Class_Data` require: 平A `Range=19` `HitboxSize=(15,10,19)` **`AttackSpeed=1.35` (全职业最快)** `TurnCount=4` `ParryDuration=0.6` `ParryCooldown=1.8` `DamageType=Physical`。技能模块 decompile 判定:

| 槽 | 技能 | 判定 | 结构 |
|---|---|---|---|
| 1 | Spatial Cut | Size(25,10,35) Range=35 | cd4 MaxCharges=3 Dash70/0.15 AirHitbox(20,30,30) MaxDuration1.2 |
| 2 | Cross Cut | Size(24,40,30) Range=28 | cd7 Dash90/0.29 IFrame0.5 MaxDuration2.5 |
| 3 | Void Cleave | Size(28,10,30) Range=30 | cd10 MaxDuration3 Stationary 无击退 |
| 4 | Judgement Rush | TickSize(24,12,24) TickRange=22 | cd15 Tick0.15×0.25 MaxDuration6 Stationary |

技能名映射: `Skills.1=Spatial Cut 2=Cross Cut 3=Void Cleave 4=Judgement Rush 5=(Lv.13 Passive) Phantom Strikes`。

## [2026-09-04 | pv1659 | hub@0.10.0] 换服会拆脚本

- RequestReplay / RequestReturn / 大厅↔地牢 走传送, DataModel 重建, 必须重新注入
- 钾有 queue_on_teleport; 局内下一房间不传送
- **[2026-09-05 | hub@1.2.5]** hub 不再 `ArmTeleportReload`。换图注入只靠钾 autoexec (`games/dungeon-raiders/potassium-autoexec.luau`)

## [2026-09-04 | pv1659 | 钾实测@假名] 角色名牌位置

- 3D 名牌不在 `LocalPlayer.Character`, 在 `Workspace.PlayerModels.<用户名>.HumanoidRootPart`
- `Player_Healthbar.NameText` = 用户名; `TitleBillboard.TitleText` = 称号 (如 VIP)
- HUD `Main.HUD.Actions.Profile.ProfileHolder.User` = DisplayName

## [2026-09-05 | pv1659 | 钾实地@Demon] 房间生成结构全景 (9 图配置 + TileData + 现场解剖)

### 地牢表核心数值 (DD.Dungeons.<名>)

| 图 | Tier | 战斗房数(按难度) | 锁房 | 每房怪 | MaxNPC | 战利品房概率 | 时限 | MiniBoss |
|---|---|---|---|---|---|---|---|---|
| Bandits Den | 1 | Easy4/Normal5/Hard6/NM7 (+Boss=总数) | 1~2 | 10 | 12 | 0.3 | 300s | Bandit Enforcer |
| Goblins | 2 | 5/5/6/7 | 1~3 | 10 | 12 | 0.3 | 300s | Goblin Warchief |
| Knights | 3 | 6/6/7/7 | 1~4 | 10 | 12 | 0.3 | 300s | Knight Champion |
| Catacombs | 4 | 6/7/7/7 | 2~4 | 10 | 14 | 0.3 | 300s | Dark Revenant |
| Snow | 5 | 表无按难度, Count=8 | 2~4 | 10 | 14 | 0.3 | 300s | Frost Warden |
| Demon | 6 | 7/7/8/8 (+1 Boss = 9~10) | 2~4 | 12 | 18 | 0.3 | 360s | Black Fang |

- `GetEstimatedRoomCount(图名, 难度)` = CombatRoomCountByDifficulty[难度] + 1 (Boss房), 返回 {Min,Max}
- 挑战图: Double Dungeon (Lv55, BossRotation 6 Boss 轮换: Scarlet Knight 9万→Imperator 11.25万→Shadow Knight/Unrestricted EX 12万→Awakened Devil 9.75万→+1, 全 5 血条) / Throne Room (Lv55, 固定 Boss=Imperator, ChallengeMap=Throne_Room, 敌池 Knight 系)
- Forest Challenge (隐藏, HideFromSelect): 固定 7 房波次表 Rooms[], Wave 数 6/6/7/8/10/12/6, Pool 混合 Bandit/Rogue/Archer/Strong Bandit, 无 MiniBoss

### 房型模板 (TileData.Biomes, 服务端生成选型池)

- 全 biome 共有: Start(Player_Spawn) / Connector(Hallway, Left/Right_Turn=走廊转角) / Combat(Large_Room_1, Large_Room_2) / Boss / Locked_Room_1 / Wall_Cap
- **Combat 第三模板按图不同**: Demon=Narrow_Room_1 (35x66 窄廊大房), 其他=常规
- **Loot_Room 模板只在 Wood/Snow/Catacombs 有**; Demon/Castle/Forest 没有 Loot tile (Demon 的战利品房是运行时属性 `IsLootRoom=true` 打在普通岔路房上)
- **Checkpoint_Room 只在 Wood(=Bandits)/Catacombs 有** (重生检查点)
- **Special_Boss_Room_1**: Snow/Catacombs/Demon 有
- biome 键映射: Bandits Den→Wood, Goblins→Forest, Knights→Castle, 其余同名

### 运行时房间结构 (Demon 现场解剖, Generated_Demon_<guid>)

- 主链: Room_1(Start) → 2(战斗 133x174, 9 敌点+2 普通+1 Rare 箱点) → 3(走廊 35x66) → 4(战斗同2) → 5(走廊) → 6(中型 89x124, **Altar_Spawn 祝福祭坛**+Extra_Spawn×4) → 7(走廊) → 8(**大房 196x174, Side×2 岔路**) → 9(Boss 133x174)
- **岔路房标记**: `Room_10` attrs `IsLootRoom=true, ParentRoomIndex=8` — 岔路房 30% roll 成 LootRoom, 属性直接可读, **寻路/拾取逻辑可直接用 `IsLootRoom` 属性判定, 不用猜**
- Room_9 attrs: `IsSpecialBoss=true, SpecialBossId=Scarlet Knight, SpecialBossPrespawned=true` — 本局 SpecialBoss = Scarlet Knight (Demon 图掉 Devil Heart 的是 Snow 的 Awakened Devil, 别混)
- **SpecialBoss 预生成**: `SpecialBossPrespawned=true` 表示 Boss 实体已放好, 进房即激活
- 空房槽位 Room_12~27: 大量编号空房是模板池预留, 只有带 Spawns 的才激活
- 房间 children 结构: Parts/Connectors/Spawns/Door(有锁才有)/Zone(碰撞大 Part)/TileAnchor
- 每战斗房 9 个 Enemy_Spawn 点, Demon 12 怪/房由服务器按 SpawnInterval=5s 分批灌入
- Zone 尺寸即房型: 战斗大房 133x174, 岔路大房 196x174, 走廊 35x66, 中型 74~89x70~124
- 走廊房无 Spawns; 判定正房=有 Enemy_Spawn 或 Zone min(X,Z)≥70 (旧结论复核通过)
- 装备品质权重 (DungeonRarityData.Weights, 按图): Demon Mythic100>Epic30>Legendary60; Snow Legendary100; Catacombs Epic100; Bandits Common100 — 岔路 LootRoom 掉落品质随图递进
- 大房战斗模式: 无 Waves (波次制仅 Forest Challenge); 标准=进房灌 12 怪 (Demon) / 10 怪 (其余), 5s 间隔, MaxNPC 上限截流; MiniBoss 混在战斗房池 (GruntCount=2 随从)


## [2026-09-05 | pv1659 | 钾实地] 钥匙房机制

- 钥匙库存: `Main.Frames.Inventory.Contents.InventorySection.ItemPanel.ItemGrid.key:T1~T5` + `key:Master`, Amount 文本 xN; T1~T5=Bronze/Silver/Gold/Platinum/Celestial, Master 0.5% 掉率全门通用
- Locked_N: 独立 Model (attrs ParentRoomIndex=主房号), KeyModel.ProximityPrompt ObjectText="Requires <名> Key" hold=0.8, Door.Animated=Up 即开
- KeyData.CanOpenDoor(keyId, tier): Master 全开, keyId>=tier
- 双箱制: Chest_Spawn×2 + Enemy_Spawn×1, 拿第一箱后刷守箱怪, 杀完解锁第二箱
- 玩家 Player 属性/角色/背包 ItemPanel 之外无钥匙数据 — 感知只能读 Inventory UI (ItemGrid 常驻渲染, 不用打开背包)


## [2026-09-05 | pv1659 | 用户确认+钾实地] 特殊BOSS行为修正 (已证伪旧认知)

- **特殊BOSS 打完无结算界面** (高级精英怪性质): 打完直接回大房继续主链, 不触发 Completion_Info — 走廊召唤型 (Snow Awakened Devil) 与主链直刷型 (Demon Room_9 IsSpecialBoss=Scarlet Knight, SpecialBossPrespawned=true) 都适用; 自动化流程 Boss 房清完必须继续 nextHop 出房, 不能干等结算
- **Demon 地图分段生成**: 岔路门/走廊随主链推进动态实例化 (SpecialBossHallway_Side_Room_N 空壳→激活); 推进中新段大房 Side×2 常见 → 寻路需要 2s 重扫而非一次性建图
- 兜底判据: 特殊BOSS 单怪房"怪数不减"不能当打不到的信号, 要看总血量是否在降

## [2026-09-05 | pv1659 | 会话3 实测] 挑战图爬塔机制 (Double Dungeon 波次竞技场)

> 机制本体在 `GameInfo.ChallengeData` (客户端可 require 读全量), 会话状态走 `ChallengeRunService.RF.GetSessionState` (无参, 直接返回状态表, 不用 await 解包)。

### 判定方式 (v1.11.0 修正, 会话4)

- ~~旧判定 (hub v1.9.x): `Dungeon_Container.Info.Depth` 存在 = 爬塔图~~ → **已证伪 [2026-09-05 | pv1659 | 会话4]**: 普通图 UI 现在也带 `Depth`+`Wave` 标签, 且打完爬塔后 `Challenge_Dungeons` 实体残留在 workspace — 旧判定把普通图当爬塔, 寻路失效 (v1.11.0 用户实测)
- **新判定**: workspace 有 `Generated_*` 实体 (普通图每局新生成带 GUID) → 普通图 (一票否决); 有 `Challenge_Dungeons` → 爬塔; 都没有 → UI Depth 兜底 (大厅/载入隙)
- 多血条 BOSS 每条血 = 独立 Model (钾实测 Awakened Devil hp=0 max=100 **无任何属性**), 死条模型留场景 — 怪活性判定必须查 `Humanoid.Health > 0`, 只看 Dead/IsDormant 会画假血条 (v1.11.0 用户实测)

### 核心循环 (ChallengeData 常量 + 反编译函数)

- **无限波次爬塔**: `InChallenge=true`, 打完一波下一波, 直到 3 条命耗尽或计时器归零 (双败条件)
- **计时器是全局共享的**: 初始 `START_TIME=60s`; 每杀小怪 +`TIME_PER_KILL=1.5s`, 杀 Boss +`TIME_PER_BOSS_KILL=5s`; 上限 `TIME_CAP=120s`; `IsTimerResetWave` = wave%10==0 时计时器重置 (Boss 波同节奏)。归零 = 失败
- **每 10 波 Boss**: `IsBossWave` = wave%10==0; Boss 轮换表 `BOSS_PREVIEW_ORDER` (6 个循环): Scarlet Knight → Imperator → Shadow Knight → Unrestricted EX → Awakened Devil → Frigid Monarch
- **每 10 波祝福**: `IsBlessingWave` = wave%10==0 (Boss 打完选增益), `BLESSING_GRACE=5s` 宽限; 增益落在 Player 属性 `RunBuff_CritRate/SkillCritChance/SkillDamage` (每层 5%) + `RunBuffStacks_*` 计层数
- **每 5 波箱子**: `IsChestWave` = wave%5==0; `CHEST_COUNT=3` 箱/次, `CHEST_LIFETIME=60s` 过期
- **怪量递增**: `GetWaveSize(wave)` = min(`WAVE_BASE_SIZE=8` + floor(wave/`WAVE_SIZE_DIVISOR=2`), `MAX_ALIVE=16`) → 16 波起满员 16
- **强度递增**: `GetWaveMult(wave)` = `SCALING_MULT=1.1` ^ floor((wave-1)/`SCALING_STEP=5`) → 每 5 波怪数值 ×1.1 (wave 62 ≈ ×3.14)
- **3 条命** `STARTING_LIVES=3`, 死光出局; 多人 `PARTY_CAP=4`, Boss 血量有 `GetPartyHealthMult` 队伍缩放

### GetSessionState 实测字段 (Wave 62 时点)

`PlayerCount=2, Phase="Combat", Wave=62, Lives=3, TimeLeft=82.5, TimeMax=120, BossHP=1430, BossMaxHP=548868, LocationId="Double Dungeon", LoadingLeft=0`

- `Phase` 取值见 "Combat" 与 Loading (载入间隙 `MAP_LOAD_TIME`/`LOADING_TIME`)
- 波次/计时/命 变化走 `ChallengeRunService.RE` 的 `WaveUpdate` / `TimerUpdate` / `TimeGain` / `LivesUpdate` / `BossHealthUpdate` / `PhaseChange`; 结束走 `DungeonComplete`, 重开投票 `ReplayStarting`/`ReplayVoteUpdate`, 观战 `EnterSpectate`/`SpectateTargetsUpdate`
- RF 仅 4 个: `GetSessionState` / `RequestReplay` / `RequestReturn` / `LeaveSpectate`
- [2026-09-05 | pv1659 | 会话4] `BossHealthUpdate` (hp, maxHp) 参数序按假设接线 (hub v1.11.0 挑战图 BOSS 真血条数据源), 未实测确认顺序 — 进塔打一波 BOSS 观察血条即可验证

### 爬塔结算窗与重开时序 (会话5, hub v1.12.9)

- **爬塔结算复用普通图容器**: `Main.HUD.Dungeon_Container.Completion_Info` (标题 COMPLETED + ReplayButton/DungeonButton/ReturnButton), 不是独立 UI
- **[实测] 结算窗弹出的瞬间**: `InDungeon` 属性**已翻 false**, 角色已移除 (Character=nil, hrp 不存在) — 任何依赖 hrp/InDungeon 的判定在该窗口下必然 return (hub v1.12.8 及以前 `tickTowerReplay` 被此门槛挡死, 爬塔胜利结算不重开; v1.12.9 把 atEnd() 检测提到门槛前修复)
- **[实测] 塔局重开服务**: 结算窗可见时 `ChallengeRunService` 仍可 GetService 到 (knit 服务目录常驻, 与是否局内无关); Replay 必须走 `ChallengeRunService:RequestReplay()` — `DungeonRunService:RequestReplay()` 对塔无效 (devlog 会话4 已归档, 会话5 复核成立)
- 普通图重开循环 (`tickReplay`) 的 atEnd 分支**必须**排除塔局 (`isTowerRun` 让路), 否则塔结算时误调 DungeonRunService 且吃掉共享防抖锁 Nav.lastReplay, 拖住塔重开 5s
- `GetSessionState` InvokeServer 非结算局内每次调用 ~70-220ms 网络往返 — 高频 tick 里别裸调 (dr_auto_replay 循环超时警告源), 需缓存节流 (遗留)

### 与普通地牢的差异 (开发注意)

- 无房间寻路问题 — 单竞技场 (`Challenge_Dungeons.Double_Dungeon` / `Throne_Room`, ARENA_ROOT="Challenge_Dungeons"), 自动战斗不需要 nextHop
- [2026-09-05 | pv1659 | 会话4 钾实测] **箱波实体**: 箱 = `DungeonChest_<guid>` Model, 挂在 **`workspace.Challenge_NPCs`** (与怪同目录, 非 Challenge_Dungeons/Loot!), Prompt ActionText="Loot"; 普通图箱挂 Generated_* 房间下, 同名前缀
- 自动打塔要点: 听 `WaveUpdate` 对齐波次; 箱波 (5%10) 顺手捡箱 (60s 限时); Boss 波 (10%10) 开拼刀; 增益选择 (Boss 后) 需要确认 UI 交互方式 (未拆, 候选: ChestSelection 类似控制器)
- `FEATURED_DUNGEON="Double Dungeon"` (轮换主打图), `NO_REPEAT_TOP_RARITY=true` (连续箱不重复最高品质)

### 当前角色新档案 (Awakened Devil EX)

`Current_Class=Awakened Devil EX` Lv92 (档案此前无此职业)。GearScore=4805, Stat_MaxHP=3487, Stat_AttackSpeed=3.3, Skill1_MaxCharges=2 (cd5), Skill2_MaxCharges=3 (cd4, HasHold), Skill3 cd5.7, Skill4 cd9.5, `Parry_Cooldown_Duration=1.8`。判定表待拆 (未做, 当前会话只做机制分析)。

## [2026-09-05 | pv1659 | 会话4 钾实测] 无限核心 (Honored One, Exotic) 机制

- Definition 反编译全量: 平A Range=20 / AttackSpeed=1 / DamageMultiplier=1.15 / Magic / TurnCount=4 (SpecialTurnCount=6) / ComboEndlag=0.3 / Crit 7%×1.8 / Dodge CD 1.8 (iFrame 0.65, 速度90)
- 技能组 (Skills.1-4 + E): 1 Blue 苍 (CD 3s, 5x, 奇点拖拽聚怪+无敌, **施放可拖动** — 用户实测可旋转拖怪) / 2 Red 赫 (CD 2.25s, 4x, tap直线 hold以自身为中心爆) / 3 Hollow Purple 茈 (CD 7.5s, 4x, 原地蓄力长直线) / 4 Infinity (CD 18.75s, 0x, 自buff: 30s 内 50% 减伤+15%攻速+15%移速, hold=回血) / E Infinite Void 无量空处 (充能100, **0伤害纯控场**, 100格全冻15s, StationarySkills.E=站桩长前摇)
- 全技能单充能 (MaxCharges 无多充字段); Skill2/Skill4 HasHold=true; NoKnockbackSkills: 1 和 E
- **技能模块 require 全崩** (`Requested module experienced an error while loading`, Skills/ 和 Skill_Modules/ 下都崩, Skill_Modules 副本是空 ModuleScript) → hub 档案走 SkipRequire 数据路径 (v1.12.0 起)
- 终极刷本优化 (v1.12.0): UltMinMobs=3 门 (60 格内活怪≥3 或锁 BOSS 才放; 残局捏住 — 0 伤害控场空放=纯亏站桩前摇) + PullSlot=1 TwistAfterPull=1.6 (丢 Blue 后自动绕奇点半径 8 格旋转 1.6s 把周围怪吸成一堆, 再接 Red/Purple AoE 总结)
- 技能发包: `Skill:FireServer(slot, "tap"|"hold", moveDir)`; HasHold 技能按 0.25s 判定长按 (InputEnded 早于 0.25s = tap)


## [2026-09-05 | pv1659 | 钾反编译 EndlessController] 无尽爬塔死亡惩罚规则

- **3 命耗尽 = 本轮自上个 Checkpoint 之后获得的全部材料/战利品清零**; Checkpoint 之前的保留 (官方原文: "Run out of lives past this checkpoint and you lose everything gained since it")
- **Extract (主动结算) = 安全落袋**: Checkpoint 清除对话框给 Continue / Extract 两选, Extract 即刻银行本轮收益
- Checkpoint 清除 → 继续则地牢重生成, 怪 +30% 强度 (NextMult), **3 命回满**; 对话框 60s 倒计时
- 里程碑奖励 (ChallengeRewardData.MILESTONES, Floor 10/20/.../300 → Coins 类) 是赛季累计奖励, 不受单轮死亡影响 (CURRENT_SEASON=1)
- 提示: 打不动就趁 Checkpoint 对话框点 Extract 落袋; 脚本未来可自动监听 EndlessDecision 事件默认选 Continue (贪) 或 Extract (稳)
- 数据: ChallengeData{TIME_PER_KILL=1.5, CHEST_WAVE_INTERVAL=5, CHEST_LIFETIME=60, CHEST_COUNT=3, BLESSING_WAVE_INTERVAL=10, ARENA_ROOT=Challenge_Dungeons}

### Heavenly Fragment (天堂碎片) 掉落与用途 [2026-09-05 | pv1659 | 数据表实测]

- **掉落方式** (ItemIndexData.Obtain 官方文案): 挑战图 (Double Dungeon/Throne Room) **每 10 波 BOSS 波, Wave 40 之后 (文案列举 50/60/70...) 每玩家独立 15% roll**; `GrantedOnDrop=true` 直接进包不落地面
- 物品属性 (QuestItemData): Rarity=**Celestial**, **MaxOwned=10** (持有上限恰好=任务需求), 图鉴 Tab=Quest
- **用途唯一**: `QuestRewardData.Quests.UnrestrictedInvertedSpear` — 找 **Unrestricted** NPC, 条件 PlayerLevel≥75 + Honored One 职业精通≥25 + 天堂碎片×10 + 金币≥50万; 消耗 10 碎片 + 50万金, 奖励 ClassItem **Inverted Spear** (转 Unrestricted 职业用, 姊妹条目: Black Heart→Shadow Monarch / Golden Katana→Master Ronin)
- 期望: 15%/波 → 平均 ~6.7 个 BOSS 波一颗; 10 颗满编 ≈ 从 wave 50 打到 ~700 区间的 BOSS 波 (长线毕业材料)
- SHOWCASE_REWARDS 无此条 (纯 BOSS 波掉落, 不在挑战图箱子/展示池); 挑战数据表 ChallengeData 无掉落键 — roll 逻辑在服务端, 客户端脚本源码 0 命中

### 倒置长矛 (Unrestricted) [2026-09-06 | pv1659 | 会话4 反编译+实测]

`Current_Class=Unrestricted` Celestial (Inverted Spear 转职产物), Lv98 GS 4841。双刀/矛**双形态近战**。数据源 `RS.Classes.Class_Data` + `Skills/*` 模块 (钾上 require+decompile 成功)。

**双形态机制** (全游戏首个 DualCooldown 职业):
- 形态开关 `SpecialMoveset` (0=剑 1=矛), 与锻造霸主同字段; 服务端权威, 无 Player 属性可读
- **形态识别 (客户端)**: `PlayerModels.<名>/HRP/Holder/Right_Arm` 下 `Sword`/`Spear` Model Transparency — 可见者=当前形态 (锻造霸主 Bow 同款模式)
- 1/2/3 每技能 **Sword/Spear 双套**: 独立动画 (Ability_N vs Special_Ability_N) + 独立伤害盒 + 独立 CD (`GetCooldown()` 按 SpecialMoveset 分流, `DualCooldown=true`)
- **4 = Tool Swap 换武器**: 切形态 + 1.5× 旋转突进 (盒 20,18,26 / Range 24 / Dash 60×0.18s) + 施放自带 0.4s 拼刀窗 (Character:SetAttribute("Parry",true)); **CD 5s 双形态共用**
- 无 SkillN_Charges/_OnCooldown 属性 → 服务端不发 CD 信号, 脚本本地计时

| 槽 | 剑形态 (Sword) | 矛形态 (Spear) |
|---|---|---|
| 1 杀戮节奏 | 5.0×单段斩 盒(20,18,28) 距26 CD7 | 0.9×7段连斩 盒(34,22,34) 周身+隔段小突进45 CD10 |
| 2 杀戮本能 | 0.25×0.1s 连打3s 站桩 距20 CD11 (全程拼刀) | 5.0×闪背单段 (Warp 60格绕后) 距26 CD7 |
| 3 领域破碎 | 0.6×0.1s 连打2.2s 距22 CD13 (tickMult 0.6) | 0.25×0.1s 连打3.6s 周身大范围 CD15 (全程拼刀) |
| 4 换武器 | CD 5 (共用): 1.5× 突进+切形态+0.4s 拼刀 | 同左 |

平A: Range=23, AtkSpd=1.1, DamageMult 1.15, Physical, Crit 5%×1.6, TurnCount=4。
Definition: ParryDuration=0.6 ParryCooldown=2 DodgeCD 1.8 (iFrame 0.7) NoKnockbackSkills {2,3} StationarySkills {2,3}=true。

**自动循环设计 (hub v1.14.0 DualForm)**: 当前形态 1/2/3 轮发 → 全进 CD → 发 4 切形态 (自带伤害不亏) → 另一形态 1/2/3 独立 CD 全好 → 理论 CD 零空窗。效率排序: 剑态 3>1>2 (1.02/0.71/0.68 mult/s), 矛态 2>1>3。CD 计时本地按 形态+槽位 分键 (1S/1P/...), `Cbt.dualCastKey()` 解析; 切换后 0.6s 强制重读形态 (模型 Transparency 晚一拍) + 切换后 1s 冷却期内不重复切。挂 Cbt 表不挂 local: fireQueuedSkill 词法作用域捕获不到后定义的 local (v1.14.0 教训, 静态门查不出运行时 nil)。

**[2026-09-06 | pv1659 | hub@v1.16.6 会话11 钾实测] 切换冷却/保护窗修正**:
- **勘误上文"服务端不发 CD 信号"**: 服务端实际下发 `SkillN_CooldownRemaining` (含 CDR buff + 当前形态; 塔内 Boss 战服务端繁忙时会冻结滞后, 实测同值 >4s 不递减); 缺失的只是 SkillN_Charges/_OnCooldown。
- **4 = Tool Swap 有服务端切换保护**: 一次切换处理期间再 fire4 被吞 — 手动 fire4 对照实测同样吞 (非脚本 bug), 保护窗 >1.8s; 被吞重试需 ≥2.8s 退避。
- **切换方向不对称**: 剑→矛 一次成功 (0.26~0.32s 翻转); 矛→剑 偶发连吞 2~3 次 (最坏 ~8.8s), 疑似矛3 (周身连打 3.6s 全程拼刀) 期间服务端锁 Tool Swap。
- **就绪判定分层**: 4 号槽必须严格信 Rem≤0 (本地档案 cd 与真实切换冷却不符, 兜底即误放风暴源); 1/2/3 可本地双口径兜底 (防 Rem 冻结憋手)。

### 倒置长矛 服务端 CD 属性行为 [2026-09-06 | pv1659 | hub@v1.17.0 会话13 钾实测] → hub@v1.20.0 已进代码

- 服务端**下发 `SkillN_CooldownRemaining`** (实测 s2=10.23 / s3=12.09 正常递减); 恒缺的只有 `SkillN_Charges` / `SkillN_OnCooldown`。→ 修正上文"服务端不发 CD 信号"表述: 不发的只是充能/布尔位, Rem 数值是有的。
- **Rem 同步滞后**: fire 后约 1s 内 Rem 仍读到 0, 之后才刷成真实 CD 值 → 任何"Rem≤0 即就绪"判据会在这 1s 窗口内反复重发同槽 (实测 s2 连发 5 次, 间隔 0.22s = busy 窗口), 每发掐 0.22s 平A。
- **4 号槽 (Tool Swap) 冷却好时 `Rem`/`OnCooldown` 均为 nil**, 只在冷却中才下发数值 (曾测到 rem4=4.4) → 就绪判据必须写成 "nil 或 ≤0"; 写成 `rem~=nil and rem<=0` 会让换武器永不就绪、形态永远切不了。 **hub v1.20.0 已改 `rem==nil or rem<=0`, 并: 同槽退避 / 打空对面有货就切 / 站桩后再 fire4。**
- **连打类技能 (剑2/剑3/矛3, `StationarySkills` 站桩) 在平A动画中发包常被服务端拒收**, 吞包后 Rem 不进 CD 恒为 0 → 同上, "见 0 就放"会退化成重试刷屏, 且角色反复进站桩技够不着怪 (平A侧表现为"无目标"静默)。

**[2026-09-06 | pv1766 | hub@v1.17.1]** 近战技能出手距离: 档案射程的一半 (不再 `skillRange+8`)。圈边索敌会空挥 — 双光环贴脸 + 寻路 fight 拉怪与出手门共用 `Cbt.engageRange`。远程职业仍满射程。

## [2026-09-06 | pv1766 | 会话16 钾] 地板爆炸预警 (红/黄圆)

不是直线斩击 Beam, 也不是 HUD 雷达。是落地 AoE 爆炸前的地面圆。

### 数据层 (会炸的那种)

`Boss_ActionData.Index.<Boss>.Abilities[]`:

| TelegraphType | 地面形状 | 范围字段 | 预警时长 |
|---|---|---|---|
| **AoE** | 圆 | `TelegraphRadius` (常见 20~30) | `TelegraphDuration` 0.7~1.2s |
| **BigAoE** | 更大的圆 | `TelegraphRadius` (常见 25~44) | 常 0.9~1.5s |
| Line | 长条 (不是爆炸圆) | `TelegraphRange` | — |

本图 Mage 例子: Cryomancer `Frozen_Sigils` BigAoE r=36 / `Glacier_Crash` BigAoE r=40; Demagios `Dread_Vortex` AoE r=30 / `Rose_Cataclysm` BigAoE r=35。技能模块命中盒另有 `HitboxSize` (冰法 Sigils 40³、Crash 40×50×40), 和 Radius 同量级。表里**没有** TelegraphColor 字段 — 红/黄不写在动作表。

小怪法师 (Mage Student 2 / Dark Acolyte / Goblin Shaman) `Spells={MeteorZones, WardBarrier, GroupHeal}`: MeteorZones **不挂 NPC Telegraph_Root**。客户端 `SpellBurst` `{EffectName=Grenade, SoundName=Earth_Hammer_2, Lifetime=3, Position}`。**hub v1.20.2** 按落点闪避。模板 `RS.Assets.Effects.Grenade`。

### 表现层

- 模板 `RS.Assets.Effects.Telegraph_Root` (透明 1³ Part)。子级 **`AoE_Telegraph`** = 爆炸预警圆; `End.Beam` / `Wide_Length_Telegraph` = 直线斩, 可忽略。
- 圆的可见部分是 AoE 上 ParticleEmitter: 颜色 **RGB(255, 51, 0) 红橙**, 粒子 Size 关键点约 15, 贴图圆。闲置 `Enabled=false`。
- 运行时克隆挂在 **NPC 模型里** (`Generated_*.NPCs.<名>.Telegraph_Root`), 不一定进 `workspace.SpellTelegraphs` (那个夹经常是空的)。
- **真正炸开**走 `PlacedEffect` 远程, 模板例如 `GroundEffect`(红冲击波) / `Light_Explosion`(金黄冲击, RGB 255,189,58) / `Fire_Pillar`(红火圈)。黄圈很多是**爆炸瞬间特效**, 不是更早的预警色。预警圈本身模板是红橙。

### 自动化含义

躲圈: ① NPC `AoE_Telegraph` 粒子 Enabled (Boss/精英); ② 小怪 MeteorZones = `SpellBurst` Grenade 落点。预警窗口 Grenade Lifetime=3s。**hub v1.18.1** 粒子 GetDescendants; **v1.20.2** 接 SpellBurst。

### 但丁 (Sinister Trigger) [2026-09-06 | 大厅 pv11476 | 会话26 钾反编译+属性]

用户中文名「但丁」。`Current_Class=Sinister Trigger` Exotic **远程双枪**, 无终极。大厅实测 Lv146 GS5481 Aspect=Sanguine。

平A: Range=**35** Hitbox(27,20,38) AttackSpeed=**1.05** DamageMult=1.5 DamageType=Ranged Crit 10%×1.9 TurnCount=5 ComboEndlag=0.12 ParryDuration=**0.25** (枪系短窗) ParryCD=2 DodgeCD 1.8 (iFrame 0.7)。`UseProjectile=false` (平A仍是前方盒, 不是弹道)。主属性 DEX20。

技能模块 `Classes.Sinister Trigger.Skills/*` 钾 require 崩 (SkillRuntime 在 ServerScriptService), 判定走 decompile。槽映射 1=Crossfire / 2=Showstopper / 3=Rainstorm / 4=Hysteria; 5=Deadeye (职业50被动, 非技能槽)。

| 槽 | 技能 | 距离 | CD | 要点 |
|---|---|---|---|---|
| 1 | Crossfire | 盒(20,12,27) 距**27**; 空中砸枪(22,50,30) 距30 | 6 ×3充能 | 四连射+方向冲刺45 +分身; 每次闪避窗1.1s; 10% 恶魔弹×1.3; Duration 1.6 |
| 2 | Showstopper | 点按周身盒(35,16,35) 距0; **长按**盒(24,26,28) 距**25** | 8 | 点按滑铲26速满拼刀 tick 0.35×0.09; 长按升空龙卷; 10% 刷新槽3; Stationary |
| 3 | Rainstorm | 周身盒(50,40,50) 距0 | 8 | 升空80×0.55s 倒悬弹雨 iFrame 2.6s tick 0.4×0.1; 15% 刷新槽2; Stationary |
| 4 | Hysteria | 盒(20,12,30) 距**28** | 10 | 七连射, 末段×2; Hit_Count≥500 改九连恶魔弹×1.45 Duration 4 |

实机 CD (Stat_CDR=4%): 1=6 / 2=7.68 / 3=7.68 / 4=9.6。Skill2_HasHold=true。hub 光环目前只发 tap (2 走滑铲不走龙卷)。

被动 Deadeye (Lv50): 平A与枪技命中 25% 在目标头上落幽灵弹, 短延迟后每发 190%。

hub 档案 Folder=`Sinister Trigger`, 中文「但丁」, `Ranged=true` (Range≥26 也会自动当远程风筝)。

## 待复核 (placeVersion 变更后移入)

## [2026-09-06 | pv1766 | 会话24] 倒置长矛实测数据修正 (全量反编译)

**来源**: `RS.Classes.Unrestricted` 模块 + `Skills/*` (Special_Ability_1/2/3, Ability_1/2/3, Tool_Swap) 全量反编译.

**重大修正** (旧档数据严重错配):

| 字段 | 旧档 (错误) | 实测 (正确) |
|---|---|---|
| 矛 1 Cd | 10 | **7** |
| 矛 1 Multiplier | 0.9×7段 (周身) | **1.55** (单段+dash突刺) |
| 矛 1 Range | 17 | **0** (SpearHitRange=0, Dash 45速×0.12s) |
| 矛 2 Cd | 7 | **11** |
| 矛 2 Multiplier | 5.0× (闪背) | **11** (闪背单段) |
| 矛 2 Range | 26 (WarpSearchRange=60) | 26 不变 |
| 矛 3 Range | 20 | **0** (SpearHitRange=0, dash 周身) |
| 剑 1 Cd | 7 | 7 不变 |
| 剑 1 Multiplier | 5.0× | 11.0 不变 |
| 剑 2 Cd | 11 | 11 不变 |
| 剑 2 Multiplier | 0.25×30tick | 0.55×30tick |
| 剑 3 Cd | 13 | 13 不变 |
| 剑 3 Multiplier | 0.6× | 1.2×22tick (26.4x总) |
| 矛 3 Multiplier | 0.25× | 0.5×36tick (18x总) |
| 4 HitMultiplier | 1.5× | **3**× |
| 4 Range | 24 | 24 不变 |

**服务端 CD 属性** (钾实测 pv1766 Mage/Hard):
- `SkillN_CooldownDuration` **不持续广播** — 只在进入冷却时下发一帧, 归零后清空. 要实时 CD 只能 `base × (1 - CDR/100)`.
- `M1Mode` (Char属性): 服务器权威形态指示, 切换瞬间立即更新无抖动. 优先级 > 武器 Transparency.
- CDR 多源: `Stat_CooldownReduction` + `RunBuff_/AchBoost_/Perk_/Passive_CooldownReduction`.
- 切换瞬间 Rem 全重置: 矛→剑切瞬间矛 Rem 按剑套刷新 (矛3 Rem=13.87→剑3 Rem=0).

**技能距离实测** (6技能+4切换):

| 槽 | 剑距 | 矛距 | 说明 |
|---|---|---|---|
| 1 | 26 | **0** (dash) | 矛1 SpearHitRange=0, 服务端按方向生成hitbox |
| 2 | 20 | 26 (Warp 60) | 剑2站桩多段, 矛2瞬移闪背 |
| 3 | 22 | **0** (dash) | 矛3 SpearHitRange=0, dash周身 |
| 4 | 24 | 24 | 突进+切形态, 无距离门, 服务端按方向生成 |

**形态偏好结论**:
- 剑形态 2/3 = 站桩 AoE 多段 (剑2 16.5x/3s, 剑3 26.4x/2.2s) → 群怪 (≥2) 留剑
- 矛形态 2 = 单段 11x 闪背 (60格内瞬移) → 单体/Boss 切矛追猎
- 剑 1(7s) + 矛 2(7s) 是低 Cd 技能, 组成快速循环; 剑 1(11x) + 矛 2(11x) 是爆发王组合

**踩坑记录**:
- [ SpearsHitRange=0 误判为无范围 → 技能打不出去 → 实为 dash 型, 贴脸放即可, fallback 18 兜底]
- [ `CooldownDuration` 不持续广播 → 动态 CD 用 Stat_CooldownReduction 算, 而非读服务端字段]
- [ 旧档矛 1/2 Cd 互换 → 矛1 Cd=7, 矛2 Cd=11, 调换]

- [pv1659→1766] 旧 6 图房间现场解剖 (Bandits~Demon) 生成算法可能改 OpenWorld
- [pv1659→1766] PlaceConfig.IsDungeonPlace 在地牢图上现为 false — 凡信该布尔的代码/结论改信 InDungeon + Generated_*
- [pv1659→1766] 钥匙库存: 现有 KeyService.GetAllKeys, 旧「只能扫 ItemGrid UI」可能过时
- [pv1659→1766] CS.Enemy 空场=0, 局内 tag 是否仍打需进房再确认 (协议层未改, 大概率仍在)
- [pv1659] 爬塔 BossHealthUpdate 参数序仍未实测

## 已证伪

- [早期 Shinobi Kurogiri SmokeBurst=3] 钾 2026-09-04 再 require 模块无此字段, 以 hub@0.10.1 表为准
