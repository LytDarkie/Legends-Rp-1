--[[
    Legends Roleplay - Vehicle System
    Vehicle purchase, management, fuel, parking
    v2.0.0 - Fuel tick optimized to 60s for 4GB RAM
]]

local spawnedVehicles = {}

-- ============================================
-- CREATE VEHICLE SHOP MARKERS
-- ============================================
addEventHandler("onResourceStart", resourceRoot, function()
    for _, shop in ipairs(Config.VehicleShops) do
        local marker = createMarker(shop.x, shop.y, shop.z - 1, "cylinder", 2.0, 0, 100, 255, 100)
        local blip = createBlipAttachedTo(marker, 55)
        setElementData(marker, "legends:3dtext", shop.name .. "\n/comprarauto")
        setElementData(marker, "legends:shopIndex", _)
    end
end)

-- ============================================
-- BUY VEHICLE
-- ============================================
addCommandHandler("comprarauto", function(player)
    if not isPlayerLoggedIn(player) then return end

    local px, py, pz = getElementPosition(player)
    for shopIndex, shop in ipairs(Config.VehicleShops) do
        if getDistanceBetweenPoints3D(px, py, pz, shop.x, shop.y, shop.z) <= 5 then
            outputChatBox("=== " .. shop.name .. " ===", player, 100, 200, 255)
            for i, veh in ipairs(shop.vehicles) do
                outputChatBox(i .. ". " .. veh.name .. " - $" .. veh.price, player, 255, 255, 255)
            end
            outputChatBox("Usa /comprarveh [numero] para comprar", player, 200, 200, 200)
            return
        end
    end
    outputChatBox("[Vehiculos] Debes estar en una concesionaria", player, 255, 50, 50)
end)

