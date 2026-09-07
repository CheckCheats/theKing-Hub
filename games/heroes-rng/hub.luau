--[[
    TheKing HUB [1.0.0] - Heroes RNG
    RCWTK 引擎生成 | 移植自 heroes-rng-nl.luau v0.0.6 (Neverlose -> WindUI)

    功能清单:
      自动攻击: 静默点击 (低血量/高价值优先, 击杀切换/轮流/范围打击三种模式, 速率/范围可调)
      自动BOSS: 刷新自动入场, 击杀自动返回, 支持提前入场秒数, 实时状态显示
      防挂机:   吞切服请求 + 引擎闲置模拟输入 + 定期真人活动 [L2: hook Network]
      防滚动:   替换 RollingView 跳过抽取动画直接显示结果 [L2: hook 游戏函数]
      自动升级: 金币天赋树全节点扫描可购买即激活 (pending 防重复, 含二层分支)
      自动声望: 等级达标自动转生 (60s 冷却)
      自动力量: 充能阈值自动使用力量 (可设百分比, 接管游戏内自动开关)
      自动装备: 按 DPS 自动装备最强英雄至上限 (接管游戏内自动装备)
      保护屏幕: 除挂机界面外全屏黑屏防烧屏
      土豆模式: 关阴影禁特效白色光照, 每30秒对新区域补刀
      传送:     4设施(自动打开界面) + BOSS岛 + 12地区, 5秒冷却
      设置:     显示隐藏 DEL / 卸载 END / 停止全部

    逆向结论 (同步自 intel.md):
      - Network.FireServer(name,...)/InvokeServer 为游戏统一网络层封装
      - ReportClickAttack 限速 {15,1}; RequestZoneTeleport {5,5}; PrestigeRequested {5,1}
      - EquipHero/UnequipHero {30,1} -> 每轮最多处理 2 个操作
      - AfkRejoin IdleSeconds=1020s 触发 RequestAfkRejoin 切服
      - BOSS 实体 zone=WorldBoss slot=1000, 传送入口提前 300s 开放 (Warning 阶段)
      - require 缓存共享: 替换 RollingView.PlayRoll 立即对全部抽取路径生效
      - GetPowerState/SetPowerArmed/SetSetting 可直接驱动力量与自动化设置

    使用方式:
      开发: execute 本文件, theking.luau 从候选路径自动加载
      热调试: 改完直接重新 execute, 旧实例自毁让位
]]

