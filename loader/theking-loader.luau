--[[
    TheKing Loader [0.9.1]
    RCWTK 引擎 Loader | 独立加载器界面 theKing Hub (不用 WindUI) | 免卡密, 加密白名单授权

    安全设计 (多层反绕过):
      L1 白名单加密: users.enc 为密文 (你看你妈妈呢+love 双特征派生), GitHub 上无人能读
      L2 失败即拒:   名单拉取失败/解密失败/解析失败 -> 一律未授权 (绝不默认放行)
      L3 注入二次校验: 注入函数内部再走一遍 checkAuth, 绕过 UI 直调注入也会被拦
      L4 退出弹窗:    未授权 -> 强制退出弹窗 (无取消路径); 当前游戏无脚本则留在 Loader 界面
      L5 混淆兜底:    Loader 本身发布时走 theKing Obf v1.1, 校验逻辑不可读

    流程:
      1. 拉 users.enc -> 解密 -> JSONDecode -> 比对当前用户名 (记录到期时间)
      2. 通过 -> 拉 manifest.json -> 按 universeId 匹配
      3. 命中 -> 拉混淆脚本 -> loadstring 注入 (注入前再校验一次)
      4. 未授权/无脚本 -> 退出弹窗

    UI (v0.6.0):
      第一 Tab「支持的游戏」: manifest 全量游戏 + 版本列表, 当前游戏标 [当前]
      第二 Tab「授权」: 当前用户 + 到期时间 (永久/YYYY-MM-DD 剩余天数)
      v0.6.1: 加载动画去除金色皇冠 logo (👑 圆形图标), 保留背景/四角长条/彩虹进度条
      v0.6.2: 到期判断改用 HTTP 响应头服务端 Date; 本地与服务端偏差 >2 天
              判为系统时间篡改 (reason=clock) 拒绝 — 防改本地时间绕过到期
      v0.6.3: 跨注入器兼容: 无 Date 头时降级本地时间校验;
              gethui 加 type 探测降级, WindUI 副本托管 Gitee 主源 (国内直连)
      v0.6.4: 跟随 lib v1.7.3 — WindUI 图标缓存 loadstring(nil) 防护 + 空串重试 + 本地缓存
      v0.6.5: 跟随 lib v1.7.4 — 补 authCdnUrls, 修复注入 authCheck 调 nil
      v0.7.0: 启动体验重做 — 阶段化真实进度+状态文案; 中心 TheKing 品牌字/呼吸环;
              L 形四角金条错峰; 欢迎字错峰缩放; 授权成功后 splash 内预拉 manifest
      v0.7.1: 跟随 lib v1.8.2 — Destroy 只关本实例 WindUI, 注入后自毁不再误关游戏 HUB UI
      v0.8.0: 主界面脱离 WindUI — 独立玻璃面板 (当前游戏卡+注入+清单+授权),
              lib Headless 不加载 WindUI, 与游戏 HUB 窗口完全隔离
      v0.8.1: 显示名 theKing Hub; 注入后点亮新创建的 WindUI 层 (兼容旧包全局 softHide)
      v0.8.2: 支持的游戏清单改为中英双语显示名
      v0.8.3: 按 universeId 识别当前游戏 (狙击场游戏厅/对局 PlaceId 不同也能注入)
      v0.8.4: 清单增加地下城战利品者 (dungeon-raiders)
      v0.9.0: 自动注入开关 (writefile 持久化); 下次开 Loader 命中清单则直注, 未适配回退界面
      v0.9.1: 清单按英文名 A-Z; 加入 Project Aura RNG 发布路由

    配置: _G.RCWTK_LOADER_CONFIG 或下方默认值 (发布前改成你自己的 GitHub 仓库)
]]

local CONFIG = _G.RCWTK_LOADER_CONFIG or {
    RepoOwner = "CheckCheat",
    RepoName = "the-king-hub",
    RepoBranch = "master",
    UsersPath = "dist/users.enc",        -- 加密白名单 (publish.py 生成)
    ManifestPath = "dist/manifest.json", -- 游戏清单
    WhiteKey = 20260831,                 -- 白名单密钥 (必须与 publish.py WHITE_KEY 一致)
}

-- ==================== 解密常量 (与 publish.py 逐字节一致) ====================
local EGG = {20320, 30475, 20320, 22920, 22920, 21602} -- 你看你妈妈呢
local LOVE = {108, 111, 118, 101}                      -- love
local YPR = {89, 111, 117, 32, 80, 108, 97, 121, 32, 82, 111, 98, 108, 111, 120} -- You Play Roblox
local SURRENDER_DAY = 19450815                          -- 日本战败日 (与 publish.py 一致)

-- ==================== 多源降级 (Gitee 优先: 国内直连稳) ====================
-- 主仓库: https://gitee.com/CheckCheat/the-king-hub (public, raw 直出, 无 CDN 缓存层)
-- 兜底: 旧 GitHub 仓库仅作灾备 (Gitee 挂了才轮到它, 版本可能落后)
local GITHUB_MIRROR = { Owner = "CheckCheats", Name = "theKing-Hub", Branch = "main" }

local function cdnUrls(path)
    local b = CONFIG.RepoBranch
    return {
        ("https://gitee.com/%s/%s/raw/%s/%s"):format(CONFIG.RepoOwner, CONFIG.RepoName, b, path),
        ("https://gitee.com/%s/%s/raw/%s/%s?raw=true"):format(CONFIG.RepoOwner, CONFIG.RepoName, b, path),
        ("https://raw.githubusercontent.com/%s/%s/%s/%s"):format(
            GITHUB_MIRROR.Owner, GITHUB_MIRROR.Name, GITHUB_MIRROR.Branch, path),
    }
end

local TheKing = loadstring(readfile("lib/theking.luau"))({
    GameName = "TheKing Loader", -- 窗口 Author 小字
    ScriptVersion = "0.9.1",
    Headless = true, -- 不加载 WindUI, Loader 自建界面
})

-- ==================== HTTP (跨注入器) ====================
local HttpService = game:GetService("HttpService")
local function httpGet(url)
    -- 主路: pcall 探测 HttpGet (不存在或报错都自然落到 request 兜底)
    local ok, body = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and type(body) == "string" then
        return body
    end
    local req = rawget(_G, "request")
        or (type(http) == "table" and type(http.request) == "function" and http.request)
    if type(req) ~= "function" then return nil end
    local ok2, resp = pcall(function() return req({ Url = url, Method = "GET" }) end)
    if not ok2 then return nil end
    return type(resp) == "table" and (resp.Body or resp.body) or resp
end

-- 授权专用 HTTP: 优先 request (拿响应头 Date 做服务端时间), 兜底 HttpGet (无响应头)
local AUTH_MONTHS = { Jan=1,Feb=2,Mar=3,Apr=4,May=5,Jun=6,Jul=7,Aug=8,Sep=9,Oct=10,Nov=11,Dec=12 }
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
local function authDateOrdinal(s)
    if type(s) ~= "string" then return nil end
    local y, m, d = s:match("(%d+)-(%d+)-(%d+)")
    if not (y and m and d) then return nil end
    local yi, mi, di = tonumber(y), tonumber(m), tonumber(d)
    if not (yi and mi and di) then return nil end
    return yi * 372 + (mi - 1) * 31 + (di - 1)
end
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

local function fetchFirst(urls)
    for _, u in ipairs(urls) do
        local ok, body = pcall(httpGet, u)
        if ok and type(body) == "string" and #body > 0 then
            -- 拒收 HTML 错误页: 网关/404 有时返回 200 + HTML 文案, 混进去会导致解密/解析全盘失败
            local head = body:sub(1, 32):lower()
            if not (head:find("<!doctype") or head:find("<html") or head:find("<head")) then
                return body
            end
        end
    end
    return nil
