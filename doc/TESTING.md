# Testing Guide - Country Road RP: Reckoning

Comprehensive testing procedures for all system components.

## 🎯 Testing Overview

This guide covers testing procedures for:
- Core system functionality
- Admin panel operations
- Database integration
- Discord logging
- Player interactions
- Performance monitoring

## 🔧 Pre-Testing Setup

### 1. Enable Debug Mode
```lua
-- In config.lua
Config.Debug = true
```

### 2. Admin Permissions
Ensure test admin has proper permissions:
```
/addpermission [playerId] admin
```

### 3. Database Access
Verify database connection:
```sql
SHOW TABLES LIKE 'reckoning_%';
```

## 🧪 System Component Tests

### TRENCHGLASS Tunnel System

#### Manual Testing
```lua
-- Test tunnel entrance detection
-- Go to coordinates: 1210.5, -620.8, 63.0 (East Vinewood)
-- Expected: Environmental effects activate, GPS disabled

-- Test access control
-- Without clearance: Should be blocked
-- With clearance: Should allow entry
```

#### Console Commands
```lua
-- Server console
TriggerEvent('crp-reckoning:tunnel:debugAccess', playerId, tunnelId)

-- Client console (F8)
TriggerEvent('crp-reckoning:tunnel:testEffects')
```

#### Expected Behaviors
- [ ] Fog effects activate in tunnel zones
- [ ] GPS/radar disabled underground
- [ ] Access control based on job/clearance
- [ ] Database logging of tunnel access
- [ ] Discord notifications (if enabled)

### Blackline Correction Events

#### Trigger Test Event
```lua
-- Server console
TriggerEvent('crp-reckoning:blackline:triggerEvent', playerId, 'interrogation')
```

#### Event Types Testing
```lua
-- Test each event type
TriggerEvent('crp-reckoning:blackline:triggerEvent', playerId, 'memory_wipe')
TriggerEvent('crp-reckoning:blackline:triggerEvent', playerId, 'surveillance')
```

#### Expected Behaviors
- [ ] Random NPC spawning
- [ ] Player screen effects during events
- [ ] Memory simulation (screen fade, confusion)
- [ ] Database event logging
- [ ] Configurable duration timing

### Resistance Radio Network

#### Test Radio Broadcast
```lua
-- Server console
TriggerEvent('crp-reckoning:radio:testBroadcast', 'This is a test broadcast')
```

#### Signal Testing
```lua
-- Test signal strength simulation
TriggerEvent('crp-reckoning:radio:testSignal', playerId, signalStrength)
```

#### Expected Behaviors
- [ ] Radio broadcasts to all players
- [ ] Signal strength affects clarity
- [ ] Interference effects in certain areas
- [ ] Emergency broadcast capability
- [ ] Activity logging to database

### NPC Handler System

#### Spawn Test NPC
```lua
-- Server console
TriggerEvent('crp-reckoning:npc:spawnAgent', x, y, z, 'disguise_type')
```

#### Test Exposure Mechanics
```lua
-- Test NPC exposure detection
TriggerEvent('crp-reckoning:npc:testExposure', npcId, playerId)
```

#### Expected Behaviors
- [ ] NPCs spawn with proper disguises
- [ ] Exposure mechanic works correctly
- [ ] NPCs despawn after exposure
- [ ] Security alerts generated
- [ ] Database logging of interactions

### Access Control Framework

#### Test Clearance Levels
```lua
-- Set player clearance level
TriggerServerEvent('crp-reckoning:access:setClearance', playerId, 3)

-- Test zone access
TriggerEvent('crp-reckoning:access:testZone', playerId, zoneId)
```

#### Expected Behaviors
- [ ] Clearance levels properly enforced
- [ ] Zone access restrictions work
- [ ] Job-based access control
- [ ] Temporary access grants
- [ ] Violation logging

## 🖥️ Admin Panel Testing

### Authentication Testing

#### Valid Login Test
1. Access admin panel URL
2. Enter valid player ID and token
3. Should successfully authenticate

#### Invalid Login Test
1. Enter invalid credentials
2. Should show error message
3. Should not grant access

#### Session Management
1. Login successfully
2. Wait for session timeout (or modify timeout for testing)
3. Should require re-authentication

### Dashboard Functionality

#### Dashboard Load Test
```javascript
// In browser console on admin panel
callAPI('getDashboard', {sessionId: 'your_session_id'});
```

#### Real-time Updates
1. Trigger events in-game
2. Verify dashboard updates automatically
3. Check refresh intervals

#### Widget Testing
- [ ] Server statistics display correctly
- [ ] Recent security events load
- [ ] High-risk players list populated
- [ ] Milestone progress accurate
- [ ] Real-time player count updates

### API Endpoint Testing

#### Player Management
```javascript
// Test player data retrieval
callAPI('getPlayers', {sessionId: sessionId, page: 1, limit: 10});

// Test player actions
callAPI('playerAction', {
    sessionId: sessionId,
    action: 'update_suspicion',
    citizenid: 'TEST123',
    params: {suspicionLevel: 50}
});
```

#### Security Events
```javascript
// Test security event filtering
callAPI('getSecurityEvents', {
    sessionId: sessionId,
    page: 1,
    limit: 10,
    severity: 'high'
});
```

## 💾 Database Testing

### Data Integrity Tests

#### Player Profile Creation
```sql
-- Test player profile auto-creation
SELECT * FROM reckoning_player_profiles WHERE citizenid = 'TEST123';
```

