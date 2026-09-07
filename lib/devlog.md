# TheKing 运行时库 — 开发手册 (DevLog)

> lib/theking.luau 是共享层: 改一处影响所有游戏脚本。每次升级必须在此记录, 并按 AGENTS.md 游戏隔离节逐游戏回归。
> 接手 AI: 只读本文件最后一条 + hub.luau 头部注释, 即可恢复 lib 层上下文。

---

## [2026-09-06 | lib v2.5.1] LocalPlayer 载入界面就绪等待

### 症状
autoexec 在载入界面/换图过场执行时, `Players.LocalPlayer` 还是 nil → lib 顶部捕获 nil → authCheck 炸 `attempt to index nil with 'Name'`, 整个 hub 拒绝启动。此前 autoexec 都在局内触发所以从未暴露。

### 修改
`lib/theking.luau` 顶部 LocalPlayer 捕获改为: nil 时挂 `GetPropertyChangedSignal("LocalPlayer")` 等就绪 (属性非子实例, 不能 WaitForChild)。最多等 30 个信号周期。

### 回归
`python tools/check_hub.py lib/theking.luau` 通过 (主块峰值 109 不变)。局内 (LocalPlayer 已存在) 行为零变化, 不影响其他游戏。

---

### 目标
齿轮设置页加「关闭所有通知」: 开了之后本游戏不再弹 Notify/Toast (含警告), 按 PlaceId 落盘, 所有 TheKing HUB 游戏共用 lib 即生效.

### 改动
- `muteAllNotify` + `Configurations/TheKing_<placeId>/mute-notify.txt` (`1`/`0`)
- 包装 Rayfield `Window:Notify` / `:Toast`, WindUI `:Notify`, `TheKing.Notify`
- 打开时拆掉已有通知/Toast 层; CreateToggle 忽略创建时那一次 Callback
- 不改 vendor; 不静音 Confirm/Popup (那是要人点的对话框)

### 验证
`python tools/check_hub.py lib/theking.luau`

### 回归
各游戏热替换后点右上角齿轮应看到 TheKing HUB 分区. 开开关后功能提示/异常警告都不应再出窗; 重进同游戏应记住.

---

## [2026-09-04 | lib v2.4.0 → v2.4.1] 传送挂号补洞

- 写入 `rcwtk-reload/<placeId>.luau` 再挂号, 避免路径对不上
- `OnTeleport` 在 Started/RequestedFromServer 再 queue 一次
- Files + Url 兜底

钾实测 dungeon 工作区: `dungeon-raiders/hub.luau` 有, `games/dungeon-raiders/hub.luau` 无.

---

## [2026-09-04 | lib v2.3.0 → v2.4.0] 传送自动注入

- `TheKing.ArmTeleportReload({ Files | Source })`: 探测 `queue_on_teleport`/`queueonteleport`, 没有则 info 跳过
- 挂号前 `clear_teleport_queue` 去重; 热替换不取消; 真卸载 Disarm
- 钾 19952 已实测 API 存在, 未在库内主动试传送

验证: `python tools/check_hub.py lib/theking.luau`

---

## [2026-09-04 | lib v2.2.1 → v2.3.0] UI 库会话缓存 + 去掉 Banner 等待

### 目标
热替换/反复注入每次 `loadstring` Rayfield Gen2 (及 WindUI) 太慢; Gen2 建窗后还要 0.28+0.18s 拆 Banner 才 Show.

### 改动
- `_G.RCWTK_UIKIT_CACHE`: 按源指纹缓存已编译库表. 同会话源未变则跳过 `loadstring`; 换了 `rayfield-gen2.lua` / WindUI 副本指纹对不上才重编.
- `CreateWindow` 始终包在 `_TKOrigCreate` 上, 热替换不套娃.
- Banner ScreenGui 建出来立刻 Destroy; 吃掉 Gen2 那次延迟 `Show`. 非 `StartHidden` 立刻 `Show`. 不再铺 theKing 闪屏字.

### 决策
不改压缩 vendor (换行对不上). 强制重编: `_G.RCWTK_UIKIT_CACHE = nil` 再注入.

### 验证
`python tools/check_hub.py lib/theking.luau`. 游戏内: 冷启动控制台应有「已编译 Rayfield」; 热替换应有「复用已编译…跳过 loadstring」; 窗应马上出现, 无官方 Banner、无半秒黑屏字.