end

-- 白名单专用拉取: 返回 body + 服务端日期 (HTTP Date 头, 用于防本地时间篡改)
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

local function jsonDecode(s)
    if not s then return nil end
    local ok, v = pcall(function() return HttpService:JSONDecode(s) end)
    if ok then return v end
    -- 兜底: 无 JSONDecode 的环境, 用 loadstring 解析 (匿名函数包装规避类型推断)
    local ok2, chunk = pcall(function()
        return loadstring("return " .. s)
    end)
    if ok2 and type(chunk) == "function" then
        local ok3, v2 = pcall(chunk)
        if ok3 then return v2 end
    end
    return nil
end

-- ==================== 白名单解密 (字节级, 与 publish.py encode_list 互逆, 四特征派生) ====================
local function decryptUsers(encBytes)
    local k = #encBytes
    local t = {}
    for i = 1, k do
        local c = encBytes:byte(i)
        local p = i * 31 + k * 7 + EGG[(i - 1) % #EGG + 1] + LOVE[(i - 1) % #LOVE + 1]
            + YPR[(i - 1) % #YPR + 1] + SURRENDER_DAY + CONFIG.WhiteKey
        t[i] = string.char((c - p) % 256)
    end
    return table.concat(t)
end

-- ==================== 授权状态 (L2 失败即拒) ====================
local state = {
    authorized = false,   -- 唯一授权位
    checked = false,      -- 是否已尝试拉取
    reason = "pending",   -- 授权结果原因: ok / expired / unauthorized / network
    untilStr = nil,       -- 当前用户到期时间 (nil=永久), 授权 Tab 展示用
    manifest = nil,
    injected = {},
}

local LocalPlayer = game.Players.LocalPlayer
local username = LocalPlayer.Name

-- 自动注入偏好 (注入器 workspace, 下次开 Loader 直接读)
local LOADER_PREF_CANDIDATES = {
    "theking-loader/prefs.txt",
    "theking-loader-prefs.txt",
}
local LOADER_PREF_FILE = LOADER_PREF_CANDIDATES[1]
local loaderPrefs = { autoInject = false }
local function loaderPrefLoad()
    if type(readfile) ~= "function" then
        return
    end
    for _, p in ipairs(LOADER_PREF_CANDIDATES) do
        local ok, raw = pcall(readfile, p)
        if ok and type(raw) == "string" and raw ~= "" then
            LOADER_PREF_FILE = p
            for line in (raw .. "\n"):gmatch("([^\n]+)\n") do
                local k, v = line:match("^([%w_]+)=(.-)$")
                if k and v then
                    v = v:gsub("\r", ""):gsub("^%s+", ""):gsub("%s+$", "")
                    if k == "autoInject" then
                        loaderPrefs.autoInject = (v == "1" or v == "true")
                    end
                end
            end
            return
        end
    end
end
local function loaderPrefFlush()
    if type(writefile) ~= "function" then
        return
    end
    local body = "autoInject=" .. (loaderPrefs.autoInject and "1" or "0") .. "\n"
    local ok = pcall(writefile, LOADER_PREF_FILE, body)
    if ok then
        return
    end
    for _, p in ipairs(LOADER_PREF_CANDIDATES) do
        local folder = p:match("^(.*)/[^/]+$")
        if folder and type(makefolder) == "function" then
            pcall(makefolder, folder)
        end
        if pcall(writefile, p, body) then
            LOADER_PREF_FILE = p
            return
        end
    end
end
loaderPrefLoad()

-- 多层反绕过核心: 唯一授权入口。任何注入路径都必须经过它。
local function todayUtc()
    local t = os.date("!*t") -- UTC 日期, 与工具端 datetime.utcnow() 对齐
    return string.format("%04d-%02d-%02d", t.year, t.month, t.day)
end

-- 到期判断: until 缺省/空 = 永久; 否则 YYYY-MM-DD 字典序即时间序
local function isExpired(untilStr)
    if type(untilStr) ~= "string" or #untilStr == 0 then
        return false
    end
    return todayUtc() > untilStr
end

local function authFailMsg()
    if state.reason == "expired" then
        return "用户已至期限，请续约公司"
    end
    if state.reason == "clock" then
        return "检测到系统时间异常, 请校准系统时间后重试"
    end
    return "未授权"
end

local function checkAuth()
    -- 已确认过且通过 -> 直接放行 (同一会话不重复拉)
    if state.checked and state.authorized then
        return true
    end
    state.checked = true
    -- 服务端时间: 从 users.enc 响应头 Date 解析
    local body, serverDate = authFetchFirst(cdnUrls(CONFIG.UsersPath))
    if not body then
        state.reason = "network"
        return false -- L2: 拉不到名单 -> 未授权
    end
    local refDate = serverDate
    if not serverDate then
        -- 降级 (跨注入器兼容): 无 request API 的环境 (如 Potassium) 拿不到 HTTP Date 头,
        -- 回退本地 UTC 日期做到期判断 (防篡改能力弱化, 但不拒用户)
        refDate = todayUtc()
        warn("[RCWTK] 无服务端时间 (注入器无 request), 降级本地时间校验")
    else
        -- 防本地时间篡改: 本地 UTC 与服务端偏差 > 2 天 -> 拒绝
        local localDate = todayUtc()
        local diff = math.abs((authDateOrdinal(serverDate) or 0) - (authDateOrdinal(localDate) or 0))
        if diff > 2 then
            state.reason = "clock"
            return false -- 系统时间被篡改
        end
    end
    local okDec, plain = pcall(decryptUsers, body)
    if not okDec or not plain then
        state.reason = "network"
        return false -- L2: 解密失败 -> 未授权
    end
    local users = jsonDecode(plain)
    if type(users) ~= "table" then
        state.reason = "network"
        return false -- L2: 解析失败 -> 未授权
    end
    for _, u in ipairs(users) do
        -- 新格式 (whitelist.py 生成): {name=..., until=...}; 兼容旧格式: 纯字符串
        local nm = type(u) == "table" and tostring(u.name or u[1]) or tostring(u)
        if nm == username then
            -- 注意: Luau 不允许 u.until (关键字字段访问), 必须用 u["until"]
            state.untilStr = type(u) == "table" and tostring(u["until"] or "") or ""
            -- 到期判断: until 空 = 永久; 否则参考日期字典序比较 (服务端优先, 无则本地)
            if type(u) == "table" and state.untilStr ~= "" and refDate > state.untilStr then
                state.reason = "expired"
                return false -- 名单内但已到期 (以参考日期为准)
            end
            state.authorized = true
            state.reason = "ok"
            return true
        end
    end
    state.reason = "unauthorized"
    return false -- 不在名单 -> 未授权
end

-- ==================== 清单拉取 ====================
local function loadManifest()
    if state.manifest then return state.manifest end
    local body = fetchFirst(cdnUrls(CONFIG.ManifestPath))
    local m = jsonDecode(body)
    if type(m) == "table" then
        state.manifest = sortManifest(m)
    end
    return state.manifest
end

local function manifestEntryForGame()
    local m = loadManifest()
    if not m then return nil end
    local placeId = tostring(game.PlaceId)
    local universeId = tostring(game.GameId)
    for _, e in ipairs(m) do
        if e.placeId ~= nil and tostring(e.placeId) == placeId then
            return e
        end
        if e.universeId ~= nil and tostring(e.universeId) == universeId then
            return e
        end
        if type(e.placeIds) == "table" then
            for _, pid in ipairs(e.placeIds) do
                if tostring(pid) == placeId then
                    return e
                end
            end
        end
    end
    return nil
end

local function isCurrentManifestEntry(e)
    if type(e) ~= "table" then
        return false
    end
    local placeId = tostring(game.PlaceId)
    local universeId = tostring(game.GameId)
    if e.placeId ~= nil and tostring(e.placeId) == placeId then
        return true
    end
    if e.universeId ~= nil and tostring(e.universeId) == universeId then
        return true
    end
    if type(e.placeIds) == "table" then
        for _, pid in ipairs(e.placeIds) do
            if tostring(pid) == placeId then
                return true
            end
        end
    end
    return false
end

-- WindUI 每个 loadstring 各建一层, 也可能复用上次残留的同名 ScreenGui (已被 Enabled=false)
local function isWindScreenGui(g)
    if not g or not g:IsA("ScreenGui") then
        return false
    end
    if g.Name:find("WindUI") then
        return true
    end
    return g:FindFirstChild("WindUI", true) ~= nil
end

local function enableAllWindUi()
    pcall(function()
        local function revive(parent)
            if not parent then
                return
            end
            for _, g in ipairs(parent:GetChildren()) do
                if isWindScreenGui(g) then
                    g.Enabled = true
                end
            end
        end
        if type(gethui) == "function" then
            revive(gethui())
        end
        revive(LocalPlayer:FindFirstChildOfClass("PlayerGui"))
    end)
end

-- ==================== 注入 (L3: 内部二次校验, 绕 UI 直调也会被拦) ====================
local function injectScript(entry)
    -- 二次校验: 即使绕过 UI 直接调用, 未授权/已到期也进不来
    if not checkAuth() then
        return false, authFailMsg()
    end
    local key = entry.game or entry.script
    if state.injected[key] then
        return true, "已注入过"
    end
    local src = fetchFirst(cdnUrls(entry.script))
    if not src then
        return false, "拉取脚本失败 (网络或仓库路径错误)"
    end
    local chunk = loadstring(src)
    if not chunk then
        return false, "脚本编译失败"
    end
    local ok, err = pcall(chunk)
    if not ok then
        return false, "脚本执行错误: " .. tostring(err)
    end
    task.wait(0.15)
    enableAllWindUi()
    state.injected[key] = true
    return true, "注入成功"
end

local function afterInjectOk()
    enableAllWindUi()
    task.delay(0.4, enableAllWindUi)
    task.delay(1.2, function()
        TheKing.Destroy()
        enableAllWindUi()
    end)
end

-- ==================== 强制退出弹窗 (L4, 独立 ScreenGui, 不依赖 WindUI) ====================
local UserInputService = game:GetService("UserInputService")
local loaderGui = nil
local ui = {}

local CN_GAME = {
    ["clean-the-world"] = "清洁世界（Clean the WORLD!）",
    ["dungeon-quest-reborn"] = "地牢任务重生（Dungeon Quest Reborn）",
    ["dungeon-raiders"] = "地下城战利品者（Dungeon Raiders）",
    ["fisch"] = "Fisch",
    ["gakuran"] = "(学乱) Gakuran",
    ["heavy-fishing"] = "（重型钓鱼）heavy fishing",
    ["heroes-rng"] = "（英雄随机生成）Heroes RNG",
    ["project-aura-rng"] = "（项目光环）Project Aura RNG",
    ["sniper-arena"] = "（狙击竞技场）[🔥UPD] Sniper Arena",
}

-- 清单排序用英文名 (A-Z, 不区分大小写)
local EN_SORT = {
    ["clean-the-world"] = "Clean the WORLD",
    ["dungeon-quest-reborn"] = "Dungeon Quest Reborn",
    ["dungeon-raiders"] = "Dungeon Raiders",
    ["fisch"] = "Fisch",
    ["gakuran"] = "Gakuran",
    ["heavy-fishing"] = "Heavy Fishing",
    ["heroes-rng"] = "Heroes RNG",
    ["project-aura-rng"] = "Project Aura RNG",
    ["sniper-arena"] = "Sniper Arena",
}

local function parentToHui(sg)
    local okh, h = pcall(function()
        if type(gethui) == "function" then
            return gethui()
        end
        return nil
    end)
    sg.Parent = (okh and h) or LocalPlayer:WaitForChild("PlayerGui", 10)
end

local function gameTitle(id)
    return CN_GAME[id] or tostring(id)
end

local function englishSortKey(id)
    local s = EN_SORT[id] or tostring(id or "")
    return string.lower(s)
end

local function sortManifest(m)
    if type(m) ~= "table" then
        return m
    end
    table.sort(m, function(a, b)
        local ia = type(a) == "table" and a.game or a
        local ib = type(b) == "table" and b.game or b
        local ka, kb = englishSortKey(ia), englishSortKey(ib)
        if ka ~= kb then
            return ka < kb
        end
        return tostring(ia) < tostring(ib)
    end)
    return m
end

local function forceExit(title, content)
    local sg = Instance.new("ScreenGui")
    sg.Name = "TheKingLoaderExit"
    sg.DisplayOrder = 10001
    sg.IgnoreGuiInset = true
    sg.ResetOnSpawn = false
    parentToHui(sg)
    local dim = Instance.new("Frame")
    dim.Size = UDim2.fromScale(1, 1)
    dim.BackgroundColor3 = Color3.new(0, 0, 0)
    dim.BackgroundTransparency = 0.45
    dim.BorderSizePixel = 0
    dim.Parent = sg
    local panel = Instance.new("Frame")
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.Size = UDim2.fromOffset(420, 220)
    panel.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    panel.BorderSizePixel = 0
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 90, 90)
    stroke.Transparency = 0.4
    stroke.Parent = panel
    panel.Parent = sg
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Position = UDim2.fromOffset(24, 22)
    t.Size = UDim2.new(1, -48, 0, 32)
    t.Font = Enum.Font.GothamBold
    t.TextSize = 20
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.TextColor3 = Color3.fromRGB(255, 120, 120)
    t.Text = tostring(title or "无法继续")
    t.Parent = panel
    local d = Instance.new("TextLabel")
    d.BackgroundTransparency = 1
    d.Position = UDim2.fromOffset(24, 64)
    d.Size = UDim2.new(1, -48, 0, 80)
    d.Font = Enum.Font.Gotham
    d.TextSize = 15
    d.TextWrapped = true
    d.TextXAlignment = Enum.TextXAlignment.Left
    d.TextYAlignment = Enum.TextYAlignment.Top
    d.TextColor3 = Color3.fromRGB(210, 210, 210)
    d.Text = tostring(content or "")
    d.Parent = panel
    local btn = Instance.new("TextButton")
    btn.AnchorPoint = Vector2.new(0.5, 1)
    btn.Position = UDim2.new(0.5, 0, 1, -20)
    btn.Size = UDim2.fromOffset(160, 38)
    btn.BackgroundColor3 = Color3.fromRGB(255, 90, 90)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 15
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Text = "退出"
    btn.AutoButtonColor = true
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    btn.Parent = panel
    btn.Activated:Connect(function()
        sg:Destroy()
        TheKing.Destroy()
    end)
end

-- ==================== 加载动画 (Splash) v0.7.0 ====================
-- 背景淡入 -> L 形四角金条错峰 -> 中心 TheKing 品牌+呼吸环 -> 阶段化真实进度
-- -> 欢迎(错峰彩色字)/拒绝(头像+文案) -> 统一淡出; 授权成功时 splash 内预拉 manifest
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local splashGui = nil
local MIN_SPLASH_SEC = 1.35

local function getAvatarUrl(userId)
    return "https://www.roblox.com/headshot-thumbnail/image?userId="
        .. tostring(userId) .. "&width=420&height=420&format=png"
end

local function playSplash(getAuthResult, onFinish)
    if splashGui and splashGui.Parent then splashGui:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "TheKingSplash"
    sg.DisplayOrder = 9999
    sg.IgnoreGuiInset = true
    sg.ResetOnSpawn = false
    local okh, h = pcall(function()
        if type(gethui) == "function" then return gethui() end
        return nil
    end)
    sg.Parent = (okh and h) or LocalPlayer:WaitForChild("PlayerGui", 10)
    splashGui = sg

    local fadeTargets = {} -- {inst, prop} 退场统一淡出
    local function trackFade(inst, prop)
        table.insert(fadeTargets, { inst = inst, prop = prop or "BackgroundTransparency" })
    end

    -- 背景
    local bg = Instance.new("Frame")
    bg.Size = UDim2.fromScale(1, 1)
    bg.BackgroundColor3 = Color3.new(0, 0, 0)
    bg.BackgroundTransparency = 1
    bg.BorderSizePixel = 0
    bg.Parent = sg
    trackFade(bg, "BackgroundTransparency")

    -- L 形四角金条 (每角横+竖两段)
    local GOLD = Color3.fromRGB(255, 208, 70)
    local cornerParts = {}
    local function makeBar(parent, anchor, pos, size)
        local bar = Instance.new("Frame")
        bar.BackgroundColor3 = GOLD
        bar.BackgroundTransparency = 1
        bar.BorderSizePixel = 0
        bar.AnchorPoint = anchor
        bar.Position = pos
        bar.Size = size
        bar.Parent = parent
        trackFade(bar, "BackgroundTransparency")
        table.insert(cornerParts, bar)
        return bar
    end
    -- TL
    makeBar(sg, Vector2.new(0, 0), UDim2.fromOffset(18, 18), UDim2.fromOffset(0, 4))
    makeBar(sg, Vector2.new(0, 0), UDim2.fromOffset(18, 18), UDim2.fromOffset(4, 0))
    -- TR
    makeBar(sg, Vector2.new(1, 0), UDim2.new(1, -18, 0, 18), UDim2.fromOffset(0, 4))
    makeBar(sg, Vector2.new(1, 0), UDim2.new(1, -18, 0, 18), UDim2.fromOffset(4, 0))
    -- BL
    makeBar(sg, Vector2.new(0, 1), UDim2.new(0, 18, 1, -18), UDim2.fromOffset(0, 4))
    makeBar(sg, Vector2.new(0, 1), UDim2.new(0, 18, 1, -18), UDim2.fromOffset(4, 0))
    -- BR
    makeBar(sg, Vector2.new(1, 1), UDim2.new(1, -18, 1, -18), UDim2.fromOffset(0, 4))
    makeBar(sg, Vector2.new(1, 1), UDim2.new(1, -18, 1, -18), UDim2.fromOffset(4, 0))
    local cornerTargets = {
        UDim2.fromOffset(72, 4), UDim2.fromOffset(4, 72),
        UDim2.fromOffset(72, 4), UDim2.fromOffset(4, 72),
        UDim2.fromOffset(72, 4), UDim2.fromOffset(4, 72),
        UDim2.fromOffset(72, 4), UDim2.fromOffset(4, 72),
    }

    -- 中心品牌 + 呼吸环
    local brandHost = Instance.new("Frame")
    brandHost.AnchorPoint = Vector2.new(0.5, 0.5)
    brandHost.Position = UDim2.fromScale(0.5, 0.42)
    brandHost.Size = UDim2.fromOffset(160, 160)
    brandHost.BackgroundTransparency = 1
    brandHost.Parent = sg
    local ring = Instance.new("Frame")
    ring.AnchorPoint = Vector2.new(0.5, 0.5)
    ring.Position = UDim2.fromScale(0.5, 0.5)
    ring.Size = UDim2.fromOffset(120, 120)
    ring.BackgroundTransparency = 1
    ring.Parent = brandHost
    local ringStroke = Instance.new("UIStroke")
    ringStroke.Color = GOLD
    ringStroke.Thickness = 2
    ringStroke.Transparency = 1
    ringStroke.Parent = ring
    Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
    local ringScale = Instance.new("UIScale")
    ringScale.Scale = 1
    ringScale.Parent = ring
    trackFade(ringStroke, "Transparency")
    local brand = Instance.new("TextLabel")
    brand.AnchorPoint = Vector2.new(0.5, 0.5)
    brand.Position = UDim2.fromScale(0.5, 0.5)
    brand.Size = UDim2.fromOffset(220, 48)
    brand.BackgroundTransparency = 1
    brand.Font = Enum.Font.GothamBold
    brand.TextScaled = true
    brand.Text = "theKing Hub"
    brand.TextColor3 = GOLD
    brand.TextTransparency = 1
    brand.Parent = brandHost
    trackFade(brand, "TextTransparency")

    -- 彩虹进度条 + 阶段文案
    local progWrap = Instance.new("Frame")
    progWrap.AnchorPoint = Vector2.new(0.5, 1)
    progWrap.Position = UDim2.new(0.5, 0, 1, -56)
    progWrap.Size = UDim2.fromOffset(320, 8)
    progWrap.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    progWrap.BackgroundTransparency = 0.2
    progWrap.BorderSizePixel = 0
    Instance.new("UICorner", progWrap).CornerRadius = UDim.new(1, 0)
    progWrap.Parent = sg
    trackFade(progWrap, "BackgroundTransparency")
    local prog = Instance.new("Frame")
    prog.Size = UDim2.fromScale(0, 1)
    prog.BackgroundColor3 = Color3.new(1, 1, 1)
    prog.BorderSizePixel = 0
    Instance.new("UICorner", prog).CornerRadius = UDim.new(1, 0)
    prog.Parent = progWrap
    local grad = Instance.new("UIGradient")
    grad.Rotation = 0
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)),
        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 170, 0)),
        ColorSequenceKeypoint.new(0.34, Color3.fromRGB(255, 255, 60)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 255, 120)),
        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(60, 200, 255)),
        ColorSequenceKeypoint.new(0.84, Color3.fromRGB(140, 90, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 70, 190)),
    })
    grad.Parent = prog
    local stageLabel = Instance.new("TextLabel")
    stageLabel.AnchorPoint = Vector2.new(0.5, 1)
    stageLabel.Position = UDim2.new(0.5, 0, 1, -72)
    stageLabel.Size = UDim2.fromOffset(420, 22)
    stageLabel.BackgroundTransparency = 1
    stageLabel.Font = Enum.Font.Gotham
    stageLabel.TextSize = 14
    stageLabel.Text = ""
    stageLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    stageLabel.TextTransparency = 1
    stageLabel.Parent = sg
    trackFade(stageLabel, "TextTransparency")

    -- 结果区文案
    local statusTitle = Instance.new("TextLabel")
    statusTitle.AnchorPoint = Vector2.new(0.5, 0.5)
    statusTitle.Position = UDim2.fromScale(0.5, 0.58)
    statusTitle.Size = UDim2.fromOffset(600, 42)
    statusTitle.BackgroundTransparency = 1
    statusTitle.Font = Enum.Font.GothamBold
    statusTitle.TextScaled = true
    statusTitle.Text = ""
    statusTitle.TextTransparency = 1
    statusTitle.Parent = sg
    trackFade(statusTitle, "TextTransparency")
    local statusDesc = Instance.new("TextLabel")
    statusDesc.AnchorPoint = Vector2.new(0.5, 0.5)
    statusDesc.Position = UDim2.fromScale(0.5, 0.66)
    statusDesc.Size = UDim2.fromOffset(600, 28)
    statusDesc.BackgroundTransparency = 1
    statusDesc.Font = Enum.Font.Gotham
    statusDesc.TextScaled = true
    statusDesc.Text = ""
    statusDesc.TextTransparency = 1
    statusDesc.Parent = sg
    trackFade(statusDesc, "TextTransparency")

    -- 未授权头像
    local avatar = Instance.new("ImageLabel")
    avatar.AnchorPoint = Vector2.new(0.5, 0.5)
    avatar.Position = UDim2.fromScale(0.5, 0.48)
    avatar.Size = UDim2.fromOffset(0, 0)
    avatar.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
    avatar.Image = getAvatarUrl(LocalPlayer.UserId)
    avatar.ScaleType = Enum.ScaleType.Crop
    avatar.ImageTransparency = 1
    Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)
    local avStroke = Instance.new("UIStroke")
    avStroke.Color = Color3.fromRGB(255, 90, 90)
    avStroke.Thickness = 2
    avStroke.Transparency = 1
    avStroke.Parent = avatar
    avatar.Parent = sg
    trackFade(avatar, "ImageTransparency")
    trackFade(avStroke, "Transparency")

    local welcomeHolder = nil
    local breathConn = nil
    local shimmerConn = nil
    local progValue = 0

    local function setProgress(p, label, dur)
        p = math.clamp(p, 0, 1)
        if type(label) == "string" and label ~= "" then
            stageLabel.Text = label
            if stageLabel.TextTransparency > 0.5 then
                TweenService:Create(stageLabel, TweenInfo.new(0.25), { TextTransparency = 0 }):Play()
            end
        end
        local d = dur or 0.45
        local tw = TweenService:Create(prog, TweenInfo.new(d, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromScale(p, 1),
        })
        tw:Play()
        progValue = p
        return tw
    end

    local function stopLoops()
        if breathConn then breathConn:Disconnect(); breathConn = nil end
        if shimmerConn then shimmerConn:Disconnect(); shimmerConn = nil end
    end

    task.spawn(function()
        local t0 = os.clock()

        -- 1. 背景
        TweenService:Create(bg, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.1,
        }):Play()
        setProgress(0.08, "正在启动 theKing Hub…", 0.4)
        task.wait(0.12)

        -- 2. L 形金条错峰弹出
        for i, bar in ipairs(cornerParts) do
            task.delay((i - 1) * 0.05, function()
                if not sg.Parent then return end
                TweenService:Create(bar, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 0,
                    Size = cornerTargets[i],
                }):Play()
            end)
        end
        task.wait(0.2)

        -- 3. 品牌字 + 呼吸环
        TweenService:Create(brand, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            TextTransparency = 0,
        }):Play()
        TweenService:Create(ringStroke, TweenInfo.new(0.5), { Transparency = 0.25 }):Play()
        local breathT = 0
        breathConn = RunService.Heartbeat:Connect(function(dt)
            if not sg.Parent then return end
            breathT += dt
            ringScale.Scale = 1 + 0.06 * math.sin(breathT * 2.2)
            ringStroke.Transparency = 0.2 + 0.15 * (0.5 + 0.5 * math.sin(breathT * 2.2))
        end)
        shimmerConn = RunService.Heartbeat:Connect(function(dt)
            if not sg.Parent then return end
            local off = (grad.Offset.X + dt * 0.35) % 1
            grad.Offset = Vector2.new(off, 0)
        end)

        setProgress(0.15, "正在启动 theKing Hub…", 0.35)
        task.wait(0.25)
        setProgress(0.35, "校验白名单…", 0.5)

        -- 4. 等授权 (最多 8s), 期间推进进度
        local authorized = false
        local got = false
        local waited = 0
        while waited < 80 do
            local v = getAuthResult()
            if v ~= nil then
                authorized = v
                got = true
                break
            end
            -- 校验中缓推到 ~0.65
            local mid = 0.35 + math.min(0.3, waited * 0.008)
            setProgress(mid, "校验白名单…", 0.2)
            task.wait(0.1)
            waited += 1
        end
        if not got then
            authorized = false
        end

        setProgress(0.75, "确认授权状态…", 0.4)
        task.wait(0.2)

        -- 授权成功: splash 内预拉清单
        if authorized then
            setProgress(0.88, "准备游戏清单…", 0.35)
            task.spawn(function()
                pcall(loadManifest)
            end)
        else
            setProgress(0.88, "确认授权状态…", 0.3)
        end

        -- 最短展示时间
        local elapsed = os.clock() - t0
        if elapsed < MIN_SPLASH_SEC then
            task.wait(MIN_SPLASH_SEC - elapsed)
        end

        local fillDone = setProgress(1, authorized and "授权通过" or "授权未通过", 0.35)
        fillDone.Completed:Wait()
        -- 近满亮度闪
        TweenService:Create(prog, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(255, 255, 255) }):Play()
        task.wait(0.12)
        TweenService:Create(prog, TweenInfo.new(0.25), { BackgroundColor3 = Color3.fromRGB(240, 240, 240) }):Play()

        -- 5. 隐藏加载品牌, 揭示结果
        TweenService:Create(brand, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
        TweenService:Create(ringStroke, TweenInfo.new(0.35), { Transparency = 1 }):Play()
        TweenService:Create(stageLabel, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
        if breathConn then breathConn:Disconnect(); breathConn = nil end
        task.wait(0.2)

        if authorized then
            local chars = { "中", "国", "人", "能", "飞" }
            local colors = {
                Color3.fromRGB(255, 90, 90), Color3.fromRGB(255, 200, 60),
                Color3.fromRGB(255, 255, 90), Color3.fromRGB(80, 255, 140),
                Color3.fromRGB(90, 180, 255),
            }
            welcomeHolder = Instance.new("Frame")
            welcomeHolder.Name = "WelcomeChars"
            welcomeHolder.AnchorPoint = Vector2.new(0.5, 0.5)
            welcomeHolder.Position = UDim2.fromScale(0.5, 0.44)
            welcomeHolder.Size = UDim2.fromOffset(340, 56)
            welcomeHolder.BackgroundTransparency = 1
            welcomeHolder.Parent = sg
            for i, ch in ipairs(chars) do
                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.fromOffset(60, 56)
                lbl.Position = UDim2.fromOffset((i - 1) * 68, 8)
                lbl.BackgroundTransparency = 1
                lbl.Font = Enum.Font.GothamBold
                lbl.TextScaled = true
                lbl.Text = ch
                lbl.TextColor3 = colors[i]
                lbl.TextTransparency = 1
                lbl.Parent = welcomeHolder
                local sc = Instance.new("UIScale")
                sc.Scale = 0.55
                sc.Parent = lbl
                trackFade(lbl, "TextTransparency")
                task.delay((i - 1) * 0.08, function()
                    if not sg.Parent then return end
                    TweenService:Create(lbl, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                        TextTransparency = 0,
                        Position = UDim2.fromOffset((i - 1) * 68, 0),
                    }):Play()
                    TweenService:Create(sc, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                        Scale = 1,
                    }):Play()
                end)
            end
            statusTitle.Text = "欢迎白名单用户 " .. username
            statusTitle.TextColor3 = Color3.fromRGB(255, 214, 90)
            statusTitle.Position = UDim2.fromScale(0.5, 0.58)
            statusDesc.Text = "中国人能飞"
            statusDesc.TextColor3 = Color3.fromRGB(200, 200, 200)
            task.delay(0.35, function()
                if not sg.Parent then return end
                TweenService:Create(statusTitle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    TextTransparency = 0,
                }):Play()
            end)
            task.delay(0.5, function()
                if not sg.Parent then return end
                TweenService:Create(statusDesc, TweenInfo.new(0.5), { TextTransparency = 0 }):Play()
            end)
        else
            statusTitle.Position = UDim2.fromScale(0.5, 0.62)
            statusDesc.Position = UDim2.fromScale(0.5, 0.70)
            TweenService:Create(avatar, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(110, 110),
                ImageTransparency = 0,
            }):Play()
            TweenService:Create(avStroke, TweenInfo.new(0.55), { Transparency = 0.15 }):Play()
            if state.reason == "expired" then
                statusTitle.Text = "用户已至期限"
                statusDesc.Text = "请续约公司"
            elseif state.reason == "clock" then
                statusTitle.Text = "系统时间异常"
                statusDesc.Text = "本地时间与服务端不一致"
            else
                statusTitle.Text = "未授权用户"
                statusDesc.Text = "请升级 O5 会议权限"
            end
            statusTitle.TextColor3 = Color3.fromRGB(255, 90, 90)
            statusDesc.TextColor3 = Color3.fromRGB(255, 160, 80)
            -- 文案上滑淡入
            local ty = statusTitle.Position
            statusTitle.Position = UDim2.new(ty.X.Scale, ty.X.Offset, ty.Y.Scale, ty.Y.Offset + 16)
            local dy = statusDesc.Position
            statusDesc.Position = UDim2.new(dy.X.Scale, dy.X.Offset, dy.Y.Scale, dy.Y.Offset + 16)
            TweenService:Create(statusTitle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                TextTransparency = 0,
                Position = ty,
            }):Play()
            TweenService:Create(statusDesc, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                TextTransparency = 0,
                Position = dy,
            }):Play()
        end

        task.wait(1.55)

        -- 6. 统一退场
        stopLoops()
        for _, item in ipairs(fadeTargets) do
            local inst = item.inst
            if inst and inst.Parent then
                pcall(function()
                    TweenService:Create(inst, TweenInfo.new(0.4), { [item.prop] = 1 }):Play()
                end)
            end
        end
        if welcomeHolder then
            for _, c in ipairs(welcomeHolder:GetChildren()) do
                if c:IsA("TextLabel") then
                    TweenService:Create(c, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
                end
            end
        end
        task.wait(0.45)
        stopLoops()
        if sg.Parent then sg:Destroy() end
        splashGui = nil
        if onFinish then pcall(onFinish, authorized) end
    end)
