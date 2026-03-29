--[[
    Legends Roleplay - Faction System
    Server-side faction management (Argentina RP style)
    v2.0.0 - PFA, SAME, Mecanicos, Gobierno, Cartel
]]

local factionCache = {}
local factionVehicles = {}
local onDutyPlayers = {}

-- ============================================
-- INITIALIZATION
-- ============================================
addEventHandler("onResourceStart", resourceRoot, function()
    loadFactionCache()
    createFactionHQMarkers()
    outputDebugString("[Legends] Faction system initialized")
end)

function loadFactionCache()
    local db = getDatabase()
    if not db then return end

    factionCache = {}
    for factionId, factionData in pairs(Config.Factions) do
        local members = dbPoll(dbQuery(db, [[
            SELECT fm.*, c.name as char_name
            FROM faction_members fm
            JOIN characters c ON c.id = fm.character_id
            WHERE fm.faction_id = ?
            ORDER BY fm.rank DESC
        ]], factionId), -1)

        factionCache[factionId] = {
            data = factionData,
            members = members or {},
            leader = 0,
        }

        local factionRow = dbPoll(dbQuery(db, "SELECT leader_id FROM factions WHERE id = ?", factionId), -1)
        if factionRow and #factionRow > 0 then
            factionCache[factionId].leader = factionRow[1].leader_id
        end
    end
end

function createFactionHQMarkers()
    for factionId, factionData in pairs(Config.Factions) do
        local hq = factionData.hq
        if hq then
            local r, g, b = unpack(factionData.color)
            local marker = createMarker(hq.x, hq.y, hq.z - 1, "cylinder", 2.0, r, g, b, 100)
            local blip = createBlipAttachedTo(marker, factionData.blipIcon or 0)
            setBlipColor(blip, r, g, b, 255)
            setElementData(marker, "legends:3dtext", factionData.name .. "\nSede Central")
            setElementData(marker, "legends:factionHQ", factionId)
        end
    end
end

-- ============================================
-- /f - FACTION CHAT
-- ============================================
addCommandHandler("f", function(player, cmd, ...)
    local factionId = getElementData(player, "legends:factionId") or 0
    if factionId == 0 then
        outputChatBox("[Faccion] No perteneces a ninguna faccion", player, 255, 50, 50)
        return
    end

    local msg = table.concat({...}, " ")
    if msg == "" then
        outputChatBox("[Uso] /f [mensaje]", player, 255, 200, 0)
        return
    end

    local charName = getElementData(player, "legends:charName") or "Desconocido"
    local factionData = Config.Factions[factionId]
    local rank = getElementData(player, "legends:factionRank") or 1
    local rankName = factionData.ranks[rank] or "Miembro"
    local r, g, b = unpack(factionData.color)

    -- Send to all faction members online
    for _, p in ipairs(getElementsByType("player")) do
        if getElementData(p, "legends:factionId") == factionId then
            outputChatBox("[" .. factionData.shortName .. "] " .. rankName .. " " .. charName .. ": " .. msg, p, r, g, b)
        end
    end
end)

-- ============================================
-- /fr - FACTION RADIO
-- ============================================
addCommandHandler("fr", function(player, cmd, ...)
    local factionId = getElementData(player, "legends:factionId") or 0
    if factionId == 0 then
        outputChatBox("[Faccion] No perteneces a ninguna faccion", player, 255, 50, 50)
        return
    end

    if not onDutyPlayers[player] then
        outputChatBox("[Faccion] Debes estar en servicio (/fduty)", player, 255, 50, 50)
        return
    end

    local msg = table.concat({...}, " ")
    if msg == "" then
        outputChatBox("[Uso] /fr [mensaje de radio]", player, 255, 200, 0)
        return
    end

    local charName = getElementData(player, "legends:charName") or "Desconocido"
    local factionData = Config.Factions[factionId]
    local r, g, b = unpack(factionData.color)

    for _, p in ipairs(getElementsByType("player")) do
        if getElementData(p, "legends:factionId") == factionId and onDutyPlayers[p] then
            outputChatBox("[RADIO " .. factionData.shortName .. "] " .. charName .. ": " .. msg, p, r, g, b)
        end
    end
end)

