---
genre: simulator
game: "Clean the WORLD!"
placeId: 105767799784652
universeId: 10494847029
placeVersion: 761
created: 2026-09-01
updated: 2026-09-01
script: "games/clean-the-world/hub.luau"
status: active
---

# 游戏情报档案 — Clean the WORLD!

> **AI 铁律**:
> 1. 会话开始必须先读本文件 + `recall-game-memory`, 禁止对已有结论重新逆向。
> 2. 开发中新发现: 当场 `remember-game` (运行时召回), 收工前回写本文件 (持久归档)。
> 3. 每条结论必须带条目头: `[日期 | pv<placeVersion> | 来源脚本@版本]`。
> 4. 游戏更新 (placeVersion 变更) 时: 把受影响条目剪切到「待复核」区并标注新 pv, **不删除**。
> 5. 结论被证伪时: 移到「已证伪」区保留原文 + 写明证伪原因, 不静默删除。

## 建档元数据

- 官方名: Clean the WORLD! [PRESTIGE!]
- 客户端本地化名 (MarketplaceService): 清洁世界！[声望！]
- 制作组: Bring Back Old Robloxians
- 目录: `games/clean-the-world/`
- 建档时 JobId: `ff9d03fb-0d14-4587-a828-a4c4ea3aa65b`
- 玩法粗描 (公开资料, 未逆向验证): 清扫垃圾/树叶赚现金 → 升级装备 → 解锁时代 → 声望; 地下城 Chapter 3 / 外太空 Chapter 4 为预告。

## 协议与通信

## [2026-09-01 | pv761 | clean-the-world@0.2.0]
- 通信不是 ByteNet: `ReplicatedStorage.Remotes` 下一组 RemoteEvent/RemoteFunction, 共 37 个。
- 地上垃圾收集唯一发包: `Remotes.CollectPaper` (RemoteEvent)。由 `PlayerScripts.LocalNPCManager` 的 `throwPaperToTrash` 在扔进垃圾桶时调用。
- 垃圾袋兑现: `Remotes.CollectTrashBag:FireServer(money, gum)` (RemoteEvent), 出现在风扇撕碎/兑现路径 `u17.CashOutTrashBag`。
- 升级/购买类全部是 RemoteFunction (`Purchase*` / `Get*`), 自动清扫不碰。

## Remote 清单