addCommandHandler("comprarveh", function(player, cmd, index)
    if not isPlayerLoggedIn(player) then return end

    local px, py, pz = getElementPosition(player)
    for shopIndex, shop in ipairs(Config.VehicleShops) do
        if getDistanceBetweenPoints3D(px, py, pz, shop.x, shop.y, shop.z) <= 5 then
            local idx = tonumber(index)
            if not idx or not shop.vehicles[idx] then
                outputChatBox("[Vehiculos] Numero de vehiculo invalido", player, 255, 50, 50)
                return
            end

            local vehData = shop.vehicles[idx]
            local money = getPlayerMoney(player)
            if money < vehData.price then
                outputChatBox("[Vehiculos] No tienes suficiente dinero ($" .. vehData.price .. ")", player, 255, 50, 50)
                return
            end

            takePlayerMoney(player, vehData.price)

            -- Create vehicle
            local veh = createVehicle(vehData.model, shop.x + 5, shop.y, shop.z + 1)
            if veh then
                local db = getDatabase()
                local charId = getElementData(player, "legends:charId")
                local vx, vy, vz = getElementPosition(veh)
                local _, _, vrz = getElementRotation(veh)

                local plate = "LS-" .. math.random(1000, 9999)
                setVehiclePlateText(veh, plate)
                setElementData(veh, "legends:fuel", Config.MaxFuel)
                setElementData(veh, "legends:owner", charId)

                dbExec(db, "INSERT INTO vehicles (owner_id, model, x, y, z, rz, plate, fuel) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                    charId, vehData.model, vx, vy, vz, vrz, plate, Config.MaxFuel)

                local result = dbPoll(dbQuery(db, "SELECT last_insert_rowid() as id"), -1)
                if result and #result > 0 then
                    setElementData(veh, "legends:vehId", result[1].id)
                    spawnedVehicles[result[1].id] = veh
                end

                warpPedIntoVehicle(player, veh)
                outputChatBox("[Vehiculos] Compraste un " .. vehData.name .. " por $" .. vehData.price, player, 100, 220, 100)
                invalidateCache("vehicles")
            end
            return
        end
    end
    outputChatBox("[Vehiculos] Debes estar en una concesionaria", player, 255, 50, 50)
end)

-- ============================================
-- MY VEHICLES
-- ============================================
addCommandHandler("misautos", function(player)
    if not isPlayerLoggedIn(player) then return end

    local db = getDatabase()
    local charId = getElementData(player, "legends:charId")
    local vehicles = cachedQuery("SELECT * FROM vehicles WHERE owner_id = ?", charId)

    if #vehicles == 0 then
        outputChatBox("[Vehiculos] No tienes vehiculos", player, 255, 200, 0)
        return
    end

    outputChatBox("=== Tus Vehiculos ===", player, 100, 200, 255)
    for _, veh in ipairs(vehicles) do
        local modelName = getVehicleNameFromModel(veh.model) or "Desconocido"
        outputChatBox("ID: " .. veh.id .. " | " .. modelName .. " | Placa: " .. veh.plate, player, 255, 255, 255)
    end
end)

-- ============================================
-- ENGINE TOGGLE
-- ============================================
addCommandHandler("motor", function(player)
    local vehicle = getPedOccupiedVehicle(player)
    if not vehicle then
        outputChatBox("[Vehiculos] Debes estar en un vehiculo", player, 255, 50, 50)
        return
    end

    if getVehicleOccupant(vehicle) ~= player then
        outputChatBox("[Vehiculos] Debes ser el conductor", player, 255, 50, 50)
        return
    end

    local fuel = getElementData(vehicle, "legends:fuel") or 0
    if fuel <= 0 then
        outputChatBox("[Vehiculos] Sin combustible", player, 255, 50, 50)
        return
    end

    local state = getVehicleEngineState(vehicle)
    setVehicleEngineState(vehicle, not state)

    if state then
        outputChatBox("[Vehiculos] Motor apagado", player, 255, 200, 0)
    else
        outputChatBox("[Vehiculos] Motor encendido", player, 100, 220, 100)
    end
end)

-- ============================================
-- LOCK/UNLOCK
-- ============================================
addCommandHandler("lock", function(player)
    local vehicle = getPedOccupiedVehicle(player)
    if not vehicle then
        -- Find nearest owned vehicle
        local charId = getElementData(player, "legends:charId")
        local px, py, pz = getElementPosition(player)
        local nearestVeh = nil
        local nearestDist = 10

        for _, veh in ipairs(getElementsByType("vehicle")) do
            if getElementData(veh, "legends:owner") == charId then
                local vx, vy, vz = getElementPosition(veh)
                local dist = getDistanceBetweenPoints3D(px, py, pz, vx, vy, vz)
                if dist < nearestDist then
                    nearestDist = dist
                    nearestVeh = veh
                end
            end
        end

        if not nearestVeh then
            outputChatBox("[Vehiculos] No hay vehiculos tuyos cerca", player, 255, 50, 50)
            return
        end
        vehicle = nearestVeh
    else
        local owner = getElementData(vehicle, "legends:owner")
        local charId = getElementData(player, "legends:charId")
        if owner ~= charId then
            outputChatBox("[Vehiculos] No eres el dueño de este vehiculo", player, 255, 50, 50)
            return
        end
    end

    local locked = isVehicleLocked(vehicle)
    setVehicleLocked(vehicle, not locked)

    if locked then
        outputChatBox("[Vehiculos] Vehiculo desbloqueado", player, 100, 220, 100)
    else
        outputChatBox("[Vehiculos] Vehiculo bloqueado", player, 255, 200, 0)
    end
end)

-- ============================================
-- FUEL SYSTEM (optimized tick: 60s)
-- ============================================
setTimer(function()
    for _, vehicle in ipairs(getElementsByType("vehicle")) do
        if getVehicleEngineState(vehicle) then
            local fuel = getElementData(vehicle, "legends:fuel") or Config.MaxFuel
            local speed = getElementSpeed(vehicle) or 0
            local consumption = Config.FuelConsumption * (1 + speed / 100)
            fuel = math.max(0, fuel - consumption)
            setElementData(vehicle, "legends:fuel", fuel)

            if fuel <= 0 then
                setVehicleEngineState(vehicle, false)
                local driver = getVehicleOccupant(vehicle)
                if driver then
                    outputChatBox("[Vehiculos] Se acabo el combustible!", driver, 255, 50, 50)
                end
            end
        end
    end
end, Config.FuelTickInterval or 60000, 0)

-- ============================================
-- GET VEHICLE SPEED UTILITY
-- ============================================
function getElementSpeed(element)
    if not isElement(element) then return 0 end
    local vx, vy, vz = getElementVelocity(element)
    return math.sqrt(vx * vx + vy * vy + vz * vz) * 180
end

-- ============================================
-- PARK VEHICLE
-- ============================================
addCommandHandler("estacionar", function(player)
    local vehicle = getPedOccupiedVehicle(player)
    if not vehicle then
        outputChatBox("[Vehiculos] Debes estar en un vehiculo", player, 255, 50, 50)
        return
    end

    local owner = getElementData(vehicle, "legends:owner")
    local charId = getElementData(player, "legends:charId")
    if owner ~= charId then
        outputChatBox("[Vehiculos] No eres el dueño de este vehiculo", player, 255, 50, 50)
        return
    end

    local vehId = getElementData(vehicle, "legends:vehId")
    if not vehId then return end

    local db = getDatabase()
    local x, y, z = getElementPosition(vehicle)
    local rx, ry, rz = getElementRotation(vehicle)
    local fuel = getElementData(vehicle, "legends:fuel") or Config.MaxFuel

    dbExec(db, "UPDATE vehicles SET x = ?, y = ?, z = ?, rx = ?, ry = ?, rz = ?, fuel = ? WHERE id = ?",
        x, y, z, rx, ry, rz, fuel, vehId)

    invalidateCache("vehicles")
    outputChatBox("[Vehiculos] Vehiculo estacionado", player, 100, 220, 100)
end)