### 遗留
冷启动仍要编一次 UI 库 + 编 theking/hub. 图标 HTTP 仍同步, 未做.

### 回归
所有默认 Rayfield 的游戏热替换都会吃到; 卸载/DEL/StartHidden 路径依赖「吃掉延迟 Show」, 若窗不出或 DEL 要按两次再查这层包装.

---

## [2026-09-04 | lib v2.2.0 → v2.2.1] 启动 Banner 改 theKing 字

Rayfield Gen2 `CreateWindow` 会先铺全屏 `ImageLabel` Name=`Banner` (官方 Logo), 再等约 0.5s 拆掉后 Show 主窗。

- 加载 Gen2 成功后包装 `CreateWindow`: ChildAdded 藏掉 Banner, 同层加金色 GothamBold 字 `theKing`
- `welcomeToast=false` (能写 settings 就写)
- 不改压缩 vendor 源码 (换行对不上); 钾缓存仍走包装层

验证: 热替换 hub, 启动应先出字再出窗, 不出官方 Banner 图。

---

## [2026-09-04 | lib v2.1.1 → v2.2.0] 从现有游戏回收基建

扫了地下城/钓鱼/狙击场/清洁世界/英雄RNG/学兰的踩坑后, 把重复手写收进库 (未改各游戏 hub, 新代码走新 API):

- `OpenPrefs`: 钾上 Rayfield Flag 经常不落盘 (地下城 PREF、狙击无 Flag 开关)
- `Hold` + `BindStepped`: 移速被 50ms 打回; 钓鱼节奏不能走 StartLoop 50ms+抖动
- `Await`: Knit Promise 当同步返回会拿到 `_status`
- `DeferTick`: StartLoop 里同步 Invoke/抛物线拖死循环 (清洁世界)
- `Upvalue`: 钾 getupvalue 越界硬崩

StopAll 会拆掉 BindStepped/Hold. 旧 hub 的手写 Heartbeat 仍要自己 OnDisable 断.

## [2026-09-04 | lib v2.1.0 → v2.1.1] 热替换叠两个 HUB 窗

- 根因: Rayfield 每次 CreateWindow 新建 ScreenGui; 热替换只 Enabled=false; hideForeign 找子级名 `Rayfield`, Gen2 窗名是 GUID 对不上
- 热替换路径改为 Destroy 本实例 GUI; 建窗后按「TheKing HUB + 当前游戏名」拆遗留层, 不误伤其他游戏

## [2026-09-04 | lib v2.0.17 → v2.1.0] 自迭代: 寄存器门 + Draw + 记忆

### 目标
开发期反复 `limit 200` 编不过; 各游戏手写 Overlay; 无 Real 时上下文只靠游戏档、引擎坑记不住。

### 改动
- `TheKing.Draw`: ScreenGui 对象池 2D + HandleAdornment/Highlight/Billboard 3D; `onPaint`; 禁止 Drawing.new。API: `docs/draw-api.md`
- `TheKing.Pack`: 状态收单表, 少占 local
- `Destroy` 热替换也跑 OnCleanup + Draw.destroy (旧热替换会漏 Overlay); destroy 后本实例不再重建绘制层
- 静态门: `tools/check_hub.py` + `luau_reg_pressure.py` (函数峰值 ≥195 FAIL, ≥160 WARN)
- 记忆: `docs/engine-memory.md` + `.cursor/rules/rcwtk-engine.mdc`; 骨架 v1.1 默认 IIFE

### 决策
- 绘制不走开源 Drawing API: 地下城战利品者已证 Potassium 上不可靠
- 不把地下城现有 Overlay 迁到 Draw (战斗脚本已验证); 新功能必须走引擎

### 验证
- `python tools/check_hub.py --all`

### 遗留
- 地下城/钓鱼历史绘制仍是业务侧对象池, 大改再迁
- 无游戏内实测 Draw (需注入后看圈/字)

### 回归
- 热替换: 旧脚本 OnCleanup 现在会跑, 自建 GUI 应被拆掉; 若某游戏 OnCleanup 依赖「热替换不清理」会行为变化

---

## [2026-09-03 | lib v2.0.5 → v2.0.6] 不要抢游戏视角锁

