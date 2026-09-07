# (学乱) Gakuran TheKing HUB — 版本历史

> 维护铁律: 每次发布新版本必须在顶部追加条目; 条目格式固定; 不删旧条目。
> 备份规则: **major** 发布前先把旧 hub.luau 复制为 `archive/hub-v<旧版本>.luau`; fix/minor 只记本文件不备份。

---

## v0.0.1 [2026-09-03]
- chore: 版本号重置为 v0.0.1 (对外重新编号, 功能不变)

## v1.0.1 [2026-09-03]
- PATCH: 跟随 lib v2.0.3 黑金主题发布 (Logo 呼吸 / 切 Tab 淡入 / 侧栏白字)。玩法不变。

## v1.0.0 [2026-09-03]
- MAJOR: 跟随 lib v2.0.0 迁 Rayfield Gen2 + 品牌方圆标。玩法不变。

## v0.3.0 [2026-08-25 | pv7560]

### Added
- **走路姿势系统**: 16 套 Roblox 官方动画包 (忍者/骑士/海盗/僵尸/吸血鬼/狼人/超级英雄/法师/机器人/宇航员/卡通/玩具/悬浮者/老者/时髦/活泼), Dropdown 一键替换平常状态的走路+待机+跑步全套, 全服可见; 支持恢复默认; 角色重生后持续生效。战斗姿态不受影响。
- 替身使者站位三轴可调: 左右偏移 (-6~6) / 高度 (-4~8) / 身后深度滑条。

### Changed
- 祖国人飞行重构 (社区 Superman-Fly 正解): `SetStateEnabled(全部false)` 废掉状态机 + Animate 脚本禁用 + 飞行动画 `AdjustSpeed(0)` 定格在最佳帧 — 姿势永不接缝; 朝向无条件对齐相机视线 (yaw+pitch 数学构造, ±85° 俯仰); 播放前独占清场 Animator 上一切其他 track。

### Fixed
- 飞行中动作不完整: 根因 = 多 Action track 权重混合 + 游戏 Core 动画透出 + emote 型动画循环接缝。

<!-- 新版本条目追加在这条线之上 -->

## v0.2.0 [2026-08-25 | pv7560]

### Changed (功能重做, MINOR)
- **祖国人重做**: 弃用 Gakuran 原生 emote, 改用真实祖国人动画 (Roblox UGC "Homelander" 系列, GetObjects 拆包取真实 AnimationId)。新增飞行状态机: 移动/升降时自动切超人飞姿, 静止悬浮; 新增手动姿势锁定按钮 (Hover/Pose/GodIdle)。
- **替身使者重做**: 动作换真实 JOJO 动画 (The World Stand Pose / Jojo Pose Idle Pt3), FE 通道循环播放; 跟随逻辑保留。
- 战斗桥重构: hook 操作锚从 OnM1Activated 的 upvalue 改为 ServerResponse 共享 upvalue ([4]=combo [5]=ready), 带 ComboResetTime=1.55 布局校验锚点。

### Fixed
- 快攻/遗忘不生效: 根因 = OnM1Activated 被 hookfunction detour 后 getupvalue 报错导致 Init 校验失败 → 整个战斗桥停摆。改锚 ServerResponse 后实测 setupvalue 写入生效。

### 逆向依据
- intel.md 2026-08-25 条目: FE 动画复制原理 / UGC Emote 拆包 / M1 ServerResponse upvalue 布局 dump

<!-- 新版本条目追加在这条线之上, 格式:
## vX.Y.Z [日期 | pv<N>]
### Added / Fixed / Changed
- 变更点 (一行一条, 写清动了哪个功能)
### 逆向依据 (如有)
- 引用 intel.md 的相关结论条目日期
-->
