-- Drescher's Field Guide – Flugzeiten
-- Misst jeden Flug, teilt die Zeiten mit der Gilde, zeigt sie auf der Flugkarte an
-- und blendet während des Flugs einen verschiebbaren Timer ein.

local ADDON, ns = ...
local L = ns.L

local PREFIX = "DFGuide"
local DEFAULT_FACTOR = 650   -- Sekunden pro Kartenbreite der Flugkarte (Schätzung, wird angepasst)

---------------------------------------------------------------------------
-- Daten
---------------------------------------------------------------------------
-- DFGDB.flights[Start>Ziel] = { t = Sekunden (Mittelwert), n = Anzahl Messungen }
-- DFGDB.flightFactor[Karte] = { sum = Sekunden, len = Strecke } für Schätzungen
local function Flights() ns.db.flights = ns.db.flights or {}; return ns.db.flights end
local function Factors() ns.db.flightFactor = ns.db.flightFactor or {}; return ns.db.flightFactor end

local function Key(src, dst) return src .. ">" .. dst end

local function Fmt(sec)
  sec = math.max(0, math.floor(sec + 0.5))
  return ("%d:%02d"):format(math.floor(sec / 60), sec % 60)
end

local function AddTime(src, dst, secs, fromGuild)
  if not (src and dst and secs) or secs < 5 or secs > 1800 then return false end
  local f = Flights()
  local e = f[Key(src, dst)]
  if e then
    -- gleitender Mittelwert; stark abweichende Gilden-Werte ignorieren
    if fromGuild and math.abs(e.t - secs) > e.t * 0.25 then return false end
    e.t = (e.t * e.n + secs) / (e.n + 1)
    e.n = math.min(e.n + 1, 20)
  else
    f[Key(src, dst)] = { t = secs, n = 1 }
  end
  return true
end

local function MergeBundled()
  for key, secs in pairs(ns.BUNDLED_FLIGHTS or {}) do
    local src, dst = key:match("^(.-)>(.+)$")
    if src and not Flights()[key] then AddTime(src, dst, secs) end
  end
end

---------------------------------------------------------------------------
-- Flugkarte auslesen
---------------------------------------------------------------------------
local function TaxiMapKey()
  return tostring((GetTaxiMapID and GetTaxiMapID()) or "default")
end

local function CurrentNode()
  for i = 1, (NumTaxiNodes() or 0) do
    if TaxiNodeGetType(i) == "CURRENT" then return TaxiNodeName(i), i end
  end
end

-- Länge der Route (über alle Zwischenstopps) in Flugkarten-Einheiten
local function RouteLength(slot)
  if not (GetNumRoutes and TaxiGetSrcX) then return end
  local hops = GetNumRoutes(slot)
  if not hops or hops < 1 then return end
  local len = 0
  for h = 1, hops do
    local sx, sy = TaxiGetSrcX(slot, h), TaxiGetSrcY(slot, h)
    local dx, dy = TaxiGetDestX(slot, h), TaxiGetDestY(slot, h)
    if not (sx and dx) then return end
    len = len + math.sqrt((dx - sx) ^ 2 + (dy - sy) ^ 2)
  end
  return len
end

local function Estimate(slot)
  local len = RouteLength(slot)
  if not len or len <= 0 then return end
  local fac = Factors()[TaxiMapKey()]
  local factor = (fac and fac.len > 0) and (fac.sum / fac.len) or DEFAULT_FACTOR
  return len * factor
end

-- Flugzeit für ein Ziel: gemessen (genau) oder geschätzt
local function TimeFor(slot)
  local src = CurrentNode()
  local dst = TaxiNodeName(slot)
  if not (src and dst) then return end
  local e = Flights()[Key(src, dst)]
  if e then return e.t, false, e.n end
  local est = Estimate(slot)
  if est then return est, true end
end

---------------------------------------------------------------------------
-- Tooltip auf der Flugkarte
---------------------------------------------------------------------------
local function AddTooltip(slot)
  if not slot or TaxiNodeGetType(slot) ~= "REACHABLE" then return end
  local secs, estimated = TimeFor(slot)
  if not secs then return end
  if estimated then
    GameTooltip:AddLine(L.FLIGHT_EST:format(Fmt(secs)), 0.8, 0.8, 0.8)
  else
    GameTooltip:AddLine(L.FLIGHT_TIME:format(Fmt(secs)), 0.4, 1, 0.4)
  end
  GameTooltip:Show()
end

---------------------------------------------------------------------------
-- Timer-Leiste
---------------------------------------------------------------------------
local bar
local flight   -- { src, dst, slot, expected, estimated, start, len, mapKey }

local function SaveBarPos()
  local p, _, rp, x, y = bar:GetPoint()
  ns.db.flightBarPos = { p, rp, x, y }
end

local function ApplyBarPos()
  bar:ClearAllPoints()
  local p = ns.db.flightBarPos
  if p then bar:SetPoint(p[1], UIParent, p[2], p[3], p[4]) else bar:SetPoint("TOP", UIParent, "TOP", 0, -150) end
end
ns.ResetFlightBar = function() ns.db.flightBarPos = nil; if bar then ApplyBarPos() end end

