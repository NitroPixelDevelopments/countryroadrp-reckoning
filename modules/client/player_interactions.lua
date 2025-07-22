-- Player Interaction System for Country Road RP: Reckoning
local QBCore = exports['qb-core']:GetCoreObject()

local PlayerInteractions = {}
local isMenuOpen = false
local playerData = {}

-- Initialize player interactions
CreateThread(function()
    while not LocalPlayer.state.isLoggedIn do
        Wait(1000)
    end
    
    PlayerInteractions.Initialize()
end)

function PlayerInteractions.Initialize()
    print('^2[Reckoning] Player interaction system loaded^7')
    
    -- Register key mappings
    RegisterKeyMapping('reckoning_menu', 'Open Reckoning Menu', 'keyboard', 'F6')
    RegisterKeyMapping('reckoning_status', 'Check Personal Status', 'keyboard', 'F7')
    RegisterKeyMapping('reckoning_radio', 'Quick Radio Check', 'keyboard', 'F8')
    
    -- Register command handlers
    RegisterCommand('reckoning_menu', function()
        PlayerInteractions.OpenMainMenu()
    end, false)
    
    RegisterCommand('reckoning_status', function()
        PlayerInteractions.ShowPersonalStatus()
    end, false)
    
    RegisterCommand('reckoning_radio', function()
        PlayerInteractions.QuickRadioCheck()
    end, false)
    
    -- Chat commands
    RegisterCommand('suspicion', function()
        PlayerInteractions.CheckSuspicion()
    end, false)
    
    RegisterCommand('clearance', function()
        PlayerInteractions.CheckClearance()
    end, false)
    
    RegisterCommand('resistance', function()
        PlayerInteractions.ResistanceMenu()
    end, false)
    
    RegisterCommand('tunnel', function()
        PlayerInteractions.TunnelInfo()
    end, false)
    
    -- Register NUI callbacks
    RegisterNUICallback('closeMenu', function(data, cb)
        isMenuOpen = false
        SetNuiFocus(false, false)
        cb({success = true})
    end)
    
    RegisterNUICallback('playerAction', function(data, cb)
        PlayerInteractions.HandlePlayerAction(data)
        cb({success = true})
    end)
    
    -- Update player data periodically
    CreateThread(function()
        while true do
            PlayerInteractions.UpdatePlayerData()
            Wait(30000) -- Update every 30 seconds
        end
    end)
end

function PlayerInteractions.OpenMainMenu()
    if isMenuOpen then return end
    
    isMenuOpen = true
    PlayerInteractions.UpdatePlayerData()
    
    local menuData = {
        type = 'mainMenu',
        playerData = playerData,
        systems = {
            tunnel = Config.TunnelSystem.enabled,
            blackline = Config.BlacklineEvents.enabled,
            radio = Config.ResistanceRadio.enabled,
            npc = Config.NPCHandlers.enabled
        }
    }
    
    SetNuiFocus(true, true)
    SendNUIMessage(menuData)
end

function PlayerInteractions.ShowPersonalStatus()
    PlayerInteractions.UpdatePlayerData()
    
    local statusMessage = string.format([[
^3=== PERSONAL STATUS REPORT ===^7
^2Clearance Level:^7 %s
^2Suspicion Level:^7 %s%%
^2Current Job:^7 %s (%s)
^2Security Status:^7 %s
^2Last Activity:^7 %s
^3============================^7
    ]], 
        playerData.clearanceLevel and ('Level ' .. playerData.clearanceLevel) or 'Unknown',
        playerData.suspicionLevel or 'Unknown',
        playerData.jobName or 'Civilian',
        playerData.jobRank or 'None',
        PlayerInteractions.GetSecurityStatus(),
        os.date('%H:%M:%S')
    )
    
    TriggerEvent('chat:addMessage', {
        color = {255, 255, 255},
        multiline = true,
        args = {"[RECKONING]", statusMessage}
    })
end

function PlayerInteractions.CheckSuspicion()
    PlayerInteractions.UpdatePlayerData()
    
    local suspicionLevel = playerData.suspicionLevel or 0
    local statusColor = suspicionLevel > 75 and '^1' or suspicionLevel > 50 and '^3' or '^2'
    local riskLevel = suspicionLevel > 75 and 'HIGH RISK' or suspicionLevel > 50 and 'MODERATE' or suspicionLevel > 25 and 'LOW' or 'MINIMAL'
    
    QBCore.Functions.Notify(
        statusColor .. 'Suspicion Level: ' .. suspicionLevel .. '% (' .. riskLevel .. ')^7',
        suspicionLevel > 75 and 'error' or suspicionLevel > 50 and 'primary' or 'success',
        5000
    )
end

