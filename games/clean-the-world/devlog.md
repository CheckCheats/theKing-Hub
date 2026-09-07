# Clean the WORLD! TheKing HUB — 开发手册 (DevLog)

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

## [2026-09-01 | 会话9 | v0.5.3 | lib 1.8.0] 接入引擎循环退避

### 目标
清洁世界用上 lib 1.8.0 的 Backoff/FindRemote/BindToggle, 去掉游戏内闲置表。

### 改动明细
| 文件 | 位置 | 改动 |
|---|---|---|
| lib/theking.luau | 1.8.0 | 见 lib/devlog |
| hub.luau | waitRemote/findRemote/runShopBuys/技能循环 | WaitChild/FindRemote/Backoff; 花钱 BindToggle |

### 决策记录
- 口香糖涨了靠 StartLoop wakeIf 叫醒技能循环。

### 验证
- 静态: 无 shopIdleUntil / skillState.idleUntil。

### 遗留问题 / 下一步
- [ ] 游戏内热替换后开技能/花钱, 确认慢循环告警去抖且功能仍买

## [2026-09-01 | 会话8 | v0.5.2 | lib 1.7.4] 技能/花钱循环退避

### 目标
优化已有循环, 去掉 GetSkillUpgrades 每 0.6s 同步卡 5s+ 的慢循环, 商店全满不再空转 Get。

### 改动明细 (函数级定位)
| 文件 | 位置 | 改动 |
|---|---|---|
| hub.luau | skillState / autoSkillUpgrade | 缓存 Get 返回表; Purchase 成功用 res 更新缓存; 无可买 idle 10s; findRemote 热路径; 每轮最多买 1 |
| hub.luau | shopIdleUntil / runShopBuys | UI MAX/cap 满跳过 Get; pending==0 idle 12s; 买不起 idle 6s; 买成功清 idle |
| hub.luau | bindShopToggle | 循环间隔 0.75→1.2; 开启时清 idle |

### 决策记录
- PATCH 不改功能面, 只改轮询策略。GetSkillUpgrades 实测常 5s+, 不能当心跳。口香糖明显增加才强制刷新缓存。

### 验证
- 静态: shopIdleUntil 在 runShopBuys 前声明; 热路径无 waitRemote(GetSkillUpgrades)。

### 遗留问题 / 下一步
- [ ] 游戏内开技能/花钱开关, 确认控制台不再刷慢循环告警
- [ ] 建议 2-6 未做 (传送/藏小人/限量兑胶/声望/只收袋)

## [2026-09-01 | 会话7 | v0.5.1 | lib 1.7.4] 撤回大海垃圾清洗

### 目标
用户反馈该功能没用, 从主功能去掉。

### 改动明细
| 文件 | 位置 | 改动 |
|---|---|---|
| hub.luau | autoSeaClean / dumpFullCans 等 | 删除 Toggle 与倒袋兑现逻辑; 顺手修回退时 SKILL_SKIP 重复声明 |
| changelog.md | v0.5.1 | Removed |

### 决策记录
- 协议结论留在 intel, 功能不再进 UI。

### 验证
- 静态: hub 不再引用 sweepSeaTrash / autoSeaClean。

### 遗留
- 无

## [2026-09-01 | 会话6 | v0.5.0 | lib 1.7.4] 大海垃圾清洗

### 目标
主功能增加大海清洗: 快速把垃圾袋推进风扇清理器兑现。

### 改动明细
| 文件 | 位置 | 改动 |
|---|---|---|
| hub.luau | bindThrowHelpers | 绑定 u17 / throwFullTrashBag / resetTrashCanVisuals / 桶表 |
| hub.luau | dumpFullCans / cashSeaBag / sweepSeaTrash | 跳过摇桶, 倒袋后立刻 CashOutTrashBag |
| hub.luau | autoSeaClean | 主功能 Toggle, 0.12s 循环 |

### 决策记录
- 走游戏 CashOutTrashBag 发包, 不裸编造金额。
- 不调 shakeAndResetTrashCan (内含 4s Heartbeat 摇晃)。
- 倒袋成功才清零桶 count/money, 避免失败后吞数据。

### 验证
- u17.CashOutTrashBag / CaptureTrashBagAtFan 存在; 场上 Thrown Trash Bag 带 StoredMoney。
- 桶表 5 个均有 count/storedMoney。未在本轮对用户号试兑现。

### 遗留
- [ ] 实机开开关确认扣桶、加钱、无双发。

## [2026-09-01 | 会话5 | v0.4.1 | lib 1.7.4] 自动清扫走无动画快路径

### 目标
自动清扫更高效: 去掉入桶弧线等待, 新垃圾尽快入桶。

### 改动明细 (函数级定位)
| 文件 | 位置 | 改动 |
|---|---|---|
| hub.luau | withFastThrow / throwOne / sweepBatch | 当轮 SetAttribute 关动画/音效/飘字, 同步调用 throw, 轮末还原 |
| hub.luau | startSweepWatch | DropArea.ChildAdded 立刻扔; StopAll 后靠 lastSweepPulse 0.35s 失效 |
| hub.luau | bindThrowHelpers | throw uv1 空桶查询, uv4 在途表, 满桶停 |
| hub.luau | autoSweep | 间隔 0.08 无抖动, 滑条默认 16 上限 40 |

