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

-- Create fonts once (cached across calls)
local fontSmall = nil
local fontMedium = nil
local fontLarge = nil

local function getFonts()
    if not fontSmall then
        fontSmall = love.graphics.newFont(22)
        fontMedium = love.graphics.newFont(32)
        fontLarge = love.graphics.newFont(28)
    end
    return fontSmall, fontMedium, fontLarge
end

-- Rounded rectangle helper (Love2D 11+)
local function roundedRect(mode, x, y, w, h, r)
    love.graphics.rectangle(mode, x, y, w, h, r, r)
end

function ShipPanel:init()
end

function ShipPanel:drawAll(ships, infoBarY, infoBarHeight, screenWidth)
    local oldFont = love.graphics.getFont()
    local fSmall, fMedium, fLarge = getFonts()

    local colW = screenWidth / 4
    local pad = 8
    local cardPad = 6

    -- Draw card backgrounds first
    for i, ship in ipairs(ships) do
        local panelX = (i - 1) * colW + pad
        local cardW = colW - pad * 2
        local cardY = infoBarY + cardPad
        local cardH = infoBarHeight - cardPad * 2
        love.graphics.setColor(0.12, 0.12, 0.18)
        roundedRect("fill", panelX, cardY, cardW, cardH, 14)
        -- Subtle border on card
        love.graphics.setColor(ship.color[1], ship.color[2], ship.color[3], 0.15)
        roundedRect("line", panelX, cardY, cardW, cardH, 14)
    end

    -- Draw panels
    for i, ship in ipairs(ships) do
        local panelX = (i - 1) * colW + pad
        local cardW = colW - pad * 2
        self:drawShipPanel(i, ship, panelX, infoBarY, cardW, infoBarHeight)
    end

    -- Decorative dividers between panels
    for i = 1, 3 do
        local divX = i * colW
        local midY = infoBarY + infoBarHeight / 2
        -- Thin line
        love.graphics.setColor(Config.INFO_BAR_BORDER[1], Config.INFO_BAR_BORDER[2], Config.INFO_BAR_BORDER[3], 0.3)
        love.graphics.line(divX, infoBarY + 20, divX, infoBarY + infoBarHeight - 20)
        -- Diamond markers at top, center, bottom
        local diamondR = 4
        for _, dy in ipairs({infoBarY + 20, midY, infoBarY + infoBarHeight - 20}) do
            love.graphics.setColor(0.4, 0.4, 0.5, 0.5)
            love.graphics.push()
            love.graphics.translate(divX, dy)
            love.graphics.rotate(math.pi / 4)
            love.graphics.rectangle("fill", -diamondR, -diamondR, diamondR * 2, diamondR * 2)
            love.graphics.pop()
        end
    end

    love.graphics.setFont(oldFont)
end

function ShipPanel:drawShipPanel(index, ship, x, y, w, h)
    local color = ship.color
    local fSmall, fMedium, fLarge = getFonts()

    -- Ship index label at top
    love.graphics.setFont(fLarge)
    love.graphics.setColor(color[1], color[2], color[3], 0.8)
    local label = "P" .. index
    local labelW = fLarge:getWidth(label)
    local labelX = x + w / 2 - labelW / 2
    local labelY = y + 10
    -- Background strip behind label
    love.graphics.setColor(color[1], color[2], color[3], 0.2)
    roundedRect("fill", labelX - 8, labelY - 2, labelW + 16, fLarge:getHeight() + 4, 4)
    love.graphics.setColor(color[1], color[2], color[3], 0.9)
    love.graphics.print(label, labelX, labelY)

    -- Compass on the left
    local radius = 70
    local cx = x + radius + 20
    local cy = y + h / 2 + 8
    self:drawMomentumCompass(cx, cy, radius, ship)

    -- Stats on the right
    local statsX = x + radius * 2 + 45
    local momY = cy - 50
    local hpY = cy - 10
    local fuelY = cy + 26

    -- Momentum text with colored indicator dot
    love.graphics.setFont(fSmall)
    -- Dot indicator
    love.graphics.setColor(color[1], color[2], color[3], 0.8)
    love.graphics.circle("fill", statsX + 4, momY + 10, 4)
    -- Label
    love.graphics.setColor(Config.TEXT_COLOR[1], Config.TEXT_COLOR[2], Config.TEXT_COLOR[3], 0.5)
    love.graphics.print("Mom:", statsX + 14, momY)
    -- Value
    local momParts = {}
    if ship.momentum.y < 0 then table.insert(momParts, "N" .. math.abs(ship.momentum.y)) end
    if ship.momentum.y > 0 then table.insert(momParts, "S" .. math.abs(ship.momentum.y)) end
    if ship.momentum.x > 0 then table.insert(momParts, "E" .. math.abs(ship.momentum.x)) end
    if ship.momentum.x < 0 then table.insert(momParts, "W" .. math.abs(ship.momentum.x)) end
    local momValue = #momParts > 0 and table.concat(momParts, " ") or "0"
    love.graphics.setFont(fMedium)
    love.graphics.setColor(color[1], color[2], color[3], 0.9)
    love.graphics.print(momValue, statsX + 14, momY + 18)

    -- HP and Fuel bars
    local barWidth = math.min(160, w - (statsX - x) - 50)
    self:drawHPBar(statsX, hpY, ship, barWidth)
    self:drawFuelBar(statsX, fuelY, ship, barWidth)
