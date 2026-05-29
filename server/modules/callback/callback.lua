--[[
    CNBT Framework — Callbacks (server)
    ------------------------------------------------------------------
    Server side of the RPC system. Other modules register callbacks the
    client can await, and the server can await client callbacks too.

    Uses the shared rpc core over a single request/response event pair —
    no per-callback event registration.

      callback.register(name, fn)        fn receives (source, ...)
      callback.call(playerId, name, ...) awaits the client's result
]]

local createRpc = require 'shared.rpc'

local REQUEST = 'cnbt:cb:request'
local RESPONSE = 'cnbt:cb:response'

local rpc = createRpc({
    sendRequest = function(target, name, id, args)
        TriggerClientEvent(REQUEST, target, name, id, args)
    end,
    sendResponse = function(target, id, results)
        TriggerClientEvent(RESPONSE, target, id, results)
    end,
})

-- Inbound client -> server request. `source` is the calling player.
RegisterNetEvent(REQUEST, function(name, id, args)
    rpc.handleRequest(source, name, id, args)
end)

-- Inbound response to a server -> client call.
RegisterNetEvent(RESPONSE, function(id, results)
    rpc.handleResponse(id, results)
end)

return {
    register = rpc.register,
    --- Awaits a callback registered on a specific client.
    --- @param playerId integer
    --- @param name string
    call = function(playerId, name, ...)
        return rpc.call(playerId, name, ...)
    end,
}
