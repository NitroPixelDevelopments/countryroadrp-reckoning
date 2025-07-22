-- Discord Webhook Logging System
local DiscordLogger = {}

function DiscordLogger.SendToDiscord(webhook, title, description, color, fields, footer)
    if not Config.Discord.enabled or not webhook or webhook == '' then
        return
    end
    
    local embed = {
        {
            title = title,
            description = description,
            color = color or Config.Discord.colors.blue,
            fields = fields or {},
            footer = {
                text = footer or (Config.Discord.serverName .. ' • ' .. os.date('%Y-%m-%d %H:%M:%S')),
                icon_url = Config.Discord.serverIcon
            },
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
        }
    }
    
    local data = {
        username = 'Reckoning System',
        avatar_url = Config.Discord.serverIcon,
        embeds = embed
    }
    
    PerformHttpRequest(webhook, function(err, text, headers) 
        if err ~= 200 then
            print('^1[Discord Logger] Error sending webhook: ' .. tostring(err) .. '^7')
        end
    end, 'POST', json.encode(data), {
        ['Content-Type'] = 'application/json'
    })
end

-- Enhanced logging function that supports multiple outputs
function DiscordLogger.LogEvent(category, title, description, logLevel, playerData)
    local color = Config.Discord.colors.blue
    local webhook = Config.Discord.webhooks.general
    
    -- Determine color and webhook based on category and level
    if category == 'security' or logLevel == 'red' then
        color = Config.Discord.colors.red
        webhook = Config.Discord.webhooks.security
    elseif category == 'resistance' then
        color = Config.Discord.colors.green
        webhook = Config.Discord.webhooks.resistance
    elseif category == 'milestone' or category == 'admin' then
        color = Config.Discord.colors.purple
        webhook = Config.Discord.webhooks.admin
    elseif logLevel == 'orange' then
        color = Config.Discord.colors.orange
    elseif logLevel == 'yellow' then
        color = Config.Discord.colors.yellow
    elseif logLevel == 'green' then
        color = Config.Discord.colors.green
    end
    
    local fields = {}
    
    -- Add player information if provided
    if playerData then
        table.insert(fields, {
            name = 'Player',
            value = string.format('%s (%s)', playerData.name or 'Unknown', playerData.citizenid or 'N/A'),
            inline = true
        })
        
        if playerData.job then
            table.insert(fields, {
                name = 'Job',
                value = string.format('%s (%s)', playerData.job, playerData.rank or 'Unknown'),
                inline = true
            })
        end
        
        if playerData.coords then
            table.insert(fields, {
                name = 'Location',
                value = string.format('X: %.1f, Y: %.1f, Z: %.1f', playerData.coords.x, playerData.coords.y, playerData.coords.z),
                inline = false
            })
        end
    end
    
    -- Send to Discord
    if Config.Performance.enableDiscordLogging then
        DiscordLogger.SendToDiscord(webhook, title, description, color, fields)
    end
    
    -- Send to QB-Core logging
    if Config.Performance.enableQBLogging then
        TriggerEvent('qb-log:server:CreateLog', 'crp-reckoning', title, logLevel or 'blue', description)
    end
    
    -- Console logging
    if Config.Performance.enableConsoleLogging then
        local logColor = '^7' -- Default white
        if logLevel == 'red' then logColor = '^1'
        elseif logLevel == 'green' then logColor = '^2'
        elseif logLevel == 'yellow' then logColor = '^3'
        elseif logLevel == 'orange' then logColor = '^8'
        end
        
        print(string.format('%s[Reckoning - %s] %s: %s^7', logColor, category:upper(), title, description))
    end
end

-- Specific logging functions for different events
function DiscordLogger.LogTunnelAccess(playerData, zone, granted)
    local title = granted and 'Tunnel Access Granted' or 'Unauthorized Tunnel Access'
    local description = string.format('%s %s access to %s', 
        playerData.name, 
        granted and 'gained' or 'attempted', 
        zone
    )
    
    DiscordLogger.LogEvent('security', title, description, granted and 'green' or 'red', playerData)
end

function DiscordLogger.LogBlacklineEvent(playerData, eventType, status)
    local title = string.format('Blackline Event - %s', eventType:gsub('_', ' '):gsub('%l', string.upper, 1))
    local description = string.format('Event %s for player %s', status, playerData.name)
    
    DiscordLogger.LogEvent('security', title, description, 'orange', playerData)
end

function DiscordLogger.LogResistanceBroadcast(message, emergency)
    local title = emergency and 'Emergency Resistance Broadcast' or 'Resistance Broadcast'
    local description = string.format('Message: "%s"', message)
    
    DiscordLogger.LogEvent('resistance', title, description, emergency and 'red' or 'green')
end

function DiscordLogger.LogAgentExposure(playerData, location)
    local title = 'Northbridge Agent Exposed'
    local description = string.format('%s exposed a disguised agent', playerData.name)
    
    playerData.coords = location
    DiscordLogger.LogEvent('security', title, description, 'red', playerData)
end

function DiscordLogger.LogPropaganda(message, channel)
    local title = string.format('Northbridge Propaganda - %s Channel', channel:gsub('%l', string.upper, 1))
    local description = string.format('Message: "%s"', message)
    
    DiscordLogger.LogEvent('general', title, description, 'yellow')
end

function DiscordLogger.LogMilestone(milestoneName, triggerCount, required)
    local title = 'Story Milestone Progress'
    local description = string.format('Milestone: %s (%d/%d triggers)', 
        milestoneName:gsub('_', ' '):gsub('%l', string.upper, 1), 
        triggerCount, 
        required
    )
    
    DiscordLogger.LogEvent('milestone', title, description, 'purple')
end

function DiscordLogger.LogAccessViolation(playerData, zoneName, clearanceLevel)
    local title = 'Access Control Violation'
    local description = string.format('%s attempted to access %s (Clearance: %d)', 
        playerData.name, 
        zoneName, 
        clearanceLevel
    )
    
    DiscordLogger.LogEvent('security', title, description, 'red', playerData)
end

-- Export the logger
exports('DiscordLogger', function()
    return DiscordLogger
end)

return DiscordLogger
