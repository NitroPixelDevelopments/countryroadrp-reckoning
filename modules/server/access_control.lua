local QBCore = exports['qb-core']:GetCoreObject()

local accessLogs = {}
local zoneActivity = {}
local unauthorizedAttempts = {}

local AccessControlServer = {}

function AccessControlServer.Initialize()
    if not Config.AccessControl.enabled then return end
    
    -- Clean up old logs periodically
    CreateThread(function()
        while true do
            Wait(Config.Performance.cleanupInterval)
            AccessControlServer.CleanupOldLogs()
        end
    end)
end

function AccessControlServer.CleanupOldLogs()
    local currentTime = os.time()
    local cutoffTime = currentTime - 86400 -- 24 hours
    
    for i = #accessLogs, 1, -1 do
        if accessLogs[i].timestamp < cutoffTime then
            table.remove(accessLogs, i)
        end
    end
    
    -- Clean up zone activity older than 1 hour
    for zoneName, activities in pairs(zoneActivity) do
        for i = #activities, 1, -1 do
            if activities[i].timestamp < currentTime - 3600 then
                table.remove(activities, i)
            end
        end
    end
end

function AccessControlServer.GetPlayerClearance(player)
    if not player or not player.PlayerData then return 0 end
    
    local job = player.PlayerData.job.name
    local rank = player.PlayerData.job.grade.name
    local clearanceLevel = 0
    
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
            clearanceLevel = level.level
        end
    end
    
    return clearanceLevel
end

function AccessControlServer.LogAccess(playerId, zoneName, granted, clearanceLevel)
    local player = QBCore.Functions.GetPlayer(playerId)
    if not player then return end
    
    local logEntry = {
        playerId = playerId,
        citizenid = player.PlayerData.citizenid,
        playerName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
        zoneName = zoneName,
        granted = granted,
        clearanceLevel = clearanceLevel,
        timestamp = os.time()
    }
    
    table.insert(accessLogs, logEntry)
    
    -- Add to zone activity
    if not zoneActivity[zoneName] then
        zoneActivity[zoneName] = {}
    end
    
    table.insert(zoneActivity[zoneName], logEntry)
    
    -- Log to QB logging system
    TriggerEvent('qb-log:server:CreateLog', 'crp-reckoning', 'Zone Access', 
        granted and 'green' or 'red',
        string.format('%s (%s) %s access to %s (Clearance: %d)', 
            logEntry.playerName,
            logEntry.citizenid,
            granted and 'granted' or 'denied',
            zoneName,
            clearanceLevel
        )
    )
end

-- Event handlers
RegisterNetEvent('crp-reckoning:access:zoneEntered', function(zoneName, authorized)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    
    if not player then return end
    
    local clearanceLevel = AccessControlServer.GetPlayerClearance(player)
    AccessControlServer.LogAccess(src, zoneName, authorized, clearanceLevel)
end)

RegisterNetEvent('crp-reckoning:access:zoneExited', function(zoneName)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    
    if not player then return end
    
    -- Log zone exit
    TriggerEvent('qb-log:server:CreateLog', 'crp-reckoning', 'Zone Exit', 'blue',
        string.format('%s (%s) exited %s', 
            player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
            player.PlayerData.citizenid,
            zoneName
        )
    )
end)

RegisterNetEvent('crp-reckoning:access:unauthorizedEntry', function(zoneName, coords)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    
    if not player then return end
    
    local citizenid = player.PlayerData.citizenid
    
    -- Track unauthorized attempts
    if not unauthorizedAttempts[citizenid] then
        unauthorizedAttempts[citizenid] = {}
    end
    
    table.insert(unauthorizedAttempts[citizenid], {
        zoneName = zoneName,
        coords = coords,
        timestamp = os.time()
    })
    
    local clearanceLevel = AccessControlServer.GetPlayerClearance(player)
    AccessControlServer.LogAccess(src, zoneName, false, clearanceLevel)
    
    -- Alert security if multiple attempts
    if #unauthorizedAttempts[citizenid] >= 2 then
        AccessControlServer.AlertSecurity(src, player, zoneName, coords)
    end
    
    -- Send access denied response to client
    TriggerClientEvent('crp-reckoning:access:accessDenied', src, zoneName, 'Insufficient clearance level')
end)

