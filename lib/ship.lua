local Class = require("lib.class")
local Config = require("config")
local Ship = Class:extend()

local FACING_DEGREES = {
    N  = 0,
    NE = 45,
    E  = 90,
    SE = 135,
    S  = 180,
    SW = 225,
    W  = 270,
    NW = 315,
}

local function toRad(deg)
    return (deg - 90) * math.pi / 180
end

local function shortestRotation(current, target)
    local diff = target - current
    while diff > 180 do diff = diff - 360 end
    while diff < -180 do diff = diff + 360 end
    return current + diff
end

function Ship:init(x, y, facing, color, shipIndex)
    self.x = x
    self.y = y
    self.drawX = x
    self.drawY = y
    self.tweenActive = false
    self.facing = facing
    self.drawAngle = FACING_DEGREES[facing]
    self.turretFacing = facing
    self.hp = Config.SHIP_HP
    self.fuel = Config.SHIP_FUEL
    self.momentum = { x = 0, y = 0 }
    self.color = color or Config.SHIP_COLOR
    self.shipIndex = shipIndex or 1
end

function Ship:moveTo(newX, newY)
    local flux = self._flux
    if flux then
        self.tweenActive = true
        flux.to(self, Config.SHIP_ANIMATION_SPEED, {drawX = newX, drawY = newY}):ease("quadout"):oncomplete(function()
            self.tweenActive = false
        end)
    end
    self.x = newX
    self.y = newY
end

function Ship:rotateTo(newFacing)
    local flux = self._flux
    if flux then
        local targetDeg = FACING_DEGREES[newFacing]
        if targetDeg then
            local currentDeg = self.drawAngle % 360
            local goal = shortestRotation(currentDeg, targetDeg)
            flux:to(self, Config.SHIP_ANIMATION_SPEED, {drawAngle = goal}):ease("quadout")
        end
    end
    self.facing = newFacing
end

function Ship:setFlux(flux)
    self._flux = flux
end

function Ship:draw(tileSize, offsetX, offsetY)
    local dx = self.drawX or self.x
    local dy = self.drawY or self.y
    local cx = offsetX + dx * tileSize + tileSize / 2
    local cy = offsetY + dy * tileSize + tileSize / 2
    local r = tileSize * 0.35

    -- 1. Glow circle (player color, soft)
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.25)
    love.graphics.circle("fill", cx, cy, r * 1.6)

    -- 2. Body circle (player color, solid)
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.9)
    love.graphics.circle("fill", cx, cy, r)

    -- 3. Body outline (bright white)
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", cx, cy, r)

    -- 4. Body direction arrow (bright white, big and clear)
    local bodyAngle = toRad(self.drawAngle or FACING_DEGREES[self.facing] or 0)
    self:drawArrow(cx, cy, bodyAngle, r * 1.7, r * .8, {self.color[1], self.color[2], self.color[3], 0.9})

    -- 5. Turret (offset from center, in turret facing direction)
    local turretAngle = toRad(FACING_DEGREES[self.turretFacing] or 0)
    local turretR = r * 0.35
    local turretOffset = r * 0.5
    local tx = cx + math.cos(turretAngle) * turretOffset
    local ty = cy + math.sin(turretAngle) * turretOffset

    -- Turret circle (yellow/orange)
    love.graphics.setColor(1.0, 0.85, 0.2, 0.95)
    love.graphics.circle("fill", tx, ty, turretR)
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.circle("line", tx, ty, turretR)

    -- 6. Gun barrel (extending from turret in turret facing direction)
    local barrelLen = turretR * 3.0
    local barrelWidth = turretR * 0.9
    love.graphics.setColor(0.75, 0.75, 0.75)
    love.graphics.push()
    love.graphics.translate(tx, ty)
    love.graphics.rotate(turretAngle)
    love.graphics.rectangle("fill", turretR * 0.4, -barrelWidth / 2, barrelLen, barrelWidth, 2, 2)
    love.graphics.pop()

    -- 7. Player number label
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.setFont(love.graphics.newFont(math.max(10, tileSize * 0.18)))
    love.graphics.printf(tostring(self.shipIndex), cx - r, cy - r * 0.4, r * 2, "center")
end

function Ship:drawArrow(cx, cy, angle, length, halfWidth, color)
    love.graphics.setColor(color)
    local tipX = cx + math.cos(angle) * length
    local tipY = cy + math.sin(angle) * length
    local perp = angle + math.pi / 2
    local bx = cx + math.cos(angle) * (length * 0.15)
    local by = cy + math.sin(angle) * (length * 0.15)
    local lx = bx + math.cos(perp) * halfWidth
    local ly = by + math.sin(perp) * halfWidth
    local rx = bx - math.cos(perp) * halfWidth
    local ry = by - math.sin(perp) * halfWidth
    love.graphics.polygon("fill", tipX, tipY, lx, ly, rx, ry)
end

return Ship
