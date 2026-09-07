--[[
    TheKing HUB [0.3.0] - Cultivation: Evermortal
    RCWTK 引擎生成 | 模板 v1.1
    版本历史: games/cultivation-evermortal/changelog.md (每次发布追加条目, 语义见该文件)

    功能清单 (改这里, 保持格式):
      自动: 自动冥想 (切到修炼页 → 点 MEDITATE → 指针进金色芯点左键)
      自动: 自动克服困难 (气够点突破 Orb/渡劫)
      自动: 自动磨练肉体 (气够且磨练钮亮起时点 REFINE FLESH)
      自动: 自动升级技巧 (气够点技巧页 CULTIVATE, 跳过玉/已圆满)
      自动: 自动滚动天赋 (点 ROLL TALENT, 不用天道玉抽)
      自动: 装备最佳天赋 (拥有里最稀有, 已穿则跳过)

    逆向结论 (关键协议结论写这里, 收工同步到 games/cultivation-evermortal/intel.md):
      - 入口: Root.Nav.Cultivate + Root.Content.Cultivate.Actions.Meditate
      - QTE: AscensionUI.Meditate; Groove.Zone=绿, Zone.Core=金; Hit.MouseButton1Down=MeditateGame.tap
      - 突破: BreakCluster.Orb / Tribulation; 磨练: BreakCluster.Refine
      - 技巧: Techniques.Grid.*.BuyOne CULTIVATE; 天赋: Talents.Roll + Owned.*.Hit + Detail.Equip
      - 不直调 Knit RF (参数未逐项验证); 走按钮连接

    使用方式:
      开发: loadstring(readfile("games/cultivation-evermortal/hub.luau"))()
      热调试: 改完代码直接重新执行本文件, 旧实例自动自毁让位, 无需手动卸载
      发布: 用构建脚本把 theking.luau 内嵌后单文件化
      静态门: python tools/check_hub.py games/cultivation-evermortal/hub.luau
]]

local TheKing = loadstring(readfile("lib/theking.luau"))({
    GameName = "Cultivation: Evermortal",
    ScriptVersion = "0.3.0",
})

;(function()

TheKing.Notify({ Content = "TheKing HUB 已加载", Icon = "crown" })

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

local Ui = TheKing.Pack({})
local Med = TheKing.Pack({
    on = false,
    armedAt = 0,
    lastEnter = 0,
    lastNav = 0,
    inCore = false,
    clickedBeat = false,
})
local Auto = TheKing.Pack({
    breakOn = false,
    fleshOn = false,
    techOn = false,
    rollOn = false,
    equipOn = false,
    lastBreak = 0,
    lastFlesh = 0,
    lastTech = 0,
    lastRoll = 0,
    lastEquip = 0,
    lastPick = "",
})

function Ui.asc()
    local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    return pg and pg:FindFirstChild("AscensionUI")
end

function Ui.root()
    local a = Ui.asc()
    return a and a:FindFirstChild("Root")
end

function Ui.page(name)
    local r = Ui.root()
    local content = r and r:FindFirstChild("Content")
    return content and content:FindFirstChild(name)
end

function Ui.strip(s)
    s = tostring(s or "")
    s = string.gsub(s, "<[^>]+>", "")
    return s
end

function Ui.parseAmount(s)
    s = string.lower(Ui.strip(s))
    local num, suf = string.match(s, "([%d%.]+)%s*([kmbt]?)")
    local n = tonumber(num)
    if not n then
        return nil
    end
    if suf == "k" then
        n *= 1e3
    elseif suf == "m" then
        n *= 1e6
    elseif suf == "b" then
        n *= 1e9
    elseif suf == "t" then
        n *= 1e12
    end
    return n
end

function Ui.qi()
    local best = 0
    local tech = Ui.page("Techniques")
    local chip = tech and tech:FindFirstChild("QiChip")
    if chip then
        local lab = chip:FindFirstChild("Value")
        if not lab then
            for _, d in ipairs(chip:GetDescendants()) do
                if d:IsA("TextLabel") and d.Name == "Value" then
                    lab = d
                    break
                end
            end
        end
        if lab then
            best = math.max(best, Ui.parseAmount(lab.Text) or 0)
        end
    end
    local cult = Ui.page("Cultivate")
    local q = cult and cult:FindFirstChild("Qi")
    if q then
        best = math.max(best, Ui.parseAmount(q.Text) or 0)
    end
    return best
end

function Ui.fire(btn, sigName)
    if not (btn and btn.Parent) then
        return false
    end
    local sig
    pcall(function()
        sig = btn[sigName]
    end)
    if typeof(sig) ~= "RBXScriptSignal" then
        return false
    end
    if type(getconnections) == "function" then
        local ok, cons = pcall(getconnections, sig)
        if ok and type(cons) == "table" and #cons > 0 then
            for _, c in ipairs(cons) do
                pcall(function()
                    if c.Fire then
                        c:Fire()
                    elseif type(c.Function) == "function" then
                        c.Function()
                    end
                end)
            end
            return true
        end
    end
    if type(firesignal) == "function" then
        return pcall(firesignal, sig)
    end
    return false
end

function Ui.lmbAt(x, y)
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
    end)
    if type(mouse1press) == "function" then
        pcall(mouse1press)
    end
    task.defer(function()
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
        end)
        if type(mouse1release) == "function" then
            pcall(mouse1release)
        end
    end)
