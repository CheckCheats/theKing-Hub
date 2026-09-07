# 地下城战利品者 TheKing HUB — 开发手册 (DevLog)

> 维护铁律: **每次开发会话收工前必须追加一条**, 写给下一个接手的 AI 和未来的自己。
> 与 changelog.md 分工: changelog 面向用户记"发布了什么"; 本文件面向开发者记"怎么做的、为什么、验证结果、遗留问题"。
> 接手 AI: 只读本文件最后一条 + intel.md 相关分区, 即可恢复上下文, 禁止凭空猜测前人意图。

## [2026-09-07 | 会话55 | v1.30.17] 秒杀后恢复攻击

**用户**: 水晶没打完 BOSS 秒杀后脚本发呆不攻击. 做好后不注入, 推仓库.

**根因**: ① 水晶阶段禁止一切闪避, 超时全图地板直接秒杀. ② `inRaid` 只认 `InRaid`, 死后属性一翻就不再锁 Raid_NPCs (水晶/BOSS 无 Enemy 标签), pick 空转. ③ 死时 `skillBusyUntil`/`lock` 不清. ④ 失败常进 Spectate_Info 而不是 Completion_Info, 自动重开等不到 atEnd.

**改**: `raidRecover` 死后 wipe + LeaveSpectate + (自动重开且观战/结算才 replayRaid); `inRaid` 加图名和 Raid_NPCs; 水晶只躲盖脚全图地板; 机制锁不上回落 BOSS. 本版不注入.

## [2026-09-07 | 会话54 | v1.30.16] 水晶不闪、清光小弟再打 BOSS

**用户**: 有水晶不要闪避; 不要锁 BOSS, 先打完 4 个水晶再打 BOSS; 有小弟必须把所有小弟杀完.

**改**:
- `raidMustDodge` / `tickAoeDodge` / 远程风筝: 场上有水晶或小弟一律不闪
- `raidTarget`: 有小弟只锁小弟(最近一只循环到清光); 没小弟才锁水晶; 不锁罩、不锁 BOSS
- `pick` / `raidTick`: 还有水晶或小弟时禁止 `raidBossWrap`

**遗留**: 连环地板只在没水晶没小弟时绕中心躲. 罩不主动打.

## [2026-09-07 | 会话53 | v1.30.14] 活动重开不再进塔

**用户**: 自助活动副本, 爬塔自动重开关着也会被重开进爬塔.

**根因**: `tickTowerReplay` 挂在「自动重开」不是「爬塔自动重开」. 结算 `InChallenge` 或点 `ReplayButton` (HUD Source=Challenge) 都会 `ChallengeRunService.RequestReplay`. 粘滞还曾被 InChallenge 清掉.

**改**: `Nav.raidLocked` 90s; 禁止 InChallenge 单独当真爬塔; 活动重开只 Knit DungeonRunService; 所有 Challenge 发包走 `replayChallenge` 先过锁.

## [2026-09-07 | 会话52 | v1.30.13] 结算点 Replay 按钮 + 躲圈不回头

**用户**: 重开还是进爬塔; 连环炸不要走已经走过的路.

**重开**: `DungeonRunService.RequestReplay` 无 HUD Source 时服务端可能开成塔. 改点 `Completion_Info...ReplayButton:Activate()`. `isTowerRun` 去掉 `Challenge_NPCs` 兜底. `_raidSticky` / 结算后 40s 禁止塔重开与快刷.

**躲**: 10 格格子脚印, 8 方向里挑踩过最少的.

## [2026-09-07 | 会话51 | v1.30.12] 水晶不闪 + 多小弟先清

**用户**: 识别到水晶一直闪避, 严重影响输出; 很多小弟要优先打, 不然 BOSS 回血.

**闪**: `raidChaseFloor(..., cover=true)` 把未亮的 BOSS `AoE_Telegraph` 当活圈, 1³ 强制 36 格, 人在场内必 `n>=1` → 跳过水晶+心跳 Dash.

**改**: 水晶阶段必须粒子亮且圈心离 BOSS>14; 谨慎避战不再扫 BOSS 预警. 小弟≥2 锁小弟 (prio 0), 罩/水晶让路.

## [2026-09-07 | 会话50 | v1.30.11] 躲圈离点 + 结算不再进塔

**用户**: 躲避太傻还会被炸死; 重开还是进爬塔.

**躲圈**: `AoE_Telegraph` 是 BOSS 身上 1³, 粒子才是圈. `raidFlee` cover=false 要求离 BOSS>12, 连环砸脚等于不认圈, 只绕 18 格且 need>0 才 Dash. 现倒计时/盖脚用 cover, 默认半径 36, 心跳闪避离点 32 格.

**重开**: `isTowerRun` 只看 `Challenge_Dungeons` 无 Generated → 教堂结算必真. `tickTowerReplay` 调 ChallengeRunService. 现爬塔认 `InChallenge` / Double Dungeon 名 / `Challenge_NPCs`. 结算粘滞不清在 Challenge_NPCs; Raid DungeonComplete 1.2s 后无条件 `DungeonRunService.RequestReplay`.

## [2026-09-07 | 会话49 | v1.30.10] 有水晶不因倒计时乱跑

**用户**: 有水晶也会乱跑躲避; 问 Damage Crystal 识别是否做好.

**根因**: ① `raidMustDodge` 在 `hasCrystal` 时把每阶段都亮的倒计当躲圈信号, 直接 `_raidSkipCrystal` 满场跑, 水晶根本不砸. ② 只扫 `Raid_NPCs` 第一层且 `raidWrap` 必须 HRP/PrimaryPart — `Damage_Crystal` 若挂子级或没有 Humanoid 就 `hasCrystal=false`, 再被连环炸逻辑清锁乱跑.

**改**:
- 名认 `Damage_Crystal` / `Damage Crystal` / 含 crystal, 排除 `Crystal_Spawn`
- 子级扫描 + 无 HRP 用任意 BasePart 当锁点
- 有水晶: 只在圈盖到人时才躲并跳过水晶; 否则锁水晶打

**验证**: check_hub + 热替换; 场上有水晶时应贴水晶输出, 不绕圈.

## [2026-09-07 | 会话48 | v1.30.9] 打不破的罩不挡连环躲

**用户**: 连环炸判断还有问题; 罩能打但打不破、不显示血条.

**根因**: raidDomeHit 把无血条 Protective_Dome 当 hitDome, mustDodge 直接否.

**改**: 连环地板不再看罩. 只在 hasAdd 时锁罩; 其它时候当装饰, 打 BOSS.



**用户**: 放小弟的阶段优先攻击保护罩.

**现场**: `Raid_NPCs.Protective_Dome` 是独立 Part. 旧顺序水晶>罩>小弟, 水晶还在时会先砸水晶不破罩.

**改**: hasAdd 时罩 prio=0; 扫 Descendants 防罩挂在子级.



**用户**: 放水晶阶段若水晶没打完会放可躲的全图地板; 放完这阶段结束, 不用再打水晶.

**改**: 有水晶 + (倒计时亮 或 圈盖到人) → 躲, `_raidSkipCrystal`. raidTarget 跳过水晶改锁 BOSS. 切 PHASE 标题才清跳过.



**用户**: 每阶段都有倒计时; 排除「有小弟 / 有水晶 / 罩能打」才是连环地板. 非躲地板要主动打 BOSS.

**改**: raidMustDodge = Phase_Countdown.Enabled 且无 add/crystal/可打罩. 无敌罩 (CanAttack=false) 不挡. pick/raidTick 无机制时锁并走近 BOSS.



**用户**: BOSS 秒杀时除无敌罩外, 头顶有红色 10s 倒计时; 能认这个就别用干扰战斗的躲法.

**现场**: `Raid_NPCs.Dark Professor.HumanoidRootPart.Phase_Countdown` BillboardGui. 秒杀窗 `Enabled=true`, 子级 `CanvasGroup.dmgLabel` 红字 `10s`→`1s` (255,90,90). 平时 Enabled=false (残字 1s 不能当信号).

**改**: `raidMustDodge` 只认该 Billboard Enabled. 亮着才跑/闪; 灭了锁回机制/BOSS.



**用户**: 开了还是一直乱跑; 只要新阶段识别到 BOSS 放玩家跟踪地板爆炸才跑.

**根因**: raidMustDodge 把 SURVIVE/任意圈当满场逃, 没圈还随机 22 格; 1.30.3 把 GroundEffect 也算进落点.

**改**: PHASE≥2 或 HUD SURVIVE 才允许躲; 只认圈心贴玩家且离 BOSS>12 格 (点名落点/Grenade). 没圈不 MoveTo.



**用户**: 深度分析活动 BOSS; 自动重开结算后进玩不了的爬塔.

**活动机制 (钾 require+反编译, Impossible 1亿血)**:
- 四技能全是身前 QueryHitbox (Range 35, 盒约 40³), 特效挂 BOSS `Telegraph_Root`, **不是**随机落点圈. 1 暗矢 / 2 砸地 / 3 五连符雨 / 4 五连崩塌. 大招 Final Examination 8s 每 0.35s 在 80 格内点名.
- HUD Title 默认 `PHASE N`; Complete/Failed 才关画布. RaidRunService **没有** RequestReplay, 只有 GetSessionState/RequestReturn/LeaveSpectate.
- 官方 Replay: Source=BossRush→BossRushService; Challenge→ChallengeRunService; **其它含 Raids→DungeonRunService**.

**重开串塔**: 活动房 `Challenge_Dungeons` 常驻 + 无 Generated_* → isTowerRun=true; isBossRush 被 InRaid 挡掉 → tickTowerReplay 调 ChallengeRunService.

**改**: Nav.isRaidRun (含结算粘滞) 一票否决塔/BossRush; 结算走 DungeonRunService; 听 RaidRunService.DungeonComplete. Grenade 圈读写字段对齐.



**用户**: 脚本还是有问题, BOSS 放技能红圈就乱跑.

**根因**: v1.30.1 任意亮着的 AoE_Telegraph 都 raidFlee. BOSS 技能圈挂在自己 Telegraph_Root, 默认半径还按 22 算, 一放技能就清锁满场跑.

**改**: 只把「落点离 BOSS>14 格 / 不是 BOSS 身上 / meteor·grenade」当连环地板. 技能脚下圈不进 mustDodge. 谨慎避战也不再扫 BOSS 自己的预警.


**用户**: 自助活动新阶段连环地板不躲红圈, 还锁无敌 BOSS.

**根因**: v1.29.2 要求 SURVIVE 或 ≥2 个 xz≥8 的圈, 且祖先是 Dark Professor 直接丢掉. 真圈是 BOSS 上 `Telegraph_Root.AoE_Telegraph` 1³ 块, 粒子亮才是预警; `SpellTelegraphs` 常空; pick 没机制目标就回落到普通光环锁 BOSS.

**改**: 扫 Raid_NPCs 预警; 1 个亮圈即躲; 圈内 Dash; 有圈不锁 BOSS. 谨慎避战 collect 也扫 Raid_NPCs.


**用户**: 挂自动重开; 仅普通地牢; 一间 10 分钟打不完就卡死, 用 Roblox 自带重生刷新位置.

**改**: `Nav.tickRoomStuck` 跟 `dr_auto_replay`. 进度键 = 顶栏格号 + 星星数 + Room 名, 600s 不变则 `hum.Health=0` (等同菜单 Reset Character). 排除塔/BossRush/InRaid. 45s 防连杀. 5 分钟原地 Replay 看门狗仍在.

**发布**: `publish.py --game dungeon-raiders --no-class-archive --push` → Gitee master `752b15c` (manifest v1.30.0, obf ~531KB). 未重推 Loader.



**用户**: 顶部进度条星星图标代表房间完成.

**对照**: `Completion_Progress.List.ZoneSlot.Completed` (图 `72072883813318`) Visible=true 就是那颗星. Treasure/Boss 是格类型, Current 是指针. 现场第 1 格星星亮, 其余未亮. `Nav.uiCleared` 已读这层, 仍未接寻路.


**结论**: 能, 分两层。当前遭遇用 `Info.Mob_Counter` 剩余怪; 整图用顶栏 ZoneSlot.Completed。不能当 Room_N 一对一对齐, 也不能读关掉的 Objective 残字。未改 hub。

**现场** Mage `Generated_Mage_bdb9d3e6` Room_17: Info 开着 Enemies Left=27; 150 格内活怪 0。Completion_Progress 10 格, #1-2 Completed, Current 贴 #3。图上 Room_*≈28。Objective_Frame 关着但字是 ROOM CLEARED。房间无 Cleared 属性。


**用户**: 又卡拐角; 卡住时其实往前走几步就可以.

**现场** Mage Room_21: Entry/Exit 在 Connectors 下 (roomClass 用 FindFirstChild 找不到). Zone 82×78 被当成战斗房, 绿线走到 AABB 中心 (内拐). 路走完 hallKey 还在, MoveDirection=0, 人贴 +X 墙. 出口在 -X, 沿主轴顶 12 格就能进西臂.

**改**:
- L 房不当战斗房、不居中
- roomClass 走 Nav.conn
- 卡住 / 路完但离 Exit 还远 → `nudgeForward` 沿出口主轴 12 格
- wallAhead 30→8, 不再把远处内拐墙当挡路
- elbowPoint 优先外拐且两段射线通


**用户**: 自动重开不会重开爬塔了.

**现场**: Double Dungeon, `isTowerRun=true` 且 `isBossRush=true` (`Boss_Rush` 模板常驻). `tickTowerReplay` 先判 BossRush 直接 return, ChallengeRunService 永不调用.

**改**: `Nav.isBossRush` 只认 `InBossRush` / `CurrentDungeon=BossRush` (仍排除 InRaid).

## [2026-09-07 | 会话35c | v1.29.2] 光环打 BOSS 变傻

**用户**: 自助开着, 光环打 BOSS 变傻.

**根因**: SpellTelegraphs 里 BOSS 自己的预警圈 xz≥6 被当成连环地板, 一直清锁乱跑; `CanAttack=false` 时拒锁 BOSS (现场掉血时这个属性仍是 false).

**改**: pick 只在水晶/罩/小弟时抢锁; 躲圈要 SURVIVE 或 ≥2 枚炸弹圈; 远程风筝仅在躲圈/打机制时让路.

## [2026-09-07 | 会话35b | v1.29.1] 地板炸清锁

**用户**: 躲地板时仍锁无敌 BOSS, 走进连环圈被秒杀.

**改**: `Cbt.raidMustDodge` 认 SpellTelegraphs/MeteorZones 大圈 + SURVIVE, 锁存 2.2s; `raidFlee` 背离圈; pick/平A/走位全部停.

## [2026-09-07 | 会话35 | v1.29.0] 自助活动BOSS

**用户**: 活动 Raid 加开关, 放技能光环下方; 阶段号与机制不一一对应 (2/4 都可能出小弟+水晶)。

**现场**: `InRaid` + `CurrentDungeon=The First Test`, BOSS Dark Professor, 图 `Boss_Rush.Maps.Church_Room`, 怪在 `Raid_NPCs`. HUD `Timer_Canvas.Raid.Title` = PHASE N / SURVIVE. `GetSessionState`: RaidPhase 1-4, Phase=Combat. Extreme 6500万. PHASE2 见过 Protective_Dome + Mage Student×4; BOSS 无 Humanoid, 血走 HUD/BossHealthUpdate.

**改**: `Cbt.raidTarget` 优先级水晶>罩>小弟>BOSS; SURVIVE 清锁+绕走; 出手仍靠平A/技能光环. `isBossRush` 排除 InRaid.

**版本**: 1.28.0→1.29.0 MINOR. 需开「自助活动BOSS」+ 平A或技能光环.

## [2026-09-06 | 会话34 | v1.27.0] L 走廊 Z 字拐点 + 编译坑修复

**用户**: L 走廊一直卡死 + 自动执行最新代码。

**核心改动**:
- `Nav.computePts` 长距离 (>25格) 强制沿主轴 55% → 从轴 30% → 从轴 85% → 主轴 75%, 4 点拐角不走直线撞墙
- `Nav.detLCorner` 检测前方墙+左右空, 主动插拐点
- 3s 不动跳 idx, 不清 pts (让 bumpStuck 自然 reroute)
- `Nav.currentRoom(hrp)` → `getCurrentRoom()` 修 nil 引用

**关键调试经验 (反复坑)**:
1. 几次 v1.24~v1.27 改完自认为热替换成功, 实际 hub.luau 末尾 `task.delay(0.8, function() ... end)()` **缺一个闭合 `end`**. 编译器报 `:9408: Expected 'end'`, 但 line9408 看起来已经是 `end)()`. 真正问题是 IIFE 主壳的 `end` 被吞掉, 内部 task.delay 闭包的 `end` 不存在 → 解析器找不到 IIFE 的 `end`.
2. **正确闭合**: `end)` 闭 task.delay function, `end)()` 闭 IIFE. 合并写为 `end)end)()`.
3. 钾 autoexec 用 tag 判重, `DR_HUB_v<version>` 跟代码绑定, 每次都要 deploy + sync.
4. 部署时注意行尾统一 LF, 避免 \r\n 错乱.

**验证**: 编译通过, `[RCWTK] DR_HUB_v1270 loaded` 打印成功. 热替换进游戏.

**遗留**:
- [ ] `dr_auto_nav` 80~94ms (>33ms) — 寻路函数 + 8 raycast 计算量大, 待降频
- [ ] `SenseWalls` 缓存需实测角色快速移动时仍准确
- [ ] BossRush 重开 (DungeonComplete RE) 待局内实测 Phase 字符串拼写

**版本**: 1.26.0→1.27.0 MINOR. 增量 ~150 行.

## [2026-09-06 | 会话33 | v1.26.0] 防发呆 + 墙体感知 + tag 同步

**用户**: 自动执行每次都是最新; 普通地牢不卡死发呆; 寻路感知墙体。

**问题根因**:
- `DR_HUB_v1231` tag 硬编码, 钾 autoexec 一直认为同一版本, **新代码根本没在游戏里跑** — 看起来卡死其实是旧代码的问题
- `Nav.tickPath` 没有全局发呆检测, 单个 watchdog (stuckT/moveAt/idx跳) 之一超时, 但**所有 watchdog 同时失活** → 永远不出
- `Nav.wallAhead` 只单方向前方 4.4 格, 复杂地形 (L 形墙、U 形死胡同) 看不到

**改**:
1. `deploy_dr.py` 自动同步 `DR_HUB_v<版本号>` tag + mtime 检测, --check 显示 STALE 警告, 写临时文件避免半截状态
2. `Nav.senseWalls(hrp, radius)`: 8 方向 (前后左右 + 4 对角) raycast 角色周围, 1s 缓存, 返回每方向距墙最近距离
3. `Nav.bestSidestep(hrp, dir)`: 基于 senseWalls 选最优侧滑方向 (左右都 >4 格不侧滑)
4. `walkTick`: 发 MoveTo 前 senseWalls; 前方 <3 格被堵 + 距目标 >5.5 → 跳 idx
5. `tickPath`: 全局发呆 watchdog — 30s 无位移 → forceClear 当前房 + 重路由

**关键调试经验**:
- 之前几轮 v1.24.0 → v1.25.0 → v1.26.0 自认为热替换成功, 实际 **tag 未变**, 钾一直跑 v1.23.1 旧代码
- 任何"卡死"问题先确认 hub 真的更新了 (`grep DR_HUB_v` 控制台)
- 部署脚本必须同步 tag, 否则用户看不到效果以为改错了

**验证**: 静态门过 (峰值 194 不变); 热替换 `@1.26.0` 成功, 控制台确认 `DR_HUB_v1260 loaded`; tag 自动同步生效.

**遗留**:
- [ ] `dr_auto_nav` 单次 84ms (>33ms) — 下次降频优化 (0.18s tick + raycast 8 方向可能过重)
- [ ] 8 方向墙体感知在角色移动中 1s 缓存可能错过快速墙体变化 — 待跑
- [ ] 30s 全局 watchdog 在等门 / 等祭坛 时会误触 — 阶段 phase=door_wait/altar 应当豁免 (留给下版)

**版本**: 1.25.0→1.26.0 MINOR。增量 ~150 行。

## [2026-09-06 | 会话32 | v1.25.0] 房间模式识别 + 智能寻路

**用户**: 寻路知道每个房间的游戏模式 → 优化智能性、准确、迅捷、路径点优化。

**房间分类 (Nav.roomClass)**:
- `start` — Start 房 (Player_Spawn, 大 Zone 无 Spawn)
- `combat` — 战斗大房 (Spawns.Enemy_Spawn)
- `corridor` — 走廊 (Zone < 70)
- `loot` — 战利品房 (`IsLootRoom=true`)
- `boss` — Boss 房 (Spawns.Boss_Spawn)
- `special_boss` — 特殊 BOSS 房 (`IsSpecialBoss=true`)
- `locked` — 锁定房 (`IsLocked=true`)
- `altar` — 祭坛房 (Spawns.Altar_Spawn)
- `checkpoint` — 检查点房 (`IsCheckpointRoom=true`)

**改**:
- `Nav.roomClass(room)`: 属性优先 (服务端权威) → Spawns 子级 → Zone 大小, 单一判定
- `Nav.classifyRooms()`: 一次性全图分类, **2s 缓存**, 替代每次 tick 全扫描
- `Nav.nextHop/nextCombatFrom`: 过滤 `locked`/`corridor`/`loot` (loot 房有 ParentRoomIndex, 不作主链目标)
- `tickPath`: locked 房 forceClear+跳过 → 阶段 `skipping`; checkpoint 房停下等决策 → `checkpoint`
- `nextHop` 路径断时: 用 `nextCombatFrom` 反向推到下一间可战斗房, 避免"主链走到尾停住"
- 战斗超时: special_boss 300s, boss 240s, altar 30s, 普通 60s

**性能**: 寻路函数峰值 194 → **118** (分类缓存 + 短路判定 + 收紧 nextHop 扫描).

**验证**: 静态门过, 寄存器峰值大幅下降. 热替换待跑.

**遗留**:
- [ ] Mage OpenWorld 房间结构可能不走 Room_N 命名, 需进局实测 `Nav.roomClass` 能否识别
- [ ] checkpoint 房决策 (Continue/Extract) 当前只停顿, 未自动化 — 等 EndlessDecision RE 监听接入
- [ ] Special_Boss 房清怪超时 300s 偏激进 — 实测 Demagios 105w 血单刷时间

**版本**: 1.24.0→1.25.0 MINOR。增量 130 行。

## [2026-09-06 | 会话31 | v1.24.0] BossRush (BOSS爬塔) 独立支持

**用户**: BOSS爬塔和普通爬塔是两种模式, 重开不能共用 (会路由错), 寻路要找 BOSS 打 (不是波次怪)。

**为什么独立**:
- BossRush: `DungeonRunService.RequestReplay()` (服务端按当前会话重开同模式)
- 普通爬塔: `ChallengeRunService.RequestReplay()` (走波次挑战图)
- 跨服务调 → 服务端按 RF 注册路由, 错调 → 直接进错对局
- BOSS爬塔每层只有一只 BOSS, getEnemies() (Enemy 标签) 已自动找到; 复用普通爬塔箱逻辑会浪费循环在没箱的房

**改**:
- `Nav.isBossRush()`: workspace 无 Generated_* + 有 Boss_Rush 容器
- `Nav.replayBossRush()`: 100% 走 DungeonRunService, 绝不允许 ChallengeRunService 路径
- `Nav.tickBossRushFight()`: 0.3s 扫 Enemy 标签 BOSS, 走近至 engage 距离; 无 BOSS 时复用箱扫描 (含 Boss_Rush 根)
- `Nav.tickBossRushReplay()` / `Nav.tickBossRushSpeedrun()`: 独立函数, 走 DungeonRunService.GetSessionInfo (CurrentFloor/Lives/Phase)
- `Nav.tickPath`: BossRush 早退改走 tickBossRushFight (原 isTowerRun 早退会卡 BossRush)
- `Nav.tickTowerReplay/Speedrun`: BossRush 早 return 让路, 严禁共用

**关键隔离点 (踩过坑)**:
1. 之前一版写过 `Nav.replayReq()` 二选一路由 (isBossRush ? DungeonRun : ChallengeRun), **错**. 服务端按 RF 注册路由, 同帧状态切换可能拿到错的实例. 撤销, 改独立函数.
2. `Nav.tickPath` 里 `isTowerRun` 早退 → BossRush 永远走箱逻辑 → BOSS 不被寻路锁. 必须独立早退判断.

**验证**: 静态门过 (峰值 194 不变); 热替换 `@1.24.0` 成功, `DR_HUB_v1240 loaded`, 无 compile error / index nil.

**遗留**:
- [ ] BossRush 局内实测: 进 100 层 BossRush 走 5~10 层确认 isBossRush 判定稳定 (Boss_Rush 容器不在 Loading 间隙消失)
- [ ] GetSessionInfo 返回 boolean (当前不在 BossRush 局), 局内实测 Phase 字符串 ("Active"/"Defeat"/"Complete") 服务端实际拼写
- [ ] tickBossRushFight 远程职业 (但丁/Sinister Trigger) kite 逻辑未覆盖 — 当前为通用近战贴脸, 远程可能站位出错
- [ ] chestIntermissionTime=8 在 BossRush 箱阶段是喘息期, 寻路此时应锁 BOSS 不是拾箱 — 待实测调整优先级

**版本**: 1.23.1→1.24.0 MINOR。增量 70 行, 不动既有结构。

## [2026-09-06 | 会话30 | v1.23.2] E 键交互让路

**用户**: 用户操控除了 w/s/a/d 移动要暂停寻路, 按 e 交互也要暂停。

**改**: `Nav.userDriving` 的 keys 表加 `Enum.KeyCode.E`。E 长按 → 持续让路；松开 → `yieldIfSteer` 已有 0.45s 收尾自动覆盖。

**验证**: 静态门过 (峰值 194 不变)。热替换 `@1.23.1` 成功后控制台 `DR_HUB_v1231 loaded`, 无 `index nil`/compile error。

**版本**: 1.23.1→1.23.2 PATCH。一行改动, 不动结构。

**遗留**: 没加 InputBegan 单帧让路兜底, 靠 `IsKeyDown` 在 5Hz 轮询下的命中 (WASD 已验证同逻辑无漏帧)。若用户反馈快速点 E 偶尔抢断, 再加 `InputBegan` 强制让 0.8s。

## [2026-09-06 | 会话29 | v1.23.1] 空地直线 + 停反复重算

**用户**: 路点太密、空地 Z 字; 随后又反复寻路、卡住。

**根因**:
1. stitch/centerLane/半径2 PFS 在空地把直线拆成折线
2. 门口大战场 Zone ∩ 过廊 Zone, `getCurrentRoom` 每帧切房 → hallKey 变 → 绿线重画
3. 走到终点 pathLive=false 立刻按同一目的再规划 → 死循环
4. 离路 dropRoute 清 hallKey → 下一 tick 再规划

**改**: 直线通就两点; 当前房粘滞; key=`to:下一房`; 距目的 <12 不再建路; 离路只 snap idx。

**版本**: 1.23.0→1.23.1 PATCH。部署后热替换。

## [2026-09-06 | 会话28 | v1.23.0] Mage 寻路贴门洞 + 过廊路点

**用户**: 新地图寻路不好用, 卡住, 绿线看着穿墙。

**现场**: 钾 Mage pv1768, 人在 Room_23 (Large). 主链 Large↔37×69 过廊循环; Exit/Entry 是同一世界坐标的 0.86 门缝方块。

**根因**:
1. `nextHop` 只认战斗房 (Zone 短边≥70 或有刷怪点) → 跳过廊, 一路从大战场中心连到下一战场, 线段穿过门墙
2. `thinPts` 丢掉 <18 格路点 → 门口 9 格点被删, 绿线穿墙
3. `getCurrentRoom` 只要战斗房 → 人在过廊 = 没房间 → `nextCombatFrom` 再直线飞
4. PFS 半径 5 过不了门洞, 退回 `shapePts` 穿墙折线

