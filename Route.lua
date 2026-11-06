-- Drescher's Field Guide – Routen-Fenster
-- "Jetzt hier leveln", "Als Nächstes" und passende Dungeons – nach Level und Fraktion.

local ADDON, ns = ...
local L = ns.L

local frame
local rows = {}
local WIDTH = 260

---------------------------------------------------------------------------
-- Auswahl
---------------------------------------------------------------------------
local function Usable(z)
  return not z.noRoute and not z.skyborneOnly and ns.FactionOK(z)
end

-- Wie gut passt ein Gebiet? (kleiner = besser): Abstand zur Mitte der Spanne
local function Score(z, level)
  local mid = (z.min + z.max) / 2
  local s = math.abs(level - mid)
  if z.faction ~= "C" then s = s - 1.5 end   -- eigenes Fraktionsgebiet leicht bevorzugen
  return s
end

local function BuildLists()
  local level = UnitLevel("player") or 1
  local now, nextUp, dungeons = {}, {}, {}
  for _, z in ipairs(ns.ZONES) do
    if Usable(z) then
      if level >= z.min and level <= z.max - 1 then
        now[#now + 1] = z
      elseif z.min > level - 1 and z.min <= level + 6 and level < z.min + 1 then
        nextUp[#nextUp + 1] = z
      end
    end
  end
  table.sort(now, function(a, b) return Score(a, level) < Score(b, level) end)
  table.sort(nextUp, function(a, b) return a.min < b.min end)
  for _, d in ipairs(ns.DUNGEONS) do
    if ns.FactionOK(d) and level >= d.min - 1 and level <= d.max - 2 then dungeons[#dungeons + 1] = d end
  end
  table.sort(dungeons, function(a, b) return a.min < b.min end)
  -- kompakt halten
  while #now > 4 do table.remove(now) end
  while #nextUp > 3 do table.remove(nextUp) end
  while #dungeons > 4 do table.remove(dungeons) end
  return now, nextUp, dungeons, level
end

---------------------------------------------------------------------------
-- Zeilen
---------------------------------------------------------------------------
local function Row(i)
  local r = rows[i]
  if r then return r end
  r = CreateFrame("Button", nil, frame)
  r:SetHeight(16)
  r.left = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  r.left:SetPoint("LEFT")
  r.left:SetJustifyH("LEFT")
  r.right = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  r.right:SetPoint("RIGHT")
  r.right:SetJustifyH("RIGHT")
  r:SetScript("OnEnter", function(self)
    if not self.zone then return end
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    ns.ZoneTooltip(GameTooltip, self.zone)
    if self.zone.uiMap then GameTooltip:AddLine(" "); GameTooltip:AddLine(L.CLICK_OPEN, 0.5, 0.5, 0.5) end
    GameTooltip:Show()
  end)
  r:SetScript("OnLeave", function() GameTooltip:Hide() end)
  r:SetScript("OnClick", function(self)
    local z = self.zone
    if not (z and z.uiMap) then return end
    if not WorldMapFrame:IsShown() then
      if ToggleWorldMap then ToggleWorldMap() else WorldMapFrame:Show() end
    end
    WorldMapFrame:SetMapID(z.uiMap)
  end)
  rows[i] = r
  return r
end

function ns.RefreshRoute()
  if not frame or not frame:IsShown() then return end
  local now, nextUp, dungeons, level = BuildLists()
  local y, i = -30, 0

  local function place(r)
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, y)
    r:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, y)
  end
  local function header(text)
    i = i + 1
    local r = Row(i)
    r.zone = nil
    place(r)
    r.left:SetText("|cffe0b040" .. text .. "|r")
    r.left:SetTextColor(1, 1, 1)
    r.right:SetText("")
    r:Show()
    y = y - 17
  end
  local function line(left, right, zone, cr, cg, cb)
    i = i + 1
    local r = Row(i)
    r.zone = zone
    place(r)
    r.left:SetText("  " .. left)
    r.left:SetTextColor(cr or 1, cg or 1, cb or 1)
    r.right:SetText(right)
    r:Show()
    y = y - 16
  end

  header(L.NOW)
  if #now == 0 then line("|cff999999" .. L.NOTHING .. "|r", "") end
  for _, z in ipairs(now) do
    local _, cr, cg, cb = ns.Rate(z, level)
    line(ns.ZoneName(z) .. (z.new and " " .. ns.NEW_ICON or ""), ("%d–%d"):format(z.min, z.max), z, cr, cg, cb)
  end
  if #dungeons > 0 then
    y = y - 4
    header(L.DUNGEONS)
    for _, d in ipairs(dungeons) do
      line((ns.IS_DE and d.de or d.en) .. (d.new and " " .. ns.NEW_ICON or ""), ("%d–%d"):format(d.min, d.max), ns.ZONE_BY_KEY[d.zone])
    end
  end
  if #nextUp > 0 then
    y = y - 4
    header(L.NEXT)
    for _, z in ipairs(nextUp) do
      local _, cr, cg, cb = ns.Rate(z, level)
      line(ns.ZoneName(z) .. (z.new and " " .. ns.NEW_ICON or ""), ("%d–%d"):format(z.min, z.max), z, cr, cg, cb)
    end
  end
  for k = i + 1, #rows do rows[k]:Hide() end
  frame.title:SetText(("%s  |cffffffff· %s %d|r"):format(L.TITLE, L.LEVEL, level))
  frame:SetHeight(-y + 10)
end

---------------------------------------------------------------------------
-- Fenster
---------------------------------------------------------------------------
local function SavePosition()
  local p, _, rp, x, y = frame:GetPoint()
  ns.db.routePoint = { p, rp, x, y }
end

function ns.ResetRoutePosition()
  if not frame then return end
  frame:ClearAllPoints()
  frame:SetPoint("RIGHT", UIParent, "RIGHT", -40, 80)
  SavePosition()
end

function ns.InitRoute()
  frame = CreateFrame("Frame", "DreschersFieldGuideRoute", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
  frame:SetWidth(WIDTH)
  frame:SetFrameStrata("MEDIUM")
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); SavePosition() end)
  if frame.SetBackdrop then
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    frame:SetBackdropColor(0.04, 0.04, 0.06, 0.85)
    frame:SetBackdropBorderColor(0.88, 0.69, 0.25, 0.8)
  end

  frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  frame.title:SetPoint("TOPLEFT", 10, -9)

  local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", 3, 3)
  close:SetScale(0.8)
  close:SetScript("OnClick", function() ns.ToggleRoute(false) end)

  local p = ns.db.routePoint
  if p then frame:SetPoint(p[1], UIParent, p[2], p[3], p[4]) else ns.ResetRoutePosition() end

  frame:RegisterEvent("PLAYER_ENTERING_WORLD")
  frame:RegisterEvent("PLAYER_LEVEL_UP")
  frame:SetScript("OnEvent", function() C_Timer.After(0.5, ns.RefreshRoute) end)

  frame:SetShown(ns.db.routeShown)
  ns.RefreshRoute()
end

function ns.ToggleRoute(show)
  if not frame then return end
  if show == nil then show = not frame:IsShown() end
  ns.db.routeShown = show
  frame:SetShown(show)
  ns.RefreshRoute()
end