Rayfield 默认 mouseOverride: 菜单开着就持续 MouseBehavior=Default。theking 藏窗又 LockCenter。重型钓鱼里 Shift 关不掉视角锁定。

现: `mouseOverride=false`; 开菜单保存并松开一次鼠标; 关掉还原, 不 LockCenter。

---

## [2026-09-03 | lib v2.0.3 全游戏发布]
- `publish.py --loader --all --push` 内嵌黑金主题到全部有 hub 的游戏混淆包

## [2026-09-03 | lib v2.0.2 → v2.0.3] Tab 字色改白

### 改动
- 主题 `TabColor` 从近黑改为纯白; 侧栏 Tab 标题与 Lucide 图标一起变白 (选中金底上也是白字)

---

## [2026-09-03 | lib v2.0.1 → v2.0.2] 黑金主题 + Logo 呼吸 + 切 Tab 淡入

### 改动
- CreateWindow 自定义黑金主题 (`LiveAnimation`, AccentGlow 0.78, 圆角 16/14/11), 不再锁 cobalt
- 窗口 Logo / 折叠胶囊 `UIScale` 1.00↔1.04, Sine 约 2.6s 往返; Destroy/热替换 Cancel
- 切 Tab: UIPageLayout 0.16s Quint + 内容 `GroupTransparency`/`UIScale` 淡入; 不包控件 Tween

### 决策
- 动效只挂窗口标和 Tab 页, 不跟库抢控件属性

### 遗留
- 开窗本身仍走 Rayfield Reveal; 胶囊展开未另写一套

---

## [2026-09-03 | lib v2.0.0 → v2.0.1] Logo / Tab 图标拆开

### 改动
- 品牌方圆标只用于窗口 `icon` / 折叠胶囊 `showIcon`
- 功能 Tab 的 `Icon` 走 Lucide 名 → latte-soft 48px png 缓存 (`lucide-cache/`)
- 控件行不再塞 Logo
- build.py 把 brand b64 打进单文件, 发布态也能出 Logo

---

## [2026-09-03 | lib v1.9.0 → v2.0.0] Rayfield 成为默认 UI + 品牌方圆标

### 改动
- 默认 `UiKit=rayfield`; 仅 `Headless` 或 `UiKit="windui"` 退出
- 窗口/Tab/开关/滑条/下拉/按钮/段落/键位/通知图标一律 `lib/assets/theking-mark.png` (getcustomasset; 无文件则解 b64)
- 不再传 lucide 名或 Rayfield 自带数字图标
- Section 句柄转发回 Tab, 兼容 `sec:Paragraph` 写法

### 回归
- 全游戏 hub 已跟版本; Loader 仍 Headless

---

## [2026-09-02 | lib v1.8.3 → v1.9.0] Rayfield Gen2 可选渲染

### 改动
- `config.UiKit="rayfield"` 加载 Gen2, 用 WindUI 形参封装 Tab 元素
- 默认仍 WindUI; Headless 不变
- 热替换 Destroy 也会软关本实例 Rayfield ScreenGui (GUID 名, 不能按 WindUI 扫)

### 回归
- 未开 UiKit 的游戏路径不应变化
- 重型钓鱼 v1.0.0 试点

---

## [2026-09-02 | lib v1.8.2 → v1.8.3] Headless 跳过 WindUI

### 改动
- `config.Headless=true` 不加载 WindUI、不 CreateWindow
- Notify 无 WindUI 时降级 print; NewTab 无 Window.Tab 返回空表
- 热替换 hideForeignWindUi 仅非 Headless 执行 (避免误关游戏 HUB)
- **时序**: `hideForeignWindUi` 必须在 `CreateWindow` **之后**, 再 `ensureOwnWindUiEnabled`。放在建窗前会把刚加载的 WindUI ScreenGui 关掉, 新窗口建在 Disabled 层上 (Loader 注入后「有日志没 UI」)

### 用途
Loader 自建界面, 与游戏脚本 WindUI 完全隔离。

---

## [2026-09-02 | lib v1.8.1 → v1.8.2] Destroy 不再误关共存脚本 UI

### 根因
`softHideWindUi` 按名扫 gethui/PlayerGui 全部 `WindUI` ScreenGui 并 `Enabled=false`。
WindUI 每个 loadstring 实例各建一层同名 ScreenGui — Loader 注入游戏后自毁会把游戏 HUB 的层一并关掉 → UI 不显示。

