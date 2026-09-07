local pg = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
print("=== ScreenGuis ===")
for _, sg in ipairs(pg:GetChildren()) do
	if sg:IsA("LayerCollector") then
		print(string.format("%s Enabled=%s", sg.Name, tostring(sg.Enabled)))
	end
end

local function absVis(x)
	local n = x
	while n and n ~= pg do
		if n:IsA("GuiObject") then
			local ok, v = pcall(function()
				return n.Visible
			end)
			if ok and v == false then
				return false
			end
		end
		if n:IsA("ScreenGui") and n.Enabled == false then
			return false
		end
		n = n.Parent
	end
	return true
end

local keys = {
	"complet", "replay", "extract", "check", "result", "fail", "victory",
	"defeat", "decision", "endless", "summary", "reward", "chest", "boost",
	"continue", "extract", "leave", "return", "retry", "restart",
}

print("=== hit frames ===")
local n = 0
local function walk(p, d)
	if d > 7 or n > 300 then
		return
	end
	for _, c in ipairs(p:GetChildren()) do
		if c:IsA("GuiObject") and absVis(c) then
			local nm = string.lower(c.Name)
			local hit = false
			for _, k in ipairs(keys) do
				if string.find(nm, k, 1, true) then
					hit = true
					break
				end
			end
			local txt = ""
			if c:IsA("TextLabel") or c:IsA("TextButton") then
				txt = tostring(c.Text or "")
				local tl = string.lower(txt)
				if string.find(tl, "replay", 1, true) or string.find(tl, "extract", 1, true)
					or string.find(tl, "continue", 1, true) or string.find(tl, "重开", 1, true)
					or string.find(tl, "再来", 1, true) or string.find(tl, "结算", 1, true)
					or string.find(tl, "checkpoint", 1, true) or string.find(tl, "leave", 1, true)
					or string.find(tl, "retry", 1, true) then
					hit = true
				end
			end
			if hit then
				n += 1
				print(string.format("%s [%s] vis=%s txt=%s", c:GetFullName(), c.ClassName, tostring(c.Visible), string.sub(txt, 1, 90)))
			end
		end
		walk(c, d + 1)
	end
end
walk(pg, 0)
print("done n=" .. tostring(n))

print("=== HUD children ===")
local mainG = pg:FindFirstChild("Main")
local hud = mainG and mainG:FindFirstChild("HUD")
if hud then
	for _, c in ipairs(hud:GetChildren()) do
		local vis = ""
		if c:IsA("GuiObject") then
			vis = " vis=" .. tostring(c.Visible)
		end
		print(c.ClassName .. " " .. c.Name .. vis)
	end
else
	print("no HUD")
end
