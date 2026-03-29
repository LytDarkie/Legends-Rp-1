--[[
    Legends Roleplay - Custom HUD
    Custom HUD with player info, money, health, etc.
    OPTIMIZED for 4GB RAM servers - cached rendering, reduced draw calls
]]

local screenW, screenH = guiGetScreenSize()
local hudEnabled = true
local notificationQueue = {}

-- ============================================
-- HUD DATA CACHE (reduces getElementData calls per frame)
-- ============================================
local hudCache = {
    charName = "",
    money = 0,
    moneyFormatted = "$0",
    health = 100,
    armor = 0,
    job = "Desempleado",
    lastUpdate = 0,
}

-- Pre-computed colors (avoid creating tocolor every frame)
local COLORS = {
    bgBlack       = tocolor(0, 0, 0, 150),
    accentBlue    = tocolor(100, 200, 255, 255),
    white         = tocolor(255, 255, 255, 255),
    moneyGreen    = tocolor(100, 220, 100, 255),
    textGray      = tocolor(200, 200, 200, 200),
    textGrayLight = tocolor(200, 200, 200, 180),
    healthBg      = tocolor(60, 0, 0, 200),
    healthGreen   = tocolor(0, 180, 0, 200),
    healthYellow  = tocolor(200, 150, 0, 200),
    healthRed     = tocolor(200, 0, 0, 200),
    armorBg       = tocolor(0, 0, 60, 200),
    armorBlue     = tocolor(50, 100, 200, 200),
    vehBg         = tocolor(0, 0, 0, 150),
    vehAccent     = tocolor(255, 200, 0, 255),
    vehWhite      = tocolor(255, 255, 255, 255),
    darkBg        = tocolor(40, 40, 40, 200),
    fuelYellow    = tocolor(255, 200, 0, 200),
    fuelRed       = tocolor(200, 0, 0, 200),
    timeWhite     = tocolor(255, 255, 255, 200),
}

-- Pre-computed HUD positions
local HUD = {
    x = screenW - 280,
    y = 20,
    w = 260,
    h = 130,
}
HUD.barX = HUD.x + 10
HUD.barY = HUD.y + 65
HUD.barW = HUD.w - 20
HUD.barH = 12

-- ============================================
-- DISABLE DEFAULT HUD
-- ============================================
addEventHandler("onClientResourceStart", resourceRoot, function()
    setPlayerHudComponentVisible("health", false)
    setPlayerHudComponentVisible("armour", false)
    setPlayerHudComponentVisible("breath", false)
    setPlayerHudComponentVisible("clock", false)
    setPlayerHudComponentVisible("money", false)
    setPlayerHudComponentVisible("weapon", false)
    setPlayerHudComponentVisible("ammo", false)
    setPlayerHudComponentVisible("wanted", false)
end)

-- ============================================
-- UPDATE HUD CACHE (every 200ms instead of every frame)
-- ============================================
function updateHUDCache()
    local now = getTickCount()
    if (now - hudCache.lastUpdate) < (Config and Config.HUDUpdateInterval or 200) then return end
    hudCache.lastUpdate = now

    hudCache.charName = getElementData(localPlayer, "legends:charName") or ""
    hudCache.money = getElementData(localPlayer, "legends:money") or 0
    hudCache.moneyFormatted = "$" .. formatNumber(hudCache.money)
    hudCache.health = getElementHealth(localPlayer) or 100
    hudCache.armor = getPedArmor(localPlayer) or 0
    hudCache.job = getElementData(localPlayer, "legends:job") or "Desempleado"
    hudCache.factionId = getElementData(localPlayer, "legends:factionId") or 0
    hudCache.onDuty = getElementData(localPlayer, "legends:onDuty") or false
end

-- ============================================
-- DRAW HUD
-- ============================================
addEventHandler("onClientRender", root, function()
    if not hudEnabled then return end
    if hudCache.charName == "" then return end

    updateHUDCache()

    -- Background
    dxDrawRectangle(HUD.x, HUD.y, HUD.w, HUD.h, COLORS.bgBlack)
    dxDrawRectangle(HUD.x, HUD.y, HUD.w, 3, COLORS.accentBlue)

    -- Player name and ID
    local charId = getElementData(localPlayer, "legends:charId") or 0
    dxDrawText(hudCache.charName .. " [" .. charId .. "]", HUD.x + 10, HUD.y + 8, 0, 0, COLORS.white, 1.0, "default-bold")

    -- Money
    dxDrawText(hudCache.moneyFormatted, HUD.x + HUD.w - 10, HUD.y + 8, 0, 0, COLORS.moneyGreen, 1.0, "default-bold", "right")

    -- Job
    local jobText = hudCache.job
    if hudCache.factionId > 0 and Config.Factions[hudCache.factionId] then
        local factionData = Config.Factions[hudCache.factionId]
        jobText = factionData.shortName
        if hudCache.onDuty then
            jobText = jobText .. " [EN SERVICIO]"
        end
    end
    dxDrawText(jobText, HUD.x + 10, HUD.y + 30, 0, 0, COLORS.textGray, 0.9, "default")

    -- Time
    local hour, minute = getTime()
    dxDrawText(string.format("%02d:%02d", hour, minute), HUD.x + HUD.w - 10, HUD.y + 30, 0, 0, COLORS.timeWhite, 0.9, "default", "right")

    -- Health bar
    dxDrawText("HP", HUD.barX, HUD.barY - 2, 0, 0, COLORS.textGrayLight, 0.8, "default")
    dxDrawRectangle(HUD.barX + 25, HUD.barY, HUD.barW - 25, HUD.barH, COLORS.healthBg)
    local healthWidth = (HUD.barW - 25) * (hudCache.health / 100)
    local healthColor = COLORS.healthGreen
    if hudCache.health < 25 then
        healthColor = COLORS.healthRed
    elseif hudCache.health < 50 then
        healthColor = COLORS.healthYellow
    end
    dxDrawRectangle(HUD.barX + 25, HUD.barY, healthWidth, HUD.barH, healthColor)

    -- Armor bar
    if hudCache.armor > 0 then
        dxDrawText("AR", HUD.barX, HUD.barY + HUD.barH + 4, 0, 0, COLORS.textGrayLight, 0.8, "default")
        dxDrawRectangle(HUD.barX + 25, HUD.barY + HUD.barH + 5, HUD.barW - 25, HUD.barH, COLORS.armorBg)
        local armorWidth = (HUD.barW - 25) * (hudCache.armor / 100)
        dxDrawRectangle(HUD.barX + 25, HUD.barY + HUD.barH + 5, armorWidth, HUD.barH, COLORS.armorBlue)
    end

    -- Vehicle HUD
    local vehicle = getPedOccupiedVehicle(localPlayer)
    if vehicle then
        drawVehicleHUD(vehicle)
    end

    -- Notifications
    drawNotifications()
end)

