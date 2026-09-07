--[[
    TheKing HUB [0.0.1] - Dungeon Quest Reborn
    RCWTK 引擎生成 | 基于 hub-skeleton.luau 模板

    功能清单:
      自动准备:   检测到准备/开始按钮自动点击 (readyUp / changeStartValue / startDungeon)
      自动普攻:   按游戏原生左键攻击路径自动普攻 (范围内最近敌人)
      自动技能:   自动释放 Q/E 槽技能 (可选等待释放完成)
      移动速度:   可选修改 Humanoid.WalkSpeed (副本内跑图)
      全屏命中:   自行跑进入索敌范围后传头顶施法/普攻 [L2: 移动位置]
      BOSS躲避:   全屏命中内置, 检测BOSS技能判定框自动传送躲避
      快捷键:     显示 Q/E 当前技能与冷却状态, 自定义触发键
      设置:       显示隐藏 DEL / 卸载 END / 停止全部 (骨架标配)

    逆向结论 (同步自 intel.md):
      - 技能触发链: localEvent:Fire() -> Tool LocalScript 校验冷却/busyCasting -> 技能RemoteEvent:FireServer()
      - 伤害全服务器权威 (Tool 内 Server Script), 客户端无法直接指定命中目标
      - 全屏命中: 仅当敌人距玩家 <= 索敌范围时传送到头顶 (默认 +8 stud) 再出手; 超出范围不传送
      - 普攻: Character 内 Accessory 带 Weapon 的 RemoteEvent:FireServer() + weaponUsed:FireServer()
      - 世界 START 按钮 (ui.startButton) → changeStartValue (不是 startDungeon!)
      - 组队大厅 Start (queueGui/bossQueueGui) → startDungeon
      - 准备按钮 (ui.readyButton) → readyUp

    使用方式:
      开发: execute 本文件 (theking.luau 多候选路径自动加载)
      热调试: 改完直接重新 execute, 旧实例自毁让位
]]

