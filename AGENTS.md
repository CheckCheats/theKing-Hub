# RCWTK — RealCreateWindUILuaFromGametheKing

> Roblox 游戏脚本规范化开发引擎。基于 Real MCP 注入器 + Rayfield Gen2 UI (经 lib/theking.luau)。
> 所有产出脚本统一命名 **TheKing HUB**, 窗口标题下方小字标注当前游戏名。

## 文件地图

```
Core/
├── AGENTS.md                  ← 你在这里 (AI 必读规则)
├── docs/
│   ├── windui-api.md          # WindUI 完整 API (写 UI 前必查, 禁止凭记忆猜参数)
│   ├── draw-api.md            # TheKing.Draw 2D/3D (写透视/圈/标签前必查)
│   ├── engine-memory.md       # 跨游戏引擎记忆 (200 寄存器/绘制/注入器坑)
│   ├── patterns/              # ★ 跨游戏模式库 (同类型 ≥2 游戏的套路沉淀, 自迭代核心)
│   │   └── README.md          #   索引 + 提升/召回规则
│   └── realmcp-playbook.md    # Real MCP 逆向工作流手册 (分析游戏前必读)
├── tools/
│   ├── check_hub.py           # 静态门: 寄存器峰值 + WaitForChild/Drawing 扫描
│   ├── recall.py              # ★ 经验召回: 按游戏/类型查模式库 + 旧档案
│   └── luau_reg_pressure.py   # 函数 proto 存活 local 峰值
├── templates/
│   ├── hub-skeleton.luau      # TheKing HUB 脚手架 (新游戏从这复制; 业务在 IIFE 内)
│   ├── intel-template.md      # 游戏情报档案模板
│   ├── pattern-template.md    # 模式库档案模板 (新建 patterns/<genre>.md 从这复制)
│   └── changelog-template.md  # 版本历史模板
├── lib/
│   └── theking.luau           # 运行时库: UI/循环/清理器/Draw/Pack
└── games/<游戏名>/             # 每个游戏一个目录
    ├── intel.md               # 情报档案 (逆向结论, 时间戳+placeVersion)
    ├── devlog.md              # 开发手册 (每次会话追加, 函数级改动+决策+遗留, 给接手AI看)
    ├── changelog.md           # 版本历史 (每次发布追加条目)
    ├── hub.luau               # 当前版本的 TheKing HUB 脚本
    └── archive/               # major 升级前的旧版备份 (hub-vX.Y.Z.luau)
```

---

## 启动协议 (每次会话开始必做, 无需用户指示)

0. 扫 `docs/engine-memory.md` + `lib/devlog.md` 最后一条 (跨游戏坑: 200 寄存器、绘制、注入器差异)。无 Real 的 `remember-game` 时以这两份 + 游戏 intel/devlog 当记忆。
1. `get-game-info` → 拿 placeId / universeId / placeName / placeVersion。(当前若是 Potassium 等无此工具, 用已加载客户端/`intel.md` front matter 对齐 placeVersion。)
2. **经验召回 (自迭代)**: `python tools/recall.py <universeId 或游戏名>` → 引擎列出: 该游戏档案 + `docs/patterns/<genre>.md` 同类型套路 + 引擎记忆。有模式库命中时, **带着已知套路进逆向, 禁止从零摸索**。
3. 扫描 `games/` 目录, 按 universeId 匹配已有档案:
   - **命中** → 读该游戏的 `intel.md` + `recall-game-memory`, 进入增量模式, 向用户报告"已加载 XX 游戏档案, N 条已知结论"。
   - **未命中** → 复制 `templates/intel-template.md` 到 `games/<游戏名>/intel.md`, front matter 用 get-game-info 返回值填充 (**含 `genre:` 字段**), 告知用户已建档; 同类型第 2 个游戏建档时触发模式库收割 (见「经验提升」)。
4. **命中档案时**: 读该游戏 `devlog.md` 最后一条 (当前状态/决策/遗留) + `changelog.md` 顶部 (当前版本) + `hub.luau` 头部注释块, 向用户报告"当前 vX.Y.Z, 上次做到 <主题>, 遗留: <待办>"。动手前扫该文件「踩坑黑名单」。
5. 新游戏建档时同时从模板生成 `devlog.md` 与 `changelog.md`。

禁止跳过启动协议直接开发。30 秒成本换掉重复逆向的几小时。