end

function Ui.click(btn, sigName)
    if not (btn and btn:IsA("GuiObject") and btn.Visible) then
        return false
    end
    local fired = Ui.fire(btn, sigName or "MouseButton1Click")
    local inset = Vector2.zero
    pcall(function()
        inset = GuiService:GetGuiInset()
    end)
    local p = btn.AbsolutePosition
    local s = btn.AbsoluteSize
    Ui.lmbAt(p.X + s.X * 0.5, p.Y + s.Y * 0.5 + inset.Y)
    return fired
end

function Med.ui()
    return Ui.asc()
end

function Med.panel()
    local ui = Ui.asc()
    return ui and ui:FindFirstChild("Meditate")
end

function Med.inSession()
    local p = Med.panel()
    return p and p.Visible == true
end

function Med.coreAndNeedle()
    local p = Med.panel()
    if not p then
        return nil
    end
    local track = p:FindFirstChild("Track")
    local groove = track and track:FindFirstChild("Groove")
    local zone = groove and groove:FindFirstChild("Zone")
    local core = zone and zone:FindFirstChild("Core")
    local needle = groove and groove:FindFirstChild("Needle")
    if core and needle then
        return core, needle
    end
    return nil
end

function Med.needleInCore()
    local core, needle = Med.coreAndNeedle()
    if not (core and needle) then
        return false
    end
    local nx = needle.AbsolutePosition.X + needle.AbsoluteSize.X * 0.5
    local x0 = core.AbsolutePosition.X
    local x1 = x0 + core.AbsoluteSize.X
    return nx >= x0 and nx <= x1
end

function Med.ensurePage()
    local page = Ui.page("Cultivate")
    if page and page.Visible then
        return true
    end
    if os.clock() - Med.lastNav < 1 then
        return false
    end
    local r = Ui.root()
    local nav = r and r:FindFirstChild("Nav")
    local tab = nav and nav:FindFirstChild("Cultivate")
    if tab then
        Med.lastNav = os.clock()
        Ui.click(tab, "MouseButton1Click")
    end
    return page and page.Visible == true
end

function Med.ensureOpen()
    if not Med.on then
        return
    end
    if os.clock() < Med.armedAt then
        return
    end
    if Med.inSession() then
        return
    end
    if os.clock() - Med.lastEnter < 1.2 then
        return
    end
    if not Med.ensurePage() then
        return
    end
    local cult = Ui.page("Cultivate")
    local actions = cult and cult:FindFirstChild("Actions")
    local btn = actions and actions:FindFirstChild("Meditate")
    if not btn or not btn.Visible then
        return
    end
    Med.lastEnter = os.clock()
    Med.inCore = false
    Med.clickedBeat = false
    TheKing.Guard(function()
        Ui.click(btn, "MouseButton1Click")
    end, "进冥想")
