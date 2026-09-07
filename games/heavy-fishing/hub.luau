--[[
    TheKing HUB [1.2.8] - 重型钓鱼
    RCWTK 引擎生成 | 模板 v1.0
    版本历史: games/heavy-fishing/changelog.md (每次发布追加条目, 语义见该文件)

    功能清单 (改这里, 保持格式):
      自动钓鱼: 抛竿 -> 等咬钩 -> Tap 小游戏真人点条(绿区内回弹, 不出界) -> 自动重抛
      智能放弃: 力量差距过大/进度停滞/超时 的鱼直接放弃省时间 (条主动出界走游戏自身失败流程)
        目标鱼过滤: 分组隔离版 — 全部分组/天气鱼/诱饵制作分组/鱼竿制作分组/球体/功法/各岛屿, 切换分组清空旧选择; 只钓勾选鱼, 其他咬钩按1收竿并状态驱动自动复位重抛 (收竿/复位均校验装备态+重试+重入保护, 刷任务鱼/限定鱼/掉宝鱼专用)
      智能回正: 漂移超限拉回钓点并还原抛竿朝向 (可关)
      自动技能: 四层智能决策 (智能择优模式) — 保命回血(HP<50%优先Heal/GodHeal) > 鱼残血收尾(<15%跳过buff直伤倾泻) > 增益覆盖(无RodPower时Power/Boost先放, 自损Bleed技血低禁用) > 元素加权DPS择优(竿Description元素×技能Type同元素吃满加成); 一次性大招识别(CD≥120s: 无我999/万古9900000系等)只在鱼真血命且血量≥30%时放; 多命鱼假血感知(配置Phase: 虎沼鱼3命/无名章寄8命, dealt/MaxHealth回跳计数, 前N-1条假命不打大招); 或顺序释放 (Z→X→C→V 轮转); 分类时机判断
      自动买饵: 选定饵种+补货数量, 存货用完自动购买+自动装备; 背包管理Tab(原鱼饵管理): 钓鱼竿装备 — 全量汉化+按能量排序的竿列表, 一键装备(EquipFishingRod), 可刷新
        自动 Perfect / 自动蓄力 / 钓获通知 / 效率统计(独立心跳, 挂机友好) / 快捷传送(岛屿/NPC/服务器玩家/天气渔场; 竿店·饵店·开船·卖鱼·设出生点合并为一条并传送最近) / 全开关通知 / 注入初始化批量通知静默(notifyMuted) / 防踢心跳(注入即强制启动; 每60s重掐Idled引擎连接+VirtualUser/VIM/键鼠多通道脉冲, 失焦也生效, 不跳跃, 杜绝闲置自动换服)
        玩家Tab: 兑换码 | 虚假信息(编号隐藏/匿名者/假称号对齐服务器渐变+特效+名字色) | 玩家(保持奔跑/移动加速/目标速度)
       自动领取奖励: MultiNotifyReward 弹窗(宝珠/功法/水晶等奖励)任意状态下出现即自动关闭放行(不再依赖自动钓鱼开启), 避免挡住抛竿导致自动钓鱼卡死
       天气预报: 天气稀有鱼提醒 + 关注天气选项 (整合进自动钓鱼)
        恩佐BOSS自动战斗: 已并入自动钓鱼 — 手动开战(点NPC/传送)后开自动钓鱼即自动识别恩佐(workspace.NPC.Enzo.InFight)并接管战斗(快条钉绿心短tween+自动加血QTE/Perfect+Phase2只发包命中不模拟点击+FinalPhase节奏); 仅「智能释放技能」独立控制放技能, 其余流程全自动; 节奏/Phase2 期间禁放技能; 开战检测多路冗余
       节奏小游戏自动打击: 恩佐 FinalPhase 与普通钓鱼 Boss 鱼二段 (无名章寄等) 通用 — 过判定线按 ASD, 走游戏 TryHit(删音符/EXP特效/发包); 禁止直接 RhythmHit, 否则游戏稍后会补 miss
       智能锁定: 动态规则 (Info.MainQuest 运行时解析, 任务环 GiveFish/FishingSpecific/重量挑战/Boss 目标, 游戏更新自动跟随) + 任务完成感知 (Quest.Main[线_Completed] 完成则不锁) + 手动常锁鱼种 + 价值锁定, 自动保护要用的鱼免被自动出售; 支持解锁规则锁/刷新任务规则/锁定统计
        持久化: 除自动钓鱼外全部开关注入自动恢复 (自动钓鱼注入默认关闭, 恩佐检测随自动钓鱼驱动)

    逆向结论 (关键协议结论写这里, 收工同步到 games/heavy-fishing/intel.md):
      - 打鱼伤害 = BarFrame.Bar 的 X.Scale 停在判定区(约 [0.40,0.62])时游戏自身每 0.1s 发 UpdateFishProgression,
        客户端位置权威; 失败 = 条出界客户端上报 FishingMinigame:FireServer(false, token, "Out of bar")
        -> 控条走真点击(+0.1/0.05s), 绿区内起伏不钉死; 放弃仍主动出界走游戏失败流程
      - 力量比公式 (Fishing@逆向): ratio = 竿Power / 鱼Power, u385 = smoothstep(clamp((ratio-0.5)/1.5));
        ratio<=0.5 时条全速移动; ratio 过小 = 大概率打不动 -> 放弃判据
      - 卖鱼 = Events.SellFish:FireServer("One"/"All"), 任意位置可卖
      - 技能 = UseSkill:FireServer(键), 冷却服务器权威 Character.Skills[类别].Value
      - 买饵 = Events.BuyBait:FireServer(饵名, 数量) [实测扣款正确]
      - 装饵 = local ok = Events.EquipBait:InvokeServer(饵名), true=成功 [实测]
      - 背包饵 = Data[UserId].Bait[饵名].Value (数量); 已装 = Data.EquippedBait.Value
      - 可购饵仅 Normal 类型 5 种: Basic ¥100/L3, Crude Mash ¥1万/L8, Corrupted Essence ¥1.5万/L18,
        Elite ¥5万/L30, Ancestral ¥10万/L50; Mythical 类价格 0 不可购 (活动获取)
        - 传送 = 纯客户端 HRP.CFrame 写入; 本脚本全部走游戏自身同款路径 (L1)


     恩佐BOSS战协议结论 (Real 逆向, pv2918, 2026-08-27 实测修正):
       - 开战 = Events.StartBossFight:FireServer(bossId, "Normal") (BossUI Fight 按钮触发, 辐射岛 Enzo)
       - [已证伪] 主阶段复用钓鱼小游戏 — 实机监听证实 BOSS 战 FishingMinigame 入站 0 次, 不控 FishingMinigame 协议
       - Phase1 有顶部鱼条 (BarFrame.Bar, 实机证实) — 控条复用 enterFight 真人点条, 与协议无关
       - 战斗检测 = workspace.Fishes 战斗实体 Boss=true 属性 (普通鱼无此属性; 零 hook 纯属性检测)
       - Phase2 = 独立 BossFightBar (MinigamePhase2): 判定走内部三角波时钟, 不是画面条位; 点空会 FireServer Hit=false 扣血. 自动打只发包 Hit=true+Index, 不模拟点击
       - FinalPhase = Rhythm 节奏小游戏: Events.RhythmStart → 3 轨(ProgressionA/S/D)音符下落, 过线后按 ASD 走游戏 TryHit (禁止直接 RhythmHit)
       - 加血QTE = HealingSlam 等回血技能带 PerfectButton (MainGui.Fishing.PerfectButton:Clone 到 TrashCan); Slam handler 自动 Perfect 覆盖
       - [重大教训] hookmetamethod 挂实例共享元表会污染游戏 UI 点击链路 (注入后点竿/背包失效), 一律禁止用 hook 做检测

    使用方式:
      开发: loadstring(readfile("games/heavy-fishing/hub.luau"))()   -- 项目根目录执行
      热调试: 改完代码直接重新执行本文件, 旧实例自动自毁让位, 无需手动卸载
]]

local TheKing = loadstring(readfile("lib/theking.luau"))({
    GameName = "重型钓鱼", -- 与 intel.md front matter game 字段逐字一致 (热替换/配置/档案三处关联键)
    ScriptVersion = "1.2.8",
})

-- ============================================================
-- 运行时引用 (全部带超时, 游戏更新时降级而非假死)
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events", 10)
if not Events then
    TheKing.Notify({ Title = "加载失败", Content = "未找到 Events 目录, 游戏可能已更新", Icon = "alert-triangle" })
    return
end
local RemoteCast = Events:WaitForChild("Fishing", 10)
local RemoteSell = Events:FindFirstChild("SellFish")
local RemoteBuyBait = Events:FindFirstChild("BuyBait")
local RemoteEquipBait = Events:FindFirstChild("EquipBait")
local DataFolder = ReplicatedStorage:WaitForChild("Data", 10)
local playerData = DataFolder and DataFolder:WaitForChild(tostring(LocalPlayer.UserId), 10)
local infoFolder = ReplicatedStorage:WaitForChild("Info", 10)

local MainGui = LocalPlayer.PlayerGui:WaitForChild("MainGui", 10)
local fightGui = MainGui and MainGui:WaitForChild("Fishing", 10)
-- 奖励弹窗独立看守 (与自动钓鱼解耦): 弹窗出现即自动隐藏放行, 任意状态下生效
-- 原逻辑放在 autoFishTick 内, 仅自动钓鱼运行时才关; 现改为常驻 Visible 监听
-- 注意: 关闭后游戏 u86 防重标志置位, 后续奖励页不再弹出 (奖励仍由服务器发放, bot 视角可接受)
function setupRewardWatcher()
    local function watch(gui)
        gui:GetPropertyChangedSignal("Visible"):Connect(function()
            if gui.Visible then
                gui.Visible = false
                TheKing.Notify({ Content = "已自动领取奖励 (关闭弹窗)", Icon = "check-circle" })
            end
        end)
    end
    local gui = MainGui and MainGui:FindFirstChild("MultiNotifyReward")
    if gui then
        watch(gui)
    elseif MainGui then
        MainGui.ChildAdded:Connect(function(c)
            if c.Name == "MultiNotifyReward" then watch(c) end
        end)
    end
end
setupRewardWatcher()
local fishesFolder = workspace:WaitForChild("Fishes", 10)
local spawnFolder = workspace:WaitForChild("Spawnpoint", 10)

if not (RemoteCast and fightGui and fishesFolder and playerData) then
    TheKing.Notify({ Title = "加载失败", Content = "关键对象缺失, 请确认已进入钓鱼场景", Icon = "alert-triangle" })
    return
end

-- ============================================================
-- 中文化映射: 游戏数据全是英文 (鱼名/岛名/天气/NPC/饵), 展示层统一翻译
-- 内部逻辑 (匹配 Info 配置) 仍用英文名, 只有通知/Dropdown 显示走 tr()
-- ============================================================
local CN_ALL = {}
function tr(name)
    return CN_ALL[name] or name
end

-- 岛屿
for en, cn in pairs({
    ["Beginning Isle"] = "新手岛", ["Amber Isle"] = "琥珀岛",
    ["Sovereign Isle"] = "君主岛", ["Bamboo Isle"] = "竹林岛",
    ["Fallout Isle"] = "辐射岛", ["Perch Isle"] = "鲈鱼岛",
    ["Coconut Isle"] = "椰子岛", ["Battlefield Isle"] = "战场岛",
    ["Mistpeak Isle"] = "雾峰岛", ["Frost Isle"] = "霜冻岛",
}) do CN_ALL[en] = cn end

-- 天气
for en, cn in pairs({
    Clear = "晴天", Rainy = "下雨", Thunderstorm = "雷暴", Foggy = "浓雾",
    Windy = "大风", Snowy = "下雪", ["Blazing Sun"] = "烈阳高照",
}) do CN_ALL[en] = cn end

-- 鱼类 (Info.Inventory 全部 109 种全覆盖)
for en, cn in pairs({
    Trout = "鳟鱼", Catfish = "鲶鱼", Tilapia = "罗非鱼",
    ["Crimson Carp"] = "绯红鲤鱼", ["Royal Carp"] = "皇家鲤鱼", ["Azure Carp"] = "蔚蓝鲤鱼",
    ["Golden Carp"] = "黄金鲤鱼", ["Emerald Carp"] = "翡翠鲤鱼", ["Platinum Carp"] = "白金鲤鱼",
    ["Gold Crucian Carp"] = "金鲫", ["Horned Silver Carp"] = "角银鲤",
    ["Trueform Jiaolongfish"] = "真形蛟鱼", ["Jiaolong Dragonfish"] = "蛟龙鱼",
    ["Adult Jiaolong Dragonfish"] = "成年蛟龙鱼", ["Baby Jiaolong Dragonfish"] = "幼年蛟龙鱼",
    ["Elder Jiaolong Dragonfish"] = "长老蛟龙鱼", ["Rainbow Dragonfish"] = "彩虹龙鱼",
    ["Dragon Battlefish"] = "龙鳞战鱼", ["Draconic Koi"] = "龙纹锦鲤",
    ["Chromatic Koi"] = "幻彩锦鲤", ["Toxic Chromatic Koi"] = "毒幻彩锦鲤",
    ["Mutated Koi Whale"] = "变异锦鲤鲸", ["Dragonstride Carp"] = "龙行鲤",
    ["Azurefin Grass Carp"] = "蓝鳍草鲤", ["Blackfin Grass Carp"] = "黑鳍草鲤",
    ["Crimsonfin Grass Carp"] = "红鳍草鲤", ["Goldfin Grass Carp"] = "金鳍草鲤",
    ["Rosefin Grass Carp"] = "玫鳍草鲤", ["Sovereign Grass Carp"] = "君主草鲤",
    ["Volt Grass Carp"] = "雷霆草鲤", ["Crimson War Carp"] = "绯红战鲤",
    ["Emerald War Carp"] = "翠战鲤", ["Dragonhead Tilapia"] = "龙头罗非",
    ["Elder Dragonhead Tilapia"] = "长老龙头罗非", ["Grass Tilapia"] = "草罗非",
    ["Platescale Tilapia"] = "板鳞罗非",
    ["Ascended Perch"] = "升华鲈鱼", ["Trueform Perch"] = "真形鲈鱼",
    ["Elder Perch I"] = "长老鲈一", ["Elder Perch II"] = "长老鲈二",
    ["Elder Perch III"] = "长老鲈三", ["Elder Perch IV"] = "长老鲈四",
    ["Elder Perch V"] = "长老鲈五", ["Elder Perch VI"] = "长老鲈六",
    ["Elder Perch VII"] = "长老鲈七", ["Elder Perch VIII"] = "长老鲈八",
    ["Kunfish I"] = "鲲鱼一", ["Kunfish II"] = "鲲鱼二", ["Kunfish III"] = "鲲鱼三",
    ["Adult Kunfish"] = "成年鲲鱼", ["Elder Kunfish"] = "长老鲲鱼",
    ["Primordial Kunfish"] = "太初鲲鱼", ["Primordial Kunfish Overlord"] = "太初鲲皇",
    ["Glorious Blobfish"] = "荣耀水滴鱼", ["Glorious Elder Turtle"] = "荣耀长老龟",
    ["Glorious Oarfish"] = "荣耀皇带鱼", ["Valentine Dolphin"] = "情人节海豚",
    ["Warbringer Shark"] = "战鲨", ["Chainbound Shark"] = "锁链鲨",
    ["Elder Chainbound Shark"] = "长老锁链鲨",
    ["Dreadscale Grouper"] = "畏鳞石斑", ["Verdant Grouper"] = "翠绿石斑",
    ["Runic Horn Grouper"] = "符文角石斑",
    ["Colossal Tigerfish"] = "巨型虎鱼", ["Tigerfang Whale"] = "虎牙鲸",
    ["Armored Battlefish"] = "甲胄战鱼", ["Darkness Battlefish"] = "暗影战鱼",
    ["Phantom Battlefish"] = "幻影战鱼",
    ["Fleshripper Fish"] = "撕肉鱼", ["Boundeye Fish"] = "缚眼鱼",
    ["Abyssal Glow Fish"] = "深渊辉光鱼", ["Arrogant Fish"] = "傲慢鱼",
    ["Azure Salmon"] = "蔚蓝鲑", ["Spiked Salmon"] = "尖刺鲑",
    ["Sunscale Salmon"] = "日鳞鲑", ["Crimson Bonefang"] = "赤骨牙",
    ["Verdant Bonefang"] = "翠骨牙", ["Verdant Alligator Gar"] = "翠鳄雀鳝",
    ["Crimson Electric Eel"] = "赤雷鳗", ["Dreadmare Eel"] = "恐梦鳗",
    ["Octoparasitic Fish"] = "章寄鱼", ["Nameless Octoparasite"] = "无名章寄",
    ["Lapis Fish"] = "青金石鱼", ["Mountain Fish"] = "高山鱼",
    ["Golden Guardian Fish"] = "黄金守护鱼", ["Heavenpiercer Turtle"] = "穿天龟",
    ["Mirage Lanternfish"] = "幻影灯笼鱼", ["Sand Anchovy"] = "沙鳀",
    ["Scarlet Fish"] = "绯红之鱼", ["Elder Scarlet Fish"] = "绯红长老鱼",
    ["Scarlet Fringehead"] = "绯红须鱂", ["Serpent Fish"] = "蛇纹鱼",
    ["Silver Bream Sovereign"] = "银鳊君主", ["Crimson Bream Sovereign"] = "赤鳊君主",
    ["Stormscale Tautog"] = "风暴鳞鲷", ["Ironhorn Flounder"] = "铁角比目",
    ["Terratiger Depthfish I"] = "地虎深水鱼一", ["Terratiger Depthfish II"] = "地虎深水鱼二",
    ["Terratiger Depthfish III"] = "地虎深水鱼三", ["Tiger Mirefish"] = "虎沼鱼",
    ["Reborn Puffer Beast"] = "重生河豚兽", ["Flying Fish Emperor"] = "飞鱼帝",
    ["Flying Fish Empress"] = "飞鱼后", ["Frost Kingfish"] = "霜王翠鸟",
    ["Frost Queenfish"] = "霜后鱼", ["Sanguine Fish"] = "血玉鱼",
    ["Radiant Goldfish"] = "辉光金鱼", ["Darkscale Fish"] = "暗鳞鱼",
}) do CN_ALL[en] = cn end

-- NPC (功能标注)
for en, cn in pairs({
    ["Biao Ge"] = "表哥 · 设出生点", ["Biao Di"] = "表弟 · 竿店",
    ["Ba Chang"] = "八长 · 饵店", ["Nana"] = "娜娜 · 卖鱼",
    ["Sage Yijiu"] = "一九大师 · 学技能", ["Zeng Tianguo"] = "曾天国 · 任务",
    ["Giang Lao"] = "江老 · 任务", ["Battlefield Isle's Giang Lao"] = "战场岛江老 · 任务",
    ["Bac Minh"] = "白民 · 任务", ["Ha Dieu De"] = "夏蝶蝶 · 任务",
    ["Lao Ngo"] = "老吴 · 任务", ["Blind Grand Angler"] = "盲眼钓神 · 任务",
    ["The Shadow"] = "暗影者", ["Nanjiang"] = "南江 · 商人",
    ["Enzo"] = "恩佐 · Boss 入口", Spirit = "精魄使徒", Green = "绿神 · 祈祷",
}) do CN_ALL[en] = cn end

-- 鱼饵
for en, cn in pairs({
    ["Basic Bait"] = "基础鱼饵", ["Crude Mash Bait"] = "粗制饵料",
    ["Corrupted Essence Bait"] = "腐化精华饵", ["Elite Bait"] = "精英鱼饵",
    ["Ancestral Bait"] = "先祖鱼饵",
}) do CN_ALL[en] = cn end

-- 特例: 楚欣船夫系列 (Chu Xin 1~10)
function trName(name)
    local cn = CN_ALL[name]
    if cn then return cn end
    if type(name) == "string" and name:match("^Chu Xin") then return "楚欣 · 开船" end
    if type(name) == "string" and name == "Ticket Quest Giver" then return "门票任务官" end
    return name
end

-- ============================================================
-- 功能状态
-- ============================================================
local autoFishOn = false   -- 自动钓鱼主开关 (状态机)
local autoChargeOn = false -- 自动蓄力
local autoSellOn = false   -- 自动出售
local sellThreshold = 20   -- 出售阈值 (固定数量模式用)
local sellTriggerMode = "固定数量" -- 固定数量 | 背包80% | 背包90% | 背包装满
local autoSkillOn = false  -- 自动技能 (战斗中智能施放)
local skillMode = "智能择优" -- 技能模式: 智能择优(DPS 最高优先) | 顺序释放(Z→X→C→V 轮转)
local currentFishName = nil -- 当前战斗鱼名 (开始包 FishName, 供多命感知取配置 Phase)
local phaseSwitches = 0     -- 本场检测到的假血阶段切换次数 (dealt/MaxHealth 回跳)
local lastDealt = 0         -- 上次观测的鱼已扣伤害 (fish.Value)
local lastMaxHp = nil       -- 上次观测的鱼 MaxHealth attribute
local ULT_CD_MIN = 120      -- 一次性大招 CD 阈值 (≥此值视为一次性, 如无我999/万古9900000)
local autoGiveUpOn = true  -- 智能放弃 (钓不动的鱼直接放弃)
local autoBaitOn = false   -- 自动买饵+装备
local selectedBait = nil   -- 选定的饵名
local baitBuyAmount = 2    -- 单次购买数量 (水位线策略: 小批勤补不囤货)
local baitReorderAt = 2    -- 库存降到该值即触发补货

-- 键位 <-> 冷却槽类别固定映射 (Character.Skills 子对象名)
local SKILL_KEYS = {
    { key = "Z", cdSlot = "Rage" },
    { key = "X", cdSlot = "Stun" },
    { key = "C", cdSlot = "Slam" },
    { key = "V", cdSlot = "Weaken" },
}

local fsmState = "待机"     -- 待机 | 等咬钩 | 战斗中 | 等结算
local giveUpDeadline = 0    -- 等结算态的兜底超时 (服务器迟迟不清场则强制回待机)
local cooldownUntil = 0     -- 重抛冷却 (人类化间隔)
local castAt = 0            -- 本次抛竿时间戳 (超时兜底)
local fightConn = nil       -- 战斗中的 Heartbeat 连接 (人类化点条)
local barTapThreshold = 0.46 -- 下次点条阈值 (绿区下沿附近随机)
local barTapReadyAt = 0     -- 人类反应延迟到期时刻
local barLastTapAt = 0      -- 上次点条时间
local barEmergencyAt = 0    -- 出界保命 tween 节流
local lastBarXSeen = 0.5    -- 状态面板用的当前条位
local lastSellAt = 0        -- 卖鱼节流 (防止阈值边界连续发卖鱼包)
local nextSkillAt = 0       -- 下次允许放技能的时间 (人类化间隔)
local fightStartedAt = 0    -- 本场战斗开始时间 (技能爆发节奏判定)
local castCursor = 0        -- 顺序模式的游标 (上次施放的槽位序号, 实现严格循环轮转)
local firstRoundCursor = nil -- 开场倾泻游标 (非 nil = 首轮按序倾泻进行中)
local lastSkillFishId = nil      -- autoSkill 自治检测用: 本模块上次见到的 FishID
local skillDecisionLog = {}      -- 决策环形日志 (最近 10 条, 调试可观测性)
local lastSeenFishId = nil       -- 上一 tick 的 FishID (跨场快速衔接检测)

-- 恩佐BOSS自动战斗状态 (用户手动开战, 本模块接管全流程)
local bossModeOn = false     -- 恩佐BOSS检测开关 (由自动钓鱼驱动: setAutoFish 同步置真, 详见 setAutoFish)
local bossActive = false     -- 当前是否处于BOSS战斗中 (自动检测)
local bossPhase2Index = 0   -- Phase2点击小游戏序号计数器 (近似游戏 u109)
local rhythmActive = false   -- 节奏小游戏进行中 (恩佐 FinalPhase / 普通钓鱼 Boss 鱼二段通用)
local rhythmUntil = 0        -- 节奏小游戏超时兜底 (服务器 MiniGameTime 120s + 余量)
-- 节奏音符追踪 (弱键表, 音符实例被游戏移除后自动回收, 不泄漏)
-- notePrevY: 上一 tick 的 Y, 用于"跨过判定线"检测 (Perfect 时机判据)
-- noteHit:   已发过 hit 的音符, 用于去重 (RhythmHit 包不带音符 ID, 重复发会被服务器按序错配 → 漏点)
local notePrevY = setmetatable({}, { __mode = "k" })
local noteHit = setmetatable({}, { __mode = "k" })
-- 过线后的迟到窗: 只收已经跨过判定线的音符. 提前点 (y<line) 拿不到 Perfect.
-- 音符间距后期 ≈0.19 Scale, 迟到窗必须小于它, 否则会误打下一颗.
local RHYTHM_LATE = 0.10
local rhythmConn = nil           -- 节奏 Heartbeat 驱动 (不用 StartLoop: 50ms 下限 + 默认抖动会偏 Perfect)
local bossEverConfirmed = false  -- 是否曾确认进入恩佐战斗 (出现过 Phase2/节奏/多命实体信号)
local lastConfirmedFight = 0     -- 上次确认战斗信号时间戳 (结束判据: 信号持续消失超时才停)
local phase2Conn = nil           -- Phase2 RenderStepped, 仅 Phase2 属性为真时挂
local phase2WatchConn = nil    -- 监听 Character.Phase2
local BossFightBar = fightGui and fightGui:FindFirstChild("BossFightBar")
local BossBar = BossFightBar and BossFightBar:FindFirstChild("Bar")
local BossHitbox = BossFightBar and BossFightBar:FindFirstChild("Hitbox")
local BossPhase2Action = Events and Events:FindFirstChild("BossPhase2Action")
local RhythmStartEv = Events and Events:FindFirstChild("RhythmStart")
local RhythmHitEv = Events and Events:FindFirstChild("RhythmHit")
local RhythmStopEv = Events and Events:FindFirstChild("RhythmStop")
-- Boss 检测信号: 用 workspace.Fishes 战斗实体的 Boss=true 属性 (普通鱼无此属性, 完美区分)
-- 不用 hookmetamethod — 实测 hook 挂实例共享元表会污染游戏 UI 点击链路 (注入后点竿/背包失效的元凶)
-- Charge 蓄力技能 (Sever the Gate 系) 状态
local chargeHoldUntil = 0        -- 蓄力保留截止时间 (期间 autoCharge 不干预)
local chargeDuration = 15        -- 蓄力时长 (秒), 伤害 = Damage × 秒数
local pendingChargeRemote = nil  -- 最后收到的 Charge 动态 remote (结算用)
local hotkeyBindings = {}        -- 快捷键绑定表: [功能id] = {action=功能定义, key=EnumItem}
-- 玩家功能相关状态 (P2-6 上移至状态区, 供 Heartbeat + UI 回调引用, 消除声明顺序脆弱性)
local keepSprintOn = false
local speedHackOn = false
local targetSpeed = 50     -- 游戏实际奔跑速度为 36, 默认 50 = 明显加速
local runBaseline = 0      -- 自适应奔跑基准 (历史最大自然 WalkSpeed)
local lastSprintToggleAt = 0
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local clickBusy = false
local lastClickPos = Vector2.new(8, 8)
local lastClickPosAt = 0
local function pickSafeClickPos()
    -- 顶部是控鱼条/BossFightBar, (10,10) 会点到 GUI → gameProcessed=true → onClick 被吞
    -- 优先点 3D 视口中下部无 Active GUI 的像素
    if lastClickPosAt > 0 and (os.clock() - lastClickPosAt) < 2 then
        return lastClickPos
    end
    local cam = workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local spots = {
        Vector2.new(vp.X * 0.5, vp.Y * 0.72),
        Vector2.new(vp.X * 0.38, vp.Y * 0.62),
        Vector2.new(vp.X * 0.62, vp.Y * 0.62),
        Vector2.new(math.max(8, vp.X - 10), math.max(8, vp.Y - 10)),
        Vector2.new(10, math.max(8, vp.Y - 10)),
    }
    if not pg then
        lastClickPos = spots[1]
        lastClickPosAt = os.clock()
        return lastClickPos
    end
    for _, p in ipairs(spots) do
        local ok, objs = pcall(function()
            return pg:GetGuiObjectsAtPosition(p.X, p.Y)
        end)
        if ok and type(objs) == "table" then
            local blocked = false
            for _, o in ipairs(objs) do
                if o:IsA("GuiButton") then
                    blocked = true
                    break
                end
                if o:IsA("GuiObject") and o.Visible and o.Active then
                    blocked = true
                    break
                end
            end
            if not blocked then
                lastClickPos = p
                lastClickPosAt = os.clock()
                return p
            end
        end
    end
    lastClickPos = spots[1]
    lastClickPosAt = os.clock()
    return lastClickPos