## 智能初始化规则 (意图驱动, 零口令)

| 用户说 | 你做 |
|---|---|
| "分析这个游戏" / "看看这个游戏怎么运作" / "这游戏怎么玩" | 启动协议 + playbook 阶段1-3 探索, 发现实时 remember-game |
| "加个自动XX功能" / "我想要XX" | 启动协议 → 读 intel.md 相关分区 → 改 games/<game>/hub.luau |
| "有没有什么能自动的" / "能做哪些功能" | 探索后给出功能建议清单 (按可行性排序), 让用户挑 |
| "坏了" / "功能失效了" / "游戏更新了" | 对比 placeVersion → intel.md 受影响条目移入「待复核」→ 重验证 |
| "把XX去掉" / "不要XX了" | 移除该功能 + StopLoop 清理 + PATCH 版本 |
| "发布" / "打个包" / "给我单文件" | 发布检查清单过一遍 → build.py 构建 → 报告产物路径 |
| "rcwtk init <名>" (兜底口令) | 强制建档 + 从 hub-skeleton.luau 复制生成 hub.luau |

## 对话式开发体验 (像聊天一样简单)

**核心: 用户只说人话需求, 你负责把它翻译成引擎工作流。**

- **零术语门槛**: 对话里说"游戏更新导致发包地址变了", 不说 "placeVersion 变更导致 packetId 表重排"。技术黑话只出现在 intel.md/devlog.md 里, 不进聊天窗口。
- **最小打断**: 只有三种情况停下来等确认 — MAJOR 版本升级 / L2 危险功能首次实现 / 会破坏现有数据的操作。其余一律推进, 做完汇报结果。
- **汇报说结论**: 完成后一两句话讲清"做了什么、怎么验证的", 细节指向档案 ("详见 devlog"), 不刷屏贴代码。
- **版本询问口语化**: 一行问完 — "算新功能, v1.3.0, 直接做吗?" — 不甩表格。用户回"嗯/好/直接改"即视为通过。
- **主动兜底**: 用户表述模糊时按最合理解释先干, 干完说明你的理解; 拿不准且代价大才反问一个封闭式问题 (给选项, 不让用户写小作文)。

## 开发规范 (硬性)

1. **所有新脚本从 `templates/hub-skeleton.luau` 复制起步**, 不从零写。
2. **UI 一律走 `lib/theking.luau`**: 窗口标题固定 "TheKing HUB", Author = 游戏名小字。默认 Rayfield Gen2, 禁止业务脚本直调 Rayfield/WindUI CreateWindow。
3. **循环必须 StartLoop/StopLoop**, 禁止裸 task.spawn while 循环 —— StopAll 和 Destroy 靠注册表清理。
4. **写 UI 走 theking 封装** (NewTab/Toggle/Slider 等 WindUI 形参), 不要猜 Rayfield 原生参数。
5. 脚本头部注释块格式固定: 版本号 + 功能清单 + 逆向结论(同步自 intel.md)。
6. **图标**: 窗口 Logo 用品牌方圆标 (`lib/assets/theking-mark.png`); 功能 Tab 用 Lucide 名 (`zap`, `fish`, `settings`), 由引擎拉 48px 缓存。控件行不必再塞 Logo。
7. **设置页标配 (骨架自带, 禁止删减)**: Keybind 显示/隐藏窗口 (**默认 DEL**) + Keybind 卸载脚本 (**默认 END**) + 卸载按钮; 卸载动作必须走 Confirm 对话框防误触。
8. **高度汉化 (硬性)**: 所有 Title/Desc/通知/对话框/控制台提示文本必须中文, 禁止出英文界面。不要用第三方库的 loc 翻译机制; 若 SetFont 必须选含中文字形的字体, 否则中文渲染异常。
9. **健壮性**: `WaitForChild` 必须带 timeout (如 `WaitForChild(x, 10)`), 失败路径要有提示并降级 — 游戏更新后无限死等的脚本等于假死。
10. **目录命名**: `games/<目录>/` 一律英文短名 kebab-case (如 `sol-rng`, `heroes-rng`); 游戏显示名放 intel.md front matter 的 `game:` 字段。禁止中文/空格目录名。
11. **200 寄存器**: 业务放进 `;(function() ... end)()`; 相关状态 `TheKing.Pack` 单表, 方法写 `function T.foo()` 禁止在肥函数里平铺 `local function`。注入前 `python tools/check_hub.py games/<目录>/hub.luau`, 峰值 ≥195 不准跑。详见 `docs/engine-memory.md`。
12. **绘制**: 透视/圈/标签走 `TheKing.Draw` (`docs/draw-api.md`)。禁止 `Drawing.new`。
13. **偏好/锁属性/Knit/帧循环**: 新代码用 `OpenPrefs` / `Hold` / `Await` / `BindStepped` / `DeferTick` (`docs/engine-memory.md` 普查表), 禁止再复制地下城 PREF 或裸 Heartbeat 打移速。