| 名 | 路径 | 类型 | 参数 | 触发 | 校验备注 |
|---|---|---|---|---|---|
| CollectPaper | ReplicatedStorage.Remotes.CollectPaper | RemoteEvent | 可选 source 字符串, 普通纸为 nil | throwPaperToTrash / 自动纸/粪入桶 | 裸 FireServer() 与地上实例脱钩, 2s 金钱增速相对基线无增益 (未验证为服务端拒绝还是被噪声淹没) |
| CollectTrashBag | ReplicatedStorage.Remotes.CollectTrashBag | RemoteEvent | (money:number, gum:number) | 垃圾袋进风扇兑现 | CashOutTrashBag 读取 StoredMoney/StoredGum 后 FireServer 并 Destroy |
| PurchaseNPC / GetNPCCount 等 | Remotes/* | RemoteFunction | 商店 | UI 购买 | 未试探 |
| GetSkillUpgrades | ReplicatedStorage.Remotes.GetSkillUpgrades | RemoteFunction | 无参 | 打开技能树 / 自动升级轮询 | 返回 costs/currencies/purchased/gum/money/robuxPoints/rebirthPoints |
| PurchaseSkillUpgrade | ReplicatedStorage.Remotes.PurchaseSkillUpgrade | RemoteFunction | upgradeName:string | 点技能按钮 / 自动升级 | 成功 `{success=true, gum, purchased, costs...}`; 满级 `{success=false, reason="Max upgrade level"}` |
| PurchaseNPC | Remotes.PurchaseNPC | RemoteFunction | 无参 | 污染-People | 满员 `{success=false, reason="Max NPCs", count=25}`; 上限硬编码 25 |
| GetNPCCount | Remotes.GetNPCCount | RemoteFunction | 无参 | 查询小人数量 | 返回 number 不是表 |
| PurchaseHorse / PurchaseUnicorn 等 | Remotes.Purchase* | RemoteFunction | 无参 | 污染/建造卡片 | 成功带 count/cost/maxCount/money; 马+独角兽共用 totalCount |
| PurchasePaperUpgrade 等 | Remotes.Purchase*Upgrade | RemoteFunction | 无参 | 升级列表 | 满级例: `{success=false, reason="Max paper level", level, maxLevel}` |
| PurchaseGum | Remotes.PurchaseGum | RemoteFunction | 无参 | 污染-Gum 金钱换口香糖 | 无数量上限, hub 自动买不碰 |

## NPC / 地点坐标

<!-- 名称 | CFrame 或模型路径 -->

## 关键机制结论

## [2026-09-01 | pv761 | clean-the-world@0.2.0]
- 地上垃圾实例在 `Workspace.DropArea` (实测 Paper/Poop 均挂这里; Banana/Egg 需 `TrashReady==true` 才允许收集)。
- 玩家清扫 = `collectPapersNearMouse`: `Mouse.Move` + `RenderStepped` 每帧跑。条件: 有空垃圾桶、技能 UI 未开、距离 `MouseTrashCollectionRadius` 中心 <= `u4` (pv761 实测 u4=4.125)。命中后 `task.spawn(throwPaperToTrash, child)`。
- `throwPaperToTrash(part, isRat?, delayFrac?)`: 选随机空桶; Poop/Banana 无 TrashReady 则 return; 已在途 (`u13`) 则 return; 按属性拼 source (`Thundergum*` / `Rat*` / `GoldenPaper` / `Poop` / `Banana` / `Egg` / 普通纸 nil) 后 `CollectPaper:FireServer(source)`; 再弧线飞向垃圾桶。无参调用时 delay 视为立刻 `finishThrow` (内部 arc 仍 yield ~0.55s)。
- 取出该函数: `getconnections(RenderStepped)` 里 source 含 `LocalNPCManager` 的回调, `debug.getupvalue(cb, 2)` = collectPapersNearMouse, `getupvalue(collect, 8)` = throwPaperToTrash, `getupvalue(collect, 5)` = DropArea。Potassium 的 getupvalue 越界抛错, 必须 pcall。
- 直接对距鼠标 130 stud 的 Paper 调 throwPaperToTrash: 实例 Parent 变 nil (视觉销毁成功)。不限鼠标圈, 但仍依赖空垃圾桶 (`getAvailableTrashCans` 为空则直接 return, 不销毁)。
- `LocalPlayer.TrashAnimationEnabled == false` 时 throw 在 FireServer 后 Destroy+addTrashToCan 并立刻 return, 不走 0.55s `arcPaperToCFrame`。自动清扫每轮临时关掉该属性及 PickupSound/CurrencyPopup, 轮末 SetAttribute 还原, 不写 SavePlayerSetting。
- throw 的 uv1=`getAvailableTrashCans`, uv4=在途表 `u13`; 桶满时 `#cans==0` 本轮不发包。
- 游戏另有技能向自动入桶 `depositAutoPaperIntoTrashCan` / `DepositAutoPoopIntoTrashCan` (IsAutoPaperEnabled / IsAutoPoopEnabled), 与鼠标清扫独立; hub 自动清扫不走这条, 避免和技能叠发语义不清。
- 老鼠 NPC (`spawnRat`) 走近松散纸也会调 `throwPaperToTrash(paper, true, ...)`, source 变成 `Rat` / `RatGoldenPaper`。

## [2026-09-01 | pv761 | clean-the-world@0.3.0]
- 口香糖技能 UI: `PlayerGui.Skill.Frame.Upgrade` 下 TextButton, Name=技能 id; Robux 树在 `Skill.Robux.Upgrade`, Currency=Robux, 自动升级不碰。
- 跳过 `PRESTIGE`、`Coming_Soon`。前置: 按钮子级 ObjectValue `Required` 指向另一技能按钮, 需 `purchased[name] > 0`。
- 价格以 `GetSkillUpgrades.costs` 为准, 不要盲信 UI 上的 Cost NumberValue。
- 实测 `The_World_Egg` 从 2→3: Invoke 成功, gum 424785→379244 (扣 45541, 与当时 cost 45563 接近, 以服务端 gum 为准)。满级 `Double_Throw` 返回 success=false, reason=`Max upgrade level`。

## [2026-09-01 | pv761 | clean-the-world@0.4.0]
- 商店 UI: `PlayerGui.Main.Sidebar` 的 `Pollution` / `Upgrades` / `Build` ScrollingFrame; 每张卡是 Frame, 名即商品键; `ImageButton.Cap` 为 `当前/上限` 或口香糖紧凑数字; `Cost` 为价格或 `MAX`。
- 污染卡: People, Gum, Horse, Unicorn, Gorilla, DINOSAUR。升级卡: Paper, Poop, Banana, Egg。建造卡: Rat, Thundergum, Seagull, Seaweed; `Info` 不是商品。
- 购买全部无参 `Purchase*:InvokeServer()`, 客户端 `LocalNPCManager` 点卡走同一条。金钱在 `Player.PrivateStats.Money`。
- 马/独角兽共享 `maxCount` (GetHorseCount.totalCount); 满共享上限时 Horse.count 仍可能为 0, 不能只看 horseCount。
- 未解锁项 `unlocked=false` 且 Visible=false (如 Seagull/Seaweed); 新商品以列表新增 Frame 为准。
- Gum 是金钱换口香糖、无 cap, 自动污染不买, 避免把钱兑光。
- 小人下一档价格客户端公式: `ceil(1.25^(clamp(count,1,25)-1)*5)`。

## [2026-09-01 | pv761 | clean-the-world@0.5.2]
- `GetSkillUpgrades` 单次 Invoke 常 5s+, 不能当心跳轮询; 应用返回表缓存, 买成功用 Purchase 回包更新, 无可买时 idle, 口香糖明显增加再 Get。
- 商店卡 UI `Cost=MAX` 或 Cap 已满时不必再 Get; 全列表满可拉长轮询间隔。

## [2026-09-01 | pv761 | clean-the-world@0.5.0]
- 大海通道: `Workspace.GarbagePart` (约 121 stud 长)。满桶经 `shakeAndResetTrashCan` (摇 4s) 调 `throwFullTrashBag`, 克隆 TrashBag 到 Workspace, 飞向 GarbagePart, 碰到风扇 `CaptureTrashBagAtFan` 后再 `CashOutTrashBag`。
- 兑现: `u17.CashOutTrashBag(bag)` → `CollectTrashBag:FireServer(StoredMoney, StoredGum)` 后 Destroy。已 `CashedOutAtFan` 则跳过。
- `throw` uv5 = LocalNPCManager 的 `u17`; `getAvailableTrashCans` uv1 = 桶状态表 (count/storedMoney/storedGum/resetting/model); `addTrash` uv3=`updateTrashCanFill` → uv4=`shakeAndResetTrashCan` → uv6=`throwFullTrashBag` / uv7=`resetTrashCanVisuals`。
- 自动大海清洗跳过 4s 摇桶: 直接 throwFull + 对新袋 CashOut + 把桶 count/money/gum 清零。**(hub v0.5.1 已撤回该功能, 结论保留备查)**

## L2 手段登记 (危险功能对抗手段台账)

<!-- 每条: [日期 | pv<N> | 功能名]
- 手段: hook 抢发包/模拟输入/...
- 目标: 函数或 remote 路径
- 验证: 小号实测时长 + 无 kick/回滚/弹窗
- 信号特征: 出问题时服务器如何反应 (供封禁预警)
-->

## 可复用代码片段

## [2026-09-01 | pv761 | clean-the-world@0.2.0]
- 收集函数绑定: RenderStepped → LocalNPCManager 回调 uv2=collectNearMouse, 其 uv8=throwPaperToTrash。调用必须 `task.spawn(throw, part)`, 禁止在 StartLoop 里同步等 arc。

## 待复核 (placeVersion 变更后移入)

## 已证伪
