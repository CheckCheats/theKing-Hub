---
genre: shooter
game: "[🔥UPD] Sniper Arena"
placeId: 119259569670784
universeId: 9534705677
placeVersion: 154
created: 2026-09-01
updated: 2026-09-03
script: "games/sniper-arena/hub.luau"
status: active
---

# 游戏情报档案 — [🔥UPD] Sniper Arena

> **AI 铁律**:
> 1. 会话开始必须先读本文件 + `recall-game-memory`, 禁止对已有结论重新逆向。
> 2. 开发中新发现: 当场 `remember-game` (运行时召回), 收工前回写本文件 (持久归档)。
> 3. 每条结论必须带条目头: `[日期 | pv<placeVersion> | 来源脚本@版本]`。
> 4. 游戏更新 (placeVersion 变更) 时: 把受影响条目剪切到「待复核」区并标注新 pv, **不删除**。
> 5. 结论被证伪时: 移到「已证伪」区保留原文 + 写明证伪原因, 不静默删除。

## 协议与通信

## [2026-09-01 | pv154 | sniper-arena@0.1.0]
- 底层协议: `ReplicatedStorage.ByteNetReliable` + `ReplicatedStorage.Remote.Any.*` 大量 RemoteEvent (423+)
- 战斗组件体系: `Client.CombatController` / `Client.WeaponController` 组件化 (ClientGun + Shootable/Fire/Aimable)
- 命中射线: `Common.AsyncService.AsyncRaycast.Raycast(origin, direction, params)` → 内部 Worker 最终走 `Util.RaycastUtils.Raycast` → `workspace:Raycast`
- universe 官方名 `[🔥UPD] Sniper Arena` (rootPlaceId=122446657157717); `[游戏厅]` placeId=126042865144779 为大厅, 暴力功能在此内部失效

## [2026-09-03 | pv194 | sniper-arena@1.1.4]
- **大厅判定**: Place 名含「游戏厅/大厅/lobby」、已知大厅 PlaceId、或角色在 `workspace.Lobby` 包围盒内 → 静默/绘制/扳机不生效 (开关不关)
- **对局**: 离开大厅 place / 离开 Lobby 模型范围后自动恢复

## Remote 清单

## [2026-09-01 | pv154 | sniper-arena@0.1.0]
- 射击相关 remote 名未单独枚举; 客户端走 `ClientGun:InvokeAction(Shoot, payload)` 组件消息, 非裸 FireServer 直调
- 可见命名 remote: `Remote.Rewards.ShootingRangeDummy`, `Remote.TradeLobby.CashGun.Fire` (非主战斗)

## NPC / 地点坐标

## 关键机制结论

## [2026-09-03 | pv194 | sniper-arena@0.4.0]
- **子弹碰撞**: `Team1Atk` 打 Team2/3 + Default 地图, 不打 Team1 队友、不打 Barrier/Obj/Dead
- **可视化锁定**: 射线 CollisionGroup 用本地队对应 Atk 组; 第一击中必须是目标 CanQuery 部位 (Head 碰撞体 CanQuery=true, HRP 常为 false)

## [2026-09-03 | pv194 | sniper-arena@0.3.4]
- **对局真人**: 手里有枪/刀骨骼 (`Gun-Main` / `Gun-*` / `Gun_*` / Knife 等) 才算进战
- **对局外观**: `Workspace.Highlight.Enemy.HighlightHolder.<玩家名>` (有 Humanoid/Head, GetPlayerFromCharacter 能拿到人); 队友在 `Highlight.Friendly.HighlightHolder`
- **大厅角色**: `Workspace.<玩家名>` = `Player.Character`, 通常无枪骨, 不是对局目标
- **World.Entities**: 可能有同名模型但未持械 (旁观/未进战), 不能单靠扫 Entities
- **尸体误判**: 对局高亮不是 `player.Character`, 不能用 Character 不一致过滤

## [2026-09-03 | pv194 | sniper-arena@0.3.2]
- **队伍检测**: 以 `EntityService.IsFriendly` 为准 (Player / Character / Entities 根模型都问); 仅开关开启时过滤。GetTeam 全员占位名时不可靠
- **存活**: `IsAlive` / `GetHealth` 同样多主体查询; Humanoid.Health 死后仍 100, 不能当死亡依据

## [2026-09-03 | pv194 | sniper-arena@0.2.1]
- **人机实体**: `World.<map>.Entities` 下常套多层 Model, 不只直系 Humanoid; 无 Humanoid 但有 Head/HRP 也可锁
- **IsFriendly**: 只对真实 Player 角色过滤友方, 人机不当队友/友方
- **尸体同名**: 仅玩家角色用 Players 同名过滤, 人机名字撞玩家时仍可锁