end

function Med.tapGold()
    if not Med.on or not Med.inSession() then
        Med.inCore = false
        Med.clickedBeat = false
        return
    end
    if os.clock() < Med.armedAt then
        return
    end
    local hit = false
    pcall(function()
        hit = Med.needleInCore()
    end)
    if not hit then
        Med.inCore = false
        Med.clickedBeat = false
        return
    end
    if Med.inCore and Med.clickedBeat then
        return
    end
    Med.inCore = true
    Med.clickedBeat = true
    TheKing.Guard(function()
        local p = Med.panel()
        local hitBtn = p and p:FindFirstChild("Hit")
        if hitBtn then
            Ui.fire(hitBtn, "MouseButton1Down")
        end
        local core = Med.coreAndNeedle()
        if core then
            local inset = Vector2.zero
            pcall(function()
                inset = GuiService:GetGuiInset()
            end)
            local pos = core.AbsolutePosition
            local sz = core.AbsoluteSize
            Ui.lmbAt(pos.X + sz.X * 0.5, pos.Y + sz.Y * 0.5 + inset.Y)
        end
    end, "冥想点金")
end

function Auto.cluster()
    local cult = Ui.page("Cultivate")
    return cult and cult:FindFirstChild("BreakCluster")
end

function Auto.breakReady()
    local cult = Ui.page("Cultivate")
    if not cult then
        return false
    end
    local lab = cult:FindFirstChild("ProgressLabel")
    local t = string.lower(Ui.strip(lab and lab.Text or ""))
    if string.find(t, "ready", 1, true) then
        return true
    end
    local a, b = string.match(t, "([%d%.]+%s*[kmbt]?)%s*/%s*([%d%.]+%s*[kmbt]?)")
    local x, y = Ui.parseAmount(a), Ui.parseAmount(b)
    if x and y then
        return x + 0.01 >= y
    end
    return false
end

function Auto.breakBtn()
    local bc = Auto.cluster()
    if not bc then
        return nil
    end
    local trib = bc:FindFirstChild("Tribulation")
    if trib and trib.Visible then
        return trib
    end
    local orb = bc:FindFirstChild("Orb")
    if orb and orb.Visible then
        return orb
    end
    local cult = Ui.page("Cultivate")
    local act = cult and cult:FindFirstChild("Actions")
    local btn = act and act:FindFirstChild("Breakthrough")
    if btn and btn.Visible then
        return btn
    end
    return nil
end

function Auto.tickBreak()
    if not Auto.breakOn then
        return
    end
    if os.clock() - Auto.lastBreak < 0.7 then
        return
    end
    if not Auto.breakReady() then
        return
    end
    local btn = Auto.breakBtn()
    if not btn then
        return
    end
    Auto.lastBreak = os.clock()
    TheKing.Guard(function()
        Ui.fire(btn, "MouseButton1Click")
    end, "克服困难")
end

function Auto.tickFlesh()
    if not Auto.fleshOn then
        return
    end
    if os.clock() - Auto.lastFlesh < 0.7 then
        return
    end
    local bc = Auto.cluster()
    local refine = bc and bc:FindFirstChild("Refine")
    if not (refine and refine.Visible) then
        return
    end
    local costLab = refine:FindFirstChild("Cost")
    local cost = Ui.parseAmount(costLab and costLab.Text or "")
    if cost and cost > Ui.qi() + 0.01 then
        return
    end
    Auto.lastFlesh = os.clock()
    TheKing.Guard(function()
        Ui.fire(refine, "MouseButton1Click")
    end, "磨练肉体")
end