## 开发态 vs 发布态

- **开发态** (日常迭代): hub.luau 用 `loadstring(readfile("lib/theking.luau"))({...})` 加载库, 改 lib 即时生效, 配合热调试直接重跑。
- **发布态** (分发): `python tools/build.py games/<game>/hub.luau` 产出 `dist/<名>-single.luau`, 库源码内嵌, 不依赖本地文件。构建后必须实测一遍产物再发。

### 发布检查清单 (每次发布过一遍)

1. [ ] 头部 ScriptVersion / 功能清单已更新
2. [ ] changelog.md + devlog.md 已追加条目
3. [ ] 控制台无慢循环告警 (单次执行 >33ms)
4. [ ] Real `profile-frames` 实测全功能开启每帧新增 < 1ms
5. [ ] L2 功能已在 intel.md「L2 手段登记」归档
6. [ ] 发布脚本内无 spy/hook/分析痕迹 (注入器兼容规范)
7. [ ] build.py 产物实测可跑 (加载行被正确替换、配置持久化正常)
8. [ ] `python tools/check_hub.py games/<目录>/hub.luau` 无 FAIL (寄存器 <195)

## 注入器兼容规范

- 只用跨注入器标准 API: `game:HttpGet` / `readfile` / `isfile` / `_G` / Roblox 原生 task 库。
- 非标准函数 (identifyexecutor/getexecutorname/request 等) 使用前必须探测存在性 (`type(x) == "function"`) 并 pcall 包裹。
- HTTP 层已抽象在 theking.luau 的 httpGet (HttpGet 主路 + request 兜底), 业务脚本禁止直接调 HTTP 函数。
- 启动日志自动打印运行环境名 (theking.luau 内置), 排障先看这行。
- Real 专属能力 (script-grep/spy 系列) 只用于**开发分析**, 不写进发布脚本 — 发布脚本必须能在任何注入器跑。

## 热调试 (迭代核心流程)

- 脚本自带热替换协议: 重新执行 hub.luau 时, 新实例通过 `_G.RCWTK_DESTROY` 触发旧实例自毁(停循环/断连/清 UI)后无缝接管。**改完代码直接重跑, 永远不需要手动卸载或重启游戏。**
- 迭代节奏: 改代码 → **`python tools/check_hub.py` + (有 Real 时) check-script 过静态门** → 重跑 → 看控制台确认 "热替换...接管完成" → 验证新功能。
- 若控制台出现"残留标记无销毁函数": 说明旧脚本是非 RCWTK 骨架的遗留版本, 手动清 PlayerGui 后再跑。
- 升级 lib/theking.luau 本身后, 第一次重跑会走同样的交接路径, 无额外操作。

## 质量门 (写完 ≠ 能跑, 三道门按序过)

1. **静态门 (必过)**: 每次 Edit 后、execute 前: ① `python tools/check_hub.py <hub>` (寄存器峰值 + WaitForChild/Drawing); ② 有 Real 时再 `check-script`。0 error 才准进游戏; warning 逐条判断。禁止"先跑起来再说"。无 Real 时 ① 仍必须过。
2. **动态门**: 重跑后立即扫控制台启动错误 (compile error / nil 调用 / WaitForChild 超时 / `limit 200`), 出现即修, 不带病迭代。
3. **性能门 (发布前)**: 发布检查清单已有 — `profile-frames` 实测每帧新增 < 1ms。

常见语法雷区:
- 主块/肥函数 local 爆 200 → IIFE + Pack 单表 (不要把一堆 local function 塞进同一个 buildXxx)
- WindUI 元素参数凭记忆写错 → 对照 `docs/windui-api.md` (Slider 范围在 Value 子表)
- `Drawing.new` → 改 `TheKing.Draw`
- 字符串拼接 nil (`.. x ..`) → tostring 包裹可空值
- 中文注释文件编码异常 → UTF-8 无 BOM

