--[[
    Legends Roleplay - Login/Register GUI
    Client-side authentication interface
    v2.0.0
]]

local screenW, screenH = guiGetScreenSize()
local loginWindow = nil
local charSelectWindow = nil
local isLoggedIn = false

-- ============================================
-- SHOW LOGIN SCREEN
-- ============================================
addEvent("legends:showLogin", true)
addEventHandler("legends:showLogin", root, function()
    if loginWindow and isElement(loginWindow) then
        destroyElement(loginWindow)
    end

    showCursor(true)
    showChat(false)

    local w, h = 400, 350
    local x, y = (screenW - w) / 2, (screenH - h) / 2

    loginWindow = guiCreateWindow(x, y, w, h, "LEGENDS ROLEPLAY - Login", false)
    guiWindowSetSizable(loginWindow, false)

    guiCreateLabel(20, 30, 360, 20, "Bienvenido a Legends Roleplay v" .. (Config and Config.ServerVersion or "2.0.0"), false, loginWindow)

    guiCreateLabel(20, 70, 100, 20, "Usuario:", false, loginWindow)
    local usernameEdit = guiCreateEdit(20, 90, 360, 30, "", false, loginWindow)
    guiEditSetMaxLength(usernameEdit, 20)

    guiCreateLabel(20, 130, 100, 20, "Contraseña:", false, loginWindow)
    local passwordEdit = guiCreateEdit(20, 150, 360, 30, "", false, loginWindow)
    guiEditSetMasked(passwordEdit, true)
    guiEditSetMaxLength(passwordEdit, 30)

    local loginBtn = guiCreateButton(20, 200, 170, 40, "Iniciar Sesion", false, loginWindow)
    local registerBtn = guiCreateButton(210, 200, 170, 40, "Registrarse", false, loginWindow)

    local statusLabel = guiCreateLabel(20, 260, 360, 60, "", false, loginWindow)
    guiLabelSetColor(statusLabel, 255, 200, 100)

    -- Login button click
    addEventHandler("onClientGUIClick", loginBtn, function()
        local username = guiGetText(usernameEdit)
        local password = guiGetText(passwordEdit)

        if username == "" or password == "" then
            guiSetText(statusLabel, "Completa todos los campos")
            return
        end

        guiSetText(statusLabel, "Iniciando sesion...")
        triggerServerEvent("legends:login", localPlayer, username, password)
    end, false)

    -- Register button click
    addEventHandler("onClientGUIClick", registerBtn, function()
        local username = guiGetText(usernameEdit)
        local password = guiGetText(passwordEdit)

        if username == "" or password == "" then
            guiSetText(statusLabel, "Completa todos los campos")
            return
        end

        if #username < 3 then
            guiSetText(statusLabel, "Usuario debe tener al menos 3 caracteres")
            return
        end

        if #password < 6 then
            guiSetText(statusLabel, "Contraseña debe tener al menos 6 caracteres")
            return
        end

        guiSetText(statusLabel, "Registrando cuenta...")
        triggerServerEvent("legends:register", localPlayer, username, password)
    end, false)

    -- Store status label for updates
    setElementData(loginWindow, "statusLabel", statusLabel, false)
end)

-- ============================================
-- AUTH RESPONSE
-- ============================================
addEvent("legends:authResponse", true)
addEventHandler("legends:authResponse", root, function(success, message)
    if loginWindow and isElement(loginWindow) then
        local statusLabel = getElementData(loginWindow, "statusLabel")
        if statusLabel and isElement(statusLabel) then
            guiSetText(statusLabel, message or "")
            if success then
                guiLabelSetColor(statusLabel, 100, 220, 100)
            else
                guiLabelSetColor(statusLabel, 255, 50, 50)
            end
        end
    end

    if charSelectWindow and isElement(charSelectWindow) then
        -- Update char select status
    end
end)

