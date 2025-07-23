# Country Road RP - Season 1: Reckoning

A comprehensive FiveM QBCore script for immersive narrative roleplay featuring secret operations, corporate espionage, resistance movements, and a complete web-based administration system.

## 🎭 Narrative Overview

**Setting:** Los Santos, present day  
**Hidden Antagonist:** Merryweather (operating as "Northbridge Solutions")  
**Core Mystery:** The Blackline Protocol - a covert memory manipulation system  
**Key Operation:** TRENCHGLASS - secret tunnel network from East Vinewood to Blaine County  
**Opposition:** The Resistance - rogue civilians fighting back against corporate control

## 🚀 Features

### 🕳️ TRENCHGLASS Tunnel System

- Secret underground route with environmental effects
- GPS blackout zones and atmospheric fog
- Rank-based access control for Merryweather/Northbridge
- Unauthorized access detection and response

### 🎯 Blackline Correction Events

- Random NPC encounters (interrogation, memory wipe, surveillance)
- Dynamic agent spawning with vehicles
- Automatic event scheduling and management
- Integration with security response systems

### 📻 Resistance Radio Network

- Scheduled broadcasts on frequency 455.550
- Signal strength based on location and weather
- Static effects and reception quality simulation
- Security alerts for Merryweather when broadcasts detected

### 👥 NPC Handler System

- Disguised Northbridge civilians in public areas
- Exposure mechanics with reinforcement calls
- Behavioral AI that reacts to player investigation
- Escalating security responses

### 🔐 Access Control Framework

- 4-tier clearance system (Basic, Elevated, Classified, Black)
- Job and rank-based permissions
- Restricted zone monitoring with ejection
- Comprehensive access logging

### 📢 Northbridge Propaganda System

- Automated corporate announcements every 30-90 minutes
- 20 unsettling propaganda messages disguised as public safety alerts
- Multi-channel system (public, emergency, internal)
- Emergency alerts with screen flash effects

### 🎬 Server Event System

- Story milestone tracking
- Ghost Division deployment finale
- Server-wide status changes and lockdowns
- Emergency broadcast capabilities

### 🖥️ Web-Based Admin Panel

- Real-time dashboard with server statistics
- Player monitoring and management interface
- Security event tracking and filtering
- Administrative actions (suspicion levels, clearance, notes)
- Session-based authentication with QBCore integration
- Live data updates and connection monitoring
- Complete audit logging of admin actions

### 🎮 Player Interaction System

- Comprehensive F6 menu with personal status and controls
- Chat commands for quick status checks and actions
- Resistance radio communication interface
- Tunnel access request and verification system
- NPC reporting with rewards and consequences
- Real-time suspicion and clearance level monitoring
- Immersive roleplay commands and features

## 📁 Installation

> **📖 For detailed installation instructions, see [INSTALLATION.md](INSTALLATION.md)**

### Quick Setup

1. Download and extract to your FiveM resources folder
2. Run database setup script: `mysql -u user -p database < database/setup.sql`
3. Add `ensure countryroadrp-reckoning` to your server.cfg
4. Configure Discord webhooks (optional) - see [DISCORD_SETUP.md](DISCORD_SETUP.md)
5. Configure QBCore jobs:
   - `merryweather` (security contractor)
   - `northbridge` (corporate analyst)
6. Restart your server

### Admin Panel Access

The admin panel is available at:

```
http://your-server-ip:30120/countryroadrp-reckoning/web/admin-panel.html
```

Authentication requires QBCore admin permissions.

## ⚙️ Configuration

All systems can be configured in `config.lua`:

### Essential Settings

```lua
Config.Debug = false -- Set to true for testing
Config.TunnelSystem.enabled = true
Config.BlacklineEvents.enabled = true
Config.ResistanceRadio.enabled = true
Config.NPCHandlers.enabled = true
Config.AccessControl.enabled = true
```

### Job Requirements

- **Merryweather:** operative, agent, commander ranks
- **Northbridge:** analyst, executive, director ranks

### Performance Tuning

- `maxActiveEvents = 3` - Concurrent Blackline events
- `maxNPCs = 10` - Maximum spawned NPCs
- `updateInterval = 1000` - System update frequency (ms)

## 🎮 Commands

### Player Commands

- `/tuneradio <frequency>` - Tune to resistance frequency (455.550)
- `/clearance` - Check your security clearance level

### Staff Commands

- `/resistancebroadcast <message>` - Manual resistance broadcast (admin)
- `/northbridgeannounce <channel> <message>` - Manual Northbridge announcement (admin)
- `/propagandahistory` - View propaganda history (Merryweather/Northbridge)
- `/accesslogs <limit>` - View access attempt logs (security)
- `/incidents` - View current security incidents (Merryweather)
- `/checkclearance <player_id>` - Check player clearance (admin/security)
- `/deployreinforcements <x> <y> <z>` - Manual deployment (Merryweather command)
- `/reckoningstatus` - System status overview (admin)
- `/broadcasthistory` - View broadcast history (Merryweather)

### Debug Commands (when Config.Debug = true)

- `/reckoningtest <system>` - Test individual systems

## 🔧 Dependencies

- **QBCore Framework** - Core functionality
- **qb-log** - Logging system (recommended)
- **pma-voice** - Radio functionality (optional)

## 📊 Discord Integration

The script includes comprehensive Discord webhook logging:

- **4 Separate Channels**: General, Security, Resistance, Admin
- **Rich Embeds**: Color-coded with player information and timestamps
- **Real-time Alerts**: Instant notifications for critical events
- **Configurable Logging**: Enable/disable different log types

