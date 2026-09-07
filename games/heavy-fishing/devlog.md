# 开发手册 — 重型钓鱼

> 接手 AI 从这里恢复上下文: 读最新条目 = 当前状态 + 决策 + 遗留。

---

## [2026-09-03 | Potassium 反作弊侦察]

用户问底层有没有会封号的检测。Potassium pid=23420 / pv2929: 元表全 C、无 nil AC 脚本、Events 无踢封命名包; Remotes 管理接口全 NO_PERMISSION。风险面写进 intel「关键机制结论」。

---

## [2026-09-03 | v1.2.8 混淆推送]

`publish.py --game heavy-fishing --push` 打单文件混淆包, 不推白名单. Loader 清单版本从旧 1.1.3 升到 1.2.8.

---

## [2026-09-03 | v1.2.8 绿条内才发包]

用户要求二阶段指针不在绿条内不许 FireServer. 删 0.7s 保底; 判定 |条心-框心| <= 半宽; 进绿才打, 冷却约 0.3s.

---

## [2026-09-03 | v1.2.7 二阶段复活]

### 原因
1.2.6 进绿心还要等 70~170ms, 快条已经离开 → 反应被清零, 一发都不出. 只认 Phase2 属性 / 注入时缓存的 Bar.

### 改
进区立刻 Hit=true; 容差放到框宽*0.72; 条 Visible 也开驱动; 0.7s 保底; 每 tick 失效则重找 GUI.

---

## [2026-09-03 | v1.2.6 丝滑手感]

### 改动
用户要真人手感. 快条: 游戏同款 Linear +0.1/0.05s, 点间隔 0.08~0.12, 出界才短拉. 二阶段: 刚进绿心 → 70~170ms 反应 → Hit=true + 游戏同款晃 Fishing + 50ms 后换框; 出绿心才允许下一发.

### 验证
待打恩佐: 条有起伏不瞬移; 二阶段一看一个准、有晃、框跳、不扣血

---

## [2026-09-03 | v1.2.5 二阶段降暴力]

### 改动
用户反馈 1.2.4 二阶段 0.14s 必中太凶. 改为: 画面条进绿心 → 反应延迟 → 发包 Hit=true → 0.5~0.85s 才许下一发. 仍不走 onClick.

### 验证
待再打恩佐: 绿框换得像人点, 不扣血, 不像机关枪

---

## [2026-09-03 | v1.2.4 恩佐控条+Phase2]

### 问题
恩佐快条经常掉红; 二阶段点绿心经常扣血。

### 决策
- 快条/恩佐: RenderStepped, 绿区短 tween (+0.12/0.03s), 不用点鼠标+反应延迟
- Phase2: MinigamePhase2 onClick 用内部三角波, 画面重叠也会 Hit=false。停掉 sendHumanClick, 0.14s 发 Hit=true+Index 并本地挪框
- 普通鱼仍走真人点条

### 验证
待用户再打恩佐: 条应停在绿心附近; 二阶段无红闪扣血 (可以没有晃动)

---

## [2026-09-03 | v1.2.3 热路径减负]

### 改动
- 奔跑 Heartbeat: 两开关都关直接 return
- 恩佐: `BossSetUp.Enzo` / `workspace.NPC.Enzo` 缓存, 失效再找; 不再每 0.4s `FindFirstChild(..., true)`
- `autoFishTick` 开头调 `bossDetectTick`, 去掉独立 `bossDetect` 循环
- 控条 Heartbeat 缓存 Bar; 点条坐标 2s 内复用
- 假称号 `fakeTitleKeep` 2s (仍 CharacterAdded 补刷)
- Phase2: `GetAttributeChangedSignal("Phase2")` 才挂 RenderStepped
- 竿力: 技能用 `getRodBuffPower`, 放弃用 `getEquippedRodBasePower`
- 删 `StopLoop("bossRhythm")`; `stopFight` 仍断节奏 Heartbeat

### 验证
- 待热跑: 看启动无 200 寄存器; 开关关着不空转; 恩佐/控条/节奏手感与 1.2.2 一致

### 遗留
- 玩法三件套仍待实机: 普通鱼回弹、恩佐晃动换框、无名章寄 EXP 闪光

---

## [2026-09-03 | v1.2.2 注入卡在 200 寄存器]

### 做了什么
`loadstring(hub)` 报 `:4334: Out of local registers ... applyTitle ... limit 200`。先把虚假信息整段收进 `buildFakeInfo()`, 不够 (嵌套 `local function` 仍占父函数寄存器); 再把假称号状态机收进 IIFE `T = (function() ... end)()`。玩家移动 UI 收进 `buildPlayerMovement()` 并在设置页前闭合调用。

已同步到 `%LOCALAPPDATA%\Potassium\workspace\games\heavy-fishing\hub.luau`。

### 遗留
钾 `execute_script` 在上次 compile fail 之后一直 `console_cursor=291` 且不再出新日志/`writefile` 也不落盘。通道疑似卡住, 需要用户在钾里手动重跑 `games/heavy-fishing/hub.luau`, 或重连客户端后再让 AI 注入。

### 踩坑
- [do...end 减局部] → [do 不新开函数, 寄存器仍算主块] → [拆成 `local function` / IIFE]
- [只包一层 buildFakeInfo] → [内部一堆 local function, 父函数仍爆 200] → [称号再拆一层闭包]

---

## [2026-09-03 | v1.2.2 MCP 实机核对]

### 结论 (pv2929, ClientModule.Fishing + MinigamePhase2)
- 控条: 战斗中 MouseButton1 **不看 processed**, `Bar +0.1 / 0.05s`。我们点空白再点条, 路径对; 出界保命 tween 仍需要(失焦)。
- 恩佐二阶段: 晃动是抖整个 Fishing GUI 0.25s, 只在 onClick 命中。点绿心走真点击是对的; 兜底发包没有晃, 符合源码。
- 章鱼节奏: **1.2.1 直接发包是错的**。TryHit 必须按 ASD; 空按/漏过会 miss 扣血。已改过线按键, 不再 FireServer。

### 遗留
- 聊天框开着时按键可能被吞
- 恩佐点被吞时仍无晃动
- 待实机: 无名章寄二阶段看 EXP 闪光、不扣血; 普通鱼控条回弹; 恩佐命中晃动

### 踩坑
- [节奏只 FireServer hit] → [游戏内部表还在, Heartbeat 再发 miss] → [只按 ASD 让 TryHit 删表+发包+特效]

---

## [2026-09-03 | v1.2.1 章鱼二阶段节奏]

### 需求
用 MCP 分析章鱼 BOSS 二阶段并优化。钾 MCP `127.0.0.1:7891` 连不上, 按 intel 已验证 Rhythm 协议改。

### 决策
章鱼二阶段 = `RhythmStart` ASD 三轨, 不是恩佐 BossFightBar。旧打击两个问题: StartLoop 50ms+默认抖动对不齐过线; `|d|≤0.15` 没过线也点 → Perfect 少。改 Heartbeat, 只打已过线且偏离 ≤0.10 的音符, Y 走锚点中心。不模拟 ASD 键防双发。

### 验证
- 未热跑 (MCP 未就绪)
- 待用户: 钓无名章寄进二阶段, 看 Perfect 变多、不漏后面几波

### 踩坑
- [StartLoop 打节奏] → [50ms 下限 + 默认 ±15% 抖动, 过线帧对不齐] → [节奏用 Heartbeat/RenderStepped, jitter=false]
- [没过线就 RhythmHit] → [Good/Miss, 一眼脚本] → [y>=line 才发, 迟到窗 < 音符间距]

---

## [2026-09-03 | v1.2.0 控条真人化 + 恩佐二阶段晃动]

### 需求
控鱼条不要一眼脚本; 恩佐二阶段每次点击要有原本晃动。

### 决策
- 控条: 去掉 0 时长 Tween 钉死。Heartbeat 只读条位, 落到 [0.43,0.50] 随机阈值后真点击, 让游戏 +0.1/0.05s 回弹。条 >0.532 不点(防 +0.1 出绿区)。90ms 内条没往上走则补同款 tween。出界才 0.08s 拉回。Phase2/节奏期间不点这条。
- 二阶段: 回到 onClick。根因是 (10,10) 点在顶部条上 processed=true, 动画和判定都被吞。落点改视口中下部无 Active GUI。只在绿心 (框宽×0.32, 条很快时 0.50) 点。100ms 绿框没动才 FireServer 兜底。驱动改 RenderStepped, 去掉 0.1s StartLoop。

### 验证
- 静态: 见本次改动片段; 注入器 MCP 本会话不可用, 未热跑
- 待用户: 普通鱼看条在绿区晃、不是钉死; 恩佐二阶段看命中晃动和绿框换位

### 遗留
- 窗口失焦时 VIM 点击可能无效, 控条走 tween 兜底, 二阶段走发包兜底(无晃动)
- 全屏 Active GUI 时安全落点可能找不到, 会退回角点

### 踩坑
- [点屏幕左上角自动化] → [顶部 GUI 吃掉点击, 没动画还可能 Hit=false] → [GetGuiObjectsAtPosition 找视口中下部空像素]
- [0 时长 Tween 锁条] → [条钉死一眼脚本] → [走游戏点击 +0.1 回弹, 只做出界保命]

---

## [2026-09-03 | v1.1.3 界面收简介]

Toggle/Dropdown/Button 上能从标题看懂的 Desc 全删; 去掉「自动买饵」「渔场传送」两段纯介绍 Paragraph。保留: 运行状态/效率、锁定规则统计、分组会清空勾选、解锁规则锁范围、NPC 最近合并、键位说明、匿名/假称号细节、防踢、速度警告。

---

## [2026-09-03 | v1.1.2 视角锁]

Rayfield `mouseOverride` 开着会一直把 MouseBehavior 掰回 Default, 和游戏 Shift 视角锁打架; 引擎藏窗还强行 LockCenter, Shift 关不掉。

lib v2.0.6: 关掉持续抢鼠标; 开菜单只松一次鼠标方便点 UI, 关掉还原进菜单前的状态。

---

## [2026-09-03 | v1.1.1 黑金主题发布]
- 跟随 lib v2.0.3 打混淆包并推 Gitee; 玩法未改

## [2026-09-03 | v1.1.0 品牌方圆标]

### 改动
- 跟随 lib v2.0.0: 所有小图标用用户提供的方+圆标志, 不再用 Rayfield/lucide
- 默认 UI 已是 Rayfield, hub 不再写 UiKit

---

## [2026-09-02 | v1.0.0 Rayfield Gen2 换皮]

### 用户需求
不用 WindUI, 试 Rayfield Gen2 重构重型钓鱼界面, 兼顾手机电脑.

### 决策
- lib v1.9.0 增加 `UiKit="rayfield"`, 业务控件仍写 WindUI 形参 (Title/Callback/Flag/:Refresh)
- 其它游戏默认 WindUI, 不跟着迁
- 快捷键改绑走 `OnChanged` (Gen2 的 Callback 是「按下已绑定键」)
- 库自带显隐默认 K, 我们改成 F13, 设置页 DEL 全权显隐, 避免按一次闪两次
- 旧版备份 `archive/hub-v0.31.1.luau`

### 验证
- 实机热替换看窗口是否出现、Tab/开关/下拉/通知/卸载确认

### 遗留
- lucide 图标 Gen2 不认数字 ID, 当前 Tab 无图标
- 配置目录变成 Rayfield/Configurations, 与旧 WindUI 配置不互通
- 未发 Gitee (先实机看)

---

## [2026-09-02 | v0.31.1 Loader 注入后窗口可见]

### 改动
- ScriptVersion 0.31.1, 发布包内嵌 lib v1.8.3 (CreateWindow 后再 hideForeign + ensureOwnWindUiEnabled)
- 无玩法改动; 为修 Loader 注入后 WindUI 层保持 Disabled

### 遗留
- 需 `publish.py --game heavy-fishing --loader --push` 后 Gitee 注入才吃到此包

---

## [2026-09-02 | v0.31.0 防踢强制启动+多通道]

### 用户需求
反踢增强, 真正启动功能后绝对不会被自动换服。

### 根因 (Potassium pid=2832, pv2929)
1. WindUI Toggle `Value=true` 创建时**不触发 Callback** → `startAntiIdle()` 从未执行, UI 显示开着实际零防护
2. 旧版仅 660s 一次 keytap, 间隔过长; 主路 Disable 后无定期重掐, 引擎可能重建连接
3. 实机确认 `getconnections(Idled)` 返回 userdata `ConnectionObject`, `con:Disable()` 可用 (掐后 count 下降)

### 改动
- 注入后立刻 `startAntiIdle()` (LoadConfig 若恢复关会 Callback 停掉)
- 每 60s: 重掐全部 Idled 连接 + VirtualUser/VIM 微动+F15/mousemoverel/keytap 四通道脉冲
- Idled 仍触发时立刻再掐+脉冲
- 去掉对 `type(con)=="table"` 的依赖, 直接 pcall `:Disable`

### 决策
- MINOR 0.31.0 (显著增强, 非纯文案)
- 不跳跃 (避免搅抛竿 CFrame)

### 验证
- 热替换加载 v0.31.0 成功 (Potassium, lib 1.8.1)
- antiIdle 循环确认在跑 (曾告警慢循环 → 已改整段 task.defer)
- getconnections(Idled) Disable 可用
- **已发布**: `python tools/publish.py --game heavy-fishing --push` → Gitee master `60ae509` (manifest v0.31.0, obf ~263KB); 首次 push 被 127.0.0.1 代理拦, 清 HTTP(S)_PROXY + git `-c http.proxy=` 后重推成功

### 遗留
- 长挂 20min+ 失焦实测仍待用户确认

### 踩坑黑名单
- [Toggle Value=true 不触发 Callback] → [功能看似开着实际没 start] → [需要强制启动的功能在创建后显式调用 start, 不要只靠 Callback]
- [Gitee push 走 127.0.0.1 代理] → [443 连不上] → [清 HTTP(S)_PROXY 并用 git -c http.proxy= -c https.proxy= 推送]

---

## [2026-09-01 | v0.30.5 防踢三层]

### 用户需求
参考较新开源 Anti-AFK 改防踢, 版本锁定 PATCH 0.30.5, 然后推送。

### 改动
- 主路: getconnections/get_signal_cons 禁用 Idled
- 退路: Idled → VirtualUser CaptureController + ClickButton2
- 再退路: 660s keytap F15, 失焦也按; 去掉空格跳跃
- 关闭/OnCleanup 尝试 Enable 已禁用连接并断自建 Idled

### 决策
- 用户指定 0.30.5, 不按 MINOR 升
- 三层可叠加: 掐连接后仍挂自己的 Idled 处理和 F15 兜底

### 遗留
- 待实机长挂确认失焦不再被 20 分钟引擎踢

---

## [2026-09-01 | v0.30.4 设出生点也合并最近]

### 用户需求
表哥 · 设出生点 与竿店/饵店等同款处理。

### 改动
- `NEAREST_FOLDER_LABEL` 增 `SetSpawn = "表哥 · 设出生点"` (×10 Biao Ge)
- 文案 Desc / 功能清单同步

### 验证
- 逻辑与 v0.30.3 四类同源; 待热替换后下拉确认「设出生点」一条 + 传最近
- **已发布**: `python tools/publish.py --game heavy-fishing --push` → Gitee master `3442af5` (manifest v0.30.4, obf ~239KB)

### 遗留
- 无更多同名多岛 Folder 待合并 (Function/Boss/LearnSkill 均为唯一)
- 本机 HTTPS 默认走 127.0.0.1 代理时 Gitee push 会失败, 需清 HTTP(S)_PROXY 后重推

---

## [2026-09-01 | v0.30.3 功能NPC传送合并最近]

### 用户需求
传送列表里「卖钓鱼竿/卖诱饵/开船/卖鱼」只显示一条, 传送按距自身最近的同功能 NPC。

### 逆向复核 (Potassium pid=18284, pv2929)
- `workspace.NPC` Folder: BuyFishingRod×8(全名 Biao Di) / BuyBait×9(Ba Chang) / SpawnBoat×10(Chu Xin 1~10) / SellFish×9(Nana)
- 旧逻辑 `seenNames[模型名]` 对同名只留第一个(竿/饵/卖鱼落点固定非最近); 楚欣英文名不同 → 列表刷出多条相同中文「楚欣 · 开船」

### 改动
- `NEAREST_FOLDER_LABEL` 绑定四 Folder → 固定中文标签; 候选全收集到 `candidates[]`
- 列表按 label 只插一条; `pickNearestHrp` 传送时选最近有效 HRP
- Character 扩展扫描跳过已合并 label, 防 Chu Xin 二次入库

### 验证
- 实机计数: 竿8/饵9/船10/卖鱼9; 当前位最近船 = Chu Xin 9 @63 studs
- 待: 注入后下拉确认四类各一条 + 点传送落最近岛

### 遗留
- ~~表哥设出生点(SetSpawn×10)仍按旧「同名取第一个」~~ → v0.30.4 已合并

---

## [2026-08-31 | v0.30.2 假称号完整对齐服务器视觉]

### 用户需求
假称号要跟真装备一样: 背景/字体长度/颜色; 关匿名时头顶名字随称号变色; 开匿名保持 theKing User 红。不做发布/混淆。

