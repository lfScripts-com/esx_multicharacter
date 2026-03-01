---@diagnostic disable: duplicate-set-field
Multicharacter = {}
Multicharacter._index = Multicharacter
Multicharacter.canRelog = true
Multicharacter.Characters = {}
Multicharacter.hidePlayers = false
Multicharacter.currentPositionIndex = 1
Multicharacter.shuffledPositions = nil

function Multicharacter:ShufflePositions()
    local positions = Config.CharacterPositions
    if not positions or #positions == 0 then
        self.shuffledPositions = {}
        return
    end

    local indices = {}
    for i = 1, #positions do
        indices[i] = i
    end

    for i = #indices, 2, -1 do
        local j = math.random(1, i)
        indices[i], indices[j] = indices[j], indices[i]
    end

    self.shuffledPositions = indices
end

function Multicharacter:GetPositionForSlot(slotIndex)
    local positions = Config.CharacterPositions
    if not positions or #positions == 0 then
        return { x = 0.0, y = 0.0, z = 0.0, w = 0.0 }
    end

    if not self.shuffledPositions or #self.shuffledPositions == 0 then
        self:ShufflePositions()
    end

    local shuffleIndex = ((slotIndex - 1) % #self.shuffledPositions) + 1
    local posIndex = self.shuffledPositions[shuffleIndex]
    return positions[posIndex]
end

function Multicharacter:SetupCamera(pos)
    pos = pos or self.spawnCoords
    if not self.cam then
        self.cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    end
    SetCamActive(self.cam, true)
    RenderScriptCams(true, false, 1, true, true)

    self:UpdateCameraForPosition(pos)
end

function Multicharacter:UpdateCameraForPosition(pos)
    if not self.cam then return end

    local ped = self.playerPed
    local camPos = GetOffsetFromEntityInWorldCoords(ped, 0.6, 2.2, 0.2)
    local lookAt = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.0, 0.4)

    SetCamCoord(self.cam, camPos.x, camPos.y, camPos.z)
    PointCamAtCoord(self.cam, lookAt.x, lookAt.y, lookAt.z)
end

function Multicharacter:MoveCameraToPosition(pos)
    if not self.cam then
        self:SetupCamera(pos)
        return
    end

    Wait(50)
    self.playerPed = PlayerPedId()
    self:UpdateCameraForPosition(pos)
end

function Multicharacter:TeleportPedToPosition(pos)
    local ped = self.playerPed

    RequestCollisionAtCoord(pos.x, pos.y, pos.z)
    SetEntityCoords(ped, pos.x, pos.y, pos.z, true, false, false, false)
    SetEntityHeading(ped, pos.w or 0.0)

    local timeout = GetGameTimer() + 3000
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < timeout do
        Wait(50)
    end

    local found, groundZ = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + 2.0, false)
    if found then
        SetEntityCoords(ped, pos.x, pos.y, groundZ, true, false, false, false)
    end

    FreezeEntityPosition(ped, true)
end

function Multicharacter:AwaitFadeIn()
    while IsScreenFadingIn() do
        Wait(200)
    end
end

function Multicharacter:AwaitFadeOut()
    while IsScreenFadingOut() do
        Wait(200)
    end
end

function Multicharacter:DestoryCamera()
    if self.cam then
        SetCamActive(self.cam, false)
        RenderScriptCams(false, false, 0, true, true)
        self.cam = nil
    end
end

local HiddenCompents = {}

local function HideComponents(hide)
    local components = {11, 12, 21}
    for i = 1, #components do
        if hide then
            local size = GetHudComponentSize(components[i])
            if size.x > 0 or size.y > 0 then
                HiddenCompents[components[i]] = size
                SetHudComponentSize(components[i], 0.0, 0.0)
            end
        else
            if HiddenCompents[components[i]] then
                local size = HiddenCompents[components[i]]
                SetHudComponentSize(components[i], size.x, size.z)
                HiddenCompents[components[i]] = nil
            end
        end
    end
    DisplayRadar(not hide)
end

function Multicharacter:HideHud(hide)
    self.hidePlayers = true

    MumbleSetVolumeOverride(ESX.playerId, 0.0)
    HideComponents(hide)
end

