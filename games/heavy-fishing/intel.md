---
genre: fishing
game: "重型钓鱼"
placeId: 98502499119821
universeId: 8342498724
placeVersion: 2929
created: 2026-08-25
updated: 2026-09-03
script: "games/heavy-fishing/hub.luau"
status: active
---

# 游戏情报档案 — 重型钓鱼 ([☯UPD] 重型钓鱼)

> **AI 铁律**:
> 1. 会话开始必须先读本文件 + `recall-game-memory`, 禁止对已有结论重新逆向。
> 2. 开发中新发现: 当场 `remember-game` (运行时召回), 收工前回写本文件 (持久归档)。
> 3. 每条结论必须带条目头: `[日期 | pv<placeVersion> | 来源脚本@版本]`。
> 4. 游戏更新 (placeVersion 变更) 时: 把受影响条目剪切到「待复核」区并标注新 pv, **不删除**。
> 5. 结论被证伪时: 移到「已证伪」区保留原文 + 写明证伪原因, 不静默删除。

---

## 协议与通信

## [2026-08-25 | pv2913 | hub@0.1.0]
- 全部走 `ReplicatedStorage.Events` 下的具名 RemoteEvent, 无 ByteNet/打包协议, 参数全是明文基础类型。

### 钓鱼完整链路
1. **抛竿**: `Events.Fishing:FireServer(HRP.CFrame)`
   - 客户端前置: `Character:GetAttribute("Type") == "Fishing Rod"` 且 `GetAttribute("Fishing") ~= true` 且背包未满
   - 服务端受理后置 `Fishing=true`, 咬钩时给 LocalPlayer 发 `FishID` attribute (= workspace.Fishes 子对象名)
2. **咬钩**: 服务器经 `Events.FishingMinigame` 发开始包 `(fishTable, powerTable, token)`:
   - fishTable = `{FishName=string, Boss=bool, Power=num, Time=num, ...}`
   - powerTable = `{Power=num}`; token = uuid 字符串 (会话标识)
   - 客户端收到后有本地 3 秒倒计时 ("The minigame will start in 3..LOCK IN!") 才真正开打
3. **打鱼伤害** (核心机制):
   - UI: `MainGui.Fishing.BarFrame.Bar` 的 X.Scale 从 0.5 起持续 Tween 到 -0.1 (全程时长 u387 = f(双方力量比), 0.01~1.5s), 玩家点击 MouseButton1 使 Bar +0.1 (0.05s tween)
   - **判定区 ≈ X.Scale ∈ [0.40, 0.62], 中心 0.5** (实测 bar 在此区间时鱼进度稳定 +1/tick)
   - Bar 在区内时, 游戏自身协程每 **0.1s** 发一次 `Events.UpdateFishProgression:FireServer()` (**无参数**) — 这是唯一的伤害上报通道, 服务器据此给鱼扣血
   - `workspace.Fishes[FishID].Value` = 已造成伤害进度; `.MaxHealth` attribute = 总血量
   - Bar 出界 → 客户端上报失败 `Events.FishingMinigame:FireServer(false, token, "Out of bar")`
   - **客户端位置权威**: 服务器不验证点击, 只认 UpdateFishProgression 上报频率 → 条停在区内即满速打鱼; 钉死 Scale 一眼脚本, 真人是点按让条在绿区回弹
4. **会话结束**: 服务器发 `FishingMinigame` 入站包 `("SessionEnd", bool, token)` — 主 handler 的 `type(p1)=="table"` 检查故意丢弃它 (防重复清理的迟到包设计)
5. **技能**: `Events.UseSkill:FireServer("Z"|"X"|"C"|"V")` (Z=Rage C=Slam X=Stun V=Weaken); 冷却存 `Character.Skills` NumberValue

### Slam 小游戏 (C 技能触发)
- 服务器经 `Events.Slam` 发 `(callbackRemote)`; 客户端建 PerfectButton, Line 从 0 tween 到 Scale=1 用时 2s
- 点击时机判定: `Line.Size.X.Scale < 1.15` → "Perfect"; `>= 1.25` → "Bad"; 中间 "Good"
- **因 tween 上限 Scale=1 < 1.15, 2.1 秒内任何时刻点击都是 Perfect**; 超 2.1s 未点自动上报 "Bad"
- 上报: `callbackRemote:FireServer("Perfect"|"Good"|"Bad")`

### Charge 小游戏 (抛竿蓄力)
- 服务器经 `Events.Charge` 发 `(callbackRemote)`; 点按钮 → `callbackRemote:FireServer()` 即成, 无超时惩罚逻辑

### Boss 战特有
- Boss 会话有 `Ready` Value 等待流程、Phase2/FinalPhase/PreFinalPhase attributes、Rhythm 节奏小游戏 (ASD 键道)、BossFightBar
- FinalPhase 期间普通 Bar 协程停摆 (走 Rhythm), 普通锁条法失效 (未逆向 Rhythm 判定)

## Remote 清单

| Remote | 方向 | 参数 | 说明 |
|---|---|---|---|
| Events.Fishing | C→S | (HRP.CFrame) | 抛竿 |
| Events.FishingMinigame | 双向 | S→C: 开始包 / ("SessionEnd",bool,token); C→S: (result,token,reason) | 小游戏会话 |
| Events.UpdateFishProgression | C→S | () 无参 | 打鱼伤害上报 (10Hz, 区内才发) |
| Events.UseSkill | C→S | ("Z"/"X"/"C"/"V") | 鱼竿技能 |
| Events.Slam | S→C→S | (cbRemote) → cb:("Perfect"/...) | Slam 小游戏 |
| Events.Charge | S→C→S | (cbRemote) → cb:() | 蓄力确认 |
| Events.AutoFishing | C→S | () | 官方自动钓鱼开关 (Level≥100) |
| **Events.SellFish** | C→S | ("One"/"All") | **卖鱼; "All"=全卖; 实测无位置限制即时到账 [pv2913 实测]** |
| Events.RedeemCode | C→S | 未逆向 | 兑换码 (Menu.Code UI) |
| Events.Market / ShopHandle | - | 未逆向 | 市场/商店 (调用处不在客户端可见流) |
| Events.Catch / ReplicateFishCaught | S→C | (玩家, 鱼模型名, 位置) | 捕获广播/展示 |
| Events.BuyFishingRod / UpdateFishingRodShop / AwakeRod / SecretRod | - | 未逆向 | 鱼竿商店/觉醒 |
| Events.MoveItems / FavoriteItem / ToggleHotbar(RF) | - | 未逆向 | 背包管理 |
| Events.PlaceStructure / RemoveStructure / ClaimPlot / UpgradePlot(RF) / BuyStructure(RF) / BuyInteractItem(RF) | - | 未逆向 | 家园建造系统 |
| Events.AddFishToFishTank / RemoveFishFromFishTank | - | 未逆向 | 鱼缸 |
| Events.AFK | C→S | 未逆向 | AFK 状态 (Data.AutoFishing BoolValue 同源?) |
| Events.Setting | - | 未逆向 | 设置同步 |
| Events.Trigger / TriggerMinigameSkill / ProximityPromptToClient / NotifyFish / MasteryNotification / CurrencyNotify / Notification / PowerWarning | - | 未逆向 | 杂项通知/交互 |

## 世界与地点

- [2026-08-25 | pv2913 | workspace.Spawnpoint] **10 个岛屿传送锚点** (Part, 直接读 Position):
  Beginning Isle (-200,11,36) / Amber Isle (1259,9,1401) / Sovereign Isle (-1276,9,1240) / Bamboo Isle (-1223,7,-24) / Fallout Isle (66,9,1181) / Perch Isle (-62,12,-1321) / Coconut Isle (1494,9,-1431) / Battlefield Isle (1393,11,170) / Mistpeak Isle (2660,8,-87) / Frost Isle (-1366,12,-1495)
- [2026-08-25 | pv2913 | ClientModule.Setting@462] **传送 = 纯客户端 CFrame**: 游戏"回到出生点"按钮就是 `HRP.CFrame = Spawnpoint[Data.Spawnpoint.Value].CFrame`, 无 remote 无校验 → 客户端任意岛瞬移可行 (官方同款路径)。
- [2026-08-25 | pv2913 | Menu.Compass.AreaList] 罗盘面板列出全部区域, Compass 模块只是指向当前区域的指针 UI。

## 数据结构 (Data[UserId])

| 对象 | 类型 | 含义 |
|---|---|---|
| Inventory (Folder) | 子项 NumberValue | 鱼; Name="鱼名 \| 价格", Value=数量(恒1) |
| Hotbar (Folder) | 子项含 Quantity | 快捷栏物品 |
| InventoryLimit | NumberValue | 背包上限 |
| Cash / Crystal / Ticket / EssenceOrb / BossCrystalCount / BossTicketCount | NumberValue | 各货币 |
| Level.Level | NumberValue | 等级 (BaseHP 也在此 folder) |
| AutoFishing | BoolValue | 官方自动钓鱼开关 |
| FishingRod / FishingRodInventory | String/Folder | 当前竿/竿库存 (Skill 子项决定小游戏技能键) |
| EquippedBait / Bait (Folder) | - | 鱼饵系统 |
| Spawnpoint | StringValue | 上次所在区域名 |
| FishCaught / HeaviestWeight | NumberValue | 统计 |

## 技能系统

- [2026-08-25 | pv2913 | Info.Skill 全量] **84 个技能**, 定义结构 (ModuleScript require):
  ```luau
  { Image, Description, Price, Type="Cloud",
    Stats = { Cooldown=秒, Damage, Duration, FirstTime, SecondDamage, SecondTime, Iframe },
    Function = require(ClientModule.Skill.<实现模块>) }
  ```
- [2026-08-25 | pv2913 | 实测] **四键槽制**: Z/X/C/V 固定映射类别 Z=Rage, X=Stun, C=Slam, V=Weaken (Character.Skills 子对象即冷却槽); 鱼竿决定装什么 — `Data[UserId].FishingRodInventory[FishingRod.Value].Skill["Z"/"X"/"C"/"V"].Value` = 技能名 (空串=未装)。同一键位可装任意技能, 类别名只是历史命名 (如 Z 槽装 Skyfall Stomp 定身技)。
- [2026-08-25 | pv2913 | Fishing@逆向] 施放 = `Events.UseSkill:FireServer("Z"/"X"/"C"/"V")`; 客户端前置: `Character:GetAttribute("SkillLocked") ~= true`, `Skills[槽].UsingSkill attribute <= 0`。
- [2026-08-25 | pv2913 | BindSkillCDUI] **冷却服务器权威**: `Character.Skills[Rage/Stun/Slam/Weaken].Value` = 剩余秒数, 由服务器递减回写; 客户端 `Value <= 0` 即可再放。
- [2026-08-25 | pv2913 | 技能效果分类] 定身类 (Skyfall Stomp/Dragon Strike/Iron Grip Art…): Stun 期间 Bar 移动协程停摆 (会话1逆向), 锁条脚本无冲突; 持续伤害类 (Swift Reel/Reel Sprint): 每 0.5s 跳伤无需操作; Slam 类: 触发 PerfectButton 小游戏需点击上报 (hub 的自动 Perfect 已覆盖)。
- [2026-08-25 | pv2913] `Events.TriggerMinigameSkill` 无客户端调用处 (服务端专用/废弃), 忽略。
- [2026-08-25 | pv2913] 技能 UI: MainGui.Fishing.SkillButton.Frame 下 TextButton 名=键位, CD 子标签显示剩余; 技能详情 require(Info.Skill[名]) 取 Description/Image。

