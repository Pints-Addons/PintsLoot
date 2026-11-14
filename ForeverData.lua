-- Pint's Loot: WoW Forever's new dungeons (the built-in data comes from Classic, which doesn't have them).
-- Boss loot by name from wowtbc.gg and forg.gg (WoW Forever loot tables; still being discovered there). The game doesn't publish
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
	["1h mace"] = W(13, 4), ["2h mace"] = W(17, 5), ["fist"] = W(13, 13),
	["head cloth"] = A(1, 1), ["head leather"] = A(1, 2), ["head plate"] = A(1, 4), ["chest plate"] = A(5, 4), ["feet plate"] = A(8, 4), ["legs plate"] = A(7, 4),
	["mh sword"] = W(21, 7), ["wrist mail"] = A(9, 3), ["wrist plate"] = A(9, 4), ["hands plate"] = A(10, 4),
	["shoulder plate"] = A(3, 4), ["head mail"] = A(1, 3), ["feet leather"] = A(8, 2),
	["gun"] = W(26, 3), ["crossbow"] = W(26, 18), ["wand"] = W(26, 19),
}
-- { name, minLevel, maxLevel, { { boss, { item, kind, item, kind, ... } }, ... } }
local NEW = {
	{ "Hall of Thanes", 13, 18, {
		{ "Faldrim Anvilmar", { "Ephemeral Choker", "neck", "Aetherwisp Bracers", "wrist cloth", "Spiritwraith Drape", "back" } },
		{ "Magmatus", { "Kindlegem Girdle", "waist mail", "Flamefist Grips", "hands leather", "Fang of Magmatus", "mh dagger" } },
		{ "Plunder", { "Golemheart Stave", "2h staff", "Treads of the Protector Golem", "feet mail", "Golemguard Chest", "chest mail" } },
		{ "Durgen Dirgehammer", { "Durgen's Crescent Axe", "mh axe", "Direhammer Leggings", "legs leather", "Robes of the Disgraced Thane", "chest cloth" } },
		{ "Quest rewards", { "Catacomb Cloak", "back", "Deepgrave Trousers", "legs leather", "Dwarven Tome", "held", "Tomb Robber's Gloves", "hands cloth",
			"Calibrated Blunderbuss", "gun", "Ironforge Greathammer", "2h mace", "Deepblaze", "wand", "Dusty Belt", "waist leather", "Cryptwalker Bracers", "wrist mail" } },
	} },
	{ "Ruins of Lordaeron", 16, 23, {
		{ "Witherfang", { "Atrophic Girdle", "waist mail", "Witherbite Bracers", "wrist leather", "Segmented Spider Leg", "2h staff" } },
		{ "The Baron", { "Meathook Slicer", "1h dagger", "Abomination Bones", "chest mail", "Leftover Abomination Skin", "chest cloth" } },
		{ "Viktor the Vile (hidden)", { "Vilewalkers", "feet mail", "Bloodied Chestwraps", "chest leather", "Vileblood Scimitar", "1h sword" } },
		{ "The Abandoned", { "Rotmender's Leggings", "legs cloth", "Grip of Fear", "hands mail", "Scepter of the Abandoned", "mh mace" } },
		{ "Bjork", { "Bonerust Leggings", "legs mail", "Tuskwrap Belt", "waist cloth", "Corpse Chopper", "2h axe" } },
		{ "Rath'mael", { "Mirror of Rath'mael", "shield", "Rotmender's Treads", "feet cloth", "Coldspire Staff", "2h staff" } },
		{ "Deathsworn Captain (rare)", { "Haunting Blade", "2h sword", "Phantom Armor", "chest mail" } },
		{ "Quest rewards", { "Monstrous Cleaver", "2h sword", "Grave Shroud", "back", "Slain Baron's Signet", "finger", "Duty Bound Leggings", "legs leather",
			"Remembrance Armor", "chest mail", "Tarnished Locket", "neck", "Forsaken Greataxe", "2h axe", "Gnarled Necromancer's Staff", "2h staff",
			"The Stitcher", "mh mace", "Spare Part Bindings", "wrist leather", "Edward's Knife", "1h dagger", "Tabitha's Cuffs", "wrist cloth",
			"Plaguefang", "1h sword", "Blight Gloves", "hands cloth" } },
	} },
	{ "Excavation Site: Wetlands", 26, 32, {
		{ "Saltspine", { "Supple Bellyskin Leggings", "legs leather", "Saltscale Girdle", "waist mail", "Glinteye Slippers", "feet cloth" } },
		{ "Shadetooth", { "Raptorclaw Greaves", "feet mail", "Garb of Florid Feathers", "chest leather", "Raptor's Gaze", "held" } },
		{ "Relic Guardian", { "Reliquary Mantle", "shoulder mail", "Golemsight Long Gun", "gun", "Ring of Power Regulation", "finger" } },
		{ "Quest rewards", { "Daewyn's Girdle", "waist cloth", "Songblade Stabilizer", "waist mail", "Explorer's League Dustcover", "back",
			"Healer's Staff", "2h staff", "Heavehammer", "2h mace", "Ironwood Destroyer", "2h mace", "Curl of Life", "finger", "Hornbeam Heft", "1h axe",
			"Satchel of Potions", "trinket", "Serrated Raptor Claw", "1h dagger", "Furs of the Earthen Ring", "back",
			"Knife-Polishing Rag", "wrist cloth", "Dirt-Heavy Bracers", "wrist leather" } },
	} },
	{ "City of Dalaran", 28, 34, {
		{ "Atrexis the Grave Knight", { "Bonebinder's Signet", "finger", "Gravespike Repeater", "crossbow", "Graveweave Bindings", "wrist cloth" } },
		{ "Lyn the Ignored", { "Tendonscraper Dagger", "mh dagger", "Cartilage Shapers", "hands leather", "Bonepile Gaze", "shield" } },
		{ "Arcane Anomaly", { "Runemender's Seal", "finger", "Ephemeral Grips", "hands cloth", "Mana-Warped Chain Shirt", "chest mail" } },
		{ "Arcanic Enigma", { "Wand of Mana Concentration", "wand", "Violet Sorcerer's Robes", "chest cloth", "Drape of Shifting Energy", "back" } },
		{ "Unstable Sentinel", { "Guardian's Dualblade", "2h axe", "Unstable Crystalline Shoulderpads", "shoulder leather", "Refractory Scaleguards", "legs mail" } },
		{ "Mana Devourer", { "Spine of the Devourer", "2h staff", "Slitherwrap Girdle", "waist leather", "Manascale Treads", "feet mail" } },
		{ "Fel Ancient", { "Felbough Arm", "2h polearm", "Garb of Fallen Felbark", "chest leather", "Blightleaf Rope", "waist cloth" } },
		{ "Shade of the Archmage", { "Archmagister's Faceted Pendant", "neck", "Violet Sorcerer's Mantle", "shoulder cloth", "Ponderous Orb", "held" } },
		{ "Quest rewards", { "Spellguard Pauldrons", "shoulder mail", "Renewing Footpads", "feet leather", "Defender of Dalaran", "2h mace",
			"Fallen Guard's Pendant", "neck", "Arcane Infused Rod", "held", "Violet Sash", "waist cloth", "Runebound Gloves", "hands leather",
			"Vine Pruner's Cloak", "back", "Thorn Protecting Girdle", "waist mail", "Battle Spaulders", "shoulder mail", "Enchanted Sandals", "feet cloth",
			"Striking Staff", "2h staff", "Gravewalker Boots", "feet leather", "Undead Knight's Bracers", "wrist mail", "Unstable Power Core", "wand",
			"Construct Cloak", "back", "Solid Gold Band", "finger", "Larcenist's Belt", "waist leather" } },
	} },
	{ "The Drowned City", 35, 40, {
		{ "Zul'Alai", { "Bloodslash Axe", "1h axe", "Oathbound Bracers", "wrist leather", "Berserker Shackles", "wrist mail" } },
		{ "Gill", { "Gill's Gills", "trinket", "Tidebound Dagger", "mh dagger" } },
		{ "Captain Dreadrise", { "Dreadfrost Saber", "mh sword", "Frosty Blunderbuss", "gun", "Briny Sash", "waist cloth" } },
		{ "Primeval Elemental", { "Robe of the Drowned", "chest cloth", "Waterlogged Burial Shroud", "back", "Heart of the Primeval", "trinket" } },
		{ "Var'Taka", { "Harpoon of Command", "2h polearm", "Brinebelly Leggings", "legs leather", "Priestess Cloak", "back" } },
		{ "Deathless Marrow", { "Bloodspine Staff", "2h staff", "Viscera Spaulders", "shoulder mail", "Knucklebone Ring", "finger" } },
		{ "Min'loth the Serpent", { "Maw of Min'loth", "shield", "Serpentbane Crown", "head mail", "Ritual-Binder's Gloves", "hands leather", "Linken's Boots of Iron", "feet mail" } },
		{ "Umbra", { "Umbral Scaled Belt", "waist mail", "Deep-Dweller's Grips", "hands cloth" } },
		{ "Zin'aka", {} },
		{ "Quest rewards", { "Rusted Troll War Belt", "waist mail", "Saltseer's Helm", "head leather", "Mutinous Cuffs", "wrist cloth", "South Seas Shroud", "back",
			"Ancient Voodoo Pouch", "held", "Intrepid Explorer's Chainmail", "chest mail", "Apprentice Sorcerer's Slacks", "legs cloth",
			"Rune-Etched Epaulets", "shoulder leather", "Tidesoaked Leggings", "legs leather", "Naga Priestess's Mantle", "shoulder cloth" } },
	} },
	{ "Krol'dok Stronghold", 40, 45, {
		{ "Slavecrusher Grox", { "Slavecrusher Scepter", "1h mace", "Resistance Breaker Spaulder", "shoulder mail", "Chain of Binding", "waist mail" } },
		{ "Twilight Commander Zarmok", { "Shadowlight Athame", "mh dagger", "Shadecaster's Leggings", "legs cloth", "Zarmok's Plated Signet", "finger" } },
		{ "War Handler Ashka", { "Bloodied Gutslicer", "2h sword", "War Handler's Gaze", "head leather", "Worgbinder's Treads", "feet plate" } },
		{ "Bossman Toof (rare)", { "Band of Bossman", "finger", "Big-Belly Belt", "waist cloth", "Toofbreaker", "1h mace" } },
		{ "Nar'gurk", { "Chain of the Corruptor", "neck", "Krol'dok Warplate Chest", "chest plate", "Krol'dok Warplate Helmet", "head plate" } },
		{ "Overlord Mugg", { "Mugg's Jabber", "fist", "Mugg's Crosser", "fist", "Emblem of Slamming", "trinket", "Strongly Scented Hood", "head cloth" } },
		{ "Trash", { "Krol'dok Warplate Legplates", "legs plate" } },
		{ "Quest rewards", { "Bigger Rock on Bigger Stick", "2h mace", "Rock on Stick", "1h mace", "Stick No Rock", "2h staff",
			"Curio-Adorned Necklace", "neck", "Twilight Initiate's Belt", "waist leather", "Torn Cultist Cloak", "back",
			"Indoctrinated Choker", "neck", "Convert's Bindings", "wrist cloth", "Semblance of Twilight", "neck" } },
	} },
	{ "Alcaz Prison", 48, 53, {
		{ "Tidemistress Ca'zass", { "Tidesong Wand", "wand", "Seascale Bracers", "wrist mail", "Cloak of the Tidemistress", "back" } },
		{ "Overseer Wrex", { "Alcaz Willcrusher", "2h mace", "Grips of Control", "hands plate", "Wrex's Pinky Ring", "finger" } },
		{ "Katerina the Cleaner", { "Katerina's Shanker", "1h dagger", "Cutthroat Chestguard", "chest mail", "Sentimental Locket", "neck" } },
		{ "Zarla Ober", {} },
		{ "The Questioner", { "Defias Enforcer's Shoulderpads", "shoulder leather", "Girdle of Extracted Answers", "waist plate", "Fingerbreaker Stamp", "trinket" } },
		{ "Quest rewards", { "Theramore Defender's Gauntlets", "hands plate", "Marshdweller's Pants", "legs cloth", "Naga Scale Spaulders", "shoulder mail",
			"Kor'kron Battle Gauntlets", "hands plate", "Bloodsplattered Bandana", "head leather", "Makeshift Belt", "waist cloth",
			"Dustwallow Dirk", "1h dagger", "Fatebound Buckler", "shield", "Courier's Clasp", "neck" } },
	} },
	{ "Blackmaw Hold", 55, 60, {
		{ "Withermaw", { "Cloak of the Fleshborer", "back", "Bloodfur Bulwark", "shield", "Withering Grips", "hands leather" } },
		{ "Bonesnout the Unbroken", { "Tuskblade Halberd", "2h polearm", "Lucky Shovelnose Tuft", "trinket", "Spike Crested Bracers", "wrist plate" } },
		{ "Moontouched Wanderer", { "Lunarlight Robe", "chest leather", "Claymore of Two Moons", "2h sword" } },
		{ "Impaan the Imprisoner", { "Flameslash Crescent", "2h axe", "Robes of Dark Summons", "chest cloth", "Impish Chain Hood", "head mail" } },
		{ "Unbound Spirit", { "Flamebreak Talisman", "trinket", "Cowl of Dark Ambition", "head cloth", "Burnished Pridescales", "chest plate" } },
		{ "Blackmaw Behemoth", { "Behemoth Bones", "trinket", "Trousers of the Ebon Giant", "legs cloth", "Blackmaw Chain Belt", "waist mail" } },
		{ "Varrox Bleakhoof", { "Scalding Flamehoof", "trinket", "Bleak Eye Shoulderplates", "shoulder plate", "Horns of Varrox", "head leather" } },
		{ "Elder Shaman Bloodmane", { "Bloody Claws of Attack", "fist", "Veilpiercer Girdle", "waist leather" } },
		{ "Quest rewards", { "Nama's Cherished Necklace", "neck", "Great Bear Claw", "fist", "Staff of Wild Beasts", "2h staff", "Wild Malleus", "2h mace",
			"Guidance of Ursoc", "back", "Wisdom of Ursol", "back", "Ouroboros Ring", "finger", "Eagle's Head Signet", "finger",
			"Malefactor's End", "finger", "Engraved Band", "finger" } },
	} },
	{ "Shaper's Terrace", 58, 60, {} },
}

