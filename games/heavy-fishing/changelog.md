# 版本历史 — 重型钓鱼

格式:
```
## vX.Y.Z — YYYY-MM-DD
- 变更点 (类型: feat/fix/refactor)
```

---

---
---
## v1.2.8 — 2026-09-03
- fix: 二阶段只在指针位于绿条内发包, 去掉绿区外 0.7s 保底
  PATCH → v1.2.7→v1.2.8

## v1.2.7 — 2026-09-03
- fix: 二阶段完全不打 — 绿心过严+反应窗未到条已离开; 改为进区立刻发包, 条可见也驱动, 0.7s 无命中保底, 实时重找 Bar/Hitbox
  PATCH → v1.2.6→v1.2.7

## v1.2.6 — 2026-09-03
- enhance: 恩佐手感 — 快条改游戏同款 +0.1/0.05s Linear 连点, 不再 0.03s 钉死; 二阶段条刚进绿心再打(一趟一次)+命中晃动+稍后再换框, 仍不点鼠标防扣血
  PATCH → v1.2.5→v1.2.6

## v1.2.5 — 2026-09-03
- fix: 恩佐二阶段降暴力 — 不再 0.14s 无脑发包; 画面进绿心后反应 0.18~0.4s 再发命中, 两次间隔约 0.5~0.85s; 仍不点鼠标, 避免三角波扣血
  PATCH → v1.2.4→v1.2.5

## v1.2.4 — 2026-09-03
- fix: 恩佐快条掉红 — 不再用人手感延迟点鼠标, RenderStepped 短 tween 把条钉在绿心; 普通鱼仍走点条
- fix: 恩佐二阶段点错扣血 — 实机确认 onClick 用内部三角波, 画面绿心≠命中; 取消真点击, 只发 Hit=true+Index
  PATCH → v1.2.3→v1.2.4

## v1.2.3 — 2026-09-03
- fix: 热路径减负 — 奔跑/加速关着不跑 Heartbeat; 恩佐检测缓存 NPC/配置不再每拍扫树; 钓鱼循环与恩佐检测合并; 控条缓存 Bar; 点条安全坐标缓存 2s; 假称号保活 0.25s→2s; 恩佐 Phase2 只在属性为真时挂 RenderStepped
- refactor: getRodPower 拆成 getRodBuffPower / getEquippedRodBasePower; 去掉已废弃的 bossRhythm StartLoop
  PATCH → v1.2.2→v1.2.3

## v1.2.2 — 2026-09-03
- fix: 节奏改按 ASD 走游戏 TryHit — 实机反编译确认直接 RhythmHit 不删内部音符表, 过线后游戏会补 miss 扣血; 过线再按对应键才有 EXP 闪光。控条点击仍走 MouseButton1(+0.1/0.05s); 恩佐二阶段晃动确认在 onClick 命中分支
  PATCH → v1.2.1→v1.2.2

## v1.2.1 — 2026-09-03
- fix: 章鱼/无名章寄二阶段节奏 — 过判定线才打击 (不再提前点); Heartbeat 驱动去掉 50ms 抖动; 音符/判定线按锚点取中心。恩佐 FinalPhase 同一套
  PATCH → v1.2.0→v1.2.1

## v1.2.0 — 2026-09-03
- enhance: 顶部控鱼条改真人点按 — 不再 0 时长钉死位置; 条在绿区下落到随机阈值再点(游戏自身 +0.1/0.05s 回弹), 反应延迟随紧迫度变化; 点不中再短 tween 保命不出界
- fix: 恩佐二阶段改走游戏 onClick — 点绿心发真鼠标(落点避开顶部 GUI), 命中晃动/换绿框/发包由游戏自己做; 点被吞才兜底发包。RenderStepped 驱动
  MINOR → v1.1.3→v1.2.0

## v1.1.3 — 2026-09-03
- enhance: 界面收紧 — 名字已经能看懂的功能去掉简介行, 只留状态、副作用和容易踩坑的说明
  PATCH → v1.1.2→v1.1.3

## v1.1.2 — 2026-09-03
- fix: 界面不再强行锁视角 — Rayfield 抢鼠标导致 Shift 关不掉视角锁定; 藏窗还原原来的鼠标, 不再 LockCenter
  PATCH → v1.1.1→v1.1.2 (跟 lib v2.0.6)

## v1.0.0 — 2026-09-03
- chore: 版本号重置为 v1.0.0 (对外重新编号, 功能不变)

## v1.1.1 — 2026-09-03
- enhance: 跟随 lib v2.0.3 — 黑金主题、Logo 呼吸、切 Tab 淡入、侧栏白字。玩法不变。
  PATCH → v1.1.0→v1.1.1

## v1.1.0 — 2026-09-03
- enhance: 跟随 lib v2.0.0 — 品牌方圆标替换全部小图标; 引擎默认即 Rayfield, 去掉单游戏 UiKit 开关。
  MINOR → v1.0.0→v1.1.0

## v1.0.0 — 2026-09-02
- refactor: 界面从 WindUI 迁到 Rayfield Gen2 (电脑侧栏 + 手机折叠胶囊). 玩法逻辑不变.
  MAJOR → v0.31.1→v1.0.0

## v0.31.1 — 2026-09-02
- fix: 跟随 lib v1.8.3 — 建窗后才关遗留层并强制本层 Enabled; 修从 Loader 注入后游戏窗口不显示。
  PATCH → v0.31.0→v0.31.1

## v0.31.0 — 2026-09-02
- enhance: 防踢心跳重做 — 注入即强制启动(修 Toggle Value=true 不触发 Callback 导致零防护);
  每 60s 重掐 Idled 引擎连接 + VirtualUser/VIM/mousemoverel/keytap 多通道脉冲;
  Idled 触发时立刻再掐+脉冲。杜绝闲置自动换服。
  MINOR → v0.30.5→v0.31.0
- publish: build+混淆 hub-single-obf → Gitee `60ae509` (manifest 0.31.0, obf ~263KB)

## v0.30.5 — 2026-09-01
- enhance: 防踢心跳改为三层 — 优先禁用 LocalPlayer.Idled 引擎连接; 退路 Idled 时 VirtualUser 右键; 再退路每 11 分钟 F15 (失焦也按, 取消跳跃以免搅抛竿)
  PATCH → v0.30.4→v0.30.5
- publish: build+混淆 hub-single-obf → Gitee `753f64b` (manifest 0.30.5)

## v0.30.4 — 2026-09-01
- fix: 快捷传送「表哥 · 设出生点」(SetSpawn ×10 Biao Ge) 纳入多岛合并 — 列表一条, 传送取最近。
  PATCH → v0.30.3→v0.30.4
- publish: build+混淆 hub-single-obf → Gitee `3442af5` (manifest 0.30.4)

## v0.30.3 — 2026-09-01
- fix: 快捷传送「功能 NPC」列表优化 — 卖钓鱼竿(表弟)/卖诱饵(八长)/开船(楚欣)/卖鱼(娜娜)
  多岛副本在下拉框只显示一条; 传送时按距自身最近的同功能 NPC 落点。
  (原逻辑: 同名只取第一个固定点; 楚欣 1~10 因英文名不同刷出多条重复「楚欣 · 开船」)
  PATCH → v0.30.2→v0.30.3

## v0.30.2 — 2026-08-31
- fix: 假称号视觉对齐服务器 EquipTitle — 颜色走 UIGradient(非 TextColor3); Title/图标/Flare1/Circle 同款渐变;
  VIP 半透底+Flare+Circle; 短名 Size.X=0.9 / 长名 2.2; 未开匿名时 PlayerName 同步同款渐变;
  开匿名时关掉名字渐变保持固定红; 不再伪造 Owned(避免误 FireServer 被拒)。
  PATCH → v0.30.1→v0.30.2

## v0.30.1 — 2026-08-31
- ui: 玩家 Tab 重排 — 兑换码 → 虚假信息(编号隐藏/匿名者/选择称号/应用称号) → 玩家(保持奔跑/移动加速/目标速度)。
- fix: 假称号未拥有时完整本地伪装 — 对齐游戏 Player_Title 逻辑: Data Owned+Equip;
  头顶 Billboard 写 Text/TextColor3/Image; 设置页写 cfg.Name + Icon.Image/ImageColor3;
  0.25s 保活防回写。立刻刷显示, 不等服务器。
  PATCH → v0.30.0→v0.30.1

## v0.30.0 — 2026-08-31
- remove: 玩家 Tab「船只召唤」整段移除 — 服务器会话状态导致召唤持续失效, 功能废弃。
- feat: 玩家 Tab「一键兑换全部」— 合并 Data[UserId].Code + 社区已知种子码 (49/48/47/46KLikes, 33~30MVisits, 13KActives, HWF, AXO, Taiji),
  跳过已兑 (BoolValue=true), 对其余 `Events.RedeemCode:FireServer(码)` 间隔抖动; 状态 Paragraph 显示已兑/待兑。
  MINOR → v0.29.2→v0.30.0

## v0.29.2 — 2026-08-31
- fix: 匿名者彩虹渐变改为固定红色 — 头顶名称 "theKing Create" 改为 "theKing User" (红色固定色, 不再渐变), 移除 0.1s HSV 彩虹循环 (StartLoop("anonRainbow"))。
  PATCH → v0.29.1→v0.29.2
- feat: 玩家 Tab 新增「编号隐藏」— 隐藏屏幕右上角玩家编号 (PlayerGui.MainGui.TextLabel, 实测用户 ID 3547743270), 开关持久化。
- feat: 玩家 Tab 新增「匿名者」— 头顶名称 (HumanoidRootPart.EquippedTitle.PlayerName) 改为 "theKing Create",
  0.1s 循环 HSV 色轮旋转 TextColor3 做彩虹渐变 (仅本地可见); 角色重生自动重新应用; 关闭恢复原名。
