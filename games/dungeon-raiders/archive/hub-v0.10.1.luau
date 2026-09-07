--[[
    TheKing HUB [0.10.1] - 地下城战利品者
    RCWTK 引擎生成 | 模板 v1.0
    版本历史: games/dungeon-raiders/changelog.md

    功能清单:
      战斗
        自动喝血药水: 低血自动使用装备血瓶 (服务端 UsePotion); 阈值可调(默认50%)
        杀戮光环(自动平A): 360° 锁最近怪; 平A距离跟当前武器形态自动识别
          (锻造霸主 3技能切弓用 Range+SpecialRangeBonus, 4技能切回近战用 Range)
          开平A或技能光环时自动对 Boss 拼刀 (点 F / Parry), 掐连段; 双光环同样生效
        杀戮技能光环: 冷却好了按 1→4 丢, 有充能打光, 不留手
        职业下拉自动跟角色, 选错档案会乱距离/乱放技能
        自动选择 BUFF: 靠近祭坛自动交互; 三选一命中偏好则自动点卡
        自动补充药水: 靠近炼药锅 (Refill Potions) 自动交互
        锁定脚底小光环: 红=平A圈 / 黄=技能圈 / 目标脚下双圈跟出手目标同一只
        职业数据写在本文件 CLASS_ARCHIVE_RAW (随脚本走, 无单独档案)
      视觉
        宝箱透视: 投影填充 ESP (穿墙), 颜色/透明度可调
        怪物预警: 屏幕中心雷达圈 + 三角箭头指示怪物方位, 距离/圈径/箭头/颜色可调
        结算动画加速: RewardReveal 卡片直显w
        假名: 左上角 + 头顶名牌改为 "theKing User" + 彩虹渐变字体
        DPS面板: 局内最多4人 名字/等级/总伤/DPS + 血条 (可拖动, 位置持久化)
        闪避冷却条: 经验条下方, 仅 CD 中显示, 从左涨满后渐隐
      快捷键
        F1 传送下一房间(需当前房间清怪完成) / F2 重开对局(结算界面) / F3 回城(结算界面)
      换服自动注入: 重开/回城等传送后自动重跑本脚本 (执行器无挂号 API 则跳过)

    逆向结论 (同步自 games/dungeon-raiders/intel.md, 会话2/2.1):
      - 战斗发包: Inputs.Attack:FireServer(moveDir)
      - 拼刀: Inputs.Parry:FireServer(); 长按举盾才是 Block start/stop
      - 喝药: PotionService:UsePotion(1); 重开/回城: DungeonRunService:RequestReplay()/RequestReturn()
      - 技能数据: 客户端 require RS.Classes.<职业>.Skills/<技能> 读 HitboxSize/HitboxRange(或AoEHitboxRange)
      - 渲染: Potassium Drawing 不可靠(隐形+疑似崩溃) → v1.0.2 起全部绘制走原生 ScreenGui
      - 平A连击: Animator DBreset (攻击动画名 Attack_* 或任意带 DBreset 的轨)
      - 锻造霸主: 3 Hrunting → EnterBowMode(SpecialMoveset=1, 弓可见); 4 Supreme Cell Blades → EnterMeleeMode
        弓平A距离 Range(16)+SpecialRangeBonus(10)=26; 近战 Range=16。占位 Hitbox Size≈0.05 时 reach=2*|C0.Z|
      - 局内总伤: Player 属性 Damage_Dealt; 面板本局累计(属性抖动/换房清 0 不丢数)
      - 被诅咒的孩子: 平A Range=18 Hitbox(15,10,18); 技能模块 require 会炸, 用档案兜底
        1 Hollow Rush 冲刺连斩 / 2 Severance 三充能横斩 / 3 Cursed Speech 范围定身 / 4 Cursed Love 前方射线 tick
      - 阿蒂米斯: 平A Range=32 Hitbox(15,15,35); 技能已写入 CLASS_ARCHIVE_RAW
        1 Twin Bolt 三充能双矢 / 2 Moonfall 前方落箭雨 / 3 Tempest Strike 双充能突进 / 4 Stormfire 八连射突进
      - 火焰据点 (Flame Bastion): 平A Range=19 Hitbox(20,10,19); Epic 长枪
        1 Pyre Cyclone 旋转三连(带格挡窗) / 2 Blazing Reach 六段突刺 / 3 Ember Step 双充能无敌冲斩 / 4 Ashen Onslaught 五连推进
      - 忍者 (Shinobi): 平A Range=14 Hitbox(18,10,14); Legendary 攻速1.1×3段
        1 Flash Rend 双充能斩 / 2 Kurogiri 烟闪连斩 / 3 Guillotine Drop 前突落地 AoE / 4 Oni Rend 四段突进可拼
      - 卡奇 (Kage): 平A Range=17 Hitbox(15,15,17); Legendary
        1 Shadow Step 三充能背后斩 / 2 Heart Stab 锁血连锁背刺 / 3 Devouring Gale 原地旋斩(可拼) / 4 Fists of Ruin 多段拳+终结

    使用方式:
      开发: loadstring(readfile("dungeon-raiders/hub.luau"))()
      热调试: 改完代码直接重新执行本文件
      发布: python tools/publish.py --game dungeon-raiders --push
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

-- 建窗前先偷看存档: 窗口创建时就能藏, 避免先闪一下再关
local START_UI_HIDDEN = false
do
    local cands = {
        "dungeon-raiders/dr-prefs.txt",
        "games/dungeon-raiders/dr-prefs.txt",
        "dr-prefs.txt",
    }
    for _, p in ipairs(cands) do
        local ok, raw = pcall(readfile, p)
        if ok and type(raw) == "string" and raw:find("uiHidden=1", 1, true) then
            START_UI_HIDDEN = true
            break
        end
    end
end

local TheKing = loadstring(libSource)({
    GameName = "地下城战利品者",
    ScriptVersion = "0.10.1",
    StartHidden = START_UI_HIDDEN,
})
pcall(function()
    TheKing.ArmTeleportReload({
        Files = {
            "games/dungeon-raiders/hub.luau",
            "dungeon-raiders/hub.luau",
        },
    })
end)

-- 主块局部变量超过 Luau 200 上限会编不过; 业务放进内层函数
;(function()

-- ============================================================
-- 服务与常量
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local hubAlive = true

-- ==================== 参数持久化 (自建防抖写盘, 不依赖 Rayfield flag 高频写盘) ====================
-- 覆盖无 Flag 的 Slider 与自绘网格: 值变更防抖 1.5s 落盘一次 + 卸载/热替换时立即落盘
local PREF_CANDIDATES = {
    "dungeon-raiders/dr-prefs.txt",
    "games/dungeon-raiders/dr-prefs.txt",
    "dr-prefs.txt",
}
local PREF_FILE = PREF_CANDIDATES[1]
local PREF = {}
local function prefLoad()
    for _, p in ipairs(PREF_CANDIDATES) do
        local ok, raw = pcall(readfile, p)
        if ok and type(raw) == "string" and raw ~= "" then
            PREF_FILE = p
            for line in (raw .. "\n"):gmatch("([^\n]+)\n") do
                local k, v = line:match("^([%w_]+)=(.-)$")
                if k and v then
                    v = v:gsub("\r", ""):gsub("^%s+", ""):gsub("%s+$", "")
                    if v ~= "" then
                        local n = tonumber(v)
                        PREF[k] = n or v
                    end
                end
            end
        end
    end
end
prefLoad()
if (tonumber(PREF.uiHidden) or 0) ~= 0 then
    START_UI_HIDDEN = true
end
local function prefFlush()
    local parts = {}
    for k, v in pairs(PREF) do
        parts[#parts + 1] = tostring(k) .. "=" .. tostring(v)
    end
    local body = table.concat(parts, "\n")
    local ok = pcall(writefile, PREF_FILE, body)
    if not ok then
        for _, p in ipairs(PREF_CANDIDATES) do
            local folder = p:match("^(.*)/[^/]+$")
            if folder and type(makefolder) == "function" then
                pcall(makefolder, folder)
            end
            if pcall(writefile, p, body) then
                PREF_FILE = p
                break
            end
        end
    end
end
local _prefSaveT = nil
local function prefSave()
    if _prefSaveT then
        task.cancel(_prefSaveT)
    end
    _prefSaveT = task.delay(0.4, function()
        _prefSaveT = nil
        prefFlush()
    end)
end
TheKing.OnCleanup(function()
    hubAlive = false
    if _prefSaveT then
        task.cancel(_prefSaveT)
        _prefSaveT = nil
    end
    prefFlush()
    -- 恢复 AutoRotate (自动平A锁定期可能残留)
    pcall(function()
        local c = LocalPlayer.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if h then
            h.AutoRotate = true
        end
    end)
end)
-- ==================== /参数持久化 ====================

-- Toggle 开关状态也走自建持久化 (Rayfield 配置系统在本环境失效, rfld 从不落盘)
-- 每次开关状态变化写 PREF.t_<flag>; 加载时由尾部 RestoreToggle 程序化恢复
if TheKing.SetTogglePersist then
    TheKing.SetTogglePersist(function(flag, on)
        PREF["t_" .. flag] = on and 1 or 0
        prefSave()
    end)
end
if TheKing.SetWindowPersist then
    local muteShow = START_UI_HIDDEN
    TheKing.SetWindowPersist(function(hidden)
        if muteShow and not hidden then
            return
        end
        PREF.uiHidden = hidden and 1 or 0
        prefFlush()
    end)
    if muteShow then
        task.delay(1.2, function()
            muteShow = false
        end)
    end
end
local function prefSet(key, val)
    PREF[key] = val
    prefSave()
end
local function keybindToName(el)
    if type(el) ~= "table" then
        return nil
    end
    local v = el.currentKeybind or el.value or el.Keybind
    if typeof(v) == "EnumItem" then
        return v.Name
    end
    if type(v) == "string" and v ~= "" and v ~= "None" and v ~= "Unknown" then
        return v
    end
    return nil
end
local function persistKeybindEl(el, prefKey)
    if type(el) ~= "table" or type(el.Set) ~= "function" then
        return el
    end
    local orig = el.Set
    function el:Set(...)
        local r = orig(self, ...)
        local name = keybindToName(self)
        if name then
            prefSet(prefKey, name)
        end
        return r
    end
    return el
end

local Knit = require(ReplicatedStorage.Packages.Knit)
local Inputs = ReplicatedStorage.Player.Remotes.Inputs
local AttackRE, SkillRE, SprintRE, ParryRE = Inputs.Attack, Inputs.Skill, Inputs.Sprint, Inputs.Parry

local function getChar()
    return LocalPlayer.Character
end
local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- ============================================================
-- 通用工具
-- ============================================================
local function flatDir(fromPos, toPos)
    local d = toPos - fromPos
    d = Vector3.new(d.X, 0, d.Z)
    if d.Magnitude < 0.01 then
        return Vector3.zero
    end
    return d.Unit
end

local function faceTowards(root, targetPos)
    if not root then
        return
    end
    local d = flatDir(root.Position, targetPos)
    if d.Magnitude < 0.01 then
        return
    end
    root.CFrame = CFrame.lookAt(root.Position, root.Position + d)
end

local _enemyCache = { t = 0, list = nil }
local function getEnemies(force)
    local now = os.clock()
    if force or not _enemyCache.list or (now - _enemyCache.t) > 0.18 then
        local list = {}
        for _, e in ipairs(CollectionService:GetTagged("Enemy")) do
            if not e:GetAttribute("Dead") then
                -- 玩家角色也可能带 Enemy 标签, 索敌绝不锁自己/队友
                local plr = Players:GetPlayerFromCharacter(e)
                if not plr then
                    local uid = tonumber(e:GetAttribute("UserId") or e:GetAttribute("PlayerUserId"))
                    if uid then
                        plr = Players:GetPlayerByUserId(uid)
                    end
                end
                if not plr then
                    local hrp = e:FindFirstChild("HumanoidRootPart") or e.PrimaryPart
                    if hrp then
                        list[#list + 1] = { model = e, hrp = hrp }
                    end
                end
            end
        end
        _enemyCache = { t = now, list = list }
    end
    return _enemyCache.list
end

local function getMapDir()
    for _, c in ipairs(workspace:GetChildren()) do
        if c.Name:match("^Generated_") then
            return c
        end
    end
    return nil
end

local function getCurrentRoom()
    local hrp = getHRP()
    if not hrp then
        return nil
    end
    local mapDir = getMapDir()
    if not mapDir then
        return nil
    end
    local pos = hrp.Position
    for _, child in ipairs(mapDir:GetChildren()) do
        if child.Name:match("^Room_%d+$") then
            local zone = child:FindFirstChild("Zone")
            if zone and zone:IsA("BasePart") then
                local rel = zone.CFrame:PointToObjectSpace(pos)
                local sz = zone.Size / 2
                if math.abs(rel.X) <= sz.X and math.abs(rel.Y) <= sz.Y and math.abs(rel.Z) <= sz.Z then
                    return child
                end
            end
        end
    end
    return nil
end

local function roomHasEnemies(roomModel)
    if not roomModel then
        return false
    end
    local zone = roomModel:FindFirstChild("Zone")
    if not zone then
        return true
    end
    local cz = zone.CFrame
    local csz = zone.Size / 2
    for _, en in ipairs(getEnemies(true)) do
        if not en.model:GetAttribute("IsDormant") then
            local rel = cz:PointToObjectSpace(en.hrp.Position)
            if math.abs(rel.X) <= csz.X and math.abs(rel.Y) <= csz.Y and math.abs(rel.Z) <= csz.Z then
                return true
            end
        end
    end
    return false
end

local function worldToRadarAngle(targetPos)
    local hrp = getHRP()
    if not hrp then
        return nil
    end
    local cam = workspace.CurrentCamera
    if not cam then
        return nil
    end
    local flatT = flatDir(hrp.Position, targetPos)
    if flatT.Magnitude < 0.01 then
        return nil
    end
    local camFlat = flatDir(hrp.Position, hrp.Position + cam.CFrame.LookVector)
    return math.atan2(
        camFlat.X * flatT.Z - camFlat.Z * flatT.X,
        camFlat.X * flatT.X + camFlat.Z * flatT.Z
    )
end

-- ============================================================
-- 职业档案 (写在本文件, 随 hub 一起走)
-- 杀戮光环: ClassKit.MeleeRange  技能光环: ClassKit.Skills
-- ============================================================
local CLASS_ARCHIVE_RAW = {
    {
        Name = "被诅咒的孩子",
        Range = 18,
        Skills = {
            { Range = 16, Cd = 7, Duration = 2, Dash = 80 },
            { Range = 29, Cd = 8, Charges = 3, Duration = 1.2, Dash = 95 },
            { Range = 30, Cd = 13, Duration = 2 },
            { Range = 40, Cd = 15, Duration = 5 },
        },
    },
    { Name = "锻造霸主", Range = 16, Bow = 26 },
    {
        Name = "忍者",
        Range = 14,
        Skills = {
            { Range = 18, Cd = 8, Charges = 2, Duration = 1.2 },
            { Range = 18, Cd = 7, Duration = 2.5, Dash = 80 },
            { Range = 15, Cd = 9, Duration = 2.5, Dash = 70 },
            { Range = 20, Cd = 12, Duration = 2.5, Dash = 80 },
        },
    },
    {
        Name = "阿蒂米斯",
        Range = 32,
        Skills = {
            { Range = 25, Cd = 4, Charges = 3, Duration = 1 },
            { Range = 29, Cd = 12, Duration = 3 },
            { Range = 25, Cd = 7, Charges = 2, Duration = 2, Dash = 70 },
            { Range = 28, Cd = 12, Duration = 3.5, Dash = 55 },
        },
    },
    {
        Name = "火焰据点",
        Range = 19,
        Skills = {
            { Range = 14, Cd = 6, Duration = 2 },
            { Range = 25, Cd = 10, Duration = 2, Dash = 90 },
            { Range = 20, Cd = 7, Charges = 2, Duration = 1.5, Dash = 70 },
            { Range = 20, Cd = 10, Duration = 2.5, Dash = 40 },
        },
    },
    {
        Name = "卡奇",
        Range = 17,
        Skills = {
            { Range = 28, Cd = 8, Charges = 3, Duration = 2 },
            { Range = 28, Cd = 10, Duration = 8 },
            { Range = 15, Cd = 10, Duration = 2.5 },
            { Range = 17, Cd = 15, Duration = 5 },
        },
    },
}
local CLASS_PROFILES = {}
local CLASS_BY_FOLDER = {}
local ClassKit = {}

local function buildClassNameIndex()
    local idx = {}
    local function add(key, folder)
        if type(key) == "string" and key ~= "" and type(folder) == "string" then
            idx[string.lower(key)] = folder
        end
    end
    local classes = ReplicatedStorage:FindFirstChild("Classes")
    if not classes then
        return idx
    end
    local classData = nil
    local cdMod = classes:FindFirstChild("Class_Data")
    if cdMod then
        local ok, data = pcall(require, cdMod)
        if ok and type(data) == "table" then
            classData = data
        end
    end
    if type(classData) == "table" then
        for k, v in pairs(classData) do
            if type(k) == "string" and type(v) == "table" then
                add(k, k)
                add(v.Name, k)
            end
        end
    end
    add("被诅咒的孩子", "Cursed Child")
    add("锻造霸主", "Forge Archon")
    add("忍者", "Shinobi")
    add("shinobi", "Shinobi")
    add("ninja", "Shinobi")
    add("阿蒂米斯", "Artemis")
    add("火焰据点", "Flame Bastion")
    add("火据点", "Flame Bastion")
    add("卡奇", "Kage")
    add("kage", "Kage")
    for _, f in ipairs(classes:GetChildren()) do
        if f:IsA("Folder") or f:IsA("ModuleScript") then
            local name = f.Name
            if name ~= "Class_Data" and name ~= "PackageLink" then
                add(name, name)
                if not (classData and type(classData[name]) == "table") then
                    local defMod = f:FindFirstChild("Definition")
                    if defMod then
                        local ok, def = pcall(require, defMod)
                        if ok and type(def) == "table" then
                            add(def.Name, name)
                        end
                    end
                end
            end
        end
    end
    return idx
end

local function resolveClassFolder(hint, idx)
    if type(hint) ~= "string" or hint == "" then
        return nil
    end
    local key = string.lower(hint)
    if idx[key] then
        return idx[key]
    end
    local en = hint:match("^([^（(]+)")
    if en then
        en = (en:gsub("%s+$", ""))
        local k2 = string.lower(en)
        if idx[k2] then
            return idx[k2]
        end
    end
    local zh = hint:match("（([^）]+)）") or hint:match("%(([^%)]+)%)")
    if zh then
        local k3 = string.lower(zh)
        if idx[k3] then
            return idx[k3]
        end
        hint = zh
        key = k3
    end
    local best, bestLen = nil, 0
    for k, folder in pairs(idx) do
        if #k >= 2 and (string.find(key, k, 1, true) or string.find(k, key, 1, true)) then
            if #k > bestLen then
                best, bestLen = folder, #k
            end
        end
    end
    return best
end

local function normSkill(slot, s)
    if type(s) ~= "table" then
        return nil
    end
    local range = tonumber(s.Range or s.HitboxRange or s.TickHitboxRange)
    return {
        AnimationName = s.AnimationName or ("Ability_" .. tostring(slot)),
        Cooldown = tonumber(s.Cd or s.Cooldown),
        MaxCharges = tonumber(s.Charges or s.MaxCharges),
        HitboxRange = range,
        TickHitboxRange = tonumber(s.TickHitboxRange),
        MaxDuration = tonumber(s.Duration or s.MaxDuration),
        DashSpeed = tonumber(s.Dash or s.DashSpeed),
        HitboxSize = s.HitboxSize,
        TickHitboxSize = s.TickHitboxSize,
    }
end

local function normalizeEntry(raw, idx)
    if type(raw) ~= "table" then
        return nil
    end
    local hint = raw.Name or raw.Class or raw.Label or raw.Folder
    local folder = resolveClassFolder(hint, idx)
    if not folder then
        warn("[RCWTK] 职业档案无法识别: " .. tostring(hint) .. " (对照游戏 Current_Class 改 Name)")
        return nil
    end
    local skills = nil
    local src = raw.Skills
    if type(src) == "table" then
        skills = {}
        local n = 0
        for i = 1, 4 do
            local one = normSkill(i, src[i])
            if one and (one.HitboxRange or one.MaxCharges or one.Cooldown) then
                skills[i] = one
                n = n + 1
            end
        end
        if n == 0 then
            skills = nil
        end
    end
    local display = raw.Name or raw.Label or folder
    return {
        Folder = folder,
        Name = display,
        Label = display,
        MeleeRange = tonumber(raw.Range or raw.MeleeRange),
        BowRange = tonumber(raw.Bow or raw.BowRange),
        SpecialRangeBonus = tonumber(raw.SpecialRangeBonus),
        SkipRequire = raw.SkipRequire == true or skills ~= nil,
        Skills = skills,
    }
end

local function normalizeArchive(data, idx)
    if type(data) ~= "table" then
        return {}
    end
    local rows = data
    if data[1] == nil then
        rows = {}
        local bag = data.Classes or data.classes
        if type(bag) == "table" then
            for k, v in pairs(bag) do
                if type(v) == "table" then
                    v.Name = v.Name or k
                    rows[#rows + 1] = v
                end
            end
        end
    end
    local list = {}
    for _, raw in ipairs(rows) do
        local cp = normalizeEntry(raw, idx)
        if cp then
            list[#list + 1] = cp
        end
    end
    return list
end

do
    local idx = buildClassNameIndex()
    CLASS_PROFILES = normalizeArchive(CLASS_ARCHIVE_RAW, idx)
    for _, cp in ipairs(CLASS_PROFILES) do
        CLASS_BY_FOLDER[cp.Folder] = cp
    end
    if #CLASS_PROFILES == 0 then
        warn("[RCWTK] 职业档案为空, 杀戮/技能光环没有职业数据")
    else
        print("[RCWTK] 职业档案已内嵌 (" .. tostring(#CLASS_PROFILES) .. " 个)")
    end
end

function ClassKit.Get(folder)
    return folder and CLASS_BY_FOLDER[folder] or nil
end
function ClassKit.MeleeRange(folder, bowStance)
    local cp = ClassKit.Get(folder)
    if not cp then
        return nil
    end
    if bowStance then
        local r = tonumber(cp.BowRange) or ((tonumber(cp.MeleeRange) or 0) + (tonumber(cp.SpecialRangeBonus) or 0))
        if r > 0 then
            return r
        end
        return nil
    end
    return tonumber(cp.MeleeRange)
end
function ClassKit.ArchiveSkills(folder)
    local cp = ClassKit.Get(folder)
    local sk = cp and cp.Skills
    if type(sk) ~= "table" then
        return nil
    end
    local n = 0
    for i = 1, 4 do
        if sk[i] then
            n = n + 1
        end
    end
    if n == 0 then
        return nil
    end
    return sk
end

local function profileByFolder(folder)
    return ClassKit.Get(folder)
end

local function loadClassSkills(folder)
    local archived = ClassKit.ArchiveSkills(folder)
    local cp = ClassKit.Get(folder)
    if cp and cp.SkipRequire then
        return archived
    end
    local clsDir = ReplicatedStorage.Classes:FindFirstChild(folder)
    if not clsDir then
        return archived
    end
    local sk = clsDir:FindFirstChild("Skills")
    if not sk then
        return archived
    end
    local skills = {}
    for _, mod in ipairs(sk:GetChildren()) do
        if mod:IsA("ModuleScript") then
            local ok, data = pcall(require, mod)
            if ok and type(data) == "table" then
                local n = tostring(data.AnimationName or ""):match("^Ability_(%d+)$")
                local slot = n and tonumber(n)
                if slot and slot >= 1 and slot <= 4 then
                    skills[slot] = data
                end
            end
        end
    end
    local n = 0
    for i = 1, 4 do
        if skills[i] then
            n = n + 1
        end
    end
    if n == 0 then
        return archived
    end
    return skills
end

local _skillCache = { folder = nil, data = nil }
local function cachedClassSkills(folder)
    if _skillCache.folder ~= folder then
        _skillCache = { folder = folder, data = loadClassSkills(folder) }
    end
    return _skillCache.data
end
function ClassKit.Skills(folder)
    return cachedClassSkills(folder)
end

local function skillRange(data)
    if not data then
        return 15
    end
    local r = tonumber(data.HitboxRange)
        or tonumber(data.TickHitboxRange)
        or tonumber(data.AoEHitboxRange)
        or tonumber(data.OpenerRange)
    if r and r > 0 then
        return r
    end
    local hs = data.HitboxSize or data.TickHitboxSize or data.OpenerHitbox or data.TornadoHitbox
    if typeof(hs) == "Vector3" then
        return math.max(hs.X, hs.Z) / 2
    elseif type(hs) == "table" and (hs.X or hs.Z) then
        return math.max(tonumber(hs.X) or 0, tonumber(hs.Z) or 0) / 2
    end
    return 15
end

local function skillMaxDuration(data)
    local d = data and tonumber(data.MaxDuration)
    if d and d > 0 then
        return math.clamp(d, 0.45, 6)
    end
    return 0.9
end

local function skillIsMobile(data)
    -- 有升空/冲刺字段 = 朝向必须先同步到服务端
    if not data then
        return false
    end
    return (tonumber(data.LiftSpeed) or 0) > 0
        or (tonumber(data.StepDashSpeed) or 0) > 0
        or (tonumber(data.DashSpeed) or 0) > 0
end

-- ============================================================
-- 覆盖层绘制: 整段落进内层闭包, 对象池 local 不占外层 200 格
-- 新功能优先 TheKing.Draw; 本段是已验证的局内圈/透视/雷达
-- ============================================================
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
if not PlayerGui then
    TheKing.Notify({ Title = "绘制", Content = "PlayerGui 等待超时, 透视/圈可能没有", Icon = "alert-triangle" })
end

local Ov = (function()
    local Overlay = Instance.new("ScreenGui")
    Overlay.Name = "TheKing_DrawOverlay"
    Overlay.ResetOnSpawn = false
    Overlay.IgnoreGuiInset = true
    Overlay.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Overlay.Parent = PlayerGui

    local linePool, barPool, dotPool = {}, {}, {}
    local arrowPool, chestTxtPool = {}, {}
    local curUsedLines, curUsedBars, curUsedDots = 0, 0, 0
    local curUsedArrows, curUsedChestTxts = 0, 0
    local lastUsedLines, lastUsedBars, lastUsedDots = 0, 0, 0
    local lastUsedArrows, lastUsedChestTxts = 0, 0
    local FOOT_Y_OFFSET = -2.2

    local function allocLine()
        local f = Instance.new("Frame")
        f.BackgroundColor3 = Color3.new(1, 1, 1)
        f.BorderSizePixel = 0
        f.AnchorPoint = Vector2.new(0, 0.5)
        f.Visible = false
        f.Parent = Overlay
        return f
    end
    local function allocBar()
        local f = Instance.new("Frame")
        f.BackgroundColor3 = Color3.new(1, 1, 1)
        f.BorderSizePixel = 0
        f.Visible = false
        f.Parent = Overlay
        return f
    end
    local function allocArrow()
        local t = Instance.new("TextLabel")
        t.Text = "▲"
        t.Font = Enum.Font.SourceSansBold
        t.BackgroundTransparency = 1
        t.BorderSizePixel = 0
        t.AnchorPoint = Vector2.new(0.5, 0.5)
        t.Visible = false
        t.Parent = Overlay
        return t
    end
    local function allocChestTxt()
        local t = Instance.new("TextLabel")
        t.Text = "宝箱"
        t.Font = Enum.Font.SourceSansBold
        t.BackgroundTransparency = 1
        t.BorderSizePixel = 0
        t.AnchorPoint = Vector2.new(0.5, 0.5)
        t.TextStrokeTransparency = 0
        t.TextStrokeColor3 = Color3.new(0, 0, 0)
        t.Visible = false
        t.Parent = Overlay
        return t
    end

    local function drawLine(x1, y1, x2, y2, thickness, color, transparency)
        curUsedLines = curUsedLines + 1
        local f = linePool[curUsedLines]
        if not f then
            f = allocLine()
            linePool[curUsedLines] = f
        end
        local dx, dy = x2 - x1, y2 - y1
        local len = math.sqrt(dx * dx + dy * dy)
        if len < 1 then
            len = 1
        end
        f.BackgroundColor3 = color
        f.BackgroundTransparency = transparency
        f.Rotation = math.deg(math.atan2(dy, dx))
        f.Size = UDim2.fromOffset(len, math.max(1, thickness))
        f.Position = UDim2.fromOffset(x1, y1 - thickness / 2)
        f.Visible = true
    end

    local function hideTail(pool, used, last)
        for i = used + 1, last do
            if pool[i] then
                pool[i].Visible = false
            end
        end
    end

    local api = {}
    function api.frameEnd()
        hideTail(linePool, curUsedLines, lastUsedLines)
        hideTail(barPool, curUsedBars, lastUsedBars)
        hideTail(dotPool, curUsedDots, lastUsedDots)
        hideTail(arrowPool, curUsedArrows, lastUsedArrows)
        hideTail(chestTxtPool, curUsedChestTxts, lastUsedChestTxts)
        lastUsedLines, lastUsedBars, lastUsedDots = curUsedLines, curUsedBars, curUsedDots
        lastUsedArrows, lastUsedChestTxts = curUsedArrows, curUsedChestTxts
        curUsedLines, curUsedBars, curUsedDots = 0, 0, 0
        curUsedArrows, curUsedChestTxts = 0, 0
    end
    function api.reset()
        for _, pool in ipairs({ linePool, barPool, dotPool, arrowPool, chestTxtPool }) do
            for _, f in ipairs(pool) do
                f.Visible = false
            end
        end
        lastUsedLines, lastUsedBars, lastUsedDots = 0, 0, 0
        lastUsedArrows, lastUsedChestTxts = 0, 0
        curUsedLines, curUsedBars, curUsedDots = 0, 0, 0
        curUsedArrows, curUsedChestTxts = 0, 0
    end
    function api.takeChestTxt()
        curUsedChestTxts = curUsedChestTxts + 1
        local t = chestTxtPool[curUsedChestTxts]
        if not t then
            t = allocChestTxt()
            chestTxtPool[curUsedChestTxts] = t
        end
        return t
    end
    function api.takeArrow()
        curUsedArrows = curUsedArrows + 1
        local t = arrowPool[curUsedArrows]
        if not t then
            t = allocArrow()
            arrowPool[curUsedArrows] = t
        end
        return t
    end
    function api.ring(hrp, radius, color, transparency, opts)
        local cam = workspace.CurrentCamera
        if not cam then
            return
        end
        opts = opts or {}
        local yOff = opts.yOff or FOOT_Y_OFFSET
        local center = hrp.Position + Vector3.new(0, yOff, 0)
        local s0 = cam:WorldToScreenPoint(center)
        local sumR, nR = 0, 0
        for k = 0, 3 do
            local a = k * math.pi / 2
            local sp = cam:WorldToScreenPoint(center + Vector3.new(math.cos(a) * radius, 0, math.sin(a) * radius))
            if s0.Z > 0 and sp.Z > 0 then
                sumR = sumR + ((sp.X - s0.X) ^ 2 + (sp.Y - s0.Y) ^ 2) ^ 0.5
                nR = nR + 1
            end
        end
        local scrR = nR > 0 and (sumR / nR) or 30
        if scrR < (opts.minScr or 4) then
            return
        end
        local segs = math.clamp(math.floor(2 * math.pi * scrR / 7), opts.minSegs or 24, opts.maxSegs or 220)
        local pts = {}
        local anyF = false
        for i = 1, segs do
            local a = (i - 1) / segs * math.pi * 2
            local sp = cam:WorldToScreenPoint(center + Vector3.new(math.cos(a) * radius, 0, math.sin(a) * radius))
            pts[i] = sp
            if sp.Z > 0 then
                anyF = true
            end
        end
        if not anyF then
            return
        end
        local th = opts.thickness or 2
        for i = 1, segs do
            local p1 = pts[i]
            local p2 = pts[(i % segs) + 1]
            if p1.Z > 0 and p2.Z > 0 then
                local dx, dy = p2.X - p1.X, p2.Y - p1.Y
                local len = math.sqrt(dx * dx + dy * dy)
                if len > 0.5 then
                    local ex, ey = dx / len * 2, dy / len * 2
                    drawLine(p1.X - ex, p1.Y - ey, p2.X + ex, p2.Y + ey, th, color, transparency)
                end
            end
        end
    end
    TheKing.OnCleanup(function()
        pcall(function()
            Overlay:Destroy()
        end)
    end)
    api.gui = Overlay
    return api
end)()

-- ============================================================
-- Tab: 战斗
-- ============================================================
local BattleTab = TheKing.NewTab({ Title = "战斗", Icon = "swords" })

-- 平A距离: 跟当前武器形态走。锻造霸主 3技能切弓 / 4技能切回近战 (看左手 Bow 透明度)
-- 未挥击时 Hitbox 是占位 (Size≈0.05, C0.Z=-Range/2), 真实距离 = 2*|C0.Z|, 不能用 Size.Z/2
local _meleeRangeCache = { t = 0, v = 12, cls = nil, bow = false, clsR = nil }
local function isForgeBowStance()
    local cls = LocalPlayer:GetAttribute("Current_Class") or LocalPlayer:GetAttribute("Active_Class")
    if cls ~= "Forge Archon" then
        return false
    end
    local char = getChar()
    if not char then
        return false
    end
    local bow = char:FindFirstChild("Bow", true)
    if bow and bow:IsA("BasePart") then
        return bow.Transparency < 0.5
    end
    local ls = char:FindFirstChild("LeftSword", true)
    if ls and ls:IsA("BasePart") then
        return ls.Transparency > 0.5
    end
    return false
end
local function classDefAttackRange(className, bowStance)
    if not className then
        return nil
    end
    if _meleeRangeCache.cls == className and _meleeRangeCache.bow == bowStance and _meleeRangeCache.clsR then
        return _meleeRangeCache.clsR
    end
    local r = ClassKit.MeleeRange(className, bowStance)
    if not r then
        local folder = ReplicatedStorage.Classes:FindFirstChild(className)
        local defMod = folder and folder:FindFirstChild("Definition")
        if defMod then
            local ok, def = pcall(require, defMod)
            if ok and type(def) == "table" then
                r = tonumber(def.Range)
                if bowStance then
                    r = (r or 0) + (tonumber(def.SpecialRangeBonus) or 0)
                    if r <= 0 then
                        r = nil
                    end
                end
            end
        end
    end
    _meleeRangeCache.cls = className
    _meleeRangeCache.bow = bowStance
    _meleeRangeCache.clsR = r
    return r
end
local function liveHitboxReach()
    local char = getChar()
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return nil
    end
    local best = nil
    local function consider(p)
        if not (p and p.Name == "Hitbox" and p:IsA("BasePart")) then
            return
        end
        local sz = p.Size
        local off = 0
        local weld = p:FindFirstChild("Hitbox_Weld")
        if weld and weld:IsA("Weld") then
            off = math.abs(weld.C0.Position.Z)
        else
            local look = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z)
            if look.Magnitude > 0.01 then
                look = look.Unit
                local d = p.Position - hrp.Position
                off = math.abs(d.X * look.X + d.Z * look.Z)
            end
        end
        local szZ = math.abs(sz.Z)
        -- 占位盒: Weapon_Manager 闲置 Size≈0.05, C0 = (0,0,-Range/2)
        local reach = (szZ < 1) and (off * 2) or (off + szZ / 2)
        if reach > 1.5 and (not best or reach > best) then
            best = reach
        end
    end
    consider(hrp:FindFirstChild("Hitbox"))
    for _, ch in ipairs(hrp:GetChildren()) do
        consider(ch)
    end
    consider(char:FindFirstChild("Hitbox"))
    return best
end
local function getMeleeRange()
    local now = os.clock()
    local bow = isForgeBowStance()
    if now - _meleeRangeCache.t < 0.12 and _meleeRangeCache.bow == bow then
        return _meleeRangeCache.v
    end
    local cls = LocalPlayer:GetAttribute("Current_Class") or LocalPlayer:GetAttribute("Active_Class")
    local fromBox = liveHitboxReach()
    local fromDef = classDefAttackRange(cls, bow)
    local v
    if bow then
        -- 切弓瞬间闲置 Hitbox 可能还是近战 Range, 信档案 BowRange
        v = fromDef or fromBox or 26
        if fromBox and fromBox > v then
            v = fromBox
        end
    else
        -- 档案 Range 是闲置权威距离; 挥击中盒更长才跟盒, 占位盒(≈Range)不覆盖档案
        v = fromDef or fromBox or 12
        if fromBox and fromDef and fromBox > fromDef + 1.5 then
            v = fromBox
        end
    end
    v = math.clamp(v, 4, 50)
    _meleeRangeCache.t = now
    _meleeRangeCache.v = v
    _meleeRangeCache.bow = bow
    return v
end
do
    local conn = LocalPlayer.CharacterAdded:Connect(function()
        _meleeRangeCache.t = 0
        _meleeRangeCache.v = 12
        _meleeRangeCache.cls = nil
        _meleeRangeCache.clsR = nil
        _meleeRangeCache.bow = false
    end)
    TheKing.AddConnection(conn)
end

-- ---- 自动喝血: 开关在阈值之上 ----
local potionPct = PREF.potionPct or 50

TheKing.BindToggle(BattleTab, {
    Title = "自动喝血药水",
    Flag = "dr_potion",
    Interval = 0.6,
    OnTick = function()
        local hum = getHum()
        if not hum then
            return
        end
        local hp, maxHp = hum.Health, hum.MaxHealth
        if maxHp <= 0 or hp <= 0 then
            return
        end
        if (hp / maxHp) * 100 >= potionPct then
            return
        end
        local svc = Knit.GetService("PotionService")
        local ok = pcall(function()
            local p = svc:UsePotion(1)
            if p and p.await then
                p:await()
            end
        end)
        if not ok then
            TheKing.Notify({ Title = "自动喝血", Content = "喝药请求失败", Icon = "alert-triangle" })
            TheKing.Backoff(3)
        end
    end,
})

BattleTab:Slider({
    Title = "血量百分比阈值",
    Value = { Min = 5, Max = 95, Default = PREF.potionPct or 50 },
    Step = 5,
    Callback = function(v)
        potionPct = v
        PREF.potionPct = v
        prefSave()
    end,
})

-- ---- 杀戮光环: 开关在范围滑条之上, 360° 锁怪 ----
-- 攻击连击引擎 (照抄客户端 Weapon_Input.hookAttackCadence):
-- 真人持按 = 每击攻击动画播放到内嵌 "DBreset" marker 时自动接下一击 -> 无缝连砍
-- 本引擎 hook Animator.AnimationPlayed("Animation") + GetMarkerReachedSignal("DBreset")
-- 技能要释放时 (skillPending 非空) 自动断链 -> 动画自然停止 -> 空窗内插技能
local ATK_ANIM_NAME = "Animation"
local atkAnim = { isAttacking = false, curTrack = nil, endAt = 0 }
local meleeEnabled = false
local meleeLastAttack = 0
local skillHoldUntil = 0 -- 技能释放时间窗: 期间平A让路
local autoRotateLockUntil = 0 -- 平A锁朝向: 防 WASD 把脸转走
local skillPending = nil -- { slot=, target=, createdAt= } (前向声明, 供 fireMeleeOnce 判断断链)
local skillCursor = 0 -- 公平轮转游标: 每次从上次释放槽的下一个开始找, 保证 3/4 也能轮到
local skillBusyUntil = 0 -- 技能侧节流: 发技能后等服务端动作处理 (长技能动画自动延展)
local skillAuraOn = false -- (前向声明, fireMeleeOnce 技能优先 gate 用)
local skillDumpSlot = nil -- 充能技打空当前槽前不换技能
local skillRestUntil = 0 -- 一段技能打完后给平A接刀的窗口
local skillFreezeMove = false -- 仅位移技 (Dash/升空) 才禁 WalkSpeed; 弓手技能禁走会抽搐
local findReadySkill = nil -- (前向声明, 定义在技能调度区: 返回 {slot,target} 或 nil)
-- 战斗锁定收进一张表, 少占主块 local 寄存器 (Luau 上限 200)
local Cbt = { lock = nil }
function Cbt.alive(en)
    if not (en and en.model and en.model.Parent) then
        return false
    end
    if en.model:GetAttribute("Dead") or en.model:GetAttribute("IsDormant") then
        return false
    end
    if Players:GetPlayerFromCharacter(en.model) then
        return false
    end
    local hrp = en.hrp
    if not (hrp and hrp.Parent) then
        return false
    end
    return true
end
function Cbt.mark(en)
    if en and Cbt.alive(en) then
        Cbt.lock = en
    end
end
function Cbt.pick(range)
    local hrp = getHRP()
    if not (hrp and range and range > 0) then
        return nil
    end
    local pos = hrp.Position
    if Cbt.lock and not Cbt.alive(Cbt.lock) then
        Cbt.lock = nil
        getEnemies(true)
    end
    local look = hrp.CFrame.LookVector
    look = Vector3.new(look.X, 0, look.Z)
    if look.Magnitude > 0.05 then
        look = look.Unit
    else
        look = nil
    end
    -- 粘性: 锁还在射程内、大体朝它、且没有明显更近的才继续; 否则重选, 避免圈在东边刀在西边
    if Cbt.lock then
        local d = (Cbt.lock.hrp.Position - pos).Magnitude
        if d <= range * 1.12 then
            local keep = true
            local toLock = Vector3.new(Cbt.lock.hrp.Position.X - pos.X, 0, Cbt.lock.hrp.Position.Z - pos.Z)
            if look and toLock.Magnitude > 0.4 and look:Dot(toLock.Unit) < 0.22 then
                keep = false
            end
            if keep then
                for _, en in ipairs(getEnemies()) do
                    if Cbt.alive(en) and en.model ~= Cbt.lock.model then
                        local d2 = (en.hrp.Position - pos).Magnitude
                        if d2 <= range and d2 + 3.5 < d then
                            keep = false
                            break
                        end
                    end
                end
            end
            if keep then
                return Cbt.lock
            end
        end
    end
    local best, bestS = nil, 1e9
    for _, en in ipairs(getEnemies()) do
        if Cbt.alive(en) then
            local d = (en.hrp.Position - pos).Magnitude
            if d <= range then
                local s = d
                local hum = en.model:FindFirstChildOfClass("Humanoid")
                local frac = (hum and hum.MaxHealth > 1) and (hum.Health / hum.MaxHealth) or 1
                if frac < 0.32 then
                    s = s - 5
                elseif frac < 0.55 then
                    s = s - 2
                end
                if en.model:GetAttribute("IsBoss") or en.model:GetAttribute("IsMiniBoss") then
                    s = s - 2.2
                end
                if look then
                    local to = Vector3.new(en.hrp.Position.X - pos.X, 0, en.hrp.Position.Z - pos.Z)
                    if to.Magnitude > 0.4 then
                        s = s - look:Dot(to.Unit) * 1.8
                    end
                end
                if Cbt.lock and en.model == Cbt.lock.model then
                    s = s - 4
                end
                if s < bestS then
                    bestS = s
                    best = en
                end
            end
        end
    end
    Cbt.lock = best
    return best
end

local function findMeleeTarget(range)
    return Cbt.pick(range)
end
function Cbt.disc(key, adornee, radius, color, trans, yOff)
    local a = Cbt[key]
    if not (a and a.Parent) then
        a = Instance.new("CylinderHandleAdornment")
        a.Name = "TK_" .. key
        a.AlwaysOnTop = true
        a.ZIndex = 10
        a.Height = 0.12
        a.Parent = Ov.gui
        Cbt[key] = a
    end
    if not (adornee and radius and radius > 0.2) then
        a.Visible = false
        return
    end
    a.Adornee = adornee
    a.Radius = radius
    a.Color3 = color
    a.Transparency = trans or 0.4
    a.CFrame = CFrame.new(0, yOff or -2.45, 0) * CFrame.Angles(math.pi / 2, 0, 0)
    a.Visible = true
end
-- 发一击: 技能优先 + 技能排队/窗口期间停发 (双光环时平A只补技能真空)
local function fireMeleeOnce()
    local hrp = getHRP()
    local hum = getHum()
    if not (hrp and hum) or hum.Health <= 0 then
        return
    end
    local now = os.clock()
    if now - meleeLastAttack < 0.1 then
        return
    end
    local tgt = findMeleeTarget(getMeleeRange())
    if not tgt then
        return
    end
    Cbt.mark(tgt)
    -- 朝向跟锁定对齐, 否则服务端按面前判定会打另一只
    local to = tgt.hrp.Position - hrp.Position
    to = Vector3.new(to.X, 0, to.Z)
    local look = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z)
    if to.Magnitude > 0.4 and (look.Magnitude < 0.05 or look.Unit:Dot(to.Unit) < 0.9) then
        faceTowards(hrp, tgt.hrp.Position)
    end
    TheKing.Fire(AttackRE, Vector3.new(0, 0, 0))
    meleeLastAttack = now
end

local function hookAttackAnim(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local anim = hum and hum:FindFirstChildOfClass("Animator")
    if not anim then
        return
    end
    local conn = anim.AnimationPlayed:Connect(function(track)
        -- 全程 pcall: 动画对象在角色重生/销毁时访问可能抛错, 不外泄刷屏
        pcall(function()
            local an = track.Animation
            local anName = an and an.Name or ""
            local len = (track.Length or 0.7) / math.max(track.Speed, 0.5)
            if anName:match("^Ability_") then
                -- 技能动画不拉长 busy/hold: Stormfire 等多段 Ability_ 会把平A和后续技能锁死
            elseif anName == ATK_ANIM_NAME and track.Speed >= 0.8 then
                atkAnim.isAttacking = true
                atkAnim.curTrack = track
                atkAnim.endAt = os.clock() + 0.15 + len
                local okM, dbr = pcall(function()
                    return track:GetMarkerReachedSignal("DBreset")
                end)
                if okM and dbr then
                    local mConn = dbr:Connect(function()
                        if meleeEnabled then
                            fireMeleeOnce()
                        end
                    end)
                    track.Stopped:Once(function()
                        pcall(function()
                            mConn:Disconnect()
                        end)
                        if atkAnim.curTrack == track then
                            atkAnim.isAttacking = false
                            atkAnim.curTrack = nil
                        end
                    end)
                end
            end
        end)
    end)
    TheKing.AddConnection(conn)
end
do
    local c0 = getChar()
    if c0 then
        hookAttackAnim(c0)
    end
    local connA = LocalPlayer.CharacterAdded:Connect(function(ch)
        hookAttackAnim(ch)
    end)
    TheKing.AddConnection(connA)
end
local function attackAnimBusy()
    local t = atkAnim.curTrack
    if t and t.IsPlaying then
        return true
    end
    atkAnim.isAttacking = false
    atkAnim.curTrack = nil
    return os.clock() < atkAnim.endAt
end

-- ---- 内置 Boss 拼刀: 平A/技能光环任一开启即对 Boss 出招窗点 Parry (全职业同一包) ----
function Cbt.bossIndex()
    local idx = Cbt._bossIdx
    if type(idx) == "table" then
        return idx
    end
    idx = {}
    local mod = ReplicatedStorage:FindFirstChild("GameInfo")
    mod = mod and mod:FindFirstChild("Boss_ActionData")
    if mod then
        local ok, data = pcall(require, mod)
        if ok and type(data) == "table" then
            if type(data.Index) == "table" then
                idx = data.Index
            end
            Cbt._bossResolve = data.Resolve
        end
    end
    Cbt._bossIdx = idx
    return idx
end
function Cbt.bossRow(model)
    if not model then
        return nil
    end
    local id = model:GetAttribute("ItemId") or model.Name
    local idx = Cbt.bossIndex()
    local row = idx[id]
    if not row and type(Cbt._bossResolve) == "function" then
        local ok, r = pcall(Cbt._bossResolve, id)
        if ok and type(r) == "table" then
            row = r
        end
    end
    return row, id
end
function Cbt.isBossModel(model)
    if not model then
        return false
    end
    if model:GetAttribute("IsDormant") then
        return false
    end
    if model:GetAttribute("Dead") then
        return false
    end
    if model:GetAttribute("IsFodder") then
        return false
    end
    if model:GetAttribute("IsBoss") or model:GetAttribute("IsMiniBoss") then
        return true
    end
    local row = Cbt.bossRow(model)
    return row ~= nil
end
function Cbt.parrySkipAnim(name)
    if type(name) ~= "string" or name == "" then
        return true
    end
    local l = string.lower(name)
    if string.find(l, "unblock", 1, true) then
        return true
    end
    if string.find(l, "parry", 1, true) or string.find(l, "block", 1, true) then
        return true
    end
    if string.find(l, "idle", 1, true) or string.find(l, "walk", 1, true) or string.find(l, "run", 1, true) then
        return true
    end
    if string.find(l, "stun", 1, true) or string.find(l, "hit_reaction", 1, true) or string.find(l, "death", 1, true) then
        return true
    end
    if string.find(l, "jump", 1, true) or string.find(l, "spawn", 1, true) or string.find(l, "emote", 1, true) then
        return true
    end
    return false
end
function Cbt.parryWantAnim(name)
    if Cbt.parrySkipAnim(name) then
        return false
    end
    if name == "Animation" or string.sub(name, 1, 7) == "Attack_" or string.sub(name, 1, 8) == "Ability_" then
        return true
    end
    local l = string.lower(name)
    if string.find(l, "slash", 1, true) or string.find(l, "swing", 1, true) or string.find(l, "combo", 1, true) then
        return true
    end
    if string.find(l, "string", 1, true) or string.find(l, "smash", 1, true) or string.find(l, "cleave", 1, true) then
        return true
    end
    return false
end
function Cbt.parryDelay(row, animName)
    local w = tonumber(row and row.WindUpDuration) or 0.22
    local spd = tonumber(row and row.CombatSpeed) or 1
    if type(animName) == "string" and row and type(row.Abilities) == "table" then
        for _, ab in ipairs(row.Abilities) do
            if type(ab) == "table" then
                local an = ab.AnimName
                if type(an) == "string" and an ~= "" and string.find(animName, an, 1, true) then
                    w = tonumber(ab.TelegraphDuration) or w
                    break
                end
            end
        end
    end
    return math.clamp(w / math.max(spd, 0.45) - 0.08, 0, 0.55)
end
function Cbt.bossCanReach(model, row)
    local hrp = getHRP()
    local bhrp = model and (model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart)
    if not (hrp and bhrp) then
        return false
    end
    local dist = (hrp.Position - bhrp.Position).Magnitude
    local reach = tonumber(row and row.DefaultRange) or 24
    local bs = row and row.BasicString
    if type(bs) == "table" then
        reach = math.max(reach, tonumber(bs.HitboxRange) or 0)
    end
    if dist > reach + 8 then
        return false
    end
    if dist <= 9 then
        return true
    end
    local look = Vector3.new(bhrp.CFrame.LookVector.X, 0, bhrp.CFrame.LookVector.Z)
    local to = Vector3.new(hrp.Position.X - bhrp.Position.X, 0, hrp.Position.Z - bhrp.Position.Z)
    if look.Magnitude < 0.05 or to.Magnitude < 0.05 then
        return true
    end
    return look.Unit:Dot(to.Unit) > 0.12
end
function Cbt.fireParry()
    if not hubAlive or not (meleeEnabled or skillAuraOn) then
        return
    end
    if LocalPlayer:GetAttribute("Dead") then
        return
    end
    if LocalPlayer:GetAttribute("Parry_Cooldown_Active") or LocalPlayer:GetAttribute("NoParrying") then
        return
    end
    local now = os.clock()
    if Cbt._parryAt and (now - Cbt._parryAt) < 1.7 then
        return
    end
    Cbt._parryAt = now
    TheKing.Guard(function()
        TheKing.Fire(ParryRE)
    end, "Boss拼刀")
end
function Cbt.scheduleParry(delay)
    delay = tonumber(delay) or 0
    if delay <= 0 then
        Cbt.fireParry()
        return
    end
    local token = (Cbt._parryTok or 0) + 1
    Cbt._parryTok = token
    task.delay(delay, function()
        if hubAlive and Cbt._parryTok == token then
            Cbt.fireParry()
        end
    end)
end
function Cbt.unhookBossParry()
    local bag = Cbt._parryConns
    if type(bag) == "table" then
        for _, c in ipairs(bag) do
            pcall(function()
                c:Disconnect()
            end)
        end
    end
    Cbt._parryConns = {}
    Cbt._parryHooked = {}
    TheKing.UnbindStepped("dr_boss_parry")
end
function Cbt.hookBossParry(model)
    if not (model and model.Parent) then
        return
    end
    local hooked = Cbt._parryHooked
    if type(hooked) ~= "table" then
        hooked = {}
        Cbt._parryHooked = hooked
    end
    if hooked[model] then
        return
    end
    hooked[model] = true
    local bag = Cbt._parryConns
    if type(bag) ~= "table" then
        bag = {}
        Cbt._parryConns = bag
    end
    local function onAnim(track)
        pcall(function()
            if not hubAlive or not (meleeEnabled or skillAuraOn) then
                return
            end
            if not Cbt.isBossModel(model) then
                return
            end
            local an = track.Animation
            local anName = an and an.Name or ""
            if not Cbt.parryWantAnim(anName) then
                return
            end
            local row = Cbt.bossRow(model)
            if not Cbt.bossCanReach(model, row) then
                return
            end
            Cbt.scheduleParry(Cbt.parryDelay(row, anName))
            local function hitNow()
                Cbt._parryTok = (Cbt._parryTok or 0) + 1
                Cbt.fireParry()
            end
            pcall(function()
                bag[#bag + 1] = track:GetMarkerReachedSignal("Hit"):Connect(hitNow)
            end)
            pcall(function()
                bag[#bag + 1] = track:GetMarkerReachedSignal("Swing"):Connect(hitNow)
            end)
        end)
    end
    local anim = model:FindFirstChildWhichIsA("Animator", true)
    if anim then
        bag[#bag + 1] = anim.AnimationPlayed:Connect(onAnim)
        TheKing.AddConnection(bag[#bag])
    end
    local function onPart(ch)
        if ch and (ch.Name == "Hitbox" or ch.Name == "Hurtbox") then
            local row = Cbt.bossRow(model)
            if Cbt.bossCanReach(model, row) then
                Cbt._parryTok = (Cbt._parryTok or 0) + 1
                Cbt.fireParry()
            end
        end
    end
    bag[#bag + 1] = model.DescendantAdded:Connect(onPart)
    TheKing.AddConnection(bag[#bag])
end
function Cbt.syncBossParry()
    if not hubAlive or not (meleeEnabled or skillAuraOn) then
        Cbt.unhookBossParry()
        return
    end
    Cbt.bossIndex()
    TheKing.BindStepped("dr_boss_parry", "heartbeat", function()
        if not hubAlive or not (meleeEnabled or skillAuraOn) then
            return
        end
        local now = os.clock()
        if Cbt._parryScanAt and (now - Cbt._parryScanAt) < 0.22 then
            return
        end
        Cbt._parryScanAt = now
        for _, en in ipairs(getEnemies()) do
            if en.model and Cbt.isBossModel(en.model) then
                Cbt.hookBossParry(en.model)
            end
        end
    end)
end

TheKing.BindToggle(BattleTab, {
    Title = "杀戮光环 (自动平A)",
    Flag = "dr_melee_aura",
    Interval = 0.1,
    OnEnable = function()
        meleeEnabled = true
        Cbt.syncBossParry()
        return true
    end,
    OnDisable = function()
        meleeEnabled = false
        autoRotateLockUntil = 0
        if not skillAuraOn then
            Cbt.lock = nil
        end
        Cbt.syncBossParry()
        local hum = getHum()
        if hum then
            pcall(function()
                hum.AutoRotate = true
            end)
        end
    end,
    OnTick = function()
        -- AutoRotate 管理: 攻击动画锁定期禁止移动自动转向 (射击/挥砍方向锁定怪), 到期恢复
        local now = os.clock()
        local hum = getHum()
        if hum then
            -- 攻击停止超过 0.25s 且目标已清 -> 提前解锁脸, 不等锁定窗口自然过期
            if now - meleeLastAttack > 0.25 and now < autoRotateLockUntil then
                if not findMeleeTarget(getMeleeRange()) then
                    autoRotateLockUntil = 0
                end
            end
            local want = (now < autoRotateLockUntil) and false or true
            if hum.AutoRotate ~= want then
                pcall(function()
                    hum.AutoRotate = want
                end)
            end
        end
        -- 长按连击: 与真人按住左键一致, 每 0.1s 持续尝试攻击
        -- 服务端按攻速自动裁决实际挥击节律; 技能让路由 fireMeleeOnce 内部窗口保证
        if now - meleeLastAttack >= 0.1 then
            fireMeleeOnce()
        end
    end,
})

-- ---- 杀戮技能光环: 开关在职业选择之上 ----
-- 默认职业: 当前游戏职业 > 上次菜单
local classIdx = 1
do
    local curCls = LocalPlayer:GetAttribute("Current_Class") or LocalPlayer:GetAttribute("Active_Class")
    local matched = false
    if type(curCls) == "string" and curCls ~= "" then
        for i, cp in ipairs(CLASS_PROFILES) do
            if cp.Folder == curCls then
                classIdx = i
                matched = true
                break
            end
        end
    end
    if not matched then
        local saved = PREF.classLabel
        if type(saved) == "string" and saved ~= "" then
            for i, cp in ipairs(CLASS_PROFILES) do
                if cp.Label == saved or cp.Folder == saved or cp.Name == saved
                    or (cp.Folder and string.find(saved, cp.Folder, 1, true))
                    or (cp.Name and string.find(saved, cp.Name, 1, true)) then
                    classIdx = i
                    break
                end
            end
        end
    end
end
function Cbt.syncClass()
    local cur = LocalPlayer:GetAttribute("Current_Class") or LocalPlayer:GetAttribute("Active_Class")
    if type(cur) ~= "string" or cur == "" then
        return
    end
    local now = CLASS_PROFILES[classIdx]
    if now and now.Folder == cur then
        return
    end
    for i, cp in ipairs(CLASS_PROFILES) do
        if cp.Folder == cur then
            classIdx = i
            _skillCache.folder = nil
            _skillCache.data = nil
            _meleeRangeCache.t = 0
            prefSet("classLabel", cp.Label)
            local drop = Cbt.classDrop
            if drop then
                pcall(function()
                    if drop.SetValue then
                        drop:SetValue(cp.Label)
                    elseif drop.Set then
                        drop:Set(cp.Label)
                    end
                end)
            end
            TheKing.Notify({ Title = "职业", Content = "已跟角色切换为 " .. tostring(cp.Label), Icon = "user" })
            return
        end
    end
end
do
    TheKing.AddConnection(LocalPlayer:GetAttributeChangedSignal("Current_Class"):Connect(function()
        Cbt.syncClass()
    end))
end

local classLabels = {}
for _, cp in ipairs(CLASS_PROFILES) do
    classLabels[#classLabels + 1] = cp.Label
end

local skillAuraLastSlot = nil
local lastSkillCast = {}
local skillsData = nil
-- fireQueuedSkill 使用前向声明的 skillPending/skillCursor/skillAuraOn (592 区声明, 此处勿重复 local)
local function fireQueuedSkill(pd, now)
    local hrp = getHRP()
    if not hrp then
        return
    end
    local tg = pd.target
    if tg and tg.hrp and tg.hrp.Parent then
        Cbt.mark(tg)
        faceTowards(hrp, tg.hrp.Position)
    end
    local cp = CLASS_PROFILES[classIdx]
    local skills = cp and cachedClassSkills(cp.Folder)
    local data = skills and skills[pd.slot]
    TheKing.Fire(SkillRE, pd.slot, "tap", Vector3.new(0, 0, 0))
    lastSkillCast[pd.slot] = now
    skillAuraLastSlot = pd.slot
    if pd.slot == 3 or pd.slot == 4 then
        _meleeRangeCache.t = 0
    end
    skillFreezeMove = skillIsMobile(data)
    skillHoldUntil = now + 0.08
    skillDumpSlot = nil
    skillBusyUntil = now + 0.14
    skillRestUntil = 0
end

local function skillSlotReady(slot, data, now)
    local c = tonumber(LocalPlayer:GetAttribute("Skill" .. slot .. "_Charges"))
    if c ~= nil and c <= 0 then
        return false
    end
    local onCd = LocalPlayer:GetAttribute("Skill" .. slot .. "_OnCooldown")
    -- 有剩余充能就继续丢, 不等 OnCooldown; 没充能字段时才看 CD
    if onCd == true and not (c ~= nil and c > 0) then
        return false
    end
    return (now - (lastSkillCast[slot] or 0)) >= 0.12
end

local function skillSlotTarget(data, pos)
    local range = skillRange(data) + 8
    local best, bd = nil, range
    for _, en in ipairs(getEnemies()) do
        if Cbt.alive(en) then
            local d = (en.hrp.Position - pos).Magnitude
            if d <= range and d < bd then
                bd = d
                best = en
            end
        end
    end
    return best
end

-- 冷却好了就丢: 1→4 优先, 有充能打光, 不留手
findReadySkill = function(now)
    local cp = CLASS_PROFILES[classIdx]
    local skills = cp and cachedClassSkills(cp.Folder)
    skillsData = skills
    if not skills then
        return nil
    end
    local hrp = getHRP()
    if not hrp then
        return nil
    end
    local pos = hrp.Position
    local function trySlot(slot)
        local data = skills[slot]
        if not data or not skillSlotReady(slot, data, now) then
            return nil
        end
        local reach = skillRange(data) + 8
        if Cbt.lock and Cbt.alive(Cbt.lock) then
            local d = (Cbt.lock.hrp.Position - pos).Magnitude
            if d <= reach then
                return { slot = slot, target = Cbt.lock }
            end
        end
        local best = skillSlotTarget(data, pos)
        if best then
            Cbt.lock = best
            return { slot = slot, target = best }
        end
        return nil
    end
    for slot = 1, 4 do
        local hit = trySlot(slot)
        if hit then
            return hit
        end
    end
    return nil
end

TheKing.BindToggle(BattleTab, {
    Title = "杀戮技能光环 (自动放技能)",
    Flag = "dr_skill_aura",
    Interval = 0.05,
    OnEnable = function()
        local cp = CLASS_PROFILES[classIdx]
        if not (cp and cachedClassSkills(cp.Folder)) then
            TheKing.Notify({ Title = "技能光环", Content = "技能数据读取失败, 请确认职业档案存在", Icon = "alert-triangle" })
            return false
        end
        skillAuraOn = true
        skillAuraLastSlot = nil
        skillPending = nil
        skillBusyUntil = 0
        skillDumpSlot = nil
        skillRestUntil = 0
        skillFreezeMove = false
        if not meleeEnabled then
            Cbt.lock = nil
        end
        Cbt.syncBossParry()
        return true
    end,
    OnDisable = function()
        skillAuraOn = false
        skillAuraLastSlot = nil
        skillPending = nil
        skillBusyUntil = 0
        skillDumpSlot = nil
        skillRestUntil = 0
        skillFreezeMove = false
        if not meleeEnabled then
            Cbt.lock = nil
        end
        Cbt.syncBossParry()
    end,
    OnTick = function()
        Cbt.syncClass()
        local hrp = getHRP()
        local hum = getHum()
        if not (hrp and hum) or hum.Health <= 0 then
            skillPending = nil
            return
        end
        local now = os.clock()
        -- 服务端动作节流: 发技能后等 0.55s (长技能动画由 hook 自动延展); 期间不发起新技能
        if now < skillBusyUntil then
            -- 位移技才持续扭脸; 弓手每 tick 改 CFrame 会抽搐
            if skillFreezeMove then
                local tgt = (Cbt.lock and Cbt.alive(Cbt.lock)) and Cbt.lock or findMeleeTarget(getMeleeRange() + 8)
                if tgt then
                    faceTowards(hrp, tgt.hrp.Position)
                end
            end
            return
        end
        skillFreezeMove = false
        skillPending = nil
        local res = findReadySkill(now)
        if not res then
            return
        end
        skillCursor = res.slot
        faceTowards(hrp, res.target.hrp.Position)
        fireQueuedSkill({ slot = res.slot, target = res.target }, now)
    end,
})

Cbt.classDrop = BattleTab:Dropdown({
    Title = "职业 (自动跟角色)",
    Values = classLabels,
    Value = classLabels[classIdx],
    Flag = "dr_class_profile",
    Callback = function(sel)
        for i, cp in ipairs(CLASS_PROFILES) do
            if cp.Label == sel then
                classIdx = i
                prefSet("classLabel", sel)
                break
            end
        end
        Cbt.syncClass()
    end,
})

-- ============================================================
-- 自动选择 BUFF (祭坛 Blessing_Altar 三选一: 玩家多选偏好, 命中自动选, 多命中按强度择优)
-- ============================================================
local BUFF_LIST = {
    { id = "dmg_up", label = "伤害提升" },
    { id = "move_up", label = "移速提升" },
    { id = "hp_up", label = "生命提升" },
    { id = "kill_xp", label = "击杀经验" },
    { id = "clear_xp", label = "通关经验" },
    { id = "coins", label = "金币" },
    { id = "skill_dmg", label = "技能伤害" },
    { id = "crit_rate", label = "暴击率" },
    { id = "skill_crit_rate", label = "技能暴击率" },
    { id = "skill_crit_dmg", label = "技能爆伤" },
    { id = "dmg_reduction", label = "减伤" },
    { id = "parry_window", label = "格挡窗口" },
    { id = "dodge_cd", label = "闪避冷却" },
    { id = "skill_cd", label = "技能冷却" },
}
-- 多个命中时的强度优先级 (输出 > 防御 > 经验/金币)
local BUFF_PICK_SCORE = {
    dmg_up = 100, skill_dmg = 96, skill_crit_dmg = 92, crit_rate = 88,
    skill_crit_rate = 84, skill_cd = 80, dmg_reduction = 74, hp_up = 68,
    move_up = 60, dodge_cd = 55, parry_window = 50, kill_xp = 40,
    clear_xp = 30, coins = 10,
}
function Cbt.findBlessPrompt()
    local hrp = getHRP()
    if not hrp then
        return nil
    end
    local used = Cbt.blessUsed
    if type(used) ~= "table" then
        used = {}
        Cbt.blessUsed = used
    end
    local best, bestD = nil, 1e9
    local pos = hrp.Position
    for _, c in ipairs(workspace:GetChildren()) do
        if type(c.Name) == "string" and string.sub(c.Name, 1, 10) == "Generated_" then
            for _, d in ipairs(c:GetDescendants()) do
                if d:IsA("ProximityPrompt") and d.Enabled and d.Parent and not used[d] then
                    if d.ActionText == "Receive Blessing" then
                        local part = d:FindFirstAncestorWhichIsA("BasePart")
                        local ppos = part and part.Position
                        if ppos then
                            local dist = (pos - ppos).Magnitude
                            local maxd = (tonumber(d.MaxActivationDistance) or 10) + 1.5
                            if dist <= maxd and dist < bestD then
                                bestD = dist
                                best = d
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end
function Cbt.tryOpenAltar()
    if not hubAlive then
        return
    end
    local prompt = Cbt.findBlessPrompt()
    if not prompt then
        return
    end
    local now = os.clock()
    if prompt == Cbt.blessLast and Cbt.blessFireAt and (now - Cbt.blessFireAt) < 1.1 then
        return
    end
    Cbt.blessLast = prompt
    Cbt.blessFireAt = now
    if type(fireproximityprompt) == "function" then
        pcall(fireproximityprompt, prompt)
        return
    end
    pcall(function()
        prompt:InputHoldBegin()
        task.delay(math.max(0.08, prompt.HoldDuration or 0.25), function()
            pcall(function()
                prompt:InputHoldEnd()
            end)
        end)
    end)
end
local autoBuffOn = false
local autoBuffFiredAt = nil
local buffPrefsById = {}
local _boostCtrlCache = nil
local function boostCtrl()
    if _boostCtrlCache then
        return _boostCtrlCache
    end
    local client = LocalPlayer:FindFirstChild("PlayerScripts") and LocalPlayer.PlayerScripts:FindFirstChild("Client")
    local mod = client and client:FindFirstChild("Controllers") and client.Controllers:FindFirstChild("BoostSelectionController")
    if mod then
        local ok, c = pcall(require, mod)
        if ok and type(c) == "table" then
            _boostCtrlCache = c
        end
    end
    return _boostCtrlCache
end

TheKing.BindToggle(BattleTab, {
    Title = "自动选择 BUFF (祭坛)",
    Flag = "dr_auto_buff",
    Interval = 0.25,
    OnEnable = function()
        autoBuffOn = true
        return true
    end,
    OnDisable = function()
        autoBuffOn = false
        Cbt.blessLast = nil
    end,
    OnTick = function()
        if not hubAlive then
            return
        end
        local ctrl = boostCtrl()
        local uiOn = ctrl and ctrl._active == true
        if Cbt.blessWasUi and not uiOn then
            autoBuffFiredAt = nil
            Cbt.blessPickSig = nil
            if Cbt.blessLast then
                local used = Cbt.blessUsed
                if type(used) ~= "table" then
                    used = {}
                    Cbt.blessUsed = used
                end
                used[Cbt.blessLast] = true
                Cbt.blessLast = nil
            end
        end
        if uiOn then
            Cbt.blessUiAt = Cbt.blessUiAt or os.clock()
            if os.clock() - Cbt.blessUiAt > 18 then
                uiOn = false
                Cbt.blessUiAt = nil
            end
        else
            Cbt.blessUiAt = nil
        end
        Cbt.blessWasUi = uiOn
        if not uiOn then
            Cbt.tryOpenAltar()
            return
        end
        if not (ctrl._ready and not ctrl._selecting) then
            return
        end
        local cands = ctrl._candidates
        if not cands or #cands == 0 then
            return
        end
        local bestIdx, bestScore = nil, -1
        for i, cand in ipairs(cands) do
            if buffPrefsById[cand.Id] then
                local s = BUFF_PICK_SCORE[cand.Id] or 1
                if s > bestScore then
                    bestScore = s
                    bestIdx = i
                end
            end
        end
        if not bestIdx then
            return
        end
        local sig = tostring(#cands)
        for i, cand in ipairs(cands) do
            sig = sig .. "|" .. tostring(cand.Id)
        end
        if Cbt.blessPickSig == sig then
            return
        end
        Cbt.blessPickSig = sig
        autoBuffFiredAt = os.clock()
        task.delay(0.9, function()
            if not hubAlive then
                return
            end
            pcall(function()
                if ctrl._active and ctrl._ready and not ctrl._selecting then
                    ctrl:_OnCardClicked(bestIdx)
                end
            end)
        end)
    end,
})
-- 偏好 BUFF: 自绘紧凑网格多选 (绕开 Rayfield 多选下拉弹层 — 该组件在本游戏+Potassium 下渲染必崩)
-- 纯 Instance 操作 (与范围圈/宝箱文字同路线), 零崩溃面; 选中态存 buffPrefsById
do
    local page = BattleTab:RawPage()
    if page then
        local function nextOrder()
            local mx = 0
            for _, c in ipairs(page:GetChildren()) do
                if c:IsA("GuiObject") then
                    mx = math.max(mx, c.LayoutOrder)
                end
            end
            return mx + 1
        end
        local cap = Instance.new("TextLabel")
        cap.BackgroundTransparency = 1
        cap.BorderSizePixel = 0
        cap.Font = Enum.Font.GothamBold
        cap.Text = "偏好 BUFF (点选, 可多选; 命中自动选最高分)"
        cap.TextColor3 = Color3.fromRGB(172, 178, 190)
        cap.TextSize = 13
        cap.TextXAlignment = Enum.TextXAlignment.Left
        cap.Size = UDim2.new(1, -24, 0, 20)
        cap.LayoutOrder = nextOrder()
        cap.Parent = page

        local holder = Instance.new("Frame")
        holder.BackgroundTransparency = 1
        holder.BorderSizePixel = 0
        holder.Size = UDim2.new(1, -24, 0, 0)
        holder.AutomaticSize = Enum.AutomaticSize.Y
        holder.LayoutOrder = nextOrder()
        holder.Parent = page

        local grid = Instance.new("UIGridLayout")
        grid.CellPadding = UDim2.fromOffset(6, 6)
        grid.CellSize = UDim2.fromOffset(138, 32)
        grid.SortOrder = Enum.SortOrder.LayoutOrder
        grid.Parent = holder

        local COLOR_BG = Color3.fromRGB(33, 38, 48)
        local COLOR_OFF = Color3.fromRGB(206, 212, 222)
        local COLOR_ON_BG = Color3.fromRGB(76, 124, 255)
        local COLOR_ON = Color3.new(1, 1, 1)

        local buffBtns = {}
        -- 恢复上次偏好选择 (自建持久化 dr-prefs.txt)
        if type(PREF.buffs) == "string" and PREF.buffs ~= "" then
            for id in (PREF.buffs .. ","):gmatch("([^,]+),") do
                if id ~= "" then
                    buffPrefsById[id] = true
                end
            end
        end
        local function syncGridWidth()
            local w = holder.AbsoluteSize.X
            if w > 40 then
                local cols = 4
                local cell = math.floor((w - 6 * (cols - 1)) / cols)
                grid.CellSize = UDim2.fromOffset(math.max(cell, 60), 32)
            end
        end
        holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(syncGridWidth)
        task.delay(0.6, syncGridWidth)

        local function paint(btn, on)
            if on then
                btn.BackgroundColor3 = COLOR_ON_BG
                btn.TextColor3 = COLOR_ON
                btn.BorderSizePixel = 0
            else
                btn.BackgroundColor3 = COLOR_BG
                btn.TextColor3 = COLOR_OFF
                btn.BorderSizePixel = 0
            end
        end
        for i, b in ipairs(BUFF_LIST) do
            local btn = Instance.new("TextButton")
            btn.BackgroundColor3 = COLOR_BG
            btn.BorderSizePixel = 0
            btn.Font = Enum.Font.GothamMedium
            btn.Text = b.label
            btn.TextSize = 13
            btn.TextColor3 = COLOR_OFF
            btn.AutoButtonColor = false
            btn.LayoutOrder = i
            btn.Parent = holder
            local hovered = false
            btn.MouseEnter:Connect(function()
                hovered = true
                if not buffPrefsById[b.id] then
                    btn.BackgroundColor3 = COLOR_BG:lerp(Color3.new(1, 1, 1), 0.08)
                end
            end)
            btn.MouseLeave:Connect(function()
                hovered = false
                paint(btn, buffPrefsById[b.id] == true)
            end)
            btn.Activated:Connect(function()
                if buffPrefsById[b.id] then
                    buffPrefsById[b.id] = nil
                else
                    buffPrefsById[b.id] = true
                end
                paint(btn, buffPrefsById[b.id] == true)
                -- 持久化: 序列化 id 列表写入 PREF + 防抖保存
                local ids = {}
                for id in pairs(buffPrefsById) do
                    ids[#ids + 1] = id
                end
                PREF.buffs = table.concat(ids, ",")
                prefSave()
            end)
            paint(btn, buffPrefsById[b.id] == true)
            buffBtns[#buffBtns + 1] = btn
        end
        TheKing.OnCleanup(function()
            for _, btn in ipairs(buffBtns) do
                pcall(function()
                    btn:Destroy()
                end)
            end
            pcall(function()
                cap:Destroy()
            end)
            pcall(function()
                holder:Destroy()
            end)
        end)
    else
        warn("[RCWTK] RawPage nil, 偏好网格不可用")
    end
end

-- ============================================================
-- 自动选择结算宝箱 (Boss/关卡结算宝箱选择: 自动挑稀有度最高的填满槽位并确认)
-- ============================================================
local autoChestOn = false
local _chestCtrlCache = nil
local _rarityIdxCache = nil
local function chestCtrl()
    if _chestCtrlCache then
        return _chestCtrlCache
    end
    local client = LocalPlayer:FindFirstChild("PlayerScripts") and LocalPlayer.PlayerScripts:FindFirstChild("Client")
    local mod = client and client:FindFirstChild("Controllers") and client.Controllers:FindFirstChild("ChestSelectionController")
    if mod then
        local ok, c = pcall(require, mod)
        if ok and type(c) == "table" then
            _chestCtrlCache = c
        end
    end
    return _chestCtrlCache
end
local function rarityIndex()
    if _rarityIdxCache then
        return _rarityIdxCache
    end
    _rarityIdxCache = {}
    local rd = game.ReplicatedStorage:FindFirstChild("GameInfo") and game.ReplicatedStorage.GameInfo:FindFirstChild("RarityData")
    if rd then
        local ok, t = pcall(require, rd)
        if ok and type(t) == "table" and type(t.RarityIndex) == "table" then
            _rarityIdxCache = t.RarityIndex
        end
    end
    return _rarityIdxCache
end

TheKing.BindToggle(BattleTab, {
    Title = "自动选择结算宝箱",
    Flag = "dr_auto_chest",
    Interval = 0.4,
    OnEnable = function()
        autoChestOn = true
        return true
    end,
    OnDisable = function()
        autoChestOn = false
    end,
    OnTick = function()
        local ctrl = chestCtrl()
        if not ctrl then
            return
        end
        -- 结算宝箱界面未激活或入场动画未完
        if not (ctrl._active and ctrl._ready) then
            return
        end
        -- 玩家已手动选过 (或本轮已处理) -> 不干预
        if (ctrl._selectedCount or 0) > 0 then
            return
        end
        local cands = ctrl._candidates
        if not cands or #cands == 0 then
            return
        end
        -- 按稀有度倒序 (Epic > Rare > Uncommon...)
        local idx = rarityIndex()
        local ranked = {}
        for i, cand in ipairs(cands) do
            ranked[#ranked + 1] = { i = i, r = tonumber(idx[cand.Rarity]) or 99 }
        end
        table.sort(ranked, function(a, b)
            return a.r > b.r
        end)
        local maxPick = ctrl._maxPicks or 2
        local picks = {}
        for n = 1, math.min(maxPick, #ranked) do
            picks[#picks + 1] = ranked[n].i
        end
        -- 逐个模拟点选 (间隔 0.35s 播入场动画) 后自动确认
        for n, pi in ipairs(picks) do
            task.delay((n - 1) * 0.35, function()
                pcall(function()
                    ctrl:_OnChestClicked(pi)
                end)
            end)
        end
        task.delay(#picks * 0.35 + 0.4, function()
            pcall(function()
                if ctrl._active and (ctrl._selectedCount or 0) >= maxPick then
                    ctrl:_OnFinish()
                end
            end)
        end)
    end,
})

-- ============================================================
-- 自动补充药水 (炼药锅 Potion_Station: 靠近 Refill Potions 自动交互)
-- ============================================================
function Cbt.findRefillPrompt()
    local hrp = getHRP()
    if not hrp then
        return nil
    end
    local now = os.clock()
    local list = Cbt._refillPrompts
    if type(list) ~= "table" or (now - (Cbt._refillScanAt or 0)) > 1.6 then
        list = {}
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("ProximityPrompt") then
                if d.ActionText == "Refill Potions" or d.ObjectText == "Potion Station" then
                    list[#list + 1] = d
                end
            end
        end
        Cbt._refillPrompts = list
        Cbt._refillScanAt = now
    end
    local best, bestD = nil, 1e9
    local pos = hrp.Position
    for _, d in ipairs(list) do
        if d.Parent and d:IsA("ProximityPrompt") and d.Enabled then
            local part = d:FindFirstAncestorWhichIsA("BasePart")
            local ppos = part and part.Position
            if ppos then
                local dist = (pos - ppos).Magnitude
                local maxd = (tonumber(d.MaxActivationDistance) or 10) + 1.5
                if dist <= maxd and dist < bestD then
                    bestD = dist
                    best = d
                end
            end
        end
    end
    return best
end
function Cbt.tryRefillPotions()
    if not hubAlive then
        return
    end
    local prompt = Cbt.findRefillPrompt()
    if not prompt then
        return
    end
    local now = os.clock()
    if prompt == Cbt.refillLast and Cbt.refillFireAt and (now - Cbt.refillFireAt) < 1.1 then
        return
    end
    Cbt.refillLast = prompt
    Cbt.refillFireAt = now
    if type(fireproximityprompt) == "function" then
        pcall(fireproximityprompt, prompt)
        return
    end
    pcall(function()
        prompt:InputHoldBegin()
        task.delay(math.max(0.08, prompt.HoldDuration or 0.25), function()
            pcall(function()
                prompt:InputHoldEnd()
            end)
        end)
    end)
end

TheKing.BindToggle(BattleTab, {
    Title = "自动补充药水",
    Flag = "dr_auto_refill",
    Interval = 0.3,
    OnDisable = function()
        Cbt.refillLast = nil
        Cbt._refillPrompts = nil
    end,
    OnTick = function()
        if not hubAlive then
            return
        end
        Cbt.tryRefillPotions()
    end,
})

-- ============================================================
-- Tab: 移动
-- ============================================================
local MoveTab = TheKing.NewTab({ Title = "移动", Icon = "person-standing" })

TheKing.BindToggle(MoveTab, {
    Title = "自动奔跑",
    Flag = "dr_autosprint",
    Interval = 0.5,
    OnTick = function()
        local hum = getHum()
        if not hum or hum.Health <= 0 then
            return
        end
        local moving = hum.MoveDirection.Magnitude > 0.1
        local sprinting = LocalPlayer:GetAttribute("Sprint_Active") == true
        if moving and not sprinting then
            TheKing.Fire(SprintRE, "start")
        elseif not moving and sprinting then
            TheKing.Fire(SprintRE, "stop")
        end
    end,
})

local targetSpeed = tonumber(PREF.speedVal) or 35
local speedEnabled = false
function Cbt.wsTick()
    if not hubAlive then
        return
    end
    local hum = getHum()
    if not hum then
        return
    end
    if Cbt._wsApplying then
        return
    end
    local now = os.clock()
    local want = nil
    if now < skillBusyUntil and skillFreezeMove then
        want = 0
    else
        if now >= skillBusyUntil then
            skillFreezeMove = false
        end
        if speedEnabled then
            want = tonumber(targetSpeed) or 35
        end
    end
    if want == nil then
        return
    end
    if math.abs(hum.WalkSpeed - want) > 0.05 then
        Cbt._wsApplying = true
        hum.WalkSpeed = want
        Cbt._wsApplying = false
    end
end
function Cbt.hookWsHum()
    local hum = getHum()
    if not hum or Cbt._wsHum == hum then
        return
    end
    Cbt._wsHum = hum
    if Cbt._wsConn then
        pcall(function()
            Cbt._wsConn:Disconnect()
        end)
    end
    Cbt._wsConn = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        Cbt.wsTick()
    end)
    TheKing.AddConnection(Cbt._wsConn)
end
TheKing.BindToggle(MoveTab, {
    Title = "移速修改",
    Flag = "dr_speed",
    Interval = 999,
    OnEnable = function()
        speedEnabled = true
        Cbt.hookWsHum()
        Cbt.wsTick()
        return true
    end,
    OnDisable = function()
        speedEnabled = false
    end,
})
MoveTab:Slider({
    Title = "移速目标值",
    Value = { Min = 10, Max = 120, Default = tonumber(PREF.speedVal) or 35 },
    Step = 1,
    Callback = function(v)
        local n = tonumber(v)
        if not n then
            return
        end
        targetSpeed = math.clamp(n, 10, 120)
        PREF.speedVal = targetSpeed
        prefSave()
        if speedEnabled then
            Cbt.wsTick()
        end
    end,
})
TheKing.AddConnection(RunService.Heartbeat:Connect(function()
    if not hubAlive then
        return
    end
    Cbt.hookWsHum()
    Cbt.wsTick()
end))

-- ============================================================
-- Tab: 视觉
-- ============================================================
local VisualTab = TheKing.NewTab({ Title = "视觉", Icon = "eye" })

-- 假名开关被 DPS 面板提前引用, 声明提前; 实现仍在本 Tab 后段
local fakeNameOn = false
local FAKE_NAME = "theKing User"

-- ---- DPS 面板 (黑底圆角 + 流动白边, 标题拖动, 4 槽) ----
local UserInputService = game:GetService("UserInputService")
local dpsGui = nil
local dpsRoot = nil
local dpsStrokeGrad = nil
local dpsRows = {}
local dpsMeta = {} -- userId -> { t0=, last= }
local dpsDragging = false
local dpsDragMouse0 = Vector2.new(0, 0)
local dpsDragOrigin = Vector2.new(0, 0)
local dpsTitleBar = nil
local dpsWasRun = nil
local DPS_W, DPS_TITLE_H, DPS_ROW_H = 268, 40, 62
local DPS_H = DPS_TITLE_H + DPS_ROW_H * 4 + 10

local function dpsFmt(n)
    n = tonumber(n) or 0
    if n >= 1000000 then
        return string.format("%.1fM", n / 1000000)
    end
    if n >= 10000 then
        return string.format("%.1fK", n / 1000)
    end
    return tostring(math.floor(n + 0.5))
end
local function dpsHpColor(p)
    if p >= 0.6 then
        return Color3.fromRGB(72, 214, 118)
    elseif p >= 0.3 then
        return Color3.fromRGB(232, 196, 64)
    end
    return Color3.fromRGB(232, 72, 72)
end
local function dpsCorner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = parent
    return c
end
local function dpsViewSize()
    local cam = workspace.CurrentCamera
    local vs = cam and cam.ViewportSize
    if vs and vs.X >= 200 and vs.Y >= 200 then
        return vs
    end
    return nil
end
local function dpsClampPos(x, y)
    local vs = dpsViewSize()
    if not vs then
        return x, y
    end
    x = math.clamp(x, 8, math.max(8, vs.X - DPS_W - 8))
    y = math.clamp(y, 8, math.max(8, vs.Y - DPS_H - 8))
    return x, y
end
local function dpsApplyPos(x, y)
    x, y = dpsClampPos(x, y)
    if dpsRoot then
        dpsRoot.Position = UDim2.fromOffset(x, y)
    end
end
local function dpsSavePos()
    if not dpsRoot then
        return
    end
    PREF.dpsX = math.floor(dpsRoot.Position.X.Offset + 0.5)
    PREF.dpsY = math.floor(dpsRoot.Position.Y.Offset + 0.5)
    prefFlush()
end
local function dpsMenuHidden()
    return TheKing.IsWindowHidden and TheKing.IsWindowHidden() == true
end
local function dpsPlayerHp(plr)
    local char = plr.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and hum.MaxHealth > 0 then
        return hum.Health, hum.MaxHealth
    end
    local maxHp = tonumber(plr:GetAttribute("Stat_MaxHP")) or 1
    return maxHp, maxHp
end
local function dpsSessionKey()
    if LocalPlayer:GetAttribute("InDungeon") ~= true then
        return "lobby"
    end
    return tostring(LocalPlayer:GetAttribute("CurrentDungeon") or "")
        .. "/"
        .. tostring(LocalPlayer:GetAttribute("CurrentDifficultyMode") or "")
end
local function dpsRate(st, total)
    if not st or not st.t0 or (total or 0) <= 0 then
        return 0
    end
    return total / math.max(os.clock() - st.t0, 1)
end
local function dpsPlayerDps(plr)
    local dmg = tonumber(plr:GetAttribute("Damage_Dealt")) or 0
    local uid = plr.UserId
    local st = dpsMeta[uid]
    if not st then
        st = { last = dmg, accum = 0, shown = dmg, t0 = nil, zeroAt = nil, sawDrop = false }
        dpsMeta[uid] = st
        if dmg > 0 then
            st.t0 = os.clock()
        end
    end
    local now = os.clock()
    if dmg <= 0 then
        if (st.shown or 0) > 0 then
            st.zeroAt = st.zeroAt or now
            if now - st.zeroAt < 1.5 then
                return st.shown, dpsRate(st, st.shown)
            end
            local room = tonumber(plr:GetAttribute("RoomIndex")) or tonumber(LocalPlayer:GetAttribute("RoomIndex")) or 0
            if room <= 1 then
                if now - st.zeroAt < 2.8 then
                    return st.shown, dpsRate(st, st.shown)
                end
                st.accum = 0
                st.shown = 0
                st.last = 0
                st.t0 = nil
                st.zeroAt = nil
                st.sawDrop = false
                return 0, 0
            end
            st.sawDrop = true
            st.last = 0
            return st.shown, dpsRate(st, st.shown)
        end
        st.last = 0
        return st.shown or 0, 0
    end
    if st.zeroAt and st.sawDrop and dmg + 1 < (st.shown or 0) * 0.85 then
        st.accum = st.shown or 0
        st.sawDrop = false
    elseif (st.accum or 0) > 0 and dmg >= (st.shown or 0) * 0.9 then
        st.accum = 0
    end
    st.zeroAt = nil
    st.sawDrop = false
    local total = (st.accum or 0) + dmg
    st.last = dmg
    st.shown = total
    if total > 0 and not st.t0 then
        st.t0 = now
    end
    return total, dpsRate(st, total)
end
local function dpsListPlayers()
    local out = { LocalPlayer }
    local seen = { [LocalPlayer] = true }
    for _, p in ipairs(Players:GetPlayers()) do
        if not seen[p] then
            seen[p] = true
            out[#out + 1] = p
        end
        if #out >= 4 then
            break
        end
    end
    return out
end
local function dpsMakeRow(parent, idx)
    local y = DPS_TITLE_H + 4 + (idx - 1) * DPS_ROW_H
    local row = Instance.new("Frame")
    row.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    row.BackgroundTransparency = 0.25
    row.BorderSizePixel = 0
    row.Size = UDim2.new(1, -16, 0, DPS_ROW_H - 6)
    row.Position = UDim2.fromOffset(8, y)
    row.Parent = parent
    dpsCorner(row, 8)

    local nameL = Instance.new("TextLabel")
    nameL.BackgroundTransparency = 1
    nameL.Font = Enum.Font.GothamBold
    nameL.TextSize = 13
    nameL.TextColor3 = Color3.fromRGB(240, 240, 240)
    nameL.TextXAlignment = Enum.TextXAlignment.Left
    nameL.TextTruncate = Enum.TextTruncate.AtEnd
    nameL.Size = UDim2.new(1, -70, 0, 16)
    nameL.Position = UDim2.fromOffset(8, 4)
    nameL.Text = "空位"
    nameL.Parent = row

    local lvL = Instance.new("TextLabel")
    lvL.BackgroundTransparency = 1
    lvL.Font = Enum.Font.GothamMedium
    lvL.TextSize = 12
    lvL.TextColor3 = Color3.fromRGB(180, 180, 180)
    lvL.TextXAlignment = Enum.TextXAlignment.Right
    lvL.Size = UDim2.new(0, 62, 0, 16)
    lvL.Position = UDim2.new(1, -70, 0, 4)
    lvL.Text = "Lv.--"
    lvL.Parent = row

    local barBg = Instance.new("Frame")
    barBg.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    barBg.BorderSizePixel = 0
    barBg.Size = UDim2.new(1, -16, 0, 10)
    barBg.Position = UDim2.fromOffset(8, 22)
    barBg.ClipsDescendants = true
    barBg.Parent = row
    dpsCorner(barBg, 5)

    local ghost = Instance.new("Frame")
    ghost.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ghost.BackgroundTransparency = 0.55
    ghost.BorderSizePixel = 0
    ghost.Size = UDim2.fromScale(1, 1)
    ghost.Parent = barBg
    dpsCorner(ghost, 5)

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = dpsHpColor(1)
    fill.BorderSizePixel = 0
    fill.Size = UDim2.fromScale(1, 1)
    fill.Parent = barBg
    dpsCorner(fill, 5)

    local flash = Instance.new("Frame")
    flash.BackgroundColor3 = Color3.new(1, 1, 1)
    flash.BackgroundTransparency = 1
    flash.BorderSizePixel = 0
    flash.Size = UDim2.fromScale(1, 1)
    flash.ZIndex = 2
    flash.Parent = barBg
    dpsCorner(flash, 5)

    local statL = Instance.new("TextLabel")
    statL.BackgroundTransparency = 1
    statL.Font = Enum.Font.GothamMedium
    statL.TextSize = 11
    statL.TextColor3 = Color3.fromRGB(200, 200, 200)
    statL.TextXAlignment = Enum.TextXAlignment.Left
    statL.Size = UDim2.new(1, -16, 0, 16)
    statL.Position = UDim2.fromOffset(8, 34)
    statL.Text = "总伤 0   DPS 0"
    statL.Parent = row

    return {
        row = row,
        nameL = nameL,
        lvL = lvL,
        fill = fill,
        ghost = ghost,
        flash = flash,
        statL = statL,
        lastP = 1,
    }
end
local function dpsDestroy()
    dpsDragging = false
    if dpsGui then
        pcall(function()
            dpsGui:Destroy()
        end)
    end
    dpsGui = nil
    dpsRoot = nil
    dpsStrokeGrad = nil
    dpsTitleBar = nil
    dpsRows = {}
end
local function dpsRestoreSavedPos()
    if not dpsRoot or dpsDragging then
        return
    end
    local sx = tonumber(PREF.dpsX)
    local sy = tonumber(PREF.dpsY)
    if not sx or not sy then
        return
    end
    dpsApplyPos(sx, sy)
end
local function dpsCreate()
    if dpsGui then
        return
    end
    for _, g in ipairs(PlayerGui:GetChildren()) do
        if g.Name == "TheKing_DpsPanel" then
            pcall(function()
                g:Destroy()
            end)
        end
    end
    dpsGui = Instance.new("ScreenGui")
    dpsGui.Name = "TheKing_DpsPanel"
    dpsGui.ResetOnSpawn = false
    dpsGui.IgnoreGuiInset = true
    dpsGui.DisplayOrder = 60
    dpsGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    dpsGui.Parent = PlayerGui

    local root = Instance.new("Frame")
    root.Name = "Root"
    root.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
    root.BackgroundTransparency = 0.08
    root.BorderSizePixel = 0
    root.Size = UDim2.fromOffset(DPS_W, DPS_H)
    local sx = tonumber(PREF.dpsX) or 18
    local sy = tonumber(PREF.dpsY) or 96
    sx, sy = dpsClampPos(sx, sy)
    root.Position = UDim2.fromOffset(sx, sy)
    root.ClipsDescendants = false
    root.Parent = dpsGui
    dpsCorner(root, 12)
    dpsRoot = root

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.6
    stroke.Color = Color3.new(1, 1, 1)
    stroke.Transparency = 0.05
    stroke.Parent = root
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.22, Color3.fromRGB(70, 70, 70)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.78, Color3.fromRGB(50, 50, 50)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
    })
    grad.Parent = stroke
    dpsStrokeGrad = grad

    -- 标题用 Frame+Label: TextButton 会改鼠标为拖动手势, 圆角还会裁字
    local title = Instance.new("Frame")
    title.Name = "Title"
    title.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
    title.BackgroundTransparency = 0.12
    title.BorderSizePixel = 0
    title.Size = UDim2.new(1, 0, 0, DPS_TITLE_H)
    title.Active = true
    title.Parent = root
    dpsTitleBar = title
    local titleFill = Instance.new("Frame")
    titleFill.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
    titleFill.BackgroundTransparency = 0.12
    titleFill.BorderSizePixel = 0
    titleFill.Size = UDim2.new(1, 0, 0, 16)
    titleFill.Position = UDim2.new(0, 0, 1, -16)
    titleFill.ZIndex = 0
    titleFill.Active = false
    titleFill.Parent = title
    local titleL = Instance.new("TextLabel")
    titleL.BackgroundTransparency = 1
    titleL.Font = Enum.Font.GothamBold
    titleL.Text = "DPS信息"
    titleL.TextSize = 16
    titleL.TextColor3 = Color3.fromRGB(245, 245, 245)
    titleL.TextYAlignment = Enum.TextYAlignment.Center
    titleL.Active = false
    titleL.TextWrapped = false
    titleL.Size = UDim2.new(1, 0, 1, 0)
    titleL.Parent = title
    local titlePad = Instance.new("UIPadding")
    titlePad.PaddingTop = UDim.new(0, 4)
    titlePad.PaddingBottom = UDim.new(0, 2)
    titlePad.Parent = titleL

    title.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end
        if dpsMenuHidden() then
            return
        end
        -- 按下当帧 GetMouseLocation 在钾里经常是错的(屏幕中心), 下一帧再采点
        dpsDragging = true
        dpsDragMouse0 = nil
        dpsDragOrigin = Vector2.new(dpsRoot.Position.X.Offset, dpsRoot.Position.Y.Offset)
    end)
    local connHb = RunService.Heartbeat:Connect(function()
        if not dpsDragging or not dpsRoot then
            return
        end
        if dpsMenuHidden() then
            dpsDragging = false
            dpsSavePos()
            return
        end
        if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            dpsDragging = false
            dpsSavePos()
            return
        end
        local m = UserInputService:GetMouseLocation()
        if not dpsDragMouse0 then
            dpsDragMouse0 = m
            return
        end
        local d = m - dpsDragMouse0
        dpsApplyPos(dpsDragOrigin.X + d.X, dpsDragOrigin.Y + d.Y)
    end)
    local connUp = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end
        if dpsDragging then
            dpsDragging = false
            dpsSavePos()
        end
    end)
    TheKing.AddConnection(connHb)
    TheKing.AddConnection(connUp)

    dpsRows = {}
    for i = 1, 4 do
        dpsRows[i] = dpsMakeRow(root, i)
    end
    task.defer(dpsRestoreSavedPos)
    task.delay(0.25, dpsRestoreSavedPos)
    task.delay(0.8, dpsRestoreSavedPos)
end
local function dpsSetBar(row, p, damaged)
    p = math.clamp(p, 0, 1)
    local col = dpsHpColor(p)
    row.fill.BackgroundColor3 = col
    row.fill.Size = UDim2.new(p, 0, 1, 0)
    if damaged and p < row.lastP then
        row.ghost.BackgroundColor3 = Color3.fromRGB(255, 220, 220)
        row.ghost.Size = UDim2.new(row.lastP, 0, 1, 0)
        pcall(function()
            TweenService:Create(row.ghost, TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(p, 0, 1, 0),
            }):Play()
        end)
        row.flash.BackgroundTransparency = 0.35
        pcall(function()
            TweenService:Create(row.flash, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 1,
            }):Play()
        end)
    else
        row.ghost.Size = UDim2.new(p, 0, 1, 0)
        row.ghost.BackgroundColor3 = col
    end
    row.lastP = p
end
local function dpsRefresh()
    if not dpsRoot then
        return
    end
    local sess = dpsSessionKey()
    if dpsWasRun == nil then
        dpsWasRun = sess
    elseif dpsWasRun ~= sess then
        dpsMeta = {}
        dpsWasRun = sess
    end
    if dpsStrokeGrad then
        dpsStrokeGrad.Rotation = (os.clock() * 28) % 360
    end
    if dpsTitleBar then
        local canDrag = not dpsMenuHidden()
        dpsTitleBar.Active = canDrag
        pcall(function()
            dpsTitleBar.Interactable = canDrag
        end)
    end
    local list = dpsListPlayers()
    for i = 1, 4 do
        local row = dpsRows[i]
        local plr = list[i]
        if not plr then
            row.nameL.Text = "空位"
            row.nameL.TextColor3 = Color3.fromRGB(90, 90, 90)
            row.lvL.Text = "Lv.--"
            row.statL.Text = "总伤 --   DPS --"
            dpsSetBar(row, 0, false)
        else
            local selfRow = plr == LocalPlayer
            local shown = plr.DisplayName
            if shown == "" then
                shown = plr.Name
            end
            if selfRow and fakeNameOn then
                shown = FAKE_NAME
            end
            row.nameL.Text = (selfRow and "▸ " or "") .. shown
            row.nameL.TextColor3 = selfRow and Color3.fromRGB(255, 220, 120) or Color3.fromRGB(240, 240, 240)
            local lv = tonumber(plr:GetAttribute("PlayerLevel")) or 0
            row.lvL.Text = "Lv." .. tostring(lv)
            local hp, maxHp = dpsPlayerHp(plr)
            if maxHp <= 0 then
                maxHp = 1
            end
            local p = math.clamp(hp / maxHp, 0, 1)
            dpsSetBar(row, p, true)
            local total, dps = dpsPlayerDps(plr)
            row.statL.Text = string.format("总伤 %s   DPS %s", dpsFmt(total), dpsFmt(dps))
        end
    end
end

TheKing.BindToggle(VisualTab, {
    Title = "DPS面板",
    Flag = "dr_dps_panel",
    Interval = 0.08,
    OnEnable = function()
        dpsCreate()
        if dpsGui then
            dpsGui.Enabled = true
        end
        return true
    end,
    OnDisable = function()
        dpsDragging = false
        if dpsGui then
            dpsGui.Enabled = false
        end
    end,
    OnTick = function()
        dpsRefresh()
    end,
})

-- ---- 宝箱透视 (投影填充 ESP, 原生 UI 绘制, 穿墙) ----
local chestEspOn = false
local CHEST_COLORS = {
    { Label = "金色", Color = Color3.fromRGB(255, 200, 40) },
    { Label = "红色", Color = Color3.fromRGB(255, 70, 70) },
    { Label = "青色", Color = Color3.fromRGB(70, 220, 220) },
    { Label = "绿色", Color = Color3.fromRGB(90, 230, 110) },
    { Label = "紫色", Color = Color3.fromRGB(190, 90, 255) },
}
local chestColor = CHEST_COLORS[1].Color
local chestColorLabel = "金色"
do
    local saved = PREF.chestColor
    if type(saved) == "string" then
        for _, c in ipairs(CHEST_COLORS) do
            if c.Label == saved then
                chestColor = c.Color
                chestColorLabel = c.Label
                break
            end
        end
    end
end
local chestAlpha = tonumber(PREF.chestAlpha) or 0.15
local chestCache = { t = 0, list = nil }

local function refreshChests()
    local now = os.clock()
    if not chestCache.list or (now - chestCache.t) > 1.2 then
        local list = {}
        local mapDir = getMapDir()
        if mapDir then
            for _, child in ipairs(mapDir:GetChildren()) do
                if child.Name:match("^DungeonChest_") and child:IsA("Model") then
                    list[#list + 1] = child
                end
            end
        end
        chestCache = { t = now, list = list }
    end
    return chestCache.list
end

-- 宝箱透视: 直接在宝箱位置绘制 "宝箱" 文本 (世界坐标投影, 穿墙可见)
local function paintChestEsp()
    local cam = workspace.CurrentCamera
    if not cam then
        return
    end
    local vs = cam.ViewportSize
    local camPos = cam.CFrame.Position
    for _, m in ipairs(refreshChests()) do
        if m.Parent then
            local ok, cf, sz = pcall(function()
                return m:GetBoundingBox()
            end)
            -- 跳过空模型/无实体箱 (已被采集)
            if ok and cf and sz.Y > 0.4 and sz.X > 0.4 then
                -- 实体箱体统一 1.5m 高 (地牢箱子标准): bbox 中心 ± 0.75 推实体顶/底
                -- 不信任 PrimaryPart (不同箱子类型不一: 0.4m 垫片或 1.5m 箱身, 锚点混乱)
                local bodyTopY = cf.Position.Y + 0.75
                local bodyBotY = cf.Position.Y - 0.75
                local ax, az = cf.Position.X, cf.Position.Z
                local spT = cam:WorldToScreenPoint(Vector3.new(ax, bodyTopY, az))
                if spT.Z > 0 and spT.X > -80 and spT.X < vs.X + 80 and spT.Y > -40 and spT.Y < vs.Y + 60 then
                    local dist = (Vector3.new(ax, bodyTopY, az) - camPos).Magnitude
                    -- 箱体屏幕高度: 实体顶到实体底 1.5m 投影差
                    local spB = cam:WorldToScreenPoint(Vector3.new(ax, bodyBotY, az))
                    local boxH = (spB.Z > 0 and math.abs(spT.Y - spB.Y)) or 10
                    -- 上移量随箱体屏幕高缩放 (下限 6px 防远飘)
                    local lift = math.clamp(boxH * 0.45 + 4, 6, 48)
                    local t = Ov.takeChestTxt()
                    local size = math.clamp(math.floor(1500 / math.max(dist, 8)), 6, 44)
                    t.TextColor3 = chestColor
                    t.TextTransparency = math.min(chestAlpha * 1.2, 0.5)
                    t.TextSize = size
                    t.Position = UDim2.fromOffset(math.floor(spT.X), math.floor(spT.Y - lift))
                    t.Visible = true
                end
            end
        end
    end
end

TheKing.BindToggle(VisualTab, {
    Title = "宝箱透视",
    Flag = "dr_chest_esp",
    Interval = 999,
    OnEnable = function()
        chestEspOn = true
        refreshChests()
        return true
    end,
    OnDisable = function()
        chestEspOn = false
    end,
    OnTick = function()
    end,
})

VisualTab:Dropdown({
    Title = "宝箱高亮颜色",
    Values = { "金色", "红色", "青色", "绿色", "紫色" },
    Value = chestColorLabel,
    Flag = "dr_chest_color",
    Callback = function(sel)
        for _, c in ipairs(CHEST_COLORS) do
            if c.Label == sel then
                chestColor = c.Color
                chestColorLabel = c.Label
                prefSet("chestColor", sel)
                break
            end
        end
    end,
})

-- ---- 怪物预警 (雷达) ----
local warnOn = false
local warnRange = PREF.warnRange or 25
local warnRadius = PREF.warnRadius or 150
local warnArrowSize = PREF.warnArrowSize or 22
local WARN_COLORS = {
    ["白色"] = Color3.new(1, 1, 1),
    ["红色"] = Color3.fromRGB(255, 80, 80),
    ["黄色"] = Color3.fromRGB(255, 210, 80),
    ["绿色"] = Color3.fromRGB(100, 240, 120),
}
local warnColorLabel = (type(PREF.warnColor) == "string" and WARN_COLORS[PREF.warnColor]) and PREF.warnColor or "白色"
local warnColor = WARN_COLORS[warnColorLabel]

TheKing.BindToggle(VisualTab, {
    Title = "怪物预警 (雷达箭头)",
    Flag = "dr_warn",
    Interval = 999,
    OnEnable = function()
        warnOn = true
        return true
    end,
    OnDisable = function()
        warnOn = false
    end,
    OnTick = function()
    end,
})

VisualTab:Slider({
    Title = "预警距离(米)",
    Value = { Min = 5, Max = 60, Default = PREF.warnRange or 25 },
    Step = 1,
    Callback = function(v)
        warnRange = v
        PREF.warnRange = v
        prefSave()
    end,
})
VisualTab:Slider({
    Title = "雷达圈大小(px)",
    Value = { Min = 60, Max = 320, Default = PREF.warnRadius or 150 },
    Step = 5,
    Callback = function(v)
        warnRadius = v
        PREF.warnRadius = v
        prefSave()
    end,
})
VisualTab:Slider({
    Title = "箭头大小(px)",
    Value = { Min = 8, Max = 48, Default = PREF.warnArrowSize or 22 },
    Step = 1,
    Callback = function(v)
        warnArrowSize = v
        PREF.warnArrowSize = v
        prefSave()
    end,
})
VisualTab:Dropdown({
    Title = "箭头颜色",
    Values = { "白色", "红色", "黄色", "绿色" },
    Value = warnColorLabel,
    Flag = "dr_warn_color",
    Callback = function(sel)
        warnColor = WARN_COLORS[sel] or Color3.new(1, 1, 1)
        warnColorLabel = sel
        prefSet("warnColor", sel)
    end,
})

-- 预警: 隐形雷达 + ▲ 实心箭头, 箭头宽边(尾部)贴在隐形圆周上, 尖端朝外指向怪物所在方位
-- 无怪时整个雷达不显示任何内容; 无可见圆形边界线 (用户明确不要圆)
local function paintWarnRadar()
    local hrp = getHRP()
    if not hrp then
        return
    end
    local cam = workspace.CurrentCamera
    if not cam then
        return
    end
    local vs = cam.ViewportSize
    local cx, cy = vs.X / 2, vs.Y / 2
    local pos = hrp.Position
    local shown = 0
    for _, en in ipairs(getEnemies()) do
        if shown >= 12 then
            break
        end
        if not en.model:GetAttribute("IsDormant") then
            local d = (en.hrp.Position - pos).Magnitude
            if d <= warnRange and d > 0.5 then
                local ang = worldToRadarAngle(en.hrp.Position)
                if ang then
                    shown = shown + 1
                    -- 箭头中心: 圆周外移半个身位, 使底部宽边正好贴住隐形圆
                    local rOut = warnRadius + warnArrowSize * 0.42
                    local sinA, cosA = math.sin(ang), math.cos(ang)
                    local ax, ay = cx + sinA * rOut, cy - cosA * rOut
                    local t = Ov.takeArrow()
                    t.TextColor3 = warnColor
                    t.TextTransparency = 0
                    t.TextSize = math.max(10, warnArrowSize * 1.3)
                    t.Rotation = math.deg(ang)
                    t.Position = UDim2.fromOffset(math.floor(ax), math.floor(ay))
                    t.Visible = true
                end
            end
        end
    end
end

-- ---- 结算动画加速 ----
local rewardSkipSwap = nil
local function removeRewardSkip()
    if rewardSkipSwap and rewardSkipSwap.mod then
        pcall(function()
            rewardSkipSwap.mod.PlayEntries = rewardSkipSwap.orig
        end)
        rewardSkipSwap = nil
    end
end

local function installRewardSkip()
    local topLevel = PlayerGui:FindFirstChild("TopLevel")
    if not topLevel then
        return false
    end
    local reveal = topLevel:FindFirstChild("RewardReveal", true)
    if not reveal then
        return false
    end
    local rewardsFrame = reveal:FindFirstChild("RewardsFrame", true)
    local template = rewardsFrame and rewardsFrame:FindFirstChild("ItemsTemplate", true)
    if not (rewardsFrame and template) then
        return false
    end
    local client = LocalPlayer:FindFirstChild("PlayerScripts") and LocalPlayer.PlayerScripts:FindFirstChild("Client")
    local ctrl = client and client:FindFirstChild("Controllers") and client.Controllers:FindFirstChild("RewardRevealController")
    if not ctrl or not ctrl:IsA("ModuleScript") then
        return false
    end
    local okReq, ctrlMod = pcall(require, ctrl)
    if not okReq or type(ctrlMod) ~= "table" or type(ctrlMod.PlayEntries) ~= "function" then
        return false
    end
    local orig = ctrlMod.PlayEntries
    ctrlMod.PlayEntries = function(_, _, entries, _)
        if type(entries) ~= "table" then
            return false
        end
        task.spawn(function()
            pcall(function()
                for _, child in ipairs(rewardsFrame:GetChildren()) do
                    if child.Name == "RewardCard" then
                        child:Destroy()
                    end
                end
                reveal.GroupTransparency = 1
                reveal.Visible = true
                local renderPath = ReplicatedStorage.ClientUtils and ReplicatedStorage.ClientUtils:FindFirstChild("RewardCardRender")
                if renderPath and renderPath:IsA("ModuleScript") then
                    local okR, render = pcall(require, renderPath)
                    if okR and type(render) == "table" then
                        local idx = 0
                        for _, v in ipairs(entries) do
                            if type(render.isRenderable) == "function" and render.isRenderable(v) then
                                idx = idx + 1
                                local card = template:Clone()
                                card.Name = "RewardCard"
                                if render.populateRewardCard and render.populateRewardCard(card, v) ~= false then
                                    card.Visible = true
                                    card.LayoutOrder = idx
                                    card.Parent = rewardsFrame
                                else
                                    card:Destroy()
                                end
                            end
                        end
                    end
                end
                reveal.GroupTransparency = 0
                task.wait(0.9)
                if reveal and reveal.Parent then
                    reveal.GroupTransparency = 1
                    reveal.Visible = false
                end
            end)
        end)
        return true
    end
    rewardSkipSwap = { mod = ctrlMod, orig = orig }
    return true
end

TheKing.BindToggle(VisualTab, {
    Title = "结算动画加速",
    Flag = "dr_skip_reward",
    Interval = 999,
    OnEnable = function()
        if not installRewardSkip() then
            TheKing.Notify({ Title = "结算加速", Content = "RewardReveal 界面未就绪, 稍后重开", Icon = "alert-triangle" })
            return false
        end
        return true
    end,
    OnDisable = function()
        removeRewardSkip()
    end,
    OnTick = function()
    end,
})
TheKing.OnCleanup(removeRewardSkip)

-- ---- 假名 (角色名/顶部 Player 名 -> theKing User + 彩虹渐变, 低频扫描优化) ----
local fakeNameState = { labels = {} }
local fakeScanCounter = 0

local function hsvToHex(h, s, v)
    local c = Color3.fromHSV(h % 1, s, v)
    return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end
local function rainbowRichText(text, time)
    local parts = {}
    local n = #text
    for i = 1, n do
        local ch = text:sub(i, i)
        if ch == " " then
            parts[#parts + 1] = " "
        else
            local hue = ((i - 1) / math.max(1, n - 1) * 0.85 + time) % 1
            parts[#parts + 1] = ("<font color=\"%s\">%s</font>"):format(hsvToHex(hue, 1, 1), ch)
        end
    end
    return table.concat(parts)
end

-- 目标 1: 左上 Profile 用户槽 / 文本=玩家名的标签 -> 整体假名 (kind="name")
-- 目标 2: 顶部 "Player : 玩家名" 提示 -> 保留前缀, 名字部分假名 (kind="playerprefix")
-- 目标 3: 角色 Billboard 名牌 NameText / 称号 TitleText (头顶/脚下, 不在 PlayerGui)
local function considerFakeLabel(lbl, out, disp, uname)
    if not (lbl and lbl:IsA("TextLabel") and lbl.Visible and type(lbl.Text) == "string" and lbl.Text ~= "") then
        return
    end
    local t = lbl.Text
    local nm = lbl.Name
    if nm == "Health_Amount" or nm == "LevelText" or nm == "GearScore" or nm == "Combat_Status" then
        return
    end
    local prefix = t:match("^(.-[Pp]layer%s*[:：]%s*)")
    if prefix then
        out[#out + 1] = { lbl = lbl, kind = "playerprefix" }
        return
    end
    -- 头顶/角色 Billboard 玩家名 (假名原先只扫 PlayerGui, 这块漏了)
    if nm == "NameText" then
        out[#out + 1] = { lbl = lbl, kind = "name" }
        return
    end
    -- 称号若写的是玩家名才改; VIP 之类不动
    if nm == "TitleText" then
        local textMatch = (disp ~= "" and t:find(disp, 1, true)) or (uname ~= "" and t:find(uname, 1, true))
        if textMatch then
            out[#out + 1] = { lbl = lbl, kind = "name" }
        end
        return
    end
    local full = ""
    pcall(function()
        full = lbl:GetFullName():lower()
    end)
    if full:find("cmdr", 1, true) or full:find("settings", 1, true) then
        return
    end
    local isProfileUser = full:find("profile", 1, true) and (nm == "User" or nm:lower():find("name", 1, true))
    local textMatch = (disp ~= "" and t:find(disp, 1, true)) or (uname ~= "" and t:find(uname, 1, true))
    if textMatch or isProfileUser then
        local ap = lbl.AbsolutePosition
        if isProfileUser or (ap.X >= 0 and ap.X < 620 and ap.Y >= 0 and ap.Y < 320) then
            out[#out + 1] = { lbl = lbl, kind = "name" }
        end
    end
end
local function findNameTargets()
    local out = {}
    local disp = LocalPlayer.DisplayName or ""
    local uname = LocalPlayer.Name or ""
    for _, sg in ipairs(PlayerGui:GetChildren()) do
        if sg:IsA("ScreenGui") and sg.Enabled then
            for _, lbl in ipairs(sg:GetDescendants()) do
                considerFakeLabel(lbl, out, disp, uname)
            end
        end
    end
    local function collectBillboards(root)
        if not root then
            return
        end
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("BillboardGui") then
                for _, lbl in ipairs(d:GetDescendants()) do
                    considerFakeLabel(lbl, out, disp, uname)
                end
            end
        end
    end
    collectBillboards(getChar())
    -- 名牌实际挂在 Workspace.PlayerModels.<用户名>, 不一定在 Character 上
    local models = workspace:FindFirstChild("PlayerModels")
    local pm = models and models:FindFirstChild(LocalPlayer.Name)
    if pm then
        collectBillboards(pm)
    end
    return out
end

local function scanFakeName()
    local targets = findNameTargets()
    for _, tg in ipairs(targets) do
        local lbl = tg.lbl
        if not fakeNameState.labels[lbl] then
            fakeNameState.labels[lbl] = {
                kind = tg.kind,
                text = lbl.Text,
                rich = lbl.RichText,
            }
        end
    end
end

local function refreshFakeName(time)
    for lbl, st in pairs(fakeNameState.labels) do
        if lbl and lbl.Parent then
            pcall(function()
                lbl.RichText = true
                if st.kind == "playerprefix" then
                    -- 保留 "Player : " 前缀, 名字彩虹
                    local prefix = st.text:match("^(.-[Pp]layer%s*[:：]%s*)") or (st.text .. " ")
                    lbl.Text = prefix .. rainbowRichText(FAKE_NAME, time)
                else
                    lbl.Text = rainbowRichText(FAKE_NAME, time)
                end
            end)
        end
    end
end

local function clearFakeName()
    for lbl, st in pairs(fakeNameState.labels) do
        if lbl and lbl.Parent then
            pcall(function()
                lbl.RichText = st.rich
                lbl.Text = st.text
            end)
        end
        fakeNameState.labels[lbl] = nil
    end
end

TheKing.BindToggle(VisualTab, {
    Title = "假名 (彩虹)",
    Flag = "dr_fakename",
    Interval = 0.3,
    OnEnable = function()
        fakeNameState.labels = {}
        scanFakeName()
        fakeNameOn = true
        return true
    end,
    OnDisable = function()
        fakeNameOn = false
        clearFakeName()
    end,
    OnTick = function()
        -- 低频全树扫描 (每 10 tick ~3s) 纳管新出现标签; 彩虹刷新每 tick
        fakeScanCounter = fakeScanCounter + 1
        if fakeScanCounter >= 10 then
            fakeScanCounter = 0
            scanFakeName()
        end
        refreshFakeName(os.clock() * 0.3)
    end,
})

TheKing.AddConnection(LocalPlayer.CharacterAdded:Connect(function()
    if not fakeNameOn then
        return
    end
    task.delay(0.4, function()
        if fakeNameOn then
            scanFakeName()
        end
    end)
end))

-- 闪避 CD: 贴底部职业经验条下方, 仅冷却中显示, 好了渐隐
function Cbt.findClassExpBar()
    local main = PlayerGui and PlayerGui:FindFirstChild("Main")
    local hud = main and main:FindFirstChild("HUD")
    local act = hud and hud:FindFirstChild("Actions")
    local bot = act and act:FindFirstChild("Bottom")
    local xp = bot and bot:FindFirstChild("ClassEXP")
    if xp and xp:IsA("GuiObject") and xp.Visible and xp.AbsoluteSize.Y > 1 then
        return xp
    end
    return nil
end
function Cbt.ensureDodgeBar()
    local host = Cbt._dodgeHost
    if host and host.Parent then
        return host
    end
    local gui = Cbt._dodgeGui
    if not (gui and gui.Parent) then
        gui = Instance.new("ScreenGui")
        gui.Name = "TheKing_DodgeCD"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = false
        gui.DisplayOrder = 120
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.Parent = PlayerGui
        Cbt._dodgeGui = gui
    end
    host = Instance.new("Frame")
    host.Name = "TK_DodgeCD"
    host.AnchorPoint = Vector2.new(0.5, 0)
    host.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
    host.BackgroundTransparency = 0.25
    host.BorderSizePixel = 0
    host.Size = UDim2.fromOffset(248, 6)
    host.Visible = false
    host.ZIndex = 50
    host.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 2)
    corner.Parent = host
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.AnchorPoint = Vector2.new(0, 0.5)
    fill.Position = UDim2.new(0, 0, 0.5, 0)
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(220, 196, 92)
    fill.BackgroundTransparency = 0
    fill.BorderSizePixel = 0
    fill.ZIndex = 51
    fill.Parent = host
    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0, 2)
    fc.Parent = fill
    Cbt._dodgeHost = host
    Cbt._dodgeFill = fill
    return host
end
function Cbt.hideDodgeBar()
    local host = Cbt._dodgeHost
    if host then
        host.Visible = false
    end
    Cbt._dodgeT0 = nil
    Cbt._dodgeFadeAt = nil
    Cbt._dodgeWasCd = false
end
function Cbt.destroyDodgeBar()
    TheKing.UnbindStepped("dr_dodge_cd")
    local con = Cbt._dodgeAttrConn
    if con then
        pcall(function()
            con:Disconnect()
        end)
        Cbt._dodgeAttrConn = nil
    end
    Cbt.hideDodgeBar()
    local host = Cbt._dodgeHost
    if host then
        pcall(function()
            host:Destroy()
        end)
    end
    Cbt._dodgeHost = nil
    Cbt._dodgeFill = nil
    local gui = Cbt._dodgeGui
    if gui then
        pcall(function()
            gui:Destroy()
        end)
    end
    Cbt._dodgeGui = nil
end
function Cbt.dodgeBusy()
    if LocalPlayer:GetAttribute("Dodge_Cooldown_Active") == true then
        return true
    end
    local ch = getChar()
    if ch and ch:GetAttribute("Dodge") == true then
        return true
    end
    return false
end
function Cbt.tickDodgeBar()
    if not hubAlive or not Cbt._dodgeOn then
        return
    end
    local host = Cbt.ensureDodgeBar()
    local fill = Cbt._dodgeFill
    if not (host and fill) then
        return
    end
    local xp = Cbt.findClassExpBar()
    if not xp then
        host.Visible = false
        return
    end
    local w = math.clamp(math.floor(xp.AbsoluteSize.X * 0.54 + 0.5), 160, 280)
    host.Size = UDim2.fromOffset(w, 6)
    host.Position = UDim2.fromOffset(
        math.floor(xp.AbsolutePosition.X + xp.AbsoluteSize.X * 0.5 + 0.5),
        math.floor(xp.AbsolutePosition.Y + xp.AbsoluteSize.Y + 6 + 0.5)
    )
    local dur = tonumber(LocalPlayer:GetAttribute("Dodge_Cooldown_Duration")) or 2
    if dur < 0.2 then
        dur = 2
    end
    local now = os.clock()
    local busy = Cbt.dodgeBusy()
    if busy then
        if not Cbt._dodgeWasCd then
            Cbt._dodgeT0 = now
            Cbt._dodgeFadeAt = nil
        end
        Cbt._dodgeWasCd = true
        if not Cbt._dodgeT0 then
            Cbt._dodgeT0 = now
        end
    else
        Cbt._dodgeWasCd = false
    end
    local t0 = Cbt._dodgeT0
    local inCd = t0 and (now - t0) < dur
    if inCd then
        local p = math.clamp((now - t0) / dur, 0, 1)
        fill.Size = UDim2.new(p, 0, 1, 0)
        host.BackgroundTransparency = 0.25
        fill.BackgroundTransparency = 0
        host.Visible = true
        Cbt._dodgeFadeAt = nil
        return
    end
    if t0 and not Cbt._dodgeFadeAt then
        Cbt._dodgeFadeAt = now
        fill.Size = UDim2.new(1, 0, 1, 0)
        Cbt._dodgeT0 = nil
    end
    local fadeAt = Cbt._dodgeFadeAt
    if fadeAt then
        local a = 1 - (now - fadeAt) / 0.42
        if a <= 0 then
            Cbt._dodgeFadeAt = nil
            host.Visible = false
            return
        end
        host.BackgroundTransparency = 0.25 + 0.75 * (1 - a)
        fill.BackgroundTransparency = 1 - a
        host.Visible = true
        return
    end
    host.Visible = false
end

TheKing.BindToggle(VisualTab, {
    Title = "闪避冷却条",
    Flag = "dr_dodge_cd",
    OnEnable = function()
        Cbt._dodgeOn = true
        Cbt.ensureDodgeBar()
        TheKing.BindStepped("dr_dodge_cd", "heartbeat", Cbt.tickDodgeBar)
        return true
    end,
    OnDisable = function()
        Cbt._dodgeOn = false
        Cbt.destroyDodgeBar()
    end,
})

-- ============================================================
-- Tab: 快捷键
-- ============================================================
local HotkeyTab = TheKing.NewTab({ Title = "快捷键", Icon = "keyboard" })

-- 结算界面检测 v3 (定点结构检测, 不遍历全树避免踩 UIListLayout 等无 Visible 属性坑):
-- Main.HUD.<*>_Container.Completion_Info 可见, 且含 Replay/Return 语义文本
local function atCompletionScreen()
    local mainG = PlayerGui:FindFirstChild("Main")
    local hud = mainG and mainG:FindFirstChild("HUD")
    if not hud then
        return nil
    end
    for _, container in ipairs(hud:GetChildren()) do
        if container:IsA("Frame") and container.Name:find("Container") then
            local comp = container:FindFirstChild("Completion_Info")
            if comp and comp.Visible then
                for _, d in ipairs(comp:GetDescendants()) do
                    if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Visible then
                        local t = tostring(d.Text or ""):lower()
                        if t:find("replay", 1, true) or t:find("restart", 1, true)
                            or t:find("again", 1, true) or t:find("重开", 1, true)
                            or t:find("再战", 1, true) or t:find("再来", 1, true) then
                            return true
                        end
                        if t:find("return", 1, true) or t:find("leave", 1, true)
                            or t:find("lobby", 1, true) or t:find("回城", 1, true)
                            or t:find("离开", 1, true) or t:find("退出", 1, true) then
                            return true
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function callDungeonRun(methodName, notifyTitle)
    local svc = Knit.GetService("DungeonRunService")
    local ok = pcall(function()
        local p = svc[methodName](svc)
        if p and p.await then
            p:await()
        end
    end)
    if not ok then
        TheKing.Notify({ Title = notifyTitle, Content = "请求失败, 可能不在有效界面", Icon = "alert-triangle" })
    end
end

-- 快捷键动作统一 pcall 保护: 任何内部错误不外泄到 Rayfield (避免 callback error 弹窗)
local function tryReplay()
    local ok = pcall(function()
        if not atCompletionScreen() then
            TheKing.Notify({ Title = "重开对局", Content = "当前不在结算界面, 快捷键无效", Icon = "info" })
            return
        end
        callDungeonRun("RequestReplay", "重开对局")
    end)
    if not ok then
        TheKing.Notify({ Title = "重开对局", Content = "请求出错", Icon = "alert-triangle" })
    end
end
local function tryReturn()
    local ok = pcall(function()
        if not atCompletionScreen() then
            TheKing.Notify({ Title = "回城", Content = "当前不在结算界面, 快捷键无效", Icon = "info" })
            return
        end
        callDungeonRun("RequestReturn", "回城")
    end)
    if not ok then
        TheKing.Notify({ Title = "回城", Content = "请求出错", Icon = "alert-triangle" })
    end
end

local function tryNextRoom()
    local hrp = getHRP()
    if not hrp then
        return
    end
    local room = getCurrentRoom()
    if not room then
        TheKing.Notify({ Title = "传送下一房间", Content = "找不到当前所在房间", Icon = "info" })
        return
    end
    if roomHasEnemies(room) then
        TheKing.Notify({ Title = "传送下一房间", Content = "房间怪物未清完, 无法传送", Icon = "info" })
        return
    end
    local conns = room:FindFirstChild("Connectors")
    local exitP = conns and conns:FindFirstChild("Exit")
    if not exitP or not exitP:IsA("BasePart") then
        TheKing.Notify({ Title = "传送下一房间", Content = "当前房间没有出口点", Icon = "alert-triangle" })
        return
    end
    hrp.CFrame = exitP.CFrame * CFrame.new(0, 3, -14)
    TheKing.Notify({ Title = "传送下一房间", Content = "已传送到下一房间入口", Icon = "check-circle" })
end

persistKeybindEl(HotkeyTab:Keybind({
    Title = "传送下一房间 (F1)",
    Value = PREF.kb_next or "F1",
    Flag = "dr_key_nextroom",
    Callback = function()
        tryNextRoom()
    end,
}), "kb_next")
persistKeybindEl(HotkeyTab:Keybind({
    Title = "重开对局 (F2)",
    Value = PREF.kb_replay or "F2",
    Flag = "dr_key_replay",
    Callback = function()
        tryReplay()
    end,
}), "kb_replay")
persistKeybindEl(HotkeyTab:Keybind({
    Title = "回城 (F3)",
    Value = PREF.kb_return or "F3",
    Flag = "dr_key_return",
    Callback = function()
        tryReturn()
    end,
}), "kb_return")

-- ============================================================
-- Tab: 设置 (骨架标配, 不可删)
-- ============================================================
local SettingsTab = TheKing.NewTab({ Title = "设置", Icon = "settings" })

local function unloadAction()
    local function doUnload()
        if not hubAlive then
            return
        end
        hubAlive = false
        speedEnabled = false
        TheKing.Destroy({ skipSave = true, purgeUi = true })
    end
    local ok = pcall(function()
        TheKing.Confirm({
            Title = "卸载确认",
            Content = "将停止全部功能并销毁界面, 确定吗?",
            OnConfirm = doUnload,
        })
    end)
    if not ok then
        doUnload()
    end
end

persistKeybindEl(SettingsTab:Keybind({
    Title = "显示/隐藏窗口",
    Value = PREF.kb_toggle or "Delete",
    Flag = "uiToggleKey",
    Callback = function()
        TheKing.Window:Toggle()
    end,
}), "kb_toggle")
persistKeybindEl(SettingsTab:Keybind({
    Title = "卸载脚本",
    Value = PREF.kb_unload or "End",
    Flag = "uiUnloadKey",
    Callback = unloadAction,
}), "kb_unload")
SettingsTab:Button({
    Title = "停止全部功能",
    Icon = "square",
    Callback = function()
        TheKing.StopAll()
        meleeEnabled = false
        skillAuraOn = false
        Cbt.syncBossParry()
        chestEspOn = false
        warnOn = false
        fakeNameOn = false
        Cbt._dodgeOn = false
        Cbt.destroyDodgeBar()
        autoRotateLockUntil = 0
        local hum = getHum()
        if hum then
            pcall(function()
                hum.AutoRotate = true
            end)
        end
        TheKing.Notify({ Content = "已停止全部功能", Icon = "check-circle" })
    end,
})
SettingsTab:Button({
    Title = "卸载脚本",
    Icon = "trash-2",
    Color = Color3.fromRGB(255, 100, 100),
    Callback = unloadAction,
})

-- 主绘制循环: 对象池计数制, 未使用的对象由 overlayFrameEnd 自动隐藏; 全程 pcall 兜底防崩
-- 注: 曾加"鼠标按住暂停"防护 (v1.0.32), 但误伤右键拖视角 (按住右键=游戏常态视角操作)
--     崩溃定案后证实绘制与崩溃无关, 防护已移除 — 无条件绘制
function Cbt.drawFrame()
    if not hubAlive then
        return
    end
    local ok, err = pcall(function()
        local my = getHRP()
        if meleeEnabled and my then
            Ov.ring(my, getMeleeRange(), Color3.fromRGB(255, 60, 60), 0)
        end
        if skillAuraOn and my then
            local cp = CLASS_PROFILES[classIdx]
            local skills = cp and cachedClassSkills(cp.Folder)
            local sr, slot = nil, skillAuraLastSlot
            if skills then
                if slot and skills[slot] then
                    sr = skillRange(skills[slot])
                else
                    sr = 0
                    for i = 1, 4 do
                        if skills[i] then
                            sr = math.max(sr, skillRange(skills[i]))
                        end
                    end
                    if sr <= 0 then
                        sr = nil
                    end
                end
            end
            if sr then
                local holding = slot and os.clock() < skillHoldUntil
                Ov.ring(my, sr, Color3.fromRGB(255, 220, 60), holding and 0 or 0.28)
            end
        end
        if chestEspOn then
            paintChestEsp()
        end
        if warnOn then
            paintWarnRadar()
        end
        Ov.frameEnd()
    end)
    if not ok and err then
        Ov.reset()
        if Cbt.drawErr ~= err then
            Cbt.drawErr = err
            warn("[RCWTK] drawFrame error: " .. tostring(err))
        end
    end
end
function Cbt.drawCombat()
    if not hubAlive then
        return
    end
    local ok, err = pcall(function()
        if (meleeEnabled or skillAuraOn) and Cbt.lock and Cbt.alive(Cbt.lock) then
            local pulse = 0.28 + 0.22 * (0.5 + 0.5 * math.sin(os.clock() * 7))
            local both = meleeEnabled and skillAuraOn
            local col = both and Color3.fromRGB(255, 140, 40) or (skillAuraOn and not meleeEnabled and Color3.fromRGB(255, 220, 70) or Color3.fromRGB(255, 55, 55))
            Cbt.disc("rLock", Cbt.lock.hrp, 2.7, col, pulse, -2.5)
            Cbt.disc("rLock2", Cbt.lock.hrp, 1.25, col, math.min(0.72, pulse + 0.18), -2.5)
        else
            Cbt.disc("rLock", nil)
            Cbt.disc("rLock2", nil)
        end
    end)
    if not ok and err and Cbt.drawErr ~= err then
        Cbt.drawErr = err
        warn("[RCWTK] drawCombat error: " .. tostring(err))
    end
end

TheKing.StartLoop("dr_draw_loop", 0.1, Cbt.drawFrame)
TheKing.AddConnection(RunService.Heartbeat:Connect(Cbt.drawCombat))
TheKing.OnCleanup(function()
    hubAlive = false
    speedEnabled = false
    if Cbt._wsConn then
        pcall(function()
            Cbt._wsConn:Disconnect()
        end)
        Cbt._wsConn = nil
    end
    Ov.reset()
    Cbt.disc("rLock", nil)
    Cbt.disc("rLock2", nil)
    dpsDestroy()
end)

-- ============================================================
-- 加载完成
-- ============================================================
TheKing.Notify({ Content = "TheKing HUB v0.10.1 已加载 (地下城战利品者)", Icon = "crown" })

if TheKing.LoadConfig then
    TheKing.LoadConfig()
end
if TheKing.PinNativeToggleKey then
    TheKing.PinNativeToggleKey()
end

-- 从未 Show 过的窗不要调 Hide (会缩成顶栏药丸); 库里 SetWindowHidden 会保持建窗初态
function Cbt.applyStartHidden()
    if START_UI_HIDDEN or (tonumber(PREF.uiHidden) or 0) ~= 0 then
        if TheKing.SetWindowHidden then
            pcall(TheKing.SetWindowHidden, true)
        end
    end
end
task.delay(0.15, Cbt.applyStartHidden)

-- 自建持久化: 恢复上次开启的开关 (等价逐个人工点击, 触发各自 OnEnable 启动 loop)
-- 延后到 UI 全部建完 + LoadConfig 之后执行, 避免与 Rayfield 配置恢复竞争
task.delay(0.8, function()
    if not hubAlive or not TheKing.RestoreToggle then
        return
    end
    for k, v in pairs(PREF) do
        local flag = k:match("^t_(.+)$")
        if flag and v ~= 0 then
            pcall(TheKing.RestoreToggle, flag, true)
        end
    end
end)

print("[RCWTK] DR_HUB_v0101 loaded")
end)()
