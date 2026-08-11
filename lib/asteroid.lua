local Class = require("lib.class")
local Asteroid = Class:extend()

function Asteroid:init(x, y, w, h)
    self.x = x
    self.y = y
    self.w = w
    self.h = h
end

function Asteroid:draw(tileSize, offsetX, offsetY)
    local px = offsetX + self.x * tileSize
    local py = offsetY + self.y * tileSize
    local pw = self.w * tileSize
    local ph = self.h * tileSize
    local pad = 2

    -- Rocky brown fill
    love.graphics.setColor(0.45, 0.32, 0.2)
    love.graphics.rectangle("fill", px + pad, py + pad, pw - pad * 2, ph - pad * 2, 4, 4)

    -- Darker edge
    love.graphics.setColor(0.3, 0.2, 0.12)
    love.graphics.rectangle("line", px + pad, py + pad, pw - pad * 2, ph - pad * 2, 4, 4)

    -- Highlight crack lines
    love.graphics.setColor(0.55, 0.42, 0.28)
    if self.w >= 2 then
        love.graphics.line(px + pw * 0.3, py + pad + 4, px + pw * 0.6, py + ph - pad - 4)
    end
    if self.h >= 2 then
        love.graphics.line(px + pad + 4, py + ph * 0.4, px + pw - pad - 4, py + ph * 0.7)
    end
    if self.w >= 3 and self.h >= 3 then
        love.graphics.line(px + pw * 0.7, py + pad + 4, px + pw * 0.4, py + ph * 0.5)
    end
end

function Asteroid:occupies(gx, gy)
    return gx >= self.x and gx < self.x + self.w and gy >= self.y and gy < self.y + self.h
end

return Asteroid