**改**: 过廊 Zone 可当当前房; 邻房 `adjacentByDoor` + `throughDoor` 三点穿门; PFS 先半径 2; `stitchPts` 射线堵了就侧绕; `thinPts` 保留门口点。

**版本**: 1.22.1→1.23.0 MINOR。需重跑 hub 进本看绿线是否贴门。

## [2026-09-06 | 会话27 | v1.22.1] 寻路连撞墙侧绕重算

**用户**: 寻路一直撞墙就重新绕, 找正确路径。

**根因**: Pathfinding 失败会退回 `shapePts` 直角折线 (可穿墙)。卡住只二段跳 / 跳过路点 / 回房间中心, 容易再走出同一条绿线硬顶墙。

**改**:
- `computePts`: 半径 5→3→2.2 三次 PFS; 全失败先 `sideVia` 绕中点再拼两段, 最后才 shapePts
- `walkTick`: 前方 4.4 格硬墙且 0.85s 位移 <1.6 → `rerouteAround` (左/右开阔侧 + 后退点, 同一终点最多 5 次, 1.2s 节流)
- 旧卡住链保留: 2.8s 几乎不动 → 跳 → 第 2 次再绕 → 第 3 次回房间

**版本**: 1.22.0→1.22.1 PATCH。未进本地实测。

**遗留**: 极窄门缝 PFS 全失败仍可能落到 shapePts; 绕路绿线会跳, 属预期。

## [2026-09-06 | 会话26 | v1.22.0] 但丁 (Sinister Trigger) 职业档案

**用户**: 用甲分析当前操控角色, 添加角色「但丁」。

**现场 (钾 pid 24672, 大厅 placeId=106484206883664, pv11476)**:
- `Current_Class` / `Active_Class` = **Sinister Trigger**
- Aspect=`Sanguine`, Lv146, GS5481, `InDungeon=false`
- 无终极 (`HasUltimate=false`); 技能2 `HasHold=true`; 充能 Skill1 Max=3
- 实机 CD (含 Stat_CDR=4%): 1=6 / 2=7.68 / 3=7.68 / 4=9.6 → 源码 base 6/8/8/10

**数据源**: `Class_Data` API (`Get` 直接调返回 nil, 走 `Classes["Sinister Trigger"].Definition` require) + 四技能 decompile (require 因 SkillRuntime 在 SSS 崩, 同 Honored One)。

**档案**:
- Name 中文「但丁」, Folder=`Sinister Trigger`, `Ranged=true`, Range=35, AtkSpd=1.05
- 1 Crossfire 27/6×3 / 2 Showstopper 18/8 (点按周身盒35, 长按龙卷25未接 hold 发包) / 3 Rainstorm 25/8 / 4 Hysteria 28/10
- 别名: 但丁/dante/sinister trigger/邪恶扳机/扳机

**版本**: 1.21.0→1.22.0 MINOR。未进本实测光环。

**遗留**:
- 技能光环只发 `tap`; 2 的长按龙卷 (HoldHitboxRange=25) 未接
- Range=35 会走远程风筝满射程, 2/3 是周身盒, 站 35 格可能空放 — 进本后看要不要把风筝距收到技能圈
- `Class_Data.Get("Sinister Trigger")` 钾上返回 nil, 读 Definition 模块

## [2026-09-06 | 会话25 | Spin Tap 删除回退]

**用户**: 「不要这个功能了，删除吧」

**根因**: Spin Tap (v1.21.2) 在 Potassium workspace 部署时与 Rayfield Gen2 cache (`_G.RCWTK_UIKIT_CACHE`) 状态冲突 — `rfWindow` 缓存指向已销毁实例, 每次 NewTab 调用触发 "lacking capability Plugin" 错误, 整个 hub 主 IIFE 执行到 8514 行 panic, 5 个原 Tab 无法显示。

**改动**: 删除 hub.luau 8266-8438 全部 Spin Tap 相关代码 (含 Cbt._spin 表、SPIN_CLASS_LIST/SPIN_ASPECT_LIST、spinGetRF/spinReadResult/spinClickReject/spinDismiss 函数、spinPass 局部函数、spinTab 及其 5 个控件)。hub 从 8514 行降至 8342 行。

**版本**: 不变 (1.21.0, Spin 改动全部撤销)。

**部署**:
- `python tools/deploy_dr.py` (同步到 Potassium workspace 双路径)
- `python tools/force_deploy_hub_root.py` (workspace 根 hub.luau)
- 验证: `python temp_check_deployed.py` 显示部署版无 `Spin`/`spinTab`/`Cbt._spin`/`SPIN_*`/`SpinGetRF`/`spinReadResult`/`spinClickReject`/`spinDismiss`/`spinPass`

**踩坑记录**:
- [Potassium workspace 与本地工程目录是两份独立文件副本] → 必须用 `tools/deploy_dr.py` 同步 hub, 但 lib/theking.luau 需单独 `tools/deploy_lib.py`
- [Rayfield UI 缓存 `_G.RCWTK_UIKIT_CACHE` 不自动失效] → 加新 Tab 必须先清缓存 + 手动重新 loadstring lib, 否则缓存命中旧 rfWindow 触发 Plugin capability 错
- [lib v2.5.0 rfWindow.screenGui.Parent 检测] → 已加入 NewTab 兜底 (2026-09-06 会话24), 但 Potassium 缓存仍会拦截
- [调试时 `for c in pg:GetChildren() c:Destroy()` 会破坏游戏 UI] → **只能清理 TheKing 自建 ScreenGui, 不能用全清**, 正确做法是 lib 的 `eachOwnWindGui`

**遗留**:
- Spin Tap 功能**未实现**, 用户已决定不要此功能
- Rayfield 缓存失效机制需要 lib 层彻底解决 (本次未深究)

## [2026-09-06 | 会话24 | v1.21.0] 双形态技能数据重测 + 动态 CD + 形态偏好

**用户**: 「分析详细所有两套 6 个技能攻击距离」「CD 不是固定的, 系统要支持装备减 CD」「优化双光环最大化输出调度」

**根因 (钾 Mage/Hard 局, pv1766 全量反编译)**:
1. **档案错配**: 旧矛 1 base=10/矛 2 base=7 — 实测矛 1=7 / 矛 2=11 (与剑 1/2 互换); 矛 1/3 Range=17/20 — 实测 SpearHitRange=**0** (服务端按方向生成 hitbox, 走 dash 突刺非玩家中心距离门).
2. **CD 固定**: `data.Cd` 是源码 base, 实战被 `Stat_CooldownReduction` (7.5% 起) 折算; hub 用固定 base 算 `altFormReadiness` 偏保守, 切形态判断延迟 0.5~1s.
3. **形态调度无偏好**: 双形态轮转只看就绪数, 不看战斗场景 — 剑形态 2/3 站桩 AoE 群怪强, 矛形态 2 单段 11x 瞬移背单体强; 现版本对群怪场景打矛 = 浪费剑的 AoE.

**改 (hub v1.21.0)**:
1. **档案修正** (行 605-622): 矛 1 Cd 10→7 / Range 17→0; 矛 2 Cd 7→11 / Range 不变; 矛 3 Range 20→0; 矛 1 HitMultiplier 1.55; 矛 2 11x 瞬移背 (WarpSearchRange 60); 矛 3 0.5x tick 3.6s dash.
2. **动态 CD** (`skillSlotReady` / `altFormReadiness`): 优先读 `SkillN_CooldownDuration` 服务端值; 服务端不持续广播时退化到 `base × (1 - CDR_total/100)`. CDR 多源汇总: `Stat_` + `RunBuff_` + `AchBoost_` + `Perk_` + `Passive_`.
3. **形态识别双源校验** (`dualFormState`): `M1Mode` (Char 属性, 服务器权威) 优先级 > 武器 Transparency — 切换动画瞬时无抖动.
4. **形态偏好调度** (`findReadySkill`): 群怪场景 (≥2 怪) 矛→剑 + 剑 2 就绪 → 优先切剑; 单体 (≤1 怪) 剑→矛 + 矛 2 就绪 → 优先切矛. 仍守 v1.20.1「当前套 ≥1 不切」铁律.
5. **skillRange 兜底** (行 943): `SpearHitRange` 也识别; Range=0 fallback 18 (dash 型贴脸放).

**版本**: 1.20.2→v1.21.0 MINOR。**未实测** (钾客户端掉线); 静态门通过, `(anon)` 函数峰值 194 WARN.

**遗留**:
- v1.21.0 形态偏好需要实测 (客户端掉线没注入)
- 矛 3 站桩 3.6s 是档案源码值, 实战若服务端缩短需 `Stat_CDR` 折算后重新校准 dualSwapBlocked
- 剑 1 距 26 + 剑 2 距 20: 远程怪 (Cryomancer 站远) 时剑 2 不够距, hub 会空放, 需手动贴脸

## [2026-09-06 | 会话23 | v1.20.2] 谨慎避战不躲小怪落雷

**用户**: 不会躲小怪的地板爆炸技能。

**根因 (钾 Mage 局)**: 小怪模型上没有 `Telegraph_Root` (只有 Cryomancer 有)。`MeteorZones` 走 `Player.Remotes.SpellBurst`: `{EffectName=Grenade, SoundName=Earth_Hammer_2, Lifetime=3, Position=落点}`。旧逻辑只扫 NPC/SpellTelegraphs 的 `AoE_Telegraph`, 落雷圈永远看不见。

**改**: `Cbt.hookSpellBurst` 收 Grenade 落点, 半径 16, 存活 ~2.7s; `tickAoeDodge` 与 Boss 预警圆一起比, 踩进就朝圈外 Dash。Boss 原路径保留。

**版本**: 1.20.1→1.20.2 PATCH。deploy 双路径 + 热注入 `DR_HUB_v1202 loaded`（首注 `until` 保留字编不过已改 `exp`）。

## [2026-09-06 | 会话22 | 分析] Boss Rush (BOSS爬塔) 未改 hub

用户正在打的是 **BossRush**, 不是双倍地牢爬塔。结论见 intel「Boss Rush」。要点: 100 层单 Boss; 每 10 层狂暴+选箱; 重开走 BossRushService; `isTowerRun` 会误判; 索敌会扫到预制模型。

## [2026-09-06 | 会话22 | v1.20.1] 有技能却切 + 好了不放

**用户**: 有技能却切换武器; 技能不积极, 好了不马上放。

**根因**: v1.20.0 `altN+altSoon≥2` 不看当前套 — 当前套还剩 1 个、或半半径打不着时直接 fire4。半半径出手让圈内技能干等。Rem=0 滞后让刚放完仍算就绪, 调度乱。

**改**: 当前套 ≥1 只放 1/2/3, 打不着 return nil 贴脸不切; 打空才切。DualForm 出手 80% 满射程。就绪: 同槽 0.85s 内不放; Rem>0 走本地满 CD 兜底冻结; Rem≤0 且 since≥cd*0.75 才放 (认 CDR, 挡滞后)。

**版本**: 1.20.0→1.20.1 PATCH。deploy 双路径 + 热注入 `DR_HUB_v1201 loaded` / `@1.20.1`。

## [2026-09-06 | 会话21 | v1.20.0] 倒置长矛双套轮转 (拉满技能)

**用户**: 双光环+倒置长矛不爱切短刃/矛, 一直打剑套; 要办法拉满该职业技能输出。

**根因 (会话20 分析, 钾现场)**: 剑可见 spearT=1; rem4=nil 冷却已好; `skillSlotReady(4)` 写成 `rem~=nil and rem<=0` → 永不 fire4。叠加 Rem 滞后见 0 就放把 curN 钉在 ≥2, 决策序 A 不评估切。

**改 (hub v1.20.0)**:
- `skillSlotReady` slot4: `rem==nil or rem<=0`
- 1/2/3 同槽 `since < min(1.5, cd*0.3)` 不放 (掐 Rem 滞后刷屏, curN 打空后能掉下来)
- 决策: 打空且对面 ≥1 就切; 对面 ≥2 仍切; curN≥2 打不着不 `return nil`, 继续评估切
- `Cbt.dualSwapBlocked`: 剑2 3s / 剑3 2.2s / 矛3 3.6s 站桩期不 fire4 (会话11 矛→剑连吞)
- 2.8s 退避 + DualSwapGate 1.2s 保留, 防 fire4 风暴

**版本**: 1.19.0→1.20.0 MINOR。表方法, 不新铺主块 local。

**验证**: check_hub 过静态门; deploy 双路径 v1.20.0 + 钾热注入 PID 10180: 热替换自毁接管完成, `地下城战利品者@1.20.0` / `DR_HUB_v1200 loaded`, 无编译错误。实战看剑套打空后按 4 翻矛。

**遗留**: Mage 寻路; 吞包后 2.8s 才重试, 矛3 刚结束若撞保护窗仍可能连吞一次。

## [2026-09-06 | 会话20 | v1.19.0] Mage 寻路离墙 + WASD 让路

**图**: Mage OpenWorld 分段。主链 Start(Room_1 无刷怪) → Large_Room(~139×181, 9 spawn, 双 Side) → 窄廊(~37×69) 循环; 侧房 IsLootRoom; Room_13+ 空壳后实例化。Entry/Exit 是嵌在门缝的 0.86 小块, 旧路点打在门上绿圈穿墙。

**改**: doorIn 朝房中心推 9 格; hallMid; clearSpot 八向; floorY 跳非地面; WASD 让路 yieldIfSteer。贴脸/风筝同时让路。

## [2026-09-06 | 会话19 | v1.18.2] 开关改名谨慎避战

用户确认 Boss 地板圈也闪避、不用改逻辑。UI Title「谨慎避战」, 去掉 Desc。PATCH。

## [2026-09-06 | 会话18 | v1.18.1] 自动闪避不触发

**用户**: 不会闪避。

**根因**: ① 现场 Cryomancer `AoE_Telegraph.Attachment.ParticleEmitter` — `GetChildren` 扫不到 Enabled。② BindToggle `Value=true` 创建不跑 Callback, PREF 也没 `t_dr_aoe_dodge`, RestoreToggle 跳过, 循环从未 StartLoop。③ 角色 `Dodge=true` 是技能保护, 当 busy 会把闪避包整段掐掉。

**改**: 粒子走 GetDescendants; 光环 OnEnable `BindStepped` 心跳; 默认开靠 Restore 补点; 只认 `Dodge_Cooldown_Active`。

**遗留**: 大圈一次闪不出去; 无客户端预警的 Meteor 仍躲不到。

## [2026-09-06 | 会话17 | v1.18.0] 光环自动闪避地板爆炸圈

**用户**: 杀戮光环能不能自动闪避(按Q)这类地板技能。

**协议**: Q = Dodge, 客户端 `Weapon_Input` 对 Dodge 发 `Inputs.Dash:FireServer(dir)` (有移动用相对移动方向, 否则相机水平 Look)。钾 `keypress` 不进 UIS, **不能模拟按 Q**。无独立 Dodge remote。

**实现**: `Cbt.tickAoeDodge` 50ms; 扫敌人 `Telegraph_Root.AoE_Telegraph` + `workspace.SpellTelegraphs`; 粒子 Enabled 且水平距 < `TelegraphRadius`(无属性则粒子 Size×1.35 或 22)+3; 方向=人相对圆心水平单位向量, Y=0 (VerticalReach 别飞高)。CD: `Dodge_Cooldown_Active` / 角色 `Dodge` / 0.45s 节流 / `NoDodging`。圈内 `Cbt._aoeUntil` 挡住 `autoApproach`。UI Flag `dr_aoe_dodge`, 默认开 (`PREF.t_dr_aoe_dodge ~= 0`, nil 当开)。

**版本**: 1.17.1→1.18.0 MINOR。逻辑全在 Cbt 表方法, 不新铺主块 local。

**未实机踩圈**: 需开光环+地板圈看 Dash 是否出圈; 圆心大圈一次闪避可能不够(CD~1.8s)。

**遗留**: Mage 寻路; 会话13 slot4; 直线斩不躲; 无客户端预警的 Meteor 躲不到。

## [2026-09-06 | 会话16 | 分析] 地板爆炸预警圆 (未改 hub)

用户纠正: 要的是爆炸类地面圆, 不是直线 Beam / HUD 雷达。

结论见 intel「地板爆炸预警」。要点: AoE/BigAoE + TelegraphRadius; 视觉=NPC 上 Telegraph_Root.AoE_Telegraph 红橙粒子圆; 金黄多半是 Light_Explosion 命中特效。未做自动躲圈。

## [2026-09-06 | 会话15 | v1.17.1] 近战双光环+寻路半半径贴脸

**用户反馈**: 普通地牢双光环+寻路, 怪在技能圈边或稍外, 索到了但倒置长矛技能打空、卡怪。

**根因**: `trySlot`/`skillSlotTarget` 用 `skillRange+8` 当可出手; `autoApproach` 满射程 `pick` 成功就停; 寻路 fight `nd <= getMeleeRange()` 就清路点。三处都把「圈边」当打得到。

**改动**: `Cbt.engageRange` / `Cbt.skillFireRange` — 近战出手/停步 = 档案射程×0.5 (下限 8); 远程不变。接线: skill 索敌、autoApproach 停距、Nav fight 拉怪。slot4 换武器仍「有活怪即可」。平A 仍满射程, 走近途中可补刀。

**版本**: 1.17.0→1.17.1 PATCH。静态门见 check_hub。

**遗留**: Mage OpenWorld 寻路未解剖; 会话13 slot4 nil 就绪未做。

## [2026-09-06 | 会话14 | pv1766 全量解析, hub 未改] 游戏更新复核

**触发**: 用户「启动引擎, 解析游戏全部」。钾 PID 10180, 地牢图 pv**1766** (档案 1659)。

**做了什么**: 启动协议 (engine-memory / lib 末条 / recall.py / intel+devlog+changelog) → 现场 dump PlaceConfig / DungeonData / Knit 76 服务 / Inputs / Class_Data 42 职业 / MutationData Aspect / TileData.Wistoria / 玩家属性。未改 hub。

**关键结论**: 见 intel「pv1766 全量复核」。通信层未换; 新 T7 Mage (City of Mages, 清 Demon NM + Lv100); 新 Aspect/突变; `VerticalReachAntiCheatService` (别飞高); PlaceConfig 布尔在地牢图上撒谎。

**遗留**: ① Mage 房间未实地解剖, 自动寻路勿当已适配; ② 会话13 slot4 nil=就绪 / 同槽退避仍未做; ③ 静态门 194 贴线。

## [2026-09-06 | 会话13 | 代码已回滚至 v1.17.0] 双光环平A不流畅调查 — 倒置长矛 Rem 属性行为实测 (结论留存)

**用户反馈**: 双光环(杀戮+技能)下倒置长矛"平A不流畅"; 中途要求**回滚到反馈前的 v1.17.0**。代码已回滚, 本条目只留实测结论与下次接手方案。

**实测结论 (钾三探针)**:
- **发包频率探针** (hook `__namecall` 统计 `Inputs.Attack`/`Inputs.Skill`): 平A实测 **2~4.8 刀/秒**, 理论 ~9.5 刀/s (atkInterval = 0.099/1.1); 但**相邻刀间隔正常** (avg 0.105 / max 0.15) → **不是逐刀卡顿, 是整块静默段在吃输出**。技能 1~2.5 发/秒, 而 6 技能 CD 7~15s 理论上限 ~0.5/s → 技能明显过密。
- **[FIRE] 逐包日志**: `s2 rem=0 since=0.22~0.25` **连发 5 次** → v1.16.4 双口径 `rem<=0 → return true` 无条件放行。根因是**服务端 Rem 属性同步滞后** (fire 后约 1s 内仍读到 0, 之后才刷成 10.23/12.09)。
- **[STATE] 属性快照**: `s1 Rem=0 / s2 Rem=10.23 / s3 Rem=12.09 / s4 Rem=nil OnCd=nil` → ① 服务端**确实下发 Rem** (与 intel 旧述"服务端不发 CD 信号"不符, 缺的只是 Charges/OnCooldown); ② **换武器 4 号槽冷却好时属性为 nil** → v1.16.5 起的 `rem~=nil and rem<=0` 判据让 4 永不就绪, **形态永远切不了、矛套 3 技能全程吃灰** (用户"不放技能了"的另一半原因)。
- **连打类技能 (剑2/剑3/矛3, StationarySkills) 在平A动画中发包常被服务端拒收**, 吞包后 Rem 不进 CD 恒为 0 → 任何"见 0 就放"的判据都退化成重试刷屏; 每发掐 0.22s 平A (skillHoldUntil) 且角色反复进站桩技够不着怪 → 平A静默审计 `1.92s 内 无目标=19 hold=8`。

**尝试过且已回滚的修复 (不采纳)**:
- v1.17.1「Rem 下降沿」判据: 过严, 只剩本地 cd 兜底 → 技能降到 0.3/s, 用户反馈"不会放技能了"。
- v1.17.2「三态判据」(Rem 递减=CD中 / 冻结>1.5s 走本地 cd / 可信归零需 `since≥cd*0.8`) + slot4 改 `nil or ≤0`: 未充分实测即被要求回滚。
- 回滚范围: `skillSlotReady` 双形态分支回 v1.16.5 双口径; 删除本轮全部调试代码 (`Cbt.meleeAudit`/`skipStr`、fireMeleeOnce 分支审计 + [MGAP]、fireQueuedSkill [FIRE] 日志); ScriptVersion 与启动标记回 v1.17.0。静态门 194, 已部署 + 热替换, 无调试残留。

**下次接手建议 (按优先级)**:
1. **slot4 判据改 `rem == nil or rem <= 0`** — Rem nil = 服务端无冷却记录 = 就绪; 频率由 c4retry 2.8s + DualSwapGate 把关。这是"形态永远切不了"的真 bug, **与平A流畅度无关, 应单独修且风险最低**。
2. 同槽重发退避: `since < min(1.5, cd*0.3)` 不放 — 只掐刷屏 (实测连发间隔 0.22s), 不动正常发放 (同槽最短真实 CD 7s)。
3. 平A静默另一半是"追怪/站桩期无目标", 属走位效率 (autoApproach 0.5s 移动节流 + 近战 reach 23), 与技能判定无关, 别混在一起改。

## [2026-09-06 | 会话12 | v1.17.0] 爬塔 Boss 波「清杂优先」战斗逻辑

**用户需求**: "优化自动寻路爬塔战斗逻辑, 每10层的BOSS都要优先清小怪再打boss"。

**设计**:
- 范围限制爬塔: 判定 `Nav.on and Nav.isTowerRun()` (Challenge_Dungeons 在场 / UI Depth 兜底; Generated_* 一票否决), 普通 dungeon Boss 房不受影响。
- 新 helper `Cbt.addsFirst()`: 塔内场上同时存在 Boss 集怪 (`Cbt.isBossModel`) 与活杂兵 → true, 0.5s 缓存 (`Cbt._addsAt/_addsVal`) 防每 tick 全扫。
- `Cbt.pick` (平A/技能索敌核心): ① lock 若咬 Boss 且 addsFirst → 丢锁重选 (getEnemies(true) 强刷); ② Boss 候选评分 `s+75` 沉底 — 仅当射程内无小怪候选才轮到 Boss; 原非塔场景 Boss 微优先 -2.2 保留。Boss 判定从裸 `IsBoss/IsMiniBoss` 属性换成 `Cbt.isBossModel` (补 HighlightPriority/精英/名册覆盖 — 塔 Boss 可能只靠 Boss_ActionData 名册而非裸属性)。
- `Cbt.autoApproach` (追击): addsFirst 时扫描目标剔除 Boss, 防角色主动凑 Boss 被杂兵围; Cbt.lock 落 Boss 也被 pick 丢锁逻辑拦。
- 触发**不解析 Wave UI 文本** (文本格式未知, 脆): 塔内只有 Boss 波 (每 10 层) 才会刷出 Boss 怪, addsFirst 天然只在 Boss 波为 true。

**版本**: v1.16.6→v1.17.0 (MINOR)。静态门峰值 194 (helper 走表方法, +0 顶层 local)。deploy 双路径 + 钾热替换 DR_HUB_v1170 loaded (接管干净, 无编译错误)。

**验证**: 逻辑走查 — 塔 boss 波小怪在场→先咬小怪; 清光→addsFirst 翻 false→集火 Boss; 塔外→恒 false 原行为。现场实测待用户进塔第 10/20 波确认。

**遗留**: ① 塔 Boss 若既无属性又无名册命中 (理论不会, isBossModel 覆盖面全) → 功能失效需排查; ② 若 Boss 波小怪无限刷会一直不清 Boss (设计取舍: 用户明确"清完再打"; 实测若 Boss 波有刷怪上限则无碍, 若无限刷需加"清杂 N 秒后强制转 Boss"上限); ③ dr_auto_replay 224ms 慢循环 (老问题, 未动)。

## [2026-09-06 | 会话11 | v1.16.5+v1.16.6] fire4 风暴根除 — 4号槽严格信服务端 + 服务端切换保护窗

**用户反馈**: v1.16.4 后"还是会发呆偶尔停顿 1 秒"; 补充"发呆发生在切武器**前**" → 方向修正: 不是切后静默窗, 是**切之前**断流 ~1s。

**定位 (三探针合围: hub 内死寂审计 [DEAD] + 外部时间线 DRP6 + fire4 精确日志)**:
- [DEAD] 铁证: 连 4 条 `last=4 since4=0.7 rem4=0` → fire4 在 ~1.2s 周期重复、4 从没进 CD (每次被吞); 另一条: 剑态技能全就绪 (rem=0,0,0 / since=18,17,17) 无锁却 1.6s 不放 → 决策序 A (curN≥2) 分支 trySlot 全因射程 nil 直接 return, 不再评估切换。
- [FIRE4] 日志实锤: `form=SPEAR rem4=4.40` 时本地 since≥档案 5s 误判就绪 → 提前 fire4 被吞 → 0.5s 快重试风暴: 每 ~1.5s fire4+0.9s 站桩, 切换动画永被重置 = "发呆"观感。
- **手动 fire4 对照测试** (绕过 hub, 每 2s 一发共 8 发): #1 SWORD 吞 → #2 成; #3 SPEAR 吞 → #4 成 → **吞包是服务端切换保护特性, 非脚本 bug**: 一次切换处理期间再 fire4 被吞, 隔久再发才成功。

**改动 (hub.luau, v1.16.5 → v1.16.6, 静态门 194)**:
- v1.16.5: ① `skillSlotReady` slot4 (Tool Swap) **禁用本地档案 cd 兜底、严格信服务端 Rem≤0** — 1/2/3 憋手代价小可双口径; 4 是服务端强控切换冷却 (含隐藏保护), 本地 since≥5s 兜底即误放风暴源。② fire4 重试退避: 形态已翻 0.5s / 没翻 (被拒) 1.8s。
- v1.16.6 (1.8s 退避仍撞保护窗, 风暴变慢没消失): ① `Cbt.tickSwapWatch` 加**吞包快速识别** — fire4 后 0.7s 无翻转迹象 (lastForm 未更新) = 被吞 → 立即清 busy/hold 解锁、记 swapFailAt, 当前套有技能恢复放, 不白锁满静默窗 (DualSwapLen 上限保留兜底); ② 重试退避统一 **2.8s** (> 保护窗; flippedSince 分支删 — 形态翻了会被 DualSwapGate 挡, 不会立刻再 fire4); ③ fire4 发出清 swapFailAt; 光环 OnEnable/OnDisable 清理处补 swapFailAt 复位。

