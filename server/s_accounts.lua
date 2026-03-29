--[[
    Legends Roleplay - Account & Character System
    Registration, login, character creation and management
    v2.0.0 - Faction payday integration
]]

local loggedInPlayers = {}

-- ============================================
-- ACCOUNT REGISTRATION
-- ============================================
addEvent("legends:register", true)
addEventHandler("legends:register", root, function(username, password)
    local db = getDatabase()
    if not db then return end

    local player = client
    if not player then return end

    -- Validate input
    if not username or #username < 3 or #username > 20 then
        triggerClientEvent(player, "legends:authResponse", player, false, "Usuario debe tener entre 3 y 20 caracteres")
        return
    end
    if not password or #password < 6 then
        triggerClientEvent(player, "legends:authResponse", player, false, "La contraseña debe tener al menos 6 caracteres")
        return
    end

    -- Check if username exists
    local existing = dbPoll(dbQuery(db, "SELECT id FROM accounts WHERE username = ?", username), -1)
    if #existing > 0 then
        triggerClientEvent(player, "legends:authResponse", player, false, "El usuario ya existe")
        return
    end

    -- Hash password and create account
    local hashedPassword = passwordHash(password, "bcrypt", {})
    dbExec(db, "INSERT INTO accounts (username, password) VALUES (?, ?)", username, hashedPassword)

    local result = dbPoll(dbQuery(db, "SELECT id FROM accounts WHERE username = ?", username), -1)
    if #result > 0 then
        loggedInPlayers[player] = { accountId = result[1].id, username = username }
        triggerClientEvent(player, "legends:authResponse", player, true, "Cuenta creada exitosamente")
        triggerClientEvent(player, "legends:showCharacterSelection", player, {})
        outputDebugString("[Legends] Cuenta creada: " .. username)
    end
end)

-- ============================================
-- ACCOUNT LOGIN
-- ============================================
addEvent("legends:login", true)
addEventHandler("legends:login", root, function(username, password)
    local db = getDatabase()
    if not db then return end

    local player = client
    if not player then return end

    local result = dbPoll(dbQuery(db, "SELECT * FROM accounts WHERE username = ?", username), -1)
    if #result == 0 then
        triggerClientEvent(player, "legends:authResponse", player, false, "Usuario o contraseña incorrectos")
        return
    end

    local account = result[1]

    if account.banned == 1 then
        triggerClientEvent(player, "legends:authResponse", player, false, "Cuenta baneada: " .. (account.ban_reason or "Sin razon"))
        return
    end

    if not passwordVerify(password, account.password) then
        triggerClientEvent(player, "legends:authResponse", player, false, "Usuario o contraseña incorrectos")
        return
    end

    -- Update last login
    dbExec(db, "UPDATE accounts SET last_login = datetime('now') WHERE id = ?", account.id)

    loggedInPlayers[player] = { accountId = account.id, username = username, adminLevel = account.admin_level }
    setElementData(player, "legends:adminLevel", account.admin_level)

    -- Get characters
    local characters = dbPoll(dbQuery(db, "SELECT * FROM characters WHERE account_id = ?", account.id), -1)
    triggerClientEvent(player, "legends:authResponse", player, true, "Login exitoso")
    triggerClientEvent(player, "legends:showCharacterSelection", player, characters)

    outputDebugString("[Legends] Login: " .. username)
end)