### 改动
- `softHideOwnWindUi`: 只关本实例 `WindUI.ScreenGui/NotificationGui/DropdownGui/TooltipGui`
- `hideForeignWindUi`: 热替换时只关「非本实例」遗留层
- `ensureOwnWindUiEnabled`: CreateWindow 后强制本层 Enabled
- 删除全局按名 softHide

### 回归
- 必测: Loader 注入任意游戏 → Loader 自毁后游戏窗口仍可见
- 同游戏热替换仍应只关旧层

---

## [2026-09-02 | lib v1.8.0 → v1.8.1] Potassium 卸载软隐藏

### 改动
- `softHideWindUi(detach)`: 默认只 `Enabled=false`, 显式 `detach=true` 才 Parent=nil
- `Destroy({ skipSave })`: 卸载跳过 SaveConfig
- `Confirm`: 确定回调统一 task.defer, 避免对话框栈内同步 teardown

---

### 背景
清洁世界 GetSkillUpgrades 单次 5s+, StartLoop 每轮告警且间隔叠在 yield 后; 各游戏重复 waitRemote; Guard fuse 误停全部循环; 热替换每次拉 users.enc。

### 改动
| 位置 | 改动 |
|---|---|
| StartLoop | 耗时从间隔扣除; 慢循环告警 10s 去抖; Backoff/wakeIf; opts.autoBackoff 默认关 |
| Guard | fuse=true/"loop" 停当前循环; fuse="all" 才 StopAll |
| FindRemote / WaitChild | 热路径不等待; 一次性等子级带 timeout |
| BindToggle | 开关样板 |
| authCheck 闸门 | 成功结果缓存 180s (失败不缓存) |
| StopLoop("antiafk") | 同步清 antiAfkActive |

### 决策
- autoBackoff 默认关: 慢查询后还要立刻买, 不能再强制歇一轮。
- 授权只缓存成功, 保持 fail-closed。

### 回归
- clean-the-world v0.5.3 已接 Backoff/FindRemote/BindToggle
- 其余游戏 StartLoop 签名兼容, 未改行为 (除 Guard fuse 语义; 仓库内无 fuse=true 调用)

---

## [2026-08-31 | lib v1.7.3 → v1.7.4] 补 authCdnUrls (注入 authCheck 调 nil)

### 背景
Loader 启动正常, 注入重型钓鱼报 `:14: attempt to call a nil value`。xpcall 栈定位 `authCheck`。
根因: `authCheck` 调用 `authCdnUrls(...)` 但函数从未定义 (v1.7.0 文档写了、代码漏了)。Loader 自带 `cdnUrls` 故不受影响。

### 改动
- 新增 `authCdnUrls(path)`: Gitee raw / raw=true / GitHub mirror, 与 Loader `cdnUrls` 对齐

### 验证
- Potassium traceback 已确认挂点; 补函数后重建发布再测注入

---

## [2026-08-31 | lib v1.7.2 → v1.7.3] Potassium WindUI 加载失败根治

### 背景
Loader/HUB 在 Potassium 上报 "WindUI 加载失败: CDN 不可达且无本地副本"。实机诊断:
1. `game:HttpGet` 大文件偶发静默返回空串 (不抛错) — 小文件 (users.enc/manifest) 正常
2. jsdelivr 旧 URL 指向仓库根 `main.lua` (157KB 示例), 不是 `dist/main.lua` 完整打包
3. **主因**: WindUI 启动 `loadstring(readfile("windui-cache/lucide.lua"))()` — 缺缓存文件时 readfile 返回 nil, `loadstring(nil)` 直接抛错, `or a.load'b'` 降级永远到不了

### 改动明细
| 位置 | 改动 |
|---|---|
| `CDN_SOURCES` | jsdelivr/raw 改 `dist/main.lua`; 保留 Gitee + releases |
| `WINDUI_MIN_BYTES` / `httpGetRetry` | 空串/截断重试 3 次 |
| `httpGet` | HttpGet 空串时尝试 request 兜底 |
| WindUI 加载段 | 本地缓存优先 → 网络 → writefile 缓存; `installWinduiReadfileGuard` 护栏 |
| `windui-dist/main.lua` | Icons 六路改 pcall 安全加载 (推 Gitee 后远端同步) |

