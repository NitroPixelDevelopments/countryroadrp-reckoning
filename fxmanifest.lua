fx_version 'cerulean'
game 'gta5'

name 'countryroadrp-reckoning'
author 'Country Road RP Development Team'
description 'Season 1: Reckoning - Narrative Systems with Discord Integration'
version '1.1.0'
url 'https://github.com/your-repo/countryroadrp-reckoning'
resource_type 'gametype' { name = 'CRRP Season1: The Reckoning' }


server_only 'no'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'config.lua'
}

server_scripts {
    'modules/server/database_manager.lua',
    'modules/server/discord_logger.lua',
    'modules/server/admin_api.lua',
    'modules/server/player_interactions.lua',
    'server/main.lua',
    'modules/server/tunnel_system.lua',
    'modules/server/blackline_events.lua',
    'modules/server/resistance_radio.lua',
    'modules/server/northbridge_propaganda.lua',
    'modules/server/npc_handlers.lua',
    'modules/server/access_control.lua'
}

client_scripts {
    'client/main.lua',
    'modules/client/player_interactions.lua',
    'modules/client/hud_elements.lua',
    'modules/client/tunnel_system.lua',
    'modules/client/blackline_events.lua',
    'modules/client/resistance_radio.lua',
    'modules/client/northbridge_propaganda.lua',
    'modules/client/npc_handlers.lua',
    'modules/client/access_control.lua'
}

files {
    'web/admin-panel.html',
    'web/js/admin-panel.js',
    'web/player-menu.html',
    'web/hud-overlay.html'
}

ui_page 'web/player-menu.html'

dependencies {
    'qb-core',
    'oxmysql'
}

lua54 'yes'
