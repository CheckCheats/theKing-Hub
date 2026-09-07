# TheKing Loader — 开发手册 (DevLog)

> Loader 是引擎级组件: 授权链路 + 游戏注入路由。改动影响所有游戏的注入入口, 每次升级必须在此记录。
> 接手 AI: 读最后一条即可恢复 Loader 上下文。

---

## [2026-09-04 | v0.8.4 → v0.9.0] 自动注入 + 持久化

- 主界面当前游戏卡增加「自动注入 开/关」, `writefile` 落到 `theking-loader/prefs.txt` (失败再试根目录 `theking-loader-prefs.txt`)
- 下次跑 Loader: 授权过且清单命中当前游戏 → splash 结束后直注, 不弹主界面
- 未适配 / 拉脚本失败 → 回退 Loader 界面 + toast; 不再因「无脚本」强制退出

## [2026-09-04 | v0.8.3 → v0.8.4] 地下城战利品者进清单

`CN_GAME["dungeon-raiders"]` 显示「地下城战利品者（Dungeon Raiders）」。manifest 用 universeId + placeIds（大厅/地牢/挂机）。发布包内嵌 class-archive，注入不读本地文件。

## [2026-09-03 | v0.8.2 → v0.8.3] 按 universeId 识别当前游戏

狙击场大厅 PlaceId `126042865144779` 与清单里的对局 PlaceId `119259569670784` 不同。旧 Loader 只比 `game.PlaceId == e.placeId`，大厅里显示「暂未适配」；注入按钮同一套逻辑也会拒。

`manifestEntryForGame` / 清单「当前」标记改为同时匹配 placeId、universeId（`game.GameId`）、可选 `placeIds[]`。清单里本来就有 universeId，无需改 manifest 结构。

---

## [2026-09-03 | v0.8.1 → v0.8.2] 游戏清单中英双语

CN_GAME 显示名改为用户指定双语: 英雄随机生成 / 重型钓鱼 / 狙击竞技场 / 学乱 / 地牢任务重生 / 清洁世界。仅 Loader 展示层, 不改 hub GameName 与 intel `game:` 键。

---

## [2026-09-02 | v0.8.0 → v0.8.1] 显示名 + 注入后强制点亮游戏窗

### 用户需求
Loader 名称叫 theKing Hub; 注入后新窗口仍被藏掉不显示。

### 根因
1. Gitee 游戏包仍内嵌旧 lib: 建窗前全局 `Enabled=false`, 新窗建在已关层上。
2. 点亮「快照里没有的新层」不够 — 游戏 WindUI 常复用上次残留的同名 ScreenGui (已 Disabled)。
3. Loader 自毁若发生在点亮之前, 看起来像窗口被销毁。

### 改动
- 品牌字 splash/主面板: `theKing Hub` (注册表键仍 `TheKing Loader`, 避免和游戏 HUB 撞键)
- 注入后 `enableAllWindUi`: 点亮 gethui/PlayerGui 下所有 WindUI 层 (含 Name 含子级匹配)
- Destroy 之后再点亮一次; 0.4s 补一次防异步建窗
- 游戏包须跟发 (heavy-fishing v0.31.1 内嵌 lib 1.8.3)

### 遗留
- 其它游戏包若仍是旧 lib, 靠 Loader 点亮兜底; 有空逐个 `--game` 重发

---

## [2026-09-02 | v0.7.1 → v0.8.0] 主界面脱离 WindUI

### 用户需求
Loader 不用 WindUI, 找更适合加载器的成熟界面。

### 决策
不换 Fluent/Maclib 等 HUB 库 — 仍会和游戏窗口抢层。Loader 改成独立玻璃面板 + lib Headless。

### 改动
- theking `Headless=true`: 不加载 WindUI、不建窗
- 自定义面板: 当前游戏卡 + 注入按钮 + 滚动清单 + 授权芯片
- 卸载确认写明「只关 Loader, 游戏脚本继续」
- DEL 显隐 / END 卸载; 注入成功后 Destroy 只拆 Loader GUI

### 验证
- Potassium: `TheKing Loader@0.8.0` lib v1.8.3 Headless, 未加载 WindUI
- splash 后 `TheKingLoaderUI Enabled=true`; 游戏侧 WindUI 层仍独立存在

