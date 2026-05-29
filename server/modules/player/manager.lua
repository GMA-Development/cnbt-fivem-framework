--[[
    CNBT Framework — Player Manager (server)
    ------------------------------------------------------------------
    Owns the connection lifecycle and wires identity into the runtime
    Player object:
      connecting  -> deferral + license resolution
      playerReady -> resolve/create account, build Player
      character   -> list / create / select callbacks (await-able by UI)
      dropped     -> save + evict + cleanup

    Registers the 'character' write-behind domain and a before-flush hook
    that refreshes every online player's position right before a batch
    flush — so we persist fresh positions without any per-frame loop.
]]

local Player = require 'server.modules.player.player'
local identity = require 'server.modules.identity.identity'
local writeBehind = require 'server.modules.database.writeBehind'
local callback = require 'server.modules.callback.callback'
local emitter = require('server.modules.events').emitter
local logger = require 'shared.logger'
local config = require 'config.config'

-- Persist characters via the write-behind cache.
writeBehind.register('character', identity.buildSaveQueries)

-- Refresh live positions just before each batched flush (no polling loop).
writeBehind.onBeforeFlush(function()
    for _, ply in pairs(Player.getAll()) do
        ply:syncPosition()
    end
end)

--- Resolves a player's Rockstar/license identifier.
--- @param source integer
--- @return string|nil
local function getLicense(source)
    local ids = GetPlayerIdentifiers(source)
    for i = 1, #ids do
        if ids[i]:sub(1, 8) == 'license:' then
            return ids[i]
        end
    end
    return nil
end

-- Connection gate. Extend with ban/whitelist checks later.
AddEventHandler('playerConnecting', function(_, _, deferrals)
    local source = source
    deferrals.defer()
    Wait(0)
    if not getLicense(source) then
        deferrals.done('CNBT: impossibile identificare la licenza del giocatore.')
        return
    end
    deferrals.done()
end)

-- Guards against duplicate account resolution while the DB await is in
-- flight (double-fired or spoofed playerReady).
local connecting = {}

-- Client signals it is ready; resolve the account and build the Player.
RegisterNetEvent('cnbt:server:playerReady', function()
    local source = source
    if Player.get(source) or connecting[source] then return end

    local license = getLicense(source)
    if not license then
        DropPlayer(source, 'CNBT: licenza non valida.')
        return
    end

    connecting[source] = true
    local account = identity.ensureAccount(license)
    Player.new(source, account)
    connecting[source] = nil

    logger.info(('connessione: %s (account #%d)'):format(GetPlayerName(source), account.id))
    TriggerClientEvent('cnbt:client:accountReady', source)
end)

-- ── Character selection callbacks (await-able from the client) ────

callback.register('cnbt:getCharacters', function(source)
    local ply = Player.get(source)
    return ply and identity.getCharacters(ply.userId) or {}
end)

callback.register('cnbt:createCharacter', function(source, data)
    local ply = Player.get(source)
    if not ply then return false end
    if #identity.getCharacters(ply.userId) >= config.player.maxCharacters then
        return false
    end
    return identity.createCharacter(ply.userId, data)
end)

callback.register('cnbt:selectCharacter', function(source, charId)
    local ply = Player.get(source)
    if not ply then return false end
    local char = identity.getCharacter(charId)
    if not char or char.userId ~= ply.userId then return false end -- ownership check
    ply:loadCharacter(char)
    return char
end)

-- Disconnect: persist immediately, evict from cache, clean up.
AddEventHandler('playerDropped', function()
    local source = source
    connecting[source] = nil
    local ply = Player.get(source)
    if not ply then return end
    if ply.char then
        ply:syncPosition()
        writeBehind.flushOne('character', ply.char.id, true) -- flush + evict
    end
    Player.remove(source)
    emitter:emit('player:dropped', source)
    logger.info(('disconnessione: %s'):format(ply.name))
end)
