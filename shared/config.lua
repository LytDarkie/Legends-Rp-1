--[[
    Legends Roleplay - Configuration
    Shared configuration file for server and client
    v2.0.0 - Optimized for 4GB RAM + Faction System
]]

Config = {}

-- ============================================
-- SERVER SETTINGS
-- ============================================
Config.ServerName = "Legends Roleplay"
Config.ServerVersion = "2.0.0"
Config.MaxCharacters = 3
Config.StartingMoney = 5000
Config.PaydayInterval = 30 -- minutes
Config.PaydayAmount = 500
Config.SaveInterval = 300000 -- 5 minutes in ms

-- ============================================
-- PERFORMANCE SETTINGS (4GB RAM optimization)
-- ============================================
Config.MaxStreamedElements = 50
Config.NametagRenderDistance = 25
Config.MarkerStreamDistance = 100
Config.DBCacheTTL = 30 -- seconds
Config.DBCleanupInterval = 300 -- seconds
Config.FuelTickInterval = 60000 -- ms (60s)
Config.HUDUpdateInterval = 200 -- ms
Config.MaxNotifications = 5

-- ============================================
-- SPAWN POINTS
-- ============================================
Config.DefaultSpawn = { x = 1481.0, y = -1752.0, z = 13.5, rot = 0 }
Config.HospitalSpawn = { x = 1172.0, y = -1323.0, z = 15.4, rot = 270 }

Config.SpawnPoints = {
    { x = 1481.0, y = -1752.0, z = 13.5, rot = 0, name = "Los Santos - Centro" },
    { x = 2027.0, y = -1420.0, z = 17.0, rot = 135, name = "Los Santos - Este" },
    { x = 1293.0, y = -1584.0, z = 13.5, rot = 180, name = "Los Santos - Unity Station" },
}

-- ============================================
-- CHAT SETTINGS
-- ============================================
Config.ChatRanges = {
    ic = 20,
    shout = 40,
    whisper = 5,
    me = 20,
    doAction = 20,
}

-- ============================================
-- ECONOMY
-- ============================================
Config.ATMLocations = {
    { x = 1480.0, y = -1756.0, z = 13.5 },
    { x = 2099.0, y = -1407.0, z = 17.0 },
    { x = 1928.0, y = -1781.0, z = 13.5 },
    { x = 1154.0, y = -1460.0, z = 15.8 },
}

-- ============================================
-- VEHICLES
-- ============================================
Config.VehicleShops = {
    {
        name = "Concesionaria LS",
        x = 2126.0, y = -1132.0, z = 25.5,
        vehicles = {
            { model = 400, name = "Landstalker", price = 25000 },
            { model = 401, name = "Bravura", price = 15000 },
            { model = 404, name = "Perennial", price = 12000 },
            { model = 405, name = "Sentinel", price = 35000 },
            { model = 410, name = "Manana", price = 10000 },
            { model = 411, name = "Infernus", price = 120000 },
            { model = 415, name = "Cheetah", price = 100000 },
            { model = 421, name = "Washington", price = 28000 },
            { model = 426, name = "Premier", price = 22000 },
            { model = 445, name = "Admiral", price = 30000 },
            { model = 451, name = "Turismo", price = 150000 },
            { model = 480, name = "Comet", price = 80000 },
            { model = 496, name = "Blista Compact", price = 18000 },
            { model = 507, name = "Elegant", price = 32000 },
            { model = 560, name = "Sultan", price = 45000 },
            { model = 562, name = "Elegy", price = 55000 },
        },
    },
}

Config.FuelConsumption = 0.05
Config.MaxFuel = 100

-- ============================================
-- JOBS
-- ============================================
Config.Jobs = {
    {
        name = "Recolector de Basura",
        payPerRoute = 200,
        marker = { x = 2171.0, y = -1675.0, z = 15.0 },
        vehicle = 408,
        routes = {
            { x = 2283.0, y = -1640.0, z = 14.5 },
            { x = 2400.0, y = -1517.0, z = 24.0 },
            { x = 2488.0, y = -1395.0, z = 26.0 },
            { x = 2222.0, y = -1292.0, z = 24.5 },
        },
    },
    {
        name = "Camionero",
        payPerRoute = 350,
        marker = { x = 2455.0, y = -2111.0, z = 13.5 },
        vehicle = 514,
        routes = {
            { x = 2185.0, y = -2263.0, z = 13.3 },
            { x = 1641.0, y = -2286.0, z = 13.5 },
            { x = 1318.0, y = -1809.0, z = 13.5 },
            { x = 1777.0, y = -1930.0, z = 13.5 },
        },
    },
    {
        name = "Taxista",
        payPerRoute = 150,
        marker = { x = 1728.0, y = -1943.0, z = 13.5 },
        vehicle = 420,
        routes = {
            { x = 1481.0, y = -1752.0, z = 13.5 },
            { x = 2027.0, y = -1420.0, z = 17.0 },
            { x = 1293.0, y = -1584.0, z = 13.5 },
            { x = 1172.0, y = -1323.0, z = 15.4 },
        },
    },
    {
        name = "Pescador",
        payPerRoute = 250,
        marker = { x = 376.0, y = -2054.0, z = 7.8 },
        vehicle = 453,
        routes = {
            { x = 200.0, y = -1940.0, z = 1.0 },
            { x = 140.0, y = -1860.0, z = 1.0 },
            { x = 280.0, y = -1780.0, z = 1.0 },
        },
    },
}