- fix: 船只召唤"每次必须再召唤选中船只再上座" — 召唤前快照现有船集合 (collectBoatSet),
  召唤后轮询只认**新出现**的带 VehicleSeat 的船 (排除旧船/他人船), 找到即上座; 轮询窗口 6s→8s。
  MINOR → v0.27.2→v0.28.0

## v0.27.2 — 2026-08-30
- fix: 船只召唤"实际召唤不了"两个根因 — ① selectedBoat 初始 nil (Dropdown Callback 只在主动选择时触发,
  不选直接点召唤永远"请先选择船只") → 默认选中列表第一艘 + summonBoat 兜底;
  ② 上座 hum.Sit=true 会被引擎/服务器复位 (实测 Sit=false) → 改用引擎级 `VehicleSeat:Sit(humanoid)`
  绑定 Occupant, 服务器认可 (实测 humSit=true + seatOccupant=true)。端到端实测: 找NPC(Chu Xin 9)✓
  召唤✓ 找船✓ 上座✓。PATCH

## v0.27.1 — 2026-08-30
- fix: 船只召唤逻辑改为「最近船坞 NPC → 召唤 → 传送玩家上驾驶位」 — 召唤点从玩家位置改为
  Workspace.NPC.SpawnBoat 下最近的 Chu Xin N 船坞 NPC (HumanoidRootPart.Position),
  与游戏船坞 Spawn 按钮同语义 (Location 即船坞生成点); 召唤后轮询在船坞附近找 VehicleSeat
  并把角色瞬移上去 (HRP.CFrame=seat.CFrame + Sit)。实测 10 NPC 距离排序正确。PATCH

## v0.27.0 — 2026-08-30
- feat: 玩家 Tab 新增「船只召唤」(放最前面) — 只列已拥有的船 (Data.Boats BoolValue=true), 选择后召唤到角色当前位置 (Remotes.BoatShop.Spawn:FireServer(船名, HRP.Position), 与游戏船坞 Spawn 同款), 召唤后自动找 VehicleSeat 放角色上驾驶位; 含刷新列表按钮。逆向: Info.Boats 5 艘 (Boat 60速/Golden 90速/Rainbow 120速/Kunfish Overlord 85速/Ascended Perch 85速), 船坞 UI 由 VisibleUI("BoatShop", Location) 驱动。MINOR → v0.26.3→v0.27.0
- feat: 注入初始化批量通知静默 — 新增 notifyMuted 标志, 从 NewTab 起(ConfigManager 恢复 + setAutoFish(false))到注入初始化完成全抑制 notifyToggle, 不再每次注入弹一堆"已开启/已关闭"; 用户手动操作恢复通知。MINOR
- fix: 玩家 Tab 定义行被误删 — 插入船只召唤 do 块时 new_string 吞掉了 `local PlayerTab = NewTab(...)`, 导致 `PlayerTab:Section` nil 报错; 补回定义行修复。PATCH

## v0.26.3 — 2026-08-30
- fix: Tab 侧栏重排真正生效 — TARGET_ORDER 表用了旧 Tab 名("鱼饵管理"/"恩佐BOSS"),
  v0.26.0 重命名后所有标题匹配 miss, 1.5s 延迟 LayoutOrder 覆盖完全跳过,
  WindUI 自身默认 LayoutOrder(乱序: 库存管理=0, 自动钓鱼=1, 背包管理=3, ...) 保留。
  改用新名 + 移除已并入自动钓鱼的"恩佐BOSS" → 1..7 连续覆盖, 实机验证全部正确。
  教训: TARGET_ORDER 类映射表必须随 Tab 名重命名同步更新; 错过则 LayoutOrder 失效但无任何报错, 极难发现。PATCH

## v0.26.2 — 2026-08-30
- fix: 竿列表"只列已拥有"真正生效 — FishingRodInventory 的 Folder 子对象是**全量目录**(39 把都有),
  拥有判定必须看 Folder 内 `Owned(BoolValue)=true` (实测用户仅 25/39 把); v0.26.1 误把"Folder 存在"当拥有,
  列表仍列全 39 把。PATCH → v0.26.1→v0.26.2
- fix: 修 buildRodList 结构损坏 — v0.26.2 改 guard 式 continue 时旧 `if f:IsA("Folder")` 的闭合 end 残留(2823),
  提前闭合 buildRodList 函数 → table.sort/for 被挤出函数、2834 误闭合 2747 do 块、2886 变多余 end (Lua 报
  `<eof> expected near 'end'`)。删除残留 end 后恢复 812/812。教训: 包裹式 if→guard 式改造必须同步删掉旧 end。

## v0.26.1 — 2026-08-30
- fix: 钓鱼竿列表改为**只显示已拥有的竿** — 数据源从 `Info.Inventory`(全量配置库, 含未拥有的竿) 改为 `playerData.FishingRodInventory`(Folder 子对象 = 拥有的竿, 39 把), 能量仍从 Info.Inventory 对应模块读取。
- fix: Tab 顺序调整 — WindUI Tab 顺序由创建顺序决定, 将「背包管理」(原鱼饵管理)与「库存管理」(原背包管理)两个创建块整体前移至「快捷传送」之前, 得到: 自动钓鱼→背包管理→库存管理→快捷传送→快捷键→玩家→设置。
- PATCH → v0.26.0→v0.26.1

---

## v0.26.0 — 2026-08-30
- refactor: 恩佐二阶段命中链路彻底改为**直接发服务器命中包 + 手动模拟绿框移动**。实测确认"错误按下"全部来自模拟点击链路(① 点击落点被 GUI 覆盖 → gameProcessed=true → 游戏 onClick 首行吞掉点击; ② 游戏 onClick 用自身内部变量复算条位, 与脚本预测存在系统偏差)。而服务器逆向证实只信任 `BossPhase2Action{Hit=true}` 标志(盲发必胜), 直接发包 = 100% 接受、零错按; 为保留绿框移动观感, 命中后手动把绿框挪到远离当前条位的新位置(最多试 20 次防死循环)。判定仍用 AnchorPoint 修正 + 速度预测。
- feat: Tab 重命名 — 「鱼饵管理」→「背包管理」, 「背包管理」→「库存管理」。
- feat: 背包管理 Tab 新增**钓鱼竿装备**: 扫描 Info.Inventory 中 Type=="Fishing Rod" 的 39 把竿, **完全汉化**(CN_RODS 全量映射), 按 **Power(能量)降序**排列(同能量并列稳定排序), Dropdown 选择 + 一键装备(`Events.EquipFishingRod:InvokeServer(竿英文名)`, 与游戏背包点击 Equip 同款) + 刷新列表按钮。实机验证: 荷鲁斯之眼·能量9999 排最前(降序生效), 装备失败/未选竿均有中文通知。
- MINOR → v0.25.2→v0.26.0

---

## v0.25.2 — 2026-08-30
- fix(回归): v0.25.1 判据过苛, 出现"条穿过绿区但完全不开火"。根因两条: ① **最近点判据**要求偏差"由减转增"才点击, 但循环是 20Hz(50ms)采样, 条速快时相邻两次采样直接跨过转折点 → 永远等不到 → 不开火; ② **节流 0.12s 过长**, 条单次穿越绿框的停留时间比它还短, 第二次进框被节流整个吞掉。修复: ① 移除"最近点判据", 改为**进窗即打**(命中窗 = 框宽*0.75 - 0.01, 仅留极小余量); ② 节流 0.12s → **0.06s**(游戏内部节流仅 30ms, 60ms 足够防连点又不漏框); ③ 保留真正提准的两项 — AnchorPoint 修正(框心不再偏半个框宽, 这是错按主因)与速度预测(补偿游戏 25ms 判定回溯 + 我方 1 帧输入延迟)。净效果: 召回回到"见框就打", 准确率仍由 AnchorPoint 修正兜底。PATCH → v0.25.1→v0.25.2

---

## v0.25.1 — 2026-08-30
- enhance: 恩佐二阶段点击判定精度优化, 减少错按(游戏回 Hit=false)。根因(头号): 实测 `BossFightBar.Bar` 与 `.Hitbox` 的 **AnchorPoint 均为 (0.5, 0.5)**, 即 `Position.X.Scale` 直接就是中心; 而脚本沿用 `Position + Size/2`, 把**框心算偏了半个框宽(实测 0.055)** → 脚本判定"已进框"时条其实还在框外, 一点就判未命中。修复三件套: ① **AnchorPoint 修正** — 条心/框心直接取 `Position.X.Scale`, 不再 +Size/2; ② **速度预测** — 游戏 onClick 用「点击时刻 - 25ms」的位置判定, 我方发点击另有约 1 帧输入延迟, 故按条速外推 `PHASE2_LEAD=0.02s` 到点击真正生效的时刻再判定, 避免"看着在框内、点到时已滑出"; ③ **最近点判据** — 等偏差由减转增(已越过框心最近点)才发点击, 不在框边缘冒险, 命中窗再收紧 `PHASE2_EDGE_SAFE=0.02`; 条若几乎停在框心(|d| ≤ 框宽*0.15)则直接点, 兼顾"迅速"。另加**换轮重置**: 检测到绿框位置变化(游戏已执行 newHitbox)即重置最近点追踪, 防同一轮连点。PATCH → v0.25.0→v0.25.1

---