-- ============================================
-- CHARACTER CREATION
-- ============================================
addEvent("legends:createCharacter", true)
addEventHandler("legends:createCharacter", root, function(name, skin)
    local db = getDatabase()
    if not db then return end

    local player = client
    if not player then return end

    local accountData = loggedInPlayers[player]
    if not accountData then return end

    -- Check character limit
    local chars = dbPoll(dbQuery(db, "SELECT id FROM characters WHERE account_id = ?", accountData.accountId), -1)
    if #chars >= Config.MaxCharacters then
        triggerClientEvent(player, "legends:authResponse", player, false, "Limite de personajes alcanzado (" .. Config.MaxCharacters .. ")")
        return
    end

    -- Validate name
    if not name or #name < 3 or #name > 30 then
        triggerClientEvent(player, "legends:authResponse", player, false, "Nombre debe tener entre 3 y 30 caracteres")
        return
    end

    -- Check if name exists
    local existing = dbPoll(dbQuery(db, "SELECT id FROM characters WHERE name = ?", name), -1)
    if #existing > 0 then
        triggerClientEvent(player, "legends:authResponse", player, false, "Ese nombre ya esta en uso")
        return
    end

    local spawn = Config.DefaultSpawn
    dbExec(db, "INSERT INTO characters (account_id, name, skin, money, x, y, z, rot) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        accountData.accountId, name, skin or 1, Config.StartingMoney, spawn.x, spawn.y, spawn.z, spawn.rot)

    -- Refresh character list
    local characters = dbPoll(dbQuery(db, "SELECT * FROM characters WHERE account_id = ?", accountData.accountId), -1)
    triggerClientEvent(player, "legends:showCharacterSelection", player, characters)
    triggerClientEvent(player, "legends:authResponse", player, true, "Personaje '" .. name .. "' creado")

    outputDebugString("[Legends] Personaje creado: " .. name)
end)

-- ============================================
-- CHARACTER SELECTION (SPAWN)
-- ============================================
addEvent("legends:selectCharacter", true)
addEventHandler("legends:selectCharacter", root, function(charId)
    local db = getDatabase()
    if not db then return end

    local player = client
    if not player then return end

    local accountData = loggedInPlayers[player]
    if not accountData then return end

    local result = dbPoll(dbQuery(db, "SELECT * FROM characters WHERE id = ? AND account_id = ?", charId, accountData.accountId), -1)
    if #result == 0 then return end

    local char = result[1]
    accountData.charId = char.id
    accountData.charName = char.name

    -- Set player data
    spawnPlayer(player, char.x, char.y, char.z, char.rot, char.skin, char.interior, char.dimension)
    setElementHealth(player, char.health)
    setPedArmor(player, char.armor)

    setElementData(player, "legends:charId", char.id)
    setElementData(player, "legends:charName", char.name)
    setElementData(player, "legends:money", char.money)
    setElementData(player, "legends:bank", char.bank)
    setElementData(player, "legends:job", char.job)
    setElementData(player, "legends:factionId", char.faction_id)
    setElementData(player, "legends:factionRank", char.faction_rank)

    -- Fade camera and show HUD
    fadeCamera(player, true, 2.0)
    setCameraTarget(player, player)
    triggerClientEvent(player, "legends:hideLogin", player)
    triggerClientEvent(player, "legends:toggleHUD", player, true)

    outputChatBox("[Legends] Bienvenido, " .. char.name .. "!", player, 100, 200, 255)
    outputDebugString("[Legends] Spawn: " .. char.name .. " (ID: " .. char.id .. ")")
end)

-- ============================================
-- SAVE CHARACTER DATA
-- ============================================
function saveCharacterData(player)
    local db = getDatabase()
    if not db then return end

    local accountData = loggedInPlayers[player]
    if not accountData or not accountData.charId then return end

    local x, y, z = getElementPosition(player)
    local _, _, rot = getElementRotation(player)
    local health = getElementHealth(player)
    local armor = getPedArmor(player)
    local money = getElementData(player, "legends:money") or 0
    local bank = getElementData(player, "legends:bank") or 0
    local job = getElementData(player, "legends:job") or "Desempleado"
    local factionId = getElementData(player, "legends:factionId") or 0
    local factionRank = getElementData(player, "legends:factionRank") or 0
    local interior = getElementInterior(player)
    local dimension = getElementDimension(player)

    dbExec(db, [[
        UPDATE characters SET
            x = ?, y = ?, z = ?, rot = ?,
            health = ?, armor = ?,
            money = ?, bank = ?,
            job = ?, interior = ?, dimension = ?,
            faction_id = ?, faction_rank = ?
        WHERE id = ?
    ]], x, y, z, rot, health, armor, money, bank, job, interior, dimension, factionId, factionRank, accountData.charId)

    invalidateCache("characters")
end

-- Auto-save timer
setTimer(function()
    for player, data in pairs(loggedInPlayers) do
        if isElement(player) and data.charId then
            saveCharacterData(player)
        end
    end
end, Config.SaveInterval or 300000, 0)

-- ============================================
-- PAYDAY SYSTEM (with faction salary)
-- ============================================
setTimer(function()
    for player, data in pairs(loggedInPlayers) do
        if isElement(player) and data.charId then
            local baseAmount = Config.PaydayAmount or 500
            local factionBonus = 0

            -- Add faction salary
            local factionId = getElementData(player, "legends:factionId") or 0
            local factionRank = getElementData(player, "legends:factionRank") or 0
            if factionId > 0 and Config.FactionSalary[factionId] then
                factionBonus = Config.FactionSalary[factionId][factionRank] or 0
            end

            local totalAmount = baseAmount + factionBonus
            local currentMoney = getElementData(player, "legends:money") or 0
            setElementData(player, "legends:money", currentMoney + totalAmount)

            local msg = "[Payday] +$" .. totalAmount
            if factionBonus > 0 then
                msg = msg .. " (Base: $" .. baseAmount .. " + Faccion: $" .. factionBonus .. ")"
            end
            outputChatBox(msg, player, 100, 220, 100)
        end
    end
end, (Config.PaydayInterval or 30) * 60000, 0)

-- ============================================
-- PLAYER QUIT
-- ============================================
addEventHandler("onPlayerQuit", root, function()
    saveCharacterData(source)
    loggedInPlayers[source] = nil
end)

-- ============================================
-- MONEY FUNCTIONS
-- ============================================
function givePlayerMoney(player, amount)
    local current = getElementData(player, "legends:money") or 0
    setElementData(player, "legends:money", current + amount)
end

function takePlayerMoney(player, amount)
    local current = getElementData(player, "legends:money") or 0
    if current >= amount then
        setElementData(player, "legends:money", current - amount)
        return true
    end
    return false
end

function getPlayerMoney(player)
    return getElementData(player, "legends:money") or 0
end

-- ============================================
-- UTILITY
-- ============================================
function getLoggedInData(player)
    return loggedInPlayers[player]
end

function isPlayerLoggedIn(player)
    return loggedInPlayers[player] ~= nil and loggedInPlayers[player].charId ~= nil
end
