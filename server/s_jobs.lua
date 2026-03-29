--[[
    Legends Roleplay - Job System
    Job markers, routes, and payment system
    v2.0.0
]]

local playerJobs = {}
local jobMarkers = {}

-- ============================================
-- CREATE JOB MARKERS
-- ============================================
addEventHandler("onResourceStart", resourceRoot, function()
    for i, job in ipairs(Config.Jobs) do
        local marker = createMarker(job.marker.x, job.marker.y, job.marker.z - 1, "cylinder", 2.0, 255, 200, 0, 100)
        local blip = createBlipAttachedTo(marker, 56)
        setElementData(marker, "legends:3dtext", job.name .. "\n/trabajo")
        setElementData(marker, "legends:jobIndex", i)
        jobMarkers[i] = { marker = marker, blip = blip }
    end
end)

-- ============================================
-- JOB LIST
-- ============================================
addCommandHandler("trabajo", function(player)
    if not isPlayerLoggedIn(player) then return end

    local px, py, pz = getElementPosition(player)
    local nearJob = false

    for i, job in ipairs(Config.Jobs) do
        if getDistanceBetweenPoints3D(px, py, pz, job.marker.x, job.marker.y, job.marker.z) <= 5 then
            outputChatBox("=== " .. job.name .. " ===", player, 255, 200, 0)
            outputChatBox("Pago por ruta: $" .. job.payPerRoute, player, 255, 255, 255)
            outputChatBox("Usa /tomartrabajo " .. i .. " para comenzar", player, 200, 200, 200)
            nearJob = true
        end
    end

    if not nearJob then
        outputChatBox("=== Trabajos Disponibles ===", player, 255, 200, 0)
        for i, job in ipairs(Config.Jobs) do
            outputChatBox(i .. ". " .. job.name .. " - $" .. job.payPerRoute .. "/ruta", player, 255, 255, 255)
        end
        outputChatBox("Ve al marcador del trabajo para tomarlo", player, 200, 200, 200)
    end
end)

-- ============================================
-- TAKE JOB
-- ============================================
addCommandHandler("tomartrabajo", function(player, cmd, jobIndexStr)
    if not isPlayerLoggedIn(player) then return end

    local jobIndex = tonumber(jobIndexStr)
    if not jobIndex or not Config.Jobs[jobIndex] then
        outputChatBox("[Trabajo] Numero de trabajo invalido", player, 255, 50, 50)
        return
    end

    local job = Config.Jobs[jobIndex]
    local px, py, pz = getElementPosition(player)

    if getDistanceBetweenPoints3D(px, py, pz, job.marker.x, job.marker.y, job.marker.z) > 10 then
        outputChatBox("[Trabajo] Debes estar en el marcador del trabajo", player, 255, 50, 50)
        return
    end

    -- Spawn job vehicle
    local vehicle = createVehicle(job.vehicle, job.marker.x + 3, job.marker.y, job.marker.z + 1)
    if vehicle then
        setElementData(vehicle, "legends:fuel", Config.MaxFuel)
        setElementData(vehicle, "legends:jobVehicle", true)
        setVehicleEngineState(vehicle, true)
        warpPedIntoVehicle(player, vehicle)

        setElementData(player, "legends:job", job.name)

        -- Start route
        playerJobs[player] = {
            jobIndex = jobIndex,
            vehicle = vehicle,
            currentRoute = 1,
            routeMarker = nil,
        }

        createRouteMarker(player)
        outputChatBox("[Trabajo] Comenzaste como " .. job.name .. ". Sigue los marcadores!", player, 100, 220, 100)
    end
end)

