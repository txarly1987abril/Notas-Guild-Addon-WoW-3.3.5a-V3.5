local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

-- Clave única por guild y reino
local function GetGuildKey()
    if not IsInGuild() then return "NO_GUILD" end
    local guildName, _, _, realm = GetGuildInfo("player")
    realm = realm or GetRealmName()
    return (guildName or "NO_GUILD") .. "-" .. (realm or "NO_REALM")
end


local function IsPlayerGuildMaster()
    GuildRoster()
    local _, rankName, rankIndex = GetGuildInfo("player")
    return rankIndex == 0 -- 0 es el Guild Master en WoW
end




local guildKey = GetGuildKey()
if type(NotasDB_Global) ~= "table" then NotasDB_Global = {} end
if type(NotasDB_Global[guildKey]) ~= "table" then NotasDB_Global[guildKey] = {} end
if type(NotasDB_Global[guildKey]["OFICIALES"]) == "table" then
    NotasAddon_OfficerRanks = NotasDB_Global[guildKey]["OFICIALES"]
else
    NotasAddon_OfficerRanks = {
        ["guild master"] = true,
        ["oficial"] = true,
    }
end


local function GuardarOfficerRanks()
    if type(NotasDB_Global) ~= "table" then NotasDB_Global = {} end
    local guildKey = GetGuildKey()
    if type(NotasDB_Global[guildKey]) ~= "table" then NotasDB_Global[guildKey] = {} end
    NotasDB_Global[guildKey]["OFICIALES"] = NotasAddon_OfficerRanks
end



local function HandleOfficerRanksCommand(msg)
    if not IsPlayerGuildMaster() then
        print("|cffff0000[Notas]|r Solo el Guild Master puede ver o modificar los rangos de oficiales.")
        return
    end
    msg = msg and trim(msg) or ""
    if msg == "" or msg == "ayuda" or msg == "help" then
        print("|cff00ff00Rangos de oficiales actuales:|r")
        for rank, enabled in pairs(NotasAddon_OfficerRanks) do
            if enabled then print("- "..rank) end
        end
        print("|cffFFD700/notas rangos agregar <nombre_rango>|r - Agrega un rango de oficial (en minúsculas)")
        print("|cffFFD700/notas rangos eliminar <nombre_rango>|r - Elimina un rango de oficial")
        print("|cffFFD700/notas rangos|r - Muestra los rangos actuales")
        return
    end
    local action, rest = msg:match("^(%S+)%s*(.*)$")
    if action == "agregar" and rest ~= "" then
        local rank = trim(rest):lower()
        NotasAddon_OfficerRanks[rank] = true
        GuardarOfficerRanks()
        local serialized = "OFICIALES_SYNC|"
        for r, enabled in pairs(NotasAddon_OfficerRanks) do
            if enabled then
                serialized = serialized .. r .. ","
            end
        end
        SendAddonMessage("Notas-guild-addon", serialized, "GUILD")
        print("|cff00ff00[Notas]|r Rango agregado: "..rank)
    elseif (action == "eliminar" or action == "delete" or action == "remove") and rest ~= "" then
        local rank = trim(rest):lower()
        if NotasAddon_OfficerRanks[rank] then
            NotasAddon_OfficerRanks[rank] = nil
            GuardarOfficerRanks()
            local serialized = "OFICIALES_SYNC|"
            for r, enabled in pairs(NotasAddon_OfficerRanks) do
                if enabled then
                    serialized = serialized .. r .. ","
                end
            end
            SendAddonMessage("Notas-guild-addon", serialized, "GUILD")
            print("|cff00ff00[Notas]|r Rango eliminado: "..rank)
        else
            print("|cffff0000[Notas]|r Ese rango no está en la lista.")
        end
    else
        print("|cffff0000[Notas]|r Uso incorrecto. Escribe /notas rangos ayuda para ver opciones.")
    end
end


if type(NotasDB_Global) ~= "table" then NotasDB_Global = {} end
local ADDON_VERSION = "3.5"
local ADDON_NAME = "Notas-guild-addon"
local function SaveAddonHeader()
    local guildKey = GetGuildKey()
    if type(NotasAddon_VisibleName) == "string" and NotasAddon_VisibleName ~= "" then
        if type(NotasDB_Global[guildKey]) ~= "table" then NotasDB_Global[guildKey] = {} end
        NotasDB_Global[guildKey]["ENCABEZADO"] = NotasAddon_VisibleName
    end
end
local automsg_enabled = false
local automsg_message = "Mensaje automático de la guild."
local automsg_interval = 300
local automsg_elapsed = 0
local automsgFrame = CreateFrame("Frame")
automsgFrame:SetScript("OnUpdate", function(self, elapsed)
    if automsg_enabled and IsInGuild() then
        automsg_elapsed = automsg_elapsed + elapsed
        if automsg_elapsed >= automsg_interval then
            automsg_elapsed = 0
            if automsg_message and automsg_message ~= "" then
                SendChatMessage(automsg_message, "GUILD")
            end
        end
    end
end)

local function IsPlayerGuildMaster()
    GuildRoster()
    local _, rankName, rankIndex = GetGuildInfo("player")
    return rankIndex == 0
end

local function HandleAutomsgCommand(msg)
    msg = msg and trim(msg) or ""
    if msg == "" or msg == "ayuda" or msg == "help" then
        print("|cff00ff00Automsg ayuda:|r")
        print("|cffFFD700/notas automsg <mensaje>|r - Configura el mensaje automático de la guild")
        print("|cffFFD700/notas automsg intervalo <segundos>|r - Cambia la frecuencia (mínimo 30)")
        print("|cffFFD700/notas automsg iniciar|r - Activa el automensaje")
        print("|cffFFD700/notas automsg parar|r - Desactiva el automensaje")
        return
    end
    local cmd, rest = msg:match("^(%S+)%s*(.*)$")
    if not cmd then cmd = msg end
    cmd = cmd:lower()
    if cmd == "intervalo" then
        local segs = tonumber(rest)
        if segs and segs >= 30 then
            automsg_interval = segs
            print("|cff00ff00[Automsg]|r Intervalo cambiado a " .. segs .. " segundos.")
        else
            print("|cffff0000[Automsg]|r Debes poner un número mayor o igual a 30.")
        end
    elseif cmd == "iniciar" then
        automsg_enabled = true
        automsg_elapsed = 0
        print("|cff00ff00[Automsg]|r Automensaje activado.")
    elseif cmd == "parar" then
        automsg_enabled = false
        print("|cffFFD700[Automsg]|r Automensaje desactivado.")
    else
        automsg_message = msg
        print("|cff00ff00[Automsg]|r Mensaje cambiado: " .. automsg_message)
    end
end

ShowMinimapButton = true
local currentGuildPage = 1
local MAX_GUILD_PAGES = 20
local playerName = UnitName("player")
local realmName = GetRealmName()
local function GetFullPlayerName(name)
    return name .. "-" .. realmName
end
local myFullName = GetFullPlayerName(playerName)
local MAX_PART_SIZE = 240
local currentTarget = myFullName
local AUTOSAVE_INTERVAL = 60
local elapsedSinceSave = 0
local lastSavedLength = 0
local function trim(s)
    return s:match("^%s*(.-)%s*$")
