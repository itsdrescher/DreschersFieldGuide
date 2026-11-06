-- Drescher's Field Guide – Fundorte (Phase 2)
-- Erkennt, wenn du Kräuter pflückst, Erz abbaust oder in einem Fischschwarm angelst,
-- speichert den Ort und teilt ihn unsichtbar mit deiner Gilde. Angezeigt wird auf der Weltkarte.

local ADDON, ns = ...
local L = ns.L

local PREFIX    = "DFGuide"
local MERGE_YDS = 18        -- gleicher Name innerhalb dieser Entfernung = derselbe Fundort
local PIN_SIZE  = 14

-- Zauber, an denen wir das Sammeln erkennen (alle Ränge)
local SPELLS = {
  herb = { 2366, 2368, 3570, 11993 },
  ore  = { 2575, 2576, 3564, 10248 },
  fish = { 7620, 7731, 7732, 18248 },
}
local ICON = {
  herb = "Interface\\Icons\\INV_Misc_Flower_02",
  ore  = "Interface\\Icons\\INV_Ore_Copper_01",
  fish = "Interface\\Icons\\INV_Misc_Fish_02",
}

ns.session = ns.session or ("%06x%04x"):format(math.random(0, 0xFFFFFF), math.floor(GetTime() * 1000) % 0xFFFF)

---------------------------------------------------------------------------
-- Hilfen
---------------------------------------------------------------------------
local function SpellName(id)
  if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(id) end
  if GetSpellInfo then return (GetSpellInfo(id)) end
end

local spellKind = {}   -- [Zaubername] = "herb"/"ore"/"fish"
local function BuildSpellNames()
  for kind, ids in pairs(SPELLS) do
    for _, id in ipairs(ids) do
      local n = SpellName(id)
      if n then spellKind[n] = kind end
      spellKind[id] = kind
    end
  end
end

local function IsSecret(v) return issecretvalue and issecretvalue(v) or false end

local function MyWorldPos()
  if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition and C_Map.GetWorldPosFromMapPos) then return end
  local ok, mapID = pcall(C_Map.GetBestMapForUnit, "player")
  if not ok or not mapID or IsSecret(mapID) then return end
  local ok2, pos = pcall(C_Map.GetPlayerMapPosition, mapID, "player")
  if not ok2 or not pos then return end
  local ok3, cont, world = pcall(C_Map.GetWorldPosFromMapPos, mapID, pos)
  if not ok3 or not cont or not world then return end
  local ok4, x, y = pcall(world.GetXY, world)
  if not ok4 or type(x) ~= "number" or IsSecret(x) then return end
  return cont, x, y, mapID
end

-- Fundort-Name → Item-ID (für Icons und den Material-Filter)
-- Kräuter heißen wie das Kraut; Erz-Vorkommen enthalten den Metallnamen ("Kupfervorkommen", "Copper Vein").
local itemForName = {}
local function ItemFor(kind, name)
  if not name then return end
  local key = kind .. ":" .. name
  if itemForName[key] ~= nil then return itemForName[key] or nil end
  local lname, best, bestLen = name:lower(), nil, 0
  if kind == "herb" then
    for _, id in pairs(ns.HERB) do
      local n = ns.ItemName(id):lower()
      if lname == n or lname:find(n, 1, true) then
        if #n > bestLen then best, bestLen = id, #n end
      end
    end
  elseif kind == "ore" then
    for _, id in pairs(ns.ORE) do
      -- "Kupfererz" → "kupfer", "Copper Ore" → "copper"
      local metal = ns.ItemName(id):lower():gsub("%s*ore$", ""):gsub("erz$", "")
      if #metal > 2 and lname:find(metal, 1, true) and #metal > bestLen then best, bestLen = id, #metal end
    end
  end
  itemForName[key] = best or false
  return best
end
ns.NodeItem = ItemFor

---------------------------------------------------------------------------
-- Speicher
---------------------------------------------------------------------------
-- DFGDB.nodes[mapID] = { {k=kind, n=name, c=cont, x=, y=, t=time, by=finder, h=hits}, ... }
local function Store() ns.db.nodes = ns.db.nodes or {}; return ns.db.nodes end