-- ============================================
-- HOUSES
-- ============================================
Config.DefaultHouses = {
    { x = 2495.0, y = -1686.0, z = 13.5, interior = 2, price = 50000, name = "Casa LS Este 1" },
    { x = 2468.0, y = -1698.0, z = 13.5, interior = 3, price = 75000, name = "Casa LS Este 2" },
    { x = 1430.0, y = -1735.0, z = 13.5, interior = 5, price = 100000, name = "Depto LS Centro" },
    { x = 1260.0, y = -785.0, z = 92.0, interior = 8, price = 200000, name = "Mansion Mulholland" },
}

-- ============================================
-- ADMIN LEVELS
-- ============================================
Config.AdminLevels = {
    [1] = "Moderador",
    [2] = "Administrador",
    [3] = "Admin Senior",
    [4] = "Fundador",
}

-- ============================================
-- CHARACTER SKINS
-- ============================================
Config.MaleSkins = { 1, 2, 3, 4, 5, 6, 7, 14, 15, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 32, 33, 34, 35, 36, 37, 43, 44, 45, 46, 47 }
Config.FemaleSkins = { 9, 10, 11, 12, 13, 31, 38, 39, 40, 41, 53, 54, 55, 56, 57, 63, 64, 65, 69, 76, 77, 88, 89, 90, 91, 92, 93 }