end
local isUserEditing = false
local lastEditTime = 0
local function IsPlayerOfficer()
    if IsPlayerGuildMaster() then return true end
    GuildRoster()
    local _, rankName = GetGuildInfo("player")
    if not rankName then return false end
    local normalizedRank = trim(rankName):lower()
    for savedRank, enabled in pairs(NotasAddon_OfficerRanks) do
        if enabled and normalizedRank == trim(savedRank):lower() then
            return true
        end
    end
    return false
end
local f = CreateFrame("Frame", "NotasFrame", UIParent)
local MAX_ADDON_MSG_SIZE = 240
table.insert(UISpecialFrames, "NotasFrame")
f:SetSize(600, 450)
f:SetPoint("CENTER")
f:SetFrameStrata("DIALOG")
f:Hide()
f:SetBackdropColor(0, 0, 0, 0.95)
f:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
})
local lastSendTime = {}
local SEND_THROTTLE = 2 

local function SendLongNote(note, isGuild, page, onlineOnly)
    if not IsInGuild() then return end
    local key = isGuild and ("GUILD" .. (page or 1)) or myFullName
    local now = GetTime()
    if lastSendTime[key] and (now - lastSendTime[key]) < SEND_THROTTLE then
        return 
    end
    lastSendTime[key] = now
    if not note or trim(note) == "" then return end
    page = page or 1
    local prefix
    if isGuild then
        prefix = "GUILD|"..page.."|1|1|"
    else
        prefix = myFullName.."|1|1|"
    end
    local maxPartSize = MAX_ADDON_MSG_SIZE - #prefix
    local total = math.ceil(#note / maxPartSize)
    for i = 1, total do
        local part = note:sub((i-1)*maxPartSize+1, i*maxPartSize)
        local msg
        if isGuild then
            msg = "GUILD|"..page.."|"..i.."|"..total.."|"..part
        else
            msg = myFullName.."|"..i.."|"..total.."|"..part
        end
        SendAddonMessage("Notas-guild-addon", msg, "GUILD")
    end
end

local function SendLongNoteForPlayer(note, playerFullName, skipThrottle)
    if not IsInGuild() then return end    
    if playerFullName ~= myFullName and not IsPlayerOfficer() then
        print("|cffff0000[" .. ADDON_NAME .. "]|r Solo los oficiales pueden sincronizar notas de otros jugadores.")
        return
    end
    if not skipThrottle then
        local key = playerFullName
        local now = GetTime()
        if lastSendTime[key] and (now - lastSendTime[key]) < SEND_THROTTLE then
            return
        end
        lastSendTime[key] = now
    end
    if not note or trim(note) == "" then return end
    local prefix = playerFullName.."|1|1|"
    local maxPartSize = MAX_ADDON_MSG_SIZE - #prefix
    local total = math.ceil(#note / maxPartSize)
    for i = 1, total do
        local part = note:sub((i-1)*maxPartSize+1, i*maxPartSize)
        local msg = playerFullName.."|"..i.."|"..total.."|"..part
        SendAddonMessage("Notas-guild-addon", msg, "GUILD")
    end
end

local scroll = CreateFrame("ScrollFrame", "NotasScrollFrame", f, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 20, -30)
scroll:SetPoint("BOTTOMRIGHT", -30, 80)
local editBox = CreateFrame("EditBox", "NotasEditBox", scroll)
editBox:SetMultiLine(true)
editBox:SetWidth(540)
editBox:SetHeight(320) 
editBox:SetFontObject(ChatFontNormal)
editBox:SetAutoFocus(false)
editBox:EnableMouse(true)
local function GetOnlineGuildMembers()
    if not IsInGuild() then return {} end    
    GuildRoster() 
    local onlineMembers = {}
    local numTotalMembers = GetNumGuildMembers()    
    for i = 1, numTotalMembers do
        local name, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName = GetGuildRosterInfo(i)
        if name and online then
            table.insert(onlineMembers, name)
        end
    end    
    return onlineMembers
end

local function UpdateCharCounter()
    if not editBox then return end
    local text = editBox:GetText()
    local length = #text
    local charCounter = _G["NotasCharCounter"]
    if charCounter then
        charCounter:SetText(length .. " / 50000 caracteres")
        if length > 45000 then
            charCounter:SetTextColor(1, 0, 0)
        elseif length > 35000 then
            charCounter:SetTextColor(1, 1, 0)
        else
            charCounter:SetTextColor(0.7, 0.7, 0.7)
        end
    end
end

local function UpdateStatusLabel()
    local statusLabel = _G["NotasStatusLabel"]
    if not statusLabel then return end    
    local syncAllButton = _G["NotasSyncAllButton"] or syncAllButton    
    if isUserEditing then
        statusLabel:SetText("Editando...")
        statusLabel:SetTextColor(1, 1, 0)
    elseif currentTarget == myFullName then
        statusLabel:SetText("Tu nota")
        statusLabel:SetTextColor(0, 1, 0)
    elseif currentTarget == "GUILD" then
        if IsPlayerGuildMaster() then
            statusLabel:SetText("Nota guild (Editor)")
            statusLabel:SetTextColor(0, 0.8, 1)
            if syncAllButton then syncAllButton:Show() end
        else
            statusLabel:SetText("Nota guild (Solo lectura)")
            statusLabel:SetTextColor(0.7, 0.7, 0.7)
            if syncAllButton then syncAllButton:Hide() end
        end
    elseif currentTarget == "OFICIALES" then
        if IsPlayerOfficer() then
            statusLabel:SetText("Nota oficiales (Editor)")
            statusLabel:SetTextColor(0.5, 0.9, 0.2)
        else
            statusLabel:SetText("Nota oficiales (No permitido)")
            statusLabel:SetTextColor(0.7, 0.7, 0.7)
        end
    else
        local displayName = currentTarget:gsub("%-"..realmName, "")
        statusLabel:SetText("Nota de " .. displayName .. " (Solo lectura)")
        statusLabel:SetTextColor(1, 0.5, 0)
    end   
    if currentTarget ~= "GUILD" or not IsPlayerGuildMaster() then
        if syncAllButton then syncAllButton:Hide() end
    end
end

editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
editBox:SetScript("OnTextChanged", function(self)
    isUserEditing = true
    lastEditTime = GetTime()
    UpdateStatusLabel()
    UpdateCharCounter()
    local cursorPosition = self:GetCursorPosition()
    local text = self:GetText()
    local linesBeforeCursor = 0
    for i = 1, cursorPosition do
        if text:sub(i, i) == "\n" then
            linesBeforeCursor = linesBeforeCursor + 1
        end
    end
    local lineHeight = 14
    local visibleHeight = scroll:GetHeight()
    local visibleLines = math.floor(visibleHeight / lineHeight)
    local scrollValue = scroll:GetVerticalScroll()
    local scrolledLines = math.floor(scrollValue / lineHeight)
    if linesBeforeCursor >= (scrolledLines + visibleLines - 2) then
        local newScrollValue = (linesBeforeCursor - visibleLines + 3) * lineHeight
        scroll:SetVerticalScroll(math.max(0, newScrollValue))
    end
    if linesBeforeCursor < scrolledLines then
        local newScrollValue = linesBeforeCursor * lineHeight
        scroll:SetVerticalScroll(math.max(0, newScrollValue))
    end
end)
editBox:SetScript("OnEditFocusGained", function(self)
    self:HighlightText()
end)
editBox:SetScript("OnTabPressed", function(self)
    self:Insert("    ")
end)
editBox:SetScript("OnEnterPressed", function(self)
    self:Insert("\n")
    local cursorPosition = self:GetCursorPosition()
    local text = self:GetText()
    local linesBeforeCursor = 0
    for i = 1, cursorPosition do
        if text:sub(i, i) == "\n" then
            linesBeforeCursor = linesBeforeCursor + 1
        end
    end
    local lineHeight = 14
    local visibleHeight = scroll:GetHeight()
    local visibleLines = math.floor(visibleHeight / lineHeight)
    local scrollValue = scroll:GetVerticalScroll()
    local scrolledLines = math.floor(scrollValue / lineHeight)    
    if linesBeforeCursor >= (scrolledLines + visibleLines - 2) then
        local newScrollValue = (linesBeforeCursor - visibleLines + 3) * lineHeight
        scroll:SetVerticalScroll(math.max(0, newScrollValue))
    end
end)

editBox:SetScript("OnCursorChanged", function(self)
    if not self:HasFocus() then return end    
    local cursorPosition = self:GetCursorPosition()
    local text = self:GetText()   
    local linesBeforeCursor = 0
    for i = 1, cursorPosition do
        if text:sub(i, i) == "\n" then
            linesBeforeCursor = linesBeforeCursor + 1
        end
    end
    local lineHeight = 14
    local visibleHeight = scroll:GetHeight()
    local visibleLines = math.floor(visibleHeight / lineHeight)
    local scrollValue = scroll:GetVerticalScroll()
    local scrolledLines = math.floor(scrollValue / lineHeight)
    if linesBeforeCursor >= (scrolledLines + visibleLines - 1) then
        local newScrollValue = (linesBeforeCursor - visibleLines + 2) * lineHeight
        scroll:SetVerticalScroll(math.max(0, newScrollValue))
    end
    if linesBeforeCursor < scrolledLines then
        local newScrollValue = linesBeforeCursor * lineHeight
        scroll:SetVerticalScroll(math.max(0, newScrollValue))
    end
end)
editBox:ClearAllPoints()
editBox:SetPoint("TOPLEFT", scroll)
editBox:SetPoint("RIGHT", scroll)
editBox:SetPoint("BOTTOM", scroll)
editBox:SetMaxLetters(50000)
editBox:SetTextInsets(4, 4, 4, 4)
local function EnsureMinimumHeight()
    local minHeight = 320
    if editBox:GetHeight() < minHeight then
        editBox:SetHeight(minHeight)
    end
end

EnsureMinimumHeight()
scroll:SetScrollChild(editBox)
local autosaveFrame = CreateFrame("Frame")
autosaveFrame:SetScript("OnUpdate", function(self, elapsed)
    elapsedSinceSave = elapsedSinceSave + elapsed
    if elapsedSinceSave >= AUTOSAVE_INTERVAL and not isUserEditing then
        elapsedSinceSave = 0
        local text = editBox:GetText()
    if (currentTarget == myFullName or currentTarget == "GUILD" or currentTarget == "OFICIALES") then
        if #text ~= lastSavedLength then
            local guildKey = GetGuildKey()
            if type(NotasDB_Global[guildKey]) ~= "table" then NotasDB_Global[guildKey] = {} end
            if currentTarget == "GUILD" then
                if not IsPlayerGuildMaster() then return end
                SaveAddonHeader()
                if type(NotasDB_Global[guildKey]["GUILD"]) ~= "table" then NotasDB_Global[guildKey]["GUILD"] = {} end
                NotasDB_Global[guildKey]["GUILD"][currentGuildPage] = text
                SendLongNote(text, true, currentGuildPage, false)
            elseif currentTarget == "OFICIALES" then
                if IsPlayerOfficer() then
                    NotasDB_Global[guildKey]["OFICIALES"] = text
                    SendAddonMessage("Notas-guild-addon", "OFICIALES|"..text, "GUILD")
                end
            else
                NotasDB_Global[guildKey][currentTarget] = text
                if currentTarget == myFullName or IsPlayerOfficer() then
                    SendLongNote(text, false, nil, false)
                end
            end
            lastSavedLength = #text
        end
    end
    end
    if isUserEditing and (GetTime() - lastEditTime) > 3 then
        isUserEditing = false
        UpdateStatusLabel()
    end
end)

local saveButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
saveButton:SetSize(80, 22)
saveButton:SetPoint("BOTTOMLEFT", 20, 10)
saveButton:SetText("Guardar")
saveButton:SetScript("OnClick", function()
    local text = editBox:GetText()
    if IsPlayerGuildMaster() and NotasAddon_VisibleName and trim(NotasAddon_VisibleName) ~= "" then
    SaveAddonHeader()
    local setNameMsg = "SET_ADDON_NAME|" .. NotasAddon_VisibleName
    SendAddonMessage("Notas-guild-addon", setNameMsg, "GUILD")
    print("|cff00ff00[" .. ADDON_NAME .. "]|r Encabezado enviado a la guild.")
    end    
    saveButton:SetText("Guardando...")
    saveButton:Disable()    
    local guildKey = GetGuildKey()
    if type(NotasDB_Global[guildKey]) ~= "table" then NotasDB_Global[guildKey] = {} end
    if currentTarget == "GUILD" then
        if not IsPlayerGuildMaster() then
            print("|cffff0000[" .. ADDON_NAME .. "]|r Solo el Guild Master puede editar la nota de guild.")
            saveButton:SetText("Guardar")
            saveButton:Enable()
            return
        end
        if type(NotasDB_Global[guildKey]["GUILD"]) ~= "table" then NotasDB_Global[guildKey]["GUILD"] = {} end
        NotasDB_Global[guildKey]["GUILD"][currentGuildPage] = text
        SaveAddonHeader()
        SendLongNote(text, true, currentGuildPage, false)
        if IsPlayerGuildMaster() and NotasAddon_VisibleName and trim(NotasAddon_VisibleName) ~= "" then
            local setNameMsg = "SET_ADDON_NAME|" .. NotasAddon_VisibleName
            SendAddonMessage("Notas-guild-addon", setNameMsg, "GUILD")
            print("|cff00ff00[" .. ADDON_NAME .. "]|r Encabezado enviado a la guild.")
        end
    elseif currentTarget == "OFICIALES" then
        if IsPlayerOfficer() then
            NotasDB_Global[guildKey]["OFICIALES"] = text
            SendAddonMessage("Notas-guild-addon", "OFICIALES|"..text, "GUILD")
            print("|cff00ff00[" .. ADDON_NAME .. "]|r Nota de oficiales guardada y enviada a los oficiales.")
        else
            print("|cffff0000[" .. ADDON_NAME .. "]|r Solo los oficiales pueden editar esta nota.")
        end
    else
        NotasDB_Global[guildKey][currentTarget] = text
        if currentTarget == myFullName or IsPlayerOfficer() then
            SendLongNote(text, false, nil, false)
            print("|cff00ff00[" .. ADDON_NAME .. "]|r Nota guardada y enviada a la guild.")
        else
            print("|cff00ff00[" .. ADDON_NAME .. "]|r Nota guardada localmente.")
        end
    end
    lastSavedLength = #text
    isUserEditing = false
    UpdateStatusLabel()
    local restoreFrame = CreateFrame("Frame")
    local elapsed = 0
    restoreFrame:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta
        if elapsed >= 1 then
            saveButton:SetText("Guardar")
            saveButton:Enable()
            self:SetScript("OnUpdate", nil)
        end
    end)
end)


local clearButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
clearButton:SetSize(60, 22)
clearButton:SetPoint("LEFT", saveButton, "RIGHT", 5, 0)
clearButton:SetText("Limpiar")
clearButton:SetScript("OnClick", function()
    if currentTarget == myFullName 
        or (currentTarget == "GUILD" and IsPlayerOfficer())
        or (currentTarget == "OFICIALES" and IsPlayerOfficer()) then
        StaticPopup_Show("NOTAS_CONFIRM_CLEAR")
    else
        print("|cffff0000[" .. ADDON_NAME .. "]|r No puedes limpiar esta nota.")
    end
end)

StaticPopupDialogs["NOTAS_CONFIRM_CLEAR"] = {
    text = "¿Estás seguro de que quieres limpiar esta nota?\n\n|cffff0000Esta acción no se puede deshacer.|r",
    button1 = "Sí, limpiar",
    button2 = "Cancelar",
    OnAccept = function()
        editBox:SetText("")
        editBox:SetFocus()
        isUserEditing = true
        lastEditTime = GetTime()
        UpdateStatusLabel()
        UpdateCharCounter()
        print("|cff00ff00[" .. ADDON_NAME .. "]|r Nota limpiada.")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local closeButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
closeButton:SetSize(80, 22)
closeButton:SetPoint("BOTTOMRIGHT", -20, 10)
closeButton:SetText("Cerrar")
closeButton:SetScript("OnClick", function() f:Hide() end)
local charCounter = f:CreateFontString("NotasCharCounter", "OVERLAY", "GameFontNormalSmall")
charCounter:SetPoint("BOTTOM", f, "BOTTOM", 0, 52)
charCounter:SetText("0 / 50000 caracteres")
charCounter:SetTextColor(0.7, 0.7, 0.7)
local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -10)
title:SetText(NotasAddon_VisibleName)
local function UpdateAddonTitle()
    if title and NotasAddon_VisibleName then
        title:SetText(NotasAddon_VisibleName)
    end
end

local statusLabel = f:CreateFontString("NotasStatusLabel", "OVERLAY", "GameFontNormal")
statusLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -10)
statusLabel:SetText("")
statusLabel:SetTextColor(0.7, 0.7, 0.7)

