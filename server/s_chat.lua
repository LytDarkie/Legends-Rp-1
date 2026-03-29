--[[
    Legends Roleplay - Chat System
    IC/OOC chat, /me, /do, /gritar, /susurrar, /pm, /ayuda
    v2.0.0 - Faction help commands added
]]

-- ============================================
-- BLOCK DEFAULT CHAT
-- ============================================
addEventHandler("onPlayerChat", root, function(msg, type)
    cancelEvent()
    if type == 0 then
        local charName = getElementData(source, "legends:charName")
        if not charName then return end

        local range = Config.ChatRanges.ic or 20
        local x, y, z = getElementPosition(source)
        local charId = getElementData(source, "legends:charId") or 0

        for _, player in ipairs(getElementsByType("player")) do
            local px, py, pz = getElementPosition(player)
            if getDistanceBetweenPoints3D(x, y, z, px, py, pz) <= range then
                outputChatBox(charName .. " [" .. charId .. "] dice: " .. msg, player, 255, 255, 255)
            end
        end
    end
end)

-- ============================================
-- /me COMMAND
-- ============================================
addCommandHandler("me", function(player, cmd, ...)
    local charName = getElementData(player, "legends:charName")
    if not charName then return end

    local action = table.concat({...}, " ")
    if action == "" then
        outputChatBox("[Uso] /me [accion]", player, 255, 200, 0)
        return
    end

    local range = Config.ChatRanges.me or 20
    local x, y, z = getElementPosition(player)

    for _, p in ipairs(getElementsByType("player")) do
        local px, py, pz = getElementPosition(p)
        if getDistanceBetweenPoints3D(x, y, z, px, py, pz) <= range then
            outputChatBox("* " .. charName .. " " .. action, p, 200, 100, 200)
        end
    end
end)

-- ============================================
-- /do COMMAND
-- ============================================
addCommandHandler("do", function(player, cmd, ...)
    local charName = getElementData(player, "legends:charName")
    if not charName then return end

    local action = table.concat({...}, " ")
    if action == "" then
        outputChatBox("[Uso] /do [descripcion]", player, 255, 200, 0)
        return
    end

    local range = Config.ChatRanges.doAction or 20
    local x, y, z = getElementPosition(player)

    for _, p in ipairs(getElementsByType("player")) do
        local px, py, pz = getElementPosition(p)
        if getDistanceBetweenPoints3D(x, y, z, px, py, pz) <= range then
            outputChatBox("* " .. action .. " (( " .. charName .. " ))", p, 120, 200, 120)
        end
    end
end)

-- ============================================
-- /b (LOCAL OOC)
-- ============================================
addCommandHandler("b", function(player, cmd, ...)
    local charName = getElementData(player, "legends:charName")
    if not charName then return end

    local msg = table.concat({...}, " ")
    if msg == "" then
        outputChatBox("[Uso] /b [mensaje OOC local]", player, 255, 200, 0)
        return
    end

    local range = Config.ChatRanges.ic or 20
    local x, y, z = getElementPosition(player)

    for _, p in ipairs(getElementsByType("player")) do
        local px, py, pz = getElementPosition(p)
        if getDistanceBetweenPoints3D(x, y, z, px, py, pz) <= range then
            outputChatBox("(( [" .. getPlayerName(player) .. "] " .. charName .. ": " .. msg .. " ))", p, 200, 200, 200)
        end
    end
end)

-- ============================================
-- /ooc (GLOBAL OOC)
-- ============================================
addCommandHandler("ooc", function(player, cmd, ...)
    local charName = getElementData(player, "legends:charName")
    if not charName then return end

    local msg = table.concat({...}, " ")
    if msg == "" then
        outputChatBox("[Uso] /ooc [mensaje OOC global]", player, 255, 200, 0)
        return
    end

    outputChatBox("(( OOC | " .. charName .. ": " .. msg .. " ))", root, 180, 180, 180)
end)

-- ============================================
-- /gritar (SHOUT)
-- ============================================
addCommandHandler("gritar", function(player, cmd, ...)
    local charName = getElementData(player, "legends:charName")
    if not charName then return end

    local msg = table.concat({...}, " ")
    if msg == "" then
        outputChatBox("[Uso] /gritar [mensaje]", player, 255, 200, 0)
        return
    end

    local range = Config.ChatRanges.shout or 40
    local x, y, z = getElementPosition(player)

    for _, p in ipairs(getElementsByType("player")) do
        local px, py, pz = getElementPosition(p)
        if getDistanceBetweenPoints3D(x, y, z, px, py, pz) <= range then
            outputChatBox(charName .. " grita: " .. msg .. "!", p, 255, 100, 100)
        end
    end
end)

-- ============================================
-- /susurrar (WHISPER)
-- ============================================
addCommandHandler("susurrar", function(player, cmd, ...)
    local charName = getElementData(player, "legends:charName")
    if not charName then return end

    local msg = table.concat({...}, " ")
    if msg == "" then
        outputChatBox("[Uso] /susurrar [mensaje]", player, 255, 200, 0)
        return
    end

    local range = Config.ChatRanges.whisper or 5
    local x, y, z = getElementPosition(player)

    for _, p in ipairs(getElementsByType("player")) do
        local px, py, pz = getElementPosition(p)
        if getDistanceBetweenPoints3D(x, y, z, px, py, pz) <= range then
            outputChatBox(charName .. " susurra: " .. msg, p, 255, 255, 150)
        end
    end
end)