-- ============================================
-- CREATE ROUTE MARKERS
-- ============================================
function createRouteMarker(player)
    local jobData = playerJobs[player]
    if not jobData then return end

    local job = Config.Jobs[jobData.jobIndex]
    if not job then return end

    -- Destroy previous marker
    if jobData.routeMarker and isElement(jobData.routeMarker) then
        destroyElement(jobData.routeMarker)
    end

    local route = job.routes[jobData.currentRoute]
    if not route then
        -- All routes completed
        finishJob(player)
        return
    end

    local marker = createMarker(route.x, route.y, route.z - 1, "checkpoint", 3.0, 255, 200, 0, 200)
    setElementData(marker, "legends:3dtext", "Punto " .. jobData.currentRoute .. "/" .. #job.routes)
    jobData.routeMarker = marker

    -- Create blip for route point
    local blip = createBlipAttachedTo(marker, 0, 2, 255, 200, 0)
    setElementData(marker, "legends:routeBlip", blip)
end

-- ============================================
-- ROUTE CHECKPOINT HIT
-- ============================================
addEventHandler("onMarkerHit", root, function(hitElement, matchingDimension)
    if not matchingDimension then return end
    if getElementType(hitElement) ~= "player" then return end

    local jobData = playerJobs[hitElement]
    if not jobData then return end

    if source == jobData.routeMarker then
        local job = Config.Jobs[jobData.jobIndex]

        -- Destroy marker and blip
        local blip = getElementData(source, "legends:routeBlip")
        if blip and isElement(blip) then destroyElement(blip) end
        destroyElement(source)

        jobData.currentRoute = jobData.currentRoute + 1
        outputChatBox("[Trabajo] Punto " .. (jobData.currentRoute - 1) .. "/" .. #job.routes .. " completado", hitElement, 100, 220, 100)

        createRouteMarker(hitElement)
    end
end)

-- ============================================
-- FINISH JOB
-- ============================================
function finishJob(player)
    local jobData = playerJobs[player]
    if not jobData then return end

    local job = Config.Jobs[jobData.jobIndex]
    if not job then return end

    givePlayerMoney(player, job.payPerRoute)
    outputChatBox("[Trabajo] Ruta completada! +$" .. job.payPerRoute, player, 100, 220, 100)

    -- Destroy job vehicle
    if jobData.vehicle and isElement(jobData.vehicle) then
        local occupants = getVehicleOccupants(jobData.vehicle)
        for _, occ in pairs(occupants or {}) do
            removePedFromVehicle(occ)
        end
        destroyElement(jobData.vehicle)
    end

    setElementData(player, "legends:job", "Desempleado")
    playerJobs[player] = nil
end

-- ============================================
-- QUIT JOB
-- ============================================
addCommandHandler("dejartrabajo", function(player)
    local jobData = playerJobs[player]
    if not jobData then
        outputChatBox("[Trabajo] No tienes un trabajo activo", player, 255, 50, 50)
        return
    end

    -- Cleanup
    if jobData.routeMarker and isElement(jobData.routeMarker) then
        local blip = getElementData(jobData.routeMarker, "legends:routeBlip")
        if blip and isElement(blip) then destroyElement(blip) end
        destroyElement(jobData.routeMarker)
    end
    if jobData.vehicle and isElement(jobData.vehicle) then
        removePedFromVehicle(player)
        destroyElement(jobData.vehicle)
    end

    setElementData(player, "legends:job", "Desempleado")
    playerJobs[player] = nil
    outputChatBox("[Trabajo] Dejaste tu trabajo", player, 255, 200, 0)
end)

-- ============================================
-- CLEANUP ON PLAYER QUIT
-- ============================================
addEventHandler("onPlayerQuit", root, function()
    if playerJobs[source] then
        local jobData = playerJobs[source]
        if jobData.routeMarker and isElement(jobData.routeMarker) then
            local blip = getElementData(jobData.routeMarker, "legends:routeBlip")
            if blip and isElement(blip) then destroyElement(blip) end
            destroyElement(jobData.routeMarker)
        end
        if jobData.vehicle and isElement(jobData.vehicle) then
            destroyElement(jobData.vehicle)
        end
        playerJobs[source] = nil
    end
end)
