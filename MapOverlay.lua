-- Drescher's Field Guide – Weltkarte
-- Kontinentkarte: Gebiete nach Level (oder nach gesuchtem Material) eingefärbt + Beschriftung.
-- Zonenkarte: Infobox mit Level-Spanne, Bewertung und Materialien.

local ADDON, ns = ...
local L = ns.L

local layer, labels, shapes = nil, {}, {}
local infoBox, modeButton
local shapeCache = {}   -- [contMap..":"..zoneMap] = Highlight-Info oder false

---------------------------------------------------------------------------
-- Hilfen
---------------------------------------------------------------------------
local function Map() return WorldMapFrame end

local function FrameLevel(map, canvas, kind, extra)
  local base = canvas:GetFrameLevel() + (extra or 0)
  local mgr = map.GetPinFrameLevelsManager and map:GetPinFrameLevelsManager()
  if mgr and mgr.GetValidFrameLevel then
    local ok, lvl = pcall(mgr.GetValidFrameLevel, mgr, kind)
    if ok and type(lvl) == "number" then base = lvl + (extra or 0) end
  end
  return math.min(base, 9000)
end

-- Einen Punkt finden, der sicher im Gebiet liegt (Mitte reicht nicht immer)
local function PointInZone(contMap, zoneMap)
  if not (C_Map.GetMapRectOnMap and C_Map.GetMapInfoAtPosition) then return end
  local ok, minX, maxX, minY, maxY = pcall(C_Map.GetMapRectOnMap, zoneMap, contMap)
  if not ok or not minX then return end
  local rect = { minX, maxX, minY, maxY }
  local best
  for _, fy in ipairs({ 0.5, 0.4, 0.6, 0.3, 0.7 }) do
    for _, fx in ipairs({ 0.5, 0.4, 0.6, 0.3, 0.7, 0.2, 0.8 }) do
      local x, y = minX + (maxX - minX) * fx, minY + (maxY - minY) * fy
      local ok2, info = pcall(C_Map.GetMapInfoAtPosition, contMap, x, y)
      if ok2 and info and info.mapID == zoneMap then return x, y, rect end
      best = best or { x, y }
    end
  end
  return nil
end

local function ZoneShape(contMap, zoneMap)
  local key = contMap .. ":" .. zoneMap
  if shapeCache[key] ~= nil then return shapeCache[key] end
  local x, y, rect = PointInZone(contMap, zoneMap)
  local shape = false
  if x then
    shape = { cx = x, cy = y, rect = rect }
    if C_Map.GetMapHighlightInfoAtPosition then
      local ok, fileID, atlasID, texX, texY, w, h, posX, posY = pcall(C_Map.GetMapHighlightInfoAtPosition, contMap, x, y)
      local hasFile = type(fileID) == "number" and fileID > 0
      local hasAtlas = type(atlasID) == "string" and atlasID ~= ""
      if ok and (hasFile or hasAtlas) and type(w) == "number" and w > 0 then
        shape.file = hasFile and fileID or nil
        shape.atlas = hasAtlas and atlasID or nil
        shape.texX, shape.texY, shape.w, shape.h, shape.x, shape.y = texX, texY, w, h, posX, posY
      end
    end
  end
  shapeCache[key] = shape
  return shape
end

---------------------------------------------------------------------------
-- Farben je nach Modus
---------------------------------------------------------------------------
local function ColorFor(z)
  local mode = ns.db.mode
  if type(mode) == "number" then
    if ns.ZoneHas(z, mode) then return 1, 0.8, 0.1, 0.55, true end
    return 0.2, 0.2, 0.2, 0.35, false
  end
  local status, r, g, b = ns.Rate(z)
  local a = (status == "fits") and 0.5 or (status == "soon") and 0.42 or (status == "hard") and 0.32 or 0.22
  return r, g, b, a, status == "fits" or status == "soon"
end

---------------------------------------------------------------------------
-- Kontinentkarte einfärben
---------------------------------------------------------------------------
local function GetShapeTex(i)
  local t = shapes[i]
  if not t then
    t = layer:CreateTexture(nil, "ARTWORK")
    shapes[i] = t
  end
  return t
end

local function GetLabel(i)
  local l = labels[i]
  if not l then
    l = CreateFrame("Frame", nil, layer)
    l:SetSize(110, 30)
    l.text = l:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    l.text:SetPoint("CENTER")
    l.text:SetShadowOffset(1, -1)
    l.text:SetJustifyH("CENTER")
    l:EnableMouse(true)
    l:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      ns.ZoneTooltip(GameTooltip, self.zone)
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine(L.CLICK_OPEN, 0.5, 0.5, 0.5)
      GameTooltip:Show()
    end)
    l:SetScript("OnLeave", function() GameTooltip:Hide() end)
    l:SetScript("OnMouseUp", function(self) if self.zone.uiMap then Map():SetMapID(self.zone.uiMap) end end)
    labels[i] = l
  end
  return l