local function CreateBar()
  bar = CreateFrame("Frame", "DreschersFieldGuideFlightBar", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
  bar:SetSize(280, 44)
  bar:SetFrameStrata("MEDIUM")
  bar:SetClampedToScreen(true)
  bar:SetMovable(true)
  bar:EnableMouse(true)
  bar:RegisterForDrag("LeftButton")
  bar:SetScript("OnDragStart", bar.StartMoving)
  bar:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); SaveBarPos() end)
  if bar.SetBackdrop then
    bar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    bar:SetBackdropColor(0.04, 0.04, 0.06, 0.85)
    bar:SetBackdropBorderColor(0.88, 0.69, 0.25, 0.8)
  end
  bar.dest = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  bar.dest:SetPoint("TOPLEFT", 10, -7)
  bar.dest:SetPoint("RIGHT", -70, 0)
  bar.dest:SetJustifyH("LEFT")
  bar.dest:SetWordWrap(false)
  bar.time = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  bar.time:SetPoint("TOPRIGHT", -10, -7)
  bar.status = CreateFrame("StatusBar", nil, bar)
  bar.status:SetPoint("BOTTOMLEFT", 10, 8)
  bar.status:SetPoint("BOTTOMRIGHT", -10, 8)
  bar.status:SetHeight(8)
  bar.status:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
  bar.status:SetStatusBarColor(0.88, 0.69, 0.25)
  bar.status:SetMinMaxValues(0, 1)
  bar.status.bg = bar.status:CreateTexture(nil, "BACKGROUND")
  bar.status.bg:SetAllPoints()
  bar.status.bg:SetColorTexture(1, 1, 1, 0.1)
  ApplyBarPos()
  bar:Hide()
end

local function UpdateBar()
  if not flight or not flight.start then return end
  local elapsed = GetTime() - flight.start
  bar.dest:SetText(L.FLIGHT_TO:format(flight.dst))
  if flight.expected then
    local left = flight.expected - elapsed
    local txt = left > 0 and Fmt(left) or L.FLIGHT_SOON
    if flight.estimated and left > 0 then txt = "ca. " .. txt end
    bar.time:SetText(txt)
    bar.status:SetValue(math.min(1, elapsed / flight.expected))
  else
    bar.time:SetText(Fmt(elapsed))
    bar.status:SetValue(0)
  end
end

---------------------------------------------------------------------------
-- Gilde: teilen und empfangen   F;Start;Ziel;Sekunden;session
---------------------------------------------------------------------------
local function Share(src, dst, secs)
  if not IsInGuild() or not C_ChatInfo then return end
  local msg = ("F;%s;%s;%d;%s"):format((src:gsub(";", ",")), (dst:gsub(";", ",")), math.floor(secs + 0.5), ns.session or "")
  pcall(C_ChatInfo.SendAddonMessage, PREFIX, msg, "GUILD")
end

local function OnAddonMessage(prefix, msg)
  if prefix ~= PREFIX then return end
  local p = { strsplit(";", msg) }
  if p[1] ~= "F" or (ns.session and p[5] == ns.session) then return end
  AddTime(p[2], p[3], tonumber(p[4]), true)
end

---------------------------------------------------------------------------
-- Flug starten / landen
---------------------------------------------------------------------------
local function OnTakeTaxi(slot)
  local src = CurrentNode()
  local dst = TaxiNodeName(slot)
  if not (src and dst) then return end
  local secs, estimated = TimeFor(slot)
  flight = { src = src, dst = dst, expected = secs, estimated = estimated,
             len = RouteLength(slot), mapKey = TaxiMapKey(), requested = GetTime() }
end

local function Landed()
  local f = flight
  flight = nil
  bar:Hide()
  if not (f and f.start) then return end
  local secs = GetTime() - f.start
  if secs < 5 then return end
  AddTime(f.src, f.dst, secs)
  Share(f.src, f.dst, secs)
  -- Schätzung für diese Flugkarte verbessern
  if f.len and f.len > 0 then
    local fac = Factors()[f.mapKey] or { sum = 0, len = 0 }
    fac.sum, fac.len = fac.sum + secs, fac.len + f.len
    Factors()[f.mapKey] = fac
  end
end

local ticker = 0
local function OnUpdate(_, dt)
  ticker = ticker + dt
  if ticker < 0.1 then return end
  ticker = 0
  local onTaxi = UnitOnTaxi("player")
  if flight and not flight.start then
    if onTaxi then
      flight.start = GetTime()
      bar:Show()
    elseif GetTime() - flight.requested > 10 then
      flight = nil   -- Flug kam nicht zustande
    end
  elseif flight and flight.start then
    if onTaxi then UpdateBar() else Landed() end
  end
end

---------------------------------------------------------------------------
-- Start
---------------------------------------------------------------------------
function ns.InitFlight()
  CreateBar()
  MergeBundled()

  if TakeTaxiNode then hooksecurefunc("TakeTaxiNode", function(slot) pcall(OnTakeTaxi, slot) end) end
  if TaxiNodeOnButtonEnter then
    hooksecurefunc("TaxiNodeOnButtonEnter", function(button) pcall(AddTooltip, button and button:GetID()) end)
  end
  -- Neuere Flugkarte (falls der Client sie nutzt)
  local function hookFlightMap()
    if FlightMap_FlightPointPinMixin and not ns.flightMapHooked then
      ns.flightMapHooked = true
      hooksecurefunc(FlightMap_FlightPointPinMixin, "OnMouseEnter", function(pin)
        local slot = pin.taxiNodeData and pin.taxiNodeData.slotIndex
        pcall(AddTooltip, slot)
      end)
    end
  end
  hookFlightMap()

  local f = CreateFrame("Frame")
  f:RegisterEvent("CHAT_MSG_ADDON")
  f:RegisterEvent("ADDON_LOADED")
  f:SetScript("OnEvent", function(_, event, a, b, c, d)
    if event == "CHAT_MSG_ADDON" then pcall(OnAddonMessage, a, b, c, d)
    elseif event == "ADDON_LOADED" and a == "Blizzard_FlightMap" then hookFlightMap() end
  end)
  f:SetScript("OnUpdate", OnUpdate)
end
