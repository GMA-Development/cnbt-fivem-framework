--[[
    CNBT Framework — Minimal OOP
    ------------------------------------------------------------------
    A tiny class system with single inheritance. No metatable magic
    beyond what's needed. Reused everywhere we model entities
    (Player, EventEmitter, ...).

    Example:
        local Animal = class('Animal')
        function Animal:init(name) self.name = name end
        function Animal:speak() return '...' end

        local Dog = class('Dog', Animal)
        function Dog:speak() return 'woof' end

        local d = Dog.new('Rex')   -- or Dog('Rex')
        d.name      --> 'Rex'
        d:speak()   --> 'woof'
]]

--- Creates a class, optionally inheriting from `super`.
--- @param name string Class name (stored on __name, handy for debugging)
--- @param super table|nil Parent class
--- @return table
local function class(name, super)
    local cls = setmetatable({}, {
        __index = super,                          -- inherit static + methods
        __call = function(self, ...) return self.new(...) end,
    })
    cls.__index = cls
    cls.__name = name
    cls.super = super

    --- Instantiates the class. Calls :init(...) if defined.
    function cls.new(...)
        local self = setmetatable({}, cls)
        if self.init then self:init(...) end
        return self
    end

    return cls
end

return class