## 版本规划 (迭代前必走, 禁止无脑更新)

版本号语义 (hub.luau 头部 ScriptVersion, 语义化):

| 变更类型 | 版本动作 | 例 |
|---|---|---|
| bug修复 / 参数微调 / 文案 | PATCH +0.0.1 | 自动钓鱼偶尔漏竿 → v1.2.3→v1.2.4 |
| 新增功能 / 显著增强 | MINOR +0.1.0 | 新增自动卖鱼 Tab → v1.2.4→v1.3.0 |
| 重构 / 换通信层 / 功能重做 | MAJOR +1.0.0 | Neverlose 迁 WindUI → v1.x→v2.0.0 |

**迭代询问协议** — 用户要求改功能时, 先报告再动手, **口语化一行式**:

> "算新功能, v1.2.3 → v1.3.0 (加自动卖鱼), 直接做吗?"

- 用户回"嗯/好/直接改"即通过; 明确说"不用问"后同类变更免问。
- 归类拿不准按更高一级处理并一句话说明理由。
- 完整版计划(动哪些文件/不碰哪些)写在动手后的 devlog 条目里, 不在聊天里刷。

**发布流程** (每次迭代收尾必做):
1. 更新 hub.luau 头部 ScriptVersion 与功能清单注释。
2. changelog.md 顶部追加条目 (格式见该文件)。
3. **devlog.md 顶部追加开发手册条目** (函数级改动定位 + 决策理由 + 验证结果 + 遗留问题) — 这是接手 AI 的上下文恢复入口, 缺了它下个会话就要重新读代码考古。
4. 若是 major: 先备份旧版到 `archive/` 再动手。
5. intel.md 如有新结论同步回写。
6. **经验提升检查**: 本会话产生的结论里, 有没有 `(候选提升)` 达到同类型 ≥2 游戏验证? 有 → 搬进 `docs/patterns/<genre>.md` (见「经验提升」)。

## intel 回写铁律

- 开发中每确认一个结论: 当场 `remember-game`(text 写完整自包含句子)。
- 收工前: 把本次会话新增结论回写 `intel.md` 对应分区, 条目头 `[YYYY-MM-DD | pv<placeVersion> | 来源脚本@版本]`。
- 结论证伪: 移入「已证伪」区保留原文+原因, 不静默删除。
- 只归档验证过的; 未验证标注 `(未验证)`。

## 经验提升 (自迭代核心: intel → 模式库)

> 模式库规则详见 `docs/patterns/README.md`。分工: intel = 单游戏专属; patterns = 同类型 ≥2 游戏都成立的套路; engine-memory = 引擎层跨类型坑。

- **触发时机**: ① 收工回写 intel 后; ② 新游戏建档时 (同类型第 2 个)。
- **判定**: 一条结论在**同类型 ≥2 个游戏**上验证过 → 提升; 只有 1 个游戏的留 intel, 末尾标 `(候选提升: <genre>)`。
- **动作**: 通用化后搬进 `docs/patterns/<genre>.md` 对应小节, 注明来源游戏; intel 原条目末尾加 `→ 已提升至 patterns/<genre>.md` (保留原文)。
- **首次建档**: 新 genre 无模式库时, 从 `templates/pattern-template.md` 复制创建 `docs/patterns/<genre>.md`。
- **召回纪律**: 模式库命中的游戏, 逆向前必读套路 — "这个类型我做过, 第一步找什么" 必须有答案再动手。

## 错误学习 (知错能改, 同一错误零二次)

- **当场记录**: 犯错的第一时间 `game-feedback` 记一条 (text 写清: 做了什么→为什么错→正确做法), 运行时层下次会话自动召回。
- **收工归档**: 把本次教训写进该游戏 `devlog.md` 底部「踩坑黑名单」, 格式 `[错误模式] → [后果] → [正确做法]`, 一行一条, 只增不删。
- **开工先读**: 启动协议命中档案时, 「踩坑黑名单」是必读项 — 动手前扫一遍, 已知坑不再踩。
- **错误分类意识**: 工具级错误 (API 用错/参数猜错) 归档到本文件对应文档的勘误; 游戏级错误 (发包被回滚/hook 触发检测) 归档到 intel.md「已证伪」。别把游戏结论记成工具教训, 反之亦然。