-- ============================================
-- /fduty - TOGGLE DUTY
-- ============================================
addCommandHandler("fduty", function(player)
    local factionId = getElementData(player, "legends:factionId") or 0
    if factionId == 0 then
        outputChatBox("[Faccion] No perteneces a ninguna faccion", player, 255, 50, 50)
        return
    end

    local factionData = Config.Factions[factionId]
    local r, g, b = unpack(factionData.color)

    if onDutyPlayers[player] then
        onDutyPlayers[player] = nil
        setElementData(player, "legends:onDuty", false)
        outputChatBox("[Faccion] Saliste de servicio", player, 255, 200, 0)

        -- Notify faction
        local charName = getElementData(player, "legends:charName") or "Desconocido"
        for _, p in ipairs(getElementsByType("player")) do
            if p ~= player and getElementData(p, "legends:factionId") == factionId then
                outputChatBox("[" .. factionData.shortName .. "] " .. charName .. " salio de servicio", p, r, g, b)
            end
        end
    else
        onDutyPlayers[player] = true
        setElementData(player, "legends:onDuty", true)
        outputChatBox("[Faccion] Entraste en servicio", player, 100, 220, 100)

        local charName = getElementData(player, "legends:charName") or "Desconocido"
        for _, p in ipairs(getElementsByType("player")) do
            if p ~= player and getElementData(p, "legends:factionId") == factionId then
                outputChatBox("[" .. factionData.shortName .. "] " .. charName .. " entro en servicio", p, r, g, b)
            end
        end
    end
end)

-- ============================================
-- /finvite - INVITE PLAYER
-- ============================================
addCommandHandler("finvite", function(player, cmd, targetIdStr)
    local factionId = getElementData(player, "legends:factionId") or 0
    if factionId == 0 then
        outputChatBox("[Faccion] No perteneces a ninguna faccion", player, 255, 50, 50)
        return
    end

    local rank = getElementData(player, "legends:factionRank") or 0
    if rank < (Config.FactionPermissions.invite or 3) then
        outputChatBox("[Faccion] No tienes rango suficiente para invitar", player, 255, 50, 50)
        return
    end

    if not targetIdStr then
        outputChatBox("[Uso] /finvite [id del jugador]", player, 255, 200, 0)
        return
    end

    local target = getPlayerFromCharId(tonumber(targetIdStr))
    if not target then
        outputChatBox("[Faccion] Jugador no encontrado", player, 255, 50, 50)
        return
    end

    local targetFaction = getElementData(target, "legends:factionId") or 0
    if targetFaction > 0 then
        outputChatBox("[Faccion] Ese jugador ya pertenece a una faccion", player, 255, 50, 50)
        return
    end

    local db = getDatabase()
    local targetCharId = getElementData(target, "legends:charId")
    local targetName = getElementData(target, "legends:charName") or "Desconocido"
    local factionData = Config.Factions[factionId]

    dbExec(db, "INSERT INTO faction_members (character_id, faction_id, rank) VALUES (?, ?, 1)", targetCharId, factionId)
    dbExec(db, "UPDATE characters SET faction_id = ?, faction_rank = 1 WHERE id = ?", factionId, targetCharId)

    setElementData(target, "legends:factionId", factionId)
    setElementData(target, "legends:factionRank", 1)

    -- Log action
    local charName = getElementData(player, "legends:charName") or "Desconocido"
    logFactionAction(factionId, "invite", charName, targetName, "Invitado a la faccion")

    local r, g, b = unpack(factionData.color)
    outputChatBox("[Faccion] " .. targetName .. " fue invitado a " .. factionData.name, player, r, g, b)
    outputChatBox("[Faccion] Fuiste invitado a " .. factionData.name .. " por " .. charName, target, r, g, b)

    invalidateCache("faction_members")
    loadFactionCache()
end)