-- ==================== 运行库加载 (多候选路径) ====================
local function loadTheKing()
    local errs = {}
    for _, p in ipairs({
        "theking.luau",                              -- Real workspace 根 (开发态主路)
        "D:/BuildProject/RoLua/Core/lib/theking.luau", -- 本机绝对路径 (沙箱外注入器)
    }) do
        local ok, loader = pcall(function()
            return loadstring(readfile(p))
        end)
        if ok and type(loader) == "function" then
            return loader
        end
        errs[#errs + 1] = p .. " -> " .. tostring(loader)
    end
    error("[Heroes RNG] theking.luau 加载失败:\n" .. table.concat(errs, "\n"), 0)
end

local TheKing = loadTheKing()({
    GameName = "Heroes RNG", -- 与 intel.md front matter game 字段逐字一致 (隔离键)
    ScriptVersion = "1.0.0",
})

-- ==================== 游戏模块 ====================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local Shared, Network, Enemies, Upgrades, Inventory, Fusion
do
    local ok, err = pcall(function()
        Shared = require(ReplicatedStorage.shared.Shared)
        Network = require(ReplicatedStorage.client.Network.Network)
        Enemies = require(ReplicatedStorage.client.Enemies.Enemies)
        Upgrades = require(ReplicatedStorage.client.Upgrades.Upgrades)
        Inventory = require(ReplicatedStorage.client.Inventory.Inventory)
        Fusion = require(ReplicatedStorage.client.Fusion.Fusion)
    end)
    if not ok then
        TheKing.Notify({ Title = "加载失败", Content = "游戏模块不可用, 可能已更新: " .. tostring(err), Icon = "alert-triangle", Duration = 8 })
        error("[Heroes RNG] 游戏模块加载失败: " .. tostring(err), 0)
    end
end
local Artifacts = require(ReplicatedStorage.client.Artifacts.Artifacts)
local Runes = require(ReplicatedStorage.client.Runes.Runes)
local Sound = require(ReplicatedStorage.client.Sound.Sound)
local BossesClient = require(ReplicatedStorage.client.Bosses.Bosses)
local BossesShared = require(ReplicatedStorage.shared.Bosses.Bosses)
local PrestigeClient = require(ReplicatedStorage.client.Prestige.Prestige)
local Heroes = Shared.Heroes
local Config = Shared.Config

TheKing.Notify({ Content = "TheKing HUB 已加载 (Heroes RNG)", Icon = "crown" })

-- ==================== 设置表 (逻辑状态; UI 持久化由 Flag 接管) ====================
local Settings = {
    Enabled = false,
    Range = 100,
    Rate = 8,
    TargetPriority = "LowHP",
    KillSwitchMode = true,
    AoeAttack = false,
    AutoBoss = false,
    BossEarlyEntry = 0,
    AntiAfk = false,
    AntiScroll = false,
    ScreenProtect = false,
    PotatoMode = false,
    AutoUpgrade = false,
    AutoUpgradeTick = 2,
    AutoUpgradeMax = 5,
    AutoPrestige = false,
    AutoPower = false,
    AutoPowerPercent = 100,
    AutoEquipHero = false,
}

-- ==================== 复刻游戏伤害计算 ====================
local function getTotalDps()
    local equipped = Inventory.GetEquipped()
    if not equipped or #equipped == 0 then return 0 end
    local owned = Upgrades.GetOwned()
    local prestige = Upgrades.GetPrestigeOwned()
    local heroAtkSpd = Shared.GetStat("HeroAttackSpeed", owned, prestige, 1)
    local speedMul = heroAtkSpd * (LocalPlayer:GetAttribute("EventHeroAttackSpeedMul") or 1)
    local dmgMul = LocalPlayer:GetAttribute("EventHeroDamageMul") or 1
    local total = 0
    for _, v in ipairs(equipped) do
        local hero = Heroes.Get(v.HeroId)
        if hero then
            local attackSpeed = hero.AttackSpeed or Config.HeroDefaultAttackSpeed
            local asMul = speedMul * Artifacts.GetInstanceMul(v.HeroId, v.Size, v.InstanceId, "HeroAttackSpeed")
            local interval = attackSpeed / math.max(asMul * Runes.GetInstanceMul(v.HeroId, v.Size, v.InstanceId, "HeroAttackSpeed"), 1e-6)
            local lvl = Inventory.GetInstanceLevel(v.HeroId, v.Size, v.InstanceId)
            local atk = Heroes.GetCombatATK(v.HeroId, lvl, v.Size, Inventory.GetBestOwnedDps()) * Shared.GetStat("HeroDamage", owned, prestige, 1)
            atk = atk * Shared.IndexRewards.GetPlayerMul(LocalPlayer, "HeroDamage")
            atk = atk * Shared.Guilds.GetPlayerMul(LocalPlayer, "Damage") * dmgMul
            atk = atk * Fusion.GetInstanceStarMul(v.HeroId, v.Size, v.InstanceId)
            atk = atk * Artifacts.GetInstanceMul(v.HeroId, v.Size, v.InstanceId, "HeroDamage")
            atk = atk * Runes.GetInstanceMul(v.HeroId, v.Size, v.InstanceId, "HeroDamage")
            total = total + atk / math.max(interval, 1e-6)
        end
    end
    return total
end

-- ==================== 核心: 静默攻击一个怪物 ====================
local lastHitTime = 0
local function tryHitEnemy(zone, slot, pos)
    local now = os.clock()
    local minInterval = 1 / math.max(Shared.GetStat("ClickAttackMaxPerSec", Upgrades.GetOwned(), Upgrades.GetPrestigeOwned(), 3), 0.001)
    if now - lastHitTime < minInterval then return false end
    lastHitTime = now

    local owned = Upgrades.GetOwned()
    local prestige = Upgrades.GetPrestigeOwned()
    local dpsFrac = Shared.GetStat("ClickAttackDpsFraction", owned, prestige, 0.05)
    local dmg = 1 + dpsFrac * getTotalDps()
    local critChance = Shared.GetStat("ClickAttackCritChance", owned, prestige, 0)
    if critChance > 0 and math.random() < critChance then
        dmg = dmg * Shared.GetStat("ClickAttackCritDamage", owned, prestige, 1.5)
    end

    Enemies.ApplyLocalDamage(zone, slot, dmg)
    Enemies.PlayHitFlash(zone, slot)
    Enemies.PlayHitBump(zone, slot)
    local enemyPos = Enemies.GetPosition(zone, slot) or pos
    if enemyPos then
        Sound.PlayAt("ClickHit", enemyPos)
    end
    Network.FireServer("ReportClickAttack", zone, slot, enemyPos or pos)
    return true
end

-- ==================== 目标选择 ====================
local function getMyPosition()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    return root and root.Position or nil
end

local function collectTargets()
    local zone = Enemies.GetCurrentZone()
    if not zone then return nil, {} end
    local myPos = getMyPosition()
    local targets = {}
    for slot in Enemies.IterateZoneSlots(zone) do
        if Enemies.IsAlive(zone, slot) then
            local hp = Enemies.GetHealth(zone, slot)
            if hp and hp > 0 then
                local pos = Enemies.GetPosition(zone, slot)
                if pos and (not myPos or (pos - myPos).Magnitude <= Settings.Range) then
                    targets[#targets + 1] = { slot = slot, hp = hp, pos = pos }
                end
            end
        end
    end
    table.sort(targets, function(a, b)
        if a.hp ~= b.hp then
            if Settings.TargetPriority == "HighValue" then return a.hp > b.hp end
            return a.hp < b.hp
        end
        return a.slot < b.slot
    end)
    return zone, targets
end

-- ==================== 攻击主循环 ====================
local statePara -- 状态 Paragraph (UI 段创建)
local updateBossStatus -- BOSS 状态刷新 (UI 段赋值, boss 循环调用)

local aoeCursor = 0
local function mainLoop()
    local zone, targets = collectTargets()
    if not zone or #targets == 0 then
        TheKing.UpdateStatus(statePara, "状态: 无目标", "等待怪物出现...")
        return
    end
    local target = targets[1]
    local pos = target.pos or Enemies.GetPosition(zone, target.slot)

    if Settings.AoeAttack then
        aoeCursor = aoeCursor % #targets + 1
        local t = targets[aoeCursor]
        if Settings.Enabled and Enemies.IsAlive(zone, t.slot) then
            tryHitEnemy(zone, t.slot, t.pos)
        end
        TheKing.UpdateStatus(statePara,
            string.format("状态: 范围打击 | 覆盖 %d 只", #targets),
            string.format("目标 %d/%d | 血量: %s", aoeCursor, #targets, tostring(Enemies.GetHealth(zone, t.slot) or "-")))
    elseif Settings.KillSwitchMode then
        if Settings.Enabled and Enemies.IsAlive(zone, target.slot) then
            tryHitEnemy(zone, target.slot, pos)
        end
        TheKing.UpdateStatus(statePara,
            string.format("状态: 攻击中 | 范围内 %d 只", #targets),
            string.format("当前目标血量: %s", tostring(Enemies.GetHealth(zone, target.slot) or "-")))
    else
        for _, t in ipairs(targets) do
            if not Settings.Enabled then break end
            if Enemies.IsAlive(zone, t.slot) then
                tryHitEnemy(zone, t.slot, t.pos)
            end
        end
        TheKing.UpdateStatus(statePara,
            string.format("状态: 攻击中 | 范围内 %d 只", #targets),
            string.format("当前目标血量: %s", tostring(Enemies.GetHealth(zone, target.slot) or "-")))
    end
end

-- 服务器点击限速 (ReportClickRateLimits.ReportClickAttack = {15,1})
local CLICK_RATE_LIMIT = 15
pcall(function()
    local lim = Config.RemoteRateLimits and Config.RemoteRateLimits.ReportClickAttack
    if lim and type(lim[1]) == "number" and lim[1] > 0 then
        CLICK_RATE_LIMIT = lim[1]
    end
end)

--- 攻击速率变更后重启攻击循环 (间隔 = 1/有效速率)
local function restartAttackLoop()
    if not Settings.Enabled then return end
    local effRate = Settings.AoeAttack and math.min(Settings.Rate, CLICK_RATE_LIMIT) or Settings.Rate
    TheKing.StartLoop("attack", 1 / math.max(effRate, 1), mainLoop, { jitter = false })
end

-- ==================== 自动BOSS ====================
local BOSS_ZONE = "WorldBoss"
local BOSS_SLOT = 1000
local bossState = { joined = false, lastTeleport = 0 }

local function formatBossCountdown(seconds)
    seconds = math.max(0, math.floor(seconds))
    return string.format("%dm %02ds", math.floor(seconds / 60), seconds % 60)
end

local function bossTeleport(kind)
    local now = os.clock()
    if now - bossState.lastTeleport < 3 then return false end
    bossState.lastTeleport = now
    bossState.joined = (kind == "Join")
    task.spawn(function()
        pcall(function()
            Network.InvokeServer("RequestArenaTeleport", kind)
        end)
    end)
    return true
end

local function bossLoop()
    if not Settings.AutoBoss then return end
    local serverTime = workspace:GetServerTimeNow()
    local window = BossesShared.GetWindow(serverTime)
    local hasFight = BossesClient.HasLiveFight()
    local inArena = BossesClient.IsPlayerInArena()

    if inArena then
        if not hasFight and bossState.joined then
            bossTeleport("Leave")
        end
        return
    end
    if hasFight then
        bossTeleport("Join")
        return
    end
    if window.phase == "Warning" then
        local countdown = window.spawnEpoch - serverTime
        if countdown <= Settings.BossEarlyEntry then
            bossTeleport("Join")
        end
    end
end

-- ==================== 防挂机 [L2: hook Network] ====================
local VirtualUser = game:GetService("VirtualUser")
local antiAfkInstalled = false
local origFireServer, origInvokeServer

local function simulateClick()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:Button1Down(Vector2.new(0, 0))
        task.wait(0.05)
        VirtualUser:Button1Up(Vector2.new(0, 0))
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end

local function simulateJump()
    pcall(function()
        simulateClick()
        local char = LocalPlayer.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local state = humanoid:GetState()
            if state ~= Enum.HumanoidStateType.Jumping
                and state ~= Enum.HumanoidStateType.Freefall
                and state ~= Enum.HumanoidStateType.Dead then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
end

local function enableAntiAfk()
    if antiAfkInstalled then return end
    antiAfkInstalled = true

    pcall(function()
        -- 挂机阈值 -> 几乎无限 (游戏每 CheckInterval 秒检查一次闲置时间)
        if Config.AfkRejoin then
            Config.AfkRejoin.IdleSeconds = 999999999
            Config.AfkRejoin.CheckInterval = 3600
        end
    end)

    -- Hook 网络层: 吞掉切服请求 (保存原函数, 卸载时还原)
    origFireServer = origFireServer or Network.FireServer
    origInvokeServer = origInvokeServer or Network.InvokeServer
    Network.FireServer = function(name, ...)
        if name == "RequestAfkRejoin" then return nil end
        return origFireServer(name, ...)
    end
    Network.InvokeServer = function(name, ...)
        if name == "RequestAfkRejoin" then return nil end
        return origInvokeServer(name, ...)
    end

    -- Roblox 引擎闲置弹窗防护: Idled 时模拟输入重置计时器
    TheKing.AddConnection(LocalPlayer.Idled:Connect(function()
        simulateClick()
    end))
end

local function disableAntiAfk()
    if not antiAfkInstalled then return end
    antiAfkInstalled = false
    pcall(function()
        if origFireServer then Network.FireServer = origFireServer end
        if origInvokeServer then Network.InvokeServer = origInvokeServer end
        origFireServer, origInvokeServer = nil, nil
        if Config.AfkRejoin then
            Config.AfkRejoin.IdleSeconds = 1020 -- 游戏默认值
            Config.AfkRejoin.CheckInterval = 5
        end
    end)
end

-- ==================== 土豆模式 ====================
local potatoOriginal = {}
local function savePotatoOriginal()
    pcall(function()
        local Lighting = game:GetService("Lighting")
        potatoOriginal.Technology = Lighting.Technology
        potatoOriginal.GlobalShadows = Lighting.GlobalShadows
        potatoOriginal.ShadowSoftness = Lighting.ShadowSoftness
        potatoOriginal.Ambient = Lighting.Ambient
        potatoOriginal.OutdoorAmbient = Lighting.OutdoorAmbient
        potatoOriginal.FogColor = Lighting.FogColor
        potatoOriginal.FogStart = Lighting.FogStart
        potatoOriginal.FogEnd = Lighting.FogEnd
    end)
end

local FX_CLASSES = {
    ParticleEmitter = true, Beam = true, Trail = true,
    PointLight = true, SurfaceLight = true, SpotLight = true,
    Fire = true, Smoke = true, Sparkles = true,
}

local function applyPotatoSettings()
    pcall(function()
        local Lighting = game:GetService("Lighting")
        Lighting.Technology = Enum.Technology.Compatibility
        Lighting.GlobalShadows = false
        Lighting.ShadowSoftness = 0
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.FogColor = Color3.new(1, 1, 1)
        Lighting.FogStart = 0
        Lighting.FogEnd = 1e9
    end)
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if FX_CLASSES[obj.ClassName] and obj.Enabled ~= false then
                obj.Enabled = false
            end
        end
    end)
end

local function revertPotatoSettings()
    pcall(function()
        local Lighting = game:GetService("Lighting")
        if potatoOriginal.Technology then Lighting.Technology = potatoOriginal.Technology end
        if potatoOriginal.GlobalShadows ~= nil then Lighting.GlobalShadows = potatoOriginal.GlobalShadows end
        if potatoOriginal.ShadowSoftness ~= nil then Lighting.ShadowSoftness = potatoOriginal.ShadowSoftness end
        if potatoOriginal.Ambient then Lighting.Ambient = potatoOriginal.Ambient end
        if potatoOriginal.OutdoorAmbient then Lighting.OutdoorAmbient = potatoOriginal.OutdoorAmbient end
        if potatoOriginal.FogColor then Lighting.FogColor = potatoOriginal.FogColor end
        if potatoOriginal.FogStart then Lighting.FogStart = potatoOriginal.FogStart end
        if potatoOriginal.FogEnd then Lighting.FogEnd = potatoOriginal.FogEnd end
    end)
end

-- ==================== 防滚动 [L2: 替换 RollingView] ====================
local antiScrollInstalled = false
local origPlayRoll, origWaitComplete

local function enableAntiScroll()
    if antiScrollInstalled then return end
    local ok, RollingView = pcall(function()
        return require(ReplicatedStorage.client.Rolling.RollingView)
    end)
    if not ok or type(RollingView) ~= "table" or not RollingView.PlayRoll then
        TheKing.Notify({ Content = "防滚动: 找不到 RollingView 模块", Icon = "alert-triangle" })
        return
    end
    origPlayRoll = origPlayRoll or RollingView.PlayRoll
    origWaitComplete = origWaitComplete or RollingView.WaitForRollComplete

    RollingView.PlayRoll = function(col, heroId, size, speedMul, effectOneIn, serial, chance, powerMul, powerBattery)
        pcall(function()
            local Main = LocalPlayer:FindFirstChild("PlayerGui")
            if Main then Main = Main:FindFirstChild("Main") end
            if not Main then return end
            local Rolling = Main:FindFirstChild("Rolling")
            local Frame = Rolling and Rolling:FindFirstChild("Frame")
            local column = Frame and Frame:FindFirstChild("Column" .. col)
            local hero = heroId and Heroes.Get(heroId)
            if column then
                local slots = column:FindFirstChild("Slots")
                for i = 1, 13 do
                    local slot = slots and slots:FindFirstChild("Slot" .. i)
                    if slot then
                        local d = math.abs(i - 1 - 12)
                        local t = math.clamp(d, 0, 1)
                        local s = t * t * (3 - 2 * t)
                        local scale = 1 - s
                        slot.Size = UDim2.fromScale(scale, scale)
                        slot.Position = UDim2.fromScale(0.5, 0.5 + (i - 1 - 12) * 0.55)
                        local img = slot:FindFirstChild("Icon")
                        if img then
                            img.ImageTransparency = s
                            if i == 13 and hero then
                                img.Image = Heroes.GetIcon(heroId)
                            end
                        end
                    end
                end
                local nameLabel = column:FindFirstChild("ItemName")
                if nameLabel and hero then
                    nameLabel.Text = (serial and ("[#" .. serial .. "] ") or "") .. hero.Name
                    nameLabel.TextTransparency = 0
                    nameLabel.TextStrokeTransparency = 0
                end
                local rarityLabel = column:FindFirstChild("ItemRarity")
                if rarityLabel and hero then
                    rarityLabel.Text = Shared.Format.DropChance(Heroes.GetDropChance(heroId))
                    rarityLabel.TextTransparency = 0
                    rarityLabel.TextStrokeTransparency = 0
                end
            end
            if col == 1 and hero and Rolling then
                local rc = Rolling:FindFirstChild("RarityColorFull")
                if rc and Shared.Assets.GetRarityGradient then
                    local g = Shared.Assets.GetRarityGradient(hero.Rarity)
                    if g and g.Color and g.Color.Keypoints and #g.Color.Keypoints > 0 then
                        rc.ImageColor3 = g.Color.Keypoints[math.ceil(#g.Color.Keypoints / 2)].Value
                    end
                end
            end
        end)
    end

    RollingView.WaitForRollComplete = function() end
    antiScrollInstalled = true
    print("[Heroes RNG] 防滚动已启用 - 抽取动画已跳过")
end

local function disableAntiScroll()
    if not antiScrollInstalled then return end
    pcall(function()
        local RollingView = require(ReplicatedStorage.client.Rolling.RollingView)
        if origPlayRoll then RollingView.PlayRoll = origPlayRoll end
        if origWaitComplete then RollingView.WaitForRollComplete = origWaitComplete end
    end)
    antiScrollInstalled = false
    print("[Heroes RNG] 防滚动已关闭 - 恢复抽取动画")
end

-- ==================== 保护屏幕 (防烧屏) ====================
local screenProtectGui = nil
local origHubDisplayOrder = nil

--- 探测 TheKing HUB 自己的 ScreenGui (WindUI 内部引用路径未知, 多处尝试)
local function findHubScreenGui()
    -- WindUI 渲染树 (实测): gethui()/WindUI/Window(Folder) 挂在某个 ScreenGui 下
    local found
    pcall(function()
        local h = type(gethui) == "function" and gethui()
        local w = h and h:FindFirstChild("WindUI")
        local win = w and w:FindFirstChild("Window")
        if win then
            found = win:FindFirstAncestorOfClass("ScreenGui")
        end
    end)
    if found and found:IsA("ScreenGui") then return found end
    -- 兜底: PlayerGui/CoreGui 里 DisplayOrder 最高的非游戏 ScreenGui 不易判定, 放弃精确探测
    return nil
end

local function enableScreenProtect()
    if screenProtectGui then return end
    pcall(function()
        local hubGui = findHubScreenGui()
        if hubGui then
            origHubDisplayOrder = hubGui.DisplayOrder
            hubGui.DisplayOrder = 500
        end
        local sg = Instance.new("ScreenGui")
        sg.Name = "theKingScreenProtect"
        sg.DisplayOrder = 400
        sg.IgnoreGuiInset = true
        sg.ResetOnSpawn = false
        local frame = Instance.new("Frame")
        frame.Name = "Overlay"
        frame.BackgroundColor3 = Color3.new(0, 0, 0)
        frame.BorderSizePixel = 0
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.Parent = sg
        sg.Parent = hubGui and hubGui.Parent or game:GetService("CoreGui")
        screenProtectGui = sg
        if not hubGui then
            TheKing.Notify({ Content = "保护屏幕: 未找到窗口层级, 界面可能被遮挡", Icon = "info" })
        end
    end)
end

local function disableScreenProtect()
    if not screenProtectGui then return end
    pcall(function()
        if screenProtectGui.Parent then screenProtectGui:Destroy() end
        local hubGui = findHubScreenGui()
        if hubGui and origHubDisplayOrder ~= nil then
            hubGui.DisplayOrder = origHubDisplayOrder
        end
        origHubDisplayOrder = nil
        screenProtectGui = nil
    end)
end

-- ==================== 传送 ====================
local TELEPORT_COOLDOWN = 5
local lastTeleportTime = 0
local teleportStatusPara

local function teleportCooldownLeft()
    return math.max(0, TELEPORT_COOLDOWN - (os.clock() - lastTeleportTime))
end

local function setTpStatus(title, desc)
    TheKing.UpdateStatus(teleportStatusPara, title, desc)
end

-- 把玩家放到设施碰撞体上, 触发游戏原生 Touched 打开界面
local function snapToFacility(modelName, label)
    pcall(function()
        local chr = LocalPlayer.Character
        local root = chr and chr:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local model = workspace:FindFirstChild(modelName)
        if not model then
            setTpStatus("传送: 成功", label .. " 设施未找到 (已传送到区域)")
            return
        end
        local part = model:FindFirstChild("Hitbox")
            or (model:IsA("BasePart") and model)
            or model:FindFirstChild("Touch")
            or model.PrimaryPart
        if not part then
            for _, d in ipairs(model:GetDescendants()) do
                if d:IsA("BasePart") then
                    part = d
                    break
                end
            end
        end
        if not part then
            setTpStatus("传送: 成功", label .. " 设施位置未知 (已传送到区域)")
            return
        end
        root.CFrame = part.CFrame * CFrame.new(0, 0, -8)
        task.wait(0.15)
        root.CFrame = part.CFrame
        setTpStatus("传送: 完成", label .. " 已就位, 界面自动打开中...")
    end)
end

local function teleportToFacility(zoneName, modelName, label)
    local cd = teleportCooldownLeft()
    if cd > 0 then
        setTpStatus("传送: 冷却中", string.format("请 %.1f 秒后再试", cd))
        return false
    end
    lastTeleportTime = os.clock()
    setTpStatus("传送: 进行中", string.format("正在传送至 %s (%s)...", zoneName, label))
    task.spawn(function()
        local ok, res = pcall(Network.InvokeServer, "RequestZoneTeleport", zoneName)
        if not ok or res ~= true then
            setTpStatus("传送: 失败", zoneName .. " 未解锁或传送被拒绝")
            return
        end
        setTpStatus("传送: 成功", string.format("已到 %s, 正在定位 %s...", zoneName, label))
        task.wait(1.5)
        snapToFacility(modelName, label)
    end)
    return true
end

local function doTeleport(action, zoneName)
    local cd = teleportCooldownLeft()
    if cd > 0 then
        setTpStatus("传送: 冷却中", string.format("请 %.1f 秒后再试", cd))
        return false
    end
    lastTeleportTime = os.clock()
    setTpStatus("传送: 进行中", "正在请求服务器...")
    task.spawn(function()
        local ok, res = pcall(function()
            if action == "zone" then
                return Network.InvokeServer("RequestZoneTeleport", zoneName)
            else
                return Network.InvokeServer("RequestArenaTeleport", "Join")
            end
        end)
        if not ok then
            setTpStatus("传送: 失败", "远程调用错误: " .. tostring(res))
        elseif res == true or (type(res) == "table" and res.ok) then
            setTpStatus("传送: 成功", zoneName and ("已传送到 " .. zoneName) or "已抵达目标")
        else
            local reason = type(res) == "table" and tostring(res.reason or res.message) or tostring(res)
            setTpStatus("传送: 被拒绝", reason ~= "nil" and reason or "目标未解锁或条件不满足")
        end
    end)
    return true
end

-- ==================== 自动升级 / 自动声望 / 自动力量 / 自动装备 ====================
local upgradePending = {}
local upgradeLastBuy, upgradeLastAffordable, upgradeLastGold = "", 0, 0

local function autoUpgradeTick()
    if not Settings.AutoUpgrade then return end
    local gold = Upgrades.GetGold()
    local owned = Upgrades.GetOwned() or {}
    local now = os.clock()
    for k, t in pairs(upgradePending) do
        if owned[k] then
            upgradePending[k] = nil
        elseif now - t > 30 then
            upgradePending[k] = nil
        end
    end
    local bought, affordable = 0, 0
    for _, id in ipairs(Shared.Upgrades.Order()) do
        if not owned[id] and not upgradePending[id] then
            local state = Shared.Upgrades.GetState(id, owned, gold, nil)
            if state == "Affordable" then
                affordable += 1
                if bought < Settings.AutoUpgradeMax then
                    upgradePending[id] = now
                    Network.FireServer("PurchaseUpgrade", id)
                    upgradeLastBuy = id
                    bought += 1
                end
            end
        end
    end
    upgradeLastAffordable = affordable
    upgradeLastGold = gold
end

local lastPrestigeReqTime = -60
local autoPrestigeStatus = "等待检查"
local function autoPrestigeTick()
    if not Settings.AutoPrestige then return end
    local now = os.clock()
    if now - lastPrestigeReqTime < 60 then
        autoPrestigeStatus = "冷却中"
        return
    end
    local ok, can = pcall(PrestigeClient.CanPrestige)
    if not ok then
        autoPrestigeStatus = "模块异常"
        return
    end
    if can then
        lastPrestigeReqTime = now
        local ok2, err = pcall(PrestigeClient.Request)
        autoPrestigeStatus = ok2 and "已发起转生!" or ("转生失败: " .. tostring(err))
        return
    end
    autoPrestigeStatus = "等级未达标"
end

local powerStatusPara, equipStatusPara
local gameAutoPowerOff, gameAutoEquipOff = false, false

local function autoPowerTick()
    if not Settings.AutoPower then return end
    if not gameAutoPowerOff then
        -- 接管: 关闭游戏内置自动力量, 避免双重触发冲突
        Network.FireServer("SetSetting", "AutoPower", false)
        gameAutoPowerOff = true
    end
    local ok, st = pcall(Network.InvokeServer, "GetPowerState")
    if not ok or type(st) ~= "table" then
        TheKing.UpdateStatus(powerStatusPara, "自动力量: 运行中", "状态读取失败")
        return
    end
    local charge = tonumber(st.charge) or 0
    local capacity = tonumber(st.capacity) or 1
    if capacity <= 0 then return end
    local pct = math.clamp(Settings.AutoPowerPercent or 100, 1, 100) / 100
    if charge >= capacity * pct then
        Network.FireServer("SetPowerArmed", true)
        TheKing.UpdateStatus(powerStatusPara, "自动力量: 运行中",
            string.format("已使用 | 阈值 %d%%", Settings.AutoPowerPercent or 100))
    else
        TheKing.UpdateStatus(powerStatusPara, "自动力量: 运行中",
            string.format("充能 %.1f%% (阈值 %d%%)", charge / capacity * 100, Settings.AutoPowerPercent or 100))
    end
end

local autoEquipStatus = "等待"
local function computeEntryDps(entry)
    local dps = entry.Dps or 0
    if dps > 0 and entry.EquippedInstanceId then
        pcall(function()
            local mul = Artifacts.GetInstanceMul(entry.HeroId, entry.Size, entry.EquippedInstanceId, "HeroDamage")
            if mul and mul > 0 then dps = dps * mul end
        end)
    end
    return dps
end

local function getInstanceId(heroId, size)
    local ok, entry = pcall(Inventory.GetHeroEntry, heroId)
    if not ok or not entry or not entry.Sizes then return nil end
    local szd = entry.Sizes[size]
    if not szd or not szd.Instances then return nil end
    for k in pairs(szd.Instances) do return k end
    return nil
end

local function getMaxEquipped()
    local base = Config.MaxEquippedHeroes or 2
    local add = Shared.GetStat("MaxEquippedHeroes", Upgrades.GetOwned(), Upgrades.GetPrestigeOwned(), 0)
    return base + (add or 0)
end

local function autoEquipTick()
    if not Settings.AutoEquipHero then return end
    if not gameAutoEquipOff then
        -- 接管: 关闭游戏内置自动装备最佳
        Network.FireServer("SetSetting", "AutoEquip", false)
        gameAutoEquipOff = true
    end
    local ok, buckets = pcall(Inventory.GetOwnedBuckets)
    if not ok or type(buckets) ~= "table" or #buckets == 0 then
        autoEquipStatus = "背包为空"
        TheKing.UpdateStatus(equipStatusPara, "自动装备: 运行中", autoEquipStatus)
        return
    end
    local ranked = {}
    for _, b in ipairs(buckets) do
        ranked[#ranked + 1] = {
            heroId = b.HeroId, size = b.Size, stars = b.BestStars,
            instanceId = b.EquippedInstanceId, dps = computeEntryDps(b),
        }
    end
    table.sort(ranked, function(a, b)
        if a.dps ~= b.dps then return a.dps > b.dps end
        return (a.heroId .. "/" .. a.size) < (b.heroId .. "/" .. b.size)
    end)
    local maxEquip = getMaxEquipped()
    local targetKeys = {}
    for i = 1, math.min(maxEquip, #ranked) do
        targetKeys[ranked[i].heroId .. "/" .. ranked[i].size] = true
    end
    local current = Inventory.GetEquipped() or {}
    local handled = 0
    for _, e in ipairs(current) do
        if handled >= 2 then break end
        local key = e.HeroId .. "/" .. e.Size
        if not targetKeys[key] then
            Network.FireServer("UnequipHero", e.HeroId, e.Size, e.InstanceId)
            handled += 1
        end
    end
    local equippedKeys = {}
    for _, e in ipairs(current) do
        equippedKeys[e.HeroId .. "/" .. e.Size] = true
    end
    for _, r in ipairs(ranked) do
        if handled >= 2 then break end
        local key = r.heroId .. "/" .. r.size
        if targetKeys[key] and not equippedKeys[key] then
            local inst = r.instanceId or getInstanceId(r.heroId, r.size)
            if inst then
                Network.FireServer("EquipHero", r.heroId, r.size, r.stars or 0, inst)
                handled += 1
            end
        end
    end
    autoEquipStatus = string.format("出战 %d/%d | 最佳: %s (%.0f DPS)", #current, maxEquip,
        ranked[1] and (ranked[1].heroId .. " " .. ranked[1].size) or "-", ranked[1] and ranked[1].dps or 0)
    TheKing.UpdateStatus(equipStatusPara, "自动装备: 运行中", autoEquipStatus)
end

-- 升级/声望综合状态
local upgradeStatusPara
local function updateUpgradeStatus()
    if not Settings.AutoUpgrade and not Settings.AutoPrestige then return end
    pcall(function()
        local Prestige = Shared.Prestige
        local cur = PrestigeClient.GetCurrent()
        local curInfo = cur and Prestige.Get(cur)
        local curName = (curInfo and curInfo.DisplayName) or tostring(cur)
        local idx = Prestige.GetIndex(cur) or 1
        local rankCount = Prestige.GetRankCount()
        TheKing.UpdateStatus(upgradeStatusPara,
            string.format("金币: %s | 可购买: %d", tostring(upgradeLastGold), upgradeLastAffordable),
            string.format("声望: %s (%d/%d) | 最近: %s | %s",
                curName, idx, rankCount, upgradeLastBuy ~= "" and upgradeLastBuy or "-", autoPrestigeStatus))
    end)
end

-- ==================== 业务清理登记 (卸载/热替换时还原一切) ====================
TheKing.OnCleanup(function()
    disableAntiAfk()
    disableAntiScroll()
    revertPotatoSettings()
    disableScreenProtect()
    gameAutoPowerOff, gameAutoEquipOff = false, false
end)

-- ============================================================
-- Tab: 自动
-- ============================================================
local AutoTab = TheKing.NewTab({ Title = "自动", Icon = "zap" })

local attackTgl, aoeTgl, bossTgl, powerTgl, equipTgl, upgTgl, prestigeTgl
local afkTgl, scrollTgl, protectTgl, potatoTgl

local attackTgl, aoeTgl, bossTgl, powerTgl, equipTgl, upgTgl, prestigeTgl
local afkTgl, scrollTgl, protectTgl, potatoTgl

-- ---- 自动攻击 ----
local AttackSec = AutoTab:Section({ Title = "自动攻击" })

attackTgl = AttackSec:Toggle({
    Title = "静默点击",
    Desc = "按选定的优先级自动攻击附近怪物",
    Value = Settings.Enabled,
    Callback = function(v)
        Settings.Enabled = v
        if v then
            restartAttackLoop()
        else
            TheKing.StopLoop("attack")
            TheKing.UpdateStatus(statePara, "状态: 未启用", "打开开关后自动攻击附近怪物")
        end
    end,
})

local lowHpTgl, highValueTgl
lowHpTgl = AttackSec:Toggle({
    Title = "低血量优先",
    Desc = "先打残血的怪物",
    Value = (Settings.TargetPriority == "LowHP"),
    Callback = function(v)
        if v then
            Settings.TargetPriority = "LowHP"
            pcall(function() highValueTgl:Set(false) end)
        elseif Settings.TargetPriority == "LowHP" then
            Settings.TargetPriority = "HighValue"
            pcall(function() highValueTgl:Set(true) end)
        end
    end,
})
highValueTgl = AttackSec:Toggle({
    Title = "高价值优先",
    Desc = "先打血厚的怪物 (可能精英怪)",
    Value = (Settings.TargetPriority == "HighValue"),
    Callback = function(v)
        if v then
            Settings.TargetPriority = "HighValue"
            pcall(function() lowHpTgl:Set(false) end)
        elseif Settings.TargetPriority == "HighValue" then
            Settings.TargetPriority = "LowHP"
            pcall(function() lowHpTgl:Set(true) end)
        end
    end,
})

AttackSec:Toggle({
    Title = "击杀切换",
    Desc = "连续攻击一个目标, 击杀后换下一个",
    Value = Settings.KillSwitchMode,
    Callback = function(v) Settings.KillSwitchMode = v end,
})
aoeTgl = AttackSec:Toggle({
    Title = "范围打击",
    Desc = "对所有怪物轮转攻击 (全局速率限制在服务器限速内)",
    Value = Settings.AoeAttack,
    Callback = function(v)
        Settings.AoeAttack = v
        restartAttackLoop()
    end,
})
AttackSec:Slider({
    Title = "攻击范围 (studs)",
    Value = { Min = 10, Max = 500, Default = Settings.Range },
    Step = 5,
    Callback = function(v) Settings.Range = v end,
})
AttackSec:Slider({
    Title = "攻击速率 (次/秒)",
    Value = { Min = 1, Max = 20, Default = Settings.Rate },
    Step = 1,
    Callback = function(v)
        Settings.Rate = v
        restartAttackLoop()
    end,
})

-- ---- 自动BOSS ----
local BossSec = AutoTab:Section({ Title = "自动BOSS" })
bossTgl = BossSec:Toggle({
    Title = "自动BOSS",
    Desc = "BOSS刷新时自动前往, 打完自动返回",
    Value = Settings.AutoBoss,
    Callback = function(v)
        Settings.AutoBoss = v
        if v then
            TheKing.StartLoop("boss", 1, function()
                bossLoop()
                updateBossStatus()
            end)
        else
            TheKing.StopLoop("boss")
        end
    end,
})
BossSec:Slider({
    Title = "提前入场秒数",
    Desc = "传送入口提前300秒开放, 0=BOSS刷新时入场",
    Value = { Min = 0, Max = 300, Default = Settings.BossEarlyEntry },
    Step = 5,
    Callback = function(v) Settings.BossEarlyEntry = v end,
})

-- ---- 自动力量 ----
local PowerSec = AutoTab:Section({ Title = "自动力量" })
powerTgl = PowerSec:Toggle({
    Title = "自动力量",
    Desc = "充能达到阈值时自动使用 (代替游戏设置里的自动力量)",
    Value = Settings.AutoPower,
    Callback = function(v)
        Settings.AutoPower = v
        if v then
            TheKing.StartLoop("power", 3, autoPowerTick)
        else
            TheKing.StopLoop("power")
            gameAutoPowerOff = false -- 下次开启重新接管
            TheKing.UpdateStatus(powerStatusPara, "自动力量: 已关闭", "打开开关后按阈值自动使用力量")
        end
    end,
})
PowerSec:Slider({
    Title = "力量阈值 (%)",
    Desc = "充能达到上限的百分比时使用 (默认100%满管)",
    Value = { Min = 1, Max = 100, Default = Settings.AutoPowerPercent },
    Step = 1,
    Callback = function(v) Settings.AutoPowerPercent = v end,
})

-- ---- 自动装备 ----
local EquipSec = AutoTab:Section({ Title = "自动装备" })
equipTgl = EquipSec:Toggle({
    Title = "自动装备英雄",
    Desc = "按DPS自动装备最强英雄至上限 (代替游戏内自动装备最佳)",
    Value = Settings.AutoEquipHero,
    Callback = function(v)
        Settings.AutoEquipHero = v
        if v then
            TheKing.StartLoop("equip", 1.5, autoEquipTick, { jitter = false })
        else
            TheKing.StopLoop("equip")
            gameAutoEquipOff = false
            TheKing.UpdateStatus(equipStatusPara, "自动装备: 已关闭", "打开开关后按DPS自动装备")
        end
    end,
})

-- ---- 自动升级 / 声望 ----
local UpgradeSec = AutoTab:Section({ Title = "自动升级 / 声望" })
upgTgl = UpgradeSec:Toggle({
    Title = "自动升级",
    Desc = "金币够买的天赋自动激活 (含二层分支)",
    Value = Settings.AutoUpgrade,
    Callback = function(v)
        Settings.AutoUpgrade = v
        if v then
            TheKing.StartLoop("upgrade", Settings.AutoUpgradeTick, function()
                autoUpgradeTick()
                autoPrestigeTick()
                updateUpgradeStatus()
            end)
        else
            TheKing.StopLoop("upgrade")
        end
    end,
})
UpgradeSec:Slider({
    Title = "购买间隔 (秒)",
    Value = { Min = 1, Max = 10, Default = Settings.AutoUpgradeTick },
    Step = 1,
    Callback = function(v) Settings.AutoUpgradeTick = v end,
})
UpgradeSec:Slider({
    Title = "每轮最大购买",
    Desc = "防止一次性发送过多购买请求",
    Value = { Min = 1, Max = 20, Default = Settings.AutoUpgradeMax },
    Step = 1,
    Callback = function(v) Settings.AutoUpgradeMax = v end,
})
prestigeTgl = UpgradeSec:Toggle({
    Title = "自动声望",
    Desc = "等级达到转生条件时自动转生",
    Value = Settings.AutoPrestige,
    Callback = function(v) Settings.AutoPrestige = v end,
})

-- ---- 状态区 ----
local StateSec = AutoTab:Section({ Title = "状态" })
statePara = StateSec:Paragraph({ Title = "状态: 未启用", Desc = "打开开关后自动攻击附近怪物" })
upgradeStatusPara = StateSec:Paragraph({ Title = "金币: 0 | 可购买: 0", Desc = "打开开关后自动购买天赋" })
local bossStatusPara = StateSec:Paragraph({ Title = "BOSS 状态: 空闲", Desc = "等待BOSS刷新..." })
powerStatusPara = PowerSec:Paragraph({ Title = "自动力量: 已关闭", Desc = "打开开关后按阈值自动使用力量" })
equipStatusPara = EquipSec:Paragraph({ Title = "自动装备: 已关闭", Desc = "打开开关后按DPS自动装备" })

-- BOSS 状态刷新 (挂在 boss 循环里)
updateBossStatus = function()
    local serverTime = workspace:GetServerTimeNow()
    local w, hasFight, inArena
    pcall(function() w = BossesShared.GetWindow(serverTime) end)
    pcall(function() hasFight = BossesClient.HasLiveFight() end)
    pcall(function() inArena = BossesClient.IsPlayerInArena() end)
    if not w then return end

    if inArena then
        local bossHp
        pcall(function() bossHp = Enemies.GetHealth(BOSS_ZONE, BOSS_SLOT) end)
        if hasFight and bossHp and bossHp > 0 then
            TheKing.UpdateStatus(bossStatusPara,
                string.format("战斗中 | %s | 血量 %.1fM", tostring(w.bossId), bossHp / 1000000),
                "等待英雄击杀, 击杀后自动返回")
        else
            TheKing.UpdateStatus(bossStatusPara, "BOSS 已击杀", "正在返回...")
        end
    elseif hasFight then
        TheKing.UpdateStatus(bossStatusPara,
            string.format("BOSS 已刷新 | %s", tostring(w.bossId)), "正在传送入场...")
    elseif w.phase == "Warning" then
        local cd = w.spawnEpoch - serverTime
        local state = cd <= Settings.BossEarlyEntry and "正在传送..." or "等待入场"
        TheKing.UpdateStatus(bossStatusPara,
            string.format("传送入口已开放 | %s", tostring(w.bossId)),
            string.format("%s 后刷新 | 提前%s秒入场 | %s", formatBossCountdown(cd), tostring(Settings.BossEarlyEntry), state))
    else
        local cd = w.spawnEpoch - serverTime
        TheKing.UpdateStatus(bossStatusPara,
            string.format("入口未开放 | 下一个: %s", tostring(w.bossId)),
            string.format("%s 后刷新 (传送入口提前5分钟开放)", formatBossCountdown(cd)))
    end
end

-- ============================================================
-- Tab: 防
-- ============================================================
local DefTab = TheKing.NewTab({ Title = "防", Icon = "shield-check" })
local AfkSec = DefTab:Section({ Title = "防挂机" })
afkTgl = AfkSec:Toggle({
    Title = "防挂机",
    Desc = "吞掉切服请求 + 模拟输入防引擎弹窗 [L2: hook]",
    Value = Settings.AntiAfk,
    Callback = function(v)
        Settings.AntiAfk = v
        if v then
            enableAntiAfk()
        else
            disableAntiAfk()
        end
    end,
})

local ScrollSec = DefTab:Section({ Title = "防滚动" })
scrollTgl = ScrollSec:Toggle({
    Title = "防滚动",
    Desc = "跳过英雄抽取动画直接显示结果 [L2: 替换函数]",
    Value = Settings.AntiScroll,
    Callback = function(v)
        Settings.AntiScroll = v
        if v then
            enableAntiScroll()
        else
            disableAntiScroll()
        end
    end,
})

local ProtectSec = DefTab:Section({ Title = "保护屏幕" })
protectTgl = ProtectSec:Toggle({
    Title = "保护屏幕",
    Desc = "除界面外全屏黑屏, 防长时间挂机烧屏",
    Value = Settings.ScreenProtect,
    Callback = function(v)
        Settings.ScreenProtect = v
        if v then
            enableScreenProtect()
        else
            disableScreenProtect()
        end
    end,
})

-- ============================================================
-- Tab: 性能
-- ============================================================
local PerfTab = TheKing.NewTab({ Title = "性能", Icon = "gauge" })
local PotatoSec = PerfTab:Section({ Title = "土豆模式" })
potatoTgl = PotatoSec:Toggle({
    Title = "土豆模式",
    Desc = "关阴影禁特效白光照, 提升长时间挂机稳定性",
    Value = Settings.PotatoMode,
    Callback = function(v)
        Settings.PotatoMode = v
        if v then
            savePotatoOriginal()
            applyPotatoSettings()
        else
            revertPotatoSettings()
        end
    end,
})

-- ============================================================
-- Tab: 传送
-- ============================================================
local TeleportTab = TheKing.NewTab({ Title = "传送", Icon = "map-pin" })
local TpFacilitySec = TeleportTab:Section({ Title = "重要地点" })

local FACILITIES = {
    { label = "融合", desc = "森林融合台, 自动打开融合界面", zone = "Forest", model = "Fusion", icon = "diamond" },
    { label = "符文", desc = "海滩符文祭坛, 自动打开符文界面", zone = "Beach", model = "RuneAltar", icon = "diamond" },
    { label = "塔楼", desc = "荒地塔楼入口, 自动打开面板", zone = "Badlands", model = "InfinityTower", icon = "crown" },
    { label = "制造", desc = "北极制造台, 自动打开制造界面", zone = "Arctic", model = "CraftingTable", icon = "wrench" },
}
for _, f in ipairs(FACILITIES) do
    TpFacilitySec:Button({
        Title = f.label,
        Desc = f.desc,
        Icon = f.icon,
        Callback = function() teleportToFacility(f.zone, f.model, f.label) end,
    })
end
TpFacilitySec:Button({
    Title = "BOSS岛",
    Desc = "传送到 BOSS 竞技场",
    Icon = "sword",
    Callback = function() doTeleport("boss") end,
})

local TELEPORT_ZONES = {
    "Starter", "Meadows", "Forest", "Beach", "Sea",
    "Arctic", "Jungle", "Badlands", "Shadowgrove",
    "SerpentSands", "Void", "IceCave",
}
local TpZoneSecA = TeleportTab:Section({ Title = "地区 1-6" })
for i = 1, 6 do
    local zoneName = TELEPORT_ZONES[i]
    TpZoneSecA:Button({
        Title = string.format("%d. %s", i, zoneName),
        Icon = "flag",
        Callback = function() doTeleport("zone", zoneName) end,
    })
end
local TpZoneSecB = TeleportTab:Section({ Title = "地区 7-12" })
for i = 7, #TELEPORT_ZONES do
    local zoneName = TELEPORT_ZONES[i]
    TpZoneSecB:Button({
        Title = string.format("%d. %s", i, zoneName),
        Icon = "flag",
        Callback = function() doTeleport("zone", zoneName) end,
    })
end
local TpStatusSec = TeleportTab:Section({ Title = "状态" })
teleportStatusPara = TpStatusSec:Paragraph({ Title = "传送: 就绪", Desc = "点击上方按钮传送 (5 秒冷却)" })

-- ============================================================
-- Tab: 设置 (骨架标配)
-- ============================================================
local SettingsTab = TheKing.NewTab({ Title = "设置", Icon = "settings" })

local function unloadAction()
    TheKing.Confirm({
        Title = "卸载确认",
        Content = "将停止全部功能并还原游戏状态, 确定吗?",
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
        -- WindUI Window:Toggle 的动画链在 Real 下会卡死 (蓝本已验证), 直切 ScreenGui.Enabled
        local gui = findHubScreenGui()
        if gui then
            gui.Enabled = not gui.Enabled
        end
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

-- ==================== 常驻辅助循环 ====================
-- 土豆补刀: 新区域会带新特效
TheKing.StartLoop("potatoWatch", 30, function()
    if Settings.PotatoMode then
        applyPotatoSettings()
    end
end)

-- 防挂机定期真人活动: 8~13 分钟随机一次隐形点击/跳跃
TheKing.StartLoop("afkActivity", 585, function()
    if Settings.AntiAfk then
        if math.random(1, 2) == 1 then
            simulateClick()
        else
            simulateJump()
        end
    end
end, { jitter = false })

-- ==================== 启动状态对齐 ====================
-- Toggle 已脱离 Flag 配置系统 (误启源头移除), 此处仅做一次直调对齐, 兜底防遗漏。
task.delay(1, function()
    local function align(elem, target)
        if type(elem) == "table" and type(elem.Callback) == "function" then
            pcall(elem.Callback, target)
        end
    end
    align(attackTgl, Settings.Enabled)
    align(aoeTgl, Settings.AoeAttack)
    align(bossTgl, Settings.AutoBoss)
    align(powerTgl, Settings.AutoPower)
    align(equipTgl, Settings.AutoEquipHero)
    align(upgTgl, Settings.AutoUpgrade)
    align(prestigeTgl, Settings.AutoPrestige)
    align(afkTgl, Settings.AntiAfk)
    align(scrollTgl, Settings.AntiScroll)
    align(protectTgl, Settings.ScreenProtect)
    align(potatoTgl, Settings.PotatoMode)
    print("[Heroes RNG] 启动状态对齐完成")
end)

-- WindUI 兼容: Tab 只含 Section 时空页检测误判, EmptyPage 覆盖层压住内容。
-- 修复: 找到 EmptyPage 文本的祖先 Frame 直接隐藏 (切 Tab 后若复现由用户点击自然刷新)
task.delay(1.4, function()
    pcall(function()
        local h = type(gethui) == "function" and gethui()
        local w = h and h:FindFirstChild("WindUI")
        local win = w and w:FindFirstChild("Window")
        if not win then return end
        for _, g in ipairs(win:GetDescendants()) do
            if g:IsA("TextLabel") and g.Text == "This tab is Empty" then
                -- 只藏文本与同级图标; EmptyPage 直接挂在 Tab 页面容器下, 藏容器会黑整页
                g.Visible = false
                if g.Parent then
                    for _, sib in ipairs(g.Parent:GetChildren()) do
                        if sib:IsA("ImageLabel") then sib.Visible = false end
                    end
                end
            end
        end
    end)
end)

-- ==================== Flag 注册 (脱离创建期, 避免配置系统误触发) ====================
task.delay(0.2, function()
    if TheKing.Config then
        pcall(function() TheKing.Config:Register("attack", attackTgl) end)
        pcall(function() TheKing.Config:Register("aoe", aoeTgl) end)
        pcall(function() TheKing.Config:Register("autoboss", bossTgl) end)
        pcall(function() TheKing.Config:Register("autopower", powerTgl) end)
        pcall(function() TheKing.Config:Register("autoequip", equipTgl) end)
        pcall(function() TheKing.Config:Register("autoupgrade", upgTgl) end)
        pcall(function() TheKing.Config:Register("autoprestige", prestigeTgl) end)
        pcall(function() TheKing.Config:Register("antiafk", afkTgl) end)
        pcall(function() TheKing.Config:Register("antiscroll", scrollTgl) end)
        pcall(function() TheKing.Config:Register("screenprotect", protectTgl) end)
        pcall(function() TheKing.Config:Register("potato", potatoTgl) end)
        TheKing.LoadConfig() -- Register 完成后再 Load, 顺序不能反 (否则恢复为空)
        -- 排障句柄: 验证持久化链路用 (Save/Load/Config 内部状态)
        rawset(_G, "HeroRNG_Debug", {
            Save = TheKing.SaveConfig,
            Load = TheKing.LoadConfig,
            Config = TheKing.Config,
        })

    end
end)