local function AddNode(kind, name, cont, x, y, mapID, by, quiet, bundled)
  if not (kind and name and cont and x and y and mapID) then return end
  local zone = Store()[mapID] or {}
  Store()[mapID] = zone
  for _, n in ipairs(zone) do
    if n.k == kind and n.n == name and math.abs(n.x - x) + math.abs(n.y - y) < MERGE_YDS then
      if bundled then return false end   -- mitgelieferte Daten nicht bei jedem Login neu zählen
      n.h = (n.h or 1) + 1
      n.t = time()
      return false
    end
  end
  zone[#zone + 1] = { k = kind, n = name, c = cont, x = x, y = y, t = time(), by = by, h = 1 }
  if not quiet and ns.RefreshNodes then ns.RefreshNodes() end
  return true
end

-- Mitgelieferte Fundorte (NodesData.lua) einmalig übernehmen
local function MergeBundled()
  local data = ns.BUNDLED_NODES
  if not data then return end
  for mapID, list in pairs(data) do
    for _, n in ipairs(list) do AddNode(n[1], n[2], n[3], n[4], n[5], mapID, nil, true, true) end
  end
end

function ns.NodeCount()
  local total = 0
  for _, list in pairs(Store()) do total = total + #list end
  return total
end

---------------------------------------------------------------------------
-- Gilde: teilen und empfangen   N;kind;name;cont;x;y;map;session
---------------------------------------------------------------------------
local function Share(kind, name, cont, x, y, mapID)
  if not IsInGuild() or not C_ChatInfo then return end
  local msg = ("N;%s;%s;%d;%.1f;%.1f;%d;%s"):format(kind, (name:gsub(";", ",")), cont, x, y, mapID, ns.session)
  pcall(C_ChatInfo.SendAddonMessage, PREFIX, msg, "GUILD")
end

local function OnAddonMessage(prefix, msg, _, sender)
  if prefix ~= PREFIX then return end
  local p = { strsplit(";", msg) }
  if p[1] ~= "N" or p[8] == ns.session then return end
  local kind, name = p[2], p[3]
  if kind ~= "herb" and kind ~= "ore" and kind ~= "fish" then return end
  AddNode(kind, name, tonumber(p[4]), tonumber(p[5]), tonumber(p[6]), tonumber(p[7]), sender)
end

---------------------------------------------------------------------------
-- Sammeln erkennen
---------------------------------------------------------------------------
local pending = {}   -- [castGUID] = { kind, name }

local function FishPoolName()
  -- Beim Angeln zeigt der Tooltip den Schwarm, über dem die Maus steht
  if not GameTooltip:IsShown() then return end
  local line = _G["GameTooltipTextLeft1"]
  local text = line and line:GetText()
  if not text or IsSecret(text) then return end
  local t = text:lower()
  for _, word in ipairs({ "school", "schwarm", "pool", "wreckage", "wrack", "oil", "öl", "patch", "floating", "treibgut", "debris" }) do
    if t:find(word, 1, true) then return text end
  end
end

local function OnSent(unit, target, castGUID, spellID)
  if unit ~= "player" then return end
  local kind = spellKind[spellID] or spellKind[SpellName(spellID) or ""]
  if not kind then return end
  local name = target
  if kind == "fish" then name = FishPoolName() end
  if not name or name == "" or IsSecret(name) then return end
  pending[castGUID or "x"] = { kind = kind, name = name, t = GetTime() }
end

local function OnSucceeded(unit, castGUID, spellID)
  if unit ~= "player" then return end
  local p = pending[castGUID or "x"]
  pending[castGUID or "x"] = nil
  if not p or GetTime() - p.t > 30 then return end
  local cont, x, y, mapID = MyWorldPos()
  if not cont then return end
  if AddNode(p.kind, p.name, cont, x, y, mapID, nil) then
    Share(p.kind, p.name, cont, x, y, mapID)
  end
end

---------------------------------------------------------------------------
-- Anzeige auf der Weltkarte
---------------------------------------------------------------------------
local pins, used = {}, 0

-- Welche Fundorte sollen gezeigt werden? (Filter aus dem Karten-Menü)
local function Wanted(n)
  local mode, f = ns.db.mode, ns.db.nodeFilter or "all"
  if type(mode) == "number" then return ItemFor(n.k, n.n) == mode end   -- gesuchtes Material
  if f == "off" then return false end
  return f == "all" or f == n.k
end

local function PinLevel(map, canvas)
  local base = canvas:GetFrameLevel() + 1500
  local mgr = map.GetPinFrameLevelsManager and map:GetPinFrameLevelsManager()
  if mgr and mgr.GetValidFrameLevel then
    local ok, lvl = pcall(mgr.GetValidFrameLevel, mgr, "PIN_FRAME_LEVEL_GROUP_MEMBER")
    if ok and type(lvl) == "number" then base = math.max(base, lvl - 2) end
  end
  return math.min(base, 9000)
end

local function ItemIcon(id)
  if C_Item and C_Item.GetItemIconByID then return C_Item.GetItemIconByID(id) end
  if GetItemIcon then return GetItemIcon(id) end
end

local function CreatePin(canvas)
  local pin = CreateFrame("Frame", nil, canvas)
  pin:SetSize(PIN_SIZE, PIN_SIZE)
  pin.icon = pin:CreateTexture(nil, "ARTWORK")
  pin.icon:SetAllPoints()
  pin.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  pin.border = pin:CreateTexture(nil, "BACKGROUND")
  pin.border:SetPoint("TOPLEFT", -1, 1)
  pin.border:SetPoint("BOTTOMRIGHT", 1, -1)
  pin.border:SetColorTexture(0, 0, 0, 0.9)
  pin:EnableMouse(true)
  pin:SetScript("OnEnter", function(self)
    local n = self.node
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(n.n, 1, 0.82, 0)
    local kind = n.k == "herb" and L.HERBS or n.k == "ore" and L.ORES or L.FISH
    GameTooltip:AddLine(kind, 0.8, 0.8, 0.8)
    if (n.h or 1) > 1 then GameTooltip:AddLine(L.SEEN:format(n.h), 0.7, 0.7, 0.7) end
    if n.by then GameTooltip:AddLine(L.FOUND_BY:format((n.by:match("^[^-]+") or n.by)), 0.5, 0.8, 1) end
    GameTooltip:Show()
  end)
  pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
  return pin
end

function ns.RefreshNodes()
  local map = WorldMapFrame
  if not map or not map:IsShown() or not map.GetCanvas then return end
  local canvas, shownID = map:GetCanvas(), map:GetMapID()
  if not canvas or not shownID then return end
  local scale = 1 / ((map.GetCanvasScale and map:GetCanvasScale()) or 1)
  local W, H = canvas:GetWidth(), canvas:GetHeight()
  local level = PinLevel(map, canvas)

  -- Auf Kontinentkarten nur, wenn ein bestimmtes Material gesucht wird (sonst zu voll)
  local zone = ns.ZONE_BY_MAP and ns.ZONE_BY_MAP[shownID]
  local isZoneMap = zone ~= nil
  local onContinent = type(ns.db.mode) == "number"
  used = 0

  if ns.db.mode ~= "off" and (isZoneMap or onContinent) then
    for mapID, list in pairs(Store()) do
      if isZoneMap and mapID ~= shownID then
        -- andere Zone: überspringen
      else
        for _, n in ipairs(list) do
          if Wanted(n) then
            local ok, onMap, pos = pcall(C_Map.GetMapPosFromWorldPos, n.c, CreateVector2D(n.x, n.y), shownID)
            local mx, my
            if ok and pos then mx, my = pos:GetXY() end
            if mx and my and mx >= 0 and mx <= 1 and my >= 0 and my <= 1 then
              used = used + 1
              local pin = pins[used] or CreatePin(canvas)
              pins[used] = pin
              pin:SetParent(canvas)
              pin:SetFrameLevel(level)
              pin.node = n
              local item = ItemFor(n.k, n.n)
              pin.icon:SetTexture((item and ItemIcon(item)) or ICON[n.k])
              local s = isZoneMap and scale or scale * 0.75
              pin:SetScale(s)
              pin:ClearAllPoints()
              pin:SetPoint("CENTER", canvas, "TOPLEFT", W * mx / s, -H * my / s)
              pin:Show()
            end
          end
        end
      end
    end
  end
  for i = used + 1, #pins do pins[i]:Hide() end
end

---------------------------------------------------------------------------
-- Start
---------------------------------------------------------------------------
function ns.InitNodes()
  BuildSpellNames()
  if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then C_ChatInfo.RegisterAddonMessagePrefix(PREFIX) end
  MergeBundled()

  local f = CreateFrame("Frame")
  f:RegisterEvent("UNIT_SPELLCAST_SENT")
  f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
  f:RegisterEvent("CHAT_MSG_ADDON")
  f:SetScript("OnEvent", function(_, event, ...)
    if event == "UNIT_SPELLCAST_SENT" then pcall(OnSent, ...)
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then pcall(OnSucceeded, ...)
    elseif event == "CHAT_MSG_ADDON" then pcall(OnAddonMessage, ...) end
  end)

  local map = WorldMapFrame
  if map and map.GetCanvas then
    map:HookScript("OnShow", ns.RefreshNodes)
    if map.OnMapChanged then hooksecurefunc(map, "OnMapChanged", ns.RefreshNodes) end
    if map.OnCanvasScaleChanged then hooksecurefunc(map, "OnCanvasScaleChanged", ns.RefreshNodes) end
  end
end
