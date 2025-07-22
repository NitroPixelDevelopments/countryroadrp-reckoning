local QBCore = exports['qb-core']:GetCoreObject()

local activeBroadcast = nil
local broadcastHistory = {}
local lastBroadcastTime = 0

local ResistanceRadioServer = {}

function ResistanceRadioServer.Initialize()
    if not Config.ResistanceRadio.enabled then return end
    
    -- Schedule broadcasts
    CreateThread(function()
        while true do
            Wait(60000) -- Check every minute
            ResistanceRadioServer.CheckBroadcastSchedule()
        end
    end)
end

function ResistanceRadioServer.CheckBroadcastSchedule()
    local currentTime = os.date('*t')
    local currentHour = currentTime.hour
    
    -- Check if it's time for a broadcast
    for _, hour in ipairs(Config.ResistanceRadio.broadcastTimes) do
        if currentHour == hour and not ResistanceRadioServer.HasBroadcastThisHour() then
            ResistanceRadioServer.StartBroadcast()
            break
        end
    end
end

function ResistanceRadioServer.HasBroadcastThisHour()
    local currentTime = os.time()
    local hourAgo = currentTime - 3600 -- 1 hour in seconds
    
    return lastBroadcastTime > hourAgo
end

function ResistanceRadioServer.StartBroadcast()
    if activeBroadcast then return end
    
    local message = ResistanceRadioServer.GetRandomMessage()
    local broadcastData = {
        id = #broadcastHistory + 1,
        message = message,
        startTime = os.time(),
        duration = Config.ResistanceRadio.broadcastDuration * 60, -- Convert to seconds
        frequency = Config.ResistanceRadio.frequency
    }
    
    activeBroadcast = broadcastData
    lastBroadcastTime = os.time()
    
    -- Add to history
    table.insert(broadcastHistory, broadcastData)
    
    -- Keep only last 10 broadcasts in history
    if #broadcastHistory > 10 then
        table.remove(broadcastHistory, 1)
    end
    
    -- Log broadcast
    local DiscordLogger = exports['countryroadrp-reckoning']:DiscordLogger()
    DiscordLogger.LogResistanceBroadcast(message, false)
    
    -- Notify all players
    TriggerClientEvent('crp-reckoning:radio:startBroadcast', -1, broadcastData)
    
    -- Auto-end broadcast after duration
    CreateThread(function()
        Wait(broadcastData.duration * 1000)
        ResistanceRadioServer.EndBroadcast()
    end)
    
    -- Alert Merryweather about broadcast
    ResistanceRadioServer.AlertSecurity(broadcastData)
end

function ResistanceRadioServer.EndBroadcast()
    if not activeBroadcast then return end
    
    -- Log broadcast end
    TriggerEvent('qb-log:server:CreateLog', 'crp-reckoning', 'Resistance Broadcast End', 'blue',
        string.format('Resistance broadcast ended: ID %d', activeBroadcast.id)
    )
    
    -- Notify all players
    TriggerClientEvent('crp-reckoning:radio:endBroadcast', -1)
    
    activeBroadcast = nil
end

function ResistanceRadioServer.GetRandomMessage()
    local messages = Config.ResistanceRadio.messages
    return messages[math.random(#messages)]
end

function ResistanceRadioServer.AlertSecurity(broadcastData)
    local players = QBCore.Functions.GetQBPlayers()
    
    -- Alert Merryweather personnel about unauthorized broadcast
    for playerId, player in pairs(players) do
        if player.PlayerData.job.name == 'merryweather' then
            TriggerClientEvent('QBCore:Notify', playerId,
                string.format('SECURITY ALERT: Unauthorized broadcast detected on frequency %.3f', 
                    broadcastData.frequency
                ), 'error'
            )
            
            -- Add to their police computer/MDT if available
            TriggerEvent('crp-reckoning:security:addAlert', playerId, {
                type = 'unauthorized_broadcast',
                frequency = broadcastData.frequency,
                timestamp = os.time(),
                message = broadcastData.message
            })
        end
    end
end

-- Manual broadcast command for admins
RegisterCommand('resistancebroadcast', function(source, args)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    
    -- Check permissions (admin only)
    if not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('QBCore:Notify', src, 'No permission', 'error')
        return
    end
    
    if #args < 1 then
        TriggerClientEvent('QBCore:Notify', src, 'Usage: /resistancebroadcast <message>', 'error')
        return
    end
    
    local message = table.concat(args, ' ')
    
    -- Create custom broadcast
    local broadcastData = {
        id = #broadcastHistory + 1,
        message = message,
        startTime = os.time(),
        duration = Config.ResistanceRadio.broadcastDuration * 60,
        frequency = Config.ResistanceRadio.frequency
    }
    
    activeBroadcast = broadcastData
    table.insert(broadcastHistory, broadcastData)
    
    TriggerClientEvent('crp-reckoning:radio:startBroadcast', -1, broadcastData)
    TriggerClientEvent('QBCore:Notify', src, 'Resistance broadcast started', 'success')
    
    -- Auto-end
    CreateThread(function()
        Wait(broadcastData.duration * 1000)
        ResistanceRadioServer.EndBroadcast()
    end)
    
    ResistanceRadioServer.AlertSecurity(broadcastData)
end)

-- Command to get broadcast history
RegisterCommand('broadcasthistory', function(source, args)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    
    -- Check if player has access (Merryweather only)
    if not player or player.PlayerData.job.name ~= 'merryweather' then
        TriggerClientEvent('QBCore:Notify', src, 'Access denied', 'error')
        return
    end
    
    -- Send broadcast history
    TriggerClientEvent('crp-reckoning:radio:showHistory', src, broadcastHistory)
end)

-- Export functions
exports('GetActiveBroadcast', function()
    return activeBroadcast
end)

exports('GetBroadcastHistory', function()
    return broadcastHistory
end)

exports('TriggerEmergencyBroadcast', function(message)
    if not message or message == '' then
        print('^1[Resistance Radio] Error: Empty message provided for emergency broadcast^7')
        return false
    end
    
    if activeBroadcast then
        ResistanceRadioServer.EndBroadcast()
        Wait(1000)
    end
    
    local broadcastData = {
        id = #broadcastHistory + 1,
        message = message,
        startTime = os.time(),
        duration = 180, -- 3 minutes for emergency broadcasts
        frequency = Config.ResistanceRadio.frequency,
        emergency = true
    }
    
    activeBroadcast = broadcastData
    table.insert(broadcastHistory, broadcastData)
    
    -- Log emergency broadcast
    local DiscordLogger = exports['countryroadrp-reckoning']:DiscordLogger()
    DiscordLogger.LogResistanceBroadcast(message, true)
    
    TriggerClientEvent('crp-reckoning:radio:startBroadcast', -1, broadcastData)
    
    CreateThread(function()
        Wait(broadcastData.duration * 1000)
        ResistanceRadioServer.EndBroadcast()
    end)
    
    return true
end)

-- Initialize system
CreateThread(function()
    Wait(2000)
    ResistanceRadioServer.Initialize()
end)
