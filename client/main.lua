local QBCore = exports['qb-core']:GetCoreObject()

-- Main client initialization
CreateThread(function()
    while not LocalPlayer.state.isLoggedIn do
        Wait(1000)
    end
    
    print('^2[Country Road RP - Reckoning]^7 Loading Season 1 client systems...')
    
    -- Global client state
    local systemState = {
        radiosDisabled = false,
        lockdownActive = false,
        securityLevel = 1
    }
    
    -- Admin Panel Support - Make API calls available to NUI
    RegisterNUICallback('adminAPI', function(data, cb)
        local action = data.action
        local params = data.params or {}
        
        if action == 'authenticate' then
            TriggerServerEvent('crp-reckoning:admin:authenticate', params.playerId, params.token)
        elseif action == 'getDashboard' then
            TriggerServerEvent('crp-reckoning:admin:getDashboard', params.sessionId)
        elseif action == 'getPlayers' then
            TriggerServerEvent('crp-reckoning:admin:getPlayers', params.sessionId, params.page, params.limit)
        elseif action == 'getSecurityEvents' then
            TriggerServerEvent('crp-reckoning:admin:getSecurityEvents', params.sessionId, params.page, params.limit, params.severity, params.citizenid)
        elseif action == 'getTunnelActivity' then
            TriggerServerEvent('crp-reckoning:admin:getTunnelActivity', params.sessionId, params.page, params.limit)
        elseif action == 'getPlayerDetails' then
            TriggerServerEvent('crp-reckoning:admin:getPlayerDetails', params.sessionId, params.citizenid)
        elseif action == 'playerAction' then
            TriggerServerEvent('crp-reckoning:admin:playerAction', params.sessionId, params.action, params.citizenid, params.params)
        elseif action == 'triggerEvent' then
            TriggerServerEvent('crp-reckoning:admin:triggerEvent', params.sessionId, params.eventType, params.params)
        end
        
        cb({success = true})
    end)
    
    -- Admin Panel Response Handlers
    RegisterNetEvent('crp-reckoning:admin:authResult', function(data)
        SendNUIMessage({type = 'authResult', data = data})
    end)
    
    RegisterNetEvent('crp-reckoning:admin:dashboardResult', function(data)
        SendNUIMessage({type = 'dashboardResult', data = data})
    end)
    
    RegisterNetEvent('crp-reckoning:admin:playersResult', function(data)
        SendNUIMessage({type = 'playersResult', data = data})
    end)
    
    RegisterNetEvent('crp-reckoning:admin:securityEventsResult', function(data)
        SendNUIMessage({type = 'securityEventsResult', data = data})
    end)
    
    RegisterNetEvent('crp-reckoning:admin:tunnelActivityResult', function(data)
        SendNUIMessage({type = 'tunnelActivityResult', data = data})
    end)
    
    RegisterNetEvent('crp-reckoning:admin:playerDetailsResult', function(data)
        SendNUIMessage({type = 'playerDetailsResult', data = data})
    end)
    
    RegisterNetEvent('crp-reckoning:admin:playerActionResult', function(data)
        SendNUIMessage({type = 'playerActionResult', data = data})
    end)
    
    RegisterNetEvent('crp-reckoning:admin:triggerEventResult', function(data)
        SendNUIMessage({type = 'triggerEventResult', data = data})
    end)
    
    -- Main client event handlers
    RegisterNetEvent('crp-reckoning:server:disableRadios', function()
        systemState.radiosDisabled = true
        QBCore.Functions.Notify('All radio communications have been disabled by security directive.', 'error', 8000)
        
        -- Disable radio functionality
        exports['pma-voice']:setRadioEnabled(false)
    end)
    
    RegisterNetEvent('crp-reckoning:server:activateLockdown', function(zone)
        systemState.lockdownActive = true
        
        QBCore.Functions.Notify(
            string.format('LOCKDOWN ACTIVE: %s is now under martial law.', zone.coords), 
            'error', 
            10000
        )
        
        -- Visual effects for lockdown
        CreateThread(function()
            local startTime = GetGameTimer()
            while GetGameTimer() - startTime < 30000 do -- 30 seconds of effects
                -- Screen flash effect
                SetFlash(0, 0, 100, 500, 100)
                Wait(2000)
            end
        end)
    end)
    
    RegisterNetEvent('crp-reckoning:server:increaseSecurityLevel', function()
        systemState.securityLevel = 3
        
        QBCore.Functions.Notify('Security level has been elevated to maximum. Comply with all directives.', 'error', 8000)
        
        -- Increase wanted level for any criminal activity
        CreateThread(function()
            while systemState.securityLevel >= 3 do
                local playerPed = PlayerPedId()
                if GetPlayerWantedLevel(PlayerId()) > 0 then
                    SetPlayerWantedLevel(PlayerId(), 5, false)
                    SetPlayerWantedLevelNow(PlayerId(), false)
                end
                Wait(5000)
            end
        end)
    end)
    
    RegisterNetEvent('crp-reckoning:server:cleanup', function()
        print('^1[Country Road RP - Reckoning]^7 Cleaning up client systems...')
        
        -- Re-enable radios
        if systemState.radiosDisabled then
            exports['pma-voice']:setRadioEnabled(true)
        end
        
        -- Clear any visual effects
        ClearTimecycleModifier()
        DisplayRadar(true)
        SetArtificialLightsState(false)
        
        -- Reset system state
        systemState = {
            radiosDisabled = false,
            lockdownActive = false,
            securityLevel = 1
        }
    end)
    
    RegisterNetEvent('crp-reckoning:server:showStatus', function(status)
        -- Display admin status information
        SendNUIMessage({
            type = 'showStatus',
            data = status
        })
    end)
    
    RegisterNetEvent('crp-reckoning:security:setWaypoint', function(coords)
        SetNewWaypoint(coords.x, coords.y, coords.z)
        QBCore.Functions.Notify('Security waypoint set.', 'primary')
    end)
    
    RegisterNetEvent('crp-reckoning:npc:setResponseWaypoint', function(coords)
        SetNewWaypoint(coords.x, coords.y, coords.z)
        QBCore.Functions.Notify('Response location marked.', 'error')
    end)
    
    -- Debug command for testing systems
    if Config.Debug then
        RegisterCommand('reckoningtest', function(args)
            if #args < 1 then
                print('Usage: /reckoningtest <system>')
                print('Available systems: tunnel, blackline, radio, npc, access')
                return
            end
            
            local system = args[1]:lower()
            
            if system == 'tunnel' then
                local tunnelSystem = exports['countryroadrp-reckoning']:GetTunnelSystem()
                if tunnelSystem then
                    print('Tunnel system active:', exports['countryroadrp-reckoning']:IsPlayerInTunnel())
                end
            elseif system == 'blackline' then
                print('Active blackline event:', exports['countryroadrp-reckoning']:IsEventActive())
            elseif system == 'radio' then
                print('Radio active:', exports['countryroadrp-reckoning']:IsRadioActive())
                print('Signal strength:', exports['countryroadrp-reckoning']:GetSignalStrength())
            elseif system == 'npc' then
                local civilians = exports['countryroadrp-reckoning']:GetSpawnedCivilians()
                print('Spawned civilians:', #civilians)
            elseif system == 'access' then
                print('Player clearance:', exports['countryroadrp-reckoning']:GetPlayerClearance())
                print('In restricted zone:', exports['countryroadrp-reckoning']:IsInRestrictedZone())
            end
        end)
    end
    
    -- Main system monitoring loop
    CreateThread(function()
        while true do
            -- Monitor system health
            local activeModules = 0
            
            if Config.TunnelSystem.enabled then activeModules = activeModules + 1 end
            if Config.BlacklineEvents.enabled then activeModules = activeModules + 1 end
            if Config.ResistanceRadio.enabled then activeModules = activeModules + 1 end
            if Config.NPCHandlers.enabled then activeModules = activeModules + 1 end
            if Config.AccessControl.enabled then activeModules = activeModules + 1 end
            
            -- Performance monitoring
            if Config.Debug then
                local memUsage = GetResourceKvpString('memory_usage') or '0'
                if tonumber(memUsage) > 50 then -- MB threshold
                    print('^3[Country Road RP - Reckoning]^7 High memory usage detected:', memUsage, 'MB')
                end
            end
            
            Wait(60000) -- Check every minute
        end
    end)
    
    print('^2[Country Road RP - Reckoning]^7 Client systems loaded successfully!')
end)

-- Export main client functions
exports('GetSystemState', function()
    return systemState
end)

exports('IsSystemActive', function(systemName)
    local configMap = {
        tunnel = Config.TunnelSystem.enabled,
        blackline = Config.BlacklineEvents.enabled,
        radio = Config.ResistanceRadio.enabled,
        npc = Config.NPCHandlers.enabled,
        access = Config.AccessControl.enabled
    }
    
    return configMap[systemName] or false
end)
