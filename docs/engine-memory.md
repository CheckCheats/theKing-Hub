# RCWTK 引擎记忆 (跨游戏)

> 跨所有 `games/*` 的坑、约定、能力。游戏专属结论仍写该游戏 `intel.md` / `devlog.md`。
> **每次会话** (含引擎升级): 扫本文件 + `lib/devlog.md` 最后一条。新坑只增不删。

## 启动时还要带上

- `python tools/check_hub.py games/<目录>/hub.luau` — 改完 hub / 即将注入前
- 绘制: `docs/draw-api.md` (禁止 Drawing.new)
- UI 参数: `docs/windui-api.md`

---

## 从现有脚本收回来的经验 (2026-09-04 普查)

| 游戏 | 反复出现的问题 | 引擎对策 (lib 2.2.0) |
|---|---|---|
| 地下城战利品者 | Rayfield Flag 不落盘; WalkSpeed 50ms 被打回; Knit 当同步; 200 寄存器; Drawing 崩 | `OpenPrefs` `Hold` `Await` `Pack` `Draw` |
| 重型钓鱼 | 主块 200; 节奏对不齐 StartLoop; Toggle 创建不触发 Callback; hookmetamethod 污染 | `BindStepped` jitter=false 仍不够就用帧连接; 禁止元表 hook 做功能 |
| 狙击场 | Toggle+Flag+Tween 点开关崩; Drawing 圈崩; 心跳里扫人崩 | 暴力开关无 Flag; 圈走 `Draw`; 选人低频、绘制只画缓存 |
| 清洁世界 | StartLoop 里同步慢 Invoke / 抛物线 yield | `DeferTick`; 缓存; 热路径禁止 WaitForChild |
| Heroes RNG | Flag 创建误 Callback(true); 裸 task.spawn 热替换杀不死 | BindToggle 已有; 常驻逻辑必须 StartLoop/BindStepped |
| 学兰 | HttpService:GetAsync 403; getupvalue 打在已 hook 的函数上 | HTTP 走引擎 httpGet; `Upvalue` pcall |

**新功能默认用这些 API, 不要再在 hub 里复制一份 PREF/Heartbeat 锁属性。** 旧 hub 能跑就先不迁, 大改时再换。

### 不进引擎的 (游戏语义, 不是基建)

- 职业档案 / Knit 服务名 / 房间祭坛 / 钓鱼状态机 / 静默瞄准调用栈 — 继续写该游戏 intel
- 致盲反作弊、伪造检测上报 — 红线

### 开发手感 (工具层, 已在质量门)

- 钾没有 remember-game: 结论写 intel + 本文件
- PowerShell 改 Luau 会加 BOM/截断: 用编辑器工具
- `do-end` 不新开 200 格, 必须 IIFE
- 副功能不要寄生在主循环里 (主开关一关全死)
- 注入即错乱: 先看自建 prefs / 配置 JSON, 再猜逻辑

---

## 200 寄存器 (主块/函数编不过)

**症状**: `loadstring` / 注入报 `Out of local registers ... limit 200`, 行号常落在某个 `local function` 名上, 并不一定是那一行写错。

**原理**: Luau **每个函数 proto** 最多约 200 个同时存活的 local。`local function` 的名字占**父函数**一格; 函数体另有自己的 200。`do-end` 可缩短存活期, 但闭包捕获会钉死寄存器。只把一堆 `local function` 塞进同一个 `buildXxx()` **不够**, 父函数照样爆 (重型钓鱼假称号)。

**正确收法 (按优先级)**:

1. 整份业务包进 `;(function() ... end)()` — 新 proto, 主块只留 `TheKing` 加载。骨架已这样写。
2. 相关状态收单表: `local Cbt = TheKing.Pack({ lock = nil })` , 方法写成 `function Cbt.pick()` 而不是再 `local function pick`。
3. 再爆就再拆一层 IIFE: `T = (function() ... return T end)()`。
4. 改完跑 `python tools/check_hub.py <hub>`: 任一函数峰值 ≥195 不准注入; ≥160 先收再加功能。