-- ==================== 运行库加载 (多候选路径) ====================
local function loadTheKing()
    local errs = {}
    for _, p in ipairs({
        "theking.luau",                                  -- Real workspace 根 (开发态主路)
        "D:/BuildProject/RoLua/Core/lib/theking.luau",   -- 本机绝对路径 (沙箱外注入器)
    }) do
        local ok, loader = pcall(function()
            return loadstring(readfile(p))
        end)
        if ok and type(loader) == "function" then
            return loader
        end
        errs[#errs + 1] = p .. " -> " .. tostring(loader)
    end
    error("[Dungeon Quest Reborn] theking.luau 加载失败:\n" .. table.concat(errs, "\n"), 0)
end

local TheKing = loadTheKing()({
    GameName = "Dungeon Quest Reborn", -- 与 intel.md front matter game 字段逐字一致 (隔离键)
    ScriptVersion = "0.0.1",
})

TheKing.Notify({ Content = "TheKing HUB 已加载 (Dungeon Quest Reborn)", Icon = "crown" })

-- ==================== 游戏服务引用 ====================
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local remotes = ReplicatedStorage:WaitForChild("remotes", 10)
local abilityUsed = remotes:WaitForChild("abilityUsed", 10)
local weaponUsed = remotes:WaitForChild("weaponUsed", 10)

-- ==================== 设置表 ====================
local Settings = {
    AutoAttack = false,
    AutoQ = false,
    AutoE = false,
    FullHit = false,
    Range = 500,
    SkillDelay = 0.6,
    DodgeEnabled = true,        -- BOSS攻击躲避 (全屏命中内置, 无需单独开启)
    AutoReady = true,           -- 自动准备 (检测到准备按钮自动点击)
    SkillWaitCast = true,       -- 技能等待释放完成再放下一个
    DodgeDistance = 30,         -- 躲避传送距离
    DodgeReturnDelay = 0.5,    -- 躲避后返回延迟
    FullHitHeight = 8.0,        -- 全屏命中: 传送到敌人头顶的悬浮高度 (studs)
    FullHitSettle = 0.12,       -- 进范围传送后等待再出手
    WalkSpeedMod = false,       -- 修改移动速度
    WalkSpeed = 32,             -- WalkSpeedMod 开启时的速度
}

--- 配置持久化: Load 期间禁止 Save; 用户改项后立即存档
local configLoading = false
local function persistSave()
    if configLoading then return end
    if TheKing.Config then
        pcall(TheKing.SaveConfig)
    end
end

-- ==================== BOSS 攻击躲避模块 ====================
local BossDodge = {}
BossDodge.__index = BossDodge

--- 判断是否为BOSS房间
local function isBossRoom()
    local root = getHumanoidRootPart()
    if not root then return false end
    local dungeon = workspace:FindFirstChild("dungeon")
    if not dungeon then return false end
    for _, room in ipairs(dungeon:GetChildren()) do
        if room.Name == "bossRoom" then
            local ef = room:FindFirstChild("enemyFolder")
            if ef then
                for _, enemy in ipairs(ef:GetChildren()) do
                    local hum = enemy:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        local hrp = enemy:FindFirstChild("HumanoidRootPart")
                            or enemy:FindFirstChild("Head")
                            or enemy:FindFirstChildOfClass("BasePart")
                        if hrp then
                            local dist = (root.Position - hrp.Position).Magnitude
                            if dist < 200 then
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

--- BOSS攻击躲避状态
local bossDodgeActive = false
local bossDodgeConn = nil
local bossDodgeReturnPos = nil
local fullHitSettleUntil = 0 -- 切目标/躲避返回后短暂只锁位不出手

--- 检测workspace中新增的判定框Part (宽松匹配, 打日志确认)
local function isHitboxPart(child)
    if not child:IsA("BasePart") then return false end
    if not child.Anchored then return false end
    if child.CanTouch ~= false then return false end
    if child.CanCollide ~= false then return false end
    return true
end

--- 处理判定框出现
local function handleHitboxPart(part)
    if not Settings.DodgeEnabled then return end
    if not Settings.FullHit then return end
    if bossDodgeActive then return end

    local root = getHumanoidRootPart()
    if not root then return end
    local playerPos = root.Position

    local hitboxCFrame = part.CFrame
    local hitboxSize = part.Size
    local hitboxCenter = hitboxCFrame.Position
    local inHitbox = false

    if part.Shape == Enum.PartType.Cylinder then
        local dist = (playerPos - hitboxCenter).Magnitude
        local radius = math.max(hitboxSize.Y, hitboxSize.Z) / 2
        inHitbox = dist <= radius + 5
    else
        local halfSize = hitboxSize / 2
        local localPos = hitboxCFrame:VectorToObjectSpace(playerPos - hitboxCenter)
        inHitbox = math.abs(localPos.X) <= halfSize.X + 3
            and math.abs(localPos.Y) <= halfSize.Y + 3
            and math.abs(localPos.Z) <= halfSize.Z + 3
    end

    if not inHitbox then
        print("[DQ-Dodge] 判定框出现, 玩家不在范围内, 忽略")
        return
    end

    bossDodgeActive = true
    bossDodgeReturnPos = root.Position

    local safePos
    if part.Shape == Enum.PartType.Cylinder then
        local radius = math.max(hitboxSize.Y, hitboxSize.Z) / 2
        local dir = (playerPos - hitboxCenter)
        if dir.Magnitude < 0.1 then dir = Vector3.new(1, 0, 0) end
        safePos = hitboxCenter + dir.Unit * (radius + 15)
    else
        local halfSize = hitboxSize / 2
        local bestDist = math.huge
        local dirs = {
            Vector3.new(1, 0, 0) * (halfSize.X + 15),
            Vector3.new(-1, 0, 0) * (halfSize.X + 15),
            Vector3.new(0, 0, 1) * (halfSize.Z + 15),
            Vector3.new(0, 0, -1) * (halfSize.Z + 15),
        }
        for _, d in ipairs(dirs) do
            local testPos = hitboxCenter + d
            local dist = (testPos - playerPos).Magnitude
            if dist < bestDist then
                bestDist = dist
                safePos = testPos
            end
        end
    end

    if not safePos then bossDodgeActive = false return end
    safePos = safePos + Vector3.new(0, 5, 0)

    removeHoldMovers()
    root.CFrame = CFrame.new(safePos)
    root.Velocity = Vector3.new(0, 0, 0)

    print("[DQ-Dodge] 躲避! 形状:", part.Shape.Name, "大小:", hitboxSize)
    TheKing.Notify({ Content = "BOSS攻击预警! 躲避中...", Icon = "shield", Duration = 2 })

    task.spawn(function()
        while part and part.Parent do task.wait(0.1) end
        task.wait(0.3)
        if bossDodgeReturnPos and Settings.FullHit then
            local r = getHumanoidRootPart()
            if r then
                local h = Settings.FullHitHeight or 8.0
                r.CFrame = CFrame.new(bossDodgeReturnPos + Vector3.new(0, h, 0))
                pcall(function()
                    r.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    r.Velocity = Vector3.new(0, 0, 0)
                end)
                ensureHoldMovers()
                fullHitSettleUntil = os.clock() + (Settings.FullHitSettle or 0.12)
            end
        end
        bossDodgeActive = false
        bossDodgeReturnPos = nil
    end)
end

--- 启动 BOSS 判定框监听
local function setupBossDodge()
    -- workspace.ChildAdded 监听 + 打日志
    bossDodgeConn = workspace.ChildAdded:Connect(function(child)
        if child:IsA("BasePart") then
            print("[DQ-Dodge] workspace+Part:", child.Name,
                "Mat:", child.Material.Name,
                "Anchor:", child.Anchored,
                "Touch:", child.CanTouch,
                "Collide:", child.CanCollide,
                "Shape:", child.Shape.Name,
                "Size:", tostring(child.Size))
        end
        if isHitboxPart(child) then
            print("[DQ-Dodge] >>> 判定框命中! 触发躲避检查")
            task.defer(function()
                handleHitboxPart(child)
            end)
        end
    end)
    print("[DQ-Dodge] 监听已启动")
end

--- 停止 BOSS 躲避监听
local function stopBossDodge()
    if bossDodgeConn then
        bossDodgeConn:Disconnect()
        bossDodgeConn = nil
    end
    bossDodgeActive = false
    bossDodgeReturnPos = nil
    print("[DQ-Dodge] 监听已停止")
end

-- ==================== 工具函数 ====================
--- 获取副本房间列表并按 order 排序
local function getDungeonRooms()
    local dungeon = workspace:FindFirstChild("dungeon")
    if not dungeon then return {} end
    local rooms = {}
    for _, room in ipairs(dungeon:GetChildren()) do
        local order = room:FindFirstChild("order")
        local startPart = room:FindFirstChild("startPart")
        local endPart = room:FindFirstChild("endPart")
        local enemyFolder = room:FindFirstChild("enemyFolder")
        table.insert(rooms, {
            name = room.Name,
            order = order and order.Value or 0,
            startPart = startPart,
            endPart = endPart,
            enemyFolder = enemyFolder,
            model = room,
        })
    end
    table.sort(rooms, function(a, b) return a.order < b.order end)
    return rooms
end

--- 根据玩家位置确定当前所在房间
local function getCurrentRoom()
    local root = getHumanoidRootPart()
    if not root then return nil end
    local pos = root.Position
    local rooms = getDungeonRooms()
    local bestRoom = nil
    local bestDist = math.huge
    for _, room in ipairs(rooms) do
        local ref = room.startPart or room.endPart
        if ref then
            local dist = (pos - ref.Position).Magnitude
            if dist < bestDist then
                bestDist = dist
                bestRoom = room
            end
        end
    end
    return bestRoom
end

local function getCharacter()
    return LocalPlayer.Character
end

local function getHumanoidRootPart()
    local ch = getCharacter()
    return ch and ch:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local ch = getCharacter()
    return ch and ch:FindFirstChildOfClass("Humanoid")
end

--- 移动速度修改 (游戏会周期性重置 WalkSpeed, 需循环回写)
local baseWalkSpeed = nil
local function applyWalkSpeed()
    local hum = getHumanoid()
    if not hum then return end
    if baseWalkSpeed == nil then
        baseWalkSpeed = hum.WalkSpeed
    end
    if Settings.WalkSpeedMod then
        hum.WalkSpeed = Settings.WalkSpeed
    else
        hum.WalkSpeed = baseWalkSpeed
    end
end

local function resetWalkSpeed()
    local hum = getHumanoid()
    if hum and baseWalkSpeed then
        hum.WalkSpeed = baseWalkSpeed
    end
    baseWalkSpeed = nil
end

local function isInDungeon()
    local ws = workspace
    local ds = ws:FindFirstChild("dungeonStarted")
    return ds and ds.Value == true
end

--- 按 abilitySlot 找技能 Tool (Backpack 优先, 其次 Character)
local function findAbilityTool(slot)
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and t:FindFirstChild("abilitySlot") and t.abilitySlot.Value == slot then
                return t
            end
        end
    end
    local ch = getCharacter()
    if ch then
        for _, t in ipairs(ch:GetChildren()) do
            if t:IsA("Tool") and t:FindFirstChild("abilitySlot") and t.abilitySlot.Value == slot then
                return t
            end
        end
    end
    return nil
end

--- 技能是否在冷却
local function isAbilityOnCooldown(slot)
    local tool = findAbilityTool(slot)
    if tool then
        local cd = tool:FindFirstChild("cooldown")
        if cd and cd.Value > 0 then return true end
    end
    return false
end

--- 玩家是否在施法动画中
local function isBusyCasting()
    local ch = getCharacter()
    local busy = ch and ch:FindFirstChild("busyCasting")
    return busy and busy.Value == true
end

--- 等待施法完成 (busyCasting 回 false)
local function waitForCastComplete(timeout)
    timeout = timeout or 3
    local t = os.clock()
    while isBusyCasting() and os.clock() - t < timeout do
        RunService.Heartbeat:Wait()
    end
end

--- 判断 Gui 是否真正可见 (含父级 ScreenGui.Enabled)
local function isGuiVisible(gui)
    if not gui or not gui:IsA("GuiObject") then return false end
    if not gui.Visible then return false end
    local p = gui
    while p do
        if p:IsA("GuiObject") and not p.Visible then return false end
        if p:IsA("ScreenGui") and not p.Enabled then return false end
        p = p.Parent
    end
    return true
end

--- 在指定 ScreenGui 下找可见的交互按钮
local function findVisibleActionButton(rootName, buttonNames)
    local root = LocalPlayer.PlayerGui:FindFirstChild(rootName)
    if not root then return nil end
    if type(buttonNames) == "string" then buttonNames = { buttonNames } end
    local nameSet = {}
    for _, n in ipairs(buttonNames) do nameSet[n] = true end
    for _, d in ipairs(root:GetDescendants()) do
        if nameSet[d.Name] and (d:IsA("TextButton") or d:IsA("ImageButton")) and isGuiVisible(d) then
            return d
        end
    end
    return nil
end

--- 组队/boss 大厅里的 Start 按钮
local function findLobbyStartButton()
    for _, guiName in ipairs({ "queueGui", "bossQueueGui" }) do
        local gui = LocalPlayer.PlayerGui:FindFirstChild(guiName)
        if gui and (not gui:IsA("ScreenGui") or gui.Enabled) then
            for _, d in ipairs(gui:GetDescendants()) do
                if d.Name == "startButton" and d:IsA("TextButton") and isGuiVisible(d) then
                    return d
                end
            end
        end
    end
    return nil
end

--- 自动准备/开始: readyButton / 世界START / 大厅Start / 重开
local autoReadyCooldown = 0
local function autoReady()
    if not Settings.AutoReady then return end
    if os.clock() - autoReadyCooldown < 0.8 then return end
    local remotes = game.ReplicatedStorage:FindFirstChild("remotes")
    if not remotes then return end

    -- 1) 准备 (readyButton / playersNotReady)
    if LocalPlayer.PlayerGui:FindFirstChild("readyButton") then
        autoReadyCooldown = os.clock()
        pcall(function() remotes.readyUp:FireServer() end)
        return
    end
    local dp = workspace:FindFirstChild("dungeonProgress")
    if dp and dp.Value == "playersNotReady" then
        autoReadyCooldown = os.clock()
        pcall(function() remotes.readyUp:FireServer() end)
        return
    end

    -- 2) 世界 START (showStartButton 克隆的 startButton) → changeStartValue
    if LocalPlayer.PlayerGui:FindFirstChild("startButton")
        or findVisibleActionButton("startButton", "TextButton") then
        autoReadyCooldown = os.clock()
        pcall(function() remotes.changeStartValue:FireServer() end)
        return
    end

    -- 3) 组队大厅 Start → startDungeon
    if findLobbyStartButton() then
        autoReadyCooldown = os.clock()
        pcall(function() remotes.startDungeon:FireServer() end)
        return
    end

    -- 4) 副本结束重开
    local replayGui = LocalPlayer.PlayerGui:FindFirstChild("mainInterface")
    if replayGui then
        local btns = replayGui:FindFirstChild("buttons")
        if btns then
            local replayBtn = btns:FindFirstChild("ReplayDungeonButton")
            if replayBtn and replayBtn.Visible then
                autoReadyCooldown = os.clock()
                pcall(function() remotes.replayDungeon:FireServer() end)
            end
        end
    end