end
local function sendHumanClick()
    if clickBusy then return false end
    clickBusy = true
    local p = pickSafeClickPos()
    lastClickPos = p
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(p.X, p.Y, 0, true, game, 0)
    end)
    local hold = 0.032 + math.random() * 0.05
    task.delay(hold, function()
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(p.X, p.Y, 0, false, game, 0)
        end)
        clickBusy = false
    end)
    return true
end
local RHYTHM_KEYS = {
    ProgressionA = Enum.KeyCode.A,
    ProgressionS = Enum.KeyCode.S,
    ProgressionD = Enum.KeyCode.D,
}
local function sendLaneKey(code)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, code, false, game)
        VirtualInputManager:SendKeyEvent(false, code, false, game)
    end)
end
local toggleEls = {}             -- UI Toggle 元素引用 (快捷键切换后同步显示用)
function logDecision(msg)
    table.insert(skillDecisionLog, string.format("[%.1fs] %s", os.clock() % 10000, msg))
    if #skillDecisionLog > 10 then table.remove(skillDecisionLog, 1) end
end
local currentFishPower = 0  -- 当前鱼的 Power (FishingMinigame 开始包)
local lastProgressAt = 0    -- 上次鱼进度变化时间 (停滞检测)
local lastProgressValue = -1
local anchorPos = nil           -- 钓点锚位 (自动钓鱼首次抛竿位置, 漂移修正用)
local anchorCFrame = nil        -- 抛竿瞬间完整 CFrame (位置+朝向, 智能回正还原用)
local smartReturnOn = true      -- 智能回正开关: 漂移超限拉回锚点并还原抛竿朝向 (默认开, 可关)
local targetFishNames = {}      -- 目标鱼过滤多选集 (英文鱼名 -> true; 空=不过滤)
local targetFishEnabled = false -- 目标鱼过滤总开关 (与选中鱼联动)
local targetFishRestoreFn = nil -- 重载后恢复 targetFishNames (闭包在 buildMainTab 内赋值, LoadConfig 后调用)
local FISH_ISLE_MAP = {}        -- 鱼英文名 -> 岛屿英文名 (来自 Info.FishingAreaRarity, 显示前缀用)
local ISLE_CN = { -- 岛屿中文名映射 (与 trName 一致, 供列表显示)
    ["Beginning Isle"] = "新手岛", ["Perch Isle"] = "鲈鱼岛", ["Frost Isle"] = "霜冻岛",
    ["Bamboo Isle"] = "竹林岛", ["Coconut Isle"] = "椰子岛", ["Mistpeak Isle"] = "雾峰岛",
    ["Amber Isle"] = "琥珀岛", ["Fallout Isle"] = "辐射岛", ["Battlefield Isle"] = "战场岛",
    ["Sovereign Isle"] = "皇冠岛", ["Exclusive"] = "限定", ["Secret Boss"] = "秘密Boss",
}
-- 构建 鱼->岛 映射 (运行时从 FishingAreaRarity 读取, 游戏更新自动跟随)
do
    local infoMod = infoFolder and infoFolder:FindFirstChild("FishingAreaRarity")
    if infoMod then
        local ok, areaData = pcall(function() return require(infoMod) end)
        if ok and type(areaData) == "table" then
            for isleEn, fishList in pairs(areaData) do
                if type(fishList) == "table" then
                    for fishEn in pairs(fishList) do
                        FISH_ISLE_MAP[fishEn] = isleEn
                    end
                end
            end
        end
    end
end
-- 鱼显示名: 岛屿前缀 + 中文名 (用于目标列表/放弃通知)
function fishLabel(fishEn)
    local cn = trName(fishEn)
    local isle = FISH_ISLE_MAP[fishEn]
    if isle then
        return (ISLE_CN[isle] or trName(isle)) .. "-" .. cn
    end
    return cn
end

-- 天气限定鱼映射 (模块级: 天气预报/智能锁定/天气渔场传送共用)
-- 特定天气 × 特定岛屿 = 限定 Boss 鱼
WEATHER_ISLE_MAP = {
    Windy = { ["Perch Isle"] = { "Flying Fish Emperor", "Flying Fish Empress" } },
    Snowy = { ["Frost Isle"] = { "Reborn Puffer Beast", "Frost Kingfish" } },
    ["Blazing Sun"] = { ["Amber Isle"] = { "Draconic Koi", "Sanguine Fish" } },
    Thunderstorm = { ["Bamboo Isle"] = { "Crimson Electric Eel", "Scarlet Fish", "Elder Scarlet Fish" } },
    Foggy = {
        ["Coconut Isle"] = { "Heavenpiercer Turtle" },
        ["Mistpeak Isle"] = { "Mirage Lanternfish" },
    },
}
-- 天气键规范化查表: 游戏实际天气值含空格 (实机 pv: workspace:GetAttribute("Weather")
-- 取值 Clear/Windy/Rainy/Thunderstorm/Foggy/Snowy/"Blazing Sun"), 而历史版本曾写成无空格的
-- "BlazingSun" → 直接下标查表落空, 表现为烈阳天气下天气渔场传送/预报/锁定整片静默失效。
-- 三级兜底: 原值 → 去空格 → 小写去空格, 键格式再变也不会整片失效。
local function getWeatherTargets(weather)
    if type(weather) ~= "string" then return nil end
    if WEATHER_ISLE_MAP[weather] then return WEATHER_ISLE_MAP[weather] end
    -- 括号不可省: string.gsub 返回 (结果, 替换次数) 两个值, 不加括号会把次数一并传给 string.lower
    local compact = string.lower((string.gsub(weather, "%s+", "")))
    for k, v in pairs(WEATHER_ISLE_MAP) do
        if type(k) == "string" and string.lower((string.gsub(k, "%s+", ""))) == compact then
            return v
        end
    end
    return nil
end

-- 天气鱼集合: 全部天气限定鱼英文名 -> true (智能锁定"特殊天气鱼"规则用)
WEATHER_FISH_SET = {}
do
    for _, isleList in pairs(WEATHER_ISLE_MAP) do
        if type(isleList) == "table" then
            for _, fishList in pairs(isleList) do
                if type(fishList) == "table" then
                    for _, fishEn in ipairs(fishList) do
                        WEATHER_FISH_SET[fishEn] = true
                    end
                elseif type(fishList) == "string" then
                    WEATHER_FISH_SET[fishList] = true
                end
            end
        end
    end
end

-- 效率统计
local stats = {
    startedAt = os.clock(),
    fish = 0,     -- 捕获条数
    cash = 0,     -- 卖鱼收入
    fights = 0,   -- 战斗场次
}
local lastCashSeen = nil -- 现金差分基线 (兜底统计非卖鱼来源的收入)
local lastStatsAt = 0
local fishRunStartedAt = 0  -- 本轮自动钓鱼累计运行起始 (暂停/关闭期间不计)
local fishRunAccum = 0      -- 自动钓鱼累计运行秒数

local StatusPara = nil -- 主界面状态段落柄 (后创建)
local StatsPara = nil  -- 效率统计段落柄
local notifyMuted = false -- 注入初始化阶段置 true: 抑制批量开关通知 (setAutoFish/ConfigManager 恢复)

-- 统一功能开关通知: 开启/关闭都弹清晰提示, 带图标
-- 所有 Toggle 的 Callback 必须走此函数 (或等效 Notify), 禁止静默切换
function notifyToggle(name, on, icon)
    if notifyMuted then return end -- 注入初始化期静默, 避免弹一堆"已开启/已关闭"
    TheKing.Notify({
        Title = name,
        Content = on and "已开启" or "已关闭",
        Icon = icon or (on and "toggle-right" or "toggle-left"),
        Duration = 2.5,
    })
end

--- 数字格式化: 1.5M / 230K / 999 (与游戏内 KG 显示同款风格)
function fmtNum(n)
    n = tonumber(n) or 0
    local a = math.abs(n)
    if a >= 1e12 then return (string.gsub(string.format("%.1f", n / 1e12), "%.0$", "")) .. "T" end
    if a >= 1e9 then return (string.gsub(string.format("%.1f", n / 1e9), "%.0$", "")) .. "B" end
    if a >= 1e6 then return (string.gsub(string.format("%.1f", n / 1e6), "%.0$", "")) .. "M" end
    if a < 1000 then return tostring(math.floor(n)) end
    return (string.gsub(string.format("%.1f", n / 1000), "%.0$", "")) .. "K"
end

--- 差分刷新状态显示
function updateStatus(text)
    if StatusPara then
        TheKing.UpdateStatus(StatusPara, "运行状态", text)
    end
end

--- 效率统计刷新 (statsTick 每 2s 调一次, UpdateStatus 内部差分)
--- 长时间挂机友好: 分「挂机总时长」与「自动钓鱼实际运行时长」双指标,
--- 条/时与 ¥/时按实际钓鱼时长计算 (暂停/关闭不稀释效率)
--- 显示精度: 垂钓分母保留 1 位小数 (避免 1.6 分显示为 1 分导致效率口径失真);
---            背包库存实时统计, 让用户明确"捕获≠收入" (¥0 时可见背包里 X 条待售)
--- 容错: sellFishCount 可能瞬态失败, 全部 pcall 包裹保证面板永不因数据缺失崩坏
local sellFishCount  -- 前向声明: 实际定义在447, updateStatsPanel(388)需先于其定义引用之
local realBagCount  -- 前向声明
function updateStatsPanel()
    if not StatsPara then return end
    pcall(function()
        local totalHours = (os.clock() - stats.startedAt) / 3600
        local runHours = fishRunAccum / 3600
        if totalHours <= 0 then totalHours = 1 / 3600 end
        if runHours <= 0 then runHours = 1 / 3600 end
        local runMinPrecise = fishRunAccum / 60
        local okBag, bagCount = pcall(function() return realBagCount() end)
        bagCount = okBag and bagCount or 0
        TheKing.UpdateStatus(StatsPara, "效率统计", string.format(
            "挂机 %d 分 · 垂钓 %.1f 分 · 捕获 %d 条 · 背包 %d 条 · 收入 ¥%s\n垂钓效率 %s 条/时 · ¥%s/时 · 战斗 %d 场",
            math.floor((os.clock() - stats.startedAt) / 60),
            runMinPrecise,
            stats.fish, bagCount, fmtNum(stats.cash),
            fmtNum(stats.fish / runHours), fmtNum(stats.cash / runHours), stats.fights))
    end)
end

-- ============================================================
-- 背包容量检查 (照抄游戏自身逻辑: Inventory 数量 + Hotbar 数量 >= InventoryLimit)
-- 2s 缓存: 该函数被 dbg.state / 待机分支每帧轮询, 实测 pcall 遍历 Inventory+Hotbar 有开销 (P2-7)
-- ============================================================
local invFullCacheAt = 0
local invFullCache = false
function isInventoryFull(fresh)
    if not fresh and (os.clock() - invFullCacheAt) < 2 then return invFullCache end
    local res = false
    if playerData then
        local ok, full = pcall(function()
            local limitInst = playerData:FindFirstChild("InventoryLimit")
            local limit = limitInst and limitInst.Value or 0
            local count = #playerData.Inventory:GetChildren()
            for _, slot in ipairs(playerData.Hotbar:GetChildren()) do
                count = count + slot.Quantity.Value
            end
            return count >= limit
        end)
        res = ok and full
    end
    invFullCache = res
    invFullCacheAt = os.clock()
    return res
end

-- ============================================================
-- 自动出售: 背包鱼数(仅未锁定) >= 阈值时全卖 (Events.SellFish("All"))
-- 锁定的鱼 (Name 以 " | Favorite" 结尾) 不计入可售数量, 不参与出售
-- 实测任意位置可卖; 10s 节流防阈值边界连发
-- ============================================================
local FAV_SUFFIX = " | Favorite"

