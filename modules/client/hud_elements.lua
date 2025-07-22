-- HUD Elements for Country Road RP: Reckoning
local QBCore = exports['qb-core']:GetCoreObject()

local HUDElements = {}
local isHUDVisible = true
local playerData = {}
local hudConfig = {
    showSuspicion = true,
    showClearance = true,
    showTunnelProximity = true,
    showSecurityLevel = true,
    showRadioStatus = true,
    position = {x = 20, y = 200}
}

-- Initialize HUD system
CreateThread(function()
    while not LocalPlayer.state.isLoggedIn do
        Wait(1000)
    end
    
    HUDElements.Initialize()
end)

function HUDElements.Initialize()
    print('^2[Reckoning] HUD Elements system loaded^7')
    
    -- Create NUI callbacks
    RegisterNUICallback('toggleHUD', function(data, cb)
        isHUDVisible = data.visible
        cb({success = true})
    end)
    
    RegisterNUICallback('updateHUDConfig', function(data, cb)
        hudConfig = data.config
        cb({success = true})
    end)
    
    -- Register commands for HUD control
    RegisterCommand('hud_toggle', function()
        HUDElements.ToggleHUD()
    end, false)
    
    RegisterCommand('hud_config', function()
        HUDElements.OpenHUDConfig()
    end, false)
    
    -- Start HUD update loop
    CreateThread(function()
        while true do
            if isHUDVisible then
                HUDElements.UpdateHUD()
            end
            Wait(1000) -- Update every second
        end
    end)
    
    -- Environmental scanning loop
    CreateThread(function()
        while true do
            if isHUDVisible then
                HUDElements.ScanEnvironment()
            end
            Wait(2000) -- Scan every 2 seconds
        end
    end)
    
    -- Tunnel proximity detection
    CreateThread(function()
        while true do
            if isHUDVisible and hudConfig.showTunnelProximity then
                HUDElements.CheckTunnelProximity()
            end
            Wait(3000) -- Check every 3 seconds
        end
    end)
end

function HUDElements.UpdateHUD()
    -- Get current player data
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local currentTime = GetClockHours() .. ':' .. string.format('%02d', GetClockMinutes())
    
    -- Prepare HUD data
    local hudData = {
        type = 'updateHUD',
        visible = isHUDVisible,
        config = hudConfig,
        playerData = playerData,
        environment = {
            time = currentTime,
            location = HUDElements.GetLocationName(playerCoords),
            weather = HUDElements.GetWeatherStatus(),
            securityLevel = HUDElements.GetAreaSecurityLevel(playerCoords)
        },
        systems = {
            tunnel = HUDElements.GetTunnelStatus(),
            radio = HUDElements.GetRadioStatus(),
            surveillance = HUDElements.GetSurveillanceStatus()
        }
    }
    
    SendNUIMessage(hudData)
end

function HUDElements.ScanEnvironment()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    -- Check for nearby NPCs
    local nearbyNPCs = HUDElements.ScanNearbyNPCs(playerCoords)
    
    -- Check for restricted zones
    local restrictedZones = HUDElements.CheckRestrictedZones(playerCoords)
    
    -- Check for surveillance cameras
    local surveillanceLevel = HUDElements.CheckSurveillance(playerCoords)
    
    local scanData = {
        type = 'environmentScan',
        npcs = nearbyNPCs,
        restrictedZones = restrictedZones,
        surveillanceLevel = surveillanceLevel,
        timestamp = GetGameTimer()
    }
    
    SendNUIMessage(scanData)
end

function HUDElements.CheckTunnelProximity()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local nearestTunnel = nil
    local nearestDistance = 999999
    
    if Config.TunnelSystem.enabled then
        for i, tunnel in ipairs(Config.TunnelSystem.tunnelPoints) do
            local distance = #(playerCoords - tunnel.coords)
            if distance < tunnel.radius and distance < nearestDistance then
                nearestDistance = distance
                nearestTunnel = {
                    id = i,
                    distance = distance,
                    canAccess = HUDElements.CanAccessTunnel(tunnel)
                }
            end
        end
    end
    
    local tunnelData = {
        type = 'tunnelProximity',
        nearestTunnel = nearestTunnel
    }
    
    SendNUIMessage(tunnelData)
