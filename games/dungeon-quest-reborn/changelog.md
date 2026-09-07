# <游戏名> TheKing HUB — 版本历史

> 维护铁律: 每次发布新版本必须在顶部追加条目; 条目格式固定; 不删旧条目。
> 备份规则: **major** 发布前先把旧 hub.luau 复制为 `archive/hub-v<旧版本>.luau`; fix/minor 只记本文件不备份。

```
版本号语义 (ScriptVersion, 写在 hub.luau 头部注释块):
  MAJOR  主版本   — 重构 / UI库或通信层更换 / 功能体系重做 (破坏性)
  MINOR  次版本   — 新增功能 / 显著增强现有功能
  PATCH  修订号   — bug修复 / 参数微调 / 文案修正 (不改变功能面)
```

---

## v0.0.1 — 2026-09-03
- chore: 版本号重置为 v0.0.1 (对外重新编号, 功能不变)

## v1.0.1 — 2026-09-03
- enhance: 跟随 lib v2.0.3 黑金主题发布 (Logo 呼吸 / 切 Tab 淡入 / 侧栏白字)。玩法不变。
  PATCH → v1.0.0→v1.0.1

## v1.0.0 — 2026-09-03
- refactor: 跟随 lib v2.0.0 迁 Rayfield Gen2 + 品牌方圆标。玩法不变。

## v0.4.4 — 2026-09-01
- feat: 全部 UI 项持久化 — 7 个 Toggle + 4 个 Slider + 4 个 Keybind 均 Register; 改项即时 Save; 热重载 Load 后自动恢复循环/移速。
  PATCH → v0.4.3→v0.4.4

## v0.4.3 — 2026-09-01
- feat: 新增「修改移动速度」开关 + 滑条 (16~120, 默认 32), 周期回写防游戏重置。
- change: 全屏命中改回「进索敌范围 → 传头顶 (+8 stud) → 出手」; 超出范围不传送、不自动 MoveTo, 释放 BodyMover 让玩家自己跑近。
- change: 移除全屏模式下清房后自动跨房 CFrame 传送。
  PATCH → v0.4.2→v0.4.3

## v0.4.2 — 2026-09-01
- fix: 自动准备/开始失效 — 世界 START 按钮 (ui.startButton) 协议是 `changeStartValue` 而非 `startDungeon`; showStartButton 事件同步修正。
- fix: 新增组队大厅 Start 检测 (queueGui/bossQueueGui.lobbyInfo.startButton → startDungeon)。
- improve: 自动开始轮询 2s→1s; 事件响应 0.5s→0.35s; 可见性校验 (ScreenGui.Enabled + Visible)。
  PATCH → v0.4.1→v0.4.2

## v0.4.1 — 2026-09-01
- fix: 全屏命中「传到敌人头上却打不出伤害」— 站位从直挂头顶+8 改为贴身水平平视 (~3.2stud / 抬高2);
  避免剑 hitBox 够不着、lookAt 近垂直方向崩、火球沿 LookVector 打偏。
- fix: 切目标 / 躲避返回后 0.12s 只锁位不出手, 等服务器位置同步再普攻/放技能。
- fix: 全屏命中内置普攻 (不再关掉 AutoAttack 却又不打); 普攻按武器 attackSpeed 节流。
- fix: 每帧刷新敌人 HRP; 躲避返回不再错误抬高 +8。
  PATCH → v0.4.0→v0.4.1

## v0.3.0 [2026-08-30 | pv1244]

### Added
- BOSS攻击自动躲避: 检测PrecastHitbox判定框(Cube/Circle), 自动传送躲避后再返回攻击
- BOSS躲避开关: 全屏命中Tab新增BOSS躲避Toggle

### Changed
- 全屏命中模式: 躲避中暂停悬浮, 等待自动返回

### 逆向依据
- PrecastHitbox模块: Cube/Circle判定框, delayUntilAttack延迟参数

---

## v0.2.2 [2026-08-30 | pv1244]

### Changed
- 全屏命中模式: 使用 `BodyPosition` + `BodyGyro` 强制钉死悬浮位置，彻底杜绝物理引擎导致的下落

### Fixed
- 修复全屏命中模式下角色仍会偶尔掉落的问题（BodyMover 强制锁定位置）

### 逆向依据
- 无新增逆向，基于现有 intel.md 结论优化

---

## v0.2.1 [2026-08-30 | pv1244]

### Changed
- 全屏命中模式: 默认索敌范围从200扩大至500 studs
- 全屏命中模式: 全屏命中时忽略范围限制，扫描全图敌人
- 全屏命中模式: 优化目标切换逻辑，目标死亡时立即选择下一个敌人，减少角色掉落空窗期

### Fixed
- 修复全屏命中模式下目标切换时角色会掉落的问题

### 逆向依据
- 无新增逆向，基于现有 intel.md 结论优化

---

## v0.2.0 [2026-08-30 | pv1244]

### Changed
- 全屏命中模式: 优化位置保持机制，每帧归零速度并使用 RenderStepped:Wait()，防止角色下落
- 全屏命中模式: 增强敌人扫描逻辑，同时扫描 workspace.enemies 和副本房间 enemyFolder
- 全屏命中模式: 新增房间传送功能，当前房间敌人清空后自动传送至下一房间的 startPart

### Fixed
- 修复全屏命中模式下角色会下落被敌人攻击的问题

### 逆向依据
- 无新增逆向，基于现有 intel.md 结论优化

---

## v0.1.0 [2026-08-30 | pv1237]

### Added
- 战斗 Tab: 自动普攻 / 自动 Q 技能 / 自动 E 技能 / 索敌范围 / 技能间隔
- 战斗 Tab (L2): 技能无视距离全命中 (传送至每个敌人身边施法)
- 快捷键 Tab: Q/E 技能信息实时显示 (名字/冷却/伤害) + 自定义触发键 + 普攻按钮
- 设置 Tab: 显示隐藏 DEL / 卸载 END / 停止全部 (骨架标配)

### 逆向依据
- 技能触发链 / 敌人容器 / remote 清单: 见 intel.md 2026-08-30 条目

<!-- 新版本条目追加在这条线之上, 格式:
## vX.Y.Z [日期 | pv<N>]
### Added / Fixed / Changed
- 变更点 (一行一条, 写清动了哪个功能)
### 逆向依据 (如有)
- 引用 intel.md 的相关结论条目日期
-->
