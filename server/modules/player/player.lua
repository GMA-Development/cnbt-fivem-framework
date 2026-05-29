--[[
    CNBT Framework — Player (server)
    ------------------------------------------------------------------
    Runtime object for a connected player and their active character.
    Persistent fields live in `self.char` (in memory) and are mirrored to
    the player's state bag for native client replication. Mutations mark
    the character dirty for the write-behind cache and emit events for the
    analytics bridge — never write to the DB directly here.

    NOTE: we deliberately use the `state` component instead of the native
    Player(source) global, since `Player` is also this class's name.
]]

local class = require 'shared.class'
local state = require 'server.modules.state.state'
local writeBehind = require 'server.modules.database.writeBehind'
local emitter = require('server.modules.events').emitter

local Player = class('Player')

-- Online players keyed by server source.
local players = {}

function Player:init(source, account)
    self.source = source
    self.userId = account.id
    self.license = account.license
    self.name = GetPlayerName(source) or ('player_%d'):format(source)
    self.char = nil -- active character, set by loadCharacter
    players[source] = self
end

-- ── Static registry ──────────────────────────────────────────────

--- Returns the online Player for a source (or nil).
function Player.get(source)
    return players[source]
end

--- Returns all online players keyed by source.
function Player.getAll()
    return players
end

--- Removes a player from the registry.
function Player.remove(source)
    players[source] = nil
end

-- ── Character lifecycle ──────────────────────────────────────────

--- Loads a character row as the active character and mirrors it to the
--- replicated state bag.
--- @param char table Decoded character row
function Player:loadCharacter(char)
    self.char = char
    local src = self.source
    state.setPlayer(src, 'citizenid', char.citizenid)
    state.setPlayer(src, 'charId', char.id)
    state.setPlayer(src, 'name', { first = char.firstName, last = char.lastName })
    state.setPlayer(src, 'money', char.money)
    state.setPlayer(src, 'job', char.job)

    writeBehind.set('character', char.id, char)
    emitter:emit('character:loaded', self)
end

-- ── Money ────────────────────────────────────────────────────────

--- Returns the balance of an account ('cash', 'bank', ...).
function Player:getMoney(account)
    return self.char and (self.char.money[account] or 0) or 0
end

--- Adds money to an account. Returns true on success.
function Player:addMoney(account, amount, reason)
    if not self.char or amount <= 0 then return false end
    local money = self.char.money
    money[account] = (money[account] or 0) + amount
    state.setPlayer(self.source, 'money', money)
    writeBehind.markDirty('character', self.char.id)
    emitter:emit('money:changed', self, account, amount, reason)
    return true
end

--- Removes money from an account if sufficient. Returns true on success.
function Player:removeMoney(account, amount, reason)
    if not self.char or amount <= 0 then return false end
    local money = self.char.money
    local current = money[account] or 0
    if current < amount then return false end
    money[account] = current - amount
    state.setPlayer(self.source, 'money', money)
    writeBehind.markDirty('character', self.char.id)
    emitter:emit('money:changed', self, account, -amount, reason)
    return true
end

-- ── Job ──────────────────────────────────────────────────────────

--- Returns the active job { name, grade }.
function Player:getJob()
    return self.char and self.char.job
end

--- Sets the active job. Returns true on success.
function Player:setJob(name, grade)
    if not self.char then return false end
    self.char.job = { name = name, grade = grade or 0 }
    state.setPlayer(self.source, 'job', self.char.job)
    writeBehind.markDirty('character', self.char.id)
    emitter:emit('job:changed', self, self.char.job)
    return true
end

-- ── Position & persistence ───────────────────────────────────────

--- Returns the player's current world coordinates (vector3).
function Player:getCoords()
    return GetEntityCoords(GetPlayerPed(self.source))
end

--- Refreshes the character's stored position from the live ped, if valid.
function Player:syncPosition()
    if not self.char then return end
    local ped = GetPlayerPed(self.source)
    if ped == 0 then return end
    local coords = GetEntityCoords(ped)
    if coords.x == 0.0 and coords.y == 0.0 then return end -- ped not streamed yet
    self.char.position = {
        x = coords.x,
        y = coords.y,
        z = coords.z,
        heading = GetEntityHeading(ped),
    }
    writeBehind.markDirty('character', self.char.id)
end

--- Forces an immediate persistence of the active character.
function Player:save()
    if not self.char then return false end
    self:syncPosition()
    return writeBehind.flushOne('character', self.char.id, false)
end

return Player