-- ============================================
-- /fkick - KICK FROM FACTION
-- ============================================
addCommandHandler("fkick", function(player, cmd, targetIdStr)
    local factionId = getElementData(player, "legends:factionId") or 0
    if factionId == 0 then return end

    local rank = getElementData(player, "legends:factionRank") or 0
    if rank < (Config.FactionPermissions.kick or 4) then
        outputChatBox("[Faccion] No tienes rango suficiente para expulsar", player, 255, 50, 50)
        return
    end

    if not targetIdStr then
        outputChatBox("[Uso] /fkick [id del jugador]", player, 255, 200, 0)
        return
    end

    local target = getPlayerFromCharId(tonumber(targetIdStr))
    if not target then
        outputChatBox("[Faccion] Jugador no encontrado", player, 255, 50, 50)
        return
    end

    local targetFaction = getElementData(target, "legends:factionId") or 0
    if targetFaction ~= factionId then
        outputChatBox("[Faccion] Ese jugador no esta en tu faccion", player, 255, 50, 50)
        return
    end

    local targetRank = getElementData(target, "legends:factionRank") or 0
    if targetRank >= rank then
        outputChatBox("[Faccion] No puedes expulsar a alguien de tu rango o superior", player, 255, 50, 50)
        return
    end

    local db = getDatabase()
    local targetCharId = getElementData(target, "legends:charId")
    local targetName = getElementData(target, "legends:charName") or "Desconocido"
    local factionData = Config.Factions[factionId]

    dbExec(db, "DELETE FROM faction_members WHERE character_id = ? AND faction_id = ?", targetCharId, factionId)
    dbExec(db, "UPDATE characters SET faction_id = 0, faction_rank = 0 WHERE id = ?", targetCharId)

    setElementData(target, "legends:factionId", 0)
    setElementData(target, "legends:factionRank", 0)
    onDutyPlayers[target] = nil

    local charName = getElementData(player, "legends:charName") or "Desconocido"
    logFactionAction(factionId, "kick", charName, targetName, "Expulsado de la faccion")

    local r, g, b = unpack(factionData.color)
    outputChatBox("[Faccion] " .. targetName .. " fue expulsado de " .. factionData.name, player, r, g, b)
    outputChatBox("[Faccion] Fuiste expulsado de " .. factionData.name, target, 255, 50, 50)

    invalidateCache("faction_members")
    loadFactionCache()
end)

-- ============================================
-- /fpromote - PROMOTE MEMBER
-- ============================================
addCommandHandler("fpromote", function(player, cmd, targetIdStr)
    local factionId = getElementData(player, "legends:factionId") or 0
    if factionId == 0 then return end

    local rank = getElementData(player, "legends:factionRank") or 0
    if rank < (Config.FactionPermissions.promote or 4) then
        outputChatBox("[Faccion] No tienes rango suficiente para promover", player, 255, 50, 50)
        return
    end

    if not targetIdStr then
        outputChatBox("[Uso] /fpromote [id del jugador]", player, 255, 200, 0)
        return
    end

    local target = getPlayerFromCharId(tonumber(targetIdStr))
    if not target then
        outputChatBox("[Faccion] Jugador no encontrado", player, 255, 50, 50)
        return
    end

    local targetFaction = getElementData(target, "legends:factionId") or 0
    if targetFaction ~= factionId then
        outputChatBox("[Faccion] Ese jugador no esta en tu faccion", player, 255, 50, 50)
        return
    end

    local targetRank = getElementData(target, "legends:factionRank") or 0
    local factionData = Config.Factions[factionId]
    local maxRank = #factionData.ranks

    if targetRank >= rank - 1 then
        outputChatBox("[Faccion] No puedes promover a alguien a tu rango o superior", player, 255, 50, 50)
        return
    end

    if targetRank >= maxRank then
        outputChatBox("[Faccion] Ese jugador ya tiene el rango maximo", player, 255, 50, 50)
        return
    end

    local newRank = targetRank + 1
    local db = getDatabase()
    local targetCharId = getElementData(target, "legends:charId")
    local targetName = getElementData(target, "legends:charName") or "Desconocido"

    dbExec(db, "UPDATE faction_members SET rank = ? WHERE character_id = ? AND faction_id = ?", newRank, targetCharId, factionId)
    dbExec(db, "UPDATE characters SET faction_rank = ? WHERE id = ?", newRank, targetCharId)

    setElementData(target, "legends:factionRank", newRank)

    local charName = getElementData(player, "legends:charName") or "Desconocido"
    local newRankName = factionData.ranks[newRank] or "Rango " .. newRank
    logFactionAction(factionId, "promote", charName, targetName, "Promovido a " .. newRankName)

    local r, g, b = unpack(factionData.color)
    outputChatBox("[Faccion] " .. targetName .. " fue promovido a " .. newRankName, player, r, g, b)
    outputChatBox("[Faccion] Fuiste promovido a " .. newRankName .. " por " .. charName, target, r, g, b)

    invalidateCache("faction_members")
    loadFactionCache()
end)

