-- Drescher's Field Guide – Texte (Englisch als Standard, Deutsch für deDE)

local ADDON, ns = ...

local L = {
  TITLE        = "Drescher's Field Guide",
  NOW          = "Level here now",
  NEXT         = "Up next",
  DUNGEONS     = "Dungeons for you",
  NOTHING      = "Nothing found for your level.",
  LEVEL        = "Level",
  FITS         = "Good for you",
  SOON         = "A bit too high",
  HARD         = "Too high",
  LOW          = "Too low (little XP)",
  ENEMY        = "Enemy starting area",
  FACTION_A    = "Alliance",
  FACTION_H    = "Horde",
  CONTESTED    = "Contested",
  HERBS        = "Herbs",
  ORES         = "Ores",
  CLOTH        = "Cloth (humanoids)",
  LEATHER      = "Leather (beasts)",
  NO_DATA      = "No data yet – will be collected while playing",
  NEW_ZONE     = "New in Forever",
  ALT          = "Alternative: %s",
  SKYBORNE     = "Skyborne starting area",
  MODE_LEVEL   = "Show: zones by level",
  MODE_OFF     = "Map overlay off",
  MODE_MAT     = "Show: %s",
  MAT_MENU     = "Find material …",
  ZONES_WITH   = "Zones with %s",
  CLICK_OPEN   = "Click: open map",
  LOADED       = "loaded – |cffffffff/fg|r for commands. Built live on twitch.tv/itsdrescher_",
  HELP_ROUTE   = "|cffffffff/fg|r – show/hide the route window",
  HELP_MAP     = "|cffffffff/fg map|r – switch map overlay on/off",
  HELP_ZONES   = "|cffffffff/fg zones|r – list zone IDs (for bug reports)",
  HELP_RESET   = "|cffffffff/fg reset|r – reset window and map box positions",
  ZONES_SAVED  = "%d zones listed and saved.",
  NOT_FOUND    = "not found on map yet",
  CREDIT       = "Built live on stream: twitch.tv/itsdrescher_",
}

if GetLocale() == "deDE" then
  L.NOW        = "Jetzt hier leveln"
  L.NEXT       = "Als Nächstes"
  L.DUNGEONS   = "Dungeons für dich"
  L.NOTHING    = "Nichts Passendes für dein Level gefunden."
  L.LEVEL      = "Level"
  L.FITS       = "Passt für dich"
  L.SOON       = "Etwas zu hoch"
  L.HARD       = "Zu hoch"
  L.LOW        = "Zu niedrig (wenig EP)"
  L.ENEMY      = "Startgebiet der Gegenseite"
  L.FACTION_A  = "Allianz"
  L.FACTION_H  = "Horde"
  L.CONTESTED  = "Umkämpft"
  L.HERBS      = "Kräuter"
  L.ORES       = "Erze"
  L.CLOTH      = "Stoff (Humanoide)"
  L.LEATHER    = "Leder (Tiere)"
  L.NO_DATA    = "Noch keine Daten – werden beim Spielen gesammelt"
  L.NEW_ZONE   = "Neu in Forever"
  L.ALT        = "Alternative: %s"
  L.SKYBORNE   = "Startgebiet der Himmelsgeborenen"
  L.MODE_LEVEL = "Anzeige: Gebiete nach Level"
  L.MODE_OFF   = "Karten-Anzeige aus"
  L.MODE_MAT   = "Anzeige: %s"
  L.MAT_MENU   = "Material suchen …"
  L.ZONES_WITH = "Gebiete mit %s"
  L.CLICK_OPEN = "Klick: Karte öffnen"
  L.LOADED     = "geladen – |cffffffff/fg|r für Befehle. Live entwickelt auf twitch.tv/itsdrescher_"
  L.HELP_ROUTE = "|cffffffff/fg|r – Routen-Fenster ein/aus"
  L.HELP_MAP   = "|cffffffff/fg map|r – Karten-Anzeige ein/aus"
  L.HELP_ZONES = "|cffffffff/fg zones|r – Gebiets-IDs auflisten (für Fehlermeldungen)"
  L.HELP_RESET = "|cffffffff/fg reset|r – Fenster und Karten-Infobox zurücksetzen"
  L.ZONES_SAVED = "%d Gebiete aufgelistet und gespeichert."
  L.NOT_FOUND  = "noch nicht auf der Karte gefunden"
  L.CREDIT     = "Live entwickelt im Stream: twitch.tv/itsdrescher_"
end

ns.L = L
ns.IS_DE = GetLocale() == "deDE"