-- ============================================
-- CHARACTER SELECTION SCREEN
-- ============================================
addEvent("legends:showCharacterSelection", true)
addEventHandler("legends:showCharacterSelection", root, function(characters)
    -- Close login window
    if loginWindow and isElement(loginWindow) then
        destroyElement(loginWindow)
        loginWindow = nil
    end

    if charSelectWindow and isElement(charSelectWindow) then
        destroyElement(charSelectWindow)
    end

    showCursor(true)
    showChat(false)

    local w, h = 500, 450
    local x, y = (screenW - w) / 2, (screenH - h) / 2

    charSelectWindow = guiCreateWindow(x, y, w, h, "LEGENDS ROLEPLAY - Personajes", false)
    guiWindowSetSizable(charSelectWindow, false)

    -- Character list
    local gridList = guiCreateGridList(20, 30, 460, 200, false, charSelectWindow)
    guiGridListAddColumn(gridList, "Nombre", 0.35)
    guiGridListAddColumn(gridList, "Dinero", 0.2)
    guiGridListAddColumn(gridList, "Trabajo", 0.2)
    guiGridListAddColumn(gridList, "Faccion", 0.2)

    local charIds = {}
    for _, char in ipairs(characters or {}) do
        local row = guiGridListAddRow(gridList)
        guiGridListSetItemText(gridList, row, 1, char.name, false, false)
        guiGridListSetItemText(gridList, row, 2, "$" .. (char.money or 0), false, false)
        guiGridListSetItemText(gridList, row, 3, char.job or "Desempleado", false, false)

        local factionName = "Ninguna"
        if char.faction_id and char.faction_id > 0 and Config.Factions[char.faction_id] then
            factionName = Config.Factions[char.faction_id].shortName
        end
        guiGridListSetItemText(gridList, row, 4, factionName, false, false)

        charIds[row] = char.id
    end

    -- Select character button
    local selectBtn = guiCreateButton(20, 240, 220, 40, "Seleccionar Personaje", false, charSelectWindow)

    addEventHandler("onClientGUIClick", selectBtn, function()
        local row = guiGridListGetSelectedItem(gridList)
        if row == -1 then
            outputChatBox("Selecciona un personaje de la lista", 255, 50, 50)
            return
        end

        local charId = charIds[row]
        if charId then
            triggerServerEvent("legends:selectCharacter", localPlayer, charId)
        end
    end, false)

    -- Create character section
    guiCreateLabel(20, 300, 460, 20, "--- Crear Nuevo Personaje ---", false, charSelectWindow)

    guiCreateLabel(20, 325, 100, 20, "Nombre:", false, charSelectWindow)
    local nameEdit = guiCreateEdit(120, 322, 200, 28, "", false, charSelectWindow)
    guiEditSetMaxLength(nameEdit, 30)

    guiCreateLabel(330, 325, 50, 20, "Skin:", false, charSelectWindow)
    local skinEdit = guiCreateEdit(380, 322, 100, 28, "1", false, charSelectWindow)
    guiEditSetMaxLength(skinEdit, 3)

    local createBtn = guiCreateButton(20, 365, 460, 40, "Crear Personaje (" .. #(characters or {}) .. "/" .. (Config and Config.MaxCharacters or 3) .. ")", false, charSelectWindow)

    if #(characters or {}) >= (Config and Config.MaxCharacters or 3) then
        guiSetEnabled(createBtn, false)
    end

    addEventHandler("onClientGUIClick", createBtn, function()
        local name = guiGetText(nameEdit)
        local skin = tonumber(guiGetText(skinEdit)) or 1

        if name == "" or #name < 3 then
            outputChatBox("El nombre debe tener al menos 3 caracteres", 255, 50, 50)
            return
        end

        triggerServerEvent("legends:createCharacter", localPlayer, name, skin)
    end, false)
end)

-- ============================================
-- HIDE LOGIN (after character selection)
-- ============================================
addEvent("legends:hideLogin", true)
addEventHandler("legends:hideLogin", root, function()
    if loginWindow and isElement(loginWindow) then
        destroyElement(loginWindow)
        loginWindow = nil
    end
    if charSelectWindow and isElement(charSelectWindow) then
        destroyElement(charSelectWindow)
        charSelectWindow = nil
    end

    showCursor(false)
    showChat(true)
    isLoggedIn = true
end)
