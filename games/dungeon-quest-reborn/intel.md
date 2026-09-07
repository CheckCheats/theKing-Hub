---
genre: dungeon
game: "Dungeon Quest Reborn"
placeId: 85776757589518
universeId: 9931749389
placeVersion: 1270
created: 2026-08-30
updated: 2026-09-01
script: "games/dungeon-quest-reborn/hub.luau"
status: active
---

# 游戏情报档案 — Dungeon Quest Reborn (地下城传奇复活)

> **AI 铁律**:
> 1. 会话开始必须先读本文件 + `recall-game-memory`, 禁止对已有结论重新逆向。
> 2. 开发中新发现: 当场 `remember-game` (运行时召回), 收工前回写本文件 (持久归档)。
> 3. 每条结论必须带条目头: `[日期 | pv<placeVersion> | 来源脚本@版本]`。
> 4. 游戏更新 (placeVersion 变更) 时: 把受影响条目剪切到「待复核」区并标注新 pv, **不删除**。
> 5. 结论被证伪时: 移到「已证伪」区保留原文 + 写明证伪原因, 不静默删除。

## 条目格式示例

```
## [2026-08-25 14:30 | pv5231 | sol-rng-fishing@2.0.0]
- ByteNetReliable 是唯一 Reliable RemoteEvent
- 包格式: [u8 packetId][payload], 一帧可含多包连续排列
- string 编码 = u16 长度 + 字节; bool/u8 = 1字节; f32/f64 标准 IEEE754
```

---

## 协议与通信

## [2026-08-30 18:10 | pv1237 | hub@0.1.0]
- 伤害判定全在服务器 (Tool 内 Script, RunContext=Server, 客户端不可读/不可 hook)
- 技能触发链: 按键Q/E -> PlayerGui.UIS (LocalScript) -> 找 Backpack/Character 中 abilitySlot=="q"/"e" 的 Tool -> tool.localEvent:Fire() + abilityUsed:FireServer("q"/"e", tool)
- Tool 内 LocalScript 监听 localEvent: 校验 cooldown.Value<=0 + busyCasting==false -> 技能特定 RemoteEvent:FireServer() (Fireball 用 fireballShootEvent, 其他 spellEvent/abilityEvent) + 播动画 + 卸装备
- 服务器处理技能后通过 remotes.abilityCast:FireClient(p, 技能名, ...) 通知客户端播投射物/特效 (PlayerGui.abilityLocal 监听)
- 客户端"想发什么"无断言参数, 纯粹 FireServer() 空调用触发, 服务器按 Tool 的 damage/abilityType 决定伤害

## Remote 清单

<!-- remote 名 | 路径 | 类型 | 参数格式 | 触发动作 | 服务端是否校验 -->
- abilityUsed | ReplicatedStorage.remotes.abilityUsed | RemoteEvent | ("q"/"e", tool实例) | 按Q/E时触发 | 未验证(疑似记冷却)
- weaponUsed | ReplicatedStorage.remotes.weaponUsed | RemoteEvent | () 空 | 普攻(鼠标左键)时触发 | 未验证
- 技能专用: Tool内 fireballShootEvent / spellEvent / abilityEvent / holyCircleEvent / absorbEvent | RemoteEvent | () 空 | localEvent触发后由Tool LocalScript发出 | 服务器权威判定
- abilityCast | ReplicatedStorage.remotes.abilityCast | RemoteEvent | (player, 技能名, ...) | 服务器->客户端通知播特效 | 客户端只播视觉
- 其他: clientLoaded, teleToLobby, swapAbilitySet, updateGoldDisplayRemote, moveItemToInventory(RemoteFunction), getData(RemoteFunction) 等

## NPC / 地点坐标

<!-- 名称 | CFrame 或模型路径 -->
- 副本: workspace.dungeon (initialRoom, room1-room5, bossRoom; 每房间有 enemyFolder 含 spawn Part + startPart + endPart + order IntValue)
- 敌人容器: workspace.enemies (空, 服务器按波次填充), workspace.enemyPool
- 状态: workspace.currentWave / dungeonStarted / dungeonProgress / timeLeft / tier / hardcore / skips / pause

