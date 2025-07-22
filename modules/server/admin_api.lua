-- Admin API Server for Country Road RP - Reckoning
local QBCore = exports['qb-core']:GetCoreObject()

local AdminAPI = {}
local activeSessions = {}
local rateLimitStore = {}

-- Initialize Admin API
function AdminAPI.Initialize()
    if not Config.AdminPanel.enabled then
        print('^3[Admin API] Admin panel disabled^7')
        return false
    end
    
    -- Start HTTP server
    AdminAPI.StartHTTPServer()
    
    -- Start session cleanup
    AdminAPI.StartSessionCleanup()
    
    print('^2[Admin API] Started on http://' .. Config.AdminPanel.host .. ':' .. Config.AdminPanel.port .. '^7')
    return true
end

function AdminAPI.StartHTTPServer()
    print('^3[Admin API] Setting up event-based API...^7')
    
    -- Register server events for API calls
    RegisterNetEvent('crp-reckoning:admin:authenticate', function(playerId, token)
        local src = source
        AdminAPI.HandleAuthEvent(src, playerId, token)
    end)
    
    RegisterNetEvent('crp-reckoning:admin:getDashboard', function(sessionId)
        local src = source
        AdminAPI.HandleDashboardEvent(src, sessionId)
    end)
    
    RegisterNetEvent('crp-reckoning:admin:getPlayers', function(sessionId, page, limit)
        local src = source
        AdminAPI.HandlePlayersEvent(src, sessionId, page, limit)
    end)
    
    RegisterNetEvent('crp-reckoning:admin:getSecurityEvents', function(sessionId, page, limit, severity, citizenid)
        local src = source
        AdminAPI.HandleSecurityEventsEvent(src, sessionId, page, limit, severity, citizenid)
    end)
    
    RegisterNetEvent('crp-reckoning:admin:getTunnelActivity', function(sessionId, page, limit)
        local src = source
        AdminAPI.HandleTunnelActivityEvent(src, sessionId, page, limit)
    end)
    
    RegisterNetEvent('crp-reckoning:admin:getPlayerDetails', function(sessionId, citizenid)
        local src = source
        AdminAPI.HandlePlayerDetailsEvent(src, sessionId, citizenid)
    end)
    
    RegisterNetEvent('crp-reckoning:admin:playerAction', function(sessionId, action, citizenid, params)
        local src = source
        AdminAPI.HandlePlayerActionEvent(src, sessionId, action, citizenid, params)
    end)
    
    RegisterNetEvent('crp-reckoning:admin:triggerEvent', function(sessionId, eventType, params)
        local src = source
        AdminAPI.HandleTriggerEventEvent(src, sessionId, eventType, params)
    end)
    
    print('^2[Admin API] Event-based API setup completed^7')
    print('^3[Admin API] Access the admin panel via resource URL:^7')
    print('^3[Admin API] URL: http://localhost:30120/' .. GetCurrentResourceName() .. '/web/admin-panel.html^7')
end

function AdminAPI.HandleAuthEvent(src, playerId, token)
    if not playerId or not token then
        TriggerClientEvent('crp-reckoning:admin:authResult', src, {success = false, error = 'Missing credentials'})
        return
    end
    
    -- Validate with QBCore if enabled
    if Config.AdminPanel.useQBCoreAuth then
        local player = QBCore.Functions.GetPlayer(tonumber(playerId))
        
        if not player then
            TriggerClientEvent('crp-reckoning:admin:authResult', src, {success = false, error = 'Player not found'})
            return
        end
        
        if not QBCore.Functions.HasPermission(tonumber(playerId), Config.AdminPanel.adminPermission) then
            TriggerClientEvent('crp-reckoning:admin:authResult', src, {success = false, error = 'Insufficient permissions'})
            return
        end
        
        -- Create session
        local sessionId = AdminAPI.GenerateSessionId()
        local session = {
            playerId = playerId,
            playerName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
            citizenid = player.PlayerData.citizenid,
            permissions = {'admin'},
            createdAt = os.time(),
            lastActivity = os.time(),
            source = src
        }
        
        activeSessions[sessionId] = session
        
        -- Log admin login
        if Config.AdminPanel.enableAuditLog then
            local DatabaseManager = exports['countryroadrp-reckoning']:DatabaseManager()
            DatabaseManager.LogSecurityEvent(
                session.citizenid,
                'admin_login',
                'admin',
                'info',
                'Admin panel login via events',
                nil,
                {session_id = sessionId, source = src}
            )
        end
        
        TriggerClientEvent('crp-reckoning:admin:authResult', src, {
            success = true,
            sessionId = sessionId,
            user = {
                name = session.playerName,
                citizenid = session.citizenid,
                permissions = session.permissions
            }
        })
    else
        TriggerClientEvent('crp-reckoning:admin:authResult', src, {success = false, error = 'Authentication method not implemented'})
    end
end

