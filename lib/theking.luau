--[[
    TheKing Runtime Library [2.5.0]
    RCWTK 引擎运行时层 | UI: Rayfield Gen2 (默认) / WindUI (config.UiKit="windui")

    职责 (所有 TheKing HUB 脚本共用, 只改这一处):
      1. WindUI 加载: 本地缓存优先 + Gitee 主源 + CDN 兜底, 空响应重试, 成功后 writefile 缓存
      2. 热调试: 同游戏旧实例 -> 自毁交接; 不同游戏实例共存互不影响 (游戏隔离)
      3. 标准窗口: Title = "TheKing HUB", Author = 游戏名(小字标注), 配置目录按游戏隔离
      4. 循环状态机: StartLoop/StopLoop/StopAll + 最小间隔保护 + 慢循环告警去抖
         + 人类化抖动 + 耗时从间隔扣除 + 超预算自动退避 + Backoff/wakeIf
      5. 连接登记: AddConnection, Destroy 时统一断连
      6. 性能: UpdateStatus 文本差分刷新, 杜绝每帧 SetText
      7. 配置持久化: Flag 元素状态自动存取, reload 后功能自动恢复
      8. 危险操作防护: Guard 安全封装; fuse=true/"loop" 停当前循环, fuse="all" 全停
      9. 业务清理钩子: OnCleanup(fn), Destroy 时执行业务侧恢复逻辑 (还原 hook/画质等)
     10. 统一发包: Fire/Invoke pcall 封装, Invoke 失败留痕 (L2 SOP 要求)
     11. 登记式替换: Swap 表字段替换, Destroy 自动逆序还原, 防叠加残留
     12. 防挂机: EnableAntiAfk 假输入续命 (L2 手段, Destroy 自动停)
     13. 2D/3D 绘制: TheKing.Draw (ScreenGui 池化 + HandleAdornment, 不用 Drawing.new)
     14. 跨游戏基建: OpenPrefs / Hold / Await / BindStepped / DeferTick / Upvalue
     15. 授权闸门: 建窗口前自校验 users.enc (拉取->解密->用户名+到期), 未授权/到期拒绝建 UI
         防直接注入 (Loader 白名单只是双保险); Loader 自带授权链路故跳过 (防双重校验)
         v1.7.1: 到期判断改用 HTTP 响应头服务端 Date; 本地与服务端偏差 >2 天
         判为系统时间篡改 (reason=clock) 拒绝 — 防改本地时间绕过到期
         v1.7.2: 跨注入器兼容 — WindUI 副本托管 Gitee 主源; 无 Date 头时降级本地时间
         v1.7.3: WindUI 图标缓存 loadstring(nil) 防护 + CDN 路径修正 (dist/main.lua)
         + HttpGet 空串重试 + 成功后本地缓存; 适配 Potassium 等注入器
         v1.7.4: 补回缺失的 authCdnUrls (authCheck 调 nil 致注入 :14 attempt to call a nil value)
         v1.8.0: 循环退避/告警去抖; FindRemote/WaitChild; BindToggle; Guard 熔断粒度; 授权热替换短缓存
         v1.8.2: softHideWindUi 只关本实例 WindUI.*Gui — 禁止按名全局扫 ScreenGui;
              修 Loader 注入后自毁误关游戏 HUB 窗口导致 UI 不显示
         v1.8.3: Headless=true 跳过 WindUI 加载与建窗 (Loader 自建界面, 与游戏 HUB 完全隔离)
              热替换 hideForeignWindUi 挪到 CreateWindow 之后, 避免新窗建在已被关掉的层上
         v1.9.0: UiKit="rayfield" 走 Rayfield Gen2; Tab 元素保持 WindUI 形参 (Title/Callback/Flag)
              其它游戏默认仍 WindUI, 互不影响
         v2.0.0: 默认 UI 改为 Rayfield Gen2; Logo 用品牌方圆标
         v2.0.1: 品牌标只作窗口 Logo; 功能 Tab 走 Lucide 图标库 (48px 缓存)
         v2.0.2: 黑金自定义主题 + Logo 呼吸 + 切 Tab 淡入 (不改控件层)
         v2.0.3: Tab 标题/图标色改为白色
         v2.0.4: 窗口隐藏/最小化后把鼠标交还游戏 (Rayfield mouseOverride 不会自行恢复)
         v2.0.5: Rayfield Toggle/Button 去掉点击 Size 缓动 (Potassium 改控件 Size 会原生崩)
         v2.0.17: Destroy({ purgeUi=true }) 拆掉本实例 Rayfield/WindUI 层, 卸载不再只藏窗
         v2.0.16: 首次注入且存档为隐藏时, 不要对未 Show 过的窗调 Hide (会缩成顶栏药丸)
         v2.0.15: 显隐按顶栏 Visible 判断, 避免 hidden 标记和画面不同步导致 DEL 要按两次
         v2.0.14: 藏窗不再关 ScreenGui.Enabled (关掉后设置页 DEL 听不到, 再也打不开)
         v2.0.13: StartHidden 建窗即可藏; SetWindowHidden 同时关 ScreenGui.Enabled
         v2.0.12: SetWindowPersist / IsWindowHidden / SetWindowHidden — 菜单显隐可由游戏 hub 自建存档
         v2.0.11: BindToggle 统一状态落盘钩子 SetTogglePersist + RestoreToggle (彻底绕开失效的 Rayfield 配置)
        v2.0.10: Toggle/单选Dropdown/Keybind改绑 callback 变更后显式 Save (Rayfield autoSave 不触发兜底)
        v2.0.9: SaveConfig 前分段预建 Rayfield 配置目录 (Potassium makefolder 多级失败致 Save 静默失效)
        v2.0.8: 配置目录改纯 PlaceId (GameName 中文改名不再丢配置)
        v2.0.7: Tab 暴露 RawPage() (返回 Rayfield tabPage 容器, 支持 hub 内嵌自绘面板)
        v2.0.6: 关掉 Rayfield 持续抢 MouseBehavior; 藏窗不再强行 LockCenter (Shift 视角锁可开关)
         v2.5.0: 齿轮设置「关闭所有通知」— 拦截 Notify/Toast, 按 PlaceId 单独落盘
         v2.4.1: 传送挂号改为落地快照+OnTeleport补挂; 无 API 仍跳过
         v2.4.0: ArmTeleportReload — 探测 queue_on_teleport, 换服自动重跑; 无 API 则跳过
         v2.3.0: UI 库按源指纹会话缓存, 热替换不重编; 跳过 Gen2 Banner 半秒
         v2.2.1: Rayfield 启动 Banner 改成 theKing 字, 去掉官方 Logo 图
         v2.2.0: OpenPrefs / Hold / Await / BindStepped / DeferTick / Upvalue — 从各游戏 hub 回收的重复基建
         v2.1.1: 热替换拆掉旧 Rayfield 窗 (只藏会叠两层); 遗留窗按 TheKing HUB 标题认 Gen2 GUID
         v2.1.0: TheKing.Draw 2D/3D 绘制; Pack 收状态少占寄存器; Destroy 热替换也跑清理/拆绘制层

    用法:
        local TheKing = loadstring(readfile("lib/theking.luau"))({
            GameName = "Sol's RNG",        -- 窗口标题下方小字标注 + 隔离键
            ScriptVersion = "1.0.0",
            WindowSize = UDim2.fromOffset(580, 420), -- 可选
            -- Auth = false  -- 可选: 显式跳过授权闸门 (仅纯开发/测试场景; 默认开启)
        })
        -- 显示/隐藏快捷键默认 DEL, 卸载默认 END (设置页可重绑)

    lib 版本历史见 lib/devlog.md; 升级本文件必须回归所有已有游戏 (AGENTS.md 游戏隔离节)
]]

local LIB_VERSION = "2.5.0"

-- ==================== 配置 ====================
local WINDUI_VERSION = "1.6.66" -- 锁定版本: 升级前先本地验证, 改这里一处生效
-- WindUI 加载链 (多源降级, 适配所有注入器):
--   0) 本地 readfile 缓存 (上次成功拉取的 windui-main.lua / 项目副本) — 优先, 零网络
--   1) Gitee 主源 (国内直连最稳, 与 users.enc 同源; RCWTK 已打图标缓存安全补丁)
--   2) jsdelivr / GitHub raw dist/main.lua (官方打包路径, 非仓库根 main.lua 示例)
--   3) GitHub releases
-- 注意: 部分注入器 HttpGet 失败时静默返回空串 (不抛错); 大文件偶发失败 → 空串重试。
local WINDUI_GITEE_URL = string.format("https://gitee.com/%s/%s/raw/master/windui-dist/main.lua",
    "CheckCheat", "the-king-hub")
local CDN_SOURCES = {
    WINDUI_GITEE_URL,
    ("https://cdn.jsdelivr.net/gh/Footagesus/WindUI@%s/dist/main.lua"):format(WINDUI_VERSION),
    ("https://raw.githubusercontent.com/Footagesus/WindUI/%s/dist/main.lua"):format(WINDUI_VERSION),
    ("https://github.com/Footagesus/WindUI/releases/download/%s/main.lua"):format(WINDUI_VERSION),
}
local LOCAL_FALLBACKS = {
    "windui-main.lua",        -- 注入器 workspace 缓存 (lib 成功拉取后 writefile)
    "windui-dist/main.lua",   -- RCWTK 项目结构的本地副本
}
local WINDUI_CACHE_PATH = "windui-main.lua"
local WINDUI_MIN_BYTES = 500000 -- 完整打包约 1.3MB; 小于此视为错误页/截断
local MIN_LOOP_INTERVAL = 0.05   -- 循环间隔下限 50ms (20Hz): 再快的需求该用事件连接而不是轮询
local SLOW_LOOP_THRESHOLD = 0.033 -- 单次执行超 33ms (~1帧@30fps) 即告警
local SLOW_WARN_GAP = 10          -- 同名循环慢循环告警最短间隔 (秒)
local AUTH_CACHE_TTL = 180        -- 授权成功热替换缓存 (秒), 失败不缓存

-- ==================== 日志 (统一前缀, 排障过滤用) ====================
local LOG = "[RCWTK]"
local function logInfo(msg) print(LOG .. " " .. msg) end
local function logWarn(msg) warn(LOG .. " " .. msg) end

-- ==================== 入口配置 ====================
-- 来源优先级: loadstring 参数 (开发态) -> _G.RCWTK_LIB_CONFIG (tools/build.py 单文件构建注入)
-- 注意: ... 只能在 chunk 顶层解构 (vararg 不跨函数边界), 不能包进 pcall 闭包
local passed = ...
if type(passed) ~= "table" then
    passed = rawget(_G, "RCWTK_LIB_CONFIG")
end
local config = (type(passed) == "table") and passed or {}
pcall(function() rawset(_G, "RCWTK_LIB_CONFIG", nil) end) -- 用完即清, 减少全局痕迹
local GameName = tostring(config.GameName or "Unknown Game")
local ScriptVersion = tostring(config.ScriptVersion or "0.0.0")
local ToggleKey = config.ToggleKey or Enum.KeyCode.Delete -- 默认 DEL 显示/隐藏窗口
local startHidden = config.StartHidden == true
local headless = config.Headless == true -- Loader 等自建 UI: 不加载 WindUI, 不建 HUB 窗
local uiKit = string.lower(tostring(config.UiKit or config.UI or "rayfield"))
local useRayfield = (not headless) and (uiKit ~= "windui")

-- ==================== Services / 基础 ====================
-- autoexec 可能在载入界面执行, LocalPlayer 尚未就绪 → 等就绪 (LocalPlayer 是属性非子实例, 不能 WaitForChild)
local PlayersSvc = game:GetService("Players")
local LocalPlayer = PlayersSvc.LocalPlayer
local _lpWait = 0
while not LocalPlayer and _lpWait < 30 do
    PlayersSvc:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LocalPlayer = PlayersSvc.LocalPlayer
    _lpWait = _lpWait + 1
end
local HttpService = game:GetService("HttpService")

-- ==================== 游戏隔离注册表 ====================
-- _G 生命周期 = 当前 DataModel (换游戏/传送后自然清空)。
-- 按 GameName 键控: 同游戏重跑走热替换自毁交接, 异游戏脚本共存互不干扰。
rawset(_G, "RCWTK_REGISTRY", rawget(_G, "RCWTK_REGISTRY") or {})
local registry = rawget(_G, "RCWTK_REGISTRY")

-- 提前声明: softHide 闭包要捕获本实例的 WindUI, 禁止按名全局扫 (会误关共存脚本窗口)
local WindUI = nil
local RayfieldLib = nil
local rfWindow = nil
local rfScreenGui = nil
local _windowPersist = nil -- hub: SetWindowPersist(fn) fn(hidden:boolean)
local muteAllNotify = false -- 齿轮页: 关闭所有通知窗口 (按 PlaceId 落盘)
local rfBrandMotionTweens = {}
local rfBrandMotionAlive = true

local function mutePrefPaths()
    local id = tostring(game.PlaceId)
    return {
        "Configurations/TheKing_" .. id .. "/mute-notify.txt",
        "TheKing_" .. id .. "/mute-notify.txt",
    }
end
local function loadMuteNotify()
    for _, p in ipairs(mutePrefPaths()) do
        local ok, raw = pcall(readfile, p)
        if ok and type(raw) == "string" then
            raw = string.lower((raw:gsub("%s+", "")))
            muteAllNotify = (raw == "1" or raw == "true" or raw == "yes")
            return
        end
    end
end
local function saveMuteNotify()
    local body = muteAllNotify and "1" or "0"
    local paths = mutePrefPaths()
    local first = paths[1]
    local folder = first:match("^(.*)/[^/]+$")
    if folder and type(makefolder) == "function" then
        local parent = folder:match("^(.*)/[^/]+$")
        if parent then
            pcall(makefolder, parent)
        end
        pcall(makefolder, folder)
    end
    if pcall(writefile, first, body) then
        return
    end
    for i = 2, #paths do
        local p = paths[i]
        local fold = p:match("^(.*)/[^/]+$")
        if fold and type(makefolder) == "function" then
            pcall(makefolder, fold)
        end
        if pcall(writefile, p, body) then
            return
        end
    end
end
local function dismissAllNotifs()
    pcall(function()
        if rfWindow then
            local q = rfWindow._liveNotifications
            if type(q) == "table" then
                for i = #q, 1, -1 do
                    local n = q[i]
                    if type(n) == "table" then
                        if type(n._dismiss) == "function" then
                            pcall(n._dismiss, n)
                        elseif n.main then
                            pcall(function()
                                n.main:Destroy()
                            end)
                        end
                    end
                end
            end
            for _, key in ipairs({ "notifications", "_toastsTop", "_toastsBottom" }) do
                local host = rfWindow[key]
                if host then
                    for _, ch in ipairs(host:GetChildren()) do
                        if ch:IsA("GuiObject") and not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then
                            pcall(function()
                                ch:Destroy()
                            end)
                        end
                    end
                end
            end
        end
        if WindUI and WindUI.NotificationGui then
            for _, ch in ipairs(WindUI.NotificationGui:GetChildren()) do
                if ch:IsA("GuiObject") and not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then
                    pcall(function()
                        ch:Destroy()
                    end)
                end
            end
        end
    end)