local dropdown = CreateFrame("Frame", "NotasDropdown", f, "UIDropDownMenuTemplate")
dropdown:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -5)
dropdown:SetWidth(180)

local pageLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
pageLabel:SetText("Página 1/" .. MAX_GUILD_PAGES)

local prevPage = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
prevPage:SetSize(30, 22)
prevPage:SetText("<")
prevPage:SetScript("OnClick", function()
    if currentTarget == "GUILD" and currentGuildPage > 1 then
        SaveAddonHeader()
        currentGuildPage = currentGuildPage - 1
        isUserEditing = false
        local guildKey = GetGuildKey()
        editBox:SetText((NotasDB_Global[guildKey] and NotasDB_Global[guildKey]["GUILD"] and NotasDB_Global[guildKey]["GUILD"][currentGuildPage]) or "")
        pageLabel:SetText("Página " .. currentGuildPage .. "/" .. MAX_GUILD_PAGES)
        UpdateCharCounter()
    end
end)

local nextPage = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
nextPage:SetSize(30, 22)
nextPage:SetText(">")
nextPage:SetScript("OnClick", function()
    if currentTarget == "GUILD" and currentGuildPage < MAX_GUILD_PAGES then
        SaveAddonHeader()
        currentGuildPage = currentGuildPage + 1
        isUserEditing = false 
        local guildKey = GetGuildKey()
        editBox:SetText((NotasDB_Global[guildKey] and NotasDB_Global[guildKey]["GUILD"] and NotasDB_Global[guildKey]["GUILD"][currentGuildPage]) or "")
        pageLabel:SetText("Página " .. currentGuildPage .. "/" .. MAX_GUILD_PAGES)
        UpdateCharCounter()
    end
end)