#### Security Event Logging
```sql
-- Verify security events are logged
SELECT COUNT(*) FROM reckoning_security_logs 
WHERE timestamp > DATE_SUB(NOW(), INTERVAL 1 HOUR);
```

#### Data Relationships
```sql
-- Test foreign key relationships
SELECT pp.player_name, COUNT(sl.id) as event_count
FROM reckoning_player_profiles pp
LEFT JOIN reckoning_security_logs sl ON pp.citizenid = sl.citizenid
GROUP BY pp.citizenid;
```

### Database Views Testing
```sql
-- Test active security events view
SELECT * FROM view_active_security_events LIMIT 10;

-- Test high-risk players view
SELECT * FROM view_high_risk_players LIMIT 10;

-- Test tunnel activity summary
SELECT * FROM view_tunnel_activity_summary;
```

### Stored Procedures Testing
```sql
-- Test suspicion update procedure
CALL UpdatePlayerSuspicion('TEST123', 75, 'Admin test adjustment');

-- Test cleanup procedures
CALL CleanupOldLogs(30); -- Cleanup logs older than 30 days
```

## 📢 Discord Integration Testing

### Webhook Testing

#### Security Events
```lua
-- Trigger a security event
TriggerEvent('crp-reckoning:security:testEvent', playerId, 'tunnel_breach', 'high')
```

#### Admin Actions
```lua
-- Test admin action logging
-- Perform any admin action through panel
-- Check Discord admin channel for notification
```

#### Manual Webhook Test
```lua
-- Server console
local DiscordLogger = exports['countryroadrp-reckoning']:DiscordLogger()
DiscordLogger.LogSecurityEvent('TEST123', 'test_event', 'system', 'info', 'Test message', nil, {test = true})
```

### Expected Discord Behaviors
- [ ] Security events posted to security channel
- [ ] Tunnel access logged to tunnel channel
- [ ] Resistance activity to resistance channel
- [ ] Admin actions to admin channel
- [ ] Proper embed formatting
- [ ] Color coding by severity

## 🚀 Performance Testing

### Load Testing

#### Multiple Player Simulation
```lua
-- Test with multiple players in tunnels
for i = 1, 10 do
    TriggerEvent('crp-reckoning:tunnel:simulatePlayer', 'TEST' .. i)
end
```

#### Database Load Testing
```sql
-- Insert test data for performance testing
INSERT INTO reckoning_security_logs (citizenid, event_type, severity, description, timestamp)
SELECT 
    CONCAT('TEST', FLOOR(RAND() * 1000)),
    'test_event',
    'medium',
    'Performance test event',
    DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 30) DAY)
FROM 
    (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) t1,
    (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) t2,
    (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) t3;
```

### Memory Usage Testing
```lua
-- Monitor resource memory usage
-- Check FiveM resource monitor or use:
collectgarbage("collect")
print("Memory usage: " .. collectgarbage("count") .. " KB")
```

## 🐛 Error Testing

### Invalid Input Testing

#### API Error Handling
```javascript
// Test invalid session ID
callAPI('getDashboard', {sessionId: 'invalid_session'});

// Test missing parameters
callAPI('playerAction', {sessionId: sessionId}); // Missing action
```

#### Database Error Simulation
```lua
-- Test database connection loss
-- Temporarily stop MySQL service
-- Verify graceful error handling
```

### Edge Case Testing

#### Player Edge Cases
```lua
-- Test with non-existent player
TriggerEvent('crp-reckoning:tunnel:access', 99999)

-- Test with invalid coordinates
TriggerEvent('crp-reckoning:tunnel:checkAccess', 0, 0, 0)
```

#### Data Validation
```sql
-- Test with invalid data types
INSERT INTO reckoning_player_profiles (citizenid, suspicion_level) 
VALUES ('TEST', 'not_a_number'); -- Should fail
```

## ✅ Testing Checklist

### Pre-Production Testing
- [ ] All system components function correctly
- [ ] Admin panel loads and authenticates properly
- [ ] Database operations work without errors
- [ ] Discord integration sends notifications
- [ ] Performance is acceptable under load
- [ ] Error handling works for edge cases
- [ ] Security permissions are properly enforced
- [ ] Data integrity is maintained
- [ ] Real-time features update correctly
- [ ] Cleanup procedures work as expected

### Production Readiness
- [ ] Debug mode disabled
- [ ] Production database configured
- [ ] Discord webhooks working
- [ ] Admin permissions secured
- [ ] Performance monitoring in place
- [ ] Backup procedures tested
- [ ] Error logging configured
- [ ] Documentation complete

## 📊 Test Reports

### Automated Testing
Create test scripts for repeated testing:

```lua
-- test_script.lua
local Tests = {}

function Tests.RunAllTests()
    Tests.TestTunnelSystem()
    Tests.TestBlacklineEvents()
    Tests.TestRadioSystem()
    Tests.TestDatabase()
    Tests.TestAdminPanel()
end

function Tests.TestTunnelSystem()
    print("Testing tunnel system...")
    -- Add specific test logic
end

-- Continue for other systems...
```

### Manual Test Results
Document test results in a structured format:

```
Test: Admin Panel Authentication
Date: [Date]
Tester: [Name]
Result: PASS/FAIL
Notes: [Any observations]
Issues: [List any problems found]
```

---

**Remember to test thoroughly before deploying to production servers!**
