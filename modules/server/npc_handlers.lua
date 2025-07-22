local QBCore = exports['qb-core']:GetCoreObject()

local exposureIncidents = {}
local reinforcementUnits = {}

local NPCHandlersServer = {}

function NPCHandlersServer.Initialize()
    if not Config.NPCHandlers.enabled then return end
    
    -- Clean up old incidents periodically
    CreateThread(function()
        while true do
            Wait(Config.Performance.cleanupInterval)
            NPCHandlersServer.CleanupOldIncidents()
        end
    end)
end

function NPCHandlersServer.CleanupOldIncidents()
    local currentTime = os.time()
    
    for incidentId, incident in pairs(exposureIncidents) do
        if currentTime - incident.timestamp > 1800 then -- 30 minutes old
            exposureIncidents[incidentId] = nil
        end
    end
    
    -- Clean up reinforcement units
    for unitId, unit in pairs(reinforcementUnits) do
        if currentTime - unit.deployedAt > 600 then -- 10 minutes old
            reinforcementUnits[unitId] = nil
        end
    end
end

-- Event handlers
RegisterNetEvent('crp-reckoning:npc:agentExposed', function(coords)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    
    if not player then return end
    
    local incidentId = #exposureIncidents + 1
    local incident = {
        id = incidentId,
        playerId = src,
        playerName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
        citizenid = player.PlayerData.citizenid,
        coords = coords,
        timestamp = os.time()
    }
    
    exposureIncidents[incidentId] = incident
    
    -- Log the incident
    TriggerEvent('qb-log:server:CreateLog', 'crp-reckoning', 'Agent Exposed', 'red',
        string.format('Northbridge agent exposed by %s (%s) at %s', 
            incident.playerName, 
            incident.citizenid, 
            coords
        )
    )
    
    -- Deploy reinforcements
    NPCHandlersServer.DeployReinforcements(incident)
    
    -- Alert command structure
    NPCHandlersServer.AlertCommand(incident)
end)