local paginadorFrame = CreateFrame("Frame", nil, f)
paginadorFrame:SetSize(300, 22)
paginadorFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -120, 10)
prevPage:SetParent(paginadorFrame)
prevPage:ClearAllPoints()
prevPage:SetPoint("LEFT", paginadorFrame, "LEFT", 0, 0)
pageLabel:SetParent(paginadorFrame)
pageLabel:ClearAllPoints()
pageLabel:SetPoint("LEFT", prevPage, "RIGHT", 10, 0)
nextPage:SetParent(paginadorFrame)
nextPage:ClearAllPoints()
nextPage:SetPoint("LEFT", pageLabel, "RIGHT", 10, 0)
local syncAllButton = CreateFrame("Button", "NotasSyncAllButton", paginadorFrame, "UIPanelButtonTemplate")
syncAllButton:SetSize(80, 22)
syncAllButton:SetPoint("LEFT", nextPage, "RIGHT", 10, 0)
syncAllButton:SetText("Sync Guild")
syncAllButton:Hide()
syncAllButton:SetScript("OnClick", function()
    if not IsInGuild() then
        print("|cffff0000[" .. ADDON_NAME .. "]|r No estás en una guild.")
        return
    end    
    if not IsPlayerOfficer() then
        print("|cffff0000[" .. ADDON_NAME .. "]|r Solo los oficiales pueden sincronizar todas las notas de guild.")
        return
    end
    print("|cff00ff00[" .. ADDON_NAME .. "]|r Iniciando sincronización de nombre, notas de guild, oficiales y miembros...")
    syncAllButton:SetText("Sincronizando...")
    syncAllButton:Disable()
    local paginasSincronizadas = 0
    local notasPersonalesSincronizadas = 0
    local oficialesSincronizada = false
    local encabezadoSincronizado = false
    if IsPlayerGuildMaster() and NotasAddon_VisibleName and trim(NotasAddon_VisibleName) ~= "" then
        local setNameMsg = "SET_ADDON_NAME|" .. NotasAddon_VisibleName
        SendAddonMessage("Notas-guild-addon", setNameMsg, "GUILD")
        encabezadoSincronizado = true
        print("|cff00ff00[" .. ADDON_NAME .. "]|r Encabezado enviado a la guild.")
    end
    local guildKey = GetGuildKey()
    if type(NotasDB_Global[guildKey]) ~= "table" then NotasDB_Global[guildKey] = {} end
    if type(NotasDB_Global[guildKey]["GUILD"]) == "table" then
        for pagina = 1, MAX_GUILD_PAGES do
            local contenido = NotasDB_Global[guildKey]["GUILD"][pagina]
            if contenido and trim(contenido) ~= "" then
                SendLongNote(contenido, true, pagina)
                paginasSincronizadas = paginasSincronizadas + 1
            end
        end
    end
    if IsPlayerOfficer() and type(NotasDB_Global[guildKey]["OFICIALES"]) == "string" and trim(NotasDB_Global[guildKey]["OFICIALES"]) ~= "" then
        SendAddonMessage("Notas-guild-addon", "OFICIALES|"..NotasDB_Global[guildKey]["OFICIALES"], "GUILD")
        oficialesSincronizada = true
        print("|cff00ff00[" .. ADDON_NAME .. "]|r Nota de oficiales enviada a los oficiales.")
    end
    local notasParaEnviar = {}
    for nombreCompleto, nota in pairs(NotasDB_Global[guildKey]) do
        if nombreCompleto ~= "GUILD" and nombreCompleto ~= myFullName and nombreCompleto ~= "ENCABEZADO" and nombreCompleto ~= "OFICIALES" then
            if nota and trim(nota) ~= "" and #trim(nota) > 10 then
                table.insert(notasParaEnviar, {nombre = nombreCompleto, nota = nota})
            end
        end
    end
    local function mostrarResumenFinal()
        local mensaje = "|cff00ff00[" .. ADDON_NAME .. "]|r Sincronización completa:"
        if encabezadoSincronizado then
            mensaje = mensaje .. "\n- Encabezado/nombre de guild sincronizado"
        end
        if paginasSincronizadas > 0 then
            mensaje = mensaje .. "\n- " .. paginasSincronizadas .. " páginas de guild sincronizadas"
        end
        if oficialesSincronizada then
            mensaje = mensaje .. "\n- Nota de oficiales sincronizada"
        end
        if notasPersonalesSincronizadas > 0 then
            mensaje = mensaje .. "\n- " .. notasPersonalesSincronizadas .. " notas personales compartidas"
        end
        if not encabezadoSincronizado and paginasSincronizadas == 0 and notasPersonalesSincronizadas == 0 and not oficialesSincronizada then
            mensaje = "|cffFFD700[" .. ADDON_NAME .. "]|r No hay contenido para sincronizar."
        end
        print(mensaje)
    end
    if #notasParaEnviar > 0 then
        local notaIndex = 1
        local function EnviarSiguienteNota()
            if notaIndex <= #notasParaEnviar then
                local datos = notasParaEnviar[notaIndex]
                SendLongNoteForPlayer(datos.nota, datos.nombre, true)
                notasPersonalesSincronizadas = notasPersonalesSincronizadas + 1
                notaIndex = notaIndex + 1
                if notaIndex <= #notasParaEnviar then
                    local timerFrame = CreateFrame("Frame")
                    local elapsed = 0
                    timerFrame:SetScript("OnUpdate", function(self, delta)
                        elapsed = elapsed + delta
                        if elapsed >= 5 then
                            self:SetScript("OnUpdate", nil)
                            EnviarSiguienteNota()
                        end
                    end)
                else
                    mostrarResumenFinal()
                end
            else
                mostrarResumenFinal()
            end
        end
        EnviarSiguienteNota()
    else
        mostrarResumenFinal()
    end
    local restoreFrame = CreateFrame("Frame")
    local elapsed = 0
    restoreFrame:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta
        if elapsed >= 2 then
            syncAllButton:SetText("Sync Guild")
            syncAllButton:Enable()
            self:SetScript("OnUpdate", nil)
        end
    end)
