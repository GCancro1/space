local Class = require("lib.class")
local Config = require("config")

local ShipPanel = Class:extend()

local FACING_ANGLES = {
    N  = -math.pi / 2,
    NE = -math.pi / 4,
    E  = 0,
    SE = math.pi / 4,
    S  = math.pi / 2,
    SW = 3 * math.pi / 4,
    W  = math.pi,
    NW = -3 * math.pi / 4,
}

function ShipPanel:init()
end

function ShipPanel:drawAll(ships, infoBarY, infoBarHeight, screenWidth)
    local oldFont = love.graphics.getFont()
    local bigFont = love.graphics.newFont(42)
    love.graphics.setFont(bigFont)

    local colW = screenWidth / 4
    for i, ship in ipairs(ships) do
        local panelX = (i - 1) * colW
        self:drawShipPanel(i, ship, panelX, infoBarY, colW, infoBarHeight)
    end

    -- Vertical dividers between panels
    love.graphics.setColor(Config.INFO_BAR_BORDER)
    for i = 1, 3 do
        local divX = i * colW
        love.graphics.line(divX, infoBarY, divX, infoBarY + infoBarHeight)
    end

    love.graphics.setFont(oldFont)
end

function ShipPanel:drawShipPanel(index, ship, x, y, w, h)
    local color = ship.color

    -- Compass on the left
    local radius = 80
    local cx = x + radius + 25
    local cy = y + h / 2
    self:drawMomentumCompass(cx, cy, radius, ship)

    -- Stats on the right
    local statsX = x + radius * 2 + 55
    local momY = cy - 40
    local hpY = cy - 4
    local fuelY = cy + 24

    -- Momentum text
    love.graphics.setColor(Config.TEXT_COLOR)
    local momParts = {}
    if ship.momentum.y < 0 then table.insert(momParts, "N" .. math.abs(ship.momentum.y)) end
    if ship.momentum.y > 0 then table.insert(momParts, "S" .. math.abs(ship.momentum.y)) end
    if ship.momentum.x > 0 then table.insert(momParts, "E" .. math.abs(ship.momentum.x)) end
    if ship.momentum.x < 0 then table.insert(momParts, "W" .. math.abs(ship.momentum.x)) end
    local momText = "Mom: " .. (#momParts > 0 and table.concat(momParts, " ") or "0")
    love.graphics.print(momText, statsX, momY)

    -- HP and Fuel bars
    local barWidth = math.min(180, (x + w - 10) - statsX - 60)
    self:drawHPBar(statsX, hpY, ship, barWidth)
    self:drawFuelBar(statsX, fuelY, ship, barWidth)
end

function ShipPanel:drawCompassBase(cx, cy, radius)
    -- Background circle
    love.graphics.setColor(0.05, 0.05, 0.1)
    love.graphics.circle("fill", cx, cy, radius)

    -- Outline
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.circle("line", cx, cy, radius)

    -- Tick marks and labels
    local font = love.graphics.getFont()
    for _, dir in ipairs(Config.FACING_LIST) do
        local angle = FACING_ANGLES[dir] or 0
        local isCardinal = (dir == "N" or dir == "E" or dir == "S" or dir == "W")
        local innerR = isCardinal and (radius - 14) or (radius - 9)
        local outerR = radius - 2

        local ix = cx + math.cos(angle) * innerR
        local iy = cy + math.sin(angle) * innerR
        local ox = cx + math.cos(angle) * outerR
        local oy = cy + math.sin(angle) * outerR

        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.line(ix, iy, ox, oy)

        if isCardinal then
            local labelR = radius + 14
            local lx = cx + math.cos(angle) * labelR
            local ly = cy + math.sin(angle) * labelR
            love.graphics.setColor(0.7, 0.7, 0.7)
            local fw = font:getWidth(dir)
            local fh = font:getHeight()
            love.graphics.print(dir, lx - fw / 2, ly - fh / 2)
        end
    end
end

function ShipPanel:drawArrow(cx, cy, angle, length, halfWidth, color)
    love.graphics.setColor(color)
    local tipX = cx + math.cos(angle) * length
    local tipY = cy + math.sin(angle) * length
    local perp = angle + math.pi / 2
    local lx = cx + math.cos(perp) * halfWidth
    local ly = cy + math.sin(perp) * halfWidth
    local rx = cx - math.cos(perp) * halfWidth
    local ry = cy - math.sin(perp) * halfWidth
    love.graphics.polygon("fill", tipX, tipY, lx, ly, rx, ry)
end

function ShipPanel:drawMomentumCompass(cx, cy, radius, ship)
    self:drawCompassBase(cx, cy, radius)

    local mx = ship.momentum.x
    local my = ship.momentum.y

    if mx == 0 and my == 0 then
        -- Center dot for zero momentum
        love.graphics.setColor(ship.color)
        love.graphics.circle("fill", cx, cy, 5)
    else
        local magnitude = math.sqrt(mx * mx + my * my)
        local angle = math.atan2(my, mx)
        local maxLen = radius * 0.8
        local len = math.min(magnitude, 3) / 3 * maxLen
        self:drawArrow(cx, cy, angle, len, radius * 0.15, ship.color)
    end

    -- Center dot
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", cx, cy, 5)
end

function ShipPanel:drawHPBar(x, y, ship, maxWidth)
    local maxHP = Config.SHIP_HP
    local segW = 28
    local segH = 22
    local gap = 3

    love.graphics.setColor(Config.TEXT_COLOR)
    love.graphics.print("HP:", x, y)

    local barX = x + 44
    for i = 1, maxHP do
        local sx = barX + (i - 1) * (segW + gap)
        if sx + segW > x + maxWidth then break end
        if i <= ship.hp then
            love.graphics.setColor(ship.color)
            love.graphics.rectangle("fill", sx, y, segW, segH)
        else
            love.graphics.setColor(0.2, 0.2, 0.2)
            love.graphics.rectangle("line", sx, y, segW, segH)
        end
    end

    love.graphics.setColor(Config.TEXT_COLOR)
    local numX = barX + maxHP * (segW + gap) + 8
    love.graphics.print(ship.hp .. "/" .. maxHP, numX, y)
end

function ShipPanel:drawFuelBar(x, y, ship, maxWidth)
    local maxFuel = Config.SHIP_FUEL
    local barWidth = math.min(140, maxWidth)
    local barH = 22

    love.graphics.setColor(Config.TEXT_COLOR)
    love.graphics.print("Fuel:", x, y)

    local barX = x + 50

    love.graphics.setColor(0.15, 0.15, 0.15)
    love.graphics.rectangle("fill", barX, y, barWidth, barH)

    local fillW = (ship.fuel / maxFuel) * barWidth
    love.graphics.setColor(ship.color)
    love.graphics.rectangle("fill", barX, y, fillW, barH)

    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("line", barX, y, barWidth, barH)

    love.graphics.setColor(Config.TEXT_COLOR)
    local numX = barX + barWidth + 8
    love.graphics.print(ship.fuel .. "/" .. maxFuel, numX, y)
end

return ShipPanel
