--[[
    TheKing HUB [0.4.2] - [🔥UPD] Sniper Arena
    RCWTK 引擎生成 | 模板 v1.0
    版本历史: games/sniper-arena/changelog.md

    功能清单:
      暴力-静默瞄准: 对局锁拿枪/刀的人 (Highlight 敌人 + World 持械实体), 不锁大厅角色
      暴力-可视化: 开则只锁子弹能打到的人; 与其它参数一并本地记住
      暴力-瞄准逻辑: 单选 准星附近优先 / 距离近优先 / 准星与距离
      暴力-最大距离: 超出不锁
      暴力-范围绘制: 静默瞄准开启后才画白圈/连线/十字
      暴力-队伍检测: 开则跟游戏友方判定跳过队友; 关则全锁
      暴力-自动扳机: 静默瞄准锁到人则开枪; 未开静默时准星指到人则开枪; 大厅内失效

    逆向结论 (同步自 games/sniper-arena/intel.md):
      - 对局真人: Highlight.Enemy.HighlightHolder 里带 Gun-/刀骨骼的模型; Player.Character 常在大厅无枪
      - 不能把「不是 player.Character」当尸体, 否则对局高亮全被滤掉
      - 子弹碰撞组 TeamXAtk: 打对面队伍+地图, 不打队友/Barrier; 可视化射线跟这套走
      - 队伍: Remote.EntityService.GetTeam(player) 字符串; Default 为混战占位
      - 自动扳机: Potassium mouse1click, 不直调 Shoot

    使用方式:
      开发: loadstring(readfile("games/sniper-arena/hub.luau"))()
      热调试: 改完代码直接重新执行本文件
      发布: python tools/build.py games/sniper-arena/hub.luau

    注入器要求: debug.setupvalue / debug.getupvalue
]]

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
    GameName = "[🔥UPD] Sniper Arena",
    ScriptVersion = "0.4.2",
})

-- ============================================================
-- 服务与引用
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local function getLocalCharacter()
    return LocalPlayer.Character
end

local function waitChild(parent, name, timeout)
    if not parent then
        return nil
    end
    local inst = parent:FindFirstChild(name)
    if inst then
        return inst
    end
    return parent:WaitForChild(name, timeout or 10)
end

local function requireChild(parent, name, timeout)
    local inst = waitChild(parent, name, timeout)
    if not inst then
        return nil
    end
    local ok, mod = pcall(require, inst)
    if ok then
        return mod
    end
    return nil
end

-- 别人注入器没有服务全局名; 模块缺失也不能 return, 否则只剩 Rayfield 自带 General
local RS_CLIENT = waitChild(ReplicatedStorage, "Client", 10)
local CameraController = requireChild(RS_CLIENT, "CameraController", 10)
local combatController = waitChild(RS_CLIENT, "CombatController", 10)
local clientComponent = waitChild(combatController, "ClientComponent", 10)
local ClientShootableComponent = requireChild(clientComponent, "ClientShootableComponent", 10)
local combatReady = type(CameraController) == "table"
    and type(CameraController.GetCombatOriginFn) == "function"
    and type(ClientShootableComponent) == "table"
if type(CameraController) ~= "table" then
    CameraController = {
        GetCombatOriginFn = function() end,
        GetCombatOrigin = function() end,
    }
end
if type(ClientShootableComponent) ~= "table" then
    ClientShootableComponent = {}
end
if not combatReady then
    TheKing.Notify({ Content = "战斗模块未就绪, 功能页已打开; 进对局后重载脚本", Icon = "alert-triangle" })
end

local EntityService = nil
pcall(function()
    local remote = waitChild(ReplicatedStorage, "Remote", 10)
    EntityService = requireChild(remote, "EntityService", 10)
end)

-- 大厅 Place 里仍有靶场/假人; 静默瞄准不按 PlaceId 一刀切。自动扳机仍避开社交大厅, 免得在排队区乱点。
local function isInSocialLobby()
    local lobby = workspace:FindFirstChild("Lobby")
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if lobby and root and lobby:IsA("Model") then
        local ok, cf, size = pcall(function()
            return lobby:GetBoundingBox()
        end)
        if ok and cf and size then
            local localPos = cf:PointToObjectSpace(root.Position)
            local half = size * 0.5
            if math.abs(localPos.X) <= half.X + 4
                and math.abs(localPos.Y) <= half.Y + 4
                and math.abs(localPos.Z) <= half.Z + 4 then
                return true
            end
        end
    end
    return false
end

local function combatZoneActive()
    -- 自动扳机用: 站在 Lobby 模型里不算对局
    return not isInSocialLobby()
end

-- ============================================================
-- 静默瞄准核心
-- ============================================================
local silentAim = {
    enabled = false,
    drawFov = true,
    maxDistance = 5000,
    fovRadius = 60,
    raycastGuard = false,
    lastTargetName = nil,
    lastTargetPart = nil,
    uiQuietUntil = 0,
    aimMode = "both",
    visibility = false,
}

local AIM_MODE_LABELS = { "准星附近优先", "距离近优先", "准星与距离" }
local AIM_MODE_FROM_LABEL = {
    ["准星附近优先"] = "crosshair",
    ["距离近优先"] = "distance",
    ["准星与距离"] = "both",
}
local AIM_MODE_TO_LABEL = {
    crosshair = "准星附近优先",
    distance = "距离近优先",
    both = "准星与距离",
}

local function applyAimModeSelection(sel)
    local s = sel
    if type(sel) == "table" then
        s = sel[1] or sel.value or sel.Value
    end
    local mode = AIM_MODE_FROM_LABEL[tostring(s or "")]
    if mode then
        silentAim.aimMode = mode
    end
end

local CFG_FILE = "TheKing_sniper_cfg.txt"
local FOV_SAVE_FILE = "TheKing_sniper_fov.txt"
local DIST_SAVE_FILE = "TheKing_sniper_dist.txt"
pcall(function()
    if type(isfile) == "function" and isfile(FOV_SAVE_FILE) and type(readfile) == "function" then
        local n = tonumber(readfile(FOV_SAVE_FILE))
        if type(n) == "number" then
            silentAim.fovRadius = math.clamp(n, 10, 400)
        end
    end
end)
pcall(function()
    if type(isfile) == "function" and isfile(DIST_SAVE_FILE) and type(readfile) == "function" then
        local n = tonumber(readfile(DIST_SAVE_FILE))
        if type(n) == "number" then
            silentAim.maxDistance = math.clamp(n, 50, 8000)
        end
    end
end)

local findBestTarget
local isCharacterAlive