function AdminAPI.HandleDashboardEvent(src, sessionId)
    local session = activeSessions[sessionId]
    if not session or session.source ~= src then
        TriggerClientEvent('crp-reckoning:admin:dashboardResult', src, {success = false, error = 'Unauthorized'})
        return
    end
    
    -- Update session activity
    session.lastActivity = os.time()
    
    -- Get dashboard data (same as HTTP version)
    local DatabaseManager = exports['countryroadrp-reckoning']:DatabaseManager()
    
    local securityEvents = exports.oxmysql:executeSync(
        'SELECT * FROM view_active_security_events LIMIT 10'
    )
    
    local systemStats = exports.oxmysql:executeSync(
        'SELECT * FROM reckoning_system_stats ORDER BY category, stat_name'
    )
    
    local milestones = exports.oxmysql:executeSync(
        'SELECT * FROM reckoning_milestones WHERE status != "completed" ORDER BY milestone_name'
    )
    
    local highRiskPlayers = exports.oxmysql:executeSync(
        'SELECT * FROM view_high_risk_players LIMIT 5'
    )
    
    local dashboardData = {
        success = true,
        recentEvents = securityEvents or {},
        systemStats = AdminAPI.FormatSystemStats(systemStats or {}),
        milestones = milestones or {},
        highRiskPlayers = highRiskPlayers or {},
        serverInfo = {
            uptime = GetGameTimer(),
            playerCount = #QBCore.Functions.GetQBPlayers(),
            timestamp = os.time()
        }
    }
    
    TriggerClientEvent('crp-reckoning:admin:dashboardResult', src, dashboardData)
end

function AdminAPI.HandlePlayersEvent(src, sessionId, page, limit)
    local session = activeSessions[sessionId]
    if not session or session.source ~= src then
        TriggerClientEvent('crp-reckoning:admin:playersResult', src, {success = false, error = 'Unauthorized'})
        return
    end
    
    session.lastActivity = os.time()
    
    page = page or 1
    limit = limit or Config.AdminPanel.maxRecordsPerPage
    local offset = (page - 1) * limit
    
    local players = exports.oxmysql:executeSync(
        'SELECT * FROM reckoning_player_profiles ORDER BY last_activity DESC LIMIT ? OFFSET ?',
        {limit, offset}
    )
    
    local totalCount = exports.oxmysql:executeSync(
        'SELECT COUNT(*) as count FROM reckoning_player_profiles'
    )
    
    TriggerClientEvent('crp-reckoning:admin:playersResult', src, {
        success = true,
        players = players or {},
        pagination = {
            page = page,
            limit = limit,
            total = totalCount[1] and totalCount[1].count or 0
        }
    })
end

function AdminAPI.HandleSecurityEventsEvent(src, sessionId, page, limit, severity, citizenid)
    local session = activeSessions[sessionId]
    if not session or session.source ~= src then
        TriggerClientEvent('crp-reckoning:admin:securityEventsResult', src, {success = false, error = 'Unauthorized'})
        return
    end
    
    session.lastActivity = os.time()
    
    page = page or 1
    limit = limit or Config.AdminPanel.maxRecordsPerPage
    local offset = (page - 1) * limit
    
    local whereClause = {}
    local params = {}
    
    if severity then
        table.insert(whereClause, 'severity = ?')
        table.insert(params, severity)
    end
    
    if citizenid then
        table.insert(whereClause, 'citizenid = ?')
        table.insert(params, citizenid)
    end
    
    local whereSQL = #whereClause > 0 and (' WHERE ' .. table.concat(whereClause, ' AND ')) or ''
    
    table.insert(params, limit)
    table.insert(params, offset)
    
    local events = exports.oxmysql:executeSync(
        'SELECT sl.*, pp.player_name FROM reckoning_security_logs sl LEFT JOIN reckoning_player_profiles pp ON sl.citizenid = pp.citizenid' .. whereSQL .. ' ORDER BY sl.timestamp DESC LIMIT ? OFFSET ?',
        params
    )
    
    local totalParams = {}
    for i = 1, #params - 2 do
        table.insert(totalParams, params[i])
    end
    
    local totalCount = exports.oxmysql:executeSync(
        'SELECT COUNT(*) as count FROM reckoning_security_logs sl' .. whereSQL,
        totalParams
    )
    
    TriggerClientEvent('crp-reckoning:admin:securityEventsResult', src, {
        success = true,
        events = events or {},
        pagination = {
            page = page,
            limit = limit,
            total = totalCount[1] and totalCount[1].count or 0
        }
    })
end

function AdminAPI.HandleTunnelActivityEvent(src, sessionId, page, limit)
    local session = activeSessions[sessionId]
    if not session or session.source ~= src then
        TriggerClientEvent('crp-reckoning:admin:tunnelActivityResult', src, {success = false, error = 'Unauthorized'})
        return
    end
    
    session.lastActivity = os.time()
    
    page = page or 1
    limit = limit or Config.AdminPanel.maxRecordsPerPage
    local offset = (page - 1) * limit
    
    local tunnelActivity = exports.oxmysql:executeSync([[
        SELECT 
            ta.*,
            pp.player_name,
            pp.clearance_level
        FROM reckoning_tunnel_access ta
        LEFT JOIN reckoning_player_profiles pp ON ta.citizenid = pp.citizenid
        ORDER BY ta.entry_time DESC
        LIMIT ? OFFSET ?
    ]], {limit, offset})
    
    local totalCount = exports.oxmysql:executeSync('SELECT COUNT(*) as count FROM reckoning_tunnel_access')
    
    TriggerClientEvent('crp-reckoning:admin:tunnelActivityResult', src, {
        success = true,
        activity = tunnelActivity or {},
        pagination = {
            page = page,
            limit = limit,
            total = totalCount[1] and totalCount[1].count or 0
        }
    })
end

