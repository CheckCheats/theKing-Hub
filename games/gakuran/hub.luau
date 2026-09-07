--[[
    TheKing HUB [0.0.1] - (学乱) Gakuran
    RCWTK 引擎生成 | 模板 v1.0
    版本历史: games/gakuran/changelog.md (每次发布追加条目, 语义见该文件)

    功能清单 (改这里, 保持格式):
      动作-祖国人: 变身/恢复, 真实祖国人动画 (UGC Homelander 系列) + 飞行 (WASD/空格/C)
      动作-替身使者: 选定目标玩家, 循环播放真实JOJO姿势并自动跟随其身后
      动作-大陀螺: 角色高速自转, 不影响 WASD 实际操控
      动作-倒走: 角色面朝反向行走, 操作方向不变
      战斗-快攻: 清除攻击冷却标记+残留动画, 攻击节奏可调 (默认 0.18s/拳)
      战斗-遗忘: 多选跳过 M1 的第 N 段平A (如选4A: 打完3A直接回1A)

    逆向结论 (关键协议结论写这里, 收工同步到 games/gakuran/intel.md):
      - 全服可见原理: 角色物理 (HRP) 与自己角色上的 Animator 播放均随网络所有权复制;
        自定义动画 = Animator:LoadAnimation(Animation) 后 Play 即 FE 生效
      - UGC Emote 商品 ID ≠ 动画 ID, 用 game:GetObjects(商品ID) 拆包取内部 Animation.AnimationId
      - 祖国人真实动画 ID (已验证可播): Fly=134974990345233 Hover=126046533185038
        Pose=70950173927129 GodIdle=99778215626688
      - JOJO 动画: WorldStand=127063604572089 JojoIdle3=114636753459405
      - M1 连击修复锚点: M1Mod.ServerResponse 的 upvalue[4]=combo计数器 [5]=出拳就绪flag
        [8]=ComboResetTime=1.55 (布局校验锚); ServerResponse 与 tryM1 共享同一批 upvalue
        且未被 hookfunction 污染 (OnM1Activated 被 detour 后 getupvalue 报错)

    使用方式:
      开发: loadstring(readfile("games/gakuran/hub.luau"))()   -- 与 lib/ 同级目录执行
      热调试: 改完代码直接重新执行本文件, 旧实例自动自毁让位, 无需手动卸载
      发布: 用构建脚本把 theking.luau 内嵌后单文件化

    注入器要求: hookfunction + debug.getupvalue/setupvalue + getnilinstances (Real/Synapse 系)
]]

-- 双环境兼容: RCWTK 项目目录 = lib/theking.luau; Real 注入器 workspace = theking.luau
local LIB_CANDIDATES = { "lib/theking.luau", "theking.luau" }
local libSource = nil
for _, p in ipairs(LIB_CANDIDATES) do
    if type(isfile) == "function" and isfile(p) then
        libSource = readfile(p)
        break
    end
end
if not libSource then
    error("[TheKing] 找不到 theking.luau 运行库 (lib/ 或 workspace 根)", 0)
end
local TheKing = loadstring(libSource)({
    GameName = "(学乱) Gakuran",
    ScriptVersion = "0.0.1",
})

-- ============================================================
-- 基础工具
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local function getChar()
    return LocalPlayer.Character
end

local function getHrp()
    local char = getChar()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = getChar()
    return char and char:FindFirstChildOfClass("Humanoid")
end

--- 相机 yaw (弧度)
local function getCamYaw()
    local look = workspace.CurrentCamera.CFrame.LookVector
    return math.atan2(-look.X, -look.Z)
end

--- 恢复 Humanoid 默认朝向控制 (所有姿态类功能关闭时调用)
local function restoreAutoRotate()
    local hum = getHumanoid()
    if hum then
        hum.AutoRotate = true
    end
end

-- ============================================================
-- Emote 桥接 (全服可见动作的唯一合法通道)
-- EmoteServiceClient 被 bootstrap 摘除 parent, 从 nil 实例里找回 require
-- ============================================================
local emoteClient = nil

--- 从 nil-parent 实例中找回被 bootstrap 摘除的模块并 require
local function requireNilModule(moduleName)
    if type(getnilinstances) ~= "function" then return nil end
    local ok, list = pcall(getnilinstances)
    if not ok or not list then return nil end
    for _, inst in ipairs(list) do
        if inst.Name == moduleName and inst.ClassName == "ModuleScript" then
            local rok, mod = pcall(require, inst)
            if rok then return mod end
        end
    end
    return nil
end

local function findEmoteClient()
    -- 主路: 从 nil 实例找回 (bootstrap 后 Shared.Services 被摘除 parent)
    local mod = requireNilModule("EmoteServiceClient")
    if mod and type(mod) == "table" and type(mod.RequestPlay) == "function" then
        return mod
    end
    -- 兜底: 游戏未销毁时直接走正常路径
    local direct = ReplicatedStorage:FindFirstChild("Shared")
    local services = direct and direct:FindFirstChild("Services")
    local folder = services and services:FindFirstChild("EmoteService")
    local mod2 = folder and folder:FindFirstChild("EmoteServiceClient")
    if mod2 then
        local rok2, mod3 = pcall(require, mod2)
        if rok2 and type(mod3) == "table" and type(mod3.RequestPlay) == "function" then
            return mod3
        end
    end
    return nil
end

emoteClient = findEmoteClient()

--- 播放全服可见动作; 返回 false 表示被游戏拒绝 (空中/战斗中/绿区等)
local function playEmote(category, name)
    if not emoteClient then
        TheKing.Notify({ Content = "动作桥接不可用 (游戏结构变化)", Icon = "alert-triangle" })
        return false
    end
    local ok, res = pcall(function()
        if name then
            return emoteClient:RequestPlay(category, name)
        end
        return emoteClient:RequestPlay(category)
    end)
    return ok and res == true
end

-- ============================================================
-- 自定义动画播放器 (FE 通道)
-- 在自己角色的 Animator 上播放任意动画 ID, 随网络所有权复制 = 全服可见
-- ============================================================
local customTracks = {} -- key -> AnimationTrack