-- ============================================
-- VEHICLE HUD
-- ============================================
function drawVehicleHUD(vehicle)
    local vehY = HUD.y + HUD.h + 10
    dxDrawRectangle(HUD.x, vehY, HUD.w, 65, COLORS.vehBg)
    dxDrawRectangle(HUD.x, vehY, HUD.w, 3, COLORS.vehAccent)

    -- Vehicle name
    local vehName = getVehicleName(vehicle) or "Vehiculo"
    dxDrawText(vehName, HUD.x + 10, vehY + 8, 0, 0, COLORS.vehWhite, 0.9, "default-bold")

    -- Speed
    local vx, vy, vz = getElementVelocity(vehicle)
    local speed = math.floor(math.sqrt(vx * vx + vy * vy + vz * vz) * 180)
    dxDrawText(speed .. " km/h", HUD.x + HUD.w - 10, vehY + 8, 0, 0, COLORS.vehAccent, 1.0, "default-bold", "right")

    -- Fuel bar
    local fuel = getElementData(vehicle, "legends:fuel") or 0
    dxDrawText("Fuel", HUD.x + 10, vehY + 32, 0, 0, COLORS.textGrayLight, 0.8, "default")
    dxDrawRectangle(HUD.x + 45, vehY + 33, HUD.w - 55, 10, COLORS.darkBg)
    local fuelWidth = (HUD.w - 55) * (fuel / (Config and Config.MaxFuel or 100))
    local fuelColor = fuel > 20 and COLORS.fuelYellow or COLORS.fuelRed
    dxDrawRectangle(HUD.x + 45, vehY + 33, fuelWidth, 10, fuelColor)

    -- Engine state
    local engineState = getVehicleEngineState(vehicle) and "ON" or "OFF"
    local engineColor = getVehicleEngineState(vehicle) and COLORS.moneyGreen or COLORS.healthRed
    dxDrawText("Motor: " .. engineState, HUD.x + 10, vehY + 47, 0, 0, engineColor, 0.8, "default")
end

-- ============================================
-- NOTIFICATION SYSTEM
-- ============================================
function drawNotifications()
    local now = getTickCount()
    local y = screenH - 100
    local maxNotifications = Config and Config.MaxNotifications or 5

    -- Remove expired notifications and limit queue
    local activeNotifications = {}
    for i = #notificationQueue, 1, -1 do
        local notif = notificationQueue[i]
        if (now - notif.time) > 5000 then
            table.remove(notificationQueue, i)
        else
            table.insert(activeNotifications, 1, notif)
        end
    end

    -- Limit to max notifications
    local startIdx = math.max(1, #activeNotifications - maxNotifications + 1)
    for i = startIdx, #activeNotifications do
        local notif = activeNotifications[i]
        local alpha = 255
        local elapsed = now - notif.time
        if elapsed > 4000 then
            alpha = math.floor(255 * (1 - (elapsed - 4000) / 1000))
        end

        local bgColor = tocolor(0, 0, 0, math.floor(alpha * 0.6))
        local textColor = tocolor(255, 255, 255, alpha)

        dxDrawRectangle(screenW / 2 - 200, y, 400, 25, bgColor)
        dxDrawText(notif.text, screenW / 2, y + 4, 0, 0, textColor, 0.9, "default", "center")
        y = y - 30
    end
end

addEvent("legends:notification", true)
addEventHandler("legends:notification", root, function(text)
    table.insert(notificationQueue, { text = text, time = getTickCount() })
end)

-- ============================================
-- TOGGLE HUD (F7)
-- ============================================
addEvent("legends:toggleHUD", true)
addEventHandler("legends:toggleHUD", root, function(state)
    if state ~= nil then
        hudEnabled = state
    else
        hudEnabled = not hudEnabled
    end
end)

bindKey("F7", "down", function()
    hudEnabled = not hudEnabled
    outputChatBox("[HUD] " .. (hudEnabled and "Activado" or "Desactivado"), 100, 200, 255)
end)

-- ============================================
-- FORMAT NUMBER UTILITY
-- ============================================
function formatNumber(n)
    local formatted = tostring(n)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1.%2")
        if k == 0 then break end
    end
    return formatted
end
