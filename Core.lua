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

function P.Me() return GetRealmName() or "", (GetUnitName and GetUnitName("player", false) or UnitName("player")) or "" end
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
  if not (S and S.Upgrade) or not id or id <= 0 or not P.IsGear(id) or not P.Usable(id) then return nil end
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
  if P.OnWishChanged then pcall(P.OnWishChanged, P.CK(), id) end
end
-- the same for any character on the account ("Realm.Name") - Pint's Alts shows and edits wishlists through these,
-- so there's one wishlist, kept here, and both add-ons show it
function P.IsWishedFor(ck, id) local w = PintsLootDB and PintsLootDB.wish and PintsLootDB.wish[ck]; return w and w[id] ~= nil or false end
function P.ToggleWishFor(ck, id, src)
  if not ck or not id or id == 0 then return end
  local w = P.Wish(ck)
  if w[id] then w[id] = nil else
    if not src then local list = P.Sources(id); src = list and list[1] end
    w[id] = { src = src, t = time() }
  end
  if P.OnChanged then P.OnChanged() end
  if P.OnWishChanged then pcall(P.OnWishChanged, ck, id) end
end
function P.WishList(ck)
  local out = {}
  for id, e in pairs(PintsLootDB and PintsLootDB.wish and PintsLootDB.wish[ck] or {}) do out[#out + 1] = { id = id, src = e.src, t = e.t } end
  return out
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

---------------------------------------------------------------- learning item numbers (WoW Forever's new dungeons)
-- Those items start as stand-ins named from the loot sites (ForeverData.lua). When the game shows you the real item -
-- a loot window, a chat link, a tooltip - its number is learned (and kept), and the stand-in becomes the real item:
-- icon, tooltip, upgrade %, owners and wishlist then all work.
local F = _G.PintsLootForever
local function Refine(id)
  local it = D.items[id]
  if not it then return end
  local name, _, q, _, req, _, _, _, _, _, _, cls, sub = GetItemInfo(id)
  if not name then
    if C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, id) end
    return
  end
  it[4] = q or it[4]; it[3] = req or it[3]
  if cls and sub then it[2] = cls * 100 + sub end
  local inv = C_Item and C_Item.GetItemInventoryTypeByID and C_Item.GetItemInventoryTypeByID(id)
  if type(inv) == "number" then it[1] = inv end
  it.refined = true
end
local function Replace(syn, real)
  for _, page in ipairs(F.pages) do
    for _, g in ipairs(page[3]) do
      local l = g[4]
      for x = 1, #l, 2 do if l[x] == syn then l[x] = real end end
    end
  end
  if not D.items[real] then local t = D.items[syn]; D.items[real] = { t[1], t[2], t[3], t[4], t[5], t[6], forever = true } end
  F.byName[F.names[syn]] = real
  srcIndex = nil; wipe(upCache)
end
function P.Learn(id, name)
  if not F or type(id) ~= "number" or id <= 0 or type(name) ~= "string" then return end
  if issecretvalue and (issecretvalue(id) or issecretvalue(name)) then return end
  local syn = F.byName[name]
  if not syn or syn > 0 then return end
  PintsLootDB.learned = PintsLootDB.learned or {}
  PintsLootDB.learned[name] = id
  Replace(syn, id); Refine(id)
  if NS.Refresh then pcall(NS.Refresh) end
end
local function LearnText(msg)
  if type(msg) ~= "string" or (issecretvalue and issecretvalue(msg)) then return end
  for id, name in msg:gmatch("|Hitem:(%d+)[^|]*|h%[(.-)%]|h") do P.Learn(tonumber(id), name) end
end
P.LearnText = LearnText
-- the ones the game already knows by name (seen this session or before)
local function LearnByName()
  if not F then return end
  for name, id in pairs(F.byName) do
    if id < 0 then local _, link = GetItemInfo(name); if link then LearnText(link) end end
  end
end
if F then
  local lf = CreateFrame("Frame")
  for _, e in ipairs({ "CHAT_MSG_LOOT", "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER", "CHAT_MSG_PARTY",
      "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_WHISPER",
      "CHAT_MSG_CHANNEL", "LOOT_OPENED", "GET_ITEM_INFO_RECEIVED", "PLAYER_LOGIN" }) do pcall(lf.RegisterEvent, lf, e) end
  lf:SetScript("OnEvent", function(_, e, a1)
    if e == "LOOT_OPENED" then
      for i = 1, (GetNumLootItems and GetNumLootItems()) or 0 do LearnText(GetLootSlotLink and GetLootSlotLink(i)) end
    elseif e == "GET_ITEM_INFO_RECEIVED" then
      local it = type(a1) == "number" and D.items[a1]
      if it and it.forever and not it.refined then Refine(a1); if NS.Refresh then pcall(NS.Refresh) end end
    elseif e == "PLAYER_LOGIN" then
      C_Timer.After(8, LearnByName)
    else
      LearnText(a1)
    end
  end)
  -- any item tooltip you look at
  if TooltipDataProcessor and Enum and Enum.TooltipDataType then
    pcall(TooltipDataProcessor.AddTooltipPostCall, Enum.TooltipDataType.Item, function(tt)
      if not tt.GetItem then return end
      local ok, name, link = pcall(tt.GetItem, tt)
      if ok then LearnText(link) end
    end)
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
    -- item numbers learned before (WoW Forever's new dungeons)
    if F then
      db.learned = db.learned or {}
      for name, id in pairs(db.learned) do
        local syn = F.byName[name]
        if syn and syn < 0 then Replace(syn, id); D.items[id].forever = true end
      end
    end
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

---------------------------------------------------------------- sharing a wishlist with another player
-- Sent like a whisper, but as hidden add-on messages: the other player needs Pint's Loot, and is asked before it's kept.
-- No answer within a few seconds (they don't have it): you're offered to whisper the items as plain item links instead.
--   H:<token>:<count>:<owner>   I:<token>:<id,id,...>   E:<token>   (and back: A:<token> = got it, N:<token> = declined)
local PREFIX = "PintsLoot"
local SendAddon = (C_ChatInfo and C_ChatInfo.SendAddonMessage) or SendAddonMessage
local SendChat = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage
if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
elseif RegisterAddonMessagePrefix then RegisterAddonMessagePrefix(PREFIX) end
local GOLD = "|cffd4a017Pint's Loot:|r "
local function Short(name) return ((name or ""):gsub("%-.*$", "")):lower() end
local outgoing, incoming = {}, {}

-- the whispered fallback: the items as links, a few per line
local function WhisperLinks(target, ids, owner)
  SendChat(("%s's wishlist (Pint's Loot):"):format(owner), "WHISPER", nil, target)
  local line = ""
  for _, id in ipairs(ids) do
    local _, link = GetItemInfo(id)
    link = link or ("[item " .. id .. "]")
    if #line + #link + 1 > 240 then SendChat(line, "WHISPER", nil, target); line = "" end
    line = line .. (line ~= "" and " " or "") .. link
  end
  if line ~= "" then SendChat(line, "WHISPER", nil, target) end
end

function P.ShareWish(ck, target)
  target = (target or ""):gsub("^%s+", ""):gsub("%s+$", "")
  if target == "" then return end
  local ids = {}
  for id in pairs(PintsLootDB.wish[ck] or {}) do ids[#ids + 1] = id end
  table.sort(ids)
  local owner = (ck or ""):match("%.(.+)$") or "?"
  if #ids == 0 then print(GOLD .. owner .. "'s wishlist is empty - nothing to share."); return end
  local tok = tostring(math.random(10000, 99999))
  SendAddon(PREFIX, ("H:%s:%d:%s"):format(tok, #ids, owner), "WHISPER", target)
  local chunk = {}
  local function flush() if #chunk > 0 then SendAddon(PREFIX, "I:" .. tok .. ":" .. table.concat(chunk, ","), "WHISPER", target); chunk = {} end end
  for _, id in ipairs(ids) do chunk[#chunk + 1] = id; if #chunk >= 30 then flush() end end
  flush()
  SendAddon(PREFIX, "E:" .. tok, "WHISPER", target)
  for _, id in ipairs(ids) do if C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end end
  local o = { tok = tok, target = target, ids = ids, owner = owner }
  outgoing[Short(target)] = o
  print(GOLD .. ("sending %s's wishlist (%d items) to %s..."):format(owner, #ids, target))
  C_Timer.After(5, function()
    if outgoing[Short(target)] ~= o or o.answered then return end
    outgoing[Short(target)] = nil
    StaticPopup_Show("PINTSLOOT_SHARE_NOADDON", target, nil, o)
  end)
end

-- ask who to send it to (your target's name filled in)
function P.AskShare(ck)
  ck = ck or P.CK()
  local who = UnitIsPlayer("target") and UnitIsFriend("player", "target") and GetUnitName("target", true) or ""
  local d = StaticPopup_Show("PINTSLOOT_SHARE_OUT", ck:match("%.(.+)$") or "", nil, { ck = ck })
  if d then
    local eb = d.editBox or (d.GetEditBox and d:GetEditBox())
    if eb then eb:SetText(who); eb:HighlightText() end
  end
end

local function PopupEdit(self) return self.editBox or (self.GetEditBox and self:GetEditBox()) end
StaticPopupDialogs["PINTSLOOT_SHARE_OUT"] = {
  text = "Share %s's wishlist with which player?\n|cff909090(they need Pint's Loot - or it can go as item links)|r",
  button1 = "Send", button2 = CANCEL or "Cancel", hasEditBox = true, maxLetters = 60,
  OnAccept = function(self, data) P.ShareWish(data.ck, PopupEdit(self):GetText()) end,
  EditBoxOnEnterPressed = function(self) local p = self:GetParent(); P.ShareWish(p.data.ck, self:GetText()); p:Hide() end,
  EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
  timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}
StaticPopupDialogs["PINTSLOOT_SHARE_NOADDON"] = {
  text = "%s didn't answer - they may not have Pint's Loot.\nWhisper the wishlist to them as item links instead?",
  button1 = "Whisper links", button2 = CANCEL or "Cancel",
  OnAccept = function(self, o) WhisperLinks(o.target, o.ids, o.owner) end,
  timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}
StaticPopupDialogs["PINTSLOOT_SHARE_IN"] = {
  text = "%s wants to share %s with you.\nKeep it in your Pint's Loot wishlist tab?",
  button1 = "Keep it", button2 = "No thanks",
  OnAccept = function(self, x)
    PintsLootDB.shared = PintsLootDB.shared or {}
    PintsLootDB.shared[x.from] = { owner = x.owner, ids = x.ids, t = time() }
    SendAddon(PREFIX, "A:" .. x.tok, "WHISPER", x.from)
    if P.OnChanged then P.OnChanged() end
    if P.Toggle then P.Toggle("wish") end
  end,
  OnCancel = function(self, x) SendAddon(PREFIX, "N:" .. x.tok, "WHISPER", x.from) end,
  timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

-- lists other players shared with you: { {from, owner, ids, t}, ... }
function P.SharedLists()
  local out = {}
  for from, s in pairs(PintsLootDB and PintsLootDB.shared or {}) do out[#out + 1] = { from = from, owner = s.owner, ids = s.ids or {}, t = s.t } end
  table.sort(out, function(a, b) return (a.t or 0) > (b.t or 0) end)
  return out
end
function P.ForgetShared(from)
  if PintsLootDB.shared then PintsLootDB.shared[from] = nil end
  if P.OnChanged then P.OnChanged() end
end

local msgEv = CreateFrame("Frame")
msgEv:RegisterEvent("CHAT_MSG_ADDON")
msgEv:SetScript("OnEvent", function(_, _, prefix, msg, channel, sender)
  if prefix ~= PREFIX or channel ~= "WHISPER" or type(msg) ~= "string" then return end
  local kind, tok, rest = msg:match("^(%u):(%d+):?(.*)$")
  if not kind then return end
  if kind == "H" then
    local n, owner = rest:match("^(%d+):(.+)$")
    incoming[sender] = { tok = tok, n = tonumber(n) or 0, owner = owner or "?", ids = {} }
  elseif kind == "I" then
    local x = incoming[sender]
    if x and x.tok == tok then
      for id in rest:gmatch("%d+") do if #x.ids < 300 then x.ids[#x.ids + 1] = tonumber(id) end end
    end
  elseif kind == "E" then
    local x = incoming[sender]
    incoming[sender] = nil
    if x and x.tok == tok and #x.ids > 0 then
      x.from = sender
      SendAddon(PREFIX, "R:" .. tok, "WHISPER", sender)      -- (arrived: they have Pint's Loot, now they decide)
      for _, id in ipairs(x.ids) do if C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end end
      local what = (Short(x.owner) == Short(sender)) and ("their wishlist (" .. #x.ids .. " items)")
        or (x.owner .. "'s wishlist (" .. #x.ids .. " items)")
      StaticPopup_Show("PINTSLOOT_SHARE_IN", (sender:gsub("%-.*$", "")), what, x)
    end
  elseif kind == "R" then
    local o = outgoing[Short(sender)]
    if o and o.tok == tok then o.answered = true; print(GOLD .. (sender:gsub("%-.*$", "")) .. " got it - waiting for them to accept.") end
  elseif kind == "A" or kind == "N" then
    local o = outgoing[Short(sender)]
    if o and o.tok == tok then
      outgoing[Short(sender)] = nil
      print(GOLD .. (sender:gsub("%-.*$", "")) .. (kind == "A" and " has your wishlist now." or " said no thanks."))
    end
  end
end)