-- FOV: 静默+范围绘制都开才建 Drawing; 渲染循环绝不 new; 关静默不画圈
local FOV_DRAW_KEY = "RCWTK_SA_FOV_DRAW"
local FOV_OFF = Vector2.new(-10000, -10000)
local fovDraw = nil
local fovSnap = nil
local fovAxisX = nil
local fovAxisY = nil
local fovAxisZ = nil
local fovDrawAlive = true
local fovLastShow = nil
local fovLastRadius = nil
local fovLastX = nil
local fovLastY = nil
local fovRadiusQuietAt = 0

local function fovShouldShow()
    return fovDrawAlive and silentAim.enabled == true and silentAim.drawFov == true
end

local function getFovCenter()
    local cam = workspace.CurrentCamera
    if not cam then
        return Vector2.new(0, 0)
    end
    local vp = cam.ViewportSize
    -- Drawing 与 WorldToViewportPoint 同一套视口坐标, 不再加 GuiInset (加了圆心会偏下)
    return Vector2.new(vp.X * 0.5, vp.Y * 0.5)
end

local function removeDrawingObj(obj)
    if obj == nil then
        return
    end
    pcall(function()
        obj:Remove()
    end)
end

local function removeFovPack(pack)
    if type(pack) == "table" then
        for _, obj in pairs(pack) do
            removeDrawingObj(obj)
        end
        return
    end
    removeDrawingObj(pack)
end

pcall(function()
    local old = rawget(_G, FOV_DRAW_KEY)
    rawset(_G, FOV_DRAW_KEY, nil)
    task.delay(0.45, function()
        pcall(removeFovPack, old)
    end)
end)
pcall(function()
    local function dropLegacy(parent)
        if not parent then
            return
        end
        local g = parent:FindFirstChild("RCWTK_SA_FOV")
        if g then
            task.delay(0.45, function()
                pcall(function()
                    g:Destroy()
                end)
            end)
        end
    end
    if type(gethui) == "function" then
        dropLegacy(gethui())
    end
    dropLegacy(LocalPlayer:FindFirstChildOfClass("PlayerGui"))
end)

local function getDrawingLib()
    local lib = Drawing
    if type(lib) ~= "table" and type(getgenv) == "function" then
        local okEnv, env = pcall(getgenv)
        if okEnv and type(env) == "table" then
            lib = env.Drawing
        end
    end
    if type(lib) == "table" and type(lib.new) == "function" then
        return lib
    end
    return nil
end

local function makeDrawLine(lib)
    local ok, line = pcall(function()
        return lib.new("Line")
    end)
    if not (ok and line) then
        return nil
    end
    pcall(function()
        line.Thickness = 1.5
        line.Color = Color3.fromRGB(255, 255, 255)
        line.Transparency = 1
        line.Visible = true
        line.ZIndex = 3
        line.From = FOV_OFF
        line.To = FOV_OFF
    end)
    return line
end

local function hideDrawLine(line)
    if line then
        line.From = FOV_OFF
        line.To = FOV_OFF
    end
end

local function worldToDraw(cam, worldPos)
    local sp, onScreen = cam:WorldToViewportPoint(worldPos)
    if onScreen and sp.Z > 0 then
        return Vector2.new(sp.X, sp.Y), true
    end
    return nil, false
end

local function setAxisLine(line, cam, a, b)
    if not line then
        return
    end
    local pa, oa = worldToDraw(cam, a)
    local pb, ob = worldToDraw(cam, b)
    if oa and ob then
        line.From = pa
        line.To = pb
    else
        hideDrawLine(line)
    end
end

local function ensureFovDraw()
    if fovDraw then
        return fovDraw
    end
    local lib = getDrawingLib()
    if not lib then
        return nil
    end
    local ok, circle = pcall(function()
        return lib.new("Circle")
    end)
    if not (ok and circle) then
        return nil
    end
    pcall(function()
        circle.Filled = false
        circle.Thickness = 1.5
        circle.Color = Color3.fromRGB(255, 255, 255)
        circle.NumSides = 32
        circle.Transparency = 1
        circle.Visible = true
        circle.Radius = math.max(silentAim.fovRadius, 1)
        circle.Position = FOV_OFF
        circle.ZIndex = 2
    end)
    fovDraw = circle
    fovSnap = makeDrawLine(lib)
    fovAxisX = makeDrawLine(lib)
    fovAxisY = makeDrawLine(lib)
    fovAxisZ = makeDrawLine(lib)
    rawset(_G, FOV_DRAW_KEY, {
        circle = circle,
        snap = fovSnap,
        ax = fovAxisX,
        ay = fovAxisY,
        az = fovAxisZ,
    })
    return circle
end

local function tickFovDraw()
    if not fovDraw then
        return
    end
    if not fovShouldShow() then
        if fovLastShow ~= false then
            pcall(function()
                fovDraw.Position = FOV_OFF
            end)
            hideDrawLine(fovSnap)
            hideDrawLine(fovAxisX)
            hideDrawLine(fovAxisY)
            hideDrawLine(fovAxisZ)
            fovLastX = nil
            fovLastY = nil
            fovLastShow = false
        end
        return
    end
    local cam = workspace.CurrentCamera
    local c = getFovCenter()
    local r = math.max(silentAim.fovRadius, 1)
    if fovLastX ~= c.X or fovLastY ~= c.Y then
        fovDraw.Position = c
        fovLastX = c.X
        fovLastY = c.Y
    end
    if fovLastRadius == nil then
        fovLastRadius = r
    elseif r ~= fovLastRadius and (os.clock() - fovRadiusQuietAt) >= 0.22 then
        pcall(function()
            fovDraw.Radius = r
        end)
        fovLastRadius = r
    end
    fovLastShow = true

    local part = silentAim.lastTargetPart
    local model = part and part:FindFirstAncestorOfClass("Model")
    if part and part.Parent and cam and isCharacterAlive and isCharacterAlive(model) then
        local toPos, onPart = worldToDraw(cam, part.Position)
        if onPart and fovSnap then
            fovSnap.From = c
            fovSnap.To = toPos
        else
            hideDrawLine(fovSnap)
        end
        local t = os.clock() * 2.4
        local spin = CFrame.Angles(t, t * 0.71, t * 0.43)
        local cf = CFrame.new(part.Position) * spin
        local half = math.max(part.Size.Magnitude * 0.28, 0.85)
        setAxisLine(fovAxisX, cam, cf.Position - cf.RightVector * half, cf.Position + cf.RightVector * half)
        setAxisLine(fovAxisY, cam, cf.Position - cf.UpVector * half, cf.Position + cf.UpVector * half)
        setAxisLine(fovAxisZ, cam, cf.Position - cf.LookVector * half, cf.Position + cf.LookVector * half)
    else
        if part and isCharacterAlive and model and not isCharacterAlive(model) then
            silentAim.lastTargetPart = nil
            silentAim.lastTargetName = nil
        end
        hideDrawLine(fovSnap)
        hideDrawLine(fovAxisX)
        hideDrawLine(fovAxisY)
        hideDrawLine(fovAxisZ)
    end