## 开始包实测全字段 (FishingMinigame OnClientEvent)

- [2026-08-25 | pv2913 | 实测 dump] p1 fishTable = `{FishName, Power=鱼力量, Time, Weight=鱼重(随机于 MinKg~MaxKg)}`; p2 powerTable = **玩家当前竿完整配置表** ({Model, Power, Luck, Cash, Color…}, 即 require(Info.Inventory[竿名]) 原样)。
- [2026-08-25 | pv2913] **Weight 字段价值**: 开战瞬间即知鱼重 → 卖价与重量正相关 → 可实现"按预期价值决策"(低值鱼速刷/高值鱼全力) 与放弃机制升级。
- [2026-08-25 | pv2913] Boss 鱼 Info 配置含 Skill 表 (Boss 战中鱼会放技能); Azure Carp 带 SpecialBoss 标记。

## 经济与数值体系

- [2026-08-25 | pv2913 | Info.Inventory require] **物品配置三分类**: Fish ×109 / Fishing Rod ×39 / Tool ×1。鱼配置:
  ```luau
  { FishName, Type="Fish", Cash=卖价, Exp, Chance, Power=战斗力量, Time=咬钩等待秒,
    MinKg/MaxKg, Model(ReplicatedStorage.Model 下), Animation="Light",
    Boss=bool?, SpecialBoss=?, Rate=?, Skill=? }
  ```
  例: Trout(Cash20/Power1/Time5s) ~ Azure Carp(Boss/SpecialBoss/Power13/Time30s)。
- [2026-08-25 | pv2913 | 实测推论] **咬钩等待时长由抽到的鱼的 Time 字段决定** (5~30s+), 不是全局随机 — 等得久=抽中大鱼。
- [2026-08-25 | pv2913] **鱼竿属性**: {Power=打鱼力量, Luck=稀有度加成, Damage=技能伤害%, Cash/Crystal=售价}。梯度: Wooden(P8/L1) → Steel(P17/L11/¥1000) → Kraken(P90/L36/500Crystal) → Heavenpiercer(P100/L36/D100%/50Crystal)。
- [2026-08-25 | pv2913] **Luck 数值联动**: 咬钩抽鱼时 Luck 加成 Chance 权重 → 高 Luck 竿/饵 = 更多稀有条目被抽中。
- [2026-08-25 | pv2913] **鱼饵** (Info.Bait ×8): {Luck, Price, Type="Normal"/"Mythical", Boss?=召唤指定Boss}。Basic(L3/¥100) → Ancestral(L50/¥10万); Rainbow Bait(Luck0)=召唤 Rainbow Dragonfish Boss 的钥匙。
- [2026-08-25 | pv2913] **天赋** (Info.Trait ×13): {Damage%, Cooldown%, CritChance, CritDamage, Rarity=抽取权重, Type=Rarity 档位}。Berserk(+15%伤/Epic)、Swift(-4%CD/Rare) 等; 重roll 货币 = Trait Reroll / TraitMythicalPity。
- [2026-08-25 | pv2913] **宝珠** (Info.Orb ×9): Bac Minh/Taoist/Taiji 等 — God Spirit 系统材料。

## 岛屿渔获分布 (FishingAreaRarity, 键=权重)

- [2026-08-25 | pv2913 | Info.FishingAreaRarity] 12 个区域键: 10 岛屿 + Exclusive(活动鱼) + Secret Boss(19 种 Boss 鱼, 权重全 1000)。
- Beginning Isle(新手): Trout 100/Catfish 90/Crimson Carp 50…Royal Carp 仅 2。
- Battlefield Isle(高级): Silver Bream Sovereign 权重仅 5, Colossal Tigerfish/Golden Guardian Fish 10。
- Perch Isle: Elder Perch I~VIII 进阶序列; Frost Isle: Kunfish 序列 + Primordial Overlord。
- 完整权重表运行时 `require(game.ReplicatedStorage.Info.FishingAreaRarity)` 即取, 不在档案里硬抄 (游戏更新自动跟随)。

## 技能真实伤害模型 (15 实现模板全逆向)

- [2026-08-25 | pv2913 | 实现模板源码] **伤害公式** (客户端直改鱼 Value, 无 RodPower 缩放):
  ```
  单跳伤害 = Stats.Damage × 暴击(默认5%概率→×1.5; CritChance/CritDamage 字段可覆盖)
  跳间隔 = SlamTime(有则用) 否则 0.5s (DStun/DStunHealGod/Barrage/DOTGodBoost 均实测 0.5s)
  总跳数 ≈ Duration ÷ 跳间隔
  总伤 = 单跳 × 跳数
  ```
- [2026-08-25 | pv2913] **模板语义表**:
  | 模板 | 效果 |
  |---|---|
  | DStun / DStunGod / DStunHealGod | 定身(Duration) + 每0.5s直伤; God 变体附加免Boss技/回血/破无敌; 结束前3.5s 全技能CD+5 惩罚 |
  | Barrage | TrueDMG 才跳伤 + ApplyStun; Phoenix Strike 系 |
  | Stun | 纯定身无直伤, 结束前3s提醒 |
  | Slam / UltimateSlam | 触发 PerfectButton 小游戏 (`Events.Slam:FireClient`); Ultimate 多阶段 DeferEnd |
  | Rage | RodPower buff + 自损 Bleed |
  | EnhancePower | RodPower buff 无副作用 |
  | DOTGodBoost | DamageBoost 属性buff + WaitTime 延迟跳伤 |
  | HealOvertime / HealingGod / HealingSlam | 回血系 (Poisoned 时无效); HealingSlam 带 PerfectButton |
  | Charge / Stagger | 待细读 (低优先级) |
- [2026-08-25 | pv2913] **技能价值判断**: Damage 是字面基数直接加到鱼 Value — 对普通鱼 (血量几十~几百) 是主力输出, 对 Boss (血量万级) 是零头; Boss 战主要靠打鱼上报。
- [2026-08-25 | pv2913] **修正**: `Stats.Time` = **战斗时限**(超时失败), 不是咬钩等待! Power 谱系: 普通鱼 P1~P74, Boss 鱼 P13~P100; 战斗时限 5s(Trout) ~ 15000s(Heavenpiercer Turtle)。咬钩等待为独立随机。

## 鱼饵系统

- [2026-08-25 | pv2913 | 实测] **购买**: `Events.BuyBait:FireServer(饵名, 数量)` — 扣款精确 (5×Crude Mash ¥10000 = ¥50000), 现金不足服务器静默拒绝。
- [2026-08-25 | pv2913 | Fisher_Inventory@724] **装备**: `local ok = Events.EquipBait:InvokeServer(饵名)` (RemoteFunction, true=成功), EquippedBait StringValue 同步更新。
- [2026-08-25 | pv2913] **背包结构**: `Data[UserId].Bait[饵名].Value` = 数量槽 ×8 (每种一个 NumberValue, 含 0)。
- [2026-08-25 | pv2913] 可购 Normal 饵 5 种: Basic ¥100/L3 · Crude Mash ¥1万/L8 · Corrupted Essence ¥1.5万/L18 · Elite ¥5万/L30 · Ancestral ¥10万/L50; Mythical 3 种 (Frost/Nameless/Rainbow) 价格 0 不可购。

## NPC 与功能入口

- [2026-08-25 | pv2913 | workspace.NPC] 9 大功能 NPC: SetSpawn(设出生点) / SpawnBoat(开船) / BuyFishingRod(竿店) / **LearnSkill(学技能)** / BuyBait(饵店) / SellFish(卖鱼) / Boss(Boss 入口) / Spirit / God。
- [2026-08-25 | pv2913] 对应 remote: BuyFishingRod/BuyInteractItem(RF)/ShopHandle/Market 等 (参数待逆向)。
- [2026-08-26 | pv2918 | 用户从其他玩家确认] 事件 NPC "灵魂"(玩家俗称鬼魂, 头顶名 "9178") 与常驻 workspace.NPC.Spirit 是**两个不同实体**: 灵魂随机刷新于三岛之一 — 竹林岛(Bamboo Isle)/琥珀岛(Amber Isle)/霜冻岛(Frost Isle), 出现提示 "Something has appeared in the world..."。客户端按头顶文本 "9178" 定位(findGhostModel); 三岛具体坐标未逆向, 传送靠定位在场实例。

## 角色操作系统 (全逆向)

- [2026-08-25 | pv2913 | 实测+源码] **Rig**: R6 (Torso/四肢部件) + `Animate` LocalScript; 角色 子对象: Stats/Skills 文件夹、Tool(竿模型)、Buoy(浮标)、__CharacterMorph。
- [2026-08-25 | pv2913] **移动**: 标准 PlayerModule.ControlModule (Keyboard/TouchThumbstick/Gamepad 等子控制器), **游戏零自定义覆盖**; Humanoid 属性: WalkSpeed 动态 / JumpHeight 7.2 (UseJumpPower=false) / AutoRotate=true。
- [2026-08-25 | pv2913 | 实测] **WalkSpeed 管理机制**: 游戏仅在**状态切换时写入** — 16=可移动, 0=战斗锁(防走位); 非每帧覆盖 → 移动加速的 Heartbeat 每帧写入完全压制 ✓。变化实测: 600.9s→16, 602.0s→0。
- [2026-08-25 | pv2913] **Stats 文件夹** (Character.Stats) = 技能系统运行时状态: `RodPower`(增益力) / `FishPower` / `Stun`(定身中) / `Iframe`(无敌秒) / `DamageBoost`; 由技能实现模板客户端直写。
- [2026-08-25 | pv2913] **Stun 残留竞态实证**: 等咬钩态观测到 Stun=true (定身技协程延迟清理); 无害 — 新战斗 autoSkillTick 自治重置会强制清零。
- [2026-08-25 | pv2913] 其他: 死亡 = Events.Death + Health script (挂机不涉及); 游泳 = Water LocalScript + Swimming attribute; 交互 = 标准 ProximityPromptService (无自定义协议); StopMovement remote 全库零引用(废弃)。
- [2026-08-25 | pv2913] **对自动钓鱼的影响评估**: 锁条为纯 GUI 操作不受移动系统影响; ws=0 锁定不影响抛竿包; 移动加速与游戏偶发写入共存 (每帧写压制)。

## Boss 系统

