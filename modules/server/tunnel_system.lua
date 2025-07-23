-- Ensure Config is loaded before use
Config = Config or {}
local configFile = LoadResourceFile(GetCurrentResourceName(), "config.lua")
if configFile then
    local chunk = load(configFile)
    if chunk then chunk() end
end

local QBCore = exports['qb-core']:GetCoreObject()

-- Track players in tunnels
local playersInTunnel = {}
local unauthorizedAttempts = {}

-- Server-side tunnel system
local TunnelSystemServer = {}

function TunnelSystemServer.Initialize()
    if not Config.TunnelSystem or not Config.TunnelSystem.enabled then
        print("[TunnelSystem] Disabled or missing in config.")
        return
    end

    print("[TunnelSystem] Config loaded:", json.encode(Config.TunnelSystem))
    -- Clean up inactive sessions periodically
    CreateThread(function()
        while true do
            print("[TunnelSystem] Cleanup thread running...")
            Wait(Config.Performance and Config.Performance.cleanupInterval or 300000)
            TunnelSystemServer.CleanupInactiveSessions()
        end
    end)
    print("[TunnelSystem] Initialized successfully.")
end

function TunnelSystemServer.CleanupInactiveSessions()
    print("[TunnelSystem] Cleaning up inactive sessions...")
    for playerId, data in pairs(playersInTunnel) do
        local player = QBCore.Functions.GetPlayer(tonumber(playerId))
        if not player then
            print(string.format("[TunnelSystem] Removing inactive player %s from tunnel list.", playerId))
            playersInTunnel[playerId] = nil
        end
    end
end

-- Event handlers
RegisterNetEvent('crp-reckoning:tunnel:entered', function()
    local src = source
    local player = QBCore.Functions.GetPlayer(src)

    if not player then
        print("[TunnelSystem] Player not found for tunnel:entered, src:", src)
        return
    end

    playersInTunnel[tostring(src)] = {
        citizenid = player.PlayerData.citizenid,
        name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
        enteredAt = os.time(),
        job = player.PlayerData.job.name,
        rank = player.PlayerData.job.grade and player.PlayerData.job.grade.name or tostring(player.PlayerData.job.grade)
    }

    print(string.format("[TunnelSystem] Player %s (%s) entered tunnel.", playersInTunnel[tostring(src)].name, src))

    -- Log tunnel access
    local DiscordLogger = exports['countryroadrp-reckoning']:DiscordLogger()
    if DiscordLogger and DiscordLogger.LogTunnelAccess then
        print("[TunnelSystem] Logging tunnel access to Discord.")
        DiscordLogger.LogTunnelAccess({
            name = playersInTunnel[tostring(src)].name,
            citizenid = player.PlayerData.citizenid,
            job = playersInTunnel[tostring(src)].job,
            rank = playersInTunnel[tostring(src)].rank
        }, 'TRENCHGLASS Tunnel System', true)
    end

    -- Notify other authorized personnel
    TunnelSystemServer.NotifyAuthorizedPersonnel('entered', playersInTunnel[tostring(src)])
end)

RegisterNetEvent('crp-reckoning:tunnel:exited', function()
    local src = source
    local playerData = playersInTunnel[tostring(src)]

    if playerData then
        local duration = os.time() - playerData.enteredAt
        print(string.format("[TunnelSystem] Player %s (%s) exited tunnel after %d seconds.", playerData.name, src, duration))

        -- Log tunnel exit
        TriggerEvent('qb-log:server:CreateLog', 'crp-reckoning', 'Tunnel Exit', 'blue',
            string.format('%s exited TRENCHGLASS tunnel system after %d minutes',
                playerData.name, math.floor(duration / 60)
            )
        )

        playersInTunnel[tostring(src)] = nil
    else
        print("[TunnelSystem] No player data found for tunnel:exited, src:", src)
    end
end)

RegisterNetEvent('crp-reckoning:tunnel:unauthorizedAccess', function(coords)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)

    if not player then
        print("[TunnelSystem] Player not found for unauthorizedAccess, src:", src)
        return
    end

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

    print(string.format("[TunnelSystem] Unauthorized access attempt by %s (%s) at %s. Total attempts: %d",
        name, src, coords, #unauthorizedAttempts[citizenid]))

    -- Log security breach attempt
    local DiscordLogger = exports['countryroadrp-reckoning']:DiscordLogger()
    if DiscordLogger and DiscordLogger.LogTunnelAccess then
        print("[TunnelSystem] Logging unauthorized access to Discord.")
        DiscordLogger.LogTunnelAccess({
            name = name,
            citizenid = citizenid,
            job = player.PlayerData.job.name,
            coords = coords
        }, 'TRENCHGLASS System', false)
    end

    -- Alert security if multiple attempts
    if #unauthorizedAttempts[citizenid] >= 3 then
        print(string.format("[TunnelSystem] Alerting security for %s (%s)", name, src))
        TunnelSystemServer.AlertSecurity(src, player, coords)
    end
end)

function TunnelSystemServer.NotifyAuthorizedPersonnel(action, playerData)
    print(string.format("[TunnelSystem] Notifying authorized personnel: %s %s", playerData.name, action))
    local players = QBCore.Functions.GetQBPlayers()

    for playerId, player in pairs(players) do
        if player.PlayerData.job.name == 'merryweather' or player.PlayerData.job.name == 'northbridge' then
            print(string.format("[TunnelSystem] Notifying player %s (%s)", player.PlayerData.charinfo.firstname, playerId))
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

    print(string.format("[TunnelSystem] Alerting Merryweather security for %s (%s)", name, src))

    -- Alert all Merryweather personnel
    for playerId, targetPlayer in pairs(players) do
        if targetPlayer.PlayerData.job.name == 'merryweather' then
            print(string.format("[TunnelSystem] Sending security alert to %s (%s)", targetPlayer.PlayerData.charinfo.firstname, playerId))
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
    print(string.format("[TunnelSystem] Triggering Blackline event for %s (%s)", name, src))
    TriggerEvent('crp-reckoning:blackline:triggerEvent', src, 'interrogation')
end

-- Export functions
exports('GetPlayersInTunnel', function()
    print("[TunnelSystem] Export: GetPlayersInTunnel called.")
    return playersInTunnel
end)

exports('IsPlayerInTunnel', function(src)
    print(string.format("[TunnelSystem] Export: IsPlayerInTunnel called for %s.", src))
    return playersInTunnel[tostring(src)] ~= nil
end)

exports('GetUnauthorizedAttempts', function()
    print("[TunnelSystem] Export: GetUnauthorizedAttempts called.")
    return unauthorizedAttempts
end)

-- Initialize system
CreateThread(function()
    print("[TunnelSystem] Startup thread running, waiting for dependencies...")
    Wait(1000)
    TunnelSystemServer.Initialize()
end)
