--[[
    TheKing HUB [1.9.5] - 地下城战利品者
    RCWTK 引擎生成 | 模板 v1.0
    版本历史: games/dungeon-raiders/changelog.md

    功能清单:
      战斗
        自动喝血药水: 低血自动使用装备血瓶 (服务端 UsePotion); 阈值可调(默认50%)
        杀戮光环(自动平A): 360° 锁最近怪; 发包朝锁定目标, WASD 只走位不改射击方向
          (锻造霸主 3技能切弓用 Range+SpecialRangeBonus, 4技能切回近战用 Range)
          远程职业(阿蒂米斯 / 锻造霸主弓 / 真空) 自动拉开身位, 不站怪堆中间
          近战双光环: 平A范围内没怪自动贴脸最近怪, 不站着空转; 平A节奏=职业攻速×装备 Stat_AttackSpeed
          开平A或技能光环时自动对精英和 Boss 拼刀 (点 F / Parry), 掐连段; 不拼小怪
        杀戮技能光环: 冷却好了按 1→4 丢, 有充能打光, 不留手
        职业下拉自动跟角色, 选错档案会乱距离/乱放技能
        自动选择 BUFF: 靠近祭坛自动交互; 三选一命中偏好则自动点卡, 全不命中随机选一张
        自动补充药水: 靠近炼药锅 (Refill Potions) 自动交互
        锁定脚底小光环: 红=平A圈 / 黄=技能圈 / 双光环=蓝 / 目标脚下双圈跟出手目标同一只
        职业数据写在本文件 CLASS_ARCHIVE_RAW (随脚本走, 无单独档案)
      视觉
        宝箱透视: 投影填充 ESP (穿墙), 颜色/透明度可调
        怪物预警: 屏幕中心雷达圈 + 三角箭头指示怪物方位, 距离/圈径/箭头/颜色可调
        结算动画加速: RewardReveal 卡片直显w
        假名: 左上角 + 头顶名牌改为 "theKing User" + 彩虹渐变字体
        DPS面板: 局内最多4人 名字/等级/总伤/DPS + 血条 (可拖动, 位置持久化)
        闪避冷却条: 经验条下方, 仅 Dodge_Cooldown_Active 时显示, 好了渐隐
      快捷键
        F1 传送下一房间(需当前房间清怪完成) / F2 重开对局(结算界面) / F3 回城(结算界面)
      移动
        自动寻路: 主链清怪→箱→药→岔路小房(有刷怪/刷箱点就进, 不等门外实体)→特殊Boss走廊→下一房
          感知系统: 走廊 Segment 动态实例化也认 (Zone 反查); 尽头岔路房 (只进无出) 自动接管清怪+回主链
          岔路配对取最近门, 双岔路不再来回抖; 打完特殊BOSS沿走廊走回入口再回主链 (不再跨房直飞)
          IsLootRoom/IsSpecialBoss/SpecialBossId 属性直接感知房型; 尽头小房 Entry 距离配对回程门
          走廊尽量走中间; 不爬高度差, 只有捡箱/祭坛/Boss 才上高处
          路过木箱/柴堆/陶罐等杂物本地关碰撞, 避免卡死
          判定卡住时先二段跳越障, 再跳路点/重算
          死亡回上一间重生会丢掉旧绿线, 进度对齐当前房再从门口走, 避免撞墙卡死
        路径绿圈+绿线; 寻路Bot 窗: 目的性报告(正在:...) + 房内怪物血条 + 高度自适应(怪多窗长)
          窗在下半屏向上扩展, 在上半屏向下扩展 (拖动位置仍可落盘)
        自动重开: 结算无条件 Replay (换服后不再挂号注入, 靠钾 autoexec)
        自动选择结算宝箱: 结算 3 箱自动全选 (含爬塔 MidRun 箱); 爬塔祝福自动选第一张
        爬塔模式 (Double Dungeon): 自动捡波次箱 + 自动选祝福 + 不跑寻路

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
        4 技能多段位移跟相机朝向扭脸锁怪, extra 发视角方向
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
    ScriptVersion = "1.9.5",
    StartHidden = START_UI_HIDDEN,
})

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
for k, v in pairs(PREF) do
    if k:sub(1, 6) == "mobhp_" then
        Nav.mobMaxLearn[k:sub(7)] = tonumber(v) or 0
    end
end
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
    local lv = root.AssemblyLinearVelocity
    local av = root.AssemblyAngularVelocity
    root.CFrame = CFrame.lookAt(root.Position, root.Position + d)
    pcall(function()
        root.AssemblyLinearVelocity = lv
        root.AssemblyAngularVelocity = av
    end)
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