**验证**: v1.16.6 连续三循环切换**全部一次成功** (0.26~0.32s 翻转, 0.31s 接输出, 无风暴重发); 剑→矛 100% 一次成。deploy 双路径 + 钾热替换 DR_HUB_v1166 loaded 接管干净。切换风暴确认消除, 节奏 = 两套打空→切必成→无缝连发。

**遗留**: ① **矛→剑偶发连吞 2~3 次** (2.8s 间隔, 最坏 ~8.8s) — 疑矛3 周身连打 3.6s (全程拼刀 StationarySkills) 期间服务端锁 Tool Swap; 剑→矛不受影响 (剑3 连打 2.2s 较短)。下轮若仍报矛→剑卡顿, 定向做"矛3 连打/拼刀结束才允许 fire4"。② [DEAD] 3.3s 段判明为清场后追怪移动期 (MoveTo 无战斗动画, 外部探针误报), 非卡死。③ 探针教训: 平A动画名 = "Animation" (非 Attack_*); idle/jog 等移动动画必须从"战斗动画"判定集排除否则站桩检测失效。

## [2026-09-06 | 会话10 | v1.16.4] 周期性发呆实锤 — 服务端 CD 属性冻结滞后 + 就绪双口径

**用户反馈**: v1.16.3 (切4静默窗动态解锁) 后仍"有时候打着打着发呆一下"。

**定位 (钾旁路探针 ×3 迭代)**: 探针只读 (Damage_Dealt/Animator/怪距/形态/Skill Rem), 不 hook 不改 hub。
- v1 教训: 平A动画名是通用 "Animation" (非 Attack_*), 按名过滤全漏 → animAge 假象 8481s, 但 dmg 每秒 +8~13万 → 过滤放宽重做。
- 铁证 (221588-221591): SPEAR `rem=7.24,6.15,6.1` 连续 >4s 逐秒心跳**同值不动** — 服务端 CooldownRemaining 属性在塔内冻结/滞后 (70 波 Boss 战服务端繁忙)。期间角色站桩 (spd=0) 只平A, dmg 靠平A + Damage_Dealt 批量同步在涨。
- 推论链: skillSlotReady 双形态分支 `return rem<=0` 100% 信服务端 Rem (v1.15.1 引入"权威优先"正确, 但没防属性冻结) → 技能真实 CD 好、Rem 仍旧值 → 判 not ready → 决策 nil → 只平A。Rem 解冻跳 0 → 突然连放。**周期性发呆 = Rem 冻结窗口**。配合 dr_auto_replay 每 0.6s tick 一次 GetSessionState InvokeServer (74~1495ms/次, 每秒 1 条慢告警) 轰炸服务端, 加重属性同步延迟。

**改动 (hub.luau)**:
- `skillSlotReady` 双形态分支重构为**双口径**: 服务端 Rem≤0 → ready (保留 v1.16.2 吞包兜底: 吞包 Rem 保持 0); **或本地分键计时 since≥档案 cd → ready** (新: 防 Rem 冻结憋手, 本地到点即放)。onCd 不再在双形态分支前置拦截 (它与 Rem 同源, 一样会滞后)。服务端真没到点: 每 CD 至多一空包, 服务端拒收无害 + lastCast 同步刷新, 不会空发循环。
- 塔状态轮询节流: `tickTowerSpeedrun` + `tickTowerReplay` 的 GetSessionState Invoke 前加 `Nav.lastSess` 3s 节流 (原 0.6s/1.5s tick 每次 Invoke)。atEnd 结算路径不节流, 失败检测最多钝 3s, 可接受。共享键: 两塔模式同时开时互相 3s 分时。
- ScriptVersion 1.16.3→1.16.4 (PATCH)。静态门 194 通过 (双口径重构未增顶层 local)。

**验证**: deploy 双路径 + 钾热替换 DR_HUB_v1164 loaded (接管干净)。效果待用户塔内实战确认 — 预期: Rem 冻结期技能照常按本地节奏释放, "发呆一下"消失; dr_auto_replay 慢告警从每秒降为每 ~3s。

**遗留**: ① 本地档案 Cd (base 无 CDR buff) vs 服务端实际 CD (含 CDR): 本地到点若早于服务端真就绪, 每 CD 一空包 (实测待观察, 若频繁说明需给档案 cd 乘 1/(1-CDR) 修正); ② 双塔模式共享 lastSess 节流可能让失败检测与快刷互相 3s 分时 (罕见同开, 暂不拆); ③ dr_fakename 34-38ms 偶超 (假名扫描, 与本次无关)。

## [2026-09-06 | 会话9 | v1.16.3] 切 4 后发呆真空 — 静默窗改翻转感知动态解锁

**用户反馈**: 倒置长矛"切完 4 会发一会呆, 有输出真空期"。

**根因 (静态分析, 非 DBG)**: `fireQueuedSkill` 对 slot==4 设静默窗 `skillBusyUntil = skillHoldUntil = now + Cbt.DualSwapLen(1.5s)` — busy/hold 同锁 1.5s, 期间 OnTick return + fireMeleeOnce 被 hold 挡, 平A技能全停。但切换动画 + 形态消抖实测 <1s 完成 (v1.16.2 changelog 自证 "fire 4 + 形态翻转 <1s"), → 翻转后仍锁 ~0.5s+ = 白罚站 (发呆观感)。

**改动 (hub.luau, 均走 Cbt 表方法/字段, 不占主闭包顶层 local)**:
- `fireQueuedSkill` slot==4 分支: holdLen 语义改为"静默窗上限", 另登记 `Cbt.swapWatch = { at = now }`。
- 新增 `Cbt.tickSwapWatch(now)` (findReadySkill 后): swapWatch 非空时探测 `dualFormState()` — 形态翻转确认 (lastForm ≥ at 且稳定 0.05s, lastForm=消抖完成翻转时刻 = 切换动画已结束) → 立即清 busy/hold, 下一拍 findReadySkill 用新套视图连发; 兜底 now-at ≥ DualSwapLen 强解防翻转检测失效永锁。
- `OnTick` busy return 前调 `Cbt.tickSwapWatch(now)` (每 0.05s, swapWatch 平时 nil 零开销); 解锁后 0.05s 内即恢复技能调度。
- 光环 OnEnable/OnDisable 均清 swapWatch 防残留。

**决策理由**: 翻转确认 (Transparency 消抖完成) 是比固定 1.5s 更准的"动画已结束"信号 — 服务端动画驱动 Transparency, 翻转时服务端必已收完换武器包、新套 Remaining 就绪; 解锁瞬间若个别包因边界被吞, 走既有 0.5s 快重试/Remaining 幂等自愈。无起步保护窗 (翻转=动画完, 无需防插包)。

**验证**: check_hub 峰值 194 (WARN <195 过, 表方法形式 +0 local); deploy_dr 双路径 v1.16.3; 钾热替换接管成功 (DR_HUB_v1163 loaded, 无编译错误)。解锁节奏待用户实战确认 (预期: 翻转 ~<1s → 静默 <1s → 切完即连发, 空窗 ≈ 旧 1.5s 的 1/2 以下)。

**遗留**: ① 194 仍贴 195 上限 (下次加功能前先拆闭包/收表); ② dr_auto_replay 循环 239ms/154ms 超 33ms 告警 (重开检测慢循环, 与本次无关, 待单独优化); ③ 若实战仍有"切完停 0.3-0.5s"且确因服务端 Remaining 延迟翻转, 可在解锁后首拍加 1-2 tick 探测再发。

## [2026-09-06 | 会话8 | v1.16.2] 切换不积极两连修 (v1.16.1 决策序 + v1.16.2 吞包快重试)

**用户反馈**: v1.16.0 后"切换不积极"。钾 DBG 实锤两因:

**① v1.16.1 (决策序)**: 旧实现「当前套打空才评估切」→ 当前套 1 个就绪就 return 压制切换, 另一套攒够 ≥2 干等。改决策序: curN≥2 放满当前 → altN+altSoon≥2 且 curN<2 立即切 → curN=1 兜底放 → nil 平A。新增 `curFormReadiness(skills,now)` helper (skillSlotReady 计当前套就绪, 只做决策权重, trySlot 射程兜底)。

**② v1.16.2 (吞包快重试)**: DBG 观察 15s 空窗 + c4age 反复 1.5→4.9 循环 = lastSkillCast[4] 被吞包刷新 (fire 4 服务端不收不报错, 无 S4 Rem 翻转)。旧 canSwap 用 `age>=5` 本地假冷却 → 吞包后 5s 死等再试, 叠加连败 = 15s+ 切不过去。修复: canSwap 4 就绪改 `skillSlotReady(4)` (服务端 Rem≤0 权威, 吞包 Rem 保持 0 → 就绪不丢) + 0.5s 重试退避。实测 (钾): 矛态 curN=0 后 <1s fire 4 + 形态翻转 (旧 15s)。

**函数级**: findReadySkill 双形态块 canSwap 判定 + curFormReadiness 新增 + 调度顺序重排; altFormReadiness 保持 (v1.16.0)。debug: 临时 DBG4 节流打印 (Cbt.dbgT4) 已移除; 旧 v1.15.0 块注释清理。

**遗留**: ① 过渡期串套误读 (fire 4 后 ~1s 形态消抖前, 视图旧套+服务端 Rem 新套 → curN 虚高 1 tick) — 实测无害 (A 分支 trySlot 射程兜底), 不修; ② 峰值 194 贴 195 上限, 再改需先拆闭包/收表; ③ 玩家无怪期不切属正常 (trySlot 无怪 nil), 判断"不积极"务必在怪堆实战。

## [2026-09-06 | 会话7 | v1.16.0] 倒置长矛双形态猛攻三连迭代 (v1.15.0 → 1.15.1 → 1.16.0)

**用户诉求**: 一战斗就快速连放 1/2/3 → 按 4 换套 → 另一套 1/2/3 → 两套循环猛攻穿插平A, 4 前摇预判衔接; 后补明确规则: 双套独立侦测, 任意一套 ≥2 就绪即切去打, 当前套 ≥2 放满再看另一套, 都不足 2 就放当前已好技能 + 平A。

**改动 (hub.luau)**:
- v1.15.0 `findReadySkill` 双形态分支重写: 旧 allOnCd 语义写反 (全冷却完才切 → 一发技能 since≈0 就 false → 永不切 4, 半套闲置)。新: ① 当前套就绪扫光 → ② 打空评估切换 (4 CD + 翻转门 + 目标套就绪/前摇预判)。`Cbt.DualSwapLen=1.5 / DualSwapGate=1.2` 新增; `skillSlotReady` 双形态优先服务端 Remaining (含 CDR buff); `fireQueuedSkill` 4 用 swapLen 静默窗。
- v1.15.1 修两 bug (钾 debug `[DBG] trySlot4 nil` 实锤): ① 预判段读已被 dualSkillView 切单分支的视图 (找 d.Sword/Spear 恒 false → 永不切) → 注入 rawSkills 缓存原始双分支表; ② 4 自施法切换却被射程门卡 → trySlot 双形态 4 放宽"有活怪即可"。
- v1.16.0 按用户规则重构: 新增 helper `altFormReadiness(rs,tSpear,now,swapLen)` (目标套就绪+前摇内将就绪计数, 独立函数控寄存器); 调度改为 — ① for trySlot 1..3 当前套就绪放满 (含只 1 个也放, 免切走后空等 5s+) → ② 打空后 altN+altSoon≥2 才切 4 → ③ 不足 2 平A 兜底。旧阈值 (1 就绪即切) 切换收益不足, 新阈值 2 统一。

**决策理由**: 服务端只下发当前形态 Remaining, 另一套无属性可读 → 目标套就绪只能本地分键计时 (base Cd, CDR 偏保守), 配合 cd-swapLen 前摇预判覆盖; 阈值 2 = 切换成本 (1.5s 动画 + 4 CD 5s 节流) 的盈亏平衡点。

**验证**: check_hub 峰值 193 (WARN<195 过); 观察脚本实测 S1 就绪后 0.1s 内施放 (旧憋 0.6~2.8s); v1.16.0 双套交替节奏待用户实战确认。

**遗留**: ① v1.16.0 交替节奏未实测整轮 (靠用户实战反馈); ② 观察 S2/S4 服务端无 CD 属性 (HasHold 类) — 若属"长按蓄力"语义, 档案 Cd 兜底可能与实际不符待核; ③ 目标套就绪无 CDR buff 修正 (base 估) — 若实测切过去偶尔 1 技能未好, 可加 cd 折扣系数。

## [2026-09-06 | 会话6 | v1.14.1] 倒置长矛双形态 + 反挂机 + 部署链路定型

### 本会话产出 (时间序)
1. **天堂碎片** (intel 已归档): 挑战图 boss 波 (wave 40 后) 每玩家 15%, 进包不落地面, MaxOwned=10, Unrestricted 转职任务材料
2. **反挂机** (v1.13.0, 设置 Tab 底部): 重型钓鱼防踢心跳整段移植, 开关走 PREF.antiIdle, 默认开 — 症状: 脚本全 FireServer 零真实输入 → Roblox 原生 20min 闲置踢
3. **倒置长矛档案 + DualForm 循环** (v1.14.0): 档案写 CLASS_ARCHIVE_RAW (Skill 子表结构 `{ Sword={Range,Cd}, Spear={Range,Cd} }`), 数据全部反编译实测; 形态识别 `Cbt.dualFormState()` 读 PlayerModels/<名>/HRP/Holder/Right_Arm 的 Sword|Spear Transparency
4. **deploy_dr.py 定型**: 拷 Potassium workspace 双路径 (用户拍板: 砍掉 MCP 注入触发 — 注入与部署解耦, autoexec/手动重跑负责执行)。**钾 VFS 快照不同步磁盘, 以后改完 hub 必跑, 禁止 readfile 裸跑**; `--check` 比对磁盘/双路径版本

### v1.14.1 双形态 bug 修复 (用户实测反馈"只循环放 4")
- **根因①**: 4 槽 CD 被按形态分键 (lastSkillCast["4S"]/["4P"]) — 发 4 时写旧形态键, Transparency 翻转后 dualCastKey(4) 读新键=nil → since 巨大 → swapReady 恒真 → fresh 门到期就再切, 死循环。**修复: dualCastKey 对 slot==4 返回原键** (换武器 CD 双形态共用是机制语义)
- **根因②**: Tool Swap 动画 1.5s 内 Sword/Spear Transparency 过渡, dualFormState 高频抖动翻转 → 1/2/3 分键错乱 → 本地 Cd 门把技能全部挡死。**修复: 消抖 (连续 0.25s 读数一致才翻转, pendingSpear 机制) + 发 4 后 2s 强制重查窗 + fresh 门 1.0→2.5s**
- **实测坑**: 服务端确实发 `SkillN_OnCooldown` 属性 (随 CD 翻转) — skillSlotReady 信任它作权威, 本地 Cd 门兜底。之前只测 Charges 没测 OnCooldown, 差点误判"服务端不发 CD 属性"

### 教训
- Luau local 词法作用域: 先定义的函数引用后定义的 local 解析成全局 nil (fireQueuedSkill ↔ dualCastKey) — 跨区块共享方法挂 Cbt 表运行时解析
- `Players:WaitForChild("LocalPlayer")` 是错的 — LocalPlayer 是属性非子实例, 用 GetPropertyChangedSignal
- 载入界面 autoexec: LocalPlayer=nil 是常态, lib 2.5.1 已兜底 (等就绪, 见 lib/devlog.md)

### 遗留
- [ ] 双形态自动循环需用户进塔实测输出序列 — 本会话尾部钾客户端假死未验证
- [ ] DualForm 消抖 0.25s 若复现抖动加长到 0.4s
- [ ] hub (anon) 峰值 193 ≥160 警告持续累积, 下次大改优先收 Pack/IIFE

## [2026-09-05 | 会话5 | v1.12.9] 爬塔结算窗漏重开 (根因: InDungeon 门槛挡死 atEnd 检测)

### 现场实证 (钾探针, 结算窗 COMPLETED 弹出瞬间)
- Completion_Info.Visible=true 但 **InDungeon=false**、**角色已移除 (hrp=nil)** → `tickTowerReplay` 顶部门槛
  `if not (hrp and InDungeon==true) then return` 把结算检测挡死 → 胜利结算永不重开
- 次生 bug: OnTick 顺序 tickReplay→tickTowerReplay, tickReplay 的 atEnd 分支不区分塔/普通图,
  塔结算时先调 DungeonRunService:RequestReplay (对塔无效) 且吃掉 Nav.lastReplay 防抖 → tickTowerReplay 被 5s 锁住

### 改动 (hub.luau, 函数级)
- `Nav.tickTowerReplay`: atEnd() 检测提到 hrp/InDungeon 门槛**之前** — 结算 UI 可见即触发
  ChallengeRunService:RequestReplay; 局内失败检测 (GetSessionState) 保留在门槛后, 结算后会话取不到不误判
- `Nav.tickReplay`: atEnd 分支加 `if Nav.isTowerRun() then return` — 塔局让路给塔逻辑, 不抢服务不占防抖

### 验证
- check_hub 过 (峰值 181 WARN 非阻塞); 热替换 @1.12.9 生效, 探针监控中 (结算窗出现→应 <3s 自动关)

### 遗留
- dr_auto_replay 循环单次 74-223ms 超时警告: 非结算时 tickTowerSpeedrun/tickTowerReplay 每次 InvokeServer
  GetSessionState (网络往返 ~70ms) — 待后续把 GetSessionState 缓存节流 (1s+), 或合并 tick 共用一次调用

---

## [2026-09-05 | 会话4 | v1.12.6] 爬塔快刷 (10 波循环)

### 设计
强度曲线 `GetWaveMult = 1.1^floor((wave-1)/5)` — 第 11 波起怪 ×1.1, 16 波起满员 16 只; 而箱波 (每5波 3 箱) + 祝福 (每10波) + Boss (每10波) 都在前 10 波各命中一次。**循环打 1-10 波性价比恒定且最高**。

### 实现 (Nav.tickTowerSpeedrun, "爬塔快刷" 独立开关, 默认关)
- Wave > 10 (PREF.towerSpeedWave 可调阈值) → ChallengeRunService:RequestReplay
- 祝福 UI (Boost_Selection) 可见时不打断 — 选完增益拿满再重开
- 1.5s tick + 5s 重开防抖; 与 tickTowerReplay 共用 lastReplay 锁防双触发

### 验证
- check_hub 过 (180), deploy 全链已推, 热替换 @1.12.6 生效
- 未实测: 打过 10 波观察重开 (当前用户 Wave 75, 开快刷立即触发一轮 — 注意)

---

## [2026-09-05 | 会话4 | v1.12.5] 爬塔自动重开 (tickTowerReplay)

### 根因分析
旧 tickReplay 只调 `DungeonRunService:RequestReplay()` + 依赖 `atEnd()` (Completion_Info 可见)。塔内:
① 重开 RF 是 **ChallengeRunService:RequestReplay** (intel 319 行早归档: "其它模式走 BossRushService/ChallengeRunService/RaidRunService 同名字"), 调 DungeonRunService 对塔无效
② 塔败 (3命耗尽/计时归零) 的结算 UI 是否走 Completion_Info 未证实 — 不能只靠 UI 文本猜

### 新增 Nav.tickTowerReplay (自动重开 Toggle 的 OnTick 挂第二个函数)
- 模式门: isTowerRun() + InDungeon + replayOn; 防抖 5s
- 失败态判定 (服务器权威, 不猜 UI): `knit/Services.ChallengeRunService.RF.GetSessionState` 直调
  → `Lives<=0` (命耗尽) 或 `TimeLeft<=0` (计时归零) 或 Phase 含 Defeat/GameOver/Failed (枚举兜底)
- 胜利态兜底: atEnd() (Completion_Info) 命中同样触发
- 重开调用: `Knit.GetService("ChallengeRunService"):RequestReplay()`
- 钾实测 (Wave=75 时点): RF 直调链路 OK, Lives/TimeLeft/Phase 三字段实时可读

### 决策理由
- 不反编译控制器 (客户端只流送 stub, decompile 拿不到源) — 服务器态 Lives/TimeLeft 比 UI 文本可靠且免维护
- tickReplay (普通图) 原逻辑不动, 爬塔走独立分支, 两套互不干扰
- Phase 枚举名是猜的兜底 (可能永远不命中), 主判据 Lives/TimeLeft 实测可读

### 验证
- check_hub 过 (180), deploy 双路径+reload 已推, 热替换 @1.12.5 加载正常
- RF 直调链路实测通过 (Wave 75 时点)
- 未实测: 真实死光后自动重开一轮 — 等用户塔内耗尽 3 命观察

### 遗留
- 塔胜 (Boss 打完想连刷) 是否也该重开? 当前 Completion_Info 触发即重开 — 若用户想连塔, 保持现状即可

---

## [2026-09-05 | 会话4 | v1.12.4] DPS面板动态行数 (同寻路Bot延生)

### 需求
DPS 信息窗改为局内几人显示几行 (最多4), 单人只显示自己一行 — 同寻路Bot窗的自适应风格。

