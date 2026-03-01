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

-- Fonction pour réinitialiser le personnage au modèle par défaut propre
local function ResetToDefaultModel(callback)
    local model = `mp_m_freemode_01`
    
    -- Charger le modèle
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
    
    -- Appliquer le modèle
    SetPlayerModel(PlayerId(), model)
    local ped = PlayerPedId()
    
    -- Réinitialiser tous les composants à leur valeur par défaut
    SetPedDefaultComponentVariation(ped)
    
    -- Réinitialiser le head blend (parents) avec des valeurs neutres
    SetPedHeadBlendData(ped, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.0, true)
    
    -- Attendre que le head blend soit terminé
    while not HasPedHeadBlendFinished(ped) do
        Wait(0)
    end
    
    -- Réinitialiser tous les traits du visage à 0
    for i = 0, 19 do
        SetPedFaceFeature(ped, i, 0.0)
    end
    
    -- Réinitialiser tous les overlays (maquillage, barbe, etc.)
    for i = 0, 12 do
        SetPedHeadOverlay(ped, i, 0, 0.0)
    end
    
    -- Réinitialiser la couleur des cheveux
    SetPedHairColor(ped, 0, 0)
    
    -- Réinitialiser la couleur des yeux
    SetPedEyeColor(ped, 0)
    
    -- Réinitialiser les cheveux (composant 2)
    SetPedComponentVariation(ped, 2, 0, 0, 2)
    
    -- Vêtements par défaut homme (torse nu, pantalon basique)
    SetPedComponentVariation(ped, 3, 15, 0, 2)  -- Bras
    SetPedComponentVariation(ped, 4, 14, 0, 2)  -- Pantalon
    SetPedComponentVariation(ped, 6, 34, 0, 2)  -- Chaussures
    SetPedComponentVariation(ped, 8, 15, 0, 2)  -- T-shirt
    SetPedComponentVariation(ped, 11, 15, 0, 2) -- Torse
    
    -- Retirer tous les props (chapeau, lunettes, etc.)
    ClearAllPedProps(ped)
    
    -- Effacer les tatouages
    ClearPedDecorations(ped)
    
    SetModelAsNoLongerNeeded(model)
    
    Wait(100)
    
    if callback then callback() end
end

function Menu:NewCharacter()
    local slot = GetSlot()

    TriggerServerEvent("esx_multicharacter:CharacterChosen", slot, true)
    
    -- Réinitialiser le personnage au modèle par défaut AVANT d'ouvrir le créateur
    ResetToDefaultModel(function()
        if exports['lfCharacterCreator'] and exports['lfCharacterCreator'].openSaveableMenu then
            TriggerEvent('lfCharacterCreator:setCharId', slot)
            exports['lfCharacterCreator']:openSaveableMenu(function()
            end)
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
        Multicharacter:SetupCharacter(Character)
    end
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
    Multicharacter:SetupCharacter(index)
    local playerPed = PlayerPedId()
    SetPedAoBlobRendering(playerPed, true)
    ResetEntityAlpha(playerPed)
end

function Menu:PlayCharacter()
    Multicharacter:CloseUI()
    TriggerServerEvent("esx_multicharacter:CharacterChosen", Multicharacter.spawned, false)
end

function Menu:DeleteCharacter()
    TriggerServerEvent("esx_multicharacter:DeleteCharacter", Multicharacter.spawned)
    Multicharacter.spawned = false
end