## v0.25.0 — 2026-08-30
- feat: 恩佐二阶段(Phase2 点击小游戏)改为**走游戏真实流程**, 不再直接 FireServer 盲发。逆向 `PlayerScripts.MinigamePhase2` 得真实协议: 触发 = `UserInputService.InputBegan` + MouseButton1/Touch 且 `gameProcessed==false` → `onClick()`; onClick 内部判定条中心是否落在 `[绿框起点-容差, 绿框终点+容差]`, 命中则 `FireServer({Hit=true, Index=u109})` **并调用 `newHitbox()` 把绿框随机移到新位置**, 未命中则 `FireServer({Hit=false})` + 闪光; onClick 自带 30ms 节流。旧实现直接发包跳过了 newHitbox → 绿框全程不动, 只是"服务器认账", 并非真实小游戏行为。现改为: 条进绿区时模拟鼠标左键点击(落点固定屏幕左上角 10,10 — 实测该处无 GUI, gameProcessed=false; 若落在任何 GUI 上, 游戏 onClick 首行 `if p2 then return end` 会直接吞掉点击), 判定/发包/移框全部由游戏自身完成, 判定公式与官方完全一致(hbW*0.75+0.01)。点击节流 0.12s(游戏内部 30ms, 留余量防连点被吞)。无 GUI 读不到条/框时保留原直接发包兜底。MINOR → v0.24.10→v0.25.0

---

## v0.24.10 — 2026-08-29
- fix(回归): v0.24.7 的节奏重写导致章鱼二阶段小游戏**完全不起效果**(上一版还能打中, 只是漏点/无 Perfect)。根因: 兜底命中窗由 0.22 收紧到 0.06 (3.7 倍), 而主判据"跨过判定线"依赖 lineY 绝对精确 — lineY 取自 `BarFrame.Position.Y.Scale`, 一旦该值与实际判定线有偏差(音符 AnchorPoint 差异/游戏改布局), 音符永远进不了 ±0.06 的窄窗, 跨线点也落在错误位置 → 整场零命中。修复: ① 窗宽回调至 0.15 — 下界约束是后期音符间距 ≈0.19 Scale(窗必须小于它才不会同 tick 挤进多个音符), 上界约束是 lineY 容差, 0.15 是二者平衡点; ② 判据改为**每轨道每 tick 只取一个最优**(跨线优先, 其次最接近判定线), 从机制上杜绝同 tick 多发错配(旧版漏点的真因), 因此窗可以放宽而不重蹈覆辙; ③ 保留去重(noteHit, 每音符只发一次)与不再本地 Destroy; ④ 新增命中日志 `[节奏] <轨道> 命中 y=… line=… |d|=… 跨线/窗内`, 便于实机核对 lineY 是否准确。PATCH → v0.24.9→v0.24.10

---

## v0.24.9 — 2026-08-29
- fix: 烈阳高照天气下「快捷传送 → 传送至天气渔场」失效 (点按钮只弹"当前天气无稀有鱼")。根因: 游戏天气值 `workspace:GetAttribute("Weather")` 实机为 **"Blazing Sun"(带空格)** — 已由 ReplicatedStorage.Weather 子对象与 ClientModule.Weather.Weather 模块名双向证实, 与 intel 记录一致; 而脚本内天气鱼映射表的键写作 **"BlazingSun"(无空格)**, 直接下标查表落空 → 天气渔场传送/天气预报/智能锁定"特殊天气鱼"规则在烈阳下整片静默失效。其余 5 种天气(Windy/Snowy/Thunderstorm/Foggy/Clear)均为单词无空格故不受影响, 这正是"只有烈阳失效"的原因。修复: ① 7 处天气键统一改为服务器真值 "Blazing Sun"; ② 新增 `getWeatherTargets()` 规范化查表 (原值 → 去空格 → 小写去空格三级兜底), 传送与天气预报两处调用点均改走它, 键格式再变也不会整片失效; ③ 中文显示名随游戏 UI 更正为"烈阳高照"(原"烈日"), 同步 CN 映射/中文反查表/关注天气下拉框; ④ 删除因改动而失效的 `WEATHER_FISH` 本地副本。PATCH → v0.24.8→v0.24.9

---

## v0.24.8 — 2026-08-29
- fix(严重): 开目标鱼过滤后, 非目标鱼咬钩按1收竿 → 鱼竿再也装备不回去, 自动钓鱼彻底停摆。根因两层: ① fastCancelTarget 用固定 0.18s 延时按两次 1(先收竿后拿竿), 完全不校验装备态且不重试 — 第二次按键常被游戏收竿动画吃掉 → 装备态卡在"未装备"; ② autoFishTick 待机态遇到 rodEquipped=false 只提示"请先装备鱼竿"就 return, 无任何自愈 → 一旦丢失即永久停摆。修复: ① fastCancelTarget 改状态驱动 — 收竿后轮询等装备态真正解除(首按被吃掉则补按), 再按1复位且失败重试最多5次, 全程3s超时兜底; 新增 fastCancelBusy 重入保护(连续非目标鱼并发调用会按键乱序翻出未装备态); ② 待机态兜底改为自动按1重装备(1.5s 节流防刷键), 任何原因导致的装备态丢失都能自愈; 复位最终失败则弹中文通知提示手动按1, 不再静默卡死。PATCH → v0.24.7→v0.24.8

---

## v0.24.7 — 2026-08-29
- fix: 章鱼(无名章寄)二阶段节奏小游戏漏点 + 无完美点击 — 双根因: ① 判定窗 ±0.22 宽 0.44 Scale, 而后期音符间隔 0.3s×下落速度 0.64 Scale/s ≈ 0.19 Scale 间距, 窗比音符间距还大 → 同一 tick 窗内常驻 2-3 个音符, 代码对每个都发 RhythmHit("hit"), 而该包不带音符 ID, 服务器按序消费 → 多发错配, 后续真音符被判 miss(漏点); ② 音符刚进窗(偏离 0.22 最大)就立即发 hit, 命中精度最差 → 拿不到 Perfect。修复: 主判据改为"跨过判定线"检测(记录上一 tick 的 Y, prev<lineY 且 y>=lineY 的瞬间发送 = Perfect 时机), 兜底窗收紧 0.22→0.06; 新增 noteHit 弱键表去重(每个音符只发一次, 杜绝重发错配); 不再本地 Destroy 音符(避免客户端/服务器状态不一致); RhythmStart 开新场时 table.clear 清空追踪表防残留。PATCH → v0.24.6→v0.24.7

---

## v0.24.6 — 2026-08-29
- fix: 普通 Boss 鱼(章鱼/赤鳊等)二阶段节奏小游戏误触发恩佐接管 → 弹"恩佐已接管"干扰 + bossPhase2Tick 盲发 BossPhase2Action 致服务器扣血(维妮塔)。根因: bossDetectTick 的 midFight 判据含 rhythmActive, 但 RhythmStart 是通用信号(恩佐/普通 Boss 鱼共用同一套 Rhythm 容器), 普通 Boss 鱼二段触发 rhythmActive=true → bossActive=true → startBossFight() 误接管。修复: midFight 收窄为纯恩佐权威信号 enzoInFight (workspace.NPC.Enzo.InFight), 普通 Boss 鱼节奏由 bossRhythmTick 独立处理不受影响。PATCH → v0.24.5→v0.24.6
- fix: 目标鱼过滤持久化恢复不稳定 — Config:Load 恢复 Flag 顺序不确定(鱼多选可能先于分组恢复, 分组 rebuild 会清空已恢复勾选), 原 task.defer 兜底与 Config:Load 存在时序竞争。修复: 删 task.defer, 改在 TheKing.LoadConfig() 之后显式调用 targetFishRestoreFn 重套 targetFishNames, 此时所有 flag 已恢复且 choices 映射已就绪, 无时序竞争。实机验证: 重载后 targetFishNames 从持久化恢复 22 条鱼正确填充。
- enhance: dbg.state 新增 targetFishEnabled/targetFishCount 字段, 便于实机诊断目标鱼过滤状态

---

## v0.24.5 — 2026-08-29
- fix: 恩佐二阶段节奏小游戏/Phase2点击小游戏期间战斗技能仍狂放 → 打乱小游戏判定 → 服务器扣血(维妮塔)失败。根因: autoSkillTick 门控只查 fsmState=="战斗中", 而节奏小游戏(rhythmActive=true)/Phase2 期间 fsmState 仍为"战斗中"(startBossFight 置位后未清除), 技能照放。新增两处禁放门控: ① autoSkillTick @1091 节奏/Phase2 期间直接 return; ② autoCharge 蓄力代点 @2226 同款禁放。均不改正常战斗放技能逻辑。PATCH → v0.24.4→v0.24.5

---

## v0.24.4 — 2026-08-28
- fix: 恩佐战斗 FinalPhase 节奏小游戏后面阶段失效 — 根因①: pv2922 音符(Note_FX)直挂轨道(ProgressionX)下(非 NoteFrame 容器), 原 bossRhythmTick 只扫 NoteFrame 子节点 → 后面阶段音符全漏; 改为扫轨道 GetChildren 直接挂的 Note 对象(排除 NoteFrame 容器本身)。根因②: 判定线取死值 0.85, 实机 BarFrame.Position.Y.Scale 默认 0.85 但需动态读取; 改为读 track:FindFirstChild("BarFrame").Position.Y.Scale 兜底 0.85。根因③: RhythmStart 原门控 fsmState=="战斗中", 章鱼等多命鱼二段/FinalPhase 切换时 fsmState 非战斗中 → 接管不触发; 改为无条件接管(任意节奏小游戏开始即扫)。PATCH → v0.24.3→v0.24.4
- fix/refactor: 自动点 Perfect 功能内置化 — 移除「自动点Perfect」独立开关(autoSlamOn)、MainTab「战斗策略」Section 的对应 Toggle、hkSlam 热键、dbg.state 字段、setSlam; Slam handler 改为识别到 Slam/Heal/Perfect/QTE 按钮即内置代点 FireServer("Perfect") 销毁按钮(覆盖加血QTE等回血小游戏), 无需开关。PATCH → v0.24.3→v0.24.4

