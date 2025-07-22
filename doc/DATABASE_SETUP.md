# Database Setup Guide for Country Road RP - Reckoning

## Prerequisites
- MySQL/MariaDB server running
- phpMyAdmin or similar database management tool (optional)
- FiveM server with oxmysql resource

## 🗄️ Database Installation

### Step 1: Create Database
1. Access your MySQL server
2. Run the SQL file: `database/setup.sql`
3. This will create the `crp_reckoning` database with all required tables

```bash
mysql -u root -p < database/setup.sql
```

### Step 2: Configure Database Connection
Edit `config.lua` and update database settings:

```lua
Config.Database = {
    enabled = true,
    host = 'localhost',      -- Your MySQL host
    port = 3306,            -- MySQL port
    database = 'crp_reckoning',
    username = 'your_username',
    password = 'your_password',
    charset = 'utf8mb4',
    debug = false
}
```

### Step 3: Test Connection
1. Start your FiveM server
2. Check console for: `[Database Manager] Successfully connected to database`
3. If connection fails, verify credentials and MySQL server status

## 📊 Database Schema Overview

### Core Tables

**`reckoning_player_profiles`**
- Stores player security profiles, clearance levels, and suspicion ratings
- Automatically created when players first interact with systems

**`reckoning_security_logs`**
- Comprehensive logging of all security events
- Includes location data, severity levels, and metadata

**`reckoning_tunnel_access`**
- Tracks all TRENCHGLASS tunnel access attempts
- Records entry/exit times, clearance used, and access results

**`reckoning_blackline_events`**
- Logs all Blackline correction events (interrogation, memory wipe, surveillance)
- Tracks duration, outcomes, and agent deployment

**`reckoning_resistance_activity`**
- Records resistance broadcasts, interceptions, and activities
- Includes signal strength and detection status

**`reckoning_npc_agents`**
- Manages spawned NPC agents and their status
- Tracks exposures and mission objectives

**`reckoning_propaganda`**
- Logs all Northbridge propaganda broadcasts
- Tracks effectiveness and audience metrics

**`reckoning_milestones`**
- Server-wide story progression tracking
- Manages trigger counts and completion status

**`reckoning_admin_actions`**
- Audit log for all administrative actions
- Includes IP addresses and detailed parameters

**`reckoning_system_stats`**
- Real-time system statistics and metrics
- Performance monitoring and analytics

### Views and Procedures

**Views:**
- `view_active_security_events` - Recent 24h security events with player data
- `view_high_risk_players` - Players with high suspicion/violation counts
- `view_tunnel_activity_summary` - Tunnel usage statistics by zone

**Stored Procedures:**
- `UpdatePlayerSuspicion()` - Safely update player suspicion levels with logging
- `LogSecurityEvent()` - Comprehensive security event logging with auto-updates

## 🔧 Admin Panel Setup

### Step 1: Enable Admin Panel
```lua
Config.AdminPanel = {
    enabled = true,
    port = 8080,              -- Web interface port
    host = '0.0.0.0',         -- Listen on all interfaces
    useQBCoreAuth = true,     -- Use QBCore permissions
    adminPermission = 'admin' -- Required permission level
}
```

### Step 2: Configure Firewall
- Open port 8080 (or your chosen port) in server firewall
- For production, consider using reverse proxy (nginx/apache)

### Step 3: Access Admin Panel
- Navigate to: `http://your-server-ip:8080`
- Login with your QBCore admin credentials
- Player ID and QBCore token required

## 📈 Performance Optimization

### Indexing
The setup script creates optimized indexes for:
- Recent event queries (timestamp-based)
- Player lookups (citizenid)
- Security event filtering (severity, category)

### Data Retention
Configure automatic cleanup in `config.lua`:
```lua
Config.Database.retention = {
    security_logs = 30,      -- Keep 30 days
    blackline_events = 90,   -- Keep 90 days
    tunnel_access = 60,      -- Keep 60 days
    propaganda = 15,         -- Keep 15 days
    admin_actions = 365      -- Keep 1 year
}
```

### Batch Operations
Enable batch processing for high-volume servers:
```lua
Config.Performance = {
    batchInsertSize = 50,     -- Batch size for inserts
    asyncOperations = true,   -- Use async database ops
    cachePlayerData = true,   -- Cache frequently accessed data
    cacheTimeout = 300        -- Cache timeout (seconds)
}
```

## 🚨 Troubleshooting

### Connection Issues
1. **Error: Access denied**
   - Check username/password in config
   - Verify MySQL user has database access
   - Ensure MySQL server is running

2. **Error: Database not found**
   - Run `database/setup.sql` script
   - Check database name matches config

3. **Error: Table doesn't exist**
   - Re-run setup script
   - Check for SQL execution errors

### Performance Issues
1. **Slow queries**
   - Check database indexes are created
   - Monitor MySQL slow query log
   - Consider upgrading server resources

2. **High memory usage**
   - Reduce cache timeout
   - Disable player data caching
   - Adjust batch sizes

### Admin Panel Issues
1. **Cannot access web interface**
   - Check port is open in firewall
   - Verify server is listening on correct interface
   - Check server console for HTTP server startup messages

2. **Authentication fails**
   - Verify QBCore permissions
   - Check player ID and token
   - Ensure admin permission level is correct

## 🔒 Security Considerations

### Database Security
- Use dedicated MySQL user with minimal privileges
- Enable SSL connections if database is remote
- Regular backups of critical data

### Web Interface Security
- Change default port from 8080
- Use reverse proxy with SSL
- Implement IP whitelisting for admin access
- Enable audit logging for all actions

### Data Protection
- Regularly backup player profiles and logs
- Monitor for unusual database activity
- Implement log rotation for large datasets

## 📋 Maintenance Tasks

### Daily
- Monitor system statistics
- Check error logs
- Review security alerts

### Weekly
- Backup database
- Review admin action logs
- Clean up old temporary data

### Monthly
- Analyze player behavior patterns
- Update security thresholds
- Performance optimization review

---

For additional support with database setup, consult your hosting provider's MySQL documentation or contact the Country Road RP development team.
