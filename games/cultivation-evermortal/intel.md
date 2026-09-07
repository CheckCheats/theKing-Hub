---
genre: cultivation
game: "Cultivation: Evermortal"
placeId: 96179204081384
universeId: 10667860714
placeVersion: 1118
created: 2026-09-07
updated: 2026-09-07
script: "games/cultivation-evermortal/hub.luau"
status: active
---

# 游戏情报档案 — Cultivation: Evermortal

> **AI 铁律**:
> 1. 会话开始必须先读本文件 + 召回, 禁止对已有结论重新逆向。
> 2. 开发中新发现写回本文件; 钾无 remember-game。
> 3. 每条结论带条目头: `[日期 | pv<placeVersion> | 来源]`。
> 4. placeVersion 变更 → 受影响条目移「待复核」。
> 5. 证伪 →「已证伪」保留原文+原因。

## 建档元数据

- 官方名: Cultivation: Evermortal
- 商店页标题常带活动前缀 (例: `[🔥2倍运气] 修炼：永恒不朽 `); **档案 / hub `GameName` 固定 `Cultivation: Evermortal`**
- 客户端 DataModel.Name: `Ugc`
- 制作组: Miki and Miffy Games (Group, creatorId `429377976`)
- 目录: `games/cultivation-evermortal/`
- 建档时 JobId: `cddd4573-79b5-431a-96f2-392f3989e08d`
- 玩法粗描 (商店页, **未逆向验证**): 自动聚气 / 打坐加速; 气满点 BREAKTHROUGH 突破; 用气学功法提高聚气速率; 抽天赋与灵根; 入宗门打长老; 本世到顶后飞升, 下世更强; 离线也继续修炼

## 协议与通信

## [2026-09-07 | pv1118 | 建档+自动冥想]
- 通信走 Knit: `ReplicatedStorage.Packages.Knit.Services.CultivationService` (RF 一堆 + RE 状态/结果)。
- 自动冥想 **不 Invoke** `RF.Meditate` (参数未验证); 走游戏按钮与 QTE 输入。

## Remote 清单

| 名 | 路径 | 类型 | 参数 | 触发 | 校验备注 |
|---|---|---|---|---|---|
| Meditate | CultivationService.RF.Meditate | RemoteFunction | 未验证 | 坐忘开局/结算? | 未试探, hub 不直调 |
| MeditateResult | CultivationService.RE.MeditateResult | RemoteEvent | 未验证 | 服务端回坐忘结果 | 只登记 |
| Breakthrough / BreakthroughMax | CultivationService.RF | RemoteFunction | 未验证 | 法修突破 | hub 点 Orb/Tribulation, 不直调 |
| RefineFlesh / RefineFleshMax | CultivationService.RF | RemoteFunction | 未验证 | 磨练肉身 | hub 点 Refine, 钮 Hidden 时不点 |
| BuyTechnique | CultivationService.RF | RemoteFunction | 未验证 | 技巧 CULTIVATE | hub 点 Grid.BuyOne |
| RollTalent / EquipTalent | CultivationService.RF | RemoteFunction | 未验证 | 抽/装备天赋 | hub 点 Roll / Owned.Hit+Detail.Equip |

## NPC / 地点坐标

## 关键机制结论

## [2026-09-07 | pv1118 | hub v0.2.0]
- 主 UI: `PlayerGui.AscensionUI`。修炼页 `Root.Content.Cultivate` (默认可能关着, 当前页在 Talents 等)。
- 切页: `Root.Nav.Cultivate` TextButton `CULTIVATE`, MouseButton1Click → `PlayerScripts.Cultivation.UI`。
- 进坐忘: `Root.Content.Cultivate.Actions.Meditate` 文案 `MEDITATE`, MouseButton1Click → 同上 UI。
- QTE 层: `AscensionUI.Meditate` (Visible=开局)。标题「坐忘 SEATED FORGETTING」。Hint: Stop the needle in the green — the gold heart pays double。
- 条: `Meditate.Track.Groove`; **绿区** `Zone` (约 0.52,0.94,0.67); **金芯** `Zone.Core` (约 1,0.85,0.54) — 用户说的「黄色」即此芯, 双倍。指针 `Groove.Needle` 用 Position.X.Scale 扫条。
- 点击面: 全屏 `Meditate.Hit`; **MouseButton1Down** → `PlayerScripts.Cultivation.MeditateGame.tap` (不是 Click)。
- 一轮约 5 breath (`Beat`=`breath 5 of 5`); 结束 Verdict「收功 COMPLETE」。面板关后再点 MEDITATE。
- L1: 切页/进门点按钮; 金芯重叠时 Fire Hit.Down + 芯中心左键。不 hook、不伪造 RF。 (候选提升: cultivation)

## [2026-09-07 | pv1118 | hub v0.3.0]
- 气条: `Cultivate.ProgressLabel` 含 `ready` 或 当前≥需求 即够突破; `Cultivate.Qi` 是突破条附近数字, **钱包**以 `Techniques.QiChip.Value` 为准 (例 59.26B vs 页上 1.88K)。
- 克服困难: `BreakCluster.Orb` (BREAKTHROUGH, 常显) / `Tribulation` (渡劫时 vis) / `Actions.Breakthrough` (常 hidden)。Click → Cultivation.UI。
- 磨练肉体: `BreakCluster.Refine` Caption `REFINE FLESH • x/9`, vis 才点; Cost 如 `71.0 Qi`。
- 技巧: `Content.Techniques.Grid.<id>.BuyOne` 文案 CULTIVATE; PERFECTED / TRANSCRIBE(Jade) 跳过。Click → UI。
- 天赋: `Talents.Roll` = ROLL TALENT (普通抽); `JadeRoll`=HEAVENLY 不用; `Owned.<id>.Hit` 选中; `Detail.Equip` Caption `WORN`=已穿。稀有度 COMMON<UNCOMMON<RARE<EPIC<… 写在卡片 Rarity。
- 以上发包均 Fire 按钮连接, 不切页, 可与坐忘同开。 (候选提升: cultivation)

## L2 手段登记 (危险功能对抗手段台账)

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
