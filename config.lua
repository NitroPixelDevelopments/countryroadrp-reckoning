Config = {}

-- Core Settings
Config.Debug = true
Config.FrameworkName = 'qb-core'

-- TRENCHGLASS Tunnel System
Config.TunnelSystem = {
    enabled = true,
    
    -- Main tunnel route coordinates (East Vinewood to Blaine County)
    tunnelPoints = {
        {coords = vector3(1210.5, -620.8, 63.0), radius = 50.0}, -- East Vinewood entrance
        {coords = vector3(1450.2, -890.4, 45.2), radius = 35.0}, -- Underground section 1
        {coords = vector3(1680.8, -1200.6, 38.8), radius = 35.0}, -- Underground section 2
        {coords = vector3(1920.4, -1450.2, 42.1), radius = 35.0}, -- Underground section 3
        {coords = vector3(2200.1, -1680.9, 48.5), radius = 35.0}, -- Underground section 4
        {coords = vector3(2480.7, -1920.3, 55.2), radius = 40.0}, -- Blaine County exit
    },
    
    -- Environmental effects
    effects = {
        enableFog = true,
        fogDensity = 0.8,
        disableGPS = true,
        disableRadar = true,
        ambientLight = 0.3,
        enableParticles = true
    },
    
    -- Access control
    accessJobs = {'merryweather', 'northbridge'},
    accessRanks = {
        merryweather = {'Unvetted Contractor', 'Tier 1 Operative', 'Tier 2 Operative','Field Agent','Recon Specialist','Blackline Enforcer','Tactical Unit Lead','Zone Commander','Asset Containment Officer', 'Ghost Division Commander', 'Northbridge Protocol Officer', 'Executive Agent – TRENCHGLASS'},
        northbridge = {'analyst', 'executive', 'director'}
    }
}

-- Blackline Correction Events
Config.BlacklineEvents = {
    enabled = true,
    
    -- Event frequency (minutes)
    eventInterval = {min = 15, max = 45},
    
    -- Event types and their chances
    eventTypes = {
        {type = 'interrogation', chance = 40, duration = 300}, -- 5 minutes
        {type = 'memory_wipe', chance = 25, duration = 180}, -- 3 minutes
        {type = 'surveillance', chance = 35, duration = 120} -- 2 minutes
    },
    
    -- Spawn locations for agents
    spawnLocations = {
        {coords = vector3(195.17, -933.77, 29.7), heading = 144.5}, -- Downtown LS
        {coords = vector3(-531.33, -854.47, 29.29), heading = 222.5}, -- Little Seoul
        {coords = vector3(1136.4, -982.0, 46.4), heading = 310.0}, -- Mirror Park
        {coords = vector3(-1037.5, -2737.8, 20.2), heading = 150.0}, -- Airport
        {coords = vector3(25.68, -1347.3, 29.5), heading = 90.0} -- Strawberry
    },
    
    -- Agent models
    agentModels = {'s_m_m_fibsec_01', 's_m_y_blackops_01', 's_m_y_blackops_02'},
    
    -- Vehicles
    agentVehicles = {'fbi2', 'riot', 'insurgent'}
}

-- Resistance Radio System
Config.ResistanceRadio = {
    enabled = true,
    
    -- Radio frequency
    frequency = 455.550,
    
    -- Broadcast schedule (hour in 24h format)
    broadcastTimes = {2, 6, 14, 18, 22},
    
    -- Broadcast duration (minutes)
    broadcastDuration = 5,
    
    -- Signal strength zones
    signalZones = {
        {coords = vector3(-1037.5, -2737.8, 20.2), radius = 500.0, strength = 0.9}, -- Airport
        {coords = vector3(1729.2, 3311.4, 41.2), radius = 800.0, strength = 0.8}, -- Sandy Shores
        {coords = vector3(-585.1, 5300.2, 70.2), radius = 600.0, strength = 0.7}, -- Paleto Bay
        {coords = vector3(2550.4, 4680.8, 34.1), radius = 400.0, strength = 0.6} -- Grapeseed
    },
    
    -- Broadcast messages
    messages = {
        "The truth about Northbridge Solutions cannot be hidden forever...",
        "Memory fragments recovered from Sector 7 reveal the Blackline Protocol...",
        "Merryweather assets have been identified in civilian sectors...",
        "TRENCHGLASS operation confirmed. Underground movement detected...",
        "Ghost Division deployment imminent. Prepare for total information blackout..."
    }
}