- [2026-08-25 | pv2913] Boss NPC = workspace.NPC.Boss (Enzo 模型, ProximityPrompt "Talk"); BossSetUp.Enzo = {LocationBuoy, LocationPlayer} 入场锚点。
- [2026-08-25 | pv2913] **Boss 鱼 46 条** (Info.Inventory cfg.Boss=true): Power P13~P100, 战斗时限 30s ~ 15000s (Heavenpiercer Turtle 最长)。SecretBoss 区 19 种 (FishingAreaRarity 权重全 1000); Mythical 鱼饵可召唤指定 Boss (Rainbow Bait→Rainbow Dragonfish)。
- [2026-08-25 | pv2913] Boss 战特有: Phase2/FinalPhase attributes、Rhythm 节奏小游戏 (ASD 键道, 未逆向)、BossFightBar、鱼会放技能 (Boss 鱼 Info 含 Skill 表)、Iframe 无敌阶段 ("PhaseInvincible")。
- [2026-08-28 | pv2922 | 实机 job enzo-infight-spy] **恩佐开战权威检测信号 = `workspace.NPC.Enzo.InFight`** (NPC 模型镜像属性, 开战时服务器置 true; BossUI refresh() 据此禁用 Fight 按钮)。`BossSetUp.Enzo.InFight` 实测恒 nil (配置表无此属性, 不可用)。`LocalPlayer.FishID` 战斗时不指向 workspace.Fishes 内实体 → 原 isBossFish 检测永 nil。hub v0.24.2 改用 NPC.Enzo.InFight 作检测信号 (零 hook, 纯属性轮询 0.4s)。注意: 恩佐 Phase1 为纯技能 DPS (无血条无 GUI), 自动战斗接管后仍需开「智能释放技能」(bossSkillOn) 才掉血。
- [2026-08-28 | pv2922 | hub v0.24.3 架构] **恩佐BOSS已并入自动钓鱼**: bossModeOn 改为纯镜像 autoFishOn (setAutoFish 同步置真并启停 bossDetect/bossPhase2 循环), 移除独立「自动战斗」开关与 setBossMode。用户工作流: 手动点NPC/传送开恩佐挑战 → 开自动钓鱼即自动识别接管; 技能释放仍由 bossSkillOn 独立控制 (关则仅技能不自动, 其余控条/Phase2/节奏全自动)。
- [2026-08-25 | pv2913] 货币联动: Ticket/BossTicket/BossCrystal — 推测为 Boss 战门票/奖励 (入口协议未逆向)。

## Rhythm 节奏小游戏协议 (Boss Final Phase) — 全破解

- [2026-08-25 | pv2913 | Fishing@1466-1660] 触发 = `Events.RhythmStart:FireClient(player, {MiniGameTime=120})`; 结束 = `RhythmStop` 或时限到。
- [2026-08-25 | pv2913] **机制**: 3 条轨道 (ProgressionA/S/D), 音符从 Y=-0.05 落向判定线 (~0.85), 下落 t += dt/1.4 (约 1.4s 全程); **判定窗口 |noteY - 判定线| ≤ 0.22 (极宽松)**; 命中→`RhythmHit:FireServer("hit")`, 漏过/空按→`("miss")`; 音符间隔 0.5s 渐加速至 0.3s; 期间 SetFishingSkillLock(true)。
- [2026-08-25 | pv2913] **自动化可行性高**: 服务器只认 "hit"/"miss" 字符串; 可 Heartbeat 扫描 ProgressionX.NoteFrame 下 Note_FX 子对象 Y.Scale, 接近判定线即 FireServer("hit") + 销毁 note — 无需模拟键盘。
- [2026-08-28 | pv2918 | 实机] **Rhythm 容器普通钓鱼共用**: 容器路径 = `MainGui.Fishing.Rhythm` (非恩佐专属), 内含 ProgressionA/S/D 三 Frame, 各带 NoteFrame; 恩佐 FinalPhase 与普通钓鱼 Boss 鱼二段 (无名章寄 Nameless Octoparasite 等, 多命阶段触发) 走同一套 GUI 与 RhythmStart/RhythmHit/RhythmStop 事件 — hub v0.21.0 已泛化自动打击。
- [2026-08-28 | pv2922 | 实机逆向] **音符容器修正**: pv2922 实测音符(Note_FX)直接挂在轨道(ProgressionX)下, 不在 NoteFrame 容器内 (NoteFrame 仅作空容器/参照); 原 "扫 NoteFrame 下 Note_FX" 假设错误 → 自动打击漏掉后面阶段音符。正确做法: 扫轨道 `:GetChildren()` 中所有 `Note` 名对象(排除 `NoteFrame` 本身)。判定线 = 轨道内 `BarFrame.Position.Y.Scale` (默认 0.85, 需动态读取非死值)。命中窗 `|noteY - lineY| ≤ 0.22`。hub v0.24.4 bossRhythmTick 已修正。
- [2026-08-28 | pv2922 | 实机逆向] **RhythmStart 接管门控移除**: 原 hub 仅在 `fsmState=="战斗中"` 时接管节奏小游戏, 但章鱼等多命鱼二段触发 RhythmStart 时 fsmState 非战斗中(可能仍在钓鱼态/切换态) → 接管不触发, 后面阶段小游戏完全失效。修正: RhythmStart 触发即无条件接管(置 rhythmActive=true + 启 bossRhythm 循环 0.05s), 与 fsmState 解耦。hub v0.24.4。
- [2026-09-03 | pv2929 | hub@1.2.1] **章鱼二阶段 = 同一套 Rhythm**, 不是恩佐那种点击条。Heartbeat 过线打击。~~不模拟 ASD、直接 RhythmHit~~ — **已被 1.2.2 证伪, 见下条**。
- [2026-09-03 | pv2929 | Potassium decompile ClientModule.Fishing@TryHit] **必须按 ASD 走 TryHit**: 窗 `|gui.Position.Y.Scale - BarFrame.Y| ≤ 0.22`(原始 Scale, 不用锚点中心); 命中则 Destroy 音符 + 从内部表 `u144` 移除 + `RhythmHit("hit")` + `TweenExpEffect`(EXP 闪光); **空按或过线+0.22 未点 → `RhythmHit("miss")` 扣血**。只发包不删表 = 游戏 Heartbeat 稍后补 miss。hub@1.2.2 改为过线后按对应键, 不再 FireServer。
- [2026-08-25 | pv2913] miss 后果在服务器侧 (推测扣血/失败), 需 Boss 战实测。

## 技能成长系统 (EXP)

- [2026-08-25 | pv2913 | Data.Skill 实测] 玩家技能数据 = `Data[UserId].Skill[技能名]` = `{Owned=bool, EXP=number, Favorite=bool, Boost=number}`; **EXP 为技能成长值** (使用积累), 影响实际伤害 — 解释面板 Damage 基数与实战伤害的差异。UpgradeSkill(RF)/BuySkill/SkillSlot×4 配套系统。
- [2026-08-28 | pv2918 | 实机] **技能自动决策数据源** (hub v0.22.0 四层决策引擎): 竿元素 = `Info.Inventory[竿].Description` 句式 "Increases X% damage for <Element> skills" 提取, `cfg.Damage`=加成% (茅山竿 D100=×2.00); 技能元素 = `Info.Skill[名].Type` 字段; 回血技 = `Stats.Heal`(数值) 或 `Stats.GodHeal`(最大生命%: 炽焰金刚 50); 增益技 = `Stats.Power`(RodPower buff) 或 `Stats.Boost`(下个技能增伤); 自损 = `Stats.Bleed`(枭鹰/毁灭牺牲/天宗极艺自扣血, 血低禁用); 自身血量 = `Humanoid.Health/MaxHealth`; 增益状态 = `Character.Stats.RodPower.Value`; 鱼血量 = `workspace.Fishes[FishID].Value`(已扣伤) / `MaxHealth` attribute (剩余 = 1 - Value/MaxHealth)。
- [2026-08-28 | pv2918 | 实机] **多命鱼假血机制** (hub v0.23.0): 鱼配置 `Info.Inventory[鱼名].Phase` = 总命数 — 虎沼鱼 Tiger Mirefish=3 / 幻影灯笼鱼 Mirage Lanternfish=2 / 章寄鱼 Octoparasitic Fish=2 / **无名章寄 Nameless Octoparasite=8** / 普通鱼=1(无 Phase 字段)。前 N-1 条命是假血 (显示 MaxHealth=cfg.Time, 打到边界即回满切下一条命, 如虎沼鱼 10000 血剩 2000 回满), 只有最后一条命完整。客户端阶段切换信号: fish.Value 大幅回跳 (>400) 或 MaxHealth attribute 变化; 服务器显式 `FinalPhase` attribute 标记最后一条命。一次性大招 (CD≥120s) 只在真血命且血量≥30% 放。
- [2026-08-28 | pv2918 | 实机] **一次性大招全集** (CD≥120s, 共 7 个): Sever the Gate 系×3 (CD=9900000, 蜀道山, 蓄力型) / Ruinous Sacrifice 毁灭牺牲 (999) / One Hook Dominance 一钩定乾坤 (999, 神云) / Egoless Technique 无我·天宗极艺 (999, 血) / Pure Yang Wuji 纯阳无极 (999, 纯阳)。普通技能 CD 全 ≤60s。
- [2026-08-28 | pv2918 | 实机] **无名章寄 FinalPhase 配置**: HPFinalPhase=20000 / MiniGameTime=120 / HealHP=50 / LoseHP=200 — 8 命打完进 FinalPhase 音游 (最后一命 20000 血), 与 Enzo 同套 Rhythm 协议。
- [2026-08-25 | pv2913] 天赋重roll资源: Trait Reroll=101 张 + TraitMythicalPity=9/10 保底 + TraitRerollOneTime 券×4 + LockTrait 锁定×7 — 重roll协议 RerollTrait(RF) 未实测。
- [2026-08-25 | pv2913] 昼夜循环: DayCycle = unix 时间戳; GodSpirit = Yellow/Blue/Green 三 BoolValue (修仙线未解锁)。

## 角色收集系统 (PlayerCharacter ×12)

- [2026-08-25 | pv2913 | Info.Character + Data.PlayerCharacter] **角色 = 元素加成卡, 非 NPC**: 12 个全收集 (Data.PlayerCharacter), `Events.EquipCharacter` 装备生效。
  - 江老 Taiji/Normal +50%(BaseBoost 最高) · 大师兄 Sanqing/Buddha/Maoshan +20% · 北冥/白民/南江/恩佐/郁建愁 +20%
  - 小道士 Xiao Daoshi = Sanqing/Pure Yang +15% (**不是卖竿 NPC**, 是收集卡)
  - 表哥 Cloud/Taiji · 表弟 Cloud/Claw · 楚欣 Cloud/Divine Cloud · 一九大师 Cloud/Sovereign Cloud +15%
- [2026-08-25 | pv2913] 配装联动: 角色 + 竿元素加成 + 功法 Type 三层叠加才是最终元素伤害倍率。
- [2026-08-25 | pv2913] **Taoist Rod 非卖品确认**: Info.Inventory 无 Cash/Crystal 字段, 仅 God Spirit 修仙线获取; "小道士/老道士"非商店 NPC。

(未整理)

## 系统全景 (ClientModule ×34 分类)

- [2026-08-25 | pv2913] **钓鱼核心**: Fishing / Selling / Bait / Skill(15 实现模板) / UpgradeSkill / SkillStore / Mastery(精通) / TraitPassive(天赋被动)
- [2026-08-25 | pv2913] **世界与移动**: Compass(罗盘) / Boat(船) / Swimming(游泳) / Weather(天气)
- [2026-08-25 | pv2913] **经济与成长**: Inventory / Index(图鉴) / Gacha / CraftBait(合成饵) / CraftRod(合成竿) / Gamepass / Code(兑换码)
- [2026-08-25 | pv2913] **UI/杂项**: QuestUI / Dialogue(NPC 对话) / Notification / Stats / Setting / Tutorial / GUIController / FormatNumbers / EternityNum(大数) / GameService / NotifyFish

