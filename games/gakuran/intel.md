---
genre: rpg
game: "(学乱) Gakuran"
placeId: 128736949265057
universeId: 9199655655
placeVersion: 7560
created: 2026-08-25
updated: 2026-08-25
script: "games/gakuran/hub.luau"
status: active
---

# 游戏情报档案 — (学乱) Gakuran

> **AI 铁律**:
> 1. 会话开始必须先读本文件 + `recall-game-memory`, 禁止对已有结论重新逆向。
> 2. 开发中新发现: 当场 `remember-game` (运行时召回), 收工前回写本文件 (持久归档)。
> 3. 每条结论必须带条目头: `[日期 | pv<placeVersion> | 来源脚本@版本]`。
> 4. 游戏更新 (placeVersion 变更) 时: 把受影响条目剪切到「待复核」区并标注新 pv, **不删除**。
> 5. 结论被证伪时: 移到「已证伪」区保留原文 + 写明证伪原因, 不静默删除。

## 游戏概要

2007 年日本高中角色扮演游戏 (日式学兰题材)。战斗为核心 (Blink 网络格斗), 辅以生活模拟 (打工/手机/社团/街机/音乐)。开发者持续高频更新 (pv 每周 +20 左右)。

---

## 协议与通信

### [2026-08-01 | pv7538 | 架构扫描]
- 网络层 = **Blink**: `BLINK_RELIABLE_REMOTE` / BLINK_UNRELIABLE 单 remote 打包一切。
- packetId 表定义在 `ReplicatedStorage.Shared.Network.Client` (如 EVENT_BikeRide=111 S->C / EVENT_BikeExit=112 C->S), 运行时读表, 别硬编码。
- `CombatClientRemoteEvent` 是战斗专用事件, 载荷 {CharAName, CharBName, ClashType, WinnerName, SnapAPos/SnapBLookAt}。

### [2026-08-06 | pv7538 | 实测]
- **HttpService 全面禁用**: GetAsync 被 block ("disabled/blacklisted for security reasons")。出网用 executor 的 `request()` (实测可达 api.github.com)。

---

## Remote 清单

### [2026-08-01 | pv7538]
| Remote | 用途 |
|---|---|
| BLINK_RELIABLE_REMOTE / UNRELIABLE | 一切业务包 |
| CombatClientRemoteEvent | 战斗广播 |
| CabinetEvent / GameResult / GameSyncReliable | 街机 |
| CarPath | 未使用 (0 refs, 死代码) |

---

## 关键机制结论

### 架构
- [2026-08-11 | pv7538] `ReplicatedStorage.Shared.Services` 在客户端 bootstrap 完成**后被销毁** (反内存/反逆向)。Shared 存活区只剩 Config/Network/Chess/Utils/ConnectFour; Services 只在 bootstrap 期间瞬时存在。大量 ModuleScript 变 nil-parent (RhythmAmpRelayClient/Faces/ArcadeSoundHandler 等)。客户端引导 = PlayerScripts.Client LocalScript ~10 批次 (ClientBootstrapBatch attribute) + safeRequire() helper。
- [2026-07-28 | pv7532→7538] 脚本总数 789 → 1020 (+231)。v7538 新增 ArcadeService/AirHockeyService/ArmWrestlingService/RhythmService (~70 首歌 Rock Band 式玩法)。

### 战斗
- [2026-08-08 | pv7538] Grapple/Clash 胜负**纯服务端判定**, 客户端只播动画。36 样本: 仅同类型碰撞触发 (M1vsM1/M2vsM2, 无混合), 胜者与剩余 HP 无相关性 (疑似纯随机或隐藏规则)。Clash 时长 2.29s, WinnerKnockback 32, LoserLockout 0.6s, SwingCommitFraction 0.25。
- [2026-08-16 | pv7538] 格斗风格 gacha: Mystery 级 = Ali/WingChun (总权重 0.075, 各 ~0.0375%)。WingChun = 反击型 M2 (counter window 0.5s, 倍率 1.25, CD 10s), 专属 perk SwiftHands/FortifiedI。
- 核心循环: M1/M2/Block/Parry/Evasive, 10+ 风格带稀有度。

### 经济
- [2026-08-08 | pv7538] 打工走 FlipPhone 的 "Indeed" App。雇主: GAKUMART (280-400円/hr)、COFFEE SHOP (300-400)、7-ELEVEN (300-400)、CLUB AKUMA (520-720, 限 1 名额)。每场所每日 6 班, 每班 2-4 游戏小时, 玩家一天限接 1 班。WorkLocker 储物柜换装打卡, 只有穿制服在场内计时。支付时机 ShiftEnded/Quit/DayEnded/Died; 未打卡 = NoShow 0 円。

### 未上线内容 (staged-but-dead)
- [2026-08-25 | pv7560] **自行车系统已被删除**: 全索引 0 命中 "RideBike" (v7538 时卡死的 bikeclient 已移除), 别再等它。滑板是唯一载具, 且新增皮肤 gacha: SkateboardSkinConfig (REROLL_PRODUCT_ID=3658267807, SKIN_ATTRIBUTE="SkateboardSkin")。
- [2026-08-11 | pv7538] ~~自行车 staged-but-dead~~ → 已被 v7560 删除 (移入本区)。
- Skateboard 是唯一可用载具。