**反模式**: 主块平铺几十个 `local xxxOn` / `local function`; 为过线把所有函数塞进一个巨型 `buildUi()`。

来源: 地下城战利品者 (主块 IIFE + Cbt 表) / 重型钓鱼 (假称号二层闭包)。

---

## 绘制

- 用 `TheKing.Draw`, 见 `docs/draw-api.md`
- Drawing API 在 Potassium 不可靠
- 脚底圈用 `Draw.disc` (HandleAdornment Heartbeat/Render 贴 Adornee), 不要 10Hz 2D 折线追角色
- 热替换必须拆绘制层: lib 2.1.0 起 `Destroy(hotSwap)` 也会 `OnCleanup` + `Draw.destroy`

---

## 注入器

- 当前仓库常用 Potassium (`execute_script`), **没有** Real 的 `remember-game` / `check-script` / `remote-spy`。结论写 intel, 静态门用 `check_hub.py`。
- 非标准全局 (`gethui` / `identifyexecutor`) 必须探测 + pcall。
- `WaitForChild` 必须带 timeout, 否则游戏一更新脚本假死。

---

## 代码质量约定

- 循环: `StartLoop` / `BindToggle`, 禁止裸 `task.spawn while true`
- 危险发包: `Guard(..., { fuse = true })`
- 中文 UI 文案; Slider 的范围在 `Value` 子表
- 改 `lib/theking.luau` 必须记 `lib/devlog.md`, 并意识到所有游戏 hub 都会吃到这次升级
- 游戏 `GameName` 与 intel front matter `game:` 逐字一致

---

## 条目日志 (新教训往上加)

### [2026-09-05] 引擎自迭代 2.0: 跨游戏模式库

- 新增 `docs/patterns/<genre>.md` (同类型 ≥2 游戏的套路沉淀) + `templates/pattern-template.md` + `tools/recall.py`
- 全部游戏 intel.md front matter 补 `genre:` 字段 (召回匹配键)
- 启动协议加召回步骤; 发布流程加经验提升检查 (见 AGENTS.md「经验提升」)
- 首批收割: fishing (heavy-fishing+fisch), dungeon (dungeon-raiders+dungeon-quest-reborn)
- 分工铁律: intel=单游戏 / patterns=类型套路 / 本文件=引擎层坑, 别放错层

### [2026-09-04] lib 2.5.0 关闭所有通知

- 齿轮页开关, 拦截 Notify/Toast, 文件按 PlaceId 隔离
- Confirm/Popup 不关 (卸载确认还要弹)

### [2026-09-04] lib 2.4.0 传送挂号

- 钾有 `queue_on_teleport` / `clear_teleport_queue`; ArmTeleportReload 无 API 则跳过
- 换服会拆 DataModel, UI 库会话缓存带不过去

### [2026-09-04] lib 2.3.0 UI 库会话缓存

- `_G.RCWTK_UIKIT_CACHE` 热替换不重编 Rayfield/WindUI; 源文件指纹变了才 loadstring
- Gen2 Banner 半秒等待由包装层吃掉, 不改 vendor

### [2026-09-04] lib 2.2.0 普查现有 hub 回收基建

- OpenPrefs / Hold / Await / BindStepped / DeferTick / Upvalue
- 旧游戏脚本未强制迁移

### [2026-09-04] lib 2.1.0 引擎自迭代

- 静态门补寄存器扫描; 绘制进库; 热替换补跑清理 (旧行为会漏 Overlay)
- 上下文: 本文件 + cursor 规则 `rcwtk-engine.mdc`

### [2026-09-04] 主块 200 上限反复打断注入

- 大 hub 加功能时优先 Pack/IIFE, 不要先写完再救编译