function Multicharacter:SetupCharacters()
    ESX.PlayerLoaded = false
    ESX.PlayerData = {}

    self.spawned = false
    self.currentPositionIndex = 1
    self:ShufflePositions()

    self.playerPed = PlayerPedId()
    self.spawnCoords = self:GetPositionForSlot(1)

    RequestCollisionAtCoord(self.spawnCoords.x, self.spawnCoords.y, self.spawnCoords.z)
    SetEntityCoords(self.playerPed, self.spawnCoords.x, self.spawnCoords.y, self.spawnCoords.z, true, false, false, false)
    SetEntityHeading(self.playerPed, self.spawnCoords.w or 0.0)

    local timeout = GetGameTimer() + 3000
    while not HasCollisionLoadedAroundEntity(self.playerPed) and GetGameTimer() < timeout do
        Wait(50)
    end

    local found, groundZ = GetGroundZFor_3dCoord(self.spawnCoords.x, self.spawnCoords.y, self.spawnCoords.z + 2.0, false)
    if found then
        SetEntityCoords(self.playerPed, self.spawnCoords.x, self.spawnCoords.y, groundZ, true, false, false, false)
    end

    SetPlayerControl(ESX.playerId, false, 0)
    self:SetupCamera(self.spawnCoords)
    self:HideHud(true)
    
    TriggerEvent("esx:loadingScreenOff")

    SetTimeout(200, function()
        TriggerServerEvent("esx_multicharacter:SetupCharacters")
    end)
end

function Multicharacter:GetSkin()
    local character = self.Characters[self.tempIndex]
    
    local hasValidSkin = character and character.skin and type(character.skin) == 'table' and next(character.skin)
    local skin = hasValidSkin and character.skin or Config.Default
    
    if not character.model then
        if character.sex == TranslateCap("female") then
            skin.sex = 1
        else
            skin.sex = 0
        end
    end
    
    return skin
end

function Multicharacter:SpawnTempPed()
    self.canRelog = false
    local character = self.Characters[self.tempIndex]
    local skin = self:GetSkin()
    local hasValidSkin = character and character.skin and type(character.skin) == 'table' and next(character.skin)
    local pos = self:GetPositionForSlot(self.tempIndex)
    self.spawnCoords = pos
    
    ESX.SpawnPlayer(skin, pos, function()
        self.playerPed = PlayerPedId()
        SetEntityHeading(self.playerPed, pos.w or 0.0)
        self:UpdateCameraForPosition(pos)
        
        if hasValidSkin then
            Wait(100)
            
            local skinToLoad = character.skin
            local lfCreatorState = GetResourceState('lfCharacterCreator')
            if lfCreatorState == 'started' and exports['lfCharacterCreator'] and exports['lfCharacterCreator'].skinForLoading then
                local converted = exports['lfCharacterCreator'].skinForLoading(character.skin)
                if converted ~= nil then
                    skinToLoad = converted
                end
            end
            
            if skinToLoad and type(skinToLoad) == 'table' then
                TriggerEvent("skinchanger:loadSkin", skinToLoad, function()
                    Wait(100)
                    
                    if lfCreatorState == 'started' and exports['lfCharacterCreator'] then
                        local applyFunc = exports['lfCharacterCreator'].applySkinAppearance
                        if applyFunc then
                            applyFunc(character.skin)
                        end
                    end
                    
                    DoScreenFadeIn(600)
                end)
            else
                DoScreenFadeIn(600)
            end
        else
            DoScreenFadeIn(600)
        end
    end)
end

function Multicharacter:ChangeExistingPed()
    local newCharacter = self.Characters[self.tempIndex]
    local spawnedCharacter = self.Characters[self.spawned]

    if not newCharacter.model then
        newCharacter.model = newCharacter.sex == TranslateCap("male") and `mp_m_freemode_01` or `mp_f_freemode_01`
    end

    if spawnedCharacter and spawnedCharacter.model then
        local model = ESX.Streaming.RequestModel(newCharacter.model)
        if model then
            SetPlayerModel(ESX.playerId, newCharacter.model)
            SetModelAsNoLongerNeeded(newCharacter.model)
        end
    end
    
    if newCharacter.skin and type(newCharacter.skin) == 'table' then
        local skinToLoad = newCharacter.skin
        local lfCreatorState = GetResourceState('lfCharacterCreator')
        if lfCreatorState == 'started' and exports['lfCharacterCreator'] and exports['lfCharacterCreator'].skinForLoading then
            local converted = exports['lfCharacterCreator'].skinForLoading(newCharacter.skin)
            if converted ~= nil then
                skinToLoad = converted
            end
        end
        
        if skinToLoad and type(skinToLoad) == 'table' then
            TriggerEvent("skinchanger:loadSkin", skinToLoad, function()
                if lfCreatorState == 'started' and exports['lfCharacterCreator'] then
                    local applyFunc = exports['lfCharacterCreator'].applySkinAppearance
                    if applyFunc then
                        applyFunc(newCharacter.skin)
                    end
                end
            end)
        end
    end