### 遗留
- 发布 `--loader --push` 用户未要求, 未推 Gitee


---

## [2026-09-02 | v0.7.0 → v0.7.1] 注入后自毁不再误关游戏 UI

### 根因
lib softHide 全局扫 WindUI ScreenGui; Loader Destroy 把已注入 HUB 窗口 Enabled=false。

### 改动
- 跟随 lib v1.8.2 (softHideOwnWindUi)
- ScriptVersion 0.7.1; 发布 --loader 内嵌新 lib

### 验证
- publish --loader --push → Gitee `1bc271f` (lib 1.8.2 内嵌)
- Potassium 实机: Loader+重型钓鱼共存 8 层全 Enabled → Destroy Loader 后剩 4 层 Enabled (游戏 HUB), REG 仅「重型钓鱼」

### 遗留
- 无

---

## [2026-09-02 | v0.6.5 → v0.7.0] 启动体验重做: 阶段进度 + 动画增强 + 清单预拉

### 用户需求
增强优化 Loader 加载; 动画做得更好。

### 改动 (playSplash + 启动管线)
- 去掉假进度 2.2s 线性条; `setProgress` 按阶段推进 (启动→校验白名单→确认授权→揭示), Quint 缓动
- 中心金色 `TheKing` 品牌字 + UIStroke 呼吸环 (Heartbeat); 揭示前淡出
- 四角改为 L 形 (横+竖), 0.05s 错峰 Back 弹出
- 彩虹条流光改 Heartbeat 连接, 退场 Disconnect; 满条轻微闪白
- 欢迎「中国人能飞」错峰 0.08s + UIScale 弹入; 未授权头像描边上滑文案
- 最短展示 MIN_SPLASH_SEC=1.35s; 统一 fadeTargets 退场
- 授权成功后后台/splash 内预拉 `loadManifest`; onFinish 优先用 `state.manifest` 缓存
- ScriptVersion 0.7.0

### 决策
- 保留黑金彩虹调性, 不恢复 emoji 皇冠 (v0.6.1 决策延续)
- 授权 L1-L5 语义不动

### 验证
- publish --loader --push → Gitee `54c1461` (obf ~84KB)
- Potassium 实机: `TheKing Loader@0.7.0` lib v1.8.1 启动成功, RUN true, 无 compile/runtime 炸

### 遗留
- 无

---

## [2026-08-31 | v0.6.3 → v0.6.4] 跟随 lib v1.7.3 WindUI 跨注入器修复

### 改动
- ScriptVersion 0.6.3→0.6.4; 头部注释补 v0.6.4
- 无 Loader 业务代码改动 — WindUI 加载走内嵌 lib, 重建即生效
- 同步推送 patched `windui-dist/main.lua` (图标缓存安全加载)

### 验证
- 待 publish 后 Potassium 实机跑 Loader

### 遗留
- 无

---

## [2026-08-31 | v0.6.0 → v0.6.1] 加载动画去除皇冠 logo

### 改动
- 删除 splash 金色圆形皇冠 logo (ring Frame + 👑 TextLabel + UIStroke): 创建块、下坠弹性动画、淡出列表三处引用全清
- 保留: 背景淡入 / 四角金色长条 / 彩虹渐变进度条 / 欢迎语 (中国人能飞) / 未授权头像
- 版本: ScriptVersion 0.6.0→0.6.1, 头部注释补 v0.6.1 说明

### 验证
- check-script: splash 完整段 0 error / 0 warning
- 实机重跑 (重型钓鱼, client 19428): 0.6.1 启动行 lib v1.7.0, 热替换 0.6.0 接管, 无报错
- 发布: dist/theking-loader.luau 混淆后 51KB, 推送 Gitee (410ec48..cc54239)

### 遗留
- 无

---

## [2026-08-31 | v0.5.0 → v0.6.0] UI 重构: 支持的游戏列表 + 授权到期时间 + 配套白名单工具升级

### 背景
1. Loader 原 UI 第一 Tab 是「授权」, 看不到 Hub 支持哪些游戏; 授权通过后也无到期时间反馈。
2. 白名单工具 whitelist.py v1.0 纯 CLI, 且 push 缺 fetch/rebase — 远端被网页端/其他路径更新后 push 被拒 `fetch first`。

