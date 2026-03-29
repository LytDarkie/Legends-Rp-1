--[[
    Legends Roleplay - Client Faction GUI
    Faction info panel (F6)
    v2.0.0
]]

local screenW, screenH = guiGetScreenSize()
local factionWindow = nil

-- ============================================
-- TOGGLE FACTION PANEL (F6)
-- ============================================
bindKey("F6", "down", function()
    local factionId = getElementData(localPlayer, "legends:factionId") or 0
    if factionId == 0 then
        outputChatBox("[Faccion] No perteneces a ninguna faccion", 255, 50, 50)
        return
    end

    if factionWindow and isElement(factionWindow) then
        destroyElement(factionWindow)
        factionWindow = nil
        showCursor(false)
        return
    end

    showFactionPanel(factionId)
end)

-- ============================================
-- SHOW FACTION PANEL
-- ============================================
function showFactionPanel(factionId)
    local factionData = Config.Factions[factionId]
    if not factionData then return end

    showCursor(true)

    local w, h = 450, 400
    local x, y = (screenW - w) / 2, (screenH - h) / 2

    factionWindow = guiCreateWindow(x, y, w, h, factionData.name .. " - Panel de Faccion", false)
    guiWindowSetSizable(factionWindow, false)

    -- Faction info
    local rank = getElementData(localPlayer, "legends:factionRank") or 1
    local rankName = factionData.ranks[rank] or "Miembro"
    local onDuty = getElementData(localPlayer, "legends:onDuty") or false
    local dutyText = onDuty and "EN SERVICIO" or "FUERA DE SERVICIO"
    local r, g, b = unpack(factionData.color)

    guiCreateLabel(20, 30, 410, 20, "Faccion: " .. factionData.name .. " (" .. factionData.shortName .. ")", false, factionWindow)
    guiCreateLabel(20, 55, 410, 20, "Tu Rango: [" .. rank .. "] " .. rankName, false, factionWindow)

    local dutyLabel = guiCreateLabel(20, 80, 200, 20, "Estado: " .. dutyText, false, factionWindow)
    if onDuty then
        guiLabelSetColor(dutyLabel, 100, 220, 100)
    else
        guiLabelSetColor(dutyLabel, 255, 100, 100)
    end

    -- Ranks list
    guiCreateLabel(20, 115, 200, 20, "--- Rangos ---", false, factionWindow)
    local yOff = 135
    for rankNum, rName in pairs(factionData.ranks) do
        local salary = Config.FactionSalary[factionId] and Config.FactionSalary[factionId][rankNum] or 0
        guiCreateLabel(20, yOff, 410, 20, "[" .. rankNum .. "] " .. rName .. " - $" .. salary .. "/paga", false, factionWindow)
        yOff = yOff + 20
    end

    -- Commands help
    yOff = yOff + 15
    guiCreateLabel(20, yOff, 410, 20, "--- Comandos ---", false, factionWindow)
    yOff = yOff + 20

    local commands = {
        "/f [msg] - Chat de faccion",
        "/fr [msg] - Radio (en servicio)",
        "/fduty - Entrar/Salir de servicio",
        "/fmembers - Ver miembros",
        "/franks - Ver rangos",
        "/fvehicle - Vehiculo de faccion",
        "/fequip - Equiparse (en HQ)",
        "/funiform - Uniforme (en servicio)",
    }

    for _, cmdText in ipairs(commands) do
        guiCreateLabel(20, yOff, 410, 18, cmdText, false, factionWindow)
        yOff = yOff + 18
    end

    -- Close button
    local closeBtn = guiCreateButton(w - 110, h - 45, 90, 30, "Cerrar", false, factionWindow)
    addEventHandler("onClientGUIClick", closeBtn, function()
        if factionWindow and isElement(factionWindow) then
            destroyElement(factionWindow)
            factionWindow = nil
            showCursor(false)
        end
    end, false)
end