-- ============================================
-- /fdemote - DEMOTE MEMBER
-- ============================================
addCommandHandler("fdemote", function(player, cmd, targetIdStr)
    local factionId = getElementData(player, "legends:factionId") or 0
    if factionId == 0 then return end

    local rank = getElementData(player, "legends:factionRank") or 0
    if rank < (Config.FactionPermissions.demote or 4) then
        outputChatBox("[Faccion] No tienes rango suficiente para degradar", player, 255, 50, 50)
        return
    end

    if not targetIdStr then
        outputChatBox("[Uso] /fdemote [id del jugador]", player, 255, 200, 0)
        return
    end

    local target = getPlayerFromCharId(tonumber(targetIdStr))
    if not target then
        outputChatBox("[Faccion] Jugador no encontrado", player, 255, 50, 50)
        return
    end

    local targetFaction = getElementData(target, "legends:factionId") or 0
    if targetFaction ~= factionId then
        outputChatBox("[Faccion] Ese jugador no esta en tu faccion", player, 255, 50, 50)
        return
    end

    local targetRank = getElementData(target, "legends:factionRank") or 0
    if targetRank >= rank then
        outputChatBox("[Faccion] No puedes degradar a alguien de tu rango o superior", player, 255, 50, 50)
        return
    end

    if targetRank <= 1 then
        outputChatBox("[Faccion] Ese jugador ya tiene el rango minimo", player, 255, 50, 50)
        return
    end

    local newRank = targetRank - 1
    local db = getDatabase()
    local targetCharId = getElementData(target, "legends:charId")
    local targetName = getElementData(target, "legends:charName") or "Desconocido"
    local factionData = Config.Factions[factionId]

    dbExec(db, "UPDATE faction_members SET rank = ? WHERE character_id = ? AND faction_id = ?", newRank, targetCharId, factionId)
    dbExec(db, "UPDATE characters SET faction_rank = ? WHERE id = ?", newRank, targetCharId)

    setElementData(target, "legends:factionRank", newRank)

    local charName = getElementData(player, "legends:charName") or "Desconocido"
    local newRankName = factionData.ranks[newRank] or "Rango " .. newRank
    logFactionAction(factionId, "demote", charName, targetName, "Degradado a " .. newRankName)

    local r, g, b = unpack(factionData.color)
    outputChatBox("[Faccion] " .. targetName .. " fue degradado a " .. newRankName, player, r, g, b)
    outputChatBox("[Faccion] Fuiste degradado a " .. newRankName, target, 255, 200, 0)

    invalidateCache("faction_members")
    loadFactionCache()
end)

