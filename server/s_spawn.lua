--[[
    Legends Roleplay - Spawn & World System
    Player join, death, respawn management
    v2.0.0 - Timer-based anti-fall instead of per-frame
]]

-- ============================================
-- PLAYER JOIN
-- ============================================
addEventHandler("onPlayerJoin", root, function()
    fadeCamera(source, true, 0)
    fadeCamera(source, false, 0)

    -- Show login screen
    triggerClientEvent(source, "legends:showLogin", source)

    outputChatBox("Bienvenido a " .. Config.ServerName .. " v" .. Config.ServerVersion, source, 100, 200, 255)
    outputChatBox("Usa /ayuda para ver los comandos disponibles", source, 200, 200, 200)
end)

-- ============================================
-- PLAYER WASTED (DEATH)
-- ============================================
addEventHandler("onPlayerWasted", root, function(ammo, killer, weapon, bodypart)
    local charName = getElementData(source, "legends:charName") or "Desconocido"

    -- Death message
    if killer and killer ~= source and getElementType(killer) == "player" then
        local killerName = getElementData(killer, "legends:charName") or "Desconocido"
        outputChatBox("[Muerte] " .. charName .. " fue asesinado por " .. killerName, root, 255, 100, 100)
    else
        outputChatBox("[Muerte] " .. charName .. " ha muerto", root, 255, 100, 100)
    end

    -- Respawn timer (5 seconds)
    setTimer(function()
        if isElement(source) then
            respawnPlayer(source)
        end
    end, 5000, 1, source)
end)

function respawnPlayer(player)
    local spawn = Config.HospitalSpawn
    spawnPlayer(player, spawn.x, spawn.y, spawn.z, spawn.rot, getElementModel(player))
    setElementHealth(player, 100)
    setPedArmor(player, 0)
    setElementInterior(player, 0)
    setElementDimension(player, 0)
    fadeCamera(player, true, 2.0)
    setCameraTarget(player, player)

    -- Hospital fee
    local money = getElementData(player, "legends:money") or 0
    local fee = 500
    if money >= fee then
        setElementData(player, "legends:money", money - fee)
        outputChatBox("[Hospital] Pagaste $" .. fee .. " de gastos medicos", player, 255, 200, 0)
    else
        outputChatBox("[Hospital] No pudiste pagar los gastos medicos ($" .. fee .. ")", player, 255, 100, 100)
    end

    outputChatBox("[Hospital] Fuiste atendido en el hospital", player, 100, 200, 255)
end

-- ============================================
-- WORLD SETTINGS
-- ============================================
addEventHandler("onResourceStart", resourceRoot, function()
    -- Set default weather and time
    setWeather(0)
    setTime(12, 0)

    -- Game speed
    setGameSpeed(1.0)

    -- Disable auto-aim
    setGlitchEnabled("quickreload", false)

    outputDebugString("[Legends] World settings applied")
end)

-- ============================================
-- ANTI-FALL (timer-based, optimized for 4GB RAM)
-- ============================================
setTimer(function()
    for _, player in ipairs(getElementsByType("player")) do
        if isElement(player) and not isPlayerDead(player) then
            local x, y, z = getElementPosition(player)
            if z < -50 then
                local spawn = Config.DefaultSpawn
                setElementPosition(player, spawn.x, spawn.y, spawn.z)
                setElementInterior(player, 0)
                setElementDimension(player, 0)
                outputChatBox("[Sistema] Fuiste reubicado por caer del mapa", player, 255, 200, 0)
            end
        end
    end
end, 2000, 0)
