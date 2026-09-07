# WindUI API 参考 (RCWTK 标准文档)

> 来源: 官方文档 https://footagesus.github.io/treehub-web/docs/windui (2026-08 抓取) + 本地副本 `windui-dist/main.lua` v1.6.66。
> **所有参数表均来自官方文档, 未经验证的新参数不要凭记忆使用 — 查本文件或重抓官方页。**
> 库仍处 Beta, 升级 WINDUI_VERSION 前先跑一遍骨架脚本验证。

## 已验证矩阵 (真机实测记录, 与文档来源严格区分)

> 铁律: 下表只登记**在真机跑通过**的 API; 文档抄来的默认「未验证」。首飞后更新本表。

| API | 状态 | 验证方式 | 日期 |
|---|---|---|---|
| CreateWindow (Title/Icon URL/Author/Theme/Size/Folder, **不传 ToggleKey**) | ✅ 实测 | Heroes RNG 首飞, 截图确认 | 2026-08-25 |
| Window:Tab / Tab:Section / Section:Toggle/Slider/Button/Keybind/Paragraph | ✅ 实测 | 全部渲染正常 | 2026-08-25 |
| Paragraph:SetTitle/SetDesc (经 TheKing.UpdateStatus 差分) | ✅ 实测 | 状态文本动态刷新 | 2026-08-25 |
| WindUI:Notify / Window:Dialog | ✅ 实测 | 通知与卸载确认弹窗 | 2026-08-25 |
| ConfigManager:CreateConfig / Register | ✅ 实测 | 创建+手动注册成功 | 2026-08-25 |
| ConfigManager:Load 恢复路径 | ✅ 实测 (带时序前提) | **Load 必须在 Register 之后调用**, 否则恢复为空; 顺序正确时热替换自动恢复验证通过 | 2026-08-25 |
| Config.Path 字段 | ✅ 实测 | 真实存储路径带 WindUI/ 前缀, isfile 排障先读此字段 | 2026-08-25 |
| Config:Set(flag, value) | ✅ 实测 | 直接驱动元素 Callback, 可用于程序化改状态 | 2026-08-25 |
| Toggle:Set | ⚠️ 行为怪异 | false→true 触发 Callback×2 (第二次异步); true→false 不触发; 同值 no-op — **不要当状态同步手段** | 2026-08-25 |
| Window:Toggle | ❌ Real 环境禁用 | 动画链 (Tween+DepthOfField) 卡死风险, 蓝本+首飞双确认 → 直切 ScreenGui.Enabled | 2026-08-25 |
| Toggle 带 Flag 创建 | ❌ 禁用 | 配置系统误触发 Callback(true), Value=false 照误 → 手动 Register 替代 | 2026-08-25 |
| Tab 只含 Section 时的 EmptyPage | ⚠️ 覆盖 bug | 空页检测不计 Section, 覆盖层压内容 → 启动后隐藏文本+同级图标 | 2026-08-25 |
| 图标: zap/gauge/crown/shield-check/map-pin/settings/square/trash-2/sword/diamond/wrench/flag | ✅ 实测 | 本地 lucide 缓存有 | 2026-08-25 |
| 图标: crosshairs/speedometer | ❌ 缓存无 | 静默不显示, 用前 grep windui-cache/lucide.lua | 2026-08-25 |
| Icon 传玩家头像 URL | ✅ 实测 | roblox.com headshot-thumbnail URL 正常渲染 | 2026-08-25 |
| SetLanguage("zh-cn") | ✅ 无报错 | pcall 通过, 库内文本效果未逐项确认 | 2026-08-25 |

## 版本升级 SOP (WINDUI_VERSION 变更必走)

1. **查差异**: 读目标版本 GitHub release notes + 重抓官方文档 diff 参数表。
2. **本地试跑**: 改 `lib/theking.luau` 的 WINDUI_VERSION → 用 hub-skeleton.luau 真机跑通全 Tab (窗口/元素/Keybind/Dialog/通知)。
3. **回归档案**: 已有游戏的 hub.luau 逐个重跑一遍, 重点验证配置持久化 (ConfigManager 行为可能变)。
4. **更新矩阵**: 升级后把已验证矩阵清空重验, 通过的重新登记。
5. **归档**: devlog 记录升级原因与验证结果; windui-api.md 头部版本注释同步。

## 加载 (RCWTK 规范: 锁定版本)

```luau
-- 推荐: release 版本锁定 (theking.luau 已内置, 一般不直接用)
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/download/1.6.66/main.lua"))()

-- 备选: latest (不稳定, 不推荐)
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- RCWTK 兜底: readfile("windui-dist/main.lua") 本地副本
```

## WindUI 顶层函数

| 方法 | 说明 |
|---|---|
| `:CreateWindow(cfg)` | 创建主窗口 |
| `:Notify(cfg)` | 系统通知 |
| `:Popup(cfg)` | 弹出窗口 |
| `:SetFont(id)` | 全局字体 (`rbxassetid://`) |
| `:SetNotificationLower(bool)` | 通知下移避开手机跳跃键 (**TheKing 默认开启**) |
| `:GetCurrentTheme()` / `:GetThemes()` / `:AddTheme(t)` | 主题管理 |
| `:Gradient(colors, cfg)` | 渐变工具 |
| `:SetParent(inst)` / `:SetLanguage(code)` | 挂载/本地化 |

## Window

```luau
local Window = WindUI:CreateWindow({
    Title = "TheKing HUB",     -- 必填
    Icon = "crown",            -- lucide 图标名 / "rbxassetid://" / URL
    Author = "游戏名",          -- ★ 标题下方小字 = TheKing 的游戏名标注位
    Theme = "Dark",
    ToggleKey = Enum.KeyCode.K,
    Size = UDim2.fromOffset(580, 420),
})
```