function AdminAPI.HandlePlayerDetailsEvent(src, sessionId, citizenid)
    local session = activeSessions[sessionId]
    if not session or session.source ~= src then
        TriggerClientEvent('crp-reckoning:admin:playerDetailsResult', src, {success = false, error = 'Unauthorized'})
        return
    end
    
    session.lastActivity = os.time()
    
    local player = exports.oxmysql:executeSync(
        'SELECT * FROM reckoning_player_profiles WHERE citizenid = ?',
        {citizenid}
    )
    
    if not player or #player == 0 then
        TriggerClientEvent('crp-reckoning:admin:playerDetailsResult', src, {success = false, error = 'Player not found'})
        return
    end
    
    local securityEvents = exports.oxmysql:executeSync(
        'SELECT * FROM reckoning_security_logs WHERE citizenid = ? ORDER BY timestamp DESC LIMIT 50',
        {citizenid}
    )
    
    local tunnelAccess = exports.oxmysql:executeSync(
        'SELECT * FROM reckoning_tunnel_access WHERE citizenid = ? ORDER BY entry_time DESC LIMIT 20',
        {citizenid}
    )
    
    local blacklineEvents = exports.oxmysql:executeSync(
        'SELECT * FROM reckoning_blackline_events WHERE citizenid = ? ORDER BY start_time DESC LIMIT 20',
        {citizenid}
    )
    
    TriggerClientEvent('crp-reckoning:admin:playerDetailsResult', src, {
        success = true,
        player = player[1],
        securityEvents = securityEvents or {},
        tunnelAccess = tunnelAccess or {},
        blacklineEvents = blacklineEvents or {}
    })
end

function AdminAPI.HandlePlayerActionEvent(src, sessionId, action, citizenid, params)
    local session = activeSessions[sessionId]
    if not session or session.source ~= src then
        TriggerClientEvent('crp-reckoning:admin:playerActionResult', src, {success = false, error = 'Unauthorized'})
        return
    end
    
    session.lastActivity = os.time()
    
    if not action or not citizenid then
        TriggerClientEvent('crp-reckoning:admin:playerActionResult', src, {success = false, error = 'Missing action or citizenid'})
        return
    end
    
    local success = false
    local message = ''
    
    if action == 'update_suspicion' then
        local newLevel = tonumber(params.suspicionLevel)
        if newLevel and newLevel >= 0 and newLevel <= 100 then
            exports.oxmysql:execute(
                'CALL UpdatePlayerSuspicion(?, ?, ?)',
                {citizenid, newLevel, 'Admin adjustment via panel'}
            )
            success = true
            message = 'Suspicion level updated to ' .. newLevel .. '%'
        else
            message = 'Invalid suspicion level (must be 0-100)'
        end
        
    elseif action == 'update_clearance' then
        local newLevel = tonumber(params.clearanceLevel)
        if newLevel and newLevel >= 0 and newLevel <= 4 then
            exports.oxmysql:execute(
                'UPDATE reckoning_player_profiles SET clearance_level = ? WHERE citizenid = ?',
                {newLevel, citizenid}
            )
            success = true
            message = 'Clearance level updated to Level ' .. newLevel
        else
            message = 'Invalid clearance level (must be 0-4)'
        end
        
    elseif action == 'add_note' then
        local note = params.note
        if note and note ~= '' then
            exports.oxmysql:execute(
                'UPDATE reckoning_player_profiles SET notes = CONCAT(IFNULL(notes, ""), ?, "\n") WHERE citizenid = ?',
                {os.date('[%Y-%m-%d %H:%M] ') .. note, citizenid}
            )
            success = true
            message = 'Note added successfully'
        else
            message = 'Note cannot be empty'
        end
        
    elseif action == 'trigger_blackline' then
        local eventType = params.eventType or 'interrogation'
        local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(citizenid)
        if targetPlayer then
            TriggerEvent('crp-reckoning:blackline:triggerEvent', targetPlayer.PlayerData.source, eventType)
            success = true
            message = 'Blackline event (' .. eventType .. ') triggered for player'
        else
            message = 'Player not online'
        end
        
    else
        message = 'Unknown action: ' .. action
    end
    
    -- Log admin action
    if Config.AdminPanel.enableAuditLog then
        exports.oxmysql:execute([[
            INSERT INTO reckoning_admin_actions (admin_citizenid, admin_name, action_type, target_citizenid, command_used, parameters, result, source_id)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ]], {
            session.citizenid,
            session.playerName,
            'player_action',
            citizenid,
            'panel_player_action',
            json.encode({action = action, params = params}),
            success and 'success' or 'failed',
            src
        })
    end
    
    TriggerClientEvent('crp-reckoning:admin:playerActionResult', src, {
        success = success,
        message = message
    })
end

