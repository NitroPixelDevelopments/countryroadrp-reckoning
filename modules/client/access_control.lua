local QBCore = exports['qb-core']:GetCoreObject()
local activeZones = {}
local playerClearance = 0

local AccessControl = {}

function AccessControl.Initialize()
    if not Config.AccessControl.enabled then return end
    
    -- Get player clearance level
    AccessControl.UpdateClearanceLevel()
    
    -- Monitor restricted zones
    CreateThread(function()
        while true do
            AccessControl.CheckRestrictedZones()
            Wait(1000)
        end
    end)
    
    -- Listen for clearance updates
    RegisterNetEvent('crp-reckoning:access:updateClearance', AccessControl.UpdateClearanceLevel)
    RegisterNetEvent('crp-reckoning:access:accessDenied', AccessControl.HandleAccessDenied)
end

function AccessControl.UpdateClearanceLevel()
    local playerData = QBCore.Functions.GetPlayerData()
    if not playerData or not playerData.job then
        playerClearance = 0
        return
    end
    
    local job = playerData.job.name
    local rank = playerData.job.grade.name
    
    -- Determine clearance level
    for _, level in ipairs(Config.AccessControl.clearanceLevels) do
        local hasJob = false
        local hasRank = true
        
        -- Check job requirement
        for _, requiredJob in ipairs(level.jobs) do
            if job == requiredJob then
                hasJob = true
                break
            end
        end
        
        -- Check rank requirement if specified
        if level.ranks then
            hasRank = false
            for _, requiredRank in ipairs(level.ranks) do
                if rank == requiredRank then
                    hasRank = true
                    break
                end
            end
        end
        
        if hasJob and hasRank then
            playerClearance = level.level
        end
    end
end

function AccessControl.CheckRestrictedZones()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    for _, zone in ipairs(Config.AccessControl.restrictedZones) do
        local distance = #(playerCoords - zone.coords)
        local isInZone = distance <= zone.radius
        local wasInZone = activeZones[zone.name] or false
        
        if isInZone and not wasInZone then
            -- Entering restricted zone
            AccessControl.EnterRestrictedZone(zone)
        elseif not isInZone and wasInZone then
            -- Exiting restricted zone
            AccessControl.ExitRestrictedZone(zone)
        end
        
        activeZones[zone.name] = isInZone
    end
end

function AccessControl.EnterRestrictedZone(zone)
    if playerClearance >= zone.requiredLevel then
        -- Access granted
        QBCore.Functions.Notify(
            string.format('Entering %s - Clearance Level %d', zone.name, zone.requiredLevel), 
            'success'
        )
        
        TriggerServerEvent('crp-reckoning:access:zoneEntered', zone.name, true)
    else
        -- Access denied
        QBCore.Functions.Notify(
            string.format('RESTRICTED AREA: %s requires Clearance Level %d', zone.name, zone.requiredLevel), 
            'error'
        )
        
        TriggerServerEvent('crp-reckoning:access:unauthorizedEntry', zone.name, GetEntityCoords(PlayerPedId()))
        
        -- Push player away from zone
        AccessControl.EjectFromZone(zone)
    end
end

function AccessControl.ExitRestrictedZone(zone)
    QBCore.Functions.Notify(
        string.format('Exiting %s', zone.name), 
        'primary'
    )
    
    TriggerServerEvent('crp-reckoning:access:zoneExited', zone.name)
end

function AccessControl.EjectFromZone(zone)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    -- Calculate ejection direction (away from zone center)
    local direction = playerCoords - zone.coords
    local normalizedDirection = direction / #direction
    
    -- Find safe coordinates outside the zone
    local safeDistance = zone.radius + 10.0
    local safeCoords = zone.coords + (normalizedDirection * safeDistance)
    
    -- Apply force to push player away
    local force = normalizedDirection * 5.0
    SetEntityVelocity(playerPed, force.x, force.y, 0.0)
    
    -- Optional: Teleport if force doesn't work
    CreateThread(function()
        Wait(2000)
        local currentCoords = GetEntityCoords(playerPed)
        local currentDistance = #(currentCoords - zone.coords)
        
        if currentDistance <= zone.radius then
            SetEntityCoords(playerPed, safeCoords.x, safeCoords.y, safeCoords.z + 1.0)
            QBCore.Functions.Notify('You have been removed from the restricted area', 'error')
        end
    end)
end

function AccessControl.HandleAccessDenied(zoneName, reason)
    QBCore.Functions.Notify(
        string.format('Access to %s denied: %s', zoneName, reason), 
        'error', 
        5000
    )
end

function AccessControl.GetClearanceLevelName(level)
    for _, clearanceLevel in ipairs(Config.AccessControl.clearanceLevels) do
        if clearanceLevel.level == level then
            return clearanceLevel.name
        end
    end
    return 'None'
end

-- Command to check clearance level
RegisterCommand('clearance', function()
    local levelName = AccessControl.GetClearanceLevelName(playerClearance)
    QBCore.Functions.Notify(
        string.format('Security Clearance: Level %d (%s)', playerClearance, levelName), 
        'primary'
    )
end)

-- Export functions
exports('GetPlayerClearance', function()
    return playerClearance
end)

exports('GetClearanceLevelName', function(level)
    return AccessControl.GetClearanceLevelName(level or playerClearance)
end)

exports('IsInRestrictedZone', function()
    for _, inZone in pairs(activeZones) do
        if inZone then return true end
    end
    return false
end)

exports('GetActiveZones', function()
    return activeZones
end)

-- Initialize system
CreateThread(function()
    Wait(1000)
    AccessControl.Initialize()
end)