---

## v0.24.3 — 2026-08-28
- refactor: 恩佐BOSS自动战斗完全并入自动钓鱼 — 移除独立「自动战斗」开关与 setBossMode 函数, bossModeOn 改为纯镜像 autoFishOn (setAutoFish 同步置真并启停 bossDetect/bossPhase2 循环)。用户工作流: 手动点NPC/传送开恩佐挑战 → 开自动钓鱼即自动识别(workspace.NPC.Enzo.InFight)接管战斗全流程; 仅「智能释放技能」(bossSkillOn) 独立控制放技能, 关闭时除技能外(控条/Phase2/节奏/Rhythm)仍全自动。MINOR → v0.24.2→v0.24.3

---

## v0.24.2 — 2026-08-28
- fix: 恩佐BOSS开战检测第二版 — v0.24.1 的 fishesFolder 扫描(Boss&&HasPhaseLeft)假设错误, 实机 v2922 证实恩佐模型无 Boss/HasPhaseLeft 属性、FishID 不指向 fishesFolder 实体, 三路信号仍全 false → 接管继续失效。改用权威信号 `workspace.NPC.Enzo.InFight` (NPC 模型镜像属性, 开战时服务器置 true, BossUI refresh() 据此禁用 Fight 按钮), 兜底 `BossSetUp.Enzo.InFight` (实测恒 nil)。job enzo-infight-spy 抓到 npcInFight=true 全程(t=1~134) 坐实。bossDetectTick 加 2s 节流诊断日志。PATCH → v0.24.1→v0.24.2
- note: 恩佐 Phase1 = 纯技能 DPS (UseSkill Z/X/C/V, 无血条无 GUI), 接管(bossActive=true)后仍需开启「智能释放技能」(bossSkillOn) 才能对 Phase1 造成伤害; 仅开 bossModeOn 不开发技能则 Phase1 不掉血 (autoSkillTick 门控: bossActive and bossSkillOn)。

---

## v0.24.1 — 2026-08-28
- fix: 恩佐BOSS自动战斗全程无效 — 根因 bossDetectTick 三检测信号(主阶段鱼条/Phase2/控条UI可见)在恩佐 Phase1 全 false (主阶段不控 FishingMinigame, FishID 不指向恩佐实体, Phase2 仅二阶段显, 控条 UI 不显示) → bossActive 永 false → startBossFight 永不调用 → 控条/Phase2/节奏全瘫。修复: 属性扫描 fishesFolder 多命实体(Boss && HasPhaseLeft) + StartBossFight/BossPhase2Setup OnClientEvent 推送监听 + BossTab 强制接管按钮 三路冗余; 结束判据改为"曾确认且信号持续消失>2s"避免 Phase1 误停。PATCH → v0.24.0→v0.24.1

---

## v0.23.0 — 2026-08-28
- feat: 一次性大招识别与时机门 — CD≥120s 技能 (无我 Egoless 999 / 万古系 Sever the Gate 9900000 / 纯阳无极 / 一钩定乾坤 / 毁灭牺牲 等 7 个) 分类为 ult, 只在「鱼真血命且剩余血量≥30%」时放 (开场倾泻/顺序模式/智能择优三路都受门控), 假血阶段与残血收尾一律不浪费。MINOR → v0.22.0→v0.23.0
- feat: 多命鱼假血感知 — 鱼配置新增 Phase 字段识别 (虎沼鱼 3 命/无名章寄 8 命/幻影灯笼鱼 2/章寄鱼 2, 其余单命), dealt(fish.Value)/MaxHealth 回跳实时计数当前命数, FinalPhase attribute 显式标记最后一条命; 前 N-1 条假命 (打到边界回满) 一次性大招禁用, 最后一条真血命才释放。MINOR → v0.22.0→v0.23.0

---

## v0.22.0 — 2026-08-28
- feat: 智能技能四层决策引擎 (智能择优模式) — ①保命回血: 自身 HP<50% 优先放 Heal/GodHeal 回血技 ②鱼残血收尾: 鱼剩 <15% 跳过 buff 直接直伤倾泻 ③增益覆盖: 无 RodPower 增益时优先放 Power/Boost 增益技 (Bleed 自损技在 HP<40% 时禁用防猝死) ④元素加权: 竿 Description 提取元素 (如 "Maoshan skills" ×2.00) × 技能 Type 同元素 DPS 评分加权。MINOR → v0.21.0→v0.22.0
- feat/refactor: 全 UI 文案精简 — 30+ 控件 Title/Desc 重写为一句大白话 (自动钓鱼/自动技能/智能回正/智能放弃/目标鱼过滤/自动出售/智能锁定/恩佐BOSS/传送/玩家/设置 等), 去掉技术黑话与冗余括号, 功能不变仅文案。MINOR → v0.21.0→v0.22.0

---

## v0.21.0 — 2026-08-28
- feat: 恩佐BOSS Tab 新增「智能释放技能 (独立)」开关 + 「技能释放模式 (恩佐)」下拉 (智能择优/顺序释放) — 独立于自动钓鱼Tab的自动技能, 互不干扰: 恩佐战斗只认 bossSkillOn/bossSkillMode, 普通钓鱼只认 autoSkillOn/skillMode, 技能循环统一管理(syncSkillLoop 幂等启停); 恩佐战斗结束自动恢复自动钓鱼技能原状(删旧 prevAutoSkill 还原逻辑)。MINOR → v0.20.6→v0.21.0
- feat: 节奏小游戏自动打击泛化 — 恩佐 FinalPhase 与普通钓鱼 Boss 鱼二段(无名章寄等)通用: RhythmStart 触发(fsmState==战斗中)即自动扫 ProgressionA/S/D 三轨音符发 RhythmHit("hit"), 新增 RhythmStop 监听即时停扫 + 130s 超时兜底, stopFight 清残留。MINOR → v0.20.6→v0.21.0
- fix: 目标鱼分组名精简 — 「诱饵制作分组(配方…)」「鱼竿制作分组(配方…)」去掉括号配方说明, 仅保留分组名。PATCH → v0.20.6→v0.21.0

---

## v0.20.6 — 2026-08-28
- fix/feat: 目标鱼过滤分组重组修正 — 用户要的是「诱饵制作分组」「鱼竿制作分组」两个分组(非拆 6 条), 每个分组内含该制作线要钓的全部鱼, 括号标注子配方鱼构成。诱饵制作分组=冰霜/彩虹/无名饵配方鱼并集(12 种, EN); 鱼竿制作分组=穿天竿/纯钻竿/圣竹竿配方鱼并集(12 种, 穿天龟=Heavenpiercer Turtle、升华鲈鱼=Ascended Perch、高山鱼=Mountain Fish 用 EN, 余 9 中文走 cnBase 过滤)。原 v0.20.5 误拆成 6 条已废弃。PATCH → v0.20.5→v0.20.6

---

## v0.20.5 — 2026-08-28
- feat: 目标鱼过滤分组重组(初版, 误拆 6 条, 见 v0.20.6 修正) — 原「冰霜/彩虹/无名鱼饵分组」合并为「诱饵制作」+「鱼竿制作」两类目, 各含子配方鱼; 鱼竿鱼名中文走 cnBase 过滤。MINOR → v0.20.4→v0.20.5

---

## v0.20.4 — 2026-08-27
- feat: 目标鱼过滤持久化 — 鱼多选下拉加 Flag="targetFishSel", 重载/重跑自动恢复上次勾选的鱼(与分组 Flag="targetFishGroup" 联动)。目标分组此前已持久; 现分组+勾选全持久。稳健性: WindUI Config:Load 恢复 Flag 顺序不确定(鱼多选可能先于分组恢复, 分组 rebuild 会清空已恢复勾选), 故鱼回调捕获 lastFishSel + task.defer 在 LoadConfig 之后重套 targetFishNames, 与恢复顺序无关。PATCH → v0.20.3→v0.20.4

---

## v0.20.3 — 2026-08-27
- fix: 目标鱼过滤仍失效 — 根因: 开关 Callback 在「开启但还没选鱼」时把 targetFishEnabled 强制置 false(自动关闭), 而开关 Flag 持久化会在每次重载/重跑自动恢复为 ON, 触发该回调把 targetFishEnabled 打死 → 开关显示开但实际不过滤, 勾鱼也不生效。改为开启不再强制关闭(仅提示), 过滤在 targetFishNames 非空时才生效。另: 鱼名回传同时存中英文 key 防 FishName 命名空间错位; 目标鱼分组下拉排序移到选鱼上方。PATCH → v0.20.2→v0.20.3

---

## v0.20.2 — 2026-08-27
- fix: 目标鱼过滤选中不生效 — v0.20.1 鱼多选下拉用 Values={} 空列表创建后 :Refresh 填充, WindUI 空→有列表可能不绑定选项点击回调, 导致勾选写不回 targetFishNames, 过滤形同虚设。改为初始即用全部分组非空列表创建(与 pointDropdown 同款 :Refresh 用法: populated→populated 才稳)。PATCH → v0.20.1→v0.20.2

---

## v0.20.1 — 2026-08-27
- fix: 目标鱼分组下拉点不开 — 鱼多选下拉 Multi=true 时误传 Value=字符串(choiceList[1]), WindUI 多选仅接受 table 作 Value, 展开时构建选项崩溃。改为 Value={} 且切换分组改用 :Refresh 动态更新选项(复用脚本已有 pointDropdown 写法), 不再 Destroy+重建(规避 Flag 复用/无 :Destroy 隐患)。PATCH → v0.20.0→v0.20.1