### 改动定位
- DPS_H 常量删除 → dpsShownRows 状态 (1-4); dpsClampPos 用动态高度
- dpsRefresh 开头: wantRows = clamp(#list, 1, 4), 变化时 Tween 0.3s 收缩/展开 (下半屏底边锚定, 上半屏顶边不动, 与寻路窗 hudReflow 同思路但更简)
- 行 Visible: i > wantRows 或无对应玩家 → 隐藏; 空位行文案分支删除 (不再显示"空位")
- dpsPlayerDps/dpsMeta 不变 (按 UserId 键控, 玩家加入/离开自动恢复)

### 验证
- check_hub 过 (180), deploy 双路径 + reload 队列已推, 热替换 @1.12.4 加载正常
- 当前塔内单人 → 应显示 1 行; 下次多人局 2-4 行 — 待实战确认

### 遗留
- 尾部 print tag (DR_HUB_v1122) 从 v1.12.2 起忘了跟版本, 纯日志标识无功能影响 — 下次发布统一改

---

## [2026-09-05 | 会话4 | v1.12.3] 爬塔拾箱优先级反转 (箱 > 战斗)

### 用户洞察
爬塔波次无间断出怪 — v1.12.2 的"战斗优先, 清完再捡"在怪海中 = 箱子永远捡不到, 必过期。怪不会跑但箱子会消失 → **优先级应该反转**。

### 改动定位
- tickTowerPick: 删除"60 格内活怪 → 让位"门; 新逻辑 = 有箱就奔箱, 唯一例外是贴身 6 格内怪正在打脸 (先补刀脱困再捡)
- Nav.towerPicking 状态位: 走箱路上 true, autoApproach 检查 — 拾箱期间追击走位让位, 但 `Cbt.pick(reach)` 命中 (平A范围内有怪) 照常打 — 边跑边砍不站桩挨打
- towerPicking 复位: 无箱/箱消失/prompt 丢失时 false, 防陈旧 true 永久卡追击
- 顺序关键: tickPath tower 分支里 tickTowerPick 在杀戮光环 tick 之前跑 (MoveTo 先占), autoApproach 后跑看到 towerPicking 就退

### 验证
- check_hub 过 (179 持平), deploy 双路径+reload 队列已推, 热替换 @1.12.3 加载正常
- 未实测: 箱波实战 — 预期行为 = 刷箱瞬间转向奔箱, 路上平A范围内怪照砍, 捡完全部箱再回追远程怪

### 遗留
- 6 格贴身威胁门是固定值, 若怪海贴脸时捡箱太莽可改成血量阈值 (<60% 才先打)

---

## [2026-09-05 | 会话4 | v1.12.2] 爬塔追击远程怪 + 地上实体箱拾取

### 用户需求
爬塔时 ① 不主动靠近远程怪 (站 30+ 格外光挨打不还手) ② 不捡地图上刷的宝箱 (地上实体箱, 不是 UI 选箱)。

### 根因
- autoApproach 扫描半径固定 25 格 — 爬塔远程怪 (Archer/Gunner 类) 站位 30-50 格, 光环平A够不着又走不过去
- 爬塔箱子是**地上实体 Model** (Challenge_Dungeons/ 下, 名字含 Chest, 带 ProximityPrompt), 60s 过期; v1.11.0 删"爬塔自动祝福选箱"时把 SelectMidRunChests (UI 选箱) 一起删了 — 但那本来就是另一条路径, 地上箱从来没自动拾过

### 改动定位
| 区块 | 内容 |
|---|---|
| Cbt.autoApproach | scanR 动态化: `Nav.on and isTowerRun()` → 60, 否则 25 (普通图寻路跑着让寻路管走位, 不受影响) |
| Nav.tickTowerPick (towerWatch 后新增) | 拾箱状态机: ① 60 格内活怪 → 让位战斗 ② 1s 缓存扫 Challenge_Dungeons + Loot 子树找 Chest Model ③ <8 格 firePrompt 拾取 ④ 否则 0.3s 节流 MoveTo |
| tickPath tower 分支 | 加调 Nav.tickTowerPick() |

### 决策理由
- 追击 60 而非全图: 与拾箱战斗让位口径一致 (60), 且 60 格外多是被墙隔的下波怪, 冲过去 = 白跑
- 拾箱战斗优先: CHEST_LIFETIME=60s 很充裕, 清完一波再捡不亏; 怪海中捡箱 = 白给
- 箱扫描挂 Challenge_Dungeons + Loot 两个根: 钾实测实体在 Challenge_Dungeons.<图>/ 下, Loot 目录备用 (当前为空但普通图可能用)
- firePrompt 复用 Nav.promptAt (找 ProximityPrompt) + Nav.firePrompt (fireproximityprompt 主路 / InputHoldBegin 兜底) — 与普通图捡箱同源

### 验证
- check_hub 过 (179 持平), deploy 双路径 + reload 队列已推, 热替换 @1.12.2 加载正常
- 未实测: 实际爬塔箱 Model 命名待跑图确认 (假设名字含 "Chest"); 若不命中, 开 towerChestScanAt 扫描时打印一次全 Model 名即可定位

### 遗留
- 箱子拾取后 Chest_Selection UI (选奖励) 仍走「自动选择结算宝箱」功能, 已覆盖 MidRun 场景
- tickTowerPick 只在自动寻路开着时跑 (tickPath 前置 Nav.on 门) — 用户没开寻路打塔时无拾箱, 符合"寻路Bot"定位

---

## [2026-09-05 | 会话4 | v1.12.1] 寻路窗删血条 + 注入通知静音

### 用户需求
① 寻路Bot窗删血条绘制, 只留目的性报告一行 ② 注入时弹的功能开启通知全部不要。

### 改动定位
- **删除** (整链, ~390 行): Nav.hudCreate 的 Blood 容器段 / hudRefresh 血条估算整段 (收集+排序+学习表清理+12行渲染+自适应高度) / Nav.hudReflow / Nav.mobPct / Nav.bloodColor / Nav.bloodRow / Nav.mobAlive / Nav.wireDmgTrack+Nav.dmgTrackListen (DamageDisplay 监听) / Nav.bossHealthListen (ChallengeRunService.BossHealthUpdate 订阅) / Nav 表 hudBlood/hudRows/dmgTrack/mobMaxLearn/bossHp 字段 + mobhp_ PREF 加载循环。hudH 固定 76 (标题 40 + 报告 22 + 余量)
- **通知删除 4 处**: syncClass 职业跟随切换通知 (自动跟角色不需要报) / 自动寻路开启通知 / 自动重开开启通知 / 尾部 "v1.12.0 已加载" Notify
- **保留**: alert-triangle 错误警告类 / 快捷键操作反馈 (传送/重开/回城结果) / 停止全部功能确认 — 这些是要人看的

### 验证
- check_hub 过 (179, 血条链删除后峰值反降 2)
- deploy 双路径+reload 队列已推, 热替换 @1.12.1 加载正常
- 注入不再弹任何通知 (错误除外)

### 遗留
- 血条 v1.11.0 的多血条真百分比代码随本版删除 (数据源+渲染全链), 未来想加回可从 git history 恢复 (v1.11.0 版本段), 判定结论仍在 intel.md

---

## [2026-09-05 | 会话4 | v1.12.0] 无限核心 (Honored One) 职业档案 + 刷本特化调度

### 逆向结论 (详见 intel.md 会话4 条目)
- Definition 反编译: 平A 20格/攻速1.0/系数1.15; 1 Blue 3s 5x 拖拽聚怪可旋转 / 2 Red 2.25s 4x / 3 Hollow Purple 7.5s 4x 直线 / 4 Infinity 18.75s buff / E 无量空处 0伤害控场 100格冻15s 站桩
- 技能模块 require 全崩 (运行时依赖), Skill_Modules 副本是空壳 → 档案 SkipRequire 数据路径
- CD 全部从 LocalPlayer 属性 `Skill{n}_CooldownDuration` 实测, 非猜值

### 改动定位
| 区块 | 内容 |
|---|---|
| CLASS_ARCHIVE_RAW 尾部 | 新档案 "无限核心" (AtkSpd 1.0 Range 20, Skills 1-4 带 Range+Cd, **UltMinMobs=3 / PullSlot=1 / TwistAfterPull=1.6**) |
| buildClassNameIndex | add 无限核心/honored one/五条悟 → "Honored One" |
| skillRange | 档案数据兜底链加 `tonumber(data.Range)` — 模块崩的职业不再全按 15 格 |
| countAliveMobs (findReadySkill 前) | 新 helper: 半径内 Health>0 活怪计数 |
| findReadySkill 终极段 | UltMinMobs 门: 活怪 < 门值且锁的不是 BOSS → tgtE=nil 捏住 |
| fireQueuedSkill | PullSlot 命中 → Cbt.twistUntil/Center/Ang 设置 (旋转窗口启动) |
| Cbt 表 | twistUntil/twistCenter/twistAng/twistTickAt 四字段 |
| Cbt.autoApproach 开头 | 旋转执行: 0.12s tick 绕奇点半径 8 格 MoveTo + 朝向心; 到点/中心没了自动清 |
| 杀戮光环 OnTick | twisting 窗口内不等 0.3s 节流 (内部自带 0.12s) |

### 决策理由
- 终极门阈值 3: 无限核心 E 是 0 伤害控场, 冻住怪 = 平A/技能输出窗口; 残局 1-2 只怪站桩放 = 白亏前摇 15s 里的输出时间。BOSS 锁定时绕过门 (Boss 冻 15s 团队收益大)。
- 旋转半径 8 格 / 角速 0.38 rad/tick (~3.2 rad/s): Blue 奇点拖拽范围实测体感, 绕一圈 ~2s 正好把 360° 的怪带进吸力圈; TwistAfterPull=1.6s 略短于一圈, 剩余怪由奇点吸力收尾
- 旋转挂在 autoApproach 而非独立循环: 复用双光环贴脸的调度位 (近战双开才走), 远程职业不旋转 (kite 优先级更高, 用户手动可打断)
- skillRange 加 Range 字段: Honored One 技能模块崩, 档案 Range 是唯一距离源; 其他档案无 Range 字段不受影响 (HitboxRange 优先)

### 验证
- check_hub 过 (181, +1 为 countAliveMobs, 峰值仍 <195)
- deploy 双路径 + reload 队列已推, 热替换 @1.12.0 加载正常 ("职业档案已内嵌 (11 个)")
- 未实测项: ① Blue 旋转手感 (半径/时长是否合适) ② 终极门 3 只怪阈值是否合用户口味 ③ Hollow Purple 蓄力期间站桩是否被 StartLoop 打断 (服务端动作, 客户端包不干扰, 理论安全)

### 遗留
- Blue 实际吸力半径未精确测 (估计 15-20 格); 若旋转拖不满可加 TwistRadius 档案字段
- Red hold 形态 (以自身为中心 4x) 未自动化 — 拿捏时机难, 先 tap 直线

---

## [2026-09-05 | 会话4 | v1.11.0] 血条真百分比 + 格挡收紧 + 猛攻技能调度 + 假名降耗

### 动机 (用户 5 项需求)
① BOSS 多血条血条百分比失真 (有的正常有的不正常) ② 血条远距离消失 ③ 爬塔祝福想要智能识别不用单独开关 (选箱已有功能不用重复做) ④ 格挡太频繁 ⑤ 审判之刃捏技能狂平A + dr_fakename 慢循环告警。

### 关键发现 (钾实地)
- **BOSS 客户端 Humanoid 是假血**: 实测 Awakened Devil hp=100 max=100 (多血条 BOSS 每条恒 100)。旧血条算法 `hp = track.max - track.dmg` 且 `track.max` 初始吃 maxH(=100), 打穿一条就 `max*1.6` 回涨 — 这就是"不正常"根源。
- **挑战图 BOSS 服务器真血可用**: `ChallengeRunService.RE.BossHealthUpdate` (hp, maxHp), 客户端 `ChallengeRunService` 直接挂在 ReplicatedStorage 根 (非 Knit 目录, RF.GetSessionState 无参直调)。普通地牢图 DungeonRunService.RE 也有 BossHealthUpdate 但主链 BOSS 归因尚未验证。
- 普通图多血条判定: 无学习数据 (learned<=0) + 伤害 > maxH*1.15 + 怪没死 → 必是多血条假血, 当期条内百分比 = `maxH - (dmg % maxH)`。

### 改动定位 (v1.11.0, 行号为改后)
| 区块 | 位置 | 内容 |
|---|---|---|
| BOSS 服务器真血订阅 | `Nav.bossHealthListen` @3193 附近 (dmgTrackListen 后) | BossHealthUpdate → Nav.bossHp {hp,max,at}; 8s 衰减 |
| Nav 状态 | dmgTrack 表 | 新增 bossHp 字段 |
| 血条收集 | hudBlood 段 @5180 | `tower` 局部 + 爬塔全场收集 (跳过 16 格裁剪); Zone 空兜底 `not tower` 门 |
| 血条估算 | hudBlood 段 @5245 | 三分支: 挑战图 Boss→服务器真血 / 多血条首遇→条内百分比 (track.stage=条号) / 其余→原累计制 |
| 血条文本 | @5290 | stage>1 显示 "P<条号> xx%" |
| mobPct | @5360 | 同步条内归一 (排序权重一致) |
| towerWatch | @3228 | 只剩祝福 (Boost_Selection→DungeonBuffService:SelectBuff(1)); while hubAlive 常驻; 选箱代码删除 |
| 爬塔 Toggle | 已删 | "爬塔自动祝福选箱" BindToggle 整块删除, Nav.towerOn 全部清引用 |
| isBossModel | @1821 | 末尾兜底 `return true` → `return false`; IsFodder 检查随兜底一并删除 (前面已全 return) |
| 拼刀动画通道 | hookBossParry @2020 | marker/Keyframe 合并 `fired` 布尔一招一次; Hitbox 通道加 0.9s (_parryAt) 去重 |
| 平A让路 | fireMeleeOnce @1700 | 技能光环开且 findReadySkill 有货 → 本 tick 不平A (技能 tick 0.05s 会立刻发) |
| 出手窗口 | fireQueuedSkill | skillHoldUntil/skillBusyUntil 0.08/0.14 → 0.22/0.22 (防平A包挤掉技能动画) |
| 终极阈值 | findReadySkill | ultMax-5 → ultMax*0.85; 防抖 15s → 3s |
| 技能防抖 | skillSlotReady | 0.12 → 0.05 |
| 假名 | considerFakeLabel @6370 | GetFullName 前置短路 (textMatch+nmCheap 都不沾直接 return); tick 0.3→0.8s; 扫描 10→30 tick (24s); CharacterAdded 补扫保留 |

### 决策理由
- 挑战图 BOSS 选服务器真血而非估算: BOSSMaxHP 548868 级别, DamageDisplay 归因在多人局会混入队友伤害, 真血是唯一可信源。8s 衰减回退估算保底。
- 普通图多血条不写服务器: DungeonRunService.BossHealthUpdate 的事件签名未验证 (会话4 未在普通图 Boss 房实测), 先用客户端归一化, 下次打 BOSS 时 `remote-spy`/订阅验证后可换真血源。
- 猛攻调度用"平A前查技能"而非改 skillPending 断链: skillPending 是从未启用的死代码 (全文只赋 nil), 复活它要同时动 hookAttackAnim/DBreset 链, 风险大收益同。fireMeleeOnce 一个 gate 就让平A每 0.1s 让位技能 tick, 效果等价。
- 0.22s 出手窗口: 覆盖 SkillRE→服务端处理→动画起播的最小时延; 再大会拖慢技能连发节奏 (多充能职业 0.05 防抖连发 2-3 发)。
- 假名不阉割: 扫描降频靠 CharacterAdded 即时补扫兜底新标签; 彩虹渐变刷新每 tick 照旧 (字符串拼接 ~10 个标签, 微不足道)。

### 验证
- `python tools/check_hub.py` 通过 (函数峰值 180 WARN 与上版持平, 0 error)
- 未进游戏实测 (本轮纯代码会话); 待重跑验证: ① 打 BOSS 看血条是否"P2 47%"式条内百分比且不回涨 ② 挑战图 BOSS 血条走真血 ③ 普通怪不再拼刀 ④ 审判之刃技能出手频率 ⑤ fakename 告警消失

### 遗留
- 挑战图 `BossHealthUpdate` 事件参数序实测: 本轮按 (hp, maxHp) 假设接线, 若顺序反了血条会显示错误 — 进挑战图打一波即可确认
- 普通图 BOSS 也可接 DungeonRunService.RE.BossHealthUpdate 真血 (签名未验证)
- devlog 上轮遗留 3 项: 尾部 Notify 文案已修 (v1.11.0), sb 残留已不存在 (搜索 0 命中), 头部功能清单已补全

### 会话4 补丁2: isTowerRun 普通图误判 (用户实测报障, 已修)
- **现象**: v1.11.0 自动寻路在普通地牢直接失效, phase 进 "tower" 躺平
- **根因 (钾实测双铁证)**: ① 普通图 UI `Dungeon_Container.Info` 现在自带 `Depth`+`Wave` 标签 (游戏 UI 更新, 旧 intel 结论"普通图没有 Depth"已过时) ② 打完爬塔后 `Challenge_Dungeons` 实体仍残留在 workspace (与 `Generated_Demon_*` 共存)
- **修复**: isTowerRun 三级判定重写 — `Generated_*` 实体在场 → 一票否决 false (普通图每局新生成带 GUID, 最可靠的"正在跑普通图"信号); `Challenge_Dungeons` 在场 → true; 都没有 (大厅/载入隙) → UI Depth 兜底
- **连带受益**: 血条 tower 全场收集 / towerWatch 祝福 / bossHp 真血都走同一 isTowerRun, 一处修全好; 爬塔图判定不受影响 (无 Generated_)
- intel「爬塔机制」分区旧结论"判定: Dungeon_Container.Info.Depth 存在 (普通图没有)"应视为已证伪 (v1.11.0 pv1659 实测)

### 会话4 补丁: 血条假条根因 (用户实测报障, 已修)
- **现象**: 场景只有一个 BOSS, 寻路窗画出一堆虚假血条
- **根因**: 多血条 BOSS 每条血 = 独立 Model (钾实测: Awakened Devil hp=0 max=100, **无任何属性** — Dead/IsDormant 都没有), 打完一条血旧 Model 留场景。getEnemies 只过滤 Dead 属性挡不住, 血条收集只查 IsDormant → 全画出来
- **修复**: 新增 `Nav.mobAlive(en)` (hudRefresh 前, Nav 方法): IsDormant + `Humanoid.Health > 0` 双重过滤, 三个收集分支 (Zone 内/爬塔全场/16格兜底) 统一换用
- **没动 getEnemies**: 战斗侧全局索引影响面大, 且未报战斗异常; 若之后发现杀戮光环锁死条模型, 再把 mobAlive 逻辑提进 getEnemies
- 同步: check_hub 过 (峰值 180 持平), deploy_dr 已推双路径, 热替换实测 @1.11.0 加载正常

---

## [2026-09-05 | 会话3 | v1.9.5] 全脚本通读归档 + 版本断层澄清 + 挑战塔兼容性

### 版本回退历史 (重要, 澄清 devlog 断层)
- 本条目之前的 2.97 v1.10.0 (钥匙房) 不是当前版本 — **v1.10.x 全系已回退删除**
- 证据: `archive/hub-v1.10.5-pre-keyroom-removal.luau` (271KB, 12:33) = 删除前备份; 当前 `hub.luau` v1.9.5 (228KB, 15:21) 主链版
- 现行主线: v1.9.5 = 岔路/特殊BOSS/钥匙房全部删除后的主链版 (清怪→箱→药→nextHop→Boss房), 与 2.104 条目的删除手术一致

### v1.9.5 结构地图 (6906 行, 接手 AI 按行号定位)
| 行区间 | 模块 | 关键点 |
|---|---|---|
| 1-103 | 头部/加载库 | GameName="地下城战利品者"; StartHidden 建窗前读 PREF |
| 106-253 | PREF 持久化 | 自建 dr-prefs.txt; `t_<flag>` 存 Toggle 状态 (RestoreToggle 0.8s 后程序化恢复); persistKeybindEl 包装 Keybind:Set |
| 254-424 | 服务/工具 | getEnemies 0.18s 缓存 + 玩家角色过滤 (双保险: GetPlayerFromCharacter + UserId 属性); getCurrentRoom 按 Zone 包含 + 最近距离 |
| 426-851 | 职业档案 | CLASS_ARCHIVE_RAW 10 个; buildClassNameIndex 中英硬编码映射 + 模糊匹配; normSkill 归一; 档案有 Skills 即 SkipRequire |
| 853-1046 | Ov 绘制层 | 对象池 (line/bar/dot/arrow/chestTxt) 计数制, frameEnd 隐藏尾巴; ring 是 3D 圆投影分段折线 |
| 1053-1339 | 平A距离/喝药 | liveHitboxReach 占位盒 2*|C0.Z| 规则; atkInterval=0.099/(职业AtkSpd×(1+Stat_AttackSpeed%)) |
| 1347-1600 | 锁定/风筝 | Cbt 表 (寄存器收单); kiteTick 远程拉开/贴近 0.55s 节流; pick 粘性锁 + 残血加权 |
| 1687-2133 | 杀戮光环/拼刀 | DBreset marker 补发; hookBossParry 挂 Boss Animator 动画 + Hitbox 生成双通道; Parry 0.22s 节流 |
| 2218-2439 | 技能光环 | findReadySkill: 大招优先 (UltimateCharge 直读数字, 不等 Ready 信号) → 1..4 有充能就丢; skillCursor 已退化 (公平轮转被冷却好了就丢替代) |
| 2441-2947 | 自动BUFF/宝箱/补药 | BoostSelectionController._OnCardClicked; ChestSelectionController._OnChestClicked/_OnFinish (稀有度倒序, 手动选过不干预); fireproximityprompt 主路 + InputHoldBegin 兜底 |
| 2949-3065 | 移速 | wsTick Heartbeat 常驻 (技能冻移速仅在 LiftSpeed>0) |
| 3067-5300 | Nav 寻路 | damageDisplay 伤害归因血条; nextHop Side 排除; tickPath 状态机: center→fight→loot→refill→hall→boss→done/lobby; 死亡/瞬移 snap 回退 rewind; 卡死 2.8s×3 跳路点→rewind |
| 4737-4785 | 自动重开 | tickReplay: 结算界面 RequestReplay + 卡死 5min 强制重开 |
| 5322-6549 | 视觉 | DPS 面板 (Damage_Dealt 累计制 + 换房清 0 补账); 假名 (Profile/NameText/TitleText 三目标 + PlayerModels 名牌); 闪避 CD 条; 结算动画加速 (覆写 PlayEntries) |
| 6551-6745 | 快捷键/设置 | F1 传送下一房 (要求清怪完成); F2/F3 结算重开/回城; 卸载走 Confirm |
| 6747-6906 | 主绘制循环/收尾 | 双光环融合蓝圈; RestoreToggle 延迟恢复 |

### 通读发现 (未修, 候选 PATCH)
1. **尾部加载通知文案过期**: L6872 打印 "v1.8.0 已加载", 实际 1.9.5 (头部/ScriptVersion/尾部 print 均对, 仅 Notify 文案漏改)
2. **残留变量**: L5062 `en ~= sb` — sb 原是特殊BOSS变量, 删除手术后残留, `sb` 为 nil 全局查找 → 条件恒 true, 无行为影响但应清
3. **头部功能清单漏列**: "自动选择结算宝箱" (L2805 BindToggle) 未写进头部注释功能清单

### 挑战塔兼容性 (本轮新增机制结论, 与寻路关系)
- 当前用户在打 **Double Dungeon 爬塔** (机制见 intel.md 2026-09-05 会话3 条目): 单竞技场, 无 Generated_ 地图
- **自动寻路/F1 传送在挑战图全部无效**: getMapDir 只认 `^Generated_` 前缀, 挑战图 ARENA_ROOT="Challenge_Dungeons" → getCurrentRoom 恒 nil → tickPath 卡 phase="seek"
- 挑战图可用的功能: 杀戮/技能光环, 拼刀 (Boss 波), 喝药, 自动重开 (走 ChallengeRunService.RequestReplay? 未验证 — Nav.tickReplay 调的是 DungeonRunService.RequestReplay, 挑战图是否接受待实测), 假名/DPS/雷达
- 挑战图专属机会 (候选功能): WaveUpdate 对齐波次, 箱波自动捡 (60s 过期), 祝福自动选 (RunBuffStacks 属性已可读)

### 验证
- 本条目纯阅读归档, 无代码改动, hub.luau 保持 v1.9.5 原样
- 上轮会话3 已实测 GetSessionState (Wave 62 双人局) 并回写 intel.md

---

## [2026-09-05 | 会话2.97 | v1.10.0] 自寻路钥匙房 + 岔路价值重构

### 钥匙机制 (钾实地)
- 库存: `Main.Frames.Inventory.Contents.InventorySection.ItemPanel.ItemGrid.key:T1~T5/Master` 的 `Amount` 文本 (xN); Nav.keyCounts 3s 缓存
- 门: Locked_N.KeyModel.ProximityPrompt, ObjectText="Requires <名> Key" → Nav.keyForPrompt 名字反查 tier (Bronze..Celestial=T1..T5, Master 全开) → 库存量>0 才去
- KeyData.CanOpenDoor(keyId, doorTier): Master 全开, 数字 keyId>=doorTier
- 实测: Locked_1 要 Celestial (有26) / Locked_2 要 Gold (有143), 都双箱 (Chest×2+Enemy×1), 门 Door.Animated=Up
- 流程 Nav.tickKeyRoom: 走 KeyModel (25s 超时) → firePrompt (hold 0.8) → 门升 → 房内有怪先杀 (60s 兜底) → chestInRoom 逐箱 firePrompt → skipChest → 全拿完 keyDone 回主链
- 双入口接管: 人在 Locked_N Zone 内 (lockedAt 反查) / 大房清完 findKeyRoom (60 格内最近 worth 房)
- 注意: Locked_N 是独立 Model (不匹配 Room_), getCurrentRoom 看不见 — 全靠 Zone 反查

### 岔路重构 (用户规则)
- sideWorth: 纯怪点 (Enemy_Spawn 无 Chest_Spawn) 不进; 箱点进; IsLootRoom 属性必进; IsSpecialBoss/SpecialBossId/Skull_Totem/Parts 内 Totem|Summon 排除; KeyModel 排除 (走钥匙房流程)
- tickSide 锚点 = Entry 门口 (不再 roomCenter); side_go 进门目标 = 房内最近箱 > 最近怪 > center
- 清理点 (6 处 sbExitAt=nil) 全部补 key 字段, 防残留旧时间戳

### 验证
- check_hub 过 (峰值 179 WARN); 部署 potassium workspace; 热替换 @1.10.0 零错误
- 感知实测: 库存 T1=44/T2=175/T3=143/T4=85/T5=26/M=0; Locked_1/2 worth=true
- 用户实测: 开锁/双箱杀怪/无钥匙跳过 — 待反馈

---

## [2026-09-05 | 会话2.109 | v1.9.5] 归档整理 + 全脚本深度审查修复

### 归档
- `archive/hub-v1.9.5-final.luau` (定版快照, 7032 行/223KB)
- changelog 重整: 75 个唯一版本去重 + semver 线性排序 (此前重复插入乱序)

### 深度审查结论 (7 项发现, 全修复)

| 级 | 问题 | 修复 |
|---|---|---|
| BUG-1 | towerWatch 协程永生: 退出条件 `Nav.on or Nav.towerOn`, 卸载只停 Nav 不清 towerOn → OnCleanup 后协程仍活 | Nav.stop 加 towerOn=false; OnCleanup 补 towerOn=false; while 加 hubAlive 守卫 |
| BUG-2 | 血条 rows 槽位复用: 排序变化时同槽换怪, prevPct 从上只怪串到新怪 → 假拖尾 | prevPct 记录绑 model (row.prevModel), 换怪重置 |
| BUG-3 | prefLoad 键正则 `^([%w_]+)=` 不匹配中文怪名 → mobhp_猩红骑士 永远无法从 PREF 恢复 (学习表重启即失忆) | 正则改 `^(.-)=(.-)$` |
| BUG-4 | mobhp PREF 加载在 Nav 表定义前 → attempt to index nil | 加载段搬到 Nav 表闭后 |
| BUG-5 | BUG-1 补丁造成 OnCleanup 双 pcall 嵌套少 end (编译错) | 删多余 pcall 头 |
| QUAL | mobPct (排序) 与渲染 pct 公式分叉 (m=max(track.max,maxH) vs track.max) → 排序与显示不一致 | mobPct 改用渲染同源 max |
| QUAL | phase="boss" 无出口靠 5min 看门狗 — 注释说明 (不改逻辑) | 注释 |

### 终极积极性二次收敛
- E 块加 `SkillE_OnCooldown ~= true` 服务器 CD 守卫 (之前 10s 防抖 < 15s CD 会白发) + 防抖回到 15s; Charge>=max-5 保留

### 静态审查方法记录
- 死引用 grep (30+ 删函数名) CLEAN; 3 处 task.spawn 退出条件核对; 缓存表清理点核对 (dmgTrack 30s+死亡/centered/skipPot 换图清/mobMaxLearn 学习表永续合理); 空 pcall 无
- 教训: 改 OnCleanup 这类多层嵌套 pcall 区域时, 补丁脚本按行号插入极易配错 — 部署后必须 potassium loadstring 全文编译验证 (本轮 2 次编译错全是补丁引入, 都靠它抓到)

---

## [2026-09-05 | 会话2.108 | v1.9.5] 寻路重规划纠偏 + 血条击杀学习表

### 寻路频繁重规划 (上轮 30 格按点判定的误伤)
- 长路径 (60+格) 行走中人距两端点都 >30 是常态 → 每次都 dropRoute → 无限重规划
- 修: 改**点到 polyline 线段垂距** (Nav.pathOffDist, 0.3s 缓存) >45 且设路 3s 后才触发 — 贴线行走永不误杀, 真离路 (传送/掉出) 3s 内重算

### 血条不减真凶 + 三重修
- **击杀学习表**: Humanoid.MaxHealth 是假的 (服务器不同步), 怪死时用累计总伤害校准 `mobMaxLearn[怪名]` 并落盘 PREF (mobhp_<名>), 下次同怪直接用真实血量 — 几局收敛
- 排序: 按 mobPct 降序 (血多在前), 无数据垫底
- 未受击怪 = 满血绿条 (不再金色误导); 完全无数据 = 灰条
- 旧段残骸 (5255-5289) 二次清理 — 替换段配平又错一次, 用逐行打印定位后删

### 血条渲染数据链 (终态)
DD 事件(target=HRP Part) → 归一化到 Model → dmgTrack[model] 累计 → hudRefresh 读 max(学习表)>track.max>Humanoid → pct → Fill/Trail/排序
---

## [2026-09-05 | 会话2.107 | v1.9.5+] 三小修 + 终极积极性 + 爬塔自动化

### 三小修
1. 尾部通知文案 v1.8.0 → v1.9.5
2. L5063 `en ~= sb` 手术残留删 (sb 已不存在)
3. 头部功能清单补 自动选择结算宝箱/爬塔模式

### 终极积极性 (Charge>=max-5 即发)
- Ready 信号/满格都可能不同步 → Charge 达 max-5 就发包, 服务端没 ready 下轮重试 (发包无损); 防抖 15s→10s

### 爬塔自动化 (Double Dungeon 挑战图, 用户 Wave 62+)
- 判定: Dungeon_Container.Info.Depth 存在 = 爬塔 (普通图无 Depth)
- UI 通道: Main.HUD.Boost_Selection (祝福 Boost_1/2/3) + Chest_Selection (箱 Chest_1/2/3+Finish)
- 协议 (反编译 BoostSelectionController): 祝福 = DungeonBuffService:SelectBuff(1/2/3 编号); 箱 = DungeonRunService:SelectMidRunChests({1,2,3}) (MidRun source)
- Nav.towerWatch 协程: 1.2s 轮询, Boost/Chest UI Visible 时 0.5s 后自动选 (祝福第一张, 箱全选), 4s 防抖
- tickPath 爬塔 gate: isTowerRun() → phase="tower" 直接 return (单竞技场不寻路, 光环独立 loop 继续打)
- UI 开关「爬塔自动祝福选箱」(默认开, pref towerAuto); reportText tower 分支显示波次
- 爬塔节奏档案 (用户情报): 60s 计时 杀怪+1.5s/Boss+5s 上限120s; 每5波3箱60s过期; 每10波Boss+祝福+计时重置; 怪每5波x1.1; Boss 六轮换

### 验证
- check_hub 过; COMPILE_OK + RUN ok (修复 E 块重建时的多余 end 后)
- 待实测: 爬塔自动选祝福/箱子 / 终极 95% 即发

---

## [2026-09-05 | 会话2.106 | v1.9.5] 血条不减真凶: UnreliableRemoteEvent 类型守卫

### 终极根因 (调试钩子 + 外部采样实锤)
- `Player.Remotes.DamageDisplay` 是 **UnreliableRemoteEvent** 不是 RemoteEvent — wireDmgTrack 的 `IsA("RemoteEvent")` 守卫直接拒绝 → **监听从未挂载** → dmgTrack 全空 → 全部怪走金色满条分支
- 坑点: 兜底 WaitForChild 找到同一个实例后**同样被类型守卫拒掉** — 两条路都死在同一个检查上
- 验证: 修后 12s 内 count=35 次归因, Fill={0.85,0} (85% 实时下降) ✓

### 附带修复
- target 归一化: 事件 target 是 **HRP Part** 而非 Model (`Dark Revenant/Model` 的 HRP) — 归一化 FindFirstAncestorOfClass("Model") 归到宿主
- max 自适应: Humanoid.MaxHealth 与真实服务器血量比例未知 → 首估 Humanoid/首击x8, 累计打穿时 max=dmg*1.25 (血条部分回涨, 几击收敛)
- 调试结论: 调试钩子 (_G.RCWTK_DMG_DEBUG) 已清

### 教训
- UnreliableRemoteEvent 与 RemoteEvent 都有 OnClientEvent, IsA 检查要兼容两者 — 反编译确认协议时**连 ClassName 一起确认**

---

## [2026-09-05 | 会话2.105 | v1.9.5] autoexec 旧版根因终局 (双路径) + 职业下拉验证

### autoexec 永远跑旧版的真正根因 (终于抓到)
- autoexec files 列表: `{"dungeon-raiders/hub.luau", "games/dungeon-raiders/hub.luau"}` — **根目录路径优先**
- workspace 里根目录 `dungeon-raiders/hub.luau` 是 11:08 的旧版 (v1.9.5 前的), 而我只部署 games/ 路径 → 每次换图 autoexec 都先读根目录旧版 → "为什么执行还是旧版本"
- 修: tools/deploy_dr.py 改为双路径全覆盖 (games/ + 根目录), 游戏内验证 P1/P2 均 DR_HUB_v195 ✓

### 职业下拉 "none" 验证 (钾上重放解析链)
- idx["审批之刃"]="Awakened Devil EX" / idx["拳击手"]="Boxer" 均命中 (硬编码 add 正常)
- Current_Class=Awakened Devil EX, PREF.classLabel=审批之刃 — 链路通
- Hrunting/审判典狱司/诅咒之子 三个 hint -> NONE: 这三个档案的 Name 与游戏 folder 名对不上 (Hrunting? 审判典狱司?) — **它们在游戏里叫别的名**, 需要用户确认游戏内职业名或从 CLASS_DATA 拿 Name — 下次修

---

## [2026-09-05 | 会话2.104 | v1.9.5] 岔路/特殊BOSS全链路删除 + 拳击手档案

### 用户决定: 只保留主链
- 删除: findSideRoom/sideWorth/tickSide/markSideDone/sideGateFor/侧路感知块 (岔路) + ensureHeroId/findSpecialHall/hallAt/tickSpecialBoss/trySpecialBoss (特殊BOSS走廊) + 全部 side*/sb* 字段与清理点 + reportText 7 分支 + UI 开关
- 保留: 主链 (清怪→箱→药→nextHop出房) / bossout (Boss 房清完找下一段) / rewind freshCleared / nextCombatFrom 防回头 / 血条+伤害归因 / 终极光环 / Bot 窗
- sideWorth/KeyModel 排除随函数删除 — 主链 nextChest 本来只认当前房, 岔路不会再进
- 净瘦身: 7762 -> 6837 行, 寄存器峰值 178 -> 178 (主块 84)

### 手术教训 (第二次)
- 删 `if not isBossRoom` 壳时把壳头删了但壳尾 end 留下 → 3 层错位连环报错 (4631/4687 反复)
- 修法: 缩进栈模拟定位孤儿块 → 对照备份原始结构重建 bossout 段 (isBossRoom 头 + 块 + phase=boss + end + hudRefresh/return + if room 尾)
- 拳击手 (Boxer, Epic): 平A 15 格 1.0 速 1x / SK1 快拳 18格·4s·4充 / SK2 疾扫 22格·8s·0.5s无敌 / SK3 三连 18格·7s / SK4 狼牙 26格·13s / 无终极 (Ultimate 空, E 槽自动跳过)
- 档案 10 个

### 验证
- check_hub 过; 游戏内 COMPILE_OK + RUN ok; @1.9.5 零错误
- 待实测: 主链寻路正常 / 岔路完全不走 / Bot 窗正常

---

## [2026-09-05 | 会话2.103 | v1.9.1] 大招积极度 (Ready 信号滞后)

### "感觉不积极" 真相 (钾上能量计量表实测)
- 大招其实在放: UltimateReady 翻 false + Charge 清零 = 服务器已结算
- 能量积累本身 25~30s/满 (打怪攒 3~13/s, 服务器规则, 客户端无法加速)
- **真瓶颈: UltimateReady 信号滞后 Charge 1~3s** — Charge 已 100, Ready 还要等服务器才翻 true, 期间光环每次扫描都白过

### 修复 (v1.9.1)
- E 槽判定: `UltimateReady == true or UltimateCharge >= UltimateChargeMax` (数字直读不等滞后信号)
- 15s 客户端防抖保留 (防同一能量窗口重复发包)

### 部署
- v1.9.0 重构后首个 PATCH; deploy_dr.py 同步 + 游戏内 COMPILE_OK/RUN ok

---

## [2026-09-05 | 会话2.102 | v1.11.1] 终极饿死修复 + 部署脚本固化

### 满能量不放终极 (G键) 根因: 槽位饿死
- 属性实测全满足 (HasUltimate=true / UltimateReady=true / UltimateCharge=100)
- 真凶: E 检查在 findReadySkill 尾部, 而审批之刃 1-4 技能多充能几乎无缝 — 每次都在 1-4 命中提前 return, E 永远轮不到
- 修: E 检查移到 for slot=1,4 **之前** (大招优先, 能量满先放); 15s 防抖防重复
- 属性情报: SkillE_HasHold=false (tap 直发), UltimateCharge/ChargeMax=100

### 部署纪律固化 (用户明确要求)
- **每次改职业档案/脚本必须立即同步 workspace**, 否则下局 autoexec 注入旧版
- 已固化 tools/deploy_dr.py (仓库->potassium workspace 单命令); 收工/改完必跑
- 换图后看启动日志版本号, 不对就先 deploy 再要求热替换

### 验证
- check_hub 过 (178); 游戏内 COMPILE_OK + RUN ok; @1.11.1 零错误
- 待实测: 满能量 40 格内有怪应立即放 G 键大招

---

## [2026-09-05 | 会话2.101 | v1.11.0] 终极光环(G键) + 钥匙房删除 + sb分派公共化

### 教训: games/ 不在 git, 大规模删代码必须先备份
- strip 脚本两次误伤 (锚点匹配到远处的同名字符串) — 第一次把 27KB 主流程删穿, 第二次 block4 吃到 6145 行
- 正确姿势: 先 archive 备份 -> 精确字符串边界 (唯一注释锚+下一锚) 逐块删 -> 每步 grep 残留 -> check_hub -> 游戏内 loadstring 验证编译
- check_hub 的 Python 解析器抓不到不配平, **游戏内 loadstring 才是编译真相** (本次 :3411 Expected end 就是它抓到的)

### 终极技能协议 (Weapon_Input 反编译, 审批之刃实测)
- G 键 = 槽位 "E" (Keybinds Ultimate="SkillE"), 配置在 Class_Data Get(name).Ultimate = "Lunar Eclipse"
- 发包: Skill:FireServer("E", "tap", dir) / 有 HasHold 的职业是 hold->0.25s 无再 tap
- 前置: HasUltimate=true (解锁) + UltimateReady=true (能量100); CD 属性走 SkillE_* 而非 Skill5_*
- 月食: 35x22x65 hitbox / 15s CD / 判定 8x
- 光环接入: findReadySkill 尾部槽 "E" (40 格内最近怪), fireQueuedSkill 分流 Fire(slot="E"), lastSkillCast["E"]=15s 防抖

### 钥匙房功能整体删除 (用户最终决定)
- 全链路摘除: Nav 表 15 字段 / keyCounts/keyForPrompt/lockedRooms/keyWorth/lockedAt/inLockedRoom/findKeyRoom/tickKeyRoom 函数 / tickPath 2 处接管与派发 / reportText 4 分支 / UI BindToggle / 6 处清理点单行
- sideWorth 的 KeyModel 排除保留 (防岔路误进); chestInRoom 保留 (岔路拾箱在用)
- 残留 grep = 0; 行数 8105 -> 7676

### 特殊BOSS忽视修复
- sb 分派抽 Nav.trySpecialBoss(room,hrp) 公共函数, 两处调用: ① 大房清完 (原位置) ② Boss 房清完出房前 (新 — 分段图走廊常挂在已清 Boss 房 Side 上, 之前不扫就会直接 nextHop 跳过)

### Bot 窗血条增强
- 行背景 = 血条底 (暗红 110,22,22); 新增 Trail 白色残影层 (Fill 之下/文字之下): 血量下降时停留在旧 pct, 0.25s 节流下形成扣血拖尾; 回血/满血跟随
- bloodRow 返回加 Trail/prevPct 字段

### 验证
- check_hub 过 (178); 游戏内 loadstring COMPILE_OK + RUN ok; @1.11.0 零错误, 9 档案
- 待实测: G 键终极自动放 / 钥匙房完全不走 / Bot 房出房后走廊触发 / 血条残影

---

## [2026-09-05 | 会话2.100 | v1.10.5] 审批之刃档案 + 血条Visible真凶 + 钥匙房开关/回程

### 血条空白真凶 (v1.10.5, 此前 1.10.x 一直没修对)
- **bloodRow 返回包装表 {Frame,Fill,Bar}, hudRefresh 写 row.Visible=true 落在 Lua 表上, Frame.Visible 永远 false** (bloodRow 初始隐藏) → 血条从未显示过
- 上轮测试窗直接建 Frame 没走包装表 → 渲染实证误导了排查方向; 16格兜底逻辑本身没错, 是行永远不可见
- 修: row.Frame.Visible / rows[i].Frame.Visible

### 审批之刃 = Awakened Devil EX (Class_Data.Get 实测)
- 新职业 Definition 模块已删, 配置走 Class_Data:Get(名) (API 化第二阶段); Skills[slot] 是**模块名字符串**引用, 配置在 Classes/<名>/Skills/<模块名> 子级
- 平A Range 25 (hitbox 20,10,25) 攻速 1.0 Exotic; SK1 幻影追击 28/5s/2充/冲刺90; SK2 空间斩 35/4s/3充/冲刺70 (hold 版 3x 伤); SK3 坠天 40/9s (6x); SK4 月相 26/15s (6段)
- 档案写入 CLASS_ARCHIVE_RAW (9 个), 映射 审批之刃/觉醒恶魔→Awakened Devil EX

### 钥匙房开关失效 (关了还去)
- 根因: Nav.keyOn/sbOn 硬编码 true, 重载后 Rayfield 恢复 UI 状态但 hub 变量不同步 → UI 关/实际开
- 修: 初始值读 PREF.navKeyRoom/navSpecialBoss, Callback prefSet 持久化

### 钥匙房寻路 (出房穿墙)
- 进房分段 (Entry→KeyModel) 上轮已修; 这轮补**出房回程**: 拿完箱人在死路房内 phase=hall 直飞穿墙 → key_back 阶段 (回 Entry → 门外 3 格 → 交回主链)
- 实测几何: Entry↔Keyhole 11.4 格, Keyhole Y 高 5 格 (钥匙孔在门内侧上方)

### 验证
- check_hub 过 (179); 热替换 @1.10.5 零错误, 职业档案 9 个
- autoexec 缓存旧版问题再现: workspace 文件是新版但 potassium autoexec 注册表跑旧内容 — 需要用户在注入器面板重新勾选 autoexec 脚本刷新; 或每次换图后手动要求热替换

---

## [2026-09-05 | 会话2.99b | v1.10.4+1] 钥匙房穿墙 + 血条16格兜底

### 穿墙根因 (代码考古)
- Locked_N 的 Connectors **只有 Entry** (实地: conns=[Entry]), KeyModel 在墙内 — tickKeyRoom key_go 直连 Nav.go(KeyModel) 跨独立 Model 算路, Pathfinding 失败 → shapePts 直线/拐肘**穿墙**
- 修: 两段走 — ① 人→Entry 门 (allowHigh=false, 贴墙外沿) ② 距门<10 格 → KeyModel (门内短段)。via 点 = Entry 向 KeyModel 推进 2 格 (贴门内侧)
- 超时 25s→30s (分段多走一段)

### 血条空白二次修
- 上轮只修了 BOSS hum=nil; 用户仍报空白 → 补 16 格贴身兜底: Zone 内 0 态时拉 16 格内活怪 (走廊/门口/叠区也有显示), 上限 6 行
- 渲染层实证: 钾上复刻 bloodRow 构造测试窗 (3 行彩色血条) — 渲染管线无问题, 问题在数据收集 (room=nil → mobs 空) — 16 格兜底正是补这个
- 换图 autoexec 又载旧版一次 (新服触发), 重部署压制; workspace 文件校验 1.10.4 ✓; 部署后必看启动日志版本号

### 验证
- check_hub 过 (179); 热替换 @1.10.4 零错误; 测试窗渲染实证通过
- 待用户实测: 钥匙房走门不穿墙 / Bot 窗怪血条显示

---

## [2026-09-05 | 会话2.99 | v1.10.4] 寻路窗血条空白 (特殊BOSS 无 Humanoid)

### 根因 (钾实地)
- 特殊BOSS 实体 (Scarlet Knight) **无 Humanoid** (R6 身体 + AnimationController, attrs 只有 ItemId, 无 billboard 无客户端血量) — 普通怪 (Great Mage/Zombie) 有 Humanoid 正常
- 打 BOSS 时血条区 hum=nil 全 skip → 窗口"全空白只有目的信息" — 与用户症状完全吻合
- 客户端确实无 BOSS 实时血量源: 实体无血量 attr/Value, 无 bossbar UI (Healthbar_Container 是玩家自己的 HP), 血量纯服务器侧
- 换图注意: workspace 的 hub.luau 曾被还原成 1.8.1 (autoexec 读 workspace 相对路径) — 重部署即恢复, 部署后要看启动日志版本号

### 修复
- hudRefresh 血条循环 hum=nil 分支: 金色满条 + "★ 名字 (战斗中)" 状态行 (视觉确认目标在场)
- 普通怪血量行为不变 (Humanoid.Health/MaxHealth 实时)

### 验证
- check_hub 过 (179); v1.10.4 热替换零错误 (DR_HUB_v1104)
- 待用户实测: 房内普通怪血条 / BOSS 金色状态条

---

## [2026-09-05 | 会话2.98 | v1.10.1~1.10.3] 特殊BOSS三连修 + 钥匙房派发修复

### 关键游戏情报 (用户确认)
- **特殊BOSS = 高级精英怪, 打完无结算界面, 直接回大房继续主链** — 与 intel 旧认知"SpecialBoss 召唤制"互补: Demon 图猩红骑士直接在主链 Boss 房刷 (Room_9 IsSpecialBoss=Scarlet Knight, SpecialBossPrespawned=true), 不是走廊尽头召唤
- Demon 地图**分段生成**: 推进到新段才实例化岔路门/走廊 (SpecialBossHallway_Side_Room_8 曾是空壳, 后激活为 Side_Room_13)

### v1.10.2 fight 兜底误报
- 特殊BOSS 1 只怪数恒定, 旧 60s 怪数不减=跳过 误杀正常输出 → 兜底判据改"怪数不减 **且总血量不降**"; 血量在掉重置计时; Boss 房 240s
- fight 分支顺手累加 hpSum (怪列表已有 hum 访问, 零额外扫描)

### v1.10.2 Boss 房出房 (无结算死锁修复)
- 旧: `not isBossRoom` 挡掉出房逻辑, Boss 房清完 phase="boss" 干等 atEnd() → 特殊BOSS无结算=死锁"正在: Boss房"
- 新: Boss 房清完 (无怪无箱) → nextHop 分段走 (Exit门→下一段房中心, computePts 两段拼接); 普通Boss房有结算, atEnd 在 tickPath 最前优先接管不受影响

### v1.10.3 特殊BOSS打完又回去 (双回头路径封堵)
1. 出门瞬间人叠旧房 Zone (距中心<32) → 误判"死亡回退" rewindToRoom 拉回。修: `freshCleared = Nav.leaving==房名 and not roomHasEnemies` 不回拉
2. nextCombatFrom 无解时 combatByNum(afterN)→nextHop(prev) 从旧房绕回旧目标。修: 目标房号≤afterN 直接拒绝 (只前进)

### v1.10.3 钥匙房派发 (无视修复)
- 根因: findKeyRoom 贴身60格, 钥匙房 ParentRoomIndex=13/16 距人几百格 → 永不派发
- 修: 双轨 — ① ParentRoomIndex==当前房号 → 不限距离派发 (同房多间取最近) ② 兜底 120 格贴身
- 开锁链路已验证: firePrompt→prompt hold0.8→服务端验钥匙→Door.Animated 变 Up; fireproximityprompt 存在; MaxActivationDistance=10, 走到7格内 fire

### 验证
- check_hub 过 (峰值 179); v1.10.3 热替换零错误 (DR_HUB_v1103)
- 用户实测反馈: 特殊BOSS不再跳过/不再回去/钥匙房会去 — 待最终确认

---

## [2026-09-05 | 会话2.96 | v1.9.0] 职业档案缺失(部署断层) + 寻路感知系统大改

### ⚠️ 部署断层 (最重要教训, 给所有接手 AI)

**仓库 ≠ 游戏运行目录**。 potassium 的 `readfile`/`isfile` 工作目录在:
```
C:\Users\CARSER\AppData\Local\Potassium\workspace\
```
改完仓库 `D:\BuildProject\RoLua\Core\games\dungeon-raiders\hub.luau` 后**必须同步拷贝过去**, 否则游戏端热替换载入的还是旧版! 本次用户"蔚蓝恶魔档案消失"即此因: 游戏端一直跑 v1.3.2 (6 档案), 仓库已迭代到 1.9.0 (8 档案)。

**部署命令** (python shutil.copyfile 原字节拷贝, 防中文路径/BOM):
```python
import shutil
shutil.copyfile(r'D:\BuildProject\RoLua\Core\games\dungeon-raiders\hub.luau',
                r'C:\Users\CARSER\AppData\Local\Potassium\workspace\games\dungeon-raiders\hub.luau')
```
**验证三步**: ① `readfile(...)` 后 `src:find("版本串")` ② 启动日志看 `@x.y.z` ③ `职业档案已内嵌 (N 个)`。

另: Class_Data 已变 API 模块 (Exists/Get/GetClassFolder 函数表), `buildClassNameIndex` 的 `pairs` 收 table 值拿不到官方键 — 但硬编码中英映射 + folder name→name 兜底仍工作, 8 档案全解析。`Definition` require (Azure Devil/Shinobi/Kage ok, Vacio fail) 只影响官方名, 不影响硬编码。

### v1.9.0 寻路改动 (用户报: 不打猩红骑士岔路BOSS / 岔路来回 / 打完卡死 / UI 要目的性报告+血条+自适应)

根因 (钾实地 + 代码考古):
1. **findSpecialHall 永远 nil**: `map:FindFirstChild(GetFullName())` 用全路径查直接子级 — 必 nil → 特殊BOSS分支从未触发。修: 缓存存 Entry part 引用直接比距离 (阈值 2→8 格与 sideMap 一致)
2. **走廊分段流送**: 空壳走廊 (无 Entry/Exit/Zone) 在未推进段; 岔路门开在新推段。修: `Nav.hallAt(pos)` Zone 反查人在哪条走廊 + tickPath 人在走廊即接管 (不依赖 findSpecialHall 从大房触发)
3. **尽头小房卡死**: 只 Entry 无 Exit 的战斗房是 isCombatRoomModel → 主流程当主房 → nextHop 无解跨房直飞。修: tickPath 反感知 (无 Exit + 有 Entry + 战斗房) 强制走 tickSide, `sideGateFor` 反查回程门 (Side 重合 > 最近主链 Entry 兜底)
4. **岔路配错门**: sideMap 取第一个命中 → 双岔路 A/B 都配到 B。修: 取最近 Entry
5. **sbDone 键统一**: "hall:走廊名" 格式贯穿 (触发/超时/tickSpecialBoss/走廊反查)

### UI 重做 (用户要求)
- 删 起点/终点/现在/怪物数 四行坐标信息 → 一行 `Nav.reportText()` 目的性报告 (phase + 房号 + IsLootRoom/SpecialBossId 属性 + 剩余怪数, "正在: 清理Room_2怪物 (剩 5)")
- 怪物血条: 房内 (或岔路内) 活怪按血量降序, 上限 12 行, 0.25s 节流, 绿/黄/红
- 高度自适应: 68 + n*18 + 8, 变化 ≥9 才 reflow; 窗重心在下半屏→向上长 (底边不动), 上半屏→向下长
- 已知简化: reportText 的 fight/side_fight 分支每 tick 调 mobCount (Zone 内怪计数), 怪多时略重但 tick 本就 0.18s 间隔

### 验证
- check_hub 静态过 (峰值 178 WARN <195)
- 热替换三连: 游戏端日志 `@1.9.0` + `职业档案已内嵌 (8 个)` + `DR_HUB_v190 loaded`, 零错误
- 实地结构验证: Demon 局 Room_8 Side×2 → Room_10 (IsLootRoom=true, ParentRoomIndex=8); Room_9 attrs IsSpecialBoss/SpecialBossId=Scarlet Knight/SpecialBossPrespawned
- 用户实测: 猩红骑士岔路是否进/打完是否回主链/窗体表现 — 待反馈

---

## [2026-09-05 | 会话2.94 | v1.8.1] 修小房/特殊Boss走廊重复进 + 死门来回走

### 根因 (用户报: 只会重复来回进小房, 还进封死死门小房)
1. **sbDone 记账 key 不一致** (主因): 触发块查 `sbDone[Side part GetFullName]`, tickSpecialBoss 标 `sbDone[走廊 Model GetFullName]` — 永远对不上, 特殊Boss走廊每 tick 判"没打过"无限重进。修: 统一按 Side part GetFullName 记账 (Nav.sbGateName 桥接)
2. **死门小房无超时**: side_go (不在房内) 每 tick 重试走门, 封死 = 永远到不了 → 来回走。修: `Nav.sideGoAt` 去路 20s 超时强标 done + 通知
3. 回程 15s (`Nav.sideBackAt`) / sb 尽头 15s (`Nav.sbExitAt`) 兜底, 卡门强标 done
4. 清理点 (stop/rewindToRoom/rewindFromPos/lobby) 补清全部新计时字段, 防残留旧时间戳导致"一进来就超时"

### 验证
- check_hub 静态过; 热替换接管干净 (启动日志 1.8.1)
- 用户已重开 Snow 图, 下一局观察: 死门房 20s 跳过, 特殊Boss走廊只进一次

---

## [2026-09-05 | 会话2.93 | v1.8.0] 岔路小房跳过 + 装备攻速

### 岔路小房: 不是进不去, 是主链直接 nextHop
Demon 图钾实测 `Room_24.Side` ↔ `Room_25.Entry` dist=0, Zone 75×71, Spawns Enemy_Spawn×4 + Chest_Spawn×2 + Rare。nextHop 用 sideHit 把 Room_25 从主链踢掉 (设计如此), 指望 findSideRoom 另走。但 `sideWorth` 只认已刷出的 `DungeonChest_` / 非休眠活怪 — 门外探测 **CHEST in25=0, 活怪=0**, 判空立刻 `sideDone` 然后走 Exit 去下一战斗房。

改:
- `sideHasSpawns`: 有 Enemy_Spawn / Chest_Spawn* 就算值得进
- findSideRoom 只返回未 sideDone 且 worth 的 Side; 空模板才标 done
- 清完小房 `markSideDone` (回程到门口), 避免刷怪点一直 worth 死循环
- 进门后 1.4s 空窗等流送, 再判定空房回主链
- Side↔Entry 配对放宽到 8 格

锁门 `Locked_N` 仍不配对 (不是 Room_N)。WallCap 无刷怪点, 继续跳过。

### 双光环装备攻速
玩家属性 `Stat_AttackSpeed=19.58` (StatInfoData Entries[16] Cap=60, ResolveDisplay 即百分比)。公式: `间隔 = 0.099 / (职业AtkSpd × (1 + (Stat_AttackSpeed + AchBoost_AttackSpeed)/100))`。蔚蓝 1.35 × 1.1958 ≈ 1.61 → 0.061s。不扫背包, 属性已是穿戴汇总。`Cbt.atkInterval` 0.4s 缓存, 按 Current_Class 对档案, 不踩 classIdx 词法坑。

### 验证
- check_hub 过 (177 WARN 既有)
- 小房/攻速待热替换后实战: 大房清完 HUD 应出「去岔路小房」而不是直接过廊

---

## [2026-09-05 | 会话2.92 | v1.7.0] 冰图特殊Boss走廊 (觉醒恶魔) 自动插入

### 需求与结论
用户要求冰图寻路顺路打觉醒恶魔 (Devil Heart 35% 掉率唯一来源)。Snow 图结构实测: `SpecialBossHallway_Side_Room_12` (Zone 43×80, Connectors Entry+Exit) 挂在 Room_12 的 Side 上; 走廊 Zone 会**动态卸载** (第一次探到 43×80, 几分钟后 FindFirstChild("Zone")=nil); 觉醒恶魔模板在 workspace 顶层隐藏位置 (hp=100, 无 IsDormant 属性), 召唤/激活后传送进战场。

### 实现
- `Nav.findSpecialHall(room)`: 走廊 Entry part ↔ 大房 Side part 位置重合 (<2格) 配对, 走廊列表缓存 2s (sbHallByEntry: Entry path → hall Model)
- `Nav.sbWorth(hall)`: Zone 存在且 roomHasEnemies(hall) 才进; **Zone 卸载 = 空走廊跳过** (roomHasEnemies 对无 Zone 返回 true 的坑要挡, 否则死循环进出)
- `Nav.tickSpecialBoss(hrp)`: sb_back 回程 (回 Side 门口) / Zone 内怪扫描 (近战贴怪, 远程 kite 站位) / cnt=0 → 回程; sbDone 按 Side part GetFullName 记 (回程完成才标)
- 触发: tickPath 里 side 触发块之后、boss 房分支之前; 人在走廊内前置拦截 (走廊不是 Room_N, getCurrentRoom 返回 nil, 但拦截防路径污染)
- 不自动消耗召唤钥匙 (Skull_Totem 交互留给用户); 只打已刷出的怪
- 4 分钟打不死兜底撤退 (6 血条 Boss); UI 开关「冰图打觉醒恶魔」(dr_special_boss) 默认 true
- kite 禁列表加 sb_go/sb_back (sb_fight 放行, 远程 kite 站位输出)

### 验证
- check_hub 静态过; 热替换 DR_HUB_v170 接管干净, 稳态只剩既有 fakename/auto_nav 建索引告警
- 实战待验证: 走廊里有活恶魔时的 sb_fight 流程 + 击杀后回主链; 用户当前在 Snow 图 Room_12 附近可实测

---

## [2026-09-05 | 会话2.91 | v1.6.0] 蔚蓝恶魔档案 + 近战双光环贴脸

### Azure Devil (蔚蓝恶魔) 档案
- `RS.Classes.Class_Data.t["Azure Devil"]`: 平A **Range=19** HitboxSize(15,10,19) **AttackSpeed=1.35** (全职业最快) TurnCount=4 ParryDuration=0.6 ParryCooldown=1.8 DamageType=Physical
- 技能 (decompile + AnimationName 槽位确认): 1=Spatial Cut Range35 Size(25,10,35) cd4×3 Dash70 AirHitbox(20,30,30) / 2=Cross Cut Range28 Size(24,40,30) cd7 Dash90 IFrame0.5 / 3=Void Cleave Range30 Size(28,10,30) cd10 Stationary / 4=Judgement Rush TickRange22 Size(24,12,24) cd15 Tick0.15 MaxDuration6 Stationary
- StationarySkills[3]=true [4]=true, NoKnockbackSkills 2/3/4=true
- 档案条目 + add("蔚蓝恶魔"/"azure devil"/"蔚蓝", "Azure Devil")

### 近战双光环效率 (两项)
1. **平A节流跟攻速**: fireMeleeOnce + melee OnTick 的固定 0.1s 改 `0.099/AtkSpd` (同源公式)。攻速 1.35 → 0.073s。原理: 平A节奏本应跟动画 (攻速加速动画), DBreset 补发被固定 0.1 硬节流挡掉 = 漏刀。AtkSpd 入档案 (忍者 1.1 / 阿蒂米斯 1.28 / 蔚蓝恶魔 1.35, 其余默认 1), normalizeEntry 解析
2. **贴脸补位** `Cbt.autoApproach`: 双光环开启 (且非远程非 kite) 时, Cbt.pick(平A范围) 无怪 → 朝 25 格内最近活怪 MoveTo 到 reach*0.7 处。0.3s 节流 + 目标去重 0.5s + MoveTo 被 WASD 输入覆盖 (用户手动走位不冲突)。技能范围内怪由技能光环照常打, 平A贴脸补真空

### 错误学习
- **Cbt.autoApproach 首次热替换炸** `:1213 attempt to index nil with 'autoApproach'` — 函数插在 `local Cbt` 声明之前, 词法作用域拿到的是全局 Cbt (nil)。与 2.87 会话 Nav 同款坑第二次犯! 教训升级: **往既有 Pack 表加函数, 先 grep `local <表名> = {` 行号, 新代码必须放它后面**; 或者声明处前向 + 后面赋值。

### 验证
- check_hub 静态过 (177 WARN 既有); 首次热替换失败 (上述), 修复后接管干净 DR_HUB_v160, 启动「职业档案已内嵌 (8 个)」
- 平A加速实测待用户开双光环打怪观察; 服务端按动画节奏校验, 0.099/1.35≈0.073 与动画周期匹配, 超发包会被服务端自然拒绝 (无害)

---

## [2026-09-05 | 会话2.90 | v1.5.0] Vacio 职业档案 + 双光环融合圈 + BUFF 随机

### Vacio (真空) 档案 — 反编译+Class_Data require 实测
- `RS.Classes.Class_Data` (ModuleScript!) require 后 `t["Vacio"]`: **Range=21** HitboxSize(15,15,21) AttackSpeed=1 TurnCount=4 ParryDuration=0.6 DamageType=Magic Rarity=Celestial
- UseProjectile=false — 弹道字段 (ProjectileSpeed=90 等) 是摆设, 平A 还是前方盒判定
- 技能模块 `RS.Classes.Vacio.Skills/*` 钾上 require 返回空表 (纯 Activate), 判定走 decompile:
  - 1=Flash Step (Ability_1): HitboxRange=30 Size(25,15,30) cd5 MaxCharges=3 DashSpeed=80 DashDuration=0.15 IFrame=0.6 ParryDuration=0.3 MaxDuration=3
  - 2=Cero Blast (Ability_2): HitboxRange=35 Size(20,20,40) cd12 MaxDuration=3
  - 3=Sonido Barrage (Ability_3): HitboxRange=30 Size(20,15,32) cd14 BarrageMaxDuration=1.5 TickInterval=0.08 MaxDuration=4 (StationarySkills[3]=true, NoKnockbackSkills[3]=true)
  - 4=Javelin Toss (Ability_4): HitboxRange=40 Size(30,40,40) cd16 LiftSpeed=0 MaxDuration=3 (StationarySkills[4]=true)
- **Ranged=true** (用户确认法师远程): 技能 30~40 格但平A 21 < 26, 现有 "MeleeRange≥26" 规则判不出, 档案必须显式 Ranged
- CLASS_ARCHIVE_RAW 加条目 + buildClassNameIndex 加 add("真空","Vacio")/add("vacio","Vacio")
- 老坑复用: Class_Data 从 GameInfo 挪到了 RS.Classes 下 (hub 代码本来就查 RS.Classes.Class_Data, 没踩)

### 双光环融合圈
- drawFrame: meleeEnabled+skillAuraOn 同时开 → 只画一圈蓝 (RGB 80,140,255), 半径 = max(平A, 4技能最大技能范围); 单开行为不变 (红/黄)
- drawCombat 锁定目标小圈颜色同步: 双开=蓝 (原橙 255,140,40), 保持"范围圈/锁定圈"色一致

### BUFF 无偏好随机
- buff OnTick: `bestIdx` 全不命中时 `math.random(1,#cands)`, 不再 return 卡住; sig 去重照旧 (同候选组合只点一次)

### 验证
- check_hub 静态过 (176 WARN 既有); 热替换 v1.5.0 接管, 启动日志「职业档案已内嵌 (7 个)」
- drawFrame/drawCombat/BUFF 逻辑代码审读; 双圈融合 + Vacio 拉开待实战观察
- 用户当前角色已切 Azure Devil (会话中切职业), Vacio 档案留档给下次使用

---

## [2026-09-05 | 会话2.89 | v1.4.0] 岔路小房 (Side) 智能拾取

### 结构结论 (Demon 图钾实测, 待回写 intel)
- 小房 = 死路 `Room_N` (Connectors 只有 Entry 无 Exit, zone 74x70, 模板含 Enemy_Spawn×4 + Chest_Spawn×2 + Chest_Spawn_Rare)
- **Side↔小房配对**: 大房 `Connectors.Side` part 与小房 `Entry` part 位置重合 (dist<2 格) 才算连通; Room_4→Room_5 / Room_15→Room_16 实测 dist=0。距其它 Entry 近 (76/111 格) 是模板重合假象, 别用"最近 Entry"配对
- 锁门小房 = 独立 `Locked_N` Model (Door + KeyModel.Keyhole + DungeonChest 在内), 无 Entry, 配对天然排除
- 小房内容以**现场实例**为准: 本局 Room_5/10/16 全空 (模板在箱怪没刷), 情况 1; 判定"值不值得进"只看现场 DungeonChest_ 实体 (未 skip) 或活怪在 Zone 内
- WallCap_Side_Room_N.Door 是封死的 Side 装饰门 (Size.Y≈10 过不了 isSoftPart 软化), 配对不上的 Side = 封死, 别硬闯

### 实现 (tickPath 内, hall 分支之前插入)
- `Nav.findSideRoom(room)`: Side part × 全图 Room Entry 位置重合配对, 结果缓存 `Nav.sideMap` (key=Side part GetFullName) 2s 节流
- `Nav.sideWorth(target)`: 全图扫 `DungeonChest_` (inZone 小房, 未 skipChest) 或 Zone 内活怪 → 有货才去; 空模板/只怪房自动跳过并标 `Nav.sideDone[sideFullName]`
- `Nav.tickSide(hrp)` 状态机: side_go (去 Side 门口→进小房) → side_fight (近战贴怪 MoveTo, 远程站桩等怪冲脸; 45s 怪数不减 sideLooted 放弃追怪) → side_loot (firePrompt 捡箱→skipChest) → side_back (回 Side 门口 Nav.go) → phase="hall" 续主链
- 触发时机: 大房 fight/loot/refill 全落完 (tickPath hall 分支前), 符合"大房清完才去小房"顺序
- 防污染: 人在小房内 (inZone sideRoom) 时 tickSide 前置拦截, 不让 getCurrentRoom 把小房当主房 (否则 nextCombatFrom 会从死路小房算主链路径穿墙)
- 清理点: Nav.stop / rewindToRoom / rewindFromPos / lobby 全清 side 状态; sideDone 按 Side part 记, 死亡重生保留 (不重复清已清的小房)
- kiteTick 排除 side_* phase (远程不抢路, 小房内站桩打, 怪会冲脸)
- HUD phaseText: side_go=去岔路小房 / side_fight=小房清怪 / side_loot=小房拾箱 / side_back=回主链

### 验证
- check_hub 静态过; 热替换 v1.4.0 接管干净
- 本局小房全空无法实测 side_fight/side_loot; 实测路径: 下一局遇有小房/有怪小房的图观察 phase 与拾箱

---

## [2026-09-05 | 会话2.88 | v1.4.0] 寻路走空旷侧

- `computePts` AgentRadius 3→4: PFS 自动绕开窄缝/贴墙路径, 宁绕远不钻缝
- `walkTick` 加前方挡路侧滑: 距下一路点 >2 格且前方 5.5 格被挡 → 左右各 60° 探 6.5 格, 往更空旷侧偏移 3.5 格走; 探测排除角色/路径标记文件夹
- 与 laneMid (静态取中线) 互补: laneMid 管建路, 侧滑管行进中临时障碍 (杂物/漏网 soft part)
- 验证: check_hub 静态过, 热替换 v1.4.0 接管干净, 稳态无新告警; 实战待观察

---

## [2026-09-05 | 会话2.87 | v1.4.0] 卡死强制重开 + kiteTick Nav 空引用修复

### 卡死看门狗 (用户需求)
自动重开开着时, `Nav.tickReplay` (Interval 0.6s) 里加位置采样: 记 `Nav.stuckPos`/`Nav.stuckSince`, 新采样与上次距离 ≤6 格算"没怎么动", 持续 300 秒 → 无条件 `DungeonRunService:RequestReplay()` (不等结算 UI), 带 4s 节流共用 `Nav.lastReplay`。死亡/不在局内时清零重计。6 格阈值容忍小幅漂移 (风筝/击退/寻路抖动)。通知文案同步改为「结算 / 卡死5分钟」。

### fight 阶段拉怪 + 打完才走 (用户需求 "每个房间必须打怪才能后续")
原 `tickPath` fight 分支只标 phase 就 return, 近战遇到光环外的怪 (远处/墙边) 永久卡死, 也没兜底。改:
- fight 分支扫房内活怪 (排除 IsDormant): 最近怪 > `getMeleeRange()` 且非远程 → `Nav.go` 拉怪 (`hallKey="f:<怪路径>"` 去重), 怪进光环清路点停手让光环打; 远程职业仍由 kite 循环站位
- 兜底: `Nav.fightCnt`/`fightSince` — 60s 怪数纹丝不动 = 打不到 (卡墙), 置 `Nav.forceClear[房名]` 放行走箱子/出门, 通知「有怪打不到, 跳过继续」; fightCnt 变动即重置计时
- forceClear 清理点: `Nav.stop` / `rewindToRoom` / `rewindFromPos` (死亡重生怪重刷, 必须清否则漏怪)

### 顺带修: dr_ranged_kite 每帧报错
控制台刷屏 `loop 'dr_ranged_kite' 异常: :1256: attempt to index nil with 'on'`。根因: `Cbt.kiteTick` 定义于 ~1241 行, 引用 `Nav`, 但 `local Nav` 声明在 ~2848 行 — 词法作用域上 kiteTick 捕获的是**全局** Nav (nil), 与 2848 的 local 表无关。开杀戮光环+远程职业就炸。修: kiteTick 前加 `local Nav = {}` 前向声明, 2848 行去掉 `local` (填充同一 upvalue)。教训: **跨区共享的状态表, 引用前必须前向声明, 别依赖"反正后面会 local"**。

### 验证
- `python tools/check_hub.py` 静态门过 (176 WARN 为既有)
- 热替换接管 DR_HUB_v140, 启动日志干净, 稳态无 dr_ranged_kite 报错
- 拉怪/兜底路径代码审读确认; 实战待用户开自动寻路观察 (打不到怪 60s 应出「跳过继续」通知)

### 同步
钾工作区双路径 (workspace/hub.luau + workspace/dungeon-raiders/hub.luau) 已更新 v1.4.0。

---

## [2026-09-05 | 会话2.86 | v1.3.2] 同步钾工作区

hub/autoexec/lib 拷到 Potassium workspace 双路径。当前 v1.3.2 / DR_HUB_v132。

---

## [2026-09-05 | 会话2.85 | v1.3.2] 补药完卡住

灌完仍 needPotion: 账号 MaxPotions 大于本局能灌的量, 或锅边只 fire 不离开. 改: 靠近炼药锅后数量涨了/已满/2秒不再涨 → skipPot 本房, 清路点, 同一 tick 走 nextHop. 人在 Zone 外时 nextCombatFrom 空则按 lastRoomN 的 Exit 接下房.

---

## [2026-09-05 | 会话2.84 | v1.3.1] 同步钾工作区

hub/autoexec/lib 拷到 Potassium workspace 双路径。当前 v1.3.1 / DR_HUB_v131。

---

## [2026-09-05 | 会话2.83 | v1.3.1] 远程杀戮拉开

进战斗房原先无条件走 Zone 中心, 远程站进怪堆。Cbt.isRanged: 档案 Ranged(阿蒂米斯) / 平A≥26 / 锻造霸主弓形态。有怪时跳过 center; StartLoop dr_ranged_kite 贴射程约 58% 站位, 贴脸或身边≥2只就后退, 出圈再靠近, 不出房间、不爬高。捡箱/补药/过廊不抢路。近战不走这套。

---

## [2026-09-05 | 会话2.82 | v1.3.0] 精英+Boss 拼刀

Demon 现场 Awakened Devil: IsBoss=true 同时 IsFodder=true, 旧逻辑先看 fodder 直接不拼. 改: Boss/MiniBoss/HighlightPriority/IsElite/名册优先; 纯 IsFodder 才当小怪. 非 fodder 当精英.

成功率: 本地节流 1.7s 挡住 Hit 标记补发, 改 0.22s + Parry_Cooldown_Active; 预备动作 58% 处发; 多挂 Attack/Impact/Keyframe; 挂钩时处理正在播的轨; 近距 14 不看朝向.

---

## [2026-09-05 | 会话2.81 | v1.2.9] 同步钾工作区

hub/autoexec/lib 拷到 Potassium workspace 双路径。

---

## [2026-09-05 | 会话2.80 | v1.2.9] 卡住二段跳


walkTick 判定位移不足时 Nav.stuckHop: Jump + 0.16s 再跳一次. 第一次只跳不改路点, 第二次跳并跳过路点, 第三次 rewind.

---

## [2026-09-05 | 会话2.79 | v1.2.8] Demon 杂物卡寻路

现场 `Generated_Demon_*`. 可撞杂物: ClosedMediumWoodenBox / Crate1 / FirewoodPileLarge / Coal Pile / POTE* / 装饰 TreasureChest* / Rock.001. 真宝箱 DungeonChest_ 本身 CanCollide=false. MoveTo 直线撞箱, 中线探墙也把箱子当墙.

改: isSoftPart 认这些名字; softenNear 关 CanCollide+CanQuery (否则射线仍当墙); 关寻路照旧还原. 墙/Zone/Hitbox/角色部位不碰.

---

## [2026-09-05 | 会话2.78 | v1.2.7] 同步钾工作区

补上捡箱 if 后把 hub 再拷进 Potassium workspace 双路径。

---

## [2026-09-05 | 会话2.77 | v1.2.7] 同步钾工作区


hub/autoexec/lib 再拷到 Potassium workspace 双路径。

---

## [2026-09-05 | 会话2.76 | v1.2.7] 走中间 + 不爬高


PFS AgentRadius 2 贴墙, Jump 会爬台. 改半径 3, 默认禁止 Jump; 路点左右探墙取中线 (两边都空着不拉). 高度差>4.5 丢掉, 终点拍回当前地面. 例外: 捡箱 / 廊中祭坛箱 / 进 Boss 房. 补药仍走平地.

---

## [2026-09-05 | 会话2.75 | v1.2.6] 少一瓶就补药

寻路补药原先 `potionCount < 3`。改 `Nav.needPotion`: UI/属性/本局见过的最大瓶数当上限, 当前 < 上限 (空瓶必补) 且本房有 Potion_Station 才去补。大厅清 potionSeen。已同步钾工作区。

---

## [2026-09-05 | 会话2.74 | v1.2.5] 同步钾工作区

hub/autoexec/lib 拷到 `%LOCALAPPDATA%\Potassium\workspace` 双路径 + `autoexec/dungeon-raiders.luau`。

---

## [2026-09-05 | 会话2.73 | v1.2.5] 去掉换服挂号注入


用户不要 hub 里 queue_on_teleport 自动重跑。删启动时 ArmTeleportReload, 自动重开 OnEnable 也不再挂号。结算 Replay 本身保留。进图仍走钾 autoexec。

### 验证
热替换 DR_HUB_v125, 控制台不应再出现「传送自动注入已挂号」。开自动重开文案是「看到结算就重开」。

---

## [2026-09-05 | 会话2.72 | v1.2.4] 死后寻路撞墙

### 原因
lastRoomN 只增不减 + 更小编号 Zone 当走廊 + 死后 Health=0 直接 return 不清路。重生还在上一间, 绿线仍指向后一间, MoveTo 穿墙, stuck 只跳路点越撞越死。

### 改
Nav.watchBody: 倒下/换角色/瞬移>48 丢掉旧路。rewindToRoom 把进度对齐当前战斗房并取消居中标记。门口叠区仍当走廊。卡墙两次后按当前位置重算。重生当帧不跑 noteProgress, 避免叠区把进度又抬回去。

### 验证
待热替换 DR_HUB_v124: 开寻路进第二房故意死, 应回上一间走向中心再出门, 寻路Bot 显示「倒下, 等重生」后恢复, 不应贴墙空跑。

### 遗留
未实机。若重生点在房门口叠区, 仍可能被当走廊, 靠 48 stud 瞬移兜底。

---

## [2026-09-05 | 会话2.71 | v1.2.3] 进地牢不自动注入

### 原因
`rcwtk-dr-ae.lock` 写上 `job\towner` 后注入在 `task.spawn` 里. 钾 autoexec 文件一 return 就掐后台. 后续同局再跑看到 lock 含 JobId 直接 return. hub 侧 `rcwtk-dr-hub.lock` 若残留, loadstring 立刻空 return, autoexec 还当成功写 READY.

### 改
autoexec 赢选举后同步等加载再 loadstring; 已有窗口才算注入成功; 锁在、窗口没起来等 40s 再抢. hub 去掉文件闸 (防多开只靠 autoexec). 手动热替换照旧.

### 遗留
钾若对单次 autoexec 有短超时, 等角色那几秒可能被掐 — 若再现, 改心跳续锁而不是再 spawn.

---

## [2026-09-04 | 会话2.70 | v1.2.2] autoexec 并行七八份

钾进图会并行/反复跑 autoexec, getgenv 锁无效, 同一帧多份 loadstring, registry 还没写上就全建窗. 改 workspace 文件 `rcwtk-dr-ae.lock` 选举 (table 地址当 owner, 0.3s 后不是自己的字就 return). hub 在 autoexec 标记下同样选举 `rcwtk-dr-hub.lock`. 手动重跑不带标记, 热替换照旧.

---

## [2026-09-04 | 会话2.69 | 钾 autoexec 只跑一次]

钾进游戏会反复执行 autoexec, 每次都 spawn 等 5s 再 loadstring, 加载期疯狂热替换. 进文件立刻用 getgenv/JobId 上锁, 同局第二次直接 return; 等角色出现后再注入一次.

---

## [2026-09-04 | 会话2.68 | v1.2.1 | 钾完整环境]

钾 autoexec 只能跑脚本, 不能当 workspace. 把完整环境同步到 `%LOCALAPPDATA%\Potassium\workspace`: lib/theking、vendor/rayfield-gen2、assets/theking-mark.b64、hub 双路径、根目录 rayfield-gen2、dist/hub-single。autoexec/dungeon-raiders.luau 只认三张图, 缺文件会 warn。

### 验证
- 重进地下城: `autoexec 地下城战利品者 ← dungeon-raiders/hub.luau` + `DR_HUB_v121 loaded`

---

## [2026-09-04 | 会话2.67 | v1.2.1] DPS 标题方角

DPS 标题栏没 UICorner, 方框盖在根窗 12px 圆角上, 顶上两角戳出来. 寻路Bot 标题有同样 12px 圆角. 给 DPS 标题补 `dpsCorner(title, 12)`, 底下 titleFill 仍用来抹平标题下沿.

### 验证
- 热替换 DR_HUB_v121 开 DPS面板, 顶边应跟寻路Bot 一样圆, 不应冒直角

---

## [2026-09-04 | 会话2.66 | v1.2.0 | 钾 autoexec]

把地下城 hub 接到钾自动执行: `Potassium/autoexec/dungeon-raiders.luau` (源在仓库 `games/dungeon-raiders/potassium-autoexec.luau`). 只认大厅/地牢/挂机三个 PlaceId, 进游戏等加载约 5s 后 `readfile dungeon-raiders/hub.luau`. 同步拷了 workspace 的 hub + lib/theking.

### 验证
- 关 Roblox 再开进地下城, 控制台应有 `autoexec 地下城战利品者` 和 `DR_HUB_v120 loaded`

---

## [2026-09-04 | 会话2.65 | v1.2.0 | lib 2.5.0] 寻路Bot窗 + 禁止折返初始房

过廊 getCurrentRoom=nil 且 lastRoomN 被当成 0 时, 路径走完就 seek Room_1 中心, 看起来像「去第一房又折返」。旧房 Zone 重叠也会把人当还在初始房拉回中心。

改: noteProgress 只升不降; 当前战斗房编号 < lastRoomN 当走廊; leftStart 后 nextCombatFrom 至少 afterN=1; 取消 seek Room_1。开寻路建 TheKing_NavBot, PREF.navBotX/Y, 无存档默认视口左下。

### 验证
- 热替换 DR_HUB_v120 开寻路: 左下「寻路Bot」; 拖动能记住; 初始房清完应直去下一战斗房, 绿线不应折回 Room_1

---

## [2026-09-04 | 会话2.64 | v1.1.6 | lib 2.5.0] 绿标 Boss 不等于进房

卡住现场 (Snow Generated_Snow_49fa12c8): 人在 Room_23 中心, HUD Current 已贴 slot#9 Boss=true。tickPath 用 uiBoss() 跳过 nextHop, phase=boss 空转。真正 Boss 房是 Room_25 (Spawns.Boss_Spawn), 中间 Room_24 过廊 43×80, Exit23=Entry24, Exit24=Entry25, 门距 92。

改: 只有房间带 Boss_Spawn 才停寻路; 清完倒数第二房照走 Exit→下一战斗房中心。nextHop/nextCombatFrom 距离放到 420。

### 验证
- 热替换 DR_HUB_v116, 仍在 Room_23 开寻路应铺绿线进 Room_25, 不应再停着

---

## [2026-09-04 | 会话2.63 | v1.1.5 | lib 2.4.1] 沿绿线走, 不闪传送

用户: 路线画得对, 不该用 F1 穿门。关门 CanCollide 挡住 MoveTo, 绿线是直穿过门的。

改: 拆掉 `tryPass`。算路/走路时对附近 `Gate`/`Iron Gate` 本地 `CanCollide=false`(原值记在 gateSave), 关寻路 `releaseGates` 还原。

### 验证
- 热替换 DR_HUB_v115; 回 Room_1 开寻路应沿绿线走进 Room_2, 不应瞬移、不应贴门

---

## [2026-09-04 | 会话2.62 | v1.1.4 | lib 2.4.1] 走廊贴门不走

实测 Snow: Room_1 Exit 与 Room_2 Entry 同点 Z=-664, 两侧 Gate CanCollide=true。MoveTo 穿不过门, hallKey 已设且路走完就空转。F1 是 `hrp.CFrame = Exit.CFrame * (0,3,-14)` 穿到 -678。过廊 Room_3 Zone 43×80 面积仍>900, 不能用面积当战斗房, 用「有 Enemy_Spawn 或 min(X,Z)≥70」。

改: 离 Exit<18 且本房已清完要过廊时 `Nav.tryPass` 一次; 路走完仍贴门也会穿。

### 验证
- 热替换看 DR_HUB_v114; 回 Room_1 开寻路, 走到门应闪进 Room_2 再往中心, 不应贴门停住

---

## [2026-09-04 | 会话2.61 | v1.1.3 | lib 2.4.1] 中间走廊卡死不去第二房

根因: 过廊/祭坛也是 `Room_N` 且有小 Zone。`nextHop` 会把它当下一房(Entry 离 Exit 很近), 路走到廊中间就结束; 出战斗房 Zone 后 `getCurrentRoom` 命中过廊房或 nil, `leftStart` 空转 / `phase=boss`。门口打架时 Zone 可能叠过廊, 必须优先认战斗房。

改: 战斗房=有 `Enemy_Spawn` 或 Zone 面积≥900; `getCurrentRoom` 只回战斗房; `nextHop`/`nextCombatFrom` 只选编号更大的战斗房; 路走完仍按 `lastRoomN` 走到下一战斗房中心; 没有下一战斗房才进 boss。

### 验证
- 热替换开寻路: 清第一房捡箱后应穿过中间走廊(可点祭坛)进第二房, 人不停在廊中间

---

## [2026-09-04 | 会话2.60 | v1.1.2 | lib 2.4.1] 走出初始房又折返

中心逻辑每帧把离 Zone 中心>14 的人拉回去, 刚朝出口走几步就被抽回; 出 Zone 后 getCurrentRoom=nil 又 seek Room_1.

改: 每房只居中一次; 开始走廊记下 leaving/leftStart; 走廊里继续当前路点, 禁止折返一号房.

### 验证
- 热替换开寻路, 应从初始房走到中心再出廊, 不应来回踱步

---

## [2026-09-04 | 会话2.59 | v1.1.1 | lib 2.4.1] 寻路路点太密卡顿

PFS 默认一步一个 waypoint, 0.35s 重 MoveTo 导致一步一顿. 抽稀只留起点/转向/终点; I 走廊两点一段; 进房先走到 Zone 中心再打怪/拾取. MoveTo 同目标最多 1.25s 刷新一次.

### 验证
- 热替换后绿圈应很少, 走路连续; 进门后继续走到房间中间

---

## [2026-09-04 | 会话2.58 | v1.1.0 | lib 2.4.1] 自动寻路 + 自动重开

冰图 Snow: `Generated_Snow_*` Room_N.Connectors Entry/Exit/Side; UI `Dungeon_Container.Completion_Progress` ZoneSlot(Completed/Treasure/Boss) + Current 指示当前房. 药水数量 `Actions.Bottom.Actions.Health.Amount` 形如 x4. 宝箱 Prompt ActionText=Loot, 未解锁 Enabled=false.

Nav 表挂移动页: 有怪就停走交给光环; 清完走区内可拾取箱; 药<3 找本房 Potion_Station; 主链只跟 Exit→下一房 Entry (Side 更近的当岔路不去); 走廊 PFS 失败则 I/L 折点贴内弯; 廊中 Blessing_Altar/箱走近交互. 路径 Folder 绿圆柱+Beam. 自动重开看 Completion_Info 可见就 RequestReplay, OnEnable 再 ArmTeleportReload.

### 验证
- check_hub; 热替换开杀戮光环+自动寻路, 地板应有绿点线, 清房后出廊不去 Side; 结算开自动重开应 Replay 并再注入

### 遗留
- 锁门钥匙房未做; 宝箱 Enabled 时机靠走近再尝试; 其它图几何与冰图同类即可用, 未逐图实测

---

## [2026-09-04 | 会话2.57 | v1.0.6 | lib 2.4.1] 闪避条误计时

角色 `Dodge=true` 是闪避动作/技能保护, 不是 CD. 旧条把它当 busy, 再按 Duration(默认2s) 本地倒数, 没闪避也会涨条.

改: 只认 `Dodge_Cooldown_Active`; Active 落下立刻停填条并渐隐; 监听属性变化.

### 验证
- 热替换开闪避条, 不按闪避不应出条; 闪一次才涨, CD 没了条马上收

---

## [2026-09-04 | 会话2.56 | v1.0.5 | lib 2.4.1] 平A真正锁目标

钾反编译 Weapon_Input.fireAutoAttack: 先发 GetCameraRelativeMoveDir (WASD 相对相机), 没有按键才用 MoveDirection. hub 以前 Fire zero, 服务端按走位/脸判定, 所以射偏.

改: Fire 指向 Cbt.lock 的水平单位向量; BindStepped 有锁就 AutoRotate=false + 扭脸保留速度. 杀戮光环 OnTick 不再每 0.1s 把 AutoRotate 抢回 true.

### 验证
- 热替换开平A, 按 WASD 绕怪走, 箭/刀应仍打锁定那只

---

## [2026-09-04 | 会话2.55 | v1.0.4 | lib 2.4.1] 撤回风暴火跟视角

用户: 四技能不释放还会发呆. 根因是 Steer 路径 Fire extra≠0、busy/hold=MaxDuration 3.5s、心跳改 CFrame/AutoRotate. 服务端不吃方向参则技能没出, 本地却锁死平A和走位.

改回 archive 发包: `Fire(SkillRE, slot, "tap", Vector3.zero)`, busy 0.14 / hold 0.08. 冲刺不冻 WalkSpeed, 只升空才短冻. 拆掉 camFlat/steerAim/BindStepped.

### 验证
- 热替换后技能光环 1→4 应都能放, 风暴火能冲, 人不钉死

---

## [2026-09-04 | 会话2.54 | v1.0.3 | lib 2.4.1] 风暴火卡住不动

v1.0.2 把 Steer 技能 skillFreezeMove=true 且 busy=MaxDuration(3.5s)。心跳移速打回把 WalkSpeed 写成 0; BindStepped 每帧 CFrame.lookAt 清掉冲刺速度。表现为人钉死、四技能像没放出来。

改: Steer 不再冻移速; 扭脸保留 AssemblyLinearVelocity; 平A AutoRotate 在 steerUntil 内不要抢回 true; 解冻/卸载若移速<1 还原 16。

### 验证
- 热替换后开技能光环, 4 技能应冲出去, 转镜头后段跟视角, 人不钉死

---

## [2026-09-04 | 会话2.53 | v1.0.2 | lib 2.4.1] 阿蒂米斯四技能跟视角

用户当前 Current_Class=Artemis. Stormfire: Range28 Dash55 Duration3.5 DashDuration0.12. 旧光环 busy 只有 0.14s, 平A抢朝向, extra 发 0.

- 档案 slot4 Hits=8 Steer; 连段 3.5s BindStepped 按相机前方锁怪扭脸
- Fire extra = 相机水平朝向; 平A 在 hold/steer 期间不发

### 验证
- check_hub; 热替换开技能光环放 4, 转镜头应对着准星附近的怪冲

---

## [2026-09-04 | 会话2.52 | v1.0.1 | lib 2.4.1] 重开不会自动注入

钾实测: 上次进游戏是 v0.10.0 + lib 2.2.1, 根本没有挂号. workspace 只有 `dungeon-raiders/hub.luau`, `games/` 那条是 false. 脚本已不在 (registry 空), Replay 会拆实例.

改: 快照到 rcwtk-reload/<placeId>.luau; 路径顺序改对; OnTeleport 再挂; Url 拉 Gitee obf.

---

## [2026-09-04 | 会话2.51 | v1.0.0 | 混淆推送]

`publish.py --game dungeon-raiders --no-class-archive --push` → Gitee master `6cc3a73`. 内嵌 lib 2.4.0. 不推 class-archive.

---

## [2026-09-04 | 会话2.50 | v1.0.0 | lib 2.4.0] 对外版本升到 1.0.0

用户指定 ScriptVersion=1.0.0. 功能不回退. 旧版备份 `archive/hub-v0.10.1.luau`.

---

## [2026-09-04 | 会话2.49 | v0.10.1 | lib 2.4.0] 忍者档案补全

当前 Current_Class=Shinobi Legendary Lv46, 局内 Snow. 档案原先只有 Range=14.

- Definition: Range=14 Hitbox(18,10,14) AttackSpeed=1.1 TurnCount=3 Lunge=2
- 技能 require 成功: 1 Flash Rend Range18 cd8×2 Duration1.2 IFrame1; 2 Kurogiri Range18 cd7 Duration2.5 Dash80 IFrame0.45; 3 Guillotine Drop AoERange15 Size(28,20,28) cd9 Duration2.5 Dash70 IFrame0.8; 4 Oni Rend Range20 cd12 Duration2.5 Dash80 FinalHit=4 ParryAfterHit=3
- CLASS_ARCHIVE_RAW 写 Skills → SkipRequire; 别名 shinobi/ninja → Shinobi

### 验证
- 钾 pid 19952 转储; check_hub; 热替换后职业下拉应对上忍者, 技能圈跟 18/18/15/20

---

## [2026-09-04 | 会话2.48 | v0.10.0 | lib 2.4.0] 换服自动注入

钾实测有 `queue_on_teleport` / `clear_teleport_queue`. 库 `TheKing.ArmTeleportReload({Files=...})` 探测不到函数就打日志跳过.

- 地下城 hub 挂号本地 `games/dungeon-raiders/hub.luau` 与 `dungeon-raiders/hub.luau`
- 落地等 PlayerGui 再 readfile+loadstring; 热替换只重挂不取消; 设置页卸载会 Disarm
- 局内 F1 下一房不走传送, 不依赖本功能

### 验证
- check_hub hub + lib; 控制台应有「传送自动注入已挂号」; 结算点重开后应出现「传送后自动注入」

### 遗留
- 发布混淆包 workspace 没有 hub.luau 时落地会失败, 需另挂 Source 或 Loader URL

---

## [2026-09-04 | 会话2.47 | v0.9.2 | lib 2.2.1] 假名漏头顶名牌

- 原先 `findNameTargets` 只扫 `PlayerGui` 的 ScreenGui, 角色 `Player_Healthbar.NameText` 在 Billboard 里改不到
- `considerFakeLabel` + 扫 `Character` 下 Billboard; `NameText` 必改; `TitleText` 仅当写的是玩家名才改 (VIP 不动)
- **名牌在 `Workspace.PlayerModels.<Name>`**, 不一定挂在 `LocalPlayer.Character`
- 换角色 `CharacterAdded` 延迟 0.4s 再扫

### 验证
- check_hub; 热替换后开假名看脚底/头顶名是否变成 theKing User

## [2026-09-04 | 会话2.46 | v0.9.1 | lib 2.2.1] 卡奇 (Kage) 职业档案

- 当前 Current_Class=Kage Legendary; Definition.Name=Kage; 用户中文名「卡奇」
- 平A Range=17 Hitbox(15,15,17) AttackSpeed=1 TurnCount=4 DirectionalLunge 2
- Skills: 1 Shadow Step Range28 cd8×3 WarpSearch60 背后斩; 2 Heart Stab Range15(档案圈28方便连锁) cd10 Duration8 锁血连锁; 3 Devouring Gale Size30 原地旋 Range15 cd10 Parry1.4; 4 Fists of Ruin Range17 cd15 Duration5 Parry4 多段拳
- 别名 卡奇/kage → Kage; 写了 Skills 即 SkipRequire

## [2026-09-04 | 会话2.45 | v0.9.0 | lib 2.2.1] 对外版本重整

- ScriptVersion / 通知 / DR_HUB 从 0.11.1 收回 0.9.0 后混淆推送; 功能不回退

## [2026-09-04 | 会话2.44 | v0.11.1 | lib 2.2.1] 闪避条看不见

- Overlay DisplayOrder=0 且 IgnoreGuiInset, 条被 HUD Bottom 盖住, 坐标还差 58 顶栏
- 独立 ScreenGui DisplayOrder=120 IgnoreGuiInset=false; 触发改 `Dodge_Cooldown_Active` 或角色 `Dodge`; 从起跳计 Duration

## [2026-09-04 | 会话2.43 | v0.11.0 | lib 2.2.1] 闪避冷却条

- 属性 `Dodge_Cooldown_Active` + `Dodge_Cooldown_Duration`(约 2s); 无 Remaining, 边沿记 t0
- 位置跟 `Main.HUD.Actions.Bottom.ClassEXP` AbsolutePosition, 宽约经验条 54%, 高 5px
- 仅 CD 中显示; Active 落下后满条 0.42s 透明度渐隐; BindStepped 跟帧
- 视觉 Tab 开关 `dr_dodge_cd`

## [2026-09-04 | 会话2.42 | v0.10.0 | lib 2.2.1] 杀戮光环内置 Boss 拼刀

- 无单独开关: `meleeEnabled or skillAuraOn` 时 `Cbt.syncBossParry`
- 认 Boss: `IsBoss`/`IsMiniBoss` 或 `ItemId`/`Name` 命中 `Boss_ActionData.Index`; 跳过 IsDormant
- 时机: Animator 出招动画按 WindUp/Telegraph 延迟点 `Inputs.Parry`; Hit/Swing marker 或模型出现 Hitbox 则立刻发; 本地 1.7s 节流对齐 ParryCooldown; `NoParrying`/`Parry_Cooldown_Active` 不发
- 距离: Boss DefaultRange/HitboxRange 内且大致朝向玩家
- L2: 只发游戏自己的 Parry 包, 不 hook 反作弊; Guard 不熔断光环

### 验证
- check_hub 过; 热替换看 `DR_HUB_v0100`; 真拼中需进 Boss 房开光环看连段是否被掐

## [2026-09-04 | 会话2.41 | v0.9.1 | lib 2.2.1] 职业表并进 hub

- 不再 readfile class-archive / CLASS_ARCHIVE_EMBED; 数据在 `CLASS_ARCHIVE_RAW`
- 别人 Loader 只下一份混淆 hub 即可用 5 个职业 (含火焰据点)
- class-archive.luau 留作说明 stub, 发布不推 sidecar

## [2026-09-04 | 会话2.40 | v0.9.0 | lib 2.2.1] 自动补充药水 + 发布不含档案

- 大厅/局内 ProximityPrompt: ActionText=`Refill Potions` ObjectText=`Potion Station` (intel 里的 Potion_Station)
- 战斗 Tab 最底开关, 逻辑同祭坛: 距离内 fireproximityprompt, 1.1s 节流, 锅可反复用所以不记 used
- 提示列表 1.6s 缓存, 避免每 tick 全图 GetDescendants
- 发布: `publish.py --game dungeon-raiders --loader --push --no-class-archive` — 混淆 hub/Loader, 不内嵌不推 class-archive

## [2026-09-04 | 会话2.39 | v0.8.15 | lib 2.1.0] 绘制池收进 Ov 闭包 (200 上限)

- check_hub: 业务 IIFE 峰值 200, 再加功能会编不过
- 覆盖层对象池/圈/箭头/宝箱字收进 `Ov = (function() ... end)()`, 外层只留 Ov.ring/frameEnd/reset/take*
- PlayerGui WaitForChild 加 10s timeout
- 引擎侧 lib 2.1.0 Draw/Pack/静态门已落地; 本局绘制仍用已验证 Overlay, 未迁 TheKing.Draw

## [2026-09-04 | 会话2.38 | v0.8.14 | lib 2.0.17] 火焰据点职业档案

- 当前 Current_Class=Flame Bastion Lv33, 局内 Catacombs; 中文名用户指定「火焰据点」(日常 CompleteWithClass 文案也是 Flame Bastion)
- Class_Data/Definition: Epic 长枪, Range=19 Hitbox(20,10,19) AttackSpeed=1 TurnCount=4 DirectionalLunge 2.4; 技能模块 require 成功
- Skills 槽: 1 Pyre Cyclone HitboxRange=14 AoE(20,10,20) cd6 Duration2 带 Parry 0.6 原地; 2 Blazing Reach Range=25 cd10 Dash90 HitCount=6; 3 Ember Step Size(20,10,20) 无 HitboxRange 用 Z=20, cd7×2 Dash70 IFrame0.5; 4 Ashen Onslaught Size(20,10,20) cd10 Dash40 HitCount=5 Duration2.5 (StationarySkills 4=true 但仍带推进)
- 档案 Name=火焰据点; hub 别名 火焰据点/火据点 → Flame Bastion; 写了 Skills 即 SkipRequire
- 日常 d_class_Flame Bastion: 换上该职业通关任意 3 个地下城即可 (不限图), 当时进度 0/3

## [2026-09-04 | 会话2.37 | v0.8.13 | lib 2.0.17] 卸不掉 + 祭坛只开第一座

- 卸载原先只 softHide 窗, Heartbeat 移速还在; Destroy 加 purgeUi 拆 Rayfield 层; hubAlive 闸门 + RestoreToggle 不再救活已死实例
- FindFirstChild 只拿到整张 Generated_ 里第一座 Blessing_Altar; 改 GetDescendants 找 Receive Blessing, 距离内最近; UI 关掉才 used; 选卡按卡面签名而不是 4s 全局冷却

## [2026-09-04 | 会话2.36 | v0.8.12 | lib 2.0.16] 移速修改无效

- 实测: WalkSpeed=80 当帧生效, +50ms 变成 2.8, +250ms 回到 ~50.4 (冲刺档). 0.1s 循环必输
- Heartbeat + WalkSpeed Changed 立刻回写; 关掉不碰 WalkSpeed; 开关上移到滑条之上

## [2026-09-04 | 会话2.35 | v0.8.11 | lib 2.0.16] 注入编不过

- `Cbt.applyStartHidden` 里 `end` 被写成 `endw`, loadstring 直接失败
- 已改回 `end`, 钾目录热替换 `DR_HUB_v0811 loaded`

## [2026-09-04 | 会话2.34 | v0.8.11 | lib 2.0.16] DPS 局内总伤清 0

- dpsRefresh 把 DungeonRun bool 边沿当新开局, 一抖就清空 dpsMeta; dpsPlayerDps 见 Damage_Dealt 变小直接 t0=nil 并显示 0
- 改成按 InDungeon+图名/难度分局; 短时间属性 0 仍显示上次总伤; 后房间确认清 0 再累加; 回大厅或换图才重置

## [2026-09-04 | 会话2.33 | v0.8.10 | lib 2.0.16] 双光环圈打不一致

- 技能锁够不着时仍打最近怪, 但 Cbt.lock 不改 → 脚底圈一只、技能打另一只
- 粘性 1.12 倍射程 + 扭脸阈值 0.78: 圈粘在侧后方, 平A按面前判定打另一只
- 修: 出手必 Cbt.mark; 锁侧后或近处更近则重选; 平A朝向跟锁定到 0.9

## [2026-09-04 | 会话2.32 | v0.8.9 | lib 2.0.16] 混淆发布 + Loader

- 发布包 CLASS_ARCHIVE_EMBED: build.py 把 class-archive 打进 hub-single, Loader 注入不依赖 readfile
- Loader 0.8.4 CN_GAME dungeon-raiders; manifest universeId=9656201728, placeIds 含大厅/地牢/挂机
- 命令: python tools/publish.py --game dungeon-raiders --loader --push

## [2026-09-04 | 会话2.31 | v0.8.8 | lib 2.0.16] 职业选错导致一堆战斗怪病

- 用户确认此前平A/技能异常是下拉职业和角色不一致
- Cbt.syncClass: Current_Class 变了就把 classIdx/_skillCache 拨正, 技能光环每 tick 校正

## [2026-09-04 | 会话2.30 | v0.8.7 | lib 2.0.16] 祭坛自动交互

- Blessing_Altar.Altar.Bottom.PromptAttachment.ProximityPrompt Action=Receive Blessing Max=10 Hold=0.25
- 自动 BUFF 开着时距离内 fireproximityprompt; UI 已弹出 (_active) 不再刷提示

## [2026-09-04 | 会话2.29 | v0.8.6 | lib 2.0.16] 技能留手

- 去掉 dump/轮转; 就绪 1→4; 有充能无视 OnCooldown 继续丢; 节流 0.12s, busy 0.14s; 判定距离 +8

## [2026-09-04 | 会话2.28 | v0.8.5 | lib 2.0.16] 放完 2-4 整段停手

- 平A被 skillHold + Ability_ 多段延展锁死; 技能用档案 Cd=12 放完像坏了
- 平A不再看 hold; 动画不延 busy; 就绪看 OnCooldown + 0.32s 节流

## [2026-09-04 | 会话2.27 | v0.8.4 | lib 2.0.16] 范围圈变糙 + 技能仍不放

- 圈: maxSegs 被压到 40。恢复 /7 段长、上限 220, 红圈全不透明
- 技能: 平A 0.08s 刷新导致 meleeLastAttack 永远 <0.2, pending 永远发不出去。改为就绪即 Fire

## [2026-09-04 | 会话2.26 | v0.8.3 | lib 2.0.16] 双光环不积极

- 平A被 skillPending/iFrame/hold 挡住; 技能等 0.45s + rest 0.55 + attackAnimBusy 卡死 (isAttacking 永不清除)
- 远程 hold/busy ~0.14s; 技能穿插 0.2s; pending 不再停平A; Ability_ 只延展位移技

## [2026-09-04 | 会话2.25 | v0.8.2 | lib 2.0.16] 索敌不锁队友

- getEnemies / Cbt.alive: GetPlayerFromCharacter + UserId 属性, 玩家角色不进锁定

## [2026-09-04 | 会话2.24 | v0.8.1 | lib 2.0.16] 索敌卡顿+停手

- 停手: keepR 内 return nil; 技能 dump 每 tick 清槽; Humanoid.Health=0 误判死
- 卡顿: 2D 折线 10Hz。锁改 CylinderHandleAdornment Heartbeat 贴脚
- Cbt.pick 够不着就改选射程内; dump 冷却中保留槽位

## [2026-09-04 | 会话2.23 | v0.8.0 | lib 2.0.16] 粘性锁定 + 目标脚底圈

- pickCombatTarget: 死/休眠过滤, 残血与朝向加权, keepR 粘住; 双光环时远处锁不平A改打近处
- findReadySkill 技能打 lockTgt; 技能圈常显(淡)出手加亮; 锁脚 2.8+1.35 双圈脉冲
- 验证: 注入后看锁定脚底圈跟打的是同一只, 走路不抽

## [2026-09-04 | 会话2.22 | v0.7.5 | lib 2.0.16] 阿蒂米斯抽搐+停手

- 现象: 开双光环走路抽、不打平A
- 根因: 1) 任意 skillBusyUntil 把 WalkSpeed 置 0; 2) fireMeleeOnce 见 findReadySkill 就让路, Twin Bolt 三充能几乎永远就绪; 3) hold/busy 跟 MaxDuration (落箭雨 3s); 4) Ability_ 动画全匹配延展; 5) busy 期间每 tick faceTowards
- 修: skillFreezeMove 仅 Dash/升空禁走; 远程技短节流; 平A只在 hold/pending 让路; Ability_ 仅刚放技能时延展; 弓手不锁 AutoRotate; 档案 Twin Bolt 去掉误填 Dash
- 回归: 被诅咒的孩子冲刺仍禁走; 锻造霸主切弓距离不变