-- item numbers and required levels already published (forg.gg): these start as the real item, not a stand-in.
-- { item number, required level (0: the game fills it in), quality (2 green, default 3 blue) }
local KNOWN = {
	-- Hall of Thanes
	["Ephemeral Choker"] = { 270227, 13 }, ["Aetherwisp Bracers"] = { 271096, 13 }, ["Spiritwraith Drape"] = { 271097, 13 },
	["Kindlegem Girdle"] = { 270230, 13 }, ["Flamefist Grips"] = { 270231, 13 }, ["Fang of Magmatus"] = { 271095, 13 },
	["Golemheart Stave"] = { 270228, 13 }, ["Golemguard Chest"] = { 271098, 13 }, ["Treads of the Protector Golem"] = { 270229, 13 },
	["Durgen's Crescent Axe"] = { 270256, 13 }, ["Direhammer Leggings"] = { 270260, 13 }, ["Robes of the Disgraced Thane"] = { 270261, 13 },
	["Catacomb Cloak"] = { 279899, 0, 2 }, ["Deepgrave Trousers"] = { 279900, 0, 2 }, ["Dwarven Tome"] = { 279898, 0, 2 }, ["Tomb Robber's Gloves"] = { 280096, 0, 2 },
	["Calibrated Blunderbuss"] = { 279894, 0, 2 }, ["Ironforge Greathammer"] = { 279895, 0, 2 }, ["Deepblaze"] = { 279896, 0, 2 },
	["Dusty Belt"] = { 279897, 0, 2 }, ["Cryptwalker Bracers"] = { 280095, 0, 2 },
	-- Ruins of Lordaeron
	["Atrophic Girdle"] = { 271201, 15 }, ["Witherbite Bracers"] = { 271202, 15 }, ["Segmented Spider Leg"] = { 271203, 15 },
	["Meathook Slicer"] = { 271204, 15 }, ["Abomination Bones"] = { 271205, 15 }, ["Leftover Abomination Skin"] = { 271206, 15 },
	["Vilewalkers"] = { 271211, 17 }, ["Bloodied Chestwraps"] = { 271212, 17 }, ["Vileblood Scimitar"] = { 271218, 17 },
	["Rotmender's Leggings"] = { 271207, 17 }, ["Grip of Fear"] = { 271208, 17 }, ["Scepter of the Abandoned"] = { 271216, 17 },
	["Bonerust Leggings"] = { 271209, 16 }, ["Tuskwrap Belt"] = { 271210, 16 }, ["Corpse Chopper"] = { 271217, 16 },
	["Mirror of Rath'mael"] = { 271213, 19 }, ["Rotmender's Treads"] = { 271214, 19 }, ["Coldspire Staff"] = { 271215, 19 },
	["Haunting Blade"] = { 6641, 22 }, ["Phantom Armor"] = { 6642, 22 },
	["Monstrous Cleaver"] = { 279864, 0, 2 }, ["Grave Shroud"] = { 279865, 0, 2 }, ["Slain Baron's Signet"] = { 279867, 0, 2 },
	["Duty Bound Leggings"] = { 279868, 0, 2 }, ["Remembrance Armor"] = { 279869, 0, 2 }, ["Tarnished Locket"] = { 279870, 0, 2 },
	["Forsaken Greataxe"] = { 251533, 0, 2 }, ["Gnarled Necromancer's Staff"] = { 251534, 0, 2 }, ["The Stitcher"] = { 279874, 0, 2 },
	["Spare Part Bindings"] = { 279875, 0, 2 }, ["Edward's Knife"] = { 251485, 0, 2 }, ["Tabitha's Cuffs"] = { 251486, 0, 2 },
	["Plaguefang"] = { 279876, 0, 2 }, ["Blight Gloves"] = { 279877, 0, 2 },
	-- Excavation Site: Wetlands
	["Supple Bellyskin Leggings"] = { 273022, 26 }, ["Saltscale Girdle"] = { 273023, 26 }, ["Glinteye Slippers"] = { 273024, 26 },
	["Raptorclaw Greaves"] = { 273025, 26 }, ["Garb of Florid Feathers"] = { 273026, 26 }, ["Raptor's Gaze"] = { 273027, 26 },
	["Reliquary Mantle"] = { 273028, 28 }, ["Golemsight Long Gun"] = { 273029, 28 }, ["Ring of Power Regulation"] = { 273030, 28 },
	["Daewyn's Girdle"] = { 271769, 0, 2 }, ["Songblade Stabilizer"] = { 271768, 0, 2 }, ["Explorer's League Dustcover"] = { 271716, 0, 2 },
	["Healer's Staff"] = { 271767, 0, 2 }, ["Heavehammer"] = { 271766, 0, 2 }, ["Ironwood Destroyer"] = { 271667, 0, 2 }, ["Curl of Life"] = { 271670, 0, 2 },
	["Hornbeam Heft"] = { 271664, 0, 2 }, ["Satchel of Potions"] = { 280766, 0, 2 }, ["Serrated Raptor Claw"] = { 280805, 0, 2 },
	["Furs of the Earthen Ring"] = { 271719, 0, 2 }, ["Knife-Polishing Rag"] = { 271740, 0, 2 }, ["Dirt-Heavy Bracers"] = { 271732, 0, 2 },
	-- City of Dalaran
	["Graveweave Bindings"] = { 273036, 26 }, ["Bonebinder's Signet"] = { 273032, 25 }, ["Gravespike Repeater"] = { 273033, 26 },
	["Cartilage Shapers"] = { 273054, 28 }, ["Tendonscraper Dagger"] = { 273053, 28 }, ["Bonepile Gaze"] = { 273055, 28 },
	["Runemender's Seal"] = { 273031, 27 }, ["Ephemeral Grips"] = { 273034, 27 }, ["Mana-Warped Chain Shirt"] = { 273035, 27 },
	["Drape of Shifting Energy"] = { 273045, 27 }, ["Violet Sorcerer's Robes"] = { 273044, 27 }, ["Wand of Mana Concentration"] = { 273043, 27 },
	["Guardian's Dualblade"] = { 273046, 28 }, ["Refractory Scaleguards"] = { 273048, 28 }, ["Unstable Crystalline Shoulderpads"] = { 273047, 28 },
	["Spine of the Devourer"] = { 273040, 28 }, ["Manascale Treads"] = { 273042, 28 }, ["Slitherwrap Girdle"] = { 273041, 28 },
	["Blightleaf Rope"] = { 273039, 29 }, ["Garb of Fallen Felbark"] = { 273038, 29 }, ["Felbough Arm"] = { 273037, 29 },
	["Ponderous Orb"] = { 273052, 30 }, ["Violet Sorcerer's Mantle"] = { 273051, 30 }, ["Archmagister's Faceted Pendant"] = { 273049, 30 },
	["Spellguard Pauldrons"] = { 279839, 0, 2 }, ["Renewing Footpads"] = { 279840, 0, 2 }, ["Defender of Dalaran"] = { 279841, 0, 2 },
	["Fallen Guard's Pendant"] = { 279837, 0, 2 }, ["Arcane Infused Rod"] = { 279838, 0, 2 }, ["Violet Sash"] = { 251962, 0, 2 },
	["Runebound Gloves"] = { 279849, 0, 2 }, ["Vine Pruner's Cloak"] = { 279835, 0, 2 }, ["Thorn Protecting Girdle"] = { 279836, 0, 2 },
	["Battle Spaulders"] = { 279842, 0, 2 }, ["Enchanted Sandals"] = { 279843, 0, 2 }, ["Striking Staff"] = { 279844, 0, 2 },
	["Gravewalker Boots"] = { 251963, 0, 2 }, ["Undead Knight's Bracers"] = { 251965, 0, 2 }, ["Unstable Power Core"] = { 279847, 0, 2 },
	["Construct Cloak"] = { 279848, 0, 2 }, ["Solid Gold Band"] = { 279845, 0, 2 }, ["Larcenist's Belt"] = { 279846, 0, 2 },
	-- Krol'dok Stronghold
	["Slavecrusher Scepter"] = { 274995, 39 }, ["Resistance Breaker Spaulder"] = { 274996, 39 }, ["Chain of Binding"] = { 274997, 39 },
	["Shadowlight Athame"] = { 274998, 40 }, ["Shadecaster's Leggings"] = { 274999, 40 }, ["Zarmok's Plated Signet"] = { 275000, 40 },
	["Bloodied Gutslicer"] = { 275001, 40 }, ["War Handler's Gaze"] = { 275002, 40 }, ["Worgbinder's Treads"] = { 275003, 40 },
	["Band of Bossman"] = { 286428, 40 }, ["Big-Belly Belt"] = { 286429, 40 }, ["Toofbreaker"] = { 286430, 40 },
	["Chain of the Corruptor"] = { 275004, 41 }, ["Krol'dok Warplate Chest"] = { 275005, 41 }, ["Krol'dok Warplate Helmet"] = { 275006, 41 },
	["Mugg's Jabber"] = { 275007, 42 }, ["Mugg's Crosser"] = { 275008, 42 }, ["Emblem of Slamming"] = { 275009, 42 }, ["Strongly Scented Hood"] = { 275010, 42 },
	["Rock on Stick"] = { 279852, 0, 2 }, ["Stick No Rock"] = { 279853, 0, 2 }, ["Bigger Rock on Bigger Stick"] = { 279480, 0, 2 },
	["Curio-Adorned Necklace"] = { 279850, 0, 2 }, ["Twilight Initiate's Belt"] = { 279854, 0, 2 }, ["Torn Cultist Cloak"] = { 279855, 0, 2 },
	["Indoctrinated Choker"] = { 279859, 0, 2 }, ["Convert's Bindings"] = { 279860, 0, 2 }, ["Semblance of Twilight"] = { 267090, 0, 2 },
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
				local kn = KNOWN[name]
				if kn then id = kn[1] else id = nextID; nextID = nextID - 1 end
				-- { inventoryType, class*100+subclass, requiredLevel, quality, classMask, name, source } (dungeon blues until the game says)
				-- (quest rewards: greens until the game says; an item the Classic data already has is left as it is)
				if not D.items[id] then
					D.items[id] = { k[1], k[2], kn and kn[2] or 0, (kn and kn[3]) or (b[1] == "Quest rewards" and 2) or 3, 0, name, forever = kn and true or nil }
				end
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
