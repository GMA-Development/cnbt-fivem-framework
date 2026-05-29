fx_version 'cerulean'
game 'gta5'

-- Lua 5.4 for the best runtime performance (lowest resmon).
lua54 'yes'

name 'cnbt'
author 'CNBT'
version '0.1.0'
description 'CNBT — Lightweight FiveM RP Framework'

-- OneSync infinity is required (server-authoritative entities + state bags).
-- Enable it in server.cfg:  set onesync on
dependency 'oxmysql'

-- The module loader must run first in BOTH realms.
shared_script 'shared/import.lua'

client_script 'client/main.lua'
server_script 'server/main.lua'

-- Everything else is loaded on demand via require(). These files are NOT
-- auto-executed; they are listed so the client can read them at runtime
-- (the server can read any resource file directly). Server-only modules
-- are intentionally excluded — they never ship to clients.
files {
    'config/*.lua',
    'shared/**/*.lua',
    'client/**/*.lua',
}
