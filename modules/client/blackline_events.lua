local QBCore = exports['qb-core']:GetCoreObject()
local activeEvent = nil
local eventNPCs = {}
local eventVehicles = {}

local BlacklineEvents = {}

function BlacklineEvents.Initialize()
    if not Config.BlacklineEvents.enabled then return end
    
    -- Listen for server-triggered events
    RegisterNetEvent('crp-reckoning:blackline:startEvent', BlacklineEvents.StartEvent)
    RegisterNetEvent('crp-reckoning:blackline:endEvent', BlacklineEvents.EndEvent)
    RegisterNetEvent('crp-reckoning:blackline:showInterrogationScreen', BlacklineEvents.ShowInterrogationScreen)
end

function BlacklineEvents.StartEvent(eventData)
    if activeEvent then return end
    
    activeEvent = eventData
    
    CreateThread(function()
        BlacklineEvents.SpawnAgents(eventData)
        BlacklineEvents.HandleEventLogic(eventData)
    end)
end

function BlacklineEvents.SpawnAgents(eventData)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local spawnCoords = BlacklineEvents.GetNearestSpawnLocation(playerCoords)
    
    if not spawnCoords then return end
    
    -- Spawn agents
    for i = 1, math.random(2, 4) do
        local model = Config.BlacklineEvents.agentModels[math.random(#Config.BlacklineEvents.agentModels)]
        
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(10)
        end
        
        local offsetX = math.random(-10, 10)
        local offsetY = math.random(-10, 10)
        local agentCoords = vector3(spawnCoords.x + offsetX, spawnCoords.y + offsetY, spawnCoords.z)
        
        local ped = CreatePed(4, model, agentCoords.x, agentCoords.y, agentCoords.z, spawnCoords.heading, false, true)
        
        SetEntityAsMissionEntity(ped, true, true)
        SetPedFleeAttributes(ped, 0, 0)
        SetPedCombatAttributes(ped, 17, 1)
        SetPedSeeingRange(ped, 50.0)
        SetPedHearingRange(ped, 20.0)
        SetPedAlertness(ped, 3)
        
        -- Give weapons
        GiveWeaponToPed(ped, GetHashKey('WEAPON_PISTOL'), 250, false, true)
        SetPedDropsWeaponsWhenDead(ped, false)
        
        table.insert(eventNPCs, ped)
        SetModelAsNoLongerNeeded(model)
    end
    
    -- Spawn vehicle
    if eventData.type ~= 'surveillance' then
        local vehicleModel = Config.BlacklineEvents.agentVehicles[math.random(#Config.BlacklineEvents.agentVehicles)]
        
        RequestModel(vehicleModel)
        while not HasModelLoaded(vehicleModel) do
            Wait(10)
        end
        
        local vehicle = CreateVehicle(vehicleModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.heading, true, false)
        SetEntityAsMissionEntity(vehicle, true, true)
        
        table.insert(eventVehicles, vehicle)
        SetModelAsNoLongerNeeded(vehicleModel)
    end
end

function BlacklineEvents.HandleEventLogic(eventData)
    local playerPed = PlayerPedId()
    
    if eventData.type == 'interrogation' then
        BlacklineEvents.HandleInterrogation()
    elseif eventData.type == 'memory_wipe' then
        BlacklineEvents.HandleMemoryWipe()
    elseif eventData.type == 'surveillance' then
        BlacklineEvents.HandleSurveillance()
    end
    
    -- Auto-end event after duration
    CreateThread(function()
        Wait(eventData.duration * 1000)
        if activeEvent and activeEvent.id == eventData.id then
            TriggerServerEvent('crp-reckoning:blackline:eventTimeout', eventData.id)
        end
    end)
end

function BlacklineEvents.HandleInterrogation()
    QBCore.Functions.Notify('Unidentified vehicles approaching...', 'error')
    
    CreateThread(function()
        while activeEvent and activeEvent.type == 'interrogation' do
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            
            -- Make NPCs approach player
            for _, npc in ipairs(eventNPCs) do
                if DoesEntityExist(npc) then
                    TaskGoToCoordAnyMeans(npc, playerCoords.x, playerCoords.y, playerCoords.z, 2.0, 0, 0, 786603, 0xbf800000)
                    
                    local distance = #(GetEntityCoords(npc) - playerCoords)
                    if distance < 5.0 then
                        -- Trigger interrogation sequence
                        TriggerServerEvent('crp-reckoning:blackline:playerDetained')
                        break
                    end
                end
            end
            
            Wait(1000)
        end
    end)
end

function BlacklineEvents.HandleMemoryWipe()
    QBCore.Functions.Notify('You feel disoriented...', 'error')
    
    -- Apply memory wipe effects
    DoScreenFadeOut(2000)
    
    CreateThread(function()
        Wait(3000)
        
        -- Teleport player to random location
        local randomSpawn = Config.BlacklineEvents.spawnLocations[math.random(#Config.BlacklineEvents.spawnLocations)]
        SetEntityCoords(PlayerPedId(), randomSpawn.coords.x, randomSpawn.coords.y, randomSpawn.coords.z)
        
        Wait(1000)
        DoScreenFadeIn(3000)
        
        QBCore.Functions.Notify('Where am I? What was I doing?', 'primary')
    end)
end

function BlacklineEvents.HandleSurveillance()
    QBCore.Functions.Notify('You feel like you\'re being watched...', 'primary')
    
    -- Make NPCs follow at distance
    CreateThread(function()
        while activeEvent and activeEvent.type == 'surveillance' do
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            
            for _, npc in ipairs(eventNPCs) do
                if DoesEntityExist(npc) then
                    local followCoords = vector3(
                        playerCoords.x + math.random(-50, 50),
                        playerCoords.y + math.random(-50, 50),
                        playerCoords.z
                    )
                    TaskGoToCoordAnyMeans(npc, followCoords.x, followCoords.y, followCoords.z, 1.0, 0, 0, 786603, 0xbf800000)
                end
            end
            
            Wait(5000)
        end
    end)
end

function BlacklineEvents.ShowInterrogationScreen()
    -- Create interrogation UI
    SendNUIMessage({
        type = 'showInterrogation',
        questions = {
            'What were you doing in the restricted area?',
            'Who authorized your access?',
            'Are you working with any resistance groups?',
            'Have you shared classified information?'
        }
    })
    SetNuiFocus(true, true)
end

function BlacklineEvents.EndEvent()
    if not activeEvent then return end
    
    -- Clean up NPCs
    for _, npc in ipairs(eventNPCs) do
        if DoesEntityExist(npc) then
            DeleteEntity(npc)
        end
    end
    
    -- Clean up vehicles
    for _, vehicle in ipairs(eventVehicles) do
        if DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
        end
    end
    
    eventNPCs = {}
    eventVehicles = {}
    activeEvent = nil
    
    QBCore.Functions.Notify('The agents have left the area...', 'success')
end

function BlacklineEvents.GetNearestSpawnLocation(playerCoords)
    local nearestDistance = math.huge
    local nearestLocation = nil
    
    for _, location in ipairs(Config.BlacklineEvents.spawnLocations) do
        local distance = #(playerCoords - location.coords)
        if distance < nearestDistance then
            nearestDistance = distance
            nearestLocation = location
        end
    end
    
    return nearestLocation
end

-- Export functions
exports('GetActiveEvent', function()
    return activeEvent
end)

exports('IsEventActive', function()
    return activeEvent ~= nil
end)

-- Initialize system
CreateThread(function()
    Wait(1000)
    BlacklineEvents.Initialize()
end)
