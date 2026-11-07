-- Drescher's Field Guide – Minimap-Knopf
-- Linksklick: Routen-Fenster an/aus · Rechtsklick: Karten-Anzeige an/aus · Ziehen: verschieben

local ADDON, ns = ...
local L = ns.L

local ICON = "Interface\\AddOns\\DreschersFieldGuide\\icon"
local button

local function Place()
  local angle = math.rad(ns.db.minimapAngle or 210)
  local r = (Minimap:GetWidth() / 2) + 10
  button:ClearAllPoints()
  button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * r, math.sin(angle) * r)
end

local function OnDragUpdate()
  local mx, my = Minimap:GetCenter()
  local cx, cy = GetCursorPosition()
  local scale = Minimap:GetEffectiveScale()
  cx, cy = cx / scale, cy / scale
  ns.db.minimapAngle = math.deg(math.atan2(cy - my, cx - mx)) % 360
  Place()
end

function ns.InitMinimap()
  if not Minimap then return end
  button = CreateFrame("Button", "DreschersFieldGuideMinimapButton", Minimap)
  button:SetSize(31, 31)
  button:SetFrameStrata("MEDIUM")
  button:SetFrameLevel(8)
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  button:RegisterForDrag("LeftButton")
  button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

  local bg = button:CreateTexture(nil, "BACKGROUND")
  bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
  bg:SetSize(20, 20)
  bg:SetPoint("TOPLEFT", 7, -5)

  local icon = button:CreateTexture(nil, "ARTWORK")
  icon:SetTexture(ICON)
  icon:SetSize(19, 19)
  icon:SetPoint("TOPLEFT", 6, -6)
  if button.CreateMaskTexture then
    local mask = button:CreateMaskTexture()
    mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(icon)
    icon:AddMaskTexture(mask)
  end

  local border = button:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetSize(53, 53)
  border:SetPoint("TOPLEFT")

  button:SetScript("OnClick", function(_, mouse)
    if mouse == "RightButton" then
      ns.db.mode = (ns.db.mode == "off") and "level" or "off"
      ns.Print(ns.db.mode == "off" and L.MODE_OFF or L.MODE_LEVEL)
      if ns.RefreshOverlay then ns.RefreshOverlay() end
    else
      if ns.ToggleRoute then ns.ToggleRoute() end
    end
  end)
  button:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", OnDragUpdate) end)
  button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
  button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine(L.TITLE, 0.88, 0.69, 0.25)
    GameTooltip:AddLine(L.MM_LEFT, 1, 1, 1)
    GameTooltip:AddLine(L.MM_RIGHT, 1, 1, 1)
    GameTooltip:AddLine(L.MM_DRAG, 0.6, 0.6, 0.6)
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", function() GameTooltip:Hide() end)

  Place()
  button:SetShown(not ns.db.minimapHidden)
end

function ns.ToggleMinimapButton()
  if not button then return end
  ns.db.minimapHidden = not ns.db.minimapHidden
  button:SetShown(not ns.db.minimapHidden)
end

-- Addon-Sammelmenü neuerer Clients (falls vorhanden)
function DreschersFieldGuide_OnCompartmentClick(_, mouse)
  if mouse == "RightButton" then
    ns.db.mode = (ns.db.mode == "off") and "level" or "off"
    if ns.RefreshOverlay then ns.RefreshOverlay() end
  elseif ns.ToggleRoute then
    ns.ToggleRoute()
  end
end
