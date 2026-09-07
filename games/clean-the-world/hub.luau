--[[
    TheKing HUB [0.5.0] - Clean the WORLD!
    RCWTK 引擎生成 | 模板 v1.0
    版本历史: games/clean-the-world/changelog.md (每次发布追加条目, 语义见该文件)

    功能清单 (改这里, 保持格式):
      自动清扫: 关入桶动画后同步调用 throwPaperToTrash, DropArea 新垃圾立刻扫, 桶满则停一轮
      自动升级技能: 买得起且前置已点就 PurchaseSkillUpgrade; 缓存 GetSkillUpgrades, 无可买时歇约 10s
      自动买污染/升级/建造: 侧栏未满且买得起才 Purchase*; UI 已 MAX 不 Get; 全满歇约 12s, 买不起歇约 6s

    逆向结论 (关键协议结论写这里, 收工同步到 games/clean-the-world/intel.md):
      - throwPaperToTrash 在 TrashAnimationEnabled==false 时 FireServer 后立刻 Destroy/入桶, 无 0.55s 弧线; 自动清扫只在当轮临时关掉动画/拾取音/飘字, 轮末还原
      - 玩家鼠标圈 collectPapersNearMouse: RenderStepped + Mouse.Move, 半径 u4, 仅 DropArea
      - 普通纸张 FireServer(nil); 老鼠/雷胶/金纸等走命名 source; 裸 FireServer() 与地上实例脱钩, 不作为清扫路径
      - 技能树: PurchaseSkillUpgrade:InvokeServer(技能名); GetSkillUpgrades 返回 costs/currencies/purchased/gum, 单次常 5s+ 必须缓存; 满级 reason=Max upgrade level; 不碰 Robux/声望
      - 花钱: 侧栏 Pollution/Upgrades/Build 的 Frame 名对应 Purchase*/Get*; UI Cost=MAX 不必 Get; 满级 success=false 且 reason 含 Max; 不买无限口香糖兑换; 马和独角兽共用 totalCount 上限

    使用方式:
      开发: execute 本文件 (theking.luau 多候选路径自动加载)
      热调试: 改完代码直接重新执行本文件, 旧实例自动自毁让位, 无需手动卸载
      发布: 用构建脚本把 theking.luau 内嵌后单文件化
]]