--- 停止并清理指定 key 的动画
local function stopCustomAnim(key)
    local track = customTracks[key]
    if track then
        pcall(function()
            track:Stop(0.15)
            track:Destroy()
        end)
        customTracks[key] = nil
    end
end

--- 停止全部自定义动画 (角色重生/功能关闭时)
local function stopAllCustomAnims()
    for key in pairs(customTracks) do
        stopCustomAnim(key)
    end
end

--- 在自己角色上播放动画 (全服可见); 返回 track 或 nil
--- exclusive: 播放前停掉 Animator 上一切其他 track (含游戏 Core 动画), 独占全部关节
local function playCustomAnim(key, animId, looped, fade, speed, exclusive)
    local char = getChar()
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if not animator then
        return nil
    end
    -- 姿态功能互斥 (acquirePose 保证), 同一时刻只应有一个动作流:
    -- 先清光自家所有旧 track, 杜绝多个 Action 动画权重混合导致姿势畸变
    stopAllCustomAnims()
    -- 独占模式: 连游戏自己的 Core 动画一起清场, 未覆盖关节不再透出下层姿势
    if exclusive then
        pcall(function()
            for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
                t:Stop(0)
            end
        end)
    end
    local ok, track = pcall(function()
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://" .. tostring(animId)
        local t = animator:LoadAnimation(anim)
        t.Priority = Enum.AnimationPriority.Action
        t.Looped = looped and true or false
        if speed then
            t:Play(fade or 0.15, 1, speed)
        else
            t:Play(fade or 0.15)
        end
        return t
    end)
    if ok and track then
        customTracks[key] = track
        return track
    end
    return nil
end

