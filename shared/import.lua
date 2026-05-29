--[[
    CNBT Framework — Module Loader
    ------------------------------------------------------------------
    Loaded first (shared_script) in both the client and server realms.
    Provides a require()-style loader so every file can pull in reusable
    components on demand. Modules are compiled and executed once, then
    cached: zero runtime cost after the first load.

    Usage:
        local table = require 'shared.utils.table'
        local Player = require 'server.modules.player.player'
]]

local resource = GetCurrentResourceName()
local isServer = IsDuplicityVersion()
local loaded = {}

-- Public framework object for in-resource code (assembled by api/exports.lua).
-- NOTE: this is per-realm and only meaningful inside this resource. Other
-- resources must use the granular exports (see server/api/exports.lua).
CNBT = {
    name = 'cnbt',
    version = '0.1.0',
    resource = resource,
    context = isServer and 'server' or 'client',
    isServer = isServer,
    isClient = not isServer,
}

--- Loads a Lua module by dotted path and caches the result.
--- @param path string Dotted module path, e.g. 'shared.utils.table'
--- @return any The value returned by the module (or true if it returned nil)
local function requireModule(path)
    local cached = loaded[path]
    if cached ~= nil then return cached end

    local fileName = path:gsub('%.', '/') .. '.lua'
    local code = LoadResourceFile(resource, fileName)
    if not code then
        error(("module not found: '%s' (looked for %s)"):format(path, fileName), 2)
    end

    local chunk, err = load(code, ('@@%s/%s'):format(resource, fileName), 't', _ENV)
    if not chunk then
        error(("error compiling module '%s': %s"):format(path, err), 2)
    end

    local result = chunk()
    if result == nil then result = true end
    loaded[path] = result
    return result
end

-- Expose as a resource-scoped global (idiomatic) and on the framework object.
require = requireModule
CNBT.require = requireModule