end

TheKing.AddConnection(RunService.RenderStepped:Connect(function()
    pcall(tickFovDraw)
end))


local teamCheck = {
    enabled = false,
    teamPlay = false,
    nextRefresh = 0,
}

local autoTrigger = {
    enabled = false,
    lastShot = 0,
    armUntil = 0,
}

local cfgSaveToken = 0

local function collectCfg()
    return {
        silentAim = silentAim.enabled == true,
        visibility = silentAim.visibility == true,
        aimMode = silentAim.aimMode,
        maxDistance = silentAim.maxDistance,
        drawFov = silentAim.drawFov == true,
        fovRadius = silentAim.fovRadius,
        teamCheck = teamCheck.enabled == true,
        autoTrigger = autoTrigger.enabled == true,
    }
end

local function applyCfgTable(data)
    if type(data) ~= "table" then
        return
    end
    if type(data.silentAim) == "boolean" then
        silentAim.enabled = data.silentAim
    end
    if type(data.visibility) == "boolean" then
        silentAim.visibility = data.visibility
    end
    if type(data.aimMode) == "string" and AIM_MODE_TO_LABEL[data.aimMode] then
        silentAim.aimMode = data.aimMode
    end
    if type(data.maxDistance) == "number" then
        silentAim.maxDistance = math.clamp(data.maxDistance, 50, 8000)
    end
    if type(data.drawFov) == "boolean" then
        silentAim.drawFov = data.drawFov
    end
    if type(data.fovRadius) == "number" then
        silentAim.fovRadius = math.clamp(data.fovRadius, 10, 400)
    end
    if type(data.teamCheck) == "boolean" then
        teamCheck.enabled = data.teamCheck
    end
    if type(data.autoTrigger) == "boolean" then
        autoTrigger.enabled = data.autoTrigger
    end
end

local function scheduleSaveCfg()
    cfgSaveToken += 1
    local token = cfgSaveToken
    task.delay(0.4, function()
        if token ~= cfgSaveToken then
            return
        end
        pcall(function()
            if type(writefile) ~= "function" then
                return
            end
            writefile(CFG_FILE, HttpService:JSONEncode(collectCfg()))
        end)
    end)
end

pcall(function()
    if type(isfile) == "function" and isfile(CFG_FILE) and type(readfile) == "function" then
        local raw = readfile(CFG_FILE)
        if type(raw) == "string" and raw ~= "" then
            applyCfgTable(HttpService:JSONDecode(raw))
        end
    end
end)

local NON_TEAM = {
    Default = true,
    None = true,
    FFA = true,
    Neutral = true,
}

local ENEMY_ROOT_NAMES = {
    "Entities",
    "Live",
    "Characters",
    "NPCs",
    "NPC",
    "Bots",
    "Enemies",
    "AI",
    "Dummies",
}

local ENEMY_CACHE_TTL = 0.25
local enemyCache = {
    list = {},
    nextRefresh = 0,
}

local function entityRootModel(character)
    if not character then
        return nil
    end
    local ents = character:FindFirstAncestor("Entities")
    if not ents then
        return character
    end
    local node = character
    while node.Parent and node.Parent ~= ents do
        node = node.Parent
    end
    return node
end

local function hasCombatGear(character)
    if not character then
        return false
    end
    local ok, descendants = pcall(function()
        return character:GetDescendants()
    end)
    if not ok or type(descendants) ~= "table" then
        return false
    end
    for _, inst in ipairs(descendants) do
        local n = inst.Name
        local prefix = string.sub(n, 1, 4)
        if n == "Gun-Main" or prefix == "Gun-" or prefix == "Gun_" then
            return true
        end
        if string.find(n, "Knife", 1, true)
            or string.find(n, "Blade", 1, true)
            or string.find(n, "Melee", 1, true)
            or string.find(n, "Sword", 1, true)
            or string.find(n, "Katana", 1, true)
            or string.find(n, "Dagger", 1, true)
            or string.find(n, "Bayonet", 1, true)
            or string.find(n, "Axe", 1, true)
        then
            return true
        end
    end
    return false
end

local function isUnderWorldEntities(character)
    return character ~= nil
        and character:FindFirstAncestor("Entities") ~= nil
        and character:FindFirstAncestor("World") ~= nil
end

local function highlightFolderName(character)
    if not character then
        return nil
    end
    local holder = character:FindFirstAncestor("HighlightHolder")
    if not holder then
        return nil
    end
    local folder = holder.Parent
    return folder and folder.Name or nil
end

local function isMatchCombatant(character)
    if not character or not character:IsA("Model") then
        return false
    end
    if not hasCombatGear(character) then
        return false
    end
    local side = highlightFolderName(character)
    if side == "Enemy" or side == "Friendly" then
        return true
    end
    return isUnderWorldEntities(character)
end

local function entityCallPreferred(method, character)
    if not EntityService or type(EntityService[method]) ~= "function" or not character then
        return nil
    end
    local owner = nil
    if typeof(character) == "Instance" and character:IsA("Player") then
        owner = character
    else
        owner = Players:GetPlayerFromCharacter(character)
    end
    local order = {}
    if owner then
        table.insert(order, owner)
    else
        table.insert(order, entityRootModel(character))
    end
    for _, sub in ipairs(order) do
        if sub ~= nil then
            local ok, res = pcall(EntityService[method], sub)
            if ok and res ~= nil then
                return res
            end
        end
    end
    return nil
end

local function getGameTeam(subject)
    if not subject then
        return nil
    end
    local team = entityCallPreferred("GetTeam", subject)
    if type(team) == "string" and team ~= "" then
        return team
    end
    if typeof(subject) == "Instance" and subject:IsA("Player") then
        local robloxTeam = subject.Team
        if robloxTeam then
            return robloxTeam.Name
        end
    end
    return nil
end

local function refreshTeamPlay()
    local now = os.clock()
    if now < teamCheck.nextRefresh then
        return teamCheck.teamPlay
    end
    teamCheck.nextRefresh = now + 0.5
    local counts = {}
    local distinct = 0
    for _, player in ipairs(Players:GetPlayers()) do
        local t = getGameTeam(player)
        if t and not NON_TEAM[t] then
            if not counts[t] then
                counts[t] = 0
                distinct += 1
            end
            counts[t] += 1
        end
    end
    -- 个人竞技会给全员同一个占位队名(实测 Team3), 不能用「同队>=2人」
    -- 至少两支不同真实队伍才当组队赛
    teamCheck.teamPlay = distinct >= 2
    return teamCheck.teamPlay
