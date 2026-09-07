--[[
    TheKing HUB [0.2.0] - Project Aura RNG
    RCWTK 引擎生成 | 模板 v1.1
    版本历史: games/project-aura-rng/changelog.md (每次发布追加条目, 语义见该文件)

    功能清单 (改这里, 保持格式):
      主要-自动领取索引: 图鉴里程碑一键领 + 逐条发现奖励
      主要-自动装备最佳: 物品栏 EQUIP BEST 同款包
      主要-自动升级: 天赋树 canUpgrade 通过的节点逐个点

    逆向结论 (关键协议结论写这里, 收工同步到 games/project-aura-rng/intel.md):
      GlobalEvents.createClient().XxxRequest.fire(...)
      IndexClaimAllMilestonesRequest 无参; IndexClaimDiscoveryRequest(entryId)
      EquipBestCharactersRequest 无参; UpgradeRequest(nodeKind 字符串)

    使用方式:
      开发: loadstring(readfile("games/project-aura-rng/hub.luau"))()
      热调试: 改完代码直接重新执行本文件, 旧实例自动自毁让位, 无需手动卸载
      发布: 用构建脚本把 theking.luau 内嵌后单文件化
      静态门: python tools/check_hub.py games/project-aura-rng/hub.luau
]]

local TheKing = loadstring(readfile("lib/theking.luau"))({
    GameName = "Project Aura RNG",
    ScriptVersion = "0.2.0",
})

