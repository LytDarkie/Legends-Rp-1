--[[
    Legends Roleplay - Admin System
    Moderation commands and admin tools
    v2.0.0
]]

-- ============================================
-- HELPER: CHECK ADMIN LEVEL
-- ============================================
function isPlayerAdmin(player, requiredLevel)
    local adminLevel = getElementData(player, "legends:adminLevel") or 0
    return adminLevel >= (requiredLevel or 1)
end

function getAdminLevelName(level)
    return Config.AdminLevels[level] or "Jugador"
end

-- ============================================
-- /kick
-- ============================================
addCommandHandler("kick", function(player, cmd, targetId, ...)
    if not isPlayerAdmin(player, 1) then
        outputChatBox("[Admin] No tienes permisos", player, 255, 50, 50)
        return
    end

    if not targetId then
        outputChatBox("[Uso] /kick [id] [razon]", player, 255, 200, 0)
        return
    end

    local reason = table.concat({...}, " ")
    if reason == "" then reason = "Sin razon especificada" end

    local target = getPlayerFromCharId(tonumber(targetId))
    if not target then
        outputChatBox("[Admin] Jugador no encontrado", player, 255, 50, 50)
        return
    end

    local targetName = getElementData(target, "legends:charName") or getPlayerName(target)
    local adminName = getElementData(player, "legends:charName") or getPlayerName(player)

    outputChatBox("[Admin] " .. targetName .. " fue kickeado por " .. adminName .. " (" .. reason .. ")", root, 255, 100, 100)
    kickPlayer(target, player, reason)
end)

-- ============================================
-- /ban
-- ============================================
addCommandHandler("ban", function(player, cmd, targetId, ...)
    if not isPlayerAdmin(player, 2) then
        outputChatBox("[Admin] No tienes permisos (requiere Admin)", player, 255, 50, 50)
        return
    end

    if not targetId then
        outputChatBox("[Uso] /ban [id] [razon]", player, 255, 200, 0)
        return
    end

    local reason = table.concat({...}, " ")
    if reason == "" then reason = "Sin razon especificada" end

    local target = getPlayerFromCharId(tonumber(targetId))
    if not target then
        outputChatBox("[Admin] Jugador no encontrado", player, 255, 50, 50)
        return
    end

    local targetName = getElementData(target, "legends:charName") or getPlayerName(target)
    local adminName = getElementData(player, "legends:charName") or getPlayerName(player)
    local accountData = getLoggedInData(target)

    if accountData then
        local db = getDatabase()
        dbExec(db, "UPDATE accounts SET banned = 1, ban_reason = ? WHERE id = ?", reason, accountData.accountId)
    end

    outputChatBox("[Admin] " .. targetName .. " fue baneado por " .. adminName .. " (" .. reason .. ")", root, 255, 50, 50)
    kickPlayer(target, player, "Baneado: " .. reason)
end)

-- ============================================
-- /unban
-- ============================================
addCommandHandler("unban", function(player, cmd, username)
    if not isPlayerAdmin(player, 2) then
        outputChatBox("[Admin] No tienes permisos (requiere Admin)", player, 255, 50, 50)
        return
    end

    if not username then
        outputChatBox("[Uso] /unban [nombre de usuario]", player, 255, 200, 0)
        return
    end

    local db = getDatabase()
    local result = dbPoll(dbQuery(db, "SELECT * FROM accounts WHERE username = ? AND banned = 1", username), -1)

    if #result == 0 then
        outputChatBox("[Admin] Usuario no encontrado o no esta baneado", player, 255, 50, 50)
        return
    end

    dbExec(db, "UPDATE accounts SET banned = 0, ban_reason = '' WHERE username = ?", username)
    outputChatBox("[Admin] " .. username .. " fue desbaneado", player, 100, 220, 100)
end)