end

function HUDElements.GetLocationName(coords)
    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)
    
    if streetName then
        return streetName
    else
        return "Unknown Location"
    end
end

function HUDElements.GetWeatherStatus()
    local weather = GetPrevWeatherTypeHashName()
    local weatherNames = {
        ['CLEAR'] = 'Clear',
        ['EXTRASUNNY'] = 'Sunny',
        ['CLOUDS'] = 'Cloudy',
        ['OVERCAST'] = 'Overcast',
        ['RAIN'] = 'Rainy',
        ['CLEARING'] = 'Clearing',
        ['THUNDER'] = 'Stormy',
        ['SMOG'] = 'Smoggy',
        ['FOGGY'] = 'Foggy'
    }
    
    return weatherNames[weather] or 'Unknown'
end

function HUDElements.GetAreaSecurityLevel(coords)
    -- Simulate security level based on location
    local z = coords.z
    local securityLevel = 1
    
    -- Higher security in certain areas
    if z > 200 then -- High buildings
        securityLevel = 3
    elseif z < 30 then -- Underground
        securityLevel = 4
    end
    
    -- Check for proximity to government buildings, airports, etc.
    local governmentAreas = {
        vector3(436.0, -982.0, 30.0), -- LSPD Mission Row
        vector3(-1095.0, -808.0, 19.0), -- LSPD Vespucci
        vector3(-449.0, 6014.0, 31.0), -- Paleto Bay PD
    }
    
    for _, area in ipairs(governmentAreas) do
        local distance = #(coords - area)
        if distance < 150 then
            securityLevel = math.max(securityLevel, 3)
        end
    end
    
    return securityLevel
end

function HUDElements.GetTunnelStatus()
    if not Config.TunnelSystem.enabled then
        return {enabled = false, status = 'Offline'}
    end
    
    local playerJob = QBCore.Functions.GetPlayerData().job
    local hasAccess = false
    
    for _, allowedJob in ipairs(Config.TunnelSystem.accessJobs) do
        if playerJob.name == allowedJob then
            hasAccess = true
            break
        end
    end
    
    return {
        enabled = true,
        hasAccess = hasAccess,
        status = hasAccess and 'Access Granted' or 'Access Denied'
    }
end

function HUDElements.GetRadioStatus()
    if not Config.ResistanceRadio.enabled then
        return {enabled = false, status = 'Offline'}
    end
    
    local currentFreq = exports['pma-voice']:getRadioChannel()
    local isResistanceFreq = currentFreq == Config.ResistanceRadio.frequencies.main
    
    return {
        enabled = true,
        frequency = currentFreq or 'None',
        isResistance = isResistanceFreq,
        status = isResistanceFreq and 'Resistance Network' or (currentFreq and 'Standard Radio' or 'No Signal')
    }
end

function HUDElements.GetSurveillanceStatus()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local suspicionLevel = playerData.suspicionLevel or 0
    
    -- Higher suspicion = more surveillance
    local surveillanceLevel = 'None'
    if suspicionLevel >= 75 then
        surveillanceLevel = 'Active Monitoring'
    elseif suspicionLevel >= 50 then
        surveillanceLevel = 'Enhanced Watch'
    elseif suspicionLevel >= 25 then
        surveillanceLevel = 'Routine Monitoring'
    end
    
    return {
        level = surveillanceLevel,
        intensity = math.floor(suspicionLevel / 25) + 1
    }
end

function HUDElements.ScanNearbyNPCs(playerCoords)
    local nearbyNPCs = {}
    local ped = PlayerPedId()
    
    -- Get all peds in area
    local peds = exports['qb-core']:GetPedsInArea(playerCoords, 50.0)
    
    for _, npc in ipairs(peds) do
        if npc ~= ped and not IsPedAPlayer(npc) then
            local npcCoords = GetEntityCoords(npc)
            local distance = #(playerCoords - npcCoords)
            
            if distance < 30.0 then
                table.insert(nearbyNPCs, {
                    distance = distance,
                    isSuspicious = math.random() < 0.1, -- 10% chance of suspicious NPC
                    activity = HUDElements.GetNPCActivity(npc)
                })
            end
        end
    end
    
    return nearbyNPCs