end

--- 释放指定槽位技能 (完全复刻游戏 UIS 按键逻辑)
--- @return boolean 是否成功发出
local function castAbility(slot)
    local tool = findAbilityTool(slot)
    if not tool then return false end
    local le = tool:FindFirstChild("localEvent")
    if not le then return false end
    if isBusyCasting() then return false end
    pcall(function() le:Fire() end)
    pcall(function() abilityUsed:FireServer(slot, tool) end)
    return true
end

--- 普攻 (复刻游戏鼠标左键逻辑: Character Accessory 带 Weapon, swing RemoteEvent 是 Accessory 直接子级)
local function normalAttack()
    local ch = getCharacter()
    if not ch then return false end
    local peaceful = LocalPlayer:FindFirstChild("peaceful")
    if peaceful and peaceful.Value ~= false then return false end
    if isBusyCasting() then return false end
    local weaponRemote
    for _, j in ipairs(ch:GetChildren()) do
        if j:IsA("Accessory") and j:FindFirstChild("Weapon") then
            weaponRemote = j:FindFirstChildOfClass("RemoteEvent") -- swing: 直接子级
            break
        end
    end
    if not weaponRemote then return false end
    pcall(function() weaponRemote:FireServer() end)
    pcall(function() weaponUsed:FireServer() end)
    return true