-- Northbridge Propaganda System
Config.NorthbridgePropaganda = {
    enabled = true,
    
    -- Announcement frequency (minutes)
    announcementInterval = {min = 30, max = 90},
    
    -- Public announcement messages (corporate propaganda)
    publicAnnouncements = {
        "Northbridge Solutions has identified several individuals requiring wellness checks in Mirror Park. Please report any unusual behavior to our community liaisons.",
        "Due to infrastructure assessments, the Vinewood Hills area will experience intermittent GPS disruptions this evening. Citizens are advised to remain in familiar locations.",
        "Our mobile response units are conducting routine memory health screenings at Los Santos International Airport. Participation is voluntary but encouraged for your safety.",
        "Northbridge Solutions reminds Paleto Bay residents that recent power fluctuations are part of our ongoing grid optimization program. Do not investigate unusual sounds near utility stations.",
        "Several Sandy Shores residents have been selected for our exclusive relocation assistance program. If contacted, please cooperate fully with our transportation specialists.",
        "We are pleased to announce enhanced surveillance coverage in Little Seoul to better serve the community. Smile—you're now safer than ever.",
        "Temporary road closures near the Palmer-Taylor Power Station are necessary for public wellness initiatives. Alternative routes have been pre-approved for your convenience.",
        "Northbridge Solutions is investigating reports of unauthorized radio transmissions in Blaine County. Citizens experiencing unusual broadcasts should contact our information security division immediately.",
        "Our environmental specialists are conducting air quality assessments in Strawberry tonight. Residents may notice a mild sedative fragrance—this is completely normal.",
        "Due to elevated stress indicators detected in the Del Perro area, our wellness teams will be conducting door-to-door mental health evaluations this week. Thank you for your cooperation.",
        "Citizens of Vespucci Beach are reminded that the recent installation of behavioral monitoring equipment is for your protection. Please maintain normal activities.",
        "Northbridge Solutions announces a community mental wellness initiative in Burton. Participants will receive complimentary memory optimization services.",
        "Construction crews working overnight in Cypress Flats have been equipped with enhanced noise suppression technology. Any screaming sounds are part of standard equipment testing.",
        "Our data collection specialists report excellent cooperation from Mission Row residents. Those who have not yet participated will be contacted personally.",
        "The unusual fog patterns over Mount Chiliad are the result of our atmospheric wellness project. Citizens are advised to avoid the area during low visibility conditions.",
        "Northbridge Solutions thanks the community for reporting neighbors exhibiting signs of resistance ideology. Your vigilance makes everyone safer.",
        "Random vehicle checkpoints will be established throughout Los Santos this week as part of our community safety audit. Please have identification ready.",
        "Citizens experiencing recurring dreams about underground tunnels should report to the nearest Northbridge wellness center for evaluation.",
        "Our mobile psychiatric units are now available 24/7 for immediate consultation. Remember: early intervention prevents dangerous thinking patterns.",
        "The temporary amnesia reported by some Grapeseed residents is a normal side effect of our regional air purification system. Symptoms typically resolve within 72 hours."
    },
    
    -- Corporate channels for announcements
    channels = {
        {name = 'public', weight = 70}, -- 70% chance
        {name = 'emergency', weight = 20}, -- 20% chance
        {name = 'internal', weight = 10} -- 10% chance (Merryweather/Northbridge only)
    }
}

-- NPC Handler System
Config.NPCHandlers = {
    enabled = true,
    
    -- Northbridge civilian disguises
    civilianDisguises = {
        models = {'a_m_m_business_01', 'a_f_m_business_02', 'a_m_y_business_01'},
        spawnChance = 0.15, -- 15% chance per eligible location
        
        -- Spawn locations
        locations = {
            {coords = vector3(-1037.5, -2737.8, 20.2), radius = 100.0}, -- Airport
            {coords = vector3(-248.5, -2010.5, 30.1), radius = 80.0}, -- LS Port
            {coords = vector3(195.17, -933.77, 29.7), radius = 120.0}, -- Downtown
            {coords = vector3(1136.4, -982.0, 46.4), radius = 90.0} -- Mirror Park
        }
    },
    
    -- Response system when exposed
    exposureResponse = {
        alertRadius = 1000.0, -- Meters
        responseTime = 120, -- Seconds
        reinforcementUnits = 3,
        reinforcementVehicles = {'fbi2', 'riot'}
    }
}

-- Server Event System
Config.ServerEvents = {
    enabled = true,
    
    -- Story milestones
    milestones = {
        {
            name = 'ghost_division_deployment',
            requiredTriggers = 5,
            effects = {
                disableRadios = true,
                increaseSecurity = true,
                lockdownZones = {
                    {coords = vector3(1210.5, -620.8, 63.0), radius = 200.0}, -- East Vinewood
                    {coords = vector3(2480.7, -1920.3, 55.2), radius = 300.0} -- Blaine County
                }
            }
        }
    }
}

