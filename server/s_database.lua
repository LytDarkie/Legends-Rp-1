--[[
    Legends Roleplay - Database System
    SQLite database initialization and management
    v2.0.0 - Query cache with TTL for 4GB RAM optimization
]]

local db = nil
local queryCache = {}
local CACHE_TTL = (Config and Config.DBCacheTTL or 30) * 1000

-- ============================================
-- DATABASE INITIALIZATION
-- ============================================
function initDatabase()
    db = dbConnect("sqlite", "data/legends.db")
    if not db then
        outputDebugString("[Legends] ERROR: No se pudo conectar a la base de datos", 1)
        return false
    end

    -- Create tables
    dbExec(db, [[
        CREATE TABLE IF NOT EXISTS accounts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL,
            admin_level INTEGER DEFAULT 0,
            banned INTEGER DEFAULT 0,
            ban_reason TEXT DEFAULT '',
            last_login TEXT DEFAULT '',
            created_at TEXT DEFAULT (datetime('now'))
        )
    ]])

    dbExec(db, [[
        CREATE TABLE IF NOT EXISTS characters (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            account_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            skin INTEGER DEFAULT 1,
            money INTEGER DEFAULT 5000,
            bank INTEGER DEFAULT 0,
            health REAL DEFAULT 100,
            armor REAL DEFAULT 0,
            x REAL DEFAULT 1481.0,
            y REAL DEFAULT -1752.0,
            z REAL DEFAULT 13.5,
            rot REAL DEFAULT 0,
            interior INTEGER DEFAULT 0,
            dimension INTEGER DEFAULT 0,
            job TEXT DEFAULT 'Desempleado',
            phone TEXT DEFAULT '',
            faction_id INTEGER DEFAULT 0,
            faction_rank INTEGER DEFAULT 0,
            play_time INTEGER DEFAULT 0,
            created_at TEXT DEFAULT (datetime('now')),
            FOREIGN KEY (account_id) REFERENCES accounts(id)
        )
    ]])

    dbExec(db, [[
        CREATE TABLE IF NOT EXISTS vehicles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            owner_id INTEGER NOT NULL,
            model INTEGER NOT NULL,
            x REAL DEFAULT 0,
            y REAL DEFAULT 0,
            z REAL DEFAULT 0,
            rx REAL DEFAULT 0,
            ry REAL DEFAULT 0,
            rz REAL DEFAULT 0,
            color1 INTEGER DEFAULT 0,
            color2 INTEGER DEFAULT 0,
            fuel REAL DEFAULT 100,
            locked INTEGER DEFAULT 1,
            plate TEXT DEFAULT 'LS-0000',
            FOREIGN KEY (owner_id) REFERENCES characters(id)
        )
    ]])

    dbExec(db, [[
        CREATE TABLE IF NOT EXISTS houses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            owner_id INTEGER DEFAULT 0,
            price INTEGER NOT NULL,
            x REAL NOT NULL,
            y REAL NOT NULL,
            z REAL NOT NULL,
            interior INTEGER DEFAULT 0,
            locked INTEGER DEFAULT 1,
            for_sale INTEGER DEFAULT 1
        )
    ]])

    -- Faction tables
    dbExec(db, [[
        CREATE TABLE IF NOT EXISTS factions (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            leader_id INTEGER DEFAULT 0,
            bank INTEGER DEFAULT 0,
            created_at TEXT DEFAULT (datetime('now'))
        )
    ]])

    dbExec(db, [[
        CREATE TABLE IF NOT EXISTS faction_members (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            character_id INTEGER NOT NULL,
            faction_id INTEGER NOT NULL,
            rank INTEGER DEFAULT 1,
            joined_at TEXT DEFAULT (datetime('now')),
            FOREIGN KEY (character_id) REFERENCES characters(id),
            FOREIGN KEY (faction_id) REFERENCES factions(id)
        )
    ]])

    dbExec(db, [[
        CREATE TABLE IF NOT EXISTS faction_ranks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            faction_id INTEGER NOT NULL,
            rank_number INTEGER NOT NULL,
            name TEXT NOT NULL,
            salary INTEGER DEFAULT 0,
            FOREIGN KEY (faction_id) REFERENCES factions(id)
        )
    ]])

    dbExec(db, [[
        CREATE TABLE IF NOT EXISTS faction_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            faction_id INTEGER NOT NULL,
            action TEXT NOT NULL,
            actor TEXT DEFAULT '',
            target TEXT DEFAULT '',
            details TEXT DEFAULT '',
            created_at TEXT DEFAULT (datetime('now')),
            FOREIGN KEY (faction_id) REFERENCES factions(id)
        )
    ]])

    -- Create indices for performance
    dbExec(db, "CREATE INDEX IF NOT EXISTS idx_characters_account ON characters(account_id)")
    dbExec(db, "CREATE INDEX IF NOT EXISTS idx_vehicles_owner ON vehicles(owner_id)")
    dbExec(db, "CREATE INDEX IF NOT EXISTS idx_houses_owner ON houses(owner_id)")
    dbExec(db, "CREATE INDEX IF NOT EXISTS idx_faction_members_char ON faction_members(character_id)")
    dbExec(db, "CREATE INDEX IF NOT EXISTS idx_faction_members_faction ON faction_members(faction_id)")
    dbExec(db, "CREATE INDEX IF NOT EXISTS idx_faction_logs_faction ON faction_logs(faction_id)")

    -- Initialize default factions if they don't exist
    for factionId, factionData in pairs(Config.Factions) do
        local result = dbPoll(dbQuery(db, "SELECT id FROM factions WHERE id = ?", factionId), -1)
        if #result == 0 then
            dbExec(db, "INSERT INTO factions (id, name) VALUES (?, ?)", factionId, factionData.name)
            for rankNum, rankName in pairs(factionData.ranks) do
                local salary = 0
                if Config.FactionSalary[factionId] and Config.FactionSalary[factionId][rankNum] then
                    salary = Config.FactionSalary[factionId][rankNum]
                end
                dbExec(db, "INSERT INTO faction_ranks (faction_id, rank_number, name, salary) VALUES (?, ?, ?, ?)",
                    factionId, rankNum, rankName, salary)
            end
        end
    end

    outputDebugString("[Legends] Base de datos inicializada correctamente")
    return true