## 元素与天气

- [2026-08-25 | pv2913 | Info.Element] **14 种元素**: Normal/Cloud/Divine Cloud/Sovereign Cloud/Taiji/Pure Yang/Sanqing/Blood/Buddha/Claw/Pain/Maoshan/Shu Daoshan/Beiming。技能 Type 字段即元素; 装备 Description 含元素加成 (如 Heavenpiercer Rod: "Shu Daoshan 技能 +100% 伤害") → **竿与技能元素匹配是配装核心**。
- [2026-08-25 | pv2913 | ReplicatedStorage.Weather] **6 种天气**: Rainy/Thunderstorm/Foggy/Windy/Snowy/Blazing Sun (视觉特效 folder, 当前天气值由服务器同步); 对渔获的影响未量化, 待观察。

## 额外协议补充

| Remote | 方向 | 参数 | 说明 |
|---|---|---|---|
| Events.RedeemCode | C→S | (码字符串) | 兑换码, Menu.Code 输入框同款 |

- [2026-08-31 | pv2929 | Potassium] **Code 系统全解**:
  - 客户端 `ClientModule.Code` 仅 UI 绑定: Redeem 按钮 → `Events.RedeemCode:FireServer(TextBox.Text)`, **无码表** (require 返回 `{}`)。
  - 码权威在服务端; 客户端可见 `Data[UserId].Code` Folder, 子节点 `BoolValue` (Name=码, Value=true 已兑 / false 未兑)。
  - 假码不建节点; 有效码兑换成功后 BoolValue 置 true (实测 49KLikes 1.5s 内 false→true)。
  - 活跃码种子 (2026-08): 49/48/47/46KLikes · 33~30MVisits · 13KActives · HWF · AXO · Taiji(Lv500, 未必预置进 Data.Code)。
  - 部分码有等级门槛 (Like≥20 / Visits≥50 / Taiji≥500), 不够级服务器静默拒绝。
| Events.BuyFishingRod | C→S | (竿名) | 买竿 |
| Events.SecretRod | S→C→S | 服务器推限时秘密竿 → BuyFishingRod 购买 | 限量竿机制 |
| ~~Events.ShopHandle~~ / ~~Events.Market~~ | - | 全库零引用 | **废弃 remote**, 忽略 |

## 成长与角色

- [2026-08-25 | pv2913] **等级**: `Data[UserId].Level` = {Level=29, Experience, MaxExperience}; BaseHP 同级缩放; 经验来源鱼 Exp 字段。
- [2026-08-25 | pv2913] Info.Character = 12 个剧情 NPC (Chu Xin/Jiang Lao/Sage Yijiu/Enzo/Beiming…对应任务线); Info.MainQuest = 22 条任务线配置 + Reward folder。
- [2026-08-31 | pv2929 | Potassium] **称号头顶视觉 (EquipTitle)**:
  - BillboardGui Character.HumanoidRootPart.EquippedTitle: Title/Image/PlayerName 颜色走子节点 UIGradient 名 Color, TextColor3≈白; PlayerName 文本不改但渐变随称号变。
  - Title.BgT=0.25, AutomaticSize.X; 短名 Size.X≈0.9, 长名≈2.2。
  - VIP: Image.BgT=0.25 + Flare1(138111953688137) + Circle(10637682258); Sage/Master/Grandmaster 有 Flare, rot=-90; Expert/Novice 无 FX。
  - 未拥有称号 EquipTitle:FireServer 被拒; 本地伪 Owned 无效。假称号只改本地 Billboard + Equip 标记即可。
- [2026-08-25 | pv2913] 称号 9 种 (Info.Player_Title); 卡池 2 个 (Taiji/Egoless Banner, LootTable+Chance 结构); 合成系统 CraftBait/CraftRod 模块存在 (协议未逆向)。
- [2026-08-25 | pv2913] God Spirit 系统: Data.GodSpirit folder + Info.Orb 宝珠 ×9 + Spirit/God NPC — 修仙养成线, 未逆向。
- [2026-08-25 | pv2913] 家园: Plot 相关 remote (PlaceStructure/ClaimPlot/UpgradePlot/BuyStructure) + FishTank 鱼缸 — 未逆向。

## 关键机制结论

- [2026-08-25 | pv2913 | 初探] 游戏: [☯UPD] 重型钓鱼, 作者 Unknown Journey, Fisch 类玩法, 核心循环 = 抛竿 → 等咬钩 → Tap 推条打鱼 → 获鱼。
- [2026-08-25 | pv2913 | dump-anticheat-hooks] **无主动客户端反作弊**: DataModel 元表全为 C closure 无 hook, 无无源 per-frame 监听, 无注入连接检测。L1 人类化即可安全开发。
- [2026-09-03 | pv2929 | Potassium 侦察] **复测仍无客户端封号检测**:
  - DataModel `__namecall/__index/__newindex` 均为 **C closure** (无 Lua 元表 hook)
  - `getnilinstances` 无挂空父级反作弊脚本
  - `Events` 下无 Kick/Ban/Cheat/Report/Anticheat 命名业务 remote
  - `Remotes` 存在管理工具: `BanPlayer`/`UnbanPlayer`/`GetSuspects`/`ToggleInvisibility`/`SelectPlayer`/`TeleportToPlayer`/`GetAPIData`/`GetFinalPhase` — 普通号 `InvokeServer` 一律 `{ok=false, reason=NO_PERMISSION}`; 客户端脚本反编译无引用 (权限门在服务器)
  - **结论**: 看不到「客户端抓到脚本就封」的链路; 封号风险主要来自 **服务器对业务包的校验/限流/人工审核** + Roblox 平台层, 不是本游戏客户端 AC
- [2026-08-25 | pv2913 | hub@0.1.0] 官方自动钓鱼 Level≥100 解锁 (`Data[UserId].Level.Level.Value`), 开关 `Events.AutoFishing:FireServer()`; 低级号唯一路径是自制脚本。
- [2026-08-25 | pv2913 | hub@0.1.0] 背包上限检查公式: `Inventory:GetChildren()` 数量 + Hotbar 各 slot Quantity 之和 ≥ `InventoryLimit.Value` 时禁止抛竿。
- [2026-08-25 | pv2913 | 实测] 咬钩等待时间随机 (分钟级正常); 失败/结束后 FishID 被服务器清空, `Fishing` attribute 复位 false。
- [2026-08-25 | pv2913 | 实测] **卖鱼任意位置可用**: `SellFish:FireServer("All")` 在钓鱼点直发即全卖到账 (+1216 Cash/5条), 无 NPC 距离校验、无确认弹窗。
- [2026-08-25 | pv2913 | ClientModule.Setting] 游戏自身传送 = 本地 CFrame 写入, 位置不设防 → 岛屿瞬移、钓鱼点自由选择均走合法路径。
- [2026-08-25 | pv2913 | UI 结构] MainGui.Menu 含 Compass(传送)/Exchange(兑换)/Code(兑换码)/Trait(天赋)/Sell(卖鱼 One|All)/Dialogue(NPC 对话) 六大面板; Button/Button2 为侧边快捷入口 (Gacha/Quest/Shop/Index/Compass/Code/Auto)。

## L2 手段登记 (危险功能对抗手段台账)

- [2026-08-25 | pv2913 | 自动钓鱼 v0.1.0]
  - 手段: **无 L2** — 仅控制本地 Bar UI 位置 (服务器不可见), 所有发包均由游戏自身代码发出 (抛竿包与人类一致, UpdateFishProgression 由游戏协程按固定 10Hz 发出)。定性 L1 人类化。
  - 目标: MainGui.Fishing.BarFrame.Bar.Position
  - 验证: 见 devlog 实测记录
  - 信号特征: 若未来加验证, 可能表现为 UpdateFishProgression 频率与点击事件不匹配校验

- [2026-09-02 | 防踢心跳@0.31.0]
  - 手段: 注入强制 startAntiIdle; 每60s getconnections(Idled):Disable 重掐 + VirtualUser/VIM/mousemoverel/keytap 多通道脉冲; Idled 触发再掐再脉冲。无 L3。
  - 目标: 引擎 ~20min 闲置踢 / 闲置后自动换服
  - 验证: Potassium pv2929 ConnectionObject:Disable 可用; 强制启动修 Callback 未触发零防护
  - 信号特征: 无
  - 根因归档: Toggle Value=true 创建不触发 Callback → 旧版实际从未启动

- [2026-09-03 | 恩佐 Phase2@1.2.4]
  - 手段: 不走 onClick; `BossPhase2Action:FireServer({Hit=true, Index})` + 本地随机挪 Hitbox
  - 目标: 避免三角波错判 Hit=false 扣血
  - 验证: (待用户实机)
  - 信号特征: 无晃动属预期 (晃动只在 onClick 命中分支)

## 可复用代码片段

```luau
-- 锁 Bar 于判定区中心 (0 时长 TweenPosition 覆盖游戏活动 tween)
local bar = game.Players.LocalPlayer.PlayerGui.MainGui.Fishing.BarFrame.Bar
bar:TweenPosition(UDim2.new(0.5, bar.Position.X.Offset, bar.Position.Y.Scale, bar.Position.Y.Offset),
    Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, 0, true)
```

- [2026-08-25 | pv2913 | ClientModule.Weather] **当前天气值 = `workspace:GetAttribute("Weather")`**, 取值 Clear/Windy/Rainy/Thunderstorm/Foggy/Snowy/Blazing Sun (7 种含晴天); 调度器监听 `workspace.AttributeChanged` 动态 require `ClientModule.Weather.Weather[名]` 模块刷 Lighting+特效。客户端 SetAttribute 可本地触发信号 (服务器会周期覆盖回真实值)。天气鱼映射: Windy→Perch(飞鱼帝/后), Snowy→Frost(重生河豚兽/霜王翠鸟), Blazing Sun→Amber(龙纹锦鲤/血玉鱼), Thunderstorm→Bamboo(赤雷鳗/绯红之鱼系), Foggy→Coconut(穿天龟)+Mistpeak(幻影灯笼鱼) — 全为 P81~95 Boss。
- [2026-08-25 | pv2913] 天气鱼配置源 = Info.Inventory 鱼的 Description ("Can be found during X weather on Y isle"); Scarlet Fish 系配置无描述, 仅任务描述带天气信息。

## 合成系统

- [2026-08-25 | pv2913 | Info.Bait[x].Ingredient 全量解析] **Mythical 饵配方** (Ingredient = {槽位→鱼名}):
  - 冰霜鱼饵 Frost Bait = 升华鲈鱼 + 霜王翠鸟 + 太初鲲皇 + 战鲨
  - 无名鱼饵 Nameless Bait = 幻影灯笼鱼 + 高山鱼 + 章寄鱼 + 虎沼鱼
  - 彩虹鱼饵 Rainbow Bait = 巨型虎鱼 + 赤雷鳗 + 黄金守护鱼 + 穿天龟 (成品即召唤 Rainbow Dragonfish)
- [2026-08-25 | pv2913 | 实测] 合成协议 `Events.CraftBait:FireServer(饵名, 数量)`; CraftRod 同款模式; 材料鱼全部纳入智能锁定「合成材料鱼」规则。