See [DISCORD_SETUP.md](DISCORD_SETUP.md) for complete setup instructions.

## 🗄️ Database & Admin Panel

**Advanced Database System:**

- **MySQL Integration**: Complete player profiles, security logs, and analytics
- **Performance Optimized**: Batch processing, caching, and indexed queries
- **Data Retention**: Configurable cleanup and archival policies
- **Real-time Statistics**: Live server metrics and player tracking

**Web-based Admin Panel:**

- **Real-time Dashboard**: Live server stats, recent events, and alerts
- **Player Management**: View profiles, adjust clearance, trigger events
- **Security Monitoring**: Filter and search security events by severity
- **Interactive Controls**: Emergency broadcasts, zone lockdowns, data exports
- **Responsive Design**: Works on desktop and mobile devices

See [DATABASE_SETUP.md](DATABASE_SETUP.md) for complete database installation.

## 🎯 Usage Examples

### For Server Admins

```lua
-- Trigger emergency broadcast
exports['countryroadrp-reckoning']:TriggerEmergencyBroadcast("ALERT MESSAGE")

-- Check if player is in tunnel
local inTunnel = exports['countryroadrp-reckoning']:IsPlayerInTunnel(playerId)

-- Get player clearance level
local clearance = exports['countryroadrp-reckoning']:GetPlayerClearance(playerId)
```

### For Other Resources

```lua
-- Check system status
local tunnelActive = exports['countryroadrp-reckoning']:IsSystemActive('tunnel')

-- Get active events
local events = exports['countryroadrp-reckoning']:GetActiveEvents()
```

## 📊 System Monitoring

The script includes comprehensive logging through QBCore's logging system:

- Zone access attempts
- Security breaches
- Broadcast activities  
- System milestones
- Performance metrics

## 🎭 Roleplay Integration

### For Merryweather Personnel

- Monitor security alerts and respond to breaches
- Use `/incidents` to track ongoing situations
- Coordinate with Northbridge for intelligence gathering

### For Resistance Members

- Tune to 455.550 for broadcasts
- Investigate suspicious NPCs in public areas
- Avoid detection while gathering intelligence

### For Civilians

- Be aware of increased security presence
- Report suspicious activities to authorities
- Follow evacuation procedures during lockdowns

## 🔒 Security Features

- Anti-griefing through limited event frequency
- Performance optimization with entity cleanup
- Automatic system recovery and error handling
- Comprehensive access control and logging

## 🧪 Testing & Development

> **📖 For comprehensive testing procedures, see [TESTING.md](TESTING.md)**

### Quick Test Commands

```lua
-- Server console testing
TriggerEvent('crp-reckoning:tunnel:debugAccess', playerId, tunnelId)
TriggerEvent('crp-reckoning:blackline:triggerEvent', playerId, 'interrogation')
TriggerEvent('crp-reckoning:radio:testBroadcast', 'Test message')
```

### Debug Mode

Enable detailed logging for troubleshooting:

```lua
Config.Debug = true  -- In config.lua
```

## 🚨 Troubleshooting

### Common Issues

1. **Admin Panel Won't Load:** Check resource files and fxmanifest.lua
2. **Database Connection Errors:** Verify oxmysql configuration
3. **Authentication Fails:** Check QBCore permissions and player ID
4. **NPCs not spawning:** Check max NPC limit in config
5. **Radio not working:** Verify pma-voice integration
6. **Tunnel effects not applying:** Check QBCore player data access
7. **Discord webhooks failing:** Verify webhook URLs and rate limits

### Performance Issues

- Monitor memory usage with debug mode
- Adjust update intervals for lower-end servers
- Reduce max active events/NPCs if needed
- Use database cleanup procedures regularly

## 📝 Version History

**v1.2.0** - Admin Panel & Database Integration

- Complete web-based admin panel with real-time dashboard
- Event-based API system for FiveM compatibility
- Database management interface with player monitoring
- Session-based authentication and audit logging
- Fixed HTTP server issues with native FiveM events

**v1.1.0** - Discord Integration & Propaganda System

- Complete Discord webhook logging with 4 channels
- Northbridge Propaganda System with 20 announcements
- Enhanced error handling and performance monitoring
- Rich Discord embeds with color coding

**v1.0.0** - Initial Release

- Full narrative system implementation
- All 5 core modules functional
- QBCore framework integration

## 📚 Documentation

### Complete Documentation Set

- **[INSTALLATION.md](INSTALLATION.md)** - Comprehensive installation guide
- **[TESTING.md](TESTING.md)** - Testing procedures and debugging
- **[PLAYER_COMMANDS.md](PLAYER_COMMANDS.md)** - Player commands and interactions guide
- **[DISCORD_SETUP.md](DISCORD_SETUP.md)** - Discord webhook configuration
- **[DATABASE_SETUP.md](DATABASE_SETUP.md)** - Database installation and setup
- **[CHANGELOG.md](CHANGELOG.md)** - Version history and changes

### Quick Reference

- **Admin Panel:** `http://server-ip:30120/countryroadrp-reckoning/web/admin-panel.html`
- **Database Setup:** Run `database/setup.sql` to create schema
- **Testing:** Enable `Config.Debug = true` for detailed logging
- **Support:** Check console output and error logs for troubleshooting

## 🤝 Support

For support or feature requests, contact the Country Road RP development team.

### Getting Help

1. **Check Documentation:** Review the complete documentation set above
2. **Enable Debug Mode:** Turn on debug logging for detailed output
3. **Check Console:** Look for error messages in server console
4. **Test Components:** Use the testing guide to isolate issues

---

*"The truth is out there, but some would prefer it stay buried."* - The Resistance