-- ============================================
-- FACTION SYSTEM (Argentina Roleplay Style)
-- ============================================
Config.Factions = {
    [1] = {
        name = "Policia Federal Argentina",
        shortName = "PFA",
        color = { 0, 100, 200 },
        blipIcon = 30,
        hq = { x = 1555.0, y = -1675.0, z = 16.0 },
        vehicles = {
            { model = 596, name = "Patrulla LS", colors = { 0, 1 } },
            { model = 597, name = "Patrulla SF", colors = { 0, 1 } },
            { model = 598, name = "Patrulla LV", colors = { 0, 1 } },
            { model = 523, name = "HPV-1000 Moto", colors = { 0, 0 } },
            { model = 427, name = "Enforcer", colors = { 0, 1 } },
        },
        weapons = {
            [1] = { 22 },         -- Cadete: Pistol
            [2] = { 22, 3 },      -- Oficial: Pistol, Nightstick
            [3] = { 22, 25, 3 },  -- Sargento: Pistol, Shotgun, Nightstick
            [4] = { 24, 25, 31 }, -- Teniente: Deagle, Shotgun, M4
            [5] = { 24, 25, 31 }, -- Capitan: Deagle, Shotgun, M4
            [6] = { 24, 27, 31 }, -- Comisario: Deagle, Combat Shotgun, M4
            [7] = { 24, 27, 31, 34 }, -- Jefe: Deagle, Combat Shotgun, M4, Sniper
        },
        skins = {
            [1] = 280, -- Cadete
            [2] = 281, -- Oficial
            [3] = 282, -- Sargento
            [4] = 283, -- Teniente
            [5] = 284, -- Capitan
            [6] = 285, -- Comisario
            [7] = 286, -- Jefe de Policia
        },
        ranks = {
            [1] = "Cadete",
            [2] = "Oficial",
            [3] = "Sargento",
            [4] = "Teniente",
            [5] = "Capitan",
            [6] = "Comisario",
            [7] = "Jefe de Policia",
        },
    },
    [2] = {
        name = "SAME",
        shortName = "SAME",
        color = { 200, 50, 50 },
        blipIcon = 22,
        hq = { x = 1172.0, y = -1323.0, z = 15.4 },
        vehicles = {
            { model = 416, name = "Ambulancia", colors = { 1, 3 } },
            { model = 407, name = "Camion Bomberos", colors = { 3, 1 } },
        },
        weapons = {},
        skins = {
            [1] = 274, -- Voluntario
            [2] = 275, -- Paramedico
            [3] = 276, -- Paramedico Senior
            [4] = 277, -- Medico
            [5] = 278, -- Medico Jefe
            [6] = 279, -- Director
        },
        ranks = {
            [1] = "Voluntario",
            [2] = "Paramedico",
            [3] = "Paramedico Senior",
            [4] = "Medico",
            [5] = "Medico Jefe",
            [6] = "Director",
        },
    },
    [3] = {
        name = "Taller Mecanico LS",
        shortName = "Mecanicos",
        color = { 255, 165, 0 },
        blipIcon = 27,
        hq = { x = 2645.0, y = -2026.0, z = 13.5 },
        vehicles = {
            { model = 525, name = "Grua Tow", colors = { 6, 6 } },
            { model = 552, name = "Utility Van", colors = { 6, 6 } },
        },
        weapons = {},
        skins = {
            [1] = 50, -- Aprendiz
            [2] = 50, -- Mecanico
            [3] = 50, -- Mecanico Senior
            [4] = 50, -- Jefe de Taller
            [5] = 50, -- Director
        },
        ranks = {
            [1] = "Aprendiz",
            [2] = "Mecanico",
            [3] = "Mecanico Senior",
            [4] = "Jefe de Taller",
            [5] = "Director",
        },
    },
    [4] = {
        name = "Gobierno de San Andreas",
        shortName = "Gobierno",
        color = { 0, 150, 0 },
        blipIcon = 36,
        hq = { x = 1481.0, y = -1772.0, z = 18.8 },
        vehicles = {
            { model = 445, name = "Admiral Oficial", colors = { 0, 0 } },
            { model = 421, name = "Washington Oficial", colors = { 0, 0 } },
            { model = 507, name = "Elegant Oficial", colors = { 0, 0 } },
        },
        weapons = {},
        skins = {
            [1] = 17, -- Empleado
            [2] = 17, -- Funcionario
            [3] = 17, -- Secretario
            [4] = 17, -- Ministro
            [5] = 17, -- Vicegobernador
            [6] = 17, -- Gobernador
        },
        ranks = {
            [1] = "Empleado Publico",
            [2] = "Funcionario",
            [3] = "Secretario",
            [4] = "Ministro",
            [5] = "Vicegobernador",
            [6] = "Gobernador",
        },
    },
    [5] = {
        name = "Los Santos Cartel",
        shortName = "Cartel",
        color = { 128, 0, 128 },
        blipIcon = 31,
        hq = { x = 2756.0, y = -1182.0, z = 69.4 },
        vehicles = {
            { model = 411, name = "Infernus Negro", colors = { 0, 0 } },
            { model = 560, name = "Sultan Negro", colors = { 0, 0 } },
            { model = 559, name = "Jester Negro", colors = { 0, 0 } },
        },
        weapons = {
            [1] = { 22 },         -- Soldado
            [2] = { 22, 25 },     -- Sicario
            [3] = { 24, 29 },     -- Teniente
            [4] = { 24, 29, 31 }, -- Mano Derecha
            [5] = { 24, 27, 31 }, -- SubJefe
            [6] = { 24, 27, 31, 34 }, -- Jefe
        },
        skins = {
            [1] = 19, -- Soldado
            [2] = 20, -- Sicario
            [3] = 21, -- Teniente
            [4] = 22, -- Mano Derecha
            [5] = 23, -- SubJefe
            [6] = 24, -- Jefe del Cartel
        },
        ranks = {
            [1] = "Soldado",
            [2] = "Sicario",
            [3] = "Teniente",
            [4] = "Mano Derecha",
            [5] = "SubJefe",
            [6] = "Jefe del Cartel",
        },
    },
}

Config.FactionSalary = {
    [1] = { 300, 400, 500, 650, 800, 1000, 1500 },      -- PFA
    [2] = { 250, 350, 450, 600, 800, 1200 },             -- SAME
    [3] = { 200, 300, 400, 550, 800 },                    -- Mecanicos
    [4] = { 350, 500, 700, 900, 1200, 2000 },             -- Gobierno
    [5] = { 200, 300, 450, 600, 900, 1500 },              -- Cartel
}

Config.FactionPermissions = {
    invite = 3,   -- Rank 3+ can invite
    kick = 4,     -- Rank 4+ can kick
    promote = 4,  -- Rank 4+ can promote
    demote = 4,   -- Rank 4+ can demote
    manage = 5,   -- Rank 5+ full management
}