### 验证
- Potassium: 护栏 + 本地缓存 → WindUI table + CreateWindow 成功
- 待: publish 后 Loader 0.6.4 全链路实机

### 遗留
- 官方上游 WindUI 仍有 loadstring(nil) 坑; lib 护栏永久兜底, 不依赖上游修

---

## [2026-08-31 | lib v1.6.0 → v1.7.0] 授权下沉: 脚本自带白名单自校验 (防直接注入)

### 背景
仓库游戏脚本公开可下载, 任何人 loadstring 直接运行完整 HUB (绕过 Loader/checkAuth)。白名单此前只活在 Loader 里, 游戏脚本内部零授权校验。

### 改动明细 (函数级定位)
| 位置 | 改动 |
|---|---|

| 头部注释 | 职责清单新增 13 授权闸门; 版本历史指向 lib/devlog.md |
| `AUTH_DEFAULTS` | 仓库默认参数 (RepoOwner/RepoName/RepoBranch/UsersPath/WhiteKey), 与 tools/whitelist.py + Loader CONFIG 一致 |
| `AUTH_MIRROR` | GitHub 灾备仓库 (与 Loader GITHUB_MIRROR 同源) |
| `authCdnUrls` / `authFetchFirst` | Gitee 主路 + GitHub 兜底, 拒收 HTML 错误页 (同 Loader fetchFirst) |
| `authJsonDecode` | HttpService:JSONDecode 主路 + loadstring 兜底 |
| `authDecrypt` | 与 whitelist.py encode_list / Loader decryptUsers 逐字节互逆 (四特征: 你看你妈妈呢/love/You Play Roblox/战败日 + WhiteKey) |
| `authTodayUtc` / `authIsExpired` | UTC 日期 + 字典序到期判断 (until 缺省=永久) |
| `authCheck` | 拉取->解密->解析->用户名匹配+到期; 失败一律未授权 (fail-closed) |
| `authDenyUi` | 纯 ScreenGui 拒绝面板 (WindUI 未加载, 不依赖窗口): 未授权/已到期两文案 + 知道了按钮 |
| 闸门执行 (顶层) | `GameName ~= "TheKing Loader" and config.Auth ~= false` 时建窗口前校验; 失败 showUI + error |
| `Services` | 新增 `HttpService` 局部引用 |

### 决策记录
1. **闸门放 WindUI 加载之前**: 未授权连 CDN 都不用拉, 且提示面板不依赖 WindUI。
2. **默认开启, 两个跳过口**: ① Loader (自带 L1-L5 授权链路, 避免双重校验 + 不阻塞其 splash 流程); ② `config.Auth = false` (纯开发/测试显式豁免, 头部注释已文档化)。
3. **fail-closed 设计**: 网络/解密/解析失败一律未授权 — 与 Loader L2 "失败即拒" 一致, 绝无默认放行。
4. **诚实边界**: 客户端校验可被逆向删除, 防君子不防高手; 彻底防需服务端签名体系 (后续工作)。
5. **复用 Loader 同款常量与算法**: 单点维护 (tools/whitelist.py 是唯一生成源), 改 WhiteKey 必须同步三处 (whitelist.py/Loader CONFIG/lib AUTH_DEFAULTS)。

### 验证结果
- luac 5.1 语法门: lib/theking.luau SYNTAX OK (lib 无 Luau 特有 continue, 5.1 可检)
- check-script 静态门: 见会话记录 (auth 片段 0 error)
- 待实机: ① 未授权账号跑 hub → 拒绝面板 + error; ② 已授权账号正常建窗口; ③ 到期账号显示"用户已至期限，请续约公司"
- 待回归: 4 个游戏全部重建 + 逐个实测 (lib 升级必须回归, AGENTS.md 游戏隔离节)

### 回归遗留
- heroes-rng / gakuran / dungeon-quest-reborn: 需用各自 hub 重建 dist 并实测启动行 (lib v1.7.0)
- Loader: 本身不重建 (GameName 跳过闸门), 但其 dist/theking-loader.luau 内嵌的是旧 lib, 无影响 (Loader 不走闸门)

---

### 目标
吸收 4 个游戏脚本 (dungeon-quest-reborn / gakuran / heavy-fishing / heroes-rng) 重复手写的三类模式进引擎: 裸 FireServer 调用、orig 函数保存/恢复链、AntiAfk。

