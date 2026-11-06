-- Drescher's Field Guide – Daten
-- Gebiete, Dungeons und Materialien. Eigene Zusammenstellung; Level-Spannen der
-- neuen Forever-Gebiete nach Ankündigungen – bitte im Spiel prüfen und melden.

local ADDON, ns = ...

-- Fraktion: "A" = Allianz, "H" = Horde, "C" = umkämpft (beide)
-- map  = uiMapID (Classic); für neue Forever-Gebiete unbekannt → Suche über Namen
-- find = Namensteile zum Finden der Karte (klein geschrieben, EN/DE)
-- herbs/ores = Item-IDs (Namen kommen automatisch in der Spielsprache)

local H = {   -- Kräuter
  peacebloom = 2447, silverleaf = 765, earthroot = 2449, mageroyal = 785, briarthorn = 2450,
  stranglekelp = 3820, bruiseweed = 2453, steelbloom = 3355, gravemoss = 3369, kingsblood = 3356,
  liferoot = 3357, fadeleaf = 3818, goldthorn = 3821, khadgar = 3358, wintersbite = 3819,
  firebloom = 4625, purplelotus = 8831, arthas = 8836, sungrass = 8838, blindweed = 8839,
  ghostmushroom = 8845, gromsblood = 8846, sansam = 13464, dreamfoil = 13463, silversage = 13465,
  plaguebloom = 13466, icecap = 13467, blacklotus = 13468,
}
local O = {   -- Erze
  copper = 2770, tin = 2771, silver = 2775, iron = 2772, gold = 2776, mithril = 3858,
  truesilver = 7911, thorium = 10620, darkiron = 11370,
}
ns.HERB, ns.ORE = H, O

-- Englische Namen als Rückfall, solange WoW die Item-Namen noch nicht geladen hat
ns.ITEM_FALLBACK = {
  [2447] = "Peacebloom", [765] = "Silverleaf", [2449] = "Earthroot", [785] = "Mageroyal", [2450] = "Briarthorn",
  [3820] = "Stranglekelp", [2453] = "Bruiseweed", [3355] = "Wild Steelbloom", [3369] = "Grave Moss",
  [3356] = "Kingsblood", [3357] = "Liferoot", [3818] = "Fadeleaf", [3821] = "Goldthorn", [3358] = "Khadgar's Whisker",
  [3819] = "Wintersbite", [4625] = "Firebloom", [8831] = "Purple Lotus", [8836] = "Arthas' Tears", [8838] = "Sungrass",
  [8839] = "Blindweed", [8845] = "Ghost Mushroom", [8846] = "Gromsblood", [13464] = "Golden Sansam",
  [13463] = "Dreamfoil", [13465] = "Mountain Silversage", [13466] = "Plaguebloom", [13467] = "Icecap",
  [13468] = "Black Lotus",
  [2770] = "Copper Ore", [2771] = "Tin Ore", [2775] = "Silver Ore", [2772] = "Iron Ore", [2776] = "Gold Ore",
  [3858] = "Mithril Ore", [7911] = "Truesilver Ore", [10620] = "Thorium Ore", [11370] = "Dark Iron Ore",
  [2589] = "Linen Cloth", [2592] = "Wool Cloth", [4306] = "Silk Cloth", [4338] = "Mageweave Cloth",
  [14047] = "Runecloth", [2318] = "Light Leather", [2319] = "Medium Leather", [4234] = "Heavy Leather",
  [4304] = "Thick Leather", [8170] = "Rugged Leather",
}

-- Stoff (Humanoide) und Leder (Tiere) hängen am Level der Gegner
ns.CLOTH = {
  { item = 2589,  min = 5,  max = 16 }, { item = 2592,  min = 14, max = 26 },
  { item = 4306,  min = 24, max = 38 }, { item = 4338,  min = 34, max = 50 },
  { item = 14047, min = 46, max = 60 },
}
ns.LEATHER = {
  { item = 2318, min = 5,  max = 20 }, { item = 2319, min = 18, max = 30 },
  { item = 4234, min = 28, max = 40 }, { item = 4304, min = 38, max = 50 },
  { item = 8170, min = 48, max = 60 },
}