## [2026-09-04 | 会话2.21 | v0.7.3 | lib 2.0.16] 注入 Out of local registers

- loadstring 报 exceeded limit 200 (applyStartHidden); 主 chunk 包一层 IIFE

## [2026-09-04 | 会话2.21 | v0.7.4 | lib 2.0.16] 阿蒂米斯技能写入职业档案

- 当前 Current_Class=Artemis Lv20; 地牢 Knights; 技能模块 require 成功 (与被诅咒的孩子相反)
- Class_Data.Range=32 Hitbox(15,15,35); Skills: Twin Bolt / Moonfall / Tempest Strike / Stormfire
- 档案 Skills: 1 Range25 Cd4×3 Duration1 Dash70; 2 Range29(=ForwardDistance15+盒半14) Cd12 Duration3; 3 Range25 Cd7×2 Duration2 Dash70; 4 Range28 Cd12 Duration3.5 Dash55
- 写了 Skills 即 SkipRequire, 技能光环走档案不跟游戏 Activate

## [2026-09-04 | 会话2.20 | v0.7.2 | lib 2.0.16] 双光环计量+接刀

- skillDumpSlot: MaxCharges>1 时打空再 round-robin
- skillHold/Busy 跟 MaxDuration; Ability_* 动画再延展, 避免平A打断多段
- skillRestUntil: 一段结束后 ~0.35s 只平A; 接刀挥完再插下一技能