-- ============================================
-- /pm (PRIVATE MESSAGE)
-- ============================================
addCommandHandler("pm", function(player, cmd, targetId, ...)
    local charName = getElementData(player, "legends:charName")
    if not charName then return end

    if not targetId then
        outputChatBox("[Uso] /pm [id] [mensaje]", player, 255, 200, 0)
        return
    end

    local msg = table.concat({...}, " ")
    if msg == "" then
        outputChatBox("[Uso] /pm [id] [mensaje]", player, 255, 200, 0)
        return
    end

    -- Find target player by character ID
    local target = nil
    for _, p in ipairs(getElementsByType("player")) do
        if tostring(getElementData(p, "legends:charId")) == tostring(targetId) then
            target = p
            break
        end
    end

    if not target then
        outputChatBox("[PM] Jugador no encontrado con ID " .. targetId, player, 255, 50, 50)
        return
    end

    local targetName = getElementData(target, "legends:charName") or "Desconocido"
    outputChatBox("[PM -> " .. targetName .. "] " .. msg, player, 255, 200, 100)
    outputChatBox("[PM <- " .. charName .. "] " .. msg, target, 255, 200, 100)
end)

-- ============================================
-- /ayuda (HELP)
-- ============================================
addCommandHandler("ayuda", function(player)
    outputChatBox("=============== LEGENDS ROLEPLAY ===============", player, 100, 200, 255)
    outputChatBox("Chat IC: Escribe normalmente en el chat", player, 255, 255, 255)
    outputChatBox("/me [accion] - Accion de personaje", player, 255, 255, 255)
    outputChatBox("/do [descripcion] - Descripcion de entorno", player, 255, 255, 255)
    outputChatBox("/b [msg] - OOC local", player, 255, 255, 255)
    outputChatBox("/ooc [msg] - OOC global", player, 255, 255, 255)
    outputChatBox("/gritar [msg] - Gritar (rango extendido)", player, 255, 255, 255)
    outputChatBox("/susurrar [msg] - Susurrar (rango corto)", player, 255, 255, 255)
    outputChatBox("/pm [id] [msg] - Mensaje privado", player, 255, 255, 255)
    outputChatBox("/comprarauto - Comprar vehiculo", player, 255, 255, 255)
    outputChatBox("/misautos - Ver tus vehiculos", player, 255, 255, 255)
    outputChatBox("/motor - Encender/apagar motor", player, 255, 255, 255)
    outputChatBox("/lock - Cerrar/abrir vehiculo", player, 255, 255, 255)
    outputChatBox("/comprarcasa - Comprar casa", player, 255, 255, 255)
    outputChatBox("/miscasas - Ver tus casas", player, 255, 255, 255)
    outputChatBox("/trabajo - Ver trabajos disponibles", player, 255, 255, 255)
    outputChatBox("/fhelp - Comandos de faccion", player, 120, 220, 120)
    outputChatBox("/f [msg] - Chat de faccion", player, 120, 220, 120)
    outputChatBox("/fr [msg] - Radio de faccion", player, 120, 220, 120)
    outputChatBox("/fduty - Entrar/salir de servicio", player, 120, 220, 120)
    outputChatBox("F7 - Toggle HUD", player, 200, 200, 200)
    outputChatBox("================================================", player, 100, 200, 255)
end)

-- ============================================
-- /fhelp (FACTION HELP)
-- ============================================
addCommandHandler("fhelp", function(player)
    local factionId = getElementData(player, "legends:factionId") or 0
    if factionId == 0 then
        outputChatBox("[Faccion] No perteneces a ninguna faccion", player, 255, 50, 50)
        return
    end

    local factionData = Config.Factions[factionId]
    local factionName = factionData and factionData.name or "Desconocida"

    outputChatBox("========= " .. factionName .. " =========", player, 100, 200, 255)
    outputChatBox("/f [msg] - Chat de faccion", player, 120, 220, 120)
    outputChatBox("/fr [msg] - Radio de faccion", player, 120, 220, 120)
    outputChatBox("/fduty - Entrar/salir de servicio", player, 120, 220, 120)
    outputChatBox("/fmembers - Ver miembros de faccion", player, 120, 220, 120)
    outputChatBox("/franks - Ver rangos de faccion", player, 120, 220, 120)
    outputChatBox("/fvehicle - Spawnear vehiculo de faccion", player, 120, 220, 120)
    outputChatBox("/fequip - Equiparse con armas de faccion", player, 120, 220, 120)
    outputChatBox("/funiform - Ponerse uniforme de faccion", player, 120, 220, 120)

    local rank = getElementData(player, "legends:factionRank") or 0
    if rank >= (Config.FactionPermissions.invite or 3) then
        outputChatBox("/finvite [id] - Invitar jugador", player, 255, 200, 100)
    end
    if rank >= (Config.FactionPermissions.kick or 4) then
        outputChatBox("/fkick [id] - Expulsar miembro", player, 255, 200, 100)
        outputChatBox("/fpromote [id] - Promover miembro", player, 255, 200, 100)
        outputChatBox("/fdemote [id] - Degradar miembro", player, 255, 200, 100)
    end
    outputChatBox("==========================================", player, 100, 200, 255)
end)