function AdminAPI.HandleTriggerEventEvent(src, sessionId, eventType, params)
    local session = activeSessions[sessionId]
    if not session or session.source ~= src then
        TriggerClientEvent('crp-reckoning:admin:triggerEventResult', src, {success = false, error = 'Unauthorized'})
        return
    end
    
    session.lastActivity = os.time()
    
    if not eventType then
        TriggerClientEvent('crp-reckoning:admin:triggerEventResult', src, {success = false, error = 'Missing event type'})
        return
    end
    
    local success = false
    local message = ''
    
    if eventType == 'ghost_division' then
        TriggerEvent('crp-reckoning:server:triggerMilestone', 'ghost_division_deployment')
        success = true
        message = 'Ghost Division deployment initiated'
        
    elseif eventType == 'emergency_broadcast' then
        local broadcastMessage = params.message or 'EMERGENCY: All units report to designated stations immediately.'
        TriggerEvent('crp-reckoning:resistance:emergencyBroadcast', broadcastMessage)
        success = true
        message = 'Emergency broadcast sent: ' .. broadcastMessage
        
    elseif eventType == 'lockdown_zone' then
        local coords = params.coords
        if coords then
            TriggerClientEvent('crp-reckoning:server:activateLockdown', -1, {coords = coords, radius = params.radius or 100})
            success = true
            message = 'Zone lockdown activated at specified coordinates'
        else
            message = 'Missing coordinates for lockdown'
        end
        
    elseif eventType == 'increase_security' then
        TriggerClientEvent('crp-reckoning:server:increaseSecurityLevel', -1)
        success = true
        message = 'Server security level increased'
        
    elseif eventType == 'spawn_blackline_event' then
        local targetPlayerId = params.playerId
        local blacklineType = params.blacklineType or 'interrogation'
        if targetPlayerId then
            TriggerEvent('crp-reckoning:blackline:triggerEvent', targetPlayerId, blacklineType)
            success = true
            message = 'Blackline event spawned for player ' .. targetPlayerId
        else
            message = 'Missing target player ID'
        end
        
    else
        message = 'Unknown event type: ' .. eventType
    end
    
    -- Log admin action
    if Config.AdminPanel.enableAuditLog then
        exports.oxmysql:execute([[
            INSERT INTO reckoning_admin_actions (admin_citizenid, admin_name, action_type, command_used, parameters, result, source_id)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ]], {
            session.citizenid,
            session.playerName,
            'trigger_event',
            'panel_trigger_event',
            json.encode({eventType = eventType, params = params}),
            success and 'success' or 'failed',
            src
        })
    end
    
    TriggerClientEvent('crp-reckoning:admin:triggerEventResult', src, {
        success = success,
        message = message
    })
end