## 关键机制结论

## [2026-09-01 | pv1270 | hub@0.4.2]
- **自动开始协议修正** (decompile 实锤):
  - 世界 START (`PlayerGui.startButton`, 由 showStartButton 克隆) → `remotes.changeStartValue:FireServer()` — 设置 workspace.start=true 并开始副本
  - 组队大厅 Start (`queueGui`/`bossQueueGui`.lobbyInfo.startBackground.startFrame.startButton) → `remotes.startDungeon:FireServer()`
  - 准备 (`readyButton`) → `remotes.readyUp:FireServer()`
- 旧版误把 startButton 当 startDungeon 是自动开始失效根因

## [2026-09-01 | pv1270 | hub@0.4.1]
- 全屏命中站位约束: **禁止直挂敌人头顶**。正确姿态 = 水平距约 3.2stud + 相对 HRP 抬高约 2stud, 视线保持水平对准敌人 (lookAt 目标 Y = 自身 Y)。
- 根因: 武器 Accessory `hitBox` 约 Size(0.71,6.53,1.73) 挂角色前侧 — 头顶+8 时碰不到敌人; `CFrame.lookAt` 近垂直有方向奇点; 技能视觉/伤害沿 `HumanoidRootPart.LookVector` 前射 (Fireball/Searing Beam: `HRP.CFrame + lookVector*3`)。
- 切目标后需短 settle (~0.12s) 再 FireServer, 否则服务器仍按旧位置判空。
- Tool LocalScript (decompile): `localEvent` → 校验 cooldown+本地 debounce+busyCasting → `spellEvent:FireServer()` + 播 spellAnim 2.5s; 无目标参数。

## [2026-08-30 18:10 | pv1237 | hub@0.1.0]
- 玩家当前技能: Backpack 两个 Fireball (q/e 槽), 100 伤害, 9s 冷却, spell 类型
- 普攻: 鼠标左键 -> Character 里 Accessory 带 Weapon 子级的 RemoteEvent:FireServer() + weaponUsed:FireServer(); 城镇 (peaceful.Value) 禁止
- busyCasting: Character 上 BoolValue, 施法期间 true, 服务端/客户端共同维护
- 敌人是 Humanoid (workspace.enemies 下), damageNums 监听 Humanoid.HealthChanged 显示伤害数字
- 无元表 hook (dump-anticheat-hooks 全 C closure) — 反作弊未见主动 hook
- 技能"无视距离命中所有敌人"可行性评估: 伤害服务器权威且技能无目标参数(空 FireServer), 客户端无法直接指定命中目标;
  可行路径 = 自动普攻/自动技能 + 传送至敌人群附近再放技能 (L2 模拟, 需实测服务器对传送的校验)

## L2 手段登记 (危险功能对抗手段台账)

## [2026-09-01 | pv1270 | 全屏命中]
- 手段: 客户端 CFrame + BodyPosition/BodyGyro 贴身平视锁定敌人, 再走原生 swing/spellEvent
- 目标: 玩家 HRP 位置 (不 hook 反作弊, 不伪造伤害)
- 验证: 待副本实机; 大厅已确认 hitBox/spell 路径
- 信号特征: 若出现瞬移回滚/技能无冷却空放 → 服务器在校验位置, 加大 settle 或改走房间 startPart 路径

<!-- 每条: [日期 | pv<N> | 功能名]
- 手段: hook 抢发包/模拟输入/...
- 目标: 函数或 remote 路径
- 验证: 小号实测时长 + 无 kick/回滚/弹窗
- 信号特征: 出问题时服务器如何反应 (供封禁预警)
-->

## 可复用代码片段

<!-- 已验证的 send/listen/buffer 片段, 注明依赖条件 -->

## 待复核 (placeVersion 变更后移入)

## 已证伪
