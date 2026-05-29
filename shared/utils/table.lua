--[[ CNBT Framework — Table utilities (shared, reusable) ]]

local tableUtils = {}

--- Recursively clones a table.
--- @param value any
--- @return any
function tableUtils.deepClone(value)
    if type(value) ~= 'table' then return value end
    local copy = {}
    for k, v in pairs(value) do
        copy[k] = type(v) == 'table' and tableUtils.deepClone(v) or v
    end
    return copy
end

--- Shallow-merges `src` into `dst` (mutates and returns `dst`).
--- @param dst table
--- @param src table
--- @return table
function tableUtils.merge(dst, src)
    for k, v in pairs(src) do dst[k] = v end
    return dst
end

--- True when the table has no entries.
--- @param t table
--- @return boolean
function tableUtils.isEmpty(t)
    return next(t) == nil
end

--- Counts entries (works for maps, not just arrays).
--- @param t table
--- @return integer
function tableUtils.count(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

--- Returns an array of the table's keys.
--- @param t table
--- @return table
function tableUtils.keys(t)
    local out, i = {}, 0
    for k in pairs(t) do
        i = i + 1
        out[i] = k
    end
    return out
end

--- Returns an array of the table's values.
--- @param t table
--- @return table
function tableUtils.values(t)
    local out, i = {}, 0
    for _, v in pairs(t) do
        i = i + 1
        out[i] = v
    end
    return out
end

--- True when an array-style table contains `value`.
--- @param t table
--- @param value any
--- @return boolean
function tableUtils.includes(t, value)
    for i = 1, #t do
        if t[i] == value then return true end
    end
    return false
end

--- Maps an array through `fn(value, index)`.
--- @param t table
--- @param fn fun(value:any, index:integer):any
--- @return table
function tableUtils.map(t, fn)
    local out = {}
    for i = 1, #t do
        out[i] = fn(t[i], i)
    end
    return out
end

--- Filters an array by `fn(value, index)`.
--- @param t table
--- @param fn fun(value:any, index:integer):boolean
--- @return table
function tableUtils.filter(t, fn)
    local out, i = {}, 0
    for idx = 1, #t do
        if fn(t[idx], idx) then
            i = i + 1
            out[i] = t[idx]
        end
    end
    return out
end

return tableUtils
