# Discord Webhook Setup Guide

## 📋 Prerequisites
- Discord server with administrator permissions
- FiveM server running QBCore framework
- Country Road RP - Reckoning script installed

## 🔧 Setting Up Discord Webhooks

### Step 1: Create Discord Channels
Create the following channels in your Discord server:
- `#reckoning-general` - General events and activities
- `#reckoning-security` - Security alerts and breaches
- `#reckoning-resistance` - Resistance activities and broadcasts
- `#reckoning-admin` - Admin notifications and milestones

### Step 2: Create Webhooks
For each channel:
1. Right-click the channel → **Edit Channel**
2. Go to **Integrations** → **Webhooks**
3. Click **Create Webhook**
4. Set webhook name (e.g., "Reckoning General")
5. Copy the **Webhook URL**

### Step 3: Configure the Script
Edit `config.lua` and add your webhook URLs:

```lua
Config.Discord = {
    enabled = true,
    
    webhooks = {
        general = 'https://discord.com/api/webhooks/YOUR_GENERAL_WEBHOOK_HERE',
        security = 'https://discord.com/api/webhooks/YOUR_SECURITY_WEBHOOK_HERE', 
        resistance = 'https://discord.com/api/webhooks/YOUR_RESISTANCE_WEBHOOK_HERE',
        admin = 'https://discord.com/api/webhooks/YOUR_ADMIN_WEBHOOK_HERE'
    },
    
    serverName = 'Your Server Name',
    serverIcon = 'https://your-server-icon-url.com/icon.png'
}
```

### Step 4: Customize Colors (Optional)
You can modify the embed colors in `config.lua`:

```lua
colors = {
    green = 3066993,   -- Success/Access granted
    red = 15158332,    -- Alerts/Security breaches  
    orange = 15105570, -- Warnings/Events
    blue = 3447003,    -- Information
    yellow = 16776960, -- Propaganda/Announcements
    purple = 10181046  -- Milestones/Special events
}
```

## 📊 What Gets Logged

### General Channel
- Northbridge propaganda announcements
- General system events
- Player activities

### Security Channel  
- Tunnel access attempts (authorized & unauthorized)
- Blackline correction events
- Agent exposures and reinforcement deployments
- Access control violations

### Resistance Channel
- Resistance radio broadcasts
- Emergency resistance alerts
- Underground activities

### Admin Channel
- Story milestone progress
- System status changes
- Ghost Division deployment
- Server-wide events

## 🎨 Discord Embed Examples

### Security Alert Example:
```
🚨 Unauthorized Tunnel Access
John_Doe (ABC123) attempted access to TRENCHGLASS System

Player: John Doe (ABC123)
Job: civilian (Unknown)
Location: X: 1210.5, Y: -620.8, Z: 63.0

Country Road RP • 2024-01-15 14:30:22
```

### Resistance Broadcast Example:
```
📻 Resistance Broadcast
Message: "The truth about Northbridge Solutions cannot be hidden forever..."

Country Road RP • 2024-01-15 18:45:12
```

## ⚙️ Logging Control

You can enable/disable different logging methods in `config.lua`:

```lua
Config.Performance = {
    enableConsoleLogging = true,   -- Server console
    enableDiscordLogging = true,   -- Discord webhooks
    enableQBLogging = true        -- QB-Core logging system
}
```

## 🔍 Testing Webhooks

Use these commands to test your webhook setup:

```
/northbridgeannounce public Test message for general webhook
/resistancebroadcast Test message for resistance webhook
/reckoningstatus (triggers admin webhook)
```

## 🚨 Security Considerations

1. **Keep webhook URLs private** - Never share them publicly
2. **Use channel permissions** - Restrict access to sensitive channels
3. **Monitor webhook usage** - Discord has rate limits (30 requests per minute)
4. **Backup webhooks** - Keep spare webhooks in case of issues

## 🛠️ Troubleshooting

### Webhooks Not Working
1. Check webhook URLs are correct and not expired
2. Verify `Config.Discord.enabled = true`
3. Check server console for HTTP errors
4. Ensure Discord channel permissions allow webhooks

### Missing Embeds
1. Verify webhook URLs point to correct channels
2. Check `enableDiscordLogging = true` in config
3. Look for Discord API rate limiting messages

### Rate Limiting
If you see rate limit errors:
1. Reduce event frequency in config
2. Combine multiple events into single messages
3. Use QB-Core logging as fallback

## 📝 Custom Webhook Integration

To add custom Discord logging in your own scripts:

```lua
local DiscordLogger = exports['countryroadrp-reckoning']:DiscordLogger()

DiscordLogger.LogEvent('security', 'Custom Event', 'Description here', 'red', {
    name = 'Player Name',
    citizenid = 'ABC123',
    job = 'police',
    coords = vector3(0, 0, 0)
})
```

## 🎯 Best Practices

1. **Channel Organization**: Use different channels for different event types
2. **Notification Roles**: Create Discord roles for staff notifications
3. **Archive Old Channels**: Regularly archive old log channels
4. **Monitor Disk Space**: Webhook logs can accumulate quickly
5. **Test Regularly**: Verify webhooks work after Discord server changes

---

*For additional support, contact the Country Road RP development team.*