end

-- ==================== Loader 主界面 (独立玻璃面板, 不用 WindUI) ====================
-- 到期时间格式化: 永久 -> "永久"; 有日期 -> "YYYY-MM-DD (剩余N天)" / "(已到期)"
local function formatExpiry(untilStr)
    if type(untilStr) ~= "string" or #untilStr == 0 then
        return "永久"
    end
    local today = todayUtc()
    local y, m, d = untilStr:match("(%d+)-(%d+)-(%d+)")
    if not y then return untilStr end
    local remaining = (os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d) })
        - os.time({ year = tonumber(today:sub(1, 4)), month = tonumber(today:sub(6, 7)), day = tonumber(today:sub(9, 10)) })) / 86400
    if remaining < 0 then
        return untilStr .. " (已到期)"
    end
    return untilStr .. " (剩余" .. tostring(math.floor(remaining + 0.5)) .. "天)"
end

local GOLD = Color3.fromRGB(255, 208, 70)

local function corner(inst, r)
    Instance.new("UICorner", inst).CornerRadius = UDim.new(0, r or 10)
end

local function buildUI()
    if loaderGui and loaderGui.Parent then
        loaderGui:Destroy()
    end
    local sg = Instance.new("ScreenGui")
    sg.Name = "TheKingLoaderUI"
    sg.DisplayOrder = 10000
    sg.IgnoreGuiInset = true
    sg.ResetOnSpawn = false
    parentToHui(sg)
    loaderGui = sg

    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.Size = UDim2.fromOffset(540, 400)
    panel.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
    panel.BackgroundTransparency = 0.04
    panel.BorderSizePixel = 0
    corner(panel, 16)
    local pst = Instance.new("UIStroke")
    pst.Color = GOLD
    pst.Transparency = 0.55
    pst.Thickness = 1
    pst.Parent = panel
    panel.Parent = sg

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 56)
    header.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
    header.BorderSizePixel = 0
    corner(header, 16)
    header.Parent = panel
    -- 盖住 header 下圆角
    local headerFill = Instance.new("Frame")
    headerFill.Position = UDim2.new(0, 0, 1, -16)
    headerFill.Size = UDim2.new(1, 0, 0, 16)
    headerFill.BackgroundColor3 = header.BackgroundColor3
    headerFill.BorderSizePixel = 0
    headerFill.Parent = header

    local brand = Instance.new("TextLabel")
    brand.BackgroundTransparency = 1
    brand.Position = UDim2.fromOffset(20, 8)
    brand.Size = UDim2.fromOffset(220, 24)
    brand.Font = Enum.Font.GothamBold
    brand.TextSize = 20
    brand.TextXAlignment = Enum.TextXAlignment.Left
    brand.TextColor3 = GOLD
    brand.Text = "theKing Hub"
    brand.Parent = header
    local sub = Instance.new("TextLabel")
    sub.BackgroundTransparency = 1
    sub.Position = UDim2.fromOffset(20, 30)
    sub.Size = UDim2.fromOffset(280, 18)
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 12
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.TextColor3 = Color3.fromRGB(170, 170, 175)
    sub.Text = "v0.9.0"
    sub.Parent = header

    local closeBtn = Instance.new("TextButton")
    closeBtn.AnchorPoint = Vector2.new(1, 0.5)
    closeBtn.Position = UDim2.new(1, -14, 0.5, 0)
    closeBtn.Size = UDim2.fromOffset(28, 28)
    closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 46)
    closeBtn.BorderSizePixel = 0
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
    closeBtn.AutoButtonColor = true
    corner(closeBtn, 8)
    closeBtn.Parent = header

    local authChip = Instance.new("TextLabel")
    authChip.AnchorPoint = Vector2.new(1, 0.5)
    authChip.Position = UDim2.new(1, -52, 0.5, 0)
    authChip.Size = UDim2.fromOffset(200, 28)
    authChip.BackgroundColor3 = Color3.fromRGB(32, 28, 18)
    authChip.BorderSizePixel = 0
    authChip.Font = Enum.Font.Gotham
    authChip.TextSize = 11
    authChip.TextColor3 = GOLD
    authChip.Text = username
    corner(authChip, 8)
    authChip.Parent = header

    -- 当前游戏卡
    local card = Instance.new("Frame")
    card.Position = UDim2.fromOffset(18, 72)
    card.Size = UDim2.new(1, -36, 0, 136)
    card.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    card.BorderSizePixel = 0
    corner(card, 12)
    card.Parent = panel

    local curTitle = Instance.new("TextLabel")
    curTitle.BackgroundTransparency = 1
    curTitle.Position = UDim2.fromOffset(16, 10)
    curTitle.Size = UDim2.new(1, -32, 0, 16)
    curTitle.Font = Enum.Font.Gotham
    curTitle.TextSize = 12
    curTitle.TextXAlignment = Enum.TextXAlignment.Left
    curTitle.TextColor3 = Color3.fromRGB(150, 150, 155)
    curTitle.Text = "当前游戏"
    curTitle.Parent = card
    local curName = Instance.new("TextLabel")
    curName.BackgroundTransparency = 1
    curName.Position = UDim2.fromOffset(16, 28)
    curName.Size = UDim2.new(1, -170, 0, 28)
    curName.Font = Enum.Font.GothamBold
    curName.TextSize = 20
    curName.TextXAlignment = Enum.TextXAlignment.Left
    curName.TextColor3 = Color3.new(1, 1, 1)
    curName.Text = "检测中…"
    curName.TextTruncate = Enum.TextTruncate.AtEnd
    curName.Parent = card
    local curDesc = Instance.new("TextLabel")
    curDesc.BackgroundTransparency = 1
    curDesc.Position = UDim2.fromOffset(16, 58)
    curDesc.Size = UDim2.new(1, -170, 0, 18)
    curDesc.Font = Enum.Font.Gotham
    curDesc.TextSize = 13
    curDesc.TextXAlignment = Enum.TextXAlignment.Left
    curDesc.TextColor3 = Color3.fromRGB(180, 180, 185)
    curDesc.Text = ""
    curDesc.Parent = card

    local injectBtn = Instance.new("TextButton")
    injectBtn.AnchorPoint = Vector2.new(1, 0)
    injectBtn.Position = UDim2.new(1, -16, 0, 28)
    injectBtn.Size = UDim2.fromOffset(132, 40)
    injectBtn.BackgroundColor3 = GOLD
    injectBtn.BorderSizePixel = 0
    injectBtn.Font = Enum.Font.GothamBold
    injectBtn.TextSize = 15
    injectBtn.TextColor3 = Color3.fromRGB(20, 16, 8)
    injectBtn.Text = "注入脚本"
    injectBtn.AutoButtonColor = true
    corner(injectBtn, 10)
    injectBtn.Parent = card

    local autoBtn = Instance.new("TextButton")
    autoBtn.AnchorPoint = Vector2.new(1, 0)
    autoBtn.Position = UDim2.new(1, -16, 0, 76)
    autoBtn.Size = UDim2.fromOffset(132, 28)
    autoBtn.BorderSizePixel = 0
    autoBtn.Font = Enum.Font.Gotham
    autoBtn.TextSize = 12
    autoBtn.AutoButtonColor = true
    corner(autoBtn, 8)
    autoBtn.Parent = card
    local function paintAutoBtn()
        if loaderPrefs.autoInject then
            autoBtn.BackgroundColor3 = Color3.fromRGB(48, 40, 18)
            autoBtn.TextColor3 = GOLD
            autoBtn.Text = "自动注入  开"
        else
            autoBtn.BackgroundColor3 = Color3.fromRGB(36, 36, 42)
            autoBtn.TextColor3 = Color3.fromRGB(180, 180, 185)
            autoBtn.Text = "自动注入  关"
        end
    end
    paintAutoBtn()

    -- 清单
    local listLabel = Instance.new("TextLabel")
    listLabel.BackgroundTransparency = 1
    listLabel.Position = UDim2.fromOffset(22, 218)
    listLabel.Size = UDim2.new(1, -44, 0, 18)
    listLabel.Font = Enum.Font.GothamBold
    listLabel.TextSize = 13
    listLabel.TextXAlignment = Enum.TextXAlignment.Left
    listLabel.TextColor3 = Color3.fromRGB(200, 200, 205)
    listLabel.Text = "支持的游戏"
    listLabel.Parent = panel

    local listFrame = Instance.new("ScrollingFrame")
    listFrame.Position = UDim2.fromOffset(18, 240)
    listFrame.Size = UDim2.new(1, -36, 0, 112)
    listFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
    listFrame.BorderSizePixel = 0
    listFrame.ScrollBarThickness = 4
    listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    corner(listFrame, 10)
    listFrame.Parent = panel
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 4)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = listFrame
    local listPad = Instance.new("UIPadding")
    listPad.PaddingTop = UDim.new(0, 6)
    listPad.PaddingBottom = UDim.new(0, 6)
    listPad.PaddingLeft = UDim.new(0, 8)
    listPad.PaddingRight = UDim.new(0, 8)
    listPad.Parent = listFrame

    local foot = Instance.new("TextLabel")
    foot.BackgroundTransparency = 1
    foot.Position = UDim2.fromOffset(20, 358)
    foot.Size = UDim2.new(1, -40, 0, 28)
    foot.Font = Enum.Font.Gotham
    foot.TextSize = 12
    foot.TextXAlignment = Enum.TextXAlignment.Left
    foot.TextColor3 = Color3.fromRGB(120, 120, 128)
    foot.Text = "DEL 显示/隐藏    END 卸载    自动注入开着时下次直进游戏, 未适配会回到本界面"
    foot.Parent = panel

    local toast = Instance.new("TextLabel")
    toast.AnchorPoint = Vector2.new(0.5, 1)
    toast.Position = UDim2.new(0.5, 0, 1, -8)
    toast.Size = UDim2.fromOffset(320, 28)
    toast.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
    toast.BackgroundTransparency = 1
    toast.BorderSizePixel = 0
    toast.Font = Enum.Font.Gotham
    toast.TextSize = 13
    toast.TextColor3 = Color3.new(1, 1, 1)
    toast.TextTransparency = 1
    toast.Text = ""
    corner(toast, 8)
    toast.Parent = panel

    -- 拖动
    do
        local dragging = false
        local startInput, startPos
        header.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                startInput = input.Position
                startPos = panel.Position
            end
        end)
        TheKing.AddConnection(UserInputService.InputChanged:Connect(function(input)
            if not dragging then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                local d = input.Position - startInput
                panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end))
        TheKing.AddConnection(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end))
    end

    local confirmLayer = nil
    local function hideConfirm()
        if confirmLayer then
            confirmLayer:Destroy()
            confirmLayer = nil
        end
    end
    local function askUnload()
        hideConfirm()
        confirmLayer = Instance.new("Frame")
        confirmLayer.Size = UDim2.fromScale(1, 1)
        confirmLayer.BackgroundColor3 = Color3.new(0, 0, 0)
        confirmLayer.BackgroundTransparency = 0.4
        confirmLayer.BorderSizePixel = 0
        confirmLayer.Parent = panel
        local box = Instance.new("Frame")
        box.AnchorPoint = Vector2.new(0.5, 0.5)
        box.Position = UDim2.fromScale(0.5, 0.5)
        box.Size = UDim2.fromOffset(300, 150)
        box.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
        box.BorderSizePixel = 0
        corner(box, 12)
        box.Parent = confirmLayer
        local tt = Instance.new("TextLabel")
        tt.BackgroundTransparency = 1
        tt.Position = UDim2.fromOffset(16, 16)
        tt.Size = UDim2.new(1, -32, 0, 24)
        tt.Font = Enum.Font.GothamBold
        tt.TextSize = 16
        tt.TextColor3 = Color3.new(1, 1, 1)
        tt.Text = "卸载 Loader?"
        tt.Parent = box
        local dd = Instance.new("TextLabel")
        dd.BackgroundTransparency = 1
        dd.Position = UDim2.fromOffset(16, 46)
        dd.Size = UDim2.new(1, -32, 0, 40)
        dd.Font = Enum.Font.Gotham
        dd.TextSize = 13
        dd.TextWrapped = true
        dd.TextColor3 = Color3.fromRGB(180, 180, 185)
        dd.Text = "只关闭加载器, 已注入的游戏脚本会继续运行。"
        dd.Parent = box
        local cancel = Instance.new("TextButton")
        cancel.Position = UDim2.fromOffset(16, 100)
        cancel.Size = UDim2.fromOffset(120, 34)
        cancel.BackgroundColor3 = Color3.fromRGB(50, 50, 56)
        cancel.BorderSizePixel = 0
        cancel.Font = Enum.Font.Gotham
        cancel.TextSize = 14
        cancel.TextColor3 = Color3.new(1, 1, 1)
        cancel.Text = "取消"
        corner(cancel, 8)
        cancel.Parent = box
        local okb = Instance.new("TextButton")
        okb.Position = UDim2.fromOffset(164, 100)
        okb.Size = UDim2.fromOffset(120, 34)
        okb.BackgroundColor3 = Color3.fromRGB(255, 90, 90)
        okb.BorderSizePixel = 0
        okb.Font = Enum.Font.GothamBold
        okb.TextSize = 14
        okb.TextColor3 = Color3.new(1, 1, 1)
        okb.Text = "卸载"
        corner(okb, 8)
        okb.Parent = box
        cancel.Activated:Connect(hideConfirm)
        okb.Activated:Connect(function()
            hideConfirm()
            TheKing.Destroy()
        end)
    end

    local function showToast(msg, ok)
        toast.Text = tostring(msg or "")
        toast.BackgroundTransparency = 0.15
        toast.TextTransparency = 0
        toast.TextColor3 = ok and Color3.fromRGB(140, 255, 180) or Color3.fromRGB(255, 200, 120)
        task.delay(2.4, function()
            if toast.Parent then
                TweenService:Create(toast, TweenInfo.new(0.3), {
                    BackgroundTransparency = 1,
                    TextTransparency = 1,
                }):Play()
            end
        end)
    end

    local function setAuth(text)
        authChip.Text = tostring(text or username)
    end

    local function setCurrent(name, desc, canInject)
        curName.Text = name or "未知"
        curDesc.Text = desc or ""
        injectBtn.Visible = canInject == true
        if canInject then
            injectBtn.BackgroundColor3 = GOLD
            injectBtn.Text = "注入脚本"
            injectBtn.AutoButtonColor = true
        end
    end

    local function setGames(entries, currentPlace)
        for _, c in ipairs(listFrame:GetChildren()) do
            if c:IsA("TextLabel") or c:IsA("TextButton") then
                c:Destroy()
            end
        end
        if type(entries) == "table" then
            sortManifest(entries)
        end
        if type(entries) ~= "table" or #entries == 0 then
            local empty = Instance.new("TextLabel")
            empty.Size = UDim2.new(1, 0, 0, 28)
            empty.BackgroundTransparency = 1
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 13
            empty.TextColor3 = Color3.fromRGB(140, 140, 145)
            empty.Text = "清单为空或拉取失败"
            empty.Parent = listFrame
            return
        end
        for i, e in ipairs(entries) do
            local isCur = isCurrentManifestEntry(e)
            local row = Instance.new("TextLabel")
            row.Size = UDim2.new(1, -4, 0, 26)
            row.BackgroundColor3 = isCur and Color3.fromRGB(40, 34, 18) or Color3.fromRGB(28, 28, 32)
            row.BackgroundTransparency = isCur and 0.15 or 0.4
            row.BorderSizePixel = 0
            row.Font = Enum.Font.Gotham
            row.TextSize = 13
            row.TextXAlignment = Enum.TextXAlignment.Left
            row.TextColor3 = isCur and GOLD or Color3.fromRGB(210, 210, 215)
            row.Text = "  " .. gameTitle(e.game) .. "  v" .. tostring(e.version) .. (isCur and "  · 当前" or "")
            row.LayoutOrder = i
            corner(row, 6)
            row.Parent = listFrame
        end
    end

    local injecting = false
    local function doInject()
        if injecting then return end
        if not checkAuth() then
            if state.reason == "expired" then
                forceExit("用户已至期限", "用户已至期限，请续约公司")
            elseif state.reason == "clock" then
                forceExit("系统时间异常", "检测到本地时间与服务端不一致, 请校准系统时间后重试")
            else
                forceExit("未授权", "当前用户未授权, 无法使用 TheKing 脚本。")
            end
            return
        end
        local entry = manifestEntryForGame()
        if not entry then
            showToast("当前游戏暂未适配, 留在 Loader", false)
            return
        end
        injecting = true
        injectBtn.Text = "注入中…"
        injectBtn.AutoButtonColor = false
        setCurrent(gameTitle(entry.game), "v" .. tostring(entry.version) .. "  正在注入", true)
        local ok, msg = injectScript(entry)
        if ok then
            showToast(gameTitle(entry.game) .. " 已加载", true)
            afterInjectOk()
        else
            injecting = false
            injectBtn.Text = "注入脚本"
            injectBtn.AutoButtonColor = true
            if msg == "用户已至期限，请续约公司" then
                forceExit("用户已至期限", msg)
                return
            end
            setCurrent(gameTitle(entry.game), "注入失败: " .. tostring(msg), true)
            showToast(tostring(msg), false)
        end
    end
    injectBtn.Activated:Connect(doInject)
    autoBtn.Activated:Connect(function()
        loaderPrefs.autoInject = not loaderPrefs.autoInject
        loaderPrefFlush()
        paintAutoBtn()
        if loaderPrefs.autoInject then
            showToast("已开启自动注入, 下次开 Loader 将直进当前游戏", true)
        else
            showToast("已关闭自动注入", true)
        end
    end)
    closeBtn.Activated:Connect(askUnload)

    TheKing.AddConnection(UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if not loaderGui or not loaderGui.Parent then return end
        if input.KeyCode == Enum.KeyCode.Delete then
            sg.Enabled = not sg.Enabled
        elseif input.KeyCode == Enum.KeyCode.End then
            if sg.Enabled then
                askUnload()
            end
        end
    end))

    ui.setAuth = setAuth
    ui.setCurrent = setCurrent
    ui.setGames = setGames
    ui.toast = showToast
