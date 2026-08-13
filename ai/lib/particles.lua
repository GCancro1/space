local Config = require("config")
local Assets = require("assets")
local Particles = {}
Particles.__index = Particles

function Particles:new()
    local self = setmetatable({}, Particles)
    self.systems = {}
    return self
end

function Particles:createThruster(x, y, angle, color)
    local tex = Assets.thruster[1]
    if not tex then return end
    local ps = love.graphics.newParticleSystem(tex, 128)
    ps:setParticleLifetime(Config.THRUSTER_LIFETIME, Config.THRUSTER_LIFETIME * 1.5)
    ps:setEmissionRate(40)
    ps:setDirection(angle + math.pi)
    ps:setSpread(math.pi / 6)
    ps:setSpeed(Config.THRUSTER_SPEED_MIN, Config.THRUSTER_SPEED_MAX)
    ps:setSizes(Config.THRUSTER_SIZE_MIN, Config.THRUSTER_SIZE_MAX)
    ps:setSizeVariation(1)
    ps:setColors(
        0.8, 0.9, 1.0, 1,
        color[1], color[2], color[3], 0.6,
        color[1] * 0.5, color[2] * 0.5, color[3] * 0.5, 0
    )
    ps:setPosition(x, y)
    ps:emit(12)
    table.insert(self.systems, {ps = ps, duration = -1})
end

function Particles:createExplosion(x, y, color)
    local tex = Assets.explosionSheet
    if not tex then return end
    local ps = love.graphics.newParticleSystem(tex, 256)
    ps:setParticleLifetime(Config.EXPLOSION_LIFETIME, Config.EXPLOSION_LIFETIME * 1.5)
    ps:setEmissionRate(0)
    ps:setDirection(0)
    ps:setSpread(math.pi * 2)
    ps:setSpeed(60, 150)
    ps:setSize(8, 16)
    ps:setSizeVariation(1)
    ps:setColors(
        1, 1, 0.8, 1,
        1, 0.5, 0.1, 0.8,
        color[1], color[2], color[3], 0.4,
        0.2, 0.2, 0.2, 0
    )
    ps:setPosition(x, y)
    ps:emit(Config.EXPLOSION_PARTICLE_COUNT)
    table.insert(self.systems, {ps = ps, duration = 0})
end

function Particles:update(dt)
    for i = #self.systems, 1, -1 do
        local entry = self.systems[i]
        entry.ps:update(dt)
        if entry.duration >= 0 then
            entry.duration = entry.duration - dt
        end
        if entry.ps:getCount() == 0 then
            table.remove(self.systems, i)
        end
    end
end

function Particles:draw()
    love.graphics.setColor(1, 1, 1)
    for _, entry in ipairs(self.systems) do
        love.graphics.draw(entry.ps)
    end
end

return Particles
