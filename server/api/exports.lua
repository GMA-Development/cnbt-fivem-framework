--[[
    CNBT Framework — Public API / Exports (server)
    ------------------------------------------------------------------
    Two surfaces:

    1. The CNBT global — assembled here for code running INSIDE this
       resource (live objects with methods).

    2. exports.cnbt:* — for OTHER resources. Return values are serialized
       across the resource boundary, so these expose data and actions, not
       live objects. This is the cross-resource API ("API ovunque").
]]

local Player = require 'server.modules.player.player'
local db = require 'server.modules.database.database'
local state = require 'server.modules.state.state'
local callback = require 'server.modules.callback.callback'
local writeBehind = require 'server.modules.database.writeBehind'
local identity = require 'server.modules.identity.identity'
local emitter = require('server.modules.events').emitter

-- In-resource framework object.
CNBT.db = db
CNBT.state = state
CNBT.callback = callback
CNBT.writeBehind = writeBehind
CNBT.identity = identity
CNBT.events = emitter
CNBT.getPlayer = Player.get
CNBT.getPlayers = Player.getAll

-- ── Cross-resource exports ───────────────────────────────────────

local function withPlayer(source, fn)
    local ply = Player.get(source)
    if not ply then return nil end
    return fn(ply)
end

-- Player data (serializable snapshots).
exports('getPlayer', function(source)
    return withPlayer(source, function(p)
        return p.char and { source = p.source, userId = p.userId, char = p.char } or nil
    end)
end)

exports('isPlayerLoaded', function(source)
    local p = Player.get(source)
    return p ~= nil and p.char ~= nil
end)

exports('getMoney', function(source, account)
    return withPlayer(source, function(p) return p:getMoney(account) end)
end)

exports('addMoney', function(source, account, amount, reason)
    return withPlayer(source, function(p) return p:addMoney(account, amount, reason) end)
end)

exports('removeMoney', function(source, account, amount, reason)
    return withPlayer(source, function(p) return p:removeMoney(account, amount, reason) end)
end)

exports('getJob', function(source)
    return withPlayer(source, function(p) return p:getJob() end)
end)

exports('setJob', function(source, name, grade)
    return withPlayer(source, function(p) return p:setJob(name, grade) end)
end)

-- Database passthrough (so other resources reuse the pooled connection).
exports('query', function(query, params) return db.query(query, params) end)
exports('single', function(query, params) return db.single(query, params) end)
exports('scalar', function(query, params) return db.scalar(query, params) end)
exports('insert', function(query, params) return db.insert(query, params) end)
exports('update', function(query, params) return db.update(query, params) end)
exports('transaction', function(queries) return db.transaction(queries) end)

-- Let other resources register await-able callbacks on this framework.
exports('registerCallback', function(name, fn)
    callback.register(name, fn)
    return true
end)

-- Replicated state passthrough.
exports('setPlayerState', function(source, key, value, replicated)
    state.setPlayer(source, key, value, replicated)
end)
exports('getPlayerState', function(source, key) return state.getPlayer(source, key) end)
exports('setGlobalState', function(key, value, replicated)
    state.setGlobal(key, value, replicated)
end)
exports('getGlobalState', function(key) return state.getGlobal(key) end)