end

-- ============================================
-- QUERY CACHE SYSTEM (4GB RAM optimization)
-- ============================================
function cachedQuery(query, ...)
    local cacheKey = query .. tostring(...)
    local now = getTickCount()

    if queryCache[cacheKey] and (now - queryCache[cacheKey].time) < CACHE_TTL then
        return queryCache[cacheKey].result
    end

    local result = dbPoll(dbQuery(db, query, ...), -1)
    queryCache[cacheKey] = { result = result, time = now }
    return result
end

function invalidateCache(pattern)
    if pattern then
        for key in pairs(queryCache) do
            if string.find(key, pattern) then
                queryCache[key] = nil
            end
        end
    else
        queryCache = {}
    end
end

-- Periodic cache cleanup
setTimer(function()
    local now = getTickCount()
    local cleaned = 0
    for key, data in pairs(queryCache) do
        if (now - data.time) > CACHE_TTL then
            queryCache[key] = nil
            cleaned = cleaned + 1
        end
    end
    if cleaned > 0 then
        outputDebugString("[Legends] Cache: " .. cleaned .. " entradas limpiadas")
    end
end, (Config and Config.DBCleanupInterval or 300) * 1000, 0)

-- ============================================
-- DATABASE ACCESSOR
-- ============================================
function getDatabase()
    return db
end

-- Initialize on resource start
addEventHandler("onResourceStart", resourceRoot, function()
    initDatabase()
end)

addEventHandler("onResourceStop", resourceRoot, function()
    if db then
        invalidateCache()
        destroyElement(db)
    end
end)