function Auto.tickTech()
    if not Auto.techOn then
        return
    end
    if os.clock() - Auto.lastTech < 0.45 then
        return
    end
    local page = Ui.page("Techniques")
    local grid = page and page:FindFirstChild("Grid")
    if not grid then
        return
    end
    local wallet = Ui.qi()
    for _, card in ipairs(grid:GetChildren()) do
        local buy = card:FindFirstChild("BuyOne")
        if buy then
            local label = string.lower(Ui.strip(buy.Text))
            local costT = Ui.strip(card:FindFirstChild("Cost") and card.Cost.Text or "")
            local lowCost = string.lower(costT)
            if string.find(label, "cultivate", 1, true)
                and not string.find(label, "perfect", 1, true)
                and not string.find(label, "transcribe", 1, true)
                and not string.find(lowCost, "jade", 1, true)
                and not string.find(lowCost, "perfect", 1, true)
            then
                local cost = Ui.parseAmount(costT)
                if cost and cost <= wallet + 0.01 then
                    Auto.lastTech = os.clock()
                    TheKing.Guard(function()
                        Ui.fire(buy, "MouseButton1Click")
                    end, "升级技巧")
                    return
                end
            end
        end
    end
end

function Auto.tickRoll()
    if not Auto.rollOn then
        return
    end
    if os.clock() - Auto.lastRoll < 0.65 then
        return
    end
    local page = Ui.page("Talents")
    if not page then
        return
    end
    local gate = page:FindFirstChild("Gate")
    if gate and gate.Visible then
        return
    end
    local btn = page:FindFirstChild("Roll")
    if not btn then
        return
    end
    Auto.lastRoll = os.clock()
    TheKing.Guard(function()
        Ui.fire(btn, "MouseButton1Click")
    end, "滚动天赋")
end

function Auto.rarityScore(card)
    local lab = card:FindFirstChild("Rarity")
    local t = string.lower(Ui.strip(lab and lab.Text or ""))
    local ranks = {
        common = 1,
        uncommon = 2,
        rare = 3,
        epic = 4,
        legendary = 5,
        mythic = 6,
        immortal = 7,
        divine = 8,
        secret = 9,
    }
    for name, score in pairs(ranks) do
        if string.find(t, name, 1, true) then
            return score
        end
    end
    local n = string.match(t, "1%s*in%s*([%d,]+)")
    if n then
        n = tonumber((string.gsub(n, ",", ""))) or 0
        if n >= 100000 then
            return 8
        elseif n >= 20000 then
            return 6
        elseif n >= 5000 then
            return 5
        elseif n >= 500 then
            return 4
        elseif n >= 50 then
            return 3
        elseif n >= 10 then
            return 2
        end
        return 1
    end
    return 0
end

function Auto.tickEquip()
    if not Auto.equipOn then
        return
    end
    if os.clock() - Auto.lastEquip < 1.1 then
        return
    end
    local page = Ui.page("Talents")
    local owned = page and page:FindFirstChild("Owned")
    if not owned then
        return
    end
    local best, bestScore, bestName = nil, -1, ""
    for _, card in ipairs(owned:GetChildren()) do
        if card:IsA("GuiObject") and card.Visible then
            local score = Auto.rarityScore(card)
            if score > bestScore then
                bestScore = score
                best = card
                local title = card:FindFirstChild("TitleText")
                bestName = Ui.strip(title and title.Text or card.Name)
            end
        end
    end
    if not best or bestScore < 1 then
        return
    end
    local det = page:FindFirstChild("Detail")
    local eq = det and det:FindFirstChild("Equip")
    local worn = false
    if eq then
        local cap = eq:FindFirstChild("Caption")
        worn = string.find(string.lower(Ui.strip(cap and cap.Text or "")), "worn", 1, true) ~= nil
    end
    local sel = det and det:FindFirstChild("TalentName")
    local selName = Ui.strip(sel and sel.Text or "")
    if worn and selName ~= "" and string.find(string.lower(selName), string.lower(bestName), 1, true) then
        return
    end
    Auto.lastEquip = os.clock()
    TheKing.Guard(function()
        if Auto.lastPick ~= best.Name then
            local hit = best:FindFirstChild("Hit")
            if hit then
                if not Ui.fire(hit, "MouseButton1Click") then
                    Ui.fire(hit, "MouseButton1Down")
                end
            end
            Auto.lastPick = best.Name
            return
        end
        if eq and not worn then
            Ui.fire(eq, "MouseButton1Click")
        end
    end, "装备天赋")