---

## v0.20.0 — 2026-08-27
- feat: 目标鱼过滤分组隔离版 — 新增「目标鱼分组」单选下拉, 在 全部/BOSS/天气鱼/冰霜·彩虹·无名鱼饵/球体/功法/各岛屿(新手/竹子/核弹/主权/鲈鱼/冰霜/椰子/琥珀/战场/迷雾) 间切换; 切换分组销毁旧鱼多选下拉并重建仅含该组鱼, 同时清空 targetFishNames 实现真互不干扰(旧勾选全废)。BOSS分组=Info.Inventory 鱼模块 Boss=true 字段(46 种, 即多人可钓 BOSS 鱼); 球体/功法分组=扫描 Reward.Orb/Skill 字段(4/24 种)运行时生成, 游戏更新自动跟随。MINOR → v0.19.0→v0.20.0

---

## v0.19.0 — 2026-08-27
- feat: 目标鱼过滤快放弃 — 非目标鱼咬钩时不再走 doGiveUp 的 8s 服务器结算等待, 改为 `VirtualInputManager` 模拟按 1 收起钓鱼竿(即时取消咬钩) + 间隔 0.18s 再按 1 拿起复位, 状态机回待机由自动抛竿循环无缝接管, 显著提速。智能放弃(战斗中)仍走原路径。增强 MINOR → v0.18.3→v0.19.0

---

## v0.18.3 — 2026-08-27
- fix: 天气渔场传送 — 雾蒙蒙(Foggy)天气椰子岛与雾峰岛均有特殊鱼, 原逻辑取映射表"第一个"岛(顺序不定)可能传错岛。改为多岛屿天气优先用户偏好岛: 雾蒙蒙固定传椰子岛(Coconut Isle), 其余天气回退取首个。纯偏好修正 PATCH → v0.18.2→v0.18.3

---

## v0.18.2 — 2026-08-27
- fix: 删除传送鬼魂(9178)相关功能 — 用户判定无用。清理: `findGhostModel()`/`tpToSpirit()` 函数、TeleportTab "传送至当前鬼魂" 按钮、"NPC 大全" 鬼魂图鉴整段(Section/Paragraph/按钮)、头部 intel 鬼魂注释、功能清单 "NPC大全(鬼魂图鉴)"。游商/普通NPC/服务器玩家传送不受影响, 无专属循环需清理。纯删除 PATCH → v0.18.1→v0.18.2

---

## v0.18.1 — 2026-08-27
- fix: 奖励弹窗不会自动关闭 — 根因: 自动关闭逻辑原写在 autoFishTick 内, 该 tick 仅由自动钓鱼循环驱动, 关闭自动钓鱼后循环不跑 → 弹窗永不关。修复: 抽出独立常驻看守 setupRewardWatcher(), 对 MultiNotifyReward 挂 Visible 属性监听, 任意状态下弹窗出现即隐藏放行, 与自动钓鱼开关解耦

---

## v0.18.0 — 2026-08-27
- feat: 智能锁定新增「手动常锁鱼种」— 用户手动勾选特定鱼种永久锁定(优先级高于规则/价值), 自动出售永不卖。修复初版下拉源错误(FISH_ISLE_MAP/fishesFolder 不含背包真实鱼名导致清单为空选不到): 改由实时扫描 `Data[userId].Inventory` 当前鱼种生成清单, 名称空间与锁定逻辑(getFishBase)一致。选定即扫描锁定现有背包

---

## v0.17.0 — 2026-08-27
- feat: 自动领取奖励弹窗 — 钓上鱼触发宝珠/功法/水晶等奖励时, 游戏 `MultiNotifyReward` 弹窗(纯展示, 无自动关闭逻辑)会挡住抛竿导致自动钓鱼卡死。修复: 自动钓鱼主循环检测该弹窗 `Visible` 即隐藏放行, 奖励已由服务器发放不受影响。惰性补抓 GUI 引用(弹窗由 PlayerScript 延迟创建), 每个新弹窗仅提示一次。注意: 隐藏后游戏内 `u86` 防重复标志永久置位, 后续奖励页不再弹出(仅展示层, 奖励仍到账)

---

## v0.16.3 — 2026-08-27
- fix: 随机切换服务器永远报"没有可用的其他服务器" — 根因: 过滤条件 `maxP - curP >= 2`(要求≥2空位)过严。该游戏每服 maxPlayers=10 且有空位服恒为 9/10(仅差1空位), 无任何服满足≥2空位 → candidates 恒空。实测第一页 100 服有 53 个有空位(全 9/10)。修复: 放宽到 `curP < maxP`(至少1空位即可, TeleportToPlaceInstance 在 playing<maxPlayers 能进)。实机验证新逻辑候选数 0→51。API/HTTP/JSON解析均正常, 非网络问题

---

## v0.16.2 — 2026-08-27
- fix: 天气传送/天气稀有鱼提醒在「烈阳高照」失效 — 根因: WEATHER_ISLE_MAP / CN_ALL / watchWeathers / CN_TO_WEATHER 四处天气键写成带空格 `"Blazing Sun"`, 而 `workspace:GetAttribute("Weather")` 实际返回无空格格式 (Windy/Snowy/Thunderstorm/Foggy 均无空格且能传, Foggy 已实测)。键≠值 → 查表 nil → 该天气链路(提醒+传送)全失效。修复: 四处统一改 `["BlazingSun"]` / `"BlazingSun"`, 与天气属性真实格式对齐。待烈阳高照天气实机验证(当前 Foggy 无法触发)
- 版本号纠正: 运行时版本实为 line 51 `ScriptVersion="0.16.0"`(独立变量, 连 v0.16.1 都未更), 本次一并 `0.16.0`→`0.16.2`; line 2 头部注释仅为文档, 不影响运行时

---

## v0.16.1 — 2026-08-27
- fix: 效率统计「背包」显示 0 — 根因 Lua 前向引用: updateStatsPanel(388) 定义早于 sellFishCount(447) 的 local 声明, 闭包把 sellFishCount 解析为全局(nil), 调用 nil 抛错使 bagCount 恒 0。修复: ①updateStatsPanel 前前向声明 local sellFishCount/realBagCount ②447 行 local function→function(复用前向局部) ③新增 realBagCount() 返回真实背包总数(Inventory 全部子项 + Hotbar 数量, 匹配游戏背包容量口径), 面板改显真实总数(含锁定鱼)而非仅可售数(用户要求"真实背包数量")。实测 forcePanelDetail 由 beforeBag=0 变 349, 与独立复刻计数一致

## v0.16.0 — 2026-08-27
- feat: 快捷传送新增「传送至当前鬼魂」— 实时定位随机刷新的特殊 NPC (玩家头顶名 "9178", 非固定 workspace.NPC.Spirit 无用NPC); 无 workspace attribute 监听 (异于游商), 按 名称/DisplayName/头顶文本 "9178" 实时判定, 未刷新时提示; 复用 L1 同款 CFrame 写入, 战斗/结算中拦截
- feat: 新增「NPC 大全」Section (图鉴) — 首条收录鬼魂: 头顶名 9178、随机刷新于三个点位之一、可花游戏币购买功法 (概率失败, 功法名待确认); 附「传送至鬼魂」按钮

## v0.15.7 — 2026-08-27
- feat: 设置新增「随机切换服务器」— 调 Roblox games API 拿服务器列表, 随机选非当前且未满员的 jobId, TeleportToPlaceInstance 传送; 确认对话框 + 切换前自动停止全部功能; game:HttpGet 主路 / request 兜底 (不注入不 hook)
- fix: 效率统计面板不更新 — 根因: 热替换后旧 statsTick 循环引用已销毁的 Paragraph/playerData, 每周期报 `attempt to call a nil value` 打断刷新。三重修复: ①theking.luau UpdateStatus 增加元素已销毁静默返回 ②statsTick 循环体整体 pcall 容错 ③isInventoryFull 改 FindFirstChild 防御性取值。实测 8 秒错误零增长, 面板恢复刷新

## v0.15.6 — 2026-08-27
- fix: 效率统计显示精度与认知 — "垂钓 X 分" 改 .1f 小数 (避免 1.6 分显示 1 分导致效率口径失真); 面板新增 "背包 X 条" 实时显示可售库存, 解释 ¥0 时 "捕获≠收入" (卖鱼现金 ≠ 捕获价值, 背包鱼待自动出售阈值触发)

## v0.15.5 — 2026-08-27
- fix: 记录/删除点位后列表不刷新 — 保存 pointDropdown 句柄, 记录/删除后调用 WindUI `Dropdown:Refresh(newValues)` 重建选项列表 (源码确认 Refresh 接受新 Values 参数); 选中项失效自动回退首个

## v0.15.4 — 2026-08-27
- feat: 快捷传送新增「记录点位」— 自定义标记点: 记录当前位置 (自动命名"点位 N") / 下拉选择 / 传送 / 删除; 持久化到 heavyfishing_points.json (readfile/writefile + JSON, 标准注入器 API), 重注入自动恢复
- 验证: JSON 读写 roundtrip 实测通过 (含中文点位名); 语法门 0 error (2939 行); 注入无编译错误

