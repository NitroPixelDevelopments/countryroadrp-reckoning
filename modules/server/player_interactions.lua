-- Server-side Player Interaction Handlers for Country Road RP: Reckoning
local QBCore = exports['qb-core']:GetCoreObject()

local PlayerInteractions = {}
local recentBroadcasts = {}

-- Initialize server-side interactions
CreateThread(function()
    PlayerInteractions.Initialize()
end)

function PlayerInteractions.Initialize()
    print('^2[Reckoning] Server player interaction handlers loaded^7')
    
    -- Register server events
    RegisterNetEvent('crp-reckoning:server:requestPlayerData', PlayerInteractions.SendPlayerData)
    RegisterNetEvent('crp-reckoning:server:tuneRadio', PlayerInteractions.HandleRadioTune)
    RegisterNetEvent('crp-reckoning:server:checkRadioSignal', PlayerInteractions.HandleSignalCheck)
    RegisterNetEvent('crp-reckoning:server:requestRecentBroadcasts', PlayerInteractions.SendRecentBroadcasts)
    RegisterNetEvent('crp-reckoning:server:requestTunnelAccess', PlayerInteractions.HandleTunnelAccess)
    RegisterNetEvent('crp-reckoning:server:reportSuspiciousNPC', PlayerInteractions.HandleNPCReport)
    
    -- Hook into existing resistance radio events to track broadcasts
    RegisterNetEvent('crp-reckoning:resistance:broadcastSent', PlayerInteractions.TrackBroadcast)
end

function PlayerInteractions.SendPlayerData(source)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    
    if not player then return end
    
    -- Get player profile from database
    local playerProfile = exports.oxmysql:executeSync(
        'SELECT * FROM reckoning_player_profiles WHERE citizenid = ?',
        {player.PlayerData.citizenid}
    )
    
    local profile = playerProfile[1]
    local playerData = {
        citizenid = player.PlayerData.citizenid,
        playerName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
        jobName = player.PlayerData.job.name,
        jobRank = player.PlayerData.job.grade.name,
        clearanceLevel = profile and profile.clearance_level or 0,
        suspicionLevel = profile and profile.suspicion_level or 0,
        totalViolations = profile and profile.total_violations or 0,
        lastActivity = profile and profile.last_activity or os.date('%Y-%m-%d %H:%M:%S'),
        notes = profile and profile.notes or nil
    }
    
    TriggerClientEvent('crp-reckoning:client:updatePlayerData', src, playerData)
end

function PlayerInteractions.HandleRadioTune(source, frequency)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    
    if not player then return end
    
    -- Log radio activity
    if frequency == Config.ResistanceRadio.frequencies.main then
        -- Log resistance radio connection
        local DatabaseManager = exports['countryroadrp-reckoning']:DatabaseManager()
        DatabaseManager.LogSecurityEvent(
            player.PlayerData.citizenid,
            'resistance_radio_tune',
            'resistance',
            'medium',
            'Player tuned to resistance frequency',
            nil,
            {frequency = frequency, method = 'player_command'}
        )
        
        -- Increase suspicion slightly for tuning to resistance frequency
        exports.oxmysql:execute(
            'CALL UpdatePlayerSuspicion(?, ?, ?)',
            {player.PlayerData.citizenid, 2, 'Tuned to resistance frequency'}
        )
    end
    
    TriggerClientEvent('crp-reckoning:client:tuneResistance', src)
end

function PlayerInteractions.HandleSignalCheck(source)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    
    if not player then return end
    
    -- Simulate signal strength based on player location and other factors
    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    local signalStrength = PlayerInteractions.CalculateSignalStrength(playerCoords)
    
    TriggerClientEvent('crp-reckoning:client:signalCheckResult', src, signalStrength)
    
    -- Log signal check activity
    local DatabaseManager = exports['countryroadrp-reckoning']:DatabaseManager()
    DatabaseManager.LogSecurityEvent(
        player.PlayerData.citizenid,
        'radio_signal_check',
        'resistance',
        'low',
        'Player checked radio signal strength',
        nil,
        {signal_strength = signalStrength, location = playerCoords}
    )
end