end)

local function Dropdown_Initialize(self, level)
    local info = UIDropDownMenu_CreateInfo()
    info.text = "Notas de guild"
    info.func = function()
        currentTarget = "GUILD"
        isUserEditing = false
        local texto = ""
        local guildKey = GetGuildKey()
        if type(NotasDB_Global[guildKey]) == "table" and type(NotasDB_Global[guildKey]["GUILD"]) == "table" and type(NotasDB_Global[guildKey]["GUILD"][currentGuildPage]) == "string" then
            texto = NotasDB_Global[guildKey]["GUILD"][currentGuildPage]
        end
        editBox:SetText(texto or "")
        if IsPlayerGuildMaster() then
            editBox:EnableMouse(true)
            editBox:EnableKeyboard(true)
            editBox:SetTextColor(1,1,1)
            syncAllButton:Show()
            editBox:SetFocus()
            editBox:SetCursorPosition(editBox:GetText():len())
        else
            editBox:EnableMouse(false)
            editBox:EnableKeyboard(false)
            editBox:SetTextColor(0.7,0.7,0.7)
            syncAllButton:Hide()
        end
        pageLabel:SetText("Página " .. currentGuildPage .. "/" .. MAX_GUILD_PAGES)
        UIDropDownMenu_SetSelectedName(dropdown, "Notas de guild")
        paginadorFrame:Show()
        UpdateStatusLabel()
        UpdateCharCounter()
    end
    info.checked = (currentTarget == "GUILD")
    UIDropDownMenu_AddButton(info, level)
    if IsPlayerOfficer() then
        local infoOfi = UIDropDownMenu_CreateInfo()
        infoOfi.text = "Notas de oficiales"
        infoOfi.func = function()
            currentTarget = "OFICIALES"
            isUserEditing = false
            local texto = ""
            local guildKey = GetGuildKey()
            if type(NotasDB_Global[guildKey]) == "table" and type(NotasDB_Global[guildKey]["OFICIALES"]) == "string" then
                texto = NotasDB_Global[guildKey]["OFICIALES"]
            end
            editBox:SetText(texto or "")
            editBox:EnableMouse(true)
            editBox:EnableKeyboard(true)
            editBox:SetTextColor(1,1,1)
            pageLabel:SetText("")
            UIDropDownMenu_SetSelectedName(dropdown, "Notas de oficiales")
            paginadorFrame:Hide()
            syncAllButton:Hide()
            editBox:SetFocus()
            editBox:SetCursorPosition(editBox:GetText():len())
            UpdateStatusLabel()
            UpdateCharCounter()
        end
        infoOfi.checked = (currentTarget == "OFICIALES")
        UIDropDownMenu_AddButton(infoOfi, level)
    end
    local personajes = {}
    local guildKey = GetGuildKey()
    if type(NotasDB_Global[guildKey]) == "table" then
        for nombre, _ in pairs(NotasDB_Global[guildKey]) do
            if nombre ~= "GUILD" and nombre ~= "ENCABEZADO" and nombre ~= "OFICIALES" then
                local displayName = nombre:gsub("%-"..realmName, "")
                table.insert(personajes, {nombre = nombre, displayName = displayName})
            end
        end
    end
    table.sort(personajes, function(a, b)
        return a.displayName:lower() < b.displayName:lower()
    end)
    for _, personaje in ipairs(personajes) do
        local info2 = UIDropDownMenu_CreateInfo()
        info2.text = personaje.displayName
        info2.func = function()
            currentTarget = personaje.nombre
            isUserEditing = false
            local nota = ""
            local guildKey = GetGuildKey()
            if type(NotasDB_Global[guildKey]) == "table" and type(NotasDB_Global[guildKey][personaje.nombre]) == "string" then
                nota = NotasDB_Global[guildKey][personaje.nombre]
            end
            editBox:SetText(nota or "")
            pageLabel:SetText("")
            UIDropDownMenu_SetSelectedName(dropdown, personaje.displayName)
            paginadorFrame:Hide()
            syncAllButton:Hide()
            if personaje.nombre == myFullName then
                editBox:EnableMouse(true)
                editBox:EnableKeyboard(true)
                editBox:SetTextColor(1,1,1)
                editBox:SetFocus()
                editBox:SetCursorPosition(editBox:GetText():len())
            else
                editBox:EnableMouse(false)
                editBox:EnableKeyboard(false)
                editBox:SetTextColor(0.7,0.7,0.7)
            end
            UpdateStatusLabel()
            UpdateCharCounter()
        end
        info2.checked = (currentTarget == personaje.nombre)
        UIDropDownMenu_AddButton(info2, level)
    end
end

