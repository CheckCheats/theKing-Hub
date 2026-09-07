# <游戏名> TheKing HUB — 开发手册 (DevLog)

> 维护铁律: **每次开发会话收工前必须追加一条**, 写给下一个接手的 AI 和未来的自己。
> 与 changelog.md 分工: changelog 面向用户记"发布了什么"; 本文件面向开发者记"怎么做的、为什么、验证结果、遗留问题"。
> 接手 AI 使用法: 只读本文件最后一条 + intel.md 相关分区, 即可恢复全部上下文, 禁止凭空猜测前人意图。

---

## [2026-09-03 | v1.0.1 | lib v2.0.3] 黑金主题发布
跟随共享库主题打混淆包推 Gitee。玩法未改。

## 条目格式 (复制使用)

```
## [YYYY-MM-DD | 会话N | vX.Y.Z | lib v1.2.0] <一句话主题>

### 目标
本轮想达成什么 (1-3 行)

### 改动明细 (函数级定位)
| 文件 | 位置 | 改动 |
|---|---|---|
| hub.luau | autoSellFish() L120-150 | 新增: ... |
| lib/theking.luau | StartLoop | 修改: ... |

### 决策记录 (为什么这么改)
- 方案A被否原因 / 选择方案B的理由 / 关键权衡

### 验证
- 怎么测的 (record-session/watch-value/手动), 结果如何

### 遗留问题 / 下一步
- [ ] 具体待办, 写清复现条件和线索
```

---

<!-- 实际条目追加在这条线之下, 最新的在最上面 -->

---

## [2026-09-01 | 会话7 | v0.4.4 | lib] 全功能配置持久化

### 目标
战斗/辅助/快捷键/设置页所有可调项热重载后自动恢复。

### 改动明细
| 文件 | 位置 | 改动 |
|---|---|---|
| hub.luau | persistSave / configLoading | 新增: Load 期间不 Save; 用户改 Toggle/Slider 即时存档 |
| hub.luau | UI 元素引用 | rangeSl/skillDelaySl/fullHitHeightSl/walkSpeedSl/kbQKey 等 |
| hub.luau | Config:Register ×14 | 全部 Toggle+Slider+Keybind |
| hub.luau | LoadConfig 后 | restartCombatLoop + applyWalkSpeed 对齐运行时 |

### 验证
- 待热重载: 改索敌/移速/开关 → 重跑 hub → 应自动恢复。

---

## [2026-09-01 | 会话6 | v0.4.3 | lib] 移速修改 + 全屏命中跑近模式

### 目标
1. 新增移动速度修改
2. 全屏命中改回头顶传送 (进范围再传)
3. 接近目标由玩家自己跑, 脚本不 MoveTo

### 改动明细
| 文件 | 位置 | 改动 |
|---|---|---|
| hub.luau | Settings WalkSpeedMod/WalkSpeed | 新增移速修改 |
| hub.luau | applyWalkSpeed / resetWalkSpeed / walkspeed 循环 | 新增 |
| hub.luau | combatTick FullHit | 范围外 removeHoldMovers + 状态提示; 范围内 lockPosition 头顶 |
| hub.luau | collectEnemies | FullHit 仍可索全图目标, 出手仍受 Range 门控 |
| hub.luau | UI MiscSec / FullHitSec | 移速开关/滑条; 头顶高度滑条; 文案更新 |

### 决策记录
- 实机证实客户端 CFrame 骗服务器位置无法稳定出伤; 改为玩家自己跑进范围 (可配合移速) 再头顶传送。
- 去掉 MoveTo 与清房跨房传送, 避免 BodyMover 锁死导致跑不动。

### 验证
- 待游戏内热重载: 开移速 + 全屏, 范围外应能正常跑动, 进范围后传头顶出手。

### 遗留问题 / 下一步
- [ ] 实机确认进范围后头顶传送能否出伤 (依赖服务器是否已同步玩家进房)

---

## [2026-09-01 | 会话5 | v0.4.2 | lib] 自动开始修复 + 全屏命中 v0.4.1 收尾

### 目标
1. 修复「自动开始不起作用」— 开了不会帮点 START
2. 收尾 v0.4.1 全屏命中贴身平视优化

### 改动明细
| 文件 | 位置 | 改动 |
|---|---|---|
| hub.luau | autoReady / isGuiVisible / findLobbyStartButton | 重写: startButton→changeStartValue; queue Start→startDungeon |
| hub.luau | showStartButton 事件 | 修正: changeStartValue (原误 startDungeon) |
| hub.luau | computeFullHitPose 等 | v0.4.1 已合入: 贴身平视+settle+内置普攻 |

### 决策记录
- Potassium decompile 实锤: `ReplicatedStorage.ui.startButton` 点击发 `changeStartValue`, 不是 `startDungeon`
- `startDungeon` 仅用于 queueGui/bossQueueGui 大厅 Start 按钮
- 实机验证: 手动 FireServer(changeStartValue) → workspace.start=true, dungeonStarted=true