## v0.15.3 — 2026-08-27
- feat: 智能锁定新增「特殊天气鱼」规则 — 天气限定鱼 (特定天气×特定岛, WEATHER_ISLE_MAP 全部 11 种) 自动锁定; 默认开启, 可在「启用哪些锁定规则」多选调整 (Flag: lockRules)
- refactor: WEATHER_ISLE_MAP / WEATHER_FISH_SET 上移至状态区 — 智能锁定/天气预报/天气渔场传送三处共用
- 分析: 「跳过每条鱼等待时间」经源码+实机分析判定**不可行** — 咬钩等待由服务器端定时器控制, 客户端无加速/跳过接口 (Fishing:FireServer 仅抛竿/收竿两动作, 鱼饵 Luck 只影响稀有度不影响等待). 详情见 devlog 会话53

## v0.15.2 — 2026-08-27
- feat: 目标鱼过滤支持多选 — Dropdown 改 Multi=true, 可勾选多鱼只钓其一 (集合匹配, 英文鱼名存储); 过滤判断/通知同步
- 分析: 「虚空钓」(假坐标钓远程海域) 经实机发包测试判定**不可行** — 服务器忽略包内 CFrame, 按玩家 HumanoidRootPart 实际位置判海域 (发霜冻岛坐标 3445 格远, 仍回推玩家脚下战场岛鱼)。详情见 devlog 会话52

## v0.15.1 — 2026-08-27
- feat: 目标鱼列表与放弃通知全面汉化 + 岛屿前缀 — 新增 FISH_ISLE_MAP (运行时读 Info.FishingAreaRarity 构建, 109 鱼全覆盖), 目标鱼过滤下拉列表格式「岛屿-鱼名」(岛屿与鱼名均汉化, 如「椰子岛-绯红战鲤」「秘密Boss-穿天龟」); 目标过滤放弃原因同步显示带前缀鱼名
- fix: 目标鱼列表只列鱼 (过滤掉 Inventory 中的竿/饵模块, 以 FishingAreaRarity/Fishes 为准)
- dbg: 新增 fishLabels 接口 (验证列表汉化用)

## v0.15.0 — 2026-08-27
- feat: 智能回正独立开关 — 原漂移修正增强为「位置+朝向双还原」(记录抛竿瞬间完整 CFrame, 漂移超 10 格拉回并还原朝向), 可关闭 (Flag: smartReturn, 默认开)
- feat: 目标鱼过滤 — 选一种鱼后只钓它, 其他咬钩自动放弃 (刷任务鱼/限定鱼专用, Flag: targetFishFilter/targetFishSel)
- feat: 天气预报整合进自动钓鱼 Tab — 新增「天气预报」Section 收拢 天气稀有鱼提醒 + 关注天气选项 (原独立区块)
- feat: 快捷传送新增「天气渔场」按钮 — 一键传送到当前天气对应的稀有鱼岛屿; 当前天气无特殊鱼 (Clear/Rainy/未映射) 仅通知不动作
- feat: 效率统计重做 — 独立 statsTick 心跳 (2s 常挂, 不受自动钓鱼启停影响), 分「挂机总时长/垂钓实际时长」双指标, 条时率按实际垂钓时长计算 (长时间挂机不稀释效率)
- fix: 自动钓鱼 Tab 排版重组 — 战斗策略 Section 收拢 自动Perfect→自动技能→技能释放模式→自动蓄力→蓄力时长→智能回正→智能放弃
- fix: 蓄力技时长 Slider 加 Flag (chargeDuration) — 修复此前无 Flag 不持久化、重注入后丢失的问题
- 注: 目标鱼过滤的鱼名列来自 Info.Inventory 模块名 (英文) + 中文映射; 若图鉴名不匹配需反馈校准

## v0.14.0 — 2026-08-27
- feat: 快捷传送新增「传送至服务器玩家」— 下拉列出在线玩家 (除自己, 显示名+用户名), 选人后传送到其身旁; 含刷新列表按钮
- feat: Tab 侧栏重排 — 自动钓鱼→鱼饵管理→背包管理→恩佐BOSS→快捷传送→玩家→快捷键→设置 (LayoutOrder 覆盖, 实测生效)
- feat: 持久化规则 — 除「自动钓鱼」与「恩佐BOSS·自动战斗」外全部开关经 ConfigManager 持久化自动恢复; 这两项**不设 Flag 不持久化**, 注入强制关闭 (严格从关闭态起步防误触)
- rename: 恩佐BOSS Tab 开关「恩佐BOSS自动战斗」→「自动战斗」; 通知文本同步「恩佐BOSS·自动战斗」
- fix: 快捷传送原「传送不可用」分支 (无 Spawnpoint 时) 不再覆盖玩家传送区块 (玩家传送独立于岛屿/NPC 区块)

## v0.13.4 — 2026-08-27
- feat: 功能开关全量通知 — 新增统一 notifyToggle 辅助函数, 13 个 Toggle 开关 (自动钓鱼/自动出售/自动技能/自动买饵/自动Perfect/自动蓄力/智能放弃/天气提醒/智能锁定/保持奔跑/移动加速/防踢心跳/恩佐BOSS) 开启与关闭均弹清晰通知 (标题+图标+已开启/已关闭), 快捷键切换同链路统一
- fix: 严重 Bug — hookmetamethod 挂 StartBossFight 共享元表污染游戏 UI 点击链路 (注入后点竿/背包失效); 已彻底移除 hook, Boss 战检测改用 workspace.Fishes 战斗实体 Boss=true 属性 (零 hook 纯属性)
- fix: 恩佐BOSS 顶部鱼条恢复锁居中 (enterFight 控条), Boss 战豁免 fightGui.Visible 检查
- 逆向: [已证伪] Boss 战不走 FishingMinigame 协议 (入站 0 次), 但顶部条 = BarFrame.Bar 纯客户端控条, 与协议无关

## v0.13.3 — 2026-08-27
- feat: 新增「恩佐BOSS」Tab — 恩佐BOSS智能小游戏自动战斗模块 (用户手动开战, 脚本全自动接管全流程)
  - 自动放技能 Z/X/C/V (autoSkillTick 复用, Phase1 纯技能 DPS)
  - 加血QTE = Slam/Heal 类 PerfectButton 自动 Perfect 覆盖 (Slam handler 扩展为匹配 Slam/Heal/Perfect/QTE 按钮)
  - Phase2 点击小游戏: 服务器信任 BossPhase2Action{Hit=true} 标志, 循环发命中即必胜
  - FinalPhase 节奏小游戏: 监听 RhythmStart, 音符临近判定线发 RhythmHit("hit")
  - 与自动钓鱼互斥: 开启 BOSS 自动关钓鱼, 开钓鱼自动关 BOSS
- fix: 实机失效修复 — [已证伪] BOSS 主阶段复用钓鱼小游戏 (FishingMinigame 入站 0 次); 改 StartBossFight 发包 namecall hook 做 Phase1 检测信号, 结束判定改「中段信号消失 8s」模型 (修 bossFightRunning 永不复位死锁)
- 逆向: Boss 战协议全破解 (StartBossFight / BossPhase2Action 信任标志 / RhythmStart-RhythmHit / HealingSlam QTE)
- 注: Phase2/Rhythm 的 GUI 路径与服务器契约为实机验证项 (devlog 待校准)

## v0.13.2 — 2026-08-25
- enhance: 首发零延迟 — 去掉开场观察期 (1.5~3s 人为延迟), 改由 SkillLocked 属性自然拦截游戏 3 秒倒计时; 倒计时结束瞬间即首发 Z, 输出窗口零浪费

## v0.13.1 — 2026-08-25
- fix: 顺序模式首轮倾泻后误切 DPS 择优 — 补刀阶段选择策略改为跟随当前模式 (顺序=游标循环轮转 / 智能=DPS 择优), 整场语义一致

## v0.13.0 — 2026-08-25
- rework: 自动释放技能大修 — 两阶段模式: ①开场倾泻 (无条件按 Z→X→C→V 把已装备且冷却好的技能放一轮, 不看定身/无敌/血量任何过滤) → ②自由补刀 (哪个 CD 转好放哪个, DPS 择优)
- refactor: 删除首发等待/超时降级/分类过滤整套旧机制 (firstRoundCursor 游标替代); Charge 蓄力技保留自动延迟结算
- 实测: 决策日志确认倾泻序列正常

## v0.12.x — 2026-08-25
- fix: ESC 取消绑定不生效 — WindUI Keybind 捕获态按 ESC 被内部吞掉 (标准取消捕获行为), Callback 永远收不到 Escape; 改为每个快捷键配独立「✕ 清空」按钮, 直接清除绑定
- 布局: 快捷键 Tab 每功能一组 (Section 标题 + 清空按钮 + 绑定按键), 冲突检测保留

## v0.12.0 — 2026-08-25
- feat: 新增「快捷键」Tab — 8 大功能键位绑定 (切换钓鱼/技能/出售/Perfect/蓄力/锁定 + 立即出售/扫描锁定), 默认无绑定, 绑定 ESC 即取消, 冲突检测
- feat: 天气提醒改选择模式 —「关注哪些天气」多选 Dropdown, 只提醒选中天气; 通知全面中文化
- feat: 鱼名 109 种全量中文翻译 (钓获/锁定通知); 传送岛屿/NPC/鱼饵列表中文化
- fix: 「传送到选中岛屿」Callback 内嵌错位代码清理

## v0.12.6 — 2026-08-25
- feat: 游商传送与提醒 — 「传送至当前游商」按钮实时定位 MerchantNPC (随机刷新卖限定功法/竿); 游商上线自动大字提醒含商品名
- 逆向: 游商系统 = workspace attribute MerchantNPC/MerchantItem 服务器推送, NPC 刷在 workspace.NPC.Function 下; 小道士(Xiao Daoshi)/老道士系游商中文名, 非卖竿 NPC
- fix: 传送按钮内嵌错位等结算代码清理 (历史编辑事故)

