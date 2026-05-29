--[[ CNBT Framework — String utilities (shared, reusable) ]]

local stringUtils = {}

local CHARSET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'

--- Trims leading/trailing whitespace.
--- @param s string
--- @return string
function stringUtils.trim(s)
    return s and s:match('^%s*(.-)%s*$') or s
end

--- Splits `s` by a literal separator.
--- @param s string
--- @param sep string Literal separator (not a pattern)
--- @return table
function stringUtils.split(s, sep)
    local out, i, from = {}, 0, 1
    sep = sep or ','
    while true do
        local a, b = s:find(sep, from, true) -- plain find
        if not a then
            i = i + 1
            out[i] = s:sub(from)
            break
        end
        i = i + 1
        out[i] = s:sub(from, a - 1)
        from = b + 1
    end
    return out
end

--- Random alphanumeric string of the given length.
--- @param length integer
--- @return string
function stringUtils.random(length)
    local out = {}
    for i = 1, length do
        local r = math.random(#CHARSET)
        out[i] = CHARSET:sub(r, r)
    end
    return table.concat(out)
end

--- Uppercases the first character.
--- @param s string
--- @return string
function stringUtils.capitalize(s)
    if s == '' then return s end
    return s:sub(1, 1):upper() .. s:sub(2)
end

--- Generates a RFC4122 v4 UUID.
--- @return string
function stringUtils.uuid()
    return (('xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'):gsub('[xy]', function(c)
        local v = (c == 'x') and math.random(0, 15) or math.random(8, 11)
        return ('%x'):format(v)
    end))
end

return stringUtils
