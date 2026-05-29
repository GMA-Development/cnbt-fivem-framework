--[[
    CNBT Framework — State (server)
    ------------------------------------------------------------------
    Thin helpers over FiveM state bags — the framework's single source of
    truth for replicated data. Setting `replicated = true` (the default)
    makes the server push the value to the relevant client(s) natively,
    which is how we keep multiplayer in sync WITHOUT custom net events.

    Scopes:
      player  -> Player(source).state  (per-player data: money, job, ...)
      entity  -> Entity(entity).state  (per-entity data: ownership, props)
      global  -> GlobalState           (world data: weather, time, economy)
]]

local state = {}

--- Sets a replicated value on a player's state bag.
function state.setPlayer(source, key, value, replicated)
    Player(source).state:set(key, value, replicated ~= false)
end

--- Reads a value from a player's state bag.
function state.getPlayer(source, key)
    return Player(source).state[key]
end

--- Sets a replicated value on an entity's state bag.
function state.setEntity(entity, key, value, replicated)
    Entity(entity).state:set(key, value, replicated ~= false)
end

--- Reads a value from an entity's state bag.
function state.getEntity(entity, key)
    return Entity(entity).state[key]
end

--- Sets a replicated value on the global state bag.
function state.setGlobal(key, value, replicated)
    GlobalState:set(key, value, replicated ~= false)
end

--- Reads a value from the global state bag.
function state.getGlobal(key)
    return GlobalState[key]
end

--- Subscribes to state-bag changes. `keyFilter`/`bagFilter` may be nil to
--- match all. Returns the handler cookie (pass to RemoveStateBagChangeHandler).
--- @param keyFilter string|nil
--- @param bagFilter string|nil
--- @param handler fun(bagName:string, key:string, value:any, reserved:any, replicated:boolean)
--- @return integer cookie
function state.onChange(keyFilter, bagFilter, handler)
    return AddStateBagChangeHandler(keyFilter, bagFilter, handler)
end

return state