常用参数: `Folder`(配置目录) `MinSize`/`MaxSize` `Position` `Transparent` `Resizable`
`SideBarWidth` `HideSearchBar` `Background`(raw URL 或 rbxassetid) `ShadowTransparency` `Acrylic` `AutoScale` `KeySystem`

常用方法:

| 方法 | 说明 |
|---|---|
| `:Tab(cfg)` / `:Section(cfg)` | 新建 Tab |
| `:SetTitle(t)` / `:SetAuthor(a)` / `:SetIcon(i)` | 动态改标题/小字 |
| `:Dialog(cfg)` | 对话框 |
| `:Toggle()` / `:Open()` / `:Close()` / `:Destroy()` | 开关销毁 |
| `:OnOpen(fn)` / `:OnClose(fn)` / `:OnDestroy(fn)` | 生命周期回调 |
| `:SelectTab(tab)` | 切换 Tab |

## Tab

```luau
local Tab = Window:Tab({ Title = "主功能", Icon = "zap" })
```

参数: `Title` `Desc?` `Icon?` `IconColor?` `Locked?` `ShowTabTitle?` `Border?`
方法: `:Select()` `:SetTitle(t)` `:SetDesc(d)` `:Lock()` `:Unlock()`
元素创建直接挂 Tab 上: `Tab:Toggle{...}` `Tab:Button{...}` 等, 见下。

## 元素速查 (统一 table 配置风格)

### Toggle
```luau
Tab:Toggle({ Title, Desc?, Icon?, Value=false, Type="Toggle"|"Checkbox", Locked?, Flag?, Callback=function(state) end })
```
方法: `:Set(bool)` `:Toggle()` `:Lock()` `:Unlock()` `:Destroy()`

### Button
```luau
Tab:Button({ Title, Desc?, Icon?, IconAlign="Right"|"Left", Color=Color3?, Justify="Between"|"Center", Locked?, LockedTitle?, Callback })
```
方法: `:SetTitle` `:SetDesc` `:Lock` `:Unlock` `:Highlight` `:Destroy`

### Slider
```luau
Tab:Slider({ Title, Value={ Min=0, Max=100, Default=50 }, Step=1, Icons={From,to}, Callback=function(value) end })
```
注意: 范围在 `Value` 子表里; 浮点滑条设 `Step=0.1`。
方法: `:Set(n)` `:SetMin(n)` `:SetMax(n)`

### Dropdown
```luau
Tab:Dropdown({ Title, Values={"A","B"}, Value="A", Multi=false, AllowNone=false, SearchBarEnabled=true, Callback=function(sel) end })
```
⚠️ Values 不允许重复项。Multi 时 Callback 收到 table。
方法: `:Select(v)`

### Input
```luau
Tab:Input({ Title, Type="Default"|"Textarea", Placeholder?, Value?, Icon?, Callback=function(text) end })
```
方法: `:Set(text)`

### Keybind
```luau
Tab:Keybind({ Title, Value="K", Callback=function(key) end })
```
方法: `:Set(Enum.KeyCode)`
TheKing 规范: 显示/隐藏界面固定放设置页。

### Colorpicker
```luau
Tab:Colorpicker({ Title, Default=Color3.fromRGB(255,255,255), Callback=function(color) end })
```
方法: `:Set(color, transparency?)`

### Paragraph (状态显示)
```luau
local p = Tab:Paragraph({ Title, Desc, Image?, ImageSize?, Thumbnail?, Buttons={{Title,Icon?,Callback}} })
p:SetTitle("...") p:SetDesc("...")  -- 动态更新状态文本用这个
```

## Dialog

```luau
Window:Dialog({
    Title, Content, Icon?,
    Buttons = { { Title, Variant="Primary"|"Secondary", Callback } },
})
```
返回对象: `:Show()` `:Close()`

## Notification

```luau
WindUI:Notify({ Title, Content, Icon?, Duration=3 })
```

## 图标

默认 Lucide 图标集, 直接写名字 (`"zap"` `"crown"` `"settings"`)。
其他前缀: `sfsymbols:` `craft:` `geist:` `gravity:` `solar:`, 以及 `lucide:名字` 显式前缀。
也接受 `rbxassetid://` 与图片 URL。

## 中文适配 (RCWTK 规范)

1. **自产 UI 文本直接写中文字符串** — Title/Desc/通知内容硬编码中文, 单语产品不走翻译系统。
2. **库内置文本**: `WindUI:SetLanguage("zh-cn")` 尝试切换 (theking.luau 已内置, pcall 包裹, 不支持时静默跳过)。
3. **loc: 翻译机制不要用** — `WindUI:Localization{Translations}` 是多语言产品用的, TheKing HUB 只出中文, 加翻译表是负担。
4. **字体**: 默认字体下 Roblox 自动 fallback 渲染中文; 若必须 `WindUI:SetFont(id)`, 选含中文字形的字体资产, 否则界面变方块。

## RCWTK 使用规范

1. **永远通过 `lib/theking.luau` 使用 WindUI**, 不直接 CreateWindow —— 统一标题 "TheKing HUB" + Author 小字游戏名是硬规范。
2. 循环逻辑必须走 `TheKing.StartLoop/StopLoop`, 禁止裸 `task.spawn while true do` —— 否则 StopAll/Destroy 管不住。
3. 动态状态文本用 `Paragraph:SetDesc`, 不要反复创建元素。
