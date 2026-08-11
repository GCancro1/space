local Class = require("lib.class")
local Config = require("config")
local Ship = Class:extend()

-- User-facing degrees: 0=North, clockwise
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

-- Convert game degrees to Love2D radians (0=right, counterclockwise)
local function toRad(deg)
    return (deg - 90) * math.pi / 180
end

function Ship:init(x, y, facing, color)
    self.x = x
    self.y = y
    self.facing = facing
    self.turretFacing = facing
    self.hp = Config.SHIP_HP
    self.fuel = Config.SHIP_FUEL
    self.momentum = { x = 0, y = 0 }
    self.color = color or Config.SHIP_COLOR
    self.bodyRadius = 0
    self.turretRadius = 0
end

function Ship:draw(tileSize, offsetX, offsetY)
    local cx = offsetX + self.x * tileSize + tileSize / 2
    local cy = offsetY + self.y * tileSize + tileSize / 2
    self.bodyRadius = tileSize * 0.30
    self.turretRadius = tileSize * 0.15
    self:drawBody(cx, cy)
    self:drawTurret(cx, cy)
end

function Ship:drawBody(cx, cy)
    local r = self.bodyRadius
    local angle = toRad(FACING_DEGREES[self.facing] or 0)

    -- Body sphere
    love.graphics.setColor(self.color)
    love.graphics.circle("fill", cx, cy, r)
    love.graphics.setColor(1, 1, 1, 0.4)
    love.graphics.circle("line", cx, cy, r)

    -- Arrow pointer
    -- Arrow color: lighter version of ship color
    love.graphics.setColor(
        math.min(1, self.color[1] + 0.3),
        math.min(1, self.color[2] + 0.3),
        math.min(1, self.color[3] + 0.3)
    )

    local arrowLen = r * 1.5
    local arrowWidth = r * 0.6
    local tipX = cx + math.cos(angle) * arrowLen
    local tipY = cy + math.sin(angle) * arrowLen
    local perp = angle + math.pi / 2
    local bx = cx + math.cos(angle) * (r * 0.2)
    local by = cy + math.sin(angle) * (r * 0.2)
    local lx = bx + math.cos(perp) * arrowWidth
    local ly = by + math.sin(perp) * arrowWidth
    local rx = bx - math.cos(perp) * arrowWidth
    local ry = by - math.sin(perp) * arrowWidth
    love.graphics.polygon("fill", tipX, tipY, lx, ly, rx, ry)
end

function Ship:drawTurret(cx, cy)
    local r = self.turretRadius
    local angle = toRad(FACING_DEGREES[self.turretFacing] or 0)
    local bodyR = self.bodyRadius

    -- Offset turret slightly forward
    local tx = cx + math.cos(angle) * (bodyR * 0.3)
    local ty = cy + math.sin(angle) * (bodyR * 0.3)

    -- Turret sphere
    love.graphics.setColor(Config.TURRET_COLOR)
    love.graphics.circle("fill", tx, ty, r)
    love.graphics.setColor(1, 1, 1, 0.4)
    love.graphics.circle("line", tx, ty, r)

    -- Gun barrel
    love.graphics.setColor(0.7, 0.7, 0.7)
    local barrelLen = r * 2.5
    local barrelWidth = r * 0.8
    love.graphics.push()
    love.graphics.translate(tx, ty)
    love.graphics.rotate(angle)
    love.graphics.rectangle("fill", r * 0.3, -barrelWidth / 2, barrelLen, barrelWidth)
    love.graphics.pop()
end

return Ship
