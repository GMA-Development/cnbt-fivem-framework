--[[
    CNBT Framework — Events & Analytics bridge (server)
    ------------------------------------------------------------------
    A single shared EventEmitter instance for in-resource decoupling
    (modules pass live objects to each other), PLUS a bridge that
    re-broadcasts key lifecycle events as serializable FiveM events so
    OTHER resources can consume them for analytics/integrations.

    Keeping the serialization mapping here (not at each call site) means
    Player/manager code only emits once, with no duplication.

    External events (server-side, listen with AddEventHandler):
      cnbt:character:loaded  (source, charId, citizenid)
      cnbt:money:changed     (source, account, delta, reason)
      cnbt:job:changed       (source, jobName, grade)
      cnbt:player:dropped    (source)
]]

local EventEmitter = require 'shared.eventEmitter'

local emitter = EventEmitter.new()

emitter:on('character:loaded', function(player)
    TriggerEvent('cnbt:character:loaded', player.source, player.char.id, player.char.citizenid)
end)

emitter:on('money:changed', function(player, account, delta, reason)
    TriggerEvent('cnbt:money:changed', player.source, account, delta, reason)
end)

emitter:on('job:changed', function(player, job)
    TriggerEvent('cnbt:job:changed', player.source, job.name, job.grade)
end)

emitter:on('player:dropped', function(source)
    TriggerEvent('cnbt:player:dropped', source)
end)

return { emitter = emitter }
