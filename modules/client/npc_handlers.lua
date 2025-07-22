local QBCore = exports['qb-core']:GetCoreObject()
local spawnedCivilians = {}
local exposedAgents = {}

local NPCHandlers = {}

function NPCHandlers.Initialize()
    if not Config.NPCHandlers.enabled then return end
    
    -- Spawn civilian disguises
    CreateThread(function()
        while true do
            NPCHandlers.ManageCivilianSpawns()
            Wait(30000) -- Check every 30 seconds
        end
    end)
    
    -- Monitor for player interactions
    CreateThread(function()
        while true do
            NPCHandlers.CheckPlayerInteractions()
            Wait(1000)
        end
    end)
end

function NPCHandlers.ManageCivilianSpawns()
    local playerCoords = GetEntityCoords(PlayerPedId())
    
    -- Clean up distant NPCs
    for i = #spawnedCivilians, 1, -1 do
        local civilian = spawnedCivilians[i]
        if not DoesEntityExist(civilian.ped) then
            table.remove(spawnedCivilians, i)
        else
            local distance = #(GetEntityCoords(civilian.ped) - playerCoords)
            if distance > 500.0 then
                DeleteEntity(civilian.ped)
                table.remove(spawnedCivilians, i)
            end
        end
    end
    
    -- Limit active NPCs for performance
    if #spawnedCivilians >= Config.Performance.maxNPCs then
        return
    end
    
    -- Check spawn locations
    for _, location in ipairs(Config.NPCHandlers.civilianDisguises.locations) do
        local distance = #(playerCoords - location.coords)
        
        if distance <= location.radius then
            -- Check if we should spawn an NPC here
            if math.random() < Config.NPCHandlers.civilianDisguises.spawnChance then
                NPCHandlers.SpawnCivilianDisguise(location)
            end
        end
    end
end