end
local function wrapMuteWinFn(win, name)
    if type(win) ~= "table" then
        return
    end
    local mark = "_tkMuteWrap_" .. name
    if win[mark] then
        return
    end
    local orig = win[name]
    if type(orig) ~= "function" then
        local mt = getmetatable(win)
        if type(mt) == "table" then
            orig = mt[name]
            if type(orig) ~= "function" and type(mt.__index) == "table" then
                orig = mt.__index[name]
            end
        end
    end
    if type(orig) ~= "function" then
        return
    end
    win[mark] = true
    win[name] = function(self, ...)
        if muteAllNotify then
            return self
        end
        return orig(self, ...)
    end
end
local function installMuteOnWindow(win)
    if type(win) ~= "table" then
        return
    end
    wrapMuteWinFn(win, "Notify")
    wrapMuteWinFn(win, "Toast")
    if win._tkMuteToggle then
        return
    end
    local tab = win.rfSettings
    if type(tab) ~= "table" or type(tab.CreateToggle) ~= "function" then
        return
    end
    win._tkMuteToggle = true
    local ignoreInit = true
    pcall(function()
        if type(tab.CreateSection) == "function" then
            tab:CreateSection({ name = "TheKing HUB" })
        end
        tab:CreateToggle({
            name = "关闭所有通知",
            description = "开启后本游戏不再弹出任何通知窗口（警告、提示、Toast 全部关掉）。按游戏单独记住。",
            value = muteAllNotify,
            callback = function(on)
                if ignoreInit then
                    return
                end
                muteAllNotify = on == true
                saveMuteNotify()
                if muteAllNotify then
                    dismissAllNotifs()
                end
            end,
        })
    end)
    task.defer(function()
        ignoreInit = false
    end)
end
loadMuteNotify()

local function stopRfBrandMotion()
    rfBrandMotionAlive = false
    for _, tw in ipairs(rfBrandMotionTweens) do
        pcall(function()
            tw:Cancel()
        end)
    end
    table.clear(rfBrandMotionTweens)
end

local OWN_WIND_GUI_KEYS = { "ScreenGui", "NotificationGui", "DropdownGui", "TooltipGui" }

local function eachOwnWindGui(fn)
    if WindUI then
        for _, key in ipairs(OWN_WIND_GUI_KEYS) do
            local gui = WindUI[key]
            if gui then
                fn(gui)
            end
        end
    end
    if rfScreenGui then
        fn(rfScreenGui)
    end
end

--- 只软隐藏本实例 WindUI 层 (Potassium 禁止 Window:Destroy/Close/Parent=nil)
--- 旧实现按名扫全部 "WindUI" ScreenGui → Loader 自毁会把已注入游戏 HUB 的窗口一并 Enabled=false
local function softHideOwnWindUi(detach)
    pcall(function()
        eachOwnWindGui(function(gui)
            gui.Enabled = false
            if detach == true then
                gui.Parent = nil
            end
        end)
    end)
end