-- ============================================
-- /fmembers - VIEW MEMBERS
-- ============================================
addCommandHandler("fmembers", function(player)
    local factionId = getElementData(player, "legends:factionId") or 0
    if factionId == 0 then
        outputChatBox("[Faccion] No perteneces a ninguna faccion", player, 255, 50, 50)
        return
    end

    local factionData = Config.Factions[factionId]
    local r, g, b = unpack(factionData.color)
    local db = getDatabase()

    local members = dbPoll(dbQuery(db, [[
        SELECT fm.rank, c.name, c.id as char_id
        FROM faction_members fm
        JOIN characters c ON c.id = fm.character_id
        WHERE fm.faction_id = ?
        ORDER BY fm.rank DESC
    ]], factionId), -1)

    outputChatBox("=== " .. factionData.name .. " - Miembros (" .. #members .. ") ===", player, r, g, b)
    for _, member in ipairs(members) do
        local rankName = factionData.ranks[member.rank] or "Rango " .. member.rank
        local online = getPlayerFromCharId(member.char_id) and " [Online]" or ""
        outputChatBox("[" .. member.rank .. "] " .. rankName .. " - " .. member.name .. online, player, 255, 255, 255)
    end
end)

-- ============================================
-- /franks - VIEW RANKS
-- ============================================
addCommandHandler("franks", function(player)
    local factionId = getElementData(player, "legends:factionId") or 0
    if factionId == 0 then
        outputChatBox("[Faccion] No perteneces a ninguna faccion", player, 255, 50, 50)
        return
    end

    local factionData = Config.Factions[factionId]
    local r, g, b = unpack(factionData.color)

    outputChatBox("=== " .. factionData.name .. " - Rangos ===", player, r, g, b)
    for rankNum, rankName in pairs(factionData.ranks) do
        local salary = Config.FactionSalary[factionId] and Config.FactionSalary[factionId][rankNum] or 0
        outputChatBox("[" .. rankNum .. "] " .. rankName .. " - Salario: $" .. salary, player, 255, 255, 255)
    end
end)

-- ============================================
-- /fvehicle - SPAWN FACTION VEHICLE
-- ============================================
addCommandHandler("fvehicle", function(player, cmd, vehIndexStr)
    local factionId = getElementData(player, "legends:factionId") or 0
    if factionId == 0 then
        outputChatBox("[Faccion] No perteneces a ninguna faccion", player, 255, 50, 50)
        return
    end

    if not onDutyPlayers[player] then
        outputChatBox("[Faccion] Debes estar en servicio (/fduty)", player, 255, 50, 50)
        return
    end

    local factionData = Config.Factions[factionId]
    if not factionData.vehicles or #factionData.vehicles == 0 then
        outputChatBox("[Faccion] Tu faccion no tiene vehiculos", player, 255, 50, 50)
        return
    end

    if not vehIndexStr then
        outputChatBox("=== Vehiculos de " .. factionData.shortName .. " ===", player, 100, 200, 255)
        for i, veh in ipairs(factionData.vehicles) do
            outputChatBox(i .. ". " .. veh.name, player, 255, 255, 255)
        end
        outputChatBox("Usa /fvehicle [numero]", player, 200, 200, 200)
        return
    end

    local vehIndex = tonumber(vehIndexStr)
    if not vehIndex or not factionData.vehicles[vehIndex] then
        outputChatBox("[Faccion] Vehiculo invalido", player, 255, 50, 50)
        return
    end

    -- Destroy previous faction vehicle if exists
    if factionVehicles[player] and isElement(factionVehicles[player]) then
        destroyElement(factionVehicles[player])
    end

    local vehData = factionData.vehicles[vehIndex]
    local px, py, pz = getElementPosition(player)
    local vehicle = createVehicle(vehData.model, px + 3, py, pz + 1)

    if vehicle then
        if vehData.colors then
            setVehicleColor(vehicle, vehData.colors[1] or 0, vehData.colors[2] or 0, 0, 0)
        end
        setElementData(vehicle, "legends:factionVehicle", factionId)
        setElementData(vehicle, "legends:fuel", Config.MaxFuel)
        setVehicleEngineState(vehicle, true)
        warpPedIntoVehicle(player, vehicle)

        factionVehicles[player] = vehicle
        outputChatBox("[Faccion] Spawneaste: " .. vehData.name, player, 100, 220, 100)
    end
end)

-- ============================================
-- /fequip - EQUIP FACTION WEAPONS
-- ============================================
addCommandHandler("fequip", function(player)
    local factionId = getElementData(player, "legends:factionId") or 0
    if factionId == 0 then
        outputChatBox("[Faccion] No perteneces a ninguna faccion", player, 255, 50, 50)
        return
    end

    if not onDutyPlayers[player] then
        outputChatBox("[Faccion] Debes estar en servicio (/fduty)", player, 255, 50, 50)
        return
    end

    local factionData = Config.Factions[factionId]
    local rank = getElementData(player, "legends:factionRank") or 1

    if not factionData.weapons or not factionData.weapons[rank] then
        outputChatBox("[Faccion] Tu rango no tiene armas asignadas", player, 255, 200, 0)
        return
    end

    -- Check if near HQ
    local px, py, pz = getElementPosition(player)
    local hq = factionData.hq
    if getDistanceBetweenPoints3D(px, py, pz, hq.x, hq.y, hq.z) > 10 then
        outputChatBox("[Faccion] Debes estar en la sede (HQ) para equiparte", player, 255, 50, 50)
        return
    end

    for _, weaponId in ipairs(factionData.weapons[rank]) do
        giveWeapon(player, weaponId, 200, true)
    end

    outputChatBox("[Faccion] Te equipaste con las armas de tu rango", player, 100, 220, 100)
end)

-- ============================================
-- /funiform - EQUIP FACTION SKIN
-- ============================================
addCommandHandler("funiform", function(player)
    local factionId = getElementData(player, "legends:factionId") or 0
    if factionId == 0 then
        outputChatBox("[Faccion] No perteneces a ninguna faccion", player, 255, 50, 50)
        return
    end

    if not onDutyPlayers[player] then
        outputChatBox("[Faccion] Debes estar en servicio (/fduty)", player, 255, 50, 50)
        return
    end

    local factionData = Config.Factions[factionId]
    local rank = getElementData(player, "legends:factionRank") or 1

    if not factionData.skins or not factionData.skins[rank] then
        outputChatBox("[Faccion] Tu rango no tiene uniforme asignado", player, 255, 200, 0)
        return
    end

    setElementModel(player, factionData.skins[rank])
    outputChatBox("[Faccion] Te pusiste el uniforme de " .. (factionData.ranks[rank] or "tu rango"), player, 100, 220, 100)
end)

-- ============================================
-- /fsetleader - ADMIN: SET FACTION LEADER
-- ============================================
addCommandHandler("fsetleader", function(player, cmd, targetIdStr, factionIdStr)
    if not isPlayerAdmin(player, 3) then
        outputChatBox("[Admin] No tienes permisos (requiere Admin Senior)", player, 255, 50, 50)
        return
    end

    if not targetIdStr or not factionIdStr then
        outputChatBox("[Uso] /fsetleader [id jugador] [id faccion]", player, 255, 200, 0)
        return
    end

    local target = getPlayerFromCharId(tonumber(targetIdStr))
    if not target then
        outputChatBox("[Admin] Jugador no encontrado", player, 255, 50, 50)
        return
    end

    local factionId = tonumber(factionIdStr)
    local factionData = Config.Factions[factionId]
    if not factionData then
        outputChatBox("[Admin] Faccion invalida", player, 255, 50, 50)
        return
    end

    local db = getDatabase()
    local targetCharId = getElementData(target, "legends:charId")
    local targetName = getElementData(target, "legends:charName") or "Desconocido"
    local maxRank = #factionData.ranks

    -- Remove from current faction if any
    local currentFaction = getElementData(target, "legends:factionId") or 0
    if currentFaction > 0 then
        dbExec(db, "DELETE FROM faction_members WHERE character_id = ?", targetCharId)
    end

    -- Add to new faction as leader
    dbExec(db, "INSERT OR REPLACE INTO faction_members (character_id, faction_id, rank) VALUES (?, ?, ?)", targetCharId, factionId, maxRank)
    dbExec(db, "UPDATE characters SET faction_id = ?, faction_rank = ? WHERE id = ?", factionId, maxRank, targetCharId)
    dbExec(db, "UPDATE factions SET leader_id = ? WHERE id = ?", targetCharId, factionId)

    setElementData(target, "legends:factionId", factionId)
    setElementData(target, "legends:factionRank", maxRank)

    local r, g, b = unpack(factionData.color)
    outputChatBox("[Admin] " .. targetName .. " es ahora lider de " .. factionData.name, player, r, g, b)
    outputChatBox("[Faccion] Fuiste nombrado lider de " .. factionData.name, target, r, g, b)

    logFactionAction(factionId, "set_leader", getElementData(player, "legends:charName") or "Admin", targetName, "Nombrado lider")
    invalidateCache("faction_members")
    loadFactionCache()
end)

-- ============================================
-- /flist - ADMIN: LIST ALL FACTIONS
-- ============================================
addCommandHandler("flist", function(player)
    if not isPlayerAdmin(player, 1) then
        outputChatBox("[Admin] No tienes permisos", player, 255, 50, 50)
        return
    end

    outputChatBox("=== Facciones ===", player, 100, 200, 255)
    local db = getDatabase()
    for factionId, factionData in pairs(Config.Factions) do
        local memberCount = dbPoll(dbQuery(db, "SELECT COUNT(*) as count FROM faction_members WHERE faction_id = ?", factionId), -1)
        local count = memberCount and memberCount[1].count or 0
        local r, g, b = unpack(factionData.color)
        outputChatBox("[" .. factionId .. "] " .. factionData.name .. " (" .. factionData.shortName .. ") - " .. count .. " miembros", player, r, g, b)
    end
end)

-- ============================================
-- FACTION LOG
-- ============================================
function logFactionAction(factionId, action, actor, target, details)
    local db = getDatabase()
    if not db then return end
    dbExec(db, "INSERT INTO faction_logs (faction_id, action, actor, target, details) VALUES (?, ?, ?, ?, ?)",
        factionId, action, actor or "", target or "", details or "")
end)

