--[[ CNBT Framework — Math utilities (shared, reusable) ]]

local mathUtils = {}

--- Rounds `n` to `decimals` places (default 0).
--- @param n number
--- @param decimals integer|nil
--- @return number
function mathUtils.round(n, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(n * mult + 0.5) / mult
end

--- Clamps `n` into the [min, max] range.
--- @param n number
--- @param min number
--- @param max number
--- @return number
function mathUtils.clamp(n, min, max)
    if n < min then return min end
    if n > max then return max end
    return n
end

--- Linear interpolation between a and b by t in [0, 1].
--- @param a number
--- @param b number
--- @param t number
--- @return number
function mathUtils.lerp(a, b, t)
    return a + (b - a) * t
end

return mathUtils
