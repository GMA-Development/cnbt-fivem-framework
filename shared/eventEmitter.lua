--[[
    CNBT Framework — Event Emitter (shared, reusable)
    ------------------------------------------------------------------
    Lightweight in-process pub/sub used to decouple modules and to power
    the analytics bridge (see server/modules/events.lua). Handlers run
    synchronously in subscription order.
]]

local class = require 'shared.class'

local EventEmitter = class('EventEmitter')

function EventEmitter:init()
    self.handlers = {}
end

--- Subscribes to an event. Returns an unsubscribe function.
--- @param event string
--- @param handler fun(...):any
--- @return fun() unsubscribe
function EventEmitter:on(event, handler)
    local list = self.handlers[event]
    if not list then
        list = {}
        self.handlers[event] = list
    end
    list[#list + 1] = handler
    return function() self:off(event, handler) end
end

--- Subscribes for a single invocation.
--- @param event string
--- @param handler fun(...):any
--- @return fun() unsubscribe
function EventEmitter:once(event, handler)
    local off
    off = self:on(event, function(...)
        off()
        return handler(...)
    end)
    return off
end

--- Removes a previously registered handler.
--- @param event string
--- @param handler fun(...):any
function EventEmitter:off(event, handler)
    local list = self.handlers[event]
    if not list then return end
    for i = #list, 1, -1 do
        if list[i] == handler then
            table.remove(list, i)
        end
    end
end

--- Emits an event to all subscribers (synchronous).
--- @param event string
--- @param ... any
function EventEmitter:emit(event, ...)
    local list = self.handlers[event]
    if not list then return end
    local n = #list
    if n == 0 then return end
    -- snapshot so on()/off()/once() mutations during dispatch are safe
    local snapshot = {}
    for i = 1, n do snapshot[i] = list[i] end
    for i = 1, n do snapshot[i](...) end
end

return EventEmitter
