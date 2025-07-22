# Installation Guide - Country Road RP: Reckoning

Complete setup guide for the Season 1 narrative system with admin panel integration.

## 📋 Prerequisites

### Required Dependencies
- **FiveM Server** (latest build recommended)
- **QBCore Framework** (latest version)
- **oxmysql** (for database operations)
- **MySQL/MariaDB** database server

### Optional Dependencies
- **Discord Bot/Webhooks** (for logging integration)
- **pma-voice** (for radio system integration)

## 🗃️ Database Setup

### 1. Create Database Schema
Run the SQL setup script to create all required tables:

```bash
# Navigate to the database directory
cd resources/countryroadrp-reckoning/database/

# Execute the setup script
mysql -u your_username -p your_database < setup.sql
```

### 2. Verify Database Structure
Ensure all tables were created successfully:
- `reckoning_player_profiles`
- `reckoning_security_logs`
- `reckoning_tunnel_access`
- `reckoning_blackline_events`
- `reckoning_resistance_activity`
- `reckoning_propaganda`
- `reckoning_milestones`
- `reckoning_system_stats`
- `reckoning_admin_actions`

### 3. Database Views
The following views should be automatically created:
- `view_active_security_events`
- `view_high_risk_players`
- `view_tunnel_activity_summary`

## ⚙️ Configuration

### 1. Basic Configuration
Edit `config.lua` to match your server setup:

```lua
-- Core Settings
Config.Debug = false  -- Set to true for development
Config.FrameworkName = 'qb-core'

-- Database Configuration (handled by oxmysql)
-- Ensure oxmysql is configured in your server.cfg
```

### 2. Discord Integration
Configure Discord webhooks in `config.lua`:

```lua
Config.Discord = {
    enabled = true,
    webhooks = {
        security = "YOUR_SECURITY_WEBHOOK_URL",
        tunnel = "YOUR_TUNNEL_WEBHOOK_URL",
        resistance = "YOUR_RESISTANCE_WEBHOOK_URL",
        admin = "YOUR_ADMIN_WEBHOOK_URL"
    }
}
```

See [DISCORD_SETUP.md](DISCORD_SETUP.md) for detailed webhook configuration.

### 3. Admin Panel Setup
Configure admin panel access:

```lua
Config.AdminPanel = {
    enabled = true,
    useQBCoreAuth = true,
    adminPermission = 'admin',  -- QBCore permission level required
    sessionTimeout = 3600,     -- 1 hour
    enableAuditLog = true
}
```

## 📦 Installation Steps

### 1. Download and Extract
```bash
# Place in your resources folder
cd /path/to/fivem/resources/
git clone [repository-url] countryroadrp-reckoning
```

### 2. Server Configuration
Add to your `server.cfg`:

```cfg
# Add the resource
ensure countryroadrp-reckoning

# Ensure dependencies are loaded first
ensure qb-core
ensure oxmysql

# Optional: Configure oxmysql if not already done
set mysql_connection_string "mysql://username:password@localhost/database_name"
```

### 3. Permissions Setup
Configure QBCore permissions for admin access:

```lua
-- In qb-core/shared/permissions.lua or your permission system
Config.Permissions = {
    ['admin'] = {
        level = 100,
        commands = {'all'},
        description = 'Full Administrator Access'
    }
}
```

## 🎛️ Admin Panel Access

### URL Access
The admin panel is accessible via:
```
http://your-server-ip:30120/countryroadrp-reckoning/web/admin-panel.html
```

### Authentication
1. **Player ID**: Your FiveM server ID (visible in F8 console with `whoami`)
2. **Token**: Currently uses a simple token system (can be enhanced)
3. **QBCore Permission**: Must have 'admin' permission level

### First Time Setup
1. Ensure you have admin permissions in QBCore
2. Start the resource: `/restart countryroadrp-reckoning`
3. Access the admin panel URL
4. Authenticate with your player ID and token

## 🧪 Testing Installation

### 1. Basic Functionality Test
```lua
-- In server console or F8 console (admin only)
/restart countryroadrp-reckoning

-- Check for startup messages
-- Should see: "[Admin API] Successfully initialized"
```

### 2. Database Connection Test
```sql
-- Check if data is being logged
SELECT COUNT(*) FROM reckoning_security_logs;
SELECT COUNT(*) FROM reckoning_player_profiles;
```

### 3. Admin Panel Test
1. Access admin panel URL
2. Authenticate successfully
3. Verify dashboard loads with server data
4. Check real-time updates are working

## 🔧 Troubleshooting

### Common Issues

#### Admin Panel Won't Load
- **Check resource files**: Ensure `web/` folder exists with HTML/JS files
- **Verify fxmanifest.lua**: Files should be listed in `files` section
- **Check console**: Look for resource loading errors

#### Authentication Fails
- **QBCore permissions**: Verify admin permission is properly set
- **Player ID**: Use correct server ID, not Steam ID
- **Database connection**: Ensure oxmysql is working properly

#### Database Errors
- **Connection string**: Verify oxmysql configuration
- **Table structure**: Re-run setup.sql if tables are missing
- **Permissions**: Ensure database user has proper privileges

#### Discord Integration Not Working
- **Webhook URLs**: Verify Discord webhook URLs are valid
- **Rate limits**: Discord webhooks have rate limits (5 requests per second)
- **JSON formatting**: Check Discord embed formatting in logs

### Debug Mode
Enable debug mode for detailed logging:

```lua
Config.Debug = true
```

This will show detailed console output for troubleshooting.

### Log Files
Check FiveM server console for error messages:
- Resource loading errors
- Database connection issues
- Event registration problems
- Client-server communication errors

## 📞 Support

### Getting Help
1. **Check Console**: Always check server console for error messages
2. **Debug Mode**: Enable debug mode for detailed logging
3. **Database Logs**: Check database connection and query logs
4. **Discord Integration**: Verify webhook functionality

### Performance Optimization
- **Database Cleanup**: Regularly clean old logs to maintain performance
- **Memory Usage**: Monitor resource memory usage in production
- **Rate Limiting**: Be aware of Discord webhook rate limits

### Security Considerations
- **Admin Access**: Properly secure admin panel access
- **Database Security**: Use strong database credentials
- **Discord Webhooks**: Keep webhook URLs private
- **Audit Logging**: Monitor admin actions via audit logs

---

## ✅ Installation Checklist

- [ ] FiveM server with QBCore installed
- [ ] MySQL/MariaDB database running
- [ ] oxmysql dependency configured
- [ ] Database schema created (setup.sql)
- [ ] Discord webhooks configured (optional)
- [ ] Resource added to server.cfg
- [ ] Admin permissions configured
- [ ] Resource started successfully
- [ ] Admin panel accessible and functional
- [ ] Database logging working
- [ ] Discord integration working (if enabled)

**Once all items are checked, your Country Road RP: Reckoning system is ready!**