end

local function DrawContinent(map, canvas, mapID)
  local W, H = canvas:GetWidth(), canvas:GetHeight()
  local scale = 1 / ((map.GetCanvasScale and map:GetCanvasScale()) or 1)
  local n, m = 0, 0
  for _, z in ipairs(ns.ZONES) do
    if z.uiMap and z.contMap == mapID then
      local shape = ZoneShape(mapID, z.uiMap)
      if shape then
        local r, g, b, a, strong = ColorFor(z)
        if shape.w and not ns.db.forceBlobs then
          n = n + 1
          local t = GetShapeTex(n)
          if t.mask then t:RemoveMaskTexture(t.mask) end
          if shape.file then t:SetTexture(shape.file) else t:SetAtlas(shape.atlas) end
          t:SetTexCoord(0, shape.texX or 1, 0, shape.texY or 1)
          t:SetBlendMode("ADD")
          t:SetVertexColor(r, g, b, a)
          -- Werte sind normalerweise 0–1 (Anteil der Karte); sonst schon in Karten-Einheiten
          local norm = shape.w <= 1.5
          local sx, sy = norm and W or 1, norm and H or 1
          t:ClearAllPoints()
          t:SetPoint("TOPLEFT", canvas, "TOPLEFT", shape.x * sx, -shape.y * sy)
          t:SetSize(shape.w * sx, shape.h * sy)
          t:Show()
        elseif shape.rect then
          -- Ersatz: weiche Farbfläche in Größe des Gebiets
          n = n + 1
          local t = GetShapeTex(n)
          local minX, maxX, minY, maxY = unpack(shape.rect)
          t:SetTexture("Interface\\Buttons\\WHITE8X8")
          t:SetTexCoord(0, 1, 0, 1)
          if t.CreateMaskTexture or layer.CreateMaskTexture then
            if not t.mask then
              t.mask = layer:CreateMaskTexture()
              t.mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
              t.mask:SetAllPoints(t)
            end
            t:AddMaskTexture(t.mask)
          end
          t:SetBlendMode("BLEND")
          t:SetVertexColor(r, g, b, a * 0.7)
          local w, h = (maxX - minX) * W * 0.75, (maxY - minY) * H * 0.75
          t:ClearAllPoints()
          t:SetPoint("CENTER", canvas, "TOPLEFT", shape.cx * W, -shape.cy * H)
          t:SetSize(w, h)
          t:Show()
        end
        m = m + 1
        local l = GetLabel(m)
        l.zone = z
        l:SetScale(scale)
        l:ClearAllPoints()
        l:SetPoint("CENTER", canvas, "TOPLEFT", shape.cx * W / scale, -shape.cy * H / scale)
        local range = ("%d–%d"):format(z.min, z.max)
        l.text:SetText(range)
        l.text:SetTextColor(math.min(1, r + 0.15), math.min(1, g + 0.15), math.min(1, b + 0.15))
        l:SetAlpha(strong and 1 or 0.75)
        l:Show()
      end
    end
  end
  for i = n + 1, #shapes do shapes[i]:Hide() end
  for i = m + 1, #labels do labels[i]:Hide() end
end

---------------------------------------------------------------------------
-- Zonenkarte: Infobox
---------------------------------------------------------------------------
local function CreateInfoBox(map)
  local parent = map.ScrollContainer or map
  local box = CreateFrame("Frame", nil, parent, BackdropTemplateMixin and "BackdropTemplate" or nil)
  box:SetSize(250, 60)

  -- Position: frei verschiebbar, wird gespeichert (relativ zur linken oberen Kartenecke)
  local function applyPos()
    local p = ns.db.infoPos or { 46, -6 }
    box:ClearAllPoints()
    box:SetPoint("TOPLEFT", parent, "TOPLEFT", p[1], p[2])
  end
  applyPos()
  box:SetMovable(true)
  box:RegisterForDrag("LeftButton")
  box:SetScript("OnDragStart", function(self) GameTooltip:Hide(); self:StartMoving() end)
  box:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local s = self:GetEffectiveScale() / parent:GetEffectiveScale()
    local x = self:GetLeft() * s - parent:GetLeft()
    local y = self:GetTop() * s - parent:GetTop()
    -- innerhalb der Karte halten
    x = math.max(0, math.min(x, parent:GetWidth() - self:GetWidth()))
    y = math.min(0, math.max(y, -(parent:GetHeight() - self:GetHeight())))
    ns.db.infoPos = { x, y }
    applyPos()
  end)
  ns.ResetInfoPosition = function() ns.db.infoPos = nil; applyPos() end
  if box.SetBackdrop then
    box:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    box:SetBackdropColor(0.04, 0.04, 0.06, 0.85)
    box:SetBackdropBorderColor(0.88, 0.69, 0.25, 0.8)
  end
  box.title = box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  box.title:SetPoint("TOPLEFT", 10, -8)
  box.title:SetJustifyH("LEFT")
  box.status = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  box.status:SetPoint("TOPLEFT", box.title, "BOTTOMLEFT", 0, -3)
  box.status:SetJustifyH("LEFT")
  box.mats = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  box.mats:SetPoint("TOPLEFT", box.status, "BOTTOMLEFT", 0, -5)
  box.mats:SetWidth(230)
  box.mats:SetJustifyH("LEFT")
  box.mats:SetWordWrap(true)
  box:EnableMouse(true)
  box:SetScript("OnEnter", function(self)
    if not self.zone then return end
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
    ns.ZoneTooltip(GameTooltip, self.zone)
    GameTooltip:Show()
  end)
  box:SetScript("OnLeave", function() GameTooltip:Hide() end)
  return box
