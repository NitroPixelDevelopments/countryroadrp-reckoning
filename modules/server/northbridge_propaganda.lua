local QBCore = exports['qb-core']:GetCoreObject()

local nextAnnouncementTime = 0
local propagandaHistory = {}

local NorthbridgePropaganda = {}

function NorthbridgePropaganda.Initialize()
    if not Config.NorthbridgePropaganda.enabled then return end
    
    -- Schedule first announcement
    NorthbridgePropaganda.ScheduleNextAnnouncement()
    
    -- Main propaganda loop
    CreateThread(function()
        while true do
            Wait(60000) -- Check every minute
            
            if os.time() >= nextAnnouncementTime then
                NorthbridgePropaganda.BroadcastPropaganda()
            end
        end
    end)
end

function NorthbridgePropaganda.ScheduleNextAnnouncement()
    local minInterval = Config.NorthbridgePropaganda.announcementInterval.min * 60
    local maxInterval = Config.NorthbridgePropaganda.announcementInterval.max * 60
    local randomInterval = math.random(minInterval, maxInterval)
    
    nextAnnouncementTime = os.time() + randomInterval
end

function NorthbridgePropaganda.BroadcastPropaganda()
    local message = NorthbridgePropaganda.GetRandomMessage()
    local channel = NorthbridgePropaganda.SelectChannel()
    
    local announcementData = {
        id = #propagandaHistory + 1,
        message = message,
        channel = channel,
        timestamp = os.time()
    }
    
    table.insert(propagandaHistory, announcementData)
    
    -- Keep only last 20 announcements
    if #propagandaHistory > 20 then
        table.remove(propagandaHistory, 1)
    end
    
    -- Log announcement
    local DiscordLogger = exports['countryroadrp-reckoning']:DiscordLogger()
    DiscordLogger.LogPropaganda(message, channel)
    
    -- Send to appropriate players based on channel
    if channel == 'public' then
        NorthbridgePropaganda.SendPublicAnnouncement(announcementData)
    elseif channel == 'emergency' then
        NorthbridgePropaganda.SendEmergencyAnnouncement(announcementData)
    elseif channel == 'internal' then
        NorthbridgePropaganda.SendInternalAnnouncement(announcementData)
    end
    
    -- Schedule next announcement
    NorthbridgePropaganda.ScheduleNextAnnouncement()
end

