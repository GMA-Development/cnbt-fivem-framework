--[[
    CNBT Framework — Callbacks (client)
    ------------------------------------------------------------------
    Client side of the RPC system. The client always talks to the single
    server, so call() takes no target.

      callback.register(name, fn)   fn receives (...) from the server
      callback.call(name, ...)      awaits the server's result
]]

local createRpc = require 'shared.rpc'

local REQUEST = 'cnbt:cb:request'
local RESPONSE = 'cnbt:cb:response'

local rpc = createRpc({
    sendRequest = function(_, name, id, args)
        TriggerServerEvent(REQUEST, name, id, args)
    end,
    sendResponse = function(_, id, results)
        TriggerServerEvent(RESPONSE, id, results)
    end,
})

-- Inbound server -> client request (source is the server: nil/local).
RegisterNetEvent(REQUEST, function(name, id, args)
    rpc.handleRequest(nil, name, id, args)
end)

-- Inbound response to a client -> server call.
RegisterNetEvent(RESPONSE, function(id, results)
    rpc.handleResponse(id, results)
end)

return {
    register = rpc.register,
    --- Awaits a server callback. Must run inside a thread.
    --- @param name string
    call = function(name, ...)
        return rpc.call(nil, name, ...)
    end,
}
