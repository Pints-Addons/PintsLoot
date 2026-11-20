-- Pint's Loot: on WoW Forever, what only the Classic data says - raids that haven't opened, the world bosses' Classic tables,
-- the Classic PvP lists and reputation rewards Wowhead's WoW Forever pages don't show, raid sets and legendaries - is moved
-- out of sight into a "Not confirmed on Forever" category. Pick "Show Classic-only data" at the bottom of the category menu
-- to see it. Raids join the other dungeons as they open on Forever (OPEN below). Classic Era shows everything as before.
if type(issecretvalue) ~= "function" then return end   -- (WoW Forever only)
local D = PintsLootData
if not (D and D.cats) then return end
local OPEN = {}          -- raids open on WoW Forever, by name, e.g. ["Molten Core"] = true
local C = D.confirmed or {}
local Q = { "Not confirmed on Forever", {}, hidden = true }
local function Cat(name) for i, c in ipairs(D.cats) do if c[1] == name then return c, i end end end
local function Move(cat, pred)
	local keep = {}
	for _, p in ipairs(cat[2]) do
		if pred(p) then p[2] = (p[2] or "") .. "  -  Classic only, not confirmed on Forever"; Q[2][#Q[2] + 1] = p else keep[#keep + 1] = p end
	end
	cat[2] = keep
end
-- items in a page Wowhead's WoW Forever pages don't show go to a "Classic only" copy of the page
local function Split(page)
	local qg = {}
	for _, g in ipairs(page[3]) do
		local keep, out = {}, {}
		for x = 1, #g[4], 2 do
			local t = C[g[4][x]] and keep or out
			t[#t + 1] = g[4][x]; t[#t + 1] = g[4][x + 1]
		end
		g[4] = keep
		if #out > 0 then qg[#qg + 1] = { g[1], g[2], g[3], out } end
	end
	for i = #page[3], 1, -1 do if #page[3][i][4] == 0 then table.remove(page[3], i) end end
	if #qg > 0 then Q[2][#Q[2] + 1] = { page[1] .. " (Classic only)", "Classic only, not confirmed on Forever", qg, 0, 0, 0, 0 } end
end
-- raids
local dr = Cat("Dungeons & Raids")
if dr then Move(dr, function(p) return (p[4] or 0) ~= 0 and not OPEN[p[1]] end) end
-- world bosses and world epics: Classic tables
local wd = Cat("World Drops")
if wd then Move(wd, function() return true end) end
-- PvP: what Forever's PvP vendors sell stays (ForeverPvP.lua); the rest of the Classic rank and battleground lists goes
local pv = Cat("PvP")
if pv then
	local keep = {}
	for _, p in ipairs(pv[2]) do
		if not (p[2] or ""):find("WoW Forever", 1, true) then Split(p) end
		if #p[3] > 0 then keep[#keep + 1] = p end
	end
	pv[2] = keep
end
-- reputation rewards: the Classic factions keep what Wowhead's Forever faction pages show
local fc = Cat("Factions")
if fc then
	local keep = {}
	for _, p in ipairs(fc[2]) do
		if not p[2]:find("WoW Forever", 1, true) then Split(p) end
		if #p[3] > 0 then keep[#keep + 1] = p end
	end
	fc[2] = keep
end
-- raid sets and legendaries
local col = Cat("Collections")
if col then
	local RAID = { ["Tier 1 Sets"] = true, ["Tier 2 Sets"] = true, ["Tier 2.5 Sets"] = true, ["Tier 3 Sets"] = true,
		["Zul'Gurub Sets"] = true, ["Ruins of Ahn'Qiraj Sets"] = true, ["Legendaries"] = true, ["World Epics"] = true }
	-- PvP sets: the pieces Forever's PvP vendors sell stay
	for _, p in ipairs(col[2]) do if p[1] == "PvP Sets" then Split(p) end end
	Move(col, function(p) return RAID[p[1]] or (p[1] == "PvP Sets" and #p[3] == 0) end)
end
-- empty categories go too
for i = #D.cats, 1, -1 do if #D.cats[i][2] == 0 then table.remove(D.cats, i) end end
if #Q[2] > 0 then D.cats[#D.cats + 1] = Q end