## [2026-09-01 | pv154 | sniper-arena@0.1.0]
- **射击瞄准原点**: `CameraController.GetCombatOriginFn()` 返回**单例** CFrame 函数 (多次调用同一引用), 被 `ClientShootableComponent.Shoot` 捕获
- **Shoot 流程**: `CombatOriginFn()` → `Position/LookVector` → `u27.Direction = LookVector` → `InvokeAction(Shoot)` → `BroadcastShooted({Direction, Bullets:[{Direction=GetSpreadedDirection}]})`
- **CombatOriginFn 返回值**: `u62.Get()` 返回 3 个值 (CFrame, nil, table); Shoot 只用第一项, 但其它调用方依赖完整返回
- **静默瞄准锚点**: 不要 hookfunction 该单例 (Potassium 会丢多返回值); 用 `debug.setupvalue` 替换 `ClientShootableComponent.Shoot` / `LocalShoot` 捕获的闭包

- **队伍**: `ReplicatedStorage.Remote.EntityService.GetTeam(player)` 返回字符串 (实测 `Default` / `Team1`); Roblox `Teams` 服务为空
- **混战占位**: `Default` / `None` / `FFA` / `Neutral` 不视为队伍
- **个人竞技**: 没有任何真实队名凑齐 2 名玩家时, 队伍检测开关保持开启但内部不生效
- **组队赛**: 同一真实队名 ≥2 人时, 静默瞄准跳过队友
- **自动扳机**: 走注入器 `mouse1click`, 不直调 `ClientShootableComponent.Shoot`

## [2026-09-03 | pv194 | sniper-arena@1.3.1]
- **存活判定**: `EntityService.IsAlive` / `GetHealth` (对 Player 或 Entities 模型); Humanoid.Health 死后仍 100, 不能当死亡依据
- **排除**: Lobby 无枪角色、Highlight 里没持械的预览、`_Temp`/`Died` 残留; **不要**排除 Highlight.Enemy 持枪模型

## [2026-09-03 | pv194 | sniper-arena@1.2.1]
- **个人竞技队名**: 全员(含 AI) `GetTeam` 都是同一占位名 (实测 `Team3`); 用「同队>=2人」会误判组队并锁不到任何人
- **组队判定**: 至少两支不同真实队名才 `teamPlay`; 单队占位名时队伍检测内部失效, 仍锁玩家和 AI

## [2026-09-03 | pv194 | sniper-arena@1.2.0]
- **实体容器**: 对局/靶场角色在 `Workspace.World.<mapId>.Entities.<名>`, 不是 workspace 直系 Entities
- **静默失效**: local `isEntityFriendly` 必须定义在 `isValidEnemyCharacter` 之前, 否则选人报错被 pcall 吞掉

## [2026-09-02 | pv154 | sniper-arena@0.3.6]
- **静默瞄准目标**: 除 Players 外还扫 workspace.Entities/Live/NPCs/Bots 等容器与 EntityService 实体表; 带 Humanoid 的非本地 Model 均可锁
- **队伍**: EntityService.GetTeam 可对 Player 或 Model 调用; 无队 AI 默认视为可打目标

## [2026-09-02 | pv154 | sniper-arena@0.3.4]
- **静默瞄准选人**: 角色任意 BasePart 包围盒端点进圈即视为圈内; 先按离准星最近的**人**, 再在该人身上选露出且 ease 高的瞄准骨; 骨骼中心出圈但轮廓在圈内也会锁
- **卸载**: 禁止在 WindUI 按钮/对话框回调里同步 `Window:Destroy`; 先关静默/白圈, `task.defer` 后再 Destroy (同步 Destroy 会崩客户端)

## [2026-09-01 | pv154 | sniper-arena@0.3.3]
- **静默瞄准选人**: 头/胸/根骨/四肢分部位 `WorldToViewportPoint` 进圈; 枪口→部位 Raycast 露出 (仅该敌人自身不算挡); 评分=2D距准星−ease (躯干略优先); 全无露出时回退圈内最近

## L2 手段登记 (危险功能对抗手段台账)

## [2026-09-01 | pv154 | 静默瞄准@0.1.5]
- 手段: debug.setupvalue 替换 ClientShootableComponent.Shoot/LocalShoot 的 CombatOriginFn upvalue
- 目标: 仅改射击方向 CFrame.LookVector, 保留另外两个返回值
- 验证: (待 FFA 实测)
- 信号特征: (未验证)

## 已证伪

## [2026-09-01 | pv154]
- hookfunction `GetCombatOriginFn()` 单例: Potassium 下丢失多返回值, 开启后无法开枪, 刀正常

## 可复用代码片段

## 待复核 (placeVersion 变更后移入)