### Loader 改动明细 (函数级定位)
| 位置 | 改动 |
|---|---|
| 头部注释 | 版本 0.5.0→0.6.0; 新增「UI (v0.6.0)」节说明 Tab 结构 |
| `ScriptVersion` | "0.5.0" → "0.6.0" |
| `state.untilStr` | 新增字段: 当前用户到期时间 (nil=永久), checkAuth 命中名单时捕获 |
| `checkAuth()` | 匹配到用户名时记录 `state.untilStr` (兼容旧格式纯字符串: 置 "") |
| `formatExpiry(untilStr)` | 新增: "永久" / "YYYY-MM-DD (剩余N天)" / "(已到期)" 格式化 |
| `buildUI()` | Tab 重排: 第一 Tab「支持的游戏」(gamepad-2) = gamesPara 列表 + gamePara 当前游戏 + 注入按钮; 第二 Tab「授权」(shield-check) = authPara + 验证按钮; 第三 Tab「设置」不变 |
| 启动段 | manifest 拉到后: gamesPara 显示全量游戏列表 (多行 `游戏名 v版本 [当前]`), 当前游戏标 [当前]; authPara 显示 `(已授权, 到期: 永久/日期)` |

### 决策记录
1. **第一 Tab 放「支持的游戏」**: 用户进 Loader 第一眼应看到能干嘛 (支持哪些游戏), 授权状态退居二线 (本来就是通过才进得来)。
2. **gamesPara 用多行文本列表而非逐个 Button**: manifest 可能几十款游戏, 多行 Paragraph 一个元素搞定, 不撑爆侧边栏; 当前游戏用 `[当前]` 后缀标注。
3. **formatExpiry 复用 todayUtc 字典序**: 剩余天数用 os.time 差值 (UTC 对齐工具端 datetime.utcnow()), 日期格式非法时原样返回兜底。
4. **纯 UI 改动不动授权链路**: checkAuth/injectScript 零变化, L1-L5 反绕过语义不变 — 回归风险最低。

### 配套: whitelist.py v1.0 → v2.0
| 位置 | 改动 |
|---|---|
| `git_push()` | **修复**: push 前先 `fetch origin` + `rebase origin/master` — 解决远端被网页端/其他机器更新后本地落后导致 push 被拒 `fetch first`; rebase 冲突时明确报错提示手动处理 |
| `run_gui()` | 新增: tkinter GUI 模式 (`--gui`) — Treeview 用户列表 (用户名/到期/状态) + 刷新/添加/修改到期/删除/一键推送按钮, 复用 read_whitelist/cmd_add/cmd_remove/cmd_extend/cmd_push 全部核心逻辑 (零重复) |
| `main()` | cmd 位置参数改可选; 新增 `--gui` 分支 |
| 文档头 | 用法补 `--gui`; 版本 v1.0→v2.0 |

### 验证结果
- check-script 静态门: Loader 完整源码 0 error / 0 warning (含 formatExpiry 边界用例: 永久/有效/已到期/坏数据)
- luac 5.1: lib v1.7.0 SYNTAX OK (Loader 有 `+=` 等 Luau 语法, luac 5.1 误报, 以 check-script 为准)
- 实机回归 [重型钓鱼, placeId 98502499119821, client 19428]:
  - Loader 0.6.0 启动行 `lib v1.7.0` ✓
  - 热替换旧 0.5.0 Loader 实例, 接管完成 ✓
  - 授权通过 → UI 构建 ✓ (用户确认显示正常)
  - 到期时间: WoSh1N1D1e 为永久授权, authPara 显示 "永久"
  - 支持的游戏列表: manifest 全量 (heroes-rng v1.0.0 / dungeon-quest-reborn v0.4.0 / gakuran v0.1.0 / heavy-fishing v0.29.2), 当前重型钓鱼标 [当前]
- 发布: dist/theking-loader.luau 41KB→51KB (新 UI + lib v1.7.0 内嵌), 混淆后推送 Gitee `1443e29..2d6ae7a`

### 遗留
- 到期时间剩余天数未实机核对 (当前用户永久授权, 无到期样例); 下次有到期用户时确认文案
- whitelist.py GUI 未实机交互测试 (tkinter 依赖桌面环境; 逻辑复用 CLI 已验证路径)
- Loader 实机里同时存在旧 0.5.0 的混淆残留实例 (热替换已接管, 无功能影响)
