---
genre: dungeon
games: ["dungeon-raiders", "dungeon-quest-reborn"]
updated: 2026-09-05
---

# 地牢类游戏套路库

> 从 dungeon-raiders (深度逆向) + dungeon-quest-reborn (中度逆向) 提炼。下一个地牢/副本类游戏进逆向前先通读本文件。
> 单游戏专属细节 (具体服务名/坐标/职业数据) 不在此收, 看案例索引指向的档案。

## 逆向套路 (进新游戏先跑这个流程)

1. **反作弊侦察**: `dump-anticheat-hooks scanConnections=true` — 两家地牢游戏实测均**无主动客户端反作弊** (元表全 C closure) (来自两者)。但伤害判定在服务器, 客户端改值必被回滚。
2. **通信架构三分类 (第一步)**: 把全部 remote 分成三类再动手 — ① 业务动作 (RF/RE: 进本/拾取/选箱/商店) ② **战斗输入** (常独立成夹, 如 `Inputs.*` / Tool 内事件) ③ 数据同步 (Replica/属性回写, **别当业务 remote 去 Fire**) (来自两者; dr 是 Knit 架构 + 战斗独立, dqr 是扁平具名 remotes)。全 RS remote 几百个, 不分类必迷路。
3. **确认伤害权威**: 技能/普攻发包通常**无目标参数** (空调用或只带方向/槽位), 服务器按装备数值算伤害 — 别找"指定目标"的参数, 不存在 (来自两者)。
4. **技能数值客户端可读**: 技能判定盒/CD/充能放共享模块 (`RS.Classes/<职业>/Skills` / GameInfo 表 / Tool 内配置), **require 只读数据不执行 Activate 就能拿到服务端权威数值** — 杀戮光环距离/自动技能全靠它 (来自两者)。
5. **场景状态看属性**: 玩家 attribute (`InDungeon`/`CurrentDungeon`/难度) + workspace 状态值 (波次/开关) 区分大厅 vs 局内; 功能开发要明确"这个 remote 只在大厅图/只在局内有效" (来自两者)。
6. **GM 样子的 RF 别调**: `AddXP`/`SetLevel`/`GrantCurrency`/`GrantProduct` 类名字好看, 调了污染画像, 权限门都在服务器 (来自 dungeon-raiders)。

## 协议模式

- **战斗输入夹**: 攻击=方向向量 (Vector3), 技能=槽位+tap/hold+方向, 拼刀=空参, 格挡=start/stop — **方向必须发指向目标的真实单位向量, 禁止 zero 向量** (来自 dungeon-raiders; dqr 空参形态是简化版)。
- **连发节奏下限 = 游戏原生 0.1s/次**: 持按攻击客户端本身就是每 0.1s 发一次, 脚本别更快 — 高频没收益还加画像 (来自两者)。
- **服务端权威冷却回写**: 剩余 CD 存在 attribute/Value (`SkillN_Charges`/`cooldown.Value`/`*_Cooldown_Active`), 客户端只读不写 (来自两者)。
- **结算链**: Boss 死 → 结算 UI 事件 (RE) → 选箱 RF → Replay/Return RF; 重开/回城按钮的对应 remote 在 HUD 控制器里反编译可得 (来自两者)。

## 功能配方

- **杀戮光环 (L1)**: `CollectionService:GetTagged("Enemy")` (dr) 或敌人容器遍历 (dqr) → 过滤 `IsDormant`/距离 → 发游戏自身攻击包, 间隔 ≥0.1s。切目标后留 ~0.12s settle 再发, 否则服务器按旧位置判空 (来自两者)。
- **站位约束 (全屏命中前提)**: **禁止直挂敌人头顶** — 武器 hitBox 是前方扁盒 + `lookAt` 近垂直有奇点。正确姿态: 水平距 ~3stud + 抬高 ~2stud + 平视目标 (来自 dungeon-quest-reborn); 近战职业进房中心清怪, 远程职业 (档案 `Ranged=true`) 拉到射程 ~58% 站桩 (来自 dungeon-raiders)。
- **自动喝药**: 直接调服务 (如 `PotionService:UsePotion(1)`), 不模拟按键; 冷却服务端权威; 补药"涨停即 skip" — 灌到本局上限 (数量不变) 就走, 别死等属性上限 (来自两者)。
- **自动开始/重开**: **同名按钮不同 remote** — 世界内 START 按钮和组队大厅的 Start 是两个协议, 必须反编译按钮所在 LocalScript 确认, 别凭名字猜 (来自 dungeon-quest-reborn 证伪教训)。
- **Boss 自动拼刀 (L2)**: 读 Boss 动画/Hitbox 时机, 发游戏自身 `Parry` 包; 只对精英+Boss 拼, 小怪不拼; 拼刀窗 = 职业档案 `ParryDuration` (+装备/buff 加成) (来自 dungeon-raiders)。
- **自动寻路**: 房间结构 = `Room_N` (Entry/Exit 连接器 + Zone), 沿主链 Exit→Entry 走; 关着的门本地关 CanCollide 穿过; 岔路小房按"无刷怪点且窄"排除 (来自 dungeon-raiders)。

## 已知坑 (该类型跨游戏反复踩的)

- **模拟按键不触发 UserInputService**: keypress 合成输入 fired=0 — 自动攻击/技能/喝药**必须 FireServer**, 不能靠模拟按键 (来自两者; 注入器层通用, 但地牢类最依赖此结论)。
- **换图/换服拆 DataModel**: Replay/Return/大厅↔地牢走传送 → 全部连接/缓存失效, 必须重注入; 局内下一房间不传送。兜底 = 注入器 autoexec (来自 dungeon-raiders)。
- **没进房的怪是休眠的**: `IsDormant=true` 时不掉血不攻击 — 自动战斗先推进房间/唤醒再锁定 (来自 dungeon-raiders)。
- **进度条会提前跳格**: 顶栏完成度在清完倒数第二房后就贴到 Boss 格, 人还没进去 — 判定"已进 Boss 房"看 `Spawns.Boss_Spawn`, 不看进度 UI (来自 dungeon-raiders)。
- **死亡回上一间重生**: 局内死亡回上一战斗房, 旧路点/进度状态必须对齐当前房, 否则沿穿墙路点卡死 (来自 dungeon-raiders)。
- **传送位置多半服务端校验**: 别写 CFrame 超距瞬移清图, 走 `UsePortal` 类游戏自身路径; 位置类功能设计成"贴身平移"而非跨房瞬移 (来自两者)。
- **Craft/Require 差异**: 同一仓库里有的技能模块 require 成功、有的返回空表 (纯 Activate) — 判定数据拿不到就 decompile, 别硬猜 (来自 dungeon-raiders)。

## 案例索引

- **dungeon-raiders**: `games/dungeon-raiders/intel.md` — 全类型最完整参照: Knit 全服务清单/战斗输入协议逐参核对/职业档案库 (8 职业判定表)/自动寻路/拼刀/SpecialBoss 召唤。含"看起来能调实际必拒"的 RF 黑名单。
- **dungeon-quest-reborn**: `games/dungeon-quest-reborn/intel.md` — 服务器权威伤害判定链/技能触发链 (按键→Tool→remote)/自动开始协议修正 (同名按钮证伪)/全屏命中站位几何约束。