function PlayerInteractions.CheckClearance()
    PlayerInteractions.UpdatePlayerData()
    
    local clearanceLevel = playerData.clearanceLevel or 0
    local clearanceNames = {
        [0] = 'No Access',
        [1] = 'Basic Access',
        [2] = 'Standard Access', 
        [3] = 'High Clearance',
        [4] = 'Maximum Security'
    }
    
    local accessColor = clearanceLevel >= 3 and '^2' or clearanceLevel >= 2 and '^3' or '^1'
    
    QBCore.Functions.Notify(
        accessColor .. 'Clearance: Level ' .. clearanceLevel .. ' (' .. (clearanceNames[clearanceLevel] or 'Unknown') .. ')^7',
        'primary',
        5000
    )
end

function PlayerInteractions.QuickRadioCheck()
    if not Config.ResistanceRadio.enabled then
        QBCore.Functions.Notify('Radio systems are currently offline', 'error', 3000)
        return
    end
    
    local currentFreq = exports['pma-voice']:getRadioChannel()
    local isResistanceFreq = currentFreq == Config.ResistanceRadio.frequencies.main
    
    if isResistanceFreq then
        QBCore.Functions.Notify('^2Connected to Resistance Network (455.550)^7', 'success', 3000)
    elseif currentFreq then
        QBCore.Functions.Notify('^3Current Frequency: ' .. currentFreq .. '^7', 'primary', 3000)
    else
        QBCore.Functions.Notify('No radio frequency active', 'error', 3000)
    end
end

function PlayerInteractions.ResistanceMenu()
    if not Config.ResistanceRadio.enabled then
        QBCore.Functions.Notify('Resistance communications are not available', 'error', 3000)
        return
    end
    
    local resistanceOptions = {
        {
            header = "🎯 Resistance Network",
            txt = "Access resistance communications",
            isMenuHeader = true
        },
        {
            header = "📻 Tune to Main Frequency",
            txt = "Connect to 455.550 MHz",
            params = {
                event = "crp-reckoning:client:tuneResistance",
                args = {frequency = Config.ResistanceRadio.frequencies.main}
            }
        },
        {
            header = "📡 Check Signal Strength", 
            txt = "Test current signal quality",
            params = {
                event = "crp-reckoning:client:checkSignal"
            }
        },
        {
            header = "📋 Recent Broadcasts",
            txt = "Review last 5 broadcasts",
            params = {
                event = "crp-reckoning:client:recentBroadcasts"
            }
        },
        {
            header = "❌ Close",
            txt = "",
            params = {
                event = "qb-menu:closeMenu"
            }
        }
    }
    
    exports['qb-menu']:openMenu(resistanceOptions)
end

function PlayerInteractions.TunnelInfo()
    if not Config.TunnelSystem.enabled then
        QBCore.Functions.Notify('Tunnel information is classified', 'error', 3000)
        return
    end
    
    local playerPos = GetEntityCoords(PlayerPedId())
    local nearestTunnel = PlayerInteractions.FindNearestTunnel(playerPos)
    
    if nearestTunnel then
        local distance = nearestTunnel.distance
        local accessLevel = PlayerInteractions.CanAccessTunnel(nearestTunnel)
        
        local tunnelOptions = {
            {
                header = "🕳️ TRENCHGLASS Network",
                txt = "Tunnel access information",
                isMenuHeader = true
            },
            {
                header = "📍 Nearest Entry Point",
                txt = string.format("Distance: %.1fm", distance),
                disabled = true
            },
            {
                header = "🔐 Access Status",
                txt = accessLevel.canAccess and "^2AUTHORIZED^7" or "^1ACCESS DENIED^7",
                disabled = true
            },
            {
                header = accessLevel.canAccess and "🚪 Enter Tunnel" or "ℹ️ Access Requirements",
                txt = accessLevel.canAccess and "Access the underground network" or accessLevel.reason,
                params = {
                    event = accessLevel.canAccess and "crp-reckoning:client:enterTunnel" or nil,
                    args = accessLevel.canAccess and {tunnelId = nearestTunnel.id} or nil
                }
            },
            {
                header = "❌ Close",
                txt = "",
                params = {
                    event = "qb-menu:closeMenu"
                }
            }
        }
        
        exports['qb-menu']:openMenu(tunnelOptions)
    else
        QBCore.Functions.Notify('No tunnel access points detected in this area', 'error', 3000)
    end
end

function PlayerInteractions.HandlePlayerAction(data)
    local action = data.action
    
    if action == 'tune_resistance' then
        TriggerServerEvent('crp-reckoning:server:tuneRadio', Config.ResistanceRadio.frequencies.main)
        
    elseif action == 'check_signal' then
        TriggerServerEvent('crp-reckoning:server:checkRadioSignal')
        
    elseif action == 'recent_broadcasts' then
        TriggerServerEvent('crp-reckoning:server:requestRecentBroadcasts')
        
    elseif action == 'tunnel_access' then
        local tunnelId = data.tunnelId
        TriggerServerEvent('crp-reckoning:server:requestTunnelAccess', tunnelId)
        
    elseif action == 'report_npc' then
        local npcId = data.npcId
        TriggerServerEvent('crp-reckoning:server:reportSuspiciousNPC', npcId)
        
    elseif action == 'check_clearance_zones' then
        PlayerInteractions.ShowNearbyRestrictedZones()
    end
