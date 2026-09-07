local lp = game.Players.LocalPlayer
local pg = lp.PlayerGui
print("InDungeon=" .. tostring(lp:GetAttribute("InDungeon")) .. " Dead=" .. tostring(lp:GetAttribute("Dead")) .. " CurrentDungeon=" .. tostring(lp:GetAttribute("CurrentDungeon")))
local gen = nil
for _, c in ipairs(workspace:GetChildren()) do
	if string.sub(c.Name, 1, 10) == "Generated_" then
		gen = c.Name
		break
	end
end
print("Generated=" .. tostring(gen) .. " Challenge_Dungeons=" .. tostring(workspace:FindFirstChild("Challenge_Dungeons") ~= nil))
local hud = pg.Main.HUD
local ci = hud.Dungeon_Container:FindFirstChild("Completion_Info")
print("DC vis=" .. tostring(hud.Dungeon_Container.Visible) .. " CI vis=" .. tostring(ci and ci.Visible) .. " CI abs=" .. tostring(ci and ci.AbsoluteSize))
local sp = hud.Dungeon_Container:FindFirstChild("Spectate_Info")
print("Spectate vis=" .. tostring(sp and sp.Visible) .. " abs=" .. tostring(sp and sp.AbsoluteSize))
local loot = hud:FindFirstChild("Dungeon_Loot")
print("Loot vis=" .. tostring(loot and loot.Visible) .. " abs=" .. tostring(loot and loot.AbsoluteSize))
print("=== abs visible big ===")
local n = 0
local function walk(p)
	if n > 60 then
		return
	end
	for _, c in ipairs(p:GetChildren()) do
		if c:IsA("GuiObject") and c.Visible and c.AbsoluteSize.X >= 180 and c.AbsoluteSize.Y >= 70 then
			if c.Name ~= "HUD" and c.Name ~= "Main" then
				n += 1
				print(string.format("%s %dx%d", c.Name, c.AbsoluteSize.X, c.AbsoluteSize.Y))
			end
		end
		walk(c)
	end
end
walk(pg)
print("n=" .. n)