## v0.12.7 — 2026-08-25
- fix(P0): **配置 Flag 冲突总根源** — 快捷键 Keybind 与主功能 Toggle 共用 Flag, Keybind 存按键名字符串覆盖 Toggle 布尔值 → 注入恢复错乱/设置丢失/UI 不同步系列问题的总祸根; 快捷键全部改独立 hk_ 前缀 Flag
- fix: 清除被污染的旧配置文件全新重建; 全部 30 个 Flag 唯一性验证通过

## v0.12.8 — 2026-08-25
- fix(P0): 自动出售关闭态仍可能误触发 — autoSellCheck 缺 autoSellOn 守卫; 顶部加 `if not autoSellOn then return false end` 早退 (P0-1)
- fix(P0): 智能放弃后重抛死循环 — 断条出界未等服务器清场即重抛; 新增「等结算」状态消费 giveUpDeadline (P0-2)
- fix(P1): Charge 蓄力结算跨场漏结算 — firstRoundCursor==nil 条件竞态; 抽 scheduleChargeSettle 统一两阶段结算 (P1-3)
- refactor(P1): 删除死代码 categorizeSkill/skillCatCache (零调用方) + 修错误时机注释 (P1-4)
- fix(P1): 声明顺序脆弱性 — keepSprintOn 等玩家状态变量上移至状态区, 消除 Heartbeat/UI 回调声明顺序依赖; 移除重复 lastSeenFishId (P2-6/P1-5)
- fix(P2): 自动出售双重调用 — autoSellCheck 同时寄生主钓鱼循环与独立 autoSell 循环; 移除主循环内调用, 出售判定完全归独立循环 (P2-8)
- enhance(P2): isInventoryFull/sellFishCount 加 2s 缓存, 降每帧轮询 pcall 开销 (P2-7)
- enhance(P2): 移除锚点漂移修正 task.wait(0.15) 硬等待, 降低延迟 (P2-9)
- refactor(P2): dbg.state 移除死字段 firstCastKey/fightFirstCastDone (P2-10)
- feat: 注入即强制关闭自动钓鱼/自动卖鱼 — 每次注入从关闭态起步, 防误触自动跑 (用户要求)

## v0.11.4 — 2026-08-25
- feat: 钓点锚位系统 — 长时间钓鱼被鱼拉扯导致位置逐渐离岸、鱼竿甩不到海; 现在首竿记录锚位, 漂移超 10m 自动拉回再抛竿
- fix: 移动加速"无效"根因 — 游戏实际奔跑速度为 36 (非假设的 24), 默认目标值低于当前速度导致条件永不满足; 滑条范围 20~120 默认 50, 开启时立即生效
- enhance: 保持奔跑基准开启时立即采样; 传送按钮增加等结算态拦截
- 逆向: WalkSpeed 客户端脚本零引用, 走/跑/战斗锁全部由服务器属性复制 — 每帧写回是唯一有效路径

## v0.11.3 — 2026-08-25
- feat: Charge 蓄力技能支持 (切断大门/Sever the Gate 系) — 机制逆向: 释放后蓄力, 伤害 = 面板Damage × 蓄力秒数 (Charge 模板 Slam 公式实测); 释放后自动蓄力 N 秒 (滑条可调, 默认15s) 然后代发动态 remote 结算
- fix: autoCharge 与技能蓄力冲突 — 抛竿蓄力按钮和技能蓄力共用 Events.Charge, 蓄力保留期内禁止 autoCharge 干预避免把技能蓄力瞬间结算掉 (伤害≈0 的根因)
- enhance: 决策日志记录蓄力开始/结算事件
- 逆向: Charge 模板全读 (155 行) — Slam() 结算公式/MaxCharge 自动结算/UsingSkill 互斥/CD+5 惩罚

## v0.11.2 — 2026-08-25
- fix: 注入即卖鱼 — 新增 90 秒启动宽限期, 注入后不立即触发自动出售 (给用户检查配置的时间)
- feat: 智能锁定新增「合成材料鱼」规则 — Mythical 饵配方全量解析 (Info.Bait[x].Ingredient): 冰霜饵=升华鲈鱼/霜王翠鸟/太初鲲皇/战鲨; 无名饵=幻影灯笼鱼/高山鱼/章寄鱼/虎沼鱼; 彩虹饵=巨型虎鱼/赤雷鳗/黄金守护鱼/穿天龟; 锁定通知标注用途
- enhance: 价格显示全面 M/K 单位化 (fmtNum: 1.5M/230K, 与游戏内 KG 显示同款) — 钓获价格/出售收入/效率面板
- 实测: 宽限期生效, 天气检测 Rainy 正确跳过未关注项

## v0.11.1 — 2026-08-25
- fix: 钓获通知鱼名英文 — 翻译表只覆盖 45 种, 游戏有 109 种; 全量补齐 (按游戏命名规律系统翻译: 颜色前缀/系列后缀/长老-成年-幼年梯度)
- enhance: 防踢升级为真实跳跃 — 非战斗状态每 4 分钟模拟空格键真实跳跃一次 (角色动作+输入事件双重活跃信号), 战斗中退回 F15 无害键避免干扰站位
- 实测: 天气检测日志确认关注列表过滤正常

## v0.10.1 — 2026-08-25
- feat: 新增「玩家」Tab — 保持奔跑 (Ctrl 误切走路自动切回, 自适应奔跑基准) + 移动加速 (目标速度滑条, 仅放大不缩小, 不破坏战斗锁零)
- fix: 技能动画残留 — 战斗结束自动停止角色全部 AnimationTrack 并清定身/无敌脏状态 ("鱼钓上来马上恢复状态")
- feat: 首发等待超时降级 — Z 槽长 CD 跨场残留 (实测 Beastbreaker 32s 冷却跨场) 时最多等 5s 即按序释放, 不再干等半分钟; 决策日志记录降级事件
- 分析: 抛竿分支逆向确认无动画检查 (仅背包/Fishing attribute), 动画影响为视觉+服务器侧; Ctrl = ToggleSprint:FireServer 服务器权威翻转

## v0.9.1 — 2026-08-25
- enhance: 重抛提速 — 场间冷却 1~2.5s → 0.5~1.2s (人类速抛玩家真实区间); 主循环周期 0.5s → 0.4s 缩短事件对齐损耗; 等结算回待机同步提速
- 量化: 每轮切换开销 ~2.25s → ~1.2s, 快节奏连钓场景效率 +3~7%
- 实测: 决策日志确认跨场残留清理与首发序列持续正常

## v0.9.0 — 2026-08-25
- feat: 防踢心跳 — 每 4 分钟模拟一次 F15 按键 (OS 级输入, 游戏无绑定零干扰) 重置引擎闲置计时; 窗口失焦时跳过; keytap 能力探测不存在则降级
- feat: AutoExec 自动恢复启动器 — 被踢重连后自动加载脚本, 配置持久化恢复各开关状态, 长时间挂机断线不再需要人工干预
- 背景: 用户报告长时间挂机会被重进服务器 (引擎级闲置断线, AFK 包无法重置其计时, 唯真实输入有效)

## v0.8.2 — 2026-08-25
- fix(P1): 锁定竞态 — 钓上任务鱼瞬间恰触发出售会在 0.9s 锁定延迟窗口内把鱼卖掉; 名字级规则(上交/钓捕目标)改为入库瞬间抢先锁定, 仅重量/价值类保留延迟判定
- fix(P1): 满仓全锁死锁 — 背包被锁定鱼占满时自动出售空转循环卡死钓鱼; 现在识别"全是锁定鱼"并提示人工处理
- enhance: 出售阈值滑条上限 50→400; scanAndLock 每 10 条 0.3s 限流; 删除死代码 getFishPrice
- verify: 脚本内计数与独立复刻交叉验证一致 (limit 动态跟随)

## v0.8.1 — 2026-08-25
- fix: 主 Tab「战斗策略」Section 重复渲染两次 → 删除冗余
- feat: 快捷传送新增「功能 NPC 传送」— 扫 workspace.NPC 全部交互 Model (含 Function 子层) 去重得 27 个目标 (门票任务/学技能/买竿/买饵/卖鱼/Boss 入口/God 祈祷等), 落点 = NPC 前方 4 格面向交互位
- verify: 「背包装满」修复后长时复验 — 鱼数 13→39 持续积累零误卖 ✓

## v0.8.0 — 2026-08-25
- feat: 新增「背包管理」Tab — 自动出售板块自主 Tab 迁移至此
- feat: 智能锁定 — 数据源为 Info.MainQuest 全量 22 任务线解析, 三类规则:
  - 任务上交鱼 ×6 (GiveFish: Trueform Jiaolongfish/Ascended Perch/Glorious 系/Valentine Dolphin)
  - 任务钓捕目标 ×6 (FishingSpecific)
  - 任务重量挑战鱼 ×13 (SpecficFishWithAnAmountOfWeight, 含最低重量判定, 价格反推重量留容差)
  - 另支持价值锁定 (单价≥阈值自动锁) 与「立即扫描现有背包」按钮
- fix: 锁定协议实测 (FavoriteItem:FireServer(项名) → Name 追加 " | Favorite")
- 注: 任务 Objective 类型共 12 种全枚举入档

## v0.7.2 — 2026-08-25
- fix: 「背包装满」模式失效 — 字符串匹配漏洞: "背包装满"不含数字, match 静默回退固定数量模式(50条)导致未满就卖; 改为直接复用 isInventoryFull() 与抛竿前满仓判定完全同源 (含 Hotbar 占位)