### 改动明细 (函数级定位)
| 位置 | 改动 |
|---|---|
| `TheKing.Fire(remote, ...)` | 新增: FireServer pcall 封装, 类型预检 + 失败 warn 留痕, 返回 boolean |
| `TheKing.Invoke(remote, ...)` | 新增: InvokeServer pcall 封装, 返回 `ok, result` |
| `TheKing.Swap(obj, key, newValue)` | 新增: 登记式字段替换, 保存 original 入 swapStack, 返回 original |
| `TheKing.EnableAntiAfk()` / `DisableAntiAfk()` / `AntiAfkActive()` | 新增: VirtualUser 假输入 (240s ±15% 抖动), 走 StartLoop("antiafk") |
| `TheKing.Destroy()` | swapStack 逆序还原段, 位于 StopAll 之后、cleanupFns 之前 |
| 头部注释 | 职责清单 10-12 三条新增; 版本历史指向改 lib/devlog.md |

### 决策记录 (为什么这么改)
1. **Swap 用 rawget/rawset 而非普通索引**: hook 检测常挂 `__index` 元表, rawget 拿真实底层数据; 还原走 rawset 保证精确复位。字段不存在时拒挂并 warn (返回 nil), 杜绝把 nil 存进 swapStack 后还原写入假字段。
2. **Destroy 还原段位置**: 放 StopAll 之后 — 保证没有循环还在用被替换的函数; 放 cleanupFns 之前 — 业务清理钩子里还能调用已还原的原始函数。
3. **AntiAfk 复用 StartLoop("antiafk")**: 不另造机制, StopAll/Destroy/热替换全部自动覆盖, 零额外清理代码。循环名 `antiafk` 是保留名, 业务循环禁用此名。
4. **Fire/Invoke 只做 pcall+留痕, 不做熔断**: 熔断是业务策略 (Guard.fuse), 发包层只保证"不炸循环 + 失败可见"。
5. **纯新增不改旧接口**: 已有游戏不调用新 API 则行为零变化 — 这是回归风险最低的升级路径。

### 验证结果
- check-script 静态门: 0 error / 0 warning (Fire/Invoke/Swap/AntiAfk/Destroy 还原段全量过检)
- 动态回归 [Dungeon Quest Reborn, placeId 8577675758, client gen26]:
  - v1.4.1→v1.5.0 热替换交接 ✓ (启动行 "lib v1.5.0")
  - 窗口/Tab/循环/配置全链路无启动错误 ✓
  - Swap 冒烟: 挂 wrapper 后调用走 wrapper (`wrapped:a`), Destroy 后自动还原 (`orig:b`), 计数无误 ✓
  - Fire/Invoke/AntiAfk 类型与幂等检查 ✓ (AntiAfk 仅验证 API 存在性, 假输入效果需挂机场景实测)
- Real workspace 根的 theking.luau 副本已同步 v1.5.0 (该副本是 hub 开发态主路加载源, **漏同步会导致改动不生效** — 这是本次实际踩到的坑)

### 回归遗留
- gakuran / heavy-fishing / heroes-rng 三游戏未回归 (客户端不在线): 纯新增接口, 无旧调用点, 理论零影响; 下次进对应游戏时确认启动行 lib 版本即可
- dungeon hub 的 combat 循环单次耗时 2~13 秒 (业务侧问题, 非 lib): 慢循环告警触发, 待 dungeon 侧降频/拆分, 见该游戏 devlog

### 迁移提示 (下次迭代各游戏可选)
- heroes-rng: 手写 `Network.FireServer/InvokeServer` 封装 + `enableAntiAfk/disableAntiAfk` 可迁移至 `TheKing.Fire/Invoke` + `TheKing.EnableAntiAfk`, 预计 -80 行
- heavy-fishing: 散装 `pcall(function() Events.X:FireServer(...) end)` 模式可替换为 `TheKing.Fire`

### 遗留问题
- TheKing.Player 快捷取 (getChar/getHrp/getHumanoid 四游戏重复) 与统计面板帮助器: v1.5.0 未纳入, 视需求排 v1.6.0
- hookfunction 类 L2 hook (gakuran 场景) 无通用还原 API, 仍走业务侧 OnCleanup 手工登记 — Swap 只覆盖表字段替换场景