end

function Multicharacter:PrepForUI()
    FreezeEntityPosition(self.playerPed, true)
    SetPedAoBlobRendering(self.playerPed, true)
    SetEntityAlpha(self.playerPed, 255, false)
end

function Multicharacter:CloseUI()
    SendNUIMessage({
        action = "ToggleMulticharacter",
        data = {
            show = false
        }
    })
    SetNuiFocus(false, false)
end

function Multicharacter:SetupCharacter(index, skipTransition)
    local character = self.Characters[index]
    self.tempIndex = index

    local newPos = self:GetPositionForSlot(index)

    if not self.spawned then
        self.spawnCoords = newPos
        self:SpawnTempPed()
    else
        local duration = Config.TransitionDuration or 400

        if not skipTransition then
            DoScreenFadeOut(math.floor(duration / 2))
            self:AwaitFadeOut()
        end

        self:TeleportPedToPosition(newPos)
        self.spawnCoords = newPos

        if character and character.skin then
            self:ChangeExistingPed()
        end

        Wait(100)
        self.playerPed = PlayerPedId()
        self:MoveCameraToPosition(newPos)

        if not skipTransition then
            DoScreenFadeIn(math.floor(duration / 2))
        end
    end

    self.spawned = index
    self.currentPositionIndex = index
    self.playerPed = PlayerPedId()
    self:PrepForUI()
end

function Multicharacter:SetupUI(characters, slots)
    DoScreenFadeOut(0)

    self.Characters = characters
    self.slots = slots

    local Character = nil
    for i = 1, slots do
        if self.Characters[i] then
            Character = i
            break
        end
    end
    
    if not Character then
        self.canRelog = false

        ESX.SpawnPlayer(Config.Default, self.spawnCoords, function()
            DoScreenFadeIn(400)
            self:AwaitFadeIn()

            self.playerPed = PlayerPedId()
            SetPedAoBlobRendering(self.playerPed, false)
            SetEntityAlpha(self.playerPed, 0, false)

            TriggerServerEvent("esx_multicharacter:CharacterChosen", 1, true)
            if exports['lfCharacterCreator'] and exports['lfCharacterCreator'].openSaveableMenu then
                TriggerEvent('lfCharacterCreator:setCharId', 1)
                exports['lfCharacterCreator']:openSaveableMenu(function()
                end)
            else
                TriggerEvent("esx_identity:showRegisterIdentity")
            end
        end)
    else
        Menu:InitCharacter()
    end
end

function Multicharacter:LoadSkinCreator(skin)
    TriggerEvent("skinchanger:getSkin", function(currentSkin)
        if currentSkin and currentSkin.sex ~= nil and exports['lfCharacterCreator'] then
            Multicharacter.finishedCreation = true
            DoScreenFadeIn(600)
            SetPedAoBlobRendering(self.playerPed, true)
            ResetEntityAlpha(self.playerPed)
        else
            -- Convertir le skin au format attendu par skinchanger (normalise le sexe en 0/1)
            local skinToLoad = skin
            local lfCreatorState = GetResourceState('lfCharacterCreator')
            if lfCreatorState == 'started' and exports['lfCharacterCreator'] and exports['lfCharacterCreator'].skinForLoading then
                local converted = exports['lfCharacterCreator'].skinForLoading(skin)
                if converted ~= nil then
                    skinToLoad = converted
                end
            end
            
            if skinToLoad and type(skinToLoad) == 'table' then
                TriggerEvent("skinchanger:loadSkin", skinToLoad, function()
                    DoScreenFadeIn(600)
                    SetPedAoBlobRendering(self.playerPed, true)
                    ResetEntityAlpha(self.playerPed)

                    if exports['lfCharacterCreator'] and exports['lfCharacterCreator'].openSaveableMenu then
                        exports['lfCharacterCreator']:openSaveableMenu(function()
                            Multicharacter.finishedCreation = true
                        end, function()
                            Multicharacter.finishedCreation = true
                        end)
                    else
                        TriggerEvent("esx_skin:openSaveableMenu", function()
                            Multicharacter.finishedCreation = true
                        end, function()
                            Multicharacter.finishedCreation = true
                        end)
                    end
                end)
            else
                DoScreenFadeIn(600)
                SetPedAoBlobRendering(self.playerPed, true)
                ResetEntityAlpha(self.playerPed)
            end
        end
    end)
