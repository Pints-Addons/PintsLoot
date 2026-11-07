-- Pints Loot: the window. Built on the Pint's Alts layout - dark panel, gold trim, a navigation column on the left,
-- sortable-looking columns on the right and tabs along the bottom.
--   top bar: category drop-down (Dungeons & Raids / Professions / PvP / World Drops) and a second drop-down for the
--            dungeon, profession, battleground or rank, or world boss; plus a search box across everything
--   left:    the bosses (or skill tiers, reputation tiers...) of the chosen page
--   right:   the items, with type, level, chance or price, upgrade %, which of your characters own it, and a wishlist star
local ADDON, NS = ...
-- coins drawn with the money icons (WoW Forever's own coin text came out as bare digits: 6s 64c showed as "664")
local GetCoinTextureString = function(v)
	v = math.floor((tonumber(v) or 0) + 0.5)
	local neg = v < 0; if neg then v = -v end
	local g, s, c = math.floor(v / 10000), math.floor(v / 100) % 100, v % 100
	local out = {}
	if g > 0 then out[#out + 1] = g .. "|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t" end
	if s > 0 then out[#out + 1] = s .. "|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t" end
	if c > 0 or #out == 0 then out[#out + 1] = c .. "|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t" end
	return (neg and "-" or "") .. table.concat(out, " ")
end
-- Compatibility: WoW Forever runs on the modern game client, where these older functions moved or were renamed.
local GetItemInfo = GetItemInfo or (C_Item and C_Item.GetItemInfo)
local GetItemIcon = GetItemIcon or (C_Item and C_Item.GetItemIconByID)
local GetSpellLink = GetSpellLink or (C_Spell and C_Spell.GetSpellLink)
local GetSpellInfo = GetSpellInfo or function(s)
	local i = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(s)
	if i then return i.name, nil, i.iconID, i.castTime, i.minRange, i.maxRange, i.spellID, i.originalIconID end
end

local P = NS.P
local D = P.D

local W, H, NAVW, ROWH = 980, 548, 170, 22
local COLS = { { "Item", 200, "LEFT" }, { "Type", 108, "LEFT" }, { "Req", 34, "CENTER" }, { "Source", 214, "RIGHT" },
  { "Upgrade", 60, "RIGHT" }, { "Owned", 76, "LEFT" }, { "", 24, "CENTER" } }
-- shrink a font string until its text fits its width (down to 8pt), else it truncates with "..."
local function FitText(fs, text)
  if not fs.baseFont then fs.baseFont, fs.baseSize, fs.baseFlags = fs:GetFont() end
  if type(fs.baseSize) ~= "number" or not fs.baseFont then fs:SetText(text); return end
  fs:SetFont(fs.baseFont, fs.baseSize, fs.baseFlags); fs:SetText(text)
  local size, w = fs.baseSize, fs:GetWidth()
  while size > 8 and fs:GetStringWidth() > w do
    size = size - 0.5; fs:SetFont(fs.baseFont, size, fs.baseFlags)
  end
end
local WISH_H = 34          -- wishlist rows are two lines tall: the boss, and the dungeon beneath
local win, rowsFrame, navFrame, sf
local rows, navRows = {}, {}
local tab = "loot"
local catIdx, pageIdx, groupIdx = 1, 1, nil
local wishSlot = nil   -- wishlist filter: nil = all slots

-- wishlist slot filter: which equip slot an item goes in, in paper-doll order
local SLOT_ORDER = { "Head", "Neck", "Shoulder", "Back", "Chest", "Shirt", "Tabard", "Wrist", "Hands", "Waist", "Legs", "Feet",
  "Finger", "Trinket", "One-Hand", "Two-Hand", "Off Hand", "Ranged", "Bag", "Other" }
local INV_SLOT = { [1] = "Head", [2] = "Neck", [3] = "Shoulder", [4] = "Shirt", [5] = "Chest", [20] = "Chest", [6] = "Waist", [7] = "Legs",
  [8] = "Feet", [9] = "Wrist", [10] = "Hands", [11] = "Finger", [12] = "Trinket", [13] = "One-Hand", [21] = "One-Hand", [17] = "Two-Hand",
  [14] = "Off Hand", [22] = "Off Hand", [23] = "Off Hand", [15] = "Ranged", [25] = "Ranged", [26] = "Ranged", [28] = "Ranged",
  [16] = "Back", [18] = "Bag", [19] = "Tabard" }
local function SlotOf(id)
  local it = id and P.ITEMS[id]
  return it and INV_SLOT[it[1]] or "Other"
end
local searchText = ""

local function db() return PintsLootDB end
local function Money(c) return (c and c > 0 and GetCoinTextureString) and GetCoinTextureString(c) or "" end
local function QColor(q)
  local c = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q or 1]
  if c then return c.r, c.g, c.b end
  return 1, 1, 1
end
local function ClassHex(cls)
  local c = RAID_CLASS_COLORS and cls and RAID_CLASS_COLORS[cls]
  return c and (c.colorStr or ("ff%02x%02x%02x"):format(c.r * 255, c.g * 255, c.b * 255)) or "ffffffff"
end
local RANKS = {
  [2] = { "Private", "Corporal", "Sergeant", "Master Sergeant", "Sergeant Major", "Knight", "Knight-Lieutenant", "Knight-Captain",
    "Knight-Champion", "Lieutenant Commander", "Commander", "Marshal", "Field Marshal", "Grand Marshal" },
  [1] = { "Scout", "Grunt", "Sergeant", "Senior Sergeant", "First Sergeant", "Stone Guard", "Blood Guard", "Legionnaire",
    "Centurion", "Champion", "Lieutenant General", "General", "Warlord", "High Warlord" },
}
local SRC = { t = "Trainer", v = "Vendor", q = "Quest", d = "Drop", w = "World drop", o = "Found" }
local function PageName(page)
  local r = page[1]:match("^Rank (%d+)$")
  if r then return "Rank " .. r .. ": " .. (RANKS[P.Faction()][tonumber(r)] or "") end
  return page[1]
end

---------------------------------------------------------------- simple drop-down menu (no Blizzard dropdown taint)
local menu
local function ShowMenu(owner, items, onPick)
  if not menu then
    menu = CreateFrame("Frame", "PintsLootMenu", UIParent, "BackdropTemplate")
    menu:SetFrameStrata("FULLSCREEN_DIALOG"); menu:EnableMouse(true); menu:SetClampedToScreen(true)
    menu:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    menu:SetBackdropColor(0.05, 0.05, 0.07, 0.97); menu:SetBackdropBorderColor(1, 0.82, 0, 0.8)
    menu.btns = {}
  end
  if menu:IsShown() and menu.owner == owner then menu:Hide(); return end
  menu.owner = owner
  local perCol, colW = 22, 240
  for i, it in ipairs(items) do
    local b = menu.btns[i]
    if not b then
      b = CreateFrame("Button", nil, menu); b:SetSize(colW - 8, 18)
      b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
      b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); b.text:SetPoint("LEFT", 6, 0); b.text:SetJustifyH("LEFT")
      b.right = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall"); b.right:SetPoint("RIGHT", -6, 0)
      menu.btns[i] = b
    end
    local col, row = math.floor((i - 1) / perCol), (i - 1) % perCol
    b:ClearAllPoints(); b:SetPoint("TOPLEFT", 6 + col * colW, -6 - row * 18)
    b.text:SetText((it.header and "|cffffd100" or (it.sel and "|cff66ccff" or "")) .. it.text .. ((it.header or it.sel) and "|r" or ""))
    b.right:SetText(it.right or "")
    b:SetEnabled(not it.header)
    b:SetScript("OnClick", function() menu:Hide(); if it.value then onPick(it.value) end end)
    b:Show()
  end
  for i = #items + 1, #menu.btns do menu.btns[i]:Hide() end
  menu:SetSize(math.ceil(#items / perCol) * colW + 4, math.min(#items, perCol) * 18 + 12)
  menu:ClearAllPoints(); menu:SetPoint("TOPLEFT", owner, "BOTTOMLEFT", 0, -2)
  menu:Show()
end

local function DropButton(parent, w)
  local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
  b:SetSize(w, 24)
  b:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 } })
  b:SetBackdropColor(0.15, 0.12, 0.05, 0.9); b:SetBackdropBorderColor(1, 0.82, 0, 0.7)
  b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
  b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormal"); b.text:SetPoint("LEFT", 10, 0); b.text:SetPoint("RIGHT", -22, 0)
  b.text:SetJustifyH("LEFT"); b.text:SetWordWrap(false)
  local arrow = b:CreateTexture(nil, "OVERLAY"); arrow:SetSize(14, 14); arrow:SetPoint("RIGHT", -6, 0)
  arrow:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow"); arrow:SetRotation(-math.pi / 2)
  return b
