-- Database Manager for Country Road RP - Reckoning
local QBCore = exports['qb-core']:GetCoreObject()

local DatabaseManager = {}
local playerCache = {}
local batchQueue = {}
local isInitialized = false

-- Initialize database connection
function DatabaseManager.Initialize()
    if not Config.Database.enabled then
        print('^3[Database Manager] Database integration disabled^7')
        return false
    end
    
    -- Test database connection
    local success = DatabaseManager.TestConnection()
    if success then
        print('^2[Database Manager] Successfully connected to database^7')
        isInitialized = true
        
        -- Start batch processing
        if Config.Performance.asyncOperations then
            DatabaseManager.StartBatchProcessor()
        end
        
        -- Start cleanup routine
        DatabaseManager.StartCleanupRoutine()
        
        return true
    else
        print('^1[Database Manager] Failed to connect to database^7')
        return false
    end
end

function DatabaseManager.TestConnection()
    local success = false
    
    exports.oxmysql:execute('SELECT 1 as test', {}, function(result)
        if result and result[1] and result[1].test == 1 then
            success = true
        end
    end)
    
    -- Wait for async operation
    while success == false do
        Wait(10)
    end
    
    return success
end

-- Player Management
function DatabaseManager.GetOrCreatePlayer(citizenid, playerData)
    if not isInitialized then return nil end
    
    -- Check cache first
    if Config.Performance.cachePlayerData and playerCache[citizenid] then
        local cached = playerCache[citizenid]
        if (GetGameTimer() - cached.timestamp) < (Config.Performance.cacheTimeout * 1000) then
            return cached.data
        end
    end
    
    local result = exports.oxmysql:executeSync(
        'SELECT * FROM reckoning_player_profiles WHERE citizenid = ?',
        {citizenid}
    )
    
    if result and #result > 0 then
        local player = result[1]
        
        -- Update cache
        if Config.Performance.cachePlayerData then
            playerCache[citizenid] = {
                data = player,
                timestamp = GetGameTimer()
            }
        end
        
        return player
    else
        -- Create new player profile
        local insertData = {
            citizenid = citizenid,
            player_name = playerData.name or 'Unknown',
            clearance_level = DatabaseManager.CalculateClearanceLevel(playerData),
            job_name = playerData.job or 'civilian',
            job_rank = playerData.rank or 'none',
            suspicion_level = 0,
            total_violations = 0
        }
        
        exports.oxmysql:execute(
            'INSERT INTO reckoning_player_profiles (citizenid, player_name, clearance_level, job_name, job_rank) VALUES (?, ?, ?, ?, ?)',
            {insertData.citizenid, insertData.player_name, insertData.clearance_level, insertData.job_name, insertData.job_rank}
        )
        
        -- Update cache
        if Config.Performance.cachePlayerData then
            playerCache[citizenid] = {
                data = insertData,
                timestamp = GetGameTimer()
            }
        end
        
        return insertData
    end
end

function DatabaseManager.UpdatePlayer(citizenid, updates)
    if not isInitialized then return false end
    
    local setClause = {}
    local values = {}
    
    for key, value in pairs(updates) do
        table.insert(setClause, key .. ' = ?')
        table.insert(values, value)
    end
    
    table.insert(values, citizenid)
    
    local query = 'UPDATE reckoning_player_profiles SET ' .. table.concat(setClause, ', ') .. ', last_activity = NOW() WHERE citizenid = ?'
    
    exports.oxmysql:execute(query, values, function(affectedRows)
        if affectedRows > 0 then
            -- Clear cache
            if playerCache[citizenid] then
                playerCache[citizenid] = nil
            end
        end
    end)
    
    return true
end

function DatabaseManager.CalculateClearanceLevel(playerData)
    if not playerData.job then return 0 end
    
    for _, level in ipairs(Config.AccessControl.clearanceLevels) do
        local hasJob = false
        local hasRank = true
        
        for _, requiredJob in ipairs(level.jobs) do
            if playerData.job == requiredJob then
                hasJob = true
                break
            end
        end
        
        if level.ranks and playerData.rank then
            hasRank = false
            for _, requiredRank in ipairs(level.ranks) do
                if playerData.rank == requiredRank then
                    hasRank = true
                    break
                end
            end
        end
        
        if hasJob and hasRank then
            return level.level
        end
    end
    
    return 0