end

function PlayerInteractions.UpdatePlayerData()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    -- Request updated data from server
    TriggerServerEvent('crp-reckoning:server:requestPlayerData')
    
    -- Update local position data
    playerData.position = {
        x = playerCoords.x,
        y = playerCoords.y,
        z = playerCoords.z
    }
end

function PlayerInteractions.FindNearestTunnel(playerPos)
    local nearestTunnel = nil
    local nearestDistance = 999999
    
    for i, tunnel in ipairs(Config.TunnelSystem.tunnelPoints) do
        local distance = #(playerPos - tunnel.coords)
        if distance < tunnel.radius and distance < nearestDistance then
            nearestDistance = distance
            nearestTunnel = {
                id = i,
                coords = tunnel.coords,
                radius = tunnel.radius,
                distance = distance
            }
        end
    end
    
    return nearestTunnel
end

function PlayerInteractions.CanAccessTunnel(tunnel)
    local playerJob = QBCore.Functions.GetPlayerData().job
    
    -- Check job access
    local hasJobAccess = false
    for _, allowedJob in ipairs(Config.TunnelSystem.accessJobs) do
        if playerJob.name == allowedJob then
            -- Check rank access
            local allowedRanks = Config.TunnelSystem.accessRanks[allowedJob]
            if allowedRanks then
                for _, rank in ipairs(allowedRanks) do
                    if playerJob.grade.name == rank then
                        hasJobAccess = true
                        break
                    end
                end
            end
            break
        end
    end
    
    if not hasJobAccess then
        return {
            canAccess = false,
            reason = "Insufficient clearance level for tunnel access"
        }
    end
    
    -- Check clearance level if available
    if playerData.clearanceLevel and playerData.clearanceLevel < 2 then
        return {
            canAccess = false,
            reason = "Requires Level 2+ clearance for tunnel network"
        }
    end
    
    return {canAccess = true}
end

function PlayerInteractions.GetSecurityStatus()
    local suspicion = playerData.suspicionLevel or 0
    
    if suspicion >= 90 then
        return '^1CRITICAL - IMMEDIATE THREAT^7'
    elseif suspicion >= 75 then
        return '^1HIGH RISK - MONITOR CLOSELY^7'
    elseif suspicion >= 50 then
        return '^3MODERATE RISK - CAUTION ADVISED^7'
    elseif suspicion >= 25 then
        return '^3LOW RISK - ROUTINE MONITORING^7'
    else
        return '^2MINIMAL RISK - STANDARD STATUS^7'
    end
end

function PlayerInteractions.ShowNearbyRestrictedZones()
    -- This would show restricted zones near the player
    QBCore.Functions.Notify('Scanning for restricted zones...', 'primary', 2000)
    
    -- Could integrate with access control system
    Wait(2000)
    QBCore.Functions.Notify('No restricted zones detected in immediate area', 'success', 3000)
end

-- Export functions
exports('PlayerInteractions', function()
    return PlayerInteractions
end)

-- Event handlers
RegisterNetEvent('crp-reckoning:client:updatePlayerData', function(data)
    playerData = data
end)

RegisterNetEvent('crp-reckoning:client:tuneResistance', function()
    exports['pma-voice']:setRadioChannel(Config.ResistanceRadio.frequencies.main)
    QBCore.Functions.Notify('^2Tuned to Resistance frequency: 455.550^7', 'success', 3000)
end)

RegisterNetEvent('crp-reckoning:client:checkSignal', function()
    local signalStrength = math.random(60, 95) -- Simulate signal strength
    local quality = signalStrength > 80 and 'Excellent' or signalStrength > 60 and 'Good' or 'Poor'
    QBCore.Functions.Notify('^3Signal Strength: ' .. signalStrength .. '% (' .. quality .. ')^7', 'primary', 4000)
end)

RegisterNetEvent('crp-reckoning:client:recentBroadcasts', function(broadcasts)
    if broadcasts and #broadcasts > 0 then
        local message = '^3=== RECENT BROADCASTS ===^7\n'
        for i, broadcast in ipairs(broadcasts) do
            message = message .. '^2' .. broadcast.time .. '^7: ' .. broadcast.message .. '\n'
        end
        
        TriggerEvent('chat:addMessage', {
            color = {100, 200, 100},
            multiline = true,
            args = {"[RESISTANCE]", message}
        })
    else
        QBCore.Functions.Notify('No recent broadcasts available', 'error', 3000)
    end
end)

RegisterNetEvent('crp-reckoning:client:enterTunnel', function(data)
    local tunnelId = data.tunnelId
    QBCore.Functions.Notify('^3Accessing TRENCHGLASS tunnel network...^7', 'primary', 3000)
    
    -- Trigger tunnel entry effects
    TriggerEvent('crp-reckoning:tunnel:enter', tunnelId)
end)

return PlayerInteractions