;(function()

TheKing.Notify({ Content = "TheKing HUB 已加载", Icon = "crown" })

local S = TheKing.Pack({
    net = nil,
    user = nil,
    upReg = nil,
    idxReg = nil,
    failAt = 0,
    status = nil,
})

function S.note(title, desc)
    TheKing.UpdateStatus(S.status, title, desc)
end

function S.fire(ev, a)
    if type(ev) ~= "table" or type(ev.fire) ~= "function" then
        return false
    end
    local ok, err
    if a == nil then
        ok, err = pcall(ev.fire)
    else
        ok, err = pcall(ev.fire, a)
    end
    if not ok then
        warn("[TheKing] 发包失败: " .. tostring(err))
        return false
    end
    return true
end

function S.bind()
    if S.net and S.user then
        return true
    end
    if os.clock() < (S.failAt or 0) then
        return false
    end
    local lp = game:GetService("Players").LocalPlayer
    local rs = game:GetService("ReplicatedStorage")
    local ps = TheKing.WaitChild(lp, "PlayerScripts", 8)
    local ts = ps and TheKing.WaitChild(ps, "TS", 5)
    local userMod = ts and ts:FindFirstChild("modules")
    userMod = userMod and userMod:FindFirstChild("user")
    userMod = userMod and userMod:FindFirstChild("ClientUser")
    local geMod = rs:FindFirstChild("TS")
    geMod = geMod and geMod:FindFirstChild("network")
    geMod = geMod and geMod:FindFirstChild("GlobalEvents")
    if not (userMod and geMod) then
        S.failAt = os.clock() + 8
        S.note("状态: 未就绪", "找不到游戏模块, 过几秒再试")
        return false
    end
    local okU, userWrap = pcall(require, userMod)
    local okN, geWrap = pcall(require, geMod)
    if not (okU and okN) then
        S.failAt = os.clock() + 8
        S.note("状态: 未就绪", "require 失败")
        return false
    end
    local user = userWrap.ClientUser or userWrap
    local ge = geWrap.GlobalEvents or geWrap
    local okC, client = pcall(ge.createClient)
    if not (okC and type(client) == "table" and type(user) == "table") then
        S.failAt = os.clock() + 8
        S.note("状态: 未就绪", "createClient 失败")
        return false
    end
    S.user = user
    S.net = client
    local reg = rs.TS and rs.TS:FindFirstChild("registry")
    local ur = reg and reg:FindFirstChild("UpgradeRegistry")
    local ir = reg and reg:FindFirstChild("IndexRegistry")
    if ur then
        local okR, wrap = pcall(require, ur)
        if okR then
            S.upReg = wrap.UpgradeRegistry or wrap
        end
    end
    if ir then
        local okR, wrap = pcall(require, ir)
        if okR then
            S.idxReg = wrap.IndexRegistry or wrap
        end
    end
    return true
end

function S.tickIndex()
    if not S.bind() then
        return
    end
    local net, user = S.net, S.user
    local idx = user.index
    if type(idx) ~= "table" then
        S.note("索引: 异常", "ClientUser.index 不存在")
        return
    end
    local nMile = 0
    local okM, mile = pcall(function()
        return idx:getTotalClaimableMilestoneCount()
    end)
    if okM and type(mile) == "number" then
        nMile = mile
    end
    if nMile > 0 then
        S.fire(net.IndexClaimAllMilestonesRequest)
        S.note("索引: 领里程碑", "本轮可领 " .. tostring(nMile) .. " 档")
        return
    end
    local providers = S.idxReg and S.idxReg.providers
    if type(providers) ~= "table" then
        S.note("索引: 待命", "没有可领的奖励")
        TheKing.Backoff(4)
        return
    end
    for domain in pairs(providers) do
        local okV, views = pcall(function()
            return idx:getEntryViews(domain)
        end)
        if okV and type(views) == "table" then
            for i = 1, #views do
                local view = views[i]
                if type(view) == "table" and view.discoveryClaimable and view.entryId then
                    S.fire(net.IndexClaimDiscoveryRequest, view.entryId)
                    S.note("索引: 领发现", tostring(view.entryId))
                    return
                end
            end
            for i = 1, #views do
                local view = views[i]
                if type(view) == "table" and view.hasClaimable and view.entryId and not view.discoveryClaimable then
                    S.fire(net.IndexClaimMilestoneRequest, view.entryId)
                    S.note("索引: 领条目里程碑", tostring(view.entryId))
                    return
                end
            end
        end
    end
    S.note("索引: 待命", "没有可领的奖励")
    TheKing.Backoff(5)
end

function S.tickEquip()
    if not S.bind() then
        return
    end
    S.fire(S.net.EquipBestCharactersRequest)
    S.note("装备: 已请求最佳", "走物品栏 EQUIP BEST 同款包")
end

function S.tickUpgrade()
    if not S.bind() then
        return
    end
    local content = S.upReg and S.upReg.content
    local ups = S.user.upgrades
    if type(content) ~= "table" or type(ups) ~= "table" then
        S.note("升级: 异常", "天赋表或用户模块缺失")
        return
    end
    for kind in pairs(content) do
        local ok, res = pcall(function()
            return ups:canUpgrade(kind)
        end)
        if ok and type(res) == "table" and res.success then
            S.fire(S.net.UpgradeRequest, kind)
            S.note("升级: 点节点", tostring(kind))
            return
        end
    end
    S.note("升级: 待命", "当前没有可点的天赋 (钱不够或未解锁)")
    TheKing.Backoff(6)
end

local MainTab = TheKing.NewTab({ Title = "主要", Icon = "zap" })

S.status = MainTab:Paragraph({
    Title = "状态: 待命",
    Desc = "打开下方开关后开始; 发包走游戏自己的按钮通道",
})

TheKing.BindToggle(MainTab, {
    Title = "自动领取索引",
    Desc = "领取图鉴里所有可领奖励 (全里程碑 + 发现奖励)",
    Flag = "autoIndexClaim",
    Interval = 0.7,
    OnEnable = function()
        return S.bind()
    end,
    OnTick = function()
        S.tickIndex()
    end,
})

TheKing.BindToggle(MainTab, {
    Title = "自动装备最佳",
    Desc = "自动点物品栏里的装备最佳",
    Flag = "autoEquipBest",
    Interval = 2,
    OnEnable = function()
        return S.bind()
    end,
    OnTick = function()
        S.tickEquip()
    end,
})

TheKing.BindToggle(MainTab, {
    Title = "自动升级",
    Desc = "自动点升级界面天赋树里当前能点的节点",
    Flag = "autoUpgrade",
    Interval = 0.55,
    OnEnable = function()
        return S.bind()
    end,
    OnTick = function()
        S.tickUpgrade()
    end,
})

local TeleportTab = TheKing.NewTab({ Title = "传送", Icon = "map-pin" })

TeleportTab:Paragraph({
    Title = "传送",
    Desc = "候选通道 TeleportToPlotRequest (回地块), 参数未验证, 先别乱发。",
})

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
