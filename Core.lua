-- Pints Loot: shared helpers - who can use what, what your characters own, the wishlist, upgrade scores
-- and "where does this drop" lookups for item tooltips.
local ADDON, NS = ...
-- Compatibility: WoW Forever runs on the modern game client, where these older functions moved or were renamed.
local GetItemInfo = GetItemInfo or (C_Item and C_Item.GetItemInfo)

local P = {}
NS.P = P
_G.PintsLoot = P

local D = PintsLootData or { cats = {}, items = {} }
P.D, P.ITEMS = D, D.items

function P.Me() return GetRealmName() or "", UnitName("player") or "" end
function P.CK() local r, n = P.Me(); return r .. "." .. n end
function P.Faction() local f = UnitFactionGroup("player"); return f == "Horde" and 1 or 2 end

---------------------------------------------------------------- usable gear
local WEAPONS = {
  WARRIOR = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 13, 15, 16, 18 }, PALADIN = { 0, 1, 4, 5, 6, 7, 8 },
  HUNTER = { 0, 1, 2, 3, 6, 7, 8, 10, 13, 15, 16, 18 }, ROGUE = { 2, 3, 4, 7, 13, 15, 16, 18 }, PRIEST = { 4, 10, 15, 19 },
  SHAMAN = { 0, 1, 4, 5, 10, 13, 15 }, MAGE = { 7, 10, 15, 19 }, WARLOCK = { 7, 10, 15, 19 }, DRUID = { 4, 5, 10, 13, 15 },
}
local ARMOR = {
  WARRIOR = { 0, 1, 2, 3, 4, 6 }, PALADIN = { 0, 1, 2, 3, 4, 6, 7 }, HUNTER = { 0, 1, 2, 3 }, ROGUE = { 0, 1, 2 },
  PRIEST = { 0, 1 }, SHAMAN = { 0, 1, 2, 3, 6, 9 }, MAGE = { 0, 1 }, WARLOCK = { 0, 1 }, DRUID = { 0, 1, 2, 8 },
}
local can
local function Can()
  if can then return can end
  local _, cls, cid = UnitClass("player")
  can = { bit = cid and 2 ^ (cid - 1) or 0, w = { [14] = true, [20] = true }, a = {} }
  for _, s in ipairs(WEAPONS[cls] or {}) do can.w[s] = true end
  for _, s in ipairs(ARMOR[cls] or {}) do can.a[s] = true end
  return can
