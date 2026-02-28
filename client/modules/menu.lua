Menu = {}

function Menu:CheckModel(character)
    if not character.model then
        if character.skin and character.skin.model then
            character.model = character.skin.model
        elseif character.skin and character.skin.sex == 1 then
            character.model = `mp_f_freemode_01`
        elseif character.sex == TranslateCap("female") then
            character.model = `mp_f_freemode_01`
        else
            character.model = `mp_m_freemode_01`
        end
    end
end

local GetSlot = function()
    for i = 1, Multicharacter.slots do
        if not Multicharacter.Characters[i] then
            return i
        end
    end
end

local function CancelEmote()
    local rpemoteResource = GetResourceState('rpemotes-reborn')
    if rpemoteResource ~= 'started' then return end
    if not exports['rpemotes-reborn'] or not exports['rpemotes-reborn'].EmoteCancel then return end
    pcall(function()
        exports['rpemotes-reborn']:EmoteCancel()
    end)
end

local function GetCurrentPedGender()
    local ped = PlayerPedId()
    local model = GetEntityModel(ped)
    if model == `mp_f_freemode_01` then
        return "f"
    elseif model == `mp_m_freemode_01` then
        return "m"
    else
        return "other"
    end
end

local function PlayRandomEmote()
    local emotes = Config.SelectionEmotes
    if not emotes or #emotes == 0 then return end

    local rpemoteResource = GetResourceState('rpemotes-reborn')
    if rpemoteResource ~= 'started' then return end
    if not exports['rpemotes-reborn'] or not exports['rpemotes-reborn'].EmoteCommandStart then return end

    local gender = GetCurrentPedGender()
    local available = {}
    for _, emote in ipairs(emotes) do
        if emote.gender == "all" or emote.gender == gender then
            available[#available + 1] = emote.name
        end
    end

    if #available == 0 then return end

    CancelEmote()
    Wait(300)

    local emoteName = available[math.random(1, #available)]
    local success, err = pcall(function()
        exports['rpemotes-reborn']:EmoteCommandStart(emoteName)
    end)

    if not success then
        print(string.format("^1[esx_multicharacter] Erreur emote '%s': %s^7", emoteName, tostring(err)))
    end
end

local function ResetToDefaultModel(callback)
    local model = `mp_m_freemode_01`

    RequestModel(model)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(model) do
        Wait(0)
        if GetGameTimer() > timeout then
            break
        end
    end
    
    if not HasModelLoaded(model) then
        if callback then callback() end
        return
    end

    SetPlayerModel(PlayerId(), model)
    local ped = PlayerPedId()

    SetPedDefaultComponentVariation(ped)

    SetPedHeadBlendData(ped, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.0, true)

    while not HasPedHeadBlendFinished(ped) do
        Wait(0)
    end

    for i = 0, 19 do
        SetPedFaceFeature(ped, i, 0.0)
    end

    for i = 0, 12 do
        SetPedHeadOverlay(ped, i, 0, 0.0)
    end

    SetPedHairColor(ped, 0, 0)
    
    SetPedEyeColor(ped, 0)
    
    SetPedComponentVariation(ped, 2, 0, 0, 2)
    
    SetPedComponentVariation(ped, 3, 15, 0, 2)  -- Bras
    SetPedComponentVariation(ped, 4, 14, 0, 2)  -- Pantalon
    SetPedComponentVariation(ped, 6, 34, 0, 2)  -- Chaussures
    SetPedComponentVariation(ped, 8, 15, 0, 2)  -- T-shirt
    SetPedComponentVariation(ped, 11, 15, 0, 2) -- Torse
    
    ClearAllPedProps(ped)
    ClearPedDecorations(ped)
    
    SetModelAsNoLongerNeeded(model)
    
    Wait(100)
    
    if callback then callback() end
end

function Menu:NewCharacter()
    local slot = GetSlot()

    TriggerServerEvent("esx_multicharacter:CharacterChosen", slot, true)
    
    ResetToDefaultModel(function()
        if exports['lfCharacterCreator'] and exports['lfCharacterCreator'].openSaveableMenu then
            exports['lfCharacterCreator']:openSaveableMenu(function()
            end, nil, slot)
        else
            TriggerEvent("esx_identity:showRegisterIdentity")
        end
    end)

    local playerPed = PlayerPedId()

    SetPedAoBlobRendering(playerPed, false)
    SetEntityAlpha(playerPed, 0, false)

    Multicharacter:CloseUI()
end


function Menu:InitCharacter()
    local Characters = Multicharacter.Characters
    local Character = nil
    for i = 1, Multicharacter.slots do
        if Characters[i] then
            Character = i
            break
        end
    end
    
    if not Character then
        return
    end
    
    self:CheckModel(Characters[Character])

    if not Multicharacter.spawned then
        Multicharacter:SetupCharacter(Character, true)
    end

    PlayRandomEmote()

    Wait(500)
    
    SendNUIMessage({
        action = "ToggleMulticharacter",
        data = {
            show = true,
            Characters = Characters,
            CanDelete = Config.CanDelete,
            AllowedSlot = Multicharacter.slots,
            Locale = Locales[Config.Locale].UI,
        }
    })

    SetNuiFocus(true, true)
end

function Menu:SelectCharacter(index)
    CancelEmote()

    local oldPed = PlayerPedId()
    ClearPedTasksImmediately(oldPed)
    ClearAllPedProps(oldPed)

    Multicharacter:SetupCharacter(index)
    local playerPed = PlayerPedId()
    SetPedAoBlobRendering(playerPed, true)
    ResetEntityAlpha(playerPed)

    PlayRandomEmote()
end

function Menu:PlayCharacter()
    CancelEmote()
    Wait(300)

    local ped = PlayerPedId()
    ClearPedTasksImmediately(ped)
    ClearAllPedProps(ped)

    Multicharacter:CloseUI()
    TriggerServerEvent("esx_multicharacter:CharacterChosen", Multicharacter.spawned, false)
end

function Menu:DeleteCharacter()
    TriggerServerEvent("esx_multicharacter:DeleteCharacter", Multicharacter.spawned)
    Multicharacter.spawned = false
end