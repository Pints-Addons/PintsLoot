-- Pint's Loot: WoW Forever's new dungeons (the built-in data comes from Classic, which doesn't have them).
-- Boss loot by name from wowtbc.gg (WoW Forever loot tables; still being discovered there). The game doesn't publish
-- these items' numbers yet, so each starts as a stand-in and becomes the real item once the game has shown it to you
-- (in a loot window, a chat link, a tooltip...): see "learning item numbers" in Core.lua.
if type(issecretvalue) ~= "function" then return end   -- (WoW Forever only)
local D = PintsLootData
if not (D and D.cats and D.cats[1] and D.items) then return end

-- slot -> { inventory type, item class*100 + subclass }
local W = function(inv, sub) return { inv, 200 + sub } end
local A = function(inv, sub) return { inv, 400 + sub } end
local K = {
	["neck"] = A(2, 0), ["finger"] = A(11, 0), ["trinket"] = A(12, 0),
	["back"] = A(16, 1), ["held"] = A(23, 0), ["shield"] = A(14, 6),
	["chest cloth"] = A(5, 1), ["chest leather"] = A(5, 2), ["chest mail"] = A(5, 3),
	["waist cloth"] = A(6, 1), ["waist leather"] = A(6, 2), ["waist mail"] = A(6, 3), ["waist plate"] = A(6, 4),
	["wrist cloth"] = A(9, 1), ["wrist leather"] = A(9, 2),
	["legs cloth"] = A(7, 1), ["legs leather"] = A(7, 2), ["legs mail"] = A(7, 3),
	["hands cloth"] = A(10, 1), ["hands leather"] = A(10, 2), ["hands mail"] = A(10, 3),
	["feet cloth"] = A(8, 1), ["feet mail"] = A(8, 3),
	["shoulder cloth"] = A(3, 1), ["shoulder leather"] = A(3, 2), ["shoulder mail"] = A(3, 3),
	["1h dagger"] = W(13, 15), ["mh dagger"] = W(21, 15), ["1h sword"] = W(13, 7), ["1h axe"] = W(13, 0), ["mh axe"] = W(21, 0),
	["mh mace"] = W(21, 4), ["2h sword"] = W(17, 8), ["2h axe"] = W(17, 1), ["2h staff"] = W(17, 10), ["2h polearm"] = W(17, 6),
	["gun"] = W(26, 3), ["crossbow"] = W(26, 18), ["wand"] = W(26, 19),
}
-- { name, minLevel, maxLevel, { { boss, { item, kind, item, kind, ... } }, ... } }
local NEW = {
	{ "Hall of Thanes", 13, 18, {
		{ "Faldrim Anvilmar", { "Ephemeral Choker", "neck", "Aetherwisp Bracers", "wrist cloth", "Spiritwraith Drape", "back" } },
		{ "Magmatus", { "Kindlegem Girdle", "waist mail", "Flamefist Grips", "hands leather", "Fang of Magmatus", "mh dagger" } },
		{ "Plunder", { "Golemheart Stave", "2h staff", "Treads of the Protector Golem", "feet mail", "Golemguard Chest", "chest mail" } },
		{ "Durgen Dirgehammer", { "Durgen's Crescent Axe", "mh axe", "Direhammer Leggings", "legs leather", "Robes of the Disgraced Thane", "chest cloth" } },
	} },
	{ "Ruins of Lordaeron", 16, 23, {
		{ "The Baron", { "Meathook Slicer", "1h dagger", "Abomination Bones", "chest mail", "Leftover Abomination Skin", "chest cloth" } },
		{ "Witherfang", { "Atrophic Girdle", "waist mail", "Witherbite Bracers", "wrist leather", "Segmented Spider Leg", "2h staff" } },
		{ "The Abandoned", { "Rotmender's Leggings", "legs cloth", "Grip of Fear", "hands mail", "Scepter of the Abandoned", "mh mace" } },
		{ "Bjork", { "Bonerust Leggings", "legs mail", "Tuskwrap Belt", "waist cloth", "Corpse Chopper", "2h axe" } },
		{ "Rath'mael", { "Mirror of Rath'mael", "shield", "Rotmender's Treads", "feet cloth", "Coldspire Staff", "2h staff" } },
		{ "Deathsworn Captain", { "Haunting Blade", "2h sword", "Phantom Armor", "chest mail" } },
		{ "Viktor the Vile", { "Vilewalkers", "feet mail", "Bloodied Chestwraps", "chest leather", "Vileblood Scimitar", "1h sword" } },
	} },
	{ "Excavation Site: Wetlands", 26, 32, {
		{ "Saltspine", { "Supple Bellyskin Leggings", "legs leather", "Saltscale Girdle", "waist mail", "Glinteye Slippers", "feet cloth" } },
		{ "Shadetooth", { "Raptorclaw Greaves", "feet mail", "Garb of Florid Feathers", "chest leather", "Raptor's Gaze", "held" } },
		{ "Relic Guardian", { "Reliquary Mantle", "shoulder mail", "Golemsight Long Gun", "gun", "Ring of Power Regulation", "finger" } },
	} },
	{ "City of Dalaran", 28, 34, {
		{ "Atrexis the Grave Knight", { "Bonebinder's Signet", "finger", "Gravespike Repeater", "crossbow", "Graveweave Bindings", "wrist cloth" } },
		{ "Arcane Anomaly", { "Runemender's Seal", "finger", "Ephemeral Grips", "hands cloth", "Mana-Warped Chain Shirt", "chest mail" } },
		{ "Arcanic Enigma", { "Wand of Mana Concentration", "wand", "Violet Sorcerer's Robes", "chest cloth", "Drape of Shifting Energy", "back" } },
		{ "Unstable Sentinel", { "Guardian's Dualblade", "2h axe", "Unstable Crystalline Shoulderpads", "shoulder leather", "Refractory Scaleguards", "legs mail" } },
		{ "Mana Devourer", { "Spine of the Devourer", "2h staff", "Slitherwrap Girdle", "waist leather", "Manascale Treads", "feet mail" } },
		{ "Fel Ancient", { "Felbough Arm", "2h polearm", "Garb of Fallen Felbark", "chest leather", "Blightleaf Rope", "waist cloth" } },
		{ "Lyn the Ignored", { "Tendonscraper Dagger", "mh dagger", "Cartilage Shapers", "hands leather", "Bonepile Gaze", "shield" } },
		{ "Shade of the Archmage", { "Archmagister's Faceted Pendant", "neck", "Violet Sorcerer's Mantle", "shoulder cloth", "Ponderous Orb", "held" } },
	} },
	{ "The Drowned City", 35, 40, {
		{ "Zun'Alai", { "Bloodslash Axe", "1h axe", "Oathbound Bracers", "wrist leather" } },
		{ "Gill", {} }, { "Zin'aka", {} },
	} },
	{ "Krol'dok Stronghold", 40, 45, {
		{ "Slavecrusher Grox", { "Resistance Breaker Spaulder", "shoulder mail" } },
		{ "Twilight Commander Zarmok", { "Shadowlight Athame", "mh dagger" } },
		{ "Bossman Toof", { "Big-Belly Belt", "waist cloth" } },
		{ "Nar'gurk", { "Chain of the Corruptor", "neck" } },
		{ "Overlord Mugg", { "Emblem of Slamming", "trinket" } },
	} },
	{ "Alcaz Prison", 48, 53, {
		{ "Tidemistress Ca'zass", { "Cloak of the Tidemistress", "back" } },
		{ "Overseer Wrex", { "Wrex's Pinky Ring", "finger" } },
		{ "Katerina the Cleaner", { "Sentimental Locket", "neck" } },
		{ "The Questioner", { "Girdle of Extracted Answers", "waist plate" } },
	} },
	{ "Blackmaw Hold", 55, 60, {} },
	{ "Shaper's Terrace", 58, 60, {} },
}

local F = { byName = {}, names = {}, pages = {} }
_G.PintsLootForever = F
local nextID = -1001
for _, d in ipairs(NEW) do
	local groups = {}
	for _, b in ipairs(d[4]) do
		local list = {}
		for x = 1, #b[2], 2 do
			local name, k = b[2][x], K[b[2][x + 1]] or { 0, 1500 }
			local id = F.byName[name]
			if not id then
				id = nextID; nextID = nextID - 1
				-- { inventoryType, class*100+subclass, requiredLevel, quality, classMask, name, source } (dungeon blues until the game says)
				D.items[id] = { k[1], k[2], 0, 3, 0, name }
				F.byName[name] = id; F.names[id] = name
			end
			list[#list + 1] = id; list[#list + 1] = -1          -- (-1: drop chance not known yet)
		end
		groups[#groups + 1] = { b[1], 1, 0, list }
	end
	if #groups == 0 then groups[1] = { "Bosses and loot not found yet", 1, 0, {} } end
	local page = { d[1], ("Levels %d-%d  -  WoW Forever (new)"):format(d[2], d[3]), groups, 0, 0, d[2], d[3] }
	F.pages[#F.pages + 1] = page
	-- in level order among the dungeons
	local list, at = D.cats[1][2], nil
	for i, p in ipairs(list) do
		if (p[4] or 0) == 0 and (p[6] or 0) > d[2] then at = i; break end
	end
	if not at then
		at = #list + 1
		for i, p in ipairs(list) do if (p[4] or 0) ~= 0 then at = i; break end end
	end
	table.insert(list, at, page)
end