-- ============================================
-- /tp (TELEPORT)
-- ============================================
addCommandHandler("tp", function(player, cmd, targetId)
    if not isPlayerAdmin(player, 1) then
        outputChatBox("[Admin] No tienes permisos", player, 255, 50, 50)
        return
    end

    if not targetId then
        outputChatBox("[Uso] /tp [id]", player, 255, 200, 0)
        return
    end

    local target = getPlayerFromCharId(tonumber(targetId))
    if not target then
        outputChatBox("[Admin] Jugador no encontrado", player, 255, 50, 50)
        return
    end

    local x, y, z = getElementPosition(target)
    setElementPosition(player, x + 1, y, z)
    setElementInterior(player, getElementInterior(target))
    setElementDimension(player, getElementDimension(target))

    local targetName = getElementData(target, "legends:charName") or "Desconocido"
    outputChatBox("[Admin] Te teleportaste a " .. targetName, player, 100, 200, 255)
end)

-- ============================================
-- /traer (BRING)
-- ============================================
addCommandHandler("traer", function(player, cmd, targetId)
    if not isPlayerAdmin(player, 1) then
        outputChatBox("[Admin] No tienes permisos", player, 255, 50, 50)
        return
    end

    if not targetId then
        outputChatBox("[Uso] /traer [id]", player, 255, 200, 0)
        return
    end

    local target = getPlayerFromCharId(tonumber(targetId))
    if not target then
        outputChatBox("[Admin] Jugador no encontrado", player, 255, 50, 50)
        return
    end

    local x, y, z = getElementPosition(player)
    setElementPosition(target, x + 1, y, z)
    setElementInterior(target, getElementInterior(player))
    setElementDimension(target, getElementDimension(player))

    local targetName = getElementData(target, "legends:charName") or "Desconocido"
    outputChatBox("[Admin] Trajiste a " .. targetName, player, 100, 200, 255)
    outputChatBox("[Admin] Fuiste traido por un administrador", target, 100, 200, 255)
end)

-- ============================================
-- /darmoney (GIVE MONEY)
-- ============================================
addCommandHandler("darmoney", function(player, cmd, targetId, amountStr)
    if not isPlayerAdmin(player, 2) then
        outputChatBox("[Admin] No tienes permisos (requiere Admin)", player, 255, 50, 50)
        return
    end

    if not targetId or not amountStr then
        outputChatBox("[Uso] /darmoney [id] [cantidad]", player, 255, 200, 0)
        return
    end

    local amount = tonumber(amountStr)
    if not amount or amount <= 0 then
        outputChatBox("[Admin] Cantidad invalida", player, 255, 50, 50)
        return
    end

    local target = getPlayerFromCharId(tonumber(targetId))
    if not target then
        outputChatBox("[Admin] Jugador no encontrado", player, 255, 50, 50)
        return
    end

    givePlayerMoney(target, amount)
    local targetName = getElementData(target, "legends:charName") or "Desconocido"
    outputChatBox("[Admin] Le diste $" .. amount .. " a " .. targetName, player, 100, 220, 100)
    outputChatBox("[Admin] Un administrador te dio $" .. amount, target, 100, 220, 100)
end)

-- ============================================
-- /setadmin
-- ============================================
addCommandHandler("setadmin", function(player, cmd, targetId, levelStr)
    if not isPlayerAdmin(player, 4) then
        outputChatBox("[Admin] No tienes permisos (requiere Fundador)", player, 255, 50, 50)
        return
    end

    if not targetId or not levelStr then
        outputChatBox("[Uso] /setadmin [id] [nivel 0-4]", player, 255, 200, 0)
        return
    end

    local level = tonumber(levelStr)
    if not level or level < 0 or level > 4 then
        outputChatBox("[Admin] Nivel invalido (0-4)", player, 255, 50, 50)
        return
    end

    local target = getPlayerFromCharId(tonumber(targetId))
    if not target then
        outputChatBox("[Admin] Jugador no encontrado", player, 255, 50, 50)
        return
    end

    setElementData(target, "legends:adminLevel", level)
    local accountData = getLoggedInData(target)
    if accountData then
        local db = getDatabase()
        dbExec(db, "UPDATE accounts SET admin_level = ? WHERE id = ?", level, accountData.accountId)
    end

    local targetName = getElementData(target, "legends:charName") or "Desconocido"
    local levelName = getAdminLevelName(level)
    outputChatBox("[Admin] " .. targetName .. " ahora es " .. levelName .. " (nivel " .. level .. ")", player, 100, 200, 255)
    if level > 0 then
        outputChatBox("[Admin] Fuiste promovido a " .. levelName, target, 100, 200, 255)
    else
        outputChatBox("[Admin] Tu rango de admin fue removido", target, 255, 200, 0)
    end
end)

-- ============================================
-- /revive
-- ============================================
addCommandHandler("revive", function(player, cmd, targetId)
    if not isPlayerAdmin(player, 1) then
        outputChatBox("[Admin] No tienes permisos", player, 255, 50, 50)
        return
    end

    local target = player
    if targetId then
        target = getPlayerFromCharId(tonumber(targetId))
        if not target then
            outputChatBox("[Admin] Jugador no encontrado", player, 255, 50, 50)
            return
        end
    end

    setElementHealth(target, 100)
    setPedArmor(target, 0)

    local targetName = getElementData(target, "legends:charName") or "Desconocido"
    outputChatBox("[Admin] " .. targetName .. " fue revivido", player, 100, 220, 100)
    if target ~= player then
        outputChatBox("[Admin] Fuiste revivido por un administrador", target, 100, 220, 100)
    end
end)

-- ============================================
-- /freeze / /unfreeze
-- ============================================
addCommandHandler("freeze", function(player, cmd, targetId)
    if not isPlayerAdmin(player, 1) then
        outputChatBox("[Admin] No tienes permisos", player, 255, 50, 50)
        return
    end

    if not targetId then
        outputChatBox("[Uso] /freeze [id]", player, 255, 200, 0)
        return
    end

    local target = getPlayerFromCharId(tonumber(targetId))
    if not target then
        outputChatBox("[Admin] Jugador no encontrado", player, 255, 50, 50)
        return
    end

    toggleAllControls(target, false)
    local targetName = getElementData(target, "legends:charName") or "Desconocido"
    outputChatBox("[Admin] " .. targetName .. " fue congelado", player, 100, 200, 255)
    outputChatBox("[Admin] Fuiste congelado por un administrador", target, 255, 200, 0)
end)

addCommandHandler("unfreeze", function(player, cmd, targetId)
    if not isPlayerAdmin(player, 1) then
        outputChatBox("[Admin] No tienes permisos", player, 255, 50, 50)
        return
    end

    if not targetId then
        outputChatBox("[Uso] /unfreeze [id]", player, 255, 200, 0)
        return
    end

    local target = getPlayerFromCharId(tonumber(targetId))
    if not target then
        outputChatBox("[Admin] Jugador no encontrado", player, 255, 50, 50)
        return
    end

    toggleAllControls(target, true)
    local targetName = getElementData(target, "legends:charName") or "Desconocido"
    outputChatBox("[Admin] " .. targetName .. " fue descongelado", player, 100, 200, 255)
    outputChatBox("[Admin] Fuiste descongelado", target, 100, 220, 100)
end)

-- ============================================
-- /spectate
-- ============================================
addCommandHandler("spectate", function(player, cmd, targetId)
    if not isPlayerAdmin(player, 1) then
        outputChatBox("[Admin] No tienes permisos", player, 255, 50, 50)
        return
    end

    if not targetId then
        -- Stop spectating
        setCameraTarget(player, player)
        outputChatBox("[Admin] Dejaste de observar", player, 100, 200, 255)
        return
    end

    local target = getPlayerFromCharId(tonumber(targetId))
    if not target then
        outputChatBox("[Admin] Jugador no encontrado", player, 255, 50, 50)
        return
    end

    setCameraTarget(player, target)
    local targetName = getElementData(target, "legends:charName") or "Desconocido"
    outputChatBox("[Admin] Observando a " .. targetName .. " (usa /spectate para dejar de observar)", player, 100, 200, 255)
end)

