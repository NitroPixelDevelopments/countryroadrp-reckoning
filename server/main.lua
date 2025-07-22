-- Load config.lua if not already loaded
Config = Config or {}
local configFile = LoadResourceFile(GetCurrentResourceName(), "config.lua")
if configFile then
    local chunk = load(configFile)
    if chunk then chunk() end
end

local QBCore = exports['qb-core']:GetCoreObject()

-- Main server initialization
-- Server-wide event tracking
local milestoneProgress = {
    ghost_division_deployment = {
        triggered = false,
        triggerCount = 0,
        requiredTriggers = 5
    }
}

CreateThread(function()
    while GetResourceState('qb-core') ~= 'started' do
        Wait(1000)
    end
    
    -- Initialize main server systems
    print('^2[Country Road RP - Reckoning]^7 Starting Season 1 narrative systems...')
    
    -- Server event handlers
    RegisterNetEvent('crp-reckoning:server:triggerMilestone', function(milestoneName)
        local milestone = milestoneProgress[milestoneName]
        if not milestone or milestone.triggered then return end
        
        milestone.triggerCount = milestone.triggerCount + 1
        
        local DiscordLogger = exports['countryroadrp-reckoning']:DiscordLogger()
        DiscordLogger.LogMilestone(milestoneName, milestone.triggerCount, milestone.requiredTriggers)
        
        -- Check if milestone should be triggered
        if milestone.triggerCount >= milestone.requiredTriggers then
            TriggerMilestone(milestoneName, milestone)
        end
    end)
    
    function TriggerMilestone(milestoneName, milestone)
        milestone.triggered = true
        
        TriggerEvent('qb-log:server:CreateLog', 'crp-reckoning', 'Milestone Triggered', 'red',
            string.format('MILESTONE ACTIVATED: %s', milestoneName)
        )
        
        if milestoneName == 'ghost_division_deployment' then
            HandleGhostDivisionDeployment()
        end
    end
    
    function HandleGhostDivisionDeployment()
        local players = QBCore.Functions.GetQBPlayers()
        
        -- Global server announcement
        for playerId, player in pairs(players) do
            TriggerClientEvent('QBCore:Notify', playerId,
                'EMERGENCY BROADCAST: All communications are now monitored. Comply with security directives.',
                'error',
                10000
            )
        end
        
        -- Apply lockdown effects from config
        local config = Config.ServerEvents.milestones[1] -- ghost_division_deployment
        if config and config.effects then
            -- Disable radios globally
            if config.effects.disableRadios then
                TriggerClientEvent('crp-reckoning:server:disableRadios', -1)
            end
            
            -- Increase security presence
            if config.effects.increaseSecurity then
                TriggerEvent('crp-reckoning:server:increaseSecurityLevel')
            end
            
            -- Activate lockdown zones
            if config.effects.lockdownZones then
                for _, zone in ipairs(config.effects.lockdownZones) do
                    TriggerClientEvent('crp-reckoning:server:activateLockdown', -1, zone)
                end
            end
        end
        
        -- Emergency resistance broadcast
        exports['countryroadrp-reckoning']:TriggerEmergencyBroadcast(
            'GHOST DIVISION DEPLOYED. ALL CITIZENS REPORT TO DESIGNATED AREAS. THE BLACKLINE PROTOCOL IS NOW ACTIVE.'
        )
    end
    
    -- Resource cleanup on stop
    AddEventHandler('onResourceStop', function(resourceName)
        if resourceName == GetCurrentResourceName() then
            print('^1[Country Road RP - Reckoning]^7 Shutting down narrative systems...')
            
            -- Clean up any spawned entities
            TriggerClientEvent('crp-reckoning:server:cleanup', -1)
        end
    end)
    
    -- Status command for administrators
    RegisterCommand('reckoningstatus', function(source, args, rawCommand)
        local src = source

        if not QBCore.Functions.HasPermission(src, 'admin') then
            TriggerClientEvent('QBCore:Notify', src, 'No permission', 'error', 5000)
            return
        end

        local status = {
            tunnelSystem = Config.TunnelSystem.enabled,
            blacklineEvents = Config.BlacklineEvents.enabled,
            resistanceRadio = Config.ResistanceRadio.enabled,
            npcHandlers = Config.NPCHandlers.enabled,
            accessControl = Config.AccessControl.enabled,
            milestones = milestoneProgress
        }

        print('[reckoningstatus] Sending status:', json.encode(status)) -- Debug print

        TriggerClientEvent('crp-reckoning:server:showStatus', src, status)
    end)
    
    print('^2[Country Road RP - Reckoning]^7 Season 1 narrative systems started successfully!')
end)

-- Export main server functions
exports('GetMilestoneProgress', function()
    return milestoneProgress
end)

exports('TriggerServerMilestone', function(milestoneName)
    TriggerEvent('crp-reckoning:server:triggerMilestone', milestoneName)
end)
