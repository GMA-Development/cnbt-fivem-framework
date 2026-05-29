--[[
    CNBT Framework — State (client)
    ------------------------------------------------------------------
    Read replicated state bags and subscribe to changes. The client never
    writes replicated values for other players — the server is authority.
    This is how the client stays in sync with zero custom net traffic.
]]

local state = {}

--- Reads a value from the local player's state bag.
function state.getLocal(key)
    return LocalPlayer.state[key]
end

--- Reads a value from another player's state bag (by server id).
function state.getPlayer(serverId, key)
    local ply = GetPlayerFromServerId(serverId)
    if ply == -1 then return nil end
    return Player(ply).state[key]
end

--- Reads a value from an entity's state bag.
function state.getEntity(entity, key)
    return Entity(entity).state[key]
end

--- Reads a value from the global state bag.
function state.getGlobal(key)
    return GlobalState[key]
end

--- Subscribes to state-bag changes (nil filters match all). Returns the
--- handler cookie for RemoveStateBagChangeHandler.
--- @param keyFilter string|nil
--- @param bagFilter string|nil
--- @param handler fun(bagName:string, key:string, value:any, reserved:any, replicated:boolean)
--- @return integer
function state.onChange(keyFilter, bagFilter, handler)
    return AddStateBagChangeHandler(keyFilter, bagFilter, handler)
end

return state
