local Class = require("lib.class")
local Asteroid = Class:extend()
local Assets = require("assets")
local Config = require("config")

function Asteroid:init(x, y, w, h)
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    self.drawX = x
    self.drawY = y
    self.tweenActive = false
    self.momentum = {x = 0, y = 0}
end
function Asteroid:moveTo(newX, newY)
    self.x = newX
    self.y = newY
    if self._flux then
        self.tweenActive = true
        self._flux:to(self, Config.SHIP_ANIMATION_SPEED, {drawX = newX, drawY = newY}):ease("quadout"):oncomplete(function()
            self.tweenActive = false
        end)
    else
        self.drawX = newX
        self.drawY = newY
    end
end

function Asteroid:setFlux(flux)
    self._flux = flux
end

function Asteroid:draw(tileSize, offsetX, offsetY)
    local drawX = self.drawX or self.x
    local drawY = self.drawY or self.y
    local px = offsetX + drawX * tileSize + tileSize / 2
    local py = offsetY + drawY * tileSize + tileSize / 2
    local scale = tileSize / 64

    if Assets.asteroidQuads and #Assets.asteroidQuads > 0 then
        local frameIdx = ((self.x * 7 + self.y * 13) % #Assets.asteroidQuads) + 1
        love.graphics.setColor(1, 1, 1)
        for dy = 0, self.h - 1 do
            for dx = 0, self.w - 1 do
                local fx = px + dx * tileSize
                local fy = py + dy * tileSize
                local fi = ((frameIdx + dx * 3 + dy * 5) % #Assets.asteroidQuads) + 1
                love.graphics.draw(
                    Assets.asteroidSheet,
                    Assets.asteroidQuads[fi],
                    fx, fy,
                    0,
                    scale, scale,
                    32, 32
                )
            end
        end
    else
        self:drawFallback(px, py, tileSize)
    end
end

function Asteroid:drawFallback(px, py, tileSize)
    local pw = self.w * tileSize
    local ph = self.h * tileSize
    local pad = 2
    love.graphics.setColor(0.45, 0.32, 0.2)
    love.graphics.rectangle("fill", px - pw/2 + pad, py - ph/2 + pad, pw - pad * 2, ph - pad * 2, 4, 4)
    love.graphics.setColor(0.3, 0.2, 0.12)
    love.graphics.rectangle("line", px - pw/2 + pad, py - ph/2 + pad, pw - pad * 2, ph - pad * 2, 4, 4)
end
function Asteroid:occupies(gx, gy)
    return gx >= self.x and gx < self.x + self.w and gy >= self.y and gy < self.y + self.h
end

return Asteroid
