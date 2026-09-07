# Heroes RNG TheKing HUB — 开发手册 (DevLog)

> 维护铁律: **每次开发会话收工前必须追加一条**, 写给下一个接手的 AI 和未来的自己。
> 与 changelog.md 分工: changelog 面向用户记"发布了什么"; 本文件面向开发者记"怎么做的、为什么、验证结果、遗留问题"。
> 接手 AI 使用法: 只读本文件最后一条 + intel.md 相关分区, 即可恢复全部上下文, 禁止凭空猜测前人意图。

---

## [2026-09-03 | v2.0.1 | lib v2.0.3] 黑金主题发布
跟随共享库主题打混淆包推 Gitee。玩法未改。

## 条目格式 (复制使用)

```
## [YYYY-MM-DD | 会话N | vX.Y.Z | lib v1.2.0] <一句话主题>

### 目标
### 改动明细 (函数级定位)
### 决策记录 (为什么这么改)
### 验证
### 遗留问题 / 下一步
```

---

## [2026-08-25 | 会话2 | v1.0.0 | lib v1.4.1] 持久化链路修复 + 热替换后内容区黑屏复现

### 目标
用户报告"设置保存不了"; 排查持久化全链路 (Save/Load/Register 时序)。

### 改动明细 (函数级定位)
| 文件 | 位置 | 改动 |
|---|---|---|
| lib/theking.luau | 配置持久化段 | 删除 task.defer(LoadConfig) — Load 时机移交业务侧 |
| games/heroes-rng/hub.luau | Flag 注册块 | Register 完成后追加 TheKing.LoadConfig() |
| games/heroes-rng/hub.luau | Register 块 | 加 _G.HeroRNG_Debug 排障句柄 (Save/Load/Config)

### 决策记录
- Load 原本 defer 在 lib 里 (0s), Register 在 hub 0.2s — Load 时无注册元素, 恢复必然为空。
- 排障发现 Config.Path 带 WindUI/ 前缀 (WindUI/TheKing_<...>/config/main.json),
  之前 isfile 查错路径误判"文件不存在"; 实际 Save 一直正常, 断点只在 Load 时序。
- 排障句柄 _G.HeroRNG_Debug 保留 (开发态), 发布构建时应移除。

### 验证
- Config:Set("attack", true) -> loop 启动 -> 重跑 (Destroy 存档 -> 新实例 Register -> Load)
  -> 状态 Paragraph 显示"无目标" (loop 自动恢复) 而非"未启用" — 闭环通过。
- 测试后 Config:Set("attack", false) + Save 复位。

### 遗留问题 / 下一步
- [ ] 热替换后内容区黑屏复现一次 (Tab 页面容器 Visible=false, 来源不明, 手动翻回后恢复; 怀疑 WindUI 切页异步竞态), 待稳定复现再修
- [ ] afkActivity loop 慢循环告警 (52ms, simulateClick 内 task.wait(0.05) 所致) 属设计内, 可给 StartLoop 加豁免标记消除告警噪声

## [2026-08-25 | 会话1 | v1.0.0 | lib v1.3.0] 引擎首飞: Neverlose 版全功能移植到 TheKing HUB (WindUI)

### 目标
以 RNG 项目 heroes-rng-nl.luau v0.0.6 (2134 行) 为蓝本, 验证 RCWTK 引擎全链路
(建档→移植→静态门→真机→热调试→归档), 并产出 Heroes RNG 的首个 WindUI 版脚本。

### 改动明细 (函数级定位)
| 文件 | 位置 | 改动 |
|---|---|---|
| lib/theking.luau | 入口配置 | 修 vararg 编译错误: `local passed = ...` chunk 顶层解构 (原 `pcall(function() return ... end)` 无法编译) |
| lib/theking.luau | CreateWindow | Icon 改玩家头像动态 URL; 移除 ToggleKey 参数 (与 Keybind 元素双绑定抵消) |
| lib/theking.luau | LOCAL_FALLBACKS | 改为 windui-main.lua (Real workspace 实际位置); 删 ../RNG 沙箱外路径 |
| lib/theking.luau | safeFolder | PlaceId 前缀 + 仅过滤非法字符 (原版把中文游戏名洗成纯下划线致配置目录冲突) |
| lib/theking.luau | TheKing.OnCleanup | 新增业务清理钩子 (Destroy 时逆序执行, 还原 hook/画质/遮罩) |
| games/heroes-rng/hub.luau | 全文件 (1376行) | 11 功能全量移植; 加载行多候选路径 (theking.luau @ Real workspace 根) |
| games/heroes-rng/hub.luau | findHubScreenGui | 重写: gethui()/WindUI/Window Folder 上溯 ScreenGui (原探测路径全空) |
| games/heroes-rng/hub.luau | 显示隐藏 Keybind | Window:Toggle() 改直切 ScreenGui.Enabled (蓝本已验证动画链会卡) |
| games/heroes-rng/hub.luau | 启动状态对齐块 | task.delay(1) 直调全部 toggle Callback(Settings 真值), 兜底归位 |
| games/heroes-rng/hub.luau | Flag 注册块 | Toggle 不带 Flag 创建, 0.2s 后手动 Config:Register (绕开创建期误触发) |
| templates/hub-skeleton.luau | — | 未动 (本次未回写新经验, 下次迭代考虑) |

