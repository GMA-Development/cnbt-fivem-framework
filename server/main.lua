--[[
    CNBT Framework — Server bootstrap
    ------------------------------------------------------------------
    Requiring each module runs its top-level side effects (threads, event
    handlers, export registration) exactly once and caches it. Order is
    not critical thanks to lazy require(), but we load core -> data ->
    domain -> api for readability.
]]

local logger = require 'shared.logger'

-- Core services
require 'server.modules.events'
require 'server.modules.database.database'
require 'server.modules.database.writeBehind'
require 'server.modules.state.state'
require 'server.modules.callback.callback'

-- Domain
require 'server.modules.identity.identity'
require 'server.modules.player.player'
require 'server.modules.player.manager'

-- Public API
require 'server.api.exports'

logger.info(('framework v%s avviato (server)'):format(CNBT.version))