--- 冻结 Humanoid 全部状态 + 关闭游戏 Animate 脚本 (超人飞标配, 防状态机抢关节)
--- 返回恢复函数
local function suppressHumanoidAnim(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then
        return function() end
    end
    pcall(function()
        for _, st in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
            if st ~= Enum.HumanoidStateType.None then
                hum:SetStateEnabled(st, false)
            end
        end
    end)
    local animateScript = char:FindFirstChild("Animate")
    local wasEnabled = animateScript and animateScript:IsA("LocalScript") and animateScript.Enabled
    if animateScript then
        pcall(function() animateScript.Disabled = true end)
        pcall(function() animateScript.Enabled = false end)
    end
    return function()
        pcall(function()
            for _, st in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
                if st ~= Enum.HumanoidStateType.None then
                    hum:SetStateEnabled(st, true)
                end
            end
        end)
        if animateScript then
            pcall(function() animateScript.Disabled = false end)
            pcall(function() animateScript.Enabled = wasEnabled == true end)
        end
        pcall(function() hum.PlatformStand = false end)
    end
end

-- 角色重生: 清空 track 表 + 由各功能自行重播 (状态机在 Heartbeat 里持续驱动, 自动恢复)
TheKing.AddConnection(LocalPlayer.CharacterAdded:Connect(function()
    table.clear(customTracks)
end))

-- ============================================================
-- 姿态控制权管理: 同一时间只允许一个功能持有 yaw 控制权
-- ============================================================
local poseOwners = {} -- name -> true
local onPoseReleaseCallbacks = {} -- name -> fn(关闭时的清理)

local function releasePose(name)
    if poseOwners[name] then
        poseOwners[name] = nil
        local cb = onPoseReleaseCallbacks[name]
        if cb then
            pcall(cb)
        end
    end
end

--- 抢占姿态控制权; 若其他功能正持有则先释放它, 返回是否成功
local function acquirePose(name)
    for owner in pairs(poseOwners) do
        if owner ~= name then
            releasePose(owner)
            TheKing.Notify({ Content = "已自动切换姿态功能: 关闭 [" .. owner .. "]", Icon = "info" })
        end
    end
    poseOwners[name] = true
    local hum = getHumanoid()
    if hum then
        hum.AutoRotate = false
    end
    return true
end

TheKing.OnCleanup(function()
    for name in pairs(poseOwners) do
        releasePose(name)
    end
    restoreAutoRotate()
end)

-- ============================================================
-- Tab: 动作
-- ============================================================
local ActionTab = TheKing.NewTab({ Title = "动作", Icon = "zap" })

-- ------------------------------------------------------------
-- 动作-祖国人: 变身/恢复 + 飞行 + 真实祖国人动画 (FE 全服可见)
-- 动画资源: Roblox UGC "Homelander" 系列 (GetObjects 拆包取真实 AnimationId)
-- ------------------------------------------------------------
do
    -- 真实动画 ID (pv7560 实测全部可播)
    local ANIMS = {
        Fly = 134974990345233,   -- Homelander Fly Pose 超人飞 (4.7s)
        Hover = 126046533185038, -- Homelander Hover 悬浮抱臂 (1.6s)
        Pose = 70950173927129,   -- Homelander Pose 威压站姿 (4.0s)
        GodIdle = 99778215626688,-- Homelander GOD Idle 神态待机 (4.0s)
    }

    local flySpeed = 60
    local flyConn = nil
    local hlActive = false
    local currentPoseKey = nil -- 当前手动姿势 ("hover"/"pose"/"godidle")

    --- 飞行状态机: Fly/Hover 全部用"定格"技术 (AdjustSpeed(0) 冻结在最佳帧),
    --- 姿势永远稳定无接缝; 每帧重禁 Humanoid 状态防游戏抢回关节
    local FREEZE_AT = { fly = 0.5, hover = 0.8, pose = nil, godidle = nil }

    local function updateFlyAnim(moving, rising)
        if not hlActive then return end
        local wantKey
        if currentPoseKey and not moving and not rising then
            wantKey = currentPoseKey
        elseif moving or rising then
            wantKey = "fly"
        else
            wantKey = "idle"
        end
        local track = customTracks["hl"]
        if customTracks._state ~= wantKey or (not track or not track.IsPlaying) then
            customTracks._state = wantKey
            stopCustomAnim("hl")
            local animId = (wantKey == "fly" and ANIMS.Fly)
                or (wantKey == "idle" and ANIMS.Hover)
                or ANIMS.Pose
            local t = playCustomAnim("hl", animId, true, 0.2, nil, true)
            if t and FREEZE_AT[wantKey] then
                -- 定格: fade 完成后冻在指定帧; 每帧由下方保活逻辑钉住
                local freezeAt = FREEZE_AT[wantKey]
                task.delay(0.3, function()
                    if t.IsPlaying then
                        t:AdjustSpeed(0)
                        t.TimePosition = freezeAt
                        customTracks._frozen = true
                        customTracks._freezeAt = freezeAt
                    end
                end)
                customTracks._frozen = false -- fade 期间先正常播
            else
                customTracks._frozen = false
            end
            return
        end
        -- 定格保活: 已冻结的 track 每帧钉时间位置 + 重禁状态 (防游戏动画系统抢回)
        if track and track.IsPlaying and customTracks._frozen and customTracks._freezeAt then
            pcall(function()
                track:AdjustSpeed(0)
                track.TimePosition = customTracks._freezeAt
            end)
        end
        local hum = getHumanoid()
        if hum then
            pcall(function()
                for _, st in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
                    if st ~= Enum.HumanoidStateType.None and st ~= Enum.HumanoidStateType.Dead then
                        if hum:GetStateEnabled(st) then
                            hum:SetStateEnabled(st, false)
                        end
                    end
                end
            end)
        end
    end

    ActionTab:Toggle({
        Title = "祖国人 · 变身",
        Desc = "真·祖国人动画+飞行: WASD 沿视角全向飞 / 空格上升 / C 下降, 全服可见",
        Flag = "homelanderToggle",
        Value = false,
        Callback = function(state)
            if state then
                if not acquirePose("祖国人") then return end
                local hrp = getHrp()
                local hum0 = getHumanoid()
                if not hrp or not hum0 then
                    TheKing.Notify({ Content = "角色未加载, 稍后再试", Icon = "alert-triangle" })
                    releasePose("祖国人")
                    return
                end
                hlActive = true
                customTracks._frozen = false
                -- 废掉 Humanoid 状态机 + 游戏 Animate 脚本: 关节完全由本功能动画接管
                -- (restoreAnim 必须在关闭时调用, 否则状态机永久残废)
                local restoreHumanoidAnim = suppressHumanoidAnim(getChar())
                hum0.PlatformStand = true
                flyConn = RunService.Heartbeat:Connect(function(dt)
                    local myHrp = getHrp()
                    local hum = getHumanoid()
                    if not myHrp or not hum or hum.Health <= 0 then return end
                    if not hum.PlatformStand then
                        hum.PlatformStand = true -- 防外部状态重置
                    end
                    -- WASD 沿相机全向向量 (含俯仰): W = 往视线方向飞, 身体随之倾斜
                    local camCF = workspace.CurrentCamera.CFrame
                    local move = Vector3.zero
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                        move += camCF.LookVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                        move -= camCF.LookVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                        move += camCF.RightVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                        move -= camCF.RightVector
                    end
                    local rising = false
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                        move += Vector3.yAxis
                        rising = true
                    elseif UserInputService:IsKeyDown(Enum.KeyCode.C) then
                        move -= Vector3.yAxis
                        rising = true
                    end

                    local vel
                    if move.Magnitude > 0.01 then
                        vel = move.Unit * flySpeed
                    else
                        vel = Vector3.zero
                    end
                    myHrp.AssemblyLinearVelocity = vel

                    -- 【全服可见核心】身体长轴完全对齐飞行方向 (含垂直):
                    -- 公式 = yaw * (pitch - 90°): pitch=0 时水平躺飞; 抬头看天 pitch→85°,
                    -- 身体随之立起斜向上飞 — "绝对面向一个方向且能达到垂直"
                    local camLook = camCF.LookVector
                    local yaw = math.atan2(-camLook.X, -camLook.Z)
                    local targetCF
                    if move.Magnitude > 0.01 then
                        -- 飞行: 身体对齐速度方向 (用视线俯仰角, 与移动方向一致)
                        local pitch = math.asin(math.clamp(camLook.Y, -1, 1))
                        pitch = math.clamp(pitch, -math.rad(85), math.rad(85))
                        targetCF = CFrame.new(myHrp.Position)
                            * CFrame.Angles(0, yaw, 0)
                            * CFrame.Angles(pitch - math.rad(90), 0, 0)
                    else
                        -- 悬浮: 直立 + 视线水平朝向
                        targetCF = CFrame.new(myHrp.Position) * CFrame.Angles(0, yaw, 0)
                    end
                    myHrp.CFrame = myHrp.CFrame:Lerp(targetCF, math.clamp(dt * 10, 0, 1))

                    updateFlyAnim(move.Magnitude > 0.01, rising)
                end)
                TheKing.AddConnection(flyConn)
                onPoseReleaseCallbacks["祖国人"] = function()
                    if flyConn then
                        flyConn:Disconnect()
                        flyConn = nil
                    end
                    hlActive = false
                    customTracks._state = nil
                    customTracks._frozen = false
                    currentPoseKey = nil
                    stopCustomAnim("hl")
                    local hrp2 = getHrp()
                    if hrp2 then
                        hrp2.AssemblyLinearVelocity = Vector3.zero
                        -- 回正直立朝向 (保留原 yaw, 清掉飞行俯仰)
                        local _, yaw, _ = hrp2.CFrame:ToOrientation()
                        hrp2.CFrame = CFrame.new(hrp2.Position) * CFrame.Angles(0, yaw, 0)
                    end
                    local hum2 = getHumanoid()
                    if hum2 then
                        hum2.PlatformStand = false -- 归还动画/物理控制权给游戏
                    end
                    -- 恢复 Humanoid 状态机 + Animate 脚本 (旧版漏接这步导致永久残废)
                    if restoreHumanoidAnim then
                        pcall(restoreHumanoidAnim)
                        restoreHumanoidAnim = nil
                    end
                end
                TheKing.Notify({ Content = "祖国人形态已激活 — 起飞吧", Icon = "crown" })
            else
                releasePose("祖国人")
                TheKing.Notify({ Content = "已恢复普通形态", Icon = "circle-slash" })
            end
        end,
    })

    ActionTab:Slider({
        Title = "祖国人 · 飞行速度",
        Value = { Min = 20, Max = 120, Default = 60 },
        Step = 5,
        Callback = function(v)
            flySpeed = v
        end,
    })

    ActionTab:Section({ Title = "祖国人 · 全套姿势动作 (真实动画·全服可见)" })

    --- 手动锁定一个姿势 (静止时保持; 移动后自动切回飞姿)
    local function lockPose(key, label)
        currentPoseKey = key
        customTracks._state = nil -- 强制状态机刷新
        TheKing.Notify({ Content = label .. " — 全服可见", Icon = "check-circle" })
    end

    local poseButtons = {
        { Key = "hover", Label = "悬浮蓄势 (Hover)", Id = ANIMS.Hover },
        { Key = "pose", Label = "威压站姿 (Pose)", Id = ANIMS.Pose },
        { Key = "godidle", Label = "神态俯瞰 (God Idle)", Id = ANIMS.GodIdle },
    }
    for _, btn in ipairs(poseButtons) do
        ActionTab:Button({
            Title = btn.Label,
            Icon = "sparkles",
            Callback = function()
                if hlActive then
                    lockPose(btn.Key, btn.Label)
                else
                    TheKing.Notify({ Content = "先开启「祖国人 · 变身」", Icon = "alert-triangle" })
                end
            end,
        })
    end
end

-- ------------------------------------------------------------
-- 动作-替身使者: 目标玩家 + 动作跟随
-- ------------------------------------------------------------
do
    local standTargetName = nil   -- 选定的目标玩家名
    local standEmote = nil        -- {Label=, Id=} 选定动作
    local standActive = false
    local followDist = 4.5
    local offsetX = 1.8           -- 目标右侧偏移 (负值=左侧)
    local offsetY = 1.8           -- 目标上方偏移
    local standDropdown = nil     -- Dropdown 句柄 (刷新列表用销毁重建)
    local standSection = ActionTab:Section({ Title = "替身使者 · 配置" })

    local POSE_CHOICES = {
        { Label = "世界替身姿势", Id = 127063604572089 },  -- The World Stand Pose (DIO)
        { Label = "JOJO待机·叁", Id = 114636753459405 },   -- Jojo Pose Idle Pt3
    }

    --- 列举可选玩家名 (排除自己)
    local function listPlayerNames()
        local names = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                table.insert(names, plr.Name)
            end
        end
        table.sort(names)
        return names
    end

    local function resolveTargetChar()
        if not standTargetName then return nil end
        local plr = Players:FindFirstChild(standTargetName)
        if not plr or not plr.Character then return nil end
        local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end
        local hum = plr.Character:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return nil end
        return plr.Character, hrp
    end

    local function buildTargetDropdown(parent)
        if standDropdown then
            pcall(function() standDropdown:Destroy() end)
            standDropdown = nil
        end
        standDropdown = parent:Dropdown({
            Title = "替身使者 · 选择附身目标",
            Values = listPlayerNames(),
            AllowNone = true,
            Callback = function(sel)
                standTargetName = sel
            end,
        })
    end

    buildTargetDropdown(standSection)

    standSection:Button({
        Title = "刷新玩家列表",
        Icon = "refresh-cw",
        Callback = function()
            buildTargetDropdown(standSection)
            TheKing.Notify({ Content = "玩家列表已刷新 (" .. tostring(#listPlayerNames()) .. " 人在线)", Icon = "check-circle" })
        end,
    })

    standSection:Slider({
        Title = "跟随距离 · 身后 (格)",
        Value = { Min = 1, Max = 12, Default = 4.5 },
        Step = 0.5,
        Callback = function(v)
            followDist = v
        end,
    })

    standSection:Slider({
        Title = "站位 · 左右偏移 (身后视角, 正=画面右)",
        Value = { Min = -6, Max = 6, Default = 1.8 },
        Step = 0.2,
        Callback = function(v)
            offsetX = v
        end,
    })

    standSection:Slider({
        Title = "站位 · 高度偏移",
        Value = { Min = -4, Max = 8, Default = 1.8 },
        Step = 0.2,
        Callback = function(v)
            offsetY = v
        end,
    })

    local actionNames = {}
    for i, choice in ipairs(POSE_CHOICES) do
        actionNames[i] = choice.Label
    end
    standSection:Dropdown({
        Title = "替身使者 · 替身动作 (真实JOJO动画)",
        Values = actionNames,
        AllowNone = true,
        Callback = function(sel)
            for _, c in ipairs(POSE_CHOICES) do
                if c.Label == sel then
                    standEmote = c
                    break
                end
            end
        end,
    })

    ActionTab:Toggle({
        Title = "替身使者 · 启动跟随",
        Desc = "变成替身使者: 循环播放真实JOJO动作并贴身跟在目标身后 (全服可见)",
        Flag = "standToggle",
        Value = false,
        Callback = function(state)
            standActive = state
            if state then
                if not acquirePose("替身使者") then
                    standActive = false
                    return
                end
                if not standTargetName then
                    TheKing.Notify({ Content = "先选择一个附身目标", Icon = "alert-triangle" })
                    standActive = false
                    releasePose("替身使者")
                    return
                end
                if not standEmote then
                    TheKing.Notify({ Content = "先选一个替身动作", Icon = "alert-triangle" })
                    standActive = false
                    releasePose("替身使者")
                    return
                end
                -- 跟随循环: 每帧把角色贴到目标右后上方 (HRP 物理复制 = 全服可见)
                local followConn
                followConn = RunService.Heartbeat:Connect(function(dt)
                    if not standActive then return end
                    local targetChar, targetHrp = resolveTargetChar()
                    local myHrp = getHrp()
                    if not targetChar or not myHrp then return end
                    -- JOJO 替身站位: 目标身后 followDist 处, 在垂直于"替身↔目标"连线的
                    -- 平面内做二维偏移 — offsetX=从身后看的左右 / offsetY=高度
                    local behindPos = (targetHrp.CFrame * CFrame.new(offsetX, offsetY, followDist)).Position
                    -- 太远直接瞬移兜底 (目标传送/重生场景)
                    if (behindPos - myHrp.Position).Magnitude > 40 then
                        myHrp.CFrame = CFrame.new(behindPos)
                        return
                    end
                    local alpha = math.clamp(dt * 8, 0, 1)
                    local newPos = myHrp.Position:Lerp(behindPos, alpha)
                    local lookAt = Vector3.new(targetHrp.Position.X, newPos.Y, targetHrp.Position.Z)
                    if (lookAt - newPos).Magnitude > 0.5 then
                        myHrp.CFrame = CFrame.lookAt(newPos, lookAt)
                    else
                        myHrp.CFrame = CFrame.new(newPos)
                    end
                end)
                TheKing.AddConnection(followConn)
                onPoseReleaseCallbacks["替身使者"] = function()
                    if followConn then
                        followConn:Disconnect()
                    end
                    stopCustomAnim("stand")
                end
                -- 真实JOJO动画循环播放 (FE 通道全服可见); track 掉了就重播
                TheKing.StartLoop("stand_emote", 0.6, function()
                    if not standActive or not standEmote then return end
                    local track = customTracks["stand"]
                    local playing = track and track.IsPlaying
                    if not playing then
                        playCustomAnim("stand", standEmote.Id, true, 0.2)
                    end
                end)
                TheKing.Notify({ Content = "替身 [ " .. standEmote.Label .. " ] 已附身于 " .. standTargetName, Icon = "eye" })
            else
                TheKing.StopLoop("stand_emote")
                releasePose("替身使者")
                TheKing.Notify({ Content = "替身已收回", Icon = "circle-slash" })
            end
        end,
    })
end

-- ------------------------------------------------------------
-- 动作-大陀螺
-- ------------------------------------------------------------
do
    local spinSpeedDeg = 720 -- 度/秒
    local spinAngle = 0
    local spinConn = nil

    ActionTab:Toggle({
        Title = "大陀螺",
        Desc = "角色疯狂自转, WASD 操控不受影响 (全服可见)",
        Flag = "spinToggle",
        Value = false,
        Callback = function(state)
            if state then
                if not acquirePose("大陀螺") then return end
                spinAngle = 0
                spinConn = RunService.Heartbeat:Connect(function(dt)
                    local hrp = getHrp()
                    if not hrp then return end
                    spinAngle = (spinAngle + math.rad(spinSpeedDeg) * dt) % (math.pi * 2)
                    hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, spinAngle, 0)
                    hrp.AssemblyAngularVelocity = Vector3.zero -- 吃掉物理旋转叠加, 旋转全由本连接驱动
                end)
                TheKing.AddConnection(spinConn)
                onPoseReleaseCallbacks["大陀螺"] = function()
                    if spinConn then
                        spinConn:Disconnect()
                        spinConn = nil
                    end
                end
                TheKing.Notify({ Content = "大陀螺已启动", Icon = "rotate-cw" })
            else
                releasePose("大陀螺")
            end
        end,
    })

    ActionTab:Slider({
        Title = "大陀螺 · 转速 (度/秒)",
        Value = { Min = 180, Max = 1440, Default = 720 },
        Step = 60,
        Callback = function(v)
            spinSpeedDeg = v
        end,
    })
end

-- ------------------------------------------------------------
-- 动作-倒走
-- ------------------------------------------------------------
do
    local backConn = nil

    ActionTab:Toggle({
        Title = "倒走",
        Desc = "人物面朝反方向行走, 操作方向不变 (全服可见)",
        Flag = "backwalkToggle",
        Value = false,
        Callback = function(state)
            if state then
                if not acquirePose("倒走") then return end
                backConn = RunService.Heartbeat:Connect(function()
                    local hrp = getHrp()
                    if not hrp then return end
                    hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, getCamYaw() + math.pi, 0)
                end)
                TheKing.AddConnection(backConn)
                onPoseReleaseCallbacks["倒走"] = function()
                    if backConn then
                        backConn:Disconnect()
                        backConn = nil
                    end
                end
                TheKing.Notify({ Content = "倒走已启动", Icon = "arrow-left-right" })
            else
                releasePose("倒走")
            end
        end,
    })
end

-- ------------------------------------------------------------
-- 动作-走路姿势: 全套平常走路/待机/跑步替换 (战斗姿态不受影响)
-- 逆向依据: MovementServiceClient 平常 locomotion 源 = Animations.Movement 文件夹
--   MaleWalk/FemaleWalk (走路) + MaleRun/FemaleRun (跑步) + Idle1/Idle2 (待机)
--   本地改 Animation 实例的 AnimationId → 本客户端加载播放 → FE 复制全服可见
-- 姿势包数据: Roblox 官方动画包 (create.roblox.com/docs/animation/using), 永不失效
-- ------------------------------------------------------------
do
    local WALK_PACKS = {
        { Label = "忍者", Run = 656118852, Walk = 656121766, IdleA = 656117400, IdleB = 656118341 },
        { Label = "骑士", Run = 657564596, Walk = 657552124, IdleA = 657595757, IdleB = 657568135 },
        { Label = "海盗", Run = 750783738, Walk = 750785693, IdleA = 750781874, IdleB = 750782770 },
        { Label = "僵尸", Run = 616163682, Walk = 616168032, IdleA = 616158929, IdleB = 616160636 },
        { Label = "吸血鬼", Run = 1083462077, Walk = 1083473930, IdleA = 1083445855, IdleB = 1083450166 },
        { Label = "狼人", Run = 1083216690, Walk = 1083178339, IdleA = 1083195517, IdleB = 1083214717 },
        { Label = "超级英雄", Run = 616117076, Walk = 616122287, IdleA = 616111295, IdleB = 616113536 },
        { Label = "法师", Run = 707861613, Walk = 707897309, IdleA = 707742142, IdleB = 707855907 },
        { Label = "机器人", Run = 616091570, Walk = 616095330, IdleA = 616088211, IdleB = 616089559 },
        { Label = "宇航员", Run = 891636393, Walk = 891636393, IdleA = 891621366, IdleB = 891633237 },
        { Label = "卡通", Run = 742638842, Walk = 742640026, IdleA = 742637544, IdleB = 742638445 },
        { Label = "玩具", Run = 782842708, Walk = 782843345, IdleA = 782841498, IdleB = 782845736 },
        { Label = "悬浮者", Run = 616010382, Walk = 616013216, IdleA = 616006778, IdleB = 616008087 },
        { Label = "老者", Run = 845386501, Walk = 845403856, IdleA = 845397899, IdleB = 845400520 },
        { Label = "时髦", Run = 616140816, Walk = 616146177, IdleA = 616136790, IdleB = 616138447 },
        { Label = "活泼", Run = 910025107, Walk = 910034870, IdleA = 910004836, IdleB = 910009958 },
    }

    -- 游戏原生 locomotion id (pv7560 运行时 dump; 恢复默认用, 不用运行时快照以免热替换污染)
    local NATIVE_IDS = {
        maleWalk = "rbxassetid://83600639547203",
        femaleWalk = "rbxassetid://117293898907979",
        maleRun = "rbxassetid://85823794654077",
        femaleRun = "rbxassetid://137015026151472",
        idle1 = "rbxassetid://99661732639863",
        idle2 = "rbxassetid://122843775061652",
    }

    --- 取平常 locomotion 六件套实例 (按性别双份都改, 免依赖 PlayerData.Gender)
    local function getNormalLocomotionAnims()
        local anims = ReplicatedStorage:FindFirstChild("Animations")
        local movement = anims and (anims:FindFirstChild("Movement") or anims)
        if not movement then
            return nil
        end
        return {
            maleWalk = movement:FindFirstChild("MaleWalk"),
            femaleWalk = movement:FindFirstChild("FemaleWalk"),
            maleRun = movement:FindFirstChild("MaleRun"),
            femaleRun = movement:FindFirstChild("FemaleRun"),
            idle1 = movement:FindFirstChild("Idle1"),
            idle2 = movement:FindFirstChild("Idle2"),
        }
    end

    --- 安全刷新 locomotion: 只清 track 引用、保留 animation 克隆体,
    --- MovementService 的 _ensureXxx 逻辑发现 track=nil 会自动重载;
    --- 绝不清克隆体/批量停 track/抖 WalkSpeed (会导致倒地卡死等状态机损坏)
    local function refreshLocomotion()
        local movMod = requireNilModule("MovementServiceClient")
        if not (movMod and type(movMod.Get) == "function") then return end
        pcall(function()
            local svc = movMod:Get()
            if not svc then return end
            -- 跑步: 克隆体还在 (_runAnimation 非 nil), 只清 track 让它重载同一实例。
            -- 注意 applyWalkPack 已改 source 原件 id, 但克隆体是旧快照 — 必须同步克隆体 id!
            if svc._runAnimation and typeof(svc._runAnimation) == "Instance" then
                local src = svc._runAnimationSource
                if src and typeof(src) == "Instance" then
                    pcall(function() svc._runAnimation.AnimationId = src.AnimationId end)
                end
            end
            if svc._runTrack then
                pcall(function() svc._runTrack:Stop(0) end)
                svc._runTrack = nil
            end
            if svc._idleTrack then
                pcall(function() svc._idleTrack:Stop(0) end)
                svc._idleTrack = nil
            end
            if svc._backpedalTrack then
                pcall(function() svc._backpedalTrack:Stop(0) end)
                svc._backpedalTrack = nil
            end
        end)
    end

    --- 应用一套姿势包
    local function applyWalkPack(pack)
        local anims = getNormalLocomotionAnims()
        if not anims then
            TheKing.Notify({ Content = "动画源不可用 (游戏结构变化)", Icon = "alert-triangle" })
            return false
        end
        local targets = {
            { inst = anims.maleWalk, id = pack.Walk },
            { inst = anims.femaleWalk, id = pack.Walk },
            { inst = anims.maleRun, id = pack.Run },
            { inst = anims.femaleRun, id = pack.Run },
            { inst = anims.idle1, id = pack.IdleA },
            { inst = anims.idle2, id = pack.IdleB },
        }
        for _, t in ipairs(targets) do
            if t.inst and t.inst:IsA("Animation") and t.id then
                t.inst.AnimationId = "rbxassetid://" .. tostring(t.id)
            end
        end
        refreshLocomotion()
        return true
    end

    ActionTab:Section({ Title = "走路姿势 · 全套走路/待机/跑步 (平常状态·全服可见)" })

    local packLabels = {}
    for i, p in ipairs(WALK_PACKS) do
        packLabels[i] = p.Label
    end
    table.insert(packLabels, "恢复游戏默认")

    ActionTab:Dropdown({
        Title = "选择走路姿势包",
        Values = packLabels,
        AllowNone = true,
        Callback = function(sel)
            if sel == nil or sel == "" then return end
            if sel == "恢复游戏默认" then
                -- 恢复: 直接写回 pv7560 实测原生 id (不受脚本重启/热替换污染)
                local anims = getNormalLocomotionAnims()
                if anims then
                    local pairsToRestore = {
                        { inst = anims.maleWalk, id = NATIVE_IDS.maleWalk },
                        { inst = anims.femaleWalk, id = NATIVE_IDS.femaleWalk },
                        { inst = anims.maleRun, id = NATIVE_IDS.maleRun },
                        { inst = anims.femaleRun, id = NATIVE_IDS.femaleRun },
                        { inst = anims.idle1, id = NATIVE_IDS.idle1 },
                        { inst = anims.idle2, id = NATIVE_IDS.idle2 },
                    }
                    for _, t in ipairs(pairsToRestore) do
                        if t.inst and t.inst:IsA("Animation") and t.id then
                            t.inst.AnimationId = t.id
                        end
                    end
                    refreshLocomotion()
                    TheKing.Notify({ Content = "已恢复默认走路姿势", Icon = "rotate-ccw" })
                end
                return
            end
            for _, p in ipairs(WALK_PACKS) do
                if p.Label == sel then
                    if applyWalkPack(p) then
                        TheKing.Notify({ Content = "已切换 [ " .. p.Label .. " ] 姿势包 — 全服可见", Icon = "footprints" })
                    end
                    break
                end
            end
        end,
    })

    ActionTab:Paragraph({
        Title = "走路姿势说明",
        Desc = "切换后走路/待机/跑步全套变更 (平常状态, 战斗姿态不变), 所有人可见。\n选「恢复游戏默认」还原。角色重生后依然生效。",
    })
end

-- ============================================================
-- 战斗桥接: M1 模块 hook (快攻 + 遗忘共用一条 hook 链)
-- 逆向依据: CombatSystemClient.Combat.Base.M1
--   tryM1 upvalues (按反编译声明序):
--     [1]=tryM1自身入口? 否 — OnM1Activated 的 [1] 才是 tryM1
--     tryM1: [4]=u123 出拳就绪flag(bool) [9]=u121 连击计数(0~4)
-- ============================================================
local CombatBridge = {}
CombatBridge.animHandler = nil -- 预声明字段 (严格类型检查要求)
do
    local M1Mod = nil
    -- 共享 upvalue 操作锚: ServerResponse 与 tryM1/OnHoldSwing 同属模块闭包链,
    -- 共享同一批模块级变量且未被 hook 污染, getupvalue/setupvalue 可靠。
    local srvResp = nil
    -- ServerResponse upvalue 布局 (pv7560 运行时 dump 实测):
    --   [1]=u128(number) [2]=u130(table) [3]=u129(table) [4]=u121(combo, number)
    --   [5]=u123(ready flag, boolean) [6]=u122(nil task) ... [8]=ComboResetTime=1.55 (锚点)
    local IDX_READY = 5
    local IDX_COMBO = 4
    local ANCHOR_RESET_TIME = 8
    local EXPECTED_RESET_TIME = 1.55
    local originalActivated = nil
    local originalHoldSwing = nil

    -- 快攻状态
    local fastEnabled = false
    local fastMinInterval = 0.18
    local lastFastAt = 0

    -- 遗忘状态 (必须在闭包函数定义前声明, 否则捕获不到)
    local disabledSegs = { false, false, false, false }

    local function bridgeOk()
        return M1Mod ~= nil and srvResp ~= nil and type(srvResp) == "function"
    end

    --- 遗忘预跳: 把连击计数预置到"下一个未禁用段-1", tryM1 内部会 %4+1 推进到目标段
    local function preSkipDisabled()
        if not bridgeOk() then return end
        local anyDisabled = disabledSegs[1] or disabledSegs[2] or disabledSegs[3] or disabledSegs[4]
        if not anyDisabled then return end
        local okCur, cur = pcall(debug.getupvalue, srvResp, IDX_COMBO)
        if not okCur or type(cur) ~= "number" then return end
        local nextSeg = math.floor(cur) % 4 + 1
        for _ = 1, 4 do -- 最多绕一圈; 全禁时不动, 由全禁保护兜底
            if not disabledSegs[nextSeg] then break end
            nextSeg = nextSeg % 4 + 1
        end
        if disabledSegs[nextSeg] then return end -- 四段全禁: 保持原版行为
        pcall(debug.setupvalue, srvResp, IDX_COMBO, nextSeg - 1)
    end

    --- 重定向段号: 从 seg 起找下一个未禁用段 (HoldSwing 路径用, 原函数会直接覆写计数器)
    local function redirectSeg(seg)
        local anyDisabled = disabledSegs[1] or disabledSegs[2] or disabledSegs[3] or disabledSegs[4]
        if not anyDisabled then return seg end
        for _ = 1, 4 do
            if not disabledSegs[seg] then return seg end
            seg = seg % 4 + 1
        end
        return seg -- 四段全禁兜底: 原样返回
    end

    --- 快攻前置: 清出拳就绪 flag + 停残留 M1 动画
    local function clearAttackGate()
        if not bridgeOk() then return end
        pcall(debug.setupvalue, srvResp, IDX_READY, true)
        local char = getChar()
        local animHandler = CombatBridge.animHandler
        if char and animHandler and type(animHandler.GetAnims) == "function" then
            pcall(function()
                for animId in pairs(animHandler:GetAnims(char, "M1")) do
                    animHandler.StopAnim(char, "M1", animId, 0.06)
                end
            end)
        end
    end

    function CombatBridge.Init()
        if M1Mod then return bridgeOk() end
        local ok, mod = pcall(require, ReplicatedStorage.CombatSystemClient.Combat.Base.M1)
        if not ok or type(mod) ~= "table" or type(mod.ServerResponse) ~= "function" then
            TheKing.Notify({ Content = "战斗模块不可用 (游戏结构变化)", Icon = "alert-triangle" })
            return false
        end
        M1Mod = mod
        srvResp = mod.ServerResponse
        -- 运行时验证索引假设 (pv7560 实测布局):
        --   [2]=table [3]=table [4]=combo number∈[0,4] [5]=boolean [8]=ComboResetTime=1.55
        local v2ok, v2 = pcall(debug.getupvalue, srvResp, 2)
        local v3ok, v3 = pcall(debug.getupvalue, srvResp, 3)
        local v4ok, v4 = pcall(debug.getupvalue, srvResp, IDX_COMBO)
        local v5ok, v5 = pcall(debug.getupvalue, srvResp, IDX_READY)
        local v8ok, v8 = pcall(debug.getupvalue, srvResp, ANCHOR_RESET_TIME)
        local layoutOk = v2ok and type(v2) == "table"
            and v3ok and type(v3) == "table"
            and v4ok and type(v4) == "number" and v4 >= 0 and v4 <= 4
            and v5ok and type(v5) == "boolean"
            and v8ok and type(v8) == "number" and math.abs(v8 - EXPECTED_RESET_TIME) < 0.001
        if not layoutOk then
            TheKing.Notify({ Content = "战斗 upvalue 布局校验失败 (" .. tostring(v8ok and v8 or "?") .. "), 快攻/遗忘停用", Icon = "alert-triangle" })
            srvResp = nil
            return false
        end
        -- 动画句柄 (停残留 M1 动画用): AnimationHandler 也是 nil-parent 模块
        local animHandler = requireNilModule("AnimationHandler")
        if animHandler and type(animHandler) == "table" then
            CombatBridge.animHandler = animHandler
        end
        return true
    end

    function CombatBridge.InstallHooks()
        -- 跨注入器降级: hookfunction 是 Real/Synapse 系专属 API, 其他注入器没有 -> 功能禁用
        if type(hookfunction) ~= "function" then
            fastEnabled = false
            TheKing.Notify({ Title = "功能不可用", Content = "当前注入器不支持 hookfunction, 连击加速已禁用", Icon = "alert-triangle", Duration = 4 })
            return false
        end
        if not bridgeOk() or originalActivated then return true end
        originalActivated = hookfunction(M1Mod.OnM1Activated, function(...)
            if fastEnabled then
                if os.clock() - lastFastAt < fastMinInterval then
                    return false -- 本地节流: 拒绝过快点击, 保护服务器节奏
                end
                lastFastAt = os.clock()
                clearAttackGate()
            end
            preSkipDisabled()
            return originalActivated(...)
        end)
        originalHoldSwing = hookfunction(M1Mod.OnHoldSwing, function(seg, speed, ...)
            local n = tonumber(seg)
            if n == nil then
                return originalHoldSwing(seg, speed, ...)
            end
            local redirected = redirectSeg(math.clamp(math.floor(n), 1, 4))
            return originalHoldSwing(redirected, speed, ...)
        end)
        TheKing.OnCleanup(function()
            -- 直接把 module 表字段赋回原函数, 解除 hook 入口
            if M1Mod and originalActivated then
                pcall(function() M1Mod.OnM1Activated = originalActivated end)
            end
            if M1Mod and originalHoldSwing then
                pcall(function() M1Mod.OnHoldSwing = originalHoldSwing end)
            end
        end)
        return true
    end

    function CombatBridge.SetFast(enabled, minInterval)
        fastEnabled = enabled and bridgeOk()
        if minInterval then fastMinInterval = minInterval end
    end

    function CombatBridge.UpdateFastInterval(minInterval)
        fastMinInterval = minInterval
    end

    function CombatBridge.SetDisabledSegs(t)
        disabledSegs = t
    end

    function CombatBridge.Ready()
        return bridgeOk()
    end
end

-- ============================================================
-- Tab: 战斗
-- ============================================================
local CombatTab = TheKing.NewTab({ Title = "战斗", Icon = "sword" })

if not CombatBridge.Init() then
    CombatTab:Paragraph({
        Title = "战斗系统不可用",
        Desc = "游戏脚本结构变化或角色未就绪, 快攻/遗忘已停用。\n重进游戏后重启脚本可恢复。",
    })
else
    CombatBridge.InstallHooks()

    -- ------------------------------------------------------------
    -- 战斗-快攻
    -- ------------------------------------------------------------
    do
        local minInterval = 0.35

        CombatTab:Toggle({
            Title = "快攻",
            Desc = "清除攻击冷却+残留动画。间隔低于服务器节奏会被拒绝回滚 (控制台刷 Declined 即过快, 往大调)",
            Flag = "fastAttackToggle",
            Value = false,
            Callback = function(state)
                CombatBridge.SetFast(state, minInterval)
                if state then
                    TheKing.Notify({ Content = "快攻已开启 — 出拳如风", Icon = "zap" })
                else
                    TheKing.Notify({ Content = "快攻已关闭", Icon = "circle-slash" })
                end
            end,
        })

        CombatTab:Slider({
            Title = "快攻 · 最小出拳间隔 (秒)",
            Value = { Min = 0.15, Max = 0.45, Default = 0.35 },
            Step = 0.01,
            Callback = function(v)
                minInterval = v
                CombatBridge.UpdateFastInterval(v) -- 只更新间隔, 不改变开关状态
            end,
        })
    end

    -- ------------------------------------------------------------
    -- 战斗-遗忘 (忘我拳法): 多选跳过第 N 段平A
    -- ------------------------------------------------------------
    do
        -- 状态先行声明 (applyForget 闭包要捕获它们, 声明必须在函数之前)
        local disabledSet = { false, false, false, false }
        local toggles = { false, false, false, false }
        local forgetToggleHandles = {}

        CombatTab:Section({ Title = "遗忘 · 忘我拳法 (勾选要跳过的平A)" })

        local function applyForget()
            local count = 0
            for i = 1, 4 do
                if disabledSet[i] then count = count + 1 end
            end
            if count >= 4 then
                -- 全禁保护: 至少保留一段, 自动放行 4A 并回弹 UI (状态以本表为准)
                disabledSet[4] = false
                toggles[4] = false
                CombatBridge.SetDisabledSegs(disabledSet)
                pcall(function() forgetToggleHandles[4]:Set(false) end)
                TheKing.Notify({ Content = "四段不能全部遗忘, 已自动保留 4A", Icon = "alert-triangle" })
                return
            end
            CombatBridge.SetDisabledSegs(disabledSet)
            local skipped = {}
            for i = 1, 4 do
                if disabledSet[i] then table.insert(skipped, tostring(i) .. "A") end
            end
            if #skipped > 0 then
                TheKing.Notify({ Content = "忘我拳法: 跳过 " .. table.concat(skipped, "/"), Icon = "brain" })
            else
                TheKing.Notify({ Content = "忘我拳法已清空 — 完整四连击恢复", Icon = "check-circle" })
            end
        end

        local segLabels = { "一段平A (1A)", "二段平A (2A)", "三段平A (3A)", "四段平A (4A·终结)" }
        for i = 1, 4 do
            forgetToggleHandles[i] = CombatTab:Toggle({
                Title = "跳过 " .. segLabels[i],
                Flag = "forgetSeg" .. i,
                Value = false,
                Callback = function(state)
                    disabledSet[i] = state
                    toggles[i] = state
                    applyForget()
                end,
            })
        end

        CombatTab:Paragraph({
            Title = "忘我拳法说明",
            Desc = "例: 只勾「跳过四段」→ 打完三段直接回到第一段, 循环往复。\n多选可自由组合连击路线, 如 1→3→1→3。",
        })
    end
end

-- ============================================================
-- Tab: 设置 (骨架标配, 不可删)
-- ============================================================
local SettingsTab = TheKing.NewTab({ Title = "设置", Icon = "settings" })

--- 卸载动作 (Keybind 和 Button 共用, 带确认防误触)
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

TheKing.Notify({ Content = "TheKing HUB 已加载 — Gakuran v0.3.0", Icon = "crown" })

return TheKing