end

function Multicharacter:SetDefaultSkin(playerData)

    local skin = Config.Default[playerData.sex]
    skin.sex = playerData.sex == "m" and 0 or 1

    local model = skin.sex == 0 and `mp_m_freemode_01` or `mp_f_freemode_01`
    ---@diagnostic disable-next-line: cast-local-type
    model = ESX.Streaming.RequestModel(model)

    if not model then
        return
    end

    SetPlayerModel(ESX.playerId, model)
    SetModelAsNoLongerNeeded(model)
    self.playerPed = PlayerPedId()

    self:LoadSkinCreator(skin)
end

function Multicharacter:Reset()
    self.Characters = {}
    self.tempIndex = nil
    self.playerPed = PlayerPedId()
    self.hidePlayers = false
    self.slots = nil

    SetTimeout(10000, function()
        self.canRelog = true
    end)
end

function Multicharacter:PlayerLoaded(playerData, isNew, skin)
    DoScreenFadeOut(750)
    self:AwaitFadeOut()

    local esxSpawns = ESX.GetConfig().DefaultSpawns
    local spawn = esxSpawns[math.random(1, #esxSpawns)]

    if not isNew and playerData.coords then
        spawn = playerData.coords
    end

    if isNew or not skin or #skin == 1 then
        local currentSkin = exports["skinchanger"] and exports["skinchanger"]:GetSkin()
        
        if currentSkin and currentSkin.sex ~= nil then
            skin = currentSkin
            DoScreenFadeOut(500)
            self:AwaitFadeOut()
        else
            self.finishedCreation = false
            self:SetDefaultSkin(playerData)

            while not self.finishedCreation do
                Wait(200)
            end

            skin = exports["skinchanger"]:GetSkin()
            DoScreenFadeOut(500)
            self:AwaitFadeOut()
        end
    elseif not isNew then
        local characterSkin = skin or self.Characters[self.spawned].skin
        if characterSkin and type(characterSkin) == 'table' then
            -- Convertir le skin au format attendu par skinchanger (normalise le sexe en 0/1)
            local skinToLoad = characterSkin
            local lfCreatorState = GetResourceState('lfCharacterCreator')
            if lfCreatorState == 'started' and exports['lfCharacterCreator'] and exports['lfCharacterCreator'].skinForLoading then
                local converted = exports['lfCharacterCreator'].skinForLoading(characterSkin)
                if converted ~= nil then
                    skinToLoad = converted
                end
            end
            
            if skinToLoad and type(skinToLoad) == 'table' then
                TriggerEvent("skinchanger:loadSkin", skinToLoad, function()
                    if lfCreatorState == 'started' and exports['lfCharacterCreator'] then
                        local applyFunc = exports['lfCharacterCreator'].applySkinAppearance
                        if applyFunc then
                            Wait(50)
                            applyFunc(characterSkin)
                        end
                    end
                end)
            end
        end
    end

    self:DestoryCamera()
    ESX.SpawnPlayer(skin, spawn, function()
        self:HideHud(false)
        SetPlayerControl(ESX.playerId, true, 0)

        self.playerPed = PlayerPedId()
        
        if skin and type(skin) == 'table' then
            Wait(300)
            
            local lfCreatorState = GetResourceState('lfCharacterCreator')
            if lfCreatorState == 'started' and exports['lfCharacterCreator'] then
                local applyFunc = exports['lfCharacterCreator'].applySkinAppearance
                if applyFunc then
                    applyFunc(skin)
                end
            end
        end
        
        FreezeEntityPosition(self.playerPed, false)
        SetEntityCollision(self.playerPed, true, true)

        DoScreenFadeIn(750)

        self:AwaitFadeIn()

        TriggerServerEvent("esx:onPlayerSpawn")
        TriggerEvent("esx:onPlayerSpawn")
        TriggerEvent("esx:restoreLoadout")

        self:Reset()
    end)
end