end

function ShipPanel:drawCompassBase(cx, cy, radius, shipColor)
    local fSmall = getFonts()

    -- Outer glow ring (subtle ship color)
    love.graphics.setColor(shipColor[1], shipColor[2], shipColor[3], 0.08)
    love.graphics.circle("fill", cx, cy, radius + 4)

    -- Background circle
    love.graphics.setColor(0.04, 0.04, 0.08)
    love.graphics.circle("fill", cx, cy, radius)

    -- Ship-color outline
    love.graphics.setColor(shipColor[1], shipColor[2], shipColor[3], 0.5)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", cx, cy, radius)
    love.graphics.setLineWidth(1)

    -- Inner concentric ring at 60%
    love.graphics.setColor(0.2, 0.2, 0.25)
    love.graphics.circle("line", cx, cy, radius * 0.6)

    -- Tick marks and labels
    local font = fSmall
    for _, dir in ipairs(Config.FACING_LIST) do
        local angle = FACING_ANGLES[dir] or 0
        local isCardinal = (dir == "N" or dir == "E" or dir == "S" or dir == "W")
        local innerR = isCardinal and (radius - 14) or (radius - 9)
        local outerR = radius - 2

        local ix = cx + math.cos(angle) * innerR
        local iy = cy + math.sin(angle) * innerR
        local ox = cx + math.cos(angle) * outerR
        local oy = cy + math.sin(angle) * outerR

        if isCardinal then
            love.graphics.setColor(0.6, 0.6, 0.6)
        else
            love.graphics.setColor(0.35, 0.35, 0.4)
        end
        love.graphics.line(ix, iy, ox, oy)

        -- Intercardinal dots
        if not isCardinal then
            love.graphics.setColor(0.3, 0.3, 0.35)
            love.graphics.circle("fill", ox, oy, 2)
        end

        if isCardinal then
            local labelR = radius + 12
            local lx = cx + math.cos(angle) * labelR
            local ly = cy + math.sin(angle) * labelR
            love.graphics.setColor(0.7, 0.7, 0.7)
            local fw = font:getWidth(dir)
            local fh = font:getHeight()
            love.graphics.print(dir, lx - fw / 2, ly - fh / 2)
        end
    end
end

function ShipPanel:drawArrow(cx, cy, angle, length, halfWidth, color, alpha)
    alpha = alpha or 1
    love.graphics.setColor(color[1], color[2], color[3], alpha)
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
    self:drawCompassBase(cx, cy, radius, ship.color)

    local mx = ship.momentum.x
    local my = ship.momentum.y

    if mx == 0 and my == 0 then
        -- Center dot for zero momentum
        love.graphics.setColor(ship.color[1], ship.color[2], ship.color[3], 0.6)
        love.graphics.circle("fill", cx, cy, 5)
    else
        local magnitude = math.sqrt(mx * mx + my * my)
        local angle = math.atan2(my, mx)
        local maxLen = radius * 0.75
        local len = math.min(magnitude, 3) / 3 * maxLen

        -- Arrow glow (wide, semi-transparent behind main arrow)
        self:drawArrow(cx, cy, angle, len * 0.9, radius * 0.25, ship.color, 0.15)
        -- Main arrow
        self:drawArrow(cx, cy, angle, len, radius * 0.12, ship.color, 0.95)
        -- Bright tip dot
        local tipX = cx + math.cos(angle) * len
        local tipY = cy + math.sin(angle) * len
        love.graphics.setColor(1, 1, 1, 0.6)
        love.graphics.circle("fill", tipX, tipY, 3)
    end

    -- Center dot
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.circle("fill", cx, cy, 4)
end