local function UpdateDropdown()
    UIDropDownMenu_Initialize(dropdown, Dropdown_Initialize)
    if currentTarget == "GUILD" then
        SaveAddonHeader()
        UIDropDownMenu_SetSelectedName(dropdown, "Notas de guild")
        pageLabel:SetText("Página " .. currentGuildPage .. "/" .. MAX_GUILD_PAGES)
        paginadorFrame:Show()
    elseif currentTarget == "OFICIALES" then
        UIDropDownMenu_SetSelectedName(dropdown, "Notas de oficiales")
        pageLabel:SetText("")
        paginadorFrame:Hide()
    else
        local displayName = currentTarget:gsub("%-"..realmName, "")
        UIDropDownMenu_SetSelectedName(dropdown, displayName)
        pageLabel:SetText("")
        paginadorFrame:Hide()
    end
end

local function RequestPlayerUpdate(playerName)
    if not IsInGuild() then
        print("|cffff0000[" .. ADDON_NAME .. "]|r No estás en una guild.")
        return
    end    
    if not playerName or trim(playerName) == "" then
        print("|cffff0000[" .. ADDON_NAME .. "]|r Debes especificar un nombre de jugador.")
        print("|cffFFD700Uso:|r /renovar nota <nombre>")
        return
    end
    playerName = trim(playerName)
    local targetFullName = GetFullPlayerName(playerName)
    GuildRoster()
    local isInGuild = false
    local isOnline = false
    local numTotalMembers = GetNumGuildMembers()    
    for i = 1, numTotalMembers do
        local name, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName = GetGuildRosterInfo(i)
        if name and (name:lower() == playerName:lower() or name:lower() == targetFullName:lower()) then
            isInGuild = true
            isOnline = online
            break
        end
    end    
    if not isInGuild then
        print("|cffff0000[" .. ADDON_NAME .. "]|r El jugador '" .. playerName .. "' no está en tu guild.")
        return
    end    
    if not isOnline then
        print("|cffFFD700[" .. ADDON_NAME .. "]|r El jugador '" .. playerName .. "' no está conectado en este momento.")
        print("La solicitud se enviará de todas formas por si se conecta pronto.")
    end    
    local requestMsg = "UPDATE_REQUEST|" .. myFullName
    SendAddonMessage("Notas-guild-addon", requestMsg, "WHISPER", playerName)    
    print("|cff00ff00[" .. ADDON_NAME .. "]|r Solicitud de actualización enviada a '" .. playerName .. "'.")
    if isOnline then
        print("Si el jugador tiene el addon instalado, debería enviar su información actualizada.")
    end
end

local function RequestGuildUpdate()
    if not IsInGuild() then
        print("|cffff0000[" .. ADDON_NAME .. "]|r No estás en una guild.")
        return
    end
    local onlineMembers = GetOnlineGuildMembers()    
    if #onlineMembers == 0 then
        print("|cffFFD700[" .. ADDON_NAME .. "]|r No hay miembros conectados en la guild.")
        return
    end    
    local solicitudesEnviadas = 0
    local requestMsg = "UPDATE_REQUEST|" .. myFullName
    for _, memberName in ipairs(onlineMembers) do
        if memberName ~= playerName then
            SendAddonMessage("Notas-guild-addon", requestMsg, "WHISPER", memberName)
            solicitudesEnviadas = solicitudesEnviadas + 1
        end
    end
    
    if solicitudesEnviadas > 0 then
        print("|cff00ff00[" .. ADDON_NAME .. "]|r Solicitudes de actualización enviadas a " .. solicitudesEnviadas .. " miembros conectados.")
        print("Los miembros que tengan el addon instalado enviarán su información actualizada.")
        print("|cffFFD700Nota:|r Puede tardar unos segundos en recibir todas las respuestas.")
    else
        print("|cffFFD700[" .. ADDON_NAME .. "]|r Solo tú estás conectado o no hay otros miembros para solicitar.")
    end
end

SLASH_RENOVAR1 = "/renovar"
_G.SlashCmdList["RENOVAR"] = function(msg)
    msg = msg and trim(msg) or ""
    if msg == "" then
        print("|cffff0000[" .. ADDON_NAME .. "]|r Uso del comando /renovar:")
        print("|cffFFD700/renovar nota <nombre>|r - Solicitar información de un jugador específico")
        print("|cffFFD700/notas renovar|r - Solicitar información de todos los miembros conectados")
        return
    end
    -- Separar el primer parámetro del resto
    local action, playerName = msg:match("^(%S+)%s*(.*)$")
    if not action then
        action = msg
        playerName = ""
    end
    action = action:lower()
    if action == "nota" then
        RequestPlayerUpdate(trim(playerName))
    else
        print("|cffff0000[" .. ADDON_NAME .. "]|r Parámetro no reconocido: '" .. action .. "'")
        print("|cffFFD700Uso:|r /renovar nota <nombre> o /notas renovar")
    end
end

SLASH_NOTAS1 = "/notas"
SLASH_NOTAS2 = "/notes"