-- ============================================
-- /anuncio (ANNOUNCEMENT)
-- ============================================
addCommandHandler("anuncio", function(player, cmd, ...)
    if not isPlayerAdmin(player, 2) then
        outputChatBox("[Admin] No tienes permisos (requiere Admin)", player, 255, 50, 50)
        return
    end

    local msg = table.concat({...}, " ")
    if msg == "" then
        outputChatBox("[Uso] /anuncio [mensaje]", player, 255, 200, 0)
        return
    end

    local adminName = getElementData(player, "legends:charName") or getPlayerName(player)
    outputChatBox("[ANUNCIO] " .. msg, root, 255, 200, 0)
    outputChatBox("- " .. adminName, root, 200, 200, 200)
end)

-- ============================================
-- /players (ONLINE PLAYERS)
-- ============================================
addCommandHandler("players", function(player)
    if not isPlayerAdmin(player, 1) then
        outputChatBox("[Admin] No tienes permisos", player, 255, 50, 50)
        return
    end

    local players = getElementsByType("player")
    outputChatBox("=== Jugadores Online (" .. #players .. ") ===", player, 100, 200, 255)
    for _, p in ipairs(players) do
        local charName = getElementData(p, "legends:charName") or "Sin personaje"
        local charId = getElementData(p, "legends:charId") or "-"
        local adminLevel = getElementData(p, "legends:adminLevel") or 0
        local adminTag = adminLevel > 0 and " [" .. getAdminLevelName(adminLevel) .. "]" or ""
        outputChatBox("ID: " .. charId .. " | " .. charName .. " (" .. getPlayerName(p) .. ")" .. adminTag, player, 255, 255, 255)
    end
end)

-- ============================================
-- /setskin
-- ============================================
addCommandHandler("setskin", function(player, cmd, targetId, skinId)
    if not isPlayerAdmin(player, 2) then
        outputChatBox("[Admin] No tienes permisos (requiere Admin)", player, 255, 50, 50)
        return
    end

    if not targetId or not skinId then
        outputChatBox("[Uso] /setskin [id] [skin id]", player, 255, 200, 0)
        return
    end

    local target = getPlayerFromCharId(tonumber(targetId))
    if not target then
        outputChatBox("[Admin] Jugador no encontrado", player, 255, 50, 50)
        return
    end

    local skin = tonumber(skinId)
    if not skin then
        outputChatBox("[Admin] Skin ID invalido", player, 255, 50, 50)
        return
    end

    setElementModel(target, skin)
    local targetName = getElementData(target, "legends:charName") or "Desconocido"
    outputChatBox("[Admin] Skin de " .. targetName .. " cambiado a " .. skin, player, 100, 200, 255)
end)

-- ============================================
-- /setweather /settime
-- ============================================
addCommandHandler("setweather", function(player, cmd, weatherId)
    if not isPlayerAdmin(player, 2) then
        outputChatBox("[Admin] No tienes permisos (requiere Admin)", player, 255, 50, 50)
        return
    end

    local weather = tonumber(weatherId)
    if not weather or weather < 0 or weather > 45 then
        outputChatBox("[Uso] /setweather [0-45]", player, 255, 200, 0)
        return
    end

    setWeather(weather)
    outputChatBox("[Admin] Clima cambiado a " .. weather, player, 100, 200, 255)
end)

addCommandHandler("settime", function(player, cmd, hourStr, minStr)
    if not isPlayerAdmin(player, 2) then
        outputChatBox("[Admin] No tienes permisos (requiere Admin)", player, 255, 50, 50)
        return
    end

    local hour = tonumber(hourStr)
    local minute = tonumber(minStr) or 0
    if not hour or hour < 0 or hour > 23 then
        outputChatBox("[Uso] /settime [hora 0-23] [minuto]", player, 255, 200, 0)
        return
    end

    setTime(hour, minute)
    outputChatBox("[Admin] Hora cambiada a " .. hour .. ":" .. string.format("%02d", minute), player, 100, 200, 255)
end)

-- ============================================
-- UTILITY: Get player from character ID
-- ============================================
function getPlayerFromCharId(charId)
    if not charId then return nil end
    for _, p in ipairs(getElementsByType("player")) do
        if getElementData(p, "legends:charId") == charId then
            return p
        end
    end
    return nil
end
