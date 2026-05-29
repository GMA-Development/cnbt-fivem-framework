--[[
    CNBT Framework — Database (server)
    ------------------------------------------------------------------
    Thin, synchronous-in-coroutine wrapper over oxmysql. The promise
    plumbing lives in one helper (`await`); each method is just a typed
    binding to the matching oxmysql export — no duplicated logic.

    All calls block the calling coroutine until the query resolves, so
    they must run inside a thread/event handler (FiveM handlers already
    run in coroutines, so this is the normal case).
]]

local oxmysql = exports.oxmysql

--- Wraps a callback-style oxmysql call into an awaited result.
--- @param run fun(cb:fun(result:any))
--- @return any
local function await(run)
    local p = promise.new()
    run(function(result) p:resolve(result) end)
    return Citizen.Await(p)
end

local db = {}

--- Runs a query, returns all matching rows.
function db.query(query, params)
    return await(function(cb) oxmysql:query(query, params, cb) end)
end

--- Returns the first matching row (or nil).
function db.single(query, params)
    return await(function(cb) oxmysql:single(query, params, cb) end)
end

--- Returns a single scalar value from the first row/column.
function db.scalar(query, params)
    return await(function(cb) oxmysql:scalar(query, params, cb) end)
end

--- Runs an INSERT, returns the new insertId.
function db.insert(query, params)
    return await(function(cb) oxmysql:insert(query, params, cb) end)
end

--- Runs an UPDATE/DELETE, returns affected row count.
function db.update(query, params)
    return await(function(cb) oxmysql:update(query, params, cb) end)
end

--- Runs a prepared statement (oxmysql caches the prepare).
function db.prepare(query, params)
    return await(function(cb) oxmysql:prepare(query, params, cb) end)
end

--- Executes a list of { query = string, values = table } atomically.
--- Returns true on commit, false on rollback.
--- @param queries table
--- @return boolean
function db.transaction(queries)
    return await(function(cb) oxmysql:transaction(queries, cb) end)
end

return db