local function isCombatRoomModel(room)
    if not room then
        return false
    end
    local sp = room:FindFirstChild("Spawns")
    if sp then
        for _, d in ipairs(sp:GetDescendants()) do
            if d.Name == "Enemy_Spawn" or d.Name == "Boss_Spawn" then
                return true
            end
        end
    end
    local zone = room:FindFirstChild("Zone")
    if zone and zone:IsA("BasePart") then
        return math.min(zone.Size.X, zone.Size.Z) >= 70
    end
    return false
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
    local best, bd = nil, 1e9
    for _, child in ipairs(mapDir:GetChildren()) do
        if child.Name:match("^Room_%d+$") and isCombatRoomModel(child) then
            local zone = child:FindFirstChild("Zone")
            if zone and zone:IsA("BasePart") then
                local rel = zone.CFrame:PointToObjectSpace(pos)
                local sz = zone.Size / 2
                if math.abs(rel.X) <= sz.X and math.abs(rel.Y) <= sz.Y + 16 and math.abs(rel.Z) <= sz.Z then
                    local d = Vector3.new(zone.Position.X - pos.X, 0, zone.Position.Z - pos.Z).Magnitude
                    if d < bd then
                        bd = d
                        best = child
                    end
                end
            end
        end
    end
    return best
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
        AtkSpd = 1.1,
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
        Ranged = true,
        AtkSpd = 1.28,
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
    {
        -- 法师系远程 (玩家实测确认): 技能 30~40 格远超平A 21
        Name = "真空",
        Ranged = true,
        Range = 21,
        Skills = {
            { Range = 30, Cd = 5, Charges = 3, Duration = 3, Dash = 80 },
            { Range = 35, Cd = 12, Duration = 3 },
            { Range = 30, Cd = 14, Duration = 4 },
            { Range = 40, Cd = 16, Duration = 3 },
        },
    },
    {
        -- 双刀近战, 全职业最快平A (1.35): 双光环主输出, 平A补技能真空
        Name = "蔚蓝恶魔",
        AtkSpd = 1.35,
        Range = 19,
        Skills = {
            { Range = 35, Cd = 4, Charges = 3, Duration = 1.2, Dash = 70 },
            { Range = 28, Cd = 7, Duration = 2.5, Dash = 90 },
            { Range = 30, Cd = 10, Duration = 3 },
            { Range = 22, Cd = 15, Duration = 6 },
        },
    },
    {
        -- 审批之刃 (Awakened Devil EX, Exotic): 蔚蓝恶魔觉醒形态, Class_Data.Get 实测 2026-09-05
        -- 平A 25 攻速1.0 无加成; 技能1/2多充能, 3是坠天 (6x 伤害单体), 4 月相 6 段
        Name = "审批之刃",
        AtkSpd = 1.0,
        Range = 25,
        Skills = {
            { Range = 28, Cd = 5, Charges = 2, Duration = 2.5, Dash = 90 },
            { Range = 35, Cd = 4, Charges = 3, Duration = 1.5, Dash = 70 },
            { Range = 40, Cd = 9, Duration = 2, Dash = 70 },
            { Range = 26, Cd = 15, Duration = 3, Dash = 60 },
        },
    },
    {
        -- 拳击手 (Boxer, Epic): Class_Data.Get 实测 2026-09-05, 短拳连击型
        -- 平A 15 攻速1.0 1x; 无终极 (Ultimate 空, E 槽自动跳过); 1 四充快拳 / 2 疾扫带无敌帧 / 3 三连 / 4 狼牙
        Name = "拳击手",
        AtkSpd = 1.0,
        Range = 15,
        Skills = {
            { Range = 18, Cd = 4, Charges = 4, Duration = 1.2, Dash = 85 },
            { Range = 22, Cd = 8, Duration = 1.5, Dash = 63 },
            { Range = 18, Cd = 7, Duration = 2 },
            { Range = 26, Cd = 13, Duration = 2.5 },
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
    add("真空", "Vacio")
    add("vacio", "Vacio")
    add("蔚蓝恶魔", "Azure Devil")
    add("azure devil", "Azure Devil")
    add("蔚蓝", "Azure Devil")
    add("审批之刃", "Awakened Devil EX")
    add("awakened devil ex", "Awakened Devil EX")
    add("觉醒恶魔", "Awakened Devil EX")
    add("拳击手", "Boxer")
    add("boxer", "Boxer")
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
        Hits = tonumber(s.Hits or s.HitCount or s.FinalHit),
        Steer = s.Steer == true,
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
        AtkSpd = tonumber(raw.AtkSpd) or 1,
        SkipRequire = raw.SkipRequire == true or skills ~= nil,
        Ranged = raw.Ranged == true,
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
local autoApproachAt = 0 -- 近战双光环贴脸节流
-- 战斗锁定收进一张表, 少占主块 local 寄存器 (Luau 上限 200)
local Cbt = {
    lock = nil,
    _wsWasFreeze = false,
    blessUiAt = 0,
    blessFireAt = 0,
    _parryAt = 0,
    _parryScanAt = 0,
    _refillScanAt = 0,
    refillFireAt = 0,
    _dodgeT0 = 0,
    _dodgeFadeAt = 0,
    kiteAt = 0,
    kiteKey = "",
    kiting = false,
    _atkIntAt = 0,
    _atkInt = 0.099,
}
-- 平A间隔: 职业 AttackSpeed × (1 + 装备/成就攻速%/100). Stat_AttackSpeed 上限 60 (StatInfoData Cap)
function Cbt.atkInterval()
    local now = os.clock()
    if now - (Cbt._atkIntAt or 0) < 0.4 and (Cbt._atkInt or 0) > 0 then
        return Cbt._atkInt
    end
    local classSpd = 1
    local cur = LocalPlayer:GetAttribute("Current_Class") or LocalPlayer:GetAttribute("Active_Class")
    if type(cur) == "string" and cur ~= "" then
        for i = 1, #CLASS_PROFILES do
            local p = CLASS_PROFILES[i]
            if p and p.Folder == cur then
                classSpd = tonumber(p.AtkSpd) or 1
                break
            end
        end
    end
    if classSpd < 0.4 then
        classSpd = 0.4
    end
    local gear = tonumber(LocalPlayer:GetAttribute("Stat_AttackSpeed")) or 0
    local ach = tonumber(LocalPlayer:GetAttribute("AchBoost_AttackSpeed")) or 0
    if gear < 0 then
        gear = 0
    elseif gear > 60 then
        gear = 60
    end
    if ach < 0 then
        ach = 0
    end
    local mult = classSpd * (1 + (gear + ach) / 100)
    if mult < 0.5 then
        mult = 0.5
    elseif mult > 3.5 then
        mult = 3.5
    end
    Cbt._atkInt = 0.099 / mult
    Cbt._atkIntAt = now
    return Cbt._atkInt
end
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
function Cbt.isRanged()
    if isForgeBowStance() then
        return true
    end
    local cls = LocalPlayer:GetAttribute("Current_Class") or LocalPlayer:GetAttribute("Active_Class")
    local cp = ClassKit.Get(cls)
    if cp and cp.Ranged == true then
        return true
    end
    local r = ClassKit.MeleeRange(cls, false)
    return (tonumber(r) or 0) >= 26
end
function Cbt.kiteMove(hum, dest)
    if not (hum and dest) then
        return
    end
    local now = os.clock()
    local gk = string.format("%.0f:%.0f", dest.X, dest.Z)
    if Cbt.kiteKey == gk and (now - (Cbt.kiteAt or 0)) < 0.55 then
        return
    end
    Cbt.kiteKey = gk
    Cbt.kiteAt = now
    pcall(function()
        hum:MoveTo(dest)
    end)
end
-- Nav 前向声明: Nav 真正初始化在下方寻路区 (~2850), 不提前声明的话
-- kiteTick 捕获的是全局 Nav (nil), 远程风筝循环会每帧炸 "index nil with 'on'"
local Nav = {}
function Cbt.kiteTick()
    Cbt.kiting = false
    if not hubAlive or not (meleeEnabled or skillAuraOn) then
        return
    end
    if not Cbt.isRanged() then
        return
    end
    if LocalPlayer:GetAttribute("Dead") then
        return
    end
    local now = os.clock()
    if now < skillBusyUntil and skillFreezeMove then
        return
    end
    if Nav.on then
        local ph = Nav.phase
        if ph == "loot" or ph == "refill" or ph == "hall" or ph == "seek" or ph == "center" or ph == "boss" or ph == "done" then
            return
        end
    end
    local hrp = getHRP()
    local hum = getHum()
    if not (hrp and hum) or hum.Health <= 0 then
        return
    end
    local pos = hrp.Position
    local reach = getMeleeRange()
    local hold = math.clamp(reach * 0.58, 14, math.max(16, reach - 5))
    local tooClose = math.clamp(reach * 0.34, 9, 15)
    local nearest, nearD = nil, 1e9
    local packX, packZ, packN = 0, 0, 0
    local crowd = 0
    for _, en in ipairs(getEnemies()) do
        if Cbt.alive(en) then
            local p = en.hrp.Position
            local d = (p - pos).Magnitude
            if d < 70 then
                packX = packX + p.X
                packZ = packZ + p.Z
                packN = packN + 1
                if d < nearD then
                    nearD = d
                    nearest = en
                end
                if d < 12 then
                    crowd = crowd + 1
                end
            end
        end
    end
    if not nearest then
        return
    end
    Cbt.kiting = true
    local pack = pos
    if packN > 0 then
        pack = Vector3.new(packX / packN, pos.Y, packZ / packN)
    end
    local away = Vector3.new(pos.X - pack.X, 0, pos.Z - pack.Z)
    if away.Magnitude < 0.8 then
        away = Vector3.new(pos.X - nearest.hrp.Position.X, 0, pos.Z - nearest.hrp.Position.Z)
    end
    if away.Magnitude < 0.4 then
        local look = Vector3.new(-hrp.CFrame.LookVector.X, 0, -hrp.CFrame.LookVector.Z)
        away = look.Magnitude > 0.2 and look or Vector3.new(1, 0, 0)
    end
    away = away.Unit
    local room = getCurrentRoom()
    local function tryDest(dir, dist)
        local x = pos.X + dir.X * dist
        local z = pos.Z + dir.Z * dist
        local dest = Nav.groundAt(x, z, pos.Y)
        if room and not Nav.inZone(room, dest) then
            return nil
        end
        local climb = math.abs(dest.Y - pos.Y)
        if climb > 4.5 then
            return nil
        end
        return dest
    end
    local function sidestep(dir, dist)
        local d = tryDest(dir, dist)
        if d then
            return d
        end
        local r = Vector3.new(-dir.Z, 0, dir.X)
        d = tryDest(r, dist)
        if d then
            return d
        end
        return tryDest(-r, dist)
    end
    if Nav.on and Nav.pathLive() then
        Nav.pts = {}
        Nav.idx = 1
        Nav.clearMarks()
    end
    if nearD < tooClose or crowd >= 2 then
        local step = math.clamp(hold - nearD + 6, 8, 16)
        local dest = sidestep(away, step)
        if dest then
            Cbt.kiteMove(hum, dest)
        end
        return
    end
    if nearD > hold + 3 then
        local to = Vector3.new(nearest.hrp.Position.X - pos.X, 0, nearest.hrp.Position.Z - pos.Z)
        if to.Magnitude > 0.4 then
            local walk = math.max(0, nearD - hold)
            local dest = sidestep(to.Unit, math.min(walk, 14))
            if dest then
                Cbt.kiteMove(hum, dest)
            end
        end
        return
    end
    Cbt.kiteKey = ""
    pcall(function()
        hum:MoveTo(pos)
    end)
end
function Cbt.syncKite()
    if hubAlive and (meleeEnabled or skillAuraOn) then
        TheKing.StartLoop("dr_ranged_kite", 0.12, Cbt.kiteTick)
    else
        TheKing.StopLoop("dr_ranged_kite")
        Cbt.kiting = false
        Cbt.kiteKey = ""
    end
end
-- 有锁就关 AutoRotate: WASD 只平移不扭脸; 扭脸保留速度
function Cbt.lockFace()
    if not (hubAlive and meleeEnabled) then
        TheKing.UnbindStepped("dr_melee_lock")
        return
    end
    TheKing.BindStepped("dr_melee_lock", "heartbeat", function()
        if not (hubAlive and meleeEnabled) then
            return
        end
        local hrp = getHRP()
        local hum = getHum()
        if not (hrp and hum) or hum.Health <= 0 then
            return
        end
        local tgt = Cbt.lock
        if tgt and Cbt.alive(tgt) then
            if hum.AutoRotate ~= false then
                pcall(function()
                    hum.AutoRotate = false
                end)
            end
            local want = flatDir(hrp.Position, tgt.hrp.Position)
            local look = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z)
            if want.Magnitude > 0.05 and (look.Magnitude < 0.05 or look.Unit:Dot(want) < 0.995) then
                faceTowards(hrp, tgt.hrp.Position)
            end
        else
            if hum.AutoRotate ~= true then
                pcall(function()
                    hum.AutoRotate = true
                end)
            end
        end
    end)
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
-- 近战双光环贴脸: 范围内无怪但附近有怪 → 朝最近怪 MoveTo 小步接近
-- 仅在杀戮+技能双开时补位 (单开保持原行为), 让技能/平A 光环尽快咬住怪, 减少站桩空转
function Cbt.autoApproach()
    local hrp = getHRP()
    local hum = getHum()
    if not (hrp and hum) or hum.Health <= 0 then
        return
    end
    if LocalPlayer:GetAttribute("Dead") then
        return
    end
    local reach = getMeleeRange()
    -- 范围内已有怪: 光环自己会打, 不动 (findMeleeTarget 此时尚未定义, 走 Cbt.pick)
    if Cbt.pick(reach) then
        Cbt.approachKey = ""
        return
    end
    local now = os.clock()
    if now < skillBusyUntil and skillFreezeMove then
        return
    end
    -- 找 25 格内最近活怪走过去 (25 = 技能光环典型搜索半径上限)
    local best, bd = nil, 25
    for _, en in ipairs(getEnemies()) do
        if Cbt.alive(en) and not en.model:GetAttribute("IsDormant") then
            local d = (en.hrp.Position - hrp.Position).Magnitude
            if d < bd then
                bd = d
                best = en
            end
        end
    end
    if not best then
        Cbt.approachKey = ""
        return
    end
    Cbt.mark(best)
    -- 走到怪身边 reach*0.7 处 (留出挥刀空间), 走过了就停
    local stop = math.max(reach * 0.7, 8)
    if bd <= stop then
        Cbt.approachKey = ""
        return
    end
    local dir = (best.hrp.Position - hrp.Position)
    dir = Vector3.new(dir.X, 0, dir.Z)
    if dir.Magnitude < 0.3 then
        return
    end
    local dest = hrp.Position + dir.Unit * (bd - stop)
    local gk = string.format("%.0f:%.0f", dest.X, dest.Z)
    if Cbt.approachKey == gk and now - (Cbt.approachAt or 0) < 0.5 then
        return
    end
    Cbt.approachKey = gk
    Cbt.approachAt = now
    pcall(function()
        hum:MoveTo(dest)
    end)
end
-- 发一击本体: 技能优先 + 技能排队/窗口期间停发
local function fireMeleeOnce()
    local hrp = getHRP()
    local hum = getHum()
    if not (hrp and hum) or hum.Health <= 0 then
        return
    end
    local now = os.clock()
    if now < skillHoldUntil then
        return
    end
    if now < skillBusyUntil and skillFreezeMove then
        return
    end
    -- 平A节奏: 职业攻速 × 装备 Stat_AttackSpeed%; DBreset 补发更密时固定 0.1 会漏刀
    if now - meleeLastAttack < Cbt.atkInterval() then
        return
    end
    local tgt = findMeleeTarget(getMeleeRange())
    if not tgt then
        return
    end
    Cbt.mark(tgt)
    local to = tgt.hrp.Position - hrp.Position
    to = Vector3.new(to.X, 0, to.Z)
    local aim = Vector3.zero
    if to.Magnitude > 0.15 then
        aim = to.Unit
        faceTowards(hrp, tgt.hrp.Position)
    end
    -- 游戏本体平A发的是相机相对 WASD; 发 zero 时服务端会跟走位. 这里发指向锁定的世界方向
    TheKing.Fire(AttackRE, aim)
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

-- ---- 内置拼刀: 平A/技能光环开着就对精英和 Boss 出招窗点 Parry, 不拼小怪 ----
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
    if model:GetAttribute("IsBoss") or model:GetAttribute("IsMiniBoss") then
        return true
    end
    local pri = tonumber(model:GetAttribute("HighlightPriority")) or 0
    if pri > 0 then
        return true
    end
    if model:GetAttribute("IsElite") == true or model:GetAttribute("Elite") == true then
        return true
    end
    if Cbt.bossRow(model) then
        return true
    end
    -- 小怪: IsFodder 且不是上面那些; Demon 图 Boss 也会带 IsFodder, 所以 Boss 判断必须在前
    if model:GetAttribute("IsFodder") == true then
        return false
    end
    return true
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
    if string.find(l, "attack", 1, true) or string.find(l, "strike", 1, true) or string.find(l, "slam", 1, true) then
        return true
    end
    if string.find(l, "lunge", 1, true) or string.find(l, "stab", 1, true) or string.find(l, "punch", 1, true) then
        return true
    end
    return false
end
function Cbt.parryDelay(row, animName)
    local w = tonumber(row and row.WindUpDuration) or 0.18
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
    return math.clamp(w / math.max(spd, 0.45) * 0.58, 0, 0.42)
end
function Cbt.bossCanReach(model, row)
    local hrp = getHRP()
    local bhrp = model and (model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart)
    if not (hrp and bhrp) then
        return false
    end
    local dist = (hrp.Position - bhrp.Position).Magnitude
    local reach = tonumber(row and row.DefaultRange) or 20
    local bs = row and row.BasicString
    if type(bs) == "table" then
        reach = math.max(reach, tonumber(bs.HitboxRange) or 0)
    end
    if dist > reach + 12 then
        return false
    end
    if dist <= 14 then
        return true
    end
    local look = Vector3.new(bhrp.CFrame.LookVector.X, 0, bhrp.CFrame.LookVector.Z)
    local to = Vector3.new(hrp.Position.X - bhrp.Position.X, 0, hrp.Position.Z - bhrp.Position.Z)
    if look.Magnitude < 0.05 or to.Magnitude < 0.05 then
        return true
    end
    return look.Unit:Dot(to.Unit) > 0.02
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
    if Cbt._parryAt > 0 and (now - Cbt._parryAt) < 0.22 then
        return
    end
    Cbt._parryAt = now
    TheKing.Guard(function()
        TheKing.Fire(ParryRE)
    end, "拼刀")
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
            pcall(function()
                bag[#bag + 1] = track:GetMarkerReachedSignal("Attack"):Connect(hitNow)
            end)
            pcall(function()
                bag[#bag + 1] = track:GetMarkerReachedSignal("Impact"):Connect(hitNow)
            end)
            pcall(function()
                bag[#bag + 1] = track.KeyframeReached:Connect(function(kf)
                    if type(kf) == "string" then
                        local l = string.lower(kf)
                        if string.find(l, "hit", 1, true) or string.find(l, "swing", 1, true) or string.find(l, "atk", 1, true) then
                            hitNow()
                        end
                    end
                end)
            end)
        end)
    end
    local anim = model:FindFirstChildWhichIsA("Animator", true)
    if anim then
        bag[#bag + 1] = anim.AnimationPlayed:Connect(onAnim)
        TheKing.AddConnection(bag[#bag])
        pcall(function()
            for _, tr in ipairs(anim:GetPlayingAnimationTracks()) do
                onAnim(tr)
            end
        end)
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
        if Cbt._parryScanAt > 0 and (now - Cbt._parryScanAt) < 0.22 then
            return
        end
        Cbt._parryScanAt = now
        local my = getHRP()
        for _, en in ipairs(getEnemies()) do
            if en.model and en.hrp and Cbt.isBossModel(en.model) then
                if my and (en.hrp.Position - my.Position).Magnitude < 80 then
                    Cbt.hookBossParry(en.model)
                end
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
        Cbt.syncKite()
        Cbt.lockFace()
        return true
    end,
    OnDisable = function()
        meleeEnabled = false
        autoRotateLockUntil = 0
        if not skillAuraOn then
            Cbt.lock = nil
        end
        Cbt.syncBossParry()
        Cbt.syncKite()
        Cbt.lockFace()
        local hum = getHum()
        if hum then
            pcall(function()
                hum.AutoRotate = true
            end)
        end
    end,
    OnTick = function()
        local now = os.clock()
        -- 长按连击: 间隔跟 Cbt.atkInterval (职业×装备), 与 fireMeleeOnce 同源
        -- 朝向由 lockFace 锁目标; 发包方向是指向锁定, 不跟 WASD
        if now - meleeLastAttack >= Cbt.atkInterval() then
            fireMeleeOnce()
        end
        -- 近战双光环: 平A范围内没怪就朝最近怪小步贴脸 (0.3s 一发 MoveTo)
        -- 手动 WASD 优先于 MoveTo, 用户自己走位不受影响; 远程职业有 kite 站位不走这
        if meleeEnabled and skillAuraOn and not Cbt.isRanged() and not Cbt.kiting
            and now - autoApproachAt >= 0.3 then
            autoApproachAt = now
            Cbt.autoApproach()
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
    -- 注入早于数据加载: DataLoaded 翻 true 时补跑一次 (否则首注入 Current_Class=nil, 下拉永远 none)
    if LocalPlayer:GetAttribute("DataLoaded") ~= true then
        TheKing.AddConnection(LocalPlayer:GetAttributeChangedSignal("DataLoaded"):Connect(function()
            if LocalPlayer:GetAttribute("DataLoaded") == true then
                Cbt.syncClass()
            end
        end))
    end
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
    if pd.slot == "E" then
        -- 终极 (G键/槽位"E"): HasUltimate+UltimateReady 已在 findReadySkill 验过
        TheKing.Fire(SkillRE, "E", "tap", Vector3.new(0, 0, 0))
    else
        TheKing.Fire(SkillRE, pd.slot, "tap", Vector3.new(0, 0, 0))
    end
    lastSkillCast[pd.slot] = now
    skillAuraLastSlot = pd.slot
    if pd.slot == 3 or pd.slot == 4 then
        _meleeRangeCache.t = 0
    end
    -- 冲刺技不能冻移速 (WalkSpeed=0 会把突进掐死); 只有升空类才短冻
    skillFreezeMove = (tonumber(data and data.LiftSpeed) or 0) > 0
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
    -- 终极槽 ("E", G键) 优先: 多充能职业 1-4 技能几乎无缝, 放尾部会永久饿死
    -- Charge>=max-5 即发 (不等满格/Ready 信号, 服务端没 ready 下轮再试, 无损); 防抖 10s
    local ultMax = tonumber(LocalPlayer:GetAttribute("UltimateChargeMax")) or 100
    local ultFull = (tonumber(LocalPlayer:GetAttribute("UltimateCharge")) or 0) >= ultMax - 5
    if LocalPlayer:GetAttribute("HasUltimate") == true and ultFull
        and (now - (lastSkillCast["E"] or 0)) >= 10 then
        local tgtE = nil
        if Cbt.lock and Cbt.alive(Cbt.lock) and (Cbt.lock.hrp.Position - pos).Magnitude <= 40 then
            tgtE = Cbt.lock
        else
            local bd = 40
            for _, en in ipairs(getEnemies()) do
                if Cbt.alive(en) then
                    local d = (en.hrp.Position - pos).Magnitude
                    if d <= bd then
                        bd = d
                        tgtE = en
                    end
                end
            end
        end
        if tgtE then
            Cbt.lock = tgtE
            return { slot = "E", target = tgtE }
        end
    end
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
        Cbt.syncKite()
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
        Cbt.syncKite()
        local humOff = getHum()
        if humOff then
            pcall(function()
                humOff.AutoRotate = true
                if (humOff.WalkSpeed or 0) < 1 then
                    humOff.WalkSpeed = 16
                end
            end)
        end
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
        if now < skillBusyUntil then
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
    if prompt == Cbt.blessLast and Cbt.blessFireAt > 0 and (now - Cbt.blessFireAt) < 1.1 then
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
            if Cbt.blessUiAt <= 0 then
                Cbt.blessUiAt = os.clock()
            end
            if os.clock() - Cbt.blessUiAt > 18 then
                uiOn = false
                Cbt.blessUiAt = 0
            end
        else
            Cbt.blessUiAt = 0
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
            -- 三个候选都不是偏好: 随机选一个, 别让选择窗卡住
            bestIdx = math.random(1, #cands)
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
    if prompt == Cbt.refillLast and Cbt.refillFireAt > 0 and (now - Cbt.refillFireAt) < 1.1 then
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
        Cbt._wsWasFreeze = true
        want = 0
    else
        if now >= skillBusyUntil then
            skillFreezeMove = false
        end
        if speedEnabled then
            Cbt._wsWasFreeze = false
            want = tonumber(targetSpeed) or 35
        elseif Cbt._wsWasFreeze then
            Cbt._wsWasFreeze = false
            want = 16
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
-- 自动寻路 (冰图 Snow 主链: Room.Connectors Entry/Exit, 不去 Side)
-- 自动重开 (结算界面 RequestReplay)
-- ============================================================
local PathfindingService = game:GetService("PathfindingService")
Nav = {
    on = false,
    replayOn = false,
    pts = {},
    idx = 1,
    folder = nil,
    lastMove = 0,
    lastSprint = 0,
    lastReplay = 0,
    stuckPos = nil,
    stuckSince = 0,
    forceClear = {},
    fightCnt = nil,
    fightSince = 0,
    stuckT = 0,
    skipChest = {},
    phase = "idle",
    hallKey = "",
    moveKey = "",
    leaving = "",
    leftStart = false,
    lastRoomN = 0,
    centered = {},
    gateSave = {},
    gateList = {},
    gateScanAt = 0,
    pathFrom = nil,
    pathTo = nil,
    hudGui = nil,
    hudRoot = nil,
    hudGrad = nil,
    hudTitle = nil,
    hudReport = nil,
    hudBlood = nil,
    hudBloodAt = 0,
    hudRows = nil,
    hudDragging = false,
    hudMouse0 = nil,
    hudOrigin = nil,
    hudW = 268,
    hudH = 168,
    -- 伤害归因表: [model] = {dmg=累计伤害, max=满血值, at=最后受击}; DamageDisplay 事件喂入 (血条数据源)
    dmgTrack = {},
    mobMaxLearn = {},
    wasDead = false,
    lastPos = nil,
    lastChar = nil,
    stuckHits = 0,
    lastHop = 0,
    potionSeen = 0,
    skipPot = {},
    potWaitKey = "",
    potWaitT = 0,
    potWaitN = 0,
}
-- 伤害归因: 二次监听 DamageDisplay remote (只读, 不干扰游戏) — 客户端怪血无同步, 这是唯一实时血量通道
-- 事件: (pos, dmg, isCrit, target?) target=Instance 按怪累计; 无 target 时按 pos 最近怪 8 格归因
Nav.wireDmgTrack = function(remote)
    remote.OnClientEvent:Connect(function(pos, dmg, isCrit, target)
        if type(dmg) ~= "number" or dmg <= 0 then
            return
        end
        local model
        if typeof(target) == "Instance" then
            -- target 可能是 Part/Humanoid 而非 Model — 归一到宿主 Model
            model = target
            if not model:IsA("Model") then
                model = model:FindFirstAncestorOfClass("Model")
            end
            -- 镜像容器包裹时再上一级
            if model and model.Parent and model.Parent.Name == "PlayerModels" then
                model = model.Parent
            end
        end
        if typeof(target) ~= "Instance" and typeof(pos) == "Vector3" then
            local best, bd = nil, 8
            for _, en in ipairs(getEnemies(true)) do
                local d = (en.hrp.Position - pos).Magnitude
                if d < bd then
                    bd = d
                    best = en.model
                end
            end
            model = best
        end
        if model then
            local t = Nav.dmgTrack[model]
            if not t then
                t = { dmg = 0, max = 0, at = 0 }
                Nav.dmgTrack[model] = t
            end
            t.dmg = t.dmg + dmg
            t.at = os.clock()
        end
    end)
end
Nav.dmgTrackListen = function()
    local player_ = ReplicatedStorage:FindFirstChild("Player")
    local remotes = player_ and player_:FindFirstChild("Remotes")
    local remote = remotes and remotes:FindFirstChild("DamageDisplay")
    if remote and (remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent")) then
        Nav.wireDmgTrack(remote)
        return true
    end
    -- 兜底: 流送延迟时等待挂载
    task.spawn(function()
        local pl = ReplicatedStorage:WaitForChild("Player", 15)
        local rm = pl and pl:WaitForChild("Remotes", 15)
        local dd = rm and rm:WaitForChild("DamageDisplay", 15)
        if dd and (dd:IsA("RemoteEvent") or dd:IsA("UnreliableRemoteEvent")) then
            Nav.wireDmgTrack(dd)
        end
    end)
    return false
end
Nav.dmgTrackListen()

-- ============ 爬塔模式 (Double Dungeon 挑战图) ============
-- 判定: Dungeon_Container.Info.Depth 存在 (普通图没有). 单竞技场, 杀戮光环打怪, 寻路禁用.
-- 自动化: ① 每5波3箱(60s过期) → Chest_Selection UI 全选走 SelectMidRunChests ② Boss 后祝福 → Boost_Selection 选第一张
Nav.towerOn = PREF.towerAuto ~= false
Nav.towerBlessAt = 0
Nav.towerChestAt = 0
function Nav.isTowerRun()
    local dc = PlayerGui:FindFirstChild("Main")
    dc = dc and dc:FindFirstChild("HUD")
    dc = dc and dc:FindFirstChild("Dungeon_Container")
    local info = dc and dc:FindFirstChild("Info")
    return info ~= nil and info:FindFirstChild("Depth") ~= nil
end
function Nav.towerWatch()
    -- 每 1.2s 查一次挑战 UI, 自动选箱/祝福 (协程常驻)
    task.spawn(function()
        while Nav.on or Nav.towerOn do
            if LocalPlayer:GetAttribute("InDungeon") == true and Nav.isTowerRun() then
                local hud = PlayerGui:FindFirstChild("Main")
                hud = hud and hud:FindFirstChild("HUD")
                local boost = hud and hud:FindFirstChild("Boost_Selection")
                local chest = hud and hud:FindFirstChild("Chest_Selection")
                local now = os.clock()
                -- 祝福: UI 可见 0.5s 后选第一张 (选完 UI 自动隐藏)
                if boost and boost.Visible and now - Nav.towerBlessAt > 4 then
                    Nav.towerBlessAt = now
                    task.delay(0.5, function()
                        if boost.Visible then
                            local ok, r = pcall(function()
                                return require(game.ReplicatedStorage.Packages.Knit).GetService("DungeonBuffService"):SelectBuff(1):await()
                            end)
                            TheKing.Notify({ Title = "爬塔", Content = "祝福已自动选择 (第一张)", Icon = "sparkles" })
                        end
                    end)
                end
                -- 选箱: UI 可见 0.5s 后全选三箱
                if chest and chest.Visible and now - Nav.towerChestAt > 4 then
                    Nav.towerChestAt = now
                    task.delay(0.5, function()
                        if chest.Visible then
                            local ok, r = pcall(function()
                                return require(game.ReplicatedStorage.Packages.Knit).GetService("DungeonRunService"):SelectMidRunChests({ 1, 2, 3 }):await()
                            end)
                            TheKing.Notify({ Title = "爬塔", Content = "已自动全选 3 个箱子", Icon = "package" })
                        end
                    end)
                end
            end
            task.wait(1.2)
        end
    end)
end
function Nav.floorY(pos)
    local origin = pos + Vector3.new(0, 6, 0)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ch = getChar()
    if ch then
        params.FilterDescendantsInstances = { ch }
    end
    local hit = workspace:Raycast(origin, Vector3.new(0, -24, 0), params)
    if hit then
        return hit.Position.Y + 0.15
    end
    return pos.Y
end
function Nav.pt(x, y, z)
    return Vector3.new(x, Nav.floorY(Vector3.new(x, y, z)), z)
end
function Nav.clearMarks()
    local f = Nav.folder
    if f then
        pcall(function()
            f:Destroy()
        end)
    end
    Nav.folder = nil
end
function Nav.paintPath()
    Nav.clearMarks()
    local pts = Nav.pts
    if type(pts) ~= "table" or #pts < 1 then
        return
    end
    local fold = Instance.new("Folder")
    fold.Name = "TheKing_NavPath"
    fold.Parent = workspace
    Nav.folder = fold
    local col = Color3.fromRGB(70, 230, 90)
    local parts = {}
    for i, p in ipairs(pts) do
        local part = Instance.new("Part")
        part.Name = "wp" .. tostring(i)
        part.Anchored = true
        part.CanCollide = false
        part.CanQuery = false
        part.CanTouch = false
        part.Material = Enum.Material.Neon
        part.Color = col
        part.Transparency = 0.25
        part.Size = Vector3.new(3.2, 0.22, 3.2)
        part.CFrame = CFrame.new(p)
        part.Parent = fold
        local mesh = Instance.new("CylinderMesh")
        mesh.Parent = part
        parts[i] = part
    end
    for i = 1, #parts - 1 do
        local a = Instance.new("Attachment")
        a.Parent = parts[i]
        local b = Instance.new("Attachment")
        b.Parent = parts[i + 1]
        local beam = Instance.new("Beam")
        beam.Attachment0 = a
        beam.Attachment1 = b
        beam.FaceCamera = true
        beam.Width0 = 0.28
        beam.Width1 = 0.28
        beam.LightEmission = 0.4
        beam.Color = ColorSequence.new(col)
        beam.Transparency = NumberSequence.new(0.15)
        beam.Parent = parts[i]
    end
end
-- 离路判定: 角色到路径 polyline 的最小垂距 (各线段), 0.3s 缓存
function Nav.pathOffDist(pos)
    local pts = Nav.pts
    if type(pts) ~= "table" or #pts < 2 then
        return nil
    end
    local best = nil
    for k = 1, #pts - 1 do
        local a, b = pts[k], pts[k + 1]
        local abx, abz = b.X - a.X, b.Z - a.Z
        local apx, apz = pos.X - a.X, pos.Z - a.Z
        local ab2 = abx * abx + abz * abz
        local t = 0
        if ab2 > 0.01 then
            t = math.clamp((apx * abx + apz * abz) / ab2, 0, 1)
        end
        local cx, cz = a.X + abx * t, a.Z + abz * t
        local d = math.sqrt((pos.X - cx) ^ 2 + (pos.Z - cz) ^ 2)
        if not best or d < best then
            best = d
        end
    end
    return best
end
function Nav.setPath(list)
    Nav.pts = list or {}
    Nav.idx = 1
    Nav.stuckT = 0
    Nav.stuckHits = 0
    Nav.pathSetAt = os.clock()
    if type(Nav.pts) == "table" and #Nav.pts > 0 then
        Nav.pathFrom = Nav.pts[1]
        Nav.pathTo = Nav.pts[#Nav.pts]
    end
    Nav.paintPath()
end
function Nav.dropRoute()
    Nav.pts = {}
    Nav.idx = 1
    Nav.hallKey = ""
    Nav.moveKey = ""
    Nav.stuckT = 0
    Nav.stuckHits = 0
    Nav.pathFrom = nil
    Nav.pathTo = nil
    Nav.clearMarks()
end
function Nav.rewindToRoom(room)
    if not room then
        return
    end
    local n = Nav.roomNum(room)
    Nav.dropRoute()
    Nav.leaving = ""
    Nav.lastRoomN = n
    Nav.leftStart = n > 1
    Nav.forceClear = {}
    Nav.fightCnt = nil
    if type(Nav.centered) == "table" then
        Nav.centered[room.Name] = nil
    end
    Nav.phase = "center"
end
function Nav.rewindFromPos(pos)
    Nav.dropRoute()
    Nav.leaving = ""
    Nav.forceClear = {}
    Nav.fightCnt = nil
    local here = getCurrentRoom()
    if here then
        Nav.rewindToRoom(here)
        return
    end
    local n, bd = 0, 90
    local map = getMapDir()
    if map and pos then
        for _, ch in ipairs(map:GetChildren()) do
            if Nav.isCombatRoom(ch) then
                local c = Nav.roomCenter(ch)
                if c then
                    local d = Vector3.new(c.X - pos.X, 0, c.Z - pos.Z).Magnitude
                    if d < bd then
                        bd = d
                        n = Nav.roomNum(ch)
                    end
                end
            end
        end
    end
    if n > 0 then
        Nav.lastRoomN = n
        Nav.leftStart = n > 1
    elseif Nav.lastRoomN > 0 then
        Nav.lastRoomN = math.max(0, Nav.lastRoomN - 1)
    end
end
function Nav.watchBody(hrp, hum)
    local ch = getChar()
    local dead = (not hrp) or (not hum) or hum.Health <= 0 or LocalPlayer:GetAttribute("Dead") == true
    if dead then
        if not Nav.wasDead then
            Nav.dropRoute()
            Nav.leaving = ""
            if hum and hrp then
                pcall(function()
                    hum:MoveTo(hrp.Position)
                end)
            end
        end
        Nav.wasDead = true
        Nav.lastPos = nil
        return "dead"
    end
    local snap = Nav.wasDead == true
    if Nav.lastChar and ch and Nav.lastChar ~= ch then
        snap = true
    end
    if Nav.lastPos then
        local jump = Vector3.new(hrp.Position.X - Nav.lastPos.X, 0, hrp.Position.Z - Nav.lastPos.Z).Magnitude
        if jump > 48 then
            snap = true
        end
    end
    Nav.wasDead = false
    Nav.lastChar = ch
    Nav.lastPos = hrp.Position
    if snap then
        return "snap"
    end
    return "ok"
end
function Nav.pathLive()
    local pts = Nav.pts
    return type(pts) == "table" and #pts > 0 and Nav.idx <= #pts
end
function Nav.fmtPos(p)
    if not p then
        return "--"
    end
    return string.format("%.0f, %.0f, %.0f", p.X, p.Y, p.Z)
end
function Nav.roomTag(room)
    if not room then
        return "走廊"
    end
    local n = Nav.roomNum(room)
    if n <= 0 then
        return room.Name
    end
    local extra = ""
    if Nav.isBossRoom(room) then
        local sbId = room:GetAttribute("SpecialBossId")
        extra = sbId and (" 特殊BOSS:" .. tostring(sbId)) or " Boss房"
    elseif room:GetAttribute("IsLootRoom") == true then
        extra = " 战利品房"
    end
    return "Room_" .. n .. extra
end
function Nav.reportText()
    local p = Nav.phase
    local room = getCurrentRoom()
    local tag = Nav.roomTag(room)
    if p == "tower" then
        local info = PlayerGui:FindFirstChild("Main")
        info = info and info:FindFirstChild("HUD")
        info = info and info:FindFirstChild("Dungeon_Container")
        info = info and info:FindFirstChild("Info")
        local wv = info and info:FindFirstChild("Wave")
        wv = wv and wv:FindFirstChild("TextLabel")
        return "爬塔 " .. tostring(wv and wv.Text or "") .. ", 光环清怪中"
    end
    if p == "fight" then
        if Cbt.kiting then
            return "清理" .. tag .. "怪物, 远程拉位 (剩 " .. Nav.mobCount(room) .. ")"
        end
        return "清理" .. tag .. "怪物 (剩 " .. Nav.mobCount(room) .. ")"
    elseif p == "loot" then
        return "拾取" .. tag .. "宝箱"
    elseif p == "refill" then
        return "在" .. tag .. "补充药水"
    elseif p == "center" then
        return "进入" .. tag .. ", 走向中心"
    elseif p == "hall" then
        local k = Nav.hallKey or ""
        local tn = k:match("j:Room_(%d+)") or k:match("h:Room_(%d+)")
        if tn then
            return "穿过走廊, 前往 Room_" .. tn
        end
        return "穿过走廊, 前往下一间"
    elseif p == "boss" then
        return "Boss房 " .. tag .. " 战斗"
    elseif p == "done" then
        return "对局结算, 准备自动重开"
    elseif p == "lobby" then
        return "在大厅, 等待进本"
    elseif p == "seek" then
        return "扫描地图, 寻找下一间"
    elseif p == "down" then
        return "倒下, 等待重生"
    end
    return "待命"
end
function Nav.mobCount(room)
    if not room then
        return 0
    end
    local zone = room:FindFirstChild("Zone")
    local n = 0
    for _, en in ipairs(getEnemies(true)) do
        if not en.model:GetAttribute("IsDormant") then
            if zone and zone:IsA("BasePart") then
                local rel = zone.CFrame:PointToObjectSpace(en.hrp.Position)
                local sz = zone.Size / 2
                if math.abs(rel.X) <= sz.X and math.abs(rel.Y) <= sz.Y and math.abs(rel.Z) <= sz.Z then
                    n = n + 1
                end
            else
                n = n + 1
            end
        end
    end
    return n
end
function Nav.noteProgress(pos)
    local map = getMapDir()
    if not (map and pos) then
        return
    end
    for _, ch in ipairs(map:GetChildren()) do
        local n = Nav.roomNum(ch)
        -- 尽头小房 (只有 Entry) 不算主链进度, 否则出岔路后大房号变小被当成过廊
        if n > Nav.lastRoomN and Nav.inZone(ch, pos) and Nav.conn(ch, "Exit") then
            Nav.lastRoomN = n
        end
    end
    if Nav.leaving ~= "" then
        local ln = tonumber(Nav.leaving:match("^Room_(%d+)$")) or 0
        if ln > Nav.lastRoomN then
            Nav.lastRoomN = ln
        end
    end
end
function Nav.conn(room, name)
    if not room then
        return nil
    end
    local c = room:FindFirstChild("Connectors")
    return c and c:FindFirstChild(name)
end
function Nav.inZone(room, pos)
    if not (room and pos) then
        return false
    end
    local zone = room:FindFirstChild("Zone")
    if not (zone and zone:IsA("BasePart")) then
        return false
    end
    local rel = zone.CFrame:PointToObjectSpace(pos)
    local sz = zone.Size / 2
    return math.abs(rel.X) <= sz.X and math.abs(rel.Y) <= sz.Y + 8 and math.abs(rel.Z) <= sz.Z
end
function Nav.posOf(inst)
    if not inst then
        return nil
    end
    if inst:IsA("BasePart") then
        return inst.Position
    end
    if inst:IsA("Model") then
        local ok, cf = pcall(function()
            return inst:GetBoundingBox()
        end)
        if ok and cf then
            return cf.Position
        end
        local pp = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
        return pp and pp.Position
    end
    local p = inst:FindFirstAncestorWhichIsA("BasePart")
    return p and p.Position
end
function Nav.potionCount()
    local n = Nav.potionStock()
    if n then
        return n
    end
    return 9
end
function Nav.potionStock()
    local pg = PlayerGui
    local hud = pg and pg:FindFirstChild("Main")
    hud = hud and hud:FindFirstChild("HUD")
    local act = hud and hud:FindFirstChild("Actions")
    local bot = act and act:FindFirstChild("Bottom")
    local health = bot and bot:FindFirstChild("Actions")
    health = health and health:FindFirstChild("Health")
    local amt = health and health:FindFirstChild("Amount")
    if not (amt and amt:IsA("TextLabel")) then
        return nil
    end
    local txt = tostring(amt.Text)
    local n = tonumber(txt:match("(%d+)"))
    if not n then
        return nil
    end
    local cap = tonumber(txt:match("%d+%s*/%s*(%d+)")) or 0
    if health then
        local mx = health:FindFirstChild("Max") or health:FindFirstChild("Limit")
        if mx and mx:IsA("TextLabel") then
            local m = tonumber(tostring(mx.Text):match("(%d+)"))
            if m and m > cap then
                cap = m
            end
        end
    end
    -- 账号属性经常高于本局能灌的量, 只作「可能还没满」的参考; 锅边灌完靠 skipPot 收束
    local keys = { "MaxPotions", "Potion_Max", "Stat_MaxPotions", "HealthPotionMax" }
    for i = 1, #keys do
        local v = tonumber(LocalPlayer:GetAttribute(keys[i]))
        if v and v > cap then
            cap = v
        end
    end
    Nav.potionSeen = math.max(Nav.potionSeen or 0, n, cap)
    if cap < 1 then
        cap = Nav.potionSeen
    end
    if cap < 1 then
        cap = n
    end
    return n, cap
end
function Nav.needPotion()
    local n, cap = Nav.potionStock()
    if not n then
        return false
    end
    if n <= 0 then
        return true
    end
    return n < (cap or n)
end
function Nav.potDone(room)
    return room and Nav.skipPot[room.Name] == true
end
function Nav.markPotDone(room)
    if type(Nav.skipPot) ~= "table" then
        Nav.skipPot = {}
    end
    if room then
        Nav.skipPot[room.Name] = true
    end
    Nav.pts = {}
    Nav.idx = 1
    Nav.potWaitKey = ""
    Nav.potWaitT = 0
    Nav.potWaitN = 0
end
function Nav.notePotWait(room, n, cap)
    if not room then
        return false
    end
    local now = os.clock()
    n = tonumber(n)
    cap = tonumber(cap)
    if Nav.potWaitKey ~= room.Name then
        Nav.potWaitKey = room.Name
        Nav.potWaitT = now
        Nav.potWaitN = n or 0
    end
    if n and cap and n >= cap then
        Nav.markPotDone(room)
        return true
    end
    if n and n > (Nav.potWaitN or 0) then
        Nav.potWaitN = n
        Nav.potWaitT = now
        return false
    end
    if now - (Nav.potWaitT or 0) > 2 then
        Nav.markPotDone(room)
        return true
    end
    return false
end
function Nav.touchStation(room, st, hrp)
    local p = Nav.posOf(st)
    if not (p and hrp) then
        Nav.markPotDone(room)
        return "done"
    end
    if (hrp.Position - p).Magnitude > 8 then
        if Nav.idx > #Nav.pts or #Nav.pts < 1 then
            Nav.go(hrp.Position, p)
        end
        Nav.walkTick()
        return "walk"
    end
    Cbt.tryRefillPotions()
    local n, cap = Nav.potionStock()
    if Nav.notePotWait(room, n, cap) then
        return "done"
    end
    return "wait"
end
function Nav.combatByNum(n)
    n = tonumber(n) or 0
    if n < 1 then
        return nil
    end
    local map = getMapDir()
    if not map then
        return nil
    end
    for _, ch in ipairs(map:GetChildren()) do
        if Nav.roomNum(ch) == n and Nav.isCombatRoom(ch) then
            return ch
        end
    end
    return nil
end
function Nav.uiRoot()
    local hud = PlayerGui:FindFirstChild("Main")
    hud = hud and hud:FindFirstChild("HUD")
    local dc = hud and hud:FindFirstChild("Dungeon_Container")
    return dc and dc:FindFirstChild("Completion_Progress")
end
function Nav.uiCurrentIndex()
    local root = Nav.uiRoot()
    if not root then
        return 0
    end
    local cur = root:FindFirstChild("Current")
    local list = root:FindFirstChild("List")
    if not (cur and list) then
        return 0
    end
    local best, bd, i = 1, 1e9, 0
    for _, slot in ipairs(list:GetChildren()) do
        if slot.Name == "ZoneSlot" then
            i = i + 1
            local d = math.abs(slot.AbsolutePosition.X - cur.AbsolutePosition.X)
            if d < bd then
                bd = d
                best = i
            end
        end
    end
    return best
end
function Nav.uiSlot(i)
    local root = Nav.uiRoot()
    local list = root and root:FindFirstChild("List")
    if not list then
        return nil
    end
    local n = 0
    for _, slot in ipairs(list:GetChildren()) do
        if slot.Name == "ZoneSlot" then
            n = n + 1
            if n == i then
                return slot
            end
        end
    end
    return nil
end
function Nav.uiCleared()
    local slot = Nav.uiSlot(Nav.uiCurrentIndex())
    local done = slot and slot:FindFirstChild("Completed")
    return done and done.Visible == true
end
function Nav.uiBoss()
    -- HUD 绿标会提前贴到 Boss 格, 不能当「人已经进 Boss 房」
    local slot = Nav.uiSlot(Nav.uiCurrentIndex())
    local b = slot and slot:FindFirstChild("Boss")
    return b and b.Visible == true
end
function Nav.isBossRoom(room)
    if not room then
        return false
    end
    local sp = room:FindFirstChild("Spawns")
    if not sp then
        return false
    end
    for _, d in ipairs(sp:GetDescendants()) do
        if d.Name == "Boss_Spawn" then
            return true
        end
    end
    return false
end
function Nav.promptAt(inst)
    if not inst then
        return nil
    end
    if inst:IsA("ProximityPrompt") then
        return inst
    end
    for _, d in ipairs(inst:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Enabled then
            return d
        end
    end
    for _, d in ipairs(inst:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            return d
        end
    end
    return nil
end
function Nav.firePrompt(prompt)
    if not prompt then
        return
    end
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
function Nav.roomCenter(room)
    if not room then
        return nil
    end
    local zone = room:FindFirstChild("Zone")
    if zone and zone:IsA("BasePart") then
        local p = zone.Position
        return Nav.pt(p.X, p.Y, p.Z)
    end
    return Nav.posOf(room)
end
function Nav.thinPts(list)
    if type(list) ~= "table" or #list <= 2 then
        return list
    end
    local out = { list[1] }
    for i = 2, #list - 1 do
        local prev = out[#out]
        local cur = list[i]
        local nxt = list[i + 1]
        local a = Vector3.new(cur.X - prev.X, 0, cur.Z - prev.Z)
        local b = Vector3.new(nxt.X - cur.X, 0, nxt.Z - cur.Z)
        if a.Magnitude >= 18 then
            local turn = true
            if a.Magnitude > 0.2 and b.Magnitude > 0.2 then
                turn = a.Unit:Dot(b.Unit) < 0.88
            end
            if turn then
                out[#out + 1] = cur
            end
        end
    end
    out[#out + 1] = list[#list]
    return out
end
function Nav.shapePts(from, to)
    local a = Nav.pt(from.X, from.Y, from.Z)
    local b = Nav.pt(to.X, to.Y, to.Z)
    local dx, dz = b.X - a.X, b.Z - a.Z
    if math.abs(dx) < 14 or math.abs(dz) < 14 then
        return { a, b }
    end
    local c1 = Nav.pt(b.X, a.Y, a.Z)
    local c2 = Nav.pt(a.X, a.Y, b.Z)
    local mid = Vector3.new((a.X + b.X) * 0.5, a.Y, (a.Z + b.Z) * 0.5)
    local elbow = c1
    if (c2 - mid).Magnitude < (c1 - mid).Magnitude then
        elbow = c2
    end
    local off = Vector3.new(mid.X - elbow.X, 0, mid.Z - elbow.Z)
    if off.Magnitude > 0.4 then
        elbow = Nav.pt(elbow.X + off.Unit.X * 9, elbow.Y, elbow.Z + off.Unit.Z * 9)
    end
    return { a, elbow, b }
end
function Nav.groundAt(x, z, baseY)
    local origin = Vector3.new(x, baseY + 3.2, z)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ch = getChar()
    if ch then
        params.FilterDescendantsInstances = { ch }
    end
    local hit = workspace:Raycast(origin, Vector3.new(0, -10, 0), params)
    if hit and math.abs(hit.Position.Y - baseY) <= 4.5 then
        return Vector3.new(x, hit.Position.Y + 0.15, z)
    end
    return Vector3.new(x, baseY, z)
end
function Nav.laneMid(pos, travel)
    if not pos then
        return pos
    end
    local perp = Vector3.new(-(travel and travel.Z or 0), 0, travel and travel.X or 0)
    if perp.Magnitude < 0.08 then
        return pos
    end
    perp = perp.Unit
    local origin = pos + Vector3.new(0, 2.2, 0)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ch = getChar()
    local fold = Nav.folder
    if ch and fold then
        params.FilterDescendantsInstances = { ch, fold }
    elseif ch then
        params.FilterDescendantsInstances = { ch }
    end
    local maxD = 16
    local hitA = workspace:Raycast(origin, perp * maxD, params)
    local hitB = workspace:Raycast(origin, -perp * maxD, params)
    local dA = hitA and Vector3.new(hitA.Position.X - pos.X, 0, hitA.Position.Z - pos.Z).Magnitude or maxD
    local dB = hitB and Vector3.new(hitB.Position.X - pos.X, 0, hitB.Position.Z - pos.Z).Magnitude or maxD
    if dA >= 14 and dB >= 14 then
        return pos
    end
    local want = 6.5
    if hitA and hitB then
        return Nav.pt((hitA.Position.X + hitB.Position.X) * 0.5, pos.Y, (hitA.Position.Z + hitB.Position.Z) * 0.5)
    end
    if hitA and dA < want then
        local push = want - dA
        return Nav.pt(pos.X - perp.X * push, pos.Y, pos.Z - perp.Z * push)
    end
    if hitB and dB < want then
        local push = want - dB
        return Nav.pt(pos.X + perp.X * push, pos.Y, pos.Z + perp.Z * push)
    end
    return pos
end
function Nav.centerLane(list, keepEnds)
    if type(list) ~= "table" or #list < 2 then
        return list
    end
    local out = {}
    for i = 1, #list do
        local p = list[i]
        if keepEnds and (i == 1 or i == #list) then
            out[i] = p
        else
            local nxt = list[math.min(i + 1, #list)]
            local prev = list[math.max(i - 1, 1)]
            local d = Vector3.new(nxt.X - prev.X, 0, nxt.Z - prev.Z)
            if d.Magnitude < 0.4 then
                d = Vector3.new(p.X - prev.X, 0, p.Z - prev.Z)
            end
            out[i] = Nav.laneMid(p, d)
        end
    end
    return out
end
function Nav.dropHigh(list, baseY)
    local out = {}
    for _, p in ipairs(list) do
        if math.abs(p.Y - baseY) <= 4.5 then
            out[#out + 1] = Nav.groundAt(p.X, p.Z, baseY)
        end
    end
    if #out < 2 then
        return nil
    end
    return out
end
function Nav.isSoftPart(d)
    if not (d and d:IsA("BasePart")) then
        return false
    end
    local n = d.Name
    if n == "Gate" or n == "Iron Gate" then
        return true
    end
    if n == "Zone" or n == "Entry" or n == "Exit" or n == "Side" or n == "TileAnchor" or n == "Part" then
        return false
    end
    if n:find("Wall") or n:find("Floor") or n:find("Ceiling") then
        return false
    end
    local low = string.lower(n)
    if low:find("hitbox") or low:find("torso") or low:find("dummy") or low:find("humanoid") then
        return false
    end
    if d.Size.Y >= 7.5 or math.max(d.Size.X, d.Size.Z) >= 14 then
        return false
    end
    if low:find("wooden") or low:find("crate") or low:find("barrel") or low:find("firewood") then
        return true
    end
    if low:find("coal") or low:find("pile") or low:find("pote") or low:find("chest") then
        return true
    end
    if low:find("box") or low:find("rock") or low:find("urn") then
        return true
    end
    return false
end
function Nav.releaseGates()
    local saved = Nav.gateSave
    if type(saved) == "table" then
        for part, col in pairs(saved) do
            if part and part.Parent then
                pcall(function()
                    if type(col) == "table" then
                        part.CanCollide = col.c
                        if col.q ~= nil then
                            part.CanQuery = col.q
                        end
                    else
                        part.CanCollide = col
                    end
                end)
            end
        end
    end
    Nav.gateSave = {}
    Nav.gateList = {}
    Nav.gateScanAt = 0
end
function Nav.softenNear(pos)
    if not pos then
        return
    end
    local now = os.clock()
    if now - (Nav.gateScanAt or 0) > 1.5 then
        Nav.gateScanAt = now
        local list = {}
        local map = getMapDir()
        if map then
            for _, d in ipairs(map:GetDescendants()) do
                if Nav.isSoftPart(d) then
                    list[#list + 1] = d
                end
            end
        end
        Nav.gateList = list
    end
    local list = Nav.gateList
    if type(list) ~= "table" then
        return
    end
    if type(Nav.gateSave) ~= "table" then
        Nav.gateSave = {}
    end
    for _, d in ipairs(list) do
        if d.Parent and (d.Position - pos).Magnitude < 42 then
            if Nav.gateSave[d] == nil then
                Nav.gateSave[d] = { c = d.CanCollide, q = d.CanQuery }
            end
            if d.CanCollide then
                d.CanCollide = false
            end
            if d.CanQuery then
                d.CanQuery = false
            end
        end
    end
end
function Nav.computePts(from, to, allowHigh)
    allowHigh = allowHigh == true
    local a = Nav.pt(from.X, from.Y, from.Z)
    local b
    if allowHigh then
        b = Nav.pt(to.X, to.Y, to.Z)
    else
        b = Nav.groundAt(to.X, to.Z, a.Y)
    end
    Nav.softenNear(a)
    Nav.softenNear(b)
    local path
    local okCreate = pcall(function()
        path = PathfindingService:CreatePath({
            AgentRadius = 4,
            AgentHeight = 5,
            AgentCanJump = allowHigh,
            WaypointSpacing = 7,
        })
    end)
    local raw
    if okCreate and path then
        local ok = pcall(function()
            path:ComputeAsync(a, b)
        end)
        if ok and path.Status == Enum.PathStatus.Success then
            local wps = path:GetWaypoints()
            if #wps >= 2 then
                raw = {}
                for _, wp in ipairs(wps) do
                    if allowHigh or wp.Action ~= Enum.PathWaypointAction.Jump then
                        raw[#raw + 1] = Vector3.new(wp.Position.X, wp.Position.Y, wp.Position.Z)
                    end
                end
            end
        end
    end
    if not (raw and #raw >= 2) then
        raw = Nav.shapePts(a, b)
    end
    if not allowHigh then
        raw = Nav.dropHigh(raw, a.Y) or Nav.shapePts(a, b)
        raw = Nav.dropHigh(raw, a.Y) or { a, b }
    end
    return Nav.thinPts(Nav.centerLane(raw, allowHigh))
end
function Nav.chestInRoom(room)
    if not room then
        return nil
    end
    local map = getMapDir()
    if not map then
        return nil
    end
    for _, m in ipairs(map:GetChildren()) do
        if m.Name:match("^DungeonChest_") and m:IsA("Model") and not Nav.skipChest[m] then
            local p = Nav.posOf(m)
            if p and Nav.inZone(room, p) then
                return m
            end
        end
    end
    return nil
end
-- 房内 (或区) 最近活怪; 找不到返回 nil
function Nav.nearestEnemyIn(room, fromPos)
    local z = room and room:FindFirstChild("Zone")
    if not (z and z:IsA("BasePart")) then
        return nil
    end
    local nearest, nd = nil, 1e9
    for _, en in ipairs(getEnemies(true)) do
        if not en.model:GetAttribute("IsDormant") and en.hrp.Parent then
            local rel = z.CFrame:PointToObjectSpace(en.hrp.Position)
            local sz = z.Size / 2
            if math.abs(rel.X) <= sz.X and math.abs(rel.Z) <= sz.Z then
                local d = (en.hrp.Position - (fromPos or en.hrp.Position)).Magnitude
                if d < nd then
                    nd = d
                    nearest = en
                end
            end
        end
    end
    return nearest
end
function Nav.nextChest(room)
    if not room then
        return nil
    end
    local map = getMapDir()
    if not map then
        return nil
    end
    local hrp = getHRP()
    local pos = hrp and hrp.Position
    local best, bd = nil, 1e9
    for _, m in ipairs(map:GetChildren()) do
        if m.Name:match("^DungeonChest_") and m:IsA("Model") and not Nav.skipChest[m] then
            local p = Nav.posOf(m)
            if p and Nav.inZone(room, p) then
                local pr = Nav.promptAt(m)
                if pr and (pr.Enabled or pr.ActionText == "Loot") then
                    local d = pos and (p - pos).Magnitude or 0
                    if d < bd then
                        bd = d
                        best = m
                    end
                end
            end
        end
    end
    return best
end
function Nav.stationIn(room)
    local map = getMapDir()
    if not map then
        return nil
    end
    for _, m in ipairs(map:GetChildren()) do
        if m.Name == "Potion_Station" then
            local p = Nav.posOf(m)
            if p and (not room or Nav.inZone(room, p)) then
                return m
            end
        end
    end
    return nil
end
function Nav.corridorLoot(fromPos, toPos)
    local map = getMapDir()
    if not map then
        return {}
    end
    local mid = (fromPos + toPos) * 0.5
    local span = (toPos - fromPos).Magnitude * 0.55 + 18
    local out = {}
    for _, m in ipairs(map:GetChildren()) do
        local want = m.Name == "Blessing_Altar" or (type(m.Name) == "string" and m.Name:match("^DungeonChest_"))
        if want then
            local p = Nav.posOf(m)
            if p and (p - mid).Magnitude <= span then
                local inRoom = false
                for _, r in ipairs(map:GetChildren()) do
                    if r.Name:match("^Room_%d+$") and Nav.inZone(r, p) then
                        inRoom = true
                        break
                    end
                end
                if not inRoom or m.Name == "Blessing_Altar" then
                    out[#out + 1] = m
                end
            end
        end
    end
    table.sort(out, function(a, b)
        return (Nav.posOf(a) - fromPos).Magnitude < (Nav.posOf(b) - fromPos).Magnitude
    end)
    return out
end
function Nav.roomNum(room)
    return tonumber(room and room.Name and room.Name:match("^Room_(%d+)$")) or 0
end
function Nav.isCombatRoom(room)
    return isCombatRoomModel(room)
end
function Nav.nextHop(room)
    if not room then
        return nil
    end
    local exitP = Nav.conn(room, "Exit")
    if not (exitP and exitP:IsA("BasePart")) then
        return nil
    end
    local map = getMapDir()
    if not map then
        return nil
    end
    local sides = {}
    local con = room:FindFirstChild("Connectors")
    if con then
        for _, p in ipairs(con:GetChildren()) do
            if p.Name == "Side" and p:IsA("BasePart") then
                sides[#sides + 1] = p
            end
        end
    end
    local myN = Nav.roomNum(room)
    local best, bestE, bestN, bd = nil, nil, 1e9, 420
    for _, ch in ipairs(map:GetChildren()) do
        local n = Nav.roomNum(ch)
        if n > myN and Nav.isCombatRoom(ch) then
            local entry = Nav.conn(ch, "Entry")
            if entry and entry:IsA("BasePart") then
                local d = (entry.Position - exitP.Position).Magnitude
                local sideHit = false
                for _, s in ipairs(sides) do
                    if (entry.Position - s.Position).Magnitude + 4 < d then
                        sideHit = true
                        break
                    end
                end
                if not sideHit and d < 420 then
                    if n < bestN or (n == bestN and d < bd) then
                        bestN = n
                        bd = d
                        best = ch
                        bestE = entry
                    end
                end
            end
        end
    end
    return best, exitP, bestE
end
function Nav.nextCombatFrom(fromPos, afterN)
    local map = getMapDir()
    if not (map and fromPos) then
        return nil
    end
    afterN = tonumber(afterN) or 0
    local best, bestE, bestN, bd = nil, nil, 1e9, 420
    for _, ch in ipairs(map:GetChildren()) do
        local n = Nav.roomNum(ch)
        if n > afterN and Nav.isCombatRoom(ch) then
            local entry = Nav.conn(ch, "Entry")
            local dest = entry and entry.Position or Nav.roomCenter(ch)
            if dest then
                local d = (dest - fromPos).Magnitude
                if d < 22 then
                    -- already at this room's door/center, look further
                elseif d < 420 and n < bestN then
                    bestN = n
                    bd = d
                    best = ch
                    bestE = entry
                elseif d < 420 and n == bestN and d < bd then
                    bd = d
                    best = ch
                    bestE = entry
                end
            end
        end
    end
    return best, bestE
end
function Nav.sprint()
    local now = os.clock()
    if now - Nav.lastSprint < 0.45 then
        return
    end
    Nav.lastSprint = now
    local hum = getHum()
    if hum and hum.MoveDirection.Magnitude > 0.05 then
        if LocalPlayer:GetAttribute("Sprint_Active") ~= true then
            TheKing.Fire(SprintRE, "start")
        end
    end
end
function Nav.doJump(hum)
    if not hum then
        return
    end
    pcall(function()
        hum.Jump = true
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end)
end
function Nav.stuckHop(hum)
    local now = os.clock()
    if now - (Nav.lastHop or 0) < 0.85 then
        return
    end
    Nav.lastHop = now
    Nav.doJump(hum)
    task.delay(0.16, function()
        if hubAlive and Nav.on then
            Nav.doJump(getHum())
        end
    end)
end
function Nav.walkTick()
    local hrp = getHRP()
    local hum = getHum()
    local pts = Nav.pts
    if not (hrp and hum and type(pts) == "table" and #pts > 0) then
        return false
    end
    if Nav.idx > #pts then
        return true
    end
    Nav.softenNear(hrp.Position)
    -- 离路重规划: 只在"垂直偏离整条路径"时触发 (点到各线段垂距全 >45); 行走中离端点远是常态, 不误杀
    do
        local off = Nav.pathOffDist(hrp.Position)
        if off and off > 45 and now - (Nav.pathSetAt or 0) > 3 then
            Nav.dropRoute()
            return false
        end
    end
    local goal = pts[Nav.idx]
    local flat = Vector3.new(goal.X - hrp.Position.X, 0, goal.Z - hrp.Position.Z)
    if flat.Magnitude < 5.5 then
        Nav.idx = Nav.idx + 1
        Nav.stuckT = 0
        Nav.moveKey = ""
        if Nav.idx > #pts then
            return true
        end
        goal = pts[Nav.idx]
    end
    -- 前方挡路侧滑: goal 方向短距被挡时往更空旷侧偏移, 少正面撞墙角/杂物
    if flat.Magnitude > 2 then
        local dir = flat.Unit
        local org = Vector3.new(hrp.Position.X, hrp.Position.Y + 2, hrp.Position.Z)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        local ex = { getChar() or workspace }
        if Nav.folder then
            ex[#ex + 1] = Nav.folder
        end
        params.FilterDescendantsInstances = ex
        local hit = workspace:Raycast(org, dir * 5.5, params)
        if hit then
            local function probe(ang)
                local c, s = math.cos(ang), math.sin(ang)
                local d = Vector3.new(dir.X * c - dir.Z * s, 0, dir.X * s + dir.Z * c)
                local h = workspace:Raycast(org, d * 6.5, params)
                return h and (h.Position - hrp.Position).Magnitude or 6.5
            end
            local dl, dr = probe(math.rad(60)), probe(math.rad(-60))
            if math.max(dl, dr) > 4 then
                local ang = dl >= dr and math.rad(60) or math.rad(-60)
                local c, s = math.cos(ang), math.sin(ang)
                local nd = Vector3.new(dir.X * c - dir.Z * s, 0, dir.X * s + dir.Z * c)
                goal = Nav.pt(goal.X + nd.X * 3.5, goal.Y, goal.Z + nd.Z * 3.5)
            end
        end
    end
    local now = os.clock()
    local gk = string.format("%.0f:%.0f:%d", goal.X, goal.Z, Nav.idx)
    if Nav.moveKey ~= gk or (now - Nav.lastMove) > 1.25 then
        Nav.moveKey = gk
        Nav.lastMove = now
        pcall(function()
            hum:MoveTo(Vector3.new(goal.X, hrp.Position.Y, goal.Z))
        end)
    end
    Nav.sprint()
    if Nav.stuckT <= 0 then
        Nav.stuckT = now
        Nav.stuckPosX = hrp.Position.X
        Nav.stuckPosZ = hrp.Position.Z
    elseif now - Nav.stuckT > 2.8 then
        local moved = math.abs(hrp.Position.X - (Nav.stuckPosX or 0)) + math.abs(hrp.Position.Z - (Nav.stuckPosZ or 0))
        Nav.stuckT = now
        Nav.stuckPosX = hrp.Position.X
        Nav.stuckPosZ = hrp.Position.Z
        if moved >= 2.2 then
            Nav.stuckHits = 0
        else
            Nav.stuckHits = (Nav.stuckHits or 0) + 1
            Nav.stuckHop(hum)
            if Nav.stuckHits >= 3 then
                local here = getCurrentRoom()
                if here then
                    Nav.rewindToRoom(here)
                else
                    Nav.rewindFromPos(hrp.Position)
                end
                return false
            end
            if Nav.stuckHits >= 2 then
                Nav.idx = Nav.idx + 1
                Nav.moveKey = ""
            end
        end
    end
    return false
end
function Nav.go(from, to, allowHigh)
    if not (from and to) then
        return
    end
    Nav.setPath(Nav.computePts(from, to, allowHigh))
end
function Nav.stop()
    Nav.on = false
    Nav.pts = {}
    Nav.idx = 1
    Nav.phase = "idle"
    Nav.forceClear = {}
    Nav.fightCnt = nil
    Nav.releaseGates()
    Nav.clearMarks()
    Nav.hudDestroy()
    local hum = getHum()
    if hum then
        pcall(function()
            hum:MoveTo(hum.RootPart and hum.RootPart.Position or Vector3.zero)
        end)
    end
end
function Nav.atEnd()
    local mainG = PlayerGui:FindFirstChild("Main")
    local hud = mainG and mainG:FindFirstChild("HUD")
    if not hud then
        return false
    end
    for _, container in ipairs(hud:GetChildren()) do
        if container:IsA("Frame") and container.Name:find("Container") then
            local comp = container:FindFirstChild("Completion_Info")
            if comp and comp.Visible then
                return true
            end
        end
    end
    return false
end
function Nav.tickPath()
    if not hubAlive or not Nav.on then
        return
    end
    if LocalPlayer:GetAttribute("InDungeon") ~= true then
        Nav.phase = "lobby"
        Nav.potionSeen = 0
        Nav.skipPot = {}
        Nav.potWaitKey = ""
        Nav.hudRefresh()
        return
    end
    if Nav.atEnd() then
        Nav.phase = "done"
        Nav.clearMarks()
        Nav.hudRefresh()
        return
    end
    -- 爬塔模式 (Double Dungeon): 单竞技场不寻路, 杀戮光环打怪 + towerWatch 管箱子/祝福
    if Nav.isTowerRun() then
        Nav.phase = "tower"
        Nav.hudRefresh()
        return
    end
    local hrp = getHRP()
    local hum = getHum()
    local body = Nav.watchBody(hrp, hum)
    if body == "dead" then
        Nav.phase = "down"
        Nav.hudRefresh()
        return
    end
    if body == "snap" then
        Nav.rewindFromPos(hrp.Position)
    else
        Nav.noteProgress(hrp.Position)
    end
    local room = getCurrentRoom()
        if room and Nav.roomNum(room) < Nav.lastRoomN then
        local mid = Nav.roomCenter(room)
        local deep = mid and Vector3.new(mid.X - hrp.Position.X, 0, mid.Z - hrp.Position.Z).Magnitude < 32
        -- 刚清完离开的房不回拉 (特殊BOSS打完出门瞬间还叠在旧房 Zone 上, 误判"死亡回退"会把人带回去)
        local freshCleared = Nav.leaving == room.Name and not roomHasEnemies(room)
        if (deep or body == "snap") and not freshCleared then
            -- 死亡回上一间 / 人已经站在旧房里面, 进度回退
            Nav.rewindToRoom(room)
        else
            -- 还踩在上一间 Zone 门口叠区, 当走廊, 禁止拉回中心
            room = nil
        end
    end
    if room and Nav.leaving ~= "" and room.Name ~= Nav.leaving then
        Nav.leaving = ""
    end
    if room then
        local n = Nav.roomNum(room)
        if n > 0 and n > Nav.lastRoomN and Nav.conn(room, "Exit") then
            Nav.lastRoomN = n
        end
    end
    if room and Nav.leaving ~= room.Name and not Nav.centered[room.Name] and not (Cbt.isRanged() and roomHasEnemies(room)) then
        local mid = Nav.roomCenter(room)
        if mid then
            local toMid = Vector3.new(mid.X - hrp.Position.X, 0, mid.Z - hrp.Position.Z)
            if toMid.Magnitude > 14 then
                Nav.phase = "center"
                local ck = "c:" .. room.Name
                if Nav.hallKey ~= ck then
                    Nav.hallKey = ck
                    Nav.go(hrp.Position, mid)
                end
                Nav.walkTick()
                Nav.hudRefresh()
                return
            end
            Nav.centered[room.Name] = true
        end
    elseif room and not Nav.centered[room.Name] then
        Nav.centered[room.Name] = true
    end
    if room and roomHasEnemies(room) and not Nav.forceClear[room.Name] then
        Nav.phase = "fight"
        -- 拉怪: 房里有活怪但光环够不着就走过去; 怪进光环后停手让光环接管
        -- 远程职业 kite 循环负责站位, 不抢路
        local nearest, nd, cnt, hpSum = nil, 1e9, 0, 0
        for _, en in ipairs(getEnemies()) do
            if Cbt.alive(en) and not en.model:GetAttribute("IsDormant") then
                cnt = cnt + 1
                local hum = en.hrp.Parent and en.hrp.Parent:FindFirstChildOfClass("Humanoid")
                hpSum = hpSum + (hum and hum.Health or 0)
                local d = (en.hrp.Position - hrp.Position).Magnitude
                if d < nd then
                    nd = d
                    nearest = en
                end
            end
        end
        if nearest and not Cbt.isRanged() and nd > (getMeleeRange() or 16) then
            local fk = "f:" .. nearest.model:GetFullName()
            if Nav.hallKey ~= fk or not Nav.pathLive() then
                Nav.hallKey = fk
                Nav.go(hrp.Position, nearest.hrp.Position)
            end
            Nav.walkTick()
        elseif nearest and nd <= (getMeleeRange() or 16) then
            Nav.pts = {}
            Nav.idx = 1
        end
        -- 兜底: 怪数不减 **且总血量不降** 才算打不到 (特殊BOSS 就 1 只, 怪数恒定, 血在掉=正在输出不能跳)
        -- Boss 房 240s (特殊BOSS 血厚), 普通房 60s
        local limit = Nav.isBossRoom(room) and 240 or 60
        if cnt ~= (Nav.fightCnt or -1) then
            Nav.fightCnt = cnt
            Nav.fightHp = hpSum
            Nav.fightSince = os.clock()
        elseif (Nav.fightHp or 1e9) - hpSum >= 1 then
            -- 血量在掉: 正在输出, 重置计时
            Nav.fightHp = hpSum
            Nav.fightSince = os.clock()
        elseif os.clock() - (Nav.fightSince or 0) > limit then
            Nav.forceClear[room.Name] = true
            Nav.fightCnt = nil
            TheKing.Notify({ Title = "自动寻路", Content = room.Name .. " 有怪打不到, 跳过继续", Icon = "alert-triangle" })
        end
        Nav.hudRefresh()
        return
    end
    if room then
        local chest = Nav.nextChest(room)
        if chest then
            Nav.phase = "loot"
            local p = Nav.posOf(chest)
            if p then
                if (hrp.Position - p).Magnitude > 7 then
                    if Nav.idx > #Nav.pts or #Nav.pts < 1 then
                        Nav.go(hrp.Position, p, true)
                    end
                    Nav.walkTick()
                else
                    Nav.firePrompt(Nav.promptAt(chest))
                    Nav.skipChest[chest] = true
                    Nav.pts = {}
                    Nav.idx = 1
                end
            end
            Nav.hudRefresh()
            return
        end
        if Nav.needPotion() and not Nav.potDone(room) then
            local st = Nav.stationIn(room)
            if st then
                Nav.phase = "refill"
                local act = Nav.touchStation(room, st, hrp)
                if act ~= "done" then
                    Nav.hudRefresh()
                    return
                end
            end
        end
        if not Nav.isBossRoom(room) then
            local nxt, exitP, entryP = Nav.nextHop(room)
            if exitP and entryP then
                Nav.phase = "hall"
                local extras = Nav.corridorLoot(exitP.Position, entryP.Position)
                for _, m in ipairs(extras) do
                    local p = Nav.posOf(m)
                    if p and (hrp.Position - p).Magnitude < 10 then
                        Nav.firePrompt(Nav.promptAt(m))
                        if m.Name == "Blessing_Altar" and not autoBuffOn then
                            Cbt.tryOpenAltar()
                        end
                    end
                end
                local key = room.Name .. ":" .. entryP:GetFullName()
                local pathLive = Nav.pathLive()
                if Nav.hallKey ~= key or not pathLive then
                    Nav.hallKey = key
                    Nav.leaving = room.Name
                    Nav.leftStart = true
                    local chain = { hrp.Position }
                    local climb = { false }
                    if (hrp.Position - exitP.Position).Magnitude > 6 then
                        chain[#chain + 1] = exitP.Position
                        climb[#climb + 1] = false
                    end
                    for _, m in ipairs(extras) do
                        local p = Nav.posOf(m)
                        if p then
                            chain[#chain + 1] = p
                            climb[#climb + 1] = true
                        end
                    end
                    chain[#chain + 1] = entryP.Position
                    climb[#climb + 1] = false
                    local mid = nxt and Nav.roomCenter(nxt)
                    if mid then
                        chain[#chain + 1] = mid
                        climb[#climb + 1] = Nav.isBossRoom(nxt)
                    end
                    local built = {}
                    for i = 1, #chain - 1 do
                        local seg = Nav.computePts(chain[i], chain[i + 1], climb[i + 1])
                        for j, q in ipairs(seg) do
                            if not (i > 1 and j == 1) then
                                built[#built + 1] = q
                            end
                        end
                    end
                    if #built >= 2 then
                        Nav.setPath(built)
                    end
                end
                Nav.walkTick()
                Nav.hudRefresh()
                return
            end
            local nxt2 = Nav.nextCombatFrom(hrp.Position, Nav.lastRoomN)
            if nxt2 then
                Nav.phase = "hall"
                local dest = Nav.roomCenter(nxt2)
                if dest then
                    if Nav.hallKey ~= ("j:" .. nxt2.Name) then
                        Nav.hallKey = "j:" .. nxt2.Name
                        Nav.leaving = room.Name
                        Nav.leftStart = true
                        Nav.go(hrp.Position, dest, Nav.isBossRoom(nxt2))
                    end
                    Nav.walkTick()
                    Nav.hudRefresh()
                    return
                end
            end
        end
        if Nav.isBossRoom(room) then
            local nxtB, exitB, entryB = Nav.nextHop(room)
            if nxtB and exitB and entryB then
                Nav.phase = "hall"
                local key = room.Name .. ":bossout:" .. entryB:GetFullName()
                if Nav.hallKey ~= key or not Nav.pathLive() then
                    Nav.hallKey = key
                    Nav.leaving = room.Name
                    Nav.leftStart = true
                    -- 分段走: 先 Exit 门, 再下一房中心 (跨房一段算路常失败)
                    local seg1 = Nav.computePts(hrp.Position, exitB.Position, false)
                    local destB = Nav.roomCenter(nxtB) or entryB.Position
                    local seg2 = Nav.computePts(exitB.Position, destB, Nav.isBossRoom(nxtB))
                    local built = {}
                    for _, q in ipairs(seg1) do
                        built[#built + 1] = q
                    end
                    for j, q in ipairs(seg2) do
                        if j > 1 then
                            built[#built + 1] = q
                        end
                    end
                    if #built >= 2 then
                        Nav.setPath(built)
                    else
                        Nav.go(hrp.Position, destB, Nav.isBossRoom(nxtB))
                    end
                end
                Nav.walkTick()
                Nav.hudRefresh()
                return
            end
            Nav.phase = "boss"
        end
        Nav.hudRefresh()
        return
    end
    if Nav.pathLive() then
        Nav.phase = "hall"
        Nav.walkTick()
        Nav.hudRefresh()
        return
    end
    local afterN = Nav.lastRoomN
    if Nav.leftStart then
        afterN = math.max(afterN, 1)
    end
    local nxtH, entryH = Nav.nextCombatFrom(hrp.Position, afterN)
    if not nxtH then
        local prev = Nav.combatByNum(afterN)
        if prev then
            local hop, _, ent = Nav.nextHop(prev)
            nxtH = hop
            entryH = ent
        end
    end
    if nxtH and Nav.roomNum(nxtH) <= afterN then
        -- 目标房号没超过已到达进度 = 想往回走 (特殊BOSS房清完后 nextHop 从旧房绕回), 拒绝
        nxtH = nil
    end
    if nxtH then
        Nav.phase = "hall"
        local dest = Nav.roomCenter(nxtH) or (entryH and entryH.Position)
        if dest then
            local hk = "h:" .. nxtH.Name
            if Nav.hallKey ~= hk then
                Nav.hallKey = hk
                Nav.go(hrp.Position, dest, Nav.isBossRoom(nxtH))
            elseif not Nav.pathLive() then
                Nav.go(hrp.Position, dest, Nav.isBossRoom(nxtH))
            end
            Nav.walkTick()
        end
        Nav.hudRefresh()
        return
    end
    if Nav.lastRoomN > 0 or Nav.leftStart then
        Nav.phase = "hall"
        Nav.hudRefresh()
        return
    end
    Nav.phase = "seek"
    local nxt0, entry0 = Nav.nextCombatFrom(hrp.Position, 0)
    local dest0 = nxt0 and (Nav.roomCenter(nxt0) or (entry0 and entry0.Position))
    if dest0 then
        if not Nav.pathLive() then
            Nav.go(hrp.Position, dest0, nxt0 and Nav.isBossRoom(nxt0))
        end
        Nav.walkTick()
    end
    Nav.hudRefresh()
end
function Nav.tickReplay()
    if not (hubAlive and Nav.replayOn) then
        Nav.stuckPos = nil
        return
    end
    -- 卡死看门狗: 位置原地/小幅漂移 (<=6格) 持续 5 分钟 → 无条件重开, 不要求结算界面
    local hrp = getHRP()
    if hrp and LocalPlayer:GetAttribute("InDungeon") == true and not LocalPlayer:GetAttribute("Dead") then
        local now = os.clock()
        local pos = hrp.Position
        if Nav.stuckPos and (pos - Nav.stuckPos).Magnitude <= 6 then
            if now - Nav.stuckSince >= 300 then
                Nav.stuckPos = nil
                if now - (Nav.lastReplay or 0) >= 4 then
                    Nav.lastReplay = now
                    TheKing.Notify({ Title = "自动重开", Content = "检测到卡死 5 分钟, 强制重开", Icon = "rotate-cw" })
                    pcall(function()
                        local svc = Knit.GetService("DungeonRunService")
                        local p = svc:RequestReplay()
                        if p and p.await then
                            p:await()
                        end
                    end)
                end
                return
            end
        else
            Nav.stuckPos = pos
            Nav.stuckSince = now
        end
    else
        Nav.stuckPos = nil
    end
    if not Nav.atEnd() then
        return
    end
    local now = os.clock()
    if now - Nav.lastReplay < 4 then
        return
    end
    Nav.lastReplay = now
    pcall(function()
        local svc = Knit.GetService("DungeonRunService")
        local p = svc:RequestReplay()
        if p and p.await then
            p:await()
        end
    end)
end
function Nav.hudDefaultXY()
    local cam = workspace.CurrentCamera
    local vs = cam and cam.ViewportSize
    local h = Nav.hudH
    if vs and vs.X >= 200 and vs.Y >= 200 then
        return 8, math.max(8, vs.Y - h - 8)
    end
    return 8, 520
end
-- 拖动/缩放后统一钳制; PREF 保存走 hudSave
local function hudClampPos()
    if not Nav.hudRoot then
        return
    end
    local cam = workspace.CurrentCamera
    local vs = cam and cam.ViewportSize
    local x = Nav.hudRoot.Position.X.Offset
    local y = Nav.hudRoot.Position.Y.Offset
    if vs and vs.X >= 200 and vs.Y >= 200 then
        x = math.clamp(x, 8, math.max(8, vs.X - Nav.hudW - 8))
        y = math.clamp(y, 8, math.max(8, vs.Y - Nav.hudH - 8))
        Nav.hudRoot.Position = UDim2.fromOffset(x, y)
    end
end
function Nav.hudClamp(x, y)
    local cam = workspace.CurrentCamera
    local vs = cam and cam.ViewportSize
    if not (vs and vs.X >= 200 and vs.Y >= 200) then
        return x, y
    end
    x = math.clamp(x, 8, math.max(8, vs.X - Nav.hudW - 8))
    y = math.clamp(y, 8, math.max(8, vs.Y - Nav.hudH - 8))
    return x, y
end
function Nav.hudApply(x, y)
    x, y = Nav.hudClamp(x, y)
    if Nav.hudRoot then
        Nav.hudRoot.Position = UDim2.fromOffset(x, y)
    end
end
function Nav.hudSave()
    if not Nav.hudRoot then
        return
    end
    PREF.navBotX = math.floor(Nav.hudRoot.Position.X.Offset + 0.5)
    PREF.navBotY = math.floor(Nav.hudRoot.Position.Y.Offset + 0.5)
    prefFlush()
end
function Nav.hudMenuHidden()
    return TheKing.IsWindowHidden and TheKing.IsWindowHidden() == true
end
function Nav.hudDestroy()
    Nav.hudDragging = false
    if Nav.hudGui then
        pcall(function()
            Nav.hudGui:Destroy()
        end)
    end
    Nav.hudGui = nil
    Nav.hudRoot = nil
    Nav.hudGrad = nil
    Nav.hudTitle = nil
    Nav.hudReport = nil
    Nav.hudBlood = nil
    Nav.hudRows = nil
end
function Nav.hudLine(parent, y, label)
    local row = Instance.new("TextLabel")
    row.BackgroundTransparency = 1
    row.Font = Enum.Font.GothamMedium
    row.TextSize = 13
    row.TextColor3 = Color3.fromRGB(220, 220, 220)
    row.TextXAlignment = Enum.TextXAlignment.Left
    row.TextTruncate = Enum.TextTruncate.AtEnd
    row.Size = UDim2.new(1, -20, 0, 20)
    row.Position = UDim2.fromOffset(10, y)
    row.Text = label
    row.Parent = parent
    return row
end
function Nav.hudCreate()
    if Nav.hudGui then
        Nav.hudGui.Enabled = true
        return
    end
    for _, g in ipairs(PlayerGui:GetChildren()) do
        if g.Name == "TheKing_NavBot" then
            pcall(function()
                g:Destroy()
            end)
        end
    end
    local uis = game:GetService("UserInputService")
    local gui = Instance.new("ScreenGui")
    gui.Name = "TheKing_NavBot"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 61
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = PlayerGui
    Nav.hudGui = gui
    local root = Instance.new("Frame")
    root.Name = "Root"
    root.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
    root.BackgroundTransparency = 0.08
    root.BorderSizePixel = 0
    root.Size = UDim2.fromOffset(Nav.hudW, Nav.hudH)
    local dx, dy = Nav.hudDefaultXY()
    if tonumber(PREF.navBotX) and tonumber(PREF.navBotY) then
        dx, dy = tonumber(PREF.navBotX), tonumber(PREF.navBotY)
    end
    dx, dy = Nav.hudClamp(dx, dy)
    root.Position = UDim2.fromOffset(dx, dy)
    root.ClipsDescendants = false
    root.Parent = gui
    local rc = Instance.new("UICorner")
    rc.CornerRadius = UDim.new(0, 12)
    rc.Parent = root
    Nav.hudRoot = root
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
    Nav.hudGrad = grad
    local title = Instance.new("Frame")
    title.Name = "Title"
    title.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
    title.BackgroundTransparency = 0.12
    title.BorderSizePixel = 0
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Active = true
    title.Parent = root
    Nav.hudTitle = title
    local titleFill = Instance.new("Frame")
    titleFill.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
    titleFill.BackgroundTransparency = 0.12
    titleFill.BorderSizePixel = 0
    titleFill.Size = UDim2.new(1, 0, 0, 16)
    titleFill.Position = UDim2.new(0, 0, 1, -16)
    titleFill.ZIndex = 0
    titleFill.Active = false
    titleFill.Parent = title
    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(0, 12)
    tc.Parent = title
    local titleL = Instance.new("TextLabel")
    titleL.BackgroundTransparency = 1
    titleL.Font = Enum.Font.GothamBold
    titleL.Text = "寻路Bot"
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
    Nav.hudReport = Nav.hudLine(root, 46, "正在: 待命")
    local blood = Instance.new("Frame")
    blood.Name = "Blood"
    blood.BackgroundTransparency = 1
    blood.BorderSizePixel = 0
    blood.Size = UDim2.new(1, -20, 1, -56)
    blood.Position = UDim2.fromOffset(10, 68)
    blood.Parent = root
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = blood
    Nav.hudBlood = blood
    Nav.hudRows = {}
    title.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end
        if Nav.hudMenuHidden() then
            return
        end
        Nav.hudDragging = true
        Nav.hudMouse0 = nil
        Nav.hudOrigin = Vector2.new(Nav.hudRoot.Position.X.Offset, Nav.hudRoot.Position.Y.Offset)
    end)
    TheKing.AddConnection(RunService.Heartbeat:Connect(function()
        if not Nav.hudDragging or not Nav.hudRoot then
            return
        end
        if Nav.hudMenuHidden() then
            Nav.hudDragging = false
            Nav.hudSave()
            return
        end
        if not uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            Nav.hudDragging = false
            Nav.hudSave()
            return
        end
        local m = uis:GetMouseLocation()
        if not Nav.hudMouse0 then
            Nav.hudMouse0 = m
            return
        end
        local d = m - Nav.hudMouse0
        Nav.hudApply(Nav.hudOrigin.X + d.X, Nav.hudOrigin.Y + d.Y)
    end))
    TheKing.AddConnection(uis.InputEnded:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end
        if Nav.hudDragging then
            Nav.hudDragging = false
            Nav.hudSave()
        end
    end))
    task.defer(function()
        if tonumber(PREF.navBotX) and tonumber(PREF.navBotY) and not Nav.hudDragging then
            Nav.hudApply(tonumber(PREF.navBotX), tonumber(PREF.navBotY))
        end
    end)
end
function Nav.hudRefresh()
    if not Nav.hudRoot then
        return
    end
    if Nav.hudGrad then
        Nav.hudGrad.Rotation = (os.clock() * 28) % 360
    end
    if Nav.hudTitle then
        local canDrag = not Nav.hudMenuHidden()
        Nav.hudTitle.Active = canDrag
        pcall(function()
            Nav.hudTitle.Interactable = canDrag
        end)
    end
    -- 目的性报告: phase + 最有信息量的上下文 (目标物/房号/剩余怪), 一行说完
    if Nav.hudReport then
        Nav.hudReport.Text = "正在: " .. Nav.reportText()
    end
    -- ---- 房内怪物血条 (0.25s 节流); 特殊BOSS目标常驻顶行 ----
    local now = os.clock()
    if now - (Nav.hudBloodAt or 0) >= 0.25 then
        Nav.hudBloodAt = now
        local room = getCurrentRoom()
        local pos = getHRP() and getHRP().Position
        local mobs = {}
        if room then
            local zone = room:FindFirstChild("Zone")
            if zone and zone:IsA("BasePart") then
                for _, en in ipairs(getEnemies(true)) do
                    if not en.model:GetAttribute("IsDormant") and en.hrp.Parent then
                        local rel = zone.CFrame:PointToObjectSpace(en.hrp.Position)
                        local sz = zone.Size / 2
                        if math.abs(rel.X) <= sz.X and math.abs(rel.Z) <= sz.Z then
                            mobs[#mobs + 1] = en
                        end
                    end
                end
            end
        end
        -- Zone 空 (走廊/门口/叠区) 但附近贴身有怪: 拉进显示 (16 格), 否则战斗中窗口空白
        if #mobs == 0 then
            local pos0 = getHRP() and getHRP().Position
            if pos0 then
                for _, en in ipairs(getEnemies(true)) do
                    if not en.model:GetAttribute("IsDormant") and en.hrp.Parent
                        and (en.hrp.Position - pos0).Magnitude < 16 then
                        mobs[#mobs + 1] = en
                        if #mobs >= 6 then
                            break
                        end
                    end
                end
            end
        end
        -- 排序: 按估算剩余血量 pct 降序 (血多在前); 无数据垫底
        table.sort(mobs, function(a, b)
            local pa = Nav.mobPct(a)
            local pb = Nav.mobPct(b)
            return (pa or -1) > (pb or -1)
        end)
        local rows = Nav.hudRows or {}
        for i = #mobs + 1, #rows do
            rows[i].Frame.Visible = false
        end
        -- 血量估算: 伤害归因表 (30s 内受击) + 击杀学习表 (按怪名积累真实血量); 都没有 = 假设满血
        local nowB = os.clock()
        for model, t in pairs(Nav.dmgTrack) do
            local dead = not model.Parent or model:GetAttribute("Dead") == true
            if dead or nowB - (t.at or 0) > 30 then
                -- 击杀学习: 怪死时用累计伤害校准该怪名真实血量
                local nm = model.Name
                if dead and t.dmg and t.dmg > 0 then
                    local known = Nav.mobMaxLearn[nm] or 0
                    if t.dmg > known then
                        Nav.mobMaxLearn[nm] = t.dmg
                        prefSet("mobhp_" .. nm, math.floor(t.dmg))
                    end
                end
                Nav.dmgTrack[model] = nil
            end
        end
        for i, en in ipairs(mobs) do
            if i > 12 then
                break
            end
            local hum = en.hrp and en.hrp.Parent and en.hrp.Parent:FindFirstChildOfClass("Humanoid")
            local row = rows[i]
            if not row then
                row = Nav.bloodRow(Nav.hudBlood, i)
                rows[i] = row
            end
            row.Frame.Visible = true
            local isBoss = false
            local track = Nav.dmgTrack[en.model]
            local nm = en.model.Name
            local maxH = Nav.mobMaxLearn[nm] or 0
            if maxH <= 0 and hum and tonumber(hum.MaxHealth) and hum.MaxHealth ~= math.huge and hum.MaxHealth >= (hum.Health or 0) then
                maxH = hum.MaxHealth
            end
            local hp, haveHp
            if track and track.dmg > 0 then
                -- 伤害累计制: max 优先学习表; 累计打穿时温和放大 (血条微回涨, 继续降)
                if track.max <= 0 then
                    track.max = maxH > 0 and maxH or (track.dmg * 3)
                end
                if track.dmg >= track.max then
                    track.max = math.max(track.max * 1.6, track.dmg * 1.15)
                end
                hp = math.max(track.max - track.dmg, 0)
                maxH = track.max
                haveHp = true
            elseif maxH > 0 then
                -- 未受击: 学习表/Humanoid 参考满血
                hp = maxH
                haveHp = true
            end
            if haveHp and maxH > 0 then
                local p = math.clamp(hp / maxH, 0, 1)
                row.Fill.Size = UDim2.new(p, 0, 1, 0)
                row.Fill.BackgroundColor3 = Nav.bloodColor(p)
                -- 扣血拖尾: 血量下降时 Trail (白色) Tween 0.4s 缓动追到新值 — 拖尾期间露出暗红底
                local prev = tonumber(row.prevPct) or p
                if row.tw then
                    row.tw:Cancel()
                    row.tw = nil
                end
                if p < prev then
                    row.tw = game:GetService("TweenService"):Create(
                        row.Trail,
                        TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        { Size = UDim2.new(p, 0, 1, 0) }
                    )
                    row.tw:Play()
                else
                    row.Trail.Size = UDim2.new(p, 0, 1, 0)
                end
                row.prevPct = p
                row.Bar.Text = string.format("%.0f%%", p * 100)
            else
                -- 完全无数据: 灰白条 (不冒充血量)
                row.Fill.Size = UDim2.new(1, 0, 1, 0)
                row.Trail.Size = UDim2.new(1, 0, 1, 0)
                row.Fill.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
                row.Bar.Text = ""
            end
            row.LayoutOrder = i
        end
        -- ---- 自适应: 标题 40 + 报告 22 + 每行 18, 上限 12 行 ----
        local n = math.min(#mobs, 12)
        local newH = 68 + n * 18 + 8
        if math.abs(newH - Nav.hudH) >= 1 then
            Nav.hudReflow(newH)
        end
    end
end
-- 屏幕位置感知: 窗在下半屏 → 向上长 (底边不动); 在上半屏 → 向下长 (顶边不动)
-- 屏幕位置感知 + 弹性动画: 窗在下半屏向上长, 上半屏向下长; Back 缓动 0.35s
function Nav.hudReflow(newH)
    local oldH = Nav.hudH
    if newH == oldH or not (Nav.hudRoot and Nav.hudBlood) then
        return
    end
    Nav.hudH = newH
    local x = Nav.hudRoot.Position.X.Offset
    local y = Nav.hudRoot.Position.Y.Offset
    local cam = workspace.CurrentCamera
    local vs = cam and cam.ViewportSize
    if vs and vs.Y >= 200 and y + oldH / 2 > vs.Y / 2 then
        y = y - (newH - oldH)
    end
    x, y = Nav.hudClamp(x, y)
    -- 窗体高度延展/缩短动画 (Back 弹性, 溢出感)
    local oldTw = Nav.hudRoot:FindFirstChild("SizeTween")
    if oldTw then
        oldTw:Cancel()
        oldTw:Destroy()
    end
    local tw = game:GetService("TweenService"):Create(
        Nav.hudRoot,
        TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Size = UDim2.fromOffset(Nav.hudW, newH) }
    )
    tw.Name = "SizeTween"
    tw:Play()
    local ptw = game:GetService("TweenService"):Create(
        Nav.hudRoot,
        TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Position = UDim2.fromOffset(x, y) }
    )
    ptw.Name = "PosTween"
    ptw:Play()
end
function Nav.mobPct(en)
    local track = Nav.dmgTrack[en.model]
    local maxH = Nav.mobMaxLearn[en.model.Name] or 0
    local hum = en.hrp and en.hrp.Parent and en.hrp.Parent:FindFirstChildOfClass("Humanoid")
    if maxH <= 0 and hum and tonumber(hum.MaxHealth) and hum.MaxHealth ~= math.huge then
        maxH = hum.MaxHealth
    end
    if track and track.dmg > 0 and maxH > 0 then
        local m = math.max(track.max, maxH)
        return math.clamp(1 - track.dmg / m, 0, 1)
    end
    return nil
end
function Nav.bloodColor(p)
    if p >= 0.6 then
        return Color3.fromRGB(72, 214, 118)
    elseif p >= 0.3 then
        return Color3.fromRGB(232, 196, 64)
    end
    return Color3.fromRGB(232, 72, 72)
end
function Nav.bloodRow(parent, i)
    local row = Instance.new("Frame")
    row.Name = "Row" .. tostring(i)
    -- 行背景 = 血条底 (暗红), 扣血时露出来
    row.BackgroundColor3 = Color3.fromRGB(110, 22, 22)
    row.BackgroundTransparency = 0.15
    row.BorderSizePixel = 0
    row.Size = UDim2.new(1, 0, 0, 14)
    row.Parent = parent
    local rc = Instance.new("UICorner")
    rc.CornerRadius = UDim.new(0, 4)
    rc.Parent = row
    -- Trail: 扣血残影层 — 白色, TweenService 0.4s 缓动收缩到 Fill 位置 (经典扣血拖尾)
    local trail = Instance.new("Frame")
    trail.Name = "Trail"
    trail.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    trail.BackgroundTransparency = 0.45
    trail.BorderSizePixel = 0
    trail.Size = UDim2.new(1, 0, 1, 0)
    trail.ZIndex = 2
    trail.Parent = row
    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(0, 4)
    tc.Parent = trail
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.BackgroundColor3 = Color3.fromRGB(72, 214, 118)
    fill.BorderSizePixel = 0
    fill.Size = UDim2.new(1, 0, 1, 0)
    fill.ZIndex = 3
    fill.Parent = row
    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0, 4)
    fc.Parent = fill
    local txt = Instance.new("TextLabel")
    txt.Name = "Bar"
    txt.BackgroundTransparency = 1
    txt.Font = Enum.Font.GothamMedium
    txt.TextSize = 10
    txt.TextColor3 = Color3.fromRGB(240, 240, 240)
    txt.TextXAlignment = Enum.TextXAlignment.Right
    txt.TextTruncate = Enum.TextTruncate.AtEnd
    txt.Size = UDim2.new(1, -8, 1, 0)
    txt.Position = UDim2.fromOffset(6, 0)
    txt.ZIndex = 4
    txt.Parent = row
    row.Visible = false
    return { Frame = row, Fill = fill, Bar = txt, Trail = trail, prevPct = 1 }
end

TheKing.BindToggle(MoveTab, {
    Title = "自动寻路",
    Flag = "dr_auto_nav",
    Interval = 0.18,
    OnEnable = function()
        Nav.on = true
        Nav.skipChest = {}
        Nav.hallKey = ""
        Nav.leaving = ""
        Nav.centered = {}
        Nav.lastRoomN = 0
        Nav.leftStart = false
        Nav.wasDead = false
        Nav.lastPos = nil
        Nav.lastChar = nil
        Nav.stuckHits = 0
        Nav.potionSeen = 0
        Nav.skipPot = {}
        Nav.potWaitKey = ""
        local hrp0 = getHRP()
        if hrp0 then
            Nav.noteProgress(hrp0.Position)
        end
        if Nav.lastRoomN > 1 then
            Nav.leftStart = true
        end
        Nav.phase = "idle"
        Nav.hudCreate()
        TheKing.Notify({ Title = "自动寻路", Content = "沿主链走: 清怪→箱子→药锅→岔路小房→特殊Boss走廊→Boss。请开杀戮光环", Icon = "map" })
        return true
    end,
    OnDisable = function()
        Nav.stop()
    end,
    OnTick = function()
        Nav.tickPath()
    end,
})
TheKing.BindToggle(MoveTab, {
    Title = "自动重开",
    Flag = "dr_auto_replay",
    Interval = 0.6,
    OnEnable = function()
        Nav.replayOn = true
        Nav.stuckPos = nil
        TheKing.Notify({ Title = "自动重开", Content = "看到结算就重开; 卡死 5 分钟也强制重开", Icon = "rotate-cw" })
        return true
    end,
    OnDisable = function()
        Nav.replayOn = false
    end,
    OnTick = function()
        Nav.tickReplay()
    end,
})

TheKing.BindToggle(MoveTab, {
    Title = "爬塔自动祝福选箱",
    Flag = "dr_tower_auto",
    Interval = 2,
    OnEnable = function()
        Nav.towerOn = true
        prefSet("towerAuto", true)
        TheKing.Notify({ Title = "爬塔自动", Content = "自动选祝福(第一张) + 全选 3 箱", Icon = "sparkles" })
        return true
    end,
    OnDisable = function()
        Nav.towerOn = false
        prefSet("towerAuto", false)
    end,
    OnTick = function()
    end,
})
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
    if not st then
        return 0
    end
    local t0 = st.t0
    local tot = total or 0
    if type(t0) ~= "number" or t0 <= 0 or tot <= 0 then
        return 0
    end
    return tot / math.max(os.clock() - t0, 1)
end
local function dpsPlayerDps(plr)
    local dmg = tonumber(plr:GetAttribute("Damage_Dealt")) or 0
    local uid = plr.UserId
    local st = dpsMeta[uid]
    if not st then
        st = { last = dmg, accum = 0, shown = dmg, t0 = 0, zeroAt = 0, sawDrop = false }
        dpsMeta[uid] = st
        if dmg > 0 then
            st.t0 = os.clock()
        end
    end
    local now = os.clock()
    if dmg <= 0 then
        if (st.shown or 0) > 0 then
            if type(st.zeroAt) ~= "number" or st.zeroAt <= 0 then
                st.zeroAt = now
            end
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
                st.t0 = 0
                st.zeroAt = 0
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
    if st.zeroAt > 0 and st.sawDrop and dmg + 1 < (st.shown or 0) * 0.85 then
        st.accum = st.shown or 0
        st.sawDrop = false
    elseif (st.accum or 0) > 0 and dmg >= (st.shown or 0) * 0.9 then
        st.accum = 0
    end
    st.zeroAt = 0
    st.sawDrop = false
    local total = (st.accum or 0) + dmg
    st.last = dmg
    st.shown = total
    if total > 0 and (type(st.t0) ~= "number" or st.t0 <= 0) then
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
    dpsCorner(title, 12)
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
    Cbt._dodgeT0 = 0
    Cbt._dodgeFadeAt = 0
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
function Cbt.hookDodgeAttr()
    local con = Cbt._dodgeAttrConn
    if con then
        return
    end
    con = LocalPlayer:GetAttributeChangedSignal("Dodge_Cooldown_Active"):Connect(function()
        if Cbt._dodgeOn then
            Cbt.tickDodgeBar()
        end
    end)
    Cbt._dodgeAttrConn = con
    TheKing.AddConnection(con)
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
    local now = os.clock()
    local active = LocalPlayer:GetAttribute("Dodge_Cooldown_Active") == true
    if not active then
        if Cbt._dodgeT0 > 0 and Cbt._dodgeFadeAt <= 0 then
            Cbt._dodgeFadeAt = now
            fill.Size = UDim2.new(1, 0, 1, 0)
        end
        Cbt._dodgeT0 = 0
        Cbt._dodgeWasCd = false
        local fadeAt = Cbt._dodgeFadeAt
        if fadeAt > 0 then
            local a = 1 - (now - fadeAt) / 0.42
            if a <= 0 then
                Cbt._dodgeFadeAt = 0
                host.Visible = false
                return
            end
            host.BackgroundTransparency = 0.25 + 0.75 * (1 - a)
            fill.BackgroundTransparency = 1 - a
            host.Visible = true
            return
        end
        host.Visible = false
        return
    end
    local dur = tonumber(LocalPlayer:GetAttribute("Dodge_Cooldown_Duration"))
    if type(dur) ~= "number" or dur < 0.15 then
        dur = 2
    end
    if Cbt._dodgeT0 <= 0 then
        Cbt._dodgeT0 = now
        Cbt._dodgeFadeAt = 0
    end
    Cbt._dodgeWasCd = true
    local p = math.clamp((now - Cbt._dodgeT0) / dur, 0, 1)
    fill.Size = UDim2.new(p, 0, 1, 0)
    host.BackgroundTransparency = 0.25
    fill.BackgroundTransparency = 0
    host.Visible = true
end

TheKing.BindToggle(VisualTab, {
    Title = "闪避冷却条",
    Flag = "dr_dodge_cd",
    OnEnable = function()
        Cbt._dodgeOn = true
        Cbt.ensureDodgeBar()
        Cbt.hookDodgeAttr()
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
        local both = meleeEnabled and skillAuraOn
        if both and my then
            -- 双光环融合: 只画一个蓝圈, 半径取平A/技能最大
            local sr = 0
            local cp = CLASS_PROFILES[classIdx]
            local skills = cp and cachedClassSkills(cp.Folder)
            if skills then
                for i = 1, 4 do
                    if skills[i] then
                        sr = math.max(sr, skillRange(skills[i]))
                    end
                end
            end
            Ov.ring(my, math.max(getMeleeRange(), sr), Color3.fromRGB(80, 140, 255), 0)
        elseif meleeEnabled and my then
            Ov.ring(my, getMeleeRange(), Color3.fromRGB(255, 60, 60), 0)
        elseif skillAuraOn and my then
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
            local col = both and Color3.fromRGB(80, 140, 255) or (skillAuraOn and not meleeEnabled and Color3.fromRGB(255, 220, 70) or Color3.fromRGB(255, 55, 55))
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
    pcall(function()
        TheKing.UnbindStepped("dr_melee_lock")
        TheKing.UnbindStepped("dr_skill_steer")
    end)
    pcall(function()
        Nav.stop()
    end)
    pcall(function()
        local c = LocalPlayer.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if h then
            h.AutoRotate = true
            if (h.WalkSpeed or 0) < 1 then
                h.WalkSpeed = 16
            end
        end
    end)
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
    Nav.hudDestroy()
end)

-- ============================================================
-- 加载完成
-- ============================================================
Nav.towerWatch()
TheKing.Notify({ Content = "TheKing HUB v1.9.5 已加载 (地下城战利品者)", Icon = "crown" })

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

    print("[RCWTK] DR_HUB_v195 loaded")
end)()