--- 热替换交接: 关掉「别人的」遗留 HUB 层, 绝不碰本实例刚创建的窗
local function isLegacyHubGui(gui)
    if not gui or not gui:IsA("ScreenGui") then
        return false
    end
    if gui.Name:find("WindUI") or gui:FindFirstChild("WindUI", true) then
        return true
    end
    if gui:FindFirstChild("Rayfield", true) then
        return true
    end
    -- Rayfield Gen2 的 ScreenGui 名是 GUID, 没有 "Rayfield" 子级, 用窗口标题认
    local ok, hit = pcall(function()
        local sawBrand, sawGame = false, false
        for _, d in ipairs(gui:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextButton") then
                local t = d.Text
                if t == "TheKing HUB" or t == "theKing Hub" then
                    sawBrand = true
                end
                if t == GameName then
                    sawGame = true
                end
            end
        end
        -- 必须带当前游戏名, 避免误拆同时开着的其他游戏 HUB
        return sawBrand and sawGame
    end)
    return ok and hit == true
end
local function hideForeignWindUi()
    pcall(function()
        local mine = {}
        eachOwnWindGui(function(gui)
            mine[gui] = true
        end)
        local function sweep(parent)
            if not parent then
                return
            end
            for _, gui in ipairs(parent:GetChildren()) do
                if gui:IsA("ScreenGui") and not mine[gui] and isLegacyHubGui(gui) then
                    pcall(function()
                        gui:Destroy()
                    end)
                end
            end
        end
        if type(gethui) == "function" then
            sweep(gethui())
        end
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if pg then
            sweep(pg)
        end
    end)
end

local function ensureOwnWindUiEnabled()
    pcall(function()
        eachOwnWindGui(function(gui)
            gui.Enabled = true
        end)
    end)
end

-- ==================== 热调试: 同游戏旧实例自毁交接 ====================
local didHotSwap = false
if type(registry[GameName]) == "function" then
    didHotSwap = true
    logInfo("热替换 [" .. GameName .. "]: 检测到旧实例, 触发其自毁...")
    pcall(function()
        registry[GameName]({ hotSwap = true })
    end)
    task.wait() -- 让销毁落地一帧, 避免新旧 UI 同帧闪现
    logInfo("旧实例已销毁, 接管完成")
end

-- 冷启动防御: registry 为空但 PlayerGui 有遗留 theKing UI (非 RCWTK 协议的旧版本产物) -> 清理
-- registry 非空 = 有其他游戏脚本在共存, 此时严禁全局清扫 (会误杀别人的窗口)
if next(registry) == nil then
    pcall(function()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if not pg then return end
        for _, gui in ipairs(pg:GetChildren()) do
            if gui:IsA("ScreenGui") and (gui.Name:find("theKing") or gui.Name:find("TheKing")) then
                gui.Enabled = false
            end
        end
    end)
else
    logInfo("检测到共存实例 (" .. table.concat((function()
        local t = {}
        for k in pairs(registry) do table.insert(t, k) end
        return t
    end)(), ", ") .. "), 跳过全局清理以保护它们")
end

-- ==================== HTTP 层 (跨注入器兼容) ====================
-- HttpGet 主路; request 兜底。部分注入器 HttpGet 失败时静默返回 "" (不抛错)。
local function httpGet(url)
    if type(game.HttpGet) == "function" then
        local body = game:HttpGet(url)
        if type(body) == "string" and #body > 0 then
            return body
        end
        -- 空串: 不直接放弃, 尝试 request 兜底 (同 URL)
    end
    local req = rawget(_G, "request")
        or (type(http) == "table" and type(http.request) == "function" and http.request)
    if type(req) ~= "function" then
        if type(game.HttpGet) == "function" then
            return game:HttpGet(url) -- 保留原行为 (可能仍为空)
        end
        error(LOG .. " 无可用 HTTP 函数 (HttpGet / request)", 0)
    end
    local resp = req({ Url = url, Method = "GET" })
    return type(resp) == "table" and (resp.Body or resp.body) or resp
end

-- 带空串/截断重试的拉取 (大文件在部分注入器上偶发失败)
local function httpGetRetry(url, minBytes, tries)
    minBytes = minBytes or 1
    tries = tries or 3
    local last
    for i = 1, tries do
        local ok, body = pcall(httpGet, url)
        if ok and type(body) == "string" and #body >= minBytes then
            return body
        end
        last = ok and (type(body) == "string" and (#body .. "B") or tostring(body)) or tostring(body)
        if i < tries then
            task.wait(0.35 + math.random() * 0.4)
        end
    end
    error(LOG .. " HTTP 拉取失败 (" .. tostring(url) .. "): " .. tostring(last), 0)
end

-- 品牌方圆标: 本地 png 优先, 否则解开 b64 写出后再 getcustomasset (发布单文件也能用)
local BRAND_PNG_PATHS = { "lib/assets/theking-mark.png", "theking-mark.png" }
local BRAND_B64_PATHS = { "lib/assets/theking-mark.b64", "theking-mark.b64" }
local function b64decode(data)
    if type(data) ~= "string" or data == "" then
        return nil
    end
    local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    data = data:gsub("[^" .. alphabet .. "=]", "")
    local out = data:gsub(".", function(x)
        if x == "=" then
            return ""
        end
        local f = alphabet:find(x, 1, true)
        if not f then
            return ""
        end
        f = f - 1
        local r = ""
        for i = 6, 1, -1 do
            r = r .. ((f % (2 ^ i) - f % (2 ^ (i - 1)) > 0) and "1" or "0")
        end
        return r
    end)
    return (out:gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
        if #x ~= 8 then
            return ""
        end
        local c = 0
        for i = 1, 8 do
            c = c + (x:sub(i, i) == "1" and 2 ^ (8 - i) or 0)
        end
        return string.char(c)
    end))
end
local function resolveBrandFile()
    if type(isfile) == "function" then
        for _, p in ipairs(BRAND_PNG_PATHS) do
            if isfile(p) then
                return p
            end
        end
    end
    if type(writefile) ~= "function" or type(readfile) ~= "function" then
        return nil
    end
    for _, bp in ipairs(BRAND_B64_PATHS) do
        if type(isfile) == "function" and isfile(bp) then
            local ok, raw = pcall(readfile, bp)
            if ok then
                local bin = b64decode(raw)
                if type(bin) == "string" and #bin > 32 then
                    pcall(writefile, "theking-mark.png", bin)
                    return "theking-mark.png"
                end
            end
        end
    end
    return nil
end
local brandIcon = nil
local function loadBrandIcon()
    if brandIcon then
        return brandIcon
    end
    local path = resolveBrandFile()
    if not path or type(getcustomasset) ~= "function" then
        return nil
    end
    local ok, asset = pcall(getcustomasset, path)
    if ok and type(asset) == "string" and asset ~= "" then
        brandIcon = asset
        logInfo("品牌图标: " .. path)
        return brandIcon
    end
    return nil
end

-- 功能 Tab: Lucide 图标库 (latte-soft 48px 单图, 缓存到 lucide-cache/)
local lucideIconCache = {}
local function resolveTabIcon(v)
    if type(v) == "number" and v > 0 then
        return v
    end
    if type(v) ~= "string" or v == "" then
        return nil
    end
    if v:sub(1, 11) == "rbxasset://" or v:sub(1, 13) == "rbxassetid://" or v:sub(1, 11) == "rbxthumb://" then
        return v
    end
    local asNum = tonumber(v)
    if asNum then
        return asNum
    end
    if lucideIconCache[v] then
        return lucideIconCache[v]
    end
    if type(getcustomasset) ~= "function" then
        return nil
    end
    local folder = "lucide-cache"
    pcall(function()
        if type(makefolder) == "function" then
            if not (type(isfolder) == "function" and isfolder(folder)) then
                makefolder(folder)
            end
        end
    end)
    local file = folder .. "/" .. v .. ".png"
    if type(isfile) == "function" and isfile(file) then
        local ok, asset = pcall(getcustomasset, file)
        if ok and type(asset) == "string" and asset ~= "" then
            lucideIconCache[v] = asset
            return asset
        end
    end
    local urls = {
        ("https://cdn.jsdelivr.net/gh/latte-soft/lucide-roblox@master/icons/compiled/48px/%s.png"):format(v),
        ("https://raw.githubusercontent.com/latte-soft/lucide-roblox/master/icons/compiled/48px/%s.png"):format(v),
    }
    for _, url in ipairs(urls) do
        local ok, body = pcall(httpGet, url)
        if ok and type(body) == "string" and #body > 64 and not body:find("<html", 1, true) then
            if type(writefile) == "function" then
                pcall(writefile, file, body)
            end
            local ok2, asset = pcall(getcustomasset, file)
            if ok2 and type(asset) == "string" and asset ~= "" then
                lucideIconCache[v] = asset
                return asset
            end
        end
    end
    return nil
end

-- ==================== 授权闸门 (v1.7.1) ====================
-- 防直接注入: 脚本自带白名单自校验, Loader 白名单只是双保险。
-- 流程: 拉 users.enc -> 解密 -> JSONDecode -> 用户名匹配 + 到期判断。
--   - 失败 (网络/解密/解析/名单外) -> 一律未授权, 拒绝建 UI (fail-closed)
--   - 已到期 -> 显示 "用户已至期限，请续约公司" 并退出
-- 防本地时间篡改 (v1.7.1): 从 HTTP 响应头取服务端 Date 判到期, 本地与服务端
--   偏差 > 2 天 -> 拒绝 (reason=clock), 防改系统时间绕过到期。
-- 跳过条件: GameName == "TheKing Loader" (Loader 自带 L1-L5 授权链路, 避免双重校验)
--           config.Auth == false (纯开发/测试显式豁免)
-- 诚实边界: 客户端校验可被逆向删除, 防君子不防高手; 彻底防需服务端签名体系 (后续)
local AUTH_DEFAULTS = {
    RepoOwner = "CheckCheat",
    RepoName = "the-king-hub",
    RepoBranch = "master",
    UsersPath = "dist/users.enc",
    WhiteKey = 20260831, -- 必须与 tools/whitelist.py WHITE_KEY 一致
}
local AUTH_MIRROR = { Owner = "CheckCheats", Name = "theKing-Hub", Branch = "main" }
-- 解密常量 (与 tools/whitelist.py / Loader 逐字节一致)
local AUTH_EGG = { 20320, 30475, 20320, 22920, 22920, 21602 }              -- 你看你妈妈呢
local AUTH_LOVE = { 108, 111, 118, 101 }                                   -- love
local AUTH_YPR = { 89, 111, 117, 32, 80, 108, 97, 121, 32, 82, 111, 98, 108, 111, 120 } -- You Play Roblox
local AUTH_SURRENDER_DAY = 19450815                                        -- 日本战败日
local AUTH_MONTHS = { Jan=1,Feb=2,Mar=3,Apr=4,May=5,Jun=6,Jul=7,Aug=8,Sep=9,Oct=10,Nov=11,Dec=12 }

-- HTTP 日期解析 (RFC 7231 IMF-fixdate): "Mon, 31 Aug 2026 10:00:00 GMT" -> "2026-08-31"
local function parseHttpDate(hdr)
    if type(hdr) ~= "string" then return nil end
    local d, mon, y = hdr:match("(%a+), (%d+) (%a+) (%d+)")
    if not (d and mon and y) then
        d, mon, y = hdr:match("(%d+) (%a+) (%d+)")
    end
    if not (d and mon and y) then return nil end
    local mn = AUTH_MONTHS[mon]
    if not mn then return nil end
    local di, yi = tonumber(d), tonumber(y)
    if not (di and yi) then return nil end
    return string.format("%04d-%02d-%02d", yi, mn, di)
end

-- 日期序数 (用于偏差计算, 不依赖 os.time 规避时区坑)
local function authDateOrdinal(s)
    if type(s) ~= "string" then return nil end
    local y, m, d = s:match("(%d+)-(%d+)-(%d+)")
    if not (y and m and d) then return nil end
    local yi, mi, di = tonumber(y), tonumber(m), tonumber(d)
    if not (yi and mi and di) then return nil end
    return yi * 372 + (mi - 1) * 31 + (di - 1)
end

-- 授权专用 HTTP: 优先 request (拿响应头 Date), 兜底 HttpGet (无响应头)
local function authHttpGet(url)
    local req = rawget(_G, "request") or (type(http) == "table" and http.request)
    if type(req) == "function" then
        local ok, resp = pcall(function() return req({ Url = url, Method = "GET" }) end)
        if ok and type(resp) == "table" then
            local body = resp.Body or resp.body
            local hdr = resp.Headers or resp.headers
            return body, parseHttpDate(type(hdr) == "table" and (hdr.Date or hdr.date) or nil)
        end
    end
    if type(game.HttpGet) == "function" then
        local ok, body = pcall(game.HttpGet, game, url)
        if ok then return body, nil end
    end
    return nil, nil
end

local function authCdnUrls(path)
    local d = AUTH_DEFAULTS
    local m = AUTH_MIRROR
    return {
        ("https://gitee.com/%s/%s/raw/%s/%s"):format(d.RepoOwner, d.RepoName, d.RepoBranch, path),
        ("https://gitee.com/%s/%s/raw/%s/%s?raw=true"):format(d.RepoOwner, d.RepoName, d.RepoBranch, path),
        ("https://raw.githubusercontent.com/%s/%s/%s/%s"):format(m.Owner, m.Name, m.Branch, path),
    }
end

local function authFetchFirst(urls)
    for _, u in ipairs(urls) do
        local body, date = authHttpGet(u)
        if type(body) == "string" and #body > 0 then
            local head = body:sub(1, 32):lower()
            if not (head:find("<!doctype") or head:find("<html") or head:find("<head")) then
                return body, date
            end
        end
    end
    return nil, nil
end

local function authJsonDecode(s)
    if not s then return nil end
    local ok, v = pcall(function() return HttpService:JSONDecode(s) end)
    if ok then return v end
    local ok2, chunk = pcall(function() return loadstring("return " .. s) end)
    if ok2 and type(chunk) == "function" then
        local ok3, v2 = pcall(chunk)
        if ok3 then return v2 end
    end
    return nil
end

local function authDecrypt(encBytes)
    local k = #encBytes
    local t = {}
    for i = 1, k do
        local c = encBytes:byte(i)
        local p = i * 31 + k * 7 + AUTH_EGG[(i - 1) % #AUTH_EGG + 1]
            + AUTH_LOVE[(i - 1) % #AUTH_LOVE + 1] + AUTH_YPR[(i - 1) % #AUTH_YPR + 1]
            + AUTH_SURRENDER_DAY + AUTH_DEFAULTS.WhiteKey
        t[i] = string.char((c - p) % 256)
    end
    return table.concat(t)
end

local function authTodayUtc()
    local t = os.date("!*t")
    return string.format("%04d-%02d-%02d", t.year, t.month, t.day)
end

-- 到期判断: refDate 为服务端日期 (from HTTP Date), 字典序比较即时间序
local function authIsExpired(untilStr, refDate)
    if type(untilStr) ~= "string" or #untilStr == 0 then
        return false -- until 缺省/空 = 永久
    end
    if type(refDate) ~= "string" or #refDate == 0 then
        return false -- 无参照日期时不判过期 (由上层保证传入 refDate)
    end
    return refDate > untilStr
end

-- 返回: ok=bool, reason="ok"/"expired"/"unauthorized"/"network"/"clock"
local function authCheck()
    local body, serverDate = authFetchFirst(authCdnUrls(AUTH_DEFAULTS.UsersPath))
    if not body then
        return false, "network"
    end
    local refDate = serverDate
    if not serverDate then
        -- 降级 (跨注入器兼容): request 不可用或响应无 Date 头时,
        -- 回退本地 UTC 日期做到期判断 (防篡改能力弱化, 但不拒用户)
        refDate = authTodayUtc()
        logWarn("无服务端时间 (HTTP Date 头缺失), 降级本地时间校验")
    else
        -- 防本地时间篡改: 本地 UTC 与服务端日期偏差 > 2 天 -> 拒绝
        local localDate = authTodayUtc()
        local diff = math.abs((authDateOrdinal(serverDate) or 0) - (authDateOrdinal(localDate) or 0))
        if diff > 2 then
            logWarn(string.format("本地时间 %s 与服务端 %s 偏差 %d 天, 疑似系统时间被篡改", localDate, serverDate, diff))
            return false, "clock"
        end
    end
    local okDec, plain = pcall(authDecrypt, body)
    if not okDec or not plain then
        return false, "network"
    end
    local users = authJsonDecode(plain)
    if type(users) ~= "table" then
        return false, "network"
    end
    for _, u in ipairs(users) do
        local nm = type(u) == "table" and tostring(u.name or u[1]) or tostring(u)
        if nm == LocalPlayer.Name then
            if type(u) == "table" and authIsExpired(u["until"], refDate) then
                return false, "expired"
            end
            return true, "ok"
        end
    end
    return false, "unauthorized"
end

-- 未授权拒绝 UI: 纯 ScreenGui 提示 (WindUI 尚未加载, 不能依赖窗口)
local function authDenyUi(reason)
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then
        pg = LocalPlayer:WaitForChild("PlayerGui", 10)
    end
    if not pg then return end
    local sg = Instance.new("ScreenGui")
    sg.Name = "TheKingAuthDenied"
    sg.ResetOnSpawn = false
    sg.DisplayOrder = 9998
    sg.Parent = pg

    local panel = Instance.new("Frame")
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.Size = UDim2.fromOffset(420, 240)
    panel.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
    panel.BorderSizePixel = 0
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)
    panel.Parent = sg

    local titleText = (reason == "expired") and "用户已至期限" or (reason == "clock") and "时间异常" or "未授权"
    local descText = (reason == "expired") and "您的授权已到期\n用户已至期限，请续约公司"
        or (reason == "clock") and "检测到系统时间异常\n本地时间与服务端不一致, 请校准系统时间后重试"
        or "当前用户不在授权名单内\n脚本拒绝运行, 请通过 Loader 获取授权"

    local title = Instance.new("TextLabel")
    title.Position = UDim2.fromOffset(0, 26)
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextScaled = true
    title.Text = titleText
    title.TextColor3 = Color3.fromRGB(255, 90, 90)
    title.Parent = panel

    local desc = Instance.new("TextLabel")
    desc.Position = UDim2.fromOffset(24, 84)
    desc.Size = UDim2.new(1, -48, 0, 90)
    desc.BackgroundTransparency = 1
    desc.Font = Enum.Font.Gotham
    desc.TextWrapped = true
    desc.TextXAlignment = Enum.TextXAlignment.Center
    desc.TextYAlignment = Enum.TextYAlignment.Top
    desc.Text = descText
    desc.TextColor3 = Color3.fromRGB(210, 210, 210)
    desc.Parent = panel

    local btn = Instance.new("TextButton")
    btn.AnchorPoint = Vector2.new(0.5, 1)
    btn.Position = UDim2.new(0.5, 0, 1, -18)
    btn.Size = UDim2.fromOffset(140, 36)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 66)
    btn.Text = "知道了"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.AutoButtonColor = true
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    btn.Activated:Connect(function()
        sg:Destroy()
    end)
    btn.Parent = panel
end

-- 闸门执行 (顶层): Loader 自带授权链路跳过; config.Auth=false 显式豁免; 其余一律校验
-- 热替换短缓存: 仅缓存成功, 失败仍 fail-closed 走网络; 防开发重跑每次拉 users.enc
if GameName ~= "TheKing Loader" and config.Auth ~= false then
    local cache = rawget(_G, "RCWTK_AUTH_CACHE")
    local cachedOk = type(cache) == "table"
        and cache.ok == true
        and cache.name == LocalPlayer.Name
        and type(cache.untilClock) == "number"
        and os.clock() < cache.untilClock
    if cachedOk then
        logInfo("授权校验命中热替换缓存 [" .. LocalPlayer.Name .. "]")
    else
        local authOk, authReason = authCheck()
        if not authOk then
            logWarn("授权校验未通过: " .. authReason)
            authDenyUi(authReason)
            error(LOG .. " 授权校验未通过 (" .. authReason .. "), 拒绝运行", 0)
        end
        rawset(_G, "RCWTK_AUTH_CACHE", {
            ok = true,
            name = LocalPlayer.Name,
            untilClock = os.clock() + AUTH_CACHE_TTL,
        })
        logInfo("授权校验通过 [" .. LocalPlayer.Name .. "]")
    end
end

-- ==================== 运行环境日志 (便于排障) ====================
task.spawn(function()
    local name
    local probe = type(identifyexecutor) == "function" and identifyexecutor
        or type(getexecutorname) == "function" and getexecutorname
    if probe then
        local ok2, v = pcall(probe)
        if ok2 then name = tostring(v) end
    end
    logInfo("TheKing HUB 启动 [" .. GameName .. "@" .. ScriptVersion .. "] | 运行环境: "
        .. (name or "未知注入器") .. " | RCWTK lib v" .. LIB_VERSION
        .. (headless and " | Headless" or (useRayfield and " | Rayfield Gen2" or (" | WindUI v" .. WINDUI_VERSION))))
end)

-- ==================== UI 库会话缓存 (热替换不重编, 源变了才 loadstring) ====================
local function uikitFingerprint(src)
    if type(src) ~= "string" then
        return nil
    end
    local n = #src
    local mid = math.max(1, math.floor(n / 2))
    return table.concat({
        tostring(n),
        src:sub(1, 48),
        src:sub(mid, mid + 47),
        src:sub(math.max(1, n - 47), n),
    }, "\n")
end
local function uikitBag()
    local bag = rawget(_G, "RCWTK_UIKIT_CACHE")
    if type(bag) ~= "table" then
        bag = {}
        rawset(_G, "RCWTK_UIKIT_CACHE", bag)
    end
    return bag
end
local function uikitCachedLib(kind, fp)
    local slot = uikitBag()[kind]
    if type(slot) ~= "table" or type(slot.lib) ~= "table" then
        return nil
    end
    if fp ~= nil and slot.fp ~= fp then
        return nil
    end
    return slot.lib
end
local function uikitCacheStore(kind, fp, lib)
    uikitBag()[kind] = { fp = fp, lib = lib }
end

-- ==================== 加载 UI 库 ====================
if not headless and useRayfield then
    local RF_MIN = 80000
    local RF_CACHE = "rayfield-gen2.lua"
    local rfFallbacks = {
        RF_CACHE,
        "lib/vendor/rayfield-gen2.lua",
    }
    local rfUrls = {
        "https://sirius.menu/gen2",
    }
    local function tryRf(src, label)
        if type(src) ~= "string" or #src < RF_MIN then
            return nil
        end
        local fp = uikitFingerprint(src)
        local hit = uikitCachedLib("rayfield", fp)
        if hit then
            logInfo("复用已编译 Rayfield Gen2 (源未变, 跳过 loadstring): " .. tostring(label))
            return hit
        end
        local chunk, cerr = loadstring(src)
        if not chunk then
            logWarn("Rayfield 编译失败 [" .. tostring(label) .. "]: " .. tostring(cerr))
            return nil
        end
        local ok, result = pcall(chunk)
        if ok and type(result) == "table" and type(result.CreateWindow) == "function" then
            uikitCacheStore("rayfield", fp, result)
            logInfo("已编译 Rayfield Gen2: " .. tostring(label))
            return result
        end
        logWarn("Rayfield 运行失败 [" .. tostring(label) .. "]: " .. tostring(result))
        return nil
    end
    local loadedRf = false
    for _, path in ipairs(rfFallbacks) do
        if type(readfile) == "function" and type(isfile) == "function" and isfile(path) then
            local ok, body = pcall(readfile, path)
            if ok then
                local result = tryRf(body, path)
                if result then
                    RayfieldLib = result
                    loadedRf = true
                    break
                end
            end
        end
    end
    if not loadedRf then
        for _, url in ipairs(rfUrls) do
            local ok, body = pcall(httpGetRetry, url, RF_MIN, 3)
            if ok then
                local result = tryRf(body, url)
                if result then
                    RayfieldLib = result
                    loadedRf = true
                    if type(writefile) == "function" then
                        pcall(writefile, RF_CACHE, body)
                    end
                    logInfo("已从网络加载 Rayfield Gen2 并缓存")
                    break
                end
            else
                logWarn(tostring(body))
            end
        end
    end
    if not loadedRf then
        local hit = uikitCachedLib("rayfield", nil)
        if hit then
            RayfieldLib = hit
            loadedRf = true
            logInfo("复用本会话已编译 Rayfield Gen2 (无本地源)")
        end
    end
    if not loadedRf then
        error(LOG .. " Rayfield Gen2 加载失败: 网络不可达且无本地副本", 0)
    end
    do
        local origCreate = RayfieldLib._TKOrigCreate
        if type(origCreate) ~= "function" then
            origCreate = RayfieldLib.CreateWindow
            RayfieldLib._TKOrigCreate = origCreate
        end
        local function nukeBannerHost(host)
            if host and host:IsA("ScreenGui") and host:FindFirstChild("Banner") then
                pcall(function()
                    host:Destroy()
                end)
            end
        end
        local function nukeBanners(parent)
            if not parent then
                return
            end
            for _, g in ipairs(parent:GetChildren()) do
                nukeBannerHost(g)
            end
        end
        function RayfieldLib.CreateWindow(self, props)
            local conns = {}
            local function hookParent(parent)
                if not parent then
                    return
                end
                conns[#conns + 1] = parent.ChildAdded:Connect(function(ch)
                    nukeBannerHost(ch)
                    if ch:IsA("ScreenGui") then
                        conns[#conns + 1] = ch.ChildAdded:Connect(function(c2)
                            if c2.Name == "Banner" then
                                nukeBannerHost(ch)
                            end
                        end)
                    end
                end)
            end
            pcall(function()
                if type(gethui) == "function" then
                    hookParent(gethui())
                end
            end)
            hookParent(game:GetService("CoreGui"))
            hookParent(LocalPlayer:FindFirstChildOfClass("PlayerGui"))
            local ok, win = pcall(origCreate, self, props)
            pcall(function()
                if type(gethui) == "function" then
                    nukeBanners(gethui())
                end
                nukeBanners(game:GetService("CoreGui"))
                nukeBanners(LocalPlayer:FindFirstChildOfClass("PlayerGui"))
            end)
            for _, c in ipairs(conns) do
                pcall(function()
                    c:Disconnect()
                end)
            end
            if not ok then
                error(win, 0)
            end
            pcall(function()
                if type(win) == "table" and win.settings then
                    win.settings.welcomeToast = false
                end
            end)
            pcall(installMuteOnWindow, win)
            -- Gen2 默认 wait(0.28) 拆 Banner 再 wait(0.18) 才 Show; 立刻出窗, 吃掉那次延迟 Show
            if type(win) == "table" and type(win.Show) == "function" then
                local origShow = win.Show
                local skipDelayedIntro = true
                function win.Show(wself, ...)
                    if skipDelayedIntro then
                        skipDelayedIntro = false
                        return wself
                    end
                    return origShow(wself, ...)
                end
                if not startHidden then
                    skipDelayedIntro = false
                    pcall(origShow, win)
                    skipDelayedIntro = true
                end
            end
            return win
        end
    end
elseif not headless then
do
    -- WindUI 启动时会 readfile("windui-cache/*.lua"); 缺文件时部分注入器返回 nil,
    -- 上游写法 loadstring(nil) 直接抛错, or 降级永远到不了。加载前给 readfile 加护栏。
    local function installWinduiReadfileGuard()
        if type(readfile) ~= "function" then
            return
        end
        local old = readfile
        local function guarded(path)
            local ok, body = pcall(old, path)
            if ok and type(body) == "string" and #body > 0 then
                return body
            end
            if type(path) == "string" and string.find(path, "windui-cache", 1, true) then
                return "return nil" -- loadstring 成功返回 nil, 让上游 or 内嵌模块生效
            end
            if not ok then
                error(body, 0)
            end
            return body
        end
        readfile = guarded
        pcall(function()
            if type(getgenv) == "function" then
                getgenv().readfile = guarded
            end
            rawset(_G, "readfile", guarded)
        end)
    end

    local function tryCompile(src, label)
        if type(src) ~= "string" or #src < WINDUI_MIN_BYTES then
            return nil
        end
        local fp = uikitFingerprint(src)
        local hit = uikitCachedLib("windui", fp)
        if hit then
            logInfo("复用已编译 WindUI (源未变, 跳过 loadstring): " .. tostring(label))
            return hit
        end
        local chunk, cerr = loadstring(src)
        if not chunk then
            logWarn("WindUI 编译失败 [" .. tostring(label) .. "]: " .. tostring(cerr))
            return nil
        end
        local ok, result = pcall(chunk)
        if ok and type(result) == "table" then
            uikitCacheStore("windui", fp, result)
            logInfo("已编译 WindUI: " .. tostring(label))
            return result
        end
        logWarn("WindUI 运行失败 [" .. tostring(label) .. "]: " .. tostring(result))
        return nil
    end

    local function cacheWindui(src)
        if type(writefile) == "function" and type(src) == "string" and #src >= WINDUI_MIN_BYTES then
            pcall(writefile, WINDUI_CACHE_PATH, src)
        end
    end

    installWinduiReadfileGuard()

    local loaded = false

    -- 0) 本地缓存优先 (零网络, 适配 HttpGet 不稳的注入器)
    for _, path in ipairs(LOCAL_FALLBACKS) do
        if type(readfile) == "function" and type(isfile) == "function" and isfile(path) then
            local ok, body = pcall(readfile, path)
            if ok then
                local result = tryCompile(body, path)
                if result then
                    WindUI = result
                    loaded = true
                    break
                end
            end
        end
    end

    -- 1) 网络多源 + 空串重试
    if not loaded then
        for _, url in ipairs(CDN_SOURCES) do
            local ok, body = pcall(httpGetRetry, url, WINDUI_MIN_BYTES, 3)
            if ok then
                local result = tryCompile(body, url)
                if result then
                    WindUI = result
                    loaded = true
                    cacheWindui(body)
                    logInfo("已从网络加载 WindUI 并缓存")
                    break
                end
            else
                logWarn(tostring(body))
            end
        end
    end

    if not loaded then
        local hit = uikitCachedLib("windui", nil)
        if hit then
            WindUI = hit
            loaded = true
            logInfo("复用本会话已编译 WindUI (无本地源)")
        end
    end

    if not loaded then
        error(LOG .. " WindUI 加载失败: CDN 不可达且无本地副本", 0)
    end