end

--- 收集当前副本存活敌人
--- 敌人位置 = workspace.dungeon.<room>.enemyFolder 下的 Model (全部同名, 必须 GetChildren 遍历)
--- 玩家是 Humanoid 但不在 enemyFolder 里, 天然排除
local function collectEnemies()
    local myRoot = getHumanoidRootPart()
    local myPos = myRoot and myRoot.Position
    local list = {}
    local seen = {} -- 去重

    -- 扫描 workspace.enemies (服务器按波次填充)
    local enemiesFolder = workspace:FindFirstChild("enemies")
    if enemiesFolder then
        for _, enemy in ipairs(enemiesFolder:GetChildren()) do
            local hum = enemy:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local hrp = enemy:FindFirstChild("HumanoidRootPart")
                    or enemy:FindFirstChild("Head")
                    or enemy:FindFirstChildOfClass("BasePart")
                if hrp then
                    local pos = hrp.Position
                    if not myPos or (pos - myPos).Magnitude <= Settings.Range or Settings.FullHit then
                        list[#list + 1] = { model = enemy, humanoid = hum, hrp = hrp, pos = pos, room = nil }
                        seen[enemy] = true
                    end
                end
            end
        end
    end

    -- 扫描副本房间内的 enemyFolder
    local dungeon = workspace:FindFirstChild("dungeon")
    if dungeon then
        for _, room in ipairs(dungeon:GetChildren()) do
            local ef = room:FindFirstChild("enemyFolder")
            if ef then
                for _, enemy in ipairs(ef:GetChildren()) do
                    if not seen[enemy] then
                        local hum = enemy:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 then
                            local hrp = enemy:FindFirstChild("HumanoidRootPart")
                                or enemy:FindFirstChild("Head")
                                or enemy:FindFirstChildOfClass("BasePart")
                            if hrp then
                                local pos = hrp.Position
                                if not myPos or (pos - myPos).Magnitude <= Settings.Range or Settings.FullHit then
                                    list[#list + 1] = { model = enemy, humanoid = hum, hrp = hrp, pos = pos, room = room }
                                    seen[enemy] = true
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    table.sort(list, function(a, b)
        local da = myPos and (a.pos - myPos).Magnitude or 0
        local db = myPos and (b.pos - myPos).Magnitude or 0
        return da < db
    end)
    return list
end

-- ==================== 战斗循环 ====================
local statePara -- 状态 Paragraph (UI 段赋值)
local fullHitTarget = nil -- L2 单目标追踪: 锁定一个敌人, 悬浮施法直到死亡再切换

--- BodyPosition / BodyGyro 引用 (全局复用, 避免重复创建)
local holdBP, holdBG
local holdActive = false
local holdConn -- ChildRemoved 监听连接

--- 创建或获取固定用的 BodyMover
local function ensureHoldMovers()
    local root = getHumanoidRootPart()
    if not root then return false end
    holdActive = true
    if not holdBP or not holdBP.Parent then
        holdBP = Instance.new("BodyPosition")
        holdBP.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        holdBP.D = 5000
        holdBP.P = 100000
        holdBP.Position = root.Position
        holdBP.Parent = root
    end
    if not holdBG or not holdBG.Parent then
        holdBG = Instance.new("BodyGyro")
        holdBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        holdBG.D = 3000
        holdBG.P = 100000
        holdBG.CFrame = root.CFrame
        holdBG.Parent = root
    end
    if not holdConn or not holdConn.Connected then
        holdConn = root.ChildRemoved:Connect(function(child)
            if holdActive and (child == holdBP or child == holdBG) then
                task.defer(function()
                    if holdActive then ensureHoldMovers() end
                end)
            end
        end)
    end
    return true
end

--- 移除固定用的 BodyMover
local function removeHoldMovers()
    holdActive = false
    if holdConn then holdConn:Disconnect() end
    holdConn = nil
    pcall(function()
        if holdBP and holdBP.Parent then holdBP:Destroy() end
        if holdBG and holdBG.Parent then holdBG:Destroy() end
    end)
    holdBP, holdBG = nil, nil
end

--- 直接锁位置: BodyMover + CFrame 立即生效
local function lockPosition(holdPos, lookAtPos)
    local root = getHumanoidRootPart()
    if not root then return end
    ensureHoldMovers()
    pcall(function()
        if holdBP and holdBP.Parent then holdBP.Position = holdPos end
        if holdBG and holdBG.Parent and lookAtPos then
            holdBG.CFrame = CFrame.lookAt(holdPos, lookAtPos)
        end
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end)
        pcall(function()
            root.Velocity = Vector3.new(0, 0, 0)
            root.RotVelocity = Vector3.new(0, 0, 0)
        end)
        root.CFrame = lookAtPos and CFrame.lookAt(holdPos, lookAtPos) or CFrame.new(holdPos)
    end)
end

--- 刷新敌人 HRP 引用 (模型移动/重生后旧引用会失效)
local function refreshEnemyParts(e)
    if not e or not e.model or not e.model.Parent then return false end
    local hum = e.model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    local hrp = e.model:FindFirstChild("HumanoidRootPart")
        or e.model:FindFirstChild("Head")
        or e.model:FindFirstChildOfClass("BasePart")
    if not hrp then return false end
    e.humanoid = hum
    e.hrp = hrp
    e.pos = hrp.Position
    return true
end

--- 全屏命中站位: 敌人头顶 (仅索敌范围内才传送)
local function computeFullHitPose(enemyPos)
    local height = Settings.FullHitHeight or 8.0
    local holdPos = enemyPos + Vector3.new(0, height, 0)
    return holdPos, enemyPos
end

--- 目标是否在索敌范围内
local function isEnemyInRange(enemy, myPos)
    if not enemy or not enemy.pos then return false end
    if not myPos then return true end
    return (enemy.pos - myPos).Magnitude <= Settings.Range
end

--- 普攻间隔 (读武器 attackSpeed, 默认 2 → 0.5s)
local lastSwingAt = 0
local function getSwingInterval()
    local ch = getCharacter()
    if not ch then return 0.5 end
    for _, j in ipairs(ch:GetChildren()) do
        if j:IsA("Accessory") and j:FindFirstChild("Weapon") then
            local sp = j:FindFirstChild("attackSpeed")
            local v = sp and tonumber(sp.Value)
            if v and v > 0 then
                return math.clamp(1 / v, 0.2, 1.2)
            end
            break
        end
    end
    return 0.5
end

--- 传送至下一个有敌人的房间 (无 startPart, 用敌人位置作目标)
local function teleportToNextRoom()
    local dungeon = workspace:FindFirstChild("dungeon")
    if not dungeon then return false end
    local root = getHumanoidRootPart()
    if not root then return false end

    local myPos = root.Position
    local bestRoom = nil
    local bestDist = math.huge

    for _, room in ipairs(dungeon:GetChildren()) do
        local order = room:FindFirstChild("order")
        if order then
            local ef = room:FindFirstChild("enemyFolder")
            if ef then
                for _, enemy in ipairs(ef:GetChildren()) do
                    local hum = enemy:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        local hrp = enemy:FindFirstChild("HumanoidRootPart")
                            or enemy:FindFirstChild("Head")
                            or enemy:FindFirstChildOfClass("BasePart")
                        if hrp then
                            local dist = (myPos - hrp.Position).Magnitude
                            if dist > 20 and dist < bestDist then
                                bestDist = dist
                                bestRoom = { name = room.Name, pos = hrp.Position + Vector3.new(0, 8, 0) }
                            end
                        end
                    end
                end
            end
        end
    end

    if bestRoom then
        root.CFrame = CFrame.new(bestRoom.pos)
        root.Velocity = Vector3.new(0, 0, 0)
        TheKing.Notify({ Content = "传送至: " .. bestRoom.name, Icon = "map-pin" })
        return true
    end
    return false
end

local lastCastAt = 0
local function combatTick()
    if not (Settings.AutoAttack or Settings.AutoQ or Settings.AutoE or Settings.FullHit) then
        return
    end
    if not isInDungeon() then
        fullHitTarget = nil
        pcall(function() if statePara then TheKing.UpdateStatus(statePara, "状态: 非副本", "进入副本后自动战斗生效") end end)
        return
    end

    local ok, enemies = pcall(collectEnemies)
    if not ok then enemies = {} end

    if #enemies == 0 then
        fullHitTarget = nil
        return
    end

    local now = os.clock()

    if Settings.FullHit then
        local function pickTarget(list)
            if not list or #list == 0 then return nil end
            -- 优先续锁原目标 (还活着)
            if fullHitTarget and fullHitTarget.model then
                for _, enemy in ipairs(list) do
                    if enemy.model == fullHitTarget.model and refreshEnemyParts(enemy) then
                        return enemy
                    end
                end
            end
            local nextE = list[1]
            if refreshEnemyParts(nextE) then return nextE end
            return nil
        end

        if not fullHitTarget
            or not refreshEnemyParts(fullHitTarget) then
            local prev = fullHitTarget and fullHitTarget.model
            fullHitTarget = pickTarget(enemies)
            if fullHitTarget and fullHitTarget.model ~= prev then
                fullHitSettleUntil = os.clock() + (Settings.FullHitSettle or 0.12)
            end
        end
        if not fullHitTarget then return end
        local e = fullHitTarget
        local root0 = getHumanoidRootPart()
        if root0 and not isEnemyInRange(e, root0.Position) then
            removeHoldMovers()
            pcall(function()
                if statePara then
                    TheKing.UpdateStatus(
                        statePara,
                        "全屏: 请自行跑近",
                        string.format("最近目标距离 %.0f / 索敌 %d", (e.pos - root0.Position).Magnitude, Settings.Range)
                    )
                end
            end)
            return
        end

        holdActive = true

        local castCount = 0
        local deadline = os.clock() + 3.0
        while os.clock() < deadline do
            -- 死亡 / 失效 → 立刻换下一个, 并进入 settle
            pcall(function()
                if not refreshEnemyParts(e) then
                    for i, enemy in ipairs(enemies) do
                        if enemy.model == e.model then
                            table.remove(enemies, i)
                            break
                        end
                    end
                    local nextE = pickTarget(enemies)
                    if not nextE then
                        local newEnemies = collectEnemies()
                        if newEnemies and #newEnemies > 0 then
                            enemies = newEnemies
                            nextE = pickTarget(enemies)
                        end
                    end
                    if nextE then
                        e = nextE
                        fullHitTarget = e
                        castCount = 0
                        deadline = os.clock() + 3.0
                        fullHitSettleUntil = os.clock() + (Settings.FullHitSettle or 0.12)
                    end
                end
            end)

            -- 索敌范围内: 传头顶锁位; 范围外: 释放锁位, 等玩家自己跑近
            pcall(function()
                if bossDodgeActive then return end
                if not refreshEnemyParts(e) then return end
                local root = getHumanoidRootPart()
                if not root then return end
                if not isEnemyInRange(e, root.Position) then
                    removeHoldMovers()
                    return
                end
                local holdPos, lookAt = computeFullHitPose(e.pos)
                lockPosition(holdPos, lookAt)
            end)

            -- settle 窗口: 进范围且已锁头顶后再出手
            if not bossDodgeActive and os.clock() >= fullHitSettleUntil then
                pcall(function()
                    local root = getHumanoidRootPart()
                    if not root or not refreshEnemyParts(e) or not isEnemyInRange(e, root.Position) then
                        return
                    end
                    -- 全屏命中内置普攻 (不依赖 AutoAttack 开关)
                    local swingGap = getSwingInterval()
                    if not isBusyCasting() and os.clock() - lastSwingAt >= swingGap then
                        if normalAttack() then
                            lastSwingAt = os.clock()
                        end
                    end
                    if Settings.SkillWaitCast then
                        if not isBusyCasting() then
                            if Settings.AutoQ and not isAbilityOnCooldown("q") then
                                castAbility("q"); castCount += 1
                                waitForCastComplete()
                            elseif Settings.AutoE and not isAbilityOnCooldown("e") then
                                castAbility("e"); castCount += 1
                                waitForCastComplete()
                            end
                        end
                    else
                        if not isBusyCasting() then
                            if Settings.AutoQ and not isAbilityOnCooldown("q") then
                                castAbility("q"); castCount += 1
                            elseif Settings.AutoE and not isAbilityOnCooldown("e") then
                                castAbility("e"); castCount += 1
                            end
                        end
                    end
                end)
            end

            RunService.Heartbeat:Wait()
        end
        return
    end

    -- 常规模式
    local target = enemies[1]
    if not target then return end
    pcall(function()
        if not isBusyCasting() then
            if Settings.AutoAttack or (Settings.AutoQ or Settings.AutoE) then
                local swingGap = getSwingInterval()
                if os.clock() - lastSwingAt >= swingGap then
                    if normalAttack() then lastSwingAt = os.clock() end
                end
            end
        end
        if (Settings.AutoQ or Settings.AutoE) and now - lastCastAt >= Settings.SkillDelay then
            if Settings.AutoQ and not isAbilityOnCooldown("q") then
                castAbility("q"); lastCastAt = now
            elseif Settings.AutoE and not isAbilityOnCooldown("e") then
                castAbility("e"); lastCastAt = now
            end
        end
    end)
end

--- 启动/停止战斗循环 (统一入口)
local function restartCombatLoop()
    TheKing.StopLoop("combat") -- 先停再启, 确保新参数生效
    if Settings.AutoAttack or Settings.AutoQ or Settings.AutoE or Settings.FullHit then
        TheKing.StartLoop("combat", 0.5, combatTick, { jitter = false })
    else
        removeHoldMovers()
    end
end

-- ==================== 快捷键功能 ====================
--- 读取槽位技能信息 (名字/冷却/伤害)
local function getSlotInfo(slot)
    local tool = findAbilityTool(slot)
    if not tool then return nil end
    local info = { name = "?", cd = 0, cdLen = 0, dmg = 0 }
    local nv = tool:FindFirstChild("name")
    if nv then info.name = nv.Value end
    local cd = tool:FindFirstChild("cooldown")
    if cd then info.cd = cd.Value end
    local cl = tool:FindFirstChild("cooldownLength")
    if cl then info.cdLen = cl.Value end
    local dv = tool:FindFirstChild("damage")
    if dv then info.dmg = dv.Value end
    return info
end

-- 快捷键状态 Paragraph
local kbStatusPara

--- 刷新快捷键状态 (挂常驻循环, 差分刷新)
--- 冷却数字格式 %2.1f 匹配游戏 UI
local function refreshKeybindStatus()
    local q = getSlotInfo("q")
    local e = getSlotInfo("e")
    local qText = q and string.format("Q: %s | 冷却 %s | 伤害 %d", q.name, q.cd > 0 and string.format("%.1fs", q.cd) or "就绪", q.dmg) or "Q: 未装备"
    local eText = e and string.format("E: %s | 冷却 %s | 伤害 %d", e.name, e.cd > 0 and string.format("%.1fs", e.cd) or "就绪", e.dmg) or "E: 未装备"
    TheKing.UpdateStatus(kbStatusPara, qText, eText)
end

--- 手动触发 (快捷键回调用, 带冷却检查)
local function triggerSlot(slot)
    if isAbilityOnCooldown(slot) then
        TheKing.Notify({ Content = "技能冷却中", Icon = "timer" })
        return
    end
    local ok = castAbility(slot)
    if ok then
        TheKing.Notify({ Content = string.format("已释放 %s 槽技能", slot:upper()), Icon = "zap" })
    else
        TheKing.Notify({ Content = "技能释放失败 (未装备或正在施法)", Icon = "alert-triangle" })
    end
end

-- ==================== 业务清理登记 ====================
TheKing.OnCleanup(function()
    Settings.AutoAttack, Settings.AutoQ, Settings.AutoE, Settings.FullHit = false, false, false, false
    Settings.WalkSpeedMod = false
    removeHoldMovers()
    resetWalkSpeed()
    stopBossDodge()
end)

-- ============================================================
-- Tab: 战斗
-- ============================================================
local CombatTab = TheKing.NewTab({ Title = "战斗", Icon = "sword" })

local CombatSec = CombatTab:Section({ Title = "自动战斗" })

local attackTgl, qTgl, eTgl, fullHitTgl -- Toggle 引用 (持久化 Register 用)
local rangeSl, skillDelaySl, fullHitHeightSl, walkSpeedSl
local autoReadyTgl, skillWaitTgl, walkSpeedTgl
local kbQKey, kbEKey, kbToggleKey, kbUnloadKey

attackTgl = CombatSec:Toggle({
    Title = "自动普攻",
    Desc = "施法空闲时自动平A (没有技能/技能冷却时也持续输出)",
    Value = Settings.AutoAttack,
    Callback = function(v)
        Settings.AutoAttack = v
        restartCombatLoop()
        persistSave()
    end,
})

qTgl = CombatSec:Toggle({
    Title = "自动 Q 技能",
    Desc = "冷却结束自动释放 Q 槽技能",
    Value = Settings.AutoQ,
    Callback = function(v)
        Settings.AutoQ = v
        restartCombatLoop()
        persistSave()
    end,
})

eTgl = CombatSec:Toggle({
    Title = "自动 E 技能",
    Desc = "冷却结束自动释放 E 槽技能",
    Value = Settings.AutoE,
    Callback = function(v)
        Settings.AutoE = v
        restartCombatLoop()
        persistSave()
    end,
})

rangeSl = CombatSec:Slider({
    Title = "索敌范围 (studs)",
    Value = { Min = 30, Max = 500, Default = Settings.Range },
    Step = 10,
    Callback = function(v)
        Settings.Range = v
        persistSave()
    end,
})

skillDelaySl = CombatSec:Slider({
    Title = "技能间隔 (秒)",
    Desc = "自动技能的最小释放间隔",
    Value = { Min = 0.2, Max = 3, Default = Settings.SkillDelay },
    Step = 0.1,
    Callback = function(v)
        Settings.SkillDelay = v
        persistSave()
    end,
})

-- ---- L2: 全屏命中 ----
local FullHitSec = CombatTab:Section({ Title = "全屏命中 [L2]" })
fullHitTgl = FullHitSec:Toggle({
    Title = "技能无视距离全命中",
    Desc = "自行跑进入索敌范围后传头顶施法/普攻, 目标死亡自动切换 [L2]",
    Value = Settings.FullHit,
    Callback = function(v)
        Settings.FullHit = v
        if v and not configLoading then
            TheKing.Notify({
                Content = "全屏命中: 请自己跑到索敌范围内, 脚本再传头顶输出",
                Icon = "alert-triangle",
                Duration = 5,
            })
        elseif not v then
            removeHoldMovers()
        end
        restartCombatLoop()
        persistSave()
    end,
})

fullHitHeightSl = FullHitSec:Slider({
    Title = "头顶高度 (studs)",
    Desc = "进入范围后传送到敌人上方的距离",
    Value = { Min = 4, Max = 16, Default = Settings.FullHitHeight },
    Step = 0.5,
    Callback = function(v)
        Settings.FullHitHeight = v
        persistSave()
    end,
})

-- ---- 辅助功能 ----
local MiscSec = CombatTab:Section({ Title = "辅助" })

walkSpeedTgl = MiscSec:Toggle({
    Title = "修改移动速度",
    Desc = "提高 WalkSpeed 方便自己跑向目标 (游戏可能周期性重置, 脚本会回写)",
    Value = Settings.WalkSpeedMod,
    Callback = function(v)
        Settings.WalkSpeedMod = v
        if not v then resetWalkSpeed() else applyWalkSpeed() end
        persistSave()
    end,
})

walkSpeedSl = MiscSec:Slider({
    Title = "移动速度",
    Value = { Min = 16, Max = 120, Default = Settings.WalkSpeed },
    Step = 1,
    Callback = function(v)
        Settings.WalkSpeed = v
        if Settings.WalkSpeedMod then applyWalkSpeed() end
        persistSave()
    end,
})

autoReadyTgl = MiscSec:Toggle({
    Title = "自动准备 / 开始",
    Desc = "准备→readyUp | 世界START→changeStartValue | 大厅Start→startDungeon",
    Value = Settings.AutoReady,
    Callback = function(v)
        Settings.AutoReady = v
        persistSave()
    end,
})

skillWaitTgl = MiscSec:Toggle({
    Title = "技能等待释放",
    Desc = "释放一个技能后等待动画完成再释放下一个 (更稳但略慢)",
    Value = Settings.SkillWaitCast,
    Callback = function(v)
        Settings.SkillWaitCast = v
        persistSave()
    end,
})

local StateSec = CombatTab:Section({ Title = "状态" })
statePara = StateSec:Paragraph({ Title = "状态: 未启用", Desc = "打开自动攻击/自动技能/全屏命中后开始" })

-- ============================================================
-- Tab: 快捷键
-- ============================================================
local KeybindTab = TheKing.NewTab({ Title = "快捷键", Icon = "keyboard" })

local KbInfoSec = KeybindTab:Section({ Title = "当前技能" })
kbStatusPara = KbInfoSec:Paragraph({ Title = "读取技能信息中...", Desc = "Q/E 槽技能与冷却状态" })

local KbTriggerSec = KeybindTab:Section({ Title = "手动触发" })
kbQKey = KbTriggerSec:Keybind({
    Title = "触发 Q 槽技能",
    Desc = "按下指定键释放 Q 槽技能 (默认 F1, 避免与游戏 Q 键冲突)",
    Value = "F1",
    Callback = function()
        triggerSlot("q")
    end,
})
kbEKey = KbTriggerSec:Keybind({
    Title = "触发 E 槽技能",
    Desc = "按下指定键释放 E 槽技能 (默认 F2, 避免与游戏 E 键冲突)",
    Value = "F2",
    Callback = function()
        triggerSlot("e")
    end,
})
KbTriggerSec:Button({
    Title = "普攻一次",
    Desc = "立即执行一次普通攻击",
    Icon = "mouse-pointer-click",
    Callback = function()
        local ok = normalAttack()
        TheKing.Notify({ Content = ok and "已普攻" or "普攻失败 (非副本/无武器/施法中)", Icon = ok and "check-circle" or "alert-triangle" })
    end,
})

local KbHintSec = KeybindTab:Section({ Title = "提示" })
KbHintSec:Paragraph({
    Title = "游戏原生按键",
    Desc = "游戏内 Q/E 键已原生绑定技能; 此处 Keybind 用于从 Hub 触发, 可改绑任意键。普攻为鼠标左键。",
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

kbToggleKey = SettingsTab:Keybind({
    Title = "显示/隐藏窗口",
    Desc = "切换主窗口可见性",
    Value = "Delete",
    Callback = function()
        TheKing.Window:Toggle()
    end,
})

kbUnloadKey = SettingsTab:Keybind({
    Title = "卸载脚本",
    Desc = "按下后弹出确认对话框",
    Value = "End",
    Callback = function()
        persistSave()
        unloadAction()
    end,
})

SettingsTab:Button({
    Title = "停止全部功能",
    Desc = "关闭所有自动循环 (不销毁窗口)",
    Icon = "square",
    Callback = function()
        Settings.AutoAttack, Settings.AutoQ, Settings.AutoE, Settings.FullHit = false, false, false, false
        restartCombatLoop()
        if statePara then pcall(function() TheKing.UpdateStatus(statePara, "状态: 未启用", "打开自动攻击/自动技能/全屏命中后开始") end) end
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
-- 快捷键状态刷新 (1秒一次, 差分更新)
TheKing.StartLoop("kbStatus", 1, refreshKeybindStatus)

-- 启动自动准备循环 (独立于战斗, 每1秒检测一次)
TheKing.StartLoop("autoReady", 1, function()
    pcall(function() autoReady() end)
end)

-- 启动 BOSS 攻击躲避监听
setupBossDodge()

-- 移动速度: 重生回写 + 周期防重置
LocalPlayer.CharacterAdded:Connect(function()
    baseWalkSpeed = nil
    task.defer(applyWalkSpeed)
end)
TheKing.StartLoop("walkspeed", 1, function()
    if Settings.WalkSpeedMod then applyWalkSpeed() end
end)

-- 自动准备/开始: 事件驱动 (远程触发立刻响应)
task.spawn(function()
    local remotes = game.ReplicatedStorage:WaitForChild("remotes", 10)
    if not remotes then return end
    local showReadyGui = remotes:FindFirstChild("showReadyGui")
    if showReadyGui then
        showReadyGui.OnClientEvent:Connect(function()
            if Settings.AutoReady then
                task.wait(0.35)
                pcall(function() remotes.readyUp:FireServer() end)
            end
        end)
    end
    local showStartBtn = remotes:FindFirstChild("showStartButton")
    if showStartBtn then
        showStartBtn.OnClientEvent:Connect(function()
            if Settings.AutoReady then
                task.wait(0.35)
                pcall(function() remotes.changeStartValue:FireServer() end)
            end
        end)
    end
end)

-- 启动状态对齐
task.delay(1, function()
    refreshKeybindStatus()
    restartCombatLoop() -- 按当前 Settings 启动循环
end)

-- ==================== Flag 注册 (脱离创建期, 避免配置系统误触发) ====================
-- WindUI v1.6.66 坑: Toggle 创建时带 Flag 会被配置系统误触发 Callback(true) → 先创建后延迟 Register
-- Load 必须在 Register 之后显式调用, 否则恢复为空 (heroes-rng 首飞实测)
task.delay(0.2, function()
    if TheKing.Config then
        pcall(function() TheKing.Config:Register("combat_autoattack", attackTgl) end)
        pcall(function() TheKing.Config:Register("combat_autoq", qTgl) end)
        pcall(function() TheKing.Config:Register("combat_autoe", eTgl) end)
        pcall(function() TheKing.Config:Register("combat_fullhit", fullHitTgl) end)
        pcall(function() TheKing.Config:Register("combat_range", rangeSl) end)
        pcall(function() TheKing.Config:Register("combat_skilldelay", skillDelaySl) end)
        pcall(function() TheKing.Config:Register("combat_fullhit_height", fullHitHeightSl) end)
        pcall(function() TheKing.Config:Register("combat_walkspeed", walkSpeedTgl) end)
        pcall(function() TheKing.Config:Register("combat_walkspeed_val", walkSpeedSl) end)
        pcall(function() TheKing.Config:Register("combat_autoready", autoReadyTgl) end)
        pcall(function() TheKing.Config:Register("combat_skillwait", skillWaitTgl) end)
        pcall(function() TheKing.Config:Register("kb_trigger_q", kbQKey) end)
        pcall(function() TheKing.Config:Register("kb_trigger_e", kbEKey) end)
        pcall(function() TheKing.Config:Register("settings_toggle_window", kbToggleKey) end)
        pcall(function() TheKing.Config:Register("settings_unload", kbUnloadKey) end)
        configLoading = true
        TheKing.LoadConfig() -- Register 完成后再 Load, 顺序不能反 (否则恢复为空)
        configLoading = false
        pcall(function() restartCombatLoop() end)
        pcall(function()
            if Settings.WalkSpeedMod then applyWalkSpeed() else resetWalkSpeed() end
        end)
        print("[Dungeon Quest Reborn] 配置持久化已就绪 (全部战斗/快捷键/设置项)")
    else
        print("[Dungeon Quest Reborn] 无 ConfigManager, 持久化降级跳过")
    end
end)