-- Access Control System
Config.AccessControl = {
    enabled = true,
    
    -- Security clearance levels
    clearanceLevels = {
        {level = 1, name = 'Basic', jobs = {'merryweather', 'northbridge'}},
        {level = 2, name = 'Elevated', jobs = {'merryweather'}, ranks = {'agent', 'operative'}},
        {level = 3, name = 'Classified', jobs = {'merryweather'}, ranks = {'commander'}},
        {level = 4, name = 'Black', jobs = {'northbridge'}, ranks = {'director'}}
    },
    
    -- Restricted zones by clearance level
    restrictedZones = {
        {
            coords = vector3(1210.5, -620.8, 63.0),
            radius = 50.0,
            requiredLevel = 2,
            name = 'TRENCHGLASS Alpha Entrance'
        },
        {
            coords = vector3(2480.7, -1920.3, 55.2),
            radius = 50.0,
            requiredLevel = 3,
            name = 'TRENCHGLASS Omega Exit'
        }
    }
}

-- Discord Webhook Settings
Config.Discord = {
    enabled = true,
    
    -- Webhook URLs (set these in your server)
    webhooks = {
        general = 'https://discord.com/api/webhooks/1370940576878428191/H1Hmff87FVESKXr_7z5WyPkUWrZkjHSZb88r7DHl1P40wDeP_IlCDF9cDzjuudtHWrQq', -- General events
        security = 'https://discord.com/api/webhooks/1370940576878428191/H1Hmff87FVESKXr_7z5WyPkUWrZkjHSZb88r7DHl1P40wDeP_IlCDF9cDzjuudtHWrQq', -- Security alerts, breaches
        resistance = 'https://discord.com/api/webhooks/1370940576878428191/H1Hmff87FVESKXr_7z5WyPkUWrZkjHSZb88r7DHl1P40wDeP_IlCDF9cDzjuudtHWrQq', -- Resistance activities
        admin = 'https://discord.com/api/webhooks/1370940576878428191/H1Hmff87FVESKXr_7z5WyPkUWrZkjHSZb88r7DHl1P40wDeP_IlCDF9cDzjuudtHWrQq' -- Admin notifications, milestones
    },
    
    -- Color codes for Discord embeds
    colors = {
        green = 3066993,   -- Success/Access granted
        red = 15158332,    -- Alerts/Security breaches  
        orange = 15105570, -- Warnings/Events
        blue = 3447003,    -- Information
        yellow = 16776960, -- Propaganda/Announcements
        purple = 10181046  -- Milestones/Special events
    },
    
    -- Server information
    serverName = 'Country Road RP',
    serverIcon = 'https://your-server-icon-url.com/icon.png'
}

-- Database Settings
Config.Database = {
    enabled = true,
    
    -- MySQL connection (uses oxmysql by default)
    host = 'localhost',
    port = 3306,
    database = 'crp_reckoning',
    username = 'root',
    password = '',
    
    -- Connection options
    charset = 'utf8mb4',
    debug = false,
    
    -- Data retention (days)
    retention = {
        security_logs = 30,      -- Keep security logs for 30 days
        blackline_events = 90,   -- Keep blackline events for 90 days
        tunnel_access = 60,      -- Keep tunnel access logs for 60 days
        propaganda = 15,         -- Keep propaganda logs for 15 days
        admin_actions = 365      -- Keep admin actions for 1 year
    }
}

-- Admin Panel Settings
Config.AdminPanel = {
    enabled = true,
    
    -- Web server settings
    port = 8080,
    host = '0.0.0.0',
    
    -- Authentication
    useQBCoreAuth = true,     -- Use QBCore permissions
    adminPermission = 'admin', -- Required permission level
    
    -- Security
    sessionTimeout = 3600,    -- 1 hour
    rateLimitRequests = 100,  -- Per minute
    enableAuditLog = true,
    
    -- Features
    enableRealTimeUpdates = true,
    refreshInterval = 5000,   -- 5 seconds
    maxRecordsPerPage = 50,
    
    -- Dashboard widgets
    widgets = {
        'system_overview',
        'recent_security_events',
        'player_statistics',
        'tunnel_activity',
        'resistance_activity',
        'active_events',
        'milestone_progress'
    }
}

-- Performance Settings
Config.Performance = {
    updateInterval = 1000, -- ms
    maxActiveEvents = 3,
    cleanupInterval = 300000, -- 5 minutes
    maxNPCs = 10,
    
    -- Logging preferences
    enableConsoleLogging = true,
    enableDiscordLogging = true,
    enableQBLogging = true,
    enableDatabaseLogging = true,
    
    -- Database optimization
    batchInsertSize = 50,     -- Batch database inserts
    asyncOperations = true,   -- Use async database operations
    cachePlayerData = true,   -- Cache frequently accessed player data
    cacheTimeout = 300        -- Cache timeout in seconds
}
