--[[
    TheKing HUB [0.1.0] - <在此填游戏名>
    RCWTK 引擎生成 | 模板 v1.1
    版本历史: games/<游戏目录>/changelog.md (每次发布追加条目, 语义见该文件)

    功能清单 (改这里, 保持格式):
      功能1: ...
      功能2: ...

    逆向结论 (关键协议结论写这里, 收工同步到 games/<游戏目录>/intel.md):
      -

    使用方式:
      开发: loadstring(readfile("hub-skeleton.luau"))()   -- 与 lib/ 同级
      热调试: 改完代码直接重新执行本文件, 旧实例自动自毁让位, 无需手动卸载
      发布: 用构建脚本把 theking.luau 内嵌后单文件化
      静态门: python tools/check_hub.py games/<目录>/hub.luau
]]

local TheKing = loadstring(readfile("lib/theking.luau"))({
    GameName = "<在此填游戏名>",  -- 显示为 TheKing HUB 下方小字, 必须与 intel.md game: 逐字一致
    ScriptVersion = "0.1.0",
    -- UI 默认 Rayfield Gen2; 小图标由引擎注入品牌方圆标, 不必再填 lucide
})

-- 主块 local 超过 Luau 200 上限会编不过; 全部业务放进这层闭包
;(function()

TheKing.Notify({ Content = "TheKing HUB 已加载", Icon = "crown" })

-- 相关状态收单表: local S = TheKing.Pack({ on = false }); function S.tick() end
-- 偏好: local Prefs = TheKing.OpenPrefs({ "games/<目录>/prefs.txt", "prefs.txt" })
-- 游戏打回的属性: TheKing.Hold("walkspeed", getHum, "WalkSpeed", function() return 32 end)
-- Knit: local ok, r = TheKing.Await(svc:RequestX())
-- 绘制走 TheKing.Draw (docs/draw-api.md), 禁止 Drawing.new
-- 会对齐节拍/每帧: TheKing.BindStepped("name", "heartbeat", fn)  (StartLoop 有 50ms 下限)

-- ============================================================
-- Tab: 主功能
-- ============================================================
local MainTab = TheKing.NewTab({ Title = "主功能", Icon = "zap" })

--- 标准自动循环模板 (BindToggle: 开=StartLoop, 关=StopLoop, Flag 持久化)
TheKing.BindToggle(MainTab, {
    Title = "自动<功能名>",
    Desc = "开启后按间隔执行; 找不到界面会不开循环",
    Flag = "autoFeature",
    Interval = 0.5,
    -- Jitter = false,       -- 固定周期才关抖动
    -- AutoBackoff = true,   -- 单轮特别慢时自动歇一会
    OnEnable = function()
        -- 返回 false 则不启动循环
        return true
    end,
    OnTick = function()
        -- TODO: 单次循环体; 热路径用 TheKing.FindRemote, 禁止 WaitForChild
        -- 没事干时 TheKing.Backoff(10)
    end,
})

--[[ L2 危险功能范式 (抢发包/hook 等对抗手段照此写, 流程见 AGENTS.md 反作弊分级章节):
do
    MainTab:Toggle({
        Title = "<L2功能名>",
        Desc = "原理: <一句话说明用了什么手段和为什么安全>",
        Flag = "l2Feature",
        Value = false,
        Callback = function(state)
            if state then
                TheKing.StartLoop("l2Feature", 0.5, function()
                    TheKing.Guard(function()
                        -- TODO: L2 逻辑 (hook 游戏自身函数 / 抢发服务器接受的包)
                        -- 首次上线前必须: 最小参数试探 -> record-session 观察回滚 -> 小号实测 10 分钟
                    end, "<L2功能名>", { fuse = true }) -- 失败停当前循环; 要全停用 fuse="all"
                end)
            else
                TheKing.StopLoop("l2Feature")
            end
        end,
    })
end
]]

--- 标准按钮模板 (一次性动作)
MainTab:Button({
    Title = "一键<动作>",
    Icon = "mouse-pointer-click",
    Callback = function()
        -- TODO: 动作逻辑
        TheKing.Notify({ Content = "已执行" })
    end,
})

--[[ 绘制示例 (取消注释前读 docs/draw-api.md):
TheKing.Draw.onPaint(function()
    local hrp = game:GetService("Players").LocalPlayer.Character
        and game:GetService("Players").LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return
    end
    TheKing.Draw.disc("self", hrp, 3, Color3.fromRGB(255, 200, 40), 0.45, -2.45)
end)
]]

-- ============================================================
-- Tab: 传送
-- ============================================================
local TeleportTab = TheKing.NewTab({ Title = "传送", Icon = "map-pin" })

TeleportTab:Dropdown({
    Title = "选择地点",
    Values = {
        -- "出生点",
        -- "商店",
    },
    Callback = function(selected)
        -- TODO: 按 selected 名称取 CFrame 传送
        -- char.HumanoidRootPart.CFrame = CFrame.new(x, y, z)
    end,
})

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

end)()
