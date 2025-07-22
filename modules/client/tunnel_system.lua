local QBCore = exports['qb-core']:GetCoreObject()
local inTunnel = false
local tunnelEffects = {}
local originalWeather = nil

-- Main tunnel system handler
local TunnelSystem = {}

function TunnelSystem.Initialize()
    if not Config.TunnelSystem.enabled then return end
    
    CreateThread(function()
        while true do
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local wasInTunnel = inTunnel
            inTunnel = false
            
            -- Check if player is in any tunnel zone
            for _, point in ipairs(Config.TunnelSystem.tunnelPoints) do
                local distance = #(playerCoords - point.coords)
                if distance <= point.radius then
                    inTunnel = true
                    break
                end
            end
            
            -- Handle tunnel entry/exit
            if inTunnel and not wasInTunnel then
                TunnelSystem.EnterTunnel()
            elseif not inTunnel and wasInTunnel then
                TunnelSystem.ExitTunnel()
            end
            
            -- Apply tunnel effects while inside
            if inTunnel then
                TunnelSystem.ApplyTunnelEffects()
            end
            
            Wait(1000)
        end
    end)
end

function TunnelSystem.EnterTunnel()
    local playerData = QBCore.Functions.GetPlayerData()
    
    -- Check access permissions
    if not TunnelSystem.HasAccess(playerData) then
        QBCore.Functions.Notify('This area is restricted.', 'error')
        TriggerServerEvent('crp-reckoning:tunnel:unauthorizedAccess', GetEntityCoords(PlayerPedId()))
        return
    end
    
    -- Store original weather and time
    originalWeather = GetWeatherTypeTransition()
    
    -- Apply tunnel effects
    if Config.TunnelSystem.effects.enableFog then
        SetWeatherTypeNow('FOGGY')
        SetWeatherTypeOvertimePersist('FOGGY', 1.0)
    end
    
    -- Disable GPS and radar
    if Config.TunnelSystem.effects.disableGPS then
        DisplayRadar(false)
    end
    
    -- Adjust ambient lighting
    SetArtificialLightsState(true)
    SetArtificialLightsStateAffectsVehicles(false)
    
    -- Trigger particle effects
    if Config.TunnelSystem.effects.enableParticles then
        TunnelSystem.StartParticleEffects()
    end
    
    -- Notify server
    TriggerServerEvent('crp-reckoning:tunnel:entered')
    
    QBCore.Functions.Notify('Entering TRENCHGLASS corridor...', 'primary')
end

function TunnelSystem.ExitTunnel()
    -- Restore original effects
    if originalWeather then
        SetWeatherTypeOvertimePersist(originalWeather, 2.0)
    end
    
    DisplayRadar(true)
    SetArtificialLightsState(false)
    
    -- Stop particle effects
    TunnelSystem.StopParticleEffects()
    
    -- Notify server
    TriggerServerEvent('crp-reckoning:tunnel:exited')
    
    QBCore.Functions.Notify('Exiting TRENCHGLASS corridor...', 'primary')
end

function TunnelSystem.ApplyTunnelEffects()
    local playerPed = PlayerPedId()
    
    -- Apply fog density
    if Config.TunnelSystem.effects.enableFog then
        SetRainLevel(0.0)
        SetSnowLevel(0.0)
    end
    
    -- Reduce visibility
    SetTimecycleModifier('tunnel')
    SetTimecycleModifierStrength(Config.TunnelSystem.effects.ambientLight)
end

function TunnelSystem.HasAccess(playerData)
    if not playerData or not playerData.job then return false end
    
    local job = playerData.job.name
    local grade = playerData.job.grade.name
    
    -- Check if job is authorized
    for _, authorizedJob in ipairs(Config.TunnelSystem.accessJobs) do
        if job == authorizedJob then
            -- Check if rank is authorized for this job
            local authorizedRanks = Config.TunnelSystem.accessRanks[job]
            if authorizedRanks then
                for _, rank in ipairs(authorizedRanks) do
                    if grade == rank then
                        return true
                    end
                end
            end
        end
    end
    
    return false
end

function TunnelSystem.StartParticleEffects()
    local playerCoords = GetEntityCoords(PlayerPedId())
    
    RequestNamedPtfxAsset('scr_ie_tw')
    while not HasNamedPtfxAssetLoaded('scr_ie_tw') do
        Wait(10)
    end
    
    tunnelEffects.particles = StartParticleFxLoopedAtCoord(
        'scr_ie_tw_take_zone', 
        playerCoords.x, playerCoords.y, playerCoords.z + 2.0, 
        0.0, 0.0, 0.0, 
        1.0, false, false, false, false
    )
end

function TunnelSystem.StopParticleEffects()
    if tunnelEffects.particles then
        StopParticleFxLooped(tunnelEffects.particles, false)
        tunnelEffects.particles = nil
    end
    
    RemoveNamedPtfxAsset('scr_ie_tw')
    ClearTimecycleModifier()
end

-- Export functions
exports('GetTunnelSystem', function()
    return TunnelSystem
end)

exports('IsPlayerInTunnel', function()
    return inTunnel
end)

-- Initialize system
CreateThread(function()
    Wait(1000) -- Wait for QBCore to load
    TunnelSystem.Initialize()
end)