function PlayerInteractions.SendRecentBroadcasts(source)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    
    if not player then return end
    
    -- Get recent broadcasts (last 5)
    local broadcasts = {}
    local count = 0
    
    for i = #recentBroadcasts, 1, -1 do
        if count >= 5 then break end
        table.insert(broadcasts, recentBroadcasts[i])
        count = count + 1
    end
    
    TriggerClientEvent('crp-reckoning:client:recentBroadcasts', src, broadcasts)
    
    -- Log broadcast request
    local DatabaseManager = exports['countryroadrp-reckoning']:DatabaseManager()
    DatabaseManager.LogSecurityEvent(
        player.PlayerData.citizenid,
        'broadcast_history_request',
        'resistance',
        'medium',
        'Player requested recent broadcast history',
        nil,
        {broadcast_count = #broadcasts}
    )
    
    -- Increase suspicion for accessing resistance communications
    exports.oxmysql:execute(
        'CALL UpdatePlayerSuspicion(?, ?, ?)',
        {player.PlayerData.citizenid, 3, 'Accessed resistance broadcast history'}
    )
end

function PlayerInteractions.HandleTunnelAccess(source, tunnelId)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    
    if not player then return end
    
    if not Config.TunnelSystem.enabled then
        TriggerClientEvent('QBCore:Notify', src, 'Tunnel systems are currently offline', 'error', 3000)
        return
    end
    
    -- Check player access permissions
    local hasAccess = PlayerInteractions.ValidateTunnelAccess(player, tunnelId)
    
    if hasAccess.allowed then
        -- Grant tunnel access
        TriggerClientEvent('crp-reckoning:client:enterTunnel', src, {tunnelId = tunnelId})
        
        -- Log tunnel access
        local DatabaseManager = exports['countryroadrp-reckoning']:DatabaseManager()
        
        -- Log to tunnel access table
        exports.oxmysql:execute([[
            INSERT INTO reckoning_tunnel_access (citizenid, tunnel_id, entry_time, entry_tunnel, clearance_used)
            VALUES (?, ?, NOW(), ?, ?)
        ]], {
            player.PlayerData.citizenid,
            tunnelId,
            'Tunnel_' .. tunnelId,
            hasAccess.clearanceLevel
        })
        
        -- Log security event
        DatabaseManager.LogSecurityEvent(
            player.PlayerData.citizenid,
            'tunnel_access_granted',
            'tunnel',
            'info',
            'Player granted access to tunnel network',
            nil,
            {tunnel_id = tunnelId, clearance_level = hasAccess.clearanceLevel}
        )
        
        TriggerClientEvent('QBCore:Notify', src, '^2Access granted to TRENCHGLASS network^7', 'success', 3000)
    else
        -- Access denied
        TriggerClientEvent('QBCore:Notify', src, '^1Access denied: ' .. hasAccess.reason .. '^7', 'error', 5000)
        
        -- Log access attempt
        local DatabaseManager = exports['countryroadrp-reckoning']:DatabaseManager()
        DatabaseManager.LogSecurityEvent(
            player.PlayerData.citizenid,
            'tunnel_access_denied',
            'tunnel',
            'high',
            'Unauthorized tunnel access attempt',
            nil,
            {tunnel_id = tunnelId, reason = hasAccess.reason}
        )
        
        -- Increase suspicion for unauthorized access attempt
        exports.oxmysql:execute(
            'CALL UpdatePlayerSuspicion(?, ?, ?)',
            {player.PlayerData.citizenid, 10, 'Attempted unauthorized tunnel access'}
        )
    end
end

function PlayerInteractions.HandleNPCReport(source, npcId)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    
    if not player then return end
    
    -- Validate NPC exists and is suspicious
    local npcData = exports['countryroadrp-reckoning']:GetNPCData(npcId)
    
    if not npcData then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid target for report', 'error', 3000)
        return
    end
    
    -- Process NPC report
    local isCorrectReport = npcData.isSuspicious or false
    local reward = isCorrectReport and 50 or 0
    local suspicionChange = isCorrectReport and -5 or 2 -- Reward correct reports, penalize false ones
    
    -- Update player suspicion
    exports.oxmysql:execute(
        'CALL UpdatePlayerSuspicion(?, ?, ?)',
        {player.PlayerData.citizenid, suspicionChange, 'Reported suspicious individual'}
    )
    
    -- Give reward if correct
    if isCorrectReport and reward > 0 then
        player.Functions.AddMoney('cash', reward)
        TriggerClientEvent('QBCore:Notify', src, '^2Report validated! Reward: $' .. reward .. '^7', 'success', 5000)
    else
        TriggerClientEvent('QBCore:Notify', src, '^3Report filed. Investigation pending.^7', 'primary', 3000)
    end
    
    -- Log the report
    local DatabaseManager = exports['countryroadrp-reckoning']:DatabaseManager()
    DatabaseManager.LogSecurityEvent(
        player.PlayerData.citizenid,
        'npc_report_submitted',
        'npc',
        isCorrectReport and 'info' or 'low',
        'Player reported suspicious individual',
        nil,
        {
            npc_id = npcId,
            correct_report = isCorrectReport,
            reward_given = reward,
            suspicion_change = suspicionChange
        }
    )
end

function PlayerInteractions.TrackBroadcast(message, frequency, timestamp)
    -- Track resistance broadcasts for player access
    table.insert(recentBroadcasts, {
        message = message,
        frequency = frequency,
        time = os.date('%H:%M:%S', timestamp or os.time()),
        timestamp = timestamp or os.time()
    })
    
    -- Keep only last 20 broadcasts
    if #recentBroadcasts > 20 then
        table.remove(recentBroadcasts, 1)
    end
end

function PlayerInteractions.ValidateTunnelAccess(player, tunnelId)
    local jobName = player.PlayerData.job.name
    local jobRank = player.PlayerData.job.grade.name
    
    -- Check if job is allowed
    local hasJobAccess = false
    for _, allowedJob in ipairs(Config.TunnelSystem.accessJobs) do
        if jobName == allowedJob then
            -- Check rank
            local allowedRanks = Config.TunnelSystem.accessRanks[allowedJob]
            if allowedRanks then
                for _, rank in ipairs(allowedRanks) do
                    if jobRank == rank then
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
            allowed = false,
            reason = 'Insufficient job clearance for tunnel access'
        }
    end
    
    -- Check clearance level from database
    local playerProfile = exports.oxmysql:executeSync(
        'SELECT clearance_level FROM reckoning_player_profiles WHERE citizenid = ?',
        {player.PlayerData.citizenid}
    )
    
    local clearanceLevel = playerProfile[1] and playerProfile[1].clearance_level or 0
    
    if clearanceLevel < 2 then
        return {
            allowed = false,
            reason = 'Requires Level 2+ security clearance'
        }
    end
    
    return {
        allowed = true,
        clearanceLevel = clearanceLevel
    }
