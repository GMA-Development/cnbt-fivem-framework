--[[
    CNBT Framework — RPC core (shared, reusable)
    ------------------------------------------------------------------
    Realm-agnostic request/response engine for the callback system.
    All the bookkeeping (id generation, pending promise map, dispatch)
    lives here ONCE. The client and server callback modules only inject
    transport functions (TriggerServerEvent / TriggerClientEvent).

    This avoids registering a network event per callback name — a single
    request/response channel carries everything, keyed by request id.
]]

--- Creates an RPC endpoint.
--- @param transport { sendRequest: fun(target:any, name:string, id:integer, args:table), sendResponse: fun(target:any, id:integer, results:table) }
--- @return table
local function createRpc(transport)
    local handlers = {}
    local pending = {}
    local idCounter = 0

    local rpc = {}

    --- Registers a handler invoked when a remote calls `name`.
    --- The handler receives (source, ...) on the server and (...) on the client.
    --- @param name string
    --- @param fn fun(...):any
    function rpc.register(name, fn)
        handlers[name] = fn
    end

    --- Handles an inbound request (wired by the transport layer).
    --- @param source any Requester (player source on server, nil on client)
    --- @param name string
    --- @param id integer
    --- @param args table
    function rpc.handleRequest(source, name, id, args)
        local fn = handlers[name]
        local results
        if fn then
            results = table.pack(fn(source, table.unpack(args, 1, args.n or #args)))
        else
            results = { n = 0 }
        end
        transport.sendResponse(source, id, results)
    end

    --- Handles an inbound response (wired by the transport layer).
    --- @param id integer
    --- @param results table
    function rpc.handleResponse(id, results)
        local p = pending[id]
        if not p then return end
        pending[id] = nil
        p:resolve(results)
    end

    --- Calls a remote callback and awaits the result. Must run in a coroutine.
    --- @param target any Recipient (player source on server, ignored on client)
    --- @param name string
    --- @param ... any
    --- @return ... results returned by the remote handler
    function rpc.call(target, name, ...)
        idCounter = idCounter + 1
        local id = idCounter
        local p = promise.new()
        pending[id] = p
        transport.sendRequest(target, name, id, table.pack(...))
        local results = Citizen.Await(p)
        return table.unpack(results, 1, results.n)
    end

    return rpc
end

return createRpc
