--[[
    CNBT Framework — Identity (server)
    ------------------------------------------------------------------
    Data-access for accounts (users) and characters. This is the only
    place that knows the DB shape of an identity; the runtime Player
    object and any admin tooling reuse these functions instead of
    re-implementing queries.

    JSON columns (money/job/position/metadata) are decoded on read and
    encoded on write in one spot (decode/buildSaveQueries).
]]

local db = require 'server.modules.database.database'
local stringUtils = require 'shared.utils.string'
local config = require 'config.config'

local identity = {}

local JSON_COLUMNS = { 'money', 'job', 'position', 'metadata' }

--- Decodes JSON columns of a character row into Lua tables (in place).
--- @param row table
--- @return table
function identity.decode(row)
    for i = 1, #JSON_COLUMNS do
        local col = JSON_COLUMNS[i]
        if type(row[col]) == 'string' then
            row[col] = json.decode(row[col])
        end
    end
    return row
end

--- Generates a unique-ish citizen id (collision-checked at insert time).
--- @return string
function identity.generateCitizenId()
    return ('CNBT%s'):format(stringUtils.random(8):upper())
end

--- Returns the account row for a license, creating it if absent.
--- @param license string
--- @return table account { id, license }
function identity.ensureAccount(license)
    local row = db.single('SELECT id, license FROM users WHERE license = ?', { license })
    if row then return row end
    local id = db.insert('INSERT INTO users (license) VALUES (?)', { license })
    return { id = id, license = license }
end

--- Returns all characters belonging to an account (JSON decoded).
--- @param userId integer
--- @return table[]
function identity.getCharacters(userId)
    local rows = db.query('SELECT * FROM characters WHERE userId = ?', { userId }) or {}
    for i = 1, #rows do identity.decode(rows[i]) end
    return rows
end

--- Returns a single character by id (JSON decoded) or nil.
--- @param id integer
--- @return table|nil
function identity.getCharacter(id)
    local row = db.single('SELECT * FROM characters WHERE id = ?', { id })
    return row and identity.decode(row) or nil
end

--- Creates a character seeded from config defaults and returns it.
--- @param userId integer
--- @param data { firstName:string, lastName:string, dob:string, gender:integer }
--- @return table
function identity.createCharacter(userId, data)
    local id = db.insert(
        'INSERT INTO characters (userId, citizenid, firstName, lastName, dob, gender, money, job, position, metadata) ' ..
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        {
            userId,
            identity.generateCitizenId(),
            data.firstName,
            data.lastName,
            data.dob,
            data.gender or 0,
            json.encode(config.player.startingMoney),
            json.encode(config.player.defaultJob),
            json.encode(config.player.defaultSpawn),
            json.encode({}),
        }
    )
    return identity.getCharacter(id)
end

--- Builds the write-behind persistence queries for a character.
--- Registered as the 'character' domain builder in the player manager.
--- @param id integer
--- @param char table
--- @return table[] { { query=, values= } }
function identity.buildSaveQueries(id, char)
    return {
        {
            query = 'UPDATE characters SET money = ?, job = ?, position = ?, metadata = ? WHERE id = ?',
            values = {
                json.encode(char.money),
                json.encode(char.job),
                json.encode(char.position),
                json.encode(char.metadata or {}),
                id,
            },
        },
    }
end

return identity
