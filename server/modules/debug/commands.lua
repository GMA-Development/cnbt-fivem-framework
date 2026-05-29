--[[
    CNBT Framework — Debug commands (server)
    ------------------------------------------------------------------
    Loaded ONLY when config.debug is true (see server/main.lua), so a
    production build registers zero commands. Commands are `restricted`,
    meaning in-game use needs an ace permission, but the server/txAdmin
    live console (source 0) can always run them.

      cnbtinfo  [id]                  -> print account/char/money/job
      cnbtmoney [id] [account] [amt]  -> add money (tests write-behind + sync)
      cnbtsave  [id]                  -> force an immediate save
]]

local Player = require 'server.modules.player.player'

--- Replies to the console (source 0) or in-game chat.
local function reply(source, message)
    if source == 0 then
        print('[CNBT] ' .. message)
    else
        TriggerClientEvent('chat:addMessage', source, { args = { '[CNBT]', message } })
    end
end

--- Resolves the target id from args (defaults to the caller).
local function resolveTarget(source, args)
    return tonumber(args[1]) or source
end

RegisterCommand('cnbtinfo', function(source, args)
    local target = resolveTarget(source, args)
    local ply = Player.get(target)
    if not ply or not ply.char then
        reply(source, ('player #%s non caricato'):format(target))
        return
    end
    reply(source, ('%s | citizenid=%s | cash=%d bank=%d | job=%s:%d'):format(
        ply.name, ply.char.citizenid,
        ply:getMoney('cash'), ply:getMoney('bank'),
        ply.char.job.name, ply.char.job.grade
    ))
end, true)

RegisterCommand('cnbtmoney', function(source, args)
    local target = resolveTarget(source, args)
    local account = args[2] or 'cash'
    local amount = tonumber(args[3]) or 0
    local ply = Player.get(target)
    if not ply then
        reply(source, ('player #%s non trovato'):format(target))
        return
    end
    if ply:addMoney(account, amount, 'debug') then
        reply(source, ('+%d su %s per #%d (totale %d)'):format(amount, account, target, ply:getMoney(account)))
    else
        reply(source, 'operazione rifiutata (account/importo non validi)')
    end
end, true)

RegisterCommand('cnbtsave', function(source, args)
    local target = resolveTarget(source, args)
    local ply = Player.get(target)
    if ply and ply:save() then
        reply(source, ('salvato #%d'):format(target))
    else
        reply(source, 'nessun personaggio da salvare')
    end
end, true)