end

-- ==================== 启动 ====================
-- 卸载时清掉 splash
TheKing.OnCleanup(function()
    if splashGui and splashGui.Parent then splashGui:Destroy() end
    if loaderGui and loaderGui.Parent then loaderGui:Destroy() end
    loaderGui = nil
end)

-- 动画期间后台跑授权; 通过后立刻预拉 manifest (splash 内也会再触发, loadManifest 有缓存)
local authReady = false
local authResult = false
task.spawn(function()
    authResult = checkAuth()
    authReady = true
    if authResult then
        pcall(loadManifest)
    end
end)

playSplash(function()
    if authReady then return authResult end
    return nil
end, function(authorized)
    -- 动画结束: 授权通过才构建 UI; 自动注入命中则跳过界面
    if authorized then
        local m = state.manifest or loadManifest()
        local currentPlace = tostring(game.PlaceId)
        local entry = manifestEntryForGame()
        local autoFail = nil
        if loaderPrefs.autoInject then
            if entry then
                local ok, msg = injectScript(entry)
                if ok then
                    afterInjectOk()
                    return
                end
                autoFail = tostring(msg or "注入失败")
            else
                autoFail = "no-game"
            end
        end
        buildUI()
        ui.setAuth(username .. " · " .. formatExpiry(state.untilStr))
        if m then
            ui.setGames(m, currentPlace)
            if entry then
                local desc = "v" .. tostring(entry.version) .. "  可注入"
                if autoFail and autoFail ~= "no-game" then
                    desc = "自动注入失败: " .. autoFail
                end
                ui.setCurrent(gameTitle(entry.game), desc, true)
            else
                ui.setCurrent("此游戏暂未适配", "清单里没有当前游戏", false)
            end
        else
            ui.setGames(nil, currentPlace)
            ui.setCurrent("清单拉取失败", "检查网络或仓库", false)
        end
        if autoFail == "no-game" then
            ui.toast("当前游戏未适配, 已打开 Loader", false)
        elseif autoFail then
            ui.toast("自动注入失败: " .. autoFail, false)
        else
            ui.toast("Loader 已就绪", true)
        end
    else
        -- 未授权/已到期/时间异常: 动画里已显示拒绝信息, 补一个退出弹窗
        task.wait(1)
        if state.reason == "expired" then
            forceExit("用户已至期限", "用户已至期限，请续约公司")
        elseif state.reason == "clock" then
            forceExit("系统时间异常", "检测到本地时间与服务端不一致, 请校准系统时间后重试")
        else
            forceExit("未授权", "当前用户未授权, 无法使用 TheKing 脚本。请升级 O5 会议权限。")
        end
    end
end)