function AdminAPI.HandleRequest(req, res)
    local path = req.path or '/'
    local method = req.method or 'GET'
    
    print('^3[Admin API] Request: ' .. method .. ' ' .. path .. '^7')
    
    -- Set CORS headers
    res.writeHead(200, {
        ['Access-Control-Allow-Origin'] = '*',
        ['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS',
        ['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
    })
    
    -- Handle OPTIONS requests for CORS preflight
    if method == 'OPTIONS' then
        res.send('')
        return
    end
    
    -- Rate limiting
    if not AdminAPI.CheckRateLimit(req) then
        res.writeHead(429, {['Content-Type'] = 'application/json'})
        res.send(json.encode({error = 'Rate limit exceeded'}))
        return
    end
    
    -- Route handling
    if path == '/' or path == '/dashboard' then
        AdminAPI.ServeDashboard(res)
    elseif path == '/js/admin-panel.js' then
        AdminAPI.ServeStaticFile(req, res)
    elseif path == '/api/auth' and method == 'POST' then
        AdminAPI.HandleAuth(req, res)
    elseif path:match('^/api/') then
        -- All other API endpoints require authentication
        local isValid, session = AdminAPI.ValidateSession(req)
        if not isValid then
            res.writeHead(401, {['Content-Type'] = 'application/json'})
            res.send(json.encode({error = 'Unauthorized'}))
            return
        end
        AdminAPI.HandleAPIRequest(req, res)
    else
        res.writeHead(404, {['Content-Type'] = 'text/plain'})
        res.send('404 - Not Found')
    end
end

function AdminAPI.SetCORSHeaders(response)
    response.writeHead(200, {
        ['Access-Control-Allow-Origin'] = '*',
        ['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS',
        ['Access-Control-Allow-Headers'] = 'Content-Type, Authorization',
        ['Content-Type'] = 'application/json'
    })
end

function AdminAPI.CheckRateLimit(request)
    local ip = request.headers['x-forwarded-for'] or request.address
    local now = os.time()
    
    if not rateLimitStore[ip] then
        rateLimitStore[ip] = {count = 1, resetTime = now + 60}
        return true
    end
    
    local store = rateLimitStore[ip]
    
    if now > store.resetTime then
        store.count = 1
        store.resetTime = now + 60
        return true
    end
    
    if store.count >= Config.AdminPanel.rateLimitRequests then
        return false
    end
    
    store.count = store.count + 1
    return true
end

function AdminAPI.HandleAuth(request, response)
    local body = json.decode(request.body or '{}')
    local playerId = body.playerId
    local token = body.token
    
    if not playerId or not token then
        response.writeHead(400, {['Content-Type'] = 'application/json'})
        response.send(json.encode({error = 'Missing credentials'}))
        return
    end
    
    -- Validate with QBCore if enabled
    if Config.AdminPanel.useQBCoreAuth then
        local player = QBCore.Functions.GetPlayer(tonumber(playerId))
        
        if not player then
            response.writeHead(401, {['Content-Type'] = 'application/json'})
            response.send(json.encode({error = 'Player not found'}))
            return
        end
        
        if not QBCore.Functions.HasPermission(tonumber(playerId), Config.AdminPanel.adminPermission) then
            response.writeHead(403, {['Content-Type'] = 'application/json'})
            response.send(json.encode({error = 'Insufficient permissions'}))
            return
        end
        
        -- Create session
        local sessionId = AdminAPI.GenerateSessionId()
        local session = {
            playerId = playerId,
            playerName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
            citizenid = player.PlayerData.citizenid,
            permissions = {'admin'},
            createdAt = os.time(),
            lastActivity = os.time(),
            ipAddress = request.headers['x-forwarded-for'] or request.address
        }
        
        activeSessions[sessionId] = session
        
        -- Log admin login
        if Config.AdminPanel.enableAuditLog then
            local DatabaseManager = exports['countryroadrp-reckoning']:DatabaseManager()
            DatabaseManager.LogSecurityEvent(
                session.citizenid,
                'admin_login',
                'admin',
                'info',
                'Admin panel login',
                nil,
                {session_id = sessionId, ip_address = session.ipAddress}
            )
        end
        
        response.send(json.encode({
            success = true,
            sessionId = sessionId,
            user = {
                name = session.playerName,
                citizenid = session.citizenid,
                permissions = session.permissions
            }
        }))
    else
        response.writeHead(501, {['Content-Type'] = 'application/json'})
        response.send(json.encode({error = 'Authentication method not implemented'}))
    end
end

function AdminAPI.ValidateSession(request)
    local sessionId = request.headers['authorization']
    
    if not sessionId then
        return false
    end
    
    -- Remove 'Bearer ' prefix if present
    sessionId = sessionId:gsub('^Bearer ', '')
    
    local session = activeSessions[sessionId]
    
    if not session then
        return false
    end
    
    -- Check session timeout
    if os.time() - session.lastActivity > Config.AdminPanel.sessionTimeout then
        activeSessions[sessionId] = nil
        return false
    end
    
    -- Update last activity
    session.lastActivity = os.time()
    
    return true, session
end

function AdminAPI.HandleAPIRequest(request, response)
    local path = request.path
    local method = request.method
    local isValid, session = AdminAPI.ValidateSession(request)
    
    if not isValid then
        response.writeHead(401, {['Content-Type'] = 'application/json'})
        response.send(json.encode({error = 'Session expired'}))
        return
    end
    
    -- Route API endpoints
    if path == '/api/dashboard' and method == 'GET' then
        AdminAPI.GetDashboardData(request, response, session)
    elseif path == '/api/players' and method == 'GET' then
        AdminAPI.GetPlayers(request, response, session)
    elseif path == '/api/security-events' and method == 'GET' then
        AdminAPI.GetSecurityEvents(request, response, session)
    elseif path == '/api/tunnel-activity' and method == 'GET' then
        AdminAPI.GetTunnelActivity(request, response, session)
    elseif path == '/api/blackline-events' and method == 'GET' then
        AdminAPI.GetBlacklineEvents(request, response, session)
    elseif path == '/api/resistance-activity' and method == 'GET' then
        AdminAPI.GetResistanceActivity(request, response, session)
    elseif path == '/api/propaganda' and method == 'GET' then
        AdminAPI.GetPropaganda(request, response, session)
    elseif path == '/api/milestones' and method == 'GET' then
        AdminAPI.GetMilestones(request, response, session)
    elseif path == '/api/system-stats' and method == 'GET' then
        AdminAPI.GetSystemStats(request, response, session)
    elseif path:match('/api/player/(.+)') and method == 'GET' then
        local citizenid = path:match('/api/player/(.+)')
        AdminAPI.GetPlayerDetails(request, response, session, citizenid)
    elseif path == '/api/trigger-event' and method == 'POST' then
        AdminAPI.TriggerEvent(request, response, session)
    elseif path == '/api/player-action' and method == 'POST' then
        AdminAPI.PlayerAction(request, response, session)
    elseif path == '/api/search' and method == 'GET' then
        AdminAPI.Search(request, response, session)
    elseif path == '/api/realtime-stats' and method == 'GET' then
        AdminAPI.GetRealtimeStats(request, response, session)
    elseif path == '/api/export' and method == 'GET' then
        AdminAPI.ExportData(request, response, session)
    else
        response.writeHead(404, {['Content-Type'] = 'application/json'})
        response.send(json.encode({error = 'Endpoint not found'}))
    end
end

function AdminAPI.GetDashboardData(request, response, session)
    local DatabaseManager = exports['countryroadrp-reckoning']:DatabaseManager()
    
    -- Get recent security events
    local securityEvents = exports.oxmysql:executeSync(
        'SELECT * FROM view_active_security_events LIMIT 10'
    )
    
    -- Get system statistics
    local systemStats = exports.oxmysql:executeSync(
        'SELECT * FROM reckoning_system_stats ORDER BY category, stat_name'
    )
    
    -- Get active milestones
    local milestones = exports.oxmysql:executeSync(
        'SELECT * FROM reckoning_milestones WHERE status != "completed" ORDER BY milestone_name'
    )
    
    -- Get high-risk players
    local highRiskPlayers = exports.oxmysql:executeSync(
        'SELECT * FROM view_high_risk_players LIMIT 5'
    )
    
    local dashboardData = {
        recentEvents = securityEvents or {},
        systemStats = AdminAPI.FormatSystemStats(systemStats or {}),
        milestones = milestones or {},
        highRiskPlayers = highRiskPlayers or {},
        serverInfo = {
            uptime = GetGameTimer(),
            playerCount = #QBCore.Functions.GetQBPlayers(),
            timestamp = os.time()
        }
    }
    
    response.send(json.encode(dashboardData))
end

function AdminAPI.GetPlayers(request, response, session)
    local page = tonumber(request.query.page) or 1
    local limit = tonumber(request.query.limit) or Config.AdminPanel.maxRecordsPerPage
    local offset = (page - 1) * limit
    
    local players = exports.oxmysql:executeSync(
        'SELECT * FROM reckoning_player_profiles ORDER BY last_activity DESC LIMIT ? OFFSET ?',
        {limit, offset}
    )
    
    local totalCount = exports.oxmysql:executeSync(
        'SELECT COUNT(*) as count FROM reckoning_player_profiles'
    )
    
    response.send(json.encode({
        players = players or {},
        pagination = {
            page = page,
            limit = limit,
            total = totalCount[1] and totalCount[1].count or 0
        }
    }))
end

function AdminAPI.GetSecurityEvents(request, response, session)
    local page = tonumber(request.query.page) or 1
    local limit = tonumber(request.query.limit) or Config.AdminPanel.maxRecordsPerPage
    local severity = request.query.severity
    local citizenid = request.query.citizenid
    local offset = (page - 1) * limit
    
    local whereClause = {}
    local params = {}
    
    if severity then
        table.insert(whereClause, 'severity = ?')
        table.insert(params, severity)
    end
    
    if citizenid then
        table.insert(whereClause, 'citizenid = ?')
        table.insert(params, citizenid)
    end
    
    local whereSQL = #whereClause > 0 and (' WHERE ' .. table.concat(whereClause, ' AND ')) or ''
    
    table.insert(params, limit)
    table.insert(params, offset)
    
    local events = exports.oxmysql:executeSync(
        'SELECT sl.*, pp.player_name FROM reckoning_security_logs sl LEFT JOIN reckoning_player_profiles pp ON sl.citizenid = pp.citizenid' .. whereSQL .. ' ORDER BY sl.timestamp DESC LIMIT ? OFFSET ?',
        params
    )
    
    local totalParams = {}
    for i = 1, #params - 2 do
        table.insert(totalParams, params[i])
    end
    
    local totalCount = exports.oxmysql:executeSync(
        'SELECT COUNT(*) as count FROM reckoning_security_logs sl' .. whereSQL,
        totalParams
    )
    
    response.send(json.encode({
        events = events or {},
        pagination = {
            page = page,
            limit = limit,
            total = totalCount[1] and totalCount[1].count or 0
        }
    }))
end

function AdminAPI.GetTunnelActivity(request, response, session)
    local tunnelActivity = exports.oxmysql:executeSync([[
        SELECT 
            ta.*,
            pp.player_name,
            pp.clearance_level
        FROM reckoning_tunnel_access ta
        LEFT JOIN reckoning_player_profiles pp ON ta.citizenid = pp.citizenid
        ORDER BY ta.entry_time DESC
        LIMIT 100
    ]])
    
    local summary = exports.oxmysql:executeSync('SELECT * FROM view_tunnel_activity_summary')
    
    response.send(json.encode({
        activity = tunnelActivity or {},
        summary = summary or {}
    }))
end

function AdminAPI.GetBlacklineEvents(request, response, session)
    local events = exports.oxmysql:executeSync([[
        SELECT 
            be.*,
            pp.player_name
        FROM reckoning_blackline_events be
        LEFT JOIN reckoning_player_profiles pp ON be.citizenid = pp.citizenid
        ORDER BY be.start_time DESC
        LIMIT 100
    ]])
    
    response.send(json.encode({
        events = events or {}
    }))
end

function AdminAPI.GetResistanceActivity(request, response, session)
    local activity = exports.oxmysql:executeSync([[
        SELECT * FROM reckoning_resistance_activity
        ORDER BY timestamp DESC
        LIMIT 100
    ]])
    
    response.send(json.encode({
        activity = activity or {}
    }))
end

function AdminAPI.GetPropaganda(request, response, session)
    local propaganda = exports.oxmysql:executeSync([[
        SELECT * FROM reckoning_propaganda
        ORDER BY broadcast_time DESC
        LIMIT 100
    ]])
    
    response.send(json.encode({
        propaganda = propaganda or {}
    }))
end

function AdminAPI.GetMilestones(request, response, session)
    local milestones = exports.oxmysql:executeSync([[
        SELECT * FROM reckoning_milestones
        ORDER BY status ASC, milestone_name ASC
    ]])
    
    response.send(json.encode({
        milestones = milestones or {}
    }))
end

function AdminAPI.GetSystemStats(request, response, session)
    local stats = exports.oxmysql:executeSync([[
        SELECT * FROM reckoning_system_stats
        ORDER BY category, stat_name
    ]])
    
    response.send(json.encode({
        stats = AdminAPI.FormatSystemStats(stats or {})
    }))
end

function AdminAPI.GetPlayerDetails(request, response, session, citizenid)
    local player = exports.oxmysql:executeSync(
        'SELECT * FROM reckoning_player_profiles WHERE citizenid = ?',
        {citizenid}
    )
    
    if not player or #player == 0 then
        response.writeHead(404, {['Content-Type'] = 'application/json'})
        response.send(json.encode({error = 'Player not found'}))
        return
    end
    
    local securityEvents = exports.oxmysql:executeSync(
        'SELECT * FROM reckoning_security_logs WHERE citizenid = ? ORDER BY timestamp DESC LIMIT 50',
        {citizenid}
    )
    
    local tunnelAccess = exports.oxmysql:executeSync(
        'SELECT * FROM reckoning_tunnel_access WHERE citizenid = ? ORDER BY entry_time DESC LIMIT 20',
        {citizenid}
    )
    
    local blacklineEvents = exports.oxmysql:executeSync(
        'SELECT * FROM reckoning_blackline_events WHERE citizenid = ? ORDER BY start_time DESC LIMIT 20',
        {citizenid}
    )
    
    response.send(json.encode({
        player = player[1],
        securityEvents = securityEvents or {},
        tunnelAccess = tunnelAccess or {},
        blacklineEvents = blacklineEvents or {}
    }))
end

function AdminAPI.TriggerEvent(request, response, session)
    local body = json.decode(request.body or '{}')
    local eventType = body.eventType
    local params = body.params or {}
    
    if not eventType then
        response.writeHead(400, {['Content-Type'] = 'application/json'})
        response.send(json.encode({error = 'Missing event type'}))
        return
    end
    
    local success = false
    local message = ''
    
    if eventType == 'ghost_division' then
        TriggerEvent('crp-reckoning:server:triggerMilestone', 'ghost_division_deployment')
        success = true
        message = 'Ghost Division deployment initiated'
        
    elseif eventType == 'emergency_broadcast' then
        local broadcastMessage = params.message or 'EMERGENCY: All units report to designated stations immediately.'
        local ResistanceRadio = exports['countryroadrp-reckoning']:GetActiveBroadcast()
        exports['countryroadrp-reckoning']:TriggerEmergencyBroadcast(broadcastMessage)
        success = true
        message = 'Emergency broadcast sent'
        
    elseif eventType == 'lockdown_zone' then
        local coords = params.coords
        if coords then
            TriggerClientEvent('crp-reckoning:server:activateLockdown', -1, {coords = coords})
            success = true
            message = 'Zone lockdown activated'
        else
            message = 'Missing coordinates for lockdown'
        end
        
    elseif eventType == 'increase_security' then
        TriggerClientEvent('crp-reckoning:server:increaseSecurityLevel', -1)
        success = true
        message = 'Security level increased'
        
    else
        message = 'Unknown event type'
    end
    
    -- Log admin action
    if Config.AdminPanel.enableAuditLog then
        exports.oxmysql:execute([[
            INSERT INTO reckoning_admin_actions (admin_citizenid, admin_name, action_type, command_used, parameters, result, ip_address)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ]], {
            session.citizenid,
            session.playerName,
            'trigger_event',
            'api_trigger_event',
            json.encode({eventType = eventType, params = params}),
            success and 'success' or 'failed',
            session.ipAddress
        })
    end
    
    response.send(json.encode({
        success = success,
        message = message
    }))
end

function AdminAPI.PlayerAction(request, response, session)
    local body = json.decode(request.body or '{}')
    local action = body.action
    local citizenid = body.citizenid
    local params = body.params or {}
    
    if not action or not citizenid then
        response.writeHead(400, {['Content-Type'] = 'application/json'})
        response.send(json.encode({error = 'Missing action or citizenid'}))
        return
    end
    
    local success = false
    local message = ''
    
    if action == 'update_suspicion' then
        local newLevel = tonumber(params.suspicionLevel)
        if newLevel and newLevel >= 0 and newLevel <= 100 then
            exports.oxmysql:execute(
                'CALL UpdatePlayerSuspicion(?, ?, ?)',
                {citizenid, newLevel, 'Admin adjustment'}
            )
            success = true
            message = 'Suspicion level updated'
        else
            message = 'Invalid suspicion level'
        end
        
    elseif action == 'update_clearance' then
        local newLevel = tonumber(params.clearanceLevel)
        if newLevel and newLevel >= 0 and newLevel <= 4 then
            exports.oxmysql:execute(
                'UPDATE reckoning_player_profiles SET clearance_level = ? WHERE citizenid = ?',
                {newLevel, citizenid}
            )
            success = true
            message = 'Clearance level updated'
        else
            message = 'Invalid clearance level'
        end
        
    elseif action == 'add_note' then
        local note = params.note
        if note and note ~= '' then
            exports.oxmysql:execute(
                'UPDATE reckoning_player_profiles SET notes = CONCAT(IFNULL(notes, ""), ?, "\n") WHERE citizenid = ?',
                {os.date('[%Y-%m-%d %H:%M] ') .. note, citizenid}
            )
            success = true
            message = 'Note added'
        else
            message = 'Note cannot be empty'
        end
        
    elseif action == 'trigger_blackline' then
        local eventType = params.eventType or 'interrogation'
        local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(citizenid)
        if targetPlayer then
            TriggerEvent('crp-reckoning:blackline:triggerEvent', targetPlayer.PlayerData.source, eventType)
            success = true
            message = 'Blackline event triggered'
        else
            message = 'Player not online'
        end
        
    else
        message = 'Unknown action'
    end
    
    -- Log admin action
    if Config.AdminPanel.enableAuditLog then
        exports.oxmysql:execute([[
            INSERT INTO reckoning_admin_actions (admin_citizenid, admin_name, action_type, target_citizenid, command_used, parameters, result, ip_address)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ]], {
            session.citizenid,
            session.playerName,
            'player_action',
            citizenid,
            'api_player_action',
            json.encode({action = action, params = params}),
            success and 'success' or 'failed',
            session.ipAddress
        })
    end
    
    response.send(json.encode({
        success = success,
        message = message
    }))
end

function AdminAPI.Search(request, response, session)
    local query = request.query.q
    local type = request.query.type or 'all'
    
    if not query or query == '' then
        response.writeHead(400, {['Content-Type'] = 'application/json'})
        response.send(json.encode({error = 'Missing search query'}))
        return
    end
    
    local results = {}
    
    if type == 'all' or type == 'players' then
        local players = exports.oxmysql:executeSync([[
            SELECT citizenid, player_name, job_name, suspicion_level 
            FROM reckoning_player_profiles 
            WHERE player_name LIKE ? OR citizenid LIKE ?
            LIMIT 20
        ]], {'%' .. query .. '%', '%' .. query .. '%'})
        
        results.players = players or {}
    end
    
    if type == 'all' or type == 'events' then
        local events = exports.oxmysql:executeSync([[
            SELECT sl.*, pp.player_name
            FROM reckoning_security_logs sl
            LEFT JOIN reckoning_player_profiles pp ON sl.citizenid = pp.citizenid
            WHERE sl.description LIKE ? OR sl.event_type LIKE ? OR pp.player_name LIKE ?
            ORDER BY sl.timestamp DESC
            LIMIT 20
        ]], {'%' .. query .. '%', '%' .. query .. '%', '%' .. query .. '%'})
        
        results.events = events or {}
    end
    
    response.send(json.encode(results))
end

function AdminAPI.GetRealtimeStats(request, response, session)
    local players = QBCore.Functions.GetQBPlayers()
    local onlineCount = #players
    local activeEvents = 0
    
    -- Count active blackline events
    local blacklineEvents = exports['countryroadrp-reckoning']:GetActiveEvents()
    if blacklineEvents then
        for _, _ in pairs(blacklineEvents) do
            activeEvents = activeEvents + 1
        end
    end
    
    -- Get recent activity (last 5 minutes)
    local recentActivity = exports.oxmysql:executeSync([[
        SELECT COUNT(*) as count FROM reckoning_security_logs 
        WHERE timestamp >= DATE_SUB(NOW(), INTERVAL 5 MINUTE)
    ]])
    
    local recentCount = recentActivity[1] and recentActivity[1].count or 0
    
    response.send(json.encode({
        onlinePlayers = onlineCount,
        activeEvents = activeEvents,
        recentActivity = recentCount,
        timestamp = os.time(),
        systemUptime = GetGameTimer()
    }))
end

function AdminAPI.ExportData(request, response, session)
    local dataType = request.query.type
    local format = request.query.format or 'json'
    
    if not dataType then
        response.writeHead(400, {['Content-Type'] = 'application/json'})
        response.send(json.encode({error = 'Missing data type'}))
        return
    end
    
    local data = {}
    local filename = ''
    
    if dataType == 'security_logs' then
        data = exports.oxmysql:executeSync([[
            SELECT sl.*, pp.player_name
            FROM reckoning_security_logs sl
            LEFT JOIN reckoning_player_profiles pp ON sl.citizenid = pp.citizenid
            WHERE sl.timestamp >= DATE_SUB(NOW(), INTERVAL 30 DAY)
            ORDER BY sl.timestamp DESC
        ]])
        filename = 'security_logs_' .. os.date('%Y%m%d') .. '.json'
        
    elseif dataType == 'player_profiles' then
        data = exports.oxmysql:executeSync('SELECT * FROM reckoning_player_profiles')
        filename = 'player_profiles_' .. os.date('%Y%m%d') .. '.json'
        
    else
        response.writeHead(400, {['Content-Type'] = 'application/json'})
        response.send(json.encode({error = 'Invalid data type'}))
        return
    end
    
    response.writeHead(200, {
        ['Content-Type'] = 'application/octet-stream',
        ['Content-Disposition'] = 'attachment; filename="' .. filename .. '"'
    })
    response.send(json.encode(data, {indent = true}))
end

function AdminAPI.FormatSystemStats(stats)
    local formatted = {}
    
    for _, stat in ipairs(stats) do
        if not formatted[stat.category] then
            formatted[stat.category] = {}
        end
        
        formatted[stat.category][stat.stat_name] = {
            value = stat.stat_value,
            type = stat.stat_type,
            lastUpdated = stat.last_updated
        }
    end
    
    return formatted
end

function AdminAPI.ServeDashboard(response)
    AdminAPI.ServeStaticFile({path = '/admin-panel.html'}, response)
end

function AdminAPI.ServeStaticFile(request, response)
    local path = request.path
    
    -- Default to admin panel
    if path == '/' or path == '/dashboard' then
        path = '/admin-panel.html'
    end
    
    -- Map file paths and content types
    local fileName = nil
    local contentType = 'text/html'
    
    if path == '/admin-panel.html' then
        fileName = 'web/admin-panel.html'
        contentType = 'text/html'
    elseif path == '/js/admin-panel.js' then
        fileName = 'web/js/admin-panel.js'
        contentType = 'application/javascript'
    else
        response.writeHead(404, {['Content-Type'] = 'text/plain'})
        response.send('File not found')
        return
    end
    
    -- Use LoadResourceFile instead of io.open
    local content = LoadResourceFile(GetCurrentResourceName(), fileName)
    
    if content then
        response.writeHead(200, {['Content-Type'] = contentType})
        response.send(content)
    else
        response.writeHead(404, {['Content-Type'] = 'text/plain'})
        response.send('File not found: ' .. fileName)
    end
end

function AdminAPI.GenerateSessionId()
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
    local sessionId = ''
    
    for i = 1, 32 do
        local rand = math.random(#chars)
        sessionId = sessionId .. string.sub(chars, rand, rand)
    end
    
    return sessionId
end

function AdminAPI.StartSessionCleanup()
    CreateThread(function()
        while true do
            Wait(60000) -- Check every minute
            
            local now = os.time()
            for sessionId, session in pairs(activeSessions) do
                if now - session.lastActivity > Config.AdminPanel.sessionTimeout then
                    activeSessions[sessionId] = nil
                end
            end
        end
    end)
end

-- Export functions
exports('AdminAPI', function()
    return AdminAPI
end)

-- Initialize on resource start
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        Wait(1000) -- Give other systems time to start
        print('^3[Admin API] Starting initialization...^7')
        local success = AdminAPI.Initialize()
        if success then
            print('^2[Admin API] Successfully initialized^7')
        else
            print('^1[Admin API] Failed to initialize^7')
        end
    end
end)

return AdminAPI