### 决策记录
- 仍走 throwPaperToTrash+CollectPaper, 不改裸 FireServer。
- 不永久改玩家设置, 不调 SavePlayerSetting。
- 关动画后 throw 无 yield, 禁止再 task.spawn, 避免多协程抢同一空桶计数。

### 验证
- 反编译确认 TrashAnimationEnabled==false 早退。throw uv 下标实测 uv1 函数 / uv4 表。
- 本轮未注入跑 hub。

### 遗留问题 / 下一步
- [ ] 实机开自动清扫看地上堆积是否明显变快。
- [ ] 技能树 Invoke 仍慢。

## [2026-09-01 | 会话4 | v0.4.0 | lib 1.7.4] 花钱 Tab 自动买污染/升级/建造

### 目标
按侧栏三份商店列表自动花钱: 未满且买得起就买, 满值不买, 新卡出现后纳入下一轮。

### 改动明细 (函数级定位)
| 文件 | 位置 | 改动 |
|---|---|---|
| hub.luau | runShopBuys / bindShopToggle | 扫 Sidebar.Pollution/Upgrades/Build; Cost=MAX 或 cap 已满则不发包; 否则 Get 再 Purchase |
| hub.luau | SHOP_ALIAS / SHOP_SKIP | People→PurchaseNPC; DINOSAUR→PurchaseDinosaur; 跳过 Gum/Info |
| intel.md | Remote + 机制 | 回写无参购买、Max NPCs、马独角兽共享上限 |

### 决策记录
- 以 UI 列表为源, 未知 Frame 名猜测 Purchase/Get, 方便以后新污染不用改表。
- Gum 无上限、是兑口香糖, 自动买会把钱兑光, 明确跳过。
- 马看 totalCount 不是 horseCount。
- 钱读 PrivateStats.Money, 不每轮 Invoke GetSkillUpgrades。
- 满级试探: PurchaseNPC reason=Max NPCs; PurchasePaperUpgrade reason=Max paper level。

### 验证
- Get* 全表已拉; 满级购买返回已确认。
- 当前号污染/升级/建造几乎全满, 自动买应静默跳过; Seaweed/Seagull 未解锁且 Visible=false, 等出现再买。
- hub 未在本轮注入执行。

### 遗留问题 / 下一步
- [ ] 有未满商品时需实机开开关确认扣钱。
- [ ] CollectTrashBag 仍未做。
- [ ] 技能树循环仍偶发超 2s, 与 Invoke 延迟有关, 未在本轮治。

## [2026-09-01 | 会话3 | v0.3.0 | lib 1.7.4] 技能树自动升级 + 主功能排版

### 目标
接上次技能逆向: 试买结果已确认, 落地技能 Tab 与主功能改版。

### 改动明细 (函数级定位)
| 文件 | 位置 | 改动 |
|---|---|---|
| hub.luau | 主功能 Tab | 删 Paragraph 清扫状态与 UpdateStatus; Toggle 自动清扫置顶, Slider 在后 |
| hub.luau | waitRemote / skillReqMet / gumSkillFolder | 新增技能查询与前置判断 |
| hub.luau | SkillTab autoSkillUpgrade | StartLoop 0.6s: GetSkillUpgrades → 过滤 Robux/PRESTIGE/Coming_Soon → 便宜优先, 每轮最多 4 次 PurchaseSkillUpgrade |
| intel.md / changelog.md | 技能协议 | 回写试买结论 |

### 决策记录
- 价格走 GetSkillUpgrades.costs, 不信 UI Cost。
- 只扫 Frame.Upgrade, 不碰 Robux 树。
- 循环内 gumSkillFolder 禁止 WaitForChild, 避免缺 GUI 时长阻塞; 开开关时等一次 10s。
- 满级服务端会 success=false, 下一轮 Get 后 cost/购买态会自然排除或仍失败则跳过。

### 验证
- Invoke The_World_Egg: success=true, 等级 2→3, gum 扣减。
- 满级 Double_Throw: success=false, reason=Max upgrade level。
- hub 本体未在本轮 execute (用户未要求注入)。

### 遗留问题 / 下一步
- [ ] 其它失败 reason (钱不够/前置未点) 未穷举, 靠客户端过滤减发包。
- [ ] CollectTrashBag 风扇兑现仍未做。

## [2026-09-01 | 会话2 | v0.2.1 | lib 1.7.4] 清注入垃圾 + 去掉传送 Tab

### 目标
清掉注入过程留下的临时文件, 并按用户要求删掉空传送页。

