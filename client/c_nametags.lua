--[[
    Legends Roleplay - Custom Nametags
    Displays character name and ID above players
    OPTIMIZED for 4GB RAM - batch limit, distance culling, pre-computed colors
]]

local screenW, screenH = guiGetScreenSize()

-- Disable default nametags
addEventHandler("onClientResourceStart", resourceRoot, function()
    for _, player in ipairs(getElementsByType("player")) do
        setPlayerNametagShowing(player, false)
    end
end)

addEventHandler("onClientPlayerJoin", root, function()
    setPlayerNametagShowing(source, false)
end)

-- Pre-computed colors
local NT_COLORS = {
    nameBg    = tocolor(0, 0, 0, 120),
    nameWhite = tocolor(255, 255, 255, 255),
    idGray    = tocolor(180, 180, 180, 200),
    healthBg  = tocolor(0, 0, 0, 150),
    healthGreen  = tocolor(0, 200, 0, 200),
    healthYellow = tocolor(200, 150, 0, 200),
    healthRed    = tocolor(200, 0, 0, 200),
}

-- ============================================
-- DRAW NAMETAGS (optimized - batch limit, distance culling)
-- ============================================
addEventHandler("onClientRender", root, function()
    local px, py, pz = getElementPosition(localPlayer)
    local nametagDist = Config and Config.NametagRenderDistance or 25
    local maxRendered = Config and Config.MaxStreamedElements or 50
    local rendered = 0

    for _, player in ipairs(getElementsByType("player")) do
        if rendered >= maxRendered then break end
        if player ~= localPlayer and isElementOnScreen(player) and getElementAlpha(player) > 0 then
            local charName = getElementData(player, "legends:charName")
            if charName then
                local x, y, z = getElementPosition(player)
                local dist = getDistanceBetweenPoints3D(px, py, pz, x, y, z)

                if dist <= nametagDist then
                    local boneX, boneY, boneZ = getPedBonePosition(player, 6)
                    local sx, sy = getScreenFromWorldPosition(boneX, boneY, boneZ + 0.35)

                    if sx and sy then
                        rendered = rendered + 1

                        local alpha = 255
                        local fadeStart = nametagDist * 0.7
                        if dist > fadeStart then
                            alpha = math.floor(255 * (1 - (dist - fadeStart) / (nametagDist - fadeStart)))
                        end

                        local charId = getElementData(player, "legends:charId") or 0
                        local nameText = charName
                        local idText = "ID: " .. charId

                        -- Faction tag
                        local factionId = getElementData(player, "legends:factionId") or 0
                        local onDuty = getElementData(player, "legends:onDuty") or false
                        if factionId > 0 and onDuty and Config and Config.Factions[factionId] then
                            local factionData = Config.Factions[factionId]
                            nameText = "[" .. factionData.shortName .. "] " .. charName
                        end

                        -- Name background
                        local nameWidth = dxGetTextWidth(nameText, 1.0, "default-bold")
                        local bgAlpha = math.floor(alpha * 0.47)
                        dxDrawRectangle(sx - nameWidth / 2 - 5, sy - 12, nameWidth + 10, 20,
                            tocolor(0, 0, 0, bgAlpha))

                        -- Name text
                        dxDrawText(nameText, sx, sy - 10, sx, sy + 10,
                            tocolor(255, 255, 255, alpha), 1.0, "default-bold", "center", "top")

                        -- ID text
                        dxDrawText(idText, sx, sy + 10, sx, sy + 22,
                            tocolor(180, 180, 180, math.floor(alpha * 0.78)), 0.85, "default", "center", "top")

                        -- Health bar
                        local health = getElementHealth(player) or 100
                        local barW = 60
                        local barH = 4
                        local barX = sx - barW / 2
                        local barY = sy + 24

                        dxDrawRectangle(barX, barY, barW, barH, tocolor(0, 0, 0, math.floor(alpha * 0.59)))
                        local healthWidth = barW * (health / 100)
                        local r, g, b = 0, 200, 0
                        if health < 25 then r, g, b = 200, 0, 0
                        elseif health < 50 then r, g, b = 200, 150, 0 end
                        dxDrawRectangle(barX, barY, healthWidth, barH, tocolor(r, g, b, math.floor(alpha * 0.78)))
                    end
                end
            end
        end
    end
end)