-- ============================================
-- CLEANUP ON PLAYER QUIT
-- ============================================
addEventHandler("onPlayerQuit", root, function()
    onDutyPlayers[source] = nil
    if factionVehicles[source] and isElement(factionVehicles[source]) then
        destroyElement(factionVehicles[source])
    end
    factionVehicles[source] = nil
end)

-- ============================================
-- AUTO-CLEANUP INACTIVE FACTION VEHICLES (4GB RAM optimization)
-- ============================================
setTimer(function()
    for player, vehicle in pairs(factionVehicles) do
        if not isElement(player) or not isElement(vehicle) then
            if isElement(vehicle) then destroyElement(vehicle) end
            factionVehicles[player] = nil
        elseif not getPedOccupiedVehicle(player) then
            -- If player is not in the vehicle and it's been idle
            local vx, vy, vz = getElementVelocity(vehicle)
            if math.abs(vx) < 0.01 and math.abs(vy) < 0.01 and math.abs(vz) < 0.01 then
                local occupants = getVehicleOccupants(vehicle)
                local hasOccupant = false
                for _ in pairs(occupants or {}) do
                    hasOccupant = true
                    break
                end
                if not hasOccupant then
                    destroyElement(vehicle)
                    factionVehicles[player] = nil
                end
            end
        end
    end
end, 300000, 0) -- Every 5 minutes