function NPCHandlersServer.DeployReinforcements(incident)
    local deploymentData = {
        incidentId = incident.id,
        targetCoords = incident.coords,
        deployedAt = os.time(),
        units = {}
    }
    
    -- Calculate deployment distance
    local deploymentRadius = Config.NPCHandlers.exposureResponse.alertRadius
    
    -- Deploy reinforcement units
    for i = 1, Config.NPCHandlers.exposureResponse.reinforcementUnits do
        local unitData = {
            id = i,
            vehicle = Config.NPCHandlers.exposureResponse.reinforcementVehicles[math.random(#Config.NPCHandlers.exposureResponse.reinforcementVehicles)],
            eta = Config.NPCHandlers.exposureResponse.responseTime,
            status = 'en_route'
        }
        
        table.insert(deploymentData.units, unitData)
    end
    
    reinforcementUnits[incident.id] = deploymentData
    
    -- Notify all Merryweather personnel
    local players = QBCore.Functions.GetQBPlayers()
    for playerId, player in pairs(players) do
        if player.PlayerData.job.name == 'merryweather' then
            TriggerClientEvent('crp-reckoning:npc:reinforcementDeployed', playerId, deploymentData)
        end
    end
    
    -- Trigger client-side reinforcement spawning for nearby players
    TriggerClientEvent('crp-reckoning:npc:spawnReinforcements', -1, deploymentData)
    
    -- Schedule arrival
    CreateThread(function()
        Wait(Config.NPCHandlers.exposureResponse.responseTime * 1000)
        NPCHandlersServer.ReinforcementsArrived(incident.id)
    end)
end

function NPCHandlersServer.ReinforcementsArrived(incidentId)
    local deployment = reinforcementUnits[incidentId]
    if not deployment then return end
    
    local incident = exposureIncidents[incidentId]
    if not incident then return end
    
    -- Update unit status
    for _, unit in ipairs(deployment.units) do
        unit.status = 'arrived'
    end
    
    -- Log arrival
    TriggerEvent('qb-log:server:CreateLog', 'crp-reckoning', 'Reinforcements Arrived', 'orange',
        string.format('Reinforcement units arrived at incident %d (%s)', 
            incidentId, 
            deployment.targetCoords
        )
    )
    
    -- Notify nearby players
    TriggerClientEvent('crp-reckoning:npc:reinforcementsArrived', -1, deployment)
    
    -- Trigger Blackline event for the player who exposed the agent
    if incident.playerId then
        TriggerEvent('crp-reckoning:blackline:triggerEvent', incident.playerId, 'interrogation')
    end
end

function NPCHandlersServer.AlertCommand(incident)
    local players = QBCore.Functions.GetQBPlayers()
    
    -- Alert all authorized personnel
    for playerId, player in pairs(players) do
        local job = player.PlayerData.job.name
        local rank = player.PlayerData.job.grade.name
        
        if job == 'merryweather' or job == 'northbridge' then
            local alertLevel = 'error'
            local message = ''
            
            if job == 'northbridge' then
                message = string.format('SECURITY BREACH: Agent compromised at %s. Lockdown protocols activated.', 
                    incident.coords
                )
            else
                message = string.format('DEPLOYMENT ORDER: Respond to security incident at %s. Code Red.', 
                    incident.coords
                )
            end
            
            TriggerClientEvent('QBCore:Notify', playerId, message, alertLevel)
            
            -- Add waypoint for response teams
            if job == 'merryweather' then
                TriggerClientEvent('crp-reckoning:npc:setResponseWaypoint', playerId, incident.coords)
            end
        end
    end
    
    -- Escalate to server event system if multiple exposures
    local recentExposures = 0
    local currentTime = os.time()
    
    for _, exp in pairs(exposureIncidents) do
        if currentTime - exp.timestamp < 3600 then -- Last hour
            recentExposures = recentExposures + 1
        end
    end
    
    if recentExposures >= 3 then
        TriggerEvent('crp-reckoning:server:triggerMilestone', 'ghost_division_deployment')
    end
end

-- Command to view current incidents (Merryweather only)
RegisterCommand('incidents', function(source, args)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    
    if not player or player.PlayerData.job.name ~= 'merryweather' then
        TriggerClientEvent('QBCore:Notify', src, 'Access denied', 'error')
        return
    end
    
    TriggerClientEvent('crp-reckoning:npc:showIncidents', src, exposureIncidents, reinforcementUnits)
end)

-- Manual reinforcement deployment command
RegisterCommand('deployreinforcements', function(source, args)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    
    if not player or player.PlayerData.job.name ~= 'merryweather' or player.PlayerData.job.grade.level < 2 then
        TriggerClientEvent('QBCore:Notify', src, 'Insufficient clearance', 'error')
        return
    end
    
    if #args < 3 then
        TriggerClientEvent('QBCore:Notify', src, 'Usage: /deployreinforcements <x> <y> <z>', 'error')
        return
    end
    
    local coords = vector3(tonumber(args[1]), tonumber(args[2]), tonumber(args[3]))
    
    -- Create manual incident
    local incidentId = #exposureIncidents + 1
    local incident = {
        id = incidentId,
        playerId = nil, -- Manual deployment
        playerName = 'Manual Deployment',
        citizenid = 'SYSTEM',
        coords = coords,
        timestamp = os.time(),
        manual = true
    }
    
    exposureIncidents[incidentId] = incident
    NPCHandlersServer.DeployReinforcements(incident)
    
    TriggerClientEvent('QBCore:Notify', src, 'Reinforcements deployed', 'success')
end)

-- Export functions
exports('GetExposureIncidents', function()
    return exposureIncidents
end)

exports('GetActiveReinforcements', function()
    return reinforcementUnits
end)

exports('TriggerAgentExposure', function(playerId, coords)
    TriggerEvent('crp-reckoning:npc:agentExposed', coords)
end)

-- Initialize system
CreateThread(function()
    Wait(2000)
    NPCHandlersServer.Initialize()
end)
