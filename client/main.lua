--[[
    CNBT Framework — Client bootstrap
    ------------------------------------------------------------------
    Loads client modules, then drives a MINIMAL character flow so the
    framework is immediately playable:
      session ready -> tell server we're ready
      accountReady  -> fetch characters, auto-pick first (or create a
                       default), select it, spawn at saved position.

    A proper multi-character NUI selector is a later feature — it can
    drive the very same await-able callbacks (getCharacters /
    createCharacter / selectCharacter) without touching the server.
]]

local callback = require 'client.modules.callback.callback'
require 'client.modules.state.state'
require 'client.api.exports'

local logger = require 'shared.logger'

--- Teleports the local ped to a saved position and ends the loading screen.
local function spawnAt(position)
    local ped = PlayerPedId()
    RequestCollisionAtCoord(position.x, position.y, position.z)
    SetEntityCoords(ped, position.x, position.y, position.z, false, false, false, false)
    SetEntityHeading(ped, position.heading or 0.0)
    FreezeEntityPosition(ped, false)

    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
end

-- Tell the server we're ready once the session is actually live.
AddEventHandler('onClientResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    CreateThread(function()
        while not NetworkIsSessionStarted() do Wait(200) end
        TriggerServerEvent('cnbt:server:playerReady')
    end)
end)

-- Account is ready: resolve the active character (minimal auto-flow).
RegisterNetEvent('cnbt:client:accountReady', function()
    CreateThread(function()
        local characters = callback.call('cnbt:getCharacters')
        local character = characters[1]

        if not character then
            character = callback.call('cnbt:createCharacter', {
                firstName = 'Nuovo',
                lastName = 'Personaggio',
                dob = '2000-01-01',
                gender = 0,
            })
        end

        if not character then
            logger.error('impossibile creare/selezionare un personaggio')
            return
        end

        local selected = callback.call('cnbt:selectCharacter', character.id)
        if not selected then
            logger.error('selezione personaggio rifiutata dal server')
            return
        end

        spawnAt(selected.position)
        TriggerEvent('cnbt:client:characterSelected', selected)
        logger.info(('personaggio attivo: %s %s'):format(selected.firstName, selected.lastName))
    end)
end)

logger.info(('framework v%s avviato (client)'):format(CNBT.version))
