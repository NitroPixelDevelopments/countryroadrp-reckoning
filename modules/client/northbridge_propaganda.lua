local QBCore = exports['qb-core']:GetCoreObject()

local NorthbridgePropagandaClient = {}

function NorthbridgePropagandaClient.Initialize()
    if not Config.NorthbridgePropaganda.enabled then return end
    
    -- Register client events
    RegisterNetEvent('crp-reckoning:propaganda:emergencyFlash', NorthbridgePropagandaClient.EmergencyFlash)
    RegisterNetEvent('crp-reckoning:propaganda:showHistory', NorthbridgePropagandaClient.ShowHistory)
end

function NorthbridgePropagandaClient.EmergencyFlash()
    -- Create emergency screen flash effect
    CreateThread(function()
        for i = 1, 3 do
            SetFlash(0, 0, 100, 500, 100)
            Wait(500)
            SetFlash(0, 0, 0, 0, 0)
            Wait(300)
        end
    end)
    
    -- Play emergency sound
    PlaySoundFrontend(-1, "ERROR", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
end

function NorthbridgePropagandaClient.ShowHistory(history)
    -- Display propaganda history in chat
    TriggerEvent('chat:addMessage', {
        template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(0, 0, 0, 0.8); border-left: 4px solid #2196F3;"><b>Northbridge Propaganda History</b><br>Recent announcements:</div>',
        args = {}
    })
    
    local recentCount = math.min(#history, 5)
    for i = #history - recentCount + 1, #history do
        local announcement = history[i]
        if announcement then
            local timeStr = os.date('%H:%M', announcement.timestamp)
            local channelIcon = ''
            
            if announcement.channel == 'emergency' then
                channelIcon = '🚨 '
            elseif announcement.channel == 'internal' then
                channelIcon = '🔒 '
            else
                channelIcon = '📢 '
            end
            
            TriggerEvent('chat:addMessage', {
                template = '<div style="padding: 0.3vw; margin: 0.2vw; background-color: rgba(33, 150, 243, 0.1); font-size: 0.9em;"><b>[{0}]</b> {1}{2}</div>',
                args = { timeStr, channelIcon, announcement.message }
            })
        end
    end
end

-- Export functions
exports('GetPropagandaClient', function()
    return NorthbridgePropagandaClient
end)

-- Initialize system
CreateThread(function()
    Wait(1000)
    NorthbridgePropagandaClient.Initialize()
end)