function NPCHandlers.SpawnCivilianDisguise(location)
    -- Check if already spawned in this location recently
    for _, civilian in ipairs(spawnedCivilians) do
        local distance = #(GetEntityCoords(civilian.ped) - location.coords)
        if distance < 50.0 then
            return -- Too close to existing spawn
        end
    end
    
    local model = Config.NPCHandlers.civilianDisguises.models[math.random(#Config.NPCHandlers.civilianDisguises.models)]
    
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end
    
    -- Find a good spawn point within the location
    local spawnCoords = NPCHandlers.FindSpawnPoint(location)
    if not spawnCoords then
        SetModelAsNoLongerNeeded(model)
        return
    end
    
    local ped = CreatePed(4, model, spawnCoords.x, spawnCoords.y, spawnCoords.z, math.random(0, 360), false, true)
    
    -- Configure NPC behavior
    SetEntityAsMissionEntity(ped, true, true)
    SetPedFleeAttributes(ped, 0, 0)
    SetPedCombatAttributes(ped, 17, 1)
    SetPedSeeingRange(ped, 25.0)
    SetPedHearingRange(ped, 15.0)
    SetPedAlertness(ped, 2)
    
    -- Give civilian appearance
    SetPedRandomComponentVariation(ped, false)
    SetPedRandomProps(ped)
    
    -- Add to tracking
    local civilianData = {
        ped = ped,
        location = location,
        spawnTime = GetGameTimer(),
        exposed = false,
        isAgent = true -- This is a disguised agent
    }
    
    table.insert(spawnedCivilians, civilianData)
    
    -- Make NPC wander around
    TaskWanderStandard(ped, 10.0, 10)
    
    SetModelAsNoLongerNeeded(model)
end

function NPCHandlers.FindSpawnPoint(location)
    local attempts = 0
    while attempts < 10 do
        local offsetX = math.random(-location.radius, location.radius)
        local offsetY = math.random(-location.radius, location.radius)
        local testCoords = vector3(location.coords.x + offsetX, location.coords.y + offsetY, location.coords.z)
        
        local groundZ = NPCHandlers.GetGroundZ(testCoords)
        if groundZ then
            local finalCoords = vector3(testCoords.x, testCoords.y, groundZ)
            
            -- Check if spawn point is clear
            if NPCHandlers.IsSpawnPointClear(finalCoords) then
                return finalCoords
            end
        end
        
        attempts = attempts + 1
    end
    
    return nil
end

function NPCHandlers.GetGroundZ(coords)
    local retval, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 50.0, false)
    if retval then
        return groundZ
    end
    return nil
end

function NPCHandlers.IsSpawnPointClear(coords)
    -- Check for nearby vehicles and players
    local nearbyVehicles = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
    if nearbyVehicles ~= 0 then
        return false
    end
    
    -- Check for other NPCs
    for _, civilian in ipairs(spawnedCivilians) do
        if DoesEntityExist(civilian.ped) then
            local distance = #(GetEntityCoords(civilian.ped) - coords)
            if distance < 3.0 then
                return false
            end
        end
    end
    
    return true
end

function NPCHandlers.CheckPlayerInteractions()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    for i, civilian in ipairs(spawnedCivilians) do
        if DoesEntityExist(civilian.ped) and civilian.isAgent and not civilian.exposed then
            local npcCoords = GetEntityCoords(civilian.ped)
            local distance = #(playerCoords - npcCoords)
            
            -- Check if player is investigating the NPC
            if distance < 2.0 and IsControlJustReleased(0, 38) then -- E key
                NPCHandlers.InteractWithCivilian(civilian, i)
            end
            
            -- Check if NPC should react to player behavior
            if distance < 10.0 then
                NPCHandlers.UpdateNPCBehavior(civilian, playerPed)
            end
        end
    end
end

function NPCHandlers.InteractWithCivilian(civilian, index)
    local interactionChance = math.random()
    
    if interactionChance < 0.3 then -- 30% chance to expose themselves
        NPCHandlers.ExposeCivilian(civilian, index)
    else
        -- Normal civilian interaction
        local responses = {
            "Just minding my own business.",
            "Beautiful day, isn't it?",
            "Sorry, I'm late for a meeting.",
            "Nice weather we're having.",
            "Have a good day!"
        }
        
        local response = responses[math.random(#responses)]
        QBCore.Functions.Notify(response, 'primary', 3000)
    end
end

function NPCHandlers.ExposeCivilian(civilian, index)
    civilian.exposed = true
    exposedAgents[civilian.ped] = true
    
    -- NPC realizes they've been exposed
    local exposureLines = {
        "You shouldn't have done that...",
        "Command, we have a problem.",
        "Abort mission. Cover blown.",
        "Target is onto us."
    }
    
    local line = exposureLines[math.random(#exposureLines)]
    QBCore.Functions.Notify(line, 'error', 5000)
    
    -- NPC tries to flee
    TaskSmartFleeCoord(civilian.ped, civilian.location.coords.x, civilian.location.coords.y, civilian.location.coords.z, 500.0, -1, true, true)
    
    -- Trigger reinforcement response
    TriggerServerEvent('crp-reckoning:npc:agentExposed', GetEntityCoords(civilian.ped))
    
    -- Remove from normal tracking and add to exposed tracking
    table.remove(spawnedCivilians, index)
    
    -- Clean up after some time
    CreateThread(function()
        Wait(30000) -- 30 seconds
        if DoesEntityExist(civilian.ped) then
            DeleteEntity(civilian.ped)
        end
        exposedAgents[civilian.ped] = nil
    end)
end

function NPCHandlers.UpdateNPCBehavior(civilian, playerPed)
    -- NPCs become suspicious if player follows them
    local playerCoords = GetEntityCoords(playerPed)
    local npcCoords = GetEntityCoords(civilian.ped)
    local distance = #(playerCoords - npcCoords)
    
    if distance < 5.0 then
        -- NPC becomes alert
        SetPedAlertness(civilian.ped, 3)
        
        -- Occasionally look at player
        if math.random() < 0.3 then
            TaskLookAtEntity(civilian.ped, playerPed, 2000, 2048, 3)
        end
        
        -- If player gets too close for too long, NPC might react
        if distance < 2.5 and math.random() < 0.1 then
            TaskGoStraightToCoord(civilian.ped, npcCoords.x + math.random(-20, 20), npcCoords.y + math.random(-20, 20), npcCoords.z, 1.5, 5000, 0.0, 0)
        end
    end
end

-- Export functions
exports('GetSpawnedCivilians', function()
    return spawnedCivilians
end)

exports('GetExposedAgents', function()
    return exposedAgents
end)

exports('IsNPCExposed', function(ped)
    return exposedAgents[ped] or false
end)

-- Initialize system
CreateThread(function()
    Wait(1000)
    NPCHandlers.Initialize()
end)
