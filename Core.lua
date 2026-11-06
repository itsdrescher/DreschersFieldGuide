-- Drescher's Field Guide – Kern: Einstellungen, Gebiets-Zuordnung, Bewertung, Befehle

local ADDON, ns = ...
local L = ns.L

local defaults = {
  mode = "level",        -- "level", "off" oder Item-ID eines Materials
  routeShown = true,
  routePoint = nil,
  zoneDump = nil,
}

function ns.Print(msg) print("|cffe0b040Field Guide:|r " .. msg) end

---------------------------------------------------------------------------
-- Namen und Item-Namen
---------------------------------------------------------------------------
function ns.ZoneName(z)
  if z.resolvedName then return z.resolvedName end
  return ns.IS_DE and z.de or z.en
end

local itemNames = {}
function ns.ItemName(id)
  if itemNames[id] then return itemNames[id] end
  local name = GetItemInfo and GetItemInfo(id)
  if not name and C_Item and C_Item.GetItemNameByID then name = C_Item.GetItemNameByID(id) end
  if name then itemNames[id] = name; return name end
  return ns.ITEM_FALLBACK[id] or ("#" .. id)
end

-- Item-Namen vorladen, damit sie in der Spielsprache erscheinen
local function PreloadItems()
  if not (Item and Item.CreateFromItemID) then return end
  for id in pairs(ns.ITEM_FALLBACK) do
    local it = Item:CreateFromItemID(id)
    if it and it.ContinueOnItemLoad then
      it:ContinueOnItemLoad(function() itemNames[id] = it:GetItemName() end)
    end
  end
end

---------------------------------------------------------------------------
-- Gebiete auf der Karte finden (Classic-IDs prüfen, neue Gebiete über Namen)
---------------------------------------------------------------------------
local function norm(s) return ((s or ""):lower():gsub("[%s%-]", "")) end

local function ChildZones(contID)
  if not (C_Map and C_Map.GetMapChildrenInfo) then return {} end
  local zoneType = Enum and Enum.UIMapType and Enum.UIMapType.Zone or 3
  local ok, list = pcall(C_Map.GetMapChildrenInfo, contID, zoneType, true)
  return ok and list or {}
end