function isLockedFish(item)
    return string.sub(item.Name, -#FAV_SUFFIX) == FAV_SUFFIX
end

-- 2s 缓存: doSellAll 调用时传 fresh=true 取实时数, 其余轮询走缓存 (P2-7)
local sellCountCacheAt = 0
local sellCountCache = 0
function sellFishCount(fresh)
    if not fresh and (os.clock() - sellCountCacheAt) < 2 then return sellCountCache end
    local res = 0
    if playerData then
        local ok, n = pcall(function()
            local c = 0
            for _, f in ipairs(playerData.Inventory:GetChildren()) do
                if not isLockedFish(f) then c = c + 1 end
            end
            return c
        end)
        res = ok and n or 0
    end
    sellCountCache = res
    sellCountCacheAt = os.clock()
    return res
end

-- 真实背包总数 (含锁定鱼 + Hotbar 数量), 匹配游戏背包容量口径; 用户要"真实背包数量"
function realBagCount()
    if not playerData then return 0 end
    local ok, n = pcall(function()
        local c = #playerData.Inventory:GetChildren()
        for _, slot in ipairs(playerData.Hotbar:GetChildren()) do
            c = c + (slot:FindFirstChild("Quantity") and slot.Quantity.Value or 0)
        end
        return c
    end)
    return ok and n or 0
end

-- ============================================================
-- 智能锁定: 按任务需求/价值自动锁定背包鱼 (FavoriteItem 协议, 实测有效)
-- 规则数据源 = Info.MainQuest 全量解析 (会话20):
--   GiveFish 上交鱼 (上交后消失, 必须多备) / FishingSpecific 钓捕目标 /
--   SpecficFishWithAnAmountOfWeight 重量挑战 (鱼+最低重量)
-- ============================================================
local QUEST_GIVE_FISH = {
    ["Trueform Jiaolongfish"] = true,
    ["Ascended Perch"] = true,
    ["Glorious Blobfish"] = true,
    ["Glorious Elder Turtle"] = true,
    ["Glorious Oarfish"] = true,
    ["Valentine Dolphin"] = true,
}
local QUEST_CATCH_FISH = {
    ["Warbringer Shark"] = true,
    ["Dreadscale Grouper"] = true,
    ["Primordial Kunfish"] = true,
    ["Trueform Perch"] = true,
    ["Ascended Perch"] = true,
    ["Nameless Octoparasite"] = true,
}
-- Mythical 饵合成材料 (Info.Bait[x].Ingredient 全量解析): 鱼名 → 用于合成哪种饵
local CRAFT_MATERIAL_FISH = {
    ["Ascended Perch"] = "冰霜饵", ["Frost Kingfish"] = "冰霜饵",
    ["Primordial Kunfish Overlord"] = "冰霜饵", ["Warbringer Shark"] = "冰霜饵",
    ["Mirage Lanternfish"] = "无名饵", ["Mountain Fish"] = "无名饵",
    ["Octoparasitic Fish"] = "无名饵", ["Tiger Mirefish"] = "无名饵",
    ["Colossal Tigerfish"] = "彩虹饵", ["Crimson Electric Eel"] = "彩虹饵",
    ["Golden Guardian Fish"] = "彩虹饵", ["Heavenpiercer Turtle"] = "彩虹饵",
}
-- 重量挑战: 鱼名 -> 最低重量 kg (实际价 ≈ Weight × ~0.95, 用价格反推重量留容差)
local QUEST_WEIGHT_FISH = {
    ["Reborn Puffer Beast"] = 5000000,
    ["Scarlet Fish"] = 1500000,
    ["Elder Scarlet Fish"] = 1500000,
    ["Draconic Koi"] = 2000000,
    ["Primordial Kunfish Overlord"] = 1000000,
    ["Mutated Koi Whale"] = 1000000,
    ["Colossal Tigerfish"] = 5000000,
    ["Crimson Bream Sovereign"] = 2500000,
    ["Silver Bream Sovereign"] = 3500000,
    ["Rainbow Dragonfish"] = 6500000,
    ["Frost Kingfish"] = 5000000,
    ["Frost Queenfish"] = 6500000,
    ["Nameless Octoparasite"] = 6000000,
}

-- ============================================================
-- 智能锁定 v2 动态规则 (Info.MainQuest 运行时解析, 游戏更新自动跟随):
--   任务环结构 (实机确认): require(MainQuest[线]) = 数组, 每环 = { [1]=描述, [2]=数量/重量, [3]=类型, [4]=目标 }
--   锁鱼类型: GiveFish(上交, [4]=鱼名) / FishingSpecific(钓捕, [4]=鱼名) /
--             SpecficFishWithAnAmountOfWeight(重量挑战, [4]={Fish=鱼名,Weight=最低重量}) / FishBoss([4]=Boss鱼名)
--   进度感知: Data.Quest.Main[线名.."_Completed"] BoolValue=true → 该线目标鱼不再锁
--   硬编码表 (QUEST_GIVE_FISH 等) 保留为 require 失败的兜底
--   注: 全部动态表合并进 DYN_QUEST 单表, 控制 chunk 顶层局部变量数量 (Luau 200 寄存器上限)
-- ============================================================
local DYN_QUEST = { give = {}, catch = {}, weight = {}, lines = {} }

function isLineDone(lineName)
    if not playerData then return false end
    local qm = playerData:FindFirstChild("Quest") and playerData.Quest:FindFirstChild("Main")
    if not qm then return false end
    local done = qm:FindFirstChild(lineName .. "_Completed")
    return done ~= nil and done.Value == true
end

function buildLockTables()
    DYN_QUEST = { give = {}, catch = {}, weight = {}, lines = {} }
    pcall(function()
        local mq = infoFolder and infoFolder:FindFirstChild("MainQuest")
        if not mq then return end
        for _, lineMod in ipairs(mq:GetChildren()) do
            local lineName = lineMod.Name
            local ok, arr = pcall(require, lineMod)
            if ok and type(arr) == "table" then
                for _, ring in ipairs(arr) do
                    if type(ring) == "table" then
                        local rType = tostring(ring[3])
                        local target = ring[4]
                        local fishName, weight = nil, nil
                        if rType == "GiveFish" or rType == "FishingSpecific" or rType == "FishBoss" then
                            fishName = tostring(target)
                        elseif rType == "SpecficFishWithAnAmountOfWeight" then
                            if type(target) == "table" then
                                fishName = tostring(target.Fish)
                                weight = tonumber(target.Weight) or 0
                            end
                        end
                        if fishName and fishName ~= "nil" and fishName ~= "" then
                            if rType == "GiveFish" then DYN_QUEST.give[fishName] = true end
                            if rType == "FishingSpecific" or rType == "FishBoss" then DYN_QUEST.catch[fishName] = true end
                            if weight and weight > 0 then DYN_QUEST.weight[fishName] = weight end
                            local lines = DYN_QUEST.lines[fishName]
                            if not lines then lines = {}; DYN_QUEST.lines[fishName] = lines end
                            local dup = false
                            for _, ln in ipairs(lines) do if ln == lineName then dup = true; break end end
                            if not dup then lines[#lines + 1] = lineName end
                        end
                    end
                end
            end
        end
    end)
end

--- 鱼名: 任务线全部完成 → false (不再锁定); 任一未完成 → true
function hasActiveQuest(fish)
    local lines = DYN_QUEST.lines[fish]
    if not lines then return false end
    for _, ln in ipairs(lines) do
        if not isLineDone(ln) then return true end
    end
    return false
end

--- 从项名提取鱼种基础名 ("鱼名 | 价格[ | Favorite]" → "鱼名")
function getFishBase(itemName)
    return string.match(itemName, "^(.-) | ") or itemName
end

local lockOn = false          -- 智能锁定总开关
local lockRuleGive = true     -- 规则: 任务上交鱼
local lockRuleCatch = false   -- 规则: 任务钓捕鱼
local lockRuleCraft = true    -- 规则: Mythical 饵合成材料鱼
local lockRuleWeight = false  -- 规则: 任务重量挑战鱼
local lockRuleWeather = false -- 规则: 特殊天气鱼 (特定天气在特定岛钓的限定鱼)
local lockValueMin = 0        -- 价值锁定: 单价 ≥ 此值自动锁 (0=关闭)
local manualLockSet = {}      -- 手动常锁鱼种 (英文鱼名 -> true); UI 多选指定, 优先级高于规则

--- 名字级规则判定 (不依赖价格, 新鱼入库瞬间即可判定并抢先锁定)
function matchLockByName(fish)
    if manualLockSet[fish] then
        return "手动指定"
    end
    if lockRuleCraft and CRAFT_MATERIAL_FISH[fish] then
        return "合成材料·" .. CRAFT_MATERIAL_FISH[fish]
    end
    if lockRuleWeather and WEATHER_FISH_SET[fish] then
        return "特殊天气鱼"
    end
    -- 任务类规则: 动态表 (完成感知: 任务线全完成不锁) + 硬编码兜底
    -- 注: 重量挑战鱼不走名字级 (需价格/重量达标才锁, 见 matchLockRules)
    if not hasActiveQuest(fish) then
        return nil
    end
    if lockRuleGive and (DYN_QUEST.give[fish] or QUEST_GIVE_FISH[fish]) then
        return "任务上交"
    end
    if lockRuleCatch and (DYN_QUEST.catch[fish] or QUEST_CATCH_FISH[fish]) then
        return "任务钓捕目标"
    end
    return nil
end

--- Charge 蓄力类技能判定 (如 Sever the Gate: 释放后蓄力, 按 F 结算, 伤害=Damage×蓄力秒数)
function isChargeSkill(name)
    return type(name) == "string" and name:find("Sever the Gate", 1, true) ~= nil
end

--- 全量规则判定 (含价格依赖的重量挑战/价值锁定); 返回 原因或nil
function matchLockRules(itemName)
    local fish = getFishBase(itemName)
    local byName = matchLockByName(fish)
    if byName then
        return byName
    end
    -- 价格段提取: "鱼名 | 123.45 [| Favorite]"
    local price = tonumber(string.match(itemName, "^.- | ([%d%.]+)")) or 0
    if lockRuleWeight and hasActiveQuest(fish) then
        local minW = DYN_QUEST.weight[fish] or QUEST_WEIGHT_FISH[fish]
        -- 实际价 ≈ Weight × ~0.95 → weight ≈ price/0.949; 留容差宁多锁
        if minW and price >= minW * 0.87 then
            return "重量挑战达标"
        end
    end
    if lockValueMin > 0 and price >= lockValueMin then
        return "高价值(≥" .. lockValueMin .. ")"
    end
    return nil
end

function favoriteItem(itemName)
    pcall(function()
        Events.FavoriteItem:FireServer(itemName)
    end)
end

--- 取消收藏 (解锁): FavoriteItem:FireServer(nil, 鱼名) [实机逆向 Inventory@772]
function unfavoriteItem(itemName)
    pcall(function()
        Events.FavoriteItem:FireServer(nil, itemName)
    end)
end

--- 背包锁定统计 (已锁/未锁)
function lockStats()
    if not playerData then return 0, 0 end
    local locked, unlocked = 0, 0
    for _, f in ipairs(playerData.Inventory:GetChildren()) do
        if isLockedFish(f) then
            locked = locked + 1
        else
            unlocked = unlocked + 1
        end
    end
    return locked, unlocked
end

--- 解锁"规则锁定"的鱼 (保留手动指定/价值锁定, 防误锁解除); 返回解锁数
--- (yield: 每 10 条让 0.3s 防限流)
function unlockRuleLocked()
    if not playerData then return 0 end
    local unlocked = 0
    for _, f in ipairs(playerData.Inventory:GetChildren()) do
        if isLockedFish(f) then
            local fish = getFishBase(f.Name)
            -- 手动/价值锁保留, 只有名字级规则命中的才解
            if not manualLockSet[fish] then
                local byName = matchLockByName(fish)
                local price = tonumber(string.match(f.Name, "^.- | ([%d%.]+)")) or 0
                local isValueLocked = lockValueMin > 0 and price >= lockValueMin
                if byName and not isValueLocked then
                    unfavoriteItem(f.Name)
                    unlocked = unlocked + 1
                    if unlocked % 10 == 0 then task.wait(0.3) end
                end
            end
        end
    end
    return unlocked
end

--- 扫描现有背包, 锁定所有匹配规则的未锁定鱼; 返回锁定数
--- (yield 函数: 每 10 条让 0.3s, 防止连续 FireServer 触发服务器限流)
function scanAndLock()
    if not playerData then return 0, {} end
    local locked = 0
    local names = {}
    local seenName = {}
    for _, f in ipairs(playerData.Inventory:GetChildren()) do
        if not isLockedFish(f) then
            local reason = matchLockRules(f.Name)
            if reason then
                favoriteItem(f.Name)
                locked = locked + 1
                local base = getFishBase(f.Name)
                if not seenName[base] then
                    seenName[base] = true
                    names[#names + 1] = base
                end
            end
        end
    end
    return locked, names
end

--- 把锁定的鱼名拼成一个通知串 (中文名, 超 12 种截断)
function fmtLockList(names)
    if #names == 0 then return "" end
    local disp = {}
    for i, nm in ipairs(names) do disp[i] = trName(nm) end
    local shown, extra = disp, ""
    if #disp > 12 then
        shown = {}
        for i = 1, 12 do shown[i] = disp[i] end
        extra = string.format(" 等 %d 种", #disp)
    end
    return "\n已锁: " .. table.concat(shown, "、") .. extra
end

--- 钓获时的锁定钩子: 名字级规则立即抢锁; 价格级规则延迟判定
--- 返回 true = 已接管通知 (命中锁定), 调用方不再弹"钓到了"
function autoLockCheck(item)
    -- 第一时间: 名字类规则抢先锁 (防自动出售在延迟窗口内把任务鱼卖掉)
    local fishBase = getFishBase(item.Name)
    local immediate = lockOn and matchLockByName(fishBase)
    if immediate then
        favoriteItem(item.Name)
        TheKing.Notify({
            Title = "已锁定 · 任务鱼",
            Content = trName(fishBase) .. " (" .. immediate .. ")",
            Icon = "lock",
            Duration = 2,
        })
        return true
    end
    if not lockOn then return false end
    -- 延迟: 重量/价值规则需要价格, 等服务器写完定价再判
    task.delay(0.9, function()
        if not item.Parent then return end
        if isLockedFish(item) then return end
        local reason = matchLockRules(item.Name)
        if reason then
            favoriteItem(item.Name)
            TheKing.Notify({
                Title = "已锁定 · " .. reason,
                Content = trName(getFishBase(item.Name)),
                Icon = "lock",
                Duration = 2,
            })
        else
            local base = getFishBase(item.Name)
            local price = string.match(item.Name, " | ([%d%.]+)") or "?"
            TheKing.Notify({
                Title = "钓到了! " .. trName(base),
                Content = "价格 ¥" .. price,
                Icon = "fish",
                Duration = 2,
            })
        end
    end)
    return true
end

function setAutoLock(on)
    lockOn = on and true or false
    notifyToggle("智能锁定", lockOn, "lock")
end

function doSellAll(reason)
    if not RemoteSell then return false end
    local n = sellFishCount(true) -- 出售前取实时数, 避免缓存误判
    if n <= 0 then return false end
    local cashBefore = playerData and playerData.Cash and playerData.Cash.Value or 0
    RemoteSell:FireServer("All")
    lastSellAt = os.clock()
    task.delay(0.6, function()
        local gained = (playerData and playerData.Cash and playerData.Cash.Value or cashBefore) - cashBefore
        TheKing.Notify({
            Title = "自动出售",
            Content = string.format("(%s) 已卖出 %d 条未锁定鱼, 收入 ¥%s", reason, n, fmtNum(gained)),
            Icon = "coins",
        })
    end)
    return true
end

--- 主循环内调用: 触发条件满足且非战斗中则卖
--- 触发阈值: 固定数量模式用 sellThreshold; 百分比模式 = InventoryLimit × 百分比;
---           「背包装满」直接复用 isInventoryFull() (与抛竿前满仓判定完全同源)
--- 注入宽限: 脚本启动后 90 秒内不自动出售 (防注入瞬间误卖, 给用户检查配置的时间)
local bootAt = os.clock()

function autoSellCheck()
    if not autoSellOn then return false end
    if not RemoteSell then return false end
    if os.clock() - bootAt < 90 then return false end -- 注入宽限期
    if os.clock() - lastSellAt < 10 then return false end
    if fsmState == "战斗中" then return false end -- 战斗中不打断, 结束后下一轮处理

    if sellTriggerMode == "背包装满" then
        if isInventoryFull() and sellFishCount() > 0 then
            doSellAll("背包已装满")
            return true
        end
        return false
    end

    local trigger
    local limit = playerData and playerData.InventoryLimit and playerData.InventoryLimit.Value or 0
    local pct = (sellTriggerMode ~= "固定数量") and string.match(sellTriggerMode, "(%d+)%%") or nil
    if pct and limit > 0 then
        trigger = math.floor(limit * tonumber(pct) / 100)
    else
        trigger = sellThreshold
    end

    if sellFishCount() >= trigger then
        doSellAll(sellTriggerMode == "固定数量" and ("达到阈值 " .. sellThreshold) or ("背包" .. pct .. "%"))
        return true
    end
    return false
end

--- 自动出售独立循环: 与自动钓鱼解耦, 单开出售也能工作
function setAutoSell(on)
    autoSellOn = on and true or false
    if on then
        TheKing.StartLoop("autoSell", 2, function()
            autoSellCheck()
        end)
    else
        TheKing.StopLoop("autoSell")
    end
    notifyToggle("自动出售", autoSellOn, "coins")
end

-- ============================================================
-- 自动技能: 战斗中按鱼竿装备的 Z/X/C/V 智能施放
-- 节奏 = 人类真实打法: 开场技能全交 (伤害/定身/增益优先连发),
--       后续冷却好了再补; 不是省着留到鱼残血。
-- 时机: autoSkillTick 不做定身/无敌/血量过滤 — 只要技能就绪(冷却好+未锁定)即按阶段优先级无脑放;
--       实战未观测到偏早问题, 时机过滤属过度设计 (P1-4 已确认不实现)
-- 通用拦截: SkillLocked/UsingSkill/服务器权威冷却归零 由上方判定; C(Slam) 小游戏由 autoPerfect 单独处理
-- ============================================================


--- 技能输出评分 = 总伤指数 ÷ 冷却 (DPS 视角), 结果缓存; 用于多伤害技能择优
local skillDmgCache = {}

function getSkillDamage(name)
    local cached = skillDmgCache[name]
    if cached then return cached end
    local dmg = 0
    pcall(function()
        local mod = infoFolder.Skill:FindFirstChild(name)
        if mod then
            local cfg = require(mod)
            local st = type(cfg) == "table" and cfg.Stats
            if type(st) == "table" then
                local base = (tonumber(st.Damage) or 0) + (tonumber(st.SecondDamage) or 0)
                local duration = tonumber(st.Duration) or 1
                -- 跳伤间隔: 有 SlamTime 字段用它 (Barrage/Slam 系快跳), 否则 DStun 系固定 0.5s
                local step = tonumber(st.SlamTime) or 0.5
                if step <= 0 then step = 1 end
                local cooldown = math.max(tonumber(st.Cooldown) or 1, 1)
                local cc = math.min((tonumber(st.CritChance) or 5) / 100, 1)
                local cd = (tonumber(st.CritDamage) or 1.5) - 1
                dmg = base * (duration / step) * (1 + cc * cd) / cooldown
            end
        end
    end)
    skillDmgCache[name] = dmg
    return dmg
end
function getEquippedSkill(key)
    -- Data[UserId].FishingRodInventory[当前竿].Skill[key].Value = 技能名(""=未装)
    if not playerData then return nil end
    local ok, name = pcall(function()
        local rodInv = playerData.FishingRodInventory
        local cur = rodInv[playerData.FishingRod.Value]
        return cur.Skill[key].Value
    end)
    if ok and type(name) == "string" and name ~= "" then return name end
    return nil
end

-- 统一蓄力结算: 放 Charge 后定时结算, 不再受 firstRoundCursor 阶段条件限制
function scheduleChargeSettle(castName)
    chargeHoldUntil = os.clock() + chargeDuration
    task.delay(chargeDuration, function()
        if os.clock() >= chargeHoldUntil - 0.2 and pendingChargeRemote then
            pcall(function() pendingChargeRemote:FireServer() end)
            logDecision("蓄力结算 " .. tostring(castName))
        end
    end)
end

-- ============================================================
-- 智能技能决策辅助 (v0.21.0+):
--   技能分型: heal(回血) / buff(增益) / dps(直伤) / charge(蓄力)
--   元素匹配: 竿 Description "for <Element> skills" × 技能 Type 同元素加权
--   自身血量: Humanoid.Health 保命优先; Bleed 自损增益技血低禁用
--   鱼血量: fish.Value(已扣伤) / MaxHealth attribute → 残血收尾
-- ============================================================
local skillClassCache = {}
local skillStatsCache = {}
local skillElementCache = {}

function getSkillConfig(name)
    local mod = infoFolder and infoFolder:FindFirstChild("Skill") and infoFolder.Skill:FindFirstChild(name)
    if not mod then return nil end
    local ok, cfg = pcall(require, mod)
    return ok and cfg or nil
end

function getSkillStats(name)
    local s = skillStatsCache[name]
    if s ~= nil then return s end
    local cfg = getSkillConfig(name)
    s = type(cfg) == "table" and type(cfg.Stats) == "table" and cfg.Stats or nil
    skillStatsCache[name] = s
    return s
end

--- 技能分型: ult=一次性大招(CD≥120, 如无我999/万古9900000, 须在鱼血充足时用);
--- heal=带 Heal/GodHeal; buff=带 Power/Boost; 其余 dps (蓄力由 isChargeSkill 另判)
function classifySkill(name)
    local c = skillClassCache[name]
    if c then return c end
    local cls = "dps"
    local st = getSkillStats(name)
    if type(st) == "table" then
        local cd = tonumber(st.Cooldown) or 0
        if cd >= ULT_CD_MIN then
            cls = "ult" -- 超长CD一次性大招, 优先级最高 (即使带 Power/Heal 也是一次性的)
        elseif tonumber(st.Heal) or tonumber(st.GodHeal) then
            cls = "heal"
        elseif tonumber(st.Power) or tonumber(st.Boost) then
            cls = "buff"
        end
    end
    skillClassCache[name] = cls
    return cls
end

--- 鱼命数 (多命鱼假血机制): Info.Inventory[鱼名].Phase 字段 (虎沼鱼3/幻影灯笼鱼2/章寄鱼2/无名章寄8); 无配置=单命
local fishPhasesCache = {}
function getFishPhases(name)
    if not name then return 1 end
    local p = fishPhasesCache[name]
    if p ~= nil then return p end
    local phases = 1
    pcall(function()
        local m = infoFolder and infoFolder:FindFirstChild("Inventory") and infoFolder.Inventory:FindFirstChild(name)
        if m then
            local cfg = require(m)
            phases = tonumber(type(cfg) == "table" and cfg.Phase) or 1
        end
    end)
    fishPhasesCache[name] = phases
    return phases
end

--- 竿元素 (Description "Increases X% damage for <Element> skills") 与加成倍率; 缓存
local rodElemCached = false -- false=未算, nil=无元素加成
local rodElemBonus = 1
function getRodElement()
    if rodElemCached ~= false then return rodElemCached, rodElemBonus end
    rodElemCached = nil
    pcall(function()
        local rodInv = playerData and playerData.FishingRodInventory
        local cur = rodInv and rodInv[playerData.FishingRod.Value]
        if cur then
            local cfg = require(cur)
            local desc = tostring(type(cfg) == "table" and cfg.Description or "")
            local elem = desc:match("for ([%w ]+) skills")
            if elem then
                rodElemCached = elem:gsub("%s+$", "")
                rodElemBonus = 1 + (tonumber(type(cfg) == "table" and cfg.Damage) or 0) / 100
            end
        end
    end)
    return rodElemCached, rodElemBonus
end

--- 技能元素 (Type 字段)
function getSkillElement(name)
    local e = skillElementCache[name]
    if e ~= nil then return e end
    local cfg = getSkillConfig(name)
    e = type(cfg) == "table" and cfg.Type or nil
    skillElementCache[name] = e
    return e
end

--- 自身血量比例 (0~1)
function getSelfHpRatio()
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.MaxHealth <= 0 then return 1 end
    return hum.Health / hum.MaxHealth
end

--- 鱼剩余血量比例 (fish.Value=已造成伤害, MaxHealth attribute=总血量); 无实体/无血量字段返回 nil
function getFishHpRatio(fish)
    if not fish then return nil end
    local maxHp = fish:GetAttribute("MaxHealth")
    if not maxHp or maxHp <= 0 then return nil end
    local dealt = tonumber(fish.Value) or 0
    return math.clamp(1 - dealt / maxHp, 0, 1)
end

--- 当前 RodPower 增益值 (Character.Stats.RodPower, 技能决策用)
local function getRodBuffPower()
    local statsObj = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Stats")
    if not statsObj then return 0 end
    local v = statsObj:FindFirstChild("RodPower")
    return v and (tonumber(v.Value) or 0) or 0
end

function autoSkillTick()
    -- 恩佐战斗已并入自动钓鱼: 技能开关统一用 autoSkillOn, 模式统一用 skillMode
    local skillActive = autoSkillOn
    if not skillActive or fsmState ~= "战斗中" then
        lastSkillFishId = nil
        return
    end
    -- 节奏小游戏 / Phase2 点击小游戏期间禁放战斗技能: 技能动画打乱判定 → 服务器扣血(维妮塔)
    if rhythmActive then return end
    local _chk = LocalPlayer.Character
    if _chk and _chk:GetAttribute("Phase2") == true then return end
    -- 自治跨场检测: 本模块自己盯 FishID, 换鱼即重置 (不依赖主循环先跑, 消除循环相位竞争)
    local fidNow = LocalPlayer:GetAttribute("FishID")
    if fidNow ~= lastSkillFishId then
        lastSkillFishId = fidNow
        castCursor = 0
        firstRoundCursor = 0 -- 开场倾泻从 Z 重新起步
        fightStartedAt = os.clock()
        nextSkillAt = os.clock() -- 立即可评估: 倒计时期间由 SkillLocked 挡住, 解锁瞬间即首发
        lastProgressValue = -1
        -- 多命假血感知重置: 换鱼清零阶段计数
        phaseSwitches = 0
        lastDealt = 0
        lastMaxHp = nil
        -- 清理上一场遗留的定身/无敌脏状态: 新战斗刚开场不可能有合法跳伤进行中,
        -- 残留的 Stun=true 会错误屏蔽所有 stun 类技能导致首发漂移到后面的槽位
        local chNow = LocalPlayer.Character
        if chNow and chNow:FindFirstChild("Stats") then
            pcall(function()
                if chNow.Stats.Stun.Value == true then
                    chNow.Stats.Stun.Value = false
                    logDecision("清理跨场残留 Stun")
                end
                chNow.Stats.Iframe.Value = 0
            end)
        end
        logDecision("新战斗 开场倾泻从 Z 起")
    end
    if os.clock() < nextSkillAt then return end

    local ch = LocalPlayer.Character
    if not ch then return end
    if ch:GetAttribute("SkillLocked") == true then return end
    local skillsObj = ch:FindFirstChild("Skills")
    if not skillsObj then return end

    local fishId = lastSkillFishId
    local fish = fishId and fishesFolder:FindFirstChild(fishId)

    -- ============================================================
    -- 多命鱼假血感知 (虎沼鱼3命/无名章寄8命等):
    --   配置 Phase = 总命数; dealt(fish.Value) 或 MaxHealth 大幅回跳 = 假血阶段切换
    --   前 N-1 条命是假血(打到边界回满), 只有最后一条命是真血 → 一次性大招只在真血命放
    -- ============================================================
    local fishPhases = getFishPhases(currentFishName)
    local dealtNow = tonumber(fish and fish.Value) or 0
    local maxHpNow = fish and fish:GetAttribute("MaxHealth")
    if lastDealt - dealtNow > 400 then
        phaseSwitches = phaseSwitches + 1
        logDecision("检测到假血回跳 (第 " .. (phaseSwitches + 1) .. " 条命)")
    end
    if lastMaxHp and maxHpNow and maxHpNow ~= lastMaxHp then
        phaseSwitches = phaseSwitches + 1
        logDecision("MaxHealth 变化 (第 " .. (phaseSwitches + 1) .. " 条命)")
    end
    lastDealt = dealtNow
    lastMaxHp = maxHpNow
    local finalPhase = fishPhases <= 1
        or (fish and fish:GetAttribute("FinalPhase") == true) -- 服务器显式标记(无名章寄 HPFinalPhase)
        or (phaseSwitches + 1 >= fishPhases)
    local fishHp = getFishHpRatio(fish)
    -- 一次性大招时机门: 最后一条命(或单命鱼) 且 剩余血量≥30% (避免打在假血/残血上浪费)
    local ultOK = finalPhase and (fishHp == nil or fishHp >= 0.30)

    -- ============================================================
    -- 两阶段模式:
    --   阶段1 开场倾泻 (firstRoundCursor 非 nil): 无条件按 Z→X→C→V 顺序
    --          把所有已装备且冷却好的技能放一轮 — 不看定身/无敌/血量任何条件;
    --          Charge 蓄力技照放, 放完自动延迟猛击结算
    --   阶段2 自由补刀: 哪个冷却转好了就放哪个 (DPS 指数最高优先)
    -- ============================================================
    local ready = {}
    for idx, m in ipairs(SKILL_KEYS) do
        local name = getEquippedSkill(m.key)
        if name then
            local slot = skillsObj:FindFirstChild(m.cdSlot)
            if slot and slot.Value <= 0 and (tonumber(slot:GetAttribute("UsingSkill")) or 0) <= 0 then
                table.insert(ready, { key = m.key, order = idx, name = name })
            end
        end
    end

    if #ready == 0 then
        logDecision("池空")
        return
    end

    local key, castName
    if firstRoundCursor then
        -- 阶段1: 严格顺序倾泻 (一次性大招受 ultOK 时机门: 多命鱼假血阶段不放, 单命鱼开场血足可放)
        table.sort(ready, function(a, b) return a.order < b.order end)
        local chosen = nil
        for _, e in ipairs(ready) do
            if e.order > firstRoundCursor and not (classifySkill(e.name) == "ult" and not ultOK) then
                chosen = e
                break
            end
        end
        if not chosen then
            -- 一轮放完 → 转自由补刀 (选择策略仍按当前模式)
            firstRoundCursor = nil
            logDecision("开场倾泻完成, 转自由补刀")
            return
        end
        key = chosen.key
        castName = chosen.name
        firstRoundCursor = chosen.order
        logDecision("倾泻 [" .. key .. "] " .. trName(castName))
        if isChargeSkill(castName) then scheduleChargeSettle(castName) end
        nextSkillAt = os.clock() + 0.15 + math.random() * 0.15 -- 倾泻快节奏 (放完即准备下轮)
        return
    end

    -- 阶段2: 自由补刀 — 选择策略跟随当前场景的模式 (恩佐独立模式 / 自动钓鱼模式)
    local activeMode = skillMode
    table.sort(ready, function(a, b) return a.order < b.order end)

    if activeMode == "顺序释放" then
        -- 顺序模式: 游标循环轮转 Z→X→C→V (一次性大招未到时机则跳过, 轮转到下一槽)
        local chosen
        for _, e in ipairs(ready) do
            if e.order > castCursor and not (classifySkill(e.name) == "ult" and not ultOK) then
                chosen = e
                castCursor = e.order
                break
            end
        end
        if not chosen then
            -- 全部早于游标 → 回绕到最小序号 (同样过滤未到时机的大招)
            for _, e in ipairs(ready) do
                if not (classifySkill(e.name) == "ult" and not ultOK) then
                    chosen = e
                    castCursor = e.order
                    break
                end
            end
        end
        if not chosen then
            logDecision("顺序池空 (大招未到时机)")
            return
        end
        key, castName = chosen.key, chosen.name
        logDecision("顺序轮转 [" .. key .. "] " .. trName(castName))
    else
        -- 智能决策: 保命回血 > 鱼残血收尾 > 增益覆盖 > 元素加权 DPS 择优
        local selfHp = getSelfHpRatio()
        local fishHp = getFishHpRatio(fish)
        local rodElem, rodBonus = getRodElement()
        local rodPower = getRodBuffPower()
        -- 按类型分池 (一次性大招 ult 受时机门: 未到真血/血量不足则禁用)
        local healReady, buffReady, dmgPool = {}, {}, {}
        for _, e in ipairs(ready) do
            local cls = classifySkill(e.name)
            if cls == "heal" then
                table.insert(healReady, e)
            elseif cls == "buff" then
                -- 自损(Bleed)增益技血低禁用, 防止回血跟不上
                local st = getSkillStats(e.name)
                local bleed = tonumber(type(st) == "table" and st.Bleed) or 0
                if not (bleed > 0 and selfHp < 0.4) then
                    table.insert(buffReady, e)
                end
            elseif cls == "ult" then
                -- 一次性大招: 只在最后一条命且血量充足时入直伤池 (假血阶段/残血一律禁)
                if ultOK then
                    table.insert(dmgPool, e)
                end
            else
                table.insert(dmgPool, e)
            end
        end
        -- 择优函数: 元素匹配加权 DPS (同元素技能吃满竿加成)
        local function pickBest(pool)
            local best, bestScore = nil, -1
            for _, e in ipairs(pool) do
                if not isChargeSkill(e.name) then
                    local d = getSkillDamage(e.name)
                    if rodElem and getSkillElement(e.name) == rodElem then d = d * rodBonus end
                    if d > bestScore then bestScore, best = d, e end
                end
            end
            return best
        end
        -- 1) 保命: 自身血 < 50% 且有回血技 → 回血 (选 Heal 量最大的)
        if selfHp < 0.5 and #healReady > 0 then
            local bestH, bestHv = nil, -1
            for _, e in ipairs(healReady) do
                local st = getSkillStats(e.name)
                local hv = tonumber(type(st) == "table" and (st.Heal or (st.GodHeal or 0))) or 0
                if hv > bestHv then bestHv, bestH = hv, e end
            end
            key, castName = bestH.key, bestH.name
            logDecision("保命回血 [" .. key .. "] " .. trName(castName) .. " (HP " .. math.floor(selfHp * 100) .. "%)")
        -- 2) 鱼残血收尾: 剩余 <15% → 跳过 buff 直接直伤倾泻
        elseif fishHp and fishHp < 0.15 and #dmgPool > 0 then
            local best = pickBest(dmgPool)
            if best then key, castName = best.key, best.name end
            logDecision("残血收尾 [" .. key .. "] " .. trName(castName) .. " (鱼剩 " .. math.floor(fishHp * 100) .. "%)")
        -- 3) 增益覆盖: 无 RodPower buff 且增益技就绪 → 补 buff
        elseif rodPower <= 0 and #buffReady > 0 then
            local best, bestScore = nil, -1
            for _, e in ipairs(buffReady) do
                local st = getSkillStats(e.name)
                local bv = tonumber(type(st) == "table" and (st.Power or st.Boost or 0)) or 0
                if bv > bestScore then bestScore, best = bv, e end
            end
            key, castName = best.key, best.name
            logDecision("增益覆盖 [" .. key .. "] " .. trName(castName))
        -- 4) 常规: 元素加权 DPS 择优 (直伤优先, 无直伤才轮到 buff/heal/已到时机的大招)
        else
            local pool = dmgPool
            if #pool == 0 then
                -- 无直伤可用: 退到全部可放技能 (heal/buff/已到时机大招), 仍排除未到时机的一次性大招
                pool = {}
                for _, e in ipairs(ready) do
                    if not (classifySkill(e.name) == "ult" and not ultOK) then
                        table.insert(pool, e)
                    end
                end
            end
            if #pool == 0 then
                logDecision("无可用技能 (大招未到时机)")
                return
            end
            local best = pickBest(pool)
            if best then key, castName = best.key, best.name end
            logDecision("智能命中 [" .. key .. "] " .. trName(castName))
        end
    end

    if key then
        Events.UseSkill:FireServer(key)
        if isChargeSkill(castName) then
            scheduleChargeSettle(castName)
            logDecision("自由蓄力 " .. tostring(castName))
            nextSkillAt = os.clock() + 0.8 + math.random()
            return
        end
        logDecision("自由命中 [" .. key .. "] " .. trName(castName))
        local interval = 0.15 + math.random() * 0.25 -- 迅捷补刀: 准备结束立即放 (原 0.8~2.0)
        nextSkillAt = os.clock() + interval
    end
end

-- 技能循环统一管理: 自动钓鱼/恩佐BOSS 任一开关开启即保持循环 (StartLoop 幂等, 重复调用先停旧再起新)
-- 循环内 autoSkillTick 按 bossActive 场景感知选开关, 两场景互不干扰
function syncSkillLoop()
    if autoSkillOn then
        TheKing.StartLoop("autoSkill", 0.5, autoSkillTick)
    else
        TheKing.StopLoop("autoSkill")
    end
end

function setAutoSkill(on)
    autoSkillOn = on and true or false
    if on then
        nextSkillAt = 0
    end
    syncSkillLoop()
    notifyToggle("自动技能", autoSkillOn, "zap")
end

-- ============================================================
-- 自动买饵: 水位线补货 (库存降到阈值就小批买入) + 自动装备
-- 与游戏商店/背包按钮同款包; 现金不足服务器静默拒绝, 轮询重试
-- ============================================================
local lastBaitOpAt = 0

function autoBaitTick()
    if not autoBaitOn or not selectedBait or not playerData then return end
    if os.clock() - lastBaitOpAt < 5 then return end -- 操作节流, 防连发

    local baitSlot = playerData.Bait:FindFirstChild(selectedBait)
    local haveCount = baitSlot and baitSlot.Value or 0

    if haveCount < baitReorderAt then
        -- 降到水位线下: 小批补货 (用几个补几个的节奏, 不囤货)
        if RemoteBuyBait then
            RemoteBuyBait:FireServer(selectedBait, baitBuyAmount)
            lastBaitOpAt = os.clock()
        end
        return
    end

    if playerData.EquippedBait.Value ~= selectedBait then
        -- 有存货但没装: 装上。InvokeServer 是同步等待服务器回复 (~RTT),
        -- 放进 task.spawn 避免拖慢整个循环体 (慢循环告警的根因)
        if RemoteEquipBait then
            lastBaitOpAt = os.clock()
            task.spawn(function()
                local ok, resp = pcall(function() return RemoteEquipBait:InvokeServer(selectedBait) end)
                if ok and resp == true then
                    TheKing.Notify({ Content = "已装备 " .. selectedBait, Icon = "check-circle" })
                end
            end)
        end
    end
end

function setAutoBait(on)
    autoBaitOn = on and true or false
    if on then
        if not selectedBait then
            TheKing.Notify({ Title = "自动买饵", Content = "请先在下方选择诱饵", Icon = "alert-triangle" })
            autoBaitOn = false
            return
        end
        lastBaitOpAt = 0
        TheKing.StartLoop("autoBait", 3, autoBaitTick)
    else
        TheKing.StopLoop("autoBait")
    end
    notifyToggle("自动买饵", autoBaitOn, "package")
end

-- ============================================================
-- 智能放弃: 钓不动的鱼直接放弃省时间
-- 判据: ① 力量比 rodPower/fishPower < 0.3 (条全速+伤害效率趋零)
--       ② 开战 10s 后进度连续 12s 停滞   ③ 单场总超时 180s
-- 动作 = 游戏自身失败路径: 断锁条 + 条移出判定区 -> 客户端上报 "Out of bar" -> 会话结束
-- ============================================================
local giveUpAt = nil       -- 到点放弃的时间戳 (力量比判据)
local rodPowerCache = nil

-- 装备竿基础 Power (Info.Inventory[竿].Power), 放弃判据用; 勿与战斗 buff getRodBuffPower 混淆
local function getEquippedRodBasePower()
    if rodPowerCache then return rodPowerCache end
    if not playerData or not infoFolder then return 0 end
    local ok, p = pcall(function()
        local rodName = playerData.FishingRod.Value
        local invInfo = infoFolder:FindFirstChild("Inventory")
        local m = invInfo and invInfo:FindFirstChild(rodName)
        return m and tonumber(require(m).Power) or 0
    end)
    rodPowerCache = (ok and p) or 0 -- 换竿时由装备监听清缓存
    return rodPowerCache
end

playerData.FishingRod.Changed:Connect(function()
    rodPowerCache = nil
end)

-- ============================================================
-- 战斗: 人类化点条 (Tap)
-- 原理: 游戏把条往 -0.1 tween, 玩家点击 +0.1 (0.05s)。绿区约 [0.40,0.62]。
--       我们不钉死位置, 等条落到阈值再点, 让条在绿区里起伏; 点不到时再短 tween 保命。
--       不发包, 伤害仍走游戏自身 10Hz UpdateFishProgression。
-- ============================================================
function stopFight()
    if fightConn then
        pcall(function() fightConn:Disconnect() end)
        fightConn = nil
    end
    -- 节奏 Heartbeat 清理 (不再有 bossRhythm StartLoop)
    rhythmActive = false
    if rhythmConn then
        pcall(function() rhythmConn:Disconnect() end)
        rhythmConn = nil
    end
    -- 快速复位: 停掉残留的技能/收杆动画, 让角色立刻回到可操作状态
    -- (引擎 Animate 脚本会自动恢复 idle/walk 基础动画)
    local ch = LocalPlayer.Character
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if animator then
        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
            pcall(function() track:Stop(0.15) end)
        end
    end
    -- 清定身/无敌脏状态 (同 autoSkillTick 自治清理, 双路径兜底)
    if ch then
        local statsObj = ch:FindFirstChild("Stats")
        if statsObj then
            pcall(function()
                statsObj.Stun.Value = false
                statsObj.Iframe.Value = 0
            end)
        end
    end
end

function doGiveUp(reason)
    -- 进入"等待结算"态: 断锁条让条出界, 但不回待机不重抛,
    -- 等服务器处理失败上报 (FishID 清空/面板关闭) 后由主循环正常收尾
    stopFight()
    local bar = fightGui.BarFrame:FindFirstChild("Bar")
    if bar then
        bar:TweenPosition(
            UDim2.new(-0.15, bar.Position.X.Offset, bar.Position.Y.Scale, bar.Position.Y.Offset),
            Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, 0, true
        )
    end
    giveUpAt = nil
    giveUpDeadline = os.clock() + 8 -- 结算兜底: 8s 内服务器必响应
    fsmState = "等结算"
    updateStatus("已放弃本场 (" .. reason .. "), 等待结算…")
end

-- 装备态判据 (与 autoFishTick 的 rodEquipped 判据逐字一致, 避免两处判据漂移)
local function isRodEquipped()
    local ch = LocalPlayer.Character
    return ch ~= nil and ch:GetAttribute("Type") == "Fishing Rod"
end

local fastCancelBusy = false -- 重入保护: 连续非目标鱼咬钩时防并发按键乱序 (乱序会翻出未装备态)
local lastRodFixAt = 0       -- 主循环自动补装备节流 (防每 tick 刷按键)

