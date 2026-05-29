--[[
    CNBT Framework — Public API / Exports (client)
    ------------------------------------------------------------------
    Assembles the in-resource CNBT object and exposes a small client API
    for other resources (data reads + server callback access).
]]

local callback = require 'client.modules.callback.callback'
local state = require 'client.modules.state.state'

CNBT.callback = callback
CNBT.state = state

--- Convenience: a replicated value from the local player's state bag.
function CNBT.getData(key)
    return LocalPlayer.state[key]
end

-- ── Cross-resource exports ───────────────────────────────────────

exports('getData', function(key) return LocalPlayer.state[key] end)
exports('isLoaded', function() return LocalPlayer.state.charId ~= nil end)
exports('triggerServerCallback', function(name, ...) return callback.call(name, ...) end)
exports('registerCallback', function(name, fn) callback.register(name, fn) return true end)
exports('getGlobalState', function(key) return GlobalState[key] end)