end

function HUDElements.GetNPCActivity(npc)
    local activities = {'walking', 'standing', 'talking', 'sitting', 'working'}
    return activities[math.random(#activities)]
end

function HUDElements.CheckRestrictedZones(playerCoords)
    local restrictedZones = {}
    
    -- Example restricted zones
    local zones = {
        {coords = vector3(-75.0, -818.0, 321.0), radius = 100.0, name = "FIB Building"},
        {coords = vector3(436.0, -982.0, 30.0), radius = 75.0, name = "LSPD Mission Row"},
        {coords = vector3(-1266.0, -741.0, 20.0), radius = 50.0, name = "Military Base Entrance"}
    }
    
    for _, zone in ipairs(zones) do
        local distance = #(playerCoords - zone.coords)
        if distance < zone.radius then
            table.insert(restrictedZones, {
                name = zone.name,
                distance = distance,
                severity = distance < zone.radius * 0.5 and 'high' or 'medium'
            })
        end
    end
    
    return restrictedZones
end

function HUDElements.CheckSurveillance(playerCoords)
    local surveillanceLevel = 0
    local suspicionLevel = playerData.suspicionLevel or 0
    
    -- Base surveillance based on area
    local areaSecurityLevel = HUDElements.GetAreaSecurityLevel(playerCoords)
    surveillanceLevel = areaSecurityLevel * 25
    
    -- Increase based on suspicion
    surveillanceLevel = surveillanceLevel + (suspicionLevel * 0.5)
    
    return math.min(100, surveillanceLevel)
end

function HUDElements.CanAccessTunnel(tunnel)
    local playerJob = QBCore.Functions.GetPlayerData().job
    local clearanceLevel = playerData.clearanceLevel or 0
    
    -- Check job access
    local hasJobAccess = false
    for _, allowedJob in ipairs(Config.TunnelSystem.accessJobs) do
        if playerJob.name == allowedJob then
            hasJobAccess = true
            break
        end
    end
    
    return hasJobAccess and clearanceLevel >= 2
end

function HUDElements.ToggleHUD()
    isHUDVisible = not isHUDVisible
    
    local message = isHUDVisible and '^2HUD Enabled^7' or '^1HUD Disabled^7'
    QBCore.Functions.Notify(message, 'primary', 2000)
    
    SendNUIMessage({
        type = 'toggleHUD',
        visible = isHUDVisible
    })
end

function HUDElements.OpenHUDConfig()
    SendNUIMessage({
        type = 'openHUDConfig',
        config = hudConfig
    })
end

-- Status indicators for different states
function HUDElements.ShowTunnelEffect()
    SendNUIMessage({
        type = 'showEffect',
        effect = 'tunnel_entry',
        duration = 3000
    })
end

function HUDElements.ShowBlacklineEffect()
    SendNUIMessage({
        type = 'showEffect',
        effect = 'blackline_event',
        duration = 5000
    })
end

function HUDElements.ShowSecurityAlert(level)
    SendNUIMessage({
        type = 'showAlert',
        alert = 'security',
        level = level,
        duration = 8000
    })
end

function HUDElements.ShowResistanceBroadcast(message)
    SendNUIMessage({
        type = 'showBroadcast',
        message = message,
        duration = 10000
    })
end

-- Export functions
exports('HUDElements', function()
    return HUDElements
end)

-- Event handlers
RegisterNetEvent('crp-reckoning:client:updatePlayerData', function(data)
    playerData = data
end)

RegisterNetEvent('crp-reckoning:hud:showTunnelEffect', function()
    HUDElements.ShowTunnelEffect()
end)

RegisterNetEvent('crp-reckoning:hud:showBlacklineEffect', function()
    HUDElements.ShowBlacklineEffect()
end)

RegisterNetEvent('crp-reckoning:hud:showSecurityAlert', function(level)
    HUDElements.ShowSecurityAlert(level)
end)

RegisterNetEvent('crp-reckoning:hud:showResistanceBroadcast', function(message)
    HUDElements.ShowResistanceBroadcast(message)
end)

RegisterNetEvent('crp-reckoning:hud:toggleHUD', function()
    HUDElements.ToggleHUD()
end)

return HUDElements