-- 目标鱼过滤快放弃: 非目标鱼咬钩时, 不走 doGiveUp 的 8s 服务器结算等待,
-- 直接按 1 收起钓鱼竿取消咬钩 + 再按 1 拿起鱼竿复位, 自动抛竿循环无缝接管 (更快)
-- 流程为状态驱动: 每步都等装备态真正翻转, 而不是赌固定延时 (旧版 0.18s 固定延时会被收竿动画吃掉第二次按键,
-- 装备态卡在"未装备" → 自动钓鱼永久停在"请先装备鱼竿")
function fastCancelTarget(label)
    if fastCancelBusy then return end -- 上一轮收竿未跑完, 跳过本次 (防按键乱序)
    fastCancelBusy = true
    stopFight()
    fsmState = "待机"
    giveUpAt = nil
    cooldownUntil = os.clock() + 0.5
    updateStatus("非目标鱼, 收竿重抛 (" .. (label or "") .. ")")
    local vim = VirtualInputManager
    local k = Enum.KeyCode.One
    local function tap()
        pcall(function()
            vim:SendKeyEvent(true, k, false, game)
            vim:SendKeyEvent(false, k, false, game)
        end)
    end
    task.spawn(function()
        local deadline = os.clock() + 3 -- 总超时兜底
        -- ① 收竿: 按 1 直到装备态解除 (首按可能被动画吃掉, 补一次)
        if isRodEquipped() then
            tap()
            local t0 = os.clock()
            while isRodEquipped() and os.clock() - t0 < 1.0 do
                task.wait(0.06)
            end
            if isRodEquipped() then
                tap()
                task.wait(0.3)
            end
        end
        -- ② 复位: 按 1 重新拿起鱼竿, 失败重试 (装备态不复原则自动钓鱼彻底停摆)
        if not isRodEquipped() and autoFishOn then
            local tries = 0
            while not isRodEquipped() and tries < 5 and os.clock() < deadline do
                tap()
                tries = tries + 1
                local t1 = os.clock()
                while not isRodEquipped() and os.clock() - t1 < 0.3 do
                    task.wait(0.05)
                end
            end
        end
        fastCancelBusy = false
        if not isRodEquipped() and autoFishOn then
            TheKing.Notify({
                Title = "鱼竿未装备",
                Content = "自动复位失败, 请手动按 1 拿起鱼竿",
                Icon = "alert-triangle",
                Duration = 5,
            })
        end
    end)
end

--- 战斗状态初始化 (enterFight 与跨场快速衔接共用)
function resetFightState()
    fightStartedAt = os.clock()
    castCursor = 0
    firstRoundCursor = 0 -- 开场倾泻从 Z 起步
    nextSkillAt = os.clock() -- 立即可评估: SkillLocked 挡倒计时, 解锁瞬间首发
    lastProgressAt = fightStartedAt + 3
    lastProgressValue = -1
end

local function nudgeBarLikeClick(bar)
    local x = bar.Position.X.Scale
    local dest = x + 0.1
    if dest > 0.58 then dest = 0.50 + math.random() * 0.06 end
    if dest < 0.42 then dest = 0.46 end
    bar:TweenPosition(
        UDim2.new(dest, bar.Position.X.Offset, bar.Position.Y.Scale, bar.Position.Y.Offset),
        Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, 0.05, true
    )
end

function enterFight()
    stopFight()
    barTapThreshold = 0.43 + math.random() * 0.07
    barTapReadyAt = 0
    barLastTapAt = 0
    barEmergencyAt = 0
    lastBarXSeen = 0.5
    local barAwaitBumpUntil = 0
    local barXBeforeTap = 0.5
    resetFightState()
    giveUpAt = nil
    stats.fights = stats.fights + 1
    if not bossActive and autoGiveUpOn and currentFishPower > 0 then
        local ratio = getEquippedRodBasePower() / currentFishPower
        if ratio < 0.3 then
            giveUpAt = fightStartedAt + 5 -- 倒计时结束后执行 (条出界判定需在战斗中)
            updateStatus(string.format("鱼力量远超钓竿 (%.1f%%), 将放弃", ratio * 100))
        end
    end
    local cachedBar = nil
    local lastX = 0.5
    local lastT = 0
    local stepper = (bossActive and RunService.RenderStepped) or RunService.Heartbeat
    fightConn = TheKing.AddConnection(stepper:Connect(function()
        -- Boss 战豁免 fightGui.Visible 检查 (BOSS 条路径与普通钓鱼面板可见性不同)
        if (not autoFishOn and not bossActive) or (not bossActive and not fightGui.Visible) then return end
        local ch = LocalPlayer.Character
        if ch and ch:GetAttribute("Phase2") == true then return end
        if rhythmActive then return end
        if not (cachedBar and cachedBar.Parent) then
            cachedBar = fightGui.BarFrame:FindFirstChild("Bar")
        end
        local bar = cachedBar
        if not bar then return end
        local now = os.clock()
        if giveUpAt and now >= giveUpAt then return end
        local x = bar.Position.X.Scale
        lastBarXSeen = x
        local vx = 0
        if lastT > 0 then
            vx = (x - lastX) / math.max(1e-4, now - lastT)
        end
        lastX, lastT = x, now
        -- 恩佐/快条: 跟人连点一样, 游戏同款 +0.1/0.05s Linear, 不瞬移钉死
        if bossActive or vx < -1.2 then
            if x < 0.412 or x > 0.608 then
                if now - barEmergencyAt > 0.08 then
                    barEmergencyAt = now
                    bar:TweenPosition(
                        UDim2.new(0.48 + math.random() * 0.04, bar.Position.X.Offset, bar.Position.Y.Scale, bar.Position.Y.Offset),
                        Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.06, true
                    )
                end
                return
            end
            if x <= 0.50 and (now - barLastTapAt) >= (0.08 + math.random() * 0.04) then
                barLastTapAt = now
                nudgeBarLikeClick(bar)
            end
            return
        end
        -- 真点击没打上时, 用游戏同款 +0.1/0.05s 补一刀 (失焦/点到 GUI 时)
        if barAwaitBumpUntil > 0 and now >= barAwaitBumpUntil then
            barAwaitBumpUntil = 0
            if x <= barXBeforeTap + 0.015 then
                nudgeBarLikeClick(bar)
            end
            return
        end
        -- 出界保命: 短回弹, 不当主路
        if x < 0.408 or x > 0.615 then
            if now - barEmergencyAt > 0.12 then
                barEmergencyAt = now
                local safe = 0.46 + math.random() * 0.08
                bar:TweenPosition(
                    UDim2.new(safe, bar.Position.X.Offset, bar.Position.Y.Scale, bar.Position.Y.Offset),
                    Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.08, true
                )
            end
            return
        end
        -- 偏高就让游戏自己往左拉, 不点 (点了 +0.1 会出绿区)
        if x > 0.532 then
            barTapReadyAt = 0
            return
        end
        if x <= barTapThreshold then
            if barTapReadyAt == 0 then
                local urgency = (0.48 - x) / 0.08
                if urgency < 0 then urgency = 0 elseif urgency > 1 then urgency = 1 end
                barTapReadyAt = now + (0.16 - urgency * 0.10) + math.random() * 0.05
            end
            if now >= barTapReadyAt and (now - barLastTapAt) >= 0.13 then
                barLastTapAt = now
                barTapReadyAt = 0
                barTapThreshold = 0.43 + math.random() * 0.07
                barXBeforeTap = x
                barAwaitBumpUntil = now + 0.09
                sendHumanClick()
            end
        else
            barTapReadyAt = 0
        end
    end))
end

-- ============================================================
-- 自动钓鱼主循环 (0.5s 状态机) — 启停逻辑集中于此, Toggle 与调试口共用
-- ============================================================
TheKing.OnCleanup(stopFight) -- 卸载/热替换时必断战斗连接
TheKing.OnCleanup(function()
    if phase2Conn then
        pcall(function() phase2Conn:Disconnect() end)
        phase2Conn = nil
    end
    if phase2WatchConn then
        pcall(function() phase2WatchConn:Disconnect() end)
        phase2WatchConn = nil
    end
    if rhythmConn then
        pcall(function() rhythmConn:Disconnect() end)
        rhythmConn = nil
    end
end)

-- 独立统计心跳 (常挂, 不受自动钓鱼启停影响): 现金差分 + 效率面板刷新
-- 长时间挂机优化: 统计不依赖 autoFishTick 运行, 关闭自动钓鱼也能持续累计收入与时长
-- 容错: 循环体整体 pcall, 任何单次异常只记日志不打断心跳 (玩家数据瞬态缺失时自愈)
TheKing.StartLoop("statsTick", 2, function()
    pcall(function()
        -- 现金差分兜底统计 (卖鱼/其他收入统一走这里, 避免与出售回调重复计数)
        if playerData and playerData.Cash and playerData.Cash.Value then
            local c = playerData.Cash.Value
            if lastCashSeen and c > lastCashSeen then
                stats.cash = stats.cash + (c - lastCashSeen)
            end
            lastCashSeen = c
        end
        -- 自动钓鱼累计运行时长 (仅 autoFishOn 且未在战斗中结算停滞时累计)
        if autoFishOn and fsmState ~= "等结算" then
            if fishRunStartedAt > 0 then
                fishRunAccum = fishRunAccum + (os.clock() - fishRunStartedAt)
            end
            fishRunStartedAt = os.clock()
        else
            fishRunStartedAt = 0
        end
        updateStatsPanel()
    end)
end)

function autoFishTick()
    bossDetectTick()
    local ch = LocalPlayer.Character
    if not ch then return end

    local rodEquipped = ch:GetAttribute("Type") == "Fishing Rod"
    local isFishing = ch:GetAttribute("Fishing") == true
    local fishId = LocalPlayer:GetAttribute("FishID")

    if fsmState == "战斗中" then
        -- 跨场快速衔接检测: 上一场结束到新咬钩 < 主循环周期时, 状态机来不及回待机,
        -- FishID 直接换新 -> 强制重置战斗状态 (否则首发标志/游标继承上一场)
        if fishId ~= lastSeenFishId then
            lastSeenFishId = fishId
            if fishId then
                resetFightState()
                giveUpAt = nil
                if autoGiveUpOn and currentFishPower > 0 and getEquippedRodBasePower() > 0
                    and (getEquippedRodBasePower() / currentFishPower) < 0.3 then
                    giveUpAt = os.clock() + 5
                end
            end
        end
        -- 放弃判定 (优先级最高)
        local fish = fishId and fishesFolder:FindFirstChild(fishId)
        if giveUpAt and os.clock() >= giveUpAt then
            doGiveUp("力量差距过大")
            return
        end
        if fish then
            -- 进度停滞检测: 开战 10s 后进度 12s 不涨 = 打不动
            if autoGiveUpOn and os.clock() - fightStartedAt > 10 and lastProgressValue >= 0
                and fish.Value == lastProgressValue and os.clock() - lastProgressAt > 12 then
                doGiveUp("进度停滞")
                return
            end
            if fish.Value ~= lastProgressValue then
                lastProgressValue = fish.Value
                lastProgressAt = os.clock()
            end
        end
        -- 总超时兜底
        if autoGiveUpOn and os.clock() - fightStartedAt > 180 then
            doGiveUp("超时")
            return
        end
        -- 结束条件 (任一): FishID 被清 / 收回鱼竿 / 面板关闭且非钓鱼态
        if not fishId or not rodEquipped or (not isFishing and not fightGui.Visible) then
            stopFight()
            fsmState = "待机"
            -- 快速重抛节奏 (0.5~1.2s): 人类速抛玩家的真实区间, 兼顾反特征
            cooldownUntil = os.clock() + 0.5 + math.random() * 0.7
            updateStatus("本场结束, 稍候重抛…")
        else
            -- 显示当前鱼与击杀进度 (复用上方已取的 fish)
            local maxHp = fish and fish:GetAttribute("MaxHealth")
            if fish and type(maxHp) == "number" and maxHp > 0 then
                updateStatus(string.format("战斗中 · %d/%s (%.0f%%)",
                    fish.Value or 0, tostring(maxHp), (fish.Value or 0) / maxHp * 100))
            else
                updateStatus("战斗中 · 控条 " .. string.format("%.2f", lastBarXSeen))
            end
        end
    elseif fsmState == "等咬钩" then
        if fishId and fishesFolder:FindFirstChild(fishId) then
            -- 目标鱼过滤(多选): 只钓选中的鱼, 其他咬钩直接放弃 (不进战斗, 省时省力)
            if targetFishEnabled and next(targetFishNames) then
                local thisFish = fishId and fishesFolder:FindFirstChild(fishId)
                local fishBase = thisFish and (thisFish:GetAttribute("FishName") or thisFish.Name) or nil
                local cnBase = fishBase and (CN_ALL and CN_ALL[fishBase] or fishBase) or nil
                local isTarget = (fishBase and targetFishNames[fishBase]) or (cnBase and targetFishNames[cnBase])
                if not isTarget then
                    fastCancelTarget(fishLabel(thisFish and (thisFish:GetAttribute("FishName") or thisFish.Name) or "?"))
                    return
                end
            end
            enterFight()
            lastSeenFishId = fishId -- 同步衔接检测基线 (enterFight 已完整重置)
            fsmState = "战斗中"
            updateStatus("咬钩! 进入战斗")
        elseif not isFishing then
            -- 被打断 (手动收回/服务器超时), 回待机重抛
            fsmState = "待机"
            cooldownUntil = os.clock() + 0.5
        elseif os.clock() - castAt > 300 then
            -- 300s 无咬钩: 提示人工检查 (收回逻辑在服务端, 脚本不代收)
            updateStatus("超过 5 分钟未咬钩, 建议手动收回鱼竿")
            castAt = os.clock() -- 重置计时避免刷屏
        else
            updateStatus("等待咬钩… (" .. math.floor(os.clock() - castAt) .. "s)")
        end
    elseif fsmState == "等结算" then
        -- 已放弃: 等服务器清场 (FishID 清空) 或兜底超时, 期间不重抛
        local fid = LocalPlayer:GetAttribute("FishID")
        if not fid or os.clock() >= giveUpDeadline then
            fsmState = "待机"
            cooldownUntil = os.clock() + 0.5 + math.random() * 0.7
            updateStatus("放弃结算完成, 稍候重抛…")
        else
            updateStatus("已放弃, 等待服务器结算…")
        end
    else -- 待机 / 冷却
        if os.clock() < cooldownUntil then return end
        if not rodEquipped then
            -- 自愈兜底: 装备态丢失(收竿未复位/手动卸下/换场)时自动按 1 重装备, 节流防刷键。
            -- 旧版此处只提示"请先装备鱼竿"就 return, 装备态一旦丢失自动钓鱼即永久停摆。
            if autoFishOn and os.clock() - lastRodFixAt > 1.5 then
                lastRodFixAt = os.clock()
                pcall(function()
                    local k = Enum.KeyCode.One
                    VirtualInputManager:SendKeyEvent(true, k, false, game)
                    VirtualInputManager:SendKeyEvent(false, k, false, game)
                end)
            end
            updateStatus("鱼竿未装备, 正在自动装备…")
            return
        end
        if isInventoryFull() then
            if autoSellOn then
                if sellFishCount() > 0 then
                    -- 有可卖鱼: 卸货后无缝继续
                    doSellAll("背包已满")
                    cooldownUntil = os.clock() + 1.5
                    return
                end
                -- 满仓且全是锁定鱼: 出售救不了, 提示人工处理 (差分显示不刷屏)
                updateStatus("背包已满但全是锁定鱼, 请解锁或手动清理后继续")
                cooldownUntil = os.clock() + 3
                return
            end
            updateStatus("背包已满, 自动钓鱼暂停 (开启自动出售可继续)")
            autoFishOn = false
            TheKing.StopLoop("autoFish")
            TheKing.Notify({ Content = "背包已满, 自动钓鱼已暂停", Icon = "alert-triangle" })
            return
        end
        local hrp = ch:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        -- 智能回正 (开关可关): 钓鱼时会被鱼拉扯逐渐离岸, 漂移超限就拉回锚点;
        -- 增强: 还原抛竿瞬间的位置+朝向 (anchorCFrame), 而非仅位置
        if smartReturnOn then
            if anchorCFrame then
                local drift = (hrp.Position - anchorCFrame.Position).Magnitude
                -- 漂移 > 10 才回正; 但若距离远超合理漂移范围 (>150), 判定为玩家主动离开钓点而非被鱼拉扯,
                -- 此时回正会强行拉回, 破坏玩家正常移动/传送, 故跳过 (等下次抛竿重置锚点)
                if drift > 10 and drift <= 150 then
                    hrp.CFrame = anchorCFrame * CFrame.new(0, 2, 0)
                    updateStatus(string.format("智能回正: 拉回钓点 (漂移 %.0fm)", drift))
                elseif drift > 150 then
                    -- 离开过远: 不回正, 等待下一次抛竿自然重置锚点 (玩家可能去了别处)
                    updateStatus(string.format("已离开钓点 %.0fm, 不强制回正", drift))
                end
            else
                anchorCFrame = hrp.CFrame -- 首次抛竿记录完整位姿
                anchorPos = hrp.Position
            end
        end
        -- 与游戏 InputBegan 同款调用: 只发"我要抛竿"的请求, 结果听服务器
        RemoteCast:FireServer(hrp.CFrame)
        castAt = os.clock()
        fsmState = "等咬钩"
        updateStatus("已抛竿, 等待咬钩…")
    end
end

function setAutoFish(on, viaHotkey)
    -- 恩佐BOSS已并入自动钓鱼: 开自动钓鱼即自动接管恩佐战斗 (bossModeOn 跟随置真)
    autoFishOn = on and true or false
    bossModeOn = autoFishOn
    if on then
        anchorPos = nil -- 开启时重置锚点, 首竿位置为新钓点
        anchorCFrame = nil -- 重置位姿锚, 首竿重新记录
        fsmState = "待机"
        cooldownUntil = 0
        TheKing.StartLoop("autoFish", 0.4, autoFishTick) -- 0.4s: 钓鱼状态机 + 恩佐检测 (合并, 少一套定时器)
        if not viaHotkey then
            notifyToggle("自动钓鱼", true, "fish")
        end
    else
        TheKing.StopLoop("autoFish")
        if bossActive then stopBossFight() end -- 关钓鱼同时退出恩佐接管
        stopFight()
        updateStatus("已关闭")
        if not viaHotkey then
            notifyToggle("自动钓鱼", false, "fish")
        end
    end
end

-- ============================================================
-- UI
-- ============================================================
-- 注入初始化期静默: 从 NewTab 起 ConfigManager 恢复会触发一堆 Toggle Callback → notifyToggle,
-- 全部抑制, 直到注入初始化完成 (见文件末尾 setAutoFish(false) 之后恢复)
notifyMuted = true
local MainTab = TheKing.NewTab({ Title = "自动钓鱼", Icon = "fish" })

-- UI 构建包进函数: 块内局部/闭包捕获不再占 chunk 顶层寄存器 (Luau 200 上限)
function buildMainTab()

StatusPara = MainTab:Paragraph({
    Title = "运行状态",
    Desc = "未开启",
})

StatsPara = MainTab:Paragraph({
    Title = "效率统计",
    Desc = "开启自动钓鱼后开始累计",
})

toggleEls.autoFish = MainTab:Toggle({
    Title = "自动钓鱼",
    -- 注: 不设 Flag — 用户硬性要求注入默认关闭, 不随 ConfigManager 持久化
    Value = false,
    Callback = setAutoFish,
})

    MainTab:Section({ Title = "战斗策略" })

    MainTab:Dropdown({
        Title = "技能释放模式",
        Values = { "不释放", "智能择优", "顺序释放" },
        Value = "不释放",
        Flag = "skillMode",
        Callback = function(sel)
            if sel == "智能择优" or sel == "顺序释放" then
                autoSkillOn = true
                skillMode = sel
                syncSkillLoop()
            elseif sel == "不释放" then
                autoSkillOn = false
                skillMode = sel
                syncSkillLoop()
                notifyToggle("自动技能", false, "zap")
            end
        end,
    })

toggleEls.autoCharge = MainTab:Toggle({
    Title = "自动蓄力",
    Flag = "autoCharge",
    Value = false,
    Callback = function(state)
        autoChargeOn = state
        notifyToggle("自动蓄力", autoChargeOn, "timer")
    end,
})

MainTab:Slider({
    Title = "蓄力技时长 (秒)",
    Value = { Min = 5, Max = 60, Default = 15 },
    Step = 1,
    Flag = "chargeDuration", -- 修复: 此前无 Flag 不持久化, 重注入后丢失
    Callback = function(v)
        if type(v) == "number" and v >= 5 and v <= 60 then
            chargeDuration = math.floor(v)
        end
    end,
})

MainTab:Toggle({
    Title = "智能回正",
    Flag = "smartReturn",
    Value = true,
    Callback = function(state)
        smartReturnOn = state
        notifyToggle("智能回正", smartReturnOn, "rotate-cw")
    end,
})

MainTab:Toggle({
    Title = "智能放弃",
    Flag = "autoGiveUp",
    Value = true,
    Callback = function(state)
        autoGiveUpOn = state
        notifyToggle("智能放弃", autoGiveUpOn, "hand")
    end,
})