ns.ZONES = {
  ---------------------------------------------------------------- Östliche Königreiche
  { key = "elwynn", map = 1429, cont = 1415, min = 1, max = 10, faction = "A", en = "Elwynn Forest", de = "Wald von Elwynn",
    herbs = { H.peacebloom, H.silverleaf, H.earthroot }, ores = { O.copper } },
  { key = "dunmorogh", map = 1426, cont = 1415, min = 1, max = 10, faction = "A", en = "Dun Morogh", de = "Dun Morogh",
    herbs = { H.peacebloom, H.silverleaf, H.earthroot }, ores = { O.copper } },
  { key = "tirisfal", map = 1420, cont = 1415, min = 1, max = 10, faction = "H", en = "Tirisfal Glades", de = "Tirisfal",
    herbs = { H.peacebloom, H.silverleaf, H.earthroot }, ores = { O.copper } },
  { key = "westfall", map = 1436, cont = 1415, min = 10, max = 20, faction = "A", en = "Westfall", de = "Westfall",
    herbs = { H.peacebloom, H.silverleaf, H.earthroot, H.mageroyal, H.briarthorn }, ores = { O.copper, O.tin } },
  { key = "lochmodan", map = 1432, cont = 1415, min = 10, max = 20, faction = "A", en = "Loch Modan", de = "Loch Modan",
    herbs = { H.peacebloom, H.silverleaf, H.earthroot, H.mageroyal, H.briarthorn }, ores = { O.copper, O.tin } },
  { key = "silverpine", map = 1421, cont = 1415, min = 10, max = 20, faction = "H", en = "Silverpine Forest", de = "Silberwald",
    herbs = { H.peacebloom, H.silverleaf, H.earthroot, H.mageroyal, H.briarthorn }, ores = { O.copper, O.tin } },
  { key = "redridge", map = 1433, cont = 1415, min = 15, max = 25, faction = "A", en = "Redridge Mountains", de = "Rotkammgebirge",
    herbs = { H.mageroyal, H.briarthorn, H.bruiseweed }, ores = { O.copper, O.tin, O.silver } },
  { key = "duskwood", map = 1431, cont = 1415, min = 18, max = 30, faction = "A", en = "Duskwood", de = "Dämmerwald",
    herbs = { H.briarthorn, H.bruiseweed, H.gravemoss, H.kingsblood }, ores = { O.tin, O.silver, O.iron } },
  { key = "wetlands", map = 1437, cont = 1415, min = 20, max = 30, faction = "A", en = "Wetlands", de = "Sumpfland",
    herbs = { H.bruiseweed, H.steelbloom, H.kingsblood, H.stranglekelp, H.gravemoss }, ores = { O.tin, O.silver, O.iron } },
  { key = "hillsbrad", map = 1424, cont = 1415, min = 20, max = 30, faction = "C", en = "Hillsbrad Foothills", de = "Vorgebirge des Hügellands",
    herbs = { H.bruiseweed, H.steelbloom, H.kingsblood, H.liferoot }, ores = { O.tin, O.silver, O.iron } },
  { key = "alterac", map = 1416, cont = 1415, min = 30, max = 40, faction = "C", en = "Alterac Mountains", de = "Alteracgebirge",
    herbs = { H.kingsblood, H.liferoot, H.fadeleaf, H.goldthorn, H.steelbloom }, ores = { O.iron, O.gold, O.silver } },
  { key = "arathi", map = 1417, cont = 1415, min = 30, max = 40, faction = "C", en = "Arathi Highlands", de = "Arathihochland",
    herbs = { H.steelbloom, H.kingsblood, H.liferoot, H.goldthorn, H.fadeleaf, H.khadgar }, ores = { O.iron, O.gold, O.silver, O.mithril } },
  { key = "stranglethorn", map = 1434, cont = 1415, min = 30, max = 45, faction = "C", en = "Stranglethorn Vale", de = "Schlingendorntal",
    herbs = { H.liferoot, H.fadeleaf, H.goldthorn, H.khadgar, H.purplelotus, H.stranglekelp }, ores = { O.iron, O.gold, O.silver, O.mithril, O.truesilver },
    alt = "riverglades" },
  { key = "riverglades", cont = 1415, min = 36, max = 44, faction = "C", en = "Riverglades", de = "Riverglades", new = true,
    find = { "riverglade", "flussau", "flusslicht" }, alt = "stranglethorn" },
  { key = "badlands", map = 1418, cont = 1415, min = 35, max = 45, faction = "C", en = "Badlands", de = "Ödland",
    herbs = { H.kingsblood, H.fadeleaf, H.goldthorn, H.khadgar, H.firebloom }, ores = { O.iron, O.gold, O.mithril, O.truesilver } },
  { key = "swamp", map = 1435, cont = 1415, min = 35, max = 45, faction = "C", en = "Swamp of Sorrows", de = "Sümpfe des Elends",
    herbs = { H.kingsblood, H.liferoot, H.fadeleaf, H.goldthorn, H.khadgar, H.blindweed }, ores = { O.iron, O.gold, O.mithril } },
  { key = "hinterlands", map = 1425, cont = 1415, min = 40, max = 50, faction = "C", en = "The Hinterlands", de = "Hinterland",
    herbs = { H.goldthorn, H.khadgar, H.purplelotus, H.sungrass, H.arthas }, ores = { O.gold, O.mithril, O.truesilver } },
  { key = "searing", map = 1427, cont = 1415, min = 43, max = 50, faction = "C", en = "Searing Gorge", de = "Sengende Schlucht",
    herbs = { H.firebloom }, ores = { O.iron, O.gold, O.mithril, O.truesilver, O.thorium } },
  { key = "blasted", map = 1419, cont = 1415, min = 45, max = 55, faction = "C", en = "Blasted Lands", de = "Verwüstete Lande",
    herbs = { H.firebloom, H.sungrass, H.gromsblood }, ores = { O.mithril, O.truesilver, O.thorium } },
  { key = "burning", map = 1428, cont = 1415, min = 50, max = 58, faction = "C", en = "Burning Steppes", de = "Brennende Steppe",
    herbs = { H.sungrass, H.sansam, H.dreamfoil, H.silversage, H.firebloom }, ores = { O.mithril, O.truesilver, O.gold, O.thorium } },
  { key = "wpl", map = 1422, cont = 1415, min = 51, max = 58, faction = "C", en = "Western Plaguelands", de = "Westliche Pestländer",
    herbs = { H.arthas, H.sungrass, H.plaguebloom, H.sansam, H.dreamfoil }, ores = { O.mithril, O.truesilver, O.gold, O.thorium } },
  { key = "epl", map = 1423, cont = 1415, min = 53, max = 60, faction = "C", en = "Eastern Plaguelands", de = "Östliche Pestländer",
    herbs = { H.arthas, H.sungrass, H.plaguebloom, H.sansam, H.dreamfoil, H.silversage, H.blacklotus }, ores = { O.mithril, O.truesilver, O.thorium } },
  { key = "deadwind", map = 1430, cont = 1415, min = 55, max = 60, faction = "C", en = "Deadwind Pass", de = "Gebirgspass der Totenwinde",
    herbs = { H.silversage }, ores = { O.thorium } },

  ---------------------------------------------------------------- Kalimdor
  { key = "teldrassil", map = 1438, cont = 1414, min = 1, max = 10, faction = "A", en = "Teldrassil", de = "Teldrassil",
    herbs = { H.peacebloom, H.silverleaf, H.earthroot }, ores = {} },
  { key = "durotar", map = 1411, cont = 1414, min = 1, max = 10, faction = "H", en = "Durotar", de = "Durotar",
    herbs = { H.peacebloom, H.silverleaf, H.earthroot }, ores = { O.copper } },
  { key = "mulgore", map = 1412, cont = 1414, min = 1, max = 10, faction = "H", en = "Mulgore", de = "Mulgore",
    herbs = { H.peacebloom, H.silverleaf, H.earthroot }, ores = { O.copper } },
  { key = "darkshore", map = 1439, cont = 1414, min = 10, max = 20, faction = "A", en = "Darkshore", de = "Dunkelküste",
    herbs = { H.peacebloom, H.silverleaf, H.earthroot, H.mageroyal, H.briarthorn, H.stranglekelp }, ores = { O.copper, O.tin } },
  { key = "barrens", map = 1413, cont = 1414, min = 10, max = 25, faction = "H", en = "The Barrens", de = "Brachland",
    herbs = { H.peacebloom, H.silverleaf, H.earthroot, H.mageroyal, H.briarthorn, H.bruiseweed, H.stranglekelp }, ores = { O.copper, O.tin, O.silver } },
  { key = "stonetalon", map = 1442, cont = 1414, min = 15, max = 27, faction = "C", en = "Stonetalon Mountains", de = "Steinkrallengebirge",
    herbs = { H.briarthorn, H.bruiseweed, H.steelbloom, H.kingsblood }, ores = { O.tin, O.silver, O.iron } },
  { key = "ashenvale", map = 1440, cont = 1414, min = 18, max = 30, faction = "C", en = "Ashenvale", de = "Eschental",
    herbs = { H.mageroyal, H.briarthorn, H.bruiseweed, H.steelbloom, H.stranglekelp, H.kingsblood }, ores = { O.tin, O.silver, O.iron } },
  { key = "needles", map = 1441, cont = 1414, min = 25, max = 35, faction = "C", en = "Thousand Needles", de = "Tausend Nadeln",
    herbs = { H.steelbloom, H.kingsblood, H.fadeleaf }, ores = { O.tin, O.silver, O.iron, O.gold } },
  { key = "desolace", map = 1443, cont = 1414, min = 30, max = 40, faction = "C", en = "Desolace", de = "Desolace",
    herbs = { H.steelbloom, H.kingsblood, H.fadeleaf, H.goldthorn, H.khadgar }, ores = { O.iron, O.gold, O.silver, O.mithril } },
  { key = "dustwallow", map = 1445, cont = 1414, min = 35, max = 45, faction = "C", en = "Dustwallow Marsh", de = "Düstermarschen",
    herbs = { H.liferoot, H.fadeleaf, H.goldthorn, H.khadgar, H.purplelotus }, ores = { O.iron, O.gold, O.mithril } },
  { key = "feralas", map = 1444, cont = 1414, min = 40, max = 50, faction = "C", en = "Feralas", de = "Feralas",
    herbs = { H.khadgar, H.purplelotus, H.sungrass, H.goldthorn, H.gromsblood }, ores = { O.iron, O.gold, O.mithril, O.truesilver } },
  { key = "tanaris", map = 1446, cont = 1414, min = 40, max = 50, faction = "C", en = "Tanaris", de = "Tanaris",
    herbs = { H.firebloom, H.purplelotus }, ores = { O.iron, O.gold, O.mithril, O.truesilver } },
  { key = "shendralas", cont = 1414, min = 45, max = 55, faction = "C", en = "Shen'dralas", de = "Shen'dralas", new = true,
    find = { "shen'dralas", "shen’dralas", "shendralas" } },
  { key = "azshara", map = 1447, cont = 1414, min = 45, max = 55, faction = "C", en = "Azshara", de = "Azshara",
    herbs = { H.purplelotus, H.sungrass, H.sansam, H.dreamfoil, H.silversage }, ores = { O.mithril, O.truesilver, O.gold, O.thorium } },
  { key = "felwood", map = 1448, cont = 1414, min = 48, max = 55, faction = "C", en = "Felwood", de = "Teufelswald",
    herbs = { H.arthas, H.sungrass, H.gromsblood, H.sansam, H.dreamfoil, H.plaguebloom }, ores = { O.mithril, O.truesilver, O.gold, O.thorium } },
  { key = "ungoro", map = 1449, cont = 1414, min = 48, max = 55, faction = "C", en = "Un'Goro Crater", de = "Krater von Un'Goro",
    herbs = { H.sungrass, H.blindweed, H.sansam, H.dreamfoil, H.silversage, H.ghostmushroom }, ores = { O.mithril, O.truesilver, O.gold, O.thorium } },
  { key = "winterspring", map = 1452, cont = 1414, min = 55, max = 60, faction = "C", en = "Winterspring", de = "Winterquell",
    herbs = { H.icecap, H.silversage, H.dreamfoil, H.sansam, H.blacklotus }, ores = { O.mithril, O.truesilver, O.gold, O.thorium } },
  { key = "silithus", map = 1451, cont = 1414, min = 55, max = 60, faction = "C", en = "Silithus", de = "Silithus",
    herbs = { H.sansam, H.dreamfoil, H.silversage, H.blacklotus }, ores = { O.truesilver, O.thorium } },
  { key = "hyjal", cont = 1414, min = 55, max = 60, faction = "C", en = "Mount Hyjal", de = "Hyjal", new = true,
    find = { "hyjal" } },
  { key = "moonglade", map = 1450, cont = 1414, min = 55, max = 60, faction = "C", en = "Moonglade", de = "Mondlichtung",
    herbs = {}, ores = {}, noRoute = true },

  ---------------------------------------------------------------- Zephras Isle (Himmelsgeborene)
  { key = "zephras", min = 1, max = 12, faction = "C", en = "Zephras Isle", de = "Zephras", new = true,
    find = { "zephras" }, skyborneOnly = true },
}