### 逆向补强 (Potassium EquipTitle A/B)
- 颜色权威 = Billboard 上名为 `Color` 的 UIGradient, TextColor3 恒近白 (~0.973)
- PlayerName 换称号时同步同款渐变, 文本仍是真名
- Title.BackgroundTransparency=0.25; 短名 Size.X≈0.9 (VIP), 长名≈2.2; AutomaticSize.X
- VIP: imgBgT=0.25 + Flare1(rbxassetid://138111953688137) + Circle(rbxassetid://10637682258)
- Sage/Master/Grandmaster: flare + rot=-90; Expert/Novice: 无 FX
- 未真拥有的 OG/CC: FireServer 被拒不改头顶; Data.Owned 本地改 true 无效于服务器

### 改动
- TITLE_STYLE 表 + setGradient(缺则创建) + applyTitleFx(Flare/Circle)
- forceLocalTitle: 渐变/尺寸/特效/设置页; 只改 Equip 不伪造 Owned
- 匿名: 关 PlayerName 渐变; 关匿名后重刷称号渐变; keep 循环后盖匿名

### 验证
- Expert/VIP/Sage: 本地 force 与服务器 Equip 渐变/特效/PN 一致
- VIP Size 本地手动 0.9 对齐; OG/CC 仅本地伪装 (服务器拒)

### 遗留
- OG/CC 渐变按 cfg.Color 推算, 无真服装对照; 真拥有后再抓一次可微调
- 发布/混淆交其他 AI

---

## [2026-08-31 | v0.30.1 玩家Tab排版 + 假称号完整显示]

### 用户需求
排版: 兑换码 → 虚假信息 → 玩家; 未拥有称号也要本地真实完整显示。

### 逆向补强 (PlayerScripts.Player_Title)
- `updateEquippedDisplay` 只改设置页 `MainGui...Gameplay.Player_Title`: Text=cfg.Name, Color, Icon.Image, Icon.ImageColor3=cfg.Color
- 头顶 BillboardGui `EquippedTitle` **无客户端写入脚本** (仅服务器改 / 需本地强制); 实测显示模块名 (OG) 非 cfg.Name (OG Title)
- Chat 前缀读 Data.Equip + cfg.Name 去 Title 词

### 改动
- Section 三分区重排
- forceLocalTitle: 头顶 + 设置页双写 + Owned/Equip + 0.25s 保活; 应用立刻刷

### 验证
- Potassium 手测 force OG/Content Creator/VIP: 头顶 Text/Color/Image 与设置页 cfg.Name/IconColor 均到位

---

## [2026-08-31 | v0.30.0 删船只召唤 + 一键兑换码]

### 用户需求
1. 删除玩家 Tab 船只召唤 (已失效)
2. 分析 Code 系统, 玩家 Tab 做「一键兑换所有可用代码」

### 逆向 (pv2929, Potassium)
- 客户端 `ClientModule.Code` 仅绑 UI: Redeem 按钮 → `Events.RedeemCode:FireServer(TextBox.Text)`, 无码表
- 码表权威在服务端; 客户端可见 `Data[UserId].Code` Folder, 子节点 BoolValue (true=已兑)
- 实测: FireServer("49KLikes") → 1.5s 内 BoolValue false→true; 假码不建节点
- 社区活跃码: 49/48/47/46KLikes, 33~30MVisits, 13KActives, HWF, AXO, Taiji(Lv500); Taiji 不在 Data.Code 预置列表

### 改动
- 删除船只召唤整块 (~260 行)
- 新增兑换码 Section: 状态 Paragraph + 刷新 + 一键兑换全部
- 版本 0.29.2→0.30.0

### 验证
- 待: 注入后点一键兑换, 看状态计数与通知

### 遗留
- 新码发布时需更新 KNOWN_CODES 种子 (或等进入 Data.Code)
- Taiji 实测未写回 Data.Code (可能等级不够), 仍保留种子尝试

---

## [2026-08-31 | v0.29.2 匿名者改名+固定红色, 去彩虹循环]

### 用户需求
匿名者头顶名称 "theKing Create" 彩虹渐变改为固定红色, 改名 "theKing User"。

### 改动
- 头顶名称: "theKing Create" → "theKing User"
- 颜色: 彩虹 HSV 色轮循环 (0.1s tick) → 固定红色 Color3.fromRGB(255, 45, 45)
- 移除 StartLoop("anonRainbow") / anonTick 彩虹渐变循环
- 保留: 重生自动重应用 (CharacterAdded 1.5s 后), 持久化 Flag "anonymous"
- 版本: ScriptVersion 0.29.1→0.29.2, 头部功能清单同步更新

### 验证
- 代码只改文案/颜色/去循环, 不涉及游戏交互, 无运行时风险
- 待实机: 确认头顶显示 "theKing User" 红色, 无彩虹闪烁

---

## [2026-08-30 | v0.28.0 召唤持续失败 — 服务器会话状态诊断]

### 用户反馈
船只召唤实际还是召唤不出来 (v0.27.2 修复后仍失败)。

### 诊断 (实机, 全部 FireServer 直接调用)
| 测试 | 结果 |
|---|---|
| v0.27.1 (11:18) FireServer("Boat", Vector3) 首次 | ✅ 生成 Boat_3547743270 (NPC 旁水面) |
| 之后多次 (Boat/Golden Boat/Ascended Perch, 不同位置) | ❌ 全部无响应 |
| 本地销毁旧船后 (workspace 无船) 再召唤 | ❌ 无响应 |
| 还原玩家到首次成功位置 (1398,9,186) | ❌ 无响应 |
| 模拟按键 E / Prompt:InputHoldBegin+End (玩家在 4 格内) | ❌ VisibleUI 不触发 (服务器不认模拟输入) |
| 监听 Events 全量入站 | 无拒绝/错误响应 (仅无关 VFX) |

### 结论
- 脚本侧逻辑正确 (FireServer 发出成功, pcall 无异常; 首次召唤确实成功过)。
- **服务器侧会话状态问题**: 首次召唤后所有 Spawn 被静默拒绝, 与船名/位置/船数无关 →
  疑似服务器**召唤冷却** (时长未知, >11 分钟) 或**会话内限制**。
- 模拟输入无法触发 NPC 对话 (原生 ProximityPrompt, 服务器不认 VIM/InputHold 模拟) →
  UI 前置流程 (Open→VisibleUI→Spawn) 无法脚本化绕过, 服务器状态机不可见。

### 处理
1. summonBoat 加 [BOAT] 逐步日志 (sel/npcDist/fire/seatFound)。
2. 召唤失败降级: 找不到新船 → 上现有船 (如有) → 否则提示"重进服务器重置状态后重试"。
3. 建议用户重进服务器 (重置会话状态) 后重新注入测试; 若仍失败, 取 [BOAT] 日志深挖。

### 待验证
- 重进后第一次召唤是否成功 (验证"会话状态"假说)。
- 若成功: 注意召唤可能有冷却, 勿连续召唤。

---

## [2026-08-30 | v0.28.0 召唤只坐新船 + 玩家Tab 编号隐藏/匿名者]

### 用户需求 (三条)
1. 修复召唤: "这个船只是我自己召唤的" — 每次必须重新召唤选中的船, 再坐上**刚召唤的**那艘 (不能坐旧船/别人船)。
2. 玩家 Tab: 编号隐藏 — 隐藏屏幕右上角数字编号 (用户 ID 3547743270)。
3. 玩家 Tab: 匿名者 — 头顶名称改为固定 "theKing Create" + 彩虹渐变字体 (仅本地可见)。

### 需求 1 — 召唤只认新船
- 逆向: 模型名 = "Boat_<UserId>" (含船名前缀), 但多次召唤会生成多艘同前缀船, 名字过滤不可靠。
- 方案: 召唤前 `collectBoatSet()` 快照所有带 VehicleSeat 的模型; 召唤后轮询 (8s, 0.3s 步进)
  找**不在快照中**的新模型 → 其 VehicleSeat = 刚召唤的船 → sitOnSeat。
- 彻底排除旧船/他人船: 只有"召唤后新出现"的船会被选中。

### 需求 2 — 编号隐藏
- 数据源 (实机): `PlayerGui.MainGui.TextLabel` 文本 = UserId ("3547743270"), 右上角。
- 实现: Toggle 控制 `Visible` (开=隐藏)。持久化 Flag "hideUid"。

### 需求 3 — 匿名者
- 数据源 (实机): 头顶名称 = `Character.HumanoidRootPart.EquippedTitle.PlayerName` (TextLabel, 原名 "超級路西"),
  挂在 HumanoidRootPart 下 (非 Head)。
- 实现: Toggle 开 → PlayerName.Text="theKing Create" + `TheKing.StartLoop("anonRainbow", 0.1, tick)`
  tick 每 0.1s `Color3.fromHSV((os.clock()*0.15)%1, 1, 1)` 彩虹渐变 (HSV 色轮);
  关 → 恢复原名+原色 (0.972549 白) + StopLoop。
- CharacterAdded 监听: 重生 1.5s 后若开关仍开则重新应用。
- 持久化 Flag "anonymous"。本地改动仅客户端可见, 服务器/他人看到原名。

### 验证
- 注入 0 error; UI 渲染: 编号隐藏/匿名者 Toggle 出现; 功能实测: PlayerName="theKing Create" + HSV 色 ✓,
  uidLbl.Visible=false ✓ (随后已还原现场)。
- 块配对 893/893, 峰值 177, LUA5.1 SYNTAX OK。
- 待实机: 召唤按钮连续点两次 — 应每次生成新船并坐上最新那艘。

---

## [2026-08-30 | v0.27.2 船只召唤实际召唤不了 — 两个根因修复]

### 用户反馈
"实际召唤不了"。

### 诊断 (实机)
1. 直接 FireServer 测试: `Spawn:FireServer("Boat", npcPos)` **成功生成船** (Boat_3547743270@NPC旁水面) →
   协议本身通, 不需要先 Open/VisibleUI 流程。
2. 发现两个 bug:
   - **selectedBoat 初始 nil**: Dropdown Callback 只在用户**主动选择**时触发; 用户不点下拉直接按"召唤并上座"
     → selectedBoat 永远 nil → 弹"请先选择船只"。
   - **上座失败**: `hrp.CFrame = seat.CFrame; hum.Sit = true` 实测 hum.Sit 被引擎/服务器复位为 false
     (玩家瞬移到座位但没绑定), 船没真正"开"起来。

### 修复
1. `buildBoatList()` 后 `selectedBoat = boatChoices[boatNames[1]]` (默认第一艘) + summonBoat 开头兜底。
2. `sitOnSeat`: 改用引擎级 `seat:Sit(humanoid)` (VehicleSeat 方法, 绑定 Occupant, 服务器认可);
   非 VehicleSeat 兜底 hum.Sit=true。

### 验证 (端到端实测, 全部通过)
| 步骤 | 结果 |
|---|---|
| 找最近 NPC | Chu Xin 9, 距离 23 ✓ |
| 召唤 | FireServer("Boat", npcPos) 船生成 ✓ |
| 找船 | VehicleSeat 在 NPC 20 格内 ✓ |
| 上座 | seat:Sit(hum) → humSit=true, seatOccupant=true ✓ |
| 位置 | 玩家 (1426,3.1,299) = 座位 (1426,1.18,299) 坐上姿态 ✓ |

### 通用教训
- WindUI/UI 库 Dropdown 的 Callback 只在用户主动选择时触发, 初始 Value 不会回传 → 必须手动初始化业务变量。
- `Humanoid.Sit = true` 只是本地姿态, 不绑定 VehicleSeat → 必须 `VehicleSeat:Sit(humanoid)` 才被服务器认可。
- 服务器 Remote 是否拒绝, 直接 FireServer 实测最快 (不一定要走 UI 前置流程)。

---

## [2026-08-30 | v0.27.1 船只召唤改最近船坞NPC]

### 用户需求
船只召唤逻辑改为: 找到最近的船只召唤NPC → 召唤选择的船只 → 传送玩家到船只驾驶。

### 实现
- 新增 `findNearestBoatNpc()`: 扫 `Workspace.NPC.SpawnBoat` 下全部 Model (Chu Xin 1..10),
  取 HumanoidRootPart.Position (无则 PrimaryPart), 按玩家距离取最近, 返回其位置。
- `summonBoat`: Location 从玩家 HRP.Position 改为最近 NPC 位置 → `Spawn:FireServer(船名, npcPos)`。
- 召唤后轮询 (6s) 在 npcPos 附近 (<30) 找带 VehicleSeat 的船 → `HRP.CFrame = seat.CFrame; Humanoid.Sit = true` (瞬移传送上座)。
- 实机验证: 玩家 (1395,9,205) → 最近 Chu Xin 9 (82格), 10 个 NPC 距离排序正确。

### 注意
- 类型检查: `workspace.NPC:FindFirstChild(...)` 直接索引 workspace.NPC 会报
  `Key 'NPC' not found in external type 'Workspace'` → 必须 `workspace:FindFirstChild("NPC")` 后取。
- 船生成位置 = 船坞 NPC 附近 (服务器按 Location 生成), findBoatSeat 基准用 npcPos 而非玩家位置。

---

## [2026-08-30 | v0.27.0 注入通知静默 + 玩家Tab 船只召唤]

### 用户需求 (两条)
1. 每次注入都弹所有功能启动/关闭通知 → 太吵, 要静默。
2. 玩家 Tab 新增(放最前面): 船只召唤 — 选已拥有的船, 召唤到角色位置, 坐上驾驶位。

### 需求 1 — 通知静默
- `notifyToggle` 加 `notifyMuted` 检查 (开头 return)。
- 注入生命周期: `NewTab` 之前设 `notifyMuted = true` (ConfigManager 恢复 + setAutoFish(false) 都触发 Callback→notifyToggle),
  注入初始化完成 (setAutoFish(false) + autoFish:Set(false) 之后) 设回 false。
- 用户手动开关功能时 notifyMuted=false, 通知照常。

### 需求 2 — 船只召唤 (逆向结论)
数据源 (实机):
- `Data[UserId].Boats` (Folder) — 船目录, 子对象 BoolValue, `Value=true` = 已拥有 (用户 4/5: Boat/Golden/Kunfish/Ascended, Rainbow Boat 未拥有)。
- `Info.Boats` (Folder of ModuleScript) — 全量配置: Price/Speed (Boat 60, Golden 90, Rainbow 120, Kunfish 85, Ascended 85; -1 = 活动船)。
- `Data.BoatFavorite` — 收藏标记 (无关召唤)。
协议 (逆向 `MainGui.Menu.BoatShop.BoatShop` LocalScript):
- 召唤 = `ReplicatedStorage.Remotes.BoatShop.Spawn:FireServer(船英文名, Location)`
- Location 由服务器经 `Events.VisibleUI.OnClientEvent("BoatShop", Location)` 下发 (游戏船坞的生成点);
  我们传 `HumanoidRootPart.Position` → 船生成在角色位置。
- 上座: 服务器生成船后走 `Events.EnteredBoat` FireClient (ClientModule.Boat 处理驾驶物理/动画)。
  脚本补充: 召唤后轮询 workspace 找最近 (距离<30) 带 VehicleSeat 的模型 → `HRP.CFrame=seat.CFrame; Humanoid.Sit=true`。
- 船名汉化: Boat=基础船, Golden Boat=黄金船, Rainbow Boat=彩虹船, Kunfish Overlord=鲲皇船, Ascended Perch=升华鲈船。

### 修复 (开发中踩坑)
插入船只召唤 do 块时 new_string 误吞 `local PlayerTab = TheKing.NewTab(...)` 定义行 → 运行时 `attempt to index nil with 'Section'`。
教训: Edit 插入代码块时, old_string 若包含"上一段定义 + 后续锚点", new_string 必须原样保留定义行;
插入后立刻 grep 确认被引用符号 (PlayerTab/BagTab 等) 的定义行还在。

### 验证
- 注入 0 error; UI 渲染确认: 船只召唤 Section + 刷新船只列表 + 选择船只 Dropdown + 召唤并上座 Button 全部出现。
- 块配对 847/847, 峰值 173, LUA5.1 SYNTAX OK。
- 待实机: 点"召唤并上座"看船是否生成在角色位置 + 是否自动上座 (服务器行为验证)。

---

## [2026-08-30 | v0.26.3 Tab 侧栏重排真正生效]

### 用户反馈
Tab 顺序仍然错乱, 截图显示: 库存管理 → 自动钓鱼 → 背包管理 → 快捷传送 → 玩家 → 快捷键 → 设置。

### 根因 (实机取证)
hub.luau 3948 行有"Tab 侧栏重排"代码 (1.5s 延迟 + 遍历 tabBox + 设 LayoutOrder),
但 **TARGET_ORDER 表的标题是 v0.26.0 重命名前的旧名字**:

```lua
local TARGET_ORDER = {
    ["自动钓鱼"] = 1, ["鱼饵管理"] = 2, ["背包管理"] = 3, ["恩佐BOSS"] = 4,  -- 旧!
    ["快捷传送"] = 5, ["玩家"] = 6, ["快捷键"] = 7, ["设置"] = 8,
}
```

v0.26.0 重命名后:
- "鱼饵管理" → "背包管理" (BaitTab 改名)
- "背包管理" → "库存管理" (BagTab 改名)
- "恩佐BOSS" → 已并入自动钓鱼, BossTab 移除 (v0.24.3)

**所有标题匹配 miss → order 全为 nil → `if order then btn.LayoutOrder = order end` 全部跳过** → WindUI 自身 LayoutOrder 保留 (Tab 创建时由 WindUI 分配, 不是默认 0)。

实测注入后 WindUI 默认 LayoutOrder: 库存管理=0(异常), 自动钓鱼=1, 背包管理=3, 快捷传送=5, 玩家=6, 快捷键=7, 设置=8 — 排序时 0 < 1 < 3 ... 导致"库存管理"排第一。

### 修复
TARGET_ORDER 改为:
```lua
["自动钓鱼"] = 1, ["背包管理"] = 2, ["库存管理"] = 3,
["快捷传送"] = 4, ["快捷键"] = 5, ["玩家"] = 6, ["设置"] = 7,
```

1.5s 延迟执行后 7 个 TabItem LayoutOrder 全部正确 (1..7 连续)。

### 验证 (实机)
| LayoutOrder | 标题 | posY |
|---|---|---|
| 1 | 自动钓鱼 | 506 |
| 2 | 背包管理 | 549 |
| 3 | 库存管理 | 593 |
| 4 | 快捷传送 | 637 |
| 5 | 快捷键 | 681 |
| 6 | 玩家 | 725 |
| 7 | 设置 | 769 |

完全符合用户要求, 间距 43px 均匀。

### 通用教训
TARGET_ORDER / TITLE_MAP / FLAG_NAME 等字符串映射表必须随 Tab / 控件重命名同步更新;
错过时所有按钮静默跳过赋值, 无报错, 无警告 — 极难发现。
建议: 在头部注释里把 TARGET_ORDER 标注为"必须与 NewTab Title 一致", 并加 lint 检查 (grep 比对)。

---

## [2026-08-30 | v0.26.2 竿列表拥有判定修正(Owned 标记) + 修 buildRodList 结构损坏]

### 用户反馈
1. **顺序并没有修复好** — 排查: 代码层面 Tab 创建顺序已正确(自动钓鱼→背包管理→库存管理→快捷传送→快捷键→玩家→设置), 注入后 GetChildren 渲染序也正确; 用户看到的错乱应为旧窗口/旧实例残留, 重开窗口即好。
2. **竿列表仍列全部 39 把, 有未拥有的** — 实锤 v0.26.1 结论错误。

### 根因 (实机取证)
`FishingRodInventory` 的 39 个竿名 Folder 是**全量目录**, 与拥有与否无关; 每个 Folder 内 **`Owned(BoolValue)`** 才是真拥有:
- Grandmaster Golden Rod 的 `Owned=false` (用户无此竿)
- 全量统计: 用户实际 **25/39** 把拥有
- v0.26.1 的"存在即拥有"判定错误 → 39 把全列

修复: `f:FindFirstChild("Owned").Value == true` 才算拥有。

### 附带修复: buildRodList 结构损坏 (注入失败的隐藏炸弹)
v0.26.2 改 guard 式 continue 时, 旧"包裹式" `if f:IsA("Folder") then` 的闭合 `end` 残留(行 2823),
提前闭合 buildRodList 函数 → table.sort/for 循环被挤出函数体、2834 的 end 误闭合 2747 do 块、
2886 的 end 变多余 → Lua 报 `2886: '<eof>' expected near 'end'` + 块配对 812/813 差 -1。
切片定位: 1..2885 行 OK / 1..2886 行报错。删除残留 end 后 812/812 平衡, SYNTAX OK。

**通用教训**: 包裹式 `if X then 大段代码 end` 改成 guard 式 `if not X then continue end` 时,
必须同步删除原来包裹代码的 `end`; 残留 end 会让函数/块提前闭合, 后续所有缩进全乱,
且不报错直到注入/编译。改结构类代码后必须跑块配对检查。

### 验证
- 注入 0 error; UI 选中项 = 茅山竿 · 能量 105 (= 已拥有最高能量竿, 荷鲁斯之眼 9999 Owned=false 不再出现)
- 对照: Owned=true 25 把, 排序 Maoshan 105 > Taoist/Heavenpiercer/Pure Diamond 100 > Diamond 90 ✓
- 块配对 812/812, 峰值 165, LUA5.1 SYNTAX OK

---

## [2026-08-30 | v0.26.1 竿列表只列已拥有 + Tab 顺序修正]

### 用户需求 (两条)
1. 装备竿功能**只能选自己拥有的竿**, 不是全部 39 把。
2. Tab 顺序: 自动钓鱼第一、背包管理第二、库存管理第三、其他不变(此前背包管理/库存管理排在快捷传送之后)。

### 需求 1 — 数据源改正

**逆向** (本次实机): `playerData.Inventory` 是**鱼**背包(690 条 NumberValue), 不含竿。竿存储位置 = **`playerData.FishingRodInventory`**(Folder, 39 个竿名 Folder 子对象 = 已拥有, 非 BoolValue 标记, 存在即拥有)。当前装备竿存 `playerData.FishingRod`(StringValue, 实测 "Heavenpiercer Rod")。

**改动**: `buildRodList()` 改扫 `playerData.FishingRodInventory` 的 Folder 子对象名 → 从 `Info.Inventory` 对应模块读 Power(能量) → 排序显示。`Info.Inventory` 只作能量查表, 不再作为"拥有"依据。

### 需求 2 — Tab 顺序

WindUI **无 Tab 排序 API**(查 windui-api.md, 只有 :Tab 新建), **顺序由 NewTab 创建顺序决定**。故把两个创建块整体搬移:
- BaitTab(背包管理)块: 原 3473-3689 → 移到 TeleportTab 定义前
- BagTab(库存管理)块: 原 3122-3333 → 移到 BaitTab 块后
- 结果创建顺序: MainTab(自动钓鱼) → BaitTab(背包管理) → BagTab(库存管理) → TeleportTab(快捷传送) → HotkeyTab(快捷键) → PlayerTab(玩家) → SettingsTab(设置)

用 Python 按锚点文本提取/删除/插入, 避免手改行号。块配对 811/811、Lua 语法 OK 确认结构无损。

### 验证
- 静态门: check-script buildRodList 片段 0 error 0 warning
- 全文件: 块配对 811/811, Lua5.1 语法 OK
- 动态门: execute-file 重跑 0 startup error
- **实机 UI 验证**: 侧边栏 GetChildren 顺序 = `自动钓鱼→背包管理→库存管理→快捷传送→快捷键→玩家→设置` ✓ 与用户要求一致; 竿列表仍渲染(荷鲁斯之眼·能量9999 在列 — 用户 FishingRodInventory 全 39 把, 故列表同全量, 但语义已改为"只列拥有")
- **待实机**: 若玩家账号未全收集, 刷新列表应只出现已拥有的竿

### 遗留 / 下步
- 若后续想区分"未拥有的竿"展示(灰色/锁定), FishingRodInventory 缺项即为未拥有, 可从 Info.Inventory 全集减 FishingRodInventory 差集得出
- 注意: 竿列表是注入时构建一次 + 手动刷新; 买了新竿后需点"刷新钓鱼竿列表"才出现在列表里

---

## [2026-08-30 | v0.26.0 二阶段改直接发包 + 背包管理/库存管理 Tab 与钓鱼竿装备]

### 用户需求 (两条)
1. Phase2 要"高速且准确不错误不漏过" — 问有没有更深层输入办法。
2. Tab 重命名: 鱼饵管理→背包管理, 背包管理→库存管理; 背包管理 Tab 加钓鱼竿装备(选竿→一键装备+刷新, 全汉化, 按能量排序)。

### 需求 1 决策 — 放弃模拟点击, 直接发服务器命中包

**"错误按下"的实测来源** (v0.25.0-0.25.2 实机反复):
- ① 点击落点(10,10) 在 Phase2 期间可能被战斗 GUI 覆盖 → `gameProcessed=true` → 游戏 onClick 首行 `if p2 then return end` 直接吞掉 → 点击无效;
- ② 即使点进去, 游戏 onClick 用**自身内部变量**(u115 相位/u114 周期/u87 条速)复算条位, 与脚本从 GUI 读到的位置存在系统偏差(采样时点不同), 边缘判定必然有误差。

**关键逆向结论**: 服务器端**只信任 `{Hit=true}` 标志** — v0.24.x 盲发时代实测必胜, 服务器不校验客户端 UI/条位/Index 一致性(仅要求 Index 连续递增)。

**因此**: 直接 `FireServer({Hit=true, Index=N})` = 100% 接受, **零错按、零漏过**, 且不受 30ms 节流/采样率限制, 天然"高速"。为保留 v0.25.0 用户要的"绿框移动"观感, 命中后手动模拟 newHitbox: 把绿框挪到远离当前条位(≥0.1)的随机新位置, 最多试 20 次。被服务器回推覆盖也无妨(服务器已认账)。

**判定仍保留**: AnchorPoint 修正(条心/框心=Position.X.Scale) + 速度预测(PHASE2_LEAD=0.02) + 节流 0.06s。

### 需求 2 实现

**逆向** (本次实机):
- 竿数据源 = `Info.Inventory` 中 `Type=="Fishing Rod"` 的 ModuleScript, 39 把; 字段含 `Power`(能量)/`Luck`/`Cash`/`Model` 等, **无中文名** → 需自建 CN_RODS 映射
- 装备接口 = `Events.EquipFishingRod`(RemoteFunction), 参数 = 竿英文名, 与游戏背包 Equip 按钮同款(`Fisher_Inventory` L418)

**改动** (hub.luau):
- L3122 `BagTab` 背包管理 → **库存管理**
- L3473 `BaitTab` 鱼饵管理 → **背包管理**
- BaitTab 末尾新增「钓鱼竿」Section(独立 do 块):
  - `CN_RODS` 39 把竿中文名全量映射(英文直译, 与 intel 已知命名一致; 用户偏好可调)
  - `buildRodList()`: 扫描 Inventory → 按 Power 降序(同能量稳定排序) → label = `中文名 · 能量 N`
  - 刷新按钮: 重扫 + `rodDropdown:Refresh(rodNames)` + 中文通知
  - Dropdown 选竿 → 装备按钮: `pcall(rodEquipEv:InvokeServer(竿名))`, 成功/失败均有中文通知
  - `rodEquipEv = Events:FindFirstChild("EquipFishingRod")` 缺失时提示游戏已更新

### 验证
- 静态门: check-script 两段改动 0 error 0 warning
- 全文件: 块配对 810/810, Lua5.1 语法 OK
- 动态门: execute-file 重跑 0 startup error
- **实机 UI 验证**: WindUI 中确认 Tab 名为「库存管理」/「背包管理」; 竿列表已渲染 — `荷鲁斯之眼 · 能量 9999` 排最前(降序生效), 刷新/装备按钮的 Desc 正常
- **待实机**: ① 装备按钮实测(选竿→装备→游戏热键栏竿变化) ② 恩佐二阶段确认零错按且绿框在动

### 遗留 / 下步
- CN_RODS 中文名是按英文直译的, 若玩家习惯不同命名, 直接改表即可(一处改动全 Tab 生效)
- 若服务器未来校验 Index 与客户端 u109 一致性: 需改回"模拟点击"或 hook 游戏 onClick 拿真实 u109(实时观察是否需要)
- 竿列表暂不含 Luck/Cash 显示; 需要的话在 label 里追加

---

## [2026-08-30 | v0.25.2 二阶段判据放宽(修 v0.25.1 漏点回归)]

### 用户需求
- v0.25.1 太苛刻: 好几次条途径绿区却完全不进行操作。

### Root Cause (根因) — 两个"减召回"的项叠加

**① 最近点判据在 20Hz 下根本采不到转折点 (主因)**
v0.25.1 要求 `absd` 由减转增(越过框心最近点)才点击。但循环走 `TheKing.StartLoop`, 引擎强制间隔下限 50ms(20Hz)。条速快时相邻两次采样可能直接跨过最近点 → `passed` 永远为 false → **条穿过绿区也不开火**。这是典型的"用离散采样找连续极值"的陷阱: 采样率低于信号变化率时, 极值点必然被跳过。

**② 节流 0.12s 长于条单次穿越绿框的停留时间**
条单次进框停留 ≈ 窗宽(框宽*1.5)/条速, 实测远短于 0.12s → 第二次(乃至每一次)进框都被节流吞掉。游戏自身节流仅 30ms, 0.12s 是我方过度保守。

### 改动 (hub.luau)

- **移除** "最近点判据"(`passed` / `phase2PrevAbsd` / `phase2LastHbx` 换轮重置一并移除): 改为**进窗即打**
- `PHASE2_CLICK_CD`: 0.12 → **0.06**(游戏节流 30ms; 60ms 兼顾防连点与不漏框)
- `PHASE2_EDGE_SAFE`: 0.02 → **0.01**(仅留极小余量, 不再过度收窗)
- **保留** 两项真正"提准不减召回"的改进:
  - AnchorPoint 修正(条心/框心直接取 `Position.X.Scale`, 修掉半个框宽的偏移 — 错按主因)
  - 速度预测(`PHASE2_LEAD=0.02`, 补偿游戏 25ms 判定回溯 + 我方约 1 帧输入延迟)

### 验证
- 静态门: check-script 改动片段 0 error 0 warning
- 全文件: 块配对 788/788, Lua5.1 语法 OK
- 动态门: execute-file 重跑 0 startup error
- 待实机: 确认"见框就打"恢复, 且错按仍少于 v0.25.0

### 遗留 / 下步
- 若仍偶发漏框(条速极快): 唯一根治法是提高采样率 — 引擎 StartLoop 下限 50ms, 需改走 `AddConnection(RunService.RenderStepped)`(AGENTS.md 明确: 更高频率用事件连接而非轮询), 并自行节流避免每帧开销
- 若错按回升: 调 `PHASE2_LEAD`(系统性偏早调小/偏晚调大), 不建议再收紧窗宽或加"最近点"类判据

### 踩坑 (归档)
- `[用离散采样检测连续极值(最近点/拐点)] → [采样率低于信号变化率时极值必被跳过, 功能静默失效] → [低频采样场景禁止用极值判据; 要提准就提采样率, 不要靠加约束]`

---

## [2026-08-30 | v0.25.1 二阶段点击判定精度优化(减少错按)]

### 用户需求
- 优化判断逻辑, 减少错按, 确保迅速且准确。

### Root Cause (根因) — 框心算错半个框宽

实机读 `MainGui.Fishing.BossFightBar` 结构:
```
Bar:     AnchorPoint=(0.5,0.5)  Position.X.Scale=0.2917  Size.X.Scale=0.0175
Hitbox:  AnchorPoint=(0.5,0.5)  Position.X.Scale=0.3957  Size.X.Scale=0.11
```
**AnchorPoint=(0.5,0.5) 意味着 `Position.X.Scale 直接就是中心`**, 而脚本一直写 `Position + Size/2`:
- 框心: 脚本算 0.451 vs 真实 0.396 → **偏 0.055 = 半个框宽**
- 条心: 脚本算 0.3005 vs 真实 0.2917 → 偏 0.0088

→ 脚本判定"已进框"时条往往还在框外, 游戏 onClick 一判就是未命中 → `FireServer({Hit=false})` = 错按。**这是错按的头号根源, 且与是否模拟点击无关(旧版盲发也一样错, 只是服务器信任标志掩盖了后果)。**

### 改动 (hub.luau) — 精度三件套

- L2339-2341 **AnchorPoint 修正**: 条心/框心直接取 `Position.X.Scale`, 不再 `+Size/2`
- L2344-2351 **速度预测**: 用相邻两 tick 的条位差算速度(Scale/秒), 外推 `PHASE2_LEAD=0.02s` 得到"点击生效时刻"的条位再判定。依据: 游戏 onClick 用 `t-0.025` 的位置判定, 而我们发点击还有约 1 帧(16ms)输入延迟
- L2357-2361 **最近点判据**: 命中窗 = 游戏判据(框宽*0.75) 再收紧 `PHASE2_EDGE_SAFE=0.02`; 且等偏差**由减转增**(已越过框心最近点)才发点击, 不在框边缘冒险; 条若几乎停在框心(`|d| <= 框宽*0.15`)则直接点 — 兜底兼顾"迅速"
- L2352-2356 **换轮重置**: 检测绿框位置变化(游戏已执行 newHitbox 挪框) → 重置最近点追踪, 防同一轮重复点击
- 新增状态量: `PHASE2_LEAD` / `PHASE2_EDGE_SAFE` / `phase2LastBarX` / `phase2LastBarT` / `phase2LastHbx` / `phase2PrevAbsd`

### 验证
- 静态门: check-script 改动片段 0 error 0 warning
- 全文件: 块配对 789/789, 主 chunk 存活峰值 167 (<200), Lua5.1 语法 OK
- 动态门: execute-file 重跑 0 startup error
- **待实机**: 开恩佐打二阶段, 重点看错按(Hit=false 闪光)是否消失、绿框是否每次命中后挪位

### 遗留 / 下步
- `PHASE2_LEAD=0.02` 是按"输入延迟 1 帧 - 游戏补偿 25ms"估的, 若实机仍有系统性偏差(总偏早或偏晚), 调这个常量即可(偏早调小/偏晚调大)
- 若想更精确: 可复刻游戏的三角波位置公式(`(t-u115)%u114*u87`, 超过 u113 则镜像), 只需从采样反推 BarSpeed/周期/相位三个量, 就能算出任意时刻的精确条位
- 20Hz 采样(引擎 StartLoop 下限 50ms)仍是硬约束; 若条速极快导致单 tick 位移接近框宽, 需改走 RenderStepped 事件连接

---

## [2026-08-30 | v0.25.0 恩佐二阶段小游戏改走真实流程]

### 用户需求
- 当前 Phase2 是"条一进绿区就发 Hit 包", 不是真实完美流程。期望: 条进入绿区时发起**真实的法宝请求**, 然后**绿条改变位置**, 体现完整的小游戏流程。

### 逆向结论 (PlayerScripts.MinigamePhase2, 本次实机反编译) — 已回写 intel.md

**触发链路**:
```lua
UserInputService.InputBegan:Connect(function(p1, p2)
    if p2 then return end                                   -- ★ gameProcessed==true 直接吞掉
    if p1.UserInputType == MouseButton1 then onClick(false) end
    if p1.UserInputType == Touch then onClick(true) end
end)
```

**onClick(p1) 完整逻辑**:
```lua
if not u105 then return end                    -- u105=小游戏激活
local v1 = os.clock()
if v1 - u107 < 0.03 then return end            -- ★ 30ms 节流
u107 = v1
local v3 = (v1 - v2 - u115) % u114 * u87       -- 条当前位置(三角波往返)
local v4 = u111 + v3
local v5 = u88 * 0.5 / 2                       -- 容差 = 绿框宽 * 0.25
local v6 = if u108 - v5 <= v4 then v4 <= u108 + u88 + v5 else false
if not v6 then
    flashGlow(u99, 0.35)
    BossPhase2Action:FireServer({Hit = false})  -- ★ 未命中也发包
    return
end
BossPhase2Action:FireServer({Hit = true, Index = u109})
newHitbox(v1)                                   -- ★★★ 绿框随机移到新位置
```

**newHitbox(v1)**: 按条当前位置 v3, 在避开 v3 附近 `MinGap` 的区间内**随机**选新绿框位置 → `u109 += 1` → `applyHitbox()` 应用。即每命中一次绿框就换位置, 这就是用户说的"绿条改变位置"。

**其它**: `BossPhase2Setup.OnClientEvent` 下发 BarSpeed/HitboxW/MinGap; RenderStepped 驱动条移动; startPhase2/stopPhase2 管开关与技能锁。

### 旧实现的差距
原 `bossPhase2Tick` 判定命中后直接 `FireServer({Hit=true, Index})` —— **跳过了 newHitbox**。服务器照样认账(信任标志), 但**绿框永远不动**, 流程是"假"的。而 newHitbox 是脚本内局部函数, 外部无法调用, **唯一入口就是模拟真实鼠标左键点击**。

### 改动 (hub.luau)

- L2304-2312 新增常量与状态:
  - `PHASE2_CLICK_X/Y = 10,10` — 点击落点固定屏幕左上角。**实测该处无 GUI → gameProcessed=false**; 若落在任何 GUI 上, 游戏 onClick 首行 `if p2 then return end` 会直接吞掉点击
  - `PHASE2_CLICK_CD = 0.12` — 游戏内部节流 30ms, 此处留足余量防连点被吞
  - `phase2LastClickAt`
  - 函数头注释完整记录逆向结论(触发/判定/发包/移框/节流), 便于后续维护
- bossPhase2Tick 命中分支: `FireServer` → **模拟鼠标左键点击**
  ```lua
  VirtualInputManager:SendMouseButtonEvent(PHASE2_CLICK_X, PHASE2_CLICK_Y, 0, true, game, 0)
  task.wait(0.03)
  VirtualInputManager:SendMouseButtonEvent(PHASE2_CLICK_X, PHASE2_CLICK_Y, 0, false, game, 0)
  ```
  判定公式保持 `|barCenter - hbCenter| <= hbW*0.75 + 0.01`(与游戏 onClick 同款)
- 兜底分支(读不到 Bar/Hitbox)保留原直接发包

### 验证
- **实机预验**: eval 发 `SendMouseButtonEvent(10,10,0,true,game,0)`, 游戏 `UserInputService.InputBegan` 确实收到 `{UserInputType=MouseButton1, processed=false}` — 模拟点击通道可用且落点安全
- 静态门: check-script 改动片段 0 error 0 warning
- 全文件: 块配对 787/787, 主 chunk 存活峰值 161 (<200), Lua5.1 语法 OK
- 动态门: execute-file 重跑 0 startup error
- **待用户实机**: 开恩佐打到二阶段, 确认①能命中②**绿框每次命中后确实换位置**③小游戏能正常打完

### 遗留 / 下步
- 若点击无效(如游戏改成 GUI 按钮触发): 改为点击 BossFightBar 内实际承载 onClick 的元素(需 dump-visible-ui 定位), 但要注意那会让 gameProcessed=true, 届时需改用 firesignal(Real 下为 no-op, 不可靠)
- 若命中率下降: 说明脚本判定与游戏有细微偏差, 可在命中分支加 `logDecision("[Phase2] 点击 barX=… hbX=… tol=…")` 核对
- 当前点击落点写死左上角; 若玩家在该处放了 GUI(如其他脚本的窗口), 会失效 → 后续可改为运行时探测一个 processed=false 的安全坐标

---

## [2026-08-29 | v0.24.10 节奏重写回归: 章鱼小游戏完全不起效果]

### 用户需求
- v0.24.7 发布后, 章鱼(无名章寄)二阶段节奏小游戏**完全不起效果** (v0.24.6 时还能打中, 只是漏点/无 Perfect)。

### Root Cause (根因) — 收紧窗口过度, 且主判据依赖 lineY 绝对精确

v0.24.7 为修"漏点 + 无 Perfect"做了三件事: 主判据改跨线检测、兜底窗 0.22→0.06、每音符去重。其中**窗收紧是致命项**:

- 主判据 `crossed = prev < lineY and y >= lineY` **要求 lineY 绝对精确**。lineY 取自 `BarFrame.Position.Y.Scale` (兜底 0.85)。若该值与实际判定线存在偏差(音符/判定线 AnchorPoint 不一致会差半个音符高; 游戏改布局也会变), 则跨线点落在错误位置, 且
- 兜底窗只剩 ±0.06 (原 ±0.22), **容差缩小 3.7 倍** — lineY 偏差一旦 > 0.06, 音符永远进不了窗 → **整场零命中**。

**为什么上一版(0.22 窗)能打中**: 窗足够宽, 即使 lineY 有偏差也覆盖得到, 代价是同 tick 挤进 2-3 个音符多发错配 = 用户看到的"漏点"。即: 0.22 是"打得多但错配", 0.06 是"完全打不着"。

### 改动 (hub.luau)

- L276 `RHYTHM_WINDOW`: 0.06 → **0.15**, 并在注释里写明双向约束:
  - 下界: 后期音符间距 ≈0.19 Scale, **窗必须小于间距**才不会同 tick 挤进多个音符
  - 上界: 需容纳 lineY 的合理偏差
  - 0.15 是二者的平衡点
- bossRhythmTick 判据重构为**每轨道独立取最优**:
  - 单趟遍历轨道内所有未命中音符, 维护 `best`(跨线优先, 其次 `|d|` 最小)
  - **每条轨道每 tick 最多发一个 hit** — 这是杜绝"同 tick 多发错配"的机制性保证, 正因如此窗才可以从 0.06 放宽回 0.15 而不重蹈 v0.24.6 漏点的覆辙
  - 保留 `noteHit` 去重(每音符一生只发一次)与不再本地 Destroy
  - 删掉原 candidates 表 + table.sort (不再需要全量排序)
- 新增命中日志: `logDecision("[节奏] <轨道> 命中 y=… line=… |d|=… 跨线/窗内")` — 实机后可直接从决策日志看出 lineY 是否准确、命中是靠跨线还是兜底窗

### 验证
- 静态门: check-script 改动片段 0 error 0 warning
- 全文件: 块配对 785/785, 主 chunk 存活峰值 160 (<200), Lua5.1 语法 OK
- 动态门: execute-file 重跑 0 startup error
- **待实机**: 钓章鱼二段, 确认恢复打击; 然后从决策日志读 `line=` 与 `y=` 的实际值, 判断 lineY 是否需要改用其他参照物

### 遗留 / 下步
- 若日志显示命中全靠"窗内"而非"跨线" → lineY 确实偏了, 下一步改以"音符 |d| 的历史最小点"作判据(不依赖 lineY 绝对值), 或改取判定线子元素换算
- 若仍漏点 → 检查是否同 tick 跨轨道命中超过 1 个(现上限 3 个/tick, 每轨 1 个), 必要时降到全场每 tick 1 个
- 恩佐 FinalPhase 同套逻辑, 一并受益

### 踩坑 (归档)
- `[为修精度而收紧判定阈值] → [阈值过窄导致功能完全失效] → [收紧前先确认被依赖的量(lineY)本身可信; 精度与召回要平衡, "每 tick 限量"这类机制性手段比"缩窄窗口"更安全]`

---

## [2026-08-29 | v0.24.9 烈阳高照天气下天气渔场传送失效]

### 用户需求
- 「快捷传送 → 传送至天气渔场」在烈阳高照天气下失效 (点按钮只弹"当前天气无稀有鱼", 不传送)。

### Root Cause (根因) — 键名差一个空格

**实机取证** (本次会话 eval):
- `ReplicatedStorage.Weather` 子对象 = Blazing Sun / Foggy / Rainy / Snowy / Thunderstorm / Windy (6 种特效)
- `ClientModule.Weather.Weather` 模块 = 上述 6 种 + Clear (7 种含晴天)
- 故 `workspace:GetAttribute("Weather")` 的烈阳取值 = **`"Blazing Sun"`(带空格)**

**脚本侧**: `WEATHER_ISLE_MAP` 的键写作 **`["BlazingSun"]`(无空格)** → `WEATHER_ISLE_MAP["Blazing Sun"]` = nil → 传送按钮走 `not targets` 分支弹"当前天气无稀有鱼"。

**为何只有烈阳失效**: 其余 5 种天气键 (Windy/Snowy/Thunderstorm/Foggy/Clear) 全是单词无空格, 与服务器值逐字一致, 故不受影响 — 这是"只有烈阳挂"的直接原因, 也是该 bug 长期潜伏的原因 (其他天气测不出来)。

**影响面不止传送**: `WEATHER_ISLE_MAP` 同时供 ① 天气渔场传送 ② 天气预报 checkWeather ③ 智能锁定"特殊天气鱼"规则 (WEATHER_FISH_SET 由此表构建, 该集合本身正常) 共用 → 烈阳天气下**预报提醒与锁定规则同样静默失效**。

### 改动 (hub.luau)

- L131 CN 映射: `["BlazingSun"]="烈日"` → `["Blazing Sun"]="烈阳高照"` (中文名随游戏 UI 实际显示更正)
- L353 天气鱼映射表键: `["BlazingSun"]` → `["Blazing Sun"]`
- L364 新增 `getWeatherTargets(weather)` 规范化查表 (三级兜底): 原值 → 去空格 → 小写去空格
  - 注释已标明**括号不可省**: `string.gsub` 返回 (结果, 次数) 两值, 不加括号会把次数一并传给 `string.lower` (Luau 类型检查报 Argument count mismatch)
- L2530 天气预报 `WEATHER_FISH[weather]` → `getWeatherTargets(weather)`
- L2682 天气渔场传送 `WEATHER_ISLE_MAP[weather]` → `getWeatherTargets(weather)`
- L2481 关注天气默认集 / L2468 中文反查表 / L2560-2561 关注天气下拉框 Values+默认值: 全部同步为 "Blazing Sun"/"烈阳高照"
- 删除因改动失去用途的 `local WEATHER_FISH = WEATHER_ISLE_MAP` 本地副本 (避免未使用变量告警)

### 验证
- 静态门: check-script 0 error 0 warning (首轮 2 error 为 `string.gsub` 多返回值传入 `string.lower`, 已用括号截断修正后复检 clean)
- 全文件: 块配对 787/787, 主 chunk 存活峰值 160 (<200), Lua5.1 语法 OK
- 动态门: execute-file 重跑 0 startup error
- **实机取证**: 本地 SetAttribute 伪造 Weather="Blazing Sun" (intel 已知客户端可本地触发, 服务器周期覆盖), 在游戏内复刻查表逻辑验证 → `"Blazing Sun"`/`"BlazingSun"`/`"blazing sun"` 三种输入**均命中 Amber Isle**, `"Clear"` 正确返回 nil; 验证后已把 Weather 恢复为 "Clear"
- 未做真机点击验证 (send-input 需窗口聚焦, 本次点击未命中按钮); 但失效点确定在查表, 该点已实机证实修复

### 遗留 / 下步
- 等游戏真的进入烈阳高照天气时, 用户点一次按钮确认端到端 (通知应显示「已传送至天气渔场 [烈阳高照] · 琥珀岛 · 可钓: 龙纹锦鲤 / 血玉鱼」)
- 后续新增天气时, 键名一律以 `ReplicatedStorage.Weather` 子对象名为准 (那是特效资源名, 与 Weather 属性同源), 不要凭英文拼写臆造
- 踩坑: 多词标识符(带空格)作表键时, 极易在代码里被写成驼峰 → 凡是"服务器下发的名字"当键, 都应加规范化兜底而不是假设逐字一致

---

## [2026-08-29 | v0.24.8 目标鱼过滤收竿后鱼竿装备不回去(严重)]

### 用户需求
- 开「目标鱼过滤」后, 非目标鱼咬钩时脚本按1收竿, 之后鱼竿再也装备不回去 → 自动钓鱼彻底停摆。

### Root Cause (根因) — 两层叠加, 缺一不可

**装备态判据**: `rodEquipped = ch:GetAttribute("Type") == "Fishing Rod"` (autoFishTick L1598)。

**因① 收竿复位靠"赌延时"**: 旧 fastCancelTarget 按两次 1 (收竿 + 0.18s 后复位), **全程不校验装备态、失败不重试**。游戏收竿有状态切换/动画, 0.18s 常被吃掉第二次按键 → `rodEquipped` 永久 false。

**因② 待机态零自愈**: autoFishTick 待机分支遇到 `rodEquipped == false` 只 `updateStatus("请先装备鱼竿")` 然后 `return` — 没有重装备动作。于是**装备态一旦丢失, 自动钓鱼永久停在提示文案上**, 用户只能手动重开脚本。

**放大因素**: 非目标鱼连续咬钩时 fastCancelTarget 被**并发**调用(旧版无重入保护), 多个 task.delay 交错发按键 → 收竿/复位翻转乱序 → 更容易停在"未装备"。

### 改动 (hub.luau)

- L1498 新增 `isRodEquipped()` — 装备态判据抽成函数, 与 autoFishTick 的判据逐字一致, 避免两处判据漂移
- L1505 新增 `fastCancelBusy` (重入保护) + `lastRodFixAt` (主循环补装备节流)
- fastCancelTarget 重写为**状态驱动**:
  - 入口 `if fastCancelBusy then return end` — 上一轮未跑完直接跳过, 杜绝并发按键乱序
  - ① 收竿: 按1后**轮询**等装备态解除 (上限 1.0s); 仍在装备态则补按一次再等 0.3s
  - ② 复位: 按1重新拿竿, **失败重试最多 5 次** (每次等 0.3s 判据), 全程 `deadline = os.clock() + 3` 兜底
  - 协程出口无条件 `fastCancelBusy = false` (防异常导致永久锁死)
  - 最终仍失败 → 弹中文通知「鱼竿未装备 / 请手动按 1 拿起鱼竿」, 不再静默卡死
- autoFishTick 待机分支 (rodEquipped=false): 由"只提示"改为**自动按1重装备** (1.5s 节流防每 tick 刷键), 文案「鱼竿未装备, 正在自动装备…」— 任何原因(收竿未复位/手动卸下/换场)导致的装备态丢失都能自愈

### 验证
- 静态门: check-script 改动片段 0 error 0 warning
- 全文件: 块配对 782/782, 主 chunk 存活峰值 159 (<200), Lua5.1 语法 OK
- 动态门: execute-file 重跑 0 startup error
- **待实机**: 开目标鱼过滤连钓, 确认非目标鱼收竿后能自动复位并继续抛竿 (重点看是否还会出现"鱼竿未装备"卡住)

### 遗留 / 下步
- 若实机仍偶发: 在 fastCancelTarget 内加 `logDecision` 打印每次 tap 前后的装备态与耗时, 确认是"按键被吞"还是"判据(Character.Type)刷新延迟"
- 若 Character.Type 刷新有延迟: 判据改读 `LocalPlayer.Backpack/Character` 里鱼竿 Tool 的实际 Parent
- 兜底通知已覆盖失败路径, 最坏情况用户手动按1即可恢复, 不会再静默停摆

---

## [2026-08-29 | v0.24.7 章鱼二阶段节奏漏点/无Perfect 修复]

### 用户需求
- 自动钓鱼在章鱼(无名章寄)二阶段节奏小游戏仍漏点, 且没有完美点击 (命中判定等级差)。

### Root Cause (根因) — 双因, 均由"判定窗过宽"派生

**几何计算 (据 intel.md Rhythm 协议)**: 音符下落 1.4s 全程, Y 从 -0.05 到判定线 0.85 → 速度 = 0.9/1.4 ≈ **0.643 Scale/s**; 后期音符间隔 0.3s → 相邻音符**间距 ≈ 0.193 Scale**。而判定窗 |y-lineY| ≤ 0.22 → **窗宽 0.44 Scale > 音符间距 0.193** → 同一 tick 窗内常驻 **2-3 个音符**(3 轨并行时更多)。

**因① 漏点**: 旧 bossRhythmTick 对窗内**每个**音符都 `RhythmHitEv:FireServer("hit")`, 而该 remote 包**不带音符 ID**, 服务器只能按队列顺序消费。"多发"→ 服务器把多余 hit 派给后续音符(错配)或计为空按 → 真音符到达时无包可用 → 判 miss = 漏点。

**因② 无 Perfect**: 旧逻辑音符**刚进窗**(偏离判定线 0.22, 精度最差)就立即发 hit, 命中偏差恒为最大值 → 服务器按精度分级时只给 Good, 永远拿不到 Perfect。

**附带问题**: 旧逻辑命中后本地 `note:Destroy()` — 服务器侧仍在追踪该音符, 本地销毁造成客户端/服务器状态不一致 (是错配的帮凶)。

### 改动 (hub.luau)

- L271-276 新增追踪表 (弱键表 `__mode="k"`, 音符实例被游戏移除后自动回收):
  - `notePrevY`: 音符上一 tick 的 Y, 供跨线检测用
  - `noteHit`: 已发过 hit 的音符, 供去重
  - `RHYTHM_WINDOW = 0.06`: 兜底窗 (原 0.22 → 收紧 3.7 倍)
- bossRhythmTick @2257 重写命中判据:
  - **主判据 "跨过判定线"**: `crossed = prev ~= nil and prev < lineY and y >= lineY` — 音符正好越过判定线的那一 tick 发送 = Perfect 时机 (不受窗宽影响)
  - **兜底判据**: `|y - lineY| <= 0.06` — 防掉帧/瞬移导致跨线未被采样到
  - **去重**: `noteHit[note]` 标记, 每个音符**只发一次** hit, 杜绝重复发导致的服务器错配
  - **排序**: 候选按 `crossed` 优先、再按 `|d|` 升序 — 越接近判定线越先发
  - **不再本地 Destroy** 音符 — 判罚以服务器收到 hit 为准, 本地销毁只会制造状态不一致
- RhythmStart 监听器 @2310: 开新场时 `table.clear(notePrevY); table.clear(noteHit)` — 防上一场残留标记让新场首个音符被误判"已命中"

### 验证
- 静态门: check-script 改动片段 0 error 0 warning (两轮; 首轮 2 error 是我加的 `:: {[Instance]:number}` cast 与 metatable 类型不兼容所致, 真实脚本无类型注解, 去掉 cast 后 clean)
- 全文件: 块配对 770/770, 主 chunk 存活峰值 159 (<200), Lua5.1 语法 OK
- 动态门: execute-file 重跑 0 startup error (客户端 pid 8752)
- **待实机**: 需钓章鱼二段确认漏点消失 + 判定出 Perfect (游戏 UI 判定等级是唯一可信指标)

### 遗留 / 下步
- 若实机仍有零星漏点: 优先查是否 `BarFrame` 判定线读取异常 (notePrevY 兜底失效场景), 可在 bossRhythmTick 临时加 `logDecision` 打印 lineY/y/prev 三元组确认坐标系是否一致 (AnchorPoint 差异会让 Scale 值差半个音符高)
- 若 Perfect 仍不稳定: 考虑把采样从 StartLoop 0.05 提到事件驱动 (RenderStepped), 但引擎规范限定 StartLoop 下限 50ms, 需改走 AddConnection(RunService.RenderStepped) 并自行节流
- 恩佐 FinalPhase 同套逻辑, 一并受益 (未单独实机验证)

---

## [2026-08-29 | v0.24.6 三故障实机根因修复]

### 用户需求
- v0.24.5 遗留三项: ①自动技能失效(正常钓鱼误报接管恩佐) ②目标鱼过滤失效 ③章鱼二阶段 HP 损失

### Root Cause (根因)

**Bug #1 + #3 同根因**: bossDetectTick 的 `midFight = phase2 or rhythmActive or enzoInFight` (L2304), 其中 `rhythmActive` 被 RhythmStart 监听器(L2395) **无条件**置 true — RhythmStart 是通用信号, 恩佐 FinalPhase 与普通 Boss 鱼二段(章鱼等)共用同一套 Rhythm 容器。普通 Boss 鱼二段触发 rhythmActive=true → bossDetectTick 看到 midFight=true → 调 startBossFight() → 弹"恩佐已接管"(Bug #1) + bossPhase2Tick 启动盲发 BossPhase2Action:FireServer({Hit=true}) → 服务器不认该 Boss 鱼的 Phase2 协议 → 扣血/维妮塔(Bug #3)。

**Bug #2**: Config:Load 恢复 Flag 顺序不确定, 鱼多选 targetFishSel 回调可能先于分组 targetFishGroup 恢复, 分组 rebuild 清空已恢复勾选; 原 task.defer 兜底与 LoadConfig 存时序竞争(L2044-2057), defer 在脚本加载尾跑但 LoadConfig 在 L3589 更晚 → defer 时 Config 尚未恢复, lastFishSel 可能仍为 nil → 重套失败。

### 改动 (hub.luau)

- L2304: `midFight = phase2 or rhythmActive or enzoInFight` → `midFight = enzoInFight`
  - 普通 Boss 鱼节奏由 bossRhythmTick 独立处理(不受 midFight 影响), 不走恩佐接管链路
  - enzoInFight = workspace.NPC.Enzo.InFight, 仅恩佐开战时服务器置 true, 权威无误判
- L308: 新增 `targetFishRestoreFn` 文件级变量
- L2042-2057: 删 task.defer, 改赋闭包给 `targetFishRestoreFn`
- L3591: LoadConfig() 之后调用 `pcall(targetFishRestoreFn)` 显式重套
- L3654: dbg.state 新增 targetFishEnabled / targetFishCount 字段

### 验证
- 静态门: check-script 0 error 0 warning (两轮, 改 midFight + 加 dbg 字段)
- 动态门: execute-file 重跑 0 startup error, 热替换接管成功
- Bug #1/#3: 诊断日志 `[恩佐检测] active=false cfgInFight=false npcInFight=false isBossFish=true` 确认普通 Boss 鱼钓鱼时 bossActive 保持 false, 未弹"恩佐已接管", 未触发 bossPhase2Tick
- Bug #2: dbg.state targetFishCount=22 (持久化恢复的 22 条鱼正确填充), 旧版 task.defer 在此场景下会因时序竞争清空

### 遗留
- 鱼竿制作分组中文名飞鱼帝/飞鱼后/霜王翠鸟/血玉鱼/无名章寄 (GROUP_DEFS L1932) 在 Inventory 中非 key, 通过 CN_ALL 反查路径过滤可命中(实机 eval HIT), 但若游戏改名 CN_ALL 需同步更新

---

## [2026-08-29 | v0.24.5 恩佐二阶段小游戏禁放技能]

### 用户需求
- 恩佐全自动战斗二阶段小游戏阶段不应释放技能, 脚本自动放技能导致严重维妮塔(扣血)失败。

### Root Cause (根因)
- autoSkillTick 门控仅 `fsmState ~= "战斗中"` 才 return。恩佐接管 startBossFight 置 fsmState="战斗中" 后全程不清除; 节奏小游戏(rhythmActive=true, RhythmStart 无条件置位)与 Phase2(`Character.Phase2==true`)期间 fsmState 仍是"战斗中" → 技能/蓄力代点照常执行。技能动画干扰小游戏判定 → 服务器判失误扣血。

### 改动 (hub.luau)
- autoSkillTick @1091: `if rhythmActive then return end` + `if Character:GetAttribute("Phase2")==true then return end` (门控在 fsmState 检查之后, 紧接自治跨场检测前)。
- autoCharge 蓄力代点 @2226: 同上两道门控, 节奏/Phase2 期间不代点 Charge 按钮 (乱点同样打乱判定)。
- 正常战斗(非小游戏)放技能逻辑完全不变。

### 验证
- 静态: 两处门控 reads 确认插入位置正确, 不影响 fsmState/节奏接管链路。
- 待实机: 客户端未连接, 无法跑恩佐二阶段验证维妮塔消失; 下次联机需确认节奏/Phase2 期间技能静默 + 正常 Phase1 仍放技能。

### 遗留
- 自动技能失效(正常钓鱼也说接管恩佐)、目标鱼过滤失效、章鱼二阶段 HP 损失三项仍未实机根因 (需注入 debug 日志抓 fsmState/autoSkillOn/FishID 实时值), 见下方待办。

---

## [2026-08-28 | v0.24.4 自动Perfect内置化+节奏小游戏修正]

### 用户需求
- 完全去除「自动点Perfect」独立开关, 改为内置: 识别到 Slam/Heal/Perfect/QTE 按钮即自动代点 FireServer("Perfect") 销毁, 无需开关/UI/热键/持久化。
- 修复恩佐 FinalPhase 及章鱼等 Boss 鱼多命二段节奏小游戏后面阶段完全失效。

### Root Cause (根因)
- 节奏失效三因: ① 音符(Note_FX) pv2922 实测直接挂轨道(ProgressionX)下, 非 NoteFrame 容器内 → 原 bossRhythmTick 只扫 NoteFrame 子节点漏掉后面阶段; ② 判定线取死值 0.85, 实机需读 BarFrame.Position.Y.Scale; ③ RhythmStart 原门控 fsmState=="战斗中", 章鱼二段触发时 fsmState 非战斗中 → 不接管。
- 附带发现 bossDetect/bossPhase2 每帧 `attempt to call a nil value`: 原 `local bossDetectTick, bossPhase2Tick` 前向声明创建 local 遮蔽后方全局定义 → StartLoop 拿到 nil 回调。删前向声明后 (函数本就全局定义) 解决, 恩佐检测循环不再崩溃。

### 改动 (hub.luau)
- Slam handler @2210: 去除 autoSlamOn/bossActive 门控, 改为 task.delay(0.3) 扫 TrashCan 匹配 Slam|Heal|Perfect|QTE → FireServer("Perfect") + Destroy。
- bossRhythmTick @2385: 扫 track:GetChildren() 中 Note 对象(排除 NoteFrame); 判定线 lineY = BarFrame.Position.Y.Scale or 0.85; 命中 |y-lineY|≤0.22 → RhythmHitEv:FireServer("hit")。
- RhythmStart @2400: 去 fsmState=="战斗中" 门控, 任意节奏开始即 rhythmActive=true + StartLoop bossRhythm 0.05。
- 删除: autoSlamOn 变量/MainTab「战斗策略」Section Toggle/hkSlam 热键/dbg.state 字段/setSlam 函数/前向 local 声明。
- ScriptVersion 0.24.3→0.24.4; 头部注释 [0.24.3]→[0.24.4]。

### 验证
- 静态门: check-script 0 error (8 warning 全为预存前向引用误报, 运行时已验证正常)。
- 动态门: 重跑 client 7876 启动 0 error, 原 bossDetect/bossPhase2 nil 报错消失。

### 遗留
- 恩佐 FinalPhase / 章鱼二段节奏实机全自动通关待实战确认 (逻辑已据 pv2922 逆向修正)。

---

## [2026-08-28 | v0.24.3 恩佐BOSS并入自动钓鱼]

### 用户需求
- 恩佐BOSS功能完全失效。用户要求完全融合进入自动钓鱼: 手动开恩佐挑战后开自动钓鱼即自动识别恩佐并接管战斗全流程; 不打开「智能释放技能」时除技能外其余仍全自动。

### 改动 (hub.luau)
- 删除 setBossMode 函数及 BossTab 独立「自动战斗」开关 (toggleEls.bossMode)。
- bossModeOn 改为纯镜像 autoFishOn: setAutoFish 内 `bossModeOn = autoFishOn`, 并统一启停 bossDetect(0.4s)/bossPhase2(0.1s) 循环; 关自动钓鱼时若 bossActive 则 stopBossFight()。
- Slam/控条守卫 `not bossModeOn` → `not bossActive`; stopBossFight 内 `if bossModeOn` → `if autoFishOn`。
- 注入初始化 `setBossMode(false)` 与 `toggleEls.bossMode:Set(false)` 删除; 调试接口 setBoss 改指 setAutoFish。
- 头部 [0.24.2]→[0.24.3]; ScriptVersion 0.24.2→0.24.3。
- BossTab 使用说明更新为合并后流程; 保留「智能释放技能」独立开关 + 「强制接管/退出战斗」兜底按钮。

### 设计决策
- 技能释放仍由 bossSkillOn 独立控制 (autoSkillTick 门控 `bossActive and bossSkillOn`), 满足"关技能则除技能外全自动"。
- 不采用旧遗留方案 (bossModeOn 也接技能), 与用户"不打开智能释放技能就不放技能"的明确意图一致。

### 验证
- [待实机] 开自动钓鱼→传送到恩佐开战→看诊断日志 npcInFight=true 触发 startBossFight→控条/Phase2/Rhythm 全自动; 关 bossSkillOn 时仅技能不自动。

### 遗留
- 同 v0.24.2: enterFight 控条 Phase1 生效未实机确认; Phase2 BossFightBar / FinalPhase Rhythm 自动通关待实战验证。

---

## [2026-08-28 | v0.24.2 恩佐开战检测信号修正]

### 用户需求
- v0.24.1 修复后仍"没用": 启动自动BOSS打恩佐完全无效果。

### Root Cause (根因)
- v0.24.1 假设 fishesFolder 内恩佐实体带 Boss&&HasPhaseLeft 属性 → 实机 v2922 证伪: 恩佐模型 (workspace.NPC.Enzo) 属性为 InFight/Minigame/OnCooldown/ViewportPosition/ViewportRotation, **无 Boss/HasPhaseLeft**; `LocalPlayer.FishID` 战斗时不指向 workspace.Fishes 内实体 (fish not found, 但 fishes 有 4 子) → isBossFish 永 nil; `BossSetUp.Enzo.InFight` 实测恒 nil (配置表无此属性)。
- **唯一可靠信号 = `workspace.NPC.Enzo.InFight`** (NPC 模型镜像, 开战时服务器置 true; BossUI refresh() 据此禁用 Fight 按钮)。job enzo-infight-spy 抓到 npcInFight=true 全程 (t=1~134), cfgInFight 恒 nil → 坐实 NPC 模型属性为权威信号。

### 改动 (hub.luau)
- bossDetectTick (line 2299): 检测信号改为 `enzoInFight = enzoInFightCfg(BossSetUp.Enzo.InFight) or enzoInFightNpc(workspace.NPC.Enzo.InFight)`, 后者为权威; 其余 isBossFish/phase2/bfBarVisible/rhythmActive 仍作辅助。
- 加 2s 节流诊断日志 `logDecision("[恩佐检测] active/cfgInFight/npcInFight/phase2/bfBar/rhythm/isBossFish")`, 便于实机确认接管触发。
- 头部 [0.24.1]→[0.24.2]; ScriptVersion 0.24.1→0.24.2。

### 验证
- [待用户重跑实测] 重跑 0.24.2 进入/处于恩佐战斗 → 看诊断日志 npcInFight=true 应触发接管(startBossFight); 若仍无效应贴日志。
- 注意: 恩佐 Phase1 = 纯技能 DPS (UseSkill Z/X/C/V, 无血条无 GUI), **接管后仍需开启「智能释放技能」(bossSkillOn) 才能对 Phase1 造成伤害**; 仅开 bossModeOn 不开发技能则 Phase1 不掉血 (autoSkillTick 门控 bossActive and bossSkillOn)。

### 遗留
- 接管后 enterFight 控条是否真生效未实机确认 (Phase1 无条, BarFrame.Bar 路径待复核); Phase2 BossFightBar / FinalPhase Rhythm 自动通关待用户实战验证。
- 若用户要"一个开关搞定", 可将 bossModeOn 也接上技能释放 (改 autoSkillTick: bossActive 时 skillActive = bossSkillOn or bossModeOn) — 待用户确认。

---

## [2026-08-28 | v0.24.1 恩佐开战检测失效修复]

### 用户需求
- 用户: 开启了恩佐「自动战斗」(bossModeOn), 未开「智能释放技能」(bossSkillOn), 结果全程无效 (控条/Phase2/节奏全没接管)。

### Root Cause (根因)
- bossDetectTick 三个检测信号在恩佐 Phase1 全 false:
  1. `isBossFish`: 靠 LocalPlayer.FishID 索引 fishesFolder 实体 Boss=true; 但恩佐主阶段**不控 FishingMinigame**, FishID 不指向恩佐实体 → 永 false
  2. `phase2`: Character.Phase2 attribute, 仅 Phase2 阶段 true → Phase1 false
  3. `bfBarVisible`: BossFightBar.Visible, Phase1 控条 UI 常不显示 → false
- → bossActive 永 false → startBossFight 永不调用 → 控条/Phase2 点击/节奏全瘫 (完美解释"全程无效")
- 注: 实机 v2922 验证 Events.StartBossFight/BossPhase2Action/RhythmStart/RhythmHit/RhythmStop 全存在 (事件名未因更新变更); Character 确有 Phase2 属性 (Phase2 检测这行本身没错)

### 改动 (hub.luau)
- 状态区 (line 273 后): 新增 bossEverConfirmed / lastConfirmedFight
- bossDetectTick (line 2296):
  - 新增 fishesFolder 扫描 (Boss && HasPhaseLeft 实体) 作 hasBossEntity 辅助信号 (恩佐实体带 HasPhaseLeft, 不依赖 FishID)
  - 结束判据改为: 用户关开关 OR (曾确认战斗 AND 信号持续消失>2s) — 避免 Phase1 无信号被误停
- OnClientEvent 监听 (line 2396 后): StartBossFight.OnClientEvent / BossPhase2Setup.OnClientEvent 推送即 task.spawn(startBossFight) 接管 (L1 安全, 非 hook, 不污染 UI 点击链路, 合规 line 282)
- BossTab (line 3431 前): 新增「强制接管 / 退出战斗」按钮 (100% 兜底, 自动检测失败也能用)
- 头部 [0.24.0]→[0.24.1]; ScriptVersion 0.24.0→0.24.1
- 版本动作: bug 修复 → PATCH → v0.24.0→v0.24.1

### 验证
- [待用户重跑实测] 热替换接管 + 恩佐开战自动接管验证 + 强制接管按钮兜底
- 静态门: 用户 Real 编辑器打开 hub.luau 跑 check-script (CLI 内无法对 3886 行传 content; 走开发态重跑实测)

### 遗留
- StartBossFight.OnClientEvent 是否真触发未知 (已加 Notify 反馈); 即使不触发, 强制接管按钮 100% 兜底可用
- hasBossEntity 在普通多命鱼(虎沼鱼)时也 true, 但 bossModeOn 开启时自动钓鱼已互斥停止, 误触发接管无害

---

## [2026-08-28 | v0.23.0 一次性大招时机门 + 多命鱼假血感知]

### 用户需求
1. 识别一次性技能 (如万古/无我, 超长CD数百秒~9900000s), 在敌人血量充足时用, 不浪费。
2. 理解多命鱼假血机制: 如虎皮鱼(虎沼鱼) 3 条命, 前两条 10000 血但到 2000 就回满变下一条命, 只有最后一条命是完整血。

### Real 实机确认 (关键数据)
- **鱼配置 Phase 字段**: `Info.Inventory[鱼名].Phase` = 总命数 — 虎沼鱼 Tiger Mirefish=3 (用户"虎皮鱼" ✓), 幻影灯笼鱼=2, 章寄鱼 Octoparasitic Fish=2, **无名章寄 Nameless Octoparasite=8**, Trout=1(单命)
- **无名章寄 FinalPhase 配置**: HPFinalPhase=20000/MiniGameTime=120/HealHP=50/LoseHP=200 — 8 命打完进 FinalPhase 音游 (20000 血最后一命)
- **一次性大招全集** (CD≥120s, 7 个): Sever the Gate 系×3(9900000, 蜀道山) / Ruinous Sacrifice(999) / One Hook Dominance(999, 神云) / Egoless Technique(999, 血=无我) / Pure Yang Wuji(999, 纯阳); 普通技能 CD 全 ≤60
- **阶段切换客户端信号**: fish.Value(dealt, 客户端维护) 大幅回跳 (>400) 或 MaxHealth attribute 变化 = 假血回满; 服务器显式 `FinalPhase` attribute 标记最后一条命
- 鱼配置 Time=10000 即 MaxHealth fallback (服务器写 attribute)

### 改动 (hub.luau)
- **变量区**: currentFishName(开始包 FishName 存储, 供取 Phase) / phaseSwitches / lastDealt / lastMaxHp / ULT_CD_MIN=120
- **classifySkill**: CD≥120 → "ult" (一次性大招, 优先于 heal/buff 判定 — 无我带 Power 也是 ult)
- **getFishPhases(name)**: 读 Info.Inventory.Phase, 缓存
- **autoSkillTick**:
  - 新战斗(FishID 变化)重置 phaseSwitches/lastDealt/lastMaxHp
  - 每 tick 多命监测: dealt 回跳>400 或 MaxHealth 变化 → phaseSwitches+1 (logDecision 提示第几条命)
  - finalPhase = phases≤1 或 FinalPhase attribute 或 phaseSwitches+1≥phases
  - ultOK = finalPhase 且 fishHp≥0.30 (fishHp nil 放行=恩佐等无血量实体)
  - 开场倾泻/顺序模式/智能择优三路统一受 ultOK 门控; 顺序模式与择优加空池防护 (全 ult 未到时机时 return 不崩)
- 开始包监听: currentFishName = fishInfo.FishName
- 头部 [0.22.0]→[0.23.0]; ScriptVersion 0.22.0→0.23.0
- 版本动作: 新功能 → MINOR → v0.22.0→v0.23.0

### 验证
- luaparse 语法门通过 (3644 行); 注入零错误
- 实机数据链路: 虎沼鱼 Phase=3/无名章寄=8/灯笼鱼=2/章寄鱼=2/Trout=1; 无我/万古/纯阳无极/一钩定乾坤 全判 ult; 龙鱼活力=heal; 天坠践踏=dps ✓
- 遗留: 回跳监测阈值 400 需实机钓多命鱼验证 (dealt 回跳幅度/是否 MaxHealth 变化主导); FinalPhase 音游阶段的 ult 行为 (SkillLocked 天然挡住) 待无名章寄实测

---

## [2026-08-28 | v0.22.0 智能技能四层决策 + 全UI文案精简]

### 用户需求
1. 简化所有界面, 功能描述简洁易懂, UI 好用。
2. 拓展技能释放: 释放技能要像真人一样高效 — 选: 元素匹配加权 + 血量阶段感知; 补充: 自身血量保命(有回血技时血低优先回血, 不无脑放攻击); 要求 Real 分析游戏找更好方案。

### Real 实机数据确认 (数据源验证)
- 竿元素: `Info.Inventory[竿].Description` = "Increases 100% damage for Maoshan skills" → match `"for ([%w ]+) skills"` 提取元素, `cfg.Damage`=加成%(100→×2.00); 实测茅山竿 ×2.00
- 技能元素: `Info.Skill[名].Type` 字段 (Cloud/Taiji/Maoshan/Blood/Claw/Beiming/Buddha/Pure Yang/Shu Daoshan…)
- 回血技识别: `Stats.Heal`(龙鱼活力35/河川镇守300/弑血40…) 或 `Stats.GodHeal`(炽焰金刚50=50%最大生命)
- 增益技识别: `Stats.Power`(虎猎+30/枭鹰+999/毁灭牺牲+999…) 或 `Stats.Boost`(下个技能增伤: 魔山破50%/十二共鸣30%)
- 自损警告: `Stats.Bleed`(枭鹰/毁灭牺牲/天宗极艺自扣血) → 血低禁用
- 自身血量: `Humanoid.Health/MaxHealth`; 增益状态: `Character.Stats.RodPower.Value`
- 鱼血量: `workspace.Fishes[FishID].Value`=已扣伤, `MaxHealth` attribute=总血量 → 剩余比例 clamp(1-dealt/maxHp)

### 改动 (hub.luau)
- **新增辅助函数** (autoSkillTick 前): getSkillConfig/getSkillStats(缓存) / classifySkill(heal|buff|dps) / getRodElement(Description 提取元素+倍率, 缓存) / getSkillElement(Type) / getSelfHpRatio / getFishHpRatio / getRodPower
- **autoSkillTick 智能择优分支重写为四层决策**:
  1. 保命回血: selfHp<50% 且 healReady 非空 → 选 Heal 量最大回血技
  2. 鱼残血收尾: fishHp<15% 且 dmgPool 非空 → 直伤倾泻 (跳过 buff)
  3. 增益覆盖: rodPower<=0 且 buffReady 非空 → 放增益 (Bleed 自损技在 selfHp<40% 时从池剔除)
  4. 常规: 元素加权 DPS 择优 (直伤优先, 无直伤才轮到 buff/heal), 同元素技能 ×rodBonus
  - pickBest 内部保留 isChargeSkill 过滤 (蓄力技走独立结算)
- **全 UI 文案精简**: 30+ 控件 Title/Desc 重写为一句大白话 (自动钓鱼/自动点Perfect/自动技能/蓄力时长/智能回正/智能放弃/目标鱼过滤/分组/天气提醒/传送渔场/天气渔场/游商/玩家/点位/自动出售/全卖/锁定规则/手动常锁/价值锁定/智能锁定/自动买饵/保持奔跑/移动加速/恩佐自动战斗/智能释放技能/停止全部/随机切服 等); 技术黑话/冗余括号全删, 功能与 Flag/回调不变
- 头部 [0.21.0]→[0.22.0]; ScriptVersion 0.21.0→0.22.0
- 版本动作: 新功能+文案 → MINOR → v0.21.0→v0.22.0

### 验证
- luaparse 语法门通过 (3555 行); 注入零启动错误; 错误日志 0 条
- 实机数据链路验证: 茅山竿提取元素=Maoshan ×2.00; 当前装备 Egoless Technique 分型=buff(Blood系 元素不匹配) 分类正确
- UI 抽查渲染: 自动钓鱼/智能放弃/传送至天气渔场/立即全卖/价值锁定(0=关闭)/智能释放技能/恩佐自动放技能 等新文案全部生效
- 遗留: 四层决策需实机战斗验证 (钓鱼/恩佐中观察 logDecision: 保命回血/残血收尾/增益覆盖/智能命中 分支输出); 元素匹配依赖 Description 固定句式 "for X skills", 若游戏改文案需重提取

---

## [2026-08-28 | v0.21.0 恩佐独立智能技能 + 节奏小游戏泛化 + 分组名精简]

### 用户需求 (三条)
1. 恩佐BOSS栏目加「单独智能释放技能」开关/模式选项, 跟自动钓鱼Tab的一样, 但互不干扰、独立。
2. 自动钓鱼-目标鱼分组: 「诱饵制作」「鱼竿制作」两分组名后面 "（）" 内容删除。
3. 增强自动钓鱼: 钓到无名章寄(Nameless Octoparasite)打到多条命后出现像恩佐一样的二段小游戏(ASD音游), 让脚本自动操作。

### 需求3 可行性依据 (intel.md 已破解 Rhythm 协议)
- 触发 = Events.RhythmStart; 结束 = RhythmStop 或时限; 3 轨道 ProgressionA/S/D + NoteFrame 音符; 判定窗口 |noteY-判定线|≤0.22 极宽松; 命中 → Events.RhythmHit:FireServer("hit")
- 实机确认: MainGui.Fishing.Rhythm 容器普通钓鱼共用 (ProgressionA/S/D>NoteFrame 结构一致); Events.RhythmStop 存在
- 服务器只认 "hit"/"miss" 字符串, 无需模拟键盘 → 纯 UI 扫描 + 游戏自身事件, L1

### 改动 (hub.luau)
- **变量区**: 删 prevAutoSkill; 加 bossSkillOn/bossSkillMode/rhythmUntil; rhythmActive 注释改通用语义
- **autoSkillTick**: 场景感知 — `bossActive and bossSkillOn or (not bossActive and autoSkillOn)`; 模式同源 `bossActive and bossSkillMode or skillMode` (两开关/两模式互不干扰)
- **setAutoSkill/setBossSkill/syncSkillLoop**: 技能循环统一管理, 任一开关开即 StartLoop("autoSkill",0.5) (StartLoop 幂等先停旧再起新, 无叠加); setBossSkill 独立通知
- **startBossFight/stopBossFight**: 删 setAutoSkill(true)/prevAutoSkill 还原; 改 syncSkillLoop(); stopBossFight 加 StopLoop("bossRhythm")
- **bossRhythmTick**: 去 bossActive 限制, 加 rhythmUntil 130s 超时自停 (TheKing 注释保证循环内 StopLoop 自身迭代安全)
- **RhythmStart 监听**: 去 bossModeOn 限制, 改 fsmState=="战斗中" 即激活 + 动态 StartLoop; **新增 RhythmStop 监听** 即时停扫
- **setBossMode**: 删静态 StartLoop/StopLoop("bossRhythm") (改动态启停)
- **stopFight**: 加 rhythmActive=false + StopLoop("bossRhythm") (战斗结束清残留, enterFight/放弃/收竿共用)
- **GROUP_DEFS/GROUP_ORDER**: 「诱饵制作分组(…配方…)」「鱼竿制作分组(…配方…)」→ 纯「诱饵制作分组」「鱼竿制作分组」 (配方说明仅存 devlog/intel)
- **UI**: BossTab 加 toggleEls.bossSkill Toggle(不设Flag, 注入默认关) + 模式 Dropdown(Flag="bossSkillMode" 持久化模式); 「停止全部功能」按钮加 bossSkillOn=false + syncSkillLoop
- 头部 [0.20.6]→[0.21.0]; ScriptVersion 0.20.6→0.21.0
- 版本动作: 新增功能+文案 → MINOR → v0.20.6→v0.21.0

### 验证
- luaparse 语法门通过 (3405 行); 实机注入零启动错误
- UI 实机渲染确认: 「智能释放技能 (独立)」「技能释放模式 (恩佐)」在恩佐 Tab; 「诱饵制作分组」「鱼竿制作分组」已去括号
- 错误日志 0 条; 脚本状态正常 (sellableNow=21)
- 遗留: Rhythm 普通钓鱼实机触发 (钓无名章寄二段) 待用户挂机自然验证; 若音符路径与恩佐不同 (容器名变体) 需按实机 GUI 校准

---

## [2026-08-28 | v0.20.6 目标鱼过滤分组重组修正: 诱饵制作/鱼竿制作 两分组]

### 用户反馈(v0.20.5 纠错): 我要的是「诱饵制作分组」「鱼竿制作分组」两个分组, 分组里面是该制作线要钓的全部鱼(括号标注子配方鱼构成); 不是拆成 6 条。同理 v0.20.5 误拆已废。

### 改动 (hub.luau)
- GROUP_DEFS: 删 冰霜/彩虹/无名鱼饵分组(旧 3 条) + v0.20.5 误加 6 条; 改 2 条:
  - 诱饵制作分组（冰霜饵: 升华鲈鱼+霜王翠鸟+太初鲲皇+战鲨 | 彩虹饵: 巨型虎鱼+赤雷鳗+黄金守护鱼+穿天龟 | 无名饵: 幻影灯笼鱼+高山鱼+章寄鱼+虎沼鱼） → 鱼=3 饵配方鱼并集 12 种 EN
  - 鱼竿制作分组（穿天竿: 飞鱼帝+飞鱼后+穿天龟+彩虹龙鱼 | 纯钻竿: 霜王翠鸟+霜后鱼+血玉鱼+龙纹锦鲤 | 圣竹竿: 无名章寄+重生河豚兽+升华鲈鱼+高山鱼） → 鱼=3 竿配方鱼并集 12 种 (穿天龟=Heavenpiercer Turtle、升华鲈鱼=Ascended Perch、高山鱼=Mountain Fish 用 EN, 余 9 中文)
- GROUP_ORDER: 3 旧键换 2 新键 (诱饵制作分组 在前, 鱼竿制作分组 在后)
- 鱼名过滤: 英文饵鱼走 fishBase(FishName); 中文竿鱼走 cnBase(CN_ALL[fishBase]), 循环 1280 两 key 比对, 同效
- 头部 [0.20.5]→[0.20.6]; ScriptVersion 0.20.5→0.20.6
- 版本动作: 修正(PATCH) → v0.20.5→v0.20.6

### 数据来源
- 饵/竿配方鱼名取自 intel.md (pv2913 逆向): 冰霜饵=升华鲈鱼+霜王翠鸟+太初鲲皇+战鲨; 彩虹饵=巨型虎鱼+赤雷鳗+黄金守护鱼+穿天龟; 无名饵=幻影灯笼鱼+高山鱼+章寄鱼+虎沼鱼; 三神竿=穿天竿(飞鱼帝+飞鱼后+穿天龟+彩虹龙鱼)/纯钻竿(霜王翠鸟+霜后鱼+血玉鱼+龙纹锦鲤)/圣竹竿(无名章寄+重生河豚兽+升华鲈鱼+高山鱼)
- 用户口语名「穿天长毛/纯钻石竿/神圣竹竿」对应 intel「穿天竿/纯钻竿/圣竹竿」, 按用户命名落分组标签

### 验证
- 待实机 reload: 选「鱼竿制作分组」下拉展开应列 12 种合成鱼(中英混), 勾选后只钓这些鱼; 中文鱼经 cnBase 命中
- 遗留: 若某中文竿鱼 CN_ALL 无对应, 该鱼不过滤(数据缺口非代码错); 用户报则补 EN

---

## [2026-08-27 | v0.20.4 目标鱼过滤分组+勾选持久化]

### 用户反馈: 功能可用了, 给目标分组和选择目标鱼做持久化

### 改动 (hub.luau)
- 鱼多选下拉加 Flag="targetFishSel" (原仅目标鱼分组有 Flag="targetFishGroup")
- 持久链路: 重载时 WindUI Config:Load 恢复 Flag → 分组下拉恢复调 rebuildFishDropdown 重建该组选项并清空 targetFishNames → 鱼多选恢复 → Callback 用已恢复勾选重填 targetFishNames
- 顺序隐患: Config:Load 恢复顺序不确定, 若鱼多选先于分组恢复, 分组 rebuild 会清空已恢复勾选 → 过滤失效。兜底: 鱼回调捕获 lastFishSel, task.defer 在 hub.luau 末尾 TheKing.LoadConfig() 之后重套 targetFishNames (defer 时 lastFishSel 已是恢复值), 与恢复顺序无关
- 头部 [0.20.3]→[0.20.4]; ScriptVersion 0.20.3→0.20.4
- 版本动作: 小增强 (PATCH) → v0.20.3→v0.20.4

### 验证
- 实机 reload 日志印证持久化生效: 鱼多选回调 "命中 4 条"、开关 "当前选中=8" (4 鱼 en+中文各 1 = 8 条目), 分组+勾选均恢复
- [DBG] 临时日志已移除 (持久化确认后)

---

## [2026-08-27 | v0.20.3 目标鱼过滤开关打死 targetFishEnabled 修复]

### 用户反馈: 选了冰霜鱼饵分组勾全部鱼, 仍什么鱼都钓 (不过滤); 且分组选择器应排在选择鱼上方

### 排查路径
- v0.20.2 开关 Callback: `if state and not next(targetFishNames) then targetFishEnabled=false; return end`
- 开关带 Flag="targetFishFilter", WindUI 配置持久化: 重载/重跑自动恢复上次开关状态并触发 Callback
- 恢复为 ON 时 targetFishNames 为空(不持久化) → 回调把 targetFishEnabled 打死成 false
- 结果: UI 开关显示开, 但 targetFishEnabled=false, 循环 1276 `next(targetFishNames)` 假 → 不过滤; 用户后续勾鱼也不生效(开关已死)
- 实机 reload 日志印证: "[DBG] 目标鱼过滤开关=true 当前选中=0" (旧逻辑下此处 targetFishEnabled 已被置 false)

### 修复 (hub.luau)
- 开关 Callback 去掉强制关闭: 开启即 targetFishEnabled=state, 空选仅 Notify 提示, 不再 return 打死
- 过滤实际生效条件保持: 循环 1276 仍要求 targetFishEnabled 且 next(targetFishNames) 才过滤 (选鱼后才生效)
- 鱼多选 Callback: 回传同时写 targetFishNames[en] 与 targetFishNames[中文] (防 FishName 属性是中文导致 key 错位), 循环 1280 两种 key 都比对
- 目标鱼分组选择器移到选择鱼下拉上方 (UI 排版)
- 临时加 [DBG] 日志定位(开关/选鱼/放弃分支), 验证通过后将移除
- 头部 [0.20.2]→[0.20.3]; ScriptVersion 0.20.2→0.20.3
- 版本动作: bug 修复 (PATCH) → v0.20.2→v0.20.3

### 验证
- live-reload 编译通过 (returns "applied"); 注入接管成功
- 日志显示开关恢复 ON 时 targetFishEnabled 不再被打死

### 遗留 / 风险
- 开关 ON 但没选鱼时仍不过滤(正确行为); 若希望"选鱼自动开过滤"可去掉手动开关
- [DBG] 日志为临时调试, 确认后需移除

---

## [2026-08-27 | v0.20.2 目标鱼过滤选中不生效 修复]

### 用户反馈: 切换分组能用, 但目标鱼过滤功能失效 (勾选鱼不过滤)

### 排查路径
- v0.20.1 鱼多选下拉 `Values={}` 空列表创建, 默认 :Refresh(全部分组) 填充
- WindUI Dropdown 空列表创建后 :Refresh 灌入选项, 选项按钮点击回调可能未绑定 → 勾选不触发 Callback → targetFishNames 恒空 → 循环 1276 `next(targetFishNames)` 为假, 不过滤(抓所有鱼)
- 分组选择器本身正常(独立单选下拉), 故"能切换分组但过滤失效"

### 修复 (hub.luau)
- 提取 `buildChoiceList(enList)` 复用标签构建
- 鱼下拉初始用 `buildChoiceList(allFishEn)` 非空列表创建 (Values=initList), 确保 WindUI 绑定回调
- 切分组仍走 `fishDD:Refresh(cl)` (populated→populated, 同 pointDropdown 写法稳定)
- 头部 [0.20.1]→[0.20.2]; ScriptVersion 0.20.1→0.20.2
- 版本动作: bug 修复 (PATCH) → v0.20.1→v0.20.2

### 验证
- live-reload 编译通过 (returns "applied"), 注入接管成功, 无 client error
- 逻辑链路: 勾选→Callback 写 targetFishNames[英文名]=true→循环 1280 比对 fishBase(英文) 命中即保留, 与 v0.19.0 验证一致

### 遗留 / 风险
- 仍依赖"切分组清空选择"的隔离语义(用户原要求); 若希望跨组累加需改 rebuildFishDropdown 不清空

---

## [2026-08-27 | v0.20.1 目标鱼分组下拉点不开 修复]

### 用户反馈: 全部分组(默认)下拉点不开/展开不了

### 排查路径
- 注入 v0.20.0 后控制台无报错, 但鱼多选下拉点击不展开
- 对照脚本内正常多选下拉 (1757 天气关注): Multi=true 时 Value 必须是 table
- 本下拉传了 Value = choiceList[1] (字符串) → WindUI 展开构建选项时炸, 表现即"点不开"
- 原切换分组用 fishDD:Destroy()+重建: WindUI Dropdown 文档未列 :Destroy(仅 Button/Paragraph 有), 且重建复用同 Flag 易冲突, 实现脆弱

### 修复 (hub.luau)
- 鱼多选下拉 Value 改 {} (table, 初始不勾选), Multi=true 保持
- 切分组不再 Destroy 重建, 改 fishDD:Refresh(choiceList) 动态刷新选项(复用 2369 pointDropdown 写法, 先判 type(Refresh)=="function" 再 pcall)
- choices(label→en 映射) 提为 do 块外层 local, Callback 闭包随分组更新正确命中
- 头部 [0.20.0]→[0.20.1]; ScriptVersion 0.20.0→0.20.1
- 版本动作: bug 修复 (PATCH) → v0.20.0→v0.20.1

### 验证
- live-reload 编译通过 (returns "applied"), 注入接管成功, 无 client error

### 遗留 / 风险
- 鱼标签可能重复(同岛同鱼名)理论会让 WindUI 报错, 当前数据无重复; 若日后出现重复 Label 需去重

---

## [2026-08-27 | v0.20.0 目标鱼过滤分组隔离版 增强]

### 用户需求: 目标鱼过滤做成分组版本且互不干扰 — 全部分组/天气鱼/各鱼饵/球体/功法/各岛屿, 切换分组清空旧选择

### 排查路径
- 原目标鱼过滤只有单一全鱼多选下拉 (1540), 无法按维度(鱼饵/岛屿/掉宝)筛选
- 用户要求「真互不干扰」: 切换分组旧勾选全废, 只以新分组鱼过滤

### 修复 (hub.luau)
- 新增「目标鱼分组」单选下拉 (1631), 17 个组: 全部/BOSS/天气鱼/冰霜·彩虹·无名鱼饵/球体/功法 + 10 岛屿(新手/竹子/核弹/主权/鲈鱼/冰霜/椰子/琥珀/战场/迷雾)
- 鱼多选下拉改为运行时重建: `rebuildFishDropdown(groupKey)` (1597) 按 GROUP_DEFS 取该组鱼英文名列表 → 汉化标签 → 排序; 切换分组先 `targetFishNames={}` 清空(隔离), 再 `fishDD:Destroy()` + 新建下拉
- 分组数据源:
  - 全部 = 全鱼列表(Inventory+FishingAreaRarity 兜底)
  - 天气鱼 = WEATHER_FISH_SET
  - 冰霜/彩虹/无名鱼饵 = 用户指定 4 鱼硬编码(英文, 取自 CN_ALL 反查)
  - 球体 = 扫描 Info.Inventory 鱼模块 Reward.Orb (4 种, 实机验证)
  - 功法 = 扫描 Reward.Skill (24 种, 与 intel Reward 类型全集一致)
  - BOSS = 扫描鱼模块 Boss=true 字段 (46 种 = 可多人钓的 BOSS 鱼, 实机验证)
  - 岛屿 = 反查 FISH_ISLE_MAP (isleEn→该岛鱼列表)
- 头部 [0.19.0]→[0.20.0]; ScriptVersion 0.19.0→0.20.0
- 版本动作: 显著增强 (MINOR) → v0.19.0→v0.20.0

### 验证
- live-reload 编译通过 (returns "applied"), 注入接管成功
- 实机扫描: totalModules=149, boss=46, skill=24, orb=4 — 各动态分组均非空
- 注入后控制台仅 CDN 兜底警告, 无运行期错误

### 遗留 / 风险
- WindUI Dropdown 无动态 Values 刷新, 切换分组走 Destroy+重建(已验证可行)
- 鱼饵分组鱼名为硬编码英文(用户给定中文经 CN_ALL 反查确认), 游戏大改鱼饵体系需同步更新

---

## [2026-08-27 | v0.19.0 目标鱼过滤快放弃(按1收竿瞬重置) 增强]

### 用户需求: 增强选择目标鱼功能 — 非目标鱼时直接按1收竿再按1拿竿, 比原放弃更快

### 排查路径
- 原目标鱼过滤在 `等咬钩` 态(咬钩未进战)识别非目标鱼后调 `doGiveUp` (1096)
- `doGiveUp` 走"等结算"态: 断条出界 + 等服务器清 FishID, 兜底 8s (`giveUpDeadline`) → 慢
- 游戏中按 1 收起钓鱼竿可即时取消咬钩, 再按 1 拿起复位, 比等服务器结算快得多 (用户实机经验)

### 修复 (hub.luau)
- 新增 `VirtualInputManager` 服务引用 (285)
- 新增 `fastCancelTarget(label)` (1112 后): `stopFight()` + `fsmState="待机"` + `giveUpAt=nil`; `VirtualInputManager:SendKeyEvent` 发 `Enum.KeyCode.One` 收竿, 间隔 0.18s 再发一次拿竿; `cooldownUntil=now+0.5` 避免拿竿动画期间抢抛; `autoFishOn` 关时跳过第二次拿竿
- 目标鱼过滤非目标分支 (1260) 由 `doGiveUp` 改为 `fastCancelTarget`, 状态机回待机由自动抛竿循环无缝接管
- 智能放弃(战斗中力量/停滞/超时)仍走 `doGiveUp` 不变 (战斗中收竿不稳, 不混用)
- 头部 [0.18.3]→[0.19.0]; ScriptVersion 0.18.3→0.19.0
- 版本动作: 显著增强 (MINOR) → v0.18.3→v0.19.0 (机制变更: 新增按键输入路径, 拿不准按更高一级)

### 验证
- live-reload 编译通过 (returns "applied"), 注入接管成功
- 注入后控制台仅 CDN 兜底警告, 无运行期错误

### 遗留 / 风险
- 依赖游戏"按1=收/拿竿"绑定 (用户提供); 若鱼竿不在 1 号槽或游戏改键则失效, 届时回退 doGiveUp 或抽键位配置
- VirtualInputManager 模拟属 L1 人类化输入, 非 hook, 反作弊风险低

---

## [2026-08-27 | v0.18.3 天气传送雾蒙蒙偏好椰子岛 修复]

### 用户需求: 雾蒙蒙天气两岛(椰子岛/雾峰岛)都有特殊鱼, 但传送要去椰子岛

### 排查路径
- `WEATHER_ISLE_MAP.Foggy` 有 ["Coconut Isle"] + ["Mistpeak Isle"] 两岛
- 原天气渔场传送逻辑 (1975-2014) 用 `for k in pairs(targets) do isleEn = k break end` 取"第一个"岛, Lua 字符串键迭代顺序不定 → 雾蒙蒙时可能传去雾峰岛
- 仅此一处用 WEATHER_ISLE_MAP 选岛 (天气预报走 WEATHER_FISH 仅提醒, 不受影响)

### 修复 (hub.luau)
- 选岛逻辑改为: 多岛屿天气优先用户偏好岛, `preferred = (weather == "Foggy") and "Coconut Isle" or nil`; 命中且 targets 含该岛则用之, 否则回退取第一个
- 头部 [0.18.2]→[0.18.3]; ScriptVersion 0.18.2→0.18.3
- 版本动作: 偏好修正 (PATCH) → v0.18.2→v0.18.3

### 验证
- live-reload 编译通过 (returns "applied"), 注入接管成功
- 注入后控制台仅 CDN 兜底警告, 无运行期错误

### 遗留 / 风险
- 偏好为硬编码单行 (Foggy→Coconut Isle); 若新增其他多岛屿天气需扩展, 届时抽成映射表

---

## [2026-08-27 | v0.18.2 删除传送鬼魂(9178)相关功能 移除]

### 用户需求: 删除传送鬼魂相关功能 ("都没用")

### 排查路径
- grep 全脚本: 鬼魂相关共 15 处命中, 集中在 4 块:
  1. `findGhostModel()` + `tpToSpirit()` 两个函数 (原 2022-2072)
  2. TeleportTab "传送至当前鬼魂" 按钮 (原 2160)
  3. TeleportTab "NPC 大全" 段落 (Section + Paragraph + "传送至鬼魂" 按钮, 原 2205-2216)
  4. 头部 intel 注释行 + 功能清单 "NPC大全(鬼魂图鉴)"
- 确认无鬼魂专属循环/连接: 游商提醒连接属 MerchantNPC, 保留; 鬼魂代码仅为函数 + 按钮, 无持久循环

### 修复 (hub.luau)
- 删除 `findGhostModel()` 与 `tpToSpirit()` 函数 (及前置鬼魂注释)
- 删除 "传送至当前鬼魂" 按钮 (Callback 指向已删 tpToSpirit)
- 删除 "NPC 大全" 整段 (Spirit 图鉴 Section/Paragraph/按钮)
- 功能清单移除 " / NPC大全(鬼魂图鉴)"
- 头部 intel 注释移除鬼魂NPC行
- 头部 [0.18.1]→[0.18.2]; ScriptVersion 0.18.1→0.18.2
- 版本动作: 移除功能 (PATCH) → v0.18.1→v0.18.2

### 验证
- live-reload 编译通过 (returns "applied"), 注入接管成功
- 注入后控制台仅 CDN 兜底警告, 无运行期错误
- grep 复检: 鬼魂/Spirit/tpToSpirit/findGhostModel/9178/ghost 残余引用均已清除 (仅存 Boss 名映射 `Spirit = "精魄使徒"`, 无关)

### 遗留 / 风险
- 无 (纯删除, 不影响游商/普通NPC/服务器玩家传送)

---

## [2026-08-27 | v0.18.1 奖励弹窗自动关闭与自动钓鱼解耦 修复]

### 用户需求: 奖励弹窗不会自动关闭 (截图: MultiNotifyReward 卡住没关)

### 排查路径
- 原奖励自动关闭逻辑写在 autoFishTick() 内; autoFishTick 仅由 StartLoop("autoFish", 0.4) 驱动, 该循环只在自动钓鱼开启时活动
- 结论: 自动钓鱼没开 → 奖励循环不跑 → MultiNotifyReward 弹窗永远不被关 (用户场景)
- 逆向确认: 弹窗真实路径 Players.WoSh1N1D1e.PlayerGui.MainGui.MultiNotifyReward (Frame), 纯展示, 由 PlayerScripts.MultiReward 在 OnClientEvent 设 Visible=true, 游戏自身无关闭逻辑

### 修复 (hub.luau)
- 删除 autoFishTick 内奖励关闭块 (及 rewardGui / rewardPageActive 局部变量, 仅该块使用)
- 新增 setupRewardWatcher(): 对 MultiNotifyReward 挂 GetPropertyChangedSignal("Visible"), 任一状态变 true 即设 false + TheKing.Notify 提示; 弹窗延迟创建时经 MainGui.ChildAdded 补挂
- 启动即调用 setupRewardWatcher(), 与自动钓鱼开关完全解耦
- 头部 [0.18.0]→[0.18.1]; ScriptVersion 0.18.0→0.18.1; 功能清单注明"任意状态下出现即关"
- 版本动作: bug修复 (PATCH) → v0.18.0→v0.18.1

### 验证
- loadstring 编译通过 (syntax OK)
- 注入 v0.18.1 接管成功
- real_eval: 取 MultiNotifyReward, 置 Visible=true 模拟弹窗, 0.6s 后读回 Visible=false → 看守生效 (不再依赖自动钓鱼)

### 遗留 / 风险
- 关闭后游戏 u86 防重标志置位, 本次会话后续奖励页不再弹出 (奖励仍到账, bot 视角可接受, 同 v0.17.0 决策)
- 未触发真实奖励事件实机验证 (已用外部置 Visible 模拟, 行为一致)

---

## [2026-08-27 | v0.18.0 智能锁定·手动常锁鱼种 (修复下拉源)]

### 用户需求: 背包管理智能锁定"扫描不到背包" — 用户背包有特殊鱼(如 Crimson Bream Sovereign / Colossal Tigerfish), 选了规则但不锁定

### 排查路径 (逆向)
- 读 lock 逻辑(439-663) + 智能锁定 UI(2443-2552): 原无"手动选鱼锁定"功能; 用户选的是规则下拉(启用哪些锁定规则), 但其特殊鱼不匹配任何规则 → 0 锁定, 看起来像"扫描不到"
- 更深根因: 我新加的「手动常锁鱼种」下拉源用了 FISH_ISLE_MAP/fishesFolder/infoFolder.Inventory —— real_eval 实测: 背包 34 种真实鱼, 源覆盖=0 命中=0! 这些源根本不含背包真实鱼名(鱼名空间不一致), 下拉为空/错, 用户选不到自己的鱼
- 数据路径: `ReplicatedStorage.Data[userId].Inventory`(非 LocalPlayer); FavoriteItem 协议有效(后缀 `| Favorite`)

### 修复 (hub.luau)
- 新增 `getBackpackFishSpecies()` 直接扫描当前背包真实鱼种(基础名 `^(.-) %|`), 与 `getFishBase` 同名称空间; 下拉清单改由此生成
- `manualLockSet[基础名]` 优先级最高(matchLockByName 首个判定), 命中即锁; Callback 选定即 `scanAndLock()` 扫描锁定现有背包
- 头部 `[0.17.0]`→`[0.18.0]`; ScriptVersion `0.17.0`→`0.18.0`; 功能清单追加「智能锁定·手动常锁鱼种」
- 版本动作: 新增功能(MINOR) → v0.17.0→v0.18.0

### 验证
- `loadstring` 编译通过 (syntax OK)
- 注入 v0.18.0 接管成功 (控制台 `[重型钓鱼@0.18.0]` + `旧实例已销毁, 接管完成`)
- real_eval 端到端: 取真实未锁鱼 `Crimson Bream Sovereign`, `Events.FavoriteItem:FireServer(全名)` → Name 出现 `| Favorite` 后缀(lockedNow=true), 再发一次解锁还原, 状态零污染
- 下拉 now species=34, 全部含真实背包鱼

### 通知增强 (用户要求: 锁定了什么鱼也要发通知)
- `scanAndLock` 改为返回 `locked, names`(names = 本次锁定的鱼基础名列表, 按基础名去重避免同鱼种多实例重复刷屏)
- 新增 `fmtLockList(names)`: 中文名(trName)用 `、` 连接, >12 种截断显示「等 N 种」
- 三处通知(手动常锁选定 / 立即扫描按钮 / 快捷键扫描)均拼接 `fmtLockList`, 例:「手动锁定生效, 新锁定 3 条\n已锁: 绯红鲷鱼之王、巨虎鱼、霜王鱼」
- 验证: 模拟 manualLockSet=3 鱼种(背包 116 实例)→ 去重后唯一鱼种数=3, 通知串仅列 3 个唯一名

### 遗留 / 风险
- WindUI 下拉 Values 无动态刷新方法: 清单在脚本加载时按当时背包生成; 钓到新鱼种后需重跑脚本才出现在清单(ponytail: 不另加刷新按钮, 不过度工程)
- 手动锁定不自动覆盖已锁鱼(scanAndLock 跳过 isLockedFish), 但手动集为空时不影响规则锁定

---

## [2026-08-27 | v0.17.0 自动领取奖励弹窗 修复]

### 用户需求: 自动钓鱼缺少领取奖励机制 — 钓上鱼给宝珠/功法类奖励时, MultiNotifyReward 弹窗不自动关闭, 挡住抛竿导致脚本一直卡在奖励页

### 排查路径 (逆向)
- 全局搜 "RewardUI"/"领取" 0 匹配; 反编译定位 `Players.WoSh1N1D1e.PlayerScripts.MultiReward` (docId 17)
- `Events.MultiNotifyReward.OnClientEvent`: CleanupOld → CreateEntry(克隆 List 下模板 Other/Cash/Ticket/Crystal/Trait Reroll) → 设 `MultiNotifyReward.Visible=true` + 淡入; 函数末尾 `local u90=false; local u91=nil` 是反编译截断的自动关闭残骸 → **游戏自身无可靠关闭逻辑**, 弹窗一弹就挡抛竿
- 奖励由服务器在发包时发放(此页纯展示), 故隐藏不影响到账
- 坑: 脚本内 `u86` 防重复标志, 首帧置 true 后永不复位 → 外部强关 `Visible=false` 会让后续奖励页永不弹出 (bot 视角可接受: 奖励仍到账且不再挡竿)
- Real 约束: `firesignal`/`Connection:Fire`/`Button:Activate()` 均为 no-op; 唯一有效点击是真实鼠标 `mouse1click()`(需窗口聚焦+坐标)。本方案不依赖点击 — 直接 `Visible=false` 即可放行, 更简单稳健

### 修复 (hub.luau)
- line 76 区新增 `rewardGui` 引用 + `rewardPageActive` 去重标志 (惰性补全: tick 内 `FindFirstChild` 补抓, 因弹窗由 PlayerScript 延迟创建)
- autoFishTick 顶部(角色校验后)插入: 检测 `rewardGui.Visible` → 置 false 放行; 每个新弹窗仅 Notify 提示一次
- 头部 `[0.16.3]`→`[0.17.0]`; line 51 `ScriptVersion` `0.16.3`→`0.17.0`; 功能清单追加「自动领取奖励」
- 版本动作: 新增功能(MINOR) → v0.16.3→v0.17.0

### 验证
- `loadstring(readfile("games/heavy-fishing/hub.luau"))` 编译通过 (syntax OK)
- 待实机: 钓出触发奖励的鱼 (Boss 鱼/稀有权限鱼), 观察奖励页是否自动关闭且钓鱼无缝续抛; 控制台确认无 error

### 遗留 / 风险
- 隐藏后 `u86` 永久 true → 整局后续奖励页不再弹出(仅影响展示, 奖励仍到账); 若未来需要"看奖励弹窗"可加开关重置(当前 ponytail: 不过度工程, 不加)
- 未实机触发奖励鱼验证(需用户配合一次或自然触发)

---

## [2026-08-27 | 会话59d | v0.16.3 随机切换服务器失效 修复]

### 用户需求: 随机切换服务器功能失效, 显示"没有可用的服务器"

### 排查路径
- 复现 `game:HttpGet(games.roblox.com/v1/games/{placeId}/servers/Public?limit=100)` → 返回 13404 字节, JSON 结构正常 (previousPageCursor/nextPageCursor/data[]), 非网络/解析问题
- data 样本: 每服 maxPlayers=10, playing=10(满员) 或 9(差1)
- 宽松统计 (playing<maxPlayers): 第一页 100 服中 53 个有空位, 全 9/10
- 对照原过滤 `curP < maxP and maxP - curP >= 2`: 所有有空位服恰差1 → 条件 false → candidates 空 → 误报"没有可用的其他服务器"

### 根因
- line 2874 过滤要求空位≥2; 该游戏服务器容量小(max=10)且常仅余1空位, 条件永远不满足

### 修复 (hub.luau)
- line 2874 `if curP < maxP and maxP - curP >= 2 then` → `if curP < maxP then` (至少1空位即可, TeleportToPlaceInstance 在 playing<maxPlayers 可入)
- 实机复现新逻辑: 候选数 0→51 (第一页非当前有空位服)
- 头部 `[0.16.2]`→`[0.16.3]`; line 51 `ScriptVersion` `0.16.2`→`0.16.3`; changelog 已追加

### 验证
- 热重载后控制台 `[重型钓鱼@0.16.3]`; 无 error
- 新逻辑候选数=51, 可直接点「随机切换服务器」跳转 (目标服 9/10 能进)
- 注: 仅取第一页 limit=100, 51 候选足够随机选; 未翻页 (ponytail: 不过度工程)

---

## [2026-08-27 | 会话59c | v0.16.2 天气传送烈阳高照失效 修复]

### 用户需求: 快捷天气传送在「烈阳高照」传送不了 (其他天气正常, 琥珀岛有 Draconic Koi / Sanguine Fish 限定鱼)

### 根因
- `workspace:GetAttribute("Weather")` 返回无空格格式 (Windy/Snowy/Thunderstorm/Foggy 均无空格且能传; Foggy 已实测返回 "Foggy")
- 唯独四处天气键写成带空格 `"Blazing Sun"`: WEATHER_ISLE_MAP@313 / CN_ALL@106 / watchWeathers@1504 / CN_TO_WEATHER@1507
- 键≠值 → `WEATHER_ISLE_MAP["BlazingSun"]` 查表 nil → 天气提醒 + 天气渔场传送**整条链路失效**
- 游戏脚本内搜 "Blazing Sun" / "BlazingSun" 均 0 匹配 (天气值服务器推送, 客户端不硬编码) → 无法从源码反推真实格式, 依"其他天气全无空格且能传"归纳定论为无空格

### 修复 (hub.luau)
- 四处 `"Blazing Sun"` / `["Blazing Sun"]` 统一改为 `"BlazingSun"` / `["BlazingSun"]` (106/313/1504/1507)
- 改后全链路自洽: GetAttribute→"BlazingSun"→WEATHER_ISLE_MAP命中→传送琥珀岛; trName("BlazingSun")→"烈日" 显示正常

### 风险与验证
- 当前天气 Foggy 无法触发烈阳, **待烈阳高照实机验证**: 点「传送至当前天气渔场」应传琥珀岛; 否则 `workspace:GetAttribute("Weather")` 读真实值校准键名
- 若真实值确为无空格 → 修复成立; 若猜错(真实值带空格) → 仅维持原状(该天气本就全坏), 不波及其他天气
- 头部 `[0.16.1]`→`[0.16.2]`; **运行时版本实为 line 51 `ScriptVersion` 独立变量(此前一直 `0.16.0`, 连 v0.16.1 都未更), 本次 `0.16.0`→`0.16.2`**; changelog 已追加条目

---

## [2026-08-27 | 会话59b | v0.16.1 效率统计背包显示0 修复]

### 用户需求: 自动钓鱼-效率统计「背包显示0」, 要显示真实背包数量

### 排查路径 (函数级)
- 现象: 面板"背包 0 条", 但 debugBag 内 `sellFishCount(true)` 返回 311 正常 → 数据层 OK, 面板写入路径异常
- 加诊断 `_G.RCWTK_BAGTEST`/`_G.RCWTK_BAGERR`: forcePanelDetail 调 updateStatsPanel 后 `okBag=false`, 错误 `"attempt to call a nil value"` → updateStatsPanel 闭包里 `sellFishCount` 为 nil
- 对照: 同实例 `debugBag`(3104行, 在447之后) 引用 sellFishCount 正常 → 锁定 **Lua 前向引用坑**

### 根因
- `updateStatsPanel` 定义在 **388 行**, `sellFishCount` 用 `local function` 定义在 **447 行** (之后)
- Lua 局部变量从**声明语句起**才进入作用域; 388 行定义 updateStatsPanel 时 sellFishCount 尚未声明 → 被解析为**全局 `_G.sellFishCount`(nil)** → 闭包捕获全局 nil → 调用 nil 抛错 → bagCount 恒 0 → 面板"背包 0 条"
- debugBag 在 447 之后定义, 引用到正确局部函数, 故返回 311 (解释了"为何 debug 正常而面板 0")

### 修复 (hub.luau)
1. 388 行前新增前向声明 `local sellFishCount` / `local realBagCount`
2. 447 行 `local function sellFishCount` → `function sellFishCount` (复用前向局部, 否则 updateStatsPanel 仍解析 nil)
3. 新增 `realBagCount()`: `#playerData.Inventory:GetChildren() + ΣHotbar.Quantity` (匹配游戏背包容量口径, 含锁定鱼); 用户要"真实背包数量" → 面板改显**总数**而非仅未锁定可售数
4. updateStatsPanel 背包计数 `sellFishCount(true)` → `realBagCount()`; 头部 `[0.15.0]`→`[0.16.1]`

### 验证
- 重注入后 `forcePanelDetail`: beforeBag=349 afterBag=349 callOk=true (修复前 0)
- `debugBag` 可售数=321, 差值 28=锁定鱼数 → 两类数字区分清晰, 面板显真实总数 ✓
- startup errors=[]; 控制台无新增错误
- 注: 排查期多次 execute-file 注入, game 内可能叠加多实例(各建独立 Paragraph+statsTick); 用户侧重跑一次(热替换自毁旧实例)即清理

### 遗留
- [ ] 功法名待确认 (鬼魂购功法概率失败, 名未抓到)
- [ ] 若用户要面板同时显"总数+可售", 可加括号标注 (当前仅显总数)

---

## [2026-08-27 | 会话59 | v0.16.0 鬼魂NPC: 快捷传送 + NPC大全图鉴]

### 用户需求: 鬼魂NPC (三个点位随机刷新) 介绍进 NPC大全 + 快捷传送至刷新的鬼魂

**Real 逆向结论 (实机探查 + 用户纠正)**:
- 鬼魂 = 随机刷新的特殊 NPC, **玩家头顶名为 "9178"**; 之前误判为固定 `workspace.NPC.Spirit` (那是无用固定NPC, 已排除)
- 出现时系统提示 "Something has appeared in the world..." (类游商上线)
- 无 `workspace` attribute 监听通道 → 传送时按 **名称/Humanoid.DisplayName/头顶文本 "9178"** 实时定位 (findGhostModel)
- 可花游戏币购买某个功法且**概率失败**, 但**功法名未确认** (之前误写的 Spirit Salvation 是另一个无关功法, 撤回)
- 三个刷新点位具体坐标未逆向 (脚本混淆/运行时动态), 未编造坐标, 仅写"随机刷新于三个点位之一"

**实现**:
1. `findGhostModel()` 函数: 优先 `Name=="9178"` 快速路径 → 查 `Humanoid.DisplayName=="9178"` → 查头顶 `TextLabel=="9178"`; 范围先锁 `workspace.NPC` 再兜底全图
2. `tpToSpirit()` 调用 findGhostModel, fsmState 战斗/结算拦截 → 落到其前方 4 格抬高 2 格 → 不在场提示"鬼魂未刷新"
3. 快捷传送「功能 NPC 传送」区新增「传送至当前鬼魂」按钮 (Icon=ghost) + 「NPC 大全」Section 鬼魂图鉴 + 传送按钮
4. 头部: 功能清单补 NPC大全 + ScriptVersion 0.15.7→0.16.0 + 逆向结论区补鬼魂机制 (已修正 Spirit 误判)

**验证**: execute-file 注入 + get-console-output 无运行期错误 (静态门因完整源码无法内联, 由注入编译替代); 传送逻辑待鬼魂在场时实测

**遗留**: ①三个刷新点位具体坐标待补 ②鬼魂所售功法名待确认 ③未实现"自动购买功法" (用户仅要求介绍+传送)

---

## [2026-08-27 | 会话58 | 效率统计表实机修复：statsTick 崩溃实例替换]

### 用户反馈: 背包显示 0 条、收入一直 ¥0 (实际背包有鱼、现金在涨)

**根因 (实机探查, 非猜测)**:
1. `get-console-output` 显示本次启动 (`重型钓鱼@0.15.7`) 后 `statsTick` 从 seq 3 起持续刷 `:412: attempt to call a nil value` (至 seq 49)
2. 但磁盘 `hub.luau` 第 412 行已是修复版 (`isInventoryFull` 用 `FindFirstChild`), `statsTick`(1106) 已 pcall 包裹, `UpdateStatus`(theking.luau:277) 已加防御
3. 结论: 游戏里跑的是**修复前的旧实例/缓存副本**, 不是磁盘这份修复版。旧版 `isInventoryFull` 里 `playerData.InventoryLimit.Value` 一崩 → statsTick 每 2s 崩一次 → 面板永远刷不出真实数据 → 背包显示 0、收入 0

**修复**:
1. `mcp__real__execute-file` 重新注入磁盘上修复版 `hub.luau`, 内置 registry 热替换自毁旧崩溃实例
2. 注入后 `get-console-output severity=errors since=157` → `lines:[]` **零新错误**, statsTick 不再崩

**实机验证 (关键数据)**:
- `_G.RCWTK_DBG.heavyFishing.state()` → `sellableNow=4, autoSellOn=true, invFull=false, sellTriggerMode=背包装满` (脚本已能正确取数, 不再是 0)
- 全局 `Data[UserId].Inventory`: 223 → 32 条 (期间未锁定鱼被卖出); 未锁定 7 条
- 真实现金 `Cash`: 1416521246 → 1788310187 (**涨了约 3.7 亿**, 证明鱼已实际卖出, 旧面板只是没显示出来)
- 单实例确认: `RCWTK_REGISTRY` 仅 1 条, WindUI 窗口正常

**收入 ¥0 的真相 (非 bug)**:
- 自动出售模式 = `背包装满`, 当前背包 32/1000 未满 → 不触发卖出 → 收入 0 是预期
- 修复版注入时 `lastCashSeen` 基线 = 当前现金 17.9 亿, 注入后无新卖出 → 差分 0 → 面板显示 0 正确
- 之前那批鱼是在旧崩溃实例期间卖的, 旧面板没捕获显示

**给用户的使用建议**:
- 想持续看到收入增长: 把自动出售模式从「背包装满」改为「固定数量」并设低阈值 (如 50 条), 到达即卖
- 面板「背包 N 条」显示的是**未锁定可售数** (锁定的收藏鱼不计入, 符合"锁定鱼永不售卖"设计)

**经验**: ①"面板显示 0 / 不更新"优先用 `get-console-output severity=errors` 查 statsTick 是否在崩, 而非只看面板 ②同一 version 号可能运行着不同代码 (缓存/旧副本), 实机验证以运行实例日志为准 ③现金差分统计 (`lastCashSeen`) 在修复版注入时重置基线, 注入后若无新收入则显示 0 属正确, 要看增长需产生新卖出 ④`_G.RCWTK_DBG.heavyFishing.state()` 是验证脚本内部状态的利器 (sellableNow/invFull/autoSellOn 等)

---

## [2026-08-27 | 会话57 | v0.15.7 设置随机切换服务器 + 效率统计修复]

### 用户反馈: 效率统计不更新 (钓了好几条还显示"开始自动钓鱼后开始累计")

**根因 (排查链)**:
1. 控制台发现 `loop 'statsTick' 异常: :412: attempt to call a nil value` 持续刷
2. `:412:` = `isInventoryFull` 内 `playerData.InventoryLimit.Value` (InventoryLimit 瞬态缺失)
3. 深层: 热替换后旧 statsTick 循环线程残留 (StopLoop 的 task.cancel 对已入队迭代不生效), 旧闭包引用已销毁的 Paragraph/playerData → 每周期崩一次, 面板永远刷不出
4. **误判陷阱**: get-console-output 是历史累积日志, 第一次看 115→120 误以为持续增长, 实际是旧日志; 用"记录当前数→等 8 秒→再数"对比才确认修复生效

**修复 (三重防御)**:
1. **lib/theking.luau** `UpdateStatus`: 增加 `type(para.SetTitle) ~= "function"` 检查 → 元素已销毁静默返回 (旧循环不再刷错误)
2. **hub.luau** statsTick: 循环体整体 pcall, 任何单次异常只记日志不打断心跳
3. **hub.luau** `isInventoryFull`: `playerData:FindFirstChild("InventoryLimit")` 防御性取值

**验证**: 修复后 8 秒错误零增长 (110→110); sellFishCount()=181 正常; 面板恢复刷新。

**经验**: ①热替换残留线程是"循环异常刷屏"的头号嫌疑, 排查先看错误行号是否指向旧代码位置 ②日志排障用"前后对比计数"不是看绝对值 ③防御性写法 (FindFirstChild + pcall) 对瞬态数据缺失是标准解。

### 用户需求: 不注入, 在设置添加随机切换服务器功能。

**实现** (SettingsTab「随机切换服务器」按钮):
1. **服务器列表**: Roblox 官方 games API `https://games.roblox.com/v1/games/{placeId}/servers/Public?limit=100` (game:HttpGet 主路, request 兜底, 均 pcall)
2. **筛选**: 排除当前 jobId; 排除满员 (playing >= maxPlayers); 只留余位 >=2 的服
3. **随机传送**: `TeleportService:TeleportToPlaceInstance(placeId, jobId)`
4. **安全**: Confirm 确认对话框; 传送前 TheKing.StopAll() 停全部功能; 失败分支 (HTTP 失败/解析失败/无可用服) 各自通知

**设计决策**: 纯客户端标准 API (TeleportService + game:HttpGet), 无注入无 hook; games.roblox.com 需登录 cookie, 注入器环境 game:HttpGet 自动携带 (若受限则 request 兜底)。

**验证**: 语法门 0 error (3025 行)。客户端离线未注入, 实机待用户测试。

**待校准**: games API 在注入器环境是否返回列表 (部分注入器 game:HttpGet 域名受限, 若失败会走通知分支); TeleportToPlaceInstance 是否被游戏服务器拦截 (部分游戏禁用换服)。

---

## [2026-08-27 | 会话56 | v0.15.6 效率统计精度+认知修正]

**用户反馈**: 截图"效率统计"显示"挂机 1 分 · 垂钓 1 分 · 捕获 5 条 · 收入 ¥0 / 垂钓效率 186 条/时" — 用户怀疑是 BUG。

**根因 (两层)**:
1. **显示精度问题**: `math.floor(fishRunAccum/60)` 把 1.6 分显示为 1 分, 5 条/96.8 秒实际是 186 条/时 (算对), 但分母显示"1 分"让用户按 5/1 = 300 条/时预期, 觉得"算错了"
2. **¥0 认知误区**: `stats.cash` 只累计**卖鱼**现金差分, 不累计"捕获价值"; 用户捕 5 条没触发自动出售 (默认阈值 20 条), 所以 ¥0 = 正确行为, 但面板无"背包库存"提示, 用户以为"捕获应该有收入"

**修复**:
1. 垂钓分母改 `%.1f` 小数显示 (1.6 分 而非 1 分), 消除精度误判
2. 面板新增 "背包 N 条" 行 (实时统计 `sellFishCount()` 未锁定可售库存), 让 ¥0 时用户能看见"鱼都在背包里没卖"

**验证**: 语法门 0 error (2956 行); v0.15.6 注入无编译错误; 算法本身没改, 只优化呈现。

**经验**: "效率"类指标用户对**分母显示**极度敏感 (floor vs round vs %.1f 影响感受); "捕获 ≠ 收入" 类语义必须显式提示, 否则用户必当 BUG 报。设计面板要让每个数字都自解释。

---

## [2026-08-27 | 会话55 | v0.15.5 点位列表刷新修复]

**用户反馈**: 记录点位后列表没刷新, 删除和记录都应刷新一次列表。

**根因**: WindUI Dropdown 无公开"改项"文档 API, 记录/删除后只更新了内部数据, UI 选项列表未重建。

**修复**: 读 WindUI 源码 (windui-main.lua) 确认 DropdownMenu 暴露 `Refresh(au, av)` 方法 — av 为新 Values, 内部重建选项列表 (33208 行 `ap.Refresh=ap.DropdownMenu.Refresh`; Refresh 函数 32689 行 `for aw,ax in next,av do` 用新列表重建)。保存 pointDropdown 句柄, 记录/删除后调用 `pointDropdown:Refresh(pointOrder)`; 选中项失效自动回退首个。

**验证**: 语法门 0 error (2953 行); v0.15.5 注入无编译错误。待用户实机确认列表即时刷新。

**经验**: WindUI 元素公开方法 (Refresh/Select) 在源码里可直接确认 — grep "ap.Refresh=ap.DropdownMenu.Refresh" 即暴露面; 查元素能力优先读库源码, 别猜。

---

## [2026-08-27 | 会话54 | v0.15.4 快捷传送记录点位 + 持久化]

**用户需求**: 拓展快捷传送 — 记录点位传送, 持久化记录的点位。

**实现** (TeleportTab「记录点位」区块):
1. **记录当前位置**: 存 HRP.Position, 自动命名"点位 N" (跳号不复用); 通知含坐标
2. **下拉选择点位**: 列出全部已存点位 (插入序), Flag teleportPointSel 持久化选中
3. **传送到点位**: 战斗中/结算拦截, CFrame.new(pos+V3(0,2,0))
4. **删除点位**: 移除 + 持久化刷新
5. **持久化**: heavyfishing_points.json (readfile/writefile + HttpService JSONEncode/Decode); 脚本启动 loadPoints() 恢复; 每次增删 savePoints()

**设计决策**: 点位是自定义数据 (坐标列表) 不走 WindUI ConfigManager (它只存 Flag 元素状态); 用标准注入器 readfile/writefile (AGENTS.md 兼容规范), 与 theking.luau 的 WindUI 副本加载同目录, 跨注入器可移植。

**验证**: JSON roundtrip 实测通过 (写→读→解析, 含中文"点位 1"名); 语法门 0 error (2939 行); v0.15.4 注入无编译错误。UI 懒加载 (Content 只渲染选中 Tab) 静态不可查, 逻辑与已验证的玩家传送同构。

**经验**: 自定义持久化数据用独立 JSON 文件 (readfile/writefile), 不塞进 ConfigManager; 文件读写 API 全部 pcall 包裹防注入器差异。

---

## [2026-08-27 | 会话53 | v0.15.3 智能锁定天气鱼规则 + 等待时间跳过可行性]

**用户需求**: ①智能锁定添加新规则「所有特殊天气鱼」(特定天气特定位置钓的鱼也锁定) ②分析每条鱼等待时间可否跳过。

**智能锁定天气鱼规则** (feat):
- WEATHER_ISLE_MAP 上移至状态区 (原在 UI 区块), 新增 WEATHER_FISH_SET (11 种天气限定鱼英文名集合)
- matchLockByName 加 `lockRuleWeather and WEATHER_FISH_SET[fish] → "特殊天气鱼"`
- 「启用哪些锁定规则」多选加「特殊天气鱼」项 (默认开, Flag: lockRules 持久化)
- 验证: 构建逻辑独立测试 11 鱼全收录; 语法门 0 error (2819 行); 注入无错误

**等待时间跳过可行性分析** (不可行):
- 等待时间 = 抛竿到咬钩间隔, 服务器端定时器控制 (客户端 Fishing 模块无计时逻辑, 仅 UI 动画 task.wait)
- 抛竿 remote `Fishing:FireServer(CFrame)`: 仅两动作 — Fishing==false 时抛竿, Retractable 时收竿; 无"加速咬钩"参数
- 鱼饵 Luck 字段 (3~50) 只影响稀有鱼概率, 不影响等待时长 (实机读 Bait 配置确认)
- 服务器另有 PowerWarning 海域校验等, 咬钩完全服务器权威
- **结论: 无法跳过等待** — 客户端无通道; 近似优化 = 高 Luck 饵 + 智能放弃弱鱼 + 目标鱼过滤 (已实现)

**经验**: 脚本内全局 (loadstring 环境) 与 eval 沙箱隔离, 验证脚本内表构建用独立重建逻辑或 dbg 接口, 勿用 rawget(_G) 跨环境取。

---

## [2026-08-27 | 会话52 | v0.15.2 目标鱼多选 + 虚空钓可行性判定]

**用户需求**: ①选择目标鱼支持多选 ②「虚空钓」功能分析: 选天气, 天气到来时抛竿坐标伪装成该天气岛屿海域 (角色原地不动钓别岛鱼); 先分析, 实现不了就算了。

**目标鱼多选** (feat): Dropdown Multi=true, targetFishNames 集合 (英文鱼名→true); 过滤判断 next() 非空 + 集合匹配; Toggle 校验集合非空; 放弃通知同步。

**虚空钓可行性分析** (实机发包测试, pv2918):
- 协议: `Events.Fishing:FireServer(CFrame)` 带坐标参数 (客户端抛竿传 HRP.CFrame)
- 测试矩阵:
  - 发战场岛坐标 (距实际 259 格) → 回推 Crimson Bream Sovereign (战场岛鱼) — 位置接近无法区分
  - 发新手岛坐标 (距实际 1900 格) → 仍回推 Crimson Bream Sovereign — ⚠️ 疑似按实际位置
  - **发霜冻岛坐标 (距实际 3445 格) → 仍回推 Crimson Bream Sovereign (玩家脚下战场岛鱼)** — ✅ 实锤
- **结论: 虚空钓不可行** — 服务器忽略包内 CFrame, 按玩家 HumanoidRootPart 实际位置判定海域; 改坐标无效, 且服务器另有 PowerWarning 海域竿力校验。想钓别岛鱼只能真传送 (已有天气渔场传送按钮)。

**验证**: 语法门 0 error (2795 行); 多选版注入无编译错误。虚空钓分析不产生代码改动。

**经验**: ①验证"服务器是否信任客户端坐标"类假设, 直接发包实测最有效 — 发远距离假坐标看回推鱼种即可区分 ②远程监听用纯 OnClientEvent 挂接 (不动元表), 避免 namecall hook 污染 (会话47 教训)

---

## [2026-08-27 | 会话51 | v0.15.1 目标/放弃列表汉化 + 岛屿前缀]

**用户需求**: 目标与放弃的列表, 所有鱼名汉化, 前面加出自什么岛屿 (xx-xx鱼)。

**实现**:
1. **数据源发现**: `Info.FishingAreaRarity` ModuleScript = 岛屿→{鱼=稀有度} 全量映射 (12 区: 11 岛 + Exclusive/Secret Boss, 109 鱼全覆盖) — 比 Info.Inventory 更准 (Inventory 含竿/饵 149 项需过滤)
2. **FISH_ISLE_MAP** (鱼英文名→岛屿英文名): 运行时 require FishingAreaRarity 构建, 游戏更新自动跟随
3. **ISLE_CN 岛屿中文映射**: 新手岛/鲈鱼岛/霜冻岛/竹林岛/椰子岛/雾峰岛/琥珀岛/辐射岛/战场岛/君主岛/限定/秘密Boss
4. **fishLabel(fishEn)** = ISLE_CN[岛] .. "-" .. trName(鱼): 目标列表显示「椰子岛-绯红战鲤」式标签; Dropdown 存英文鱼名 (内部匹配不受显示影响)
5. 目标过滤判定改用英文鱼名比较; 放弃通知显示 fishLabel 带前缀
6. 列表过滤: 只列 FishingAreaRarity/Fishes 中的鱼, 排除竿/饵模块

**验证**: 语法门 0 error (2787 行); 注入后 dbg.fishLabels 实测: 「战场岛-黄金守护鱼」「椰子岛-绯红战鲤」「秘密Boss-穿天龟」「霜冻岛-太初鲲鱼」「鲈鱼岛-长老鲈五」— 岛屿+鱼名均汉化 ✅

**经验**: CN_ALL 是脚本内 local, eval 沙箱取不到 → 验证脚本内函数效果用 dbg 接口 (fishLabels) 而非外部 eval 重建逻辑。

---

## [2026-08-27 | 会话50 | v0.15.0 大修: 智能回正/目标鱼过滤/天气预报整合/天气渔场传送/效率统计重做]

**用户需求**: ①效率统计优化长时间挂机计算 ②自动钓鱼 Tab 排版重组 (战斗策略收拢) ③修复蓄力时长不保存 ④智能回正独立开关+朝向一致增强 ⑤天气预报整合 (天气稀有鱼提醒+预报选项) ⑥快捷传送加天气渔场按钮 ⑦全面拓展自动钓鱼核心 ⑧归档。

**实现**:
1. **智能回正** (smartReturnOn, 默认开): 原漂移修正仅拉回位置 (CFrame.new(pos)), 现记录抛竿瞬间完整 `anchorCFrame`, 漂移超 10 格还原 `anchorCFrame * CFrame.new(0,2,0)` — 位置+朝向双还原。独立 Toggle 可关 (Flag: smartReturn)
2. **目标鱼过滤**: 等咬钩命中瞬间判断鱼名, 非目标直接 doGiveUp (走游戏自身失败流程, 不消耗战斗状态); 鱼名单来自 Info.Inventory 模块名 + trName 中文映射, Dropdown 选择
3. **天气预报整合**: 原 MainTab 独立天气块 → 加 Section「天气预报」标题收拢提醒 Toggle + 关注天气 Dropdown; WEATHER_FISH 提升为模块级 `WEATHER_ISLE_MAP` (传送按钮复用)
4. **天气渔场传送**: TeleportTab 新区块「天气渔场」, 读 workspace Weather attribute → WEATHER_ISLE_MAP 映射岛屿 → 传送到该岛 spawnpoint, 通知含可钓鱼种; 无特殊鱼 (Clear/Rainy/未映射) 仅通知不动作
5. **效率统计重做**: 现金差分+面板刷新从 autoFishTick 抽出 → 独立 `statsTick` 循环 (2s 常挂, TheKing.StartLoop), 不受自动钓鱼启停影响; 新增 `fishRunAccum` (自动钓鱼实际累计秒数), 面板分「挂机 X 分 · 垂钓 Y 分」双指标, 条/时·¥/时按垂钓实际时长计算 — 长时间挂机效率不被暂停稀释
6. **蓄力时长持久化修复**: Slider 原无 Flag → 加 `Flag = "chargeDuration"`, 重注入恢复
7. **排版重组**: 战斗策略 Section 内顺序 = 自动Perfect → 自动技能 → 技能释放模式 → 自动蓄力 → 蓄力时长 → 智能回正 → 智能放弃 (原 autoSlam/autoCharge 在 Section 外, 已收拢)

**验证**: 语法门 0 error (2736 行); v0.15.0 注入无编译错误; Tab 顺序 1-8 保持正确; autoFish/bossMode 注入强制关闭逻辑保留。

**待校准**: 目标鱼过滤的鱼名匹配 (Info.Inventory 模块名 vs 实际 FishName attribute 可能不同, 过滤判断已双写兼容); 天气渔场按钮对 Foggy 多岛 (取首个) 是否符合预期。

**经验**: ①统计类逻辑不应嵌在功能循环里 (功能关=统计停), 独立心跳更稳 ②UI 排版重组 = 改创建顺序 (WindUI 无 reorder API, 创建即排序) ③模块级数据 (WEATHER_ISLE_MAP) 用全局赋值供跨区块复用, 但注意勿与 local 同名冲突。

---

## [2026-08-27 | 会话49 | v0.14.0 玩家传送 + Tab 重排 + 持久化规则]

**用户需求**: ①快捷传送拓展传送到服务器玩家 ②Tab 序列重排 ③全功能持久化 (除自动钓鱼/恩佐BOSS开关, 这两项注入默认严格关闭) ④恩佐BOSS开关重命名 ⑤归档。

**实现**:
1. **玩家传送** (TeleportTab 新区块): 扫 Players 在线玩家 (排除自己, DisplayName+Name 标签), Dropdown 选择 + 传送到该玩家 HRP 旁 (CFrame.new(p+V3(0,2,4),p) 同 NPC 传送路径); 刷新按钮重建列表 (WindUI Dropdown 无公开改项 API, 提示重开 Tab 生效); 战斗/结算中拦截
2. **Tab 重排**: WindUI 侧栏按创建顺序追加 (无公开排序 API) → 运行时 LayoutOrder 覆盖。**踩坑**: ①首次写 gethui() 路径没匹配 — 实测 WindUI 挂在 CoreGui.RobloxGui.WindUI (不是 gethui 根) ②同步执行时 UI 尚未完整构建 → 必须 task.delay(1.5) 延迟执行 ③侧栏按钮在 Frame>Main>Frame>ScrollingFrame>Frame 下, 按钮文本在其子 TextLabel
3. **持久化规则**: 硬性要求"除自动钓鱼/恩佐BOSS外全持久化, 这两项注入默认关闭且严格" → 实现 = 这两个 Toggle **不设 Flag** (不纳入 ConfigManager) + 注入尾段强制 setAutoFish(false)/setBossMode(false) 双保险。其余开关 Flag 保留走持久化 (LoadConfig 已就位)
4. **重命名**: bossMode Toggle 标题「恩佐BOSS自动战斗」→「自动战斗」; 通知文本「恩佐BOSS·自动战斗」; 头部功能清单同步

**验证**: 语法门 0 error (2579 行); Tab LayoutOrder 实测 1-8 正确 (自动钓鱼→鱼饵管理→背包管理→恩佐BOSS→快捷传送→玩家→快捷键→设置); 注入无运行时错误。玩家传送 UI 懒加载 (切 Tab 才渲染) 静态不可查, 待用户实机点开确认。

**待校准**: 玩家传送 Dropdown 刷新需重开 Tab (WindUI API 限制); 恩佐BOSS 实机待校准项不变。

**经验**: WindUI 元素序 = 创建序; 重排靠运行时 LayoutOrder (UIListLayout SortOrder=LayoutOrder); 结构路径 CoreGui.RobloxGui.WindUI.Window.Frame.Main.Frame.ScrollingFrame.Frame (按钮容器)。

---

## [2026-08-27 | 会话48 | v0.13.4 通知增强 + hook 根治]

**用户需求**: ①增强脚本通知 — 所有功能开关都要通知且清晰明了 ②归档。

**通知增强** (feat):
- 新增统一辅助 `notifyToggle(name, on, icon)` (L280): 标题=功能名, 内容=已开启/已关闭, 图标区分, Duration 2.5s
- 13 个 Toggle 全覆盖: 自动钓鱼(补关)/自动出售/自动技能/自动买饵/自动Perfect/自动蓄力/智能放弃/天气提醒/智能锁定/保持奔跑/移动加速/防踢心跳/恩佐BOSS — 开启关闭双向通知
- 快捷键切换链路统一 (el:Set → Callback → setter → notifyToggle 单通知), 删除旧式双链路通知

**严重 Bug 根治** (fix, 关键教训):
- 症状: 注入后点钓鱼竿/背包无反应, 销毁脚本后仍存在
- 根因: `hookmetamethod` 挂 `StartBossFight` 实例的 `__namecall` — hook 落在**共享元表**上污染游戏 UI 点击链路 (所有实例的 namecall 调用被拦)
- 铁证: Real `list-clients` healthWarnings 报告 "MCP namecall hook is installed"; `remote-spy` 停用后 `__namecall` 恢复原位
- 修复: **彻底移除 hookmetamethod** (含 remote-spy 监听也不再用, 其本身也是 namecall hook); Boss 战检测改用 `workspace.Fishes` 战斗实体 `Boss=true` 属性 (普通鱼无此属性, 零 hook 纯属性, 实测 fish.MaxHealth=40000/20000 战斗实体均带 Boss=true)
- 控条修复: Boss 战顶部条 = BarFrame.Bar (实机 barX 实测锁定 0.4997), 恢复 startBossFight 调 enterFight(), Boss 战豁免 fightGui.Visible 检查

**验证**: 实机一轮恩佐战全通 — 开战检测 ✅ / 控条锁定 0.4997 ✅ / 技能 Z/X/C/V 全自动 ✅ / Boss 40000→4950 (87%) ✅ / 点击链路无污染 ✅ (用户重进后复测)

**待校准** (不变): Phase2 Index 契约 / Rhythm 判定线 / 加血QTE 回调格式 / 战斗结束自动收尾。

**踩坑黑名单** (追加):
- [hookmetamethod 做功能检测] → [共享元表污染, 全游戏 UI 点击失效] → [功能检测一律用属性/事件/实例存在性, 严禁 hook; remote-spy 等调试 hook 用完即停]

---

## [2026-08-27 | 会话46 | v0.13.3 恩佐BOSS实机失效修复 + 接管自检]

**背景**: 会话45 交付后实机测试"一点作用都没有" (用户反馈 ×2)。接管 opencode 会话, 重新注入 + 监听定位根因。

**根因** (实机监听证据): `StartBossFight:FireServer("Enzo","Normal")` 确实发出 (seq 1/6), 但 `FishingMinigame` 入站 = 0 次 → **BOSS 战不走钓鱼小游戏**, 会话45 的「主阶段复用钓鱼小游戏」假设错误, `bossActive` 永不触发, 全模块空转。

**逆向修正** (Real, pv2918):
1. Phase1 = 纯技能 DPS (UseSkill Z/X/C/V), 无控条小游戏, 无 GUI/属性信号 → 开战检测必须 hook `StartBossFight` 发包
2. Phase2 = BossFightBar 点击条 (MinigamePhase2 docId16): `BossPhase2Setup.OnClientEvent` 触发, 点戳 `BossPhase2Action:FireServer({Hit=true,Index})`, `Character:GetAttribute("Phase2")==true` 是阶段信号
3. FinalPhase = Rhythm 节奏 (Fishing docId80): RhythmStart → 3 轨 (ProgressionA/S/D) NoteFrame 下落, 临线发 `RhythmHit("hit")`
4. `BossSetUp` 是 Folder 非 RemoteEvent (无 OnClientEvent) — 排掉一个错误检测方向
5. `SkillButton` 常驻可见 → 不是战斗信号, 排除

**改动** (hub.luau, 承接会话45 的 7 处编辑后接管再修):
1. [会话45] `bossFightRunning` 状态 + StartBossFight namecall hook (installBossStartHook, L243)
2. [会话45] startBossFight 去掉 enterFight() (Phase1 无条)
3. [会话45] FishingMinigame 监听去掉 bossActive=true 置位
4. [本会话] **死锁修复**: 原 `anySignal = bossFightRunning or ...` + `not anySignal → 清零` 逻辑中 bossFightRunning 永不复位 → stopBossFight 永不触发, 打完一轮 bossActive 卡死 true 挡下一轮。改为: 开战脉冲消费即清零 (防重复触发) + 结束判据 = 「中段信号 (Phase2条/Rhythm) 曾出现 + 连续消失 8s」模型, 兼容 Phase1 无信号特性 (不靠 fightGui.Visible 判停, 逆向确认战斗中无 GUI 信号)
5. [本会话] 新增 bossSawMidFight/bossMidLostAt 状态, startBossFight/stopBossFight 同步复位

**验证**: 全文件 luaparse 语法门 0 error (2466 行)。实机待用户复测。

**待校准** (实机验证项, 用户手动开战后反馈):
- Phase2: BossPhase2Action 的 Index 字段真实契约 (近似游戏 u109 序号循环); Hit 标志是否被接受
- FinalPhase: Rhythm GUI 路径 fightGui.Rhythm / NoteFrame 真实结构; 判定线 y 阈值 [0.6,0.95] 需微调
- 加血QTE: HealingSlam 的 callbackRemote 是否为 Slam remote 回调 (FireServer("Perfect") 格式)
- 结束判定: 「中段信号消失 8s」模型在实机是否准时收尾 (Phase2→FinalPhase 切换空隙是否 < 8s)

**经验**: [BOSS 战协议假设] 逆向结论必须实机 remote-spy 验证后才可信 — 会话45 的"复用钓鱼小游戏"假设建立在静态脚本分析上, 实机监听一抓即证伪。以后战斗类协议先挂监听抓真实包再写检测逻辑。

---

## [2026-08-27 | 会话45 | v0.13.3 恩佐BOSS自动战斗模块]

**用户需求**: 不做注入, 只使用 Real 分析。开发新 Tab "Boss" — 恩佐BOSS智能小游戏模块, 顺畅进行恩佐全流程自动战斗。只需用户自行启动战斗, 然后功能自动控鱼条/自动释放技能/自动玩加血QTE小游戏。BOSS 板块功能启动后禁止自动钓鱼 (影响 BOSS 战斗)。

**逆向成果** (Real 逆向, 无注入):
1. Boss 战复用钓鱼小游戏 — BarFrame.Bar 与主钓鱼同款心跳锁条 (enterFight 复用)
2. 技能 Z/X/C/V 复用 autoSkillTick (置 fsmState=战斗中)
3. 加血QTE = HealingSlam 等回血技能带 PerfectButton (MainGui.Fishing.PerfectButton:Clone 到 TrashCan) → Slam handler 扩展自动 Perfect
4. Phase2 = 独立 BossFightBar 点击小游戏 (MinigamePhase2 LocalScript), 服务器信任 BossPhase2Action 标志 → 循环发 {Hit=true, Index} 即必胜
5. FinalPhase = Rhythm 节奏小游戏: Events.RhythmStart → 3 轨 (ProgressionA/S/D) 音符下落, 临近判定线发 Events.RhythmHit("hit")
6. 开战 = Events.StartBossFight:FireServer(bossId, "Normal") (BossUI Fight 按钮, 辐射岛 Enzo)

**实现** (Ponytail: 最大复用, 最小新代码):
- Boss 状态变量 + 远程引用 (BossFightBar/BossPhase2Action/RhythmStart/RhythmHit)
- FishingMinigame 开始包检测 fishInfo.Boss==true 标记 bossActive
- enterFight 闸门放开给 bossActive (控条复用); 放弃判据加 `not bossActive` 守卫 (BOSS 不放弃)
- Slam handler 扩展: 自动 Perfect 匹配 Slam/Heal/Perfect/QTE 任意按钮 (覆盖加血QTE)
- Boss 模块: startBossFight/stopBossFight/bossDetectTick(0.4s)/bossPhase2Tick(0.1s)/bossRhythmTick(0.05s)/setBossMode
- 互斥: setBossMode 开 → setAutoFish(false); setAutoFish 开 → setBossMode(false)
- 恩佐BOSS Tab: 总开关 Toggle + 传送到恩佐(辐射岛) 按钮 + 使用说明
- dbg 接口: state 加 bossModeOn/bossActive/rhythmActive; setBoss(on)

**验证**: 隔离 Boss 模块块 check-script 0 语法错误 (41 条 Unknown global 为脱离上下文误报, 文件级声明均存在); 全文件 prior session 0 error。实机未跑 (无注入约束)。

**待校准** (实机验证项, 用户手动开战后反馈):
- Phase2: BossPhase2Action 的 Index 字段真实契约 (近似游戏 u109 序号循环); Hit 标志是否被接受需观察
- FinalPhase: Rhythm GUI 路径 fightGui.Rhythm / NoteFrame 真实结构; 判定线 y 阈值 [0.6,0.95] 需微调
- 加血QTE: HealingSlam 的 callbackRemote 是否为 Slam remote 回调 (FireServer("Perfect") 格式)
- bossActive 自动检测: FishID 包 Boss 标志 / Character.Phase2 attribute / BossFightBar.Visible 三信号任一来启停

**经验**: [BOSS 战 = 钓鱼小游戏换皮] 逆向确认后 90% 逻辑可复用现有钓鱼模块, 新代码仅 Phase2/Rhythm 两段循环 + 互斥管理。

---

## [2026-08-25 | 会话44 | v0.12.8 全面健壮性修复 + 注入强制关闭]

**用户需求**: 全做之前审查发现的修复点 (P0/P1/P2), 并加防止机制 — 每次注入脚本都把自动钓鱼和自动卖鱼关掉。

**修复清单**:
1. P0-1: autoSellCheck 顶部加 `if not autoSellOn then return false end` 守卫, 关闭态绝不卖。
2. P0-2: autoFishTick 新增「等结算」分支 — 智能放弃断条出界后消费 giveUpDeadline (等 FishID 清空或 8s 兜底), 解决放弃后立即重抛的死循环。
3. P1-3: 抽 scheduleChargeSettle(castName), 阶段1/阶段2 蓄力结算统一走此函数, 消除 firstRoundCursor==nil 跨场漏结算竞态。
4. P1-4: 删死代码 categorizeSkill/skillCatCache (零调用方); 修技能区错误时机注释。
5. P1-5/P2-6: keepSprintOn/speedHackOn/targetSpeed/runBaseline/lastSprintToggleAt 上移至状态区, 消除 Heartbeat 与 UI 回调的声明顺序依赖; 移除重复 lastSeenFishId 声明。
6. P2-7: isInventoryFull/sellFishCount 加 2s 缓存 (fresh 参数), doSellAll 传 fresh=true 取实时数, 降每帧轮询 pcall 开销。
7. P2-8: 移除 autoFishTick 内 autoSellCheck() 调用 — 出售判定已独立 autoSell 循环承担, 主循环不再重复调用。
8. P2-9: 移除锚点漂移修正 task.wait(0.15) 硬等待, 降低延迟。
9. P2-10: dbg.state 移除死字段 firstCastKey/fightFirstCastDone。

**新功能**: 注入即强制关闭 autoFish/autoSell (`setAutoFish(false)`/`setAutoSell(false)` + `toggleEls:Set(false)` 同步 UI) — 每次注入从关闭态起步, 覆盖 v0.12.7 的配置恢复逻辑。

**验证**: check-script 0 error; autoSellCheck 仍由独立 autoSell 循环调用 (line 575), 非死代码; keepSprintOn 仅状态区一处声明 (line 225)。

**经验**:
- [状态变量位置] 被多处引用的变量放使用方之前 (状态区) 而非某个使用方附近, 避免 "声明顺序脆弱性"。
- [注入态默认值] 用户要"注入即关"时显式 setAutoFish(false), 不能依赖 LoadConfig 恢复。

## [2026-08-25 | 会话43 | v0.12.7 Flag 冲突总根源修复]

**用户反馈**: 每次注入脚本设置都会重置/卖鱼 (历史多轮反馈的最终根源)。

**根因**: 快捷键 Keybind 元素与主功能 Toggle **共用 Flag 名** (autoFish/autoSkill/autoSell/autoSlam/autoCharge) — WindUI 配置按 Flag 存储, Keybind 写入按键名字符串 ("F") 覆盖 Toggle 的布尔值; LoadConfig 时字符串被塞进布尔逻辑 → 状态错乱。且旧配置文件已污染, 需清除重建。

**修复**: HOTKEY_ACTIONS 的 flag 全部改 hk_ 前缀独立命名 + elsKey 字段显式关联对应 Toggle 元素键; 删除污染配置文件全新重建; 30 个 Flag 唯一性脚本验证通过。

**验证**: 注入后 setAutoFish/setAutoSkill 等 Config:Set 链路正常, 各开关状态与 UI 一致。

**经验**:
- [Flag 命名空间] WindUI 配置系统全局按键名, 不同 Tab/元素类型的 Flag 必须全局唯一 — 建立命名规范 (模块前缀) 在引擎层强制。
- [诡异问题先查持久化] "注入就重置/行为错乱"类问题第一优先级: cat 配置 JSON 对照 __elements 清单, 看类型和值是否被污染。

## [2026-08-25 | 会话42 | v0.12.6 游商系统破解 + 传送增强]

**用户需求**: 找"小道士/老道士"买钓鱼竿。

**逆向成果** (游商系统全破解):
1. 游商 = 限时商人, 随机刷新在 workspace.NPC.Function 下; 当前状态由 workspace attribute 推送: MerchantNPC(游商名)/MerchantItem(商品名)。
2. 历史观察: Taoist 卖 Taoist Rod / Maoshan 卖 River Suppression 神技 (免Boss技+破无敌+2000%猛击+回300HP)。
3. **"小道士/老道士"就是游商中文名** — 不在场上时传送列表自然没有。
4. Taoist Rod 本身非卖品确认 (配置无价格字段)。

**实现**: 「传送至当前游商」按钮 — 实时读 MerchantNPC attribute 定位 Function 下模型, 前方 4 格面向交互位传送; 无游商时提示。

**踩坑黑名单** (新增):
- [PowerShell 编辑 Lua 中文文件] Set-Content UTF8 加 BOM + 替换截断多行表达式 → 大段重写用 PowerShell 拼接后必须去 BOM 并 grep 验证结构; 能用 Edit 工具就用 Edit 工具。
- [Dropdown 动态刷新] WindUI Dropdown:Refresh 行为未验证就依赖 → 改为 attribute 监听提醒 + 实时定位按钮的轻量方案。

## [2026-08-25 | 会话41 | v0.13.2 首发零延迟]

**用户反馈**: Z 技能 CD 明明好了, 每轮还要等一会才放。

**根因**: resetFightState/自治检测里遗留 1.5~3s 随机观察期 — 旧版防倒计时误放的保守设计。现在 tick 有 SkillLocked 检查兜底, 观察期纯属浪费输出窗口。

**修复**: 两处 nextSkillAt 改为 os.clock() 立即可评估; 倒计时期间由游戏 SkillLocked=true 自然拦截。

**经验**: [防御性延迟的时效性] 加防御时依赖的条件 (当时无 SkillLocked 检查) 后来被补上后, 原防御就变成纯损耗 — 定期审查历史性防御是否仍有存在必要。

## [2026-08-25 | 会话40 | v0.13.1 补刀阶段模式跟随]

**用户反馈**: 顺序释放的技能选择被带到下一轮 (首轮后变成 DPS 择优)。

**根因**: v0.13.0 两阶段重构时, 阶段2 自由补刀硬编码为 DPS 择优, 丢失了顺序模式的游标轮转语义。

**修复**: 阶段2 选择策略跟随 skillMode — 顺序=游标循环轮转 / 智能=DPS 择优。整场语义一致。

## [2026-08-25 | 会话39 | v0.13.0 技能释放两阶段大修]

**用户需求**: 每轮战斗必须先无条件按 Z→X→C→V 顺序放一轮 (不管任何条件), 之后看哪个 CD 好放哪个。

**重构**: autoSkillTick 整段重写为两阶段:
1. 阶段1 firstRoundCursor 非 nil: 从游标起按序倾泻就绪槽, 放到 V 尾转阶段2; Charge 类照放并安排延迟结算
2. 阶段2: 就绪池 DPS 择优; Charge 类排除 (避免打断蓄力节奏), 仅当只剩 Charge 且保留期已过才再蓄
删除: fightFirstCastDone/firstCastKey/fightFirstCastAt/首发等待/超时降级/categorizeSkill 时机过滤/healQ/burst 区分

**经验**: [需求演进] 用户三次调整技能策略 (智能择优→顺序→开场倾泻) 说明"最优自动化"因人而异; 复杂过滤条件在用户眼里可能是"不干活", 简单直接有时才是对的。

## [2026-08-25 | 会话38 | v0.12.5 快捷键双通知修复]

**用户反馈**: 快捷键启动功能弹两条重复通知。

**根因**: 快捷键路径双写 — act.set() 弹通知① + el:Set() 触发 Toggle Callback 再走 set 函数弹通知②。

**修复**: 快捷键 toggle 只经 el:Set() 单链路 (UI+状态+通知合一), 删除手动 act.set 前置调用; el 不存在时才降级 act.set。setAutoFish 加 viaHotkey 参数备用。

**经验**: [单链路原则] UI 元素与内部状态双写的场景, 写入必须收敛到一条链路; "先直调再同步"必然产生重复副作用。

## [2026-08-25 | 会话37 | v0.12.4 快捷键 UI 同步修复]

**用户反馈**: 快捷键启动功能后 UI Toggle 显示不变。

**根因**: 快捷键只改了内部变量, WindUI Toggle 元素的显示状态是独立的 — 必须调元素 :Set() 才会更新视觉。Config:Set 路径在本地兜底版 windui 上不可靠。

**修复**: toggleEls 表保存全部功能 Toggle 元素引用; 快捷键切换时 act.set() (功能生效) + el:Set(newState) (UI 同步) 双写。autoSell 的元素引用也补上 (BagTab 内)。

## [2026-08-25 | 会话36 | v0.12.3 快捷键功能必达 + 天气 Multi 格式兼容]

**用户反馈**: ① 快捷键启动不了功能; ② 天气提醒失效。

**根因**:
1. 上一轮把快捷键 toggle 改成"Config:Set 触发 Callback"路径 — 本地兜底 windui 副本的 ConfigManager 可能不完整, Set 静默失败 → act.set 永远不执行 → 功能不启动。
2. Multi Dropdown 的 selTable 参数格式未实测 (可能是 {[label]=true} 或数组), 单格式解析可能全漏。

**修复**:
1. 快捷键 toggle 改为"功能先行": act.set(newState) 必定执行, Config:Set 仅作 UI 同步 (StartLoop 防重入保证幂等)。
2. watchWeathers 解析兼容两种 WindUI Multi 格式。

## [2026-08-25 | 会话35 | v0.12.1 快捷键清空按钮]

**用户反馈**: ESC 取消绑定不起作用。

**根因**: WindUI Keybind 元素的捕获态按 ESC = 内部"取消本次捕获"标准行为, Callback 永远收不到 Escape — 原设计依赖不存在的信号。

**修复**: 每个功能一组 UI (Section 标题 + ✕ 清空按钮 + 绑定按键), 清空按钮直接置 hotkeyBindings[id].key = nil; ESC/Unknown 键值在 Callback 里显式忽略 (防意外绑定)。

**经验**: [UI 库元素的隐含行为] Keybind 类元素的 ESC/右键等通常是"取消操作"约定, 不能当作数据输入依赖; 需要明确的清除入口时用独立按钮。

## [2026-08-25 | 会话34 | v0.12.0 快捷键 Tab + 全面中文化]

**用户需求**: ① 快捷键 Tab 绑定所有主要功能, 默认 None, 绑 ESC = 取消; ② 通知/列表全面中文化; ③ 天气提醒改选择模式。

**实现**:
1. 快捷键 Tab: HOTKEY_ACTIONS 定义表 (8 功能: 6 toggle + 2 action) + 每功能一个 Keybind 元素 (Flag 持久化) + UIS.InputBegan 全局分发。
   - Toggle 类经 `TheKing.Config:Set(flag, newState)` 触发元素 Callback → UI 与内部状态同步
   - 冲突检测: 同键绑多功能拒绝后者
   - ESC 语义 = 清除该绑定 (非绑定 ESC 键)
2. 中文化: CN_ALL 表扩至鱼×109/岛×10/天气×7/NPC×17/饵×5; trName() 展示层翻译, 内部逻辑保留英文原名。
3. 天气提醒: watchWeathers Multi Dropdown (中文选择→英文映射), 只提醒选中天气。

**踩坑黑名单** (新增):
- [Edit 工具 oldString 含函数定义行时极易吞掉下一行] → 本轮两次事故: 吞 logDecision 定义、吞 firstCastKey 计算循环、吞 BaitTab 声明。大段插入后必须立即 grep 验证相邻结构完整。
- [WindUI Keybind Callback 双语义] 绑定变更与按键触发共用 Callback — 设计时先实测 DEL 键行为再定架构。

## [2026-08-25 | 会话33 | v0.11.4 位置漂移锚位 + 移动加速真因]

**用户反馈**: ① 长时间钓鱼角色越来越靠后甩不到海; ② 玩家 Tab 两功能无效。

**根因与修复**:
1. **位置漂移**: 钓鱼时鱼拉扯线, HRP 被物理拖动逐轮累积 → 抛竿 CFrame 离水越来越远。修复 = 锚位系统: 首竿记录位置, 漂移 >10m 自动拉回 (CFrame 直写) 再抛; 开启自动钓鱼/手动换钓点时锚位重置。
2. **移动加速无效真因**: 游戏实际奔跑速度 = **36** (实测), 而滑条默认目标 24 → `ws(36) < 目标(24)` 永假 → 从不写入。修复: 范围 20~120 默认 50; 开启瞬间采样基准。
3. 保持奔跑逻辑本身正确 (基准自适应), 但需配合移动加速先跑到高值才能学习到基准 — 已联动。

**逆向补充**: WalkSpeed 在全部客户端脚本零引用 — 走/跑/战斗锁全是服务器属性复制; 客户端每帧写回是唯一有效对抗路径。

## [2026-08-25 | 会话32 | v0.11.3 Charge 蓄力技能支持]

**用户需求**: 切断大门需要释放后按 F 猛击 (蓄力越久伤害越高), 脚本不会; 提高智能施法让所有功法都懂用法。

**逆向成果** (Charge 模板 155 行全读):
- Sever the Gate 系 = **Charge 模板** (Function 引用比对确认)
- 机制: 施放 → 直伤 MainDMG + Iframe → 进入蓄力态 (Character.Charge=true) → 按 F/点按钮 = FireServer 动态 remote → Slam() 结算
- **结算公式 = Damage × (os.time() - 施放时刻)** 线性无上限; 结算后全技能 UsingSkill=3 + CD+5 + 本技 CD60 + Iframe=1
- MaxCharge 自动 Slam 兜底; p2.__DeferEnd=true 标记延迟结束

**发现的隐藏冲突**: Events.Charge 同时用于抛竿蓄力小游戏和技能蓄力 — autoCharge 钩子会把技能蓄力的确认按钮瞬间点掉 (=蓄力0.25s就结算, 伤害≈0)! 这是"释放技能不生效"的根因之一。

**实现**: isChargeSkill() 按名判定 (Sever the Gate 系); 施放后 chargeHoldUntil = now + chargeDuration (UI 滑条默认 15s); autoCharge 在保留期内跳过; 到时 FireServer pendingChargeRemote 结算。

## [2026-08-25 | 会话31 | 全面逆向补充: Rhythm 协议/技能EXP/新remote清单]

**本次成果** (已归档 intel.md):
1. **Rhythm 节奏小游戏协议全破解** (Boss Final Phase 最大遗留): RhythmStart{MiniGameTime} → 3 轨道 ProgressionA/S/D 音符下落 (t += dt/1.4) → 判定窗口 |ΔY|≤0.22 → 命中发 RhythmHit("hit")。自动化路径明确: Heartbeat 扫 Note_FX 位置接近判定线即代发 hit — Boss 战自动化最后一块拼图就位。
2. **技能 EXP 成长系统**: Data.Skill[名]={Owned,EXP,Favorite,Boost}; EXP 使用积累影响实际伤害 — 解释面板 Damage 与实战差异; 天赋重roll资源盘点 (101 券+9/10 保底)。
3. **全量 remote 清单 111 个**归档, 新发现: BuySkill/RhythmHit 三件套/StartDialogue/ChooseDialogueOption/ClaimQuest/CancelQuest/DailyReward/Gacha/RerollTrait(RF)/LockTrait/EquipTitle 等。
4. Data 全字段刷新: Skill×84(玩家技能数据)/SkillSlot×4/TraitRerollOneTime×4/LockTrait×7/GodSpirit×3/Index×109/DayCycle 昼夜时间戳。

## [2026-08-25 | 会话30 | 归档收尾]

**归档动作**:
1. intel.md 补充: 天气值定位 (workspace attribute "Weather", 7 种含 Clear, 客户端 SetAttribute 可本地触发信号)、天气鱼映射表、合成配方 (Ingredient 表/协议)、中文化映射说明。
2. remember-game: 合成系统、防踢方案、任务系统、伤害模型累计 8 条运行时召回。
3. changelog/devlog 与代码版本同步至 v0.11.2 (changelog 清理过一次重复条目)。

**当前挂机快照**: 上限 473 (等级持续增长), 鱼 35/473 攒仓中, 现金 ¥1789 万, 顺序模式 Z→X→C 正常轮转, 天气 Rainy 未关注正确静默。

## [2026-08-25 | 会话29 | v0.11.2 注入宽限 + 合成材料锁定 + M/K 单位]

**用户反馈**: ① 每次注入脚本都卖鱼; ② 锁定加合成用鱼选项; ③ 价格用 M/k 单位。

**逆向成果**: Mythical 饵配方 = `Info.Bait[x].Ingredient` (槽位→鱼名), 三种 Mythical 饵各需 4 种特定 Boss/稀有鱼。CraftBait:FireServer(饵名, 数量) 为合成协议。

**实现**:
1. bootAt 启动时间戳 + autoSellCheck 90s 宽限期 — 注入瞬间不卖, 给检查配置的窗口。
2. CRAFT_MATERIAL_FISH 规则表 (12 种材料鱼→饵种映射) + matchLockByName 集成 + Multi Dropdown 第四选项, 默认与上交鱼一起开启。
3. fmtNum() 与游戏 FormatKg 同款 k/M/B/T 格式; 应用钓获价格/出售收入/效率面板。

## [2026-08-25 | 会话28 | v0.11.1 鱼名全量翻译 + 跳跃防踢]

**用户反馈**: ① 钓获通知鱼名还是英文; ② 防踢改成实际跳跃。

**修复/实现**:
1. 翻译表 45 → **109 种全覆盖**。命名规律系统化翻译: 颜色前缀 (Crimson=绯红/Emerald=翡翠/Verdant=翠绿) + 鱼种 (Grass Carp=草鲤/Bream Sovereign=鳊君主/Kunfish=鲲鱼) + 梯度后缀 (Elder=长老/Adult=成年/Baby=幼年)。
2. 防踢跳跃化: 非战斗状态 keytap(空格) 真实跳跃 (角色动作+输入事件双信号), 战斗中退回 F15 (跳跃会改变 HRP 高度, 抛竿 CFrame 受影响故避开)。

## [2026-08-25 | 会话27 | v0.10.1 玩家Tab + 快速复位 + 首发超时降级]

**用户需求**: ① 技能动画卡下竿 → 鱼钓上来马上恢复状态; ② 玩家 Tab (保持奔跑 + 移动速度); ③ 全功能深度自检。

**逆向成果**:
1. **抛竿分支无动画检查** — 只看背包上限 + Fishing attribute。动画卡下竿 = 视觉残留 + 服务器侧判定, 客户端 FireServer 本不受阻。
2. **Ctrl 奔跑机制** = `Events.ToggleSprint:FireServer()` (服务器权威翻转 WalkSpeed); 走/跑无 attribute 标志, 只能从 WalkSpeed 数值推断。
3. **重大认知修正: Z 槽冷却跨场残留!** 决策日志实锤 "Z排除原因[冷却32s]" 出现在新一场开场 — 推翻"每场 CD 全重置"结论。Beastbreaker Cleave CD≈32s > 场间隔 → 顺序模式死等 Z 最长浪费 30s。

**实现**:
1. stopFight() 扩展为快速复位: 停全部 AnimationTrack + 清 Stun/Iframe (引擎 Animate 自动恢复基础动画)。
2. autoSkillTick 自治重置时同样清跨场 Stun 残留 (日志记录 "清理跨场残留 Stun")。
3. 玩家 Tab: keepSprint (WalkSpeed < 基准65% 且非战斗锁零 → 再发 ToggleSprint, 基准自适应历史最大值) / speedHack+targetSpeed (Heartbeat 仅放大不缩小)。
4. 首发等待超时降级: fightFirstCastAt 起 5s 内等 Z, 超时按序放池中第一个并标记本场已开始。

**验证**: 六 Tab 渲染齐全 (自动钓鱼/快捷传送/背包管理/鱼饵管理/玩家/设置); 决策日志正常轮转。

## [2026-08-25 | 会话26 | v0.9.1 重抛提速]

**用户需求**: 缩短每轮钓完到下一竿的速度。

**时间账分析**: 结束感知对齐(0.25s) + 重抛冷却(1~2.5s) + 抛竿对齐(0.25s) ≈ 2.25s/轮; 等咬钩为分钟级大头不可压。

**实施**: 冷却 1+rand1.5 → 0.5+rand0.7 (人类速抛真实区间); 主循环 0.5s→0.4s; 等结算回待机同步提速。切换开销降至 ~1.2s。

**边界**: 不再激进压缩 — 低于 0.4s 的重抛间隔进入机器人特征区, 得不偿失。等咬钩(服务器随机)才是每轮大头, 此优化在快节奏连钓场景收益最大 (+3~7%)。

## [2026-08-25 | 会话25 | v0.8.2 背包数量判定全面复查]

**用户要求**: 重新分析背包数量相关功能确保绝对没问题。

**复查范围**: sellFishCount(未锁定计数) / isInventoryFull(满仓公式) / autoSellCheck 三模式触发线 / 锁定竞态 / 满仓死锁。

**发现与修复**:
| # | 级别 | 问题 | 处理 |
|---|---|---|---|
| A | P1 | **锁定竞态**: 钓上任务鱼瞬间恰触发出售, 0.9s 锁定延迟窗口内鱼被卖 | 名字级规则(上交/钓捕)入库瞬间抢锁; 重量/价值类保留延迟 |
| B | P1 | **满仓全锁死锁**: 背包被锁定鱼占满 → isFull=true 但可卖=0 → doSellAll 空转无限循环卡钓鱼 | 识别"全是锁定鱼"提示人工处理, 不再空转 |
| C | P2 | scanAndLock 连发 FireServer 可能触发限流 | 每 10 条 wait 0.3s |
| D | P2 | getFishPrice 死代码且逻辑有 bug (Favorite 后缀处理错) | 删除 |
| E | P3 | sellThreshold Max=50 对大背包不够 | 扩到 400 |

**验证**: 脚本内 sellFishCount/isInventoryFull 与独立复刻交叉对比完全一致; limit 动态跟随等级增长 (422→436 实测在涨); 决策日志显示顺序模式首发等待逻辑正常 ("firstCastKey=Z 但池中只有[X,C,V]" → 等 Z 就绪 → "首发命中 Z")。

**经验**:
- [事件时序竞态] "延迟判定"类逻辑必须评估: 延迟窗口内世界会变 (自动出售可能抢先); 有保护性动作 (锁定) 应尽早执行, 只把真正需要数据的部分延后。
- [资源满载+过滤条件的死锁] "满了才处理, 处理的又只有未被排除的" — 当排除项占满资源时永远无法处理; 满载分支必须区分"有可处理的"与"全是排除项"两种情况。
- [changelog 编辑事故] 多次插入产生重复条目 — 归档前 grep 标题查重。

## [2026-08-25 | 会话24 | v0.9.0 防踢心跳 + 自动恢复]

**用户反馈**: 游戏有反挂机会重进服务器, 长时间挂机失效。

**逆向结论**: 客户端零 Kick 调用 (踢人在服务器/引擎层)。AFK 模块 = 60s 无输入自动发 AFK 包进官方挂机态, 但 **AFK 包不产生 UserInputService 事件, 无法重置引擎闲置计时** — 长挂断线的根因是 Roblox 引擎级闲置断开 (~20min 无真实输入)。

**双保险实现**:
1. 防踢心跳: StartLoop 240s → isrbxactive() 检查 → keytap(VK_F15)。OS 级输入重置闲置计时; 失焦跳过 (无效且不打扰); keytap 探测不存在静默降级。
2. AutoExec 启动器: `Real autoexec/heavy-fishing-loader.luau` — delay(8s) 加载 hub.luau; 被踢重连后自动恢复, 配置持久化带回全部开关状态 → 全自动续挂。

**验证**: keytapAvailable=true; 心跳循环随 antiIdle Toggle 挂载。

**经验**:
- [AFK 包 ≠ 输入事件] 游戏"挂机模式"协议包与引擎闲置判定是两套系统, 前者不能替代后者; 防闲置只有真实输入一条路。
- [长时挂机方案分层] 预防 (心跳输入) + 兜底 (AutoExec 自动恢复) 两层都要有 — 单靠预防无法保证 100% 不被踢 (服务器侧未知判定)。

## [2026-08-25 | 会话23 | v0.8.1 重复Section修复 + NPC传送 + 装满模式复验]

**三项**:
1. 主 Tab「战斗策略」Section 重复渲染 → 删冗余 (历史编辑残留)。
2. 快捷传送增强: 功能 NPC 区块 — 扫 workspace.NPC 含 Function 子层全部交互 Model 去重得 27 目标 (门票任务 Giver/学技能/买竿/买饵/卖鱼/Boss 入口/God 祈祷/Spirit), 落点 = NPC 前方 4 格面向交互位。
3. 「背包装满」误卖复验: v0.7.2 修复后运行时证据链 — sellTriggerMode="背包装满" + invFull=false 全程成立, 鱼数 13→39 持续积累零误卖 ✓。用户报告的损失系 v0.7.2 部署前旧行为。

**踩坑黑名单** (新增):
- [do 块内提前 return 终止整个脚本] → 顶层 do...end 内的 return 属于 chunk 级; 条件降级用完整 if 包裹而不是 guard-return。
- [dbg.state 可观测性滞后] → sellTriggerMode/sellableNow/invFull 等关键字段排查时才补 — 复杂功能上线时就该把决策相关字段全暴露。

## [2026-08-25 | 会话22 | v0.7.2 「背包装满」模式失效修复]

**用户反馈**: 设置背包满了才卖, 结果没满就卖。

**根因**: v0.7.0 的触发计算用 `string.match(mode, "背包(%d+)%%")` 区分模式 — "背包装满" 不含数字 → match=nil → **静默回退固定数量模式 (阈值50)**。用户上限 372, 50 条就卖了, 表现即"没满就卖"。

**修复**: 模式分支显式化 — "背包装满" 直接复用 `isInventoryFull()` (Inventory+Hotbar ≥ limit, 与抛竿前满仓判定完全同源); 百分比模式 match 独立处理; 其余走固定数量。

**经验**:
- [枚举字符串的模式匹配] 用 match 提参数时必须显式处理"不匹配的合法枚举值", else 回退路径等于吞掉语义错误; 枚举判断优先用相等比较而不是正则提取。
- [同源判定] "满仓"语义在抛竿检查和出售检查两处出现 — 统一复用 isInventoryFull() 而不是各写一遍, 否则必然漂移。

## [2026-08-25 | 会话21 | v0.8.0 背包管理 Tab + 智能锁定]

**用户需求**: 新背包管理 Tab (迁移出售板块) + 自动锁定保留任务要用的鱼, 锁定类型覆盖全部任务系统。

**数据工程**: Info.MainQuest 22 任务线全量解析:
- Objective 结构 = {描述, 数量, 类型, 参数}; 类型 12 种全枚举 (GiveFish/FishingSpecific/SpecficFishWithAnAmountOfWeight/FishAtZoneForTimes/FishBoss/Fishing/OwnSkill/OwnRod/UseSpecficSkillForTimes/CharacterLevel/GiveCash/FishWithAnAmountOfWeight)
- **重量挑战任务 15 条**带天气地点提示 ("Snowy weather at Frost isle" 等) — 未来自动赶场功能的数据源
- 注意: 配置是纯数组, pairs 遍历+键名特判会漏 — 必须按 ipairs + obj[1]/[2]/[3]/[4] 解析

**实现**:
1. 锁定引擎: 规则表三张 (上交鱼/钓捕目标/重量挑战含阈值) + matchLockRules 判定 + favoriteItem 协议封装
2. 钩子: ChildAdded → delay(0.9) 等定价写入 → 匹配 → 锁定+通知
3. 手动扫描按钮: 全背包遍历锁定
4. UI: Multi Dropdown 选规则 / 价值锁定 Slider / 启用 Toggle
5. 主 Tab 背包 Section 迁移至新 Tab (出售四件套)

**协议实测**: FavoriteItem:FireServer(项名) → Name 追加 " | Favorite" ✓

**遗留**:
- 锁定的鱼后续如何解锁/批量管理 (游戏 UI 有星标开关, 脚本未做批量解锁)
- 重量反推系数 0.949 为单点估算, 样本多了可精化
- 任务 Objective 的 FishingSpecific 完成后规则是否自动失效 — 当前静态规则, 不跟踪任务完成状态 (用户手动关规则即可)

## [2026-08-25 | 会话20 | v0.7.1 全面代码审查]

**触发**: 用户要求全面深度审查脚本找优化点与潜在问题。

**审查方法**: 通读 v0.7.0 全文 (1217 行), 按逻辑正确性/竞态/健壮性/性能四维排查。

**发现与修复**:
| # | 级别 | 问题 | 处理 |
|---|---|---|---|
| 1 | P0 | playerData nil 时 `FishingRod.Changed:Connect` 崩 | 关键对象校验补全 (RemoteCast/fightGui/fishesFolder/playerData) |
| 2 | P0 | 重生瞬间 ch.Stats 缺失, autoSkillTick 裸索引崩 | FindFirstChild 安全访问 |
| 3 | P1 | doGiveUp 立即回待机 → 服务器清场前重抛 → 放弃失效死循环风险 | 新增「等结算」状态 + 8s 兜底超时; giveUpDeadline 变量 |
| 4 | P1 | 「停止全部功能」不重置开关变量 → UI 与实际脱节 | 同步重置 autoFishOn/autoSellOn/autoBaitOn/autoSkillOn/fsmState |
| 5 | P1 | autoBait 慢循环 (80~130ms) 根因 = InvokeServer 同步 RTT 卡 tick | task.spawn 异步化 |
| 6 | P2 | 进度显示块缩进错乱 | 对齐 |

**遗留观察项** (评估后不修): 出售百分比 string.match 每 tick 开销微小; dbg 接口发布时移除 (既有记录)。

**经验**:
- [多状态机共享变量] 新增状态 ("等结算") 必须同步检查所有消费方分支 — fsmState 加新值时逐个 grep 使用处确认兼容。
- [同步 RemoteFunction 是慢循环头号嫌疑] InvokeServer 的 RTT 会计入循环耗时; 循环体内的远程调用一律 task.spawn 化或改事件驱动。

## [2026-08-25 | 会话19 | v0.7.0 出售时机按背包上限]

**用户需求**: 出售阈值按背包最大上限来 (上限已 350, 固定数字不合身)。

**实现**: sellTriggerMode Dropdown — 固定数量 / 背包80% / 背包90% / 背包装满; 百分比模式实时 `InventoryLimit × pct` 计算, 上限升级自动跟随; autoSellCheck 触发线动态化。

**设计取舍**: 没有扩大 Slider Max 到 999 — 大范围滑条精度差且仍需手动跟随上限升级; 百分比语义一次到位。

## [2026-08-25 | 会话18 | 全面分析: BOSS/概率/真实伤害]

**本次成果** (全部归档 intel.md):
1. **重大结论修正**: Stats.Time = 战斗时限 (超时失败), 不是咬钩等待! 普通鱼 5~74s, Boss 鱼 30~15000s。此前档案写反已更正。
2. **技能真实伤害模型** (15 模板全逆向): 单跳=Damage×暴击(5%/1.5默认), 间隔 0.5s 或 SlamTime, 客户端直改鱼 Value 无缩放; Damage 对普通鱼是主力输出对 Boss 是零头; 模板语义表建成 (DStun 系/Barrage/Stun/Slam 系/Rage/buff/Healing 系)。
3. 鱼谱系: 普通 63 条 P1~P74 + Boss 46 条 P13~P100; Weight 与 MaxHealth 正相关待更多样本。
4. Boss 系统: NPC Enzo+Talk prompt+入场锚点; 入口协议需实地交互抓包 (未做)。
5. **概率采样器上线**: `_G.RCWTK_BAIT_STATS` 持续积累鱼种分布, 样本足后反推 Luck 公式。

**装备动态**: 用户已到 Thunder Thorn Rod (P67/L30, ¥1000万级)。

## [2026-08-25 | 会话17 | v0.6.5 首发漂移最终根治]

**用户反馈**: v0.6.4 后仍偶发非 Z 首发 (第一场 Z, 第二场 X)。

**真因 (v0.6.4 修复不彻底)**: 跨场重置由**主循环**执行, 但 autoSkill 是独立循环 — 两者相位随机。主循环 resetFightState 前的窗口内, autoSkillTick 用上一场的 fightFirstCastDone=true 直接走轮转分支放掉一个技能。

**修复**: autoSkillTick **自治检测** — 开头自己盯 FishID, 变化即自行重置 (首发标志/游标/firstCastKey/观察期), 完全不依赖主循环节奏。

**验证**: 三连场实战监控 首发 Z→Z→Z 全对; 决策日志全程可追溯 ("新战斗 Z 首发" → "首发命中 Z" → "轮转命中 X"...)。
注: 第三场监控探针报 X 先发系采样盲区 (探针 0.15s 间隔漏记 Z 的 CD 跳变), 决策日志证实 Z 已放 — 外部监控与内部日志冲突时信内部日志。

**经验**:
- [多循环共享状态] 独立循环各自维护的关键状态必须自治重置, 不能假设"另一个循环会先把我修好"; 或者干脆合并进同一循环。
- [外部监控 vs 内部日志冲突] 内部决策日志时间戳更细, 可信度更高; 外部探针有采样率盲区。

## [2026-08-25 | 会话16 | v0.6.1~v0.6.4 顺序模式首发漂移根治]

**用户反馈**: 顺序模式首放不稳定 (第一次 Z, 第二次变 X...)。

**排障过程与根因**:
1. v0.6.2 先做了全局游标轮转 (用户否决: 要每场从 Z 起)
2. v0.6.3 首发约定 (首发必须首个装备槽) — 实测仍 X 首发
3. **v0.6.4 真因**: 连续挂机鱼口密集时, 上一场结束到新咬钩间隔 < 主循环周期 (0.5s), fsmState 来不及回"待机" → enterFight 未执行 → fightFirstCastDone/castCursor 继承上一场 → 首发分支被跳过直接轮转
4. **修复**: FishID 变化检测兜底 — 战斗分支内 fishId ≠ lastSeenFishId 即强制 resetFightState; 重置逻辑抽成 resetFightState() 供 enterFight 与衔接检测共用

**验证**: 决策环形日志确认完整序列 首发命中Z → 轮转命中X → 轮转命中C ✓

**机制情报 (用户提供的权威信息)**: **每场战斗开始所有技能 CD 重置归零**, 不存在跨场残余。此前"CD 残余导致 Z 不就绪"的假设不成立 — 真因就是跨场状态继承。

**踩坑黑名单** (新增):
- [状态机迁移假设] 跨渡事件 (结束→开始) 可能快过一个循环周期, "必然经过中间态"的假设在密集事件流下必碎; 关键重置要绑定数据变化 (FishID) 而非状态迁移路径。
- [PowerShell Set-Content UTF8 加 BOM + 中文替换截断表达式] → 改文件用 Edit 工具, PowerShell 只做复制。
- [可观测性先行] 复杂决策逻辑 (多分支+多过滤+时序敏感) 上线时就该带决策日志, 否则排障全靠猜。

## [2026-08-25 | 会话15 | v0.5.6→v0.6.0 槽位误伤修复 + 双模式]

**用户反馈**: ① 又不首先释放 Heaven's Burden; ② 要双模式 (智能/顺序)。

**根因 (①)**: 实战监控抓到 — 全场只放了 Z, C 槽全程零施放。代码里 `if m.key ~= "C" or autoSlamOn` 按**键位**一刀切跳过 C 槽 (本意防 Slam 小游戏类无 Perfect 配合报 Bad), 但用户把定身输出技 Heaven's Burden 装在 C 槽 → 被连坐。**槽位≠技能类型**。

**修复**: 移除键位判断, 四槽一视同仁; autoPerfect 监听独立常挂 (真 Slam 类弹出按钮时若开关关着由游戏超时报 Bad, UI 文案提醒联动)。

**新功能 (②)**: skillMode 变量 + Dropdown Flag="skillMode"; 顺序模式 = 收集池按 SKILL_KEYS 序号排序取首; 智能模式 = DPS 排序取首。时机过滤 (无敌/定身/血量门槛) 两模式共用。

**实测**: 顺序模式首放 Z ✓; 用户四槽全满新配装 (Taijiquan V3/Beastbreaker/Heaven's/Phoenix V2) 正常识别。

**踩坑黑名单** (新增):
- [按槽位假设技能类型] → 键位只是输入映射, 同一槽可装任意技能; 行为分支必须基于技能自身属性 (分类/DPS), 不能基于槽位。
- ["This tab is Empty" 是 WindUI 常驻隐藏占位] → 扫 UI 文本诊断时必须带 Visible 检查, 否则误判"UI 全空"白折腾两轮。

## [2026-08-25 | 会话14 | v0.5.5 分类误判修复 + DPS 排序]

**用户反馈**: ① 还是没用伤害最高的技能 (最好的是 Heaven's Burden); ② 饵种选择不持久化。

**根因**:
1. **分类器误伤**: Heaven's Burden 描述 "Immune to boss skills, **stun** fish 10s, **heal** 25 HP, deals **current damage**" — 检查顺序 heal 在前被命中 → 归治疗类 → 血量 >70% 时直接跳过不放! 实际它是 DStunHealGod 输出模板 (0.5s 跳伤+定身+附带回血)。
2. **排序缺 CD 因子**: 总伤指数未除以冷却。Heaven's CD 仅 15s (Phoenix 28s), DPS 视角下 Heaven's(6.67) > Phoenix(2.86) > Taijiquan(2.67) — 与用户实战体感完全一致。
3. Dropdown 无 Flag → 配置不存。

**修复**: 分类顺序 stun > damage > heal (只有纯治疗描述才归 heal); 排序公式加 ÷Cooldown; Dropdown 加 Flag="baitSelection"。

**经验教训**:
- [多效果技能分类] 关键词匹配必须考虑"附带效果": 描述含 heal 不代表是治疗技; 判定顺序 = 主效果优先, 输出特征(stun/damage/deals)权重高于辅助特征(heal/power)。
- [玩家体感即事实] 伤害建模无法从客户端完美还原 (current damage 类技能伤害与打鱼 DPS 联动), 用户实战判断比公式更可信 — 公式修正以复现体感排序为准。

## [2026-08-25 | 会话13 | v0.5.4 总伤指数排序]

**用户反馈**: 没用到装备里伤害最高的技能。

**根因**: v0.5.3 按单跳 Damage 排序 — 用户配装 Z=Phoenix(5)/C=Heaven's Burden(5) 面板平手被随机对待, 但 Phoenix 的 SlamTime=0.5s 快跳 × 8s 使其总伤 (80) 是 Heaven's (50) 的 1.6 倍。**面板 Damage ≠ 总伤害, 跳频才是隐藏变量。**

**修复**: getSkillDamage → 总伤指数 = 基数 × Duration ÷ max(SlamTime, 1s) × 暴击期望。实测排序 Z(80) > C(50) > X(20) ✓。

**经验**: 技能 Stats 字段语义要对照实现模板读 — SlamTime/BlinkTime 这类字段决定实际 DPS 结构, 只看 Damage 会系统性误判。

## [2026-08-25 | 会话12 | v0.5.3 技能伤害择优]

**用户需求**: 多个伤害技能优先用伤害高的。

**实现**: getSkillDamage(name) 读 Info.Skill[名].Stats {Damage+SecondDamage} × 暴击期望 (CritChance 默认5%/CritDamage 默认1.5), 结果缓存; burst 队列排序取首。heal 队列保持随机 (治疗无伤害可比)。

**实测**: 当前配装 Z=Phoenix Strike Art V2(5) / X=Taijiquan Technique(2) / C=Heaven's Burden(5) — 排序 Z/C 先于 X, 同伤随机平手 ✓。

**备注**: Damage 是面板基数, 实际跳伤还受竿元素加成 (Description 匹配) 影响 — 未纳入排序 (需要竿 Description 解析, 收益低复杂度高, YAGNI)。若用户反馈"高面板技能实际更弱"再考虑元素加成修正。

## [2026-08-25 | 会话11 | v0.5.2 售鱼跳过锁定]

**用户需求**: 锁定的鱼不算进要出售的鱼。

**实现**: 锁定标记 = Inventory 子项 Name 后缀 `" | Favorite"` (无独立 attribute); sellFishCount() 改为只统计非锁定项 → 阈值触发基于真实可售量 (顺带修复: 有锁定鱼占位时阈值判断偏差)。出售仍走 SellFish("All")。

**风险声明**: 服务器是否跳过锁定不可见 — 设计意图应跳过 (否则锁定功能无意义), 但未实测 (用户有条 ¥9.7万 锁定鱼, 不敢拿它测)。若观察到锁定的被卖, 备选方案 = 放弃 "All" 改逐条或先 MoveItems 隔离。

## [2026-08-25 | 会话10 | v0.5.1 买饵水位线策略]

**用户需求**: 饵用完了再买, 每次用两个买两个, 不囤货。

**实现**: 补货触发条件从 `count<=0 买20个` 改为 `count < reorderAt(默认2) 时买 buyAmount(默认2) 个`; UI 拆成两个 Slider (水位线/单次购买量)。

**踩坑黑名单** (新增):
- [`<=` 水位线边界] → buyAmount=2+reorderAt=2 时: 0→买2→count=2 仍满足 <=2 → 再买 → 无限囤到现金耗尽。补货条件必须严格小于, 且语义文档化 ("降到 N **以下**才补")。
- [实测选品超预算误判为 bug] → Corrupted×10=¥15万 vs 现金 ¥3万 被服务器静默拒绝 — 先算账再测, 排障前核对服务器约束。

## [2026-08-25 | 会话9 | 深挖第二轮]

**发现**:
1. **天赋 13 个全表**: Mythical 四神兽是质变级 — Azure Dragon 低于 40% HP 时**技能无视鱼 Iframe 无敌** (破无敌配装!), Vermilion Bird 每战一次技能 CD 重置, White Tiger 暴击流, Black Tortoise 生存流。天赋重roll (Trait Reroll 货币) 的目标就是抽神兽。
2. **开始包实测全字段**: fishTable={FishName, Power, Time, **Weight 鱼重**}; powerTable=竿完整配置。Weight 开战即知 → 放弃机制可升级为"按预期卖价决策"。
3. Gacha LootTable 客户端为空 (服务器权威); Gamepass 9 个全未购; Boss 鱼 Info 含 Skill 表 (Boss 会放技); 天气运行时值不在客户端可见对象。
4. 玩家已换 Alloy Rod (P22/L5)。

**遗留问题更新**:
- 天赋重roll 自动化 (攒 Trait Reroll 抽 Mythical) — 高价值候选
- Weight 决策升级放弃机制 — 低成本改进
- 其余同会话8清单

## [2026-08-25 | 会话8 | 全面系统分析补全]

**状态**: 纯分析会话。intel.md 新增「系统全景」「元素与天气」「额外协议补充」「成长与角色」四节。

**本次发现**:
1. ClientModule 全量 34 个, 补齐合成(CraftBait/CraftRod)/天气/游泳/精通/技能升级/图鉴等模块认知。
2. **元素配装机制**: 14 元素, 技能 Type=元素; 竿 Description 含元素加成 (Heavenpiercer 对 Shu Daoshan +100%) — 后续自动配装的依据。
3. 天气 6 种 (视觉 folder), 渔获影响未量化。
4. 协议补充: RedeemCode(码)/BuyFishingRod(竿名)/SecretRod(限时竿推送); **ShopHandle/Market 确认废弃** (全库零引用)。
5. 成长结构: Level folder {Level/Experience/MaxExperience} (当前 29 级); 12 剧情 NPC ↔ 22 任务线; 称号/卡池/God Spirit 修仙线/家园 Plot 标记为未逆向区。

**遗留问题** (按自动化价值排序):
1. Boss Rhythm 小游戏 (v0.4 起最大遗留)
2. CraftBait/CraftRod 合成协议 (低成本 Luck 提升)
3. God Spirit/Spirit NPC 养成线
4. 天气→渔获关联量化
5. 家园/FishTank

## [2026-08-25 | 会话7 | v0.5.0 智能放弃 + 自动买饵]

**状态**: 双功能实装实测通过。

**本次完成**:
1. **智能放弃** (用户需求: 钓不上来的鱼直接放弃省时间):
   - 三重判据: ① 力量比 rodPower/fishPower<0.3 (来自 Fishing@逆向的 u385 公式, ratio≤0.5 条全速) 开场即判; ② 开战10s后进度停滞12s; ③ 单场180s超时
   - 放弃动作 = 复用游戏自身失败路径: 断锁条 + Bar tween 出左界 → 客户端判定循环上报 "Out of bar" → 会话正常结束 — **零额外包, 服务器视角与人类脱杆完全一致**
   - 数据源: FishingMinigame 开始包 fishInfo.Power (新增第二监听者, 合法) + require(Info.Inventory[竿名]).Power 缓存 (换竿自动失效)
2. **自动买饵** (用户需求: 列举可购饵+数量, 无存货自动买+装, 有存货先装用完再买):
   - 协议逆向: `Events.BuyBait:FireServer(名, 数量)` + `ok = Events.EquipBait:InvokeServer(名)` (RemoteFunction)
   - 背包结构: Data[UserId].Bait[饵名].Value 计数槽 ×8; EquippedBait StringValue
   - UI: Dropdown 运行时列 Normal 类饵 (含单价+Luck), Mythical 价格 0 不可购不列
   - 简化状态机: count<=0 → 买并 return; 未装 → 装; 健康态不动 — 覆盖"先装等用完再买"
3. 实测: 买5×Crude Mash 扣款精确 ¥50000, EquipBait 回执 true, EquippedBait 同步更新; 自动循环端到端 (setBait→检测0存货→买2×Corrupted Essence→自动装备) 全通。
4. 现金不足行为确认: BuyBait 服务器静默拒绝不报错, 脚本按设计轮询重试, 现金攒够自动补上。

**核心决策记录**:
- 放弃走 "条出界" 而非找收竿协议: 收竿逻辑在丢失代码里 (InputBegan Retractable 分支空体), 且出界路径零风险已验证。
- 力量比阈值 0.3 定死不做 UI (YAGNI): ratio∈[0.3,0.5] 区间脚本锁条仍可一战, <0.3 大概率伤害效率趋零。
- 买饵循环独立 (autoBait 3s) 与钓鱼解耦 (吸取 v0.2.1 教训); 操作节流 5s。

**踩坑黑名单** (新增):
- [`real_script-grep` 的 maxResults 是总匹配数不是每脚本数] → 精确协议搜索时给足配额, 否则漏掉关键调用处。

**遗留问题**:
- 力量比阈值/停滞时长为经验值, 若出现误放弃 (能打赢的被弃) 反馈后调参。
- Mythical 饵 (Frost/Nameless/Rainbow) 获取途径未逆向。
- Boss Rhythm 小游戏仍是最大遗留。

## [2026-08-25 | 会话6 | v0.4.1 技能开场爆发]

**用户反馈**: 不要等鱼快死才放伤害技能。

**根因**: enterFight 观察期 4~6s + 单发长间隔 (0.8~2s) — 短战斗 (低血鱼 5~10s) 的技能窗口被观察期吃掉大半。

**修复**: 观察期缩至 1.5~3s (SkillLocked 双保险挡倒计时); burst/heal 双队列, 伤害类绝对优先; 战斗前 8 秒连发间隔 0.4~1s、之后 0.8~2s (人类"开局技能全交、CD 好补刀"的真实打法 — 更激进反而更拟人)。

**验证**: 首次施放 6.3s → **3.6s**; 4.8s 速杀局成功吃到定身跳伤 (旧逻辑此场景为 0 次施放)。

## [2026-08-25 | 会话5 | v0.4.0 效率优化包]

**状态**: v0.4.0 实装, 传送链路实测通过。

**效率分析结论** (基于会话4数据):
- 单局 = 等咬钩(服务器权威不可压) + 3s 倒计时 + 战斗(Power/技能可控) + 重抛间隔(~2s 已人类化底线)
- **最大杠杆 = 选岛**: 高级岛贵鱼 Cash 为新手岛数十倍 (Battlefield Silver Bream Sovereign vs Trout ¥20), 传送是合法路径
- 次级杠杆: 高 Power 竿缩短战斗; 技能/buff 自动化 (v0.3.0 已覆盖); Luck 装备提升稀有率 (装备层面)
- AFK 系统收益未证实 → 不联动, 防负优化

**本次完成**:
1. 效率统计面板: fish 计数挂 ChildAdded, 现金走主循环差分 (统一口径防重复计数 — doSellAll 回调里不再累计), 战斗计数挂 enterFight。
2. 快捷传送 Tab: Dropdown 运行时读 Spawnpoint 自动跟随游戏更新; 传送=游戏 Setting 模块同款 `HRP.CFrame=锚点.CFrame`; 战斗中拦截防状态错乱。
3. 实测: Bamboo→Amber→Beginning→Bamboo 四次传送全部成功, 服务器无回滚。

**踩坑黑名单** (新增):
- [统计重复计数] 同一收入源只允许一条统计路径 — 差分统计与事件回调统计二选一, 否则双倍记账。

**遗留问题**:
- AFK 收益机制待实测 (开 AFK 对比 1 小时产出)。
- Charge 蓄力对渔获的影响未知。
- 自动买饵/买竿 (BuyInteractItem/ShopHandle 参数) 未逆向 — Luck 提升的自动化路径。

## [2026-08-25 | 会话4 | 游戏数据深挖归档]

**状态**: 纯分析会话, 无代码改动。v0.3.0 继续挂机中。

**本次完成** (全部写入 intel.md 新章节「经济与数值体系」「岛屿渔获分布」「NPC 与功能入口」「Boss 系统」):
1. Info 目录 16 子系统清点: Skill(84)/Inventory(Fish109+Rod39+Tool1)/Skin/Bait(8)/Orb(9)/Trait(13)/MainQuest/Gacha(2池)/Boats(5)/DailyReward/Quest/FishingAreaRarity。
2. **咬钩时长之谜破解**: 等待时间 = 抽到的鱼的 Time 字段 (Trout 5s ~ Boss 30s), 不是全局随机 — "等得久=抽中大鱼"。
3. Luck 经济学: 竿 Luck + 饵 Luck 叠加修正 Chance 抽取权重 → 换高 Luck 装备直接提升稀有鱼概率。
4. 鱼竿梯度表 / 天赋属性表 / 鱼饵表 / 宝珠材料。
5. 9 大功能 NPC 定位 + LearnSkill(学技能 NPC, 自动买技能的入口) + BossSetUp 入场锚点。
6. 核心结论 remember-game 存档 (运行时召回)。

**决策记录**:
- 岛屿权重表不硬抄进 intel.md — require 运行时即取, 避免游戏更新后档案过期; 只记结构和使用方式。
- 数据类结论全部带 `require(...)` 取用路径, 后续功能 (自动买饵/选岛钓鱼/天赋重roll) 可直接引用。

**遗留问题**:
- ShopHandle/Market/BuyInteractItem 参数未逆向 (自动购物候选)。
- LearnSkill NPC 的学技能协议未逆向。
- Boss 战 Rhythm 小游戏仍未逆向 (v0.4 最大目标)。
- Spirit/God 两个 NPC 功能未知。

## [2026-08-25 | 会话3 | v0.3.0 自动技能智能施放]

**状态**: v0.3.0 实装实测通过 (Skyfall Stomp 全链路验证)。

**本次完成**:
1. **技能系统全量逆向归档 intel.md「技能系统」节**: 84 技能定义结构 / 15 实现模板 (ClientModule.Skill.*) / 四键槽制 (Z=Rage,X=Stun,C=Slam,V=Weaken 固定映射, 鱼竿 Skill.Z/X/C/V 槽决定装什么) / 冷却服务器权威 (Character.Skills[类别].Value) / 鱼 Iframe 免伤机制。
2. **技能实现模块语义** (关键发现):
   - DStun 系: 定身期间客户端每 0.5s 直改鱼 Value 跳伤; 结束前 3.5s **全技能 CD+5 惩罚**
   - Rage: RodPower 增力 buff + 可选 TrueDMG 跳伤, 代价每秒自损 Bleed
   - HealOvertime: 持续回血, Poisoned 无效, 结束后同样 CD+5
   - EnhancePower: 限时 RodPower+
   - Stun=true = 玩家自己的条停摆 (会话1已逆向), 锁条脚本不受影响
3. **v0.3.0 自动技能**: 分类施放策略 (categorizeSkill 按 Description 关键词缓存分类):
   - stun 类: Stats.Stun==true 时 skip; heal 类: 血量>70% skip; buff 类: 鱼 Iframe 期照放; damage 类: Iframe 期跳过
   - C 键需 autoPerfect 配合否则跳过; 多技能就绪随机挑一; 0.8~2s 连招间隔; 开场 4~6s 观察期

**核心决策记录**:
- **分类用 Description 关键词而非 Function 模块名**: cfg.Function 是函数引用拿不到源模块名; Description 文案稳定且用户可读。兜底类="damage" (CD 好就放, 合理默认)。
- **时机判断全部读服务器权威状态**: Skills.Value (冷却)/Stats.Stun/鱼 Iframe attribute — 不自建计时器, 与游戏真实状态零漂移。

**踩坑黑名单** (新增):
- [`real_remote-spy` 的 nameFilter 偶发失灵] → seen 在涨但特定 remote 永远抓不到 (手动发包也抓不到); 改用权威信号验证 (如冷却回写 Skills.Rage.Value 0→10), 不要死磕 spy。
- [`os.clock()` 是绝对时间] → start-job 里做超时必须 `os.clock()-t0` 相对值, 直接比较绝对值立即假超时。
- [intel.md edit 吞标题] → 大段替换时 newString 结尾要带上下文锚点, 改完 grep `^## ` 验证章节完整。

**遗留问题**:
- Barrage/Stagger/DOTGodBoost 等 ~8 个实现模板未逐一精读 (分类兜底 damage 已覆盖, 效果语义待需要时补)。
- 技能商店/升级 (BuyInteractItem?) 未逆向 — 自动买技能候选。
- Boss 战 Rhythm 小游戏仍为 v0.4 候选。

## [2026-08-25 | 会话2b | v0.2.1 修复自动出售不触发]

**现象**: 用户设阈值 5, 背包 5+ 条不卖。

**根因 (两个叠加)**:
1. 出售检查 `autoSellCheck` 寄生在自动钓鱼主循环里 — 用户 autoFishOn=false 时循环不跑, 出售永远不检查。**设计缺陷: 功能间隐式依赖**。
2. Slider 没写 Flag → 配置文件无持久化项, reload 后回 Default=20; 内部值停在 20 > 鱼数 → 永不触发。诊断时配置 JSON 里只有 4 个 Toggle 的 key, 无 Slider — 这是"Flag 忘写"的直接证据。

**修复**: 出售独立 StartLoop("autoSell", 2s) 与钓鱼解耦; Slider 加 Flag="sellThreshold" + Callback 数字类型/范围防御; dbg.setSell 走同一 setAutoSell。

**验证**: setSell(true,5) + 背包12条 → 6s 内全卖 Cash +2768 ✓

**踩坑黑名单** (新增):
- [WindUI 元素漏写 Flag] → 不进 ConfigManager 持久化, reload 回默认值; 排障时先 cat config/main.json 对照 __elements 清单。
- [副功能寄生在主功能的循环里] → 主开关一关副功能静默失效; 有多开关的功能一律各自独立循环 (StartLoop 开销可忽略)。
- [诊断顺序] 先读运行时状态 (dbg.state) 再看控制台日志再猜代码 — 本次 state 直接暴露 sellThreshold=20 ≠ 用户设定的 5。

## [2026-08-25 | 会话2 | v0.2.0 自动出售 + 整体分析归档]

**状态**: v0.2.0 实装实测通过。整体系统分析已写入 intel.md (Remote 全清单/世界地点/数据结构)。

**本次完成**:
1. **整体功能分析归档**: Events 全目录清点 (41+ remote 分类表)、10 岛屿 Spawnpoint 坐标、Data[UserId] 数据结构、Menu 六大面板 — 详见 intel.md「Remote 清单」「世界与地点」「数据结构」三节。
2. **卖鱼协议验证**: `SellFish:FireServer("All")` 任意位置可卖 (+1216 Cash/5条), 无 NPC 距离校验无弹窗。
3. **传送机制确认**: 游戏"回到出生点"= 纯本地 `HRP.CFrame = Spawnpoint[区].CFrame`, 无校验 → 岛屿瞬移合法路径, 后续传送 Tab 直接可用。
4. **v0.2.0**: 自动出售 (阈值 Slider 默认 20 / 背包满自动卸货续钓 / 手动全卖按钮) + 钓获通知 + 战斗进度显示。
5. 实测: 低阈值触发链完整 (阈值到→全卖→Cash 到账→自动重抛续钓), 回归监控通过。

**核心决策记录**:
- **出售触发放主循环而非独立 ChildAdded 计数**: 复用 autoFishTick 的 0.5s 节奏 + 10s 卖鱼节流, 不加新循环; 战斗中不卖 (避免干扰小游戏 UI/通知轰炸), 结束后下一轮补卖。
- **背包满行为升级**: 开自动出售 → `doSellAll("背包已满")` 后 1.5s 冷却继续钓; 未开 → 维持暂停+提示引导。
- **dbg 与 UI 不同步的坑 (未修, YAGNI)**: 热替换后立即用 dbg.setSell 绕过 UI 设状态, 偶发被 ConfigManager 异步回写复位 (一次性事件); 用户走 UI Toggle 则无此问题。devlog 记录, 发布路径不受影响。

**踩坑黑名单** (新增):
- [`real_search-instances` selector 裸 `*` 在 fallback 引擎返回 0 条] → 用 get-descendants-tree 或具名 selector。
- [PowerShell Select-String 读 UTF-8 中文文档乱码] → 用 Grep 工具代替。
- [`check-script` 传残缺源码是自欺] → 要么传完整文件内容, 直接依赖 live-reload 编译门。

**遗留问题** (继承会话1 + 新增):
- Boss FinalPhase Rhythm 小游戏未逆向 (v0.2 候选未做, 顺延)。
- 经济侧 Market/ShopHandle/BuyFishingRod 参数未逆向 (商店自动化候选)。
- dbg/UI 状态同步竞态: 仅开发态绕过 UI 时出现, 若后续 dbg 使用频繁再考虑走 Config:Set。
- 传送 Tab 未实装 (协议已明确, 一小时工作量)。

## [2026-08-25 | 会话1 | v0.1.0 自动钓鱼首飞]

**状态**: v0.1.0 已实装并实测通过。placeVersion 2913。

**本次完成**:
1. 启动协议建档 games/heavy-fishing/ (未命中旧档, 新建)。
2. 逆向完整钓鱼协议 (详见 intel.md「协议与通信」, 已全部验证):
   - 抛竿/咬钩/打鱼伤害通道 (UpdateFishProgression 10Hz 无参包)/失败上报/SessionEnd 迟到包机制
   - Slam 判定: tween 上限 1 < 1.15 阈值 → 2.1s 内必 Perfect
3. hub.luau v0.1.0: 三功能 (自动钓鱼锁条 / 自动 Perfect / 自动蓄力) + 设置标配。
4. 质量门全过: check-script 0 error 0 warning; 实测连续捕获 (Azure Carp/Catfish 等); profile-frames 237FPS 0 慢帧。

**核心决策记录**:
- **锁条方案优于伪造包**: 打鱼伤害 = 游戏自身协程读 Bar.Position 后按 10Hz 发 UpdateFishProgression。脚本只控制本地 Bar UI 位置 (服务器不可见), 不发任何额外包 → 服务器视角与人类完美操作无差异, 定性 L1。
- **判定区 [0.40,0.62] 由实测得出**: 反编译器丢失了主判定循环函数体 (bytecode 有字符串但文本缺失), 改走 record-session 观察 bar-vs-hp 因果线拿到区间。
- **锚点随机游走 [0.46,0.54] 每 2~4s 一换**: 拒绝死钉 0.500 的机器特征; 0 时长 TweenPosition 覆盖游戏活动 tween 与游戏自身 Phase2 分支同款手法。
- **Slam/Charge 用"延迟查按钮存在性"去重**: 游戏 handler 也挂同一 OnClientEvent, 若用户手点过则跳过; Slam 必须 Destroy 按钮阻止游戏 2.1s 超时分支报 "Bad"。
- **dbg 接口 (`_G.RCWTK_DBG.heavyFishing`)**: send-input 受窗口焦点限制不可靠, 开发期用代码驱动 Toggle。发布构建时移除该段。
- **Real 文件部署路径**: executor readfile 基准 = `C:\Users\CARSER\AppData\Local\Real\workspace\`, 项目结构原样复制过去 (lib/theking.luau + games/heavy-fishing/hub.luau), hub 源码零改动。

**踩坑黑名单** (只增不删):
- `[StartLoop opts.jitter=true]` → 库内 jitter 必须是数字比例, 传 true 在 `jitter > 0.5` 处炸 "compare number < boolean" → 要么省略 opts (默认 0.15), 要么传数字。
- [`rawget(...) or rawset(...)` 作语句] → Luau 禁止表达式语句, 用 if 包裹。
- [`real_get-script-content` 首次调用可能返回残缺反编译] → build-script-index 后用 docId 精确重读, totalLines 对不上就怀疑缓存残缺。
- [`firesignal` 在 Real 是 no-op] → 点 UI 用 send-input 但受焦点限制; 自动化测试优先暴露 dbg 函数直接调。
- `[SendMouseButtonEvent(10,10)]` → 顶部控鱼条/BossFightBar 吃掉点击 processed=true, 没晃动还可能错按 → GetGuiObjectsAtPosition 找视口中下部空像素。
- `[0 时长 Tween 锁条]` → 条钉死一眼脚本 → 走游戏点击 +0.1 回弹, 只做出界保命。
- `[StartLoop 打节奏]` → [50ms 下限 + 默认 ±15% 抖动, 过线帧对不齐] → [节奏用 Heartbeat, jitter=false]
- `[没过线就 RhythmHit]` → [Good/Miss] → [y>=判定线才发, 迟到窗小于音符间距]

**遗留问题**:
- Boss 战 FinalPhase 的 Rhythm 小游戏 (ASD 键道) 未逆向, boss 最终阶段会自然失败 — v0.2 候选。
- dbg 接口段发布前需移除 (build.py 构建时人工确认)。
- 经济侧 remote (SellFish/Market/AwakeRod) 未逆向, 自动卖鱼是下一个自然功能。
- 官方 AutoFishing (Level≥100) 未深挖 — 若号练到 100 可对比服务端实现细节。

**验证方式复述**: `_G.RCWTK_DBG.heavyFishing.state()` 读状态机; workspace.Fishes[FishID].Value 看打鱼进度; 背包 Inventory 子对象看捕获结果。

## [2026-08-25 | 会话1 | 初始化]

**状态**: 新游戏建档, placeVersion 2913。

**本次完成**:
- 启动协议: get-game-info → 未命中档案 → 建 games/heavy-fishing/ 三件套。
- 目标: 自动钓鱼 (Tap 小游戏完美判定)。

**决策记录**:
- 目录名 `heavy-fishing` (kebab-case 规范)。

**遗留**:
- 钓鱼系统逆向未开始。