end
end -- not headless

-- ==================== 创建标准窗口 ====================
-- 配置目录按游戏隔离: 固定用 PlaceId (GameName 中文改名会改配置目录丢配置, v2.0.8 起不用 GameName)
local safeFolder = tostring(game.PlaceId)
local Window = nil

if useRayfield and RayfieldLib then
    loadBrandIcon()
    rfBrandMotionAlive = true
    -- 黑金主题: 不锁 cobalt; 开 LiveAnimation; 略亮 AccentGlow; 圆角更软
    local theKingTheme = {
        LiveAnimation = true,
        AccentGlow = 0.78,
        CornerRoundness = UDim.new(0, 16),
        PillCornerRadius = UDim.new(0, 14),
        ElementCornerRadius = UDim.new(0, 11),
        WindowColor = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(16, 14, 12)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(36, 28, 18)),
        }),
        ShadowColor = Color3.fromRGB(6, 5, 3),
        AccentColor = Color3.fromRGB(214, 170, 74),
        AccentStroke = Color3.fromRGB(242, 204, 112),
        TitlingColor = Color3.fromRGB(246, 236, 214),
        ContentColor = Color3.fromRGB(222, 214, 198),
        TabBackground = ColorSequence.new(Color3.fromRGB(204, 156, 62), Color3.fromRGB(138, 98, 34)),
        TabStroke = ColorSequence.new(Color3.fromRGB(236, 200, 100), Color3.fromRGB(164, 120, 44)),
        TabColor = Color3.fromRGB(255, 255, 255),
        SliderProgress = ColorSequence.new(Color3.fromRGB(224, 178, 82), Color3.fromRGB(164, 116, 38)),
        ElementStrokeHover = Color3.fromRGB(214, 170, 74),
    }
    rfWindow = RayfieldLib:CreateWindow({
        name = "TheKing HUB",
        subtitle = GameName,
        icon = brandIcon,
        showIcon = brandIcon,
        theme = theKingTheme,
        sidebarLayout = true,
        showName = "theKing Hub",
        showIconOnly = true,
        fallbackFont = Font.fromEnum(Enum.Font.SourceSans),
        configuration = {
            autoSave = true,
            autoLoad = false, -- 必须等业务把元素建完再 Load, 与 WindUI 时序一致
            fileName = "main",
            customFolder = "TheKing_" .. safeFolder,
        },
    })
    rfScreenGui = rfWindow.screenGui
    pcall(function()
        rfWindow.settings.toggleKeybind = Enum.KeyCode.F13 -- 显隐交给设置页 DEL, 避免双绑互相抵消
        -- 默认 mouseOverride 会一直把 MouseBehavior 掰回 Default, 游戏 Shift 视角锁开/关都失效
        rfWindow.settings.mouseOverride = false
    end)

    -- 菜单是否真正开着: 建窗时 topbar.Visible 已是 true, 但 main 还不可见、hidden=true
    -- 若误用 topbar 当开着, 会对从未 Show 的窗调 Hide, 缩到屏幕顶成药丸
    local function rfMenuOpen()
        if not rfWindow or rfWindow.unloaded then
            return false
        end
        if rfWindow.hidden == true then
            return false
        end
        if rfWindow.main and rfWindow.main.Visible ~= true then
            return false
        end
        return true
    end
    local function rfKeepUnshownHidden()
        if not rfWindow or rfWindow.hasShownOnce then
            return false
        end
        pcall(function()
            rfWindow.hidden = true
            rfWindow.animating = false
            rfWindow._revealing = false
            if rfWindow.main then
                rfWindow.main.Visible = false
            end
            if rfWindow.collapsedInteract then
                rfWindow.collapsedInteract.Visible = false
            end
        end)
        return true
    end
    if startHidden then
        rfKeepUnshownHidden()
    end

    -- 开菜单时松开鼠标方便点控件; 关掉后还原, 绝不 LockCenter 抢视角
    do
        local uis = game:GetService("UserInputService")
        local savedBehavior = nil
        local savedIcon = nil
        local function menuInteractive()
            return rfMenuOpen()
        end
        local function afterMenuToggle()
            task.defer(function()
                task.wait(0.08)
                if not rfWindow or rfWindow.unloaded then
                    return
                end
                if _windowPersist then
                    pcall(_windowPersist, not menuInteractive())
                end
                if menuInteractive() then
                    if savedBehavior == nil then
                        savedBehavior = uis.MouseBehavior
                        savedIcon = uis.MouseIconEnabled
                    end
                    pcall(function()
                        uis.MouseBehavior = Enum.MouseBehavior.Default
                        uis.MouseIconEnabled = true
                    end)
                    return
                end
                pcall(function()
                    if savedBehavior ~= nil then
                        uis.MouseBehavior = savedBehavior
                        uis.MouseIconEnabled = savedIcon == true
                    end
                end)
                savedBehavior = nil
                savedIcon = nil
            end)
        end
        for _, name in ipairs({ "Hide", "Show", "ToggleHide", "ToggleMinimise", "Reveal" }) do
            local orig = rfWindow[name]
            if type(orig) == "function" then
                rfWindow[name] = function(self, ...)
                    local r = orig(self, ...)
                    afterMenuToggle()
                    return r
                end
            end
        end
        afterMenuToggle()
    end

    local TweenService = game:GetService("TweenService")
    local logoBreathInfo = TweenInfo.new(1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
    local tabEnterInfo = TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

    local function trackTween(tw)
        if tw then
            table.insert(rfBrandMotionTweens, tw)
        end
        return tw
    end

    local function breatheLogo(img)
        if not img or not img:IsA("GuiObject") then
            return
        end
        local sc = img:FindFirstChild("TheKingLogoScale")
        if not sc then
            sc = Instance.new("UIScale")
            sc.Name = "TheKingLogoScale"
            sc.Parent = img
        end
        sc.Scale = 1
        trackTween(TweenService:Create(sc, logoBreathInfo, { Scale = 1.04 })):Play()
    end

    task.defer(function()
        if not rfBrandMotionAlive then
            return
        end
        pcall(function()
            breatheLogo(rfWindow.topbarIcon)
            breatheLogo(rfWindow.collapsedIcon)
        end)
        pcall(function()
            local layout = rfWindow.elementsLayout
            if layout then
                layout.TweenTime = 0.16
                layout.EasingStyle = Enum.EasingStyle.Quint
            end
        end)
    end)

    local function playTabEnter(rfTab)
        if not rfBrandMotionAlive or type(rfTab) ~= "table" then
            return
        end
        local page = rfTab.tabPage
        if not page then
            return
        end
        local sc = page:FindFirstChild("TheKingTabScale")
        if not sc then
            sc = Instance.new("UIScale")
            sc.Name = "TheKingTabScale"
            sc.Parent = page
        end
        sc.Scale = 0.985
        pcall(function()
            page.GroupTransparency = 0.22
        end)
        trackTween(TweenService:Create(sc, tabEnterInfo, { Scale = 1 })):Play()
        pcall(function()
            trackTween(TweenService:Create(page, tabEnterInfo, { GroupTransparency = 0 })):Play()
        end)
    end

    local function wrapText(h)
        if type(h) ~= "table" then
            return h
        end
        if type(h.SetDesc) ~= "function" then
            function h:SetDesc(desc)
                if type(self.Set) == "function" then
                    self:Set(tostring(desc or ""))
                end
            end
        end
        return h
    end

    local function wrapKeybind(h)
        if type(h) ~= "table" or type(h.Set) ~= "function" then
            return h
        end
        local orig = h.Set
        function h:Set(v, skip)
            if v == nil or v == "None" or v == "Unknown" then
                return orig(self, Enum.KeyCode.Unknown, skip)
            end
            if type(v) == "string" then
                local ok, k = pcall(function()
                    return Enum.KeyCode[v]
                end)
                if ok and typeof(k) == "EnumItem" then
                    v = k
                end
            end
            return orig(self, v, skip)
        end
        return h
    end

    local function disableSignalConns(signal)
        if type(getconnections) ~= "function" then
            return
        end
        pcall(function()
            for _, conn in ipairs(getconnections(signal)) do
                pcall(function()
                    if conn.Disable then
                        conn:Disable()
                    end
                    if conn.Disconnect then
                        conn:Disconnect()
                    end
                end)
            end
        end)
    end

    local function snapToggleKnob(el)
        local on = el.value == true
        pcall(function()
            if el.indicator then
                el.indicator.Position = on and UDim2.new(1, -28, 0.5, 0) or UDim2.new(1, -47, 0.5, 0)
                el.indicator.BackgroundColor3 = on and el.window.theme.AccentColor or el.window.theme.ToggleKnobOff
                local offT = el.window.theme.ToggleKnobOffTransparency
                el.indicator.BackgroundTransparency = on and 0 or (type(offT) == "number" and offT or 0)
            end
            if el.indicatorStroke then
                el.indicatorStroke.Color = on and el.window.theme.AccentStroke or Color3.fromRGB(255, 255, 255)
                el.indicatorStroke.Transparency = on and 0 or 0.7
            end
            if el.indicatorGlow then
                local glow = el.window.theme.AccentGlow
                el.indicatorGlow.Transparency = on and (type(glow) == "number" and glow or 0) or 1
            end
        end)
    end

    -- Rayfield 点击会 Tween 行 Size / UIStroke, Potassium 原生崩
    local function hardenRayfieldToggle(el)
        if type(el) ~= "table" or not el.interact then
            return el
        end
        el._animateIndicator = function(self)
            snapToggleKnob(self)
        end
        disableSignalConns(el.interact.MouseButton1Click)
        pcall(function()
            el.interact.Active = false
        end)
        local overlay = Instance.new("TextButton")
        overlay.Name = "RCWTK_SafeClick"
        overlay.BackgroundTransparency = 1
        overlay.BorderSizePixel = 0
        overlay.Text = ""
        overlay.AutoButtonColor = false
        overlay.Size = UDim2.fromScale(1, 1)
        overlay.ZIndex = 50
        overlay.Parent = el.main
        if el.window and type(el.window.ConnectFor) == "function" then
            el.window:ConnectFor(el, overlay.MouseButton1Click, function()
                el.value = not el.value
                snapToggleKnob(el)
                local cb = el.callback
                local v = el.value
                task.defer(function()
                    if type(cb) == "function" then
                        pcall(cb, v)
                    end
                end)
            end)
        else
            overlay.MouseButton1Click:Connect(function()
                el.value = not el.value
                snapToggleKnob(el)
                local cb = el.callback
                local v = el.value
                task.defer(function()
                    if type(cb) == "function" then
                        pcall(cb, v)
                    end
                end)
            end)
        end
        return el
    end

    local function hardenRayfieldButton(el)
        if type(el) ~= "table" or not el.interact then
            return el
        end
        disableSignalConns(el.interact.MouseButton1Click)
        pcall(function()
            el.interact.Active = false
        end)
        local overlay = Instance.new("TextButton")
        overlay.Name = "RCWTK_SafeClick"
        overlay.BackgroundTransparency = 1
        overlay.BorderSizePixel = 0
        overlay.Text = ""
        overlay.AutoButtonColor = false
        overlay.Size = UDim2.fromScale(1, 1)
        overlay.ZIndex = 50
        overlay.Parent = el.main
        local function fire()
            local cb = el.callback
            task.defer(function()
                if type(cb) == "function" then
                    pcall(cb)
                end
            end)
        end
        if el.window and type(el.window.ConnectFor) == "function" then
            el.window:ConnectFor(el, overlay.MouseButton1Click, fire)
        else
            overlay.MouseButton1Click:Connect(fire)
        end
        return el
    end

    local function wrapTab(rfTab)
        local t = {}
        -- 点击类控件 (Toggle/单选Dropdown/Keybind 改绑) 变更后显式 Save:
        -- Rayfield autoSave 在本环境不触发 (rfld 从未生成), 由引擎兜底低频写盘
        local function postSave(cb)
            if type(cb) ~= "function" then
                return cb
            end
            return function(...)
                local r1, r2, r3 = cb(...)
                task.spawn(function()
                    pcall(function()
                        if rfWindow and rfWindow.Save then
                            rfWindow:Save()
                        end
                    end)
                end)
                return r1, r2, r3
            end
        end
        function t:Toggle(cfg)
            cfg = cfg or {}
            local el = rfTab:CreateToggle({
                name = cfg.Title,
                description = (type(cfg.Desc) == "string" and cfg.Desc ~= "") and cfg.Desc or nil,
                value = cfg.Value == true,
                flag = cfg.Flag,
                forgetState = cfg.Flag == nil,
                callback = postSave(cfg.Callback),
            })
            return hardenRayfieldToggle(el)
        end
        function t:Slider(cfg)
            cfg = cfg or {}
            local minV, maxV, defV = 0, 100, 0
            local val = cfg.Value
            if type(val) == "table" then
                minV = tonumber(val.Min or val.min) or 0
                maxV = tonumber(val.Max or val.max) or 100
                defV = tonumber(val.Default or val.default) or minV
            elseif type(val) == "number" then
                defV = val
            end
            return rfTab:CreateSlider({
                name = cfg.Title,
                description = (type(cfg.Desc) == "string" and cfg.Desc ~= "") and cfg.Desc or nil,
                range = { minV, maxV },
                increment = cfg.Step or 1,
                value = defV,
                flag = cfg.Flag,
                forgetState = cfg.Flag == nil,
                callback = cfg.Callback,
            })
        end
        function t:Dropdown(cfg)
            cfg = cfg or {}
            return rfTab:CreateDropdown({
                name = cfg.Title,
                description = (type(cfg.Desc) == "string" and cfg.Desc ~= "") and cfg.Desc or nil,
                options = cfg.Values or {},
                value = cfg.Value,
                multiSelect = cfg.Multi == true,
                flag = cfg.Flag,
                forgetState = cfg.Flag == nil,
                callback = postSave(cfg.Callback),
            })
        end
        function t:Button(cfg)
            cfg = cfg or {}
            local el = rfTab:CreateButton({
                name = cfg.Title,
                description = (type(cfg.Desc) == "string" and cfg.Desc ~= "") and cfg.Desc or nil,
                callback = cfg.Callback,
            })
            return hardenRayfieldButton(el)
        end
        function t:Paragraph(cfg)
            cfg = cfg or {}
            return wrapText(rfTab:CreateText({
                name = cfg.Title or "",
                text = cfg.Desc or "",
            }))
        end
        function t:Section(cfg)
            cfg = cfg or {}
            rfTab:CreateSection({ name = cfg.Title or "" })
            return t -- WindUI 的 Section 还能往下挂元素, 转发回本 Tab
        end
        function t:Keybind(cfg)
            cfg = cfg or {}
            return wrapKeybind(rfTab:CreateKeybind({
                name = cfg.Title,
                description = (type(cfg.Desc) == "string" and cfg.Desc ~= "") and cfg.Desc or nil,
                value = cfg.Value,
                flag = cfg.Flag,
                forgetState = cfg.Flag == nil,
                callback = cfg.Callback, -- 按下已绑定键 (设置页 DEL/END), 频繁不 Save
                onChanged = postSave(cfg.OnChanged), -- 改绑 (快捷键页), 低频显式保存
            }))
        end
        function t:Input(cfg)
            cfg = cfg or {}
            return rfTab:CreateInput({
                name = cfg.Title,
                description = cfg.Desc,
                value = cfg.Value,
                placeholder = cfg.Placeholder,
                flag = cfg.Flag,
                forgetState = cfg.Flag == nil,
                callback = cfg.Callback,
            })
        end
        -- 暴露 Rayfield tab 内容容器 (ScrollingFrame), 供 hub 内嵌自绘 UI 面板
        -- 自绘元素以普通 Frame 子级插入 tabPage 即可随 UIListLayout 排列
        function t:RawPage()
            return rfTab.tabPage
        end
        if type(rfTab.Select) == "function" then
            local origSelect = rfTab.Select
            function rfTab:Select(...)
                local r = origSelect(self, ...)
                playTabEnter(self)
                return r
            end
        end
        return t
    end

    Window = {
        Toggle = function()
            if rfScreenGui then
                rfScreenGui.Enabled = true
            end
            pcall(function()
                if rfWindow.animating then
                    return
                end
                if rfMenuOpen() then
                    rfWindow.hidden = false
                    rfWindow:Hide()
                else
                    rfWindow.hidden = true
                    rfWindow:Show()
                end
            end)
        end,
        Open = function()
            pcall(function()
                if type(rfWindow.Reveal) == "function" then
                    rfWindow:Reveal()
                elseif rfScreenGui then
                    rfScreenGui.Enabled = true
                end
            end)
        end,
        Close = function()
            pcall(function()
                rfWindow:ToggleHide()
            end)
        end,
        Tab = function(_, cfg)
            cfg = cfg or {}
            -- rfWindow 已销毁时缓存命中会抛 Plugin 错；检测并让缓存失效
            if not (rfWindow and rfWindow.screenGui and rfWindow.screenGui.Parent) then
                local bag = rawget(_G, "RCWTK_UIKIT_CACHE")
                if bag then
                    bag["windui"] = nil
                    bag["rflib"] = nil
                end
                return error("[TheKing] NewTab failed: rfWindow destroyed, please re-execute the hub script")
            end
            return wrapTab(rfWindow:CreateTab({
                name = cfg.Title or "Tab",
                icon = resolveTabIcon(cfg.Icon),
            }))
        end,
        Dialog = function(_, cfg)
            cfg = cfg or {}
            local options = {}
            if type(cfg.Buttons) == "table" and #cfg.Buttons > 0 then
                for i, b in ipairs(cfg.Buttons) do
                    local variant = tostring(b.Variant or b.style or "")
                    local style = "neutral"
                    if variant == "Primary" or variant == "primary" or variant == "Danger" then
                        style = (variant == "Danger" or variant == "danger") and "danger" or "primary"
                    elseif i == #cfg.Buttons then
                        style = "primary"
                    end
                    table.insert(options, {
                        text = b.Title or b.text or "确定",
                        style = style,
                        callback = b.Callback,
                    })
                end
            else
                options = {
                    { text = "取消", style = "neutral" },
                    {
                        text = "确定",
                        style = "primary",
                        callback = function()
                            local fn = cfg.OnConfirm
                            if type(fn) == "function" then
                                task.defer(fn)
                            end
                        end,
                    },
                }
            end
            return rfWindow:Popup({
                title = cfg.Title or "确认操作",
                content = cfg.Content or "",
                options = options,
            })
        end,
        OnClose = function() end,
        ConfigManager = nil,
    }

    hideForeignWindUi()
    -- 建窗时 Rayfield hidden=true, 不要在这里 Hide (会 no-op); 等首次 Show 后再按存档藏
    if rfScreenGui then
        rfScreenGui.Enabled = true
    end
elseif not headless then
    -- 窗口图标: 当前 Roblox 用户头像 (不用皇冠), URL 拼装失败回退皇冠
    local windowIcon = "crown"
    pcall(function()
        windowIcon = ("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=150&height=150"):format(LocalPlayer.UserId)
    end)

    Window = WindUI:CreateWindow({
        Title = "TheKing HUB",
        Icon = windowIcon,
        Author = GameName, -- 小字标注当前游戏名 (需求核心)
        Theme = "Dark",
        -- ToggleKey 不传: 与设置页 Keybind 元素双绑定会同帧切换两次互相抵消, 显示/隐藏由 Keybind 元素全权接管
        Size = config.WindowSize or UDim2.fromOffset(580, 420),
        Transparent = true,
        SideBarWidth = 150,
        Folder = "TheKing_" .. safeFolder,
    })
    -- 必须在 CreateWindow 之后: 拆掉同游戏遗留层, 不误伤其他游戏 HUB
    hideForeignWindUi()
    ensureOwnWindUiEnabled()

    WindUI:SetNotificationLower(true) -- 通知下移, 避开手机跳跃键
    pcall(function()
        WindUI:SetLanguage("zh-cn") -- 库内置文本尽量切中文 (语言代码不受支持时静默跳过)
    end)
    pcall(function()
        wrapMuteWinFn(WindUI, "Notify")
    end)
else
    logInfo("Headless 模式: 跳过 WindUI, 业务侧自建界面")
end

Window = Window or {
    Toggle = function() end,
    Dialog = function() end,
    Open = function() end,
    Close = function() end,
}

-- ==================== 状态机: 循环与连接登记 ====================
local loops = {}       -- name -> { thread=thread, alive=bool, idleUntil=number }
local connections = {} -- { RBXScriptConnection }
local namedConns = {}  -- name -> RBXScriptConnection (Heartbeat/Render, StopAll 可停)
local cleanupFns = {}  -- 业务清理函数 (OnCleanup 登记, Destroy 时执行)
local activeLoopName = nil
local slowWarnAt = {}
local antiAfkActive = false

local TheKing = {}

TheKing.WindUI = WindUI
TheKing.Rayfield = RayfieldLib
TheKing.Window = Window
TheKing.GameName = GameName
TheKing.ScriptVersion = ScriptVersion

-- 兜底: 若上一版把 ScreenGui 关了, 设置页 DEL 听不到; 全局再听一次只负责把 GUI 打开
if rfWindow and not headless then
    local uis = game:GetService("UserInputService")
    table.insert(connections, uis.InputBegan:Connect(function(input)
        if input.KeyCode ~= Enum.KeyCode.Delete then
            return
        end
        if rfScreenGui and rfScreenGui.Enabled == false then
            rfScreenGui.Enabled = true
            pcall(function()
                Window.Toggle()
            end)
        end
    end))
end
TheKing.LibVersion = LIB_VERSION

--- 登记业务清理函数 (销毁/热替换时按登记逆序执行):
--- 还原 hook / 恢复画质 / 移除自建 GUI 等业务侧恢复逻辑都走这里
function TheKing.OnCleanup(fn)
    if type(fn) == "function" then
        table.insert(cleanupFns, fn)
    end
end

local teleportArmed = false
local teleportPayload = nil
local teleportConn = nil
local function findQueueOnTeleport()
    local cands = {
        rawget(_G, "queue_on_teleport"),
        rawget(_G, "queueonteleport"),
    }
    if type(getgenv) == "function" then
        local ok, env = pcall(getgenv)
        if ok and type(env) == "table" then
            cands[#cands + 1] = env.queue_on_teleport
            cands[#cands + 1] = env.queueonteleport
        end
    end
    for _, f in ipairs(cands) do
        if type(f) == "function" then
            return f
        end
    end
    return nil
end
local function findClearTeleportQueue()
    local cands = {
        rawget(_G, "clear_teleport_queue"),
        rawget(_G, "clearteleportqueue"),
        rawget(_G, "clearqueueonteleport"),
    }
    if type(getgenv) == "function" then
        local ok, env = pcall(getgenv)
        if ok and type(env) == "table" then
            cands[#cands + 1] = env.clear_teleport_queue
            cands[#cands + 1] = env.clearteleportqueue
            cands[#cands + 1] = env.clearqueueonteleport
        end
    end
    for _, f in ipairs(cands) do
        if type(f) == "function" then
            return f
        end
    end
    return nil
end
local function fileExists(p)
    local ok, v = pcall(function()
        return type(isfile) == "function" and isfile(p)
    end)
    return ok and v == true
end
local function snapshotHub(files)
    if type(makefolder) == "function" then
        pcall(makefolder, "rcwtk-reload")
    end
    local snap = "rcwtk-reload/" .. tostring(game.PlaceId) .. ".luau"
    if type(files) == "table" then
        for _, p in ipairs(files) do
            if type(p) == "string" and fileExists(p) then
                local ok, body = pcall(readfile, p)
                if ok and type(body) == "string" and #body > 64 then
                    if type(writefile) == "function" then
                        pcall(writefile, snap, body)
                    end
                    return snap, p
                end
            end
        end
    end
    if fileExists(snap) then
        return snap, snap
    end
    return nil, nil
end
local function buildFileReloadStub(files, url)
    local quoted = {}
    for _, p in ipairs(files) do
        if type(p) == "string" and p ~= "" then
            quoted[#quoted + 1] = string.format("%q", p)
        end
    end
    local urlLit = (type(url) == "string" and url ~= "") and string.format("%q", url) or "nil"
    return table.concat({
        "task.spawn(function()",
        "local files={" .. table.concat(quoted, ",") .. "}",
        "local url=" .. urlLit,
        "local t=0",
        "while t<12 do",
        "local lp=game:GetService('Players').LocalPlayer",
        "if lp and lp:FindFirstChild('PlayerGui') then break end",
        "task.wait(0.25) t=t+0.25",
        "end",
        "task.wait(0.6)",
        "local function run(body,label)",
        "if type(body)~='string' or #body<64 then return false end",
        "local chunk,err=loadstring(body)",
        "if not chunk then warn('[RCWTK] 自动注入编译失败: '..tostring(err)) return false end",
        "print('[RCWTK] 传送后自动注入: '..tostring(label))",
        "local ran,re=pcall(chunk)",
        "if not ran then warn('[RCWTK] 自动注入执行失败: '..tostring(re)) return false end",
        "return true",
        "end",
        "for i=1,#files do",
        "local p=files[i]",
        "local has=false",
        "pcall(function() has=type(isfile)=='function' and isfile(p) end)",
        "if has then",
        "local ok,body=pcall(readfile,p)",
        "if ok and run(body,p) then return end",
        "end",
        "end",
        "if type(url)=='string' then",
        "local ok,body=pcall(function() return game:HttpGet(url) end)",
        "if ok and run(body,url) then return end",
        "end",
        "warn('[RCWTK] 传送后自动注入失败: 本地找不到 hub 且网络兜底未成功')",
        "end)",
    }, "\n")
end
local function pushTeleportQueue(src)
    local q = findQueueOnTeleport()
    if type(q) ~= "function" or type(src) ~= "string" or src == "" then
        return false, "no-api"
    end
    teleportPayload = src
    pcall(function()
        if type(getgenv) == "function" then
            getgenv().RCWTK_TP_PAYLOAD = src
        end
    end)
    local clearer = findClearTeleportQueue()
    if type(clearer) == "function" then
        pcall(clearer)
    end
    return pcall(q, src)
end

--- 换服后自动重跑. 无 queue_on_teleport 则跳过 (不报错).
--- spec.Source = 落地后执行的 Lua 源码; spec.Files = 按序 readfile 的 hub 路径; spec.Url = HttpGet 兜底.
function TheKing.ArmTeleportReload(spec)
    spec = type(spec) == "table" and spec or {}
    local q = findQueueOnTeleport()
    if type(q) ~= "function" then
        logInfo("传送自动注入未启用: 执行器无 queue_on_teleport")
        return false
    end
    local src = spec.Source or spec.source
    local files = spec.Files or spec.files
    if type(files) == "string" then
        files = { files }
    end
    if type(files) ~= "table" then
        files = {}
    end
    local url = spec.Url or spec.url
    local snap = snapshotHub(files)
    if snap then
        table.insert(files, 1, snap)
        logInfo("传送快照已写入 " .. snap)
    end
    if type(src) ~= "string" or src == "" then
        if #files == 0 and type(url) ~= "string" then
            logWarn("传送自动注入: 未提供 Source/Files/Url")
            return false
        end
        src = buildFileReloadStub(files, url)
    end
    local ok, err = pushTeleportQueue(src)
    if not ok then
        logWarn("传送自动注入挂号失败: " .. tostring(err))
        return false
    end
    teleportArmed = true
    if not teleportConn then
        pcall(function()
            teleportConn = LocalPlayer.OnTeleport:Connect(function(state)
                if not teleportArmed or type(teleportPayload) ~= "string" then
                    return
                end
                if state == Enum.TeleportState.RequestedFromServer
                    or state == Enum.TeleportState.Started
                    or state == Enum.TeleportState.WaitingForServer
                    or state == Enum.TeleportState.InProgress
                then
                    local qq = findQueueOnTeleport()
                    if type(qq) == "function" then
                        pcall(qq, teleportPayload)
                    end
                    logInfo("检测到传送, 已再次挂号")
                end
            end)
            if TheKing.AddConnection and teleportConn then
                TheKing.AddConnection(teleportConn)
            end
        end)
    end
    logInfo("传送自动注入已挂号 (重开/回城等换服后自动重跑)")
    return true
end

function TheKing.DisarmTeleportReload()
    if not teleportArmed then
        return
    end
    local clearer = findClearTeleportQueue()
    if type(clearer) == "function" then
        pcall(clearer)
    end
    if teleportConn then
        pcall(function()
            teleportConn:Disconnect()
        end)
        teleportConn = nil
    end
    teleportArmed = false
    teleportPayload = nil
    logInfo("传送自动注入已取消")
end

--- 新建 Tab (统一默认值)
function TheKing.NewTab(cfg)
    cfg = cfg or {}
    if type(Window.Tab) ~= "function" then
        return {}
    end
    return Window:Tab({
        Title = cfg.Title or "Tab",
        Icon = cfg.Icon,
        Desc = cfg.Desc,
    })
end

--- 子级查找: 已有则立刻返回, 没有才 WaitForChild(timeout), 失败返回 nil (禁止热循环无超时死等)
function TheKing.WaitChild(parent, childName, timeout)
    if parent == nil or childName == nil then
        return nil
    end
    local existing = parent:FindFirstChild(childName)
    if existing then
        return existing
    end
    timeout = timeout or 10
    local ok, inst = pcall(function()
        return parent:WaitForChild(childName, timeout)
    end)
    if ok then
        return inst
    end
    return nil
end

--- 热路径找 Remote: 只 FindFirstChild, 不等待. 默认扫 Remotes/remotes/Events 再扫 ReplicatedStorage 直系
function TheKing.FindRemote(name, folder)
    if type(name) ~= "string" or name == "" then
        return nil
    end
    if folder then
        return folder:FindFirstChild(name)
    end
    local rs = game:GetService("ReplicatedStorage")
    local remotes = rs:FindFirstChild("Remotes") or rs:FindFirstChild("remotes") or rs:FindFirstChild("Events")
    if remotes then
        local found = remotes:FindFirstChild(name)
        if found then
            return found
        end
    end
    return rs:FindFirstChild(name)
end

--- 开关 + 命名循环样板 (StartLoop/StopLoop/通知). OnEnable 返回 false 则不启动循环
local _rtToggles = {} -- flag -> Rayfield toggle el (程序化恢复用)
local _togglePersist = nil -- hub 注入的开关状态持久化回调 (flag, bool)
-- hub 注入持久化器: SetTogglePersist(fn) fn(flag, on) 在每次开关状态变化后调用
function TheKing.SetTogglePersist(fn)
    _togglePersist = fn
end
function TheKing.SetWindowPersist(fn)
    _windowPersist = fn
end
function TheKing.PinNativeToggleKey()
    pcall(function()
        if rfWindow and rfWindow.settings then
            rfWindow.settings.toggleKeybind = Enum.KeyCode.F13
        end
    end)
end
function TheKing.IsWindowHidden()
    if not rfWindow then
        return false
    end
    if rfWindow.hasShownOnce ~= true then
        return true
    end
    local open = false
    pcall(function()
        open = rfWindow.hidden ~= true and rfWindow.main and rfWindow.main.Visible == true
    end)
    return not open
end
function TheKing.SetWindowHidden(hidden)
    hidden = hidden == true
    if not rfWindow or rfWindow.unloaded then
        return
    end
    if rfScreenGui then
        rfScreenGui.Enabled = true
    end
    if hidden and rfWindow.hasShownOnce ~= true then
        pcall(function()
            rfWindow.hidden = true
            rfWindow.animating = false
            rfWindow._revealing = false
            if rfWindow.main then
                rfWindow.main.Visible = false
            end
            if rfWindow.collapsedInteract then
                rfWindow.collapsedInteract.Visible = false
            end
        end)
        return
    end
    if rfWindow.animating then
        task.delay(0.45, function()
            if not rfWindow or rfWindow.unloaded then
                return
            end
            TheKing.SetWindowHidden(hidden)
        end)
        return
    end
    pcall(function()
        local open = rfWindow.hidden ~= true and rfWindow.main and rfWindow.main.Visible == true
        if hidden then
            if open then
                rfWindow.hidden = false
                rfWindow:Hide()
            end
        else
            if not open then
                rfWindow.hidden = true
                rfWindow:Show()
            end
        end
    end)
end
-- 程序化恢复单个开关 (等价用户点击, 触发 OnEnable/OnDisable + 启动/停止 loop)
function TheKing.RestoreToggle(flag, on)
    local el = _rtToggles[flag]
    if el and type(el.Set) == "function" then
        pcall(el.Set, el, on == true)
    end
end
function TheKing.BindToggle(tab, cfg)
    cfg = cfg or {}
    local loopName = cfg.Loop or cfg.Flag or cfg.Title
    local interval = cfg.Interval or 0.5
    local el = tab:Toggle({
        Title = cfg.Title or "功能",
        Desc = cfg.Desc,
        Icon = cfg.Icon,
        Flag = cfg.Flag,
        Value = cfg.Value == true,
        Callback = function(state)
            if state then
                if type(cfg.OnEnable) == "function" then
                    local ok, allow = pcall(cfg.OnEnable)
                    if not ok then
                        logWarn("BindToggle OnEnable 异常: " .. tostring(allow))
                        return
                    end
                    if allow == false then
                        return
                    end
                end
                TheKing.StartLoop(loopName, interval, function()
                    if type(cfg.OnTick) == "function" then
                        cfg.OnTick()
                    end
                end, {
                    jitter = cfg.Jitter,
                    wakeIf = cfg.WakeIf,
                    autoBackoff = cfg.AutoBackoff,
                })
                if cfg.Notify ~= false then
                    TheKing.Notify({ Content = tostring(cfg.Title or loopName) .. " 已开启" })
                end
            else
                TheKing.StopLoop(loopName)
                if type(cfg.OnDisable) == "function" then
                    pcall(cfg.OnDisable)
                end
            end
            -- 开关状态落盘 (自建持久化, 绕过 Rayfield 失效的 autoSave)
            if _togglePersist and cfg.Flag then
                pcall(_togglePersist, cfg.Flag, state)
            end
        end,
    })
    if cfg.Flag then
        _rtToggles[cfg.Flag] = el
    end
    return el
end

--- 启动命名循环 (覆盖同名旧循环; 强制间隔下限; 单次执行超阈值告警去抖)
--- opts.jitter: 0~0.5, 每轮在目标间隔上加 ±jitter 比例随机偏移 (默认 0.15; false 关闭)
--- opts.autoBackoff: 为 true 时, 本轮耗时超过 max(interval,0.25) 自动退避 min(cost,8) 秒 (默认关, 避免慢查询挡住后续购买)
--- opts.wakeIf: function()->boolean 退避期间若返回 true 立即醒来跑一轮
--- 实际等待 = max(目标间隔 - 本轮耗时, 50ms), 避免慢 Invoke 后再叠一整段间隔
--- 性能契约: fn 是轮询体, 高频需求请改事件连接; fn 内禁止全场景扫描等重活
function TheKing.StartLoop(name, interval, fn, opts)
    TheKing.StopLoop(name)
    opts = (type(opts) == "table") and opts or {}
    local jitter = (opts.jitter == false) and 0 or (opts.jitter or 0.15)
    if jitter > 0.5 then jitter = 0.5 end
    interval = math.max(interval or 0.5, MIN_LOOP_INTERVAL)
    local autoBackoff = opts.autoBackoff == true
    local entry = { alive = true, idleUntil = 0 } -- 先置位再 spawn: task.spawn 会立即执行到首个 yield
    entry.thread = task.spawn(function()
        while entry.alive do
            local idleUntil = entry.idleUntil or 0
            if os.clock() < idleUntil then
                local woke = false
                if type(opts.wakeIf) == "function" then
                    local wok, wake = pcall(opts.wakeIf)
                    woke = wok and wake == true
                end
                if woke then
                    entry.idleUntil = 0
                else
                    local remainIdle = idleUntil - os.clock()
                    if remainIdle > 0 then
                        task.wait(math.min(remainIdle, 0.5))
                    end
                end
            end
            if entry.alive and os.clock() >= (entry.idleUntil or 0) then
                activeLoopName = name
                local t0 = os.clock()
                local fnOk, err = pcall(fn)
                activeLoopName = nil
                if not fnOk then
                    logWarn("loop '" .. name .. "' 异常: " .. tostring(err))
                end
                local cost = os.clock() - t0
                if cost > SLOW_LOOP_THRESHOLD then
                    local last = slowWarnAt[name] or 0
                    if os.clock() - last >= SLOW_WARN_GAP then
                        slowWarnAt[name] = os.clock()
                        logWarn(string.format("loop '%s' 单次耗时 %.0fms (>%.0fms), 考虑降频/缓存/拆分",
                            name, cost * 1000, SLOW_LOOP_THRESHOLD * 1000))
                    end
                end
                if autoBackoff and cost > math.max(interval, 0.25) then
                    entry.idleUntil = os.clock() + math.min(cost, 8)
                end
                local waitTime = interval * (1 + (math.random() * 2 - 1) * jitter)
                local remain = waitTime - cost
                if remain < MIN_LOOP_INTERVAL then
                    remain = MIN_LOOP_INTERVAL
                end
                task.wait(remain)
            end
        end
    end)
    loops[name] = entry
end

--- 让当前或指定循环歇一段时间; seconds<=0 立即醒来
function TheKing.Backoff(seconds, name)
    name = name or activeLoopName
    local e = name and loops[name]
    if not e then
        return
    end
    seconds = tonumber(seconds) or 0
    if seconds <= 0 then
        e.idleUntil = 0
    else
        e.idleUntil = os.clock() + seconds
    end
end

--- 停止单个循环
function TheKing.StopLoop(name)
    local e = loops[name]
    if e then
        e.alive = false
        pcall(task.cancel, e.thread)
        loops[name] = nil
    end
    slowWarnAt[name] = nil
    if name == "antiafk" then
        antiAfkActive = false
    end
end

--- 登记事件连接, Destroy 时统一断连
function TheKing.AddConnection(conn)
    table.insert(connections, conn)
    return conn
end

--- 全停 (设置页 StopAll 按钮 / 功能互斥时用)
--- 迭代安全性: StopLoop 删除的是 pairs 当前迭代键, Lua next 语义保证此写法定义良好
function TheKing.StopAll()
    for name in pairs(loops) do
        TheKing.StopLoop(name)
    end
    if TheKing.UnbindStepped then
        local names = {}
        for name in pairs(namedConns) do
            names[#names + 1] = name
        end
        for _, name in ipairs(names) do
            TheKing.UnbindStepped(name)
        end
    end
end

--- 状态文本差分刷新: 内容没变就不 Set (杜绝每帧 SetText 引发的 UI 重排掉帧)
--- para 是 Paragraph 元素句柄; 返回是否真的更新了
function TheKing.UpdateStatus(para, title, desc)
    if not para then
        return false
    end
    -- 元素可能已被销毁 (热替换后旧循环引用旧 Paragraph): SetTitle/SetDesc 可能为 nil,
    -- 静默返回避免旧循环每周期刷 "attempt to call a nil value"
    if type(para.SetTitle) ~= "function" or type(para.SetDesc) ~= "function" then
        return false
    end
    local updated = false
    if para._tk_title ~= title then
        para._tk_title = title
        pcall(para.SetTitle, para, title)
        updated = true
    end
    if para._tk_desc ~= desc then
        para._tk_desc = desc
        pcall(para.SetDesc, para, desc)
        updated = true
    end
    return updated
end

-- ==================== 配置持久化 ====================
-- 元素声明 Flag = "唯一名" 即纳入; 关窗/卸载自动保存, 启动后自动恢复 (挂机功能 reload 无需重新勾选)
-- v2.0.9: Save 前分段预建 Rayfield 配置目录 (Configurations/<folder>/) —
--   Potassium 下 Rayfield 内部 makefolder 建多级目录失败导致 Save 静默无效 (Toggle 从不持久化)
do
    local function ensureRfConfigDir()
        local dirName = "TheKing_" .. safeFolder
        pcall(function()
            if not isfolder("Configurations") then
                makefolder("Configurations")
            end
        end)
        pcall(function()
            local full = "Configurations/" .. dirName
            if not isfolder(full) then
                makefolder(full)
            end
        end)
    end
    -- 加载即建目录: Rayfield autoSave 不经 SaveConfig, 目录必须在 CreateWindow 后立即就位
    ensureRfConfigDir()
    if rfWindow then
        function TheKing.SaveConfig()
            ensureRfConfigDir()
            pcall(function()
                rfWindow:Save()
            end)
        end
        function TheKing.LoadConfig()
            pcall(function()
                rfWindow:Load()
            end)
            TheKing.PinNativeToggleKey()
        end
    else
    local cmOk, configManager = pcall(function() return Window.ConfigManager end)
    local created = false
    if cmOk and configManager then
        local cok, cfgResult = pcall(function()
            return configManager:CreateConfig("main")
        end)
        if cok and cfgResult then
            TheKing.Config = cfgResult
            created = true
        end
    end

    if created then
        function TheKing.SaveConfig()
            pcall(TheKing.Config.Save, TheKing.Config)
        end
        function TheKing.LoadConfig()
            pcall(TheKing.Config.Load, TheKing.Config)
        end
        pcall(Window.OnClose, Window, TheKing.SaveConfig) -- 正常关窗自动存
        -- Load 不自动执行: 必须等业务侧 Register 完元素后手动调用 TheKing.LoadConfig(),
        -- 否则 Load 时无注册元素, 恢复必然为空 (Heroes RNG 首飞实测踩坑)
    else
        -- 旧版 WindUI 无配置系统: 静默降级为空操作
        function TheKing.SaveConfig() end
        function TheKing.LoadConfig() end
    end
    end
end

--- 统一通知封装
function TheKing.Notify(cfg)
    if muteAllNotify then
        return
    end
    cfg = cfg or {}
    if rfWindow then
        pcall(function()
            rfWindow:Notify({
                title = cfg.Title or "TheKing HUB",
                content = cfg.Content,
                icon = resolveTabIcon(cfg.Icon),
                duration = cfg.Duration or 3,
            })
        end)
        return
    end
    if WindUI then
        WindUI:Notify({
            Title = cfg.Title or "TheKing HUB",
            Content = cfg.Content,
            Icon = cfg.Icon or "info",
            Duration = cfg.Duration or 3,
        })
        return
    end
    logInfo((cfg.Title or "通知") .. ": " .. tostring(cfg.Content or ""))
end

--- 确认对话框封装
function TheKing.Confirm(cfg)
    return Window:Dialog({
        Title = cfg.Title or "确认操作",
        Content = cfg.Content or "",
        Buttons = {
            { Title = "取消", Variant = "Secondary", Callback = function() end },
            { Title = "确定", Variant = "Primary", Callback = function()
                local fn = cfg.OnConfirm
                if type(fn) == "function" then
                    task.defer(fn)
                end
            end },
        },
    })
end

--- 危险操作安全封装 (L2 对抗手段标配):
--- pcall 执行 fn; 失败时结构化告警
--- opts.fuse: true/"loop" 停当前循环 (不在循环里则 StopAll); "all" 全停
--- 用法: TheKing.Guard(function() ... end, "钓鱼抢发", { fuse = true })
function TheKing.Guard(fn, label, opts)
    opts = (type(opts) == "table") and opts or {}
    local ok2, err = pcall(fn)
    if ok2 then return true end
    local fuse = opts.fuse
    local fuseAll = fuse == "all"
    local fuseLoop = fuse == true or fuse == "loop"
    local fuseNote = ""
    if fuseAll then
        fuseNote = " -> 已熔断全部循环"
    elseif fuseLoop then
        fuseNote = " -> 已停止当前循环"
    end
    logWarn(string.format("[守卫] '%s' 失败: %s%s",
        tostring(label), tostring(err), fuseNote))
    if fuseAll then
        TheKing.StopAll()
        pcall(TheKing.Notify, { Title = "功能异常", Content = tostring(label) .. " 已全部停止, 请查看控制台", Icon = "alert-triangle" })
    elseif fuseLoop then
        if activeLoopName then
            TheKing.StopLoop(activeLoopName)
        else
            TheKing.StopAll()
        end
        pcall(TheKing.Notify, { Title = "功能异常", Content = tostring(label) .. " 已停止, 请查看控制台", Icon = "alert-triangle" })
    end
    return false
end

-- ==================== 统一发包层 (v1.5.0) ====================
-- 设计: pcall 包裹防断连炸循环; Invoke 留痕要求调用方在 intel.md 记录调用处语义
-- 用法:
--   TheKing.Fire(remote, a, b)            -> FireServer, 出错返回 false+warn
--   local ok, r = TheKing.Invoke(remote)  -> InvokeServer, 出错返回 false+warn
function TheKing.Fire(remote, ...)
    if type(remote) ~= "userdata" and type(remote) ~= "table" then
        logWarn("[发包] 非法 remote 类型: " .. type(remote))
        return false
    end
    local ok, err = pcall(function(...) remote:FireServer(...) end, ...)
    if not ok then
        logWarn("[发包] FireServer 失败: " .. tostring(err))
        return false
    end
    return true
end

function TheKing.Invoke(remote, ...)
    if type(remote) ~= "userdata" and type(remote) ~= "table" then
        logWarn("[发包] 非法 remote 类型: " .. type(remote))
        return false, nil
    end
    local ok, result = pcall(function(...) return remote:InvokeServer(...) end, ...)
    if not ok then
        logWarn("[发包] InvokeServer 失败: " .. tostring(result))
        return false, nil
    end
    return true, result
end

-- ==================== 登记式替换 (v1.5.0) ====================
-- 设计: hook 只挂一次, Destroy 自动逆序还原; 防叠加残留
-- 用法: local orig = TheKing.Swap(Network, "FireServer", myWrapper)
--   Swap 保存 {obj, key, original}; Destroy 按栈逆序还原
-- 业务侧不需要再手写 origFireServer 保存/恢复链 (heroes-rng 手写版本可删)
local swapStack = {} -- { {obj, key, original} }
function TheKing.Swap(obj, key, newValue)
    if type(obj) ~= "table" then
        logWarn("[替换] 目标非表: " .. tostring(key))
        return nil
    end
    local original = rawget(obj, key)
    if original == nil then
        logWarn("[替换] 字段不存在: " .. tostring(key))
        return nil
    end
    table.insert(swapStack, { obj = obj, key = key, original = original })
    rawset(obj, key, newValue)
    return original
end

-- ==================== 防挂机 (v1.5.0, L2) ====================
-- Roblox 官方空闲踢出 ~20 分钟; 每 4 分钟 (±15% 抖动, StartLoop 自带) 一次假输入续命
-- 走 StartLoop("antiafk"): 挂机循环名约定, StopAll/Destroy 自动覆盖, 不需要额外清理钩子
-- L2 手段: 业务侧启用时按 AGENTS.md 在 intel.md「L2 手段登记」归档
local ANTI_AFK_INTERVAL = 240

--- 启用防挂机 (已启用则幂等跳过); 返回是否生效
function TheKing.EnableAntiAfk()
    if antiAfkActive then
        return true
    end
    local vuOk, vu = pcall(function() return game:GetService("VirtualUser") end)
    if not vuOk or not vu then
        logWarn("[防挂机] VirtualUser 不可用, 启用失败")
        return false
    end
    TheKing.StartLoop("antiafk", ANTI_AFK_INTERVAL, function()
        pcall(function()
            vu:CaptureController()
            vu:ClickButton1(Vector2.new())
        end)
    end)
    antiAfkActive = true
    logInfo("[防挂机] 已启用 (" .. ANTI_AFK_INTERVAL .. "s ±15% 假输入)")
    return true
end

--- 停用防挂机
function TheKing.DisableAntiAfk()
    if not antiAfkActive then
        return
    end
    TheKing.StopLoop("antiafk")
    antiAfkActive = false
    logInfo("[防挂机] 已停用")
end

--- 当前防挂机状态
function TheKing.AntiAfkActive()
    return antiAfkActive
end

--- 把相关状态收进一张表, 方法挂表上 (function T.foo), 少占 enclosing 函数的 local 寄存器
function TheKing.Pack(seed)
    return (type(seed) == "table") and seed or {}
end

-- ==================== 跨游戏回收的基建 (v2.2.0) ====================
-- 来源: 地下城 PREF/移速打回、清洁世界慢 Invoke、钓鱼节奏 Heartbeat、Knit await、钾 getupvalue 越界

--- 键值偏好 (Rayfield Flag 在钾上经常不落盘). candidates 多个路径轮询读写.
--- 返回 { Data, Get, Set, Save, Flush }
function TheKing.OpenPrefs(candidates, opts)
    opts = (type(opts) == "table") and opts or {}
    local debounce = tonumber(opts.debounce) or 0.5
    local data = {}
    local paths = {}
    if type(candidates) == "string" then
        paths[1] = candidates
    elseif type(candidates) == "table" then
        for i, p in ipairs(candidates) do
            paths[i] = p
        end
    end
    if #paths == 0 then
        paths[1] = "theking-prefs.txt"
    end
    local file = paths[1]
    local delayT = nil
    local function parse(raw)
        if type(raw) ~= "string" or raw == "" then
            return
        end
        for line in (raw .. "\n"):gmatch("([^\n]+)\n") do
            local k, v = line:match("^([%w_]+)=(.-)$")
            if k and v then
                v = v:gsub("\r", ""):gsub("^%s+", ""):gsub("%s+$", "")
                if v ~= "" then
                    local n = tonumber(v)
                    data[k] = n or v
                end
            end
        end
    end
    for _, p in ipairs(paths) do
        local ok, raw = pcall(readfile, p)
        if ok and type(raw) == "string" and raw ~= "" then
            file = p
            parse(raw)
            break
        end
    end
    local function flush()
        local parts = {}
        for k, v in pairs(data) do
            parts[#parts + 1] = tostring(k) .. "=" .. tostring(v)
        end
        local body = table.concat(parts, "\n")
        if pcall(writefile, file, body) then
            return true
        end
        for _, p in ipairs(paths) do
            local folder = p:match("^(.*)/[^/]+$")
            if folder and type(makefolder) == "function" then
                pcall(makefolder, folder)
            end
            if pcall(writefile, p, body) then
                file = p
                return true
            end
        end
        return false
    end
    local function save()
        if delayT then
            pcall(task.cancel, delayT)
        end
        delayT = task.delay(debounce, function()
            delayT = nil
            flush()
        end)
    end
    TheKing.OnCleanup(function()
        if delayT then
            pcall(task.cancel, delayT)
            delayT = nil
        end
        flush()
    end)
    local P = { Data = data }
    function P.Get(key, default)
        local v = data[key]
        if v == nil then
            return default
        end
        return v
    end
    function P.Set(key, val)
        data[key] = val
        save()
    end
    function P.Save()
        save()
    end
    function P.Flush()
        if delayT then
            pcall(task.cancel, delayT)
            delayT = nil
        end
        flush()
    end
    return P
end

--- 帧级连接 (钓鱼节奏 / 移速回写 / 脚底圈). StartLoop 有 50ms 下限, 对不齐节拍时用这个.
--- kind: "heartbeat"(默认) | "render". StopAll / UnbindStepped(name) 会断.
function TheKing.UnbindStepped(name)
    local c = namedConns[name]
    if c then
        pcall(function()
            c:Disconnect()
        end)
        namedConns[name] = nil
    end
end
function TheKing.BindStepped(name, kind, fn)
    TheKing.UnbindStepped(name)
    if type(fn) ~= "function" then
        return
    end
    local rs = game:GetService("RunService")
    local sig = rs.Heartbeat
    if kind == "render" or kind == "RenderStepped" then
        sig = rs.RenderStepped
    end
    local conn = sig:Connect(function(...)
        pcall(fn, ...)
    end)
    namedConns[name] = conn
    TheKing.AddConnection(conn)
    return conn
end

--- 游戏会把属性打回时用: 每帧 + Changed 立刻写成想要的值. 关功能调 UnbindStepped(name).
--- getInst / getWanted 可以是实例/值, 也可以是函数.
function TheKing.Hold(name, getInst, prop, getWanted)
    TheKing.BindStepped(name, "heartbeat", function()
        local inst = getInst
        if type(getInst) == "function" then
            local ok, v = pcall(getInst)
            inst = ok and v or nil
        end
        if not inst then
            return
        end
        local want = getWanted
        if type(getWanted) == "function" then
            local ok, v = pcall(getWanted)
            if not ok then
                return
            end
            want = v
        end
        if want == nil then
            return
        end
        pcall(function()
            if inst[prop] ~= want then
                inst[prop] = want
            end
        end)
    end)
end

--- Knit / Promise: 表上有 await 就等, 返回 await 的返回值; 否则原样返回 true, p
function TheKing.Await(p)
    if type(p) == "table" and type(p.await) == "function" then
        local ok, a, b = pcall(function()
            return p:await()
        end)
        if not ok then
            logWarn("[Await] " .. tostring(a))
            return false, a
        end
        return a, b
    end
    return true, p
end

--- StartLoop 里会 yield 的活 (Invoke / 抛物线) 丢进新线程, 避免拖死整轮
function TheKing.DeferTick(fn)
    if type(fn) ~= "function" then
        return
    end
    task.spawn(function()
        TheKing.Guard(fn, "DeferTick")
    end)
end

--- debug.getupvalue 越界在钾上会硬报错
function TheKing.Upvalue(fn, idx)
    local dbg = debug
    if type(dbg) ~= "table" or type(dbg.getupvalue) ~= "function" then
        return nil
    end
    local ok, a, b = pcall(dbg.getupvalue, fn, idx)
    if not ok then
        return nil
    end
    return a, b
end

-- ==================== 2D / 3D 绘制 (v2.1.0) ====================
-- 教训: Potassium Drawing.new 经常隐形并疑似崩客户端; 开源 ESP 的 Drawing 路线在本引擎禁用。
-- 2D 走 ScreenGui Frame/Text 对象池 (每帧 begin/finish); 3D 走 HandleAdornment / Highlight / Billboard。
-- 整段 IIFE, 不占库主块寄存器。API 见 docs/draw-api.md
TheKing.Draw = (function()
    local D = {}
    local overlay, folder3d
    local pools = {
        line = { items = {}, used = 0, last = 0 },
        rect = { items = {}, used = 0, last = 0 },
        text = { items = {}, used = 0, last = 0 },
        dot = { items = {}, used = 0, last = 0 },
    }
    local persist = {}
    local paintConn = nil
    local destroyed = false

    local function hudParent()
        local ok, h = false, nil
        if type(gethui) == "function" then
            ok, h = pcall(gethui)
            if ok and h then
                return h
            end
        end
        local lp = game:GetService("Players").LocalPlayer
        if lp then
            local pg = lp:FindFirstChild("PlayerGui") or lp:WaitForChild("PlayerGui", 5)
            if pg then
                return pg
            end
        end
        local ok2, core = pcall(function()
            return game:GetService("CoreGui")
        end)
        if ok2 then
            return core
        end
        return lp and lp:FindFirstChild("PlayerGui")
    end

    local function ensureOverlay()
        if destroyed then
            return nil
        end
        if overlay and overlay.Parent then
            return overlay
        end
        local parent = hudParent()
        if not parent then
            return nil
        end
        local gui = Instance.new("ScreenGui")
        gui.Name = "TheKing_Draw"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.DisplayOrder = 999
        gui.Parent = parent
        overlay = gui
        local fold = Instance.new("Folder")
        fold.Name = "World3D"
        fold.Parent = gui
        folder3d = fold
        return gui
    end

    local function take2d(kind, factory)
        local gui = ensureOverlay()
        if not gui then
            return nil
        end
        local p = pools[kind]
        p.used = p.used + 1
        local inst = p.items[p.used]
        if not (inst and inst.Parent) then
            inst = factory(gui)
            p.items[p.used] = inst
        end
        return inst
    end

    local function mkLine(parent)
        local f = Instance.new("Frame")
        f.BorderSizePixel = 0
        f.AnchorPoint = Vector2.new(0, 0.5)
        f.Visible = false
        f.Parent = parent
        return f
    end
    local function mkRect(parent)
        local f = Instance.new("Frame")
        f.BorderSizePixel = 0
        f.Visible = false
        f.Parent = parent
        return f
    end
    local function mkText(parent)
        local t = Instance.new("TextLabel")
        t.BackgroundTransparency = 1
        t.BorderSizePixel = 0
        t.AnchorPoint = Vector2.new(0.5, 0.5)
        t.Font = Enum.Font.GothamBold
        t.TextStrokeTransparency = 0
        t.TextStrokeColor3 = Color3.new(0, 0, 0)
        t.Visible = false
        t.Parent = parent
        return t
    end
    local function mkDot(parent)
        local f = Instance.new("Frame")
        f.BorderSizePixel = 0
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = f
        f.Visible = false
        f.Parent = parent
        return f
    end

    function D.begin()
        for _, p in pairs(pools) do
            p.used = 0
        end
        ensureOverlay()
    end

    function D.finish()
        for _, p in pairs(pools) do
            for i = p.used + 1, p.last do
                local inst = p.items[i]
                if inst then
                    inst.Visible = false
                end
            end
            p.last = p.used
        end
    end

    function D.line(x1, y1, x2, y2, color, thickness, trans)
        local f = take2d("line", mkLine)
        if not f then
            return
        end
        local dx, dy = x2 - x1, y2 - y1
        local len = math.sqrt(dx * dx + dy * dy)
        if len < 1 then
            len = 1
        end
        local th = math.max(1, thickness or 1)
        f.BackgroundColor3 = color or Color3.new(1, 1, 1)
        f.BackgroundTransparency = trans or 0
        f.Rotation = math.deg(math.atan2(dy, dx))
        f.Size = UDim2.fromOffset(len, th)
        f.Position = UDim2.fromOffset(x1, y1 - th / 2)
        f.Visible = true
    end

    function D.rect(x, y, w, h, color, trans)
        local f = take2d("rect", mkRect)
        if not f then
            return
        end
        f.BackgroundColor3 = color or Color3.new(1, 1, 1)
        f.BackgroundTransparency = trans or 0
        f.Size = UDim2.fromOffset(math.max(1, w), math.max(1, h))
        f.Position = UDim2.fromOffset(x, y)
        f.Visible = true
    end

    function D.dot(x, y, size, color, trans)
        local f = take2d("dot", mkDot)
        if not f then
            return
        end
        local s = math.max(2, size or 6)
        f.BackgroundColor3 = color or Color3.new(1, 1, 1)
        f.BackgroundTransparency = trans or 0
        f.Size = UDim2.fromOffset(s, s)
        f.Position = UDim2.fromOffset(x, y)
        f.Visible = true
    end

    function D.text(x, y, str, opts)
        opts = opts or {}
        local t = take2d("text", mkText)
        if not t then
            return
        end
        t.Text = tostring(str or "")
        t.TextColor3 = opts.Color or Color3.new(1, 1, 1)
        t.TextTransparency = opts.Transparency or 0
        t.TextSize = opts.Size or 14
        t.AnchorPoint = opts.Center == false and Vector2.new(0, 0) or Vector2.new(0.5, 0.5)
        t.Position = UDim2.fromOffset(x, y)
        t.Visible = true
    end

    local function project(pos)
        local cam = workspace.CurrentCamera
        if not (cam and pos) then
            return 0, 0, false, 0
        end
        local v, on = cam:WorldToViewportPoint(pos)
        if typeof(v) ~= "Vector3" then
            return 0, 0, false, 0
        end
        if on == nil then
            on = v.Z > 0
        end
        return v.X, v.Y, on and v.Z > 0, v.Z
    end

    function D.worldToScreen(pos)
        return project(pos)
    end

    function D.ring(center, radius, color, trans, opts)
        local cam = workspace.CurrentCamera
        if not (cam and center and radius and radius > 0) then
            return
        end
        opts = opts or {}
        local yOff = opts.yOff or 0
        local origin = center + Vector3.new(0, yOff, 0)
        local x0, y0, vis0 = project(origin)
        if not vis0 then
            return
        end
        local sumR, nR = 0, 0
        for k = 0, 3 do
            local a = k * math.pi / 2
            local sx, sy, on = project(origin + Vector3.new(math.cos(a) * radius, 0, math.sin(a) * radius))
            if on then
                sumR = sumR + ((sx - x0) ^ 2 + (sy - y0) ^ 2) ^ 0.5
                nR = nR + 1
            end
        end
        local scrR = nR > 0 and (sumR / nR) or 30
        if scrR < (opts.minScr or 4) then
            return
        end
        local segs = math.clamp(math.floor(scrR / (opts.segPx or 7)), 16, opts.maxSegs or 220)
        local col = color or Color3.new(1, 0.2, 0.2)
        local tr = trans or 0.35
        local th = opts.thickness or 2
        local prevX, prevY, prevOn = nil, nil, false
        for i = 0, segs do
            local a = (i / segs) * math.pi * 2
            local sx, sy, on = project(origin + Vector3.new(math.cos(a) * radius, 0, math.sin(a) * radius))
            if prevOn and on then
                D.line(prevX, prevY, sx, sy, col, th, tr)
            end
            prevX, prevY, prevOn = sx, sy, on
        end
    end

    local function partOf(inst)
        if not inst then
            return nil
        end
        if inst:IsA("BasePart") then
            return inst
        end
        if inst:IsA("Model") then
            return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
        end
        return nil
    end

    local function take3d(key, className)
        ensureOverlay()
        local o = persist[key]
        if o and o.Parent and o.ClassName == className then
            return o
        end
        if o then
            pcall(function()
                o:Destroy()
            end)
        end
        o = Instance.new(className)
        o.Name = "TK_" .. tostring(key)
        persist[key] = o
        return o
    end

    function D.disc(key, adornee, radius, color, trans, yOff)
        local a = take3d(key, "CylinderHandleAdornment")
        if not folder3d then
            return
        end
        a.AlwaysOnTop = true
        a.ZIndex = 10
        a.Height = 0.12
        a.Parent = folder3d
        local part = partOf(adornee)
        if not (part and radius and radius > 0.2) then
            a.Visible = false
            return
        end
        a.Adornee = part
        a.Radius = radius
        a.Color3 = color or Color3.new(1, 1, 1)
        a.Transparency = trans or 0.4
        a.CFrame = CFrame.new(0, yOff or -2.45, 0) * CFrame.Angles(math.pi / 2, 0, 0)
        a.Visible = true
    end

    function D.box(key, adornee, size, color, trans)
        local a = take3d(key, "BoxHandleAdornment")
        if not folder3d then
            return
        end
        a.AlwaysOnTop = true
        a.ZIndex = 8
        a.Parent = folder3d
        local part = partOf(adornee)
        if not part then
            a.Visible = false
            return
        end
        a.Adornee = part
        a.Size = size or part.Size
        a.Color3 = color or Color3.new(1, 1, 1)
        a.Transparency = trans or 0.5
        a.Visible = true
    end

    function D.sphere(key, adornee, radius, color, trans)
        local a = take3d(key, "SphereHandleAdornment")
        if not folder3d then
            return
        end
        a.AlwaysOnTop = true
        a.ZIndex = 8
        a.Parent = folder3d
        local part = partOf(adornee)
        if not (part and radius) then
            a.Visible = false
            return
        end
        a.Adornee = part
        a.Radius = radius
        a.Color3 = color or Color3.new(1, 1, 1)
        a.Transparency = trans or 0.5
        a.Visible = true
    end

    function D.highlight(key, inst, fill, outline, fillT, outlineT)
        local h = persist[key]
        if not (h and h.Parent and h:IsA("Highlight")) then
            if h then
                pcall(function()
                    h:Destroy()
                end)
            end
            h = Instance.new("Highlight")
            h.Name = "TK_" .. tostring(key)
            persist[key] = h
        end
        if not (inst and inst.Parent) then
            h.Enabled = false
            return
        end
        h.Parent = inst
        h.Adornee = inst
        h.FillColor = fill or Color3.fromRGB(255, 200, 40)
        h.OutlineColor = outline or Color3.new(1, 1, 1)
        h.FillTransparency = fillT or 0.65
        h.OutlineTransparency = outlineT or 0.2
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Enabled = true
    end

    function D.billboard(key, adornee, str, opts)
        opts = opts or {}
        local bb = persist[key]
        if not (bb and bb.Parent and bb:IsA("BillboardGui")) then
            if bb then
                pcall(function()
                    bb:Destroy()
                end)
            end
            bb = Instance.new("BillboardGui")
            bb.Name = "TK_" .. tostring(key)
            bb.AlwaysOnTop = true
            bb.Size = UDim2.fromOffset(opts.Width or 80, opts.Height or 24)
            bb.StudsOffset = Vector3.new(0, opts.StudsY or 2.4, 0)
            local t = Instance.new("TextLabel")
            t.Name = "T"
            t.BackgroundTransparency = 1
            t.Size = UDim2.fromScale(1, 1)
            t.Font = Enum.Font.GothamBold
            t.TextScaled = true
            t.TextStrokeTransparency = 0.2
            t.Parent = bb
            persist[key] = bb
        end
        local part = partOf(adornee)
        if not part then
            bb.Enabled = false
            return
        end
        bb.Adornee = part
        bb.Parent = part
        local lab = bb:FindFirstChild("T")
        if lab then
            lab.Text = tostring(str or "")
            lab.TextColor3 = opts.Color or Color3.new(1, 1, 1)
        end
        bb.Enabled = true
    end

    function D.modelBox(model, color, trans)
        if not model then
            return
        end
        local ok, cf, sz = pcall(function()
            return model:GetBoundingBox()
        end)
        if not ok or not cf then
            return
        end
        local cam = workspace.CurrentCamera
        if not cam then
            return
        end
        local hx, hy, hz = sz.X / 2, sz.Y / 2, sz.Z / 2
        local corners = {
            Vector3.new(-hx, -hy, -hz), Vector3.new(hx, -hy, -hz),
            Vector3.new(hx, -hy, hz), Vector3.new(-hx, -hy, hz),
            Vector3.new(-hx, hy, -hz), Vector3.new(hx, hy, -hz),
            Vector3.new(hx, hy, hz), Vector3.new(-hx, hy, hz),
        }
        local pts = {}
        for i = 1, 8 do
            local px, py, on = project(cf:PointToWorldSpace(corners[i]))
            pts[i] = { px, py, on }
        end
        local edges = { {1,2},{2,3},{3,4},{4,1},{5,6},{6,7},{7,8},{8,5},{1,5},{2,6},{3,7},{4,8} }
        local col = color or Color3.new(1, 1, 1)
        local tr = trans or 0.2
        for _, e in ipairs(edges) do
            local a, b = pts[e[1]], pts[e[2]]
            if a[3] and b[3] then
                D.line(a[1], a[2], b[1], b[2], col, 1, tr)
            end
        end
    end

    function D.hide(key)
        local o = persist[key]
        if not o then
            return
        end
        if o:IsA("Highlight") or o:IsA("BillboardGui") then
            o.Enabled = false
        else
            o.Visible = false
        end
    end

    function D.onPaint(fn)
        if paintConn then
            pcall(function()
                paintConn:Disconnect()
            end)
            paintConn = nil
        end
        if type(fn) ~= "function" then
            return
        end
        local rs = game:GetService("RunService")
        paintConn = rs.RenderStepped:Connect(function()
            D.begin()
            local ok, err = pcall(fn)
            D.finish()
            if not ok then
                logWarn("[绘制] onPaint: " .. tostring(err))
            end
        end)
        TheKing.AddConnection(paintConn)
    end

    function D.destroy()
        destroyed = true
        if paintConn then
            pcall(function()
                paintConn:Disconnect()
            end)
            paintConn = nil
        end
        for _, o in pairs(persist) do
            pcall(function()
                o:Destroy()
            end)
        end
        table.clear(persist)
        for _, p in pairs(pools) do
            for _, inst in ipairs(p.items) do
                pcall(function()
                    inst:Destroy()
                end)
            end
            p.items = {}
            p.used = 0
            p.last = 0
        end
        if overlay then
            pcall(function()
                overlay:Destroy()
            end)
            overlay = nil
            folder3d = nil
        end
        -- 保持 destroyed=true: 本实例已死, 禁止 begin 再造一层; 热替换由新 lib 实例重建
    end

    return D
end)()

--- 销毁: 存档 -> 全停循环 -> 业务清理 -> 断连 -> 软关窗 -> 注销登记
--- opts.hotSwap: 热替换最小 teardown (不 Save/不扫 UI, 由新实例接管)
--- opts.skipSave: 卸载时跳过 SaveConfig (对话框栈内写配置易崩)
--- opts.detach: true 时 WindUI ScreenGui 额外 Parent=nil (Potassium 默认勿用)
function TheKing.Destroy(opts)
    opts = type(opts) == "table" and opts or {}
    if type(registry[GameName]) == "function" and registry[GameName] ~= TheKing.Destroy then
        return
    end

    local function runCleanupAndDraw()
        for i = #cleanupFns, 1, -1 do
            pcall(cleanupFns[i])
        end
        table.clear(cleanupFns)
        pcall(function()
            TheKing.Draw.destroy()
        end)
    end

    if opts.hotSwap then
        pcall(stopRfBrandMotion)
        pcall(TheKing.StopAll)
        runCleanupAndDraw()
        for _, conn in ipairs(connections) do
            pcall(function() conn:Disconnect() end)
        end
        table.clear(connections)
        -- Rayfield 每次 CreateWindow 都是新层; 只 Enabled=false 会留下旧窗, 重跑就叠两个 HUB
        pcall(function()
            eachOwnWindGui(function(gui)
                gui:Destroy()
            end)
            rfScreenGui = nil
        end)
        registry[GameName] = nil
        return
    end
    pcall(TheKing.DisarmTeleportReload)

    if not opts.skipSave then
        pcall(TheKing.SaveConfig)
    end
    pcall(TheKing.StopAll)
    pcall(stopRfBrandMotion)
    for i = #swapStack, 1, -1 do
        local s = swapStack[i]
        pcall(function() rawset(s.obj, s.key, s.original) end)
    end
    table.clear(swapStack)
    runCleanupAndDraw()
    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(connections)
    if opts.purgeUi then
        pcall(function()
            eachOwnWindGui(function(gui)
                gui:Destroy()
            end)
            if rfScreenGui then
                rfScreenGui:Destroy()
                rfScreenGui = nil
            end
        end)
    else
        softHideOwnWindUi(opts.detach == true)
    end
    registry[GameName] = nil
end

-- ==================== 注册到游戏隔离表 ====================
-- 本实例的销毁入口暴露给下一个同类脚本 (热调试协议), 异游戏实例不受影响
registry[GameName] = TheKing.Destroy

-- 冻结公共接口: 防业务脚本误赋值覆盖引擎方法 (TheKing.StartLoop = xxx 这类手滑直接报错暴露)
if type(table.freeze) == "function" then
    pcall(table.freeze, TheKing)
end

return TheKing
