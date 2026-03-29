--[[
    Legends Roleplay - Housing System
    House purchase, management, and interior system
    v2.0.0
]]

local houseMarkers = {}

-- ============================================
-- CREATE DEFAULT HOUSES ON START
-- ============================================
addEventHandler("onResourceStart", resourceRoot, function()
    local db = getDatabase()
    if not db then return end

    -- Create default houses if they don't exist
    local existing = dbPoll(dbQuery(db, "SELECT COUNT(*) as count FROM houses"), -1)
    if existing and existing[1].count == 0 then
        for _, house in ipairs(Config.DefaultHouses) do
            dbExec(db, "INSERT INTO houses (name, price, x, y, z, interior) VALUES (?, ?, ?, ?, ?, ?)",
                house.name, house.price, house.x, house.y, house.z, house.interior)
        end
        outputDebugString("[Legends] Casas por defecto creadas: " .. #Config.DefaultHouses)
    end

    -- Load houses and create markers
    loadHouseMarkers()
end)

function loadHouseMarkers()
    -- Destroy existing markers
    for _, data in pairs(houseMarkers) do
        if isElement(data.marker) then destroyElement(data.marker) end
        if isElement(data.blip) then destroyElement(data.blip) end
    end
    houseMarkers = {}

    local db = getDatabase()
    local houses = dbPoll(dbQuery(db, "SELECT * FROM houses"), -1)

    for _, house in ipairs(houses) do
        local r, g, b = 0, 255, 0
        local text = house.name .. "\nPrecio: $" .. house.price .. "\n/comprarcasa"

        if house.owner_id > 0 then
            r, g, b = 255, 0, 0
            text = house.name .. "\n[Ocupada]"
            if house.for_sale == 1 then
                text = house.name .. "\nEn venta: $" .. house.price
            end
        end

        local marker = createMarker(house.x, house.y, house.z - 1, "cylinder", 1.5, r, g, b, 100)
        local blip = createBlipAttachedTo(marker, 31)
        setElementData(marker, "legends:3dtext", text)
        setElementData(marker, "legends:houseId", house.id)

        houseMarkers[house.id] = { marker = marker, blip = blip }
    end
end

-- ============================================
-- BUY HOUSE
-- ============================================
addCommandHandler("comprarcasa", function(player)
    if not isPlayerLoggedIn(player) then return end

    local db = getDatabase()
    local charId = getElementData(player, "legends:charId")
    local px, py, pz = getElementPosition(player)

    local houses = dbPoll(dbQuery(db, "SELECT * FROM houses WHERE owner_id = 0 OR for_sale = 1"), -1)

    for _, house in ipairs(houses) do
        if getDistanceBetweenPoints3D(px, py, pz, house.x, house.y, house.z) <= 3 then
            local money = getPlayerMoney(player)
            if money < house.price then
                outputChatBox("[Casas] No tienes suficiente dinero ($" .. house.price .. ")", player, 255, 50, 50)
                return
            end

            -- Check if player already owns too many houses
            local owned = dbPoll(dbQuery(db, "SELECT COUNT(*) as count FROM houses WHERE owner_id = ?", charId), -1)
            if owned and owned[1].count >= 3 then
                outputChatBox("[Casas] Ya tienes el maximo de casas (3)", player, 255, 50, 50)
                return
            end

            -- If house has previous owner, give them money
            if house.owner_id > 0 then
                local prevOwner = dbPoll(dbQuery(db, "SELECT * FROM characters WHERE id = ?", house.owner_id), -1)
                if #prevOwner > 0 then
                    dbExec(db, "UPDATE characters SET bank = bank + ? WHERE id = ?", house.price, house.owner_id)
                end
            end

            takePlayerMoney(player, house.price)
            dbExec(db, "UPDATE houses SET owner_id = ?, for_sale = 0 WHERE id = ?", charId, house.id)

            invalidateCache("houses")
            loadHouseMarkers()

            outputChatBox("[Casas] Compraste '" .. house.name .. "' por $" .. house.price, player, 100, 220, 100)
            return
        end
    end

    outputChatBox("[Casas] No hay casas en venta cerca", player, 255, 50, 50)
end)

-- ============================================
-- MY HOUSES
-- ============================================
addCommandHandler("miscasas", function(player)
    if not isPlayerLoggedIn(player) then return end

    local db = getDatabase()
    local charId = getElementData(player, "legends:charId")
    local houses = cachedQuery("SELECT * FROM houses WHERE owner_id = ?", charId)

    if #houses == 0 then
        outputChatBox("[Casas] No tienes casas", player, 255, 200, 0)
        return
    end

    outputChatBox("=== Tus Casas ===", player, 100, 200, 255)
    for _, house in ipairs(houses) do
        local status = house.for_sale == 1 and " [En venta]" or ""
        outputChatBox("ID: " .. house.id .. " | " .. house.name .. status, player, 255, 255, 255)
    end
end)

-- ============================================
-- SELL HOUSE
-- ============================================
addCommandHandler("vendercasa", function(player, cmd, houseIdStr)
    if not isPlayerLoggedIn(player) then return end

    local houseId = tonumber(houseIdStr)
    if not houseId then
        outputChatBox("[Uso] /vendercasa [id de casa]", player, 255, 200, 0)
        return
    end

    local db = getDatabase()
    local charId = getElementData(player, "legends:charId")
    local result = dbPoll(dbQuery(db, "SELECT * FROM houses WHERE id = ? AND owner_id = ?", houseId, charId), -1)

    if #result == 0 then
        outputChatBox("[Casas] No eres el dueño de esa casa", player, 255, 50, 50)
        return
    end

    local house = result[1]
    dbExec(db, "UPDATE houses SET for_sale = 1 WHERE id = ?", houseId)

    invalidateCache("houses")
    loadHouseMarkers()

    outputChatBox("[Casas] Casa '" .. house.name .. "' puesta en venta por $" .. house.price, player, 100, 220, 100)
end)

-- ============================================
-- ENTER/EXIT HOUSE
-- ============================================
addCommandHandler("entrarcasa", function(player)
    if not isPlayerLoggedIn(player) then return end

    local px, py, pz = getElementPosition(player)
    local db = getDatabase()
    local charId = getElementData(player, "legends:charId")

    local houses = dbPoll(dbQuery(db, "SELECT * FROM houses WHERE owner_id = ?", charId), -1)

    for _, house in ipairs(houses) do
        if getDistanceBetweenPoints3D(px, py, pz, house.x, house.y, house.z) <= 3 then
            setElementInterior(player, house.interior)
            setElementPosition(player, 2527.0, -1679.0, 1015.5)
            setElementDimension(player, house.id)
            outputChatBox("[Casas] Entraste a " .. house.name, player, 100, 200, 255)
            return
        end
    end

    outputChatBox("[Casas] No estas cerca de ninguna de tus casas", player, 255, 50, 50)
end)

addCommandHandler("salircasa", function(player)
    local dimension = getElementDimension(player)
    if dimension == 0 then
        outputChatBox("[Casas] No estas dentro de una casa", player, 255, 50, 50)
        return
    end

    local db = getDatabase()
    local house = dbPoll(dbQuery(db, "SELECT * FROM houses WHERE id = ?", dimension), -1)

    if #house > 0 then
        setElementInterior(player, 0)
        setElementPosition(player, house[1].x, house[1].y, house[1].z)
        setElementDimension(player, 0)
        outputChatBox("[Casas] Saliste de " .. house[1].name, player, 100, 200, 255)
    end
end)