### v7560 新增系统
- [2026-08-25 | pv7560] **平常 locomotion 动画源** (走路姿势替换依据): MovementServiceClient 平常状态读 `ReplicatedStorage.Animations.Movement` 文件夹 — MaleWalk/FemaleWalk (走) + MaleRun/FemaleRun (跑, 按 PlayerData.Gender 选) + Idle1/Idle2 (待机, Core 优先级)。战斗状态另用格斗风格文件夹 (`Animations.Combat.<Style>Anims` 的 Walk/Idle, 玩家实测风格=Hakari)。**本地改这些 Animation 实例的 AnimationId → 本客户端 MovementService 加载播放 → FE 复制全服可见**, 改属性即时生效无需绕实例缓存。游戏原生 Animate LocalScript 被禁用清空 (Enabled=false 无子实例), 标准官方替换法不适用。
- [2026-08-25 | pv7560] **超人飞定格正解** (社区 b4-st/Superman-Fly 源码逆向): 飞行动画不循环播而是 `AdjustSpeed(0)` + `TimePosition=0.5` 冻结在最佳帧; 配合 `Humanoid:SetStateEnabled(所有状态,false)` + `Animate.Enabled=false` 彻底接管关节。UGC emote 型动画循环播放必有接缝, 定格才是"保持动作"的正解。
- [2026-08-25 | pv7560] **Spec 统一能力框架** (SpecConfig.Specs): lasereyes / sandevistan / ssjblue / ultrainstinct, 各 Apply/Revert。SpecServiceClient 统一调度。
  - **Sandevistan** (新): Y 键切换, 自己 4x 速 (MaxSpeed=56), 其他玩家被时停 (SlowTimeScale=0.12), 上限 30s, CD 0.35s。
  - ssjblue: X 变身 + R 蓄气波, 3x 伤害 / 1.6x 速 / 3x 血。
  - ultrainstinct: X 变身 + Q 瞬移背后 + R 气弹, 激活期间无敌。
  - lasereyes: X 开眼 + 左键双光束。
- [2026-08-25 | pv7560] **Sandevistan 权威归属**: SandevistanClient (884 行) 纯视觉; `SpecTimeSlowed` attribute 由服务器写入被时停者 Character, M1/M2/Block/Evasive 四模块全部检查它并拒绝输入 = 时停中敌人无法攻击。无限时停 L1 做不到; 但"目标带 SpecTimeSlowed"可当安全输出窗口读出来用。
- [2026-08-25 | pv7560] **校报摄影打工** (SCHOOL NEWSPAPER): JobListingShared key="SchoolNewspaper", MaxSlots=3。协议全走 `PhotoJobSubmit` RemoteFunction: `"Start"` 接班 / `"Submit", cameraCFrame` 交照片 / `"Stop"` 下班。服务器校验相机 CFrame 的距离 (区域 200/地标 160/玩家 120 studs) + FOV 半角 42° + 目标在框内。提交 CD 1.5s, 任务时限 180s, ¥90/张 + streak bonus 18/次 (max 90)。任务 3 类: Area(权重3)/Landmark(tag=`PhotoJobLandmark`, 权重2)/Player(权重5)。私服禁用 (DISABLED_ATTR)。**自动化 L1 可行** — 客户端只发 CFrame, 计算对准目标的朝向发包即可; AnalyticsConfig 已把 PhotoJobPay 列为正式经济流。
- [2026-08-25 | pv7560] **卡拉OK系统**: KaraokeService 含 ServiceClient/AudioClient/JukeboxClient/Config, UI 用 PanelKitV2。场地 Workspace.Karaoke (屏幕 -6.8, -262.4, -130.5)。"Karaoke Center" 新地点入绿区 + 专属声学 (Karaoke_HirobaLounge 带 Reverb)。点歌机模式。
- [2026-08-25 | pv7560] **GakuranBallService** = 球类运动服务 (篮球域), `IsSportsLocked` 状态锁被 AirHockey/Arcade/ArmWrestling 等 Utils 引用作互斥; remote = Remotes.GakuranBall。

---

## L2 手段登记 (危险功能对抗手段台账)

<!-- 每条: [日期 | pv<N> | 功能名] 手段/目标/验证/信号特征 -->

## 反作弊

### [2026-08-25 | pv7560 | dump-anticheat-hooks 实测]
- DataModel 元表 __index/__namecall/__newindex 全 C 原生闭包, 无 Lua hook, 无注入连接, 无可疑无源监听。
- 反作弊是**行为级**而非元表级: bootstrap 后销毁 Shared.Services 防逆向 + 关键判定全在服务器 (grapple 胜负/打工计时/摄影命中/Sandevistan 时停)。L1 人类化设计即可。

---

## 可复用代码片段

<!-- 已验证的 send/listen/buffer 片段, 注明依赖条件 -->

```lua
-- 校报摄影打工提交 (pv7560 验证协议, 依赖 Remotes.PhotoJobSubmit RemoteFunction 存在)
local rf = game.ReplicatedStorage.Remotes:WaitForChild("PhotoJobSubmit", 10)
rf:InvokeServer("Start")                      -- 接班
-- ... 对准目标后:
local result = rf:InvokeServer("Submit", workspace.CurrentCamera.CFrame)  -- 返回 "Accepted"/"TooFar"/...
rf:InvokeServer("Stop")                       -- 下班
```

---

## 待复核 (placeVersion 变更后移入)

<!-- v7538 结论待后续版本复核项: Services 销毁机制是否仍如此 / WingChun 数值 / 打工参数 -->
- [待复核] Services 销毁机制 (v7538 结论, v7560 未重验)
- [待复核] WingChun/Mystery gacha 数值 (v7538 结论, v7560 Config 里 CombatStyleRarityConfig 仍在但数值未比对)
- [待复核] 传统打工 (GAKUMART 等 4 雇主) 参数

## 已证伪