end

-- Security Logging
function DatabaseManager.LogSecurityEvent(citizenid, eventType, category, severity, description, location, metadata)
    if not isInitialized then return false end
    
    local logData = {
        citizenid = citizenid,
        event_type = eventType,
        event_category = category,
        severity = severity,
        description = description,
        location_x = location and location.x or nil,
        location_y = location and location.y or nil,
        location_z = location and location.z or nil,
        metadata = metadata and json.encode(metadata) or nil
    }
    
    if Config.Performance.asyncOperations then
        DatabaseManager.AddToBatch('security_log', logData)
    else
        exports.oxmysql:execute(
            'CALL LogSecurityEvent(?, ?, ?, ?, ?, ?, ?, ?, ?)',
            {
                logData.citizenid, logData.event_type, logData.event_category,
                logData.severity, logData.description, logData.location_x,
                logData.location_y, logData.location_z, logData.metadata
            }
        )
    end
    
    return true
end

-- Tunnel Access Logging
function DatabaseManager.LogTunnelAccess(citizenid, tunnelZone, accessGranted, entryCoords, clearanceLevel)
    if not isInitialized then return false end
    
    local accessData = {
        citizenid = citizenid,
        tunnel_zone = tunnelZone,
        access_granted = accessGranted,
        clearance_used = clearanceLevel,
        entry_coords = entryCoords and json.encode(entryCoords) or nil
    }
    
    if Config.Performance.asyncOperations then
        DatabaseManager.AddToBatch('tunnel_access', accessData)
    else
        exports.oxmysql:execute(
            'INSERT INTO reckoning_tunnel_access (citizenid, tunnel_zone, access_granted, clearance_used, entry_coords) VALUES (?, ?, ?, ?, ?)',
            {accessData.citizenid, accessData.tunnel_zone, accessData.access_granted, accessData.clearance_used, accessData.entry_coords}
        )
    end
    
    return true
end

function DatabaseManager.UpdateTunnelExit(citizenid, exitCoords)
    if not isInitialized then return false end
    
    exports.oxmysql:execute([[ 
        UPDATE reckoning_tunnel_access 
        SET exit_time = NOW(), 
            exit_coords = ?,
            duration_seconds = TIMESTAMPDIFF(SECOND, entry_time, NOW())
        WHERE citizenid = ? AND exit_time IS NULL 
        ORDER BY entry_time DESC LIMIT 1
    ]], {exitCoords and json.encode(exitCoords) or nil, citizenid})
    
    return true
end

-- Blackline Events
function DatabaseManager.LogBlacklineEvent(citizenid, eventType, status, location, metadata)
    if not isInitialized then return false end
    
    local eventData = {
        citizenid = citizenid,
        event_type = eventType,
        status = status,
        location_coords = location and json.encode(location) or nil,
        agent_count = metadata and metadata.agent_count or nil,
        vehicles_spawned = metadata and metadata.vehicles_spawned or nil,
        outcome = metadata and metadata.outcome or nil
    }
    
    if Config.Performance.asyncOperations then
        DatabaseManager.AddToBatch('blackline_event', eventData)
    else
        exports.oxmysql:execute(
            'INSERT INTO reckoning_blackline_events (citizenid, event_type, status, location_coords, agent_count, vehicles_spawned, outcome) VALUES (?, ?, ?, ?, ?, ?, ?)',
            {eventData.citizenid, eventData.event_type, eventData.status, eventData.location_coords, eventData.agent_count, eventData.vehicles_spawned, eventData.outcome}
        )
    end
    
    return true
end

-- Batch Processing
function DatabaseManager.AddToBatch(type, data)
    if not batchQueue[type] then
        batchQueue[type] = {}
    end
    
    table.insert(batchQueue[type], data)
    
    if #batchQueue[type] >= Config.Performance.batchInsertSize then
        DatabaseManager.ProcessBatch(type)
    end
end