end

local function ShowInfo(map, z)
  infoBox = infoBox or CreateInfoBox(map)
  infoBox:SetFrameLevel((map.ScrollContainer or map):GetFrameLevel() + 500)
  local _, r, g, b, text = ns.Rate(z)
  infoBox.zone = z
  infoBox.title:SetText(("%s  |cffffffff%d–%d|r"):format(ns.ZoneName(z), z.min, z.max))
  infoBox.status:SetText(text)
  infoBox.status:SetTextColor(r, g, b)
  local parts = {}
  local mode = ns.db.mode
  for _, group in ipairs(ns.Materials(z)) do
    local names = {}
    for _, id in ipairs(group[2]) do
      local nm = ns.ItemName(id)
      if type(mode) == "number" and id == mode then nm = "|cffffd100" .. nm .. "|r" end
      names[#names + 1] = nm
    end
    if #names > 0 then parts[#parts + 1] = "|cffe0b040" .. group[1] .. ":|r " .. table.concat(names, ", ") end
  end
  if z.new and not z.herbs then table.insert(parts, 1, "|cff999999" .. L.NO_DATA .. "|r") end
  infoBox.mats:SetText(table.concat(parts, "\n"))
  infoBox:SetHeight(30 + infoBox.status:GetStringHeight() + infoBox.mats:GetStringHeight() + 12)
  infoBox:Show()
end

---------------------------------------------------------------------------
-- Modus-Knopf auf der Karte (Level / Material / Aus)
---------------------------------------------------------------------------
local function MaterialMenuItems()
  local groups = {
    { L.HERBS, ns.HERB }, { L.ORES, ns.ORE },
  }
  local out = {}
  for _, g in ipairs(groups) do
    local ids = {}
    for _, id in pairs(g[2]) do ids[#ids + 1] = id end
    table.sort(ids, function(a, b) return ns.ItemName(a) < ns.ItemName(b) end)
    out[#out + 1] = { g[1], ids }
  end
  local cloth, leather = {}, {}
  for _, c in ipairs(ns.CLOTH) do cloth[#cloth + 1] = c.item end
  for _, c in ipairs(ns.LEATHER) do leather[#leather + 1] = c.item end
  out[#out + 1] = { L.CLOTH, cloth }
  out[#out + 1] = { L.LEATHER, leather }
  return out
end

local function SetMode(mode)
  ns.db.mode = mode
  ns.RefreshOverlay()
end

local function ModeText()
  local mode = ns.db.mode
  if mode == "off" then return L.MODE_OFF end
  if type(mode) == "number" then return L.MODE_MAT:format(ns.ItemName(mode)) end
  return L.MODE_LEVEL
end

local function OpenMenu(owner)
  if MenuUtil and MenuUtil.CreateContextMenu then
    MenuUtil.CreateContextMenu(owner, function(_, root)
      root:CreateTitle(L.TITLE)
      root:CreateButton(L.MODE_LEVEL, function() SetMode("level") end)
      local sub = root:CreateButton(L.MAT_MENU)
      for _, g in ipairs(MaterialMenuItems()) do
        local grp = sub:CreateButton(g[1])
        for _, id in ipairs(g[2]) do
          grp:CreateButton(ns.ItemName(id), function() SetMode(id) end)
        end
      end
      root:CreateButton(L.MODE_OFF, function() SetMode("off") end)
    end)
    return
  end
  -- Ältere Clients: klassisches Dropdown
  if not EasyMenu then return end
  local menu = {
    { text = L.TITLE, isTitle = true, notCheckable = true },
    { text = L.MODE_LEVEL, notCheckable = true, func = function() SetMode("level") end },
  }
  local mats = { text = L.MAT_MENU, notCheckable = true, hasArrow = true, menuList = {} }
  for _, g in ipairs(MaterialMenuItems()) do
    local grp = { text = g[1], notCheckable = true, hasArrow = true, menuList = {} }
    for _, id in ipairs(g[2]) do
      grp.menuList[#grp.menuList + 1] = { text = ns.ItemName(id), notCheckable = true, func = function() SetMode(id); CloseDropDownMenus() end }
    end
    mats.menuList[#mats.menuList + 1] = grp
  end
  menu[#menu + 1] = mats
  menu[#menu + 1] = { text = L.MODE_OFF, notCheckable = true, func = function() SetMode("off") end }
  ns.dropdown = ns.dropdown or CreateFrame("Frame", "DFGMapDropdown", UIParent, "UIDropDownMenuTemplate")
  EasyMenu(menu, ns.dropdown, owner, 0, 0, "MENU")
end

local function CreateModeButton(map)
  local parent = map.ScrollContainer or map
  local b = CreateFrame("Button", nil, parent, BackdropTemplateMixin and "BackdropTemplate" or nil)
  b:SetSize(200, 22)
  b:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -46, -6)
  if b.SetBackdrop then
    b:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    b:SetBackdropColor(0.04, 0.04, 0.06, 0.85)
    b:SetBackdropBorderColor(0.88, 0.69, 0.25, 0.8)
  end
  b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.text:SetPoint("CENTER")
  b:SetScript("OnClick", function(self) OpenMenu(self) end)
  b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
    GameTooltip:AddLine(L.TITLE, 0.88, 0.69, 0.25)
    GameTooltip:AddLine(L.CREDIT, 0.6, 0.6, 0.6)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  return b
end

---------------------------------------------------------------------------
-- Aktualisieren
---------------------------------------------------------------------------
-- /fg debug: zeigt, was WoW für die Umrisse der Gebiete liefert
function ns.OverlayDebug()
  local map = Map()
  local mapID = map and map:GetMapID()
  if not map or not map:IsShown() then ns.Print("Bitte zuerst die Kontinentkarte öffnen (M).") return end
  local count = 0
  for _, z in ipairs(ns.ZONES) do
    if z.uiMap and z.contMap == mapID and count < 3 then
      count = count + 1
      local x, y = PointInZone(mapID, z.uiMap)
      if not x then
        print(("  %s: kein Punkt im Gebiet gefunden"):format(ns.ZoneName(z)))
      else
        local res = { pcall(C_Map.GetMapHighlightInfoAtPosition, mapID, x, y) }
        for i = 1, #res do res[i] = tostring(res[i]) end
        print(("  %s @ %.3f/%.3f → %s"):format(ns.ZoneName(z), x, y, table.concat(res, ", ")))
      end
    end
  end
  print(("  Karte %s, Gebiete auf dieser Karte: %d"):format(tostring(mapID), count))
end

function ns.RefreshOverlay()
  local map = Map()
  if not map or not map:IsShown() or not map.GetCanvas then return end
  local canvas, mapID = map:GetCanvas(), map:GetMapID()
  if not canvas or not mapID then return end

  if not layer then
    layer = CreateFrame("Frame", nil, canvas)
    layer:SetAllPoints(canvas)
  end
  layer:SetParent(canvas)
  layer:SetFrameLevel(FrameLevel(map, canvas, "PIN_FRAME_LEVEL_MAP_HIGHLIGHT", 1))

  modeButton = modeButton or CreateModeButton(map)
  modeButton:SetFrameLevel((map.ScrollContainer or map):GetFrameLevel() + 500)
  modeButton.text:SetText(ModeText())
  modeButton:Show()

  local off = ns.db.mode == "off"
  local zone = ns.ZONE_BY_MAP and ns.ZONE_BY_MAP[mapID]
  local isContinent = mapID == 1414 or mapID == 1415
  if not isContinent and ns.ZONES then
    for _, z in ipairs(ns.ZONES) do if z.contMap == mapID then isContinent = true break end end
  end

  if off or not isContinent then
    layer:Hide()
  else
    layer:Show()
    DrawContinent(map, canvas, mapID)
  end

  if zone and not off then ShowInfo(map, zone) elseif infoBox then infoBox:Hide() end
end

function ns.InitOverlay()
  local map = Map()
  if not map or not map.GetCanvas then return end
  map:HookScript("OnShow", ns.RefreshOverlay)
  if map.OnMapChanged then hooksecurefunc(map, "OnMapChanged", ns.RefreshOverlay) end
  if map.OnCanvasScaleChanged then hooksecurefunc(map, "OnCanvasScaleChanged", ns.RefreshOverlay) end
end