local function loadTheKing()
    local errs = {}
    for _, p in ipairs({
        "theking.luau",
        "lib/theking.luau",
        "D:/BuildProject/RoLua/Core/lib/theking.luau",
    }) do
        local ok, loader = pcall(function()
            return loadstring(readfile(p))
        end)
        if ok and type(loader) == "function" then
            return loader
        end
        errs[#errs + 1] = tostring(p) .. " -> " .. tostring(loader)
    end
    error("[Clean the WORLD!] theking.luau 加载失败:\n" .. table.concat(errs, "\n"), 0)
end

local TheKing = loadTheKing()({
    GameName = "Clean the WORLD!",
    ScriptVersion = "0.5.0",
})

TheKing.Notify({ Content = "TheKing HUB 已加载", Icon = "crown" })

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local sweepPerTick = 16
local lastSweepPulse = 0
local sweepConns = {}
local collector = {
    throw = nil,
    drop = nil,
    getCans = nil,
    inFlight = nil,
}

local SWEEP_ATTRS = { "TrashAnimationEnabled", "PickupSoundEnabled", "CurrencyPopupEnabled" }

local function clearSweepConns()
    for _, conn in ipairs(sweepConns) do
        pcall(function()
            conn:Disconnect()
        end)
    end
    table.clear(sweepConns)
end

local function bindThrowHelpers(throwFn)
    collector.getCans = nil
    collector.inFlight = nil
    local okCans, getCans = pcall(debug.getupvalue, throwFn, 1)
    if okCans and type(getCans) == "function" then
        collector.getCans = getCans
    end
    local okFly, inFlight = pcall(debug.getupvalue, throwFn, 4)
    if okFly and type(inFlight) == "table" then
        collector.inFlight = inFlight
    end
end

local function refreshCollector()
    collector.throw = nil
    collector.drop = nil
    collector.getCans = nil
    collector.inFlight = nil
    if type(getconnections) ~= "function" or type(debug.getupvalue) ~= "function" then
        return false
    end
    local drop = workspace:FindFirstChild("DropArea")
    local okCons, cons = pcall(getconnections, RunService.RenderStepped)
    if not okCons or type(cons) ~= "table" then
        return false
    end
    for _, conn in ipairs(cons) do
        local fn = conn.Function
        if type(fn) == "function" then
            local infoOk, info = pcall(debug.getinfo, fn)
            local src = (infoOk and info and type(info.source) == "string") and info.source or ""
            if string.find(src, "LocalNPCManager", 1, true) then
                local okCollect, collectFn = pcall(debug.getupvalue, fn, 2)
                if okCollect and type(collectFn) == "function" then
                    local okThrow, throwFn = pcall(debug.getupvalue, collectFn, 8)
                    if okThrow and type(throwFn) == "function" then
                        if not drop then
                            local okDrop, uvDrop = pcall(debug.getupvalue, collectFn, 5)
                            if okDrop and typeof(uvDrop) == "Instance" then
                                drop = uvDrop
                            end
                        end
                        if drop and drop.Parent then
                            collector.throw = throwFn
                            collector.drop = drop
                            bindThrowHelpers(throwFn)
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

local function ensureCollector()
    local drop = workspace:FindFirstChild("DropArea")
    if drop then
        collector.drop = drop
    end
    if collector.throw and collector.drop and collector.drop.Parent then
        return true
    end
    return refreshCollector()
end

local function isCollectible(inst)
    if not inst:IsA("BasePart") then
        return false
    end
    local name = inst.Name
    if name == "Paper" then
        return true
    end
    if (name == "Poop" or name == "Banana" or name == "Egg") and inst:GetAttribute("TrashReady") == true then
        return true
    end
    return false
end

local function hasEmptyCan()
    local getCans = collector.getCans
    if type(getCans) ~= "function" then
        return true
    end
    local ok, cans = pcall(getCans)
    return ok and type(cans) == "table" and #cans > 0
end

local function withFastThrow(fn)
    local prev = {}
    for _, name in ipairs(SWEEP_ATTRS) do
        prev[name] = LocalPlayer:GetAttribute(name)
        LocalPlayer:SetAttribute(name, false)
    end
    local ok, err = pcall(fn)
    for _, name in ipairs(SWEEP_ATTRS) do
        LocalPlayer:SetAttribute(name, prev[name])
    end
    if not ok then
        warn("[自动清扫] " .. tostring(err))
    end
end

local function throwOne(part)
    if not part.Parent then
        return false
    end
    if not isCollectible(part) then
        return false
    end
    local inFlight = collector.inFlight
    if inFlight and inFlight[part] then
        return false
    end
    collector.throw(part)
    return true
end

local function sweepBatch(cap)
    lastSweepPulse = os.clock()
    if not hasEmptyCan() then
        return
    end
    local drop = collector.drop
    local fired = 0
    withFastThrow(function()
        for _, child in ipairs(drop:GetChildren()) do
            if fired >= cap then
                break
            end
            if throwOne(child) then
                fired += 1
                if not hasEmptyCan() then
                    break
                end
            end
        end
    end)
end

local function startSweepWatch()
    clearSweepConns()
    local drop = collector.drop
    if not drop then
        return
    end
    local conn = drop.ChildAdded:Connect(function(child)
        if os.clock() - lastSweepPulse > 0.35 then
            return
        end
        if not hasEmptyCan() then
            return
        end
        task.defer(function()
            if not child.Parent then
                return
            end
            withFastThrow(function()
                throwOne(child)
            end)
        end)
    end)
    table.insert(sweepConns, conn)
    TheKing.AddConnection(conn)
end

local SKILL_SKIP = {
    PRESTIGE = true,
    Coming_Soon = true,
}

local remoteCache = {}

local function waitRemote(name)
    local cached = remoteCache[name]
    if cached and cached.Parent then
        return cached
    end
    local folder = TheKing.WaitChild(ReplicatedStorage, "Remotes", 10)
    if not folder then
        return nil
    end
    local remote = TheKing.WaitChild(folder, name, 10)
    if remote then
        remoteCache[name] = remote
    end
    return remote
end

local function skillReqMet(btn, purchased)
    local req = btn:FindFirstChild("Required")
    if not (req and req:IsA("ObjectValue") and req.Value) then
        return true
    end
    local owned = purchased[req.Value.Name]
    local n = (owned == true) and 1 or (tonumber(owned) or 0)
    return n > 0
end

local function gumSkillFolder(waitTimeout)
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg and waitTimeout then
        pg = LocalPlayer:WaitForChild("PlayerGui", waitTimeout)
    end
    if not pg then
        return nil
    end
    local skillGui = pg:FindFirstChild("Skill")
    if not skillGui and waitTimeout then
        skillGui = pg:WaitForChild("Skill", waitTimeout)
    end
    if not skillGui then
        return nil
    end
    local frame = skillGui:FindFirstChild("Frame")
    if not frame and waitTimeout then
        frame = skillGui:WaitForChild("Frame", waitTimeout)
    end
    if not frame then
        return nil
    end
    local upgrade = frame:FindFirstChild("Upgrade")
    if not upgrade and waitTimeout then
        upgrade = frame:WaitForChild("Upgrade", waitTimeout)
    end
    return upgrade
end

local NPC_MAX = 25
local SHOP_SKIP = {
    Gum = true,
    Info = true,
}

local SHOP_ALIAS = {
    People = { buy = "PurchaseNPC", get = "GetNPCCount", kind = "npc" },
    Horse = { buy = "PurchaseHorse", get = "GetHorseCount", kind = "countShare" },
    Unicorn = { buy = "PurchaseUnicorn", get = "GetUnicornCount", kind = "count" },
    Gorilla = { buy = "PurchaseGorilla", get = "GetGorillaCount", kind = "count" },
    DINOSAUR = { buy = "PurchaseDinosaur", get = "GetDinosaurCount", kind = "count" },
    Paper = { buy = "PurchasePaperUpgrade", get = "GetPaperUpgrade", kind = "level" },
    Poop = { buy = "PurchasePoopUpgrade", get = "GetPoopUpgrade", kind = "level" },
    Banana = { buy = "PurchaseBananaUpgrade", get = "GetBananaUpgrade", kind = "level" },
    Egg = { buy = "PurchaseEggUpgrade", get = "GetEggUpgrade", kind = "level" },
    Rat = { buy = "PurchaseRat", get = "GetRatCount", kind = "count" },
    Thundergum = { buy = "PurchaseThundergum", get = "GetThundergumCount", kind = "count" },
    Seagull = { buy = "PurchaseSeagull", get = "GetSeagullCount", kind = "count" },
    Seaweed = { buy = "PurchaseSeaweed", get = "GetSeaweed", kind = "count" },
}

local COST_SUFFIX = {
    K = 1e3,
    M = 1e6,
    B = 1e9,
    T = 1e12,
}

local function findRemote(name)
    return TheKing.FindRemote(name)
end

local function playerMoney()
    local ps = LocalPlayer:FindFirstChild("PrivateStats")
    local money = ps and ps:FindFirstChild("Money")
    return tonumber(money and money.Value) or 0
end

local function parseCostText(text)
    if type(text) ~= "string" then
        return nil, false
    end
    if text == "MAX" then
        return nil, true
    end
    local num, suf = string.match(text, "%$?([%d%.]+)([KMBT]?)")
    local n = tonumber(num)
    if not n then
        return nil, false
    end
    if suf ~= "" then
        n = n * (COST_SUFFIX[suf] or 1)
    end
    return n, false
end

local function parseCapText(text)
    if type(text) ~= "string" then
        return nil, nil
    end
    local a, b = string.match(text, "^(%d+)%s*/%s*(%d+)$")
    return tonumber(a), tonumber(b)
end

local function sidebarShopFolder(listName, waitTimeout)
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg and waitTimeout then
        pg = LocalPlayer:WaitForChild("PlayerGui", waitTimeout)
    end
    if not pg then
        return nil
    end
    local main = pg:FindFirstChild("Main")
    if not main and waitTimeout then
        main = pg:WaitForChild("Main", waitTimeout)
    end
    if not main then
        return nil
    end
    local side = main:FindFirstChild("Sidebar")
    if not side and waitTimeout then
        side = main:WaitForChild("Sidebar", waitTimeout)
    end
    if not side then
        return nil
    end
    local folder = side:FindFirstChild(listName)
    if not folder and waitTimeout then
        folder = side:WaitForChild(listName, waitTimeout)
    end
    return folder
end

local function guessShopSpec(frameName)
    local alias = SHOP_ALIAS[frameName]
    if alias then
        return alias
    end
    return {
        buy = "Purchase" .. frameName,
        get = nil,
        kind = "auto",
    }
end

local function resolveGetRemote(frameName, spec)
    if spec.get then
        return findRemote(spec.get)
    end
    return findRemote("Get" .. frameName .. "Count")
        or findRemote("Get" .. frameName .. "Upgrade")
        or findRemote("Get" .. frameName)
end

local function normalizeShopData(raw, kind)
    if type(raw) == "number" then
        return {
            count = raw,
            maxCount = NPC_MAX,
            unlocked = true,
        }, "npc"
    end
    if type(raw) ~= "table" then
        return nil, kind
    end
    local inferred = kind
    if inferred == "auto" then
        if raw.maxLevel ~= nil then
            inferred = "level"
        elseif raw.totalCount ~= nil then
            inferred = "countShare"
        elseif raw.maxCount ~= nil then
            inferred = "count"
        elseif raw.gum ~= nil and raw.maxCount == nil and raw.level == nil then
            inferred = "skip"
        else
            inferred = "count"
        end
    end
    return raw, inferred
end

local function isShopMaxed(data, kind)
    if not data then
        return true
    end
    if kind == "skip" then
        return true
    end
    if data.unlocked == false then
        return true
    end
    if kind == "npc" then
        return (tonumber(data.count) or 0) >= NPC_MAX
    end
    if kind == "level" then
        local level = tonumber(data.level) or 0
        local maxLevel = tonumber(data.maxLevel)
        return maxLevel ~= nil and level >= maxLevel
    end
    if kind == "countShare" then
        local n = tonumber(data.totalCount) or tonumber(data.count) or 0
        local cap = tonumber(data.maxCount)
        return cap ~= nil and n >= cap
    end
    local n = tonumber(data.count) or 0
    local cap = tonumber(data.maxCount)
    return cap ~= nil and n >= cap
end

local function npcCost(count)
    local n = math.clamp(tonumber(count) or 0, 0, NPC_MAX)
    if n >= NPC_MAX then
        return nil
    end
    local used = math.max(n, 1)
    return math.ceil(1.25 ^ (used - 1) * 5)
end

local function shopCost(data, kind)
    if not data then
        return nil
    end
    local cost = tonumber(data.cost)
    if cost then
        return cost
    end
    if kind == "npc" then
        return npcCost(data.count)
    end
    return nil
end

local skillState = {
    cache = nil,
    lastGet = 0,
    gumMark = 0,
}

local function localGum()
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    local g = ls and ls:FindFirstChild("Gum")
    return tonumber(g and g.Value) or 0
end

local function runShopBuys(listName)
    local folder = sidebarShopFolder(listName, nil)
    if not folder then
        return
    end
    local money = playerMoney()
    local bought = 0
    local pending = 0
    for _, frame in ipairs(folder:GetChildren()) do
        if bought >= 3 then
            break
        end
        if frame:IsA("Frame") and frame.Visible and not SHOP_SKIP[frame.Name] then
            local btn = frame:FindFirstChild("ImageButton")
            local costLbl = btn and btn:FindFirstChild("Cost")
            local capLbl = btn and btn:FindFirstChild("Cap")
            local uiCost, uiMax = parseCostText(costLbl and costLbl.Text)
            local owned, cap = parseCapText(capLbl and capLbl.Text)
            local uiLooksMax = uiMax or (owned ~= nil and cap ~= nil and owned >= cap)
            if not uiLooksMax then
                pending += 1
                local spec = guessShopSpec(frame.Name)
                local buyRemote = findRemote(spec.buy) or findRemote("Purchase" .. frame.Name .. "Upgrade")
                local getRemote = resolveGetRemote(frame.Name, spec)
                if buyRemote then
                    local data = nil
                    local kind = spec.kind
                    if getRemote then
                        local getOk, raw = TheKing.Invoke(getRemote)
                        if getOk then
                            data, kind = normalizeShopData(raw, kind)
                        end
                    end
                    local cost = shopCost(data, kind) or uiCost
                    local maxed = isShopMaxed(data, kind)
                    if data == nil then
                        maxed = false
                    end
                    if (not maxed) and cost and cost <= money then
                        local buyOk, res = TheKing.Invoke(buyRemote)
                        if buyOk and type(res) == "table" and res.success == true then
                            bought += 1
                            money = tonumber(res.money) or playerMoney()
                        end
                    end
                end
            end
        end
    end
    if bought > 0 then
        TheKing.Backoff(0)
    elseif pending == 0 then
        TheKing.Backoff(12)
    else
        TheKing.Backoff(6)
    end
end

local function bindShopToggle(tab, title, desc, flag, listName)
    TheKing.BindToggle(tab, {
        Title = title,
        Desc = desc,
        Flag = flag,
        Loop = flag,
        Interval = 1.2,
        OnEnable = function()
            if not sidebarShopFolder(listName, 10) then
                TheKing.Notify({
                    Title = title,
                    Content = "找不到商店列表, 稍后再开",
                    Icon = "alert-triangle",
                })
                return false
            end
        end,
        OnTick = function()
            runShopBuys(listName)
        end,
    })
end

-- ============================================================
-- Tab: 主功能
-- ============================================================
local MainTab = TheKing.NewTab({ Title = "主功能", Icon = "zap" })

do
    MainTab:Toggle({
        Title = "自动清扫",
        Desc = "关入桶动画后按游戏逻辑立刻入桶, 地上新垃圾马上扫",
        Flag = "autoSweep",
        Value = false,
        Callback = function(state)
            if state then
                if not ensureCollector() then
                    TheKing.Notify({
                        Title = "自动清扫",
                        Content = "拿不到游戏清扫函数, 换注入器或重进后再试",
                        Icon = "alert-triangle",
                    })
                    return
                end
                startSweepWatch()
                lastSweepPulse = os.clock()
                TheKing.StartLoop("autoSweep", 0.08, function()
                    if not ensureCollector() then
                        clearSweepConns()
                        TheKing.StopLoop("autoSweep")
                        TheKing.Notify({ Content = "清扫函数丢失, 已停止", Icon = "alert-triangle" })
                        return
                    end
                    sweepBatch(sweepPerTick)
                end, { jitter = false })
                TheKing.Notify({ Content = "自动清扫 已开启" })
            else
                lastSweepPulse = 0
                clearSweepConns()
                TheKing.StopLoop("autoSweep")
            end
        end,
    })
end

MainTab:Slider({
    Title = "每轮清扫数量",
    Desc = "每轮最多扫几件; 动画已关, 可适当调高",
    Value = { Min = 1, Max = 40, Default = 16 },
    Callback = function(value)
        sweepPerTick = math.clamp(math.floor(tonumber(value) or 16), 1, 40)
    end,
})

-- ============================================================
-- Tab: 技能树
-- ============================================================
local SkillTab = TheKing.NewTab({ Title = "技能树", Icon = "diamond" })

do
    SkillTab:Toggle({
        Title = "自动升级技能",
        Desc = "口香糖够、前置已点就升级; 不买 Robux 项也不点声望",
        Flag = "autoSkillUpgrade",
        Value = false,
        Callback = function(state)
            if state then
                if not gumSkillFolder(10) then
                    TheKing.Notify({
                        Title = "自动升级技能",
                        Content = "找不到技能树界面, 稍后再开",
                        Icon = "alert-triangle",
                    })
                    return
                end
                skillState.cache = nil
                skillState.lastGet = 0
                skillState.gumMark = 0
                TheKing.StartLoop("autoSkillUpgrade", 1.2, function()
                    local getRemote = findRemote("GetSkillUpgrades")
                    local buyRemote = findRemote("PurchaseSkillUpgrade")
                    if not (getRemote and buyRemote) then
                        return
                    end
                    local gumNow = localGum()
                    local cache = skillState.cache
                    local stale = cache == nil or (os.clock() - skillState.lastGet) >= 15
                    if cache and gumNow > 0 and gumNow >= skillState.gumMark + math.max(200, skillState.gumMark * 0.08) then
                        stale = true
                    end
                    local data = cache
                    if stale then
                        local ok, raw = TheKing.Invoke(getRemote)
                        if not ok or type(raw) ~= "table" then
                            TheKing.Backoff(6)
                            return
                        end
                        data = raw
                        skillState.cache = raw
                        skillState.lastGet = os.clock()
                        skillState.gumMark = tonumber(raw.gum) or gumNow
                    end
                    local gum = tonumber(data.gum) or 0
                    if gumNow > gum then
                        gum = gumNow
                    end
                    local costs = type(data.costs) == "table" and data.costs or {}
                    local currencies = type(data.currencies) == "table" and data.currencies or {}
                    local purchased = type(data.purchased) == "table" and data.purchased or {}
                    local upgradeFolder = gumSkillFolder(nil)
                    if not upgradeFolder then
                        TheKing.Backoff(4)
                        return
                    end
                    local candidates = {}
                    for _, btn in ipairs(upgradeFolder:GetChildren()) do
                        if btn:IsA("GuiButton") then
                            local name = btn.Name
                            if not SKILL_SKIP[name] and currencies[name] ~= "Robux" then
                                local cost = tonumber(costs[name])
                                if not cost then
                                    local costObj = btn:FindFirstChild("Cost")
                                    cost = costObj and tonumber(costObj.Value) or nil
                                end
                                if cost and cost >= 0 and cost <= gum and skillReqMet(btn, purchased) then
                                    table.insert(candidates, { name = name, cost = cost })
                                end
                            end
                        end
                    end
                    table.sort(candidates, function(a, b)
                        return a.cost < b.cost
                    end)
                    local bought = 0
                    for _, item in ipairs(candidates) do
                        if bought >= 1 then
                            break
                        end
                        if item.cost <= gum then
                            local buyOk, res = TheKing.Invoke(buyRemote, item.name)
                            if buyOk and type(res) == "table" and res.success == true then
                                bought += 1
                                gum = tonumber(res.gum) or (gum - item.cost)
                                skillState.cache = res
                                skillState.lastGet = os.clock()
                                skillState.gumMark = gum
                            end
                        end
                    end
                    if bought == 0 then
                        TheKing.Backoff(10)
                    else
                        TheKing.Backoff(0)
                    end
                end, {
                    wakeIf = function()
                        local gumNow = localGum()
                        return gumNow > 0 and gumNow >= skillState.gumMark + math.max(200, skillState.gumMark * 0.08)
                    end,
                })
                TheKing.Notify({ Content = "自动升级技能 已开启" })
            else
                TheKing.StopLoop("autoSkillUpgrade")
            end
        end,
    })
end

-- ============================================================
-- Tab: 花钱
-- ============================================================
local SpendTab = TheKing.NewTab({ Title = "花钱", Icon = "flag" })

bindShopToggle(
    SpendTab,
    "自动购买污染",
    "买侧栏污染列表里未满且买得起的; 满了不买, 新污染出现再买。不含无限口香糖兑换",
    "autoBuyPollution",
    "Pollution"
)
bindShopToggle(
    SpendTab,
    "自动购买升级",
    "买侧栏升级列表里未满且买得起的; 满级不买, 新升级出现再买",
    "autoBuyUpgrades",
    "Upgrades"
)
bindShopToggle(
    SpendTab,
    "自动购买建造",
    "买侧栏建造列表里未满且买得起的; 满了不买, 新建造出现再买",
    "autoBuyBuild",
    "Build"
)

-- ============================================================
-- Tab: 设置 (骨架标配, 不可删)
-- ============================================================
local SettingsTab = TheKing.NewTab({ Title = "设置", Icon = "settings" })

local function unloadAction()
    TheKing.Confirm({
        Title = "卸载确认",
        Content = "将停止全部功能并销毁界面, 确定吗?",
        OnConfirm = function()
            TheKing.Destroy()
        end,
    })
end

SettingsTab:Keybind({
    Title = "显示/隐藏窗口",
    Desc = "切换主窗口可见性",
    Value = "Delete",
    Callback = function()
        TheKing.Window:Toggle()
    end,
})

SettingsTab:Keybind({
    Title = "卸载脚本",
    Desc = "按下后弹出确认对话框",
    Value = "End",
    Callback = unloadAction,
})

SettingsTab:Button({
    Title = "停止全部功能",
    Desc = "关闭所有自动循环 (不销毁窗口)",
    Icon = "square",
    Callback = function()
        TheKing.StopAll()
        TheKing.Notify({ Content = "已停止全部功能", Icon = "check-circle" })
    end,
})

SettingsTab:Button({
    Title = "卸载脚本",
    Desc = "销毁界面并停止一切",
    Icon = "trash-2",
    Color = Color3.fromRGB(255, 100, 100),
    Callback = unloadAction,
})

TheKing.LoadConfig()