function AccessControlServer.AlertSecurity(src, player, zoneName, coords)
    local playerName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    local players = QBCore.Functions.GetQBPlayers()
    
    -- Alert all security personnel
    for playerId, targetPlayer in pairs(players) do
        if targetPlayer.PlayerData.job.name == 'merryweather' then
            TriggerClientEvent('QBCore:Notify', playerId,
                string.format('SECURITY ALERT: %s attempting unauthorized access to %s', 
                    playerName, zoneName
                ), 'error'
            )
            
            -- Set waypoint for response
            TriggerClientEvent('crp-reckoning:security:setWaypoint', playerId, coords)
        end
    end
    
    -- Escalate if it's a critical zone
    local criticalZones = {'TRENCHGLASS Alpha Entrance', 'TRENCHGLASS Omega Exit'}
    for _, criticalZone in ipairs(criticalZones) do
        if zoneName == criticalZone then
            -- Trigger high-priority response
            TriggerEvent('crp-reckoning:blackline:triggerEvent', src, 'interrogation')
            break
        end
    end
end

-- Command to view access logs (security personnel only)
RegisterCommand('accesslogs', function(source, args)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    
    if not player or (player.PlayerData.job.name ~= 'merryweather' and player.PlayerData.job.name ~= 'northbridge') then
        TriggerClientEvent('QBCore:Notify', src, 'Access denied', 'error')
        return
    end
    
    local limit = tonumber(args[1]) or 10
    local recentLogs = {}
    
    for i = math.max(1, #accessLogs - limit + 1), #accessLogs do
        table.insert(recentLogs, accessLogs[i])
    end
    
    TriggerClientEvent('crp-reckoning:access:showLogs', src, recentLogs)
end)

-- Command to check player clearance (admin/security only)
RegisterCommand('checkclearance', function(source, args)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    
    if not player or (player.PlayerData.job.name ~= 'merryweather' and not QBCore.Functions.HasPermission(src, 'admin')) then
        TriggerClientEvent('QBCore:Notify', src, 'Access denied', 'error')
        return
    end
    
    if #args < 1 then
        TriggerClientEvent('QBCore:Notify', src, 'Usage: /checkclearance <player_id>', 'error')
        return
    end
    
    local targetId = tonumber(args[1])
    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    
    if not targetPlayer then
        TriggerClientEvent('QBCore:Notify', src, 'Player not found', 'error')
        return
    end
    
    local clearanceLevel = AccessControlServer.GetPlayerClearance(targetPlayer)
    local clearanceName = 'None'
    
    for _, level in ipairs(Config.AccessControl.clearanceLevels) do
        if level.level == clearanceLevel then
            clearanceName = level.name
            break
        end
    end
    
    TriggerClientEvent('QBCore:Notify', src,
        string.format('%s has Clearance Level %d (%s)', 
            targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname,
            clearanceLevel,
            clearanceName
        ), 'primary'
    )
end)

-- Export functions
exports('GetPlayerClearance', function(playerId)
    local player = QBCore.Functions.GetPlayer(playerId)
    return AccessControlServer.GetPlayerClearance(player)
end)

exports('GetAccessLogs', function()
    return accessLogs
end)

exports('GetZoneActivity', function(zoneName)
    return zoneActivity[zoneName] or {}
end)

exports('GetUnauthorizedAttempts', function()
    return unauthorizedAttempts
end)

-- Initialize system
CreateThread(function()
    Wait(1000)
    AccessControlServer.Initialize()
end)
