local QBCore = exports['qb-core']:GetCoreObject()

-- Track players in tunnels
local playersInTunnel = {}
local unauthorizedAttempts = {}

-- Server-side tunnel system
local TunnelSystemServer = {}

function TunnelSystemServer.Initialize()
    if not Config.TunnelSystem.enabled then return end
    
    -- Clean up inactive sessions periodically
    CreateThread(function()
        while true do
            Wait(Config.Performance.cleanupInterval)
            TunnelSystemServer.CleanupInactiveSessions()
        end
    end)
end

function TunnelSystemServer.CleanupInactiveSessions()
    for playerId, data in pairs(playersInTunnel) do
        local player = QBCore.Functions.GetPlayer(tonumber(playerId))
        if not player then
            playersInTunnel[playerId] = nil
        end
    end
end

-- Event handlers
RegisterNetEvent('crp-reckoning:tunnel:entered', function()
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    
    if not player then return end
    
    playersInTunnel[tostring(src)] = {
        citizenid = player.PlayerData.citizenid,
        name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
        enteredAt = os.time(),
        job = player.PlayerData.job.name,
        rank = player.PlayerData.job.grade.name
    }
    
    -- Log tunnel access
    local DiscordLogger = exports['countryroadrp-reckoning']:DiscordLogger()
    DiscordLogger.LogTunnelAccess({
        name = playersInTunnel[tostring(src)].name,
        citizenid = player.PlayerData.citizenid,
        job = playersInTunnel[tostring(src)].job,
        rank = playersInTunnel[tostring(src)].rank
    }, 'TRENCHGLASS Tunnel System', true)
    
    -- Notify other authorized personnel
    TunnelSystemServer.NotifyAuthorizedPersonnel('entered', playersInTunnel[tostring(src)])
end)

RegisterNetEvent('crp-reckoning:tunnel:exited', function()
    local src = source
    local playerData = playersInTunnel[tostring(src)]
    
    if playerData then
        local duration = os.time() - playerData.enteredAt
        
        -- Log tunnel exit
        TriggerEvent('qb-log:server:CreateLog', 'crp-reckoning', 'Tunnel Exit', 'blue', 
            string.format('%s exited TRENCHGLASS tunnel system after %d minutes', 
                playerData.name, math.floor(duration / 60)
            )
        )
        
        playersInTunnel[tostring(src)] = nil
    end
end)

RegisterNetEvent('crp-reckoning:tunnel:unauthorizedAccess', function(coords)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    
    if not player then return end
    
    local citizenid = player.PlayerData.citizenid
    local name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    
    -- Track unauthorized attempts
    if not unauthorizedAttempts[citizenid] then
        unauthorizedAttempts[citizenid] = {}
    end
    
    table.insert(unauthorizedAttempts[citizenid], {
        timestamp = os.time(),
        coords = coords,
        job = player.PlayerData.job.name
    })
    
    -- Log security breach attempt
    local DiscordLogger = exports['countryroadrp-reckoning']:DiscordLogger()
    DiscordLogger.LogTunnelAccess({
        name = name,
        citizenid = citizenid,
        job = player.PlayerData.job.name,
        coords = coords
    }, 'TRENCHGLASS System', false)
    
    -- Alert security if multiple attempts
    if #unauthorizedAttempts[citizenid] >= 3 then
        TunnelSystemServer.AlertSecurity(src, player, coords)
    end
end)

function TunnelSystemServer.NotifyAuthorizedPersonnel(action, playerData)
    local players = QBCore.Functions.GetQBPlayers()
    
    for playerId, player in pairs(players) do
        if player.PlayerData.job.name == 'merryweather' or player.PlayerData.job.name == 'northbridge' then
            TriggerClientEvent('QBCore:Notify', playerId, 
                string.format('TRENCHGLASS: %s %s the system (%s)', 
                    playerData.name, action, playerData.job
                ), 'primary'
            )
        end
    end
end

function TunnelSystemServer.AlertSecurity(src, player, coords)
    local name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    local players = QBCore.Functions.GetQBPlayers()
    
    -- Alert all Merryweather personnel
    for playerId, targetPlayer in pairs(players) do
        if targetPlayer.PlayerData.job.name == 'merryweather' then
            TriggerClientEvent('QBCore:Notify', playerId, 
                string.format('SECURITY ALERT: Multiple unauthorized access attempts by %s. Location: %s', 
                    name, coords
                ), 'error'
            )
            
            -- Add waypoint for security response
            TriggerClientEvent('crp-reckoning:security:setWaypoint', playerId, coords)
        end
    end
    
    -- Trigger Blackline event for the offending player
    TriggerEvent('crp-reckoning:blackline:triggerEvent', src, 'interrogation')
end

-- Export functions
exports('GetPlayersInTunnel', function()
    return playersInTunnel
end)

exports('IsPlayerInTunnel', function(src)
    return playersInTunnel[tostring(src)] ~= nil
end)

exports('GetUnauthorizedAttempts', function()
    return unauthorizedAttempts
end)

-- Initialize system
CreateThread(function()
    Wait(1000)
    TunnelSystemServer.Initialize()
end)