end

function PlayerInteractions.CalculateSignalStrength(coords)
    -- Simulate signal strength based on location
    -- Better signal in open areas, worse in buildings/underground
    
    local baseStrength = 75
    local z = coords.z
    
    -- Underground penalty
    if z < 30 then
        baseStrength = baseStrength - 20
    end
    
    -- Add some randomness
    local variation = math.random(-10, 15)
    local finalStrength = math.max(10, math.min(95, baseStrength + variation))
    
    return finalStrength
end

-- Chat command handlers for admin/testing
RegisterCommand('giveclearance', function(source, args)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    
    if not player then return end
    
    -- Check if player has admin permissions
    if not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('QBCore:Notify', src, 'No permission', 'error', 3000)
        return
    end
    
    local targetId = tonumber(args[1])
    local clearanceLevel = tonumber(args[2])
    
    if not targetId or not clearanceLevel then
        TriggerClientEvent('QBCore:Notify', src, 'Usage: /giveclearance [playerid] [level 0-4]', 'error', 5000)
        return
    end
    
    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        TriggerClientEvent('QBCore:Notify', src, 'Player not found', 'error', 3000)
        return
    end
    
    if clearanceLevel < 0 or clearanceLevel > 4 then
        TriggerClientEvent('QBCore:Notify', src, 'Clearance level must be 0-4', 'error', 3000)
        return
    end
    
    -- Update clearance level
    exports.oxmysql:execute(
        'INSERT INTO reckoning_player_profiles (citizenid, clearance_level) VALUES (?, ?) ON DUPLICATE KEY UPDATE clearance_level = ?',
        {targetPlayer.PlayerData.citizenid, clearanceLevel, clearanceLevel}
    )
    
    TriggerClientEvent('QBCore:Notify', src, 'Clearance level set to ' .. clearanceLevel .. ' for ' .. targetPlayer.PlayerData.charinfo.firstname, 'success', 5000)
    TriggerClientEvent('QBCore:Notify', targetId, 'Your clearance level has been updated to Level ' .. clearanceLevel, 'primary', 5000)
end, false)

RegisterCommand('setsuspicion', function(source, args)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    
    if not player then return end
    
    -- Check if player has admin permissions
    if not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('QBCore:Notify', src, 'No permission', 'error', 3000)
        return
    end
    
    local targetId = tonumber(args[1])
    local suspicionLevel = tonumber(args[2])
    
    if not targetId or not suspicionLevel then
        TriggerClientEvent('QBCore:Notify', src, 'Usage: /setsuspicion [playerid] [level 0-100]', 'error', 5000)
        return
    end
    
    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        TriggerClientEvent('QBCore:Notify', src, 'Player not found', 'error', 3000)
        return
    end
    
    if suspicionLevel < 0 or suspicionLevel > 100 then
        TriggerClientEvent('QBCore:Notify', src, 'Suspicion level must be 0-100', 'error', 3000)
        return
    end
    
    -- Update suspicion level
    exports.oxmysql:execute(
        'CALL UpdatePlayerSuspicion(?, ?, ?)',
        {targetPlayer.PlayerData.citizenid, suspicionLevel, 'Admin command adjustment'}
    )
    
    TriggerClientEvent('QBCore:Notify', src, 'Suspicion level set to ' .. suspicionLevel .. '% for ' .. targetPlayer.PlayerData.charinfo.firstname, 'success', 5000)
    TriggerClientEvent('QBCore:Notify', targetId, 'Your suspicion level has been updated', 'primary', 3000)
end, false)

-- Export functions
exports('PlayerInteractions', function()
    return PlayerInteractions
end)

return PlayerInteractions