end

local function isTeammateCharacter(character)
    if not teamCheck.enabled or not character then
        return false
    end
    if character == getLocalCharacter() then
        return true
    end
    local owner = Players:GetPlayerFromCharacter(character)
    if owner == LocalPlayer then
        return true
    end
    -- 对局友方高亮夹里的人是队友; 不要问 IsFriendly(角色) — 会对全员报 true
    if highlightFolderName(character) == "Friendly" then
        return true
    end
    -- 个人占位局 IsFriendly/GetTeam 会对全员报友方, 必须先确认真的是多队伍
    if not refreshTeamPlay() then
        return false
    end
    local friendly = entityCallPreferred("IsFriendly", character)
    if type(friendly) == "boolean" then
        return friendly
    end
    local mine = getGameTeam(LocalPlayer)
    local theirs = getGameTeam(character)
    if not mine or not theirs then
        return false
    end
    if NON_TEAM[mine] or NON_TEAM[theirs] then
        return false
    end
    return mine == theirs
end

local hookState = {
    installed = false,
    origCombatOrigin = nil,
    patches = nil,
}

local REG_KEY = "RCWTK_SNIPER_SA"

-- R6/R15 常见命中部位; 先按人进圈, 再在该人身上按评分选点
local AIM_PART_NAMES = {
    "Head",
    "UpperTorso",
    "Torso",
    "LowerTorso",
    "HumanoidRootPart",
    "LeftUpperArm",
    "RightUpperArm",
    "LeftLowerArm",
    "RightLowerArm",
    "LeftHand",
    "RightHand",
    "LeftUpperLeg",
    "RightUpperLeg",
    "LeftLowerLeg",
    "RightLowerLeg",
    "LeftFoot",
    "RightFoot",
    "Left Arm",
    "Right Arm",
    "Left Leg",
    "Right Leg",
}

-- 越大越容易命中, 只在同一敌人身上比较
local PART_HIT_EASE = {
    Head = 4,
    UpperTorso = 16,
    Torso = 16,
    LowerTorso = 14,
    HumanoidRootPart = 12,
    LeftUpperArm = 8,
    RightUpperArm = 8,
    LeftLowerArm = 5,
    RightLowerArm = 5,
    LeftHand = 2,
    RightHand = 2,
    LeftUpperLeg = 10,
    RightUpperLeg = 10,
    LeftLowerLeg = 6,
    RightLowerLeg = 6,
    LeftFoot = 3,
    RightFoot = 3,
    ["Left Arm"] = 8,
    ["Right Arm"] = 8,
    ["Left Leg"] = 10,
    ["Right Leg"] = 10,
}

local PART_EXTENTS = {
    Vector3.new(1, 0, 0),
    Vector3.new(-1, 0, 0),
    Vector3.new(0, 1, 0),
    Vector3.new(0, -1, 0),
    Vector3.new(0, 0, 1),
    Vector3.new(0, 0, -1),
}

local function findPartByName(character, name)
    local direct = character:FindFirstChild(name)
    if direct and direct:IsA("BasePart") then
        return direct
    end
    local nested = character:FindFirstChild(name, true)
    if nested and nested:IsA("BasePart") then
        return nested
    end
    return nil
end

local function getAimPart(character)
    if not character then
        return nil
    end
    for _, name in ipairs(AIM_PART_NAMES) do
        local part = findPartByName(character, name)
        if part then
            return part
        end
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.RootPart and humanoid.RootPart:IsA("BasePart") then
        return humanoid.RootPart
    end
    if character.PrimaryPart then
        return character.PrimaryPart
    end
    return character:FindFirstChildWhichIsA("BasePart") or character:FindFirstChild("HumanoidRootPart", true)
end

local function collectAimParts(character)
    local parts = {}
    local seen = {}
    for _, name in ipairs(AIM_PART_NAMES) do
        local part = findPartByName(character, name)
        if part and not seen[part] then
            seen[part] = true
            table.insert(parts, part)
        end
    end
    if #parts == 0 then
        local fallback = getAimPart(character)
        if fallback then
            table.insert(parts, fallback)
        end
    end
    return parts
end

local function collectBodyParts(character)
    local parts = {}
    for _, inst in ipairs(character:GetDescendants()) do
        if inst:IsA("BasePart") then
            table.insert(parts, inst)
        end
    end
    if character:IsA("BasePart") then
        table.insert(parts, character)
    end
    return parts
end

local function isAiCharacter(character)
    if not character then
        return false
    end
    return Players:GetPlayerFromCharacter(character) == nil
end

isCharacterAlive = function(character)
    if not character or not character.Parent then
        return false
    end
    if character:IsA("Highlight") then
        return false
    end
    -- Highlight 预览层里没拿枪/刀的不要锁; 拿枪的才是对局外观, 不能整棵跳过
    if character:FindFirstAncestor("Highlight") and not hasCombatGear(character) then
        return false
    end
    if character:FindFirstAncestor("_Temp") then
        return false
    end
    local parentName = character.Parent.Name
    if string.find(character.Name, "Died", 1, true) or string.find(parentName, "Died", 1, true) then
        return false
    end
    local owner = Players:GetPlayerFromCharacter(character)
    local inMatchVisual = isMatchCombatant(character) or isUnderWorldEntities(character)
    -- Player.Character 常停在大厅 Workspace; 对局模型不是 Character, 不能当尸体丢掉
    if owner and owner.Character ~= nil and owner.Character ~= character and not inMatchVisual then
        return false
    end
    if owner and not inMatchVisual then
        local named = Players:FindFirstChild(character.Name)
        if named and named:IsA("Player") and named.Character ~= nil and named.Character ~= character then
            return false
        end
    end
    if EntityService then
        local alive = entityCallPreferred("IsAlive", character)
        if alive == false then
            return false
        end
        local hp = entityCallPreferred("GetHealth", character)
        if type(hp) == "number" and hp <= 0 then
            return false
        end
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local okState, state = pcall(function()
            return humanoid:GetState()
        end)
        if okState and state == Enum.HumanoidStateType.Dead then
            return false
        end
    else
        if not character:FindFirstChildWhichIsA("BasePart", true) then
            return false
        end
    end
    return true
end

local function isValidEnemyCharacter(character)
    if not character or not character:IsA("Model") then
        return false
    end
    if character == getLocalCharacter() then
        return false
    end
    local owner = Players:GetPlayerFromCharacter(character)
    if owner == LocalPlayer then
        return false
    end
    local side = highlightFolderName(character)
    if character:FindFirstAncestor("Highlight") and side ~= "Enemy" and side ~= "Friendly" then
        return false
    end
    if not isCharacterAlive(character) then
        return false
    end
    if isTeammateCharacter(character) then
        return false
    end
    return getAimPart(character) ~= nil