function ShipPanel:drawHPBar(x, y, ship, maxWidth)
    local fSmall, fMedium = getFonts()
    local maxHP = Config.SHIP_HP
    local segW = 26
    local segH = 20
    local gap = 4
    local r, g, b = ship.color[1], ship.color[2], ship.color[3]

    -- Label
    love.graphics.setFont(fSmall)
    love.graphics.setColor(Config.TEXT_COLOR[1], Config.TEXT_COLOR[2], Config.TEXT_COLOR[3], 0.5)
    love.graphics.print("HP", x, y + 1)

    local barX = x + 36
    for i = 1, maxHP do
        local sx = barX + (i - 1) * (segW + gap)
        if sx + segW > x + maxWidth then break end
        if i <= ship.hp then
            -- Filled: gradient effect (brighter top half)
            love.graphics.setColor(r, g, b, 0.9)
            roundedRect("fill", sx, y, segW, segH, 3)
            -- Bright highlight on top half
            love.graphics.setColor(
                math.min(1, r + 0.3),
                math.min(1, g + 0.3),
                math.min(1, b + 0.3),
                0.35
            )
            love.graphics.rectangle("fill", sx + 1, y + 1, segW - 2, segH / 2 - 1)
            -- Low HP pulse
            if ship.hp <= 2 then
                local pulse = (math.sin(love.timer.getTime() * 4) + 1) / 2
                love.graphics.setColor(1, 0.2, 0.2, pulse * 0.3)
                roundedRect("fill", sx, y, segW, segH, 3)
            end
        else
            -- Empty: dim outline with inner shadow hint
            love.graphics.setColor(0.18, 0.18, 0.18)
            roundedRect("line", sx, y, segW, segH, 3)
            -- Top-left inner shadow
            love.graphics.setColor(0.12, 0.12, 0.12, 0.5)
            love.graphics.line(sx + 2, y + 2, sx + segW - 2, y + 2)
            love.graphics.line(sx + 2, y + 2, sx + 2, y + segH - 2)
        end
    end

    -- Numeric value
    love.graphics.setFont(fMedium)
    love.graphics.setColor(r, g, b, 0.9)
    local numX = barX + maxHP * (segW + gap) + 8
    love.graphics.print(ship.hp, numX, y - 2)
    love.graphics.setFont(fSmall)
    love.graphics.setColor(Config.TEXT_COLOR[1], Config.TEXT_COLOR[2], Config.TEXT_COLOR[3], 0.5)
    love.graphics.print("/" .. maxHP, numX + fMedium:getWidth(tostring(ship.hp)) + 2, y + 3)
end

function ShipPanel:drawFuelBar(x, y, ship, maxWidth)
    local fSmall, fMedium = getFonts()
    local maxFuel = Config.SHIP_FUEL
    local barWidth = math.min(130, maxWidth - 50)
    local barH = 18
    local ratio = ship.fuel / maxFuel

    -- Label
    love.graphics.setFont(fSmall)
    love.graphics.setColor(Config.TEXT_COLOR[1], Config.TEXT_COLOR[2], Config.TEXT_COLOR[3], 0.5)
    love.graphics.print("Fuel", x, y + 1)

    local barX = x + 44

    -- Background
    love.graphics.setColor(0.1, 0.1, 0.12)
    roundedRect("fill", barX, y, barWidth, barH, 4)

    -- Fill with color transition
    local fillW = ratio * barWidth
    if fillW > 0 then
        local fr, fg, fb
        if ratio > 0.5 then
            -- Green zone
            fr = 0.2 + (1 - ratio) * 1.4
            fg = 0.85
            fb = 0.3
        elseif ratio > 0.25 then
            -- Yellow zone
            fr = 0.85
            fg = 0.3 + ratio * 2.0
            fb = 0.15
        else
            -- Red zone
            fr = 0.85
            fg = ratio * 1.2
            fb = 0.15
        end
        love.graphics.setColor(fr, fg, fb, 0.9)
        roundedRect("fill", barX, y, fillW, barH, 4)
        -- Highlight on top
        love.graphics.setColor(math.min(1, fr + 0.2), math.min(1, fg + 0.2), math.min(1, fb + 0.2), 0.3)
        love.graphics.rectangle("fill", barX + 1, y + 1, fillW - 2, barH / 2 - 1)
    end

    -- Segment marks (every 5 units)
    love.graphics.setColor(0.0, 0.0, 0.0, 0.3)
    for mark = 5, maxFuel - 1, 5 do
        local mx = barX + (mark / maxFuel) * barWidth
        love.graphics.line(mx, y + 2, mx, y + barH - 2)
    end

    -- Outline
    love.graphics.setColor(0.25, 0.25, 0.3, 0.5)
    roundedRect("line", barX, y, barWidth, barH, 4)

    -- Numeric value
    love.graphics.setFont(fMedium)
    local nr, ng, nb
    if ratio > 0.5 then
        nr, ng, nb = 0.3, 0.9, 0.4
    elseif ratio > 0.25 then
        nr, ng, nb = 0.9, 0.8, 0.2
    else
        nr, ng, nb = 0.9, 0.3, 0.3
    end
    love.graphics.setColor(nr, ng, nb, 0.9)
    local numX = barX + barWidth + 8
    love.graphics.print(ship.fuel, numX, y - 2)
    love.graphics.setFont(fSmall)
    love.graphics.setColor(Config.TEXT_COLOR[1], Config.TEXT_COLOR[2], Config.TEXT_COLOR[3], 0.5)
    love.graphics.print("/" .. maxFuel, numX + fMedium:getWidth(tostring(ship.fuel)) + 2, y + 3)
end

return ShipPanel