_G.SlashCmdList["NOTAS"] = function(msg)
    msg = msg and trim(msg) or ""
    local rangosArg = msg:match("^rangos%s*(.*)$")
    if rangosArg then
        HandleOfficerRanksCommand(rangosArg)
        return
    end
    local nombreArg = msg:match("^nombre%s+(.+)$")
    if nombreArg then
        if not IsPlayerGuildMaster() then
            print("|cffff0000[" .. ADDON_NAME .. "]|r Solo el Guild Master puede cambiar el nombre visible del addon.")
            return
        end
        NotasAddon_VisibleName = nombreArg
        -- Guardar el nombre en la base de datos por guild y reino
        local guildKey = GetGuildKey()
        if type(NotasDB_Global[guildKey]) ~= "table" then NotasDB_Global[guildKey] = {} end
        NotasDB_Global[guildKey]["ENCABEZADO"] = nombreArg
        UpdateAddonTitle()
        print("|cff00ff00[" .. ADDON_NAME .. "]|r Nombre de la interfaz cambiado a: " .. NotasAddon_VisibleName)
        local setNameMsg = "SET_ADDON_NAME|" .. nombreArg
        SendAddonMessage("Notas-guild-addon", setNameMsg, "GUILD")
        return
    end
    local automsgPrefix = msg:match("^automsg%s*(.*)$")
    if automsgPrefix then
        HandleAutomsgCommand(automsgPrefix)
        return
    end
    local renovarArg = msg:match("^renovar%s*(.*)$")
    if renovarArg then
        renovarArg = trim(renovarArg)
        if renovarArg:lower() == "ayuda" then
            print("|cff00ff00[" .. ADDON_NAME .. "]|r Ayuda de /notas renovar:")
            print("|cffFFD700/notas renovar <nombre>|r - Solicita información de un jugador específico de la guild")
            print("|cffFFD700/notas renovar|r - Solicita información de todos los miembros conectados de la guild")
            return
        end
        if renovarArg == "" then
            RequestGuildUpdate()
            local requestNameMsg = "REQUEST_ADDON_NAME|" .. myFullName
            SendAddonMessage("Notas-guild-addon", requestNameMsg, "GUILD")
        else
            RequestPlayerUpdate(renovarArg)
        end
        return
    end
    if msg == "help" or msg == "ayuda" then
        print("|cff00ff00[" .. ADDON_NAME .. " v" .. ADDON_VERSION .. "]|r Comandos disponibles:")
        print("|cffFFD700/notas|r - Abre la ventana de notas")
        print("|cffFFD700/notas nombre <nuevo_nombre>|r - Cambia el nombre visible en la interfaz")
        print("|cffFFD700/notas estado|r - Mostrar estado del addon")
        print("|cffFFD700/notas renovar ayuda|r - Muestra ayuda de los comandos de renovar")
        print("|cffFFD700/notas automsg ayuda|r - Muestra ayuda de los automensajes")
        print("|cffFFD700/notas rangos ayuda|r - Gestiona los rangos de oficiales en tiempo real")
        print("|cffFFD700/notas creditos|r - Créditos y agradecimientos")
        return
    end
    if msg == "creditos" or msg == "créditos" then
        print("|cffFFD700Notas Guild Addon|r - Créditos y agradecimientos:")
        print("Desarrollador principal: Txarly-Txardudu")
        print("Agradecimientos especiales a la comunidad UltimoWoW y a Reckless, Ladebarr, Almeraya y en especial a Rkmerlina, Tialola y a Bertita, Dratiro.")
        print("Basado en ideas y feedback de los miembros de la hermandad Almas Perdidas.")
        print("|cff00ff00¡Gracias por usar este addon!|r")
        print("|cff00ff00Contacto para bugs y sugerencias, DISCORD: txarly2_22041")
        return
    end
    if msg == "status" or msg == "estado" then
        local notasPersonales = 0
        local paginasGuild = 0
        local guildKey = GetGuildKey()
        if type(NotasDB_Global[guildKey]) == "table" then
            if type(NotasDB_Global[guildKey]["GUILD"]) == "table" then
                for pagina = 1, MAX_GUILD_PAGES do
                    if NotasDB_Global[guildKey]["GUILD"][pagina] and trim(NotasDB_Global[guildKey]["GUILD"][pagina]) ~= "" then
                        paginasGuild = paginasGuild + 1
                    end
                end
            end
            for nombre, nota in pairs(NotasDB_Global[guildKey]) do
                if nombre ~= "GUILD" and nombre ~= "ENCABEZADO" and nombre ~= "OFICIALES" then
                    if nota and trim(nota) ~= "" then
                        notasPersonales = notasPersonales + 1
                    end
                end
            end
        end
        local totalNotas = notasPersonales + paginasGuild
        print("|cff00ff00[" .. ADDON_NAME .. " v" .. ADDON_VERSION .. "]|r Estado:")
        print("- En guild: " .. (IsInGuild() and "|cff00ff00Sí|r" or "|cffff0000No|r"))
        print("- Notas personales: " .. notasPersonales)
        print("- Páginas de guild: " .. paginasGuild)
        print("- Total de notas: " .. totalNotas)
        return
    end
    local guildKey = GetGuildKey()
    if type(NotasDB_Global[guildKey]) ~= "table" then NotasDB_Global[guildKey] = {} end
    if type(NotasDB_Global[guildKey]["GUILD"]) ~= "table" then NotasDB_Global[guildKey]["GUILD"] = {} end
    currentTarget = myFullName
    isUserEditing = false
    editBox:SetText(NotasDB_Global[guildKey][myFullName] or "")
    f:Show()
    editBox:EnableMouse(true)
    editBox:EnableKeyboard(true)
    editBox:SetTextColor(1,1,1)
    syncAllButton:Hide()
    EnsureMinimumHeight()
    editBox:SetFocus()
    editBox:SetCursorPosition(editBox:GetText():len())
    UpdateDropdown()
    UpdateStatusLabel()
    UpdateCharCounter()
    UpdateAddonTitle()
    if IsInGuild() and NotasDB_Global[guildKey][myFullName] then
        SendLongNote(NotasDB_Global[guildKey][myFullName], false, nil, false)
    end
    if IsInGuild() and NotasDB_Global[guildKey]["GUILD"][currentGuildPage] then
        SendLongNote(NotasDB_Global[guildKey]["GUILD"][currentGuildPage], true, currentGuildPage, false)
    end
    if IsInGuild() then
        RequestGuildUpdate()
    end
end
local receivedParts = {}
local partTimeouts = {}
local PART_TIMEOUT = 30
local function CleanupOldParts()
    local now = GetTime()
    for key, timestamp in pairs(partTimeouts) do
        if (now - timestamp) > PART_TIMEOUT then
            receivedParts[key] = nil
            partTimeouts[key] = nil
        end
    end
end