end

local function tryAddEnemyCharacter(seen, list, character)
    if not character then
        return
    end
    local root = entityRootModel(character) or character
    if not root then
        return
    end
    local nameKey = "n:" .. string.lower(root.Name)
    if seen[root] or seen[nameKey] then
        return
    end
    if isValidEnemyCharacter(character) then
        seen[root] = true
        seen[nameKey] = true
        table.insert(list, root)
    end
end

local function scanHighlightHolder(seen, list, sideName)
    local hl = workspace:FindFirstChild("Highlight")
    local side = hl and hl:FindFirstChild(sideName)
    local holder = side and side:FindFirstChild("HighlightHolder")
    if not holder then
        return
    end
    local ok, children = pcall(function()
        return holder:GetChildren()
    end)
    if not ok or type(children) ~= "table" then
        return
    end
    for _, inst in ipairs(children) do
        if inst:IsA("Model") and hasCombatGear(inst) then
            tryAddEnemyCharacter(seen, list, inst)
        end
    end
end

local function collectFromEntityService(seen, list)
    if not EntityService then
        return
    end
    if type(EntityService.FetchEntity) == "function" then
        local ok, entities = pcall(EntityService.FetchEntity)
        if ok and type(entities) == "table" then
            for _, item in pairs(entities) do
                local model = item
                if type(item) == "table" then
                    model = item.Model or item.Character or item.Entity or item.Instance
                end
                if typeof(model) == "Instance" and model:IsA("Model") then
                    tryAddEnemyCharacter(seen, list, model)
                end
            end
        end
    end
end

local function modelLooksAimable(inst)
    if not inst or not inst:IsA("Model") then
        return false
    end
    if inst:FindFirstChildOfClass("Humanoid") then
        return true
    end
    if inst:FindFirstChild("HumanoidRootPart", true) or inst:FindFirstChild("Head", true) then
        return true
    end
    return inst:FindFirstChildWhichIsA("BasePart", true) ~= nil
end

local function scanEnemyContainer(seen, list, container, depth)
    if not container or depth > 5 then
        return
    end
    local ok, children = pcall(function()
        return container:GetChildren()
    end)
    if not ok or type(children) ~= "table" then
        return
    end
    for _, inst in ipairs(children) do
        if inst:IsA("Model") then
            if modelLooksAimable(inst) then
                tryAddEnemyCharacter(seen, list, inst)
            end
            scanEnemyContainer(seen, list, inst, depth + 1)
        elseif inst:IsA("Folder") or inst:IsA("Configuration") then
            scanEnemyContainer(seen, list, inst, depth + 1)
        end
    end
end

local function collectWorldCombatants(seen, list, requireGear)
    local world = workspace:FindFirstChild("World")
    if not world then
        return
    end
    for _, node in ipairs(world:GetChildren()) do
        local ents = node:FindFirstChild("Entities")
        if ents then
            local ok, children = pcall(function()
                return ents:GetChildren()
            end)
            if ok and type(children) == "table" then
                for _, inst in ipairs(children) do
                    if inst:IsA("Model") then
                        if not requireGear or hasCombatGear(inst) then
                            tryAddEnemyCharacter(seen, list, inst)
                        end
                    end
                end
            end
        end
    end
end

local function collectEnemyCharacters()
    local characters = {}
    local seen = {}

    -- 对局外观在 Highlight.Enemy, 且必须拿枪/刀; World.Entities 无枪的是未进战/大厅投影
    collectWorldCombatants(seen, characters, true)
    scanHighlightHolder(seen, characters, "Enemy")
    if not teamCheck.enabled then
        scanHighlightHolder(seen, characters, "Friendly")
    end

    if #characters > 0 then
        return characters
    end

    -- 没有持械对局实体时才扫大厅/靶场假人
    for _, player in ipairs(Players:GetPlayers()) do
        tryAddEnemyCharacter(seen, characters, player.Character)
    end

    collectFromEntityService(seen, characters)
    collectWorldCombatants(seen, characters, false)

    for _, rootName in ipairs(ENEMY_ROOT_NAMES) do
        scanEnemyContainer(seen, characters, workspace:FindFirstChild(rootName), 1)
    end

    for _, inst in ipairs(workspace:GetChildren()) do
        if inst:IsA("Model") and inst:FindFirstChildOfClass("Humanoid") then
            local lobbyIdle = inst.Parent == workspace
                and Players:FindFirstChild(inst.Name) ~= nil
                and not hasCombatGear(inst)
            if not lobbyIdle then
                tryAddEnemyCharacter(seen, characters, inst)
            end
        end
    end

    return characters
end

local function getEnemyCharacters()
    local now = os.clock()
    if now >= enemyCache.nextRefresh then
        enemyCache.nextRefresh = now + ENEMY_CACHE_TTL
        enemyCache.list = collectEnemyCharacters()
    end
    return enemyCache.list
end

local function invalidateEnemyCache()
    enemyCache.nextRefresh = 0
end