### 验证
- 控制台实测 changeStartValue 有效 (startButton 被销毁, 副本开始)
- 待: 重跑 hub 后开「自动准备/开始」验证 START 按钮场景

### 遗留
- [ ] 热重载 hub v0.4.2 进游戏实测全屏命中+自动开始

---

## [2026-09-01 | 会话4 | v0.4.1 | lib] 全屏命中打不出伤害修复

### 目标
修复「传送到敌人头上却打不出伤害」的偶发/常见失效。

### 改动明细
| 文件 | 位置 | 改动 |
|---|---|---|
| hub.luau | Settings | 新增 FullHitHoriz/Height/Settle |
| hub.luau | computeFullHitPose / refreshEnemyParts / getSwingInterval | 新增 |
| hub.luau | combatTick FullHit 分支 | 贴身平视 + settle + 内置普攻节流 + HRP 刷新 |
| hub.luau | FullHit Toggle | 不再强制关 AutoAttack; 文案改为贴身平视 |
| hub.luau | handleHitboxPart 返回 | 去掉错误 +8 抬高, 回写 settle |

### 决策记录
- 根因 empirically: 头顶+8 时武器 hitBox(~2stud 前伸)碰不到敌人; `CFrame.lookAt` 近垂直奇点导致朝向乱; 火球/Searing Beam 客户端与服务器都沿 HRP.LookVector 水平前射。
- 方案选贴身平视而非继续微调头顶高度 — 同时覆盖普攻与技能。

### 验证
- Potassium decompile: Tool spell 仅 `spellEvent:FireServer()`; abilityLocal 火球 `HRP.CFrame + lookVector*3`
- 武器 hitBox Size≈(0.71, 6.53, 1.73), 挂在角色前方
- 待进副本实机确认伤害数字稳定出现

### 遗留问题 / 下一步
- [ ] 副本内实机验证: 全屏命中 + 普攻/Q/E 是否稳定出伤
- [ ] 超大体型 BOSS 是否需要按模型尺寸放大 FullHitHoriz

---

## [2026-08-30 | 会话3 | v0.2.1 | lib v1.5.0] 全屏命中扫描范围优化 + 目标切换流畅性提升

### 目标
- 扩大全屏命中模式的索敌范围，确保能扫描到更远的敌人
- 优化目标切换逻辑，减少角色掉落空窗期，防止被群殴

### 改动明细
| 文件 | 位置 | 改动 |
|---|---|---|
| games/dungeon-quest-reborn/hub.luau | Settings.Range | 默认值从200改为500 studs |
| games/dungeon-quest-reborn/hub.luau | collectEnemies() L220,244 | 全屏命中模式下忽略范围限制 (Settings.FullHit) |
| games/dungeon-quest-reborn/hub.luau | combatTick() while循环 L369-387 | 重构: 目标死亡时立即选择下一个敌人，重置deadline，减少空窗期 |
| games/dungeon-quest-reborn/hub.luau | 头部注释块 | 更新: 版本号 0.2.0→0.2.1 |

### 决策记录
- 范围优化: 全屏命中模式下自动忽略范围限制，确保扫描全图敌人
- 切换逻辑: 在循环内部实时检查目标死亡，立即切换，避免等待deadline导致掉落

### 验证
- 待实测: 需要进入副本验证扫描范围和切换流畅性

### 遗留问题 / 下一步
- [ ] 实测全屏命中模式下是否仍会掉落
- [ ] 优化没有敌人时的悬浮保持 (当前会掉落)

---

## [2026-08-30 | 会话2 | v0.2.0 | lib v1.4.1] 全屏命中位置保持优化 + 房间传送

### 目标
- 优化全屏命中模式的位置保持机制，防止角色下落被敌人攻击
- 增强敌人扫描逻辑，实现房间清空后自动传送至下一房间

### 改动明细
| 文件 | 位置 | 改动 |
|---|---|---|
| games/dungeon-quest-reborn/hub.luau | holdAboveEnemy() L241-254 | 修改: 每帧设置 CFrame 前归零速度 (Velocity/RotVelocity)，防止物理引擎干扰 |
| games/dungeon-quest-reborn/hub.luau | combatTick() while循环 L266 | 修改: 使用 RenderStepped:Wait() 替代 task.wait(0.08)，提升位置同步频率 |
| games/dungeon-quest-reborn/hub.luau | collectEnemies() L202-234 | 修改: 同时扫描 workspace.enemies 和副本房间 enemyFolder，合并去重 |
| games/dungeon-quest-reborn/hub.luau | teleportToNextRoom() L285-319 | 新增: 根据房间 order 自动传送至下一房间的 startPart |
| games/dungeon-quest-reborn/hub.luau | combatTick() 敌人清空逻辑 L333-351 | 修改: 全屏命中模式下敌人清空时尝试传送至下一房间 |
| games/dungeon-quest-reborn/hub.luau | 头部注释块 | 更新: 版本号 0.1.0→0.2.0，功能清单添加房间传送 |