## [2026-09-04 | 会话2.19 | v0.7.1 | lib 2.0.16] 档案去 Folder + 精简字段

- Name 对 Class_Data/Definition/文件夹名解析; 中文别名: 被诅咒的孩子/锻造霸主/忍者/阿蒂米斯
- Range/Bow/Skills 短字段规范化成内部 MeleeRange/HitboxRange; 写了 Skills 即 SkipRequire

## [2026-09-04 | 会话2.18 | v0.7.0 | lib 2.0.16] 职业档案外置

- 新文件 games/dungeon-raiders/class-archive.luau (return 职业数组)
- hub ClassKit: Get / MeleeRange / Skills; 读 dungeon-raiders/class-archive.luau
- 被诅咒的孩子 SkipRequire=true; 其它职业仍 require 游戏技能模块, 失败才用档案 Skills
- build.py 把 class-archive.luau 复制到 games/.../dist/

## [2026-09-04 | 会话2.17 | v0.6.0 | lib 2.0.16] 被诅咒的孩子 + 平A档案

- 当前 Current_Class=Cursed Child Lv17; Definition.Range=18 Hitbox(15,10,18)
- Skills require 失败 (模块含 Activate); 反编译: Hollow Rush / Severance×3 / Cursed Speech 定身 / Cursed Love 射线 tick40
- CLASS_PROFILES 增加 MeleeRange/MeleeHitbox/BowRange; getMeleeRange 优先档案, 挥击盒明显更长才跟盒
- 职业下拉默认跟当前游戏职业