local function getShotCollisionGroup()
    local team = getGameTeam(LocalPlayer)
    if team == "Team1" or team == "Team11" then
        return "Team1Atk"
    end
    if team == "Team2" or team == "Team22" then
        return "Team2Atk"
    end
    if team == "Team3" or team == "Team33" then
        return "Team3Atk"
    end
    local char = getLocalCharacter()
    local probe = char and (char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart"))
    local cg = probe and probe.CollisionGroup
    if cg == "Team1" or cg == "Team11" then
        return "Team1Atk"
    end
    if cg == "Team2" or cg == "Team22" then
        return "Team2Atk"
    end
    if cg == "Team3" or cg == "Team33" then
        return "Team3Atk"
    end
    return "Team3Atk"
end

local function buildVisParams(excludeList)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = excludeList
    local group = getShotCollisionGroup()
    pcall(function()
        params.CollisionGroup = group
    end)
    return params
end

local function getRayExcludeList()
    local exclude = {}
    local localChar = getLocalCharacter()
    if localChar then
        table.insert(exclude, localChar)
    end
    local hl = workspace:FindFirstChild("Highlight")
    if hl then
        for _, sideName in ipairs({ "Friendly", "Enemy" }) do
            local side = hl:FindFirstChild(sideName)
            local holder = side and side:FindFirstChild("HighlightHolder")
            local mine = holder and holder:FindFirstChild(LocalPlayer.Name)
            if mine then
                table.insert(exclude, mine)
            end
        end
    end
    return exclude
end

local function hitBelongsToTarget(hit, character)
    if not hit or not character or not hit.Instance then
        return false
    end
    if hit.Instance:IsDescendantOf(character) then
        return true
    end
    local hitModel = hit.Instance:FindFirstAncestorOfClass("Model")
    if not hitModel then
        return false
    end
    local root = entityRootModel(character)
    local hitRoot = entityRootModel(hitModel)
    if root and hitRoot and string.lower(root.Name) == string.lower(hitRoot.Name) then
        return true
    end
    local owner = Players:GetPlayerFromCharacter(character)
    if not owner then
        local named = Players:FindFirstChild(character.Name)
        if named and named:IsA("Player") then
            owner = named
        end
    end
    local hitOwner = Players:GetPlayerFromCharacter(hitModel)
    return owner ~= nil and owner == hitOwner
end

-- 跟游戏子弹同一套碰撞: 先碰到目标(含同名 World 碰撞体)才算打得到
local function isPartExposed(origin, part, excludeList)
    if not part or not part.CanQuery then
        return false
    end
    local targetPos = part.Position
    local delta = targetPos - origin
    local dist = delta.Magnitude
    if dist < 0.05 then
        return true
    end
    local character = entityRootModel(part:FindFirstAncestorOfClass("Model")) or part:FindFirstAncestorOfClass("Model")
    silentAim.raycastGuard = true
    local hit = workspace:Raycast(origin, delta.Unit * (dist + 1.5), buildVisParams(excludeList))
    silentAim.raycastGuard = false
    return hitBelongsToTarget(hit, character)
end

-- 部位中心 + 包围盒六向端点, 轮廓擦到圈也算进圈
local function minPartScreenDist(cam, part, center)
    local cf = part.CFrame
    local half = part.Size * 0.5
    local best = math.huge
    local visible = false
    local function consider(worldPos)
        local sp = cam:WorldToViewportPoint(worldPos)
        if sp.Z > 0 then
            visible = true
            local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
            if d < best then
                best = d
            end
        end
    end
    consider(cf.Position)
    for i = 1, #PART_EXTENTS do
        local axis = PART_EXTENTS[i]
        consider(cf.Position + cf:VectorToWorldSpace(Vector3.new(axis.X * half.X, axis.Y * half.Y, axis.Z * half.Z)))
    end
    if not visible then
        return nil
    end
    return best
end

local function pickPartOnCharacter(origin, character, cam, center, excludeList)
    local parts = collectAimParts(character)
    local bestPart = nil
    local bestScore = math.huge
    local fallbackPart = nil
    local fallbackDist = math.huge
    local vis = silentAim.visibility == true
    for _, part in ipairs(parts) do
        local screenPos = cam:WorldToViewportPoint(part.Position)
        if screenPos.Z > 0 then
            local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
            local worldDist = (part.Position - origin).Magnitude
            local score = screenDist - (PART_HIT_EASE[part.Name] or 0)
            if silentAim.aimMode == "distance" then
                score = worldDist
            elseif silentAim.aimMode == "both" then
                score += worldDist * 0.08
            end
            if vis then
                if isPartExposed(origin, part, excludeList) then
                    if score < bestScore then
                        bestScore = score
                        bestPart = part
                    end
                end
            else
                if score < bestScore then
                    bestScore = score
                    bestPart = part
                end
                if screenDist < fallbackDist then
                    fallbackPart = part
                    fallbackDist = screenDist
                end
            end
        end
    end
    if vis then
        return bestPart
    end
    return bestPart or fallbackPart or getAimPart(character)
end

findBestTarget = function(origin, maxDistance)
    maxDistance = maxDistance or silentAim.maxDistance
    local cam = workspace.CurrentCamera
    if not cam then
        return nil
    end
    local center = getFovCenter()
    local fovRadius = silentAim.fovRadius
    local excludeList = getRayExcludeList()
    local vis = silentAim.visibility == true

    local bestPart = nil
    local bestScore = math.huge

    for _, character in ipairs(getEnemyCharacters()) do
        if isValidEnemyCharacter(character) then
        local bodyParts = vis and collectAimParts(character) or collectBodyParts(character)
        local charScreen = math.huge
        local charWorld = math.huge
        local inRange = false
        for _, part in ipairs(bodyParts) do
            local worldDist = (part.Position - origin).Magnitude
            if worldDist <= maxDistance then
                local screenDist = minPartScreenDist(cam, part, center)
                if screenDist and screenDist <= fovRadius then
                    if (not vis) or isPartExposed(origin, part, excludeList) then
                        inRange = true
                        if screenDist < charScreen then
                            charScreen = screenDist
                        end
                        if worldDist < charWorld then
                            charWorld = worldDist
                        end
                    end
                end
            end
        end
        if inRange then
            local score
            if silentAim.aimMode == "distance" then
                score = charWorld
            elseif silentAim.aimMode == "both" then
                local screenN = charScreen / math.max(fovRadius, 1)
                local worldN = charWorld / math.max(maxDistance, 1)
                score = screenN * 0.7 + worldN * 0.3
            else
                score = charScreen
            end
            if isAiCharacter(character) then
                score -= 0.12
            end
            if score < bestScore then
                local picked = pickPartOnCharacter(origin, character, cam, center, excludeList)
                if picked then
                    bestScore = score
                    bestPart = picked
                end
            end
        end
        end
    end

    silentAim.lastTargetPart = bestPart
    silentAim.lastTargetName = bestPart and bestPart.Parent and bestPart.Parent.Name or nil
    return bestPart
end

local function findOriginUpvalueIndex(fn, originFn)
    if type(debug.getupvalue) ~= "function" then
        return nil
    end
    for i = 1, 32 do
        local ok, uv = pcall(debug.getupvalue, fn, i)
        if not ok then
            break
        end
        if uv == originFn then
            return i
        end
    end
    return nil
end

-- ============================================================
-- 安装 (一次性 setupvalue; Toggle 只改 silentAim.enabled, 不在开关时挂/卸)
-- ============================================================
local function restoreGlobalHooks()
    local reg = rawget(_G, REG_KEY)
    if type(reg) == "table" and type(reg.restore) == "function" then
        pcall(reg.restore)
    end
    rawset(_G, REG_KEY, nil)
end

local function uninstallSilentAimHooks()
    pcall(function()
        if not hookState.installed then
            return
        end
        local orig = hookState.origCombatOrigin
        local patches = hookState.patches
        if orig and type(patches) == "table" and type(debug.setupvalue) == "function" then
            for _, patch in ipairs(patches) do
                pcall(debug.setupvalue, patch.fn, patch.index, orig)
            end
        end
        hookState.installed = false
        hookState.origCombatOrigin = nil
        hookState.patches = nil
        rawset(_G, REG_KEY, nil)
    end)
end

local function installSilentAimHooks()
    if hookState.installed then
        return
    end
    if type(debug.setupvalue) ~= "function" or type(debug.getupvalue) ~= "function" then
        TheKing.Notify({ Content = "当前注入器不支持 setupvalue, 静默瞄准不可用", Icon = "alert-triangle" })
        return
    end

    local origCombatOrigin = CameraController.GetCombatOriginFn()
    if type(origCombatOrigin) ~= "function" then
        TheKing.Notify({ Content = "找不到瞄准原点函数", Icon = "alert-triangle" })
        return
    end

    local wrapped = function(...)
        local packed = table.pack(origCombatOrigin(...))
        if silentAim.enabled and not silentAim.raycastGuard and typeof(packed[1]) == "CFrame" then
            pcall(function()
                local cf = packed[1]
                local target = findBestTarget(cf.Position, silentAim.maxDistance)
                if target then
                    local delta = target.Position - cf.Position
                    if delta.Magnitude >= 0.01 then
                        local lookOk, looked = pcall(CFrame.lookAt, cf.Position, target.Position)
                        if lookOk then
                            packed[1] = looked
                        end
                    end
                end
            end)
        end
        return table.unpack(packed, 1, packed.n)
    end

    local patches = {}
    for _, name in ipairs({ "Shoot", "LocalShoot" }) do
        local fn = ClientShootableComponent[name]
        if type(fn) == "function" then
            local index = findOriginUpvalueIndex(fn, origCombatOrigin)
            if index then
                local ok = pcall(debug.setupvalue, fn, index, wrapped)
                if ok then
                    table.insert(patches, { fn = fn, index = index })
                end
            end
        end
    end

    if #patches == 0 then
        if silentAim.enabled then
            TheKing.Notify({ Content = "无法挂接射击瞄准, 静默瞄准不可用", Icon = "alert-triangle" })
        end
        return
    end

    hookState.installed = true
    hookState.origCombatOrigin = origCombatOrigin
    hookState.patches = patches

    rawset(_G, REG_KEY, { restore = uninstallSilentAimHooks })
    print("[RCWTK] silentAim hooks=" .. tostring(#patches))
end

local function disableSilentAimRuntime()
    silentAim.enabled = false
    silentAim.raycastGuard = true
    silentAim.lastTargetName = nil
    silentAim.lastTargetPart = nil
end

local function setDrawFovEnabled(state)
    silentAim.drawFov = state == true
end

local function setSilentAimEnabled(state)
    silentAim.enabled = state == true
    if not state then
        silentAim.lastTargetName = nil
        silentAim.lastTargetPart = nil
        silentAim.raycastGuard = false
    end
end

local function bootstrapSilentAimHooks()
    task.defer(function()
        task.wait(0.3)
        pcall(restoreGlobalHooks)
        task.wait(0.08)
        if not hookState.installed then
            pcall(installSilentAimHooks)
        end
    end)
end

bootstrapSilentAimHooks()

local function getCombatCFrame()
    local ok, cf = pcall(CameraController.GetCombatOrigin)
    if ok and typeof(cf) == "CFrame" then
        return cf
    end
    local cam = workspace.CurrentCamera
    if cam then
        return cam.CFrame
    end
    return nil
end

local function getCharacterFromHit(hit)
    if not hit or not hit.Instance then
        return nil
    end
    local inst = hit.Instance
    local model = inst:FindFirstAncestorOfClass("Model")
    while model do
        if model:FindFirstChildOfClass("Humanoid") then
            return model
        end
        model = model.Parent and model.Parent:FindFirstAncestorOfClass("Model")
    end
    if inst.Parent and inst.Parent:FindFirstChildOfClass("Humanoid") then
        return inst.Parent
    end
    return nil
end

local function findHubScreenGui()
    local found
    pcall(function()
        local h = type(gethui) == "function" and gethui()
        local w = h and h:FindFirstChild("WindUI")
        local win = w and w:FindFirstChild("Window")
        if win then
            found = win:FindFirstAncestorOfClass("ScreenGui")
        end
    end)
    if found and found:IsA("ScreenGui") then
        return found
    end
    return nil
end

local function isMouseOverHub()
    local hub = findHubScreenGui()
    if not hub or not hub.Enabled then
        return false
    end
    local inset = GuiService:GetGuiInset()
    local mouse = UserInputService:GetMouseLocation()
    local ok, objs = pcall(function()
        return hub:GetGuiObjectsAtPosition(mouse.X - inset.X, mouse.Y - inset.Y)
    end)
    return ok and type(objs) == "table" and #objs > 0
end

local function clickMouse()
    if type(isrbxactive) == "function" then
        local ok, active = pcall(isrbxactive)
        if ok and active == false then
            return
        end
    end
    if isMouseOverHub() then
        return
    end
    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        return
    end
    if type(mouse1click) == "function" then
        pcall(mouse1click)
        return
    end
    if type(mouse1press) == "function" then
        pcall(mouse1press)
        task.delay(0.04, function()
            if type(mouse1release) == "function" then
                pcall(mouse1release)
            end
        end)
    end
end

local function hasCrosshairTarget(originCf)
    local exclude = {}
    local localChar = getLocalCharacter()
    if localChar then
        table.insert(exclude, localChar)
    end
    silentAim.raycastGuard = true
    local hit = workspace:Raycast(originCf.Position, originCf.LookVector * silentAim.maxDistance, buildVisParams(exclude))
    silentAim.raycastGuard = false
    local character = getCharacterFromHit(hit)
    return character ~= nil and isValidEnemyCharacter(character)
end

local function tryAutoTrigger()
    if not autoTrigger.enabled then
        return
    end
    if not combatZoneActive() then
        return
    end
    local now = os.clock()
    if now < autoTrigger.armUntil then
        return
    end
    if now - autoTrigger.lastShot < 0.12 then
        return
    end
    if isMouseOverHub() then
        return
    end
    local cf = getCombatCFrame()
    if not cf then
        return
    end
    local shouldFire = false
    if silentAim.enabled then
        shouldFire = findBestTarget(cf.Position, silentAim.maxDistance) ~= nil
    else
        shouldFire = hasCrosshairTarget(cf)
    end
    if shouldFire then
        autoTrigger.lastShot = now
        clickMouse()
    end
end

TheKing.AddConnection(RunService.Heartbeat:Connect(function()
    if autoTrigger.enabled then
        if autoTrigger.armUntil == 0 then
            autoTrigger.armUntil = os.clock() + 0.6
            return
        end
        pcall(tryAutoTrigger)
    else
        autoTrigger.armUntil = 0
    end
end))

local fovWatchArmed = false
TheKing.AddConnection(RunService.Heartbeat:Connect(function()
    if fovShouldShow() then
        if not fovWatchArmed then
            fovWatchArmed = true
            silentAim.uiQuietUntil = os.clock() + 0.6
            return
        end
        if os.clock() < (silentAim.uiQuietUntil or 0) then
            return
        end
        if not fovDraw then
            pcall(ensureFovDraw)
        end
    else
        fovWatchArmed = false
    end
end))

local lastLockScan = 0
local saScanArmed = false
TheKing.AddConnection(RunService.Heartbeat:Connect(function()
    if not silentAim.enabled then
        saScanArmed = false
        return
    end
    if not saScanArmed then
        saScanArmed = true
        lastLockScan = os.clock() + 0.25
        return
    end
    local now = os.clock()
    if now < lastLockScan then
        return
    end
    lastLockScan = now + 0.15
    local cf = getCombatCFrame()
    if cf then
        pcall(findBestTarget, cf.Position, silentAim.maxDistance)
    end
end))

TheKing.Notify({ Content = "TheKing HUB 已加载", Icon = "crown" })

-- ============================================================
-- Tab: 暴力
-- ============================================================
local CombatTab = TheKing.NewTab({ Title = "暴力", Icon = "sword" })

-- UI 引用 (LoadConfig 后需手动同步运行时状态)
local uiRefs = {}

uiRefs.silentAim = CombatTab:Toggle({
    Title = "静默瞄准",
    Value = silentAim.enabled == true,
    Callback = function(state)
        silentAim.enabled = state == true
        if not state then
            silentAim.lastTargetName = nil
            silentAim.lastTargetPart = nil
        end
        scheduleSaveCfg()
    end,
})

uiRefs.visibility = CombatTab:Toggle({
    Title = "可视化",
    Value = silentAim.visibility == true,
    Callback = function(state)
        silentAim.visibility = state == true
        if state then
            silentAim.lastTargetName = nil
            silentAim.lastTargetPart = nil
        end
        scheduleSaveCfg()
    end,
})

uiRefs.aimLogic = CombatTab:Dropdown({
    Title = "瞄准逻辑",
    Values = AIM_MODE_LABELS,
    Value = AIM_MODE_TO_LABEL[silentAim.aimMode] or "准星与距离",
    Callback = function(sel)
        applyAimModeSelection(sel)
        scheduleSaveCfg()
    end,
})

uiRefs.maxDist = CombatTab:Slider({
    Title = "最大距离",
    Value = { Min = 50, Max = 8000, Default = silentAim.maxDistance },
    Step = 50,
    Callback = function(value)
        if type(value) ~= "number" then
            return
        end
        silentAim.maxDistance = math.clamp(value, 50, 8000)
        scheduleSaveCfg()
    end,
})

uiRefs.drawFov = CombatTab:Toggle({
    Title = "范围绘制",
    Value = silentAim.drawFov == true,
    Callback = function(state)
        silentAim.drawFov = state == true
        scheduleSaveCfg()
    end,
})

uiRefs.fovSlider = CombatTab:Slider({
    Title = "范围",
    Value = { Min = 10, Max = 400, Default = silentAim.fovRadius },
    Step = 1,
    Callback = function(value)
        if type(value) ~= "number" then
            return
        end
        silentAim.fovRadius = math.clamp(value, 10, 400)
        fovRadiusQuietAt = os.clock()
        scheduleSaveCfg()
    end,
})

uiRefs.teamCheck = CombatTab:Toggle({
    Title = "队伍检测",
    Value = teamCheck.enabled == true,
    Callback = function(state)
        teamCheck.enabled = state == true
        teamCheck.nextRefresh = 0
        teamCheck.teamPlay = false
        scheduleSaveCfg()
    end,
})

uiRefs.autoTrigger = CombatTab:Toggle({
    Title = "自动扳机",
    Value = autoTrigger.enabled == true,
    Callback = function(state)
        autoTrigger.enabled = state == true
        scheduleSaveCfg()
    end,
})

-- ============================================================
-- Tab: 设置 (骨架标配)
-- ============================================================
local SettingsTab = TheKing.NewTab({ Title = "设置", Icon = "settings" })

local unloading = false

local function performUnload()
    if unloading then
        return
    end
    unloading = true
    fovDrawAlive = false
    silentAim.enabled = false
    silentAim.raycastGuard = true
    silentAim.lastTargetName = nil
    silentAim.lastTargetPart = nil
    autoTrigger.enabled = false
    pcall(TheKing.StopAll)
    task.delay(0.2, function()
        removeFovPack({
            circle = fovDraw,
            snap = fovSnap,
            ax = fovAxisX,
            ay = fovAxisY,
            az = fovAxisZ,
        })
        fovDraw = nil
        fovSnap = nil
        fovAxisX = nil
        fovAxisY = nil
        fovAxisZ = nil
        rawset(_G, FOV_DRAW_KEY, nil)
    end)

    task.defer(function()
        task.wait(0.45)
        pcall(function()
            TheKing.Destroy({ skipSave = true })
        end)
    end)
end

local function unloadAction()
    TheKing.Confirm({
        Title = "卸载确认",
        Content = "将停止全部功能并销毁界面, 确定吗?",
        OnConfirm = performUnload,
    })
end

SettingsTab:Keybind({
    Title = "显示/隐藏窗口",
    Value = "Delete",
    Flag = "uiToggleKey",
    Callback = function()
        local gui = findHubScreenGui()
        if gui then
            gui.Enabled = not gui.Enabled
            return
        end
        pcall(function()
            TheKing.Window:Toggle()
        end)
    end,
})

SettingsTab:Keybind({
    Title = "卸载脚本",
    Value = "End",
    Flag = "uiUnloadKey",
    Callback = unloadAction,
})

SettingsTab:Button({
    Title = "停止全部功能",
    Icon = "square",
    Callback = function()
        TheKing.StopAll()
        setSilentAimEnabled(false)
        autoTrigger.enabled = false
        TheKing.Notify({ Content = "已停止全部功能", Icon = "check-circle" })
    end,
})

SettingsTab:Button({
    Title = "卸载脚本",
    Icon = "trash-2",
    Color = Color3.fromRGB(255, 100, 100),
    Callback = unloadAction,
})

local function syncPersistedUiState()
    if uiRefs.teamCheck and uiRefs.teamCheck.Value == true then
        teamCheck.enabled = true
    end
    if uiRefs.autoTrigger and uiRefs.autoTrigger.Value == true then
        autoTrigger.enabled = true
        autoTrigger.armUntil = os.clock() + 0.6
    end
end

if TheKing.LoadConfig then
    TheKing.LoadConfig()
    task.defer(function()
        task.wait(0.12)
        syncPersistedUiState()
    end)
end

print("[RCWTK] SNIPER_HUB_v041")

print("[RCWTK] SNIPER_HUB_v041")