end
-- this class may wear or wield it (a level requirement doesn't count against it); non-gear is always "usable"
function P.Usable(id)
  local it = P.ITEMS[id]; if not it then return true end
  local c = Can()
  local mask = it[5]
  if mask and mask > 0 and c.bit > 0 and math.floor(mask / c.bit) % 2 == 0 then return false end
  local cls, sub = math.floor(it[2] / 100), it[2] % 100
  if cls == 2 then return c.w[sub] == true end
  if cls == 4 then return c.a[sub] == true end
  return true
end
function P.IsGear(id)
  local it = P.ITEMS[id]; if not it then return false end
  local cls = math.floor(it[2] / 100)
  return (cls == 2 or cls == 4) and it[1] > 0
end

local SLOT = { [1] = "Head", [2] = "Neck", [3] = "Shoulder", [4] = "Shirt", [5] = "Chest", [6] = "Waist", [7] = "Legs", [8] = "Feet",
  [9] = "Wrist", [10] = "Hands", [11] = "Finger", [12] = "Trinket", [13] = "One-Hand", [14] = "Shield", [15] = "Ranged", [16] = "Back",
  [17] = "Two-Hand", [18] = "Bag", [19] = "Tabard", [20] = "Chest", [21] = "Main Hand", [22] = "Off Hand", [23] = "Held In Off-hand",
  [25] = "Thrown", [26] = "Ranged", [28] = "Relic" }
local WSUB = { [0] = "Axe", [1] = "Axe", [2] = "Bow", [3] = "Gun", [4] = "Mace", [5] = "Mace", [6] = "Polearm", [7] = "Sword", [8] = "Sword",
  [10] = "Staff", [13] = "Fist Weapon", [14] = "", [15] = "Dagger", [16] = "Thrown", [18] = "Crossbow", [19] = "Wand", [20] = "Fishing Pole" }
local ASUB = { [1] = "Cloth", [2] = "Leather", [3] = "Mail", [4] = "Plate", [6] = "", [7] = "Libram", [8] = "Idol", [9] = "Totem" }
local OTHER = { [0] = "Consumable", [1] = "Bag", [5] = "Reagent", [7] = "Trade Goods", [9] = "Recipe", [12] = "Quest", [15] = "Miscellaneous" }
function P.Kind(id)
  local it = P.ITEMS[id]; if not it then return "" end
  local cls, sub, inv = math.floor(it[2] / 100), it[2] % 100, it[1]
  if cls == 2 then
    local w = WSUB[sub] or ""
    if inv == 17 and w ~= "" and sub ~= 10 and sub ~= 6 then return "Two-Hand " .. w end
    if inv == 15 or inv == 26 or inv == 25 or sub == 10 or sub == 6 then return w end
    return (SLOT[inv] or "") .. (w ~= "" and (" " .. w) or "")
  elseif cls == 4 then
    local a = ASUB[sub]
    if a and a ~= "" and inv ~= 16 then return a .. " " .. (SLOT[inv] or "") end
    return SLOT[inv] or "Armor"
  end
  if cls == 15 and sub == 5 then return "Mount" end
  return OTHER[cls] or ""
end

---------------------------------------------------------------- your characters (needs Pints Ledger)
-- who on this realm has it: { {name, classFile, where}, ... }
function P.Owners(id)
  local L = _G.PintsLedger
  if not (L and L.Characters) then return nil end
  local out = {}
  for _, ch in ipairs(L.Characters()) do
    local rec, where = ch.rec, nil
    local it = rec.items or {}
    for s = 1, 19 do
      local link = rec.gear and rec.gear[s]
      if link and tonumber(link:match("item:(%d+)")) == id then where = "worn" end
    end
    if not where then
      if it.bags and it.bags[id] then where = "bags"
      elseif it.bank and it.bank[id] then where = "bank"
      elseif it.mail and it.mail[id] then where = "mail" end
    end
    if where then out[#out + 1] = { ch.name, rec.classFile, where } end
  end
  return out
end
-- who on this realm can craft it: { {name, classFile, profession}, ... }
function P.Crafters(id)
  local L = _G.PintsLedger
  if not (L and L.Characters) or not id or id == 0 then return nil end
  local out = {}
  for _, ch in ipairs(L.Characters()) do
    for prof, list in pairs(ch.rec.crafts or {}) do
      if list[id] then out[#out + 1] = { ch.name, ch.rec.classFile, prof } end
    end
  end
  return out
end
function P.HasLedger() return _G.PintsLedger and _G.PintsLedger.Characters and true or false end

---------------------------------------------------------------- upgrades (needs Craft Upgrades' scoring)
local upCache = {}
function P.Upgrade(id)
  local S = _G.CraftUpgradesScore
  if not (S and S.Upgrade) or not P.IsGear(id) or not P.Usable(id) then return nil end
  if upCache[id] ~= nil then return upCache[id][1], upCache[id][2] end
  local _, link = GetItemInfo(id)
  if not link then
    if C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
    return nil
  end
  local ok, pct, empty = pcall(S.Upgrade, link)
  if not ok then pct, empty = nil, nil end
  upCache[id] = { pct, empty }
  return pct, empty
end
function P.ClearUpgrades() wipe(upCache) end

---------------------------------------------------------------- wishlist
-- PintsLootDB.wish[realm.name] = { [itemID] = { src = "Ragnaros - Molten Core", t = time } }
function P.Wish(ck) local w = PintsLootDB.wish; w[ck or P.CK()] = w[ck or P.CK()] or {}; return w[ck or P.CK()] end
function P.IsWished(id) return P.Wish()[id] ~= nil end
function P.ToggleWish(id, src)
  if not id or id == 0 then return end
  local w = P.Wish()
  if w[id] then w[id] = nil else w[id] = { src = src, t = time() } end
  if P.OnChanged then P.OnChanged() end
end
-- every character that wants it: { "Name", ... }
function P.WishedBy(id)
  local out, realm = {}, (P.Me())
  for ck, list in pairs(PintsLootDB.wish or {}) do
    if list[id] then
      local r, n = ck:match("^(.-)%.(.+)$")
      if r == realm then out[#out + 1] = n end
    end
  end
  return out
end

---------------------------------------------------------------- where does it come from
local srcIndex
local function Index()
  srcIndex = {}
  for _, cat in ipairs(D.cats) do
    for _, page in ipairs(cat[2]) do
      for _, g in ipairs(page[3]) do
        local kind, list = g[2], g[4]
        local step = (kind == 2) and 5 or 2
        for x = 1, #list, step do
          local id, txt = list[x], nil
          if kind == 1 then
            local ch = list[x + 1]
            txt = (g[1] == page[1] and page[1] or (g[1] .. ", " .. page[1])) .. ((ch and ch > 0) and (" (" .. ch .. "%)") or "")
            if cat[1] == "World Drops" and page[1] == "World Epics" then txt = "World drop (" .. g[1] .. ")" end
          elseif kind == 3 then
            txt = page[1] .. " vendor" .. ((g[1] ~= "No reputation needed" and not g[1]:find("^Rank")) and (", " .. g[1]) or "")
          elseif kind == 4 and cat[1] == "Factions" then
            txt = page[1] .. " (" .. g[1] .. ")"
          elseif kind == 2 then
            id = list[x + 1]
            if id and id > 0 then txt = "Crafted: " .. page[1] .. " (" .. list[x + 2] .. ")" end
          end
          if id and id > 0 and txt then
            srcIndex[id] = srcIndex[id] or {}
            if #srcIndex[id] < 3 then table.insert(srcIndex[id], txt) end
          end
        end
      end
    end
  end
end
function P.Sources(id)
  if not srcIndex then Index() end
  return srcIndex[id]
end

-- tooltips everywhere: where it drops and who wants it
local function OnTip(tt)
  if not (PintsLootDB and PintsLootDB.tooltips ~= false) then return end
  local _, link = tt:GetItem()
  local id = link and tonumber(link:match("item:(%d+)"))
  if not id then return end
  local src = P.Sources(id)
  if src then for _, s in ipairs(src) do tt:AddLine("|cffd4a24cPint's Loot:|r " .. s, 0.85, 0.85, 0.85) end end
  local who = P.WishedBy(id)
  if #who > 0 then tt:AddLine("|cffd4a24cWishlist:|r " .. table.concat(who, ", "), 1, 0.82, 0) end
  if src or #who > 0 then tt:Show() end
end
local hooked
function P.HookTooltips()
  if hooked then return end
  hooked = true
  for _, tt in ipairs({ GameTooltip, ItemRefTooltip }) do
    if tt and tt.HookScript then pcall(tt.HookScript, tt, "OnTooltipSetItem", OnTip) end
  end
end

---------------------------------------------------------------- saved data
local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED"); ev:RegisterEvent("PLAYER_EQUIPMENT_CHANGED"); ev:RegisterEvent("PLAYER_LEVEL_UP")
ev:SetScript("OnEvent", function(_, event, a1)
  if event == "ADDON_LOADED" then
    if a1 ~= ADDON then return end
    PintsLootDB = PintsLootDB or {}
    local db = PintsLootDB
    db.wish = db.wish or {}; db.ui = db.ui or {}; db.minimap = db.minimap or {}; db.classes = db.classes or {}
    if db.usable == nil then db.usable = false end
    if db.tooltips == nil then db.tooltips = true end
    P.HookTooltips()
  else
    wipe(upCache)
    if P.OnChanged then P.OnChanged() end
  end
end)
local login = CreateFrame("Frame")
login:RegisterEvent("PLAYER_LOGIN")
login:SetScript("OnEvent", function()
  local _, cls = UnitClass("player")
  PintsLootDB.classes[P.CK()] = cls
end)
