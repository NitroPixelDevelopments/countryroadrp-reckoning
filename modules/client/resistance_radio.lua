local QBCore = exports['qb-core']:GetCoreObject()
local radioActive = false
local currentBroadcast = nil
local signalStrength = 0.0

local ResistanceRadio = {}

function ResistanceRadio.Initialize()
    if not Config.ResistanceRadio.enabled then return end
    
    -- Listen for broadcast events
    RegisterNetEvent('crp-reckoning:radio:startBroadcast', ResistanceRadio.StartBroadcast)
    RegisterNetEvent('crp-reckoning:radio:endBroadcast', ResistanceRadio.EndBroadcast)
    
    -- Monitor signal strength
    CreateThread(function()
        while true do
            if radioActive then
                ResistanceRadio.UpdateSignalStrength()
            end
            Wait(2000)
        end
    end)
    
    -- Register command for tuning radio
    RegisterCommand('tuneradio', function(source, args)
        if args[1] then
            local frequency = tonumber(args[1])
            if frequency then
                ResistanceRadio.TuneToFrequency(frequency)
            end
        end
    end)
end

function ResistanceRadio.StartBroadcast(broadcastData)
    currentBroadcast = broadcastData
    radioActive = true
    
    -- Check if player can receive signal
    local canReceive, strength = ResistanceRadio.CanReceiveSignal()
    
    if canReceive then
        signalStrength = strength
        ResistanceRadio.PlayBroadcast(broadcastData, strength)
    end
end

function ResistanceRadio.EndBroadcast()
    radioActive = false
    currentBroadcast = nil
    signalStrength = 0.0
    
    -- Stop any playing audio
    ResistanceRadio.StopBroadcast()
end

function ResistanceRadio.PlayBroadcast(broadcastData, strength)
    -- Apply static based on signal strength
    local staticLevel = (1.0 - strength) * 0.7
    
    QBCore.Functions.Notify(
        string.format('[STATIC] %s [STATIC]', broadcastData.message), 
        'primary', 
        broadcastData.duration * 1000
    )
    
    -- Visual effects for poor signal
    if strength < 0.5 then
        ResistanceRadio.ApplyStaticEffects(staticLevel)
    end
    
    -- Add to chat with resistance styling
    TriggerEvent('chat:addMessage', {
        template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(76, 175, 80, 0.2); border-left: 4px solid #4CAF50;"><b>The Resistance</b><br>{0}</div>',
        args = { broadcastData.message }
    })
end

function ResistanceRadio.StopBroadcast()
    -- Clear any visual effects
    ClearTimecycleModifier()
    SetTransitionTimecycleModifier('default', 1.0)
end

function ResistanceRadio.ApplyStaticEffects(staticLevel)
    -- Apply screen distortion for static
    SetTimecycleModifier('hud_def_blur')
    SetTimecycleModifierStrength(staticLevel)
    
    -- Screen shake for heavy static
    if staticLevel > 0.5 then
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', staticLevel * 0.3)
    end
end

function ResistanceRadio.CanReceiveSignal()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local bestStrength = 0.0
    local canReceive = false
    
    -- Check signal zones
    for _, zone in ipairs(Config.ResistanceRadio.signalZones) do
        local distance = #(playerCoords - zone.coords)
        
        if distance <= zone.radius then
            local strength = zone.strength * (1.0 - (distance / zone.radius))
            if strength > bestStrength then
                bestStrength = strength
                canReceive = true
            end
        end
    end
    
    -- Weather affects signal strength
    local weather = GetWeatherTypeTransition()
    if weather == GetHashKey('THUNDER') or weather == GetHashKey('RAIN') then
        bestStrength = bestStrength * 0.7
    end
    
    -- Vehicle affects reception
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        bestStrength = bestStrength * 0.8
    end
    
    return canReceive, bestStrength
end

function ResistanceRadio.UpdateSignalStrength()
    if not currentBroadcast then return end
    
    local canReceive, strength = ResistanceRadio.CanReceiveSignal()
    
    if not canReceive and signalStrength > 0 then
        -- Lost signal
        QBCore.Functions.Notify('Signal lost...', 'error')
        ResistanceRadio.StopBroadcast()
        signalStrength = 0.0
    elseif canReceive and signalStrength == 0 then
        -- Gained signal
        QBCore.Functions.Notify('Signal acquired...', 'success')
        ResistanceRadio.PlayBroadcast(currentBroadcast, strength)
        signalStrength = strength
    elseif canReceive then
        -- Update signal strength
        local strengthChange = math.abs(strength - signalStrength)
        if strengthChange > 0.2 then
            signalStrength = strength
            ResistanceRadio.ApplyStaticEffects((1.0 - strength) * 0.5)
        end
    end
end

function ResistanceRadio.TuneToFrequency(frequency)
    if math.abs(frequency - Config.ResistanceRadio.frequency) < 0.1 then
        QBCore.Functions.Notify('Frequency locked: ' .. Config.ResistanceRadio.frequency, 'success')
        
        -- If there's an active broadcast, start receiving it
        if radioActive then
            local canReceive, strength = ResistanceRadio.CanReceiveSignal()
            if canReceive then
                ResistanceRadio.PlayBroadcast(currentBroadcast, strength)
            end
        end
    else
        QBCore.Functions.Notify('No signal on frequency: ' .. frequency, 'error')
    end
end

-- Export functions
exports('GetCurrentBroadcast', function()
    return currentBroadcast
end)

exports('GetSignalStrength', function()
    return signalStrength
end)

exports('IsRadioActive', function()
    return radioActive
end)

-- Initialize system
CreateThread(function()
    Wait(1000)
    ResistanceRadio.Initialize()
end)
