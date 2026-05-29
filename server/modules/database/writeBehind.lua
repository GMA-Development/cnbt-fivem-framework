--[[
    CNBT Framework — Write-Behind Cache (server)
    ------------------------------------------------------------------
    THE core DB optimization. Instead of writing to MySQL on every change
    (the real resmon/IO bottleneck), persistent data lives in memory and
    is marked "dirty" when it changes. A periodic flush batches every
    dirty entry across every domain into a SINGLE transaction.

    Guarantees no data loss on a clean shutdown/disconnect:
      - periodic flush every config.database.saveInterval
      - flushOne() on player disconnect
      - flush() on resource stop

    A "domain" (e.g. 'character') registers a builder that turns an id +
    its data into the queries needed to persist it. This component knows
    nothing about characters/vehicles/etc. — it's fully reusable.
]]

local db = require 'server.modules.database.database'
local config = require 'config.config'
local logger = require 'shared.logger'

local writeBehind = {}

-- registry[domain] = { build = fn, store = { [id] = data }, dirty = { [id] = true } }
local registry = {}
local beforeFlush = {}

--- Registers a persistence domain.
--- @param domain string e.g. 'character'
--- @param builder fun(id:any, data:table):table[] returns { { query=, values= }, ... }
function writeBehind.register(domain, builder)
    registry[domain] = { build = builder, store = {}, dirty = {} }
end

--- Stores/replaces data for an id and marks it dirty.
--- @param domain string
--- @param id any
--- @param data table
function writeBehind.set(domain, id, data)
    local d = registry[domain]
    d.store[id] = data
    d.dirty[id] = true
end

--- Returns the cached data for an id.
--- @param domain string
--- @param id any
--- @return table|nil
function writeBehind.get(domain, id)
    return registry[domain].store[id]
end

--- Flags an id as dirty (data was mutated in place).
--- @param domain string
--- @param id any
function writeBehind.markDirty(domain, id)
    registry[domain].dirty[id] = true
end

--- Removes an id from the cache (call after a final flush).
--- @param domain string
--- @param id any
function writeBehind.evict(domain, id)
    local d = registry[domain]
    d.store[id] = nil
    d.dirty[id] = nil
end

--- Registers a hook run immediately before each flush (e.g. to refresh
--- live positions from peds). Reusable extension point.
--- @param fn fun()
function writeBehind.onBeforeFlush(fn)
    beforeFlush[#beforeFlush + 1] = fn
end

local function collect(domain, d, queries, flushed)
    for id in pairs(d.dirty) do
        local built = d.build(id, d.store[id])
        for i = 1, #built do
            queries[#queries + 1] = built[i]
        end
        flushed[#flushed + 1] = { domain = domain, id = id }
    end
end

--- Flushes every dirty entry (optionally for a single domain) in one
--- transaction. Dirty flags are only cleared on a successful commit.
--- @param domain string|nil
--- @return boolean
function writeBehind.flush(domain)
    for i = 1, #beforeFlush do beforeFlush[i]() end

    local queries, flushed = {}, {}
    if domain then
        collect(domain, registry[domain], queries, flushed)
    else
        for name, d in pairs(registry) do
            collect(name, d, queries, flushed)
        end
    end

    if #queries == 0 then return true end

    local ok = db.transaction(queries)
    if ok then
        for i = 1, #flushed do
            registry[flushed[i].domain].dirty[flushed[i].id] = nil
        end
        logger.debug(('write-behind flushed %d quer%s'):format(#queries, #queries == 1 and 'y' or 'ies'))
    else
        logger.error('write-behind flush failed — keeping dirty flags for retry')
    end
    return ok
end

--- Flushes a single id immediately (e.g. on disconnect). Optionally evicts.
--- @param domain string
--- @param id any
--- @param evict boolean|nil
--- @return boolean
function writeBehind.flushOne(domain, id, evict)
    local d = registry[domain]
    if not d.dirty[id] then
        if evict then writeBehind.evict(domain, id) end
        return true
    end

    local queries = d.build(id, d.store[id])
    local ok = #queries == 0 or db.transaction(queries)
    if ok then
        d.dirty[id] = nil
        if evict then writeBehind.evict(domain, id) end
    end
    return ok
end

-- Periodic batched flush.
CreateThread(function()
    local interval = config.database.saveInterval
    while true do
        Wait(interval)
        writeBehind.flush()
    end
end)

-- Best-effort flush when the resource stops.
AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        writeBehind.flush()
    end
end)

return writeBehind