-- Dungeons: zone = key aus ns.ZONES (wo der Eingang liegt)
ns.DUNGEONS = {
  { en = "Ragefire Chasm",        de = "Flammenschlund",          min = 13, max = 18, zone = "durotar",     faction = "H" },
  { en = "Hall of Thanes",        de = "Hall of Thanes",          min = 13, max = 18, zone = "dunmorogh",   faction = "C", new = true },
  { en = "Ruins of Lordaeron",    de = "Ruinen von Lordaeron",    min = 15, max = 22, zone = "tirisfal",    faction = "C", new = true },
  { en = "Wailing Caverns",       de = "Höhlen des Wehklagens",   min = 17, max = 24, zone = "barrens",     faction = "C" },
  { en = "The Deadmines",         de = "Die Todesminen",          min = 17, max = 26, zone = "westfall",    faction = "C" },
  { en = "Shadowfang Keep",       de = "Burg Schattenfang",       min = 22, max = 30, zone = "silverpine",  faction = "C" },
  { en = "Blackfathom Deeps",     de = "Tiefschwarze Grotte",     min = 24, max = 32, zone = "ashenvale",   faction = "C" },
  { en = "The Stockade",          de = "Das Verlies",             min = 24, max = 32, zone = "elwynn",      faction = "A" },
  { en = "Excavation Site: Wetlands", de = "Ausgrabungsstätte: Sumpfland", min = 24, max = 29, zone = "wetlands", faction = "C", new = true },
  { en = "City of Dalaran",       de = "Dalaran",                 min = 28, max = 33, zone = "alterac",     faction = "C", new = true },
  { en = "Gnomeregan",            de = "Gnomeregan",              min = 29, max = 38, zone = "dunmorogh",   faction = "C" },
  { en = "Razorfen Kraul",        de = "Kral der Klingenhauer",   min = 29, max = 38, zone = "barrens",     faction = "C" },
  { en = "Scarlet Monastery",     de = "Scharlachrotes Kloster",  min = 34, max = 45, zone = "tirisfal",    faction = "C" },
  { en = "The Drowned City",      de = "The Drowned City",        min = 35, max = 40, zone = "stranglethorn", faction = "C", new = true },
  { en = "Razorfen Downs",        de = "Hügel der Klingenhauer",  min = 37, max = 46, zone = "barrens",     faction = "C" },
  { en = "Krol'dok Stronghold",   de = "Krol'dok Stronghold",     min = 40, max = 45, zone = "riverglades", faction = "C", new = true },
  { en = "Uldaman",               de = "Uldaman",                 min = 41, max = 51, zone = "badlands",    faction = "C" },
  { en = "Zul'Farrak",            de = "Zul'Farrak",              min = 44, max = 54, zone = "tanaris",     faction = "C" },
  { en = "Maraudon",              de = "Maraudon",                min = 46, max = 55, zone = "desolace",    faction = "C" },
  { en = "Alcaz Prison",          de = "Alcaz Prison",            min = 48, max = 53, zone = "dustwallow",  faction = "C", new = true },
  { en = "Sunken Temple",         de = "Versunkener Tempel",      min = 50, max = 60, zone = "swamp",       faction = "C" },
  { en = "Blackrock Depths",      de = "Schwarzfelstiefen",       min = 52, max = 60, zone = "searing",     faction = "C" },
  { en = "Blackmaw Hold",         de = "Blackmaw Hold",           min = 55, max = 60, zone = "azshara",     faction = "C", new = true },
  { en = "Lower Blackrock Spire", de = "Untere Schwarzfelsspitze", min = 55, max = 60, zone = "burning",    faction = "C" },
  { en = "Dire Maul",             de = "Düsterbruch",             min = 55, max = 60, zone = "feralas",     faction = "C" },
  { en = "Shaper's Terrace",      de = "Shaper's Terrace",        min = 58, max = 60, zone = "ungoro",      faction = "C", new = true },
  { en = "Scholomance",           de = "Scholomance",             min = 58, max = 60, zone = "wpl",         faction = "C" },
  { en = "Stratholme",            de = "Stratholme",              min = 58, max = 60, zone = "epl",         faction = "C" },
}

ns.ZONE_BY_KEY = {}
for _, z in ipairs(ns.ZONES) do ns.ZONE_BY_KEY[z.key] = z end
