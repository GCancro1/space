local Class = {}
Class.__index = Class

function Class:new(...)
    local instance = setmetatable({}, self)
    if instance.init then
        instance:init(...)
    end
    return instance
end

function Class:extend()
    local cls = setmetatable({}, { __index = self })
    cls.__index = cls
    return cls
end

return Class