end

-- ============================================================
-- Tab: 自动
-- ============================================================
local AutoTab = TheKing.NewTab({ Title = "自动", Icon = "zap" })

TheKing.BindToggle(AutoTab, {
    Title = "自动冥想",
    Desc = "自动打开坐忘, 指针进金色芯时点左键 (金心双倍)",
    Flag = "autoMeditate",
    Interval = 0.4,
    Jitter = false,
    OnEnable = function()
        Med.on = true
        Med.armedAt = os.clock() + 0.8
        Med.lastEnter = 0
        Med.inCore = false
        Med.clickedBeat = false
        TheKing.BindStepped("autoMeditateQte", "heartbeat", function()
            Med.tapGold()
        end)
        return true
    end,
    OnDisable = function()
        Med.on = false
        TheKing.UnbindStepped("autoMeditateQte")
    end,
    OnTick = function()
        Med.ensureOpen()
    end,
})

TheKing.BindToggle(AutoTab, {
    Title = "自动克服困难",
    Desc = "气够突破时点修炼球 / 渡劫 (法修境界)",
    Flag = "autoBreakthrough",
    Interval = 0.5,
    Jitter = false,
    OnEnable = function()
        Auto.breakOn = true
        Auto.lastBreak = os.clock() + 0.4
        return true
    end,
    OnDisable = function()
        Auto.breakOn = false
    end,
    OnTick = function()
        Auto.tickBreak()
    end,
})

TheKing.BindToggle(AutoTab, {
    Title = "自动磨练肉体",
    Desc = "磨练钮亮起且气够时点 REFINE FLESH (肉身境界)",
    Flag = "autoRefineFlesh",
    Interval = 0.5,
    Jitter = false,
    OnEnable = function()
        Auto.fleshOn = true
        Auto.lastFlesh = os.clock() + 0.4
        return true
    end,
    OnDisable = function()
        Auto.fleshOn = false
    end,
    OnTick = function()
        Auto.tickFlesh()
    end,
})

TheKing.BindToggle(AutoTab, {
    Title = "自动升级技巧",
    Desc = "气够就升级技巧页 CULTIVATE, 跳过已圆满和玉石抄录",
    Flag = "autoTechniques",
    Interval = 0.5,
    Jitter = false,
    OnEnable = function()
        Auto.techOn = true
        Auto.lastTech = os.clock() + 0.4
        return true
    end,
    OnDisable = function()
        Auto.techOn = false
    end,
    OnTick = function()
        Auto.tickTech()
    end,
})

TheKing.BindToggle(AutoTab, {
    Title = "自动滚动天赋",
    Desc = "自动点 ROLL TALENT; 不用天道抽 (HEAVENLY ROLL)",
    Flag = "autoRollTalent",
    Interval = 0.5,
    Jitter = false,
    OnEnable = function()
        Auto.rollOn = true
        Auto.lastRoll = os.clock() + 0.4
        return true
    end,
    OnDisable = function()
        Auto.rollOn = false
    end,
    OnTick = function()
        Auto.tickRoll()
    end,
})

TheKing.BindToggle(AutoTab, {
    Title = "装备最佳天赋",
    Desc = "在已拥有里选最稀有并装备, 已穿则不动",
    Flag = "autoEquipTalent",
    Interval = 0.6,
    Jitter = false,
    OnEnable = function()
        Auto.equipOn = true
        Auto.lastEquip = os.clock() + 0.4
        Auto.lastPick = ""
        return true
    end,
    OnDisable = function()
        Auto.equipOn = false
    end,
    OnTick = function()
        Auto.tickEquip()
    end,
})

-- ============================================================
-- Tab: 传送
-- ============================================================
local TeleportTab = TheKing.NewTab({ Title = "传送", Icon = "map-pin" })

TeleportTab:Button({
    Title = "尚未收录地点",
    Desc = "坐标未逆向",
    Icon = "map-pin",
    Callback = function()
        TheKing.Notify({ Content = "还没有传送点", Icon = "info" })
    end,
})

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

end)()