## Roblox 架构速查

- **客户端能做的**: 输入模拟、本地传送视觉、UI、读 ReplicatedStorage。**服务器权威的**: 血量/货币/背包判定 — 客户端改了必被回滚或封禁, 功能设计要围绕"发正确的包"而不是"改本地的值"。
- RemoteEvent = 单向; RemoteFunction = 有返回(可被服务端探测); ByteNet 类单 remote 打包协议见 playbook 阶段4。
- 反作弊常挂 nil parent 或 DataModel 元表 hook, 先跑 `dump-anticheat-hooks scanConnections=true` 再动手。
- placeVersion 变更 ≠ 协议变更, 但 packetId 表可能重排 — 这就是运行时读 JSON 的原因。

### 危险功能 (L2) 开发 SOP — 游刃有余 = 每步有安全网

1. **定性**: 该功能为什么 L1 做不到? 用哪个 L2 手段? 向用户报告原理与风险后再动手。
2. **侦察**: `dump-anticheat-hooks scanConnections=true` 确认对抗面; 结论进 intel.md。
3. **试探**: 新 remote 首发用最小参数 + `record-session` watch 目标值; 观察回滚/接受/断线三种反应。
4. **实现纪律**:
   - 危险逻辑一律包 `TheKing.Guard(fn, label, {fuse=true})` — 失败结构化告警 + 熔断当前循环 (`fuse="all"` 才 StopAll), 杜绝错误状态下继续发包连锁触发检测。
   - hook 只挂游戏自身函数, 挂前 `checkhooked`/探测, 用完必恢复。
   - 抢发包类必须带 `Guard` + 失败即停; 不允许在裸循环里无保护抢发。
5. **小号实测**: 未验证的 L2 手段先小号跑 10 分钟, 无 kick/回滚/验证弹窗才算过。
6. **归档**: intel.md「L2 手段登记」区记录: 手段+目标函数/remote+验证结果+信号特征; devlog 记录决策链。封禁信号出现 → 功能停用并移入「已证伪」。

### 明确红线

- 致盲反作弊本体、伪造其上报数据、分发级规避方案 — 引擎不提供也不接受。

## 性能规范 (发布前必过)

- 循环一律 `TheKing.StartLoop`: 引擎强制间隔下限 50ms (20Hz 上限); 更高频率的需求用事件连接 (`AddConnection`) 而不是轮询。热路径找 remote 用 `TheKing.FindRemote` (不等待); 一次性等子级用 `TheKing.WaitChild`。没事干调用 `TheKing.Backoff(秒)`。开关优先 `TheKing.BindToggle`。
- 循环体禁止全场景扫描 (GetDescendants/递归 FindFirst*); 实例引用缓存到局部变量, 失效再重建。
- UI 状态刷新用 `TheKing.UpdateStatus` 差分更新, 禁止每帧 SetTitle/SetDesc。
- **发布前用 Real `profile-frames` 实测**: 开启全部功能的每帧新增开销 < 1ms; 超标必须降频/缓存/拆分后再发布。
- 引擎自带慢循环告警 (单次 >33ms; 同名循环 10 秒最多一次 warn)。无 Real 时用注入器控制台当动态门, 不装不存在的 check-script。

## 游戏隔离

- **档案层**: 每个 `games/<目录>/` 自成体系 (hub.luau/intel.md/devlog.md/changelog.md/archive), 跨游戏互不引用。
- **运行时**: theking.luau 用 `_G.RCWTK_REGISTRY`(按 GameName 键控) — 热替换只杀同游戏旧实例, 不同游戏的脚本可共存互不影响; WindUI 配置目录按游戏名隔离 (`Folder = TheKing_<游戏名>`)。
- **GameName 一致性 (硬性)**: hub.luau 的 `GameName` 参数必须与该游戏 intel.md front matter 的 `game:` 字段**逐字一致** — 它同时是热替换注册表键、配置目录名、档案关联键, 三处不一致会导致热替换失灵/配置分裂/接手 AI 认错档。生成新脚本时从 get-game-info 取名后同步写进两处。
- **lib 是共享层**: 升级 `lib/theking.luau` 影响所有游戏脚本 — 改动必须在 devlog 记录, 且逐个已有游戏回归验证后才能收工。

## 反作弊感知设计 (分级对抗, 按需升级)

