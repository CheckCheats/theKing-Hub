# Cultivation: Evermortal TheKing HUB — 开发手册 (DevLog)

> 维护铁律: **每次开发会话收工前必须追加一条**, 写给下一个接手的 AI 和未来的自己。
> 与 changelog.md 分工: changelog 面向用户记"发布了什么"; 本文件面向开发者记"怎么做的、为什么、验证结果、遗留问题"。
> 接手 AI 使用法: 只读本文件最后一条 + intel.md 相关分区, 即可恢复全部上下文, 禁止凭空猜测前人意图。

---

## [2026-09-07 | 会话3 | v0.3.0 | lib v2.5.4] 突破/磨练/技巧/天赋

### 目标
自动克服困难、磨练肉体、升级全部可负担技巧、滚动天赋、装备最稀有。

### 改动明细 (函数级定位)
| 文件 | 位置 | 改动 |
|---|---|---|
| hub.luau | Ui/Auto Pack | tickBreak/Flesh/Tech/Roll/Equip; 按钮 Fire 不切页 |
| intel.md | 机制+Remote | Orb/Refine/BuyOne/Roll/Equip |

### 决策记录 (为什么这么改)
- 不 Invoke Knit: 参数未拆; Fire 游戏自己的 Click 连接
- 不抢 Nav: 技巧/天赋按钮 Hidden 也能 Fire, 和坐忘并存
- 磨练只在 Refine.Visible: 凝气阶段钮是藏的, 硬点会乱
- 抽天赋只用 Roll, 不用 JadeRoll (花玉)
- 装备两拍: 先 Hit 选中, 下轮 Equip; WORN 且名字对上则停

### 验证
- 钾: ProgressLabel ready、Orb/Refine 连接、BuyOne CULTIVATE、Roll/Owned.Hit/Equip WORN
- `python tools/check_hub.py`
- 局内五开关 **待热替换确认**

### 遗留问题 / 下一步
- [ ] 气不够时突破是否仍点 Orb (ready 误判)
- [ ] 稀有度词表若出新档 (mythic 以外) 要补

---

## [2026-09-07 | 会话2 | v0.2.0 | lib v2.5.4] 自动冥想

### 目标
Tab「自动」+ 自动进入坐忘, 指针到金色芯时点左键。

### 改动明细 (函数级定位)
| 文件 | 位置 | 改动 |
|---|---|---|
| hub.luau | Med Pack | ensurePage/ensureOpen/tapGold; BindToggle + BindStepped QTE |
| intel.md | 关键机制 | 坐忘 UI / 绿区金芯 / Hit.Down |

### 决策记录 (为什么这么改)
- 不 Invoke RF.Meditate: 参数未知, 走游戏自己的按钮和 tap
- QTE 用心跳: StartLoop 50ms 跟不住指针
- 金芯而非整段绿区: 与 Hint「gold heart pays double」和用户「黄色」一致
- 开开关后 0.8s 再点, 避免点在 Rayfield Toggle 上

### 验证
- 钾: AscensionUI.Meditate 树 + Nav.Cultivate + Hit 连接到 MeditateGame.tap
- `python tools/check_hub.py games/cultivation-evermortal/hub.luau`
- 局内开开关走一轮坐忘 **待用户热替换确认**

### 遗留问题 / 下一步
- [ ] 热替换后看能否自动进界面、金芯命中是否稳定
- [ ] RF.Meditate 参数仍未知

---

## [2026-09-07 | 会话1 | v0.1.0 | lib v2.5.4] 建档

### 目标
钾客户端当前游戏无档案, 从模板建档并生成骨架 hub。

### 改动明细 (函数级定位)
| 文件 | 位置 | 改动 |
|---|---|---|
| intel.md | 全文 | 新建; GameName `Cultivation: Evermortal`; pv1118; universeId 10667860714 |
| hub.luau | 骨架 | 自 hub-skeleton.luau 复制, 仅填名与目录 |
| changelog.md / devlog.md | 全文 | 自模板生成 |

### 决策记录 (为什么这么改)
- 目录 `cultivation-evermortal`: 官方英文页 `Cultivation: Evermortal`, 中文店名「修炼：永恒不朽」带活动前缀不进 GameName
- genre `cultivation`: 聚气/突破/飞升闲置修仙, 与现有 fishing/dungeon/rng/simulator 都不重合; 同类尚无第 2 个游戏, 模式库只建空壳

### 验证
- `python tools/inspect.py probe gameinfo` + 钾 execute: placeId=96179204081384, universeId=10667860714, placeVersion=1118
- `python tools/recall.py 10667860714`: 无旧档案
- `python tools/check_hub.py games/cultivation-evermortal/hub.luau`

### 遗留问题 / 下一步
- [ ] 用户点功能后再 `inspect.py howto` + recipe, 禁止从零 getgc
- [ ] 商店页玩法未在局内验证

---

## 踩坑黑名单 (跨会话累积, 只增不删)

> 格式: `[错误模式] → [后果] → [正确做法]` — 开工先扫一遍, 已知坑零二次。

- [用 Verdict COMPLETE 当本局已结束] → [面板关着时文案仍残留, 会误判永远结束] → [只认 Meditate.Visible; 指针进金芯边沿点一次]
- [QTE 点 Hit.MouseButton1Click] → [游戏只挂 Down→MeditateGame.tap] → [Fire MouseButton1Down + 左键]
- [用 Cultivate.Qi 当钱包买技巧] → [那是突破条附近的小数, 和 QiChip 差几个数量级] → [技巧花费对照 Techniques.QiChip.Value]
