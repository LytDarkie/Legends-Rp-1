--[[
    Legends Roleplay - Client Main
    Client-side initialization and utilities
    OPTIMIZED for 4GB RAM - combined render handlers, timer-based checks
]]

-- ============================================
-- RESOURCE START
-- ============================================
addEventHandler("onClientResourceStart", resourceRoot, function()
    guiSetInputMode("no_binds_when_editing")

    outputChatBox("", 255, 255, 255)
    outputChatBox("=============================================", 100, 200, 255)
    outputChatBox("   LEGENDS ROLEPLAY v" .. Config.ServerVersion, 100, 200, 255)
    outputChatBox("   Bienvenido al servidor!", 255, 255, 255)
    outputChatBox("   Usa /ayuda para ver los comandos", 200, 200, 200)
    outputChatBox("   Usa /fhelp para comandos de faccion", 120, 220, 120)
    outputChatBox("=============================================", 100, 200, 255)
    outputChatBox("", 255, 255, 255)
end)

-- ============================================
-- 3D TEXT RENDERING (optimized - distance culling, batch limit)
-- ============================================
local markerTextCache = {}
local markerCacheTime = 0

addEventHandler("onClientRender", root, function()
    local px, py, pz = getElementPosition(localPlayer)
    local markerDist = Config.MarkerStreamDistance or 100
    local rendered = 0
    local maxRender = Config.MaxStreamedElements or 50

    -- Refresh marker list every 2 seconds instead of every frame
    local now = getTickCount()
    if (now - markerCacheTime) > 2000 then
        markerTextCache = {}
        for _, marker in ipairs(getElementsByType("marker")) do
            local text3d = getElementData(marker, "legends:3dtext")
            if text3d then
                table.insert(markerTextCache, { marker = marker, text = text3d })
            end
        end
        markerCacheTime = now
    end

    -- Draw cached markers
    for _, entry in ipairs(markerTextCache) do
        if rendered >= maxRender then break end
        if isElement(entry.marker) then
            local mx, my, mz = getElementPosition(entry.marker)
            local dist = getDistanceBetweenPoints3D(px, py, pz, mx, my, mz)

            if dist <= markerDist then
                local sx, sy = getScreenFromWorldPosition(mx, my, mz + 1.5)
                if sx and sy then
                    rendered = rendered + 1

                    local alpha = 255
                    local fadeStart = markerDist * 0.7
                    if dist > fadeStart then
                        alpha = math.floor(255 * (1 - (dist - fadeStart) / (markerDist - fadeStart)))
                    end

                    local scale = 1.0 - (dist / markerDist) * 0.5

                    -- Draw text lines
                    local lines = split(entry.text, "\n")
                    local lineY = sy
                    for _, line in ipairs(lines) do
                        local textWidth = dxGetTextWidth(line, scale, "default-bold")
                        dxDrawRectangle(sx - textWidth / 2 - 5, lineY - 2, textWidth + 10, 18 * scale,
                            tocolor(0, 0, 0, math.floor(alpha * 0.5)))
                        dxDrawText(line, sx, lineY, sx, lineY + 18 * scale,
                            tocolor(255, 255, 255, alpha), scale, "default-bold", "center", "top")
                        lineY = lineY + 20 * scale
                    end
                end
            end
        end
    end
end)

-- ============================================
-- UTILITY: SPLIT STRING
-- ============================================
function split(str, sep)
    local result = {}
    for part in string.gmatch(str, "([^" .. sep .. "]+)") do
        table.insert(result, part)
    end
    return result
end

-- ============================================
-- ANTI-FALL (timer-based, optimized for 4GB RAM)
-- ============================================
setTimer(function()
    if localPlayer and isElement(localPlayer) then
        local x, y, z = getElementPosition(localPlayer)
        if z < -50 then
            local spawn = Config.DefaultSpawn
            setElementPosition(localPlayer, spawn.x, spawn.y, spawn.z)
        end
    end
end, 2000, 0)