function ns.ResolveZones()
  ns.ZONE_BY_MAP = {}
  local children = {}
  for _, cont in ipairs({ 1415, 1414 }) do
    for _, c in ipairs(ChildZones(cont)) do children[#children + 1] = c end
  end
  -- Zusätzlich alle Kinder der Azeroth-Karte (für Inseln wie Zephras)
  for _, c in ipairs(ChildZones(947)) do children[#children + 1] = c end

  for _, z in ipairs(ns.ZONES) do
    local found
    if z.map and C_Map.GetMapInfo then
      local info = C_Map.GetMapInfo(z.map)
      if info and info.name then
        -- Bekannte Karten-Kennung: gilt, wenn sie noch zum richtigen Kontinent gehört
        -- (Namen weichen je nach Sprache/Schreibweise ab, z. B. Apostrophe)
        local n = norm(info.name)
        local nameOK = n == norm(z.en) or n == norm(z.de) or n:find(norm(z.de), 1, true) or n:find(norm(z.en), 1, true)
        if nameOK or not z.cont or info.parentMapID == z.cont then
          found = z.map
          z.resolvedName = info.name
        end
      end
    end
    if not found then
      local needles = z.find or { z.en:lower(), z.de:lower() }
      for _, c in ipairs(children) do
        local n = (c.name or ""):lower()
        for _, needle in ipairs(needles) do
          if n:find(needle, 1, true) then found = c.mapID; z.resolvedName = c.name; break end
        end
        if found then break end
      end
    end
    z.uiMap = found
    if found then
      ns.ZONE_BY_MAP[found] = z
      if C_Map.GetMapInfo then
        local info = C_Map.GetMapInfo(found)
        z.contMap = info and info.parentMapID or z.cont
      end
    end
  end
end

---------------------------------------------------------------------------
-- Bewertung: passt das Gebiet zu meinem Level und meiner Fraktion?
---------------------------------------------------------------------------
function ns.MyFaction()
  local f = UnitFactionGroup and UnitFactionGroup("player")
  return f == "Horde" and "H" or "A"
end

function ns.FactionOK(entry)
  return entry.faction == "C" or entry.faction == ns.MyFaction()
end

-- Rückgabe: Status, Farbe r,g,b, Text
function ns.Rate(entry, level)
  level = level or UnitLevel("player") or 1
  if entry.skyborneOnly then return "enemy", 0.55, 0.55, 0.6, L.SKYBORNE end
  if not ns.FactionOK(entry) and entry.max <= 12 then return "enemy", 0.45, 0.45, 0.55, L.ENEMY end
  if level < entry.min - 3 then return "hard", 0.9, 0.2, 0.2, L.HARD end
  if level < entry.min then return "soon", 1.0, 0.6, 0.15, L.SOON end
  if level <= entry.max then return "fits", 0.25, 0.85, 0.3, L.FITS end
  return "low", 0.6, 0.6, 0.6, L.LOW
end

-- Materialien eines Gebiets: { {label, {itemIDs}} , ... }
function ns.Materials(z)
  local out = {}
  if z.herbs and #z.herbs > 0 then out[#out + 1] = { L.HERBS, z.herbs } end
  if z.ores and #z.ores > 0 then out[#out + 1] = { L.ORES, z.ores } end
  local function byLevel(list)
    local r = {}
    for _, m in ipairs(list) do
      if m.min <= z.max and m.max >= z.min then r[#r + 1] = m.item end
    end
    return r
  end
  if z.max > 4 and not z.skyborneOnly then
    out[#out + 1] = { L.CLOTH, byLevel(ns.CLOTH) }
    out[#out + 1] = { L.LEATHER, byLevel(ns.LEATHER) }
  end
  return out
end

-- Hat das Gebiet dieses Material?
function ns.ZoneHas(z, itemID)
  for _, group in ipairs(ns.Materials(z)) do
    for _, id in ipairs(group[2]) do if id == itemID then return true end end
  end
  return false
end

-- Gebiets-Tooltip (für Karte und Routen-Fenster)
function ns.ZoneTooltip(tt, z)
  local _, r, g, b, text = ns.Rate(z)
  tt:AddLine(ns.ZoneName(z), 1, 0.82, 0)
  tt:AddLine(("%s %d–%d"):format(L.LEVEL, z.min, z.max), 1, 1, 1)
  tt:AddLine(text, r, g, b)
  local fac = z.faction == "A" and L.FACTION_A or z.faction == "H" and L.FACTION_H or L.CONTESTED
  tt:AddLine(fac, 0.7, 0.7, 0.7)
  if z.new then tt:AddLine(L.NEW_ZONE, 0.4, 0.8, 1) end
  if z.alt and ns.ZONE_BY_KEY[z.alt] then tt:AddLine(L.ALT:format(ns.ZoneName(ns.ZONE_BY_KEY[z.alt])), 0.4, 0.8, 1) end

  local dungeons = {}
  for _, d in ipairs(ns.DUNGEONS) do
    if d.zone == z.key and ns.FactionOK(d) then
      dungeons[#dungeons + 1] = ("%s (%d–%d)"):format(ns.IS_DE and d.de or d.en, d.min, d.max)
    end
  end
  if #dungeons > 0 then
    tt:AddLine(" ")
    tt:AddLine(L.DUNGEONS, 1, 0.82, 0)
    for _, line in ipairs(dungeons) do tt:AddLine(line, 1, 1, 1) end
  end

  tt:AddLine(" ")
  local mats = ns.Materials(z)
  if z.new and not z.herbs then tt:AddLine(L.NO_DATA, 0.6, 0.6, 0.6) end
  for _, group in ipairs(mats) do
    local names = {}
    for _, id in ipairs(group[2]) do names[#names + 1] = ns.ItemName(id) end
    if #names > 0 then
      tt:AddLine(group[1] .. ":", 1, 0.82, 0)
      tt:AddLine(table.concat(names, ", "), 0.9, 0.9, 0.9, true)
    end
  end
end

---------------------------------------------------------------------------
-- Start und Befehle
---------------------------------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_LEVEL_UP")
f:SetScript("OnEvent", function(_, event, arg)
  if event == "ADDON_LOADED" and arg == ADDON then
    DFGDB = DFGDB or {}
    for k, v in pairs(defaults) do if DFGDB[k] == nil then DFGDB[k] = v end end
    ns.db = DFGDB
  elseif event == "PLAYER_LOGIN" then
    PreloadItems()
    ns.ResolveZones()
    if ns.InitOverlay then ns.InitOverlay() end
    if ns.InitRoute then ns.InitRoute() end
    local v = (C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata)(ADDON, "Version") or ""
    if v:find("@", 1, true) then v = "dev" end
    ns.Print(("v%s %s"):format(v, L.LOADED))
  elseif event == "PLAYER_LEVEL_UP" then
    C_Timer.After(0.5, function()
      if ns.RefreshRoute then ns.RefreshRoute() end
      if ns.RefreshOverlay then ns.RefreshOverlay() end
    end)
  end
end)

SLASH_DRESCHERSFIELDGUIDE1 = "/fg"
SLASH_DRESCHERSFIELDGUIDE2 = "/fieldguide"
SlashCmdList.DRESCHERSFIELDGUIDE = function(input)
  local cmd = (input or ""):lower():match("^(%S*)")
  if cmd == "" then
    if ns.ToggleRoute then ns.ToggleRoute() end
  elseif cmd == "map" or cmd == "karte" then
    ns.db.mode = (ns.db.mode == "off") and "level" or "off"
    ns.Print(ns.db.mode == "off" and L.MODE_OFF or L.MODE_LEVEL)
    if ns.RefreshOverlay then ns.RefreshOverlay() end
  elseif cmd == "zones" then
    local dump, n = {}, 0
    for _, cont in ipairs({ 1415, 1414, 947 }) do
      for _, c in ipairs(ChildZones(cont)) do
        n = n + 1
        dump[#dump + 1] = ("%d = %s (parent %s)"):format(c.mapID, c.name or "?", tostring(c.parentMapID))
      end
    end
    for _, z in ipairs(ns.ZONES) do
      if not z.uiMap then dump[#dump + 1] = ("?? %s – %s"):format(z.en, L.NOT_FOUND) end
    end
    ns.db.zoneDump = dump
    for _, line in ipairs(dump) do print("  " .. line) end
    ns.Print(L.ZONES_SAVED:format(n))
  elseif cmd == "reset" then
    ns.db.routePoint = nil
    if ns.ResetRoutePosition then ns.ResetRoutePosition() end
  else
    ns.Print(L.TITLE)
    for _, line in ipairs({ L.HELP_ROUTE, L.HELP_MAP, L.HELP_ZONES, L.HELP_RESET }) do print("  " .. line) end
  end
end
