local QBCore = exports['qb-core']:GetCoreObject()

local activeEvents = {}
local eventCounter = 0
local nextEventTime = 0

local BlacklineEventsServer = {}

function BlacklineEventsServer.Initialize()
    if not Config.BlacklineEvents.enabled then return end
    
    -- Schedule first event
    BlacklineEventsServer.ScheduleNextEvent()
    
    -- Main event loop
    CreateThread(function()
        while true do
            Wait(60000) -- Check every minute
            
            if os.time() >= nextEventTime and #activeEvents < Config.Performance.maxActiveEvents then
                BlacklineEventsServer.TriggerRandomEvent()
            end
        end
    end)
end

function BlacklineEventsServer.ScheduleNextEvent()
    local minInterval = Config.BlacklineEvents.eventInterval.min * 60 -- Convert to seconds
    local maxInterval = Config.BlacklineEvents.eventInterval.max * 60
    local randomInterval = math.random(minInterval, maxInterval)
    
    nextEventTime = os.time() + randomInterval
end

function BlacklineEventsServer.TriggerRandomEvent()
    local players = QBCore.Functions.GetQBPlayers()
    local eligiblePlayers = {}
    
    -- Find players not in events and not in protected jobs
    for playerId, player in pairs(players) do
        if not BlacklineEventsServer.IsPlayerInEvent(playerId) and 
           not BlacklineEventsServer.IsPlayerProtected(player) then
            table.insert(eligiblePlayers, {id = playerId, player = player})
        end
    end
    
    if #eligiblePlayers == 0 then
        BlacklineEventsServer.ScheduleNextEvent()
        return
    end
    
    -- Select random player and event type
    local targetPlayer = eligiblePlayers[math.random(#eligiblePlayers)]
    local eventType = BlacklineEventsServer.SelectEventType()
    
    BlacklineEventsServer.StartEvent(targetPlayer.id, eventType)
    BlacklineEventsServer.ScheduleNextEvent()
end

function BlacklineEventsServer.SelectEventType()
    local totalChance = 0
    for _, eventType in ipairs(Config.BlacklineEvents.eventTypes) do
        totalChance = totalChance + eventType.chance
    end
    
    local roll = math.random(1, totalChance)
    local currentChance = 0
    
    for _, eventType in ipairs(Config.BlacklineEvents.eventTypes) do
        currentChance = currentChance + eventType.chance
        if roll <= currentChance then
            return eventType
        end
    end
    
    return Config.BlacklineEvents.eventTypes[1] -- Fallback
end

function BlacklineEventsServer.StartEvent(playerId, eventType)
    eventCounter = eventCounter + 1
    
    local eventData = {
        id = eventCounter,
        playerId = playerId,
        type = eventType.type,
        duration = eventType.duration,
        startTime = os.time()
    }
    
    activeEvents[eventCounter] = eventData
    
    -- Log event
    local player = QBCore.Functions.GetPlayer(playerId)
    if player then
        TriggerEvent('qb-log:server:CreateLog', 'crp-reckoning', 'Blackline Event', 'orange',
            string.format('Blackline %s event started for %s (%s)', 
                eventType.type, 
                player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
                player.PlayerData.citizenid
            )
        )
    end
    
    -- Trigger client event
    TriggerClientEvent('crp-reckoning:blackline:startEvent', playerId, eventData)
    
    -- Auto-cleanup after duration + buffer
    CreateThread(function()
        Wait((eventType.duration + 30) * 1000)
        BlacklineEventsServer.EndEvent(eventCounter, true)
    end)
end

function BlacklineEventsServer.EndEvent(eventId, timeout)
    local eventData = activeEvents[eventId]
    if not eventData then return end
    
    local player = QBCore.Functions.GetPlayer(eventData.playerId)
    if player then
        TriggerClientEvent('crp-reckoning:blackline:endEvent', eventData.playerId)
        
        -- Log event end
        TriggerEvent('qb-log:server:CreateLog', 'crp-reckoning', 'Blackline Event End', 'blue',
            string.format('Blackline %s event ended for %s (%s) - %s', 
                eventData.type,
                player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
                player.PlayerData.citizenid,
                timeout and 'timeout' or 'completed'
            )
        )
    end
    
    activeEvents[eventId] = nil
end

function BlacklineEventsServer.IsPlayerInEvent(playerId)
    for _, eventData in pairs(activeEvents) do
        if eventData.playerId == playerId then
            return true
        end
    end
    return false
end

function BlacklineEventsServer.IsPlayerProtected(player)
    if not player or not player.PlayerData then return true end
    
    local job = player.PlayerData.job.name
    
    -- Protect Merryweather and Northbridge employees
    if job == 'merryweather' or job == 'northbridge' then
        return true
    end
    
    -- Protect players in tunnels
    if exports['countryroadrp-reckoning']:IsPlayerInTunnel(player.PlayerData.source) then
        return true
    end
    
    return false
end

-- Event handlers
RegisterNetEvent('crp-reckoning:blackline:triggerEvent', function(playerId, eventType)
    local eventTypeData = nil
    for _, et in ipairs(Config.BlacklineEvents.eventTypes) do
        if et.type == eventType then
            eventTypeData = et
            break
        end
    end
    
    if eventTypeData then
        BlacklineEventsServer.StartEvent(playerId, eventTypeData)
    end
end)

RegisterNetEvent('crp-reckoning:blackline:eventTimeout', function(eventId)
    BlacklineEventsServer.EndEvent(eventId, true)
end)

RegisterNetEvent('crp-reckoning:blackline:playerDetained', function()
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    
    if not player then return end
    
    -- Find active event for this player
    local eventData = nil
    for _, event in pairs(activeEvents) do
        if event.playerId == src then
            eventData = event
            break
        end
    end
    
    if eventData and eventData.type == 'interrogation' then
        TriggerClientEvent('crp-reckoning:blackline:showInterrogationScreen', src)
        
        -- Log detention
        TriggerEvent('qb-log:server:CreateLog', 'crp-reckoning', 'Player Detained', 'red',
            string.format('%s (%s) has been detained for interrogation', 
                player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
                player.PlayerData.citizenid
            )
        )
    end
end)

-- Export functions
exports('GetActiveEvents', function()
    return activeEvents
end)

exports('TriggerEventForPlayer', function(playerId, eventType)
    TriggerEvent('crp-reckoning:blackline:triggerEvent', playerId, eventType)
end)

exports('EndEventForPlayer', function(playerId)
    for eventId, eventData in pairs(activeEvents) do
        if eventData.playerId == playerId then
            BlacklineEventsServer.EndEvent(eventId, false)
            break
        end
    end
end)

-- Initialize system
CreateThread(function()
    Wait(5000) -- Wait for other systems to load
    BlacklineEventsServer.Initialize()
end)