end
local function SmallButton(parent, text, w)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate"); b:SetSize(w, 22); b:SetText(text)
  return b
end
local function Check(parent, label, key, tip)
  local c = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate"); c:SetSize(22, 22)
  c.t = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); c.t:SetPoint("LEFT", c, "RIGHT", 0, 1); c.t:SetText(label)
  c:SetScript("OnClick", function(self) db()[key] = self:GetChecked() and true or false; NS.Refresh() end)
  c:SetScript("OnShow", function(self) self:SetChecked(db()[key] and true or false) end)
  if tip then
    c:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_BOTTOM"); GameTooltip:AddLine(label); GameTooltip:AddLine(tip, 1, 1, 1, true); GameTooltip:Show() end)
    c:SetScript("OnLeave", function() GameTooltip:Hide() end)
  end
  return c
end

---------------------------------------------------------------- building the list of rows
-- entry = { head = "label" } or { id, chance, price, craft = {spell, created, skill, src, recipe}, src = "where", who = ck }
local function GroupShown(g)
  local f = g[3]
  return f == 0 or f == P.Faction() or db().otherFaction
end
local function Visible(id)
  if not id or id == 0 then return true end
  if db().usable and P.IsGear(id) and not P.Usable(id) then return false end
  return true
end
local function AddGroup(out, g, page, withHead)
  local kind, list = g[2], g[4]
  local items = {}
  if kind == 2 then
    for x = 1, #list, 5 do
      local created = list[x + 1]
      if Visible(created) then
        items[#items + 1] = { id = created > 0 and created or (list[x + 4] > 0 and list[x + 4] or 0), craft = { list[x], created, list[x + 2], list[x + 3], list[x + 4] }, src = page[1] }
      end
    end
  else
    local kindText = (page[1] == "Mounts" and "Mount") or (page[1] == "Companions" and "Companion") or nil
    for x = 1, #list, 2 do
      local id = list[x]
      if Visible(id) then
        local e = { id = id, chance = (kind == 1) and list[x + 1] or nil, price = (kind == 3) and list[x + 1] or nil,
          src = (g[1] == page[1]) and page[1] or (g[1] .. " - " .. page[1]), kindText = kindText }
        if kind == 4 then
          local it = P.ITEMS[id]
          e.price = (list[x + 1] or 0) > 0 and list[x + 1] or nil
          e.note = it and it[7]
        end
        items[#items + 1] = e
      end
    end
  end
  if withHead then
    local fac = g[3] == 1 and "  |cffff5050(Horde)|r" or g[3] == 2 and "  |cff5080ff(Alliance)|r" or ""
    out[#out + 1] = { head = g[1] .. fac, n = #items }
  end
  for _, e in ipairs(items) do out[#out + 1] = e end
end
local function BuildLoot()
  local out = {}
  local cat = D.cats[catIdx]; local page = cat and cat[2][pageIdx]
  if not page then return out end
  for gi, g in ipairs(page[3]) do
    if GroupShown(g) and (not groupIdx or groupIdx == gi) then AddGroup(out, g, page, true) end
  end
  return out
end
local function BuildSearch()
  local out, seen, n = {}, {}, 0
  local text = searchText:lower()
  out[1] = { head = "Search: \"" .. searchText .. "\"" }
  for _, cat in ipairs(D.cats) do
    for _, page in ipairs(cat[2]) do
      for _, g in ipairs(page[3]) do
        if GroupShown(g) then
          local tmp = {}
          AddGroup(tmp, g, page, false)
          for _, e in ipairs(tmp) do
            local it = P.ITEMS[e.id]
            local name = it and it[6] or (e.craft and GetSpellInfo and GetSpellInfo(e.craft[1])) or ""
            if name:lower():find(text, 1, true) and not seen[e.id .. (e.craft and ("." .. e.craft[1]) or "")] then
              seen[e.id .. (e.craft and ("." .. e.craft[1]) or "")] = true
              n = n + 1
              if n <= 400 then out[#out + 1] = e end
            end
          end
        end
      end
    end
  end
  out[1].head = out[1].head .. "  |cff909090(" .. n .. " found" .. (n > 400 and ", showing 400" or "") .. ")|r"
  return out
end
local wishSlots = {}
local function BuildWishlist()
  local out = {}
  wishSlots = {}
  local realm, me = P.Me()
  local cks = {}
  for ck, list in pairs(db().wish) do
    local r, n = ck:match("^(.-)%.(.+)$")
    if r == realm and next(list) and (db().wishAll or n == me) then cks[#cks + 1] = ck end
  end
  table.sort(cks, function(a, b) if a == P.CK() then return true elseif b == P.CK() then return false end return a < b end)
  for _, ck in ipairs(cks) do
    local name = ck:match("%.(.+)$")
    local list = {}
    for id, w in pairs(db().wish[ck]) do
      local slot = SlotOf(id)
      wishSlots[slot] = (wishSlots[slot] or 0) + 1
      if not wishSlot or wishSlot == slot then list[#list + 1] = { id = id, src = w.src, who = ck, t = w.t } end
    end
    table.sort(list, function(a, b) return (a.t or 0) < (b.t or 0) end)
    if #list > 0 then out[#out + 1] = { head = "|c" .. ClassHex(db().classes[ck]) .. name .. "|r's wishlist" .. (wishSlot and (" - " .. wishSlot) or ""), n = #list } end
    for _, e in ipairs(list) do out[#out + 1] = e end
  end
  -- wishlists other players shared with you
  for _, sh in ipairs(P.SharedLists and P.SharedLists() or {}) do
    local list = {}
    for _, id in ipairs(sh.ids) do
      local slot = SlotOf(id)
      wishSlots[slot] = (wishSlots[slot] or 0) + 1
      if not wishSlot or wishSlot == slot then
        local src = P.Sources(id)
        list[#list + 1] = { id = id, src = src and src[1], who = "shared", shared = sh.from }
      end
    end
    if #list > 0 then
      local from = sh.from:gsub("%-.*$", "")
      out[#out + 1] = { head = "|cff80c0ff" .. sh.owner .. "|r's wishlist  |cff909090(shared by " .. from .. " - right-click to remove)|r", n = #list, shared = sh.from }
      for _, e in ipairs(list) do out[#out + 1] = e end
    end
  end
  if #out == 0 and wishSlot then out[1] = { head = "Nothing on your wishlist for " .. wishSlot .. "." }
  elseif #out == 0 then out[1] = { head = "Your wishlist is empty - click the star on any item (or Alt-click it) to add it." } end
  return out
end

---------------------------------------------------------------- rows
local function RowTip(r)
  local e = r.e
  if not e or e.head then return end
  GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
  if e.craft and e.craft[2] == 0 then
    if GameTooltip.SetSpellByID then GameTooltip:SetSpellByID(e.craft[1]) else GameTooltip:AddLine(r.cells[1]:GetText() or "") end
  elseif e.id and e.id > 0 then
    GameTooltip:SetHyperlink("item:" .. e.id)
  end
  if e.craft then
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine("Skill needed", tostring(e.craft[3]), 0.8, 0.8, 0.8, 1, 1, 1)
    GameTooltip:AddDoubleLine("Learned from", SRC[e.craft[4]] or "?", 0.8, 0.8, 0.8, 1, 1, 1)
    local rit = e.craft[5] > 0 and P.ITEMS[e.craft[5]]
    if rit then GameTooltip:AddDoubleLine("Recipe", rit[6], 0.8, 0.8, 0.8, 1, 1, 1) end
  elseif e.src then
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(e.src .. (e.chance and e.chance > 0 and ("  (" .. e.chance .. "% drop chance)") or ""), 0.8, 0.8, 0.8)
  end
  for _, o in ipairs(r.owners or {}) do GameTooltip:AddDoubleLine("|c" .. ClassHex(o[2]) .. o[1] .. "|r", o[3], 1, 1, 1, 0.7, 0.7, 0.7) end
  GameTooltip:AddLine(" ")
  GameTooltip:AddLine("Shift-click: link in chat   Ctrl-click: try it on   Alt-click: wishlist", 0.5, 0.5, 0.5)
  GameTooltip:Show()
end
local function RowClick(r, btn)
  local e = r.e
  if not e then return end
  if e.head then
    if e.shared and btn == "RightButton" then P.ForgetShared(e.shared); return end
    if tab == "loot" and searchText == "" and r.gi then groupIdx = (groupIdx == r.gi) and nil or r.gi; NS.Refresh() end
    return
  end
  local id = e.id
  if IsAltKeyDown() then P.ToggleWish(id, e.src); return end
  local link = id and id > 0 and select(2, GetItemInfo(id))
  if IsModifiedClick("CHATLINK") and ChatEdit_InsertLink then
    if link then ChatEdit_InsertLink(link) elseif e.craft and GetSpellLink then ChatEdit_InsertLink(GetSpellLink(e.craft[1]) or "") end
  elseif IsModifiedClick("DRESSUP") and link and DressUpItemLink then DressUpItemLink(link) end
end

local function GetRow(i)
  if rows[i] then return rows[i] end
  local r = CreateFrame("Button", nil, rowsFrame)
  r:SetSize(W - NAVW - 44, ROWH); r:SetPoint("TOPLEFT", 0, -(i - 1) * ROWH)
  r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  r.bg = r:CreateTexture(nil, "BACKGROUND"); r.bg:SetAllPoints()
  r.hl = r:CreateTexture(nil, "HIGHLIGHT"); r.hl:SetAllPoints(); r.hl:SetColorTexture(1, 0.82, 0, 0.08)
  r.icon = r:CreateTexture(nil, "ARTWORK"); r.icon:SetSize(18, 18); r.icon:SetPoint("LEFT", 4, 0)
  r.cells = {}
  local x = 28
  for j, c in ipairs(COLS) do
    local fs = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fs:SetWordWrap(false); fs:SetPoint("LEFT", x, 0); fs:SetWidth(c[2] - 6); fs:SetJustifyH(c[3])
    r.cells[j] = fs; x = x + c[2]
  end
  r.head = r:CreateFontString(nil, "OVERLAY", "GameFontNormal"); r.head:SetPoint("LEFT", 10, 0); r.head:SetWidth(W - NAVW - 70); r.head:SetJustifyH("LEFT")
  -- second line under the source (wishlist: the dungeon or zone)
  r.srcX = 28 + COLS[1][2] + COLS[2][2] + COLS[3][2]
  r.src2 = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall"); r.src2:SetWordWrap(false)
  r.src2:SetPoint("LEFT", r.srcX, -8); r.src2:SetWidth(COLS[4][2] - 6); r.src2:SetJustifyH("RIGHT"); r.src2:Hide()
  -- wishlist star, in the last column (clear of the scroll bar)
  r.star = CreateFrame("Button", nil, r); r.star:SetSize(18, 18); r.star:SetPoint("LEFT", x - COLS[#COLS][2] + 3, 0)
  r.star.tex = r.star:CreateTexture(nil, "ARTWORK"); r.star.tex:SetAllPoints(); r.star.tex:SetTexture("Interface\\COMMON\\ReputationStar")
  r.star:SetScript("OnClick", function(self) local e = self:GetParent().e; if e and e.id then P.ToggleWish(e.id, e.src) end end)
  r.star:SetScript("OnEnter", function(self)
    local e = self:GetParent().e
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine((e and P.IsWished(e.id)) and "Remove from your wishlist" or "Add to your wishlist"); GameTooltip:Show()
  end)
  r.star:SetScript("OnLeave", function() GameTooltip:Hide() end)
  r:SetScript("OnEnter", RowTip); r:SetScript("OnLeave", function() GameTooltip:Hide() end)
  r:SetScript("OnClick", RowClick)
  rows[i] = r
  return r
end

local function SetStar(r, on, can)
  r.star:SetShown(can)
  -- ReputationStar holds a lit star on the left half and an empty one on the right
  -- lit: gold. Not on the wishlist: the same full star, in light grey, so it's easy to see
  r.star.tex:SetTexCoord(0, 0.5, 0, 0.5)
  r.star.tex:SetDesaturated(not on)
  if on then r.star.tex:SetVertexColor(1, 1, 1) else r.star.tex:SetVertexColor(0.85, 0.85, 0.85) end
end

local function FillItem(r, e, odd)
  r.head:Hide(); for _, c in ipairs(r.cells) do c:Show() end
  r.bg:SetColorTexture(1, 1, 1, odd and 0.025 or 0)
  local id = e.id
  local it = id and P.ITEMS[id]
  local lvl = UnitLevel("player") or 1
  -- name and icon
  local name, icon, q
  if e.craft and e.craft[2] == 0 then
    local sn, _, sicon = GetSpellInfo and GetSpellInfo(e.craft[1])
    name, icon, q = sn or ("Spell " .. e.craft[1]), sicon, 1
  else
    name, q = it and it[6] or ("Item " .. tostring(id)), it and it[4] or 1
    icon = (GetItemIcon and id and id > 0) and GetItemIcon(id) or nil
  end
  r.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark"); r.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93); r.icon:Show()
  local usable = not it or not P.IsGear(id) or P.Usable(id)
  r.icon:SetDesaturated(not usable)
  local nc = r.cells[1]
  if tab == "wish" then
    FitText(nc, name)  -- resets any shrink left from the loot page
    nc:SetWordWrap(true); if nc.SetMaxLines then nc:SetMaxLines(2) end
    nc:SetText(name)
  else
    nc:SetWordWrap(false); if nc.SetMaxLines then nc:SetMaxLines(1) end
    FitText(nc, name)
  end
  nc:SetTextColor(QColor(q))
  if not usable then r.cells[1]:SetTextColor(0.55, 0.55, 0.55) end
  -- type
  r.cells[2]:SetText((e.craft and e.craft[2] == 0) and "Enchant" or e.kindText or (id and P.Kind(id) or "")); r.cells[2]:SetTextColor(0.8, 0.8, 0.8)
  -- required level
  local req = (it and not (e.craft and e.craft[2] == 0)) and it[3] or 0
  r.cells[3]:SetText(req > 0 and ((req > lvl and "|cffff4040" or "|cffffffff") .. req .. "|r") or "")
  -- source
  local s = ""
  r.cells[4]:ClearAllPoints(); r.cells[4]:SetPoint("LEFT", r.srcX, 0); r.src2:Hide()
  if tab == "wish" then
    -- "Boss - Dungeon": the boss on top, the dungeon on the line beneath
    local src = e.src or ""
    local boss, where = src:match("^(.-) %- (.+)$")
    if boss then
      s = "|cffe0e0e0" .. boss .. "|r"
      r.cells[4]:ClearAllPoints(); r.cells[4]:SetPoint("LEFT", r.srcX, 7)
      FitText(r.src2, where); r.src2:Show()
    else s = "|cffb0b0b0" .. src .. "|r" end
  elseif searchText ~= "" and tab == "loot" then s = "|cffb0b0b0" .. (e.src or "") .. "|r"
  elseif e.craft then s = "|cffffd100" .. e.craft[3] .. "|r  |cffb0b0b0" .. (SRC[e.craft[4]] or "") .. "|r"
  elseif e.price then s = Money(e.price)
  elseif e.note then s = "|cffb0b0b0" .. e.note .. "|r"
  elseif e.chance then s = e.chance > 0 and (e.chance .. "%") or "|cffb0b0b0rare|r" end
  FitText(r.cells[4], s)
  -- upgrade
  local pct, empty = P.Upgrade(id)
  if empty then r.cells[5]:SetText("|cff40ff40new|r")
  elseif pct and pct > 0.5 then r.cells[5]:SetText(("|cff40ff40+%d%%|r"):format(math.floor(pct + 0.5)))
  else r.cells[5]:SetText("") end
  -- owned / crafted by your characters
  local owners = P.Owners(id) or {}
  if e.craft then
    local cr = P.Crafters(e.craft[2]) or {}
    for _, c in ipairs(cr) do owners[#owners + 1] = { c[1], c[2], "can craft (" .. c[3] .. ")" } end
  end
  r.owners = owners
  if #owners == 1 then r.cells[6]:SetText("|c" .. ClassHex(owners[1][2]) .. owners[1][1] .. "|r")
  elseif #owners > 1 then r.cells[6]:SetText("|cff40ff40" .. #owners .. " characters|r")
  else r.cells[6]:SetText(P.HasLedger() and "" or "|cff606060-|r") end
  r.cells[7]:SetText("")
  SetStar(r, id and id > 0 and P.IsWished(id), id and id > 0)
  if tab == "wish" and e.who and e.who ~= P.CK() then r.star:Hide() end
end

---------------------------------------------------------------- refresh
local function NavRow(i)
  if navRows[i] then return navRows[i] end
  local b = CreateFrame("Button", nil, navFrame)
  b:SetSize(NAVW - 16, 22); b:SetPoint("TOPLEFT", 0, -(i - 1) * 24)
  b.bg = b:CreateTexture(nil, "BACKGROUND"); b.bg:SetAllPoints(); b.bg:SetColorTexture(1, 1, 1, 0.05)
  b.sel = b:CreateTexture(nil, "BORDER"); b.sel:SetAllPoints(); b.sel:SetColorTexture(0.25, 0.55, 1, 0.35); b.sel:Hide()
  local bar = b:CreateTexture(nil, "ARTWORK"); bar:SetSize(3, 22); bar:SetPoint("LEFT"); bar:SetColorTexture(1, 0.82, 0, 0.8)
  b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
  b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); b.text:SetPoint("LEFT", 10, 0); b.text:SetPoint("RIGHT", -4, 0)
  b.text:SetJustifyH("LEFT"); b.text:SetWordWrap(false)
  b:SetScript("OnClick", function(self)
    if tab == "wish" then wishSlot = self.slot else groupIdx = self.gi end
    sf:SetVerticalScroll(0); NS.Refresh()
  end)
  navRows[i] = b
  return b
end

local function RefreshNav()
  local i = 0
  local function add(text, gi)
    i = i + 1
    local b = NavRow(i)
    b.gi = gi; b.slot = gi; b.text:SetText(text)
    local sel
    if tab == "wish" then sel = (gi == wishSlot) else sel = (gi == groupIdx) end
    b.sel:SetShown(sel); b.text:SetTextColor(sel and 1 or 1, sel and 1 or 0.82, sel and 1 or 0)
    b:Show()
  end
  if tab == "loot" and searchText == "" then
    local page = D.cats[catIdx] and D.cats[catIdx][2][pageIdx]
    add("All", nil)
    for gi, g in ipairs(page and page[3] or {}) do
      if GroupShown(g) then add(g[1] .. ((g[3] == 1 and " |cffff5050(H)|r") or (g[3] == 2 and " |cff5080ff(A)|r") or ""), gi) end
    end
  end
  if tab == "wish" then
    local total = 0
    for _, n in pairs(wishSlots) do total = total + n end
    if wishSlot and not wishSlots[wishSlot] then wishSlot = nil end
    if total > 0 then
      add("All slots |cff909090(" .. total .. ")|r", nil)
      for _, sl in ipairs(SLOT_ORDER) do
        if wishSlots[sl] then add(sl .. " |cff909090(" .. wishSlots[sl] .. ")|r", sl) end
      end
    end
  end
  for j = i + 1, #navRows do navRows[j]:Hide() end
  navFrame:SetHeight(math.max(1, i * 24))
end

function NS.Refresh()
  if not (win and win:IsShown()) then return end
  local cat = D.cats[catIdx]
  local page = cat and cat[2][pageIdx]
  win.catBtn.text:SetText(cat and cat[1] or "")
  win.pageBtn.text:SetText(page and PageName(page) or "")
  win.sub:SetText(tab == "wish" and "Items your characters are hoping for" or (page and page[2] or ""))
  win.factionChk:SetShown(tab == "loot" and cat and cat[1] == "PvP" and true or false)
  win.wishAll:SetShown(tab == "wish")
  if win.share then win.share:SetShown(tab == "wish") end
  win.catBtn:SetShown(tab == "loot"); win.pageBtn:SetShown(tab == "loot"); win.prevB:SetShown(tab == "loot"); win.nextB:SetShown(tab == "loot")
  for k, t in pairs(win.tabs) do t.sel:SetShown(k == tab) end
  local list = (tab == "wish") and BuildWishlist() or (searchText ~= "" and BuildSearch()) or BuildLoot()
  if tab == "wish" and wishSlot and not wishSlots[wishSlot] then wishSlot = nil; list = BuildWishlist() end
  RefreshNav()
  local odd = false
  local gi, page3 = 0, page and page[3]
  local y = 0
  for i, e in ipairs(list) do
    local r = GetRow(i)
    r.e = e
    local h = (tab == "wish" and not e.head) and WISH_H or ROWH
    r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -y); r:SetHeight(h); y = y + h
    if e.head then
      r.icon:Hide(); r.star:Hide(); r.owners = nil; r.src2:Hide()
      for _, c in ipairs(r.cells) do c:Hide() end
      r.head:SetText(e.head .. (e.n and ("  |cff909090(" .. e.n .. ")|r") or "")); r.head:Show()
      r.bg:SetColorTexture(1, 0.82, 0, 0.07)
      -- which group this header belongs to (click a header to show just that boss)
      r.gi = nil
      if tab == "loot" and searchText == "" and page3 then
        repeat gi = gi + 1 until not page3[gi] or ((not groupIdx or groupIdx == gi) and GroupShown(page3[gi]))
        r.gi = gi
      end
      odd = false
    else
      odd = not odd
      FillItem(r, e, odd)
    end
    r:Show()
  end
  for j = #list + 1, #rows do rows[j]:Hide() end
  rowsFrame:SetHeight(math.max(1, y))
  -- footer
  local n = 0; for _, e in ipairs(list) do if not e.head then n = n + 1 end end
  win.footer:SetText(("%d item%s"):format(n, n == 1 and "" or "s") ..
    ((not P.HasLedger()) and "   |cff909090(install Pint's Alts to see which of your characters own each item)|r" or "") ..
    ((not _G.CraftUpgradesScore) and "   |cff909090(Pint's Craft Upgrades adds upgrade %)|r" or ""))
  db().ui.cat, db().ui.page = catIdx, pageIdx
end
P.OnChanged = function() if win and win:IsShown() then NS.Refresh() end end

local function SetPage(c, p)
  catIdx, pageIdx, groupIdx = c, p, nil
  if sf then sf:SetVerticalScroll(0) end
  NS.Refresh()
end
local function StepPage(dir)
  local cat = D.cats[catIdx]; if not cat then return end
  local n = #cat[2]
  SetPage(catIdx, ((pageIdx - 1 + dir) % n) + 1)
end

-- the dungeon you're in, else one that suits your level
local function DefaultPage()
  local inInst, kind = IsInInstance()
  local map = inInst and select(8, GetInstanceInfo())
  local lvl = UnitLevel("player") or 1
  local best
  for p, page in ipairs(D.cats[1] and D.cats[1][2] or {}) do
    if map and page[5] == map then return 1, p end
    if (page[4] or 0) == 0 and (page[6] or 99) <= lvl and lvl <= (page[7] or 0) + 2 then best = p end
  end
  return 1, best or 1
end

---------------------------------------------------------------- window
local function CreateWindow()
  win = CreateFrame("Frame", "PintsLootFrame", UIParent, "BackdropTemplate")
  win:SetSize(W, H); win:SetPoint("CENTER"); win:SetFrameStrata("HIGH"); win:SetToplevel(true)
  win:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
    tile = true, tileSize = 32, edgeSize = 24, insets = { left = 6, right = 6, top = 6, bottom = 6 } })
  win:SetBackdropColor(0.04, 0.04, 0.06, 0.95)
  win:EnableMouse(true); win:SetMovable(true); win:SetClampedToScreen(true); win:RegisterForDrag("LeftButton")
  win:SetScript("OnDragStart", win.StartMoving); win:SetScript("OnDragStop", win.StopMovingOrSizing)
  tinsert(UISpecialFrames, "PintsLootFrame")

  local logo = win:CreateTexture(nil, "ARTWORK"); logo:SetSize(34, 34); logo:SetPoint("TOPLEFT", 16, -14)
  logo:SetTexture("Interface\\Icons\\INV_Misc_Bag_10_Blue"); logo:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  local title = win:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge"); title:SetPoint("LEFT", logo, "RIGHT", 10, 6); title:SetText("Pint's Loot")
  win.sub = win:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall"); win.sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 1, -2)
  local close = CreateFrame("Button", nil, win, "UIPanelCloseButton"); close:SetPoint("TOPRIGHT", -6, -6)
  close:SetScript("OnClick", function() win:Hide() end)   -- (hide it directly: the game's own close goes through a path combat can block)

  -- the two drop-downs, with arrows to step through the second
  win.catBtn = DropButton(win, 170); win.catBtn:SetPoint("TOPLEFT", 260, -20)
  win.catBtn:SetScript("OnClick", function(self)
    local items = {}
    for c, cat in ipairs(D.cats) do items[#items + 1] = { text = cat[1], value = c, sel = (c == catIdx) } end
    ShowMenu(self, items, function(v) if v ~= catIdx then SetPage(v, (v == 1) and select(2, DefaultPage()) or 1) end end)
  end)
  win.prevB = SmallButton(win, "<", 26); win.prevB:SetPoint("LEFT", win.catBtn, "RIGHT", 8, 0)
  win.prevB:SetScript("OnClick", function() StepPage(-1) end)
  win.pageBtn = DropButton(win, 230); win.pageBtn:SetPoint("LEFT", win.prevB, "RIGHT", 4, 0)
  win.nextB = SmallButton(win, ">", 26); win.nextB:SetPoint("LEFT", win.pageBtn, "RIGHT", 4, 0)
  win.nextB:SetScript("OnClick", function() StepPage(1) end)
  win.pageBtn:SetScript("OnClick", function(self)
    local cat = D.cats[catIdx]; if not cat then return end
    local items, lastRaid = {}, nil
    for p, page in ipairs(cat[2]) do
      if cat[1] == "Dungeons & Raids" and page[4] ~= lastRaid then
        items[#items + 1] = { text = page[4] == 1 and "Raids" or "Dungeons", header = true }; lastRaid = page[4]
      elseif cat[1] == "PvP" and p == 1 then items[#items + 1] = { text = "Battlegrounds", header = true }
      elseif cat[1] == "PvP" and page[1] == "Rank 1" then items[#items + 1] = { text = "PvP rank rewards", header = true }
      elseif cat[1] == "World Drops" and p == 1 then items[#items + 1] = { text = "World bosses", header = true }
      elseif page[8] and page[8] ~= "" then items[#items + 1] = { text = page[8], header = true } end
      local right = (page[6] and page[6] > 0 and page[4] == 0) and (page[6] .. "-" .. page[7]) or nil
      items[#items + 1] = { text = PageName(page), value = p, right = right, sel = (p == pageIdx) }
    end
    ShowMenu(self, items, function(v) SetPage(catIdx, v) end)
  end)

  -- search across every page
  local search = CreateFrame("EditBox", "PintsLootSearchBox", win, "InputBoxTemplate")
  search:SetSize(170, 22); search:SetPoint("TOPRIGHT", -44, -20); search:SetAutoFocus(false); search:SetMaxLetters(50)
  search.ph = search:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall"); search.ph:SetPoint("LEFT", 2, 0); search.ph:SetText("Search all loot...")
  local pending = 0
  search:SetScript("OnTextChanged", function(self)
    self.ph:SetShown(self:GetText() == "" and not self:HasFocus())
    local t = self:GetText() or ""
    pending = pending + 1
    local mine = pending
    C_Timer.After(0.3, function()
      if mine ~= pending then return end
      searchText = (#t >= 2) and t or ""
      if searchText ~= "" and tab ~= "loot" then tab = "loot" end
      sf:SetVerticalScroll(0); NS.Refresh()
    end)
  end)
  search:SetScript("OnEditFocusGained", function(self) self.ph:Hide() end)
  search:SetScript("OnEditFocusLost", function(self) self.ph:SetShown(self:GetText() == "") end)
  search:SetScript("OnEscapePressed", function(self) self:SetText(""); self:ClearFocus() end)
  search:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
  win.search = search

  -- left: groups of the page
  local body = CreateFrame("Frame", nil, win)
  body:SetPoint("TOPLEFT", 12, -58); body:SetPoint("BOTTOMRIGHT", -12, 44)
  local nsf = CreateFrame("ScrollFrame", nil, body)
  nsf:SetPoint("TOPLEFT", 6, -6); nsf:SetPoint("BOTTOMLEFT", 6, 66); nsf:SetWidth(NAVW - 10)
  navFrame = CreateFrame("Frame", nil, nsf); navFrame:SetSize(NAVW - 16, 1); nsf:SetScrollChild(navFrame)
  nsf:EnableMouseWheel(true)
  nsf:SetScript("OnMouseWheel", function(self, d)
    local max = math.max(0, navFrame:GetHeight() - self:GetHeight())
    self:SetVerticalScroll(math.max(0, math.min(max, self:GetVerticalScroll() - d * 48)))
  end)
  local sep = body:CreateTexture(nil, "ARTWORK"); sep:SetColorTexture(1, 0.82, 0, 0.3); sep:SetWidth(1)
  sep:SetPoint("TOPLEFT", NAVW, 0); sep:SetPoint("BOTTOMLEFT", NAVW, 30)
  -- filters under the list
  win.usable = Check(body, "Gear I can use", "usable", "Hides gear your class can never wear or wield. Gear you're only too low a level for stays, with its level in red.")
  win.usable:SetPoint("BOTTOMLEFT", 6, 36)
  win.factionChk = Check(body, "Other faction too", "otherFaction", "Also show the other faction's PvP rewards.")
  win.factionChk:SetPoint("BOTTOMLEFT", 6, 12)
  win.wishAll = Check(body, "All my characters", "wishAll", "Show the wishlists of every character on this realm.")
  win.wishAll:SetPoint("BOTTOMLEFT", 6, 12)

  -- right: header and rows
  local content = CreateFrame("Frame", nil, body)
  content:SetPoint("TOPLEFT", NAVW + 8, 0); content:SetPoint("BOTTOMRIGHT", 0, 30)
  local header = CreateFrame("Frame", nil, content); header:SetHeight(24)
  header:SetPoint("TOPLEFT"); header:SetPoint("TOPRIGHT", -22, 0)
  local hl = header:CreateTexture(nil, "ARTWORK"); hl:SetColorTexture(1, 0.82, 0, 0.35); hl:SetHeight(1)
  hl:SetPoint("BOTTOMLEFT"); hl:SetPoint("BOTTOMRIGHT")
  local x = 28
  for _, c in ipairs(COLS) do
    local fs = header:CreateFontString(nil, "OVERLAY", "GameFontNormal"); fs:SetPoint("LEFT", x, 0); fs:SetWidth(c[2] - 6); fs:SetJustifyH(c[3])
    fs:SetText(c[1]); x = x + c[2]
  end
  sf = CreateFrame("ScrollFrame", "PintsLootScroll", content, "UIPanelScrollFrameTemplate")
  sf:SetPoint("TOPLEFT", 0, -28); sf:SetPoint("BOTTOMRIGHT", -24, 0)
  rowsFrame = CreateFrame("Frame", nil, sf); rowsFrame:SetSize(W - NAVW - 44, 1); sf:SetScrollChild(rowsFrame)
  local foot = CreateFrame("Frame", nil, body, "BackdropTemplate")
  foot:SetPoint("BOTTOMLEFT", NAVW + 8, 0); foot:SetPoint("BOTTOMRIGHT", 0, 0); foot:SetHeight(26)
  foot:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" }); foot:SetBackdropColor(1, 0.82, 0, 0.06)
  win.footer = foot:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); win.footer:SetPoint("LEFT", 10, 0)
  -- share your wishlist with another player (they get it in their Pint's Loot, or as whispered item links)
  win.share = CreateFrame("Button", nil, foot, "UIPanelButtonTemplate"); win.share:SetSize(150, 20); win.share:SetPoint("RIGHT", -6, 0)
  win.share:SetText("Share my wishlist...")
  win.share:SetScript("OnClick", function() P.AskShare(P.CK()) end)
  win.share:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:AddLine("Share your wishlist")
    GameTooltip:AddLine("Send it to another player, like a whisper. With Pint's Loot they can keep it here; without it, you can whisper the items as links.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  win.share:SetScript("OnLeave", function() GameTooltip:Hide() end)

  -- bottom tabs
  win.tabs = {}
  local tx = 16
  for _, td in ipairs({ { "loot", "Loot" }, { "wish", "Wishlist" } }) do
    local t = CreateFrame("Button", nil, win, "BackdropTemplate")
    t:SetSize(150, 30); t:SetPoint("BOTTOMLEFT", tx, 10)
    t:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12,
      insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    t:SetBackdropColor(0.15, 0.12, 0.05, 0.9); t:SetBackdropBorderColor(1, 0.82, 0, 0.7)
    t.sel = t:CreateTexture(nil, "ARTWORK"); t.sel:SetPoint("TOPLEFT", 3, -3); t.sel:SetPoint("BOTTOMRIGHT", -3, 3)
    t.sel:SetColorTexture(0.25, 0.55, 1, 0.35); t.sel:Hide()
    t:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
    t.text = t:CreateFontString(nil, "OVERLAY", "GameFontNormal"); t.text:SetPoint("CENTER"); t.text:SetText(td[2])
    t:SetScript("OnClick", function()
      tab = td[1]
      if tab == "wish" and win.search:GetText() ~= "" then win.search:SetText("") end
      sf:SetVerticalScroll(0); NS.Refresh()
    end)
    win.tabs[td[1]] = t
    tx = tx + 156
  end
  local tipChk = Check(win, "Show sources in item tooltips", "tooltips", "Adds where an item drops (and who has it on a wishlist) to every item tooltip.")
  tipChk:SetPoint("BOTTOMRIGHT", -200, 14)

  -- item names that weren't cached yet: refresh once they arrive (for upgrade %)
  win:RegisterEvent("GET_ITEM_INFO_RECEIVED")
  local wait
  win:SetScript("OnEvent", function()
    if wait or not win:IsShown() then return end
    wait = true
    C_Timer.After(0.5, function() wait = false; NS.Refresh() end)
  end)
  win:SetScript("OnShow", function() NS.Refresh() end)
  win:Hide()
end

-- a fight starts: get out of the way (/loot combat keeps it open instead)
do
  local f = CreateFrame("Frame"); f:RegisterEvent("PLAYER_REGEN_DISABLED")
  f:SetScript("OnEvent", function() if win and win:IsShown() and not db().keepInCombat then win:Hide() end end)
end

function P.Toggle(where)
  if not win then
    CreateWindow()
    local ui = db().ui
    if ui.cat and D.cats[ui.cat] and D.cats[ui.cat][2][ui.page or 0] then catIdx, pageIdx = ui.cat, ui.page
    else catIdx, pageIdx = DefaultPage() end
  end
  if where == "here" then catIdx, pageIdx = DefaultPage(); groupIdx = nil; tab = "loot" end
  if where == "wish" then tab = "wish" end
  if win:IsShown() and not where then win:Hide() else win:Show(); NS.Refresh() end
end

SLASH_PINTSLOOT1 = "/loot"
SLASH_PINTSLOOT2 = "/ploot"
SlashCmdList.PINTSLOOT = function(msg)
  msg = (msg or ""):lower()
  if msg == "combat" then
    db().keepInCombat = not db().keepInCombat
    print("|cffd4a017Pint's Loot:|r " .. (db().keepInCombat and "stays open in combat." or "closes when a fight starts."))
  elseif msg:match("^share") then
    local who = msg:match("^share%s+(.+)$")
    if who then P.ShareWish(P.CK(), who) else P.AskShare(P.CK()) end
  elseif msg == "wish" or msg == "wishlist" then P.Toggle("wish")
  elseif msg == "here" then P.Toggle("here")
  else P.Toggle() end
end

---------------------------------------------------------------- minimap button
local mm = CreateFrame("Frame")
mm:RegisterEvent("PLAYER_LOGIN")
mm:SetScript("OnEvent", function()
  local store = db().minimap
  local icon = ((C_Item and C_Item.GetItemIconByID or GetItemIcon) or function() end)(16882) or "Interface\\Icons\\INV_Misc_Bag_10_Blue"   -- Battered Junkbox (a treasure chest)
  local function Tip(tt)
    tt:AddLine("Pint's Loot")
    tt:AddLine("Left-click: browse loot", 1, 1, 1)
    tt:AddLine("Right-click: your wishlist", 1, 1, 1)
  end
  local function Click(button) if button == "RightButton" then P.Toggle("wish") else P.Toggle() end end
  local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
  local Icon = LibStub and LibStub("LibDBIcon-1.0", true)
  if LDB and Icon then
    local obj = LDB:NewDataObject("PintsLoot", { type = "launcher", text = "Pint's Loot", icon = icon,
      OnClick = function(_, b) Click(b) end, OnTooltipShow = Tip })
    Icon:Register("PintsLoot", obj, store)
    return
  end
  local b = CreateFrame("Button", "PintsLootMinimapButton", Minimap)
  b:SetSize(31, 31); b:SetFrameStrata("MEDIUM"); b:SetFrameLevel(8)
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  local ic = b:CreateTexture(nil, "BACKGROUND"); ic:SetTexture(icon); ic:SetSize(20, 20); ic:SetPoint("CENTER", 0, 1)
  local border = b:CreateTexture(nil, "OVERLAY"); border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder"); border:SetSize(53, 53); border:SetPoint("TOPLEFT")
  local function Place() local a = math.rad(store.angle or 200); b:ClearAllPoints(); b:SetPoint("CENTER", Minimap, "CENTER", 80 * math.cos(a), 80 * math.sin(a)) end
  Place()
  b:RegisterForDrag("LeftButton")
  b:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", function()
    local mx, my = Minimap:GetCenter(); local px, py = GetCursorPosition(); local s = Minimap:GetEffectiveScale()
    store.angle = math.deg(math.atan2(py / s - my, px / s - mx)); Place() end) end)
  b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
  b:SetScript("OnClick", function(_, btn) Click(btn) end)
  b:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_LEFT"); Tip(GameTooltip); GameTooltip:Show() end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
end)