## 锁定机制

- [2026-08-25 | pv2913 | 实测] 鱼的"锁定/收藏" = **Name 字符串后缀** `" | Favorite"` (如 `"Elder Chainbound Shark | 97021.39 | Favorite"`), 无独立 attribute/folder。切换协议 `Events.FavoriteItem:FireServer(鱼名或nil, 鱼名)`。
- [2026-08-25 | pv2913] SellFish("All") 是否跳过锁定: 服务端行为客户端不可见; 设计意图应跳过, 自动售鱼按"只数未锁定"实现, 待长期观察确认。

## 获取方式总表 (鱼/竿/功法)

- [2026-08-25 | pv2913 | Info.Inventory.Description 全量解析] **特殊鱼获取提示** (21 条, 其余普通鱼按岛屿权重表随机):
  - 天气限定 Boss: Windy→鲈鱼岛(飞鱼帝/后) · Snowy→霜冻岛(重生河豚兽/霜王翠鸟) · Blazing Sun→琥珀岛(龙纹锦鲤/血玉鱼) · Thunderstorm→竹林岛(赤雷鳗) · Foggy→椰子岛(穿天龟)+雾峰岛(幻影灯笼鱼)
  - 地点限定: 升华鲈鱼/真形鲈鱼→鲈鱼岛 · 太初鲲鱼系→霜冻岛 · 战鲨/畏鳞石斑→椰子岛 · 巨型虎鱼/黄金守护鱼→战场岛 · 高山鱼/虎沼鱼/章寄鱼/幻影灯笼鱼→雾峰岛
  - 鱼饵召唤: 彩虹龙鱼←彩虹饵 · 霜后鱼←冰霜饵 · 无名章寄←无名饵

## 全量数据表说明 (109 鱼 / 84 功法 / 39 竿)

- [2026-08-25 | pv2913] 三张全量表**不硬抄入档**, 运行时 `require(Info.Inventory/Skill)` 即取 (游戏更新自动跟随)。字段语义:
  - 鱼: `{Cash=展示基准价, Power=战斗力量, Time=战斗时限秒, Chance=抽取权重, MinKg/MaxKg, Boss, SpecialBoss}`
  - 极值参考: 最贵 Octoparasitic Fish ¥25000/P100/T25000s(7小时!); 最便宜 Trout ¥20/P1/T5s; 权重最高 Trout 2 vs Nameless Octoparasite 600000
- [2026-08-25 | pv2913] **功法伤害 TOP 榜** (Stats.Damage 单跳基数): Pure Yang Wuji 2300[烈日] > Yuqing Flowing Cast 1000[三清] > Seven Wounds Fusion 900[北冥] > Vajra Godcast 600[佛] > Celestial Gatebreaker 550[神云] > Hellbreaking Hook 500[痛] > Tactical Suppression 3000(Eye Of Horus 专属 CD2s!)。
- [2026-08-25 | pv2913] **破无敌功法**: Lover Slaying Fishing Art[血] 明示 "Can bypass boss invincibility"; Egoless Technique CD999 大招; Sever the Gate 系列 CD=9900000 = 一次性大招 (400%/600% current damage)。
- [2026-08-25 | pv2913] **竿 Damage 字段** = 元素加成%: Heavenpiercer/Maoshan/Pure Diamond/Sacred Bamboo 均 D100; Diamond Rod D50; 其余 nil。Crystal 价: Kraken C500 / Demonic C300 / Anchorbound C200 / Lifebloom C75 / 三 P100 竿 C50。Eye Of Horus Cash=-1 彩蛋确认。

## 获取方式总表 (鱼/竿/功法)

- [2026-08-25 | pv2913 | Info.Inventory.Description 全量解析] **特殊鱼获取提示** (21 条, 其余普通鱼按岛屿权重表随机):
  - 天气限定 Boss: Windy→鲈鱼岛(飞鱼帝/后) · Snowy→霜冻岛(重生河豚兽/霜王翠鸟) · Blazing Sun→琥珀岛(龙纹锦鲤/血玉鱼) · Thunderstorm→竹林岛(赤雷鳗) · Foggy→椰子岛(穿天龟)+雾峰岛(幻影灯笼鱼)
  - 地点限定: 升华鲈鱼/真形鲈鱼→鲈鱼岛 · 太初鲲鱼系→霜冻岛 · 战鲨/畏鳞石斑→椰子岛 · 巨型虎鱼/黄金守护鱼→战场岛 · 高山鱼/虎沼鱼/章寄鱼/幻影灯笼鱼→雾峰岛
  - 鱼饵召唤: 彩虹龙鱼←彩虹饵 · 霜后鱼←冰霜饵 · 无名章寄←无名饵
- [2026-08-25 | pv2913] **竿获取三渠道** (39 根): ①现金店×28 (BuyFishingRod NPC, ¥100 木杆 ~ ¥6000万 Starlight P83) ②水晶店×9 (Crystal 货币: Kraken P90/Heavenpiercer P100/Pure Diamond P100/Sacred Bamboo P100 等) ③非卖×5 — Diamond Rod P90、Maoshan Rod P105(全游戏最高攻!)、Taoist Rod P100、Wooden Rod、**Eye Of Horus P9999**(异常值/彩蛋); 元素加成竿: Taiji系用Sacred/Ascendant Bamboo, Shu Daoshan用Heavenpiercer, Maoshan用Maoshan Rod, Pure Yang用Taoist。
- [2026-08-25 | pv2913 | Info.Skill.Price] **功法商店 19 种可购** (¥100 Skyfall Stomp ~ ¥50万 Bac Minh Technique), 全部 Cloud/Beiming 元素系; 用户已集齐 84 功法全部。配套协议: BuySkill(购买)/EquipSkill(RF 装备)/UpgradeSkill(RF 升级); 技能 EXP 使用积累成长。

## 船只系统 / 坐骑查证

- [2026-08-25 | pv2913 | Info.Boats] 5 艘船: Boat 60速(基础) · Golden Boat 90速 ¥5亿 · Rainbow Boat 120速 ¥50亿 · Kunfish Overlord 85速(非卖 Boss 奖励) · Ascended Perch 85速(非卖)。SpawnBoat NPC 召唤; 协议 `BoatShop.Spawn:FireServer(船名, spawnpoint)`。
- [2026-08-25 | pv2913] **无坐骑系统** (全局扫描 Mount/Ride/Pet 仅命中船的 Root.Mount 挂载点)。
- [2026-08-25 | pv2913] BOSS 入口协议 = `Events.StartBossFight:FireServer(Boss标识, 难度字符串默认"Normal")`, 由 BossUI LocalScript 的 Fight 按钮触发; 面板含 BossImage/InFight 状态检查。

## 材料资源 (Orb/GodSpirit)

- [2026-08-25 | pv2913] 宝珠 Orb: Info.Orb ×9 定义 (Bac Minh/Taoist/Taiji 等), 玩家 Data.Orb 当前空; DeleteOrb/EquipOrb(RF) 协议存在。GodSpirit: Data.GodSpirit = Yellow/Blue/Green 三 BoolValue 未解锁 — 修仙养成线入口未开。

## 战力提升 DPS 增强全景

- [2026-08-25 | pv2913] 打鱼 DPS 构成 = 打鱼上报(锁条时长×频率) + 技能直伤(功法×EXP成长) + 被动加成:
  1. **竿 Power** (P8→P105): 决定力量比 → 伤害效率与条速
  2. **竿元素加成**: 元素匹配 +50~100% 技能伤害
  3. **技能 EXP**: 使用积累, 实际伤害随之增长
  4. **天赋**: Damage%/Crit%/CD% (重roll 券 101 张可刷神话)
  5. **RodPower buff**: Rage/EnhancePower/DOTGodBoost 类技能临时增益
  6. **等级**: BaseHP 生存 + 解锁高级岛资格
  - 最优路线: 高 Power 元素匹配竿 + 对应元素高伤功法 + 天赋刷攻 + 心跳类 buff 常驻

## 中文化映射 (hub.luau 内置 CN_ALL 表)


- [2026-08-25 | pv2913] 鱼名 109 种全覆盖 / 岛屿 10 / 天气 7 / NPC 17 / 鱼饵 5; `trName()` 查表翻译, 未收录显示英文原名。内部逻辑 (任务匹配/购买协议) 始终用英文原名, 翻译仅作用于展示层。
- [2026-08-25 | pv2913] 价格展示统一 fmtNum(): ≥1e6→M, ≥1e3→K, 与游戏 FormatKg 同款风格。

## AFK 系统

- [2026-08-25 | pv2913 | ClientModule.AFK] `Data.AFK` BoolValue = 挂机开关 (MainGui.Button.AFK 点击切换, `Events.AFK:FireServer()`); 鼠标不动 60s + 开关开 → 客户端自动发进入挂机态; 服务器经 OnClientEvent 回推计时文本。收益机制未证实, 自动化暂不联动。

## 角色系统 / NPC 分布 / Boss 挑战 / 每日系统 (2026-08-26 | pv2913 | wiki 逆向)