-- 目标鱼过滤: 分组隔离版本 (全部分组/天气鱼/各鱼饵/球体/功法/各岛屿), 切换分组清空旧选择
do
    -- 全鱼英文名列表 (去重, 来自 Inventory + FishingAreaRarity 兜底)
    local allFishEn = {}
    do
        local seen = {}
        if infoFolder then
            local inv = infoFolder:FindFirstChild("Inventory")
            if inv then
                for _, m in ipairs(inv:GetChildren()) do
                    if m:IsA("ModuleScript") and m.Name ~= "" and not seen[m.Name] then
                        if FISH_ISLE_MAP[m.Name] or (fishesFolder and fishesFolder:FindFirstChild(m.Name)) then
                            seen[m.Name] = true; table.insert(allFishEn, m.Name)
                        end
                    end
                end
            end
        end
        if not next(allFishEn) then
            for fishEn in pairs(FISH_ISLE_MAP) do
                if not seen[fishEn] then seen[fishEn] = true; table.insert(allFishEn, fishEn) end
            end
        end
        if not next(allFishEn) and fishesFolder then
            for _, f in ipairs(fishesFolder:GetChildren()) do
                local fn = f:GetAttribute("FishName") or f.Name
                if not seen[fn] then seen[fn] = true; table.insert(allFishEn, fn) end
            end
        end
    end

    -- 岛屿反查: 岛英文名 -> 该岛鱼英文名列表
    local ISLE_FISH = {}
    for fishEn, isleEn in pairs(FISH_ISLE_MAP) do
        ISLE_FISH[isleEn] = ISLE_FISH[isleEn] or {}
        table.insert(ISLE_FISH[isleEn], fishEn)
    end

    -- 掉落/类型集合: 扫描 Inventory 模块 (实测 Reward={Skill={名,权重}}/{Orb={名,权重}}; Boss=true=可多人钓的BOSS鱼)
    local SKILL_FISH, ORB_FISH, BOSS_FISH = {}, {}, {}
    do
        if infoFolder then
            local inv = infoFolder:FindFirstChild("Inventory")
            if inv then
                for _, m in ipairs(inv:GetChildren()) do
                    if m:IsA("ModuleScript") and m.Name ~= "" then
                        local ok, data = pcall(require, m)
                        if ok and type(data) == "table" then
                            if data.Boss then BOSS_FISH[m.Name] = true end
                            local rw = data.Reward
                            if type(rw) == "table" then
                                if rw.Skill then SKILL_FISH[m.Name] = true end
                                if rw.Orb then ORB_FISH[m.Name] = true end
                            end
                        end
                    end
                end
            end
        end
    end

    local function setToEn(set)
        local t = {}
        for k in pairs(set) do t[#t + 1] = k end
        return t
    end

    -- 分组定义: 组名 -> 取该组鱼英文名列表的函数
    local GROUP_DEFS = {
        ["全部分组"] = function() return allFishEn end,
        ["BOSS分组"] = function() return setToEn(BOSS_FISH) end,
        ["天气鱼分组"] = function() return setToEn(WEATHER_FISH_SET) end,
        ["诱饵制作分组"] = function() return { "Ascended Perch", "Frost Kingfish", "Primordial Kunfish Overlord", "Warbringer Shark", "Colossal Tigerfish", "Heavenpiercer Turtle", "Golden Guardian Fish", "Crimson Electric Eel", "Mountain Fish", "Tiger Mirefish", "Mirage Lanternfish", "Octoparasitic Fish" } end,
        ["鱼竿制作分组"] = function() return { "飞鱼帝", "飞鱼后", "Heavenpiercer Turtle", "彩虹龙鱼", "霜王翠鸟", "霜后鱼", "血玉鱼", "龙纹锦鲤", "无名章寄", "重生河豚兽", "Ascended Perch", "Mountain Fish" } end,
        ["球体分组"] = function() return setToEn(ORB_FISH) end,
        ["功法分组"] = function() return setToEn(SKILL_FISH) end,
        ["新手岛分组"] = function() return ISLE_FISH["Beginning Isle"] or {} end,
        ["竹子岛分组"] = function() return ISLE_FISH["Bamboo Isle"] or {} end,
        ["核弹岛分组"] = function() return ISLE_FISH["Fallout Isle"] or {} end,
        ["主权岛分组"] = function() return ISLE_FISH["Sovereign Isle"] or {} end,
        ["鲈鱼岛分组"] = function() return ISLE_FISH["Perch Isle"] or {} end,
        ["冰霜岛分组"] = function() return ISLE_FISH["Frost Isle"] or {} end,
        ["椰子岛分组"] = function() return ISLE_FISH["Coconut Isle"] or {} end,
        ["琥珀岛分组"] = function() return ISLE_FISH["Amber Isle"] or {} end,
        ["战场岛分组"] = function() return ISLE_FISH["Battlefield Isle"] or {} end,
        ["迷雾岛分组"] = function() return ISLE_FISH["Mistpeak Isle"] or {} end,
    }
    local GROUP_ORDER = {
        "全部分组", "BOSS分组", "天气鱼分组",
        "诱饵制作分组", "鱼竿制作分组",
        "球体分组", "功法分组",
        "新手岛分组", "竹子岛分组", "核弹岛分组", "主权岛分组", "鲈鱼岛分组",
        "冰霜岛分组", "椰子岛分组", "琥珀岛分组", "战场岛分组", "迷雾岛分组",
    }

    MainTab:Toggle({
        Title = "目标鱼过滤",
        Flag = "targetFishFilter",
        Value = false,
        Callback = function(state)
            targetFishEnabled = state
            local c = 0; for _ in pairs(targetFishNames) do c = c + 1 end
            if state and c == 0 then
                TheKing.Notify({ Title = "目标鱼过滤", Content = "已开启, 但还没选目标鱼 (在下方分组里勾选后自动生效)", Icon = "info" })
            end
            notifyToggle("目标鱼过滤", targetFishEnabled, "filter")
        end,
    })

    -- 分组选择器 (单选) — 排在选鱼上方
    local fishDD
    local choices = {}  -- label(中文) -> 英文名, 随分组更新
    local lastFishSel  -- 捕获鱼多选最近一次回传, 供重载兜底重套 (与 Config:Load 顺序无关)
    local function buildChoiceList(enList)
        local ch, cl = {}, {}
        for _, en in ipairs(enList) do
            local lbl = fishLabel(en)
            ch[lbl] = en
            table.insert(cl, lbl)
        end
        table.sort(cl)
        if #cl == 0 then cl = { "（该分组暂无可钓鱼）" } end
        return ch, cl
    end
    -- 缓存: 各组 choice 列表只构建一次 (切换分组不再重算全量鱼, 消除卡顿)
    local groupChoiceCache = {}
    local function rebuildFishDropdown(groupKey)
        local enList = GROUP_DEFS[groupKey] and GROUP_DEFS[groupKey]() or {}
        local ch, cl
        if groupChoiceCache[groupKey] then
            ch, cl = groupChoiceCache[groupKey].ch, groupChoiceCache[groupKey].cl
        else
            ch, cl = buildChoiceList(enList)
            groupChoiceCache[groupKey] = { ch = ch, cl = cl }
        end
        choices = ch
        -- 隔离: 切换分组清空旧选择
        targetFishNames = {}
        -- defer 让 Refresh 不在点击帧同步阻塞 (大列表重建 UI 在主线程, 延迟到下一帧更顺滑)
        if fishDD and type(fishDD.Refresh) == "function" then
            local list = cl
            task.defer(function()
                pcall(function() fishDD:Refresh(list) end)
            end)
        end
    end

    MainTab:Dropdown({
        Title = "目标鱼分组",
        Desc = "切换分组会清空已勾选",
        Values = GROUP_ORDER,
        Value = "全部分组",
        Multi = false,
        Flag = "targetFishGroup",  -- 持久化: 重载恢复上次分组
        Callback = function(sel)
            local key = (type(sel) == "table") and sel[1] or sel
            if not key or not GROUP_DEFS[key] then return end
            rebuildFishDropdown(key)
        end,
    })

    -- 鱼多选下拉 (创建一次, 切换分组用 :Refresh 更新选项)
    do
        local initCh, initList = buildChoiceList(allFishEn)
        choices = initCh
        fishDD = MainTab:Dropdown({
            Title = "选择目标鱼 (可多选)",
            Values = initList,
            Value = {},
            Multi = true,
            Flag = "targetFishSel",  -- 持久化: 重载恢复勾选 (与分组联动, 分组恢复在前故先清后填)
            Callback = function(selTable)
                lastFishSel = selTable  -- 先捕获, 兜底重套用
                targetFishNames = {}
                if type(selTable) ~= "table" then return end
                local n = 0
                for label, v in pairs(selTable) do
                    -- 兼容 WindUI 多选两种回传: {[label]=true} 或 {[1]="label"
                    local lbl = (type(label) == "string") and label or tostring(v)
                    local en = choices[lbl]
                    if en then
                        targetFishNames[en] = true
                        local cn = CN_ALL and CN_ALL[en]
                        if cn then targetFishNames[cn] = true end
                        n = n + 1
                    end
                end
            end,
        })
    end

    rebuildFishDropdown("全部分组")  -- 同步 choices/隔离(与初始列表一致)

    -- 重载恢复: 不在本处立即执行 (Config:Load 在脚本末尾才跑, 鱼多选 flag 恢复会触发回调重填),
    -- 改把恢复逻辑闭包赋给外层 targetFishRestoreFn, 在 TheKing.LoadConfig() 之后统一调用,
    -- 此时所有 flag 已恢复且 choices 已是当前分组映射, 重套一次即正确 (无时序竞争)
    targetFishRestoreFn = function()
        targetFishNames = {}
        if type(lastFishSel) == "table" then
            for label, v in pairs(lastFishSel) do
                local lbl = (type(label) == "string") and label or tostring(v)
                local en = choices[lbl]
                if en then
                    targetFishNames[en] = true
                    local cn = CN_ALL and CN_ALL[en]
                    if cn then targetFishNames[cn] = true end
                end
            end
        end
    end
end
end


-- ============================================================
-- Slam / Charge 响应式监听 (常挂, 回调内查开关)
-- 游戏 handler 会建按钮并在点击/超时时发包; 我们延迟检查:
--   按钮还在 = 用户没点 -> 代发最优结果并销毁按钮 (阻止其 2.1s 超时报 "Bad")
-- ============================================================
do
    local slamRemote = Events:FindFirstChild("Slam")
    if slamRemote then
        TheKing.AddConnection(slamRemote.OnClientEvent:Connect(function(callbackRemote)
            -- 内置 Perfect: 识别到 Slam/Heal/Perfect/QTE 小游戏按钮即代点, 无需开关
            task.delay(0.3, function()
                local trash = fightGui:FindFirstChild("TrashCan")
                if not trash then return end
                -- 自动 Perfect: 匹配 Slam/Heal/Perfect/QTE 任意按钮 (覆盖加血QTE等回血小游戏)
                for _, btn in ipairs(trash:GetChildren()) do
                    if btn:IsA("GuiButton") and (string.find(btn.Name, "Slam") or string.find(btn.Name, "Heal") or string.find(btn.Name, "Perfect") or string.find(btn.Name, "QTE")) then
                        callbackRemote:FireServer("Perfect")
                        btn:Destroy()
                        break
                    end
                end
            end)
        end))
    end

    local chargeRemote = Events:FindFirstChild("Charge")
    if chargeRemote then
        TheKing.AddConnection(chargeRemote.OnClientEvent:Connect(function(callbackRemote)
            -- 始终记录动态 remote (Charge 蓄力技能结算用)
        pendingChargeRemote = callbackRemote
        if not autoChargeOn then return end
        -- 节奏/Phase2 小游戏期间禁代点蓄力 (同战斗技能, 乱发会打乱判定导致服务器扣血)
        if rhythmActive then return end
        local _ch2 = LocalPlayer.Character
        if _ch2 and _ch2:GetAttribute("Phase2") == true then return end
        -- 蓄力保留期内 (技能 Charge 类蓄力中) 不点按钮, 避免把蓄力瞬间结算掉
            if os.clock() < chargeHoldUntil then return end
            task.delay(0.25, function()
                if not autoChargeOn then return end
                if os.clock() < chargeHoldUntil then return end
                local trash = fightGui:FindFirstChild("TrashCan")
                local btn = trash and trash:FindFirstChild("Charge")
                if btn then
                    callbackRemote:FireServer()
                    btn:Destroy()
                end
            end)
        end))
    end
end

-- ============================================================
-- 恩佐BOSS自动战斗模块 (用户手动开战, 本模块接管全流程)
-- 复用: 控条 = enterFight 的 BarFrame.Bar Heartbeat; 技能 = autoSkillTick (置 fsmState=战斗中)
--       QTE完美 = Slam/Heal 按钮自动 Perfect (见上方 Slam handler 扩展)
-- Phase2点击小游戏: 点绿心走游戏 onClick (晃动/换框/发包), 点不到再兜底发包
-- FinalPhase节奏: RhythmStart 后过线按 ASD, 走游戏 TryHit (不要直接 RhythmHit)
-- 注: Phase2/Rhythm 的 GUI 路径与服务器契约需实机验证 (见 devlog 待校准)
-- ============================================================
function stopPhase2Render()
    if phase2Conn then
        pcall(function() phase2Conn:Disconnect() end)
        phase2Conn = nil
    end
end

function startPhase2Render()
    if phase2Conn then return end
    phase2Conn = TheKing.AddConnection(RunService.RenderStepped:Connect(bossPhase2Tick))
end

function refreshPhase2Watch()
    if phase2WatchConn then
        pcall(function() phase2WatchConn:Disconnect() end)
        phase2WatchConn = nil
    end
    local ch = LocalPlayer.Character
    if not (bossActive and ch) then
        stopPhase2Render()
        return
    end
    local function sync()
        if bossActive and ch.Parent and ch:GetAttribute("Phase2") == true then
            startPhase2Render()
        else
            stopPhase2Render()
        end
    end
    phase2WatchConn = TheKing.AddConnection(ch:GetAttributeChangedSignal("Phase2"):Connect(sync))
    sync()
end

function startBossFight()
    if bossActive then return end
    bossActive = true
    bossPhase2Index = 0
    fsmState = "战斗中"
    -- 恩佐 Phase1 也有顶部鱼条, 复用 enterFight 真人点条
    enterFight()
    refreshPhase2Watch()
    updateStatus("恩佐BOSS战斗开始 · 自动接管")
    TheKing.Notify({ Content = "恩佐BOSS自动战斗已接管", Icon = "swords" })
end

function stopBossFight()
    if not bossActive then return end
    bossActive = false
    rhythmActive = false
    stopPhase2Render()
    if phase2WatchConn then
        pcall(function() phase2WatchConn:Disconnect() end)
        phase2WatchConn = nil
    end
    stopFight()
    fsmState = "待机"
    updateStatus("恩佐BOSS战斗结束")
end

-- BOSS战斗检测循环 (0.4s): bossModeOn 时自动感知战斗起止
-- 检测信号 (零 hook, 纯属性):
--   FishID 指向 workspace.Fishes 实体且实体 Boss==true → BOSS 战斗进行中
--   (普通钓鱼的鱼实体无 Boss 属性; BOSS 战斗实体带 Boss/MaxHealth/HasPhaseLeft 标记)
--   phase2/bfBarVisible/rhythmActive = 战斗中段信号 (Phase2 条 / FinalPhase 节奏)
-- 结束判据: FishID 消失 或 实体不再带 Boss 标记 → 战斗结束
local bossDetectState = { diagT = 0, cfg = nil, npc = nil }
function bossDetectTick()
    if not bossModeOn then
        if bossActive then stopBossFight() end
        return
    end
    local fid = LocalPlayer:GetAttribute("FishID")
    local fish = fid and fishesFolder:FindFirstChild(fid)
    local isBossFish = fish and fish:GetAttribute("Boss") == true
    -- 恩佐战斗权威信号 (服务器开战时设, BossUI 的 refresh() 据此禁用 Fight 按钮):
    --   ReplicatedStorage.BossSetUp.Enzo.InFight  (BossUI 监听此属性)
    --   workspace.NPC.Enzo.InFight                (NPC 模型镜像)
    local enzoCfg = bossDetectState.cfg
    if not (enzoCfg and enzoCfg.Parent) then
        local bossSetUp = ReplicatedStorage:FindFirstChild("BossSetUp")
        enzoCfg = bossSetUp and bossSetUp:FindFirstChild("Enzo")
        bossDetectState.cfg = enzoCfg
    end
    local enzoInFightCfg = enzoCfg and enzoCfg:GetAttribute("InFight") == true
    local npcEnzoM = bossDetectState.npc
    if not (npcEnzoM and npcEnzoM.Parent) then
        local npcFolder = workspace:FindFirstChild("NPC")
        npcEnzoM = npcFolder and npcFolder:FindFirstChild("Enzo")
        if not npcEnzoM then
            npcFolder = workspace:FindFirstChild("NPC", true)
            npcEnzoM = npcFolder and npcFolder:FindFirstChild("Enzo")
        end
        bossDetectState.npc = npcEnzoM
    end
    local enzoInFightNpc = npcEnzoM and npcEnzoM:GetAttribute("InFight") == true
    local enzoInFight = enzoInFightCfg or enzoInFightNpc
    local ch = LocalPlayer.Character
    local phase2 = ch and ch:GetAttribute("Phase2") == true
    local bfBarVisible = BossFightBar and BossFightBar.Visible
    -- 仅恩佐权威信号触发接管: 普通Boss鱼(章鱼等)二阶段也走 RhythmStart/Phase2, 但那是普通钓鱼流程,
    -- 误接管会①弹"恩佐已接管"干扰 ②bossPhase2Tick 盲发 BossPhase2Action 致服务器扣血(维妮塔)。
    -- 章鱼等普通Boss鱼节奏由 bossRhythmTick 接管, 点击小游戏由游戏自身处理, 不走恩佐接管链路。
    -- 不依赖 phase2/rhythmActive/bossEverConfirmed 判定, 避免恩佐战后钓章鱼二段被误接管。
    local midFight = enzoInFight
    -- 恩佐接管: 仅恩佐权威信号触发; 普通Boss鱼(章鱼等)带Boss=true属性不在此接管,
    -- 其节奏/二段由通用 bossRhythmTick + 战斗流程处理
    local inBossFight = midFight
    local now = os.clock()
    if inBossFight then
        bossEverConfirmed = true
        lastConfirmedFight = now
    end
    if bossActive then
        -- 结束判据: 用户关开关, 或曾确认战斗且所有信号持续消失 >2s (Phase1 无信号不误停)
        if not bossModeOn then
            stopBossFight()
        elseif bossEverConfirmed and (now - lastConfirmedFight > 2) then
            stopBossFight()
        end
    else
        -- 未激活但检测到 BOSS 战斗信号 → 接管
        if inBossFight then
            startBossFight()
        end
    end
    if now - bossDetectState.diagT > 2 then
        bossDetectState.diagT = now
        logDecision(string.format("[恩佐检测] active=%s cfgInFight=%s npcInFight=%s phase2=%s bfBar=%s rhythm=%s isBossFish=%s",
            tostring(bossActive), tostring(enzoInFightCfg), tostring(enzoInFightNpc), tostring(phase2), tostring(bfBarVisible), tostring(rhythmActive), tostring(isBossFish)))
    end
    if bossActive and (phase2 or bfBarVisible) then
        startPhase2Render()
    end
end

-- Phase2: 不点鼠标(避免三角波 Hit=false). 条刚进绿心 → 短反应 → 发包+晃动+换框, 一趟只打一次.
local phase2State = { nextAt = 0, reactAt = 0, wasIn = false, shaking = false }

local function relocatePhase2Hitbox(predX, hbW)
    if not BossHitbox then return end
    local span = math.max(0.05, 1 - hbW)
    local newX = math.random() * span
    for _ = 1, 20 do
        if math.abs(newX - predX) >= 0.1 then break end
        newX = math.random() * span
    end
    BossHitbox.Position = UDim2.new(newX, 0, BossHitbox.Position.Y.Scale, BossHitbox.Position.Y.Offset)
end

local function shakePhase2LikeGame()
    if phase2State.shaking or not fightGui then return end
    phase2State.shaking = true
    local origin = fightGui.Position
    local t0 = os.clock()
    local conn
    conn = RunService.RenderStepped:Connect(function()
        local t = os.clock() - t0
        if t < 0.25 then
            local amp = 0.02 * (1 - t / 0.25)
            fightGui.Position = UDim2.new(
                origin.X.Scale + (math.random() - 0.5) * 2 * amp, origin.X.Offset,
                origin.Y.Scale + (math.random() - 0.5) * 2 * amp, origin.Y.Offset
            )
            return
        end
        if conn then pcall(function() conn:Disconnect() end) end
        fightGui.Position = origin
        phase2State.shaking = false
    end)
    TheKing.AddConnection(conn)
end

function bossPhase2Tick()
    if not bossActive then return end
    if not (BossFightBar and BossFightBar.Parent) then
        BossFightBar = fightGui and fightGui:FindFirstChild("BossFightBar")
    end
    if BossFightBar then
        if not (BossBar and BossBar.Parent) then
            BossBar = BossFightBar:FindFirstChild("Bar")
        end
        if not (BossHitbox and BossHitbox.Parent) then
            BossHitbox = BossFightBar:FindFirstChild("Hitbox")
        end
    end
    local ch = LocalPlayer.Character
    local phase2 = ch and ch:GetAttribute("Phase2") == true
    local barOn = BossFightBar and BossFightBar.Visible == true
    if not phase2 and not barOn then
        phase2State.wasIn = false
        phase2State.reactAt = 0
        return
    end
    if not BossPhase2Action then return end
    if not (BossBar and BossHitbox) then return end
    local now = os.clock()
    local pred = BossBar.Position.X.Scale
    local hbX = BossHitbox.Position.X.Scale
    local hbW = math.max(0.04, BossHitbox.Size.X.Scale)
    -- 双方 AnchorPoint 0.5: |条心-框心| <= 半宽 = 指针在绿条内
    local inGreen = math.abs(pred - hbX) <= (hbW * 0.5)
    if not inGreen then
        phase2State.wasIn = false
        return
    end
    if now < phase2State.nextAt then return end
    phase2State.wasIn = true
    phase2State.lastHit = now
    phase2State.nextAt = now + 0.32 + math.random() * 0.10
    bossPhase2Index = bossPhase2Index + 1
    pcall(function()
        BossPhase2Action:FireServer({ Hit = true, Index = bossPhase2Index })
    end)
    shakePhase2LikeGame()
    local hbW2, pred2 = hbW, pred
    task.delay(0.04, function()
        pcall(function()
            relocatePhase2Hitbox(pred2, hbW2)
        end)
    end)
end

-- 节奏: 只按 ASD, 让游戏 TryHit 自己发包+删内部表+播 EXP.
-- 直接 RhythmHit("hit") 不删 u144, 音符过线+0.22 后游戏会再发 miss → 扣血.
-- 判定与游戏一致: |note.Position.Y.Scale - BarFrame.Y| <= 0.22; 我们只在过线后、偏离<=0.10 时按, 避免空按 miss.
local function stopRhythmDriver()
    rhythmActive = false
    if rhythmConn then
        pcall(function() rhythmConn:Disconnect() end)
        rhythmConn = nil
    end
end

local function startRhythmDriver()
    table.clear(notePrevY)
    table.clear(noteHit)
    rhythmActive = true
    rhythmUntil = os.clock() + 130
    if rhythmConn then return end
    rhythmConn = TheKing.AddConnection(RunService.Heartbeat:Connect(function()
        bossRhythmTick()
    end))
end

function bossRhythmTick()
    if not rhythmActive then return end
    if os.clock() > rhythmUntil then
        stopRhythmDriver()
        return
    end
    pcall(function()
        local rhythmGui = fightGui and fightGui:FindFirstChild("Rhythm")
        if not rhythmGui or rhythmGui.Visible == false then return end
        for _, lane in ipairs({ "ProgressionA", "ProgressionS", "ProgressionD" }) do
            local key = RHYTHM_KEYS[lane]
            if not key then continue end
            local track = rhythmGui:FindFirstChild(lane)
            if not track then continue end
            local barFrame = track:FindFirstChild("BarFrame")
            local lineY = (barFrame and barFrame:IsA("GuiObject")) and barFrame.Position.Y.Scale or 0.85
            local best, bestAbsd, bestCrossed = nil, math.huge, false
            for _, note in ipairs(track:GetChildren()) do
                if not note:IsA("GuiObject") then continue end
                if not string.find(note.Name, "Note") or note.Name == "NoteFrame" then continue end
                if noteHit[note] then continue end
                local y = note.Position.Y.Scale
                local prev = notePrevY[note]
                notePrevY[note] = y
                if y < lineY then continue end
                local absd = y - lineY
                if absd > RHYTHM_LATE then continue end
                local crossed = (prev ~= nil) and (prev < lineY)
                if (crossed and not bestCrossed) or (crossed == bestCrossed and absd < bestAbsd) then
                    best, bestAbsd, bestCrossed = note, absd, crossed
                end
            end
            if best then
                noteHit[best] = true
                sendLaneKey(key)
            end
        end
    end)
end

-- RhythmStart 监听: 节奏小游戏开始 (恩佐 FinalPhase 或普通钓鱼 Boss 鱼二段均触发)
if RhythmStartEv then
    TheKing.AddConnection(RhythmStartEv.OnClientEvent:Connect(function()
        startRhythmDriver()
        TheKing.Notify({ Content = "节奏小游戏 · 自动打击", Icon = "music" })
    end))
end

-- RhythmStop 监听: 节奏结束立即停扫 (服务器显式推送)
if RhythmStopEv then
    TheKing.AddConnection(RhythmStopEv.OnClientEvent:Connect(function()
        stopRhythmDriver()
    end))
end

-- 恩佐开战检测: 监听服务器推送事件 (L1 安全, 非 hook, 不污染 UI 点击链路)
-- 兜底: StartBossFight.OnClientEvent(开战回推) / BossPhase2Setup.OnClientEvent(阶段开始) 任一触发即接管
local StartBossFightC = Events and Events:FindFirstChild("StartBossFight")
if StartBossFightC then
    TheKing.AddConnection(StartBossFightC.OnClientEvent:Connect(function(...)
        if bossModeOn and not bossActive then
            task.spawn(startBossFight)
            TheKing.Notify({ Content = "恩佐开战检测 (服务器事件)", Icon = "swords" })
            logDecision("开战检测: StartBossFight.OnClientEvent")
        end
    end))
end
local BossPhase2SetupC = Events and Events:FindFirstChild("BossPhase2Setup")
if BossPhase2SetupC then
    TheKing.AddConnection(BossPhase2SetupC.OnClientEvent:Connect(function(...)
        if bossModeOn and not bossActive then
            task.spawn(startBossFight)
            logDecision("开战检测: BossPhase2Setup.OnClientEvent")
        end
    end))
end

-- 恩佐BOSS已并入自动钓鱼: bossModeOn 由 setAutoFish 同步; 检测在 autoFishTick 内调用
-- 旧 setBossMode 独立开关已移除, 自动钓鱼成为恩佐战斗唯一总驱动

-- ============================================================
-- 钓鱼会话监听: 从开始包读取鱼信息 (放弃机制的力量判据)
-- 游戏 handler 与本监听并存, 多监听者合法
-- ============================================================
TheKing.AddConnection(Events.FishingMinigame.OnClientEvent:Connect(function(fishInfo)
    if type(fishInfo) == "table" then
        currentFishPower = tonumber(fishInfo.Power) or 0
        currentFishName = tostring(fishInfo.FishName or "") -- 供多命感知取配置 Phase
        -- 注: 恩佐BOSS 不走 FishingMinigame (逆向证实), 此处不再据 Boss 标记置 bossActive
    end
end))

-- ============================================================
-- 钓获通知: 上钩的鱼实时提示 (Inventory.ChildAdded, 事件驱动零轮询)
-- ============================================================
do
    local invFolder = playerData and playerData:FindFirstChild("Inventory")
    if invFolder then
        TheKing.AddConnection(invFolder.ChildAdded:Connect(function(item)
            stats.fish = stats.fish + 1
            -- 智能锁定: 命中规则时接管通知 (只弹一条锁定通知, 含中文名);
            --           未启用/未命中时才弹常规"钓到了"
            local handled = false
            if lockOn then
                handled = autoLockCheck(item)
            end
            if not handled then
            task.delay(0.8, function()
                if not item.Parent then return end -- 可能已被自动出售
                local base = getFishBase(item.Name)
                local price = tonumber(string.match(item.Name, " | ([%d%.]+)")) or 0
                TheKing.Notify({
                    Title = "钓到了! " .. trName(base),
                    Content = "价格 ¥" .. fmtNum(price),
                    Icon = "fish",
                    Duration = 2,
                })
            end)
            end
        end))
    end
end

buildMainTab()

-- ============================================================
-- 天气预报: 天气稀有鱼提醒 + 预报天气选项 (整合进自动钓鱼 Tab)
-- WEATHER_ISLE_MAP / WEATHER_FISH_SET 已在状态区定义 (智能锁定共用)
-- ============================================================
do
    MainTab:Section({ Title = "天气预报" })
    -- 注: 天气查表统一走 getWeatherTargets() (键规范化), 不再本地持有 WEATHER_ISLE_MAP 副本

    local weatherAlertOn = true
    local lastAlertKey = nil
    -- 关注的天气 (英文键集合, 由 Dropdown 中文选择映射)
    local watchWeathers = { Windy = true, Snowy = true, Thunderstorm = true, Foggy = true, ["Blazing Sun"] = true }
    local CN_TO_WEATHER = {
        ["大风"] = "Windy", ["下雨"] = "Rainy", ["雷暴"] = "Thunderstorm",
        ["浓雾"] = "Foggy", ["下雪"] = "Snowy", ["烈阳高照"] = "Blazing Sun",
    }

    --- 玩家最近的岛屿 (500 格内), 不在任何岛附近返回 nil
    local function getNearestIsle()
        local ch = LocalPlayer.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        if not hrp or not spawnFolder then return nil end
        local best, bestDist = nil, 500
        for _, p in ipairs(spawnFolder:GetChildren()) do
            if p:IsA("BasePart") then
                local d = (hrp.Position - p.Position).Magnitude
                if d < bestDist then
                    best, bestDist = p.Name, d
                end
            end
        end
        return best
    end

    --- 明显提醒: 大通知 + 本地提示音
    local function alertWeather(weather, lines, hereIsle)
        pcall(function()
            local sound = Instance.new("Sound")
            sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
            sound.Volume = 1
            sound.Parent = game:GetService("SoundService")
            sound:Play()
            game:GetService("Debris"):AddItem(sound, 3)
        end)
        for _, line in ipairs(lines) do
            local mark = (hereIsle and line:find(hereIsle, 1, true)) and "★ 你在这里! " or ""
            TheKing.Notify({
                Title = "天气限定鱼! [" .. trName(weather) .. "]",
                Content = mark .. line,
                Icon = "fish",
                Duration = 12,
            })
        end
    end

    --- 检查并提醒 (仅提醒"关注天气"里选中的)
    local function checkWeather(initial)
        local weather = workspace:GetAttribute("Weather")
        logDecision("天气检测: " .. tostring(weather) .. " initial=" .. tostring(initial))
        if not weatherAlertOn then return end
        local targets = getWeatherTargets(weather)
        if not targets then return end
        -- 只提醒用户关注的天气
        if not watchWeathers[weather] then
            logDecision("天气 " .. trName(weather) .. " 不在关注列表, 跳过")
            return
        end
        local here = getNearestIsle()
        local lines, hasHere = {}, false
        for isle, fishes in pairs(targets) do
            local cnFish = {}
            for _, f in ipairs(fishes) do table.insert(cnFish, trName(f)) end
            local line = trName(isle) .. ": " .. table.concat(cnFish, " / ")
            if isle == here then hasHere = true end
            table.insert(lines, line)
        end
        table.sort(lines)
        local key = weather .. "|" .. table.concat(lines, "|")
        if key == lastAlertKey and not initial then return end
        lastAlertKey = key
        if initial and not hasHere then return end -- 启动时不在相关岛就不打扰
        alertWeather(weather, lines, hasHere and here or nil)
        if hasHere then
            updateStatus("★ 当前岛屿正在出天气限定 Boss!")
        end
    end

    MainTab:Toggle({
        Title = "天气稀有鱼提醒",
        Flag = "weatherAlert",
        Value = true,
        Callback = function(state)
            weatherAlertOn = state
            notifyToggle("天气稀有鱼提醒", weatherAlertOn, "cloud-lightning")
            if state then
                task.delay(3, function() -- 等 Character/位置就绪
                    if weatherAlertOn then checkWeather(true) end
                end)
            end
        end,
    })

    MainTab:Dropdown({
        Title = "关注哪些天气",
        Values = { "大风", "下雨", "雷暴", "浓雾", "下雪", "烈阳高照" },
        Value = { "大风", "雷暴", "浓雾", "下雪", "烈阳高照" },
        Multi = true,
        Flag = "watchWeathers",
        Callback = function(selTable)
            watchWeathers = {}
            if type(selTable) ~= "table" then return end
            for cnLabel, v in pairs(selTable) do
                -- 兼容两种 WindUI 格式: {[label]=true} 或 {[1]="label"}
                local lbl = (type(cnLabel) == "string") and cnLabel or tostring(v)
                local en = CN_TO_WEATHER[lbl]
                if en then watchWeathers[en] = true end
            end
        end,
    })

    TheKing.AddConnection(workspace:GetAttributeChangedSignal("Weather"):Connect(function()
        if weatherAlertOn then
            checkWeather(false)
        end
    end))

    -- 启动 8 秒后做一次静默初始化 (记录当前天气基线, 不打扰)
    task.delay(8, function()
        lastAlertKey = nil
        checkWeather(true)
    end)
end

-- ============================================================
-- 快捷传送: 与游戏"回到出生点"完全同款 (HRP.CFrame = Spawnpoint[区].CFrame)
-- 岛屿列表运行时读 workspace.Spawnpoint, 游戏加新岛自动跟随
-- ============================================================
local BaitTab = TheKing.NewTab({ Title = "背包管理", Icon = "package" })

do
    local baitChoices = {}   -- Dropdown 显示文本 -> 饵名
    local choiceNames = {}
    if infoFolder then
        local baitInfo = infoFolder:FindFirstChild("Bait")
        if baitInfo then
            for _, m in ipairs(baitInfo:GetChildren()) do
                local ok, cfg = pcall(require, m)
                -- 只列可购买的 Normal 类 (Mythical 价格 0 不可购)
                if ok and type(cfg) == "table" and tostring(cfg.Type) == "Normal" then
                    local label = string.format("%s · ¥%s (幸运 %s%%)", trName(m.Name), tostring(cfg.Price), tostring(cfg.Luck))
                    baitChoices[label] = m.Name
                    table.insert(choiceNames, label)
                end
            end
        end
        table.sort(choiceNames)
    end

    BaitTab:Dropdown({
        Title = "选择诱饵",
        Flag = "baitSelection",
        Values = choiceNames,
        Value = choiceNames[1],
        Callback = function(sel)
            selectedBait = baitChoices[sel]
        end,
    })

    BaitTab:Slider({
        Title = "库存降到多少时补货",
        Flag = "baitReorderAt",
        Value = { Min = 1, Max = 10, Default = 2 },
        Step = 1,
        Callback = function(v)
            if type(v) == "number" and v >= 1 and v <= 10 then
                baitReorderAt = math.floor(v)
            end
        end,
    })

    BaitTab:Slider({
        Title = "每次购买数量",
        Flag = "baitBuyAmount",
        Value = { Min = 1, Max = 50, Default = 2 },
        Step = 1,
        Callback = function(v)
            if type(v) == "number" and v >= 1 and v <= 50 then
                baitBuyAmount = math.floor(v)
            end
        end,
    })

    BaitTab:Toggle({
        Title = "启用自动买饵",
        Flag = "autoBait",
        Value = false,
        Callback = setAutoBait,
    })
end

-- ============================================================
-- 背包管理: 钓鱼竿装备 (v0.26.0)
-- 数据源: Info.Inventory 中 Type=="Fishing Rod" 的模块, Power 字段 = 能量
-- 排序: 能量降序, 同能量并列(稳定排序, 保持原扫描顺序)
-- 装备: Events.EquipFishingRod:InvokeServer(竿英文名) — 与游戏背包点击 Equip 完全同款
-- ============================================================
do
    -- 鱼竿中文名 (39 把全量; 英文直译命名, 与 intel 已知命名一致, 用户偏好可再调)
    local CN_RODS = {
        ["Wooden Rod"] = "木竿",
        ["Alloy Rod"] = "合金竿",
        ["Bamboo Rod"] = "竹竿",
        ["Bloodfire Rod"] = "血焰竿",
        ["Emerald Rod"] = "翡翠竿",
        ["Enchanted Steel Rod"] = "附魔钢竿",
        ["Iron Hook Rod"] = "铁钩竿",
        ["Ascendant Bamboo Rod"] = "上品竹竿",
        ["Steel Rod"] = "钢竿",
        ["Shadow Rod"] = "暗影竿",
        ["Triple Steel Rod"] = "三连钢竿",
        ["Golden Rod"] = "黄金竿",
        ["Maoshan Rod"] = "茅山竿",
        ["Eye Of Horus"] = "荷鲁斯之眼",
        ["Grandmaster Steel Rod"] = "宗师钢竿",
        ["Grandmaster Emerald Rod"] = "宗师翡翠竿",
        ["Inferno Rod"] = "炼狱竿",
        ["Grandmaster Golden Rod"] = "宗师黄金竿",
        ["Blazeshark Rod"] = "焰鲨竿",
        ["Diamond Spine Rod"] = "钻石脊竿",
        ["Golden Spine Rod"] = "黄金脊竿",
        ["Platinum Spine Rod"] = "白金脊竿",
        ["Steel Spine Rod"] = "钢脊竿",
        ["Lifebloom Rod"] = "生命绽放竿",
        ["Gravisteel Rod"] = "引力钢竿",
        ["Auric Gravity Rod"] = "赤金引力竿",
        ["Inferno Gravity Rod"] = "炼狱引力竿",
        ["Cryo Gravity Rod"] = "冰霜引力竿",
        ["Anchorbound Rod"] = "锚定竿",
        ["Thunder Thorn Rod"] = "雷霆荆棘竿",
        ["Soul Thorn Rod"] = "灵魂荆棘竿",
        ["Demonic Rod"] = "恶魔竿",
        ["Starlight Rod"] = "星光竿",
        ["Kraken Rod"] = "克拉肯竿",
        ["Diamond Rod"] = "钻石竿",
        ["Taoist Rod"] = "道士竿",
        ["Heavenpiercer Rod"] = "穿天竿",
        ["Pure Diamond Rod"] = "纯钻石竿",
        ["Sacred Bamboo Rod"] = "神圣竹竿",
    }
    local function rodCN(name)
        return CN_RODS[name] or trName(name)
    end
    local rodChoices = {} -- 显示文本 -> 竿英文名
    local rodNames = {}   -- 显示文本列表 (能量降序)
    local rodDropdown = nil
    local selectedRod = nil
    local rodEquipEv = Events and Events:FindFirstChild("EquipFishingRod")

    local function buildRodList()
        rodChoices, rodNames = {}, {}
        local list = {}
        -- v0.26.2: 只列**已拥有**的竿 — FishingRodInventory 的 Folder 子对象是**全量目录**(39把都有),
        -- 每个 Folder 内 Owned(BoolValue)=true 才是真拥有 (实测: Grandmaster Golden Rod 的 Owned=false)
        local owned = playerData and playerData:FindFirstChild("FishingRodInventory")
        if owned then
            local cfgInv = infoFolder and infoFolder:FindFirstChild("Inventory")
            for _, f in ipairs(owned:GetChildren()) do
                if not f:IsA("Folder") then continue end
                local ownedFlag = f:FindFirstChild("Owned")
                if not (ownedFlag and ownedFlag.Value == true) then continue end -- 未拥有, 跳过
                local power = 0
                    -- 从全量配置库取该竿的 Power(能量); 取不到则按 0 排尾
                    local m = cfgInv and cfgInv:FindFirstChild(f.Name)
                    if m then
                        local ok, cfg = pcall(require, m)
                        if ok and type(cfg) == "table" then
                            power = tonumber(cfg.Power) or 0
                        end
                    end
                    table.insert(list, { name = f.Name, power = power })
            end
        end
        -- 能量降序; 同能量并列(稳定排序: 相等时返回 false 保持原顺序)
        table.sort(list, function(a, b)
            if a.power ~= b.power then return a.power > b.power end
            return false
        end)
        for _, r in ipairs(list) do
            local label = string.format("%s · 能量 %s", rodCN(r.name), tostring(r.power))
            rodChoices[label] = r.name
            table.insert(rodNames, label)
        end
    end
    buildRodList()

    BaitTab:Section({ Title = "钓鱼竿" })

    BaitTab:Button({
        Title = "刷新钓鱼竿列表",
        Icon = "refresh-cw",
        Callback = function()
            buildRodList()
            if rodDropdown and type(rodDropdown.Refresh) == "function" then
                pcall(function() rodDropdown:Refresh(rodNames) end)
            end
            TheKing.Notify({ Content = "已刷新钓鱼竿列表 (" .. #rodNames .. " 把)", Icon = "check-circle", Duration = 3 })
        end,
    })

    rodDropdown = BaitTab:Dropdown({
        Title = "选择钓鱼竿",
        Values = rodNames,
        Value = rodNames[1],
        Callback = function(sel)
            selectedRod = rodChoices[sel]
        end,
    })

    BaitTab:Button({
        Title = "装备选中的鱼竿",
        Icon = "wand-2",
        Callback = function()
            if not rodEquipEv then
                TheKing.Notify({ Content = "未找到 EquipFishingRod 接口, 游戏可能已更新", Icon = "alert-triangle", Duration = 5 })
                return
            end
            if not selectedRod then
                TheKing.Notify({ Content = "请先在列表中选择钓鱼竿", Icon = "alert-triangle", Duration = 3 })
                return
            end
            local rodName = selectedRod
            local ok, res = pcall(function()
                return rodEquipEv:InvokeServer(rodName)
            end)
            if ok and res ~= false then
                TheKing.Notify({ Title = "已装备", Content = rodCN(rodName), Icon = "check-circle", Duration = 5 })
            else
                TheKing.Notify({ Title = "装备失败", Content = rodCN(rodName) .. " 装备失败, 请重试", Icon = "alert-triangle", Duration = 5 })
            end
        end,
    })
end

-- ============================================================
-- 玩家 Tab
-- ============================================================

local BagTab = TheKing.NewTab({ Title = "库存管理", Icon = "backpack" })

do
    -- ---- 自动出售 (自主 Tab 迁移) ----
    local SellSection = BagTab:Section({ Title = "自动出售" })

    toggleEls.autoSell = BagTab:Toggle({
        Title = "自动出售",
        Flag = "autoSell",
        Value = false,
        Callback = setAutoSell,
    })

    BagTab:Dropdown({
        Title = "出售时机",
        Values = { "固定数量", "背包80%", "背包90%", "背包装满" },
        Value = "固定数量",
        Flag = "sellTriggerMode",
        Callback = function(sel)
            sellTriggerMode = sel
        end,
    })

    BagTab:Slider({
        Title = "出售阈值 (固定数量模式)",
        Flag = "sellThreshold",
        Value = { Min = 5, Max = 400, Default = 20 },
        Step = 1,
        Callback = function(value)
            if type(value) == "number" and value >= 5 and value <= 400 then
                sellThreshold = math.floor(value)
            end
        end,
    })

    BagTab:Button({
        Title = "立即全卖",
        Icon = "coins",
        Callback = function()
            local okSell = doSellAll("手动")
            if not okSell then
                TheKing.Notify({ Content = "没有可出售的鱼", Icon = "info" })
            end
        end,
    })

    -- ---- 智能锁定 (规则数据源 = Info.MainQuest 全量解析) ----
    BagTab:Section({ Title = "智能锁定 (保护要用的鱼)" })

    -- 动态规则表: 启动即解析 (游戏更新自动跟随), 刷新按钮可重跑
    buildLockTables()

    local lockInfoPara
    local function refreshLockInfo()
        local locked, unlocked = lockStats()
        local giveN, catchN, weightN = 0, 0, 0
        for _ in pairs(DYN_QUEST.give) do giveN = giveN + 1 end
        for _ in pairs(DYN_QUEST.catch) do catchN = catchN + 1 end
        for _ in pairs(DYN_QUEST.weight) do weightN = weightN + 1 end
        local desc = string.format(
            "任务规则已解析: 上交鱼 %d 种 · 钓捕鱼 %d 种 · 重量挑战 %d 种\n背包: 已锁 %d 条 · 未锁 %d 条",
            giveN, catchN, weightN, locked, unlocked)
        if lockInfoPara and type(lockInfoPara.SetDesc) == "function" then
            pcall(function() lockInfoPara:SetDesc(desc) end)
        end
    end

    lockInfoPara = BagTab:Paragraph({
        Title = "锁定规则说明",
        Desc = "任务规则解析中…",
    })
    task.delay(0.5, refreshLockInfo) -- 等 playerData 就绪后刷新统计

    BagTab:Dropdown({
        Title = "启用哪些锁定规则",
        Values = { "任务上交鱼", "任务钓捕鱼", "合成材料鱼", "任务重量挑战鱼", "特殊天气鱼" },
        Value = { "任务上交鱼", "合成材料鱼", "特殊天气鱼" },
        Multi = true,
        Flag = "lockRules",
        Callback = function(selTable)
            lockRuleGive, lockRuleCatch, lockRuleWeight, lockRuleCraft, lockRuleWeather = false, false, false, false, false
            for sel in pairs(selTable or {}) do
                if sel == "任务上交鱼" then lockRuleGive = true end
                if sel == "任务钓捕鱼" then lockRuleCatch = true end
                if sel == "合成材料鱼" then lockRuleCraft = true end
                if sel == "任务重量挑战鱼" then lockRuleWeight = true end
                if sel == "特殊天气鱼" then lockRuleWeather = true end
            end
        end,
    })

    -- 手动常锁鱼种: 用户指定哪些鱼永远锁定 (优先级最高, 不受规则/价值影响)
    -- 鱼种清单直接取自「当前背包真实鱼种」, 名称空间与锁定逻辑一致 (FISH_ISLE_MAP/fishesFolder 不含背包真实鱼名)
    local function getBackpackFishSpecies()
        local me = game.Players.LocalPlayer
        local userId = tostring(me.UserId)
        local inv = DataFolder and DataFolder:FindFirstChild(userId) and DataFolder[userId]:FindFirstChild("Inventory")
        local set = {}
        if inv then
            for _, e in ipairs(inv:GetChildren()) do
                local base = e.Name:match("^(.-) %|") or e.Name
                if base ~= "" then set[base] = true end
            end
        end
        local list = {}
        for k in pairs(set) do list[#list + 1] = k end
        table.sort(list)
        return list
    end
    local manualLockChoices = getBackpackFishSpecies()
    local manualLockMap = {}
    for _, name in ipairs(manualLockChoices) do manualLockMap[name] = name end

    BagTab:Dropdown({
        Title = "手动常锁鱼种",
        Values = manualLockChoices,
        Value = {},
        Multi = true,
        Flag = "manualLock",
        Callback = function(selTable)
            manualLockSet = {}
            if type(selTable) == "table" then
                for label, v in pairs(selTable) do
                    local lbl = (type(label) == "string") and label or tostring(v)
                    local en = manualLockMap[lbl]
                    if en then manualLockSet[en] = true end
                end
            end
            task.spawn(function()
                local n, names = scanAndLock()
                TheKing.Notify({ Title = "智能锁定", Content = string.format("手动锁定生效, 新锁定 %d 条%s", n, fmtLockList(names)), Icon = "lock" })
            end)
        end,
    })

    BagTab:Slider({
        Title = "价值锁定 (0=关闭)",
        Flag = "lockValueMin",
        Value = { Min = 0, Max = 10000000, Default = 0 },
        Step = 50000,
        Callback = function(v)
            if type(v) == "number" and v >= 0 then
                lockValueMin = math.floor(v)
            end
        end,
    })

    BagTab:Button({
        Title = "立即扫描并锁定现有背包",
        Icon = "lock",
        Callback = function()
            task.spawn(function()
                local n, names = scanAndLock()
                refreshLockInfo()
                TheKing.Notify({
                    Title = "智能锁定",
                    Content = string.format("扫描完成, 新锁定 %d 条鱼%s", n, fmtLockList(names)),
                    Icon = "lock",
                })
            end)
        end,
    })

    BagTab:Button({
        Title = "解锁规则锁定的鱼",
        Desc = "解除任务/合成/天气规则锁 (手动常锁与价值锁保留)",
        Icon = "unlock",
        Color = Color3.fromRGB(255, 170, 90),
        Callback = function()
            task.spawn(function()
                local n = unlockRuleLocked()
                refreshLockInfo()
                TheKing.Notify({
                    Title = "智能锁定",
                    Content = "已解锁规则锁 " .. n .. " 条 (手动/价值锁保留)",
                    Icon = "unlock",
                })
            end)
        end,
    })

    BagTab:Button({
        Title = "刷新任务规则",
        Icon = "refresh-cw",
        Callback = function()
            task.spawn(function()
                buildLockTables()
                refreshLockInfo()
                TheKing.Notify({ Title = "智能锁定", Content = "任务规则已刷新", Icon = "check-circle" })
            end)
        end,
    })

    BagTab:Toggle({
        Title = "启用智能锁定",
        Flag = "autoLock",
        Value = false,
        Callback = setAutoLock,
    })
end

-- ============================================================
-- 快捷键 Tab: 主要功能键位绑定 (默认无绑定, 绑定 ESC = 取消)
-- Toggle 类经 TheKing.Config:Set 同步 UI 与内部状态; Action 类直接执行
-- ============================================================
local TeleportTab = TheKing.NewTab({ Title = "快捷传送", Icon = "map-pin" })
local selectedIsland = nil

-- UI 构建包进函数 (chunk 寄存器优化)
function buildTeleportTab()

if spawnFolder then
    -- 中文显示名 ↔ 英文锚点名 双向映射
    local isleLabels, labelToIsle = {}, {}
    for _, p in ipairs(spawnFolder:GetChildren()) do
        if p:IsA("BasePart") then
            local cn = trName(p.Name)
            table.insert(isleLabels, cn)
            labelToIsle[cn] = p.Name
        end
    end
    table.sort(isleLabels)

    local selectedIslandCN = nil
    TeleportTab:Dropdown({
        Title = "选择目标岛屿",
        Values = isleLabels,
        Value = isleLabels[1],
        Flag = "teleportIsle",
        Callback = function(sel)
            selectedIslandCN = sel
        end,
    })

    TeleportTab:Button({
        Title = "传送到选中岛屿",
        Icon = "map-pin",
        Callback = function()
            if fsmState == "战斗中" or fsmState == "等结算" then
                TheKing.Notify({ Content = "战斗/结算中无法传送", Icon = "alert-triangle" })
                return
            end
            local enName = selectedIslandCN and labelToIsle[selectedIslandCN]
            local anchor = enName and spawnFolder:FindFirstChild(enName)
            local ch = LocalPlayer.Character
            local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
            if anchor and hrp then
                hrp.CFrame = anchor.CFrame
                TheKing.Notify({ Content = "已传送到 " .. trName(enName), Icon = "check-circle" })
            else
                TheKing.Notify({ Content = "传送失败: 请在列表中重新选择目标", Icon = "alert-triangle" })
            end
        end,
    })
else
    TeleportTab:Paragraph({ Title = "传送不可用", Desc = "未找到 workspace.Spawnpoint, 游戏可能已更新" })
end

do
    -- ---- 天气渔场传送: 一键传送到当前天气可出稀有鱼的岛屿 ----
    -- 若当前天气无特殊鱼 (Clear/Rainy 或不在映射表), 仅通知不动作
    TeleportTab:Section({ Title = "天气渔场" })

    TeleportTab:Button({
        Title = "传送至天气渔场",
        Icon = "cloud-lightning",
        Callback = function()
            if fsmState == "战斗中" or fsmState == "等结算" then
                TheKing.Notify({ Content = "战斗/结算中无法传送", Icon = "alert-triangle" })
                return
            end
            local weather = workspace:GetAttribute("Weather")
            local targets = getWeatherTargets(weather)
            if not targets or not next(targets) then
                TheKing.Notify({
                    Title = "当前天气无稀有鱼",
                    Content = "[" .. trName(weather or "?") .. "] 没有对应的天气限定渔场, 无需传送",
                    Icon = "info",
                    Duration = 5,
                })
                return
            end
            -- 多岛屿天气优先传用户偏好岛 (雾蒙蒙两岛有鱼, 偏好椰子岛)
            local preferred = (weather == "Foggy") and "Coconut Isle" or nil
            local isleEn = (preferred and targets[preferred]) and preferred or nil
            if not isleEn then
                for k in pairs(targets) do isleEn = k break end
            end
            local anchor = isleEn and spawnFolder and spawnFolder:FindFirstChild(isleEn)
            local ch = LocalPlayer.Character
            local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
            if anchor and hrp then
                hrp.CFrame = anchor.CFrame
                local fishNames = {}
                for _, f in ipairs(targets[isleEn]) do fishNames[#fishNames + 1] = trName(f) end
                TheKing.Notify({
                    Title = "已传送至天气渔场 [" .. trName(weather) .. "]",
                    Content = trName(isleEn) .. " · 可钓: " .. table.concat(fishNames, " / "),
                    Icon = "check-circle",
                    Duration = 8,
                })
            else
                TheKing.Notify({ Content = "传送失败: 未找到目标岛屿锚点", Icon = "alert-triangle" })
            end
        end,
    })
end

do
    -- ---- 功能 NPC 传送: 扫 workspace.NPC; 多岛同功能合并为一条, 传送取最近 ----
    local npcRoot = workspace:FindFirstChild("NPC")

    if npcRoot then

    -- 多岛同功能 Folder → 列表只显示一条中文名, 传送时按距玩家最近选
    local NEAREST_FOLDER_LABEL = {
        BuyFishingRod = "表弟 · 竿店",
        BuyBait = "八长 · 饵店",
        SpawnBoat = "楚欣 · 开船",
        SellFish = "娜娜 · 卖鱼",
        SetSpawn = "表哥 · 设出生点",
    }

    local npcByLabel = {}   -- 中文显示名 -> { candidates = {{model, hrp}, ...} }
    local labels = {}
    local seenNames = {}    -- 非合并类: 按模型名去重

    local function addNpc(label, model, hrp, mergeNearest)
        if mergeNearest then
            local bucket = npcByLabel[label]
            if not bucket then
                bucket = { candidates = {} }
                npcByLabel[label] = bucket
                table.insert(labels, label)
            end
            table.insert(bucket.candidates, { model = model, hrp = hrp })
            return
        end
        if seenNames[model.Name] or npcByLabel[label] then
            return
        end
        seenNames[model.Name] = true
        npcByLabel[label] = { candidates = { { model = model, hrp = hrp } } }
        table.insert(labels, label)
    end

    local function collect(folder)
        local forcedLabel = NEAREST_FOLDER_LABEL[folder.Name]
        local mergeNearest = forcedLabel ~= nil
        for _, c in ipairs(folder:GetChildren()) do
            if c:IsA("Model") then
                local hrp = c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Head")
                if hrp then
                    local label = forcedLabel or trName(c.Name)
                    addNpc(label, c, hrp, mergeNearest)
                end
            elseif c:IsA("Folder") then
                collect(c)
            end
        end
    end
    collect(npcRoot)
    -- 扩展: Info.Character 定义的全部角色名全图深度查找
    -- (小道士/大师兄等特殊 NPC 可能不在 NPC folder 下, 或限时出现在任意位置)
    if infoFolder then
        local chars = infoFolder:FindFirstChild("Character")
        if chars then
            for _, m in ipairs(chars:GetChildren()) do
                local label = trName(m.Name)
                -- 已由多岛合并 Folder 收录的功能 NPC 跳过 (如 Chu Xin)
                if not seenNames[m.Name] and not npcByLabel[label] then
                    local found = workspace:FindFirstChild(m.Name, true)
                    if found and found:IsA("Model") then
                        local hrp = found:FindFirstChild("HumanoidRootPart") or found:FindFirstChild("Head")
                        if hrp then
                            addNpc(label, found, hrp, false)
                        end
                    end
                end
            end
        end
    end

    -- 传送时从候选里取距玩家最近的有效 HRP (流式加载失效则跳过)
    local function pickNearestHrp(info)
        if not info or not info.candidates then
            return nil
        end
        local ch = LocalPlayer.Character
        local myHrp = ch and ch:FindFirstChild("HumanoidRootPart")
        if not myHrp then
            return nil
        end
        local origin = myHrp.Position
        local bestHrp, bestDist = nil, math.huge
        for _, cand in ipairs(info.candidates) do
            local part = cand.hrp
            if not part or not part.Parent then
                local m = cand.model
                part = m and (m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Head"))
                cand.hrp = part
            end
            if part and part.Parent then
                local d = (part.Position - origin).Magnitude
                if d < bestDist then
                    bestDist = d
                    bestHrp = part
                end
            end
        end
        return bestHrp
    end

    table.sort(labels)
    if #labels > 0 then
        TeleportTab:Section({ Title = "功能 NPC 传送" })
        local selectedNpc = nil

        TeleportTab:Dropdown({
            Title = "选择功能 NPC",
            Desc = "竿店/饵店/开船/卖鱼/设出生点只显示一条, 传送自动去最近",
            Values = labels,
            Value = labels[1],
            Flag = "npcTarget",
            Callback = function(sel)
                selectedNpc = sel
            end,
        })
        selectedNpc = labels[1] -- Dropdown Callback 仅主动选择时触发, 默认选中首项

        TeleportTab:Button({
            Title = "传送至游商",
            Icon = "store",
            Callback = function()
                local merchantName = workspace:GetAttribute("MerchantNPC")
                if not merchantName then
                    TheKing.Notify({ Content = "当前无游商在场", Icon = "info" })
                    return
                end
                if fsmState == "战斗中" or fsmState == "等结算" then
                    TheKing.Notify({ Content = "战斗/结算中无法传送", Icon = "alert-triangle" })
                    return
                end
                local mModel = npcRoot:FindFirstChild(merchantName, true)
                local mHrp = mModel and (mModel:FindFirstChild("HumanoidRootPart") or mModel:FindFirstChild("Head"))
                local ch = LocalPlayer.Character
                local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
                if mHrp and hrp then
                    local p = mHrp.Position
                    hrp.CFrame = CFrame.new(p + Vector3.new(0, 2, 4), p)
                    TheKing.Notify({ Content = "已传送到游商 " .. merchantName .. " · 商品: " .. tostring(workspace:GetAttribute("MerchantItem") or "?"), Icon = "check-circle" })
                else
                    TheKing.Notify({ Content = "游商模型缺失", Icon = "alert-triangle" })
                end
            end,
        })

        TeleportTab:Button({
            Title = "传送到该 NPC 身旁",
            Icon = "map-pin",
            Callback = function()
                if fsmState == "战斗中" or fsmState == "等结算" then
                    TheKing.Notify({ Content = "战斗/结算中无法传送", Icon = "alert-triangle" })
                    return
                end
                local info = selectedNpc and npcByLabel[selectedNpc]
                local ch = LocalPlayer.Character
                local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
                local targetHrp = pickNearestHrp(info)
                if targetHrp and hrp then
                    -- 落在 NPC 正前方 4 格、抬高 2 格防卡模型, 面向 NPC 保证交互距离
                    local p = targetHrp.Position
                    hrp.CFrame = CFrame.new(p + Vector3.new(0, 2, 4), p)
                    TheKing.Notify({ Content = "已传送到 " .. tostring(selectedNpc) .. " (最近)", Icon = "check-circle" })
                else
                    TheKing.Notify({ Content = "传送失败: 目标 NPC 缺失", Icon = "alert-triangle" })
                end
            end,
        })

        -- 游商上线提醒: MerchantNPC attribute 变化即弹大通知 (含商品)
        TheKing.AddConnection(workspace:GetAttributeChangedSignal("MerchantNPC"):Connect(function()
            task.delay(1.5, function() -- 等服务器同步 MerchantItem
                local mn = workspace:GetAttribute("MerchantNPC")
                local mi = workspace:GetAttribute("MerchantItem")
                if mn then
                    TheKing.Notify({
                        Title = "🏪 游商出现!",
                        Content = trName(mn) .. " 正在出售: " .. tostring(mi or "?"),
                        Icon = "store",
                        Duration = 15,
                    })
                end
            end)
        end))

    end
    end

    -- ---- 传送到服务器玩家: 扫 Players 在线玩家 (除自己), 选人后落到其身旁 ----
    local playerRoot = game:GetService("Players")
    local playerListDD -- Dropdown 句柄 (刷新时即时更新)
    local function refreshPlayerList()
        local labels, labelToPlayer = {}, {}
        for _, plr in ipairs(playerRoot:GetPlayers()) do
            if plr ~= LocalPlayer then
                local label = plr.DisplayName .. " (" .. plr.Name .. ")"
                labels[#labels + 1] = label
                labelToPlayer[label] = plr
            end
        end
        table.sort(labels)
        return labels, labelToPlayer
    end

    TeleportTab:Section({ Title = "传送至服务器玩家" })

    local playerLabels, playerByLabel = refreshPlayerList()
    local selectedPlayer = nil

    playerListDD = TeleportTab:Dropdown({
        Title = "选择目标玩家",
        Values = playerLabels,
        Value = playerLabels[1],
        Flag = "teleportPlayer",
        Callback = function(sel)
            selectedPlayer = sel
        end,
    })

    TeleportTab:Button({
        Title = "刷新玩家列表",
        Icon = "refresh-cw",
        Callback = function()
            playerLabels, playerByLabel = refreshPlayerList()
            if playerListDD and type(playerListDD.Refresh) == "function" then
                pcall(function() playerListDD:Refresh(playerLabels) end)
            end
            TheKing.Notify({ Content = "已刷新 (" .. #playerLabels .. " 人在线)", Icon = "refresh-cw" })
        end,
    })

    TeleportTab:Button({
        Title = "传送到该玩家身旁",
        Icon = "map-pin",
        Callback = function()
            if fsmState == "战斗中" or fsmState == "等结算" then
                TheKing.Notify({ Content = "战斗/结算中无法传送", Icon = "alert-triangle" })
                return
            end
            local plr = selectedPlayer and playerByLabel[selectedPlayer]
            local ch = LocalPlayer.Character
            local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
            local pCh = plr and plr.Character
            local pHrp = pCh and (pCh:FindFirstChild("HumanoidRootPart") or pCh:FindFirstChild("Head"))
            if hrp and pHrp then
                local p = pHrp.Position
                hrp.CFrame = CFrame.new(p + Vector3.new(0, 2, 4), p)
                TheKing.Notify({ Content = "已传送到 " .. tostring(selectedPlayer), Icon = "check-circle" })
            else
                TheKing.Notify({ Content = "传送失败: 目标玩家不在线或角色未加载", Icon = "alert-triangle" })
            end
        end,
    })
end

-- ============================================================
-- 记录点位: 自定义标记点 + 持久化 (readfile/writefile JSON, 标准注入器 API)
-- 存到 windui 同目录下 heavyfishing_points.json, 重注入自动恢复
-- ============================================================
do
    local POINTS_FILE = "heavyfishing_points.json"
    local points = {}      -- { name = Vector3(x,y,z) }
    local pointOrder = {}  -- 保持插入顺序 (名字列表)
    local selectedPoint = nil
    local pointDropdown = nil -- Dropdown 元素句柄 (记录/删除后刷新列表)

    local function savePoints()
        pcall(function()
            if type(writefile) ~= "function" then return end -- 注入器无文件系统 -> 静默跳过
            local HttpService = game:GetService("HttpService")
            local data = {}
            for _, name in ipairs(pointOrder) do
                local v = points[name]
                data[#data + 1] = { n = name, x = v.X, y = v.Y, z = v.Z }
            end
            writefile(POINTS_FILE, HttpService:JSONEncode(data))
        end)
    end

    local function loadPoints()
        pcall(function()
            if type(readfile) ~= "function" then return end
            if type(isfile) ~= "function" then return end
            if not isfile(POINTS_FILE) then return end
            local HttpService = game:GetService("HttpService")
            local data = HttpService:JSONDecode(readfile(POINTS_FILE))
            if type(data) ~= "table" then return end
            points, pointOrder = {}, {}
            for _, entry in ipairs(data) do
                if type(entry) == "table" and entry.n and entry.x then
                    points[entry.n] = Vector3.new(entry.x, entry.y or 0, entry.z or 0)
                    pointOrder[#pointOrder + 1] = entry.n
                end
            end
        end)
    end

    -- 刷新点位 Dropdown 列表 (记录/删除后调用; WindUI Dropdown:Refresh 重建选项)
    local function refreshPointDropdown()
        if pointDropdown and type(pointDropdown.Refresh) == "function" then
            pcall(function() pointDropdown:Refresh(pointOrder) end)
        end
        -- 选中项失效时回退到第一个
        if selectedPoint and not points[selectedPoint] then
            selectedPoint = pointOrder[1]
        end
    end

    loadPoints()

    TeleportTab:Section({ Title = "记录点位" })

    -- 记录当前位置
    TeleportTab:Button({
        Title = "记录当前位置",
        Icon = "bookmark",
        Callback = function()
            local ch = LocalPlayer.Character
            local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
            if not hrp then
                TheKing.Notify({ Content = "角色未就绪, 无法记录", Icon = "alert-triangle" })
                return
            end
            -- 自动命名: 点位 N (跳过的编号不复用)
            local n = 1
            while points["点位 " .. n] do n = n + 1 end
            local name = "点位 " .. n
            points[name] = hrp.Position
            pointOrder[#pointOrder + 1] = name
            selectedPoint = name
            savePoints()
            refreshPointDropdown()
            TheKing.Notify({ Content = "已记录点位: " .. name .. " (" .. string.format("%.0f,%.0f,%.0f", hrp.Position.X, hrp.Position.Y, hrp.Position.Z) .. ")", Icon = "check-circle" })
        end,
    })

    pointDropdown = TeleportTab:Dropdown({
        Title = "选择点位",
        Values = pointOrder,
        Value = pointOrder[1],
        Flag = "teleportPointSel",
        Callback = function(sel)
            selectedPoint = sel
        end,
    })

    TeleportTab:Button({
        Title = "传送到该点位",
        Icon = "map-pin",
        Callback = function()
            if fsmState == "战斗中" or fsmState == "等结算" then
                TheKing.Notify({ Content = "战斗/结算中无法传送", Icon = "alert-triangle" })
                return
            end
            local ch = LocalPlayer.Character
            local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
            local pos = selectedPoint and points[selectedPoint]
            if hrp and pos then
                hrp.CFrame = CFrame.new(pos + Vector3.new(0, 2, 0))
                TheKing.Notify({ Content = "已传送到 " .. selectedPoint, Icon = "check-circle" })
            else
                TheKing.Notify({ Content = "传送失败: 未选择点位", Icon = "alert-triangle" })
            end
        end,
    })

    TeleportTab:Button({
        Title = "删除选中点位",
        Icon = "trash-2",
        Color = Color3.fromRGB(255, 120, 120),
        Callback = function()
            if not selectedPoint or not points[selectedPoint] then
                TheKing.Notify({ Content = "请先选择要删除的点位", Icon = "alert-triangle" })
                return
            end
            local removed = selectedPoint
            points[removed] = nil
            for i, name in ipairs(pointOrder) do
                if name == removed then table.remove(pointOrder, i) break end
            end
            selectedPoint = pointOrder[1]
            savePoints()
            refreshPointDropdown()
            TheKing.Notify({ Content = "已删除点位: " .. removed, Icon = "trash-2" })
        end,
    })
end

end

buildTeleportTab()

-- ============================================================
-- 背包管理 Tab: 自动出售 (迁移) + 智能锁定 (任务需求/重量挑战/价值)
-- ============================================================
local HotkeyTab = TheKing.NewTab({ Title = "快捷键", Icon = "keyboard" })

do
    local HOTKEY_ACTIONS = {
        { id = "hkFish", name = "切换 自动钓鱼", flag = "hk_fish", elsKey = "autoFish", kind = "toggle",
          get = function() return autoFishOn end, set = function(v) setAutoFish(v) end },
        { id = "hkSkill", name = "切换 自动技能", flag = "hk_skill", elsKey = "skillMode", kind = "dropdown-cycle",
          values = { "不释放", "智能择优", "顺序释放" },
          get = function() return skillMode end, set = function(v) skillMode = v; autoSkillOn = (v ~= "不释放"); syncSkillLoop() end },
        { id = "hkSell", name = "切换 自动出售", flag = "hk_sell", elsKey = "autoSell", kind = "toggle",
          get = function() return autoSellOn end, set = function(v) setAutoSell(v) end },
        { id = "hkChg", name = "切换 自动蓄力", flag = "hk_charge", elsKey = "autoCharge", kind = "toggle",
          get = function() return autoChargeOn end,
          set = function(v)
              autoChargeOn = v
              notifyToggle("自动蓄力", autoChargeOn, "timer")
          end },
        { id = "hkLock", name = "切换 智能锁定", flag = "hk_lock", elsKey = "lockOn", kind = "toggle",
          get = function() return lockOn end,
          set = function(v)
              lockOn = v
              notifyToggle("智能锁定", lockOn, "lock")
          end },
        { id = "hkSellAll", name = "立即出售未锁定鱼", kind = "action",
          exec = function() doSellAll("快捷键") end },
        { id = "hkScan", name = "扫描锁定现有背包", kind = "action",
          exec = function()
              task.spawn(function()
                  local n, names = scanAndLock()
                  TheKing.Notify({ Title = "智能锁定", Content = "新锁定 " .. n .. " 条鱼" .. fmtLockList(names), Icon = "lock" })
              end)
          end },
    }

    HotkeyTab:Paragraph({
        Title = "键位说明",
        Desc = "点「绑定按键」后按下新键；「清空」解除绑定。未绑定也能在 Tab 里手动开关",
    })

    for _, act in ipairs(HOTKEY_ACTIONS) do
        hotkeyBindings[act.id] = { action = act }

        HotkeyTab:Section({ Title = act.name })

        HotkeyTab:Button({
            Title = "✕ 清空此快捷键",
            Icon = "x",
            Callback = function()
                local b = hotkeyBindings[act.id]
                b.key = nil
                -- 同步 Keybind 元素显示回 None (内部值+UI 文本一并更新)
                if b.kbElement then
                    pcall(function() b.kbElement:Set("None") end)
                end
                TheKing.Notify({ Content = act.name .. " 键位已清空", Icon = "info", Duration = 1 })
            end,
        })

        hotkeyBindings[act.id].kbElement = HotkeyTab:Keybind({
            Title = "绑定按键 (点击后按新键)",
            Value = "None",
            Flag = act.flag,
            OnChanged = function(key)
                -- Gen2: 改绑走 OnChanged; 按下已绑定键不走这里 (由 InputBegan 分发)
                local keyName = (typeof(key) == "EnumItem") and key.Name or tostring(key)
                if keyName == "Escape" or keyName == "Unknown" or keyName == "None" then return end
                -- 冲突检测: 同一键不可绑多个功能
                for _, other in ipairs(HOTKEY_ACTIONS) do
                    if other.id ~= act.id then
                        local ob = hotkeyBindings[other.id]
                        if ob and ob.key then
                            if tostring(ob.key) == keyName then
                                TheKing.Notify({
                                    Title = "快捷键冲突",
                                    Content = keyName .. " 已被「" .. other.name .. "」占用, 已忽略",
                                    Icon = "alert-triangle",
                                })
                                return
                            end
                        end
                    end
                end
                hotkeyBindings[act.id].key = keyName
                TheKing.Notify({
                    Content = act.name .. " 已绑定 [" .. keyName .. "]",
                    Icon = "keyboard",
                    Duration = 1,
                })
            end,
        })
    end

    -- 全局按键分发: 匹配已绑定键 → 执行对应功能
    -- 注意: b.key 存的是键名字符串 (WindUI Callback 传 Name), 与 input.KeyCode.Name 比较
    TheKing.AddConnection(UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        local keyName = input.KeyCode.Name
        if keyName == "Escape" or keyName == "Unknown" then return end
        for _, act in ipairs(HOTKEY_ACTIONS) do
            local b = hotkeyBindings[act.id]
            if b and b.key and b.key == keyName then
                pcall(function()
                    if act.kind == "toggle" then
                        -- 只经 Toggle 元素 :Set 单链路: UI 显示 + 内部状态 + 通知一步到位
                        -- (避免 act.set 与 el:Set 双链路各弹一条通知)
                        local el = toggleEls[act.elsKey]
                        local newState = not act.get()
                        if el then
                            el:Set(newState)
                        else
                            act.set(newState) -- 无元素引用时降级直调
                        end
                    elseif act.kind == "dropdown-cycle" then
                        -- 下拉循环切换: 在 values 间轮转, 经 act.set 单链路 (UI+内部状态+通知)
                        local vals = act.values
                        if vals and #vals > 0 then
                            local cur = act.get()
                            local idx = 1
                            for i, v in ipairs(vals) do
                                if v == cur then idx = i; break end
                            end
                            local nextVal = vals[(idx % #vals) + 1]
                            act.set(nextVal)
                            TheKing.Notify({ Content = act.name .. " → " .. tostring(nextVal), Icon = "zap", Duration = 1 })
                        end
                    else
                        act.exec()
                    end
                end)
                break -- 单次输入只触发一个功能
            end
        end
    end))
end

-- ============================================================
-- 玩家 Tab (v0.30.2)
-- 排版: 兑换码 → 虚假信息(编号隐藏/匿名者/称号) → 玩家(奔跑/加速/速度)
-- 假称号: 未拥有也本地完整伪装 (Title 文本 + Image + Color), 保活防服务器回写覆盖
-- ============================================================
local PlayerTab = TheKing.NewTab({ Title = "玩家", Icon = "user" })

-- ---------- 兑换码 ----------
do
    local KNOWN_CODES = {
        "49KLikes", "48KLikes", "47KLikes", "46KLikes",
        "33MVisits", "32MVisits", "31MVisits", "30MVisits",
        "13KActives", "HWF", "AXO", "Taiji",
    }
    local redeemBusy = false
    local statusPara = nil

    local function getCodeFolder()
        local folder = nil
        pcall(function()
            local data = ReplicatedStorage:FindFirstChild("Data")
            local ud = data and data:FindFirstChild(tostring(LocalPlayer.UserId))
            folder = ud and ud:FindFirstChild("Code")
        end)
        return folder
    end

    local function getRedeemEv()
        local ev = nil
        pcall(function()
            local events = ReplicatedStorage:FindFirstChild("Events")
            ev = events and events:FindFirstChild("RedeemCode")
        end)
        return ev
    end

    local function collectCodes()
        local seen = {}
        local list = {}
        local folder = getCodeFolder()
        if folder then
            for _, c in ipairs(folder:GetChildren()) do
                if c:IsA("BoolValue") then
                    seen[c.Name] = true
                    table.insert(list, { name = c.Name, redeemed = c.Value == true })
                end
            end
        end
        for _, name in ipairs(KNOWN_CODES) do
            if not seen[name] then
                table.insert(list, { name = name, redeemed = false })
                seen[name] = true
            end
        end
        table.sort(list, function(a, b)
            return a.name < b.name
        end)
        local pending = 0
        for _, e in ipairs(list) do
            if not e.redeemed then
                pending = pending + 1
            end
        end
        return list, pending, #list
    end

    local function refreshStatus()
        local _, pending, total = collectCodes()
        local done = total - pending
        local desc = string.format("已兑 %d / 共 %d · 待兑 %d", done, total, pending)
        if statusPara then
            TheKing.UpdateStatus(statusPara, "兑换码状态", desc)
        end
        return pending, total
    end

    local function redeemAll()
        if redeemBusy then
            TheKing.Notify({ Content = "正在兑换中, 请稍候", Icon = "loader", Duration = 2 })
            return
        end
        local ev = getRedeemEv()
        if not ev then
            TheKing.Notify({ Content = "未找到兑换接口, 游戏可能已更新", Icon = "alert-triangle", Duration = 5 })
            return
        end
        local list, pending = collectCodes()
        if pending <= 0 then
            TheKing.Notify({ Content = "没有待兑换的码", Icon = "check-circle", Duration = 3 })
            refreshStatus()
            return
        end
        redeemBusy = true
        TheKing.Notify({ Title = "兑换码", Content = "开始兑换 " .. tostring(pending) .. " 个待兑码", Icon = "gift", Duration = 3 })
        task.spawn(function()
            local okN, failN = 0, 0
            for _, e in ipairs(list) do
                if not e.redeemed then
                    pcall(function()
                        ev:FireServer(e.name)
                    end)
                    task.wait(0.45 + math.random() * 0.35)
                    local folder = getCodeFolder()
                    local bv = folder and folder:FindFirstChild(e.name)
                    if bv and bv:IsA("BoolValue") and bv.Value == true then
                        okN = okN + 1
                    else
                        failN = failN + 1
                    end
                    refreshStatus()
                end
            end
            redeemBusy = false
            TheKing.Notify({
                Title = "兑换完成",
                Content = string.format("成功 %d · 未生效 %d (等级不够/已过期)", okN, failN),
                Icon = "gift",
                Duration = 5,
            })
            refreshStatus()
        end)
    end

    PlayerTab:Section({ Title = "兑换码" })
    statusPara = PlayerTab:Paragraph({
        Title = "兑换码状态",
        Desc = "扫描中...",
    })
    refreshStatus()

    PlayerTab:Button({
        Title = "刷新状态",
        Icon = "refresh-cw",
        Callback = function()
            local pending, total = refreshStatus()
            TheKing.Notify({ Content = string.format("待兑 %d / 共 %d", pending, total), Icon = "check-circle", Duration = 3 })
        end,
    })

    PlayerTab:Button({
        Title = "一键兑换全部",
        Icon = "gift",
        Callback = redeemAll,
    })
end

-- ---------- 虚假信息: 编号隐藏 / 匿名者 / 假称号 ----------
local function buildFakeInfo()
    local uidLabel = nil
    local anonOn = false
    local anonNameLabel = nil
    local anonOriginalName = ""
    local ANON_COLOR = Color3.fromRGB(255, 45, 45)

    local function getUidLabel()
        if uidLabel and uidLabel.Parent then return uidLabel end
        uidLabel = nil
        pcall(function()
            local mg = LocalPlayer.PlayerGui and LocalPlayer.PlayerGui:FindFirstChild("MainGui")
            local lbl = mg and mg:FindFirstChild("TextLabel")
            if lbl and lbl:IsA("TextLabel") then uidLabel = lbl end
        end)
        return uidLabel
    end

    local function setUidHidden(hidden)
        local lbl = getUidLabel()
        if lbl then
            pcall(function() lbl.Visible = not hidden end)
        end
    end

    local function getAnonLabel()
        if anonNameLabel and anonNameLabel.Parent then return anonNameLabel end
        anonNameLabel = nil
        local ch = LocalPlayer.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        local et = hrp and hrp:FindFirstChild("EquippedTitle")
        local pn = et and et:FindFirstChild("PlayerName")
        if pn and pn:IsA("TextLabel") then
            anonNameLabel = pn
            anonOriginalName = pn.Text
        end
        return anonNameLabel
    end

    local function setPlayerNameGradientEnabled(lbl, enabled)
        if not lbl then return end
        local g = lbl:FindFirstChild("Color")
        if not (g and g:IsA("UIGradient")) then
            g = lbl:FindFirstChildOfClass("UIGradient")
        end
        if g and g:IsA("UIGradient") then
            pcall(function() g.Enabled = enabled end)
        end
    end

    local function applyAnon(on)
        local lbl = getAnonLabel()
        if on then
            if lbl then
                pcall(function()
                    lbl.Text = "theKing User"
                    lbl.TextColor3 = ANON_COLOR
                    lbl.TextTransparency = 0
                    -- 关掉渐变, 否则 UIGradient 会盖住固定红色
                    setPlayerNameGradientEnabled(lbl, false)
                end)
            end
        else
            if lbl then
                pcall(function()
                    lbl.Text = anonOriginalName
                    lbl.TextColor3 = Color3.new(0.972549, 0.972549, 0.972549)
                    setPlayerNameGradientEnabled(lbl, true)
                end)
            end
        end
    end

    -- 假称号 (独立函数, 避免 buildFakeInfo 超过 Luau 200 局部寄存器)
    local T = (function()
    local TITLE_CN = {
        ["Default"] = "默认",
        ["Novice Angler"] = "新手钓手",
        ["Expert Angler"] = "专家钓手",
        ["Master Angler"] = "大师钓手",
        ["Grandmaster Angler"] = "宗师钓手",
        ["VIP"] = "VIP",
        ["OG"] = "老玩家",
        ["Sage Angler"] = "贤者钓手",
        ["Content Creator"] = "内容创作者",
    }
    local function titleCN(name)
        return TITLE_CN[name] or name
    end
    local titleChoices = {}
    local titleNames = {}
    local selectedTitle = nil
    local equipTitleEv = nil
    local forcedTitle = nil -- 本地伪装中的称号名 (需保活)

    local function getEquipTitleEv()
        if equipTitleEv then return equipTitleEv end
        pcall(function()
            equipTitleEv = Events and Events:FindFirstChild("EquipTitle")
        end)
        return equipTitleEv
    end

    local function getTitleCfg(name)
        local cfgFolder = infoFolder and infoFolder:FindFirstChild("Player_Title")
        local mod = cfgFolder and cfgFolder:FindFirstChild(name)
        if mod and mod:IsA("ModuleScript") then
            local ok, cfg = pcall(require, mod)
            if ok and type(cfg) == "table" then
                return cfg
            end
        end
        return nil
    end

    local function isTitleOwned(name)
        local pt = playerData and playerData:FindFirstChild("PlayerTitle")
        local f = pt and pt:FindFirstChild(name)
        local owned = f and f:FindFirstChild("Owned")
        return owned and owned:IsA("BoolValue") and owned.Value == true
    end

    -- 头顶视觉样式 (服务器 EquipTitle 实测抓取; OG/CC 按同规则推算)
    -- 关键点: 颜色走 UIGradient 而非 TextColor3; PlayerName 同步同款渐变; VIP 有 Circle+半透底
    local TITLE_TEXT_WHITE = Color3.fromRGB(248, 248, 248)
    local FLARE_IMG = "rbxassetid://138111953688137"
    local CIRCLE_IMG = "rbxassetid://10637682258"
    local TITLE_STYLE = {
        ["Default"] = { c1 = Color3.fromRGB(200, 200, 200), c2 = Color3.new(1, 1, 1), rot = 90, flare = false, circle = false, imgBgT = 0 },
        ["Novice Angler"] = { c1 = Color3.new(1, 0.616, 0.361), c2 = Color3.new(1, 0.784, 0.592), rot = 90, flare = false, circle = false, imgBgT = 0 },
        ["Expert Angler"] = { c1 = Color3.new(0.459, 0.459, 0.459), c2 = Color3.new(1, 1, 1), rot = 90, flare = false, circle = false, imgBgT = 0 },
        ["Master Angler"] = { c1 = Color3.new(1, 0.553, 0.188), c2 = Color3.new(1, 0.925, 0.129), rot = -90, flare = true, circle = false, imgBgT = 0 },
        ["Grandmaster Angler"] = { c1 = Color3.new(1, 0.137, 0.325), c2 = Color3.new(0.733, 0.306, 1), rot = -90, flare = true, circle = false, imgBgT = 0 },
        ["VIP"] = { c1 = Color3.new(1, 0.584, 0), c2 = Color3.new(1, 0.910, 0.227), rot = 90, flare = true, circle = true, imgBgT = 0.25 },
        -- OG/CC 服务器拒绝未真拥有时的 EquipTitle, 渐变按 cfg.Color + VIP 类特效推算
        ["OG"] = { c1 = Color3.new(0.20, 0.85, 0.65), c2 = Color3.new(0.45, 1, 0.90), rot = 90, flare = true, circle = false, imgBgT = 0.25 },
        ["Sage Angler"] = { c1 = Color3.new(1, 0.612, 0.294), c2 = Color3.new(0.431, 0.773, 1), rot = -90, flare = true, circle = false, imgBgT = 0 },
        ["Content Creator"] = { c1 = Color3.new(1, 0.12, 0.12), c2 = Color3.new(1, 0.35, 0.35), rot = 90, flare = true, circle = false, imgBgT = 0.25 },
    }

    local function styleFromCfg(name, cfg)
        local s = TITLE_STYLE[name]
        if s then return s end
        -- 未知称号: 用 cfg.Color 推一条简易渐变
        local c = (cfg and typeof(cfg.Color) == "Color3") and cfg.Color or Color3.new(1, 1, 1)
        return {
            c1 = Color3.new(c.R * 0.85, c.G * 0.7, c.B * 0.55),
            c2 = Color3.new(math.min(1, c.R * 0.35 + 0.65), math.min(1, c.G * 0.35 + 0.65), math.min(1, c.B * 0.35 + 0.65)),
            rot = 90,
            flare = false,
            circle = false,
            imgBgT = 0,
        }
    end

    local function setGradient(inst, c1, c2, rot)
        if not inst then return end
        local g = inst:FindFirstChild("Color")
        if not (g and g:IsA("UIGradient")) then
            g = inst:FindFirstChildOfClass("UIGradient")
        end
        if not (g and g:IsA("UIGradient")) then
            g = Instance.new("UIGradient")
            g.Name = "Color"
            g.Parent = inst
        end
        pcall(function()
            g.Enabled = true
            g.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, c1),
                ColorSequenceKeypoint.new(1, c2),
            })
            g.Rotation = rot or 90
        end)
    end

    local function ensureFxChild(parent, childName, imageId, zIndex)
        local node = parent:FindFirstChild(childName)
        if not node then
            node = Instance.new("ImageLabel")
            node.Name = childName
            node.BackgroundTransparency = 1
            node.AnchorPoint = Vector2.new(0.5, 0.5)
            node.Position = UDim2.fromScale(0.5, 0.5)
            node.Size = UDim2.fromScale(1.5, 1.5)
            node.ScaleType = Enum.ScaleType.Crop
            node.ImageColor3 = Color3.new(1, 1, 1)
            node.ZIndex = zIndex or 100
            node.Parent = parent
            local ar = Instance.new("UIAspectRatioConstraint")
            ar.AspectRatio = 1
            ar.Parent = node
            local g = Instance.new("UIGradient")
            g.Name = "Color"
            g.Parent = node
        end
        if node:IsA("ImageLabel") then
            node.Image = imageId
            node.Visible = true
            node.ImageTransparency = 0
        end
        return node
    end

    local function applyTitleFx(imgRoot, style)
        if not imgRoot then return end
        -- 半透底 (VIP 0.25, 普通 0)
        pcall(function()
            imgRoot.BackgroundTransparency = style.imgBgT or 0
        end)
        -- Flare
        if style.flare then
            local flare = ensureFxChild(imgRoot, "Flare1", FLARE_IMG, 101)
            setGradient(flare, style.c1, style.c2, style.rot)
        else
            local flare = imgRoot:FindFirstChild("Flare1")
            if flare then flare:Destroy() end
        end
        -- Circle (仅 VIP 类)
        if style.circle then
            local circle = ensureFxChild(imgRoot, "Circle", CIRCLE_IMG, 99)
            setGradient(circle, style.c1, style.c2, style.rot)
        else
            local circle = imgRoot:FindFirstChild("Circle")
            if circle then circle:Destroy() end
        end
    end

    -- 完整本地伪装: 对齐服务器 EquipTitle 写入的 Billboard 视觉
    local function forceLocalTitle(name)
        if type(name) ~= "string" or #name == 0 then return end
        local cfg = getTitleCfg(name)
        local col = (cfg and typeof(cfg.Color) == "Color3") and cfg.Color or Color3.fromRGB(255, 255, 255)
        local imgId = (cfg and type(cfg.Image) == "string") and cfg.Image or ""
        local displayName = (cfg and type(cfg.Name) == "string" and #cfg.Name > 0) and cfg.Name or name
        local style = styleFromCfg(name, cfg)

        -- 1) Data 标记: 只改 Equip (聊天前缀读这个); 禁止伪造 Owned — 否则会误走 FireServer 被服务器拒
        local pt = playerData and playerData:FindFirstChild("PlayerTitle")
        if pt then
            for _, f in ipairs(pt:GetChildren()) do
                local eq = f:FindFirstChild("Equip")
                if eq and eq:IsA("BoolValue") then
                    eq.Value = (f.Name == name)
                end
            end
        end

        -- 2) 头顶 BillboardGui
        pcall(function()
            local ch = LocalPlayer.Character
            local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
            local et = hrp and hrp:FindFirstChild("EquippedTitle")
            if not et then return end
            local frame = et:FindFirstChild("Frame")
            local titleLbl = frame and frame:FindFirstChild("Title")
            local imgRoot = frame and frame:FindFirstChild("Image")
            local img = imgRoot and (imgRoot:FindFirstChild("Image") or imgRoot:FindFirstChildOfClass("ImageLabel"))
            local playerNameLbl = et:FindFirstChild("PlayerName")

            if titleLbl and titleLbl:IsA("TextLabel") then
                titleLbl.Text = name
                -- 关键: 字色保持近白, 真正颜色由 UIGradient 决定 (服务器同款)
                titleLbl.TextColor3 = TITLE_TEXT_WHITE
                titleLbl.TextTransparency = 0
                titleLbl.Visible = true
                titleLbl.TextScaled = true
                titleLbl.AutomaticSize = Enum.AutomaticSize.X
                titleLbl.BackgroundTransparency = 0.25
                -- 服务器短名(VIP/OG) Size.X≈0.9, 长名≈2.2; AutomaticSize 缩短时常不回弹, 手动对齐
                local nameLen = (utf8 and utf8.len(name)) or #name
                local sx = (nameLen <= 4) and 0.9 or 2.2
                titleLbl.Size = UDim2.fromScale(sx, 0.7)
                setGradient(titleLbl, style.c1, style.c2, style.rot)
                -- Light 描边渐变同步
                local light = titleLbl:FindFirstChild("Light")
                if light then setGradient(light, style.c1, style.c2, style.rot) end
            end

            if img and img:IsA("ImageLabel") then
                if #imgId > 0 then img.Image = imgId end
                img.ImageColor3 = Color3.new(1, 1, 1)
                img.ImageTransparency = 0
                img.Visible = true
                setGradient(img, style.c1, style.c2, style.rot)
            end
            if imgRoot and imgRoot:IsA("GuiObject") then
                imgRoot.Visible = true
                setGradient(imgRoot, style.c1, style.c2, style.rot)
                local light = imgRoot:FindFirstChild("Light")
                if light then setGradient(light, style.c1, style.c2, style.rot) end
                applyTitleFx(imgRoot, style)
            end
            if frame and frame:IsA("GuiObject") then
                frame.Visible = true
            end

            -- 未开匿名者: 角色名同步同款渐变 (服务器换称号时 PlayerName.Color 会一起变)
            if playerNameLbl and playerNameLbl:IsA("TextLabel") and not anonOn then
                playerNameLbl.TextColor3 = TITLE_TEXT_WHITE
                setGradient(playerNameLbl, style.c1, style.c2, style.rot)
            end
        end)

        -- 3) 设置页预览 (游戏 updateEquippedDisplay 同款)
        pcall(function()
            local mg = LocalPlayer.PlayerGui and LocalPlayer.PlayerGui:FindFirstChild("MainGui")
            local menu = mg and mg:FindFirstChild("Menu")
            local settings = menu and menu:FindFirstChild("Settings")
            local smenu = settings and settings:FindFirstChild("Menu")
            local gameplay = smenu and smenu:FindFirstChild("Gameplay")
            local panel = gameplay and gameplay:FindFirstChild("Player_Title")
            if not panel then return end
            local t = panel:FindFirstChild("Title")
            local icon = panel:FindFirstChild("Icon")
            if t and t:IsA("TextLabel") then
                t.Text = displayName
                t.TextColor3 = col
            end
            if icon and icon:IsA("ImageLabel") then
                if #imgId > 0 then icon.Image = imgId end
                icon.ImageColor3 = col
            end
        end)
    end

    local function applyTitle()
        if not selectedTitle and #titleNames > 0 then
            selectedTitle = titleChoices[titleNames[1]]
        end
        if not selectedTitle then
            TheKing.Notify({ Content = "请先选择称号", Icon = "alert-triangle", Duration = 3 })
            return
        end
        local owned = isTitleOwned(selectedTitle)
        -- 立刻完整刷显示 (不等服务器)
        forcedTitle = selectedTitle
        forceLocalTitle(selectedTitle)
        TheKing.StartLoop("fakeTitleKeep", 2, function()
            if forcedTitle then forceLocalTitle(forcedTitle) end
            if anonOn then applyAnon(true) end -- 保活后盖住名字, 维持红色匿名
        end)

        local ev = getEquipTitleEv()
        if owned and ev then
            pcall(function() ev:FireServer(selectedTitle) end)
            task.delay(1.2, function()
                forceLocalTitle(selectedTitle)
                TheKing.Notify({ Title = "称号", Content = "已应用: " .. titleCN(selectedTitle), Icon = "crown", Duration = 3 })
            end)
        else
            TheKing.Notify({
                Title = "假称号",
                Content = "本地完整伪装: " .. titleCN(selectedTitle) .. (owned and "" or " (未拥有)"),
                Icon = "crown",
                Duration = 4,
            })
        end
    end

    local function buildTitleList()
        titleChoices, titleNames = {}, {}
        local list = {}
        local cfg = infoFolder and infoFolder:FindFirstChild("Player_Title")
        if cfg then
            for _, m in ipairs(cfg:GetChildren()) do
                table.insert(list, m.Name)
            end
        else
            local pt = playerData and playerData:FindFirstChild("PlayerTitle")
            if pt then
                for _, f in ipairs(pt:GetChildren()) do
                    table.insert(list, f.Name)
                end
            end
        end
        table.sort(list)
        for _, name in ipairs(list) do
            local label = titleCN(name)
            titleChoices[label] = name
            table.insert(titleNames, label)
        end
    end

        return {
            applyTitle = applyTitle,
            buildTitleList = buildTitleList,
            forceLocalTitle = forceLocalTitle,
            getForced = function()
                return forcedTitle
            end,
            getTitleNames = function()
                return titleNames
            end,
            getTitleChoices = function()
                return titleChoices
            end,
            setSelected = function(v)
                selectedTitle = v
            end,
        }
    end)()

    PlayerTab:Section({ Title = "虚假信息" })

    PlayerTab:Toggle({
        Title = "编号隐藏",
        Flag = "hideUid",
        Value = false,
        Callback = function(state)
            setUidHidden(state)
        end,
    })

    PlayerTab:Toggle({
        Title = "匿名者",
        Desc = "头顶名称改为 theKing User (红色, 仅本地可见)",
        Flag = "anonymous",
        Value = false,
        Callback = function(state)
            anonOn = state
            applyAnon(state)
            -- 关匿名后立刻把 PlayerName 渐变刷回当前伪装称号
            if (not state) and T.getForced() then
                T.forceLocalTitle(T.getForced())
            end
            notifyToggle("匿名者", anonOn, "eye-off")
        end,
    })

    T.buildTitleList()
    local titleNames = T.getTitleNames()
    if #titleNames > 0 then
        T.setSelected(T.getTitleChoices()[titleNames[1]])
    end

    PlayerTab:Dropdown({
        Title = "选择称号",
        Values = titleNames,
        Value = titleNames[1],
        Callback = function(sel)
            T.setSelected(T.getTitleChoices()[sel])
        end,
    })

    PlayerTab:Button({
        Title = "应用称号",
        Desc = "已拥有走服务器; 未拥有本地完整伪装(渐变/特效/名字色)",
        Icon = "crown",
        Callback = T.applyTitle,
    })

    LocalPlayer.CharacterAdded:Connect(function()
        anonNameLabel = nil
        task.wait(1.5)
        local ft = T.getForced()
        if ft then T.forceLocalTitle(ft) end
        if anonOn then applyAnon(true) end -- 后刷, 盖住称号对 PlayerName 的渐变
    end)
end
buildFakeInfo()

-- ---------- 玩家: 保持奔跑 / 移动加速 / 目标速度 ----------
local function buildPlayerMovement()
PlayerTab:Section({ Title = "玩家" })

PlayerTab:Toggle({
    Title = "保持奔跑",
    Flag = "keepSprint",
    Value = false,
    Callback = function(state)
        keepSprintOn = state
        notifyToggle("保持奔跑", keepSprintOn, "footprints")
    end,
})

PlayerTab:Toggle({
    Title = "移动加速",
    Flag = "speedHack",
    Value = false,
    Callback = function(state)
        speedHackOn = state
        notifyToggle("移动加速", speedHackOn, "rocket")
        if state then
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.WalkSpeed > runBaseline then runBaseline = hum.WalkSpeed end
        end
    end,
})

PlayerTab:Slider({
    Title = "目标移动速度",
    Desc = "建议 50~80，太高容易被注意",
    Flag = "targetSpeed",
    Value = { Min = 20, Max = 120, Default = 50 },
    Step = 1,
    Callback = function(v)
        if type(v) == "number" and v >= 20 and v <= 120 then
            targetSpeed = math.floor(v)
        end
    end,
})
end
buildPlayerMovement()

-- ============================================================
-- 设置 (骨架标配, 不可删)
-- ============================================================
local SettingsTab = TheKing.NewTab({ Title = "设置", Icon = "settings" })

function unloadAction()
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
    Value = "Delete",
    Callback = function()
        TheKing.Window:Toggle()
    end,
})

SettingsTab:Keybind({
    Title = "卸载脚本",
    Value = "End",
    Callback = unloadAction,
})

SettingsTab:Button({
    Title = "停止全部功能",
    Icon = "square",
    Callback = function()
        TheKing.StopAll()
        stopFight()
        -- 同步内部开关 (StopAll 只杀循环, 变量与 UI 状态需一致)
        autoFishOn = false
        autoSellOn = false
        autoBaitOn = false
        autoSkillOn = false
        syncSkillLoop()  -- 技能开关全关, 停技能循环
        fsmState = "待机"
        TheKing.Notify({ Content = "已停止全部功能", Icon = "check-circle" })
    end,
})

-- ============================================================
-- 随机切换服务器: 调 Roblox 公开 games API 拿服务器列表, 随机选非当前 jobId 传送
-- 纯客户端 TeleportService + game:HttpGet (注入器兼容: request 兜底), 不注入不 hook
-- ============================================================
SettingsTab:Button({
    Title = "随机切换服务器",
    Icon = "refresh-cw",
    Callback = function()
        TheKing.Confirm({
            Title = "随机切换服务器",
            Content = "将传送到另一个随机服务器, 当前自动功能会停止, 确定吗?",
            OnConfirm = function()
                task.spawn(function()
                    -- 1. 拿服务器列表 (Roblox 官方 games API)
                    local placeId = tostring(game.PlaceId)
                    local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?limit=100"
                    local body = nil
                    if type(game.HttpGet) == "function" then
                        local okG, res = pcall(function() return game:HttpGet(url) end)
                        if okG then body = res end
                    elseif type(request) == "function" then
                        local okR, res = pcall(function()
                            local r = request({ Url = url, Method = "GET" })
                            return r and r.Body or nil
                        end)
                        if okR then body = res end
                    end
                    if type(body) ~= "string" or body == "" then
                        TheKing.Notify({ Title = "切换失败", Content = "获取服务器列表失败, 网络或 API 受限", Icon = "alert-triangle" })
                        return
                    end
                    local HttpService = game:GetService("HttpService")
                    local okJson, parsed = pcall(function() return HttpService:JSONDecode(body) end)
                    if not okJson or type(parsed) ~= "table" or type(parsed.data) ~= "table" then
                        TheKing.Notify({ Title = "切换失败", Content = "服务器列表解析失败", Icon = "alert-triangle" })
                        return
                    end
                    -- 2. 收集非当前服务器的可用 jobId
                    local candidates = {}
                    local curJob = game.JobId
                    for _, sv in ipairs(parsed.data) do
                        if type(sv) == "table" and sv.id and sv.id ~= curJob and sv.playing ~= nil then
                            -- 只选未满员且玩家数较少的服 (更稳; playing>=maxPlayers 的进不去)
                            local maxP = sv.maxPlayers or 50
                            local curP = sv.playing or 0
                            if curP < maxP then -- 至少1空位即可 (TeleportToPlaceInstance 在 playing<maxPlayers 能进); 该游戏每服max=10且常仅余1空位, 要求>=2会永远落空
                                candidates[#candidates + 1] = { id = sv.id, players = curP }
                            end
                        end
                    end
                    if #candidates == 0 then
                        TheKing.Notify({ Title = "切换失败", Content = "没有可用的其他服务器", Icon = "alert-triangle" })
                        return
                    end
                    -- 3. 随机选一个
                    local pick = candidates[math.random(1, #candidates)]
                    TheKing.Notify({ Title = "正在切换服务器", Content = "目标服 " .. pick.players .. " 人在线, 传送中…", Icon = "loader", Duration = 5 })
                    -- 先停掉全部功能 (传送后旧实例会随 DataModel 销毁, 但主动停更干净)
                    TheKing.StopAll()
                    pcall(function()
                        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, pick.id)
                    end)
                end)
            end,
        })
    end,
})

-- ============================================================
-- 玩家功能: 保持奔跑 (Ctrl 误切自动切回) + 移动速度放大
-- Ctrl 机制 = Events.ToggleSprint:FireServer() (服务器权威翻转);
-- 关键: 游戏/服务器会周期性重置 WalkSpeed (实测 40→0), 单次写入会被打回,
-- 必须用 Heartbeat 每帧强制写回 (写入发生在物理步进前, 实际生效)
-- 变量声明已上移至状态区 (P2-6), 此处不再重复声明
-- ============================================================

TheKing.AddConnection(RunService.Heartbeat:Connect(function()
    if not speedHackOn and not keepSprintOn then return end
    local ch = LocalPlayer.Character
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    -- 移动速度: 每帧强制写目标值 (对抗游戏重置); 游泳态不干预
    if speedHackOn and ch:GetAttribute("Swimming") ~= true then
        if hum.WalkSpeed < targetSpeed then
            hum.WalkSpeed = targetSpeed
        end
    end

    -- 保持奔跑: 被切成走路速度时自动再切一次 (基准自适应学习)
    if keepSprintOn and hum.WalkSpeed > 0.5 then
        if hum.WalkSpeed > runBaseline then
            runBaseline = hum.WalkSpeed
        elseif runBaseline > 8 and hum.WalkSpeed < runBaseline * 0.65
            and os.clock() - lastSprintToggleAt > 2 then
            local remote = Events:FindFirstChild("ToggleSprint")
            if remote then
                remote:FireServer()
                lastSprintToggleAt = os.clock()
            end
        end
    end
end))

-- ============================================================
-- 防闲置增强 (v0.31.0): 注入即强制启动, 杜绝「开关显示开着实际没跑」
-- 主路: 每 60s 重掐 LocalPlayer.Idled 引擎连接 (Potassium ConnectionObject:Disable)
-- 脉冲: VirtualUser + VirtualInputManager 微动/F15 + mousemoverel + keytap (失焦也发, 不跳跃)
-- 退路: 自挂 Idled → 立刻多重脉冲 (主路已掐光时很少触发, 无害)
-- ============================================================
do
    local disabledIdle = {}
    local idleConn = nil
    local antiIdleOn = false
    local PULSE_INTERVAL = 60 -- 远低于引擎 ~20min 闲置踢; 定期重掐防连接被重建

    local function pulseInput()
        pcall(function()
            local vu = game:GetService("VirtualUser")
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end)
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            local cam = workspace.CurrentCamera
            local vp = cam and cam.ViewportSize or Vector2.new(800, 600)
            local x = vp.X * 0.5
            local y = vp.Y * 0.5
            vim:SendMouseMoveEvent(x + 1, y, game)
            vim:SendMouseMoveEvent(x, y, game)
            vim:SendKeyEvent(true, Enum.KeyCode.F15, false, game)
            vim:SendKeyEvent(false, Enum.KeyCode.F15, false, game)
        end)
        if type(mousemoverel) == "function" then
            pcall(mousemoverel, 1, 0)
            pcall(mousemoverel, -1, 0)
        end
        if type(keytap) == "function" then
            pcall(keytap, 0x7E) -- VK_F15, 游戏无绑定
        end
    end

    local function stopAntiIdle()
        antiIdleOn = false
        TheKing.StopLoop("antiIdle")
        if idleConn then
            pcall(function()
                idleConn:Disconnect()
            end)
            idleConn = nil
        end
        for _, con in ipairs(disabledIdle) do
            pcall(function()
                con:Enable()
            end)
        end
        table.clear(disabledIdle)
    end

    local function disableEngineIdle()
        local gc = nil
        if type(getconnections) == "function" then
            gc = getconnections
        elseif type(get_signal_cons) == "function" then
            gc = get_signal_cons
        end
        if type(gc) ~= "function" then
            return 0
        end
        local ok, list = pcall(gc, LocalPlayer.Idled)
        if not ok or type(list) ~= "table" then
            return 0
        end
        local n = 0
        for _, con in pairs(list) do
            -- 直接 pcall:Disable — Potassium 返回 userdata ConnectionObject,
            -- 方法在元表上, 不要先用 type(con)=="table" 挡掉
            local disabled = pcall(function()
                con:Disable()
            end)
            if not disabled then
                disabled = pcall(function()
                    con.Disable(con)
                end)
            end
            if not disabled then
                disabled = pcall(function()
                    con:Disconnect()
                end)
            end
            if disabled then
                table.insert(disabledIdle, con)
                n = n + 1
            end
        end
        return n
    end

    local function attachVirtualIdle()
        if idleConn then
            pcall(function()
                idleConn:Disconnect()
            end)
            idleConn = nil
        end
        local ok, conn = pcall(function()
            return LocalPlayer.Idled:Connect(function()
                if not antiIdleOn then
                    return
                end
                -- 仍触发 Idled = 连接可能被重建, 立刻掐 + 脉冲
                disableEngineIdle()
                pulseInput()
            end)
        end)
        if ok and conn then
            idleConn = conn
            return true
        end
        return false
    end

    local function startAntiIdle()
        stopAntiIdle()
        antiIdleOn = true
        disableEngineIdle()
        attachVirtualIdle()
        -- 再掐一次: attach 后 list 含自建连接也会被禁 —
        -- 主动脉冲循环才是权威续命; Idled 退路仅在 getconnections 不可用时兜底
        disableEngineIdle()
        TheKing.StartLoop("antiIdle", PULSE_INTERVAL, function()
            if not antiIdleOn then
                return
            end
            -- getconnections/Disable 与假输入都可能百毫秒级, 整段 defer 避免慢循环告警
            task.defer(function()
                if not antiIdleOn then
                    return
                end
                disableEngineIdle()
                pulseInput()
            end)
        end)
        task.defer(function()
            if antiIdleOn then
                disableEngineIdle()
                pulseInput()
            end
        end)
        return true
    end

    TheKing.OnCleanup(stopAntiIdle)

    SettingsTab:Toggle({
        Title = "防踢心跳",
        Desc = "注入即启动; 每分钟重掐闲置踢+多通道假输入。失焦也生效, 不跳跃",
        Flag = "antiIdle",
        Value = true,
        Callback = function(state)
            if state then
                startAntiIdle()
            else
                stopAntiIdle()
            end
            notifyToggle("防踢心跳", state, "heart-pulse")
        end,
    })

    -- 关键: WindUI Toggle Value=true 创建时不触发 Callback → 旧版开关显示开着实际零防护。
    -- 注入后立刻强制启动; 若 LoadConfig 恢复为关会再走 Callback(false) 停掉。
    startAntiIdle()
end

SettingsTab:Button({
    Title = "卸载脚本",
    Icon = "trash-2",
    Color = Color3.fromRGB(255, 100, 100),
    Callback = unloadAction,
})

TheKing.Notify({ Content = "TheKing HUB 已加载", Icon = "crown" })
TheKing.LoadConfig() -- 元素注册完毕后再恢复持久化配置 (骨架铁律)
-- LoadConfig 恢复完 flag (含鱼多选 targetFishSel), 回调已重填 lastFishSel, 此刻统一重套 targetFishNames
if type(targetFishRestoreFn) == "function" then
    pcall(targetFishRestoreFn)
end
-- 强制激活窗口一次: 确保首次快捷键即生效 (避免首次按键被窗口未激活吞掉需按两次)
pcall(function()
    if TheKing.Window and TheKing.Window.ForceOpen then
        TheKing.Window:ForceOpen()
    elseif TheKing.Window and TheKing.Window.Open then
        TheKing.Window:Open()
    end
end)

-- Tab 侧栏重排: WindUI 侧栏按创建顺序追加, 用 LayoutOrder 覆盖为目标顺序
-- 目标: 自动钓鱼 → 背包管理(原鱼饵管理) → 库存管理(原背包管理) → 快捷传送 → 快捷键 → 玩家 → 设置
-- (恩佐BOSS已并入自动钓鱼, BossTab 已移除 — 见 v0.24.3)
-- 延迟执行: UI 完整构建 + WindUI 自身 LayoutOrder 初始化之后覆盖才生效
-- 重要: TARGET_ORDER 必须与 buildMainTab/buildBaitTab/buildBagTab 等定义时的 Title 完全一致,
-- 否则标题匹配 miss, 全部按钮跳过赋值, LayoutOrder 保持 WindUI 默认(乱序)
task.delay(1.5, function()
    pcall(function()
        local windRoot = nil
        -- 主路径: CoreGui.RobloxGui.WindUI (实测 WindUI 挂此)
        local cg = game:GetService("CoreGui")
        local rbg = cg and cg:FindFirstChild("RobloxGui")
        windRoot = rbg and rbg:FindFirstChild("WindUI")
        -- 兜底: gethui
        if not windRoot then
            local okG, ghui = pcall(function()
                if type(gethui) == "function" then return gethui() end
                return nil
            end)
            if okG and ghui then windRoot = ghui:FindFirstChild("WindUI") end
        end
        if windRoot then
            local w = windRoot:FindFirstChild("Window")
            local f = w and w:FindFirstChildOfClass("Frame")
            local main = f and f:FindFirstChild("Main")
            local frame = main and main:FindFirstChild("Frame")
            local sf = frame and frame:FindFirstChild("ScrollingFrame")
            local tabBox = sf and sf:FindFirstChildOfClass("Frame")
            if tabBox then
                local TARGET_ORDER = {
                    ["自动钓鱼"] = 1,
                    ["背包管理"] = 2,
                    ["库存管理"] = 3,
                    ["快捷传送"] = 4,
                    ["快捷键"] = 5,
                    ["玩家"] = 6,
                    ["设置"] = 7,
                }
                for _, btn in ipairs(tabBox:GetChildren()) do
                    if btn:IsA("GuiObject") then
                        local title = ""
                        for _, d in ipairs(btn:GetDescendants()) do
                            if d:IsA("TextLabel") and d.Text ~= "" then title = d.Text; break end
                        end
                        local order = TARGET_ORDER[title]
                        if order then btn.LayoutOrder = order end
                    end
                end
            end
        end
    end)
end)

-- 注入即强制关闭的开关 (用户硬性要求, 严格从关闭态起步防误触):
--   自动钓鱼 (同时驱动恩佐BOSS检测) — 即使上次持久化为开启, 注入后也强制关
--   其余所有开关 (自动出售/自动技能/自动买饵/智能锁定等) 走 ConfigManager 持久化恢复
setAutoFish(false)
pcall(function() if toggleEls.autoFish then toggleEls.autoFish:Set(false) end end)

-- 注入初始化完成, 解除静默: 之后用户手动开关功能恢复弹通知
notifyMuted = false

-- 开发期调试接口 (MCP 驱动测试用; 发布构建时移除)
print("[RCWTK] PROBE_UI_DONE")
do
    local dbg = {
        state = function()
            return {
                autoFishOn = autoFishOn, fsm = fsmState,
                autoChargeOn = autoChargeOn,
                autoSellOn = autoSellOn, sellThreshold = sellThreshold,
                bossModeOn = bossModeOn, bossActive = bossActive, rhythmActive = rhythmActive,
                autoSkillOn = autoSkillOn, skillMode = skillMode,
                targetFishEnabled = targetFishEnabled,
                targetFishCount = (function() local n=0; for _ in pairs(targetFishNames) do n=n+1 end; return n end)(),
                sellTriggerMode = sellTriggerMode, sellableNow = sellFishCount(), invFull = isInventoryFull(),
                decisionLog = (function()
                    local t = {}
                    for i = math.max(1, #skillDecisionLog - 5), #skillDecisionLog do
                        table.insert(t, skillDecisionLog[i])
                    end
                    return t
                end)(),
                equipped = (function()
                    local t = {}
                    for _, m in ipairs(SKILL_KEYS) do
                        t[m.key] = getEquippedSkill(m.key)
                    end
                    return t
                end)(),
            }
        end,
        setAutoFish = setAutoFish,
        setCharge = function(on) autoChargeOn = on and true or false end,
        setSkill = function(on) setAutoSkill(on) end,
        setBoss = function(on) setAutoFish(on) end, -- 恩佐已并入自动钓鱼: 开 boss = 开自动钓鱼驱动检测
        setMode = function(mode)
            if mode == "智能择优" or mode == "顺序释放" then skillMode = mode end
        end,
        setBait = function(on, baitName, amount, reorder)
            if type(baitName) == "string" then selectedBait = baitName end
            if type(amount) == "number" and amount >= 1 then baitBuyAmount = math.floor(amount) end
            if type(reorder) == "number" and reorder >= 1 then baitReorderAt = math.floor(reorder) end
            setAutoBait(on)
        end,
        setSell = function(on, threshold)
            setAutoSell(on)
            if type(threshold) == "number" then sellThreshold = math.floor(threshold) end
        end,
        sellNow = function() return doSellAll("dbg") end,
        testNotify = function()
            TheKing.Notify({
                Title = "通知系统测试",
                Content = "如果看到这条, Notify 工作正常 " .. os.date("%X"),
                Icon = "info",
                Duration = 10,
            })
            return "fired"
        end,
        fishLabels = function(limit)
            local n = 0
            local out = {}
            for fishEn, isle in pairs(FISH_ISLE_MAP) do
                if n >= (limit or 10) then break end
                table.insert(out, fishLabel(fishEn))
                n = n + 1
            end
            table.sort(out)
            return out
        end,
        state2 = function()
            return {
                sellTriggerMode = sellTriggerMode,
                keepSprintOn = keepSprintOn,
                speedHackOn = speedHackOn,
                targetSpeed = targetSpeed,
                lockOn = lockOn,
                lockRuleGive = lockRuleGive,
                lockRuleWeight = lockRuleWeight,
                lockValueMin = lockValueMin,
            }
        end,
        cashState = function()
            return {
                statsCash = stats.cash,
                lastSeen = lastCashSeen,
                realCash = playerData and playerData.Cash and playerData.Cash.Value or -1,
                fish = stats.fish,
                fights = stats.fights,
            }
        end,
        forcePanel = updateStatsPanel,
        debugBag = function()
            local okBag, bag = pcall(function() return sellFishCount(true) end)
            local okP, pinfo = pcall(function()
                local t = type(StatsPara)
                local okT, st = pcall(function() return type(StatsPara.SetTitle) end)
                local okD, sd = pcall(function() return type(StatsPara.SetDesc) end)
                return string.format("type=%s setTitle=%s setDesc=%s", t, okT and tostring(st) or "THROW", okD and tostring(sd) or "THROW")
            end)
            return string.format("bag ok=%s val=%s para=%s", tostring(okBag), tostring(bag), okP and pinfo or ("ERR:"..tostring(pinfo)))
        end,
        debugPanel = function()
            local okBag, bagCount = pcall(function() return sellFishCount(true) end)
            bagCount = okBag and bagCount or 0
            local desc = string.format("挂机 %d 分 · 垂钓 %.1f 分 · 捕获 %d 条 · 背包 %d 条 · 收入 ¥%s",
                math.floor((os.clock() - stats.startedAt) / 60), fishRunAccum / 60,
                stats.fish, bagCount, fmtNum(stats.cash))
            return string.format("bagCount=%s desc=%s", tostring(bagCount), desc)
        end,
        testSetDesc = function(t)
            if not (StatsPara and StatsPara.SetDesc) then return "no method" end
            local ok, err = pcall(StatsPara.SetDesc, StatsPara, t)
            return ok and "ok" or ("ERR:"..tostring(err))
        end,
        checkUpdate = function()
            return "TheKing="..type(TheKing).." UpdateStatus="..(TheKing and type(TheKing.UpdateStatus) or "noTheKing")
        end,
        forcePanelDetail = function()
            local get = function() return StatsPara and (StatsPara._tk_desc or "NIL_DESC") or "NO_PARA" end
            local before = get()
            local ok, err = pcall(updateStatsPanel)
            local after = get()
            local bBag = before:match("背包 (%d+) 条") or "?"
            local aBag = after:match("背包 (%d+) 条") or "?"
            return "beforeBag="..bBag.." afterBag="..aBag.." callOk="..tostring(ok)
        end,
    }
    local g = rawget(_G, "RCWTK_DBG")
    if not g then
        g = {}
        rawset(_G, "RCWTK_DBG", g)
    end
    g.heavyFishing = dbg
    print("[RCWTK] PROBE_DBG_SET")
    TheKing.OnCleanup(function()
        local g = rawget(_G, "RCWTK_DBG")
        if g and g.heavyFishing == dbg then
            g.heavyFishing = nil
        end
    end)
end