### 改动明细
| 文件 | 位置 | 改动 |
|---|---|---|
| games/clean-the-world/hub.luau | TeleportTab | 删除空传送 Tab; 版本 0.2.1 |
| games/clean-the-world/.inj-* .inject-* _mk_inj_chunks.py | 删除 | 注入分段载荷 |
| games/sniper-arena/.inj-* .inject-* inject-now.lua _inject-* _console-* _parse_console.py | 删除 | 同类注入垃圾 |

### 决策记录
- 引擎工具 `tools/gen-inject-*.py` 保留, 那是生成器不是产物。
- 去掉传送是 PATCH: 骨架占位页, 没有实际传送逻辑。

### 验证
- glob 确认 clean-the-world 只剩 hub/intel/devlog/changelog。

### 遗留问题 / 下一步
- [ ] 注入仍需走内嵌载荷 (客户端读不到仓库路径)

---

## [2026-09-01 | 会话2 | v0.2.0 | lib 1.7.4] 自动清扫 (throwPaperToTrash)

### 目标
分析清扫协议并实现自动清扫, 走游戏自身扔桶函数而不是裸发包。

### 改动明细
| 文件 | 位置 | 改动 |
|---|---|---|
| games/clean-the-world/hub.luau | 全文件 | v0.2.0: 绑定 LocalNPCManager 收集函数, StartLoop 每 0.2s spawn throw |
| games/clean-the-world/intel.md | 协议/机制 | 回写 CollectPaper / 鼠标圈 / upvalue 布局 |
| games/clean-the-world/changelog.md | 顶部 | v0.2.0 |

### 决策记录
- 裸 `CollectPaper:FireServer()` 与 2s 基线金钱增速比无可见增益, 不用作主路径。
- 不 hook、不改鼠标圈: 直接调游戏 `throwPaperToTrash` (与鼠标命中同一条包)。圈外 130 stud 实测实例被销毁。
- 每轮 cap + task.spawn: throw 内部 arc 会 yield 0.55s, 同步调用会卡住循环。
- 垃圾袋/风扇兑现未做 (CollectTrashBag), 桶满时 throw 会静默失败。

### 验证
- Potassium pid=18552, pv761。对最远 Paper 调 throwPaperToTrash, Parent 变 nil。
- 同逻辑试跑 12×0.2s、每轮 6 件: DropArea 可收集物 172→150 (期间 NPC 仍在扔纸, 净减少说明扫得动)。
- 完整 hub UI 需用户在注入器里重跑 `games/clean-the-world/hub.luau`。

### 遗留问题 / 下一步
- [ ] 桶满后自动把垃圾袋送去风扇 (CollectTrashBag)
- [ ] Area2 / 海里垃圾若以后不进 DropArea, 要扩扫描根
- [ ] 发布前 profile-frames

---

## [2026-09-01 | 会话1 | v0.1.0 | lib -] 新游戏建档

### 目标
启动协议未命中已有 universeId, 为当前客户端游戏建档并生成骨架 hub。

### 改动明细
| 文件 | 位置 | 改动 |
|---|---|---|
| games/clean-the-world/intel.md | 全文件 | 新建: front matter 填 pv761 元数据 |
| games/clean-the-world/devlog.md | 全文件 | 新建 |
| games/clean-the-world/changelog.md | 全文件 | 新建 v0.1.0 |
| games/clean-the-world/hub.luau | 全文件 | 从 hub-skeleton.luau 复制, GameName 同步 intel `game:` |

### 决策记录
- 目录名 `clean-the-world` (官方英文短名 kebab-case)。
- `game:` / hub `GameName` 用官方英文 `Clean the WORLD!` (热替换键/配置目录/档案键三处一致); 中文本地化名只记在 intel 元数据, 不进 GameName。
- 本会话只建档, 未做逆向, intel 协议区为空。

### 验证
- Potassium 客户端 pid=18552 执行读元数据: placeId=105767799784652, universeId=10494847029, placeVersion=761。
- 与现有 games/* intel 的 universeId 全表比对无命中。

### 遗留问题 / 下一步
- [ ] 用户确认需求后再走 playbook 探索 (协议/remote/清扫循环)
- [ ] 功能候选需探索后给出, 当前无已验证结论

---

## 踩坑黑名单 (跨会话累积, 只增不删)

> 格式: `[错误模式] → [后果] → [正确做法]` — 开工先扫一遍, 已知坑零二次。

- [裸 CollectPaper:FireServer() 当自动清扫] → [金钱增速与 NPC 基线无差, 地上纸不消失] → [调 LocalNPCManager.throwPaperToTrash, 并 task.spawn]
- [debug.getupvalue 越界当返回 nil] → [Potassium 直接报 index out of range] → [pcall 包裹, 用 decompile 确认的固定下标]
- [StartLoop 里同步调用 throwPaperToTrash] → [arc 0.55s yield 拖死循环] → [与游戏一样 task.spawn]
- [每 0.6s Invoke GetSkillUpgrades] → [单次 5s+ 触发慢循环告警, 技能全满时空转] → [缓存快照 + 无可买 idle ~10s; 热路径 findRemote 禁止 WaitForChild]