- [2026-08-26 | pv2913 | Info.Character] **角色系统 = 元素增伤伙伴**: 12 角色, 获取 = 卡池抽取 (Taiji Banner Secret 层掉 Jiang Lao) + 剧情进度。BaseBoost: Jiang Lao +50%(太极&普通/全游戏最高) > Enzo·Beiming·Nanjiang·Yu Jianchou +20% > Sage Yijiu·Xiao Daoshi +15% > 其余无字段(随好感成长)。ModelLevel 关联 NPC 角色等级 (任务 CharacterLevel 类型即提升该值) 强化加成。
- [2026-08-26 | pv2913 | workspace.NPC 遍历] **NPC 全分布 60 个**: 表哥 BiaoGe 设出生点 ×10 岛全有 · 楚欣 ChuXin 船夫 ×10 (Chu Xin 1~10) · 表弟 BiaoDi 竿店 ×8 · 八长 BaChang 饵店 ×10 · 娜娜 Nana 卖鱼 ×9 · 一九大师 ×2 (新手岛+战场岛) · **恩佐 Boss 入口仅辐射岛** (-116,1349) · Spirit 精魄使徒战场岛 (1245,-134) · 曾天国辐射岛任务 · 南江/门票任务官/The Shadow??? 均新手岛 · 江老竹林岛 · 白民椰子岛 (1502,-1563) · 夏蝶蝶霜冻岛 (-1256,-1234) · 小道士鲈鱼岛 (115,-1496) · 老吴战场岛。
- [2026-09-01 | pv2929 | hub@0.30.3 实机复核] 多岛功能 NPC 计数微调: BuyFishingRod×8(Biao Di) / BuyBait×9(Ba Chang, 原档案×10) / SpawnBoat×10(Chu Xin 1~10) / SellFish×9(Nana) / SetSpawn×10(Biao Ge)。HUB 传送列表对前四类按 Folder 合并为单条中文标签, 传送取距玩家最近候选。
- [2026-09-01 | pv2929 | hub@0.30.4] SetSpawn(表哥 · 设出生点) 同样纳入合并+最近传送; 五类多岛 Folder 全部覆盖。
- [2026-08-26 | pv2913 | BossSetUp.Enzo] **Boss 挑战三难度+狂暴**: Normal/Hard/Nightmare (Power90, Time 20000/40000/80000s) + InsanePhase (Boss 施放 Egoless Technique)。**奖励表 = 血系功法唯一稳定产地**: Normal[水晶2(100)/门票1(50)/Kin·Master·Lover 斩血各(5)] · Hard[水晶5/门票1/三传说各(10)/友尽斩血 Mythical(5)/处决宝珠(10)] · Nightmare[水晶10/门票2/三传说各(20)/友尽斩血(10)/处决宝珠(50)]。括号=Rarity 权重。
- [2026-08-26 | pv2913 | QuestUI@512] **好友加成**: LocalPlayer attribute `FriendBoost` → 信息面板 "Friend Boost: X% Cash" 卖鱼现金加成; 设置项 AllowJoinBoss (Everyone/Friends/Nobody)。
- [2026-08-26 | pv2913 | QuestUI@455+] **每日系统**: ①每日水晶 DailyCrystalDrop 上限 100 (Gamepass 1899931197 → 200), 重置倒计时 = 86400 - serverTime%86400 (UTC 日界); ②DailyReward 签到 7 天循环 = 水晶×5×6 天 + 第 7 天 Specter's Chainsaw 竿皮肤; ③【修正】`Data.DailyReward.DayCycle.Value` = 上次领奖日期字符串 (ParseDate 比较), **非 unix 时间戳、非昼夜循环** — 推翻旧条目; 昼夜 = `Lighting:GetMinutesAfterMidnight()` 12 小时制纯视觉显示, 不影响渔获。
- [2026-08-26 | pv2913 | workspace 一级结构] SecretRod(Folder)=秘密竿机制载体; Leaderboard=排行榜; Visual_Balls/Reset/Tutorial 补充地标; Fishes(Folder)=战斗鱼实体容器。
- [2026-08-26 | pv2913 | 交付物] 百科网页 `C:\Users\CARSER\Desktop\HFish\wiki\index.html` (+data.js 61KB + assets 226 图): 鱼109/竿39/功法84/任务22线/角色12/NPC23类/Boss奖励/天气7/每日系统 全板块, 玩家向中文无技术词汇。数据生成链: 游戏端 eval JSONEncode → data.js (零转录), 缩略图 thumbnails API 批量下载。

## 任务奖励总表 / 功法来源体系 (2026-08-26 | pv2913 | wiki v2)

- [2026-08-26 | pv2913 | Info.MainQuest.Reward Folder] **任务通关奖励总表**（每线单奖, {类型,名字}）: GiangLao1→圣竹竿皮 · GL2→太极拳V3 · GL3→无影太极击 · SY1→**Diamond Rod(非卖竿来源实锤)** · SY2→凤凰湮灭术 · SY3→五重封印 · SY4→十方汇聚 · SY5→一钩定乾坤 · 茅山1→灵渡 · 茅山2→三清归一 · 北冥1→七伤融合 · 白民→白民宝珠 · 道士→**纯阳无极(全游最高单段2300)** · 夏蝶蝶→切门V3 · 战场岛江老→升华太极艺 · 盲眼神→天宗极艺·极 · 老吴→兽破斩V2 · 鲈鱼岛→钻脊竿 · 霜冻岛→冰晶重力竿 · 椰子岛→魂棘竿 · 情人节→丘比特竿皮 · 春节→烈焰马竿皮。另有 Easy/Hard Ticket Quest→门票、Zeng Tianguo Quest→精魄珠。
- [2026-08-26 | pv2913 | SkillStore 源码] **功法商店双门控**: ①客户端只渲染 `Price>0` 的 19 门 ②服务器经 `UpdateSkillShop` 推名单控制条目 Visible → **货架随任务进度逐步开放**。BuySkill 直接 FireServer(技能名)。
- [2026-08-26 | pv2913 | ClientModule.UpgradeSkill 实为兑换面板] 遍历 Info.Item 中 `Exchange==true` 条目按 Ingredient 配方经 Events.Exchange 兑换; 当前仅两种: 精魄珠=5水晶+500万现金、天赋重抽券=5水晶+500万现金。**不是功法升级系统**。
- [2026-08-26 | pv2913 | 存档实测] V2/V3 中段功法 = **任务线进程 NPC 授予**（玩家完成 GL1+GL2 后拥有太极 V1/V2/V3 全套; Phoenix Strike V2 在 SY2 进行前已入手）。任务进度存 `Data[UserId].Quest.Main`, 子项名 `_Completed` 后缀 = 已完成。玩家实拥功法 19 门（非此前误记的 84 集齐——84 是全图鉴总数）。
- [2026-08-26 | pv2913 | 交付物 v2] wiki 重构: ①任务区改 9 条剧情链分组(接取NPC+坐标/逐环奖励徽章/解锁条件/指导, QUEST_REWARDS 表驱动) ②功法 84 门五路径精确标注(商店19/任务终奖14/剧情授予/卡池13/恩佐4) ③天气区动态渲染 Boss 卡带图带数据点击跳鱼卡锚点 ④鱼卡加 id 锚点+任务目标鱼名可点击跳转。文件 76.9KB。

## 百科 v2 多页面重构 (2026-08-26 | pv2913 | wiki 架构)

- [2026-08-26 | pv2913 | 交付物 v2] **wiki 全面重构为多页面 iOS 玻璃拟态站**: 主页 index + 15 板块页(guide-basics/stats/advanced · dex-fish/rods/skills/characters · play-quests/boss/gacha/items · world-islands/environment/npcs) + detail.html 通用详情引擎(?type=fish|rod|skill|char&name=)。
- [2026-08-26 | pv2913 | 模块化] `css/style.css`(毛玻璃主题) · `js/core.js`(WIKI 命名空间: 映射/格式化/卡片组件/导航注入/WIKI.page() 注册) · `js/data.js`(游戏端导出) · `js/extra-data.js`(CHARS/QUEST_CHAINS/QUEST_REWARDS/NPC_DATA/ISLES/WEATHER_GROUPS/ENZO/DAILY 结构化) · 每页一个 page-*.js。**agent 增量维护 = 加 html+page-js 两文件即可**。
- [2026-08-26 | pv2913 | 岛屿竿力] world-islands 页从 AREA+FISH 实时计算每岛渔获力量区间/Boss最高力/舒适竿力(80%法则)/推荐入门竿(RODS 反查), 游戏更新数据自动跟随。
- [2026-08-26 | pv2913 | 踩坑记录] ①core.js 必须 Object.assign 合并 WIKI(整体覆盖会丢 extra-data 先挂载的数据) ②page 脚本注册依赖 DOMContentLoaded 时序(core 在 body 底部 readyState=loading 分支) ③FISH 等全局 const 不在 WIKI 上, 判空用 typeof。
- [2026-08-26 | pv2913 | 验证] node stub-DOM 全站逐页验证脚本(Temp/opencode/verify_site.js): 20/20 通过(12 板块页+8 详情样例), 容器产物字节数全正常。

## Boss 鱼击败掉落 / 坐骑 / 竿合成 (2026-08-26 | pv2913 | wiki v2.1)

- [2026-08-26 | pv2913 | Info.Inventory.Reward 字段] **Boss 鱼击败掉落实锤**（此前遗漏）: Reward 类型三种 = Skill/Orb/Boats。**坐骑=船**: 太初鲲皇→鲲皇霸主号(权重5)、升华鲈鱼→升华鲈鱼号(5)。宝珠: 霜后鱼→一九/重生河豚兽→太极/彩虹龙鱼→乾门/霜王翠鸟→云升(各100)。功法 30+ 门来源实锤: 真形蛟鱼→太极拳V1(50)、太初鲲皇→切门V1(10)、真形鲈鱼→兽破斩(5)、虎沼鱼→九阳升天(5)、蛇纹鱼→开门诀(20)、黄金守护鱼→封门诀(50)、幻彩锦鲤→正道功(100)、虎牙鲸→倒转钓鱼(100) 等——**推翻部分"剧情授予"旧标注**。
- [2026-08-26 | pv2913 | Fish.Skill 字段] Boss 反击技: 每0.5s跳伤持续3s, 伤害分级 5~500（无名章寄/虎沼鱼/高山鱼=500 致命级; 蛟龙系=10 轻微）; 部分含蓄力重击段(DurationMax=30)。Crystal 字段 = 击败必得水晶 2~20。
- [2026-08-26 | pv2913 | Rod.Ingredient 字段] **三神竿合成配方实锤**: 穿天竿=飞鱼帝+飞鱼后+穿天龟+彩虹龙鱼; 圣竹竿=无名章寄+重生河豚兽+升华鲈鱼+高山鱼; 纯钻竿=霜王翠鸟+霜后鱼+血玉鱼+龙纹锦鲤。
- [2026-08-26 | pv2913 | 汉化] 新增 WIKI.CN_SKILL(84)/CN_ROD(39)/CN_TRAIT(13)/CN_ORB(9) 全量中文名映射于 extra-data.js; 卡片/详情/任务/卡池全站双语显示。

## 日常任务 / 保底 / 档案细节 (2026-08-26 | pv2913 | wiki v2.2)

- [2026-08-26 | pv2913 | Info.Quest] **每日任务池实锤**: 固定 4 槽 = [Fishing 垂钓100次→💎5, BossQuest 打Boss10条→💎20, Bait 购买鱼饵25次(按购买次数计!)→💎10, PlayTime 在线1800s→💎5], 合计日 +40 水晶。玩家进度存 `Data.Quest.Daily[1~4]`(Progression/QuestType/Claim/Reset)。**无周常任务系统**(grep Weekly 无结果)。
- [2026-08-26 | pv2913 | Data 档案] InventoryLimit 背包容量随成长(实测580) · TraitMythicalPity 神话保底计数器 · BaseHP 随等级 · FishCaught/HeaviestWeight 个人纪录 · BossDailyResetDay · RodAwaken(竿觉醒数据) · Code(兑换码) · GodSpirit(神魂修仙线预留)。
- [2026-08-26 | pv2913 | Gamepass] 10 个 ID: 1899931197=水晶上限100→200; 另有 2 个可重复水晶礼包(带 LastBuy 计数); 其余为一次性权益。
- [2026-08-26 | pv2913 | 交付物 v2.2] play-quests 新增每日任务4槽详解+最速攻略+最省事日常路线; guide-stats 扩充双轨等级/个人纪录/保底机制/货币日收入测算; play-items 新增兑换码小节。