## [2026-09-04 | 会话2.16 | v0.5.6 | lib 2.0.16] 首次注入隐藏窗显示异常

- 建窗时 hidden=true、main 不可见, 但 topbar.Visible 已是 true
- 0.5s 的 SetWindowHidden 当成已打开去调 Hide, 窗体被挪到顶栏缩成药丸, 第一次 DEL 也从错误位置展开
- 从未 Show 过则保持初态; 是否打开看 hidden + main.Visible, 不再只看顶栏

## [2026-09-04 | 会话2.15 | v0.5.5 | lib 2.0.15] DPS 位置不持久化

- 存档已有 dpsX/dpsY, 注入仍回默认角
- 读档 tonumber 碰到行尾 CR 会失败掉默认 18,96; 视口为 0 时 clamp 夹到 8,8; 热替换不跑 OnCleanup 会叠旧窗
- 修: 去 CR、视口过小不夹、松手立刻写盘、创建前清同名 GUI、延迟再套一次存档坐标

## [2026-09-04 | 会话2.14 | v0.5.4 | lib 2.0.15] DEL 要按两下才藏

- Rayfield 新建窗 hidden=true, 画面随后 Show; ToggleHide 第一次等于 Show (空按), 第二次才 Hide
- 改看 topbar.Visible: 看见就 Hide, 看不见就 Show; 启动藏窗只在 0.5s 调一次

## [2026-09-04 | 会话2.13 | v0.5.3 | lib 2.0.14] DEL 藏窗后无法再开

- 根因: SetWindowHidden 把 rfScreenGui.Enabled=false, 设置页 Keybind 跟着死
- 藏窗只走 ToggleHide/Hide, GUI 保持 Enabled; DEL 兜底若 GUI 被关会先打开再 Toggle

## [2026-09-04 | 会话2.12 | v0.5.2 | lib 2.0.13] DPS 拖动/边框 + 藏窗真持久化

- 边框转速 110→28
- 拖动: Heartbeat, 按下后下一帧才记鼠标原点, 窗体用 Position.Offset
- StartHidden + 关 ScreenGui.Enabled; 启动 1.2s 内忽略「显示」回写, 防 LoadConfig 把 uiHidden 冲掉

## [2026-09-04 | 会话2.11 | v0.5.1] DPS 标题裁字 / 拖动手势 / 拖动跳变

- 标题 TextButton+UICorner 裁字且改鼠标指针 → Frame+Label+UIPadding
- 拖动混用 Gui Input.Position 与 AbsolutePosition (GuiInset) 导致窗体下跳 → GetMouseLocation 差值
- 菜单隐藏时 Title.Active=false, 不再进可拖动指针

## [2026-09-04 | 会话2.10 | v0.5.0] DPS 面板

### 目标
视觉 Tab 可开关的局内 DPS 窗: 4 人槽、拖动、持久化、假名、血条特效。

### 改动
| 文件 | 改动 |
|---|---|
| hub.luau | TheKing_DpsPanel ScreenGui; Flag dr_dps_panel; PREF.dpsX/dpsY |
| intel.md | Damage_Dealt 作为局内总伤权威字段 |

### 决策
- 独立 ScreenGui, 不进绘制对象池 (拖动/Tween 和每帧 hide 冲突)
- DPS = Damage_Dealt / 该玩家本局首次伤害后的秒数; DungeonRun 再进清空 dpsMeta
- 菜单隐藏时禁止拖动 (IsWindowHidden), 面板本身仍显示
- 其它玩家伤害/等级走 Player 属性复制, 血量走 Humanoid, 没角色则用 Stat_MaxHP 当满血

### 验证
- 需重跑开「DPS面板」: 看自己名字/等级/血条; 开假名第一格应变; 藏菜单后拖不动; 重注位置和开关应还在

### 遗留
- [ ] 四人队实战未测队友 Damage_Dealt 是否复制到本地
- [ ] 弓形态 26m 平A未实打

---

## [2026-09-04 | 会话2.9 | v0.4.3 | lib 2.0.12] 全控件 + 菜单显隐持久化

### 目标
所有功能参数落本游戏 `dr-prefs.txt`; 菜单藏了下次注入仍是藏的。

### 改动
| 文件 | 改动 |
|---|---|
| lib/theking.luau | SetWindowPersist / IsWindowHidden / SetWindowHidden; Hide/Show 后回调 hidden |
| hub.luau | PREF.uiHidden; 职业/颜色/快捷键写入 PREF; 启动 defer 藏窗 |

### 决策
- Rayfield Flag 在本环境不落盘, 继续自建 PREF, 不依赖 Configurations/
- 卸载 Destroy 走 softHide 不走 ToggleHide, 不会把「开着菜单卸载」误存成隐藏
- 菜单状态只写这游戏 PREF, 其它游戏不接 SetWindowPersist 则无行为变化

### 验证
- 需重跑: 藏菜单→重注, 应仍隐藏; 开杀戮/改颜色/改职业→重注应恢复

### 遗留
- [ ] 弓形态 26m 平A未实打
- [ ] Rayfield LoadConfig 若某天突然生效, 可能和 PREF 抢一次显隐, 以 SetWindowHidden(defer) 为准

---

## [2026-09-04 | 会话2.8 | v0.4.2] 锻造霸主 3/4 切武器 + 平A判定

### 目标
锻造霸主 3技能切远程、4技能切回近战, 杀戮光环找怪距离必须跟当前武器形态走。

### 改动
| 文件 | 位置 | 改动 |
|---|---|---|
| hub.luau | isForgeBowStance / getMeleeRange | 弓=Bow.Transparency<0.5; 弓距 Range+SpecialRangeBonus=26; 近战 Range≈16.5 |
| hub.luau | liveHitboxReach | Size.Z<1 视为占位, reach=2*\|C0.Z\| |
| hub.luau | meleeEnabled | 删掉 BindToggle 前第二份 local, DBreset 连击终于读到开关 |
| hub.luau | fireQueuedSkill | 槽 3/4 发包后清平A距离缓存 |

### 决策
- 没有 Player 属性标记形态, 只能看左手模型透明度 (Definition.setModeVisual)。
- 切弓瞬间 Hitbox C0 可能仍是 -8, 不能信盒, 弓形态优先职业表。
- RangeOrder.5=27 仍不当默认圈。

### 验证
- MCP: 当前近战 Bow.trans=1, Hitbox Size=0.05 C0.Z=-8; Hrunting 调 EnterBowMode, SCB 调 EnterMeleeMode。
- 需进本: 开杀戮, 放 3 看红圈变大并打远处怪; 放 4 圈收回。

### 遗留
- [ ] 弓形态平A是否仍是前方盒 (Weapon_Manager.Hitbox) 而非弹道, 未实打确认 26m 是否被服务端接受
- [ ] 视觉颜色 Dropdown 仍可能不落盘

---

## [2026-09-04 | 会话2.7 | v0.4.1] 平A范围改自动识别

### 目标
去掉战斗页「平A范围(米)」滑条, 按当前角色真实平A距离自动设杀戮光环/红圈。

### 改动明细
| 文件 | 位置 | 改动 |
|---|---|---|
| hub.luau | getMeleeRange | 新增: 实时 Hitbox 几何 + 职业 Definition.Range 回退, 0.2s 缓存 |
| hub.luau | 战斗 Tab | 删除平A范围 Slider; 所有 calibRange/auraMeleeRange 改为 getMeleeRange() |

