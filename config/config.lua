--[[
    CNBT Framework — Configuration (shared)
    Loaded via require('config.config'). Keep this lean; feature configs
    should live next to their modules, not pile up here.
]]

return {
    -- Logging verbosity: trace | debug | info | warn | error
    logLevel = 'info',

    -- Default locale (reserved for the i18n component added later).
    locale = 'it',

    database = {
        -- Write-behind cache: how often dirty data is flushed to MySQL (ms).
        -- Larger = fewer writes / lower DB load. Disconnect still flushes
        -- immediately, so data is never lost on a clean drop.
        saveInterval = 5 * 60 * 1000, -- 5 minutes
    },

    player = {
        maxCharacters = 5,

        -- Fallback spawn (Legion Square) used for brand new characters.
        defaultSpawn = { x = 195.17, y = -933.77, z = 30.69, heading = 144.0 },

        -- Money accounts seeded on character creation.
        startingMoney = { cash = 500, bank = 5000 },

        -- Default job assigned to new characters.
        defaultJob = { name = 'unemployed', grade = 0 },
    },
}