- [2026-08-26 | pv2913 | 交付物 v2.3] 船只系统独立成页 world-boats.html(5船详解/坐骑船刷取攻略/召唤方法/购买建议); 导航与主页入口同步更新。
- [2026-08-26 | pv2913 | 复核] Reward 类型全集 = {Skill:24, Orb:4, Boats:2} — **Boss 掉落坐骑仅 2 艘**(鲲皇霸主号/升华鲈鱼号), 无第三种; 全游戏船只 5 艘(初始1+商店2+Boss掉落2)。用户报告"3种"未获数据支持, 若后续版本新增以 Inventory.Reward 扫描为准。
- [2026-08-26 | pv2913 | 文案] wiki 掉落频率改为通俗五级: 较容易出(≥100)/常见掉落(≥50)/概率不错(≥20)/可以刷到(≥10)/稀有看脸(<10); 新增 WIKI.CN_BOAT/CN_TRAIT_DESC 映射, 天赋效果全中文。
- [2026-08-26 | pv2913 | SkillShop 双货架] NPC 模型自带 SkillShop(ModuleScript): Sage Yijiu=15门通用/流云系(Skyfall/InfiniteSky/Unshaken/SwiftReel/ReelMachine/ReelSprint/Demonfall/DragonfishVitality/Skybreaker/AerialRodThrow/ThousandEnemySweep/OneStrike/RollingChaos/PhoenixStrike/RoosterStrike); Bac Minh=2门北冥系(BacMinique/HeadSmash)。Dragon Strike 与 Echo Hand 不在任何 SkillShop 但 Price>0(全局商店池)。客户端 SkillStore 渲染全部 Price>0 到同一面板——货架分组可能由服务器按 NPC 决定。
- [2026-08-26 | pv2913 | NPC 内部名] Taoist→XiaoDaoshi · HaDieuDe→XiaDiaodi · BacMinh→Beiming · GiangLao→OldJiang · LaoNgo→OldWu · TheShadow 显示名"???"。workspace.NPC 按 Folder 功能分组: BuyBait/BuyFishingRod/SetSpawn/Function/Boss/LearnSkill/SpawnBoat/SellFish/Spirit/God; 全部 ProximityPrompt 均为 Talk。BlindGrandAngler 手持 GrandmasterSteelRod 装饰模型。
- [2026-08-26 | pv2913 | 交付物 v2.4] world-npcs 重构为四组详解卡片(基础设施5/功法成长3/任务发布10/特殊彩蛋6, 含内部名+关联链接)+快速索引表。
- [2026-08-26 | pv2913 | 门票任务实锤] Hard Ticket Quest = 钓重量≥150万kg的Boss×10(FishBossWithAnAmountOfWeight,1500000); Zeng Tianguo Quest = 椰子岛击败Boss25条(FishAtZoneForTimesBoss)→精魄珠; Easy 档目标为服务器下发低门槛(以面板为准)。任务重置购买产品ID=3538386903。QuestUI u152 表含 Hard/Easy Ticket Quest/Zeng Tianguo/Ticket Quest 四个不可取消任务。
- [2026-08-26 | pv2913 | 交付物 v2.5] ①core.js 新增 calcSkill() 功法DPS引擎(单发/持续多段Duration÷0.5s跳伤/Slam周期/一次性大招四形态, 输出单轮总伤/DPS/HPS) ②detail skill 页加实战数值卡 ③新板块 play-simulator.html 配装模拟器: 竿39(元素加成解析)/角色12(增伤%可调)/宝珠元素+伤害冷却词条自填/天赋%/暴击期望 → 84门实时DPS排序+元素匹配高亮+七流派一键预设(太极/蜀道山/茅山/纯阳/三清/北冥/血祭)+大招单独排序。
- [2026-08-26 | pv2913 | Enzo 配置全解] Boss 血量无客户端字段(服务器权威); Skill 三难度完全一致(Power90/Nerf0/血系四连), 唯一区别 Time=20000/40000/80000秒; InsanePhase=SpecialSkill Egoless Technique+Time20000; Reward 按品质分级 Epic/Legendary/Mythical 含 Image 字段; BossImage=76373398213301。
- [2026-08-26 | pv2913 | Character 字段] Info.Character 仅含 ModelLevel/Name/Boost(元素列表)/BaseBoost/Description — 无等级成长表, 升级公式服务器侧; Data.PlayerCharacter.每角色={Equip,Level,Favorite,Owned}。
- [2026-08-26 | pv2913 | 神话饵字段] Bait 配置: Luck=0/Boss=召唤目标名/Ingredient=4鱼/Type=Mythical。
- [2026-08-26 | pv2913 | 汉化] descCN 补 5 组句式后覆盖 84/84(切门400%/600%锁条累积型/定身+伤害短句/固定伤害型/荷鲁斯专属)。
- [2026-08-26 | pv2913 | 交付物 v2.6] play-boss 扩容(地点坐标/六步流程/三难度精确对比表/品质分级掉落表/无HP说明); dex-characters 角色详解卡(属性句式加成/好感机制/受益功法链接); play-items 制作工坊板块(竿合成3配方带来源链接+饵合成3配方+四步流程+循环技巧)。
- [2026-08-26 | pv2913 | 新挖掘] Info.Element 14元素=纯标签(Name+Image, 无相克数据); Data.Index=图鉴收录(每鱼BoolValue, 110种含绯红鲶鱼CrimsonCatfish P3/¥30/15~300kg新手鱼, 已补入data.js); Data.Setting 12项(Lamp/SFX/BGM/RandomBGM/DisableCutscene/VFX/AllowJoinBoss/SkipBossTime/LowGraphic/Sprint等); Gamepass 10项(1899931197水晶上限翻倍+2个可重复礼包); TraitMythicalPity神话保底计数器; RodAwaken觉醒存档。
- [2026-08-26 | pv2913 | 交付物 v3.0 GitHub就绪] 导航重构(10项: 主页/新手指南下拉/鱼类/竿/功法/角色/模拟器/任务攻略下拉/世界下拉/进阶系统); 主页重构(三步上手+四大区全站地图+常用速查); 新页 play-systems.html(图鉴收集/竿觉醒/设置12项详解/通行证/挂机自动化); 鱼表补绯红鲶鱼→110条; README.md+.nojekyll+大小写一致性检查通过(126引用/226图全匹配)。
- [2026-08-26 | pv2913 | 卖价机制] SellFish 客户端仅发"One"/"All"(ClientModule.Selling), 价格计算完全在服务器 — 基准价 Cash 与实际收入的关系待实测(背包鱼名格式="鱼名 | 重量 | Favorite#N", 重量存实例名, GameService.DestringFish 解析)。
- [2026-08-26 | pv2913 | 图鉴结论] Index 无收集奖励机制(ClientModule.Index 的 Reward UI 仅展示该鱼 Boss 掉落 Skill/Orb/Boats)。
- [2026-08-26 | pv2913 | 经验锚点] Data.Level={Level:551, Experience:232916, MaxExperience:386959} — 单点锚点, 完整曲线服务器侧。
- [2026-08-26 | pv2913 | 交付物 v2.7] 任务进度追踪器(localStorage hfish_quest_done, 任务页每链"整线完成"勾选+淡化); 新页 guide-faq.html FAQ 17问(钓鱼基础/功法/Boss/卡关四组); guide-stats 补经验锚点; play-systems 标注图鉴无奖励; 鱼卡卖价标"实得随重量浮动"。
- [2026-08-26 | pv2913 | 修正] 三神竿(穿天/圣竹/纯钻)配置 C=-1+Cr=50+Ingredient — Cr=50 是**合成消耗的水晶费用**非商店售价; rodChannel 已修为配方优先判断, 显示"合成获得·四种Boss鱼+50水晶"。
- [2026-08-26 | pv2913 | 水晶竿入口] 水晶竿购买=鱼竿背包面板(Fisher_Inventory)水晶页签, Events.BuyFishingRod:FireServer(名字), 非 NPC 面板。
- [2026-08-26 | pv2913 | 汉化完成] WIKI.CN_SKILL_DESC 84条全量人工翻译(extra-data.js), core.js skillDesc(name,d) 优先查表→descCN 正则兜底; 英文残留检测=0。
- [2026-08-26 | pv2913 | 新板块] dex-orbs.html 球体图鉴独立页(机制说明+九珠详解卡含获取途径+总表); 导航加"🔮 球体"。全站 23/23。
- [2026-08-26 | pv2913 | 【用户纠错】道士竿/茅山竿] **非卖品结论错误** — 实际由两名随机刷新的流浪道士 NPC 出售(全图随机位置刷新)。刷新/售卖逻辑在服务器侧, workspace 常驻无此模型, 客户端无痕迹。rodChannel 已加专属分支; 卡池 Mythical 层的 Taoist/Maoshan Rod 是 RodSkin 皮肤非本体, 勿混淆。教训: Price 字段缺失≠非卖, 服务器侧售卖渠道无法从客户端排除。
- [2026-08-26 | pv2913 | SecretRod 补充] workspace.SecretRod folder = 6 个水晶竿模型(Blazeshark/Lifebloom/Kraken/Demonic/AscendantBamboo/Anchorbound) — 秘密竿推送候选池。
- [2026-08-26 | pv2913 | 【用户反馈修正】] ①宝珠页竖排根因=JS 往已有 class="grid" 的容器里又包一层 grid(内层被压进 252px 列) — dex-orbs/play-items 已修, 全站扫描无同类; ②"重生等级"=客户端不存在 Rebirth/Prestige 系统(grep 无结果), 用户所指为**角色好感等级**(Data.PlayerCharacter.角色.Level, 任务 CharacterLevel 5 级条件即此); 模拟器已加好感等级下拉(每级+5% 为估算值并明确标注, 官方未公开曲线)。教训: 用户术语需先确认对应游戏实体。
- [2026-08-26 | pv2913 | 【用户纠错2】道士竿¥1亿/茅山竿¥3亿] 两竿为**高价商店竿**: 道士竿=鲈鱼岛小道士处 ¥1亿; 茅山竿=大师兄处 ¥3亿。**大师兄(Maoshan)与小道士(XiaoDaoshi)同点位鲈鱼岛(115,-1496)** — Maoshan@Function 内部名即 Da Shixiong。rodChannel 已改价格文案; NPC_GROUPS 已更新。
- [2026-08-26 | pv2913 | 【重大发现】"重生"系统实锤 = 角色升级(UPG_Char面板+Char_Level脚本)] **精确公式: 实际增伤% = 角色重生等级 × BaseBoost**(CharBoostPercent 函数); 无 BaseBoost 字段的角色默认按 10 计算。升级材料四选一: 玩家等级-500级(即"重生"之本义,牺牲自身等级)/现金50亿/水晶1000/门票200。升级同时给 EXPBoost(经验加成0%起步Cap100%, 存 EXPFromUPGChar)。Offer 三选二随机。入口=菜单UPG_Char面板, 协议 Events.UpgradeCharacter。
- [2026-08-26 | pv2913 | 交付物 v2.8] 模拟器角色等级下拉改真实公式(lv×base, 删+5%估算); dex-characters 加「重生角色升级系统」大节(公式表/四选一材料/EXP Boost/双刃剑警告); NPC 卡更新小道士大师兄同点位+售竿信息。
- [2026-08-26 | pv2913 | 【数据审计】功法 Stats 真实字段模型] 旧 calcSkill 用了不存在的 DamageAfter 字段导致多段功法 DPS 全错。**真实字段**: 多段=SlamTime+Duration(每SlamTime跳) 或 Tick+TickTime(固定跳数); 二段爆发=FirstTime(延迟)+SecondDamage(+SecondTime); 切门系=MainDMG(引爆基数)+Damage(每秒累积)+Duration=9900000; 百分比型=HPPercent/GodHeal(炽焰金刚50%自损打等值伤害回50%血); 定身另一表达=StunTime+DelayTime; 增益回合=Turn/WaitTime/Boost。**Duration 语义双关**(持续时长 or 定身时长), 需结合 Description 文本判定(per second/every 0.5 → 持续; 纯 stun → 单发)。calcSkill v4 已重写并抽查验证(宗师斩血 Tick9跳450伤dps18/友尽1180伤dps19.7/纯阳单发burst2300 ✓)。
- [2026-08-26 | pv2913 | 数量澄清] 鱼类=109(非110, Draconic Koi 显示名"Fish"已在 wiki 改名); 竿=39 含 Grandmaster 三连竿(Steel P37/¥25万 · Emerald P39/¥50万 · Golden P45/¥100万 现金店) — 此前人工盘点漏数, 页面数据本身无缺失。
- [2026-08-26 | pv2913 | 表弟.Setting] 表弟模型自带4根高价竿配置(Grandmaster系列) — 与 Fisher_Inventory 面板购买的关系待确认。
- [2026-08-26 | pv2913 | 【重大发现】Time 字段 = 血量] 战斗鱼实体在 workspace.Fishes, MaxHealth 为服务器写入的动态属性; 客户端 Fishing 模块 fallback MaxHealth=p1.Time → **配置 Time 即单人基准血量**。战斗 UI 血条 = (MaxHealth-已扣)/MaxHealth。Boss 战实体带 HumanBoss/Iframe(无敌期)/HasPhaseLeft 标记。
- [2026-08-26 | pv2913 | 多人机制实测] 8人服恩佐: Normal 与 Hard MaxHealth 同为 **80000**(与 Time 20000/40000 不同→服务器按参战动态写入); 战斗海域刷新伴随小怪(血玉鱼7000/赤鳊君主4000/恐梦鳗1200, 同样可击杀); Boss 反制四类按键映射 Z=Rage/C=Slam/X=Stun/V=Weaken; Boss战专属BGM+节奏谱面预载。多人倍率公式服务器侧不可见。
- [2026-08-26 | pv2913 | 交付物 v2.9] 鱼卡+鱼详情加基准血量; play-boss 加多人机制节(实机数据); 功法详情页新增「伤害最大化教学」生成器——按形态(dot引导/Slam高频/Tick连击/二段爆发/锁条累积/真伤破无敌/增益引信/自损回血/百分比伤害/一次性大招)+字段自动输出针对性连招建议。
- [2026-08-26 | BossUI 入场机制] 恩佐挑战状态机=InFight(全服唯一, 他人战斗中按钮"In Progress"不可进)+OnCooldown(击败后冷却"Cooldown"); 客户端无等级检查代码(门槛在服务器, 具体数值未知); 无门票/材料消耗。用户反馈存在等级门槛待实测数值。
- [2026-08-26 | pv2913 | 手机优化] style.css 新增 @media 760px/420px 两档: 导航横向滚动(brand 文字小屏隐藏)/卡片单列/portal 双列/prop-grid 双列/字号缩放; 角色卡新排版(charcard: 头像块+元素标签+重生公式大字+受益功法截断5+N)。DOM 与 CSS 均验证无误——用户报的竖排疑为浏览器缓存, 建议 Ctrl+F5。
- [2026-08-26 | 等级系统审计] 客户端可挖等级数据已到底: 无 LevelUp 奖励表/解锁表配置(服务器侧); GetInventoryLimit=当前占用统计(上限 InventoryLimit.Value 服务器管理); AFK 模块无客户端门槛。**账号等级实锤作用清单**: BaseHP 随等级(551级=630) / 100级解锁官方AFK / 转生材料(-500级) / 背包容量随成长(551级=580格, 公式服务器侧) / 经验锚点551级需38.7万 / 经验来源=鱼Exp字段(高力量鱼高经验)。guide-stats 已加「账号等级全解」板块。
## 钓鱼竿数据与装备协议