### 决策
- 用户明确不要手动距离。命中框是游戏设置里调试用的服务器判定盒, 跟平A一致。
- 锻造霸主 Definition.Range=16、HitboxSize.Z=17; RangeOrder.5=27 是第五段特殊挥, 不用来当默认圈 (会虚高), 只取 Range 与实时盒。
- 两者都有时取 max(盒, Range*0.9), 避免盒偏小打不着。

### 验证
- 静态: 滑条引用已清, getMeleeRange 四调用点 (找怪/解锁朝向/技能面向/红圈)
- 动态: 需进本开杀戮光环, 看红圈是否贴当前职业; 开设置命中框对照圈径

### 遗留
- [ ] 连击中途 Hitbox 变大(第五段)时圈会跟着变, 是否接受待用户说
- [ ] 视觉 Tab 颜色仍可能不落盘 (上轮中断未做完)

---


> 维护铁律: **每次开发会话收工前必须追加一条**, 写给下一个接手的 AI 和未来的自己。
> 与 changelog.md 分工: changelog 面向用户记"发布了什么"; 本文件面向开发者记"怎么做的、为什么、验证结果、遗留问题"。
> 接手 AI 使用法: 只读本文件最后一条 + intel.md 相关分区, 即可恢复全部上下文, 禁止凭空猜测前人意图。

## [2026-09-04 | 会话2.6 | v0.3.1 | lib 2.0.7] 崩溃定案 + 偏好自绘网格 + 改名/版本重构

### 崩溃调查定案 (多轮实锤, 重要!)
- 现象: v1.0.26~v1.0.33 反复崩溃, 集中在"操作 Rayfield 多选下拉"瞬间 (滑块 Flag 写盘已 v1.0.28 排除; 绘制循环已 v1.0.32 加鼠标暂停保护+降频仍崩; 用户确认未开绘制也崩)
- 排除链: 组件参数(与重型钓鱼 hub 逐字对照一致, 含 value={}) / UI 库版本(同 theking v2.0.6 + 同 rayfield-gen2.lua 缓存) / 绘制循环(未开也崩)
- 结论: **Rayfield 多选下拉的弹层渲染路径在地牢掠夺者游戏 + Potassium 注入组合下本身不稳定** (重型钓鱼同组件稳定 → 游戏环境差异, 与 hub 代码无关)
- 修复: 弃用多选下拉组件 → **自绘紧凑网格** (4 列 TextButton + UIGridLayout 内嵌 Rayfield tabPage, 纯 Instance 操作, 与 overlay 绘制同路线零崩溃面)
- lib v2.0.7: wrapTab 新增 t:RawPage() 返回 rfTab.tabPage (ScrollingFrame), 供 hub 内嵌自绘面板 (布局: tabPage 已有 UIListLayout, 自绘 Frame 作为一行子级自动排列, LayoutOrder 需读现有子级最大值+1)
- 自绘网格注意: tabPage 内 UIListLayout SortOrder=LayoutOrder; 手动元素 LayoutOrder 必须显式设大 (默认 0 会排最前); UIGridLayout CellSize 需按 holder AbsoluteSize 动态算 (GetPropertyChangedSignal('AbsoluteSize'))

### 其它
- 游戏显示名「地牢掠夺者」→「地下城战利品者」全量统一
- ScriptVersion 重构 1.0.x → 0.3.1 (历史 changelog 条目保留原版本号不动)

### 遗留
- [ ] 偏好网格选中态尚未做配置持久化 (自绘无 Rayfield flag 通道; 待评估安全写盘时机)
- [ ] F1 传送只到走廊未修; 自动选宝箱/自动喝血等 v1.0.x 功能回归待测

### v0.3.1b 增补 (同会话)
- 修复: 移除 v1.0.32 引入的"鼠标按住暂停绘制" — 误伤右键拖视角 (按住右键=游戏常态视角操作), 用户反馈"按住右键所有绘制消失"。崩溃定案后该防护已无必要, 改无条件绘制 + 10Hz

---
## [2026-09-03 | 会话2.5 | v1.0.5 | lib 2.0.6 当前] 圆盘视觉失败→回 ScreenGui + nil 引用修复

### 问题
- v1.0.4 圆盘 (Cylinder 0.06 高 / 30 直径) 在 Potassium 下从玩家站立视角被渲染为一条横线 (截图证实), 2D 侧面视角看薄盘 = 边缘线
- v1.0.5 热替换后平A光环 loop 持续报错 "attempt to compare number <= nil" — 闭包读到隐式全局 nil (auraMeleeRange 在 BindToggle 创建后才声明, local 不可见, 退化为 _G.auraMeleeRange=nil)

### 决策
- 圆盘方案否决 (3D 圆盘在 Potassium 引擎下侧视成线, 无法修复)
- 回 2D 折线: 96 段 + 端点 2.5px 重叠 + 每 6 段一个 8x8 Frame 圆点盖接缝 → 视觉近完美圆
- 雷达: 先扫描怪, dirs 空时整个雷达 (中心圆+三角) 隐藏, 有怪才显示
- auraMeleeRange 上移到 BindToggle 之前, 确保 OnTick 闭包读到 local

### 遗留
- [ ] 96 段折线 + 顶点圆点 (总 ~96+16 frame/光环) 是否引发崩溃? (若崩 → 进一步降频或回 Drawing)
- [ ] 用户复测: 平A/技能光环圆线 + 预警无怪隐藏 + 滑块崩溃

---

## [2026-09-03 | 会话2.4 | v1.0.4 | lib 2.0.6 当前] 范围圈改 3D 圆盘

### 问题
- Frame 线段画圈 (40 段 + 端点外扩) 在 Potassium/原生 UI 下仍"接不上/不闭合"
- 结论: Roblox 原生 Frame 亚像素接缝 + 近镜头段 Z<0 剔除导致, 2D 投影折线方案到此极限

### 决策
- 查社区成熟方案: 地面范围圈主流 = Cylinder 半透明发光圆盘 Part (Codepal/espLibrary 同款), 而非 2D 折线
- 弃用 drawWorldRing3D 折线 → 本地创建 Cylinder(ForceField) 圆盘, Weld 到 HumanoidRootPart 脚底 (FOOT_Y_OFFSET=-2.2), 半径=光环范围, 每 20Hz reconcile 半径/颜色/自愈重生
- 平A 红盘 / 技能 黄盘; CharacterAdded 时 clearAllRangeDisks (下一轮绘制自动重建)
- OnCleanup 清盘; 盘为客户端本地新建 (不碰 replicated 属性, 安全)
- 宝箱 fill / 雷达圆仍用 Frame (2D 无此问题)

### 遗留
- [ ] 圆盘视觉接受度 (半透明实心盘 vs 细线圈; 用户可能更想要环线, 但盘是无缝稳定方案)
- [ ] 圆盘本地新建 Part 若被游戏清理/检测需观察 (L1 低风险)
- [ ] 滑块崩溃是否随 20Hz+去Flag 消失 → 待用户复测

---

## [2026-09-03 | 会话2.3 | v1.0.3 | lib 2.0.6 当前] 崩溃排查 + 手感/绘制/宝箱优化

### 用户实测反馈
1. 原生 UI 覆盖层可见性证实 (红测试线 + 假名生效 ✓)
2. 光环圈线段接缝明显 (每段粗细/错位感) → 段数 24→40 + 端点外扩 1.2px 重叠闭合, 线宽统一 2.5
3. 技能光环"发呆"→ 释放窗口压缩: dur=clamp(MaxDuration+0.15, 1.0~1.9) 不再死等 2.5s
4. **位移型技能乱飞跑出怪范围**: 服务器 dash 方向取角色朝向(MoveDirection=0→LookVector), 客户端 cast 时朝向尚未复制到服务器 → 改两阶段释放: faceTowards → 0.22s 后再 Fire tap (pending 状态机)
5. 宝箱 fill "不是3D/悬在头顶" → 待 dump 箱子结构后精确化 (本轮未完成, 客户端又崩)
6. **滑块/下拉崩溃仍复现 (原生 UI 版)** → 本轮: (a) 渲染 RenderStepped 60Hz → StartLoop 20Hz (UI 写入降 3x); (b) 全部参数控件去掉 Flag 持久化(10 处), 消除高频配置写盘; 待用户复测是否还崩

### 改动
- 绘制引擎: TheKing.StartLoop("dr_draw_loop", 0.05, drawFrame) 替代 RenderStepped; drawWorldRing3D 40 段+端点重叠
- 技能光环: 两阶段 pending (先转向同步服务器 → 再释放), 窗口 clamp 上限 1.9s
- 控件: dr_potion_pct/dr_melee_range/dr_class_profile/dr_chest_color/dr_chest_alpha/dr_warn_range/dr_warn_radius/dr_warn_arrow/dr_warn_color/dr_speed_val 去 Flag (不持久化, 防高频写盘)

### 遗留
- [ ] 宝箱贴合: dump DungeonChest 结构 (part 构成/bbox 偏差) 后精确化绘制矩形
- [ ] 滑块崩溃: 待用户用 v1.0.3 复测 (若仍崩 → 排查 Rayfield slider 拖动 + theking 配置保存)
- [ ] 怪物预警 UI 复测

---

## [2026-09-03 | 会话2.1 | v1.0.1 | lib 2.0.6 当前] 实机三修

### 问题与修复
1. **宝箱透视染色崩溃 + 不穿墙** (用户实测: 改色崩溃, 疑似客户端级崩溃——用户重开了游戏进程)
   - 根因: 对 replicated BasePart 写 LocalTransparencyModifier/Material=ForceField/Color, 触发客户端崩溃或服务端强校验
   - 修复: **彻底移除染色方案**, 改纯 Drawing 投影填充 ESP: 箱子 GetBoundingBox 8 角→屏幕矩形→6px 水平线填充, 穿墙可见; 颜色/透明度只改 Drawing.Line 属性 (绝对安全)
   - 前向引用坑: drawChestEsp 引用晚声明的 drawingAvailable → Luau 视为全局 nil 功能死; 修复为仅由渲染循环调用
2. **杀戮技能光环启动无效**
   - 根因 A: busy 依赖 Character:GetAttribute("Skill_Camera_Stabilize") — 反编译后确认只有 Flash Rend 设它, Kurogiri/Guillotine/Oni 都不设
   - 根因 B: 与平A光环同开时, 服务端 Is_Attacking=true 会拒 Skill (CanActivate 返回 "Attacking")
   - 修复: 全局时间窗 `skillHoldUntil` = MaxDuration+0.4 (保底 1.2s), cast 后锁; 平A tick 见 `now<skillHoldUntil` 让路; 技能槽就绪双门: 充能型看 SkillN_Charges (多充能由低槽优先自动放完层), 冷却型按模块 Cooldown 节流; 槽序 1→4 低槽优先
3. **平A不够流畅**: 发包周期 0.18s→0.1s (Interval 0.1), 贴近游戏持按 0.1s 协议

### 验证
- 编译 OK; 加载 OK (PID 20084, 新进程因用户崩溃后重开); 热替换未测 (进程换了)
- 实机 UI 复测待用户

### 遗留
- [ ] 复测宝箱 fill 视觉效果 (fill 线 6px 是否够"实心")
- [ ] 技能光环: 无充能技能的 CD 节流为模块近似值 (被动减 CD 未感知), 效果可接受性待测
- [ ] 平A 0.1s 频率与用户手动攻击的双通道竞争节奏待观察

---

## [2026-09-03 | 会话2 | v1.0.0 | lib 2.0.6 当前] 全量功能实现 (4 Tab)

### 目标
按用户清单实现首版全功能 (战斗/移动/视觉/快捷键), 并在会话内完成代码级验证。

### 逆向增量 (已回写 intel.md)
- 键位动作表 (InputMapData): Attack=LMB, Skill1-4=1-4, SkillE=G, Potion_Health=5, Sprint=Shift...
- 技能发包: Skill:FireServer(slot,"tap"|"hold",dir); 槽映射 {Skill1=1..4,SkillE="E"}
- ShowHitbox = 服务器攻击判定盒可视化 (HRP.Hitbox, Wep_Data.HitboxSize+Range)
- 喝药 = PotionService:UsePotion(1); 重开/回城 = DungeonRunService:RequestReplay()/RequestReturn()
- RewardRevealController.PlayEntries = 结算奖励卡片动画入口
- 技能范围数据可在客户端 require RS.Classes.<Class>.Skills/<技能> (共享权威模块)
- 实测: WalkSpeed 7s 不回滚; keypress 不触发 UserInputService → 必须 FireServer
- Shinobi 技能判定表 + 场景结构 (Room_N.Connectors.Exit / DungeonChest_<guid> / tag Enemy)

### 改动明细
| 文件 | 改动 |
|---|---|
| games/dungeon-raiders/hub.luau | 全新: 4 Tab 8 功能 + 设置标配 |
| games/dungeon-raiders/intel.md | 会话2 大节 (键位/技能/结算/场景/实测) |
| changelog.md / devlog.md | v1.0.0 条目 |

### 决策记录
- **攻击/技能/喝药/冲刺一律 FireServer** (实测 keypress 无效), 均游戏自身协议, L1
- **移速常驻覆盖** (实测服务端不回滚); 每 0.4s 差量校正
- **职业档案驱动技能光环**: CLASS_PROFILES 表只存 Folder/Label; 技能 HitboxSize/HitboxRange/MaxCharges/MaxDuration 全部运行时 require 读取 (未来加职业只需加一行档案 + 反编译确认其 Skills 目录)
- **技能槽序**: 按技能模块 AnimationName "Ability_N" 解析到 slot; Shinobi 四技能均映射 1-4
- **技能判定范围坑**: Guillotine Drop 用 AoEHitboxRange (非 HitboxRange) → skillRange() 双字段兜底
- 光环"逐个放": Character:GetAttribute("Skill_Camera_Stabilize") 服务端同步作为 busy 锁; slot 再叠加 gap=MaxDuration+0.3s 节流; 多充能技能 (Flash Rend 2 层) 因每轮只放一个槽会隔 gap 续放直到层数用完
- 平A范围自动校准: 监听 HRP.ChildAdded "Hitbox" (服务器攻击判定盒) 抓几何 → calibRange 覆盖滑条值 (未抓到用滑条)
- 3D 范围圈: Drawing Line 分段 28 条投影, 脚底 Y offset -2.2, 透明度 0.75; 宝箱高亮: ForceField+LocalTransparencyModifier 本地染色; 雷达: 屏幕中心 Drawing.Circle + 三角箭头
- 结算加速: 覆写 RewardRevealController.PlayEntries (卡片立现 + 0.9s 后隐藏), OnCleanup 还原
- F1 下一房间: getCurrentRoom (Zone OBB) + roomHasEnemies 判定 + Exit CFrame 前移; 纯本地位移
- F2/F3 结算判定: 扫 PlayerGui 可见按钮文本 (重开/Replay/返回/Leave 等), 命中才发 RequestReplay/Return

### 验证
- 静态: loadstring 编译 OK (source 41KB)
- 动态: execute 运行 OK → 授权通过 (WoSh1N1D1e) → Rayfield 本地副本加载 → DR_HUB_v100 loaded, 无报错
- 热替换: 二次执行旧实例自毁接管完成
- 冒烟: require Shinobi.Skills 四技能全部读到 (发现并修复 AoEHitboxRange 坑); 敌人扫描/玩家属性读取正常
- **未验证**: UI 交互级实测 (开关/绘制/喝药/移速/结算/F键) 待用户实机

### 遗留问题 / 下一步
- [ ] 用户实机 UI 实测各功能; 按反馈修 bug (预计 PATCH)
- [ ] F1 出口传送是否触发服务端房间切换逻辑 (纯本地位移, 需实测"下一房是否正常刷怪")
- [ ] 结算界面按钮文本匹配是启发式, 若按钮无 Text 或为 ImageButton 需补 (BossRush/Challenge 模式另走 BossRushService 等)
- [ ] 平A Hitbox 校准仅在服务器攻击瞬间可抓; 若攻速快每下都在可稳定校准
- [ ] 新职业分析后再加 CLASS_PROFILES 一行 (技能数据全自动)

---

## [2026-09-03 | 会话1 | v0.1.0 | lib 当前] 新游戏建档 + 全量结构/战斗协议分析

### 目标
用户在地牢图注入, 要求开新档并深挖代码方便后续做功能。

### 改动明细 (函数级定位)
| 文件 | 位置 | 改动 |
|---|---|---|
| games/dungeon-raiders/intel.md | 全文 | 新建: 分图 ID、Knit 服务、战斗 Inputs、地牢解锁链、敌人 tag、功能可行性 |
| games/dungeon-raiders/hub.luau | 骨架 | 从 hub-skeleton 复制, GameName=地下城战利品者 |
| changelog.md / devlog.md | 顶部 | 初始条目 |

### 决策记录
- 目录名 `dungeon-raiders`(英文 kebab), 显示名用中文「地下城战利品者」与 intel `game:` / hub `GameName` 对齐
- 当前注入器只有 Potassium, 没有 Real `remote-spy`/`check-script`; 战斗协议靠 `decompile(Weapon_Input)` 钉死, Knit RF 列表靠实例树
- 未对 Grant/SetLevel 类 RF 做试探发包 (检测风险, 也不是功能路径)
- 未生成玩法循环: 用户要的是分析, 骨架留给下一轮按功能清单挑

### 验证
- `PlaceConfig` require 成功, 确认当前是 DungeonPlace
- 玩家属性: InDungeon=true, CurrentDungeon=Bandits Den, Class=Artemis, Lv10
- `CollectionService` 标签 Enemy/NPC 能扫到 Bandit, 休眠怪 `IsDormant=true`
- `DungeonRunService:GetSessionInfo()` 返回 Promise; `:await()` 解包方式本轮没解干净 (Knit Promise 二元组), 下一轮用 `andThen` 打会话结构
- Weapon_Input 反编译: Attack 参数是移动方向 Vector3; 持按 0.1s 循环

### 遗留问题 / 下一步
- [ ] 反编译 `ChestSelectionController` / `DungeonHUDController`(90k) 钉选箱参数与 Replay 流程
- [ ] 大厅图再扫一遍排队 RF 实参 (`RequestSelectDungeon` 传的是 DungeonId 字符串还是表)
- [ ] `DropSpawner` CollectDrop 第一个参数 `u58` 的来源 (掉落实例 id?)
- [ ] `Weapon_Manager.CanAttack` 客户端能否当本地门 (共享模块在客户端 require 是否完整)
- [ ] 若用户点功能: 优先自动普攻 + 吸掉落 + 低血吃药, 全 L1

---

---

---

## [2026-09-03 | 会话2.2 | v1.0.2 | lib 2.0.6 当前] 渲染迁移 + 技能真因 + UI 精简

### 用户实测问题
1. v1.0.1 宝箱透视(纯 Drawing fill)仍不可见; 光环范围圈也不可见 → Drawing 在 Potassium 全系失效
2. 调宝箱透明度仍崩溃 (v1.0.1 回调仅改变量 → 崩与回调无关, 指向 Drawing 渲染层把客户端搞崩)
3. 技能状态显示"释放"但实际没放 → 找到真因: **槽位参数要数字**! 客户端 u17={Skill1=1..4}, 我之前 tostring 成 "1" 字符串被服务端丢弃
4. 杀戮光环只打前方 (我加的前方 dot 过滤), 用户期望 360° 锁怪

### 决策与改动
- **彻底弃用 Drawing**: 全部绘制 → 原生 ScreenGui overlay 线段引擎 (Frame Rotation 画线池 + 填充 bar 池), 按帧 hide 复用。根治可见性与崩溃 (原生 UI 引擎)
- 3D 圈 / 宝箱 fill / 雷达圆与箭头全部改走 overlay; 移除 drawingAvailable 探测
- 技能 Fire 改传数字槽位; 光环 360° (删 fwd dot)
- 战斗 Tab 重排: Toggle 在上 参数在下, 删两个状态 Paragraph
- UI 精简: 用户澄清"不是删移动Tab, 是去掉所有功能描述文字" → 全局删 Desc 行(19处) + Paragraph 说明; 移动 Tab 恢复(自动奔跑/移速, 无描述)
- 新增 视觉-假名: 扫 PlayerGui 找 Text==玩家名 且在左上(或父链 hud/top) 的 TextLabel → RichText 彩虹逐字 "theKing User"; 0.25s 循环纳管新 label

### 验证
- 编译未做 (客户端崩后未重连); changelog/devlog 已记
- 待客户端重连: 编译+加载+复测 (圈可见性/宝箱/技能实际释放/彩虹名)

### 遗留
- [ ] Drawing 崩溃假设验证: 若 v1.0.2 不再崩且绘制可见 → 坐实
- [ ] 假名目标 label 若不在左上(如头像旁), scanFakeName 找不到需用户描述位置
- [ ] overlay 每帧 UI 属性写入 ~几百次, 若卡顿需降频策略

---

## 踩坑黑名单 (跨会话累积, 只增不删)

> 格式: `[错误模式] → [后果] → [正确做法]`

- [Knit 客户端 RF 当同步返回值用] → [拿到的是 Promise 表, 字段是 `_status/_thread`] → [必须 `:await()` 或 `andThen`, 并按 Promise 二元组解包]
- [把 Replica* 当业务动作 Fire] → [这是数据复制通道] → [写数据走对应 Knit Service]
- [对休眠怪打 Attack] → [IsDormant=true 的怪还在未进房间] → [先推进房间/靠近唤醒再循环攻击]
- [GrantCurrency/SetLevel/GiveReward 当刷资源] → [GM 口, 大概率拒+画像] → [只发游戏自己的请求型 API]
- [同一块作用域二次 `local meleeEnabled`] → [BindToggle 改的是第二份, DBreset 钩的是第一份, 连击永远不触发] → [开关/发包/钩子共用一份 local, BindToggle 前禁止再声明]
- [闲置 Hitbox Size≈0.05 仍用 C0.Z+Size.Z/2] → [锻造霸主算成 ~8m, 实际 Range=16] → [Size.Z<1 当占位, reach=2*|C0.Z|; 锻造霸主弓形态另加 SpecialRangeBonus]
- [锻造霸主平A只用 Definition.Range] → [3技能切弓后还按 16m 找怪, 远处空挥] → [看 Bow 透明度切形态; 弓=Range+SpecialRangeBonus]
- [视觉 Dropdown 只写 Rayfield Flag] → [本环境 rfld 不落盘, 下次注入颜色/职业丢] → [Callback 写 PREF + Default 从 PREF 读]
- [菜单显隐靠 Rayfield 默认] → [下次注入窗口总是弹出] → [PREF.uiHidden + SetWindowHidden]
- [技能改打近处却不改 Cbt.lock] → [脚底圈一只、平A/技能打另一只] → [出手路径 Cbt.mark; 锁侧后或近处更近则重选]
- [DPS 用 DungeonRun bool 边沿清 dpsMeta + Damage_Dealt 变小当 0] → [同一局里总伤闪 0] → [按 InDungeon+图名分局; 短 0 保持上次总伤]
- [0.1s 写一次 WalkSpeed] → [游戏 50ms 内打回, 移速开关等于没开] → [Heartbeat + GetPropertyChangedSignal 立刻回写]
- [业务 IIFE 平铺对象池+几十个 local function] → [峰值 200, loadstring limit 200] → [绘制收 Ov 闭包; 新状态 TheKing.Pack; check_hub.py]
- [FindFirstChild 第一座 Blessing_Altar] → [后面祭坛不交互] → [扫所有 Receive Blessing, 开最近且未用过的]
- [Destroy 只 Enabled=false] → [窗还在、循环还跑] → [purgeUi 拆 GUI + hubAlive 停心跳]
- [以为打完换房脚本还在] → [Replay/回城是换服, DataModel 没了] → [queue_on_teleport 挂号本地 hub; 无 API 则跳过]
- [hub 里 ArmTeleportReload 跟钾 autoexec 叠两套] → [换房重复注入/抢锁] → [1.2.5 起 hub 不挂号, 换图只靠 autoexec]
- [nextHop 把过廊/祭坛小 Room 当下一房, 出 Zone 后 leftStart 空转] → [捡箱后卡在中间走廊不去第二房] → [只认战斗房; 廊里 lastRoomN 找下一战斗房中心]
- [用 Zone 面积≥900 当战斗房] → [过廊 43×80=3440 被当成下一房, 人停廊中间] → [有 Enemy_Spawn 或 min(Size.X,Z)≥70]
- [MoveTo 穿关闭的 Gate] → [1–2 房门口贴门, 绿线停、不寻路] → [近路的 Gate 本地关碰撞, 沿绿线走; 不要用 F1 CFrame 闪门]
- [HUD Current+Boss 当已进 Boss 房] → [倒数第二房清完绿标提前变 Boss, 人卡门口不走] → [认 Spawns.Boss_Spawn; 没进该房就继续 nextHop]
- [过廊 lastRoomN=0 再 seek Room_1] → [出初始房去第一战斗房又折返] → [进度只增不减; 旧 Zone 当走廊; leftStart 后绝不寻回 Room_1]
- [死后不清绿线 + 更小房号当走廊] → [回上一间重生仍沿穿墙路点撞墙] → [倒下/瞬移丢掉旧路, lastRoomN 对齐当前战斗房, 从门口重走]
- [autoexec 写文件锁后 task.spawn 注入] → [文件 return 钾掐线程, 锁还在, 进图再也不注入] → [赢选举的那份当前线程同步 loadstring; 没窗口才能抢锁; 不要用 lock:find(job) 无条件 return]
- [远程进战斗房先走 Zone 中心] → [站怪堆中间吃伤害] → [Cbt.isRanged 且房内有怪则跳过 center, kite 按平A射程拉开]
- [补药 needPotion 死等账号 MaxPotions] → [锅灌满仍 n<属性上限, 人站锅边不走] → [锅边数量涨停/已满/2s 后 skipPot, 继续 nextHop]
- [岔路小房只认门外活怪/已刷箱] → [模板有刷怪点但实体进门才出, 判空后 nextHop 直接下一房] → [sideWorth 看 Enemy_Spawn/Chest_Spawn; 清完才 sideDone]
- [闪避用 keypress Q] → [钾不进 UIS, 人不动] → [发 Inputs.Dash:FireServer(水平离开圆心方向); 认 Dodge_Cooldown_Active 不是角色 Dodge]
- [AoE 粒子只 GetChildren] → [PE 在 Attachment 下, 永远判没预警] → [GetDescendants 认 Enabled]
- [BindToggle 默认 Value=true 当已开启] → [创建不触发 Callback, 循环没跑] → [Value=false + RestoreToggle; 光环 OnEnable 再 BindStepped]
- [getCurrentRoom 在 `local Nav` 之前读 Nav.stayRoom] → [闭包抓全局 nil, 寻路/风筝每帧炸] → [Nav 前向声明放 IIFE 顶部, 寻路区只赋值不要再 local]
- [L 拐角房 Zone≥70 当战斗房 + 走 AABB 中心] → [路走完贴内墙, MoveTo 停] → [Connectors 两轴都偏=过廊, 不居中; 卡住沿 Exit 主轴往前顶]
- [普通地牢卡死只 Replay 整局] → [人还在墙角, 重开浪费] → [自动重开下 10 分钟未出星用 Health=0 Roblox 重生刷到上一间]
- [活动有水晶还躲圈/锁 BOSS] → [砸不出水晶、小弟未清 BOSS 回血] → [有小弟清光; 再砸完水晶; 这两段禁止闪避与 raidBossWrap]
- [活动水晶未砸完被秒杀后 inRaid 只认 InRaid] → [Raid_NPCs 无 Enemy 标签, pick 空转不攻击] → [inRaid 加图名/Raid_NPCs; 死后 raidWipe; 观战 LeaveSpectate]