## v0.7.1 — 2026-08-25
- fix(P0): playerData 为 nil 时 FishingRod.Changed 裸连接崩溃 → 关键对象校验补全
- fix(P0): 重生瞬间 ch.Stats 缺失致 autoSkill 循环异常 → 安全访问
- fix(P1): 智能放弃死循环风险 — doGiveUp 立即回待机会在服务器清场前重抛; 新增「等结算」状态 (断条出界后等 FishID 清空/面板关闭, 8s 兜底超时)
- fix(P1): 「停止全部功能」按钮只杀循环不重置开关变量, UI 与实际状态脱节 → 同步重置
- fix(P1): autoBait 慢循环告警根因 = InvokeServer 同步 RTT 卡 tick → task.spawn 异步化
- style: 战斗进度显示块缩进对齐

## v0.7.0 — 2026-08-25
- feat: 出售时机可选 — Dropdown「固定数量 / 背包80% / 背包90% / 背包装满」, 百分比模式按 InventoryLimit 实时计算触发线, 上限升级自动跟随
- 背景: 用户背包上限已 350, 固定数字阈值不再合身

## v0.6.5 — 2026-08-25
- fix: 顺序模式首发漂移最终根治 — autoSkillTick 自治检测 FishID 变化 (不依赖主循环先跑跨场重置, 消除双循环相位竞争)
- feat: 技能决策环形日志 (dbg.decisionLog), 时序逻辑全程可追溯
- 实测: 三连场首发 Z→Z→Z 全部正确 (第三场监控探针漏记系采样盲区, 决策日志证实已放)

## v0.6.1 ~ v0.6.4 — 2026-08-25
- fix: 顺序释放模式首发不稳定 (首放 Z→X→C 漂移)
  - v0.6.2: 游标跨场连续轮转 (用户否决, 要求每场从 Z 起)
  - v0.6.3: 首发约定 — 第一发必须是首个装备槽, 未就绪就等不顶替
  - **v0.6.4 根因修复**: 跨场快速衔接 (上一场结束到新咬钩 < 主循环周期) 时状态机来不及回待机, enterFight 未执行 → 首发标志/游标继承上一场。改为 FishID 变化检测强制重置战斗状态 + 决策环形日志 (dbg 可观测)
- 实测: 决策日志确认 Z(首发)→X(轮转)→C(轮转) 完整序列 ✓

## v0.6.0 — 2026-08-25
- feat: 自动技能双模式 — 「智能择优」(DPS 最高优先, 默认) / 「顺序释放」(Z→X→C→V 固定轮转); 主 Tab Dropdown 切换并持久化
- 实测: 顺序模式首放 Z (键位序第一) ✓

## v0.5.6 — 2026-08-25
- fix: 移除 C 槽键位一刀切跳过 — 槽位≠技能类型 (C 槽装定身/直伤技被误跳过导致"不首先释放天堂的负担"), 四槽一视同仁参与择优; 实战监控证实修复前 C 槽全程未放

## v0.5.5 — 2026-08-25
- fix: 技能分类误判 — 多效果技能 (如 Heaven's Burden 的 stun+heal+damage) 被 heal 关键词误归治疗类导致血满时不放; 分类顺序改为 stun > damage > heal, 只有纯治疗描述才归 heal
- enhance: 技能排序加入冷却因子 (总伤指数÷CD = DPS 视角) — 实测 Heaven's Burden(6.67) 正确登顶, 与实战体感一致
- fix: 鱼饵 Dropdown 加 Flag 持久化, 饵种选择重启脚本不再丢失

## v0.5.4 — 2026-08-25
- fix: 技能择优误判 — 面板 Damage 是单跳基数不代表总伤; 改为总伤指数 = (Damage+SecondDamage) × Duration ÷ 跳间隔(SlamTime 字段, 无则1s) × 暴击期望
- 实测: Phoenix Strike Art V2 (5×8/0.5=**80**) 正确压过同面板的 Heaven's Burden (50) 与 Taijiquan (20) — 旧逻辑把 Z/C 判平手随机放

## v0.5.3 — 2026-08-25
- enhance: 自动技能多伤害技能择优 — 爆发队列按面板期望伤害降序取最高 (Damage+SecondDamage 计入暴击期望), 不再随机; 同伤随机打破平手
- 实测: 当前配装 Phoenix Strike Art V2(Dmg5) > Taijiquan Technique(Dmg2), 排序正确

## v0.5.2 — 2026-08-25
- fix: 自动售鱼跳过锁定的鱼 — 锁定标记 = 鱼 Name 后缀 " | Favorite" (FavoriteItem 协议); 可售计数只统计未锁定鱼, 锁定的不卖不计入阈值
- 注意: 出售仍走游戏自身 SellFish("All") 按钮 — 若发现服务器连锁定鱼一起卖请反馈 (设计意图应跳过)

## v0.5.1 — 2026-08-25
- refactor: 自动买饵改水位线策略 — 库存降到阈值(默认2)以下才小批买入(默认2个), 用几个补几个不囤货; 原"见底买20个"改为两参数可调
- fix: 水位线边界 <= 改 < (买入后恰好等于阈值会连环补货)
- 实测: 消耗至剩2不误购 / 低于水位线自动买+装备回执正常

## v0.5.0 — 2026-08-25
- feat: 智能放弃 — 力量比 rodPower/fishPower <0.3 开场判弃 / 开战10s后进度停滞12s 判弃 / 单场180s 超时兜底; 放弃动作 = 条主动出界走游戏自身 "Out of bar" 失败流程 (与人类脱杆无异)
- feat: 自动买饵 — 鱼饵管理 Tab: Dropdown 列出全部可购 Normal 饵 (含单价+Luck) + 补货数量 Slider; 流程 = 无存货自动买 + 未装备自动装; 独立循环 5s 节流
- 实测: BuyBait("Crude Mash Bait",5) 扣款 ¥50000 精确 + EquipBait 回执 true 自动装备

## v0.4.1 — 2026-08-25
- fix: 技能释放太晚 — 开场观察期 4~6s 缩至 1.5~3s; 分类优先级重排 (伤害/定身/增益为爆发队列绝对优先, 治疗不插队); 开场 8 秒内连发间隔收紧至 0.4~1s (人类开局本就是技能全交), 后期恢复保守节奏
- 实测: 首次施放 6.3s → 3.6s; 4.8s 速杀局也能吃到定身跳伤 (旧逻辑下短战斗直接空过)

## v0.4.0 — 2026-08-25
- feat: 效率统计面板 — 运行时长/捕获条数/现金收入/条每小时/现金每小时/战斗场次 (现金走差分统计, 全收入来源覆盖)
- feat: 快捷传送 Tab — Dropdown 选岛 + 一键传送, 与游戏自身传送同款本地 CFrame 路径; 岛屿列表运行时读取自动跟随更新; 战斗中拦截
- 分析: AFK 系统机制摸清 (收益未证实暂不联动)
- 实测: Amber Isle 往返传送成功; 统计面板随主循环刷新

## v0.3.0 — 2026-08-25
- feat: 自动技能 (智能施放) — 战斗中按鱼竿装备的 Z/X/C/V 技能自动施放; 非无脑 CD 好就放:
  - 定身类: 自己已在定身跳伤中不重放 (避免双开浪费+CD+5 惩罚)
  - 治疗类: 血量 >70% 不放留救命 (用后 CD+5 惩罚)
  - 增益类: 鱼 Iframe 无敌期间照放; 直伤/定身类无敌期跳过
  - C(Slam) 未开自动 Perfect 时跳过 (防小游戏超时报 Bad)
- feat: 多技能就绪随机挑一 + 0.8~2s 人类化连招间隔 + 开场 4~6s 观察期
- 实测: Skyfall Stomp 全链路 (施放→服务器受理→定身跳伤→CD 递减→归零再放)
- 分析: 技能系统全量归档 intel.md (84 技能/15 实现模板/四键槽制/冷却权威/Iframe/Stun 机制)

## v0.2.1 — 2026-08-25
- fix: 自动出售不触发 — 根因1: 出售检查寄生在自动钓鱼循环内, 主开关关闭时出售永不执行 → 独立 StartLoop("autoSell", 2s), 可单独使用
- fix: 阈值 Slider 无 Flag 不持久化, reload 后回默认值 20 → 加 Flag="sellThreshold" + 回调数字类型防御
- 实测: 阈值5 + 背包12条 → 自动全卖到账 (+2768 Cash)

## v0.2.0 — 2026-08-25
- feat: 自动出售 — 背包鱼数达到阈值 (Slider 默认 20) 即任意位置全卖 `SellFish("All")`; 背包满时自动卸货无缝续钓; 附"立即出售"手动按钮
- feat: 钓获通知 — Inventory.ChildAdded 事件驱动, 上钩即提示鱼名·价格
- enhance: 战斗状态显示击杀进度百分比; 背包满提示引导开启自动出售
- refactor: 出售逻辑集中 doSellAll (10s 节流), dbg 接口扩展 setSell/sellNow

## v0.1.0 — 2026-08-25
- feat: 自动钓鱼 (Tap 完美) — 抛竿/咬钩检测/锁条打鱼/自动重抛全循环状态机 (0.5s 轮询 + Heartbeat 锁条, 默认 ±15% 时序抖动)
- feat: 自动 Perfect — Slam 小游戏自动上报 Perfect 并销毁按钮防 2.1s 超时误报 Bad
- feat: 自动蓄力 — Charge 小游戏自动确认
- feat: 设置页标配 (DEL 显隐 / END 卸载确认 / 停止全部)
- 架构: 状态机启停逻辑集中 setAutoFish, UI Toggle 与调试口共用; 战斗连接走 OnCleanup 登记