### 决策记录
- 位置保持方案: 直接设置 CFrame 并归零速度，比 BodyPosition/BodyGyro 更轻量，且与游戏原有物理交互更少
- 房间传送时机: 在敌人清空时立即传送，而非等待波次结束，因为副本可能没有明确的波次结束信号
- 扫描范围: 同时扫描 workspace.enemies 和房间 enemyFolder，兼容不同副本实现

### 验证
- 待实测: 需要进入有敌人的副本验证位置保持和传送功能
- 预期: 全屏命中模式下角色应稳定悬浮在敌人头顶，不会下落；房间清空后自动传送

### 遗留问题 / 下一步
- [ ] 实测传送是否被服务器接受 (L2 风险)
- [ ] 实测位置保持是否完全消除下落 (RenderStepped 频率)
- [ ] 优化传送逻辑: 处理 bossRoom 和初始房间的边界情况

---

## [2026-08-30 | 会话1 | v0.1.0 | lib v1.4.1] 首飞建档 + 战斗Tab + 快捷键Tab

### 目标
- 分析 Dungeon Quest Reborn 副本技能系统, 评估"技能无视距离命中区域所有敌人"可行性
- 构建 TheKing HUB 初版 (战斗Tab + 快捷键Tab + 设置页)

### 改动明细
| 文件 | 位置 | 改动 |
|---|---|---|
| games/dungeon-quest-reborn/hub.luau | 全文 | 新建: 战斗 Tab (自动普攻/自动Q/E/全屏命中L2) + 快捷键 Tab (技能信息+手动触发) + 设置页 |
| games/dungeon-quest-reborn/intel.md | 全文 | 新建: Remote 清单 / 关键机制结论 / 协议与通信 |
| games/dungeon-quest-reborn/changelog.md | 首条 | 新建: v0.1.0 条目 |

### 技能系统分析结论
- 技能触发链: 按键Q/E -> PlayerGui.UIS -> 找Backpack abilitySlot=="q"/"e"的Tool -> tool.localEvent:Fire() + abilityUsed:FireServer(slot, tool)
- Tool内LocalScript监听localEvent: 校验cooldown<=0 + busyCasting==false -> 技能专用RemoteEvent:FireServer() (Fireball用fireballShootEvent)
- 服务器Tool内Script (RunContext Server) 处理伤害判定, 客户端不可读/hook
- 伤害全服务器权威, 客户端无法直接指定命中目标
- "无视距离全命中"可行路径: 传送至每个敌人身边施法 (L2, 需实测传送是否被服务器校验)
- abilityUsed 实测: FireServer 被接受, 冷却倒计时 + busyCasting 置位

### 反作弊环境
- dump-anticheat-hooks: 全 C closure, 无注入连接, 无元表 hook — 干净

### 验证
- Hub 启动成功 (WindUI 本地加载, 窗口在 CoreGui 内渲染可见)
- castAbility 路径实测: le:Fire() + abilityUsed:FireServer("q", tool) 被服务器接受 (冷却倒计时, busyCasting 置 true)
- remote-spy 捕获到 abilityUsed 调用, 参数格式正确 (slot string + tool Instance)

### 遗留问题 / 下一步
- [ ] 全屏命中 L2 待实测: 当前副本 wave=0 无敌人, 需等敌人刷新后验证传送+施法是否被服务器接受
- [ ] 技能伤害范围: 需要实测服务器对 Fireball 的伤害判定范围 (投射物 vs 即时AOE)
- [ ] 敌人刷新后测试: 自动普攻是否触发伤害数字 (weaponUsed + Weapon RemoteEvent)
- [ ] 快捷键 Tab 的 Keybind 自定义键触发 Q/E 需实测 (hub-local Keybind 不走游戏 UIS, 直接 castAbility)

---

## 踩坑黑名单 (跨会话累积, 只增不删)

> 格式: `[错误模式] → [后果] → [正确做法]` — 开工先扫一遍, 已知坑零二次。

- [全屏命中直挂敌人头顶+8 + lookAt 脚下] → [普攻/火球经常 0 伤害] → [贴身水平平视 ~3.2stud, lookAt 保持同 Y; 切目标后 settle 再出手]
- [开启 FullHit 时强制 Settings.AutoAttack=false 却依赖头顶普攻] → [只开全屏命中时几乎不出伤] → [FullHit 分支内置普攻, 不依赖 AutoAttack 开关]
- [startButton 误发 startDungeon] → [自动开始完全无效] → [世界 START 发 changeStartValue; 仅大厅 Start 发 startDungeon]