function DatabaseManager.ProcessBatch(type)
    if not batchQueue[type] or #batchQueue[type] == 0 then
        return
    end
    
    local batch = batchQueue[type]
    batchQueue[type] = {}
    
    if type == 'security_log' then
        DatabaseManager.ProcessSecurityLogBatch(batch)
    elseif type == 'tunnel_access' then
        DatabaseManager.ProcessTunnelAccessBatch(batch)
    elseif type == 'blackline_event' then
        DatabaseManager.ProcessBlacklineEventBatch(batch)
    end
end

function DatabaseManager.ProcessSecurityLogBatch(batch)
    local values = {}
    local placeholders = {}
    
    for _, log in ipairs(batch) do
        table.insert(values, log.citizenid)
        table.insert(values, log.event_type)
        table.insert(values, log.event_category)
        table.insert(values, log.severity)
        table.insert(values, log.description)
        table.insert(values, log.location_x)
        table.insert(values, log.location_y)
        table.insert(values, log.location_z)
        table.insert(values, log.metadata)
        table.insert(placeholders, '(?, ?, ?, ?, ?, ?, ?, ?, ?)')
    end
    
    local query = 'INSERT INTO reckoning_security_logs (citizenid, event_type, event_category, severity, description, location_x, location_y, location_z, metadata) VALUES ' .. table.concat(placeholders, ', ')
    
    exports.oxmysql:execute(query, values)
end

function DatabaseManager.StartBatchProcessor()
    CreateThread(function()
        while true do
            Wait(5000) -- Process batches every 5 seconds
            
            for batchType, _ in pairs(batchQueue) do
                DatabaseManager.ProcessBatch(batchType)
            end
        end
    end)
end

-- Data Cleanup
function DatabaseManager.StartCleanupRoutine()
    CreateThread(function()
        while true do
            Wait(3600000) -- Run every hour
            
            DatabaseManager.CleanupOldData()
        end
    end)
end

function DatabaseManager.CleanupOldData()
    if not isInitialized then return end
    
    local retention = Config.Database.retention
    
    -- Clean security logs
    exports.oxmysql:execute(
        'DELETE FROM reckoning_security_logs WHERE timestamp < DATE_SUB(NOW(), INTERVAL ? DAY)',
        {retention.security_logs}
    )
    
    -- Clean blackline events
    exports.oxmysql:execute(
        'DELETE FROM reckoning_blackline_events WHERE start_time < DATE_SUB(NOW(), INTERVAL ? DAY)',
        {retention.blackline_events}
    )
    
    -- Clean tunnel access logs
    exports.oxmysql:execute(
        'DELETE FROM reckoning_tunnel_access WHERE entry_time < DATE_SUB(NOW(), INTERVAL ? DAY)',
        {retention.tunnel_access}
    )
    
    -- Clean propaganda logs
    exports.oxmysql:execute(
        'DELETE FROM reckoning_propaganda WHERE broadcast_time < DATE_SUB(NOW(), INTERVAL ? DAY)',
        {retention.propaganda}
    )
    
    print('^2[Database Manager] Completed data cleanup routine^7')
end

-- Statistics
function DatabaseManager.UpdateSystemStat(statName, value, statType)
    if not isInitialized then return false end
    
    exports.oxmysql:execute(
        'UPDATE reckoning_system_stats SET stat_value = ?, stat_type = ? WHERE stat_name = ?',
        {value, statType or 'counter', statName}
    )
    
    return true
end

function DatabaseManager.IncrementStat(statName, amount)
    if not isInitialized then return false end
    
    amount = amount or 1
    
    exports.oxmysql:execute(
        'UPDATE reckoning_system_stats SET stat_value = stat_value + ? WHERE stat_name = ?',
        {amount, statName}
    )
    
    return true
end

-- Export functions
exports('DatabaseManager', function()
    return DatabaseManager
end)

exports('GetPlayerProfile', function(citizenid)
    return DatabaseManager.GetOrCreatePlayer(citizenid, {})
end)

exports('LogSecurityEvent', function(citizenid, eventType, category, severity, description, location, metadata)
    return DatabaseManager.LogSecurityEvent(citizenid, eventType, category, severity, description, location, metadata)
end)

-- Initialize on resource start
CreateThread(function()
    Wait(2000) -- Wait for other resources
    DatabaseManager.Initialize()
end)

return DatabaseManager
