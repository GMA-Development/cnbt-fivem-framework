--[[
    CNBT Framework — Logger (shared, reusable)
    ------------------------------------------------------------------
    Level-gated, colorized console logging. Tables are JSON-encoded.
    Exposes logger.trace/debug/info/warn/error — all share one code path
    (no duplicated functions).
]]

local config = require 'config.config'

local LEVELS = { trace = 1, debug = 2, info = 3, warn = 4, error = 5 }
local COLORS = { trace = '^7', debug = '^6', info = '^2', warn = '^3', error = '^1' }
local RESET = '^7'

local threshold = LEVELS[config.logLevel] or LEVELS.info

local function stringify(value)
    return type(value) == 'table' and json.encode(value) or tostring(value)
end

local function output(level, ...)
    if LEVELS[level] < threshold then return end
    local n = select('#', ...)
    local parts = {}
    for i = 1, n do
        parts[i] = stringify((select(i, ...)))
    end
    print(('%s[CNBT:%s]%s %s'):format(COLORS[level], level:upper(), RESET, table.concat(parts, ' ')))
end

local logger = {}
for level in pairs(LEVELS) do
    logger[level] = function(...) output(level, ...) end
end

return logger