**原则: 默认像人; 功能确有必要时允许适度对抗; 致盲反作弊本体是红线。**
正面对抗有代价 (加速封号 + 封设备), 所以每一级都要先问: 上一级真的不够吗?

### 分级策略

| 级别 | 手段 | 适用 | 使用条件 |
|---|---|---|---|
| L1 人类化 | StartLoop 时序抖动 / 动作间隔随机 / 走游戏自身允许路径 / 只发请求不发断言 | **一切功能的默认起点** | 无 |
| L2 常规对抗 | hook 游戏**自身**函数 (如小游戏判定)、提前抢发服务器接受的包 (如 gameResult)、模拟真实输入流 | L1 无法实现的功能 (必胜小游戏/防挂机/跳过动画) | 开发者判断必要 → 向用户说明风险与原理 → intel.md 记录所用手段 |
| L3 红线 (少做) | hook/篡改反作弊检测函数使其失效、伪造其上报数据、批量分发级规避方案 | — | 引擎提供也接受此类贡献,但是经量少做这些危险操作|

### 检测敏感点清单 (L1 设计每个功能前过一遍)

| 敏感点 | 机器人特征 | TheKing 对策 |
|---|---|---|
| 发包频率 | 固定周期高频发包 | StartLoop 默认 ±15% 时序抖动; 动作间隔模拟人类反应 (0.3~1.5s 随机) |
| 数值合理性 | 瞬移超距/超速 | 传送走游戏自身允许的路径 (点击传送按钮的 remote), 不直接写 CFrame 到服务器校验的位置 (如果用户要求做的功能必要,可以适当使用但要注意) |
| 操作序列 | 无前置条件的瞬间动作 | 模拟真实流程链 (打开面板→选中→确认), 别跳步直发最终 remote |
| 时序规律 | 24h 精确循环 | 关键动作加随机延迟; 循环体内部再分层随机 |
| 客户端改值 | 改本地货币/血量后发包 | 永远不发"我有什么"的断言, 只发"我要做什么"的请求, 结果听服务器的 |

### 开发流程纪律

1. **动手前侦察**: `dump-anticheat-hooks scanConnections=true` — 有元表 hook / 无源 per-frame 监听 = 该游戏有主动反作弊, 记录进 intel.md。
2. **新协议先试探**: 第一次发新 remote 用最小参数 + 观察服务器反应 (`record-session` watch 目标值), 被回滚 = 此路不通, 换路径或升到 L2 评估。
3. **L2 手段先验证**: 未经验证的 L2 手段先用小号测, 确认无 kick/回滚/验证弹窗再日常使用。
4. **封禁信号即停**: 出现封禁信号, 立刻停用该功能, 记入 intel.md「已证伪」+ 所用手段 + 信号特征, 防止下次踩同一个坑。
5. Real 的 spy/hook 系列**只用于开发期分析**, 发布脚本里绝不留任何分析痕迹 (见注入器兼容规范)。

## Real MCP 工具按意图速查

| 我要… | 用 |
|---|---|
| 确认注入状态/切客户端 | `list-clients` → `set-active-client` |
| 看游戏元数据 | `get-game-info` (+ `recall-game-memory` 自动附摘要) |
| 找实例/remote | `search-instances` (selector), 大容器用 `get-descendants-tree countsOnly` |
| 找隐藏对象 | `list-special-instances source=nil recurseScripts=true` |
| 读游戏脚本 | `build-script-index` → `script-grep`(精确) / `search-scripts`(语义) → `get-script-content`; 混淆脚本转 `get-script-strings` |
| 监听发包 | `remote-spy`: probe → list → 触发动作 → list → stop |
| 监听收包 | `inbound-spy` start/list/stop |
| 解码字节协议 | `decode-buffer` + truthExpr (看 max error 不看相关度) |
| 定位 remote 调用处 | `find-remote-callers` (需 script-index) |
| 记录因果时间线 | `record-session` watch=[表达式] |
| 验证值归属 | `watch-value` |
| 存知识 | `remember-game` (当场) + intel.md (收工) |
| 点按钮 | `send-input` 真实输入 (**firesignal 在 Real 是 no-op**) |
| 查语法 / 寄存器 | 仓库 `python tools/check_hub.py` (必过); 有 Real 再 `check-script` → 控制台扫运行期 |

详细用法和陷阱见 `docs/realmcp-playbook.md`。