- [2026-08-30 | pv2922 | 实机] **竿数据源**: `Info.Inventory` 中 `Type == "Fishing Rod"` 的 ModuleScript, 共 **39 把**; 字段: `Power`(=能量, 如 Wooden=8 / Maoshan=105 / Eye Of Horus=9999 彩蛋值), `Luck`(幸运), `Cash`(现金价, 水晶店竿无此字段), `Model`(装备模型名)。模块**无中文名字段** → 汉化需外部映射表。
- [2026-08-30 | pv2922 | 实机] **装备协议**: `Events.EquipFishingRod`(RemoteFunction), 参数 = **竿英文名**, 返回非 false 即成功。与游戏背包 Equip 按钮同款 (`PlayerScripts.Fisher_Inventory` L418: `Events.EquipFishingRod:InvokeServer(Name)`)。
- [2026-08-30 | pv2922] 竿获取渠道(三渠道): ①现金店×28 (BuyFishingRod NPC) ②水晶店×9 (Crystal 货币) ③非卖×5 (Diamond Rod/Maoshan Rod/Taoist Rod/Wooden Rod/Eye Of Horus)。

## 船只系统 (Boat) — 全破解

- [2026-08-30 | pv2922 | 实机] **数据**: 玩家船 = `Data[UserId].Boats` (Folder, 子对象 BoolValue, Value=true=已拥有); 全量配置 = `Info.Boats` (ModuleScript: Price/Speed; -1=活动船); 收藏 = `Data.BoatFavorite`。实测 5 艘: Boat 60速免费 / Golden Boat 90速 5亿 / Rainbow Boat 120速 50亿 / Kunfish Overlord 85速(-1) / Ascended Perch 85速(-1)。
- [2026-08-30 | pv2922] **召唤协议**: `ReplicatedStorage.Remotes.BoatShop.Spawn:FireServer(船英文名, Location)`; Location 由服务器 `Events.VisibleUI.OnClientEvent("BoatShop", Location)` 下发(游戏船坞生成点), 可传玩家 `HRP.Position` 让船生成在角色位置。同目录: Open/Buy/Favorite。
- [2026-08-30 | pv2922] **上座**: 服务器生成船后 FireClient `Events.EnteredBoat`(Boat 模型, 含 VehicleSeat/Root(BodyVelocity, AlignOrientation)/Configuration(MaxSpeed=60, MaxTurnSpeed=2, Accel=2.5, Drag=1.2...)/Sit 动画), `ClientModule.Boat` 处理驾驶。客户端补上座: 找 VehicleSeat, `HRP.CFrame=seat.CFrame; Humanoid.Sit=true`。

- [2026-08-30 | pv2922] **召唤点**: 船生成在 Location 指定的位置。游戏船坞 NPC = `Workspace.NPC.SpawnBoat` 下 10 个 "Chu Xin N" Model (HumanoidRootPart + ProximityPrompt "Talk"), 各岛屿一个。脚本取离玩家最近的 NPC 位置作为 Location (实测玩家 1395,9,205 → Chu Xin 9 距离 82)。召唤后轮询找带 VehicleSeat 的船, `HRP.CFrame=seat.CFrame; Humanoid.Sit=true` 传送上座。

## Boss Phase2 点击小游戏协议 — 全破解 (真实流程)

- [2026-08-30 | pv2922 | 来源 PlayerScripts.MinigamePhase2 实机反编译] **触发链路**: `UserInputService.InputBegan` + `MouseButton1` 或 `Touch`, 且 **`gameProcessed == false`** — 若为 true(点击落在任何 GUI 上) 游戏首行 `if p2 then return end` 直接吞掉。→ 外部自动化唯一入口 = 模拟真实鼠标左键点击。
- [2026-08-30 | pv2922] **onClick 完整逻辑**: `if not u105 then return end`(u105=激活) → `os.clock()` 节流 **30ms**(u107) → 算条当前位置 `v4 = u111 + ((t - u115) % u114 * u87 的三角波)` → 命中判据 `v4 ∈ [u108 - v5, u108 + u88 + v5]`, 其中 u108=绿框起点, u88=绿框宽, `v5 = u88*0.5/2`(容差=绿框宽×0.25), 等价于 `|条心 - 框心| <= 框宽*0.75`。
- [2026-08-30 | pv2922] **命中 → `BossPhase2Action:FireServer({Hit=true, Index=u109})` 然后调用 `newHitbox(t)`** — newHitbox 按条当前位置, 在避开 `MinGap` 的区间内**随机**选新绿框位置并 `u109 += 1`。**这就是"绿框每命中一次就换位置"的机制来源**; 只发 FireServer 而不触发 newHitbox 的话, 绿框全程不动(服务器照样认账, 但流程不完整)。
- [2026-08-30 | pv2922] **未命中同样发包**: `BossPhase2Action:FireServer({Hit=false})` + `flashGlow` 闪光(0.35s)。
- [2026-08-30 | pv2922] 其它: `BossPhase2Setup.OnClientEvent` 下发 `BarSpeed/HitboxW/MinGap`(客户端据此重建几何); `RunService.RenderStepped` 驱动条往返移动; `startPhase2/stopPhase2` 管 `BossFightBar.Visible` 与技能锁 `setSkillLock`。
- [2026-08-30 | pv2922 | 实机] **模拟点击通道可用**: `VirtualInputManager:SendMouseButtonEvent` 能触发 `InputBegan` 且 `processed=false`, **前提是落点没有 Active GUI**。
- [2026-09-03 | pv2929 | hub@1.2.0] **(10,10) 会点到顶部控鱼条/BossFightBar** → `gameProcessed=true` → onClick 首行吞掉 → **没有命中晃动、也不换绿框**。正确落点 = 视口中下部无 Active GUI 的像素 (`PlayerGui:GetGuiObjectsAtPosition` 探测)。晃动/newHitbox/发包都在游戏 `onClick` 里, 跳过它只 FireServer 就没有动画。
- [2026-09-03 | pv2929 | Potassium decompile MinigamePhase2] **晃动 = `shakeFishingUI`**: 命中时把整个 `MainGui.Fishing` 的 Position 随机抖 0.25s(幅度 0.02), 只在 onClick 命中分支; 未命中只 `flashGlow` 红光。判定用内部三角波(`t-0.025` 鼠标 / `t-0.06` 触摸), 不是 GUI 条位; 容差仍是框宽×0.25。Bar/Hitbox AnchorPoint 均为 (0.5,0.5)。手机另有 `MainGui.Mobile.Fishing.MouseButton1Down` 不看 processed。
- [2026-09-03 | pv2929 | hub@1.2.4 实机] **按画面点绿心会大量 Hit=false 扣血** — 内部三角波与 GUI 条不同步。自动化改为只 `FireServer({Hit=true, Index})` + 本地挪框, 禁止 sendHumanClick 进 onClick。

## 待复核 (placeVersion 变更后移入)

## 已证伪

- [2026-08-27 | pv2918 | 实机监听] ~~BOSS 主阶段复用钓鱼小游戏 (控 BarFrame.Bar)~~ — **证伪**: 实机 remote-spy 证实开战 (StartBossFight:FireServer("Enzo","Normal")) 后 FishingMinigame 入站 = 0 次, BOSS 战根本不走钓鱼小游戏通道。正确架构: Phase1 = 纯技能 DPS (UseSkill Z/X/C/V, 无条无 GUI/属性信号), Phase2 = BossFightBar 点击条 (MinigamePhase2, BossPhase2Action{Hit=true,Index}), FinalPhase = Rhythm 节奏 (RhythmStart→RhythmHit("hit"))。检测信号改用 StartBossFight 发包 hook 捕获 (Phase1 无 GUI/属性信号)。