local commFrame = CreateFrame("Frame")
commFrame:RegisterEvent("PLAYER_LOGIN")
commFrame:RegisterEvent("CHAT_MSG_ADDON")
commFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "CHAT_MSG_ADDON" then
        local prefix, msg, channel, sender = ...
        if prefix == "Notas-guild-addon" and sender ~= UnitName("player") then
            if msg:match("^UPDATE_REQUEST|") then
                local requesterName = msg:match("^UPDATE_REQUEST|(.+)$")
                if requesterName and channel == "WHISPER" then
                    print("|cff00ff00[" .. ADDON_NAME .. "]|r " .. sender .. " ha solicitado tu información actualizada.")
                    local guildKey = GetGuildKey()
                    if NotasDB_Global[guildKey] and NotasDB_Global[guildKey][myFullName] and trim(NotasDB_Global[guildKey][myFullName]) ~= "" then
                        local note = NotasDB_Global[guildKey][myFullName]
                        local prefix = myFullName.."|1|1|"
                        local maxPartSize = MAX_ADDON_MSG_SIZE - #prefix
                        local total = math.ceil(#note / maxPartSize)
                        for i = 1, total do
                            local part = note:sub((i-1)*maxPartSize+1, i*maxPartSize)
                            local msg = myFullName.."|"..i.."|"..total.."|"..part
                            SendAddonMessage("Notas-guild-addon", msg, "WHISPER", sender)
                        end
                        print("|cff00ff00[" .. ADDON_NAME .. "]|r Información enviada a " .. sender .. ".")
                    else
                        local emptyMsg = myFullName .. "|1|1|"
                        SendAddonMessage("Notas-guild-addon", emptyMsg, "WHISPER", sender)
                        print("|cffFFD700[" .. ADDON_NAME .. "]|r No tienes nota guardada para enviar.")
                    end
                end
                return
            end
            if msg:match("^SET_ADDON_NAME|") then
                local newName = msg:match("^SET_ADDON_NAME|(.+)$")
                if newName and trim(newName) ~= "" then
                    NotasAddon_VisibleName = newName
                    _G["NotasAddon_VisibleName"] = newName
                    -- Guardar el nombre en la base de datos por guild y reino
                    local guildKey = GetGuildKey()
                    if type(NotasDB_Global[guildKey]) ~= "table" then NotasDB_Global[guildKey] = {} end
                    NotasDB_Global[guildKey]["ENCABEZADO"] = newName
                    if UpdateAddonTitle then UpdateAddonTitle() end
                    print("|cff00ff00[" .. ADDON_NAME .. "]|r El nombre visible del addon ha sido actualizado por el Guild Master: " .. newName)
                end
                return
            end
            if msg:match("^OFICIALES_SYNC|") then
                local lista = msg:match("^OFICIALES_SYNC|(.*)$")
                if lista then
                    local nuevaTabla = {}
                    for rank in string.gmatch(lista, "([^,]+)") do
                        rank = trim(rank):lower()
                        if rank ~= "" then
                            nuevaTabla[rank] = true
                        end
                    end
                    NotasAddon_OfficerRanks = nuevaTabla
                    GuardarOfficerRanks()
                    print("|cff00ff00[Notas]|r Rangos de oficiales actualizados desde la guild: "..lista)
                end
                return
            end
            -- Procesar recepción de nota de oficiales
            if msg:match("^OFICIALES|") then
                local nota = msg:match("^OFICIALES|(.*)$")
                if nota and IsPlayerOfficer() then
                    local guildKey = GetGuildKey()
                    if type(NotasDB_Global[guildKey]) ~= "table" then NotasDB_Global[guildKey] = {} end
                    NotasDB_Global[guildKey]["OFICIALES"] = nota
                    print("|cff00ff00[Notas]|r Nota de oficiales recibida y guardada.")
                    -- Si la ventana está abierta y viendo la nota de oficiales, actualizar el editBox
                    if f and f:IsShown() and currentTarget == "OFICIALES" and not isUserEditing then
                        editBox:SetText(nota)
                        UpdateCharCounter()
                    end
                end
                return
            end
            if msg:match("^REQUEST_ADDON_NAME|") then
                local requester = msg:match("^REQUEST_ADDON_NAME|(.+)$")
                if requester and (IsPlayerOfficer() or IsPlayerGuildMaster()) then
                    local responseMsg = "SET_ADDON_NAME|" .. (NotasAddon_VisibleName or ADDON_NAME)
                    local targetName = requester:match("^([^-]+)")
                    if targetName then
                        SendAddonMessage("Notas-guild-addon", responseMsg, "WHISPER", targetName)
                    end
                end
                return
            end
            if (channel == "GUILD" or channel == "WHISPER") then
                CleanupOldParts()
                local who, page, idx, total, part = msg:match("^(GUILD)|(%d+)|(%d+)|(%d+)|(.*)$")
                if who == "GUILD" then
                    page = tonumber(page)
                    idx = tonumber(idx)
                    total = tonumber(total)
                    if page and idx and total and part and idx > 0 and idx <= total then
                        local key = "GUILD"..page
                        receivedParts[key] = receivedParts[key] or {}
                        receivedParts[key][idx] = part
                        partTimeouts[key] = GetTime()
                        local count = 0
                        for _ in pairs(receivedParts[key]) do count = count + 1 end
                        if count == total then
                            local full = ""
                            for i = 1, total do
                                full = full .. (receivedParts[key][i] or "")
                            end
                            local guildKey = GetGuildKey()
                            if type(NotasDB_Global[guildKey]) ~= "table" then NotasDB_Global[guildKey] = {} end
                            if type(NotasDB_Global[guildKey]["GUILD"]) ~= "table" then NotasDB_Global[guildKey]["GUILD"] = {} end
                            NotasDB_Global[guildKey]["GUILD"][page] = full
                            receivedParts[key] = nil
                            partTimeouts[key] = nil
                            if f:IsShown() and currentTarget == "GUILD" and currentGuildPage == page and not isUserEditing then
                                editBox:SetText(full)
                                UpdateCharCounter()
                            end
                        end
                    end
                else
                    local who2, idx2, total2, part2 = msg:match("^(.-)|(%d+)|(%d+)|(.*)$")
                    if who2 and idx2 and total2 and part2 then
                    local senderFullName = GetFullPlayerName(sender)
                    local isOwner = (senderFullName == who2)
                    local isOfficerSyncing = false
                    if not isOwner then
                       GuildRoster()
                        local numTotalMembers = GetNumGuildMembers()
                        for i = 1, numTotalMembers do
                            local name, rank = GetGuildRosterInfo(i)
                            if name == sender then
                                isOfficerSyncing = rank and (rank:lower() == "guild master" or rank:lower() == "oficial")
                                break
                            end
                        end
                    end
                    if isOwner or isOfficerSyncing then
                        idx2 = tonumber(idx2)
                        total2 = tonumber(total2)
                        if idx2 and total2 and idx2 > 0 and idx2 <= total2 then
                            receivedParts[who2] = receivedParts[who2] or {}
                            receivedParts[who2][idx2] = part2
                            partTimeouts[who2] = GetTime()

                            local count = 0
                            for _ in pairs(receivedParts[who2]) do count = count + 1 end

                            if count == total2 then
                                local full = ""
                                for i = 1, total2 do
                                    full = full .. (receivedParts[who2][i] or "")
                                end
                                local guildKey = GetGuildKey()
                                if type(NotasDB_Global[guildKey]) ~= "table" then NotasDB_Global[guildKey] = {} end
                                NotasDB_Global[guildKey][who2] = full
                                local playerDisplayName = who2:gsub("%-"..realmName, "")
                                if trim(full) ~= "" then
                                    print("|cff00ff00[" .. ADDON_NAME .. "]|r Nota de " .. playerDisplayName .. " recibida y actualizada.")
                                else
                                    print("|cffFFD700[" .. ADDON_NAME .. "]|r " .. playerDisplayName .. " no tiene nota guardada.")
                                end
                                if f:IsShown() and currentTarget == who2 and not isUserEditing then
                                    editBox:SetText(full)
                                    UpdateCharCounter()
                                end
                                if f:IsShown() then
                                    UpdateDropdown()
                                end
                                receivedParts[who2] = nil
                                partTimeouts[who2] = nil
                            end
                        end
                    end
                    end
                end
            end
        end
    end
end)

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == ADDON_NAME then
        print("|cff00ff00[" .. ADDON_NAME .. " v" .. ADDON_VERSION .. "]|r Cargado correctamente.")
        print("|cffFFD700Usa /notas ayuda para ver los comandos disponibles.|r")
        if type(NotasDB_Global) ~= "table" then
            NotasDB_Global = {}
            print("|cffff0000[" .. ADDON_NAME .. "]|r Base de datos inicializada.")
        end
        local guildKey = GetGuildKey()
        if type(NotasDB_Global[guildKey]) ~= "table" then
            NotasDB_Global[guildKey] = {}
        end
        if type(NotasDB_Global[guildKey]["GUILD"]) ~= "table" then
            NotasDB_Global[guildKey]["GUILD"] = {}
        end
        -- Siempre leer y aplicar el encabezado si existe
        if type(NotasDB_Global[guildKey]["ENCABEZADO"]) == "string" and NotasDB_Global[guildKey]["ENCABEZADO"] ~= "" then
            NotasAddon_VisibleName = NotasDB_Global[guildKey]["ENCABEZADO"]
        else
            NotasAddon_VisibleName = nil
        end
        if UpdateAddonTitle then UpdateAddonTitle() end
        if type(NotasDB_Global[guildKey]["OFICIALES"]) == "table" then
            NotasAddon_OfficerRanks = NotasDB_Global[guildKey]["OFICIALES"]
        end
    elseif event == "PLAYER_LOGIN" then
        if IsInGuild() then
            if IsPlayerOfficer() then
                print("|cff00ff00[" .. ADDON_NAME .. "]|r Conectado a la guild. Para ver los comandos disponibles usa |cff00ff00/notas ayuda|r.")
            else
                print("|cff00ff00[" .. ADDON_NAME .. "]|r Conectado a la guild. Para ver los comandos disponibles usa |cff00ff00/notas ayuda|r.")
            end
        end
    end
end)