### 决策记录
- **Flag 持久化改手动 Register**: 实测 WindUI v1.6.66 带 Flag 的 Toggle 会被配置系统在创建/加载期
  误触发 Callback(true) (Value=false 照误), 导致静默点击/防挂机开机自启。多轮实验定位:
  - Toggle:Set 行为怪异: false→true 触发 Callback 两次 (第二次异步), true→false 不触发;
    元素内部 Value 与视觉渲染可脱节, Set 同值 no-op。
  - 最小复现证明裸 Toggle(Value=false) 不误触发 → 误启源 = Flag 配置系统 → 移除 Flag + 延迟手动 Register。
- **显示/隐藏直切 Enabled**: 蓝本注释已警告 WindUI Toggle 动画链 (Tween+DepthOfField) 在 Real 会卡死;
  且 lib ToggleKey + Keybind 元素双绑定同帧切两次互相抵消 = "按了没反应"。
- **EmptyPage 隐藏**: Tab 只含 Section 时 WindUI 空页检测误判, "This tab is Empty" 覆盖层压住内容。
  只藏文本+同级图标, 不能藏容器 (EmptyPage 直接挂在 Tab 页面 Frame 下, 藏容器=黑整页, 踩过)。
- **图标**: crosshairs/speedometer 不在本地 lucide 缓存 (windui-cache/lucide.lua) → 换 zap/gauge。

### 验证
- 静态门: check-script 全文 0 error (14 个 Unknown require 为分析器无法解析游戏实例路径的固有误报, 注明跳过)。
- 真机: 启动零错误; 截图确认窗口/头像图标/五 Tab/Section 列表/中文界面; DEL 隐藏 (Enabled=false) 截图确认;
  热替换日志链完整 ("检测到旧实例→防滚动还原→接管完成"); 误启修复后 IdleSeconds=1020 + 状态"未启用"。
- 热调试: 连续 7 次 execute 重跑, 每次交接正常, OnCleanup 还原链生效。

### 遗留问题 / 下一步
- [ ] Config:Register 之后的 Load 恢复路径未深验 (重启游戏后 toggle 状态是否恢复待测)
- [ ] build.py 不识别 hub 的多候选加载块 (loadTheKing 函数), 发布态构建前需适配
- [ ] 保护屏幕的层级提升未实测 (需开启功能后目视确认窗口在遮罩之上)
- [ ] lib 的 CDN 在 Real 环境 HttpGet 失败 (nil), 长期依赖本地副本; 换注入器后需复测 CDN
- [ ] hub-skeleton.luau 未回写本次经验 (EmptyPage 隐藏/手动 Register/直切 Enabled), 下次迭代同步

---

## 踩坑黑名单 (跨会话累积, 只增不删)

> 格式: `[错误模式] → [后果] → [正确做法]` — 开工先扫一遍, 已知坑零二次。

- [`...` 包进 pcall 闭包捕获 loadstring 参数] → [编译直接报错, 脚本完全跑不了] → [chunk 顶层 `local passed = ...` 解构, vararg 不跨函数边界]
- [WindUI Toggle 带 Flag 创建] → [配置系统误触发 Callback(true), Value=false 的功能开机自启] → [创建不带 Flag, 0.2s 后手动 Config:Register]
- [WindUI Toggle:Set 当状态同步手段] → [Set 同值 no-op / false→true 触发两次且第二次异步, 状态永远对不齐] → [直调 elem.Callback(目标值) 定状态, Set 只当视觉刷新用]
- [隐藏 EmptyPage 时藏其容器 Frame] → [整个 Tab 页面 Visible=false 黑屏] → [只藏 TextLabel+同级 ImageLabel, EmptyPage 直接挂在页面容器下]
- [lib CreateWindow 传 ToggleKey + 设置页 Keybind 元素同键] → [同帧切两次互相抵消, 按键"无效"] → [只留 Keybind 元素, lib 不传 ToggleKey]
- [Window:Toggle() 做显示隐藏] → [动画链 (Tween+DepthOfField) 在 Real 卡死/崩溃风险] → [直切 ScreenGui.Enabled (蓝本验证)]
- [lucide 图标名凭记忆写 (crosshairs/speedometer)] → [图标静默不显示] → [先 grep windui-cache/lucide.lua 确认存在]
- [readfile 绝对路径 / 沙箱外相对路径] → [Real 直接拒绝 "Path outside workspace"] → [文件放 Real workspace 根, 相对路径引用; bash Copy-Item 同步]
- [假设 CDN 永远可达] → [Real 环境 HttpGet GitHub 失败, 脚本起不来] → [LOCAL_FALLBACKS 必须含实测存在的本地副本 (windui-main.lua)]
- [修 bug 改局部变量声明时丢 local (config)] → [全局泄漏 + lint 报错] → [每次改声明结构后重读改动段确认]
- [GameName 用中文名做 Folder] → [gsub 洗成纯下划线, 多游戏配置目录冲突] → [PlaceId 前缀 + 仅过滤文件系统非法字符]
- [task.spawn 裸循环做启动后同步] → [热替换后旧实例的裸循环杀不死, 幽灵回调继续跑] → [同步逻辑走 StartLoop 或 task.delay 有限次, 不留常驻裸循环]
- [Config.Load 放在元素 Register 之前 (lib defer 0s vs hub Register 0.2s)] → [Load 时无注册元素, 恢复永远为空, 设置全丢] → [Load 必须在 Register 之后由业务侧显式调用]
- [isfile 查配置文件用猜测路径 (少 WindUI/ 前缀)] → [误判"文件不存在", 排障方向全错] → [先读 Config.Path 字段拿真实路径再查]
