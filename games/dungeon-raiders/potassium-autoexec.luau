--[[
    Potassium autoexec — 地下城战利品者
    钾会并行/反复执行本文件. 同 Job 只注入一次.
    禁止把注入丢进 task.spawn: 文件一 return 钾会掐掉后台线程, 锁还在, 后面全 return.
    只在地牢图跑.
]]

if game.PlaceId ~= 132285059959516 then
    return
end

local LOCKF = "rcwtk-dr-ae.lock"

local function readLock()
    local ok, s = pcall(readfile, LOCKF)
    if ok and type(s) == "string" then
        return s
    end
    return ""
end

local function clearLock()
    pcall(function()
        if type(delfile) == "function" then
            delfile(LOCKF)
        else
            writefile(LOCKF, "")
        end
    end)
end

local function hubAlive()
    local ok, alive = pcall(function()
        local reg = rawget(_G, "RCWTK_REGISTRY")
        if type(reg) == "table" and type(reg["地下城战利品者"]) == "function" then
            return true
        end
        local lp = game:GetService("Players").LocalPlayer
        if not lp then
            return false
        end
        local pg = lp:FindFirstChild("PlayerGui")
        if not pg then
            return false
        end
        for _, g in ipairs(pg:GetChildren()) do
            local n = g.Name
            if n:find("TheKing", 1, true) or n:find("Rayfield", 1, true) then
                return true
            end
        end
        return false
    end)
    return ok and alive == true
end

if hubAlive() then
    return
end

local tJob = os.clock()
while tostring(game.JobId) == "" and (os.clock() - tJob) < 12 do
    task.wait(0.2)
end

local job = tostring(game.JobId)
if job == "" then
    job = "sess"
end

local function waitHub(sec)
    local t = os.clock()
    while (os.clock() - t) < sec do
        if hubAlive() then
            return true
        end
        task.wait(0.4)
    end
    return hubAlive()
end

local cur = readLock()
if cur:find(job, 1, true) then
    if hubAlive() then
        return
    end
    if cur:find("READY", 1, true) then
        clearLock()
    elseif waitHub(40) then
        return
    else
        clearLock()
    end
end

local owner = tostring({}) .. ":" .. tostring(os.clock())
pcall(writefile, LOCKF, job .. "\t" .. owner)
task.wait(0.35)
if not readLock():find(owner, 1, true) then
    waitHub(40)
    return
end

local t0 = os.clock()
while not game:IsLoaded() and (os.clock() - t0) < 30 do
    task.wait(0.25)
end
local Players = game:GetService("Players")
local lp = Players.LocalPlayer
while not lp and (os.clock() - t0) < 30 do
    task.wait(0.25)
    lp = Players.LocalPlayer
end
while lp and not lp.Character and (os.clock() - t0) < 25 do
    task.wait(0.25)
end
task.wait(0.6)

if hubAlive() then
    pcall(writefile, LOCKF, job .. "\tREADY")
    return
end

local g = _G
pcall(function()
    if type(getgenv) == "function" then
        local ok, env = pcall(getgenv)
        if ok and type(env) == "table" then
            g = env
        end
    end
end)
pcall(function()
    g.RCWTK_DR_AUTOEXEC_RUN = true
    _G.RCWTK_DR_AUTOEXEC_RUN = true
end)

local function has(p)
    local ok, v = pcall(function()
        return type(isfile) == "function" and isfile(p) == true
    end)
    return ok and v == true
end

local files = {
    "dungeon-raiders/hub.luau",
    "games/dungeon-raiders/hub.luau",
}
local injected = false
for _, p in ipairs(files) do
    if has(p) then
        local ok, src = pcall(readfile, p)
        if ok and type(src) == "string" and #src > 200 then
            local fn, err = loadstring(src)
            if type(fn) == "function" then
                print("[RCWTK] autoexec 地下城战利品者 ← " .. p)
                local ran, runErr = pcall(fn)
                injected = ran and hubAlive()
                if not ran then
                    warn("[RCWTK] autoexec 运行失败: " .. tostring(runErr))
                elseif not hubAlive() then
                    warn("[RCWTK] autoexec hub 跑完但窗口没起来")
                end
                break
            end
            warn("[RCWTK] autoexec 编译失败: " .. tostring(err))
        end
    end
end

pcall(function()
    g.RCWTK_DR_AUTOEXEC_RUN = nil
    _G.RCWTK_DR_AUTOEXEC_RUN = nil
end)

if injected then
    pcall(writefile, LOCKF, job .. "\tREADY")
else
    clearLock()
    if not injected then
        warn("[RCWTK] autoexec: 找不到地下城 hub 或注入失败")
    end
end