function NorthbridgePropaganda.GetRandomMessage()
    local messages = Config.NorthbridgePropaganda.publicAnnouncements
    return messages[math.random(#messages)]
end

function NorthbridgePropaganda.SelectChannel()
    local totalWeight = 0
    for _, channel in ipairs(Config.NorthbridgePropaganda.channels) do
        totalWeight = totalWeight + channel.weight
    end
    
    local roll = math.random(1, totalWeight)
    local currentWeight = 0
    
    for _, channel in ipairs(Config.NorthbridgePropaganda.channels) do
        currentWeight = currentWeight + channel.weight
        if roll <= currentWeight then
            return channel.name
        end
    end
    
    return 'public' -- Fallback
end

function NorthbridgePropaganda.SendPublicAnnouncement(announcementData)
    local players = QBCore.Functions.GetQBPlayers()
    
    -- Send to all players
    for playerId, player in pairs(players) do
        TriggerClientEvent('chat:addMessage', playerId, {
            template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(33, 150, 243, 0.2); border-left: 4px solid #2196F3;"><b>Northbridge Solutions</b><br>{0}</div>',
            args = { announcementData.message }
        })
        
        TriggerClientEvent('QBCore:Notify', playerId, 
            'Northbridge Solutions: ' .. announcementData.message, 
            'primary', 
            8000
        )
    end
end

function NorthbridgePropaganda.SendEmergencyAnnouncement(announcementData)
    local players = QBCore.Functions.GetQBPlayers()
    
    -- Send as emergency alert to all players
    for playerId, player in pairs(players) do
        TriggerClientEvent('chat:addMessage', playerId, {
            template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(255, 152, 0, 0.3); border-left: 4px solid #FF9800;"><b>NORTHBRIDGE EMERGENCY ALERT</b><br>{0}</div>',
            args = { announcementData.message }
        })
        
        TriggerClientEvent('QBCore:Notify', playerId, 
            'EMERGENCY: ' .. announcementData.message, 
            'error', 
            12000
        )
        
        -- Add screen flash for emergency alerts
        TriggerClientEvent('crp-reckoning:propaganda:emergencyFlash', playerId)
    end
end

function NorthbridgePropaganda.SendInternalAnnouncement(announcementData)
    local players = QBCore.Functions.GetQBPlayers()
    
    -- Send only to Merryweather and Northbridge personnel
    for playerId, player in pairs(players) do
        local job = player.PlayerData.job.name
        
        if job == 'merryweather' or job == 'northbridge' then
            TriggerClientEvent('chat:addMessage', playerId, {
                template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(76, 175, 80, 0.3); border-left: 4px solid #4CAF50;"><b>NORTHBRIDGE INTERNAL</b><br>{0}</div>',
                args = { announcementData.message }
            })
            
            TriggerClientEvent('QBCore:Notify', playerId, 
                'Internal: ' .. announcementData.message, 
                'success', 
                6000
            )
        end
    end
end

-- Manual propaganda command for admins
RegisterCommand('northbridgeannounce', function(source, args)
    local src = source
    
    -- Check permissions
    if not QBCore.Functions.HasPermission(src, 'admin', 'command') then
        TriggerClientEvent('QBCore:Notify', src, 'No permission', 'error')
        return
    end
    
    if #args < 2 then
        TriggerClientEvent('QBCore:Notify', src, 'Usage: /northbridgeannounce <channel> <message>', 'error')
        return
    end
    
    local channel = args[1]:lower()
    local message = table.concat(args, ' ', 2)
    
    if not (channel == 'public' or channel == 'emergency' or channel == 'internal') then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid channel. Use: public, emergency, or internal', 'error')
        return
    end
    
    local announcementData = {
        id = #propagandaHistory + 1,
        message = message,
        channel = channel,
        timestamp = os.time(),
        manual = true
    }
    
    table.insert(propagandaHistory, announcementData)
    
    if channel == 'public' then
        NorthbridgePropaganda.SendPublicAnnouncement(announcementData)
    elseif channel == 'emergency' then
        NorthbridgePropaganda.SendEmergencyAnnouncement(announcementData)
    elseif channel == 'internal' then
        NorthbridgePropaganda.SendInternalAnnouncement(announcementData)
    end
    
    TriggerClientEvent('QBCore:Notify', src, 'Northbridge announcement sent', 'success')
end)

-- Command to view propaganda history (security personnel only)
RegisterCommand('propagandahistory', function(source, args)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    
    if not player or (player.PlayerData.job.name ~= 'merryweather' and player.PlayerData.job.name ~= 'northbridge') then
        TriggerClientEvent('QBCore:Notify', src, 'Access denied', 'error')
        return
    end
    
    TriggerClientEvent('crp-reckoning:propaganda:showHistory', src, propagandaHistory)
end)

-- Export functions
exports('GetPropagandaHistory', function()
    return propagandaHistory
end)

exports('TriggerManualAnnouncement', function(message, channel)
    local announcementData = {
        id = #propagandaHistory + 1,
        message = message,
        channel = channel or 'public',
        timestamp = os.time(),
        triggered = true
    }
    
    table.insert(propagandaHistory, announcementData)
    
    if channel == 'emergency' then
        NorthbridgePropaganda.SendEmergencyAnnouncement(announcementData)
    elseif channel == 'internal' then
        NorthbridgePropaganda.SendInternalAnnouncement(announcementData)
    else
        NorthbridgePropaganda.SendPublicAnnouncement(announcementData)
    end
end)

-- Initialize system
CreateThread(function()
    Wait(3000)
    NorthbridgePropaganda.Initialize()
end)
