local Config = require("config")

local Sidebar = {}

-- Player colors (must match main.lua)
local PLAYER_COLORS = {
    {0.2, 0.6, 1.0},
    {1.0, 0.3, 0.3},
    {0.3, 1.0, 0.4},
    {1.0, 0.4, 0.7},
}

-- Fonts (cached)
local fonts = {}
local function getFonts()
    if not fonts.title then
        fonts.title = love.graphics.newFont(24)
        fonts.value = love.graphics.newFont(18)
        fonts.label = love.graphics.newFont(14)
        fonts.small = love.graphics.newFont(12)
        fonts.cardTitle = love.graphics.newFont(20)
        fonts.cardValue = love.graphics.newFont(16)
        fonts.cardLabel = love.graphics.newFont(13)
    end
    return fonts
end

-- Card type definitions
local CARD_TYPES = {
    {id = "thrust",   name = "Thrust",       bgKey = "CARD_THRUST_BG",   hoverKey = "CARD_THRUST_HOVER"},
    {id = "rotate",   name = "Body Rotate",   bgKey = "CARD_ROTATE_BG",   hoverKey = "CARD_ROTATE_HOVER"},
    {id = "turret",   name = "Turret Rotate",  bgKey = "CARD_TURRET_BG",   hoverKey = "CARD_TURRET_HOVER"},
    {id = "shoot",    name = "Shoot",          bgKey = "CARD_SHOOT_BG",    hoverKey = "CARD_SHOOT_HOVER"},
    {id = "special",  name = "Special",        bgKey = "CARD_SPECIAL_BG",  hoverKey = "CARD_SPECIAL_HOVER"},
}

-- Helper: draw rounded rect
local function roundedRect(mode, x, y, w, h, r)
    love.graphics.rectangle(mode, x, y, w, h, r, r)
end

-- Helper: lighten color
local function lighten(c, amount)
    return {
        math.min(1, c[1] + amount),
        math.min(1, c[2] + amount),
        math.min(1, c[3] + amount),
    }
end

function Sidebar:new()
    local instance = setmetatable({}, {__index = self})
    instance.suit = require("ai.vendor.suit").new()
    instance.activeCard = nil
    instance.activePlayer = 1
    instance.turnNumber = 1
    instance.selectedShip = 1

    -- Action state
    instance.thrust = {direction = "F", power = 1}
    instance.bodyRotation = {direction = "CW"}
    instance.turretRotation = {direction = "CW"}
    instance.shootPower = 1
    instance.specialAction = false

    -- Slider references
    instance.powerSlider = {value = 1}
    instance.shootSlider = {value = 1}

    -- Hover state for custom draw
    instance.cardHovered = {}

    -- Animation pulse
    instance.pulse = 0

    return instance
end

function Sidebar:update(dt, ships, activePlayer, turnNumber)
    self.activePlayer = activePlayer or 1
    self.turnNumber = turnNumber or 1
    self.ships = ships or {}
    self.pulse = self.pulse + dt

    local suit = self.suit
    local w = Config.SIDEBAR_WIDTH
    local h = Config.SCREEN_HEIGHT
    local pad = 16

    suit:enterFrame()
    suit.layout:reset(Config.SCREEN_WIDTH - w, 0)
    suit.layout:padding(pad, 0)

    -- Turn header space
    suit.layout:row(w - pad * 2, 60)

    -- Ship info space (4 players × ~52px each + title + padding)
    suit.layout:row(w - pad * 2, 230)

    -- ===== ACTION CARDS =====
    local cardH = 72
    local cardW = w - pad * 2

    -- Card 1: Thrust
    local cx, cy, cw, ch = suit.layout:row(cardW, cardH)
    local thrustState = suit:Button("", cx, cy, cw, ch, {
        id = "card_thrust",
        draw = function(text, opt, x, y, w, h)
            self:drawCard("thrust", x, y, w, h, opt)
        end
    })
    if thrustState.hit then
        self.activeCard = self.activeCard == "thrust" and nil or "thrust"
    end
    self.cardHovered["thrust"] = thrustState.hovered

    if self.activeCard == "thrust" then
        local ctrlH = 90
        local cx2, cy2, cw2, ch2 = suit.layout:row(cardW, ctrlH)
        self:drawThrustControls(suit, cx2, cy2, cw2, ch2)
    end

    -- Card 2: Body Rotation
    cx, cy, cw, ch = suit.layout:row(cardW, cardH)
    local rotateState = suit:Button("", cx, cy, cw, ch, {
        id = "card_rotate",
        draw = function(text, opt, x, y, w, h)
            self:drawCard("rotate", x, y, w, h, opt)
        end
    })
    if rotateState.hit then
        self.activeCard = self.activeCard == "rotate" and nil or "rotate"
    end
    self.cardHovered["rotate"] = rotateState.hovered

    if self.activeCard == "rotate" then
        local ctrlH = 70
        local cx2, cy2, cw2, ch2 = suit.layout:row(cardW, ctrlH)
        self:drawRotateControls(suit, cx2, cy2, cw2, ch2)
    end

    -- Card 3: Turret Rotation
    cx, cy, cw, ch = suit.layout:row(cardW, cardH)
    local turretState = suit:Button("", cx, cy, cw, ch, {
        id = "card_turret",
        draw = function(text, opt, x, y, w, h)
            self:drawCard("turret", x, y, w, h, opt)
        end
    })
    if turretState.hit then
        self.activeCard = self.activeCard == "turret" and nil or "turret"
    end
    self.cardHovered["turret"] = turretState.hovered

    if self.activeCard == "turret" then
        local ctrlH = 70
        local cx2, cy2, cw2, ch2 = suit.layout:row(cardW, ctrlH)
        self:drawTurretControls(suit, cx2, cy2, cw2, ch2)
    end

    -- Card 4: Shoot
    cx, cy, cw, ch = suit.layout:row(cardW, cardH)
    local shootState = suit:Button("", cx, cy, cw, ch, {
        id = "card_shoot",
        draw = function(text, opt, x, y, w, h)
            self:drawCard("shoot", x, y, w, h, opt)
        end
    })
    if shootState.hit then
        self.activeCard = self.activeCard == "shoot" and nil or "shoot"
    end
    self.cardHovered["shoot"] = shootState.hovered

    if self.activeCard == "shoot" then
        local ctrlH = 60
        local cx2, cy2, cw2, ch2 = suit.layout:row(cardW, ctrlH)
        self:drawShootControls(suit, cx2, cy2, cw2, ch2)
    end

    -- Card 5: Special
    cx, cy, cw, ch = suit.layout:row(cardW, cardH)
    local specialState = suit:Button("", cx, cy, cw, ch, {
        id = "card_special",
        draw = function(text, opt, x, y, w, h)
            self:drawCard("special", x, y, w, h, opt)
        end
    })
    if specialState.hit then
        self.activeCard = self.activeCard == "special" and nil or "special"
    end
    self.cardHovered["special"] = specialState.hovered

    if self.activeCard == "special" then
        local ctrlH = 50
        local cx2, cy2, cw2, ch2 = suit.layout:row(cardW, ctrlH)
        self:drawSpecialControls(suit, cx2, cy2, cw2, ch2)
    end

    -- ===== END TURN BUTTON =====
    local btnH = 44
    local bx, by, bw, bh = suit.layout:row(cardW, btnH)
    local endTurnState = suit:Button("END TURN", bx, by, bw, bh, {
        id = "end_turn",
        font = getFonts().value,
        color = {
            normal = {bg = Config.SIDEBAR_BTN_BG, fg = {0.8, 0.8, 0.8}},
            hovered = {bg = Config.SIDEBAR_BTN_HOVER, fg = {1, 1, 1}},
            active = {bg = Config.SIDEBAR_BTN_ACTIVE, fg = {1, 1, 1}},
        },
        cornerRadius = 6,
    })

    -- Sync sliders with state
    self.thrust.power = math.floor(self.powerSlider.value + 0.5)
    self.shootPower = math.floor(self.shootSlider.value + 0.5)
end

-- Draw the main sidebar background
function Sidebar:draw()
    local w = Config.SIDEBAR_WIDTH
    local h = Config.SCREEN_HEIGHT
    local x = Config.SCREEN_WIDTH - w

    local oldFont = love.graphics.getFont()

    -- Sidebar background
    love.graphics.setColor(Config.SIDEBAR_BG)
    love.graphics.rectangle("fill", x, 0, w, h)

    -- Left border line (separator from board)
    love.graphics.setColor(Config.SIDEBAR_BORDER)
    love.graphics.setLineWidth(2)
    love.graphics.line(x, 0, x, h)
    love.graphics.setLineWidth(1)

    -- Glow on border
    for i = 1, 4 do
        local alpha = 0.08 / i
        love.graphics.setColor(0.3, 0.5, 1.0, alpha)
        love.graphics.rectangle("fill", x - i, 0, 1, h)
    end

    -- Draw section backgrounds and content
    self:drawTurnHeader()
    self:drawShipInfoSection()

    -- Draw SUIT widgets on top (cards + end turn button)
    self.suit:draw()

    love.graphics.setFont(oldFont)
end

-- Turn header (top section)
function Sidebar:drawTurnHeader()
    local f = getFonts()
    local x = Config.SCREEN_WIDTH - Config.SIDEBAR_WIDTH
    local w = Config.SIDEBAR_WIDTH
    local pad = 16
    local y = 0
    local h = 60

    -- Section bg
    love.graphics.setColor(Config.SIDEBAR_SECTION_BG)
    love.graphics.rectangle("fill", x + pad, y + 6, w - pad * 2, h - 12, 8)

    -- Turn number
    love.graphics.setFont(f.title)
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.print("Turn " .. self.turnNumber, x + pad + 12, y + 10)

    -- Active player indicator
    local playerColor = PLAYER_COLORS[self.activePlayer] or {0.5, 0.5, 0.5}
    love.graphics.setColor(playerColor[1], playerColor[2], playerColor[3], 0.8)
    love.graphics.circle("fill", x + pad + 12, y + 42, 6)
    love.graphics.setFont(f.label)
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print("Player " .. self.activePlayer, x + pad + 24, y + 34)
end

-- Ship info section (all players)
function Sidebar:drawShipInfoSection()
    local f = getFonts()
    local x = Config.SCREEN_WIDTH - Config.SIDEBAR_WIDTH
    local w = Config.SIDEBAR_WIDTH
    local pad = 16
    local sectionPad = 12
    local y = 60
    local h = 230

    -- Section bg
    love.graphics.setColor(Config.SIDEBAR_SECTION_BG)
    love.graphics.rectangle("fill", x + pad, y, w - pad * 2, h, 8)

    -- Section title
    love.graphics.setFont(f.label)
    love.graphics.setColor(0.5, 0.5, 0.6)
    love.graphics.print("PLAYERS", x + pad + sectionPad, y + 6)

    local playerH = 48
    local playerY = y + 24

    for i = 1, 4 do
        local ship = self.ships[i]
        local isActive = (i == self.activePlayer)
        local color = PLAYER_COLORS[i] or {0.5, 0.5, 0.5}

        -- Player row background (subtle highlight for active)
        if isActive then
            love.graphics.setColor(color[1], color[2], color[3], 0.08)
            love.graphics.rectangle("fill", x + pad + 4, playerY, w - pad * 2 - 8, playerH - 4, 6)
        end

        local rowX = x + pad + sectionPad
        local rowY = playerY + 4

        -- Player color dot
        love.graphics.setColor(color[1], color[2], color[3], isActive and 1.0 or 0.5)
        love.graphics.circle("fill", rowX + 6, rowY + 12, 6)

        -- Active indicator ring
        if isActive then
            love.graphics.setColor(color[1], color[2], color[3], 0.4)
                            love.graphics.circle("line", rowX + 6, rowY + 12, 9)
        end

        -- Player number
        love.graphics.setFont(f.cardLabel)
        love.graphics.setColor(isActive and {0.9, 0.9, 0.9} or {0.4, 0.4, 0.4})
        love.graphics.print("P" .. i, rowX + 18, rowY + 1)

        if ship then
            local valColor = isActive and {0.8, 0.8, 0.8} or {0.35, 0.35, 0.35}

            -- HP
            love.graphics.setFont(f.small)
            love.graphics.setColor(valColor[1], valColor[2], valColor[3])
            love.graphics.print("HP", rowX + 48, rowY + 1)
            love.graphics.setColor(color[1], color[2], color[3], isActive and 0.9 or 0.4)
            love.graphics.print(tostring(ship.hp) .. "/" .. Config.SHIP_HP, rowX + 70, rowY + 1)

            -- Fuel
            love.graphics.setColor(valColor[1], valColor[2], valColor[3])
            love.graphics.print("F", rowX + 130, rowY + 1)
            love.graphics.setColor(color[1], color[2], color[3], isActive and 0.9 or 0.4)
            love.graphics.print(tostring(ship.fuel) .. "/" .. Config.SHIP_FUEL, rowX + 144, rowY + 1)

            -- Facing + Momentum on second line
            love.graphics.setColor(valColor[1], valColor[2], valColor[3])
            love.graphics.print(ship.facing, rowX + 48, rowY + 18)

            -- Momentum
            local mx, my = ship.momentum.x, ship.momentum.y
            local momStr = ""
            if my < 0 then momStr = momStr .. "N" .. math.abs(my) end
            if my > 0 then momStr = momStr .. "S" .. math.abs(my) end
            if mx > 0 then momStr = momStr .. "E" .. math.abs(mx) end
            if mx < 0 then momStr = momStr .. "W" .. math.abs(mx) end
            if momStr == "" then momStr = "0" end
            love.graphics.print(momStr, rowX + 100, rowY + 18)

            -- HP bar (small, on the right)
            local barX = rowX + 200
            local barW = 80
            local barH = 8
            local barY = rowY + 5
            local hpFrac = ship.hp / Config.SHIP_HP
            love.graphics.setColor(0.15, 0.15, 0.2)
            love.graphics.rectangle("fill", barX, barY, barW, barH, 3)
            if hpFrac > 0 then
                love.graphics.setColor(color[1], color[2], color[3], isActive and 0.8 or 0.4)
                love.graphics.rectangle("fill", barX, barY, barW * hpFrac, barH, 3)
            end

            -- Fuel bar (small)
            local barY2 = barY + 14
            local fuelFrac = ship.fuel / Config.SHIP_FUEL
            love.graphics.setColor(0.15, 0.15, 0.2)
            love.graphics.rectangle("fill", barX, barY2, barW, barH, 3)
            if fuelFrac > 0 then
                love.graphics.setColor(0.4, 0.7, 0.4, isActive and 0.8 or 0.4)
                love.graphics.rectangle("fill", barX, barY2, barW * fuelFrac, barH, 3)
            end
        else
            love.graphics.setFont(f.cardLabel)
            love.graphics.setColor(0.3, 0.3, 0.3)
            love.graphics.print("No ship", rowX + 48, rowY + 8)
        end

        playerY = playerY + playerH
    end

    -- Player color bar at bottom of section
    local activeColor = PLAYER_COLORS[self.activePlayer] or {0.5, 0.5, 0.5}
    love.graphics.setColor(activeColor[1], activeColor[2], activeColor[3], 0.3)
    love.graphics.rectangle("fill", x + pad, y + h - 3, w - pad * 2, 3, 2)
end

-- Draw a single action card
function Sidebar:drawCard(cardType, x, y, w, h, opt)
    local f = getFonts()
    local isSelected = self.activeCard == cardType
    local isHovered = self.cardHovered[cardType]

    -- Find card type definition
    local cardDef = nil
    for _, ct in ipairs(CARD_TYPES) do
        if ct.id == cardType then
            cardDef = ct
            break
        end
    end
    if not cardDef then return end

    -- Get colors
    local bgColor, hoverColor
    if cardDef.bgKey then bgColor = Config[cardDef.bgKey] end
    if cardDef.hoverKey then hoverColor = Config[cardDef.hoverKey] end

    -- Determine fill color
    local fillC
    if isSelected then
        fillC = Config.CARD_SELECTED_BG
    elseif isHovered then
        fillC = hoverColor or lighten(bgColor or {0.2, 0.2, 0.2}, 0.08)
    else
        fillC = bgColor or {0.2, 0.2, 0.2}
    end

    -- Background
    love.graphics.setColor(fillC)
    roundedRect("fill", x, y, w, h, Config.SIDEBAR_CARD_RADIUS)

    -- Border
    local borderC
    if isSelected then
        borderC = Config.CARD_SELECTED_BORDER
        -- Glow effect
        love.graphics.setColor(borderC[1], borderC[2], borderC[3], 0.15)
        roundedRect("line", x - 1, y - 1, w + 2, h + 2, Config.SIDEBAR_CARD_RADIUS + 1)
    else
        borderC = lighten(fillC, 0.15)
    end
    love.graphics.setColor(borderC[1], borderC[2], borderC[3], isSelected and 0.9 or 0.3)
    love.graphics.setLineWidth(isSelected and 2 or 1)
    roundedRect("line", x, y, w, h, Config.SIDEBAR_CARD_RADIUS)
    love.graphics.setLineWidth(1)

    -- Icon dot
    local dotR = 6
    local dotX = x + 16
    local dotY = y + h / 2
    local iconColor = isSelected and {1, 1, 1} or {0.5, 0.5, 0.6}
    if isHovered then iconColor = {0.8, 0.8, 0.8} end
    love.graphics.setColor(iconColor)
    love.graphics.circle("fill", dotX, dotY, dotR)

    -- Card title
    love.graphics.setFont(f.cardTitle)
    love.graphics.setColor(isSelected and {1, 1, 1} or {0.75, 0.75, 0.8})
    love.graphics.print(cardDef.name, x + 32, y + 8)

    -- Card value (current selection)
    local valStr = self:getCardValueString(cardType)
    love.graphics.setFont(f.cardLabel)
    love.graphics.setColor(isSelected and {0.8, 0.9, 1} or {0.5, 0.5, 0.6})
    love.graphics.print(valStr, x + 32, y + h - 26)

    -- Arrow indicator on right side
    local arrowX = x + w - 24
    local arrowY = y + h / 2
    love.graphics.setColor(isSelected and {0.6, 0.7, 0.9} or {0.3, 0.3, 0.4})
    love.graphics.polygon("fill",
        arrowX, arrowY - 5,
        arrowX + 6, arrowY,
        arrowX, arrowY + 5
    )
end

-- Get value string for a card type
function Sidebar:getCardValueString(cardType)
    if cardType == "thrust" then
        return "Direction: " .. self.thrust.direction .. " Power: " .. self.thrust.power
    elseif cardType == "rotate" then
        return "Direction: " .. self.bodyRotation.direction
    elseif cardType == "turret" then
        return "Direction: " .. self.turretRotation.direction
    elseif cardType == "shoot" then
        return "Power: " .. self.shootPower
    elseif cardType == "special" then
        return "Heal 1 HP"
    end
    return ""
end

-- Thrust controls (direction buttons + power slider)
function Sidebar:drawThrustControls(suit, x, y, w, h)
    local f = getFonts()
    local btnW = 60
    local btnH = 32
    local sliderH = 24

    -- Label
    love.graphics.setFont(f.cardLabel)
    love.graphics.setColor(0.5, 0.5, 0.6)
    love.graphics.print("Direction", x, y + 2)

    -- F/B/L/R buttons
    local dirs = {{"F", "F"}, {"B", "B"}, {"L", "L"}, {"R", "R"}}
    local btnX = x
    local btnY = y + 18
    for i, dir in ipairs(dirs) do
        local state = suit:Button(dir[1], btnX + (i-1) * (btnW + 4), btnY, btnW, btnH, {
            id = "thrust_" .. dir[2],
            font = f.cardValue,
            color = {
                normal = {bg = Config.SIDEBAR_BTN_BG, fg = {0.7, 0.7, 0.7}},
                hovered = {bg = Config.SIDEBAR_BTN_HOVER, fg = {1, 1, 1}},
                active = {bg = Config.SIDEBAR_BTN_ACTIVE, fg = {1, 1, 1}},
            },
            cornerRadius = 4,
        })
        if state.hit then
            self.thrust.direction = dir[2]
        end
        if self.thrust.direction == dir[2] then
            love.graphics.setColor(Config.CARD_SELECTED_BORDER[1], Config.CARD_SELECTED_BORDER[2], Config.CARD_SELECTED_BORDER[3], 0.3)
            love.graphics.rectangle("line", btnX + (i-1) * (btnW + 4), btnY, btnW, btnH, 4)
        end
    end

    -- Power slider label
    love.graphics.setFont(f.cardLabel)
    love.graphics.setColor(0.5, 0.5, 0.6)
    love.graphics.print("Power", x, y + 56)
    love.graphics.setFont(f.cardValue)
    love.graphics.setColor(0.8, 0.8, 0.9)
    love.graphics.print(tostring(math.floor(self.powerSlider.value + 0.5)), x + w - 30, y + 54)

    -- Slider
    local sliderX = x + 45
    local sliderW = w - 80
    suit:Slider(self.powerSlider, sliderX, y + 58, sliderW, sliderH, {
        id = "thrust_power",
        color = {
            normal = {bg = {0.2, 0.2, 0.25}, fg = {0.4, 0.6, 0.8}},
            hovered = {bg = {0.25, 0.25, 0.3}, fg = {0.5, 0.7, 0.9}},
            active = {bg = {0.25, 0.25, 0.3}, fg = {0.5, 0.7, 0.9}},
        },
        cornerRadius = 4,
    })
end

-- Body rotation controls (CW/CCW)
function Sidebar:drawRotateControls(suit, x, y, w, h)
    local f = getFonts()
    local btnW = 120
    local btnH = 36

    love.graphics.setFont(f.cardLabel)
    love.graphics.setColor(0.5, 0.5, 0.6)
    love.graphics.print("Direction", x, y + 2)

    local cwState = suit:Button("CW", x, y + 18, btnW, btnH, {
        id = "rotate_cw",
        font = f.cardValue,
        color = {
            normal = {bg = Config.SIDEBAR_BTN_BG, fg = {0.7, 0.7, 0.7}},
            hovered = {bg = Config.SIDEBAR_BTN_HOVER, fg = {1, 1, 1}},
            active = {bg = Config.SIDEBAR_BTN_ACTIVE, fg = {1, 1, 1}},
        },
        cornerRadius = 4,
    })
    if cwState.hit then self.bodyRotation.direction = "CW" end

    local ccwState = suit:Button("CCW", x + btnW + 12, y + 18, btnW, btnH, {
        id = "rotate_ccw",
        font = f.cardValue,
        color = {
            normal = {bg = Config.SIDEBAR_BTN_BG, fg = {0.7, 0.7, 0.7}},
            hovered = {bg = Config.SIDEBAR_BTN_HOVER, fg = {1, 1, 1}},
            active = {bg = Config.SIDEBAR_BTN_ACTIVE, fg = {1, 1, 1}},
        },
        cornerRadius = 4,
    })
    if ccwState.hit then self.bodyRotation.direction = "CCW" end

    -- Highlight active direction
    if self.bodyRotation.direction == "CW" then
        love.graphics.setColor(Config.CARD_SELECTED_BORDER[1], Config.CARD_SELECTED_BORDER[2], Config.CARD_SELECTED_BORDER[3], 0.3)
        love.graphics.rectangle("line", x, y + 18, btnW, btnH, 4)
    else
        love.graphics.setColor(Config.CARD_SELECTED_BORDER[1], Config.CARD_SELECTED_BORDER[2], Config.CARD_SELECTED_BORDER[3], 0.3)
        love.graphics.rectangle("line", x + btnW + 12, y + 18, btnW, btnH, 4)
    end
end

-- Turret rotation controls (CW/CCW)
function Sidebar:drawTurretControls(suit, x, y, w, h)
    local f = getFonts()
    local btnW = 120
    local btnH = 36

    love.graphics.setFont(f.cardLabel)
    love.graphics.setColor(0.5, 0.5, 0.6)
    love.graphics.print("Direction", x, y + 2)

    local cwState = suit:Button("CW", x, y + 18, btnW, btnH, {
        id = "turret_cw",
        font = f.cardValue,
        color = {
            normal = {bg = Config.SIDEBAR_BTN_BG, fg = {0.7, 0.7, 0.7}},
            hovered = {bg = Config.SIDEBAR_BTN_HOVER, fg = {1, 1, 1}},
            active = {bg = Config.SIDEBAR_BTN_ACTIVE, fg = {1, 1, 1}},
        },
        cornerRadius = 4,
    })
    if cwState.hit then self.turretRotation.direction = "CW" end

    local ccwState = suit:Button("CCW", x + btnW + 12, y + 18, btnW, btnH, {
        id = "turret_ccw",
        font = f.cardValue,
        color = {
            normal = {bg = Config.SIDEBAR_BTN_BG, fg = {0.7, 0.7, 0.7}},
            hovered = {bg = Config.SIDEBAR_BTN_HOVER, fg = {1, 1, 1}},
            active = {bg = Config.SIDEBAR_BTN_ACTIVE, fg = {1, 1, 1}},
        },
        cornerRadius = 4,
    })
    if ccwState.hit then self.turretRotation.direction = "CCW" end

    -- Highlight active direction
    if self.turretRotation.direction == "CW" then
        love.graphics.setColor(Config.CARD_SELECTED_BORDER[1], Config.CARD_SELECTED_BORDER[2], Config.CARD_SELECTED_BORDER[3], 0.3)
        love.graphics.rectangle("line", x, y + 18, btnW, btnH, 4)
    else
        love.graphics.setColor(Config.CARD_SELECTED_BORDER[1], Config.CARD_SELECTED_BORDER[2], Config.CARD_SELECTED_BORDER[3], 0.3)
        love.graphics.rectangle("line", x + btnW + 12, y + 18, btnW, btnH, 4)
    end
end

-- Shoot controls (power slider)
function Sidebar:drawShootControls(suit, x, y, w, h)
    local f = getFonts()
    local sliderH = 24

    love.graphics.setFont(f.cardLabel)
    love.graphics.setColor(0.5, 0.5, 0.6)
    love.graphics.print("Power", x, y + 2)

    love.graphics.setFont(f.cardValue)
    love.graphics.setColor(0.8, 0.8, 0.9)
    love.graphics.print(tostring(math.floor(self.shootSlider.value + 0.5)), x + w - 30, y + 0)

    suit:Slider(self.shootSlider, x + 50, y + 4, w - 90, sliderH, {
        id = "shoot_power",
        color = {
            normal = {bg = {0.2, 0.2, 0.25}, fg = {0.8, 0.4, 0.3}},
            hovered = {bg = {0.25, 0.25, 0.3}, fg = {0.9, 0.5, 0.4}},
            active = {bg = {0.25, 0.25, 0.3}, fg = {0.9, 0.5, 0.4}},
        },
        cornerRadius = 4,
    })
end

-- Special controls (heal button)
function Sidebar:drawSpecialControls(suit, x, y, w, h)
    local f = getFonts()
    local btnH = 36

    local healState = suit:Button("Heal 1 HP", x, y + 4, w, btnH, {
        id = "special_heal",
        font = f.cardValue,
        color = {
            normal = {bg = {0.2, 0.3, 0.2}, fg = {0.7, 0.9, 0.7}},
            hovered = {bg = {0.25, 0.35, 0.25}, fg = {1, 1, 1}},
            active = {bg = {0.3, 0.4, 0.3}, fg = {1, 1, 1}},
        },
        cornerRadius = 6,
    })
    if healState.hit then
        self.specialAction = not self.specialAction
    end
end

-- Get selected action
function Sidebar:getSelectedAction()
    if not self.activeCard then return nil end
    if self.activeCard == "thrust" then
        return {type = "thrust", direction = self.thrust.direction, power = self.thrust.power}
    elseif self.activeCard == "rotate" then
        return {type = "rotate", direction = self.bodyRotation.direction}
    elseif self.activeCard == "turret" then
        return {type = "turret", direction = self.turretRotation.direction}
    elseif self.activeCard == "shoot" then
        return {type = "shoot", power = self.shootPower}
    elseif self.activeCard == "special" then
        return {type = "special", action = "heal"}
    end
    return nil
end

-- Reset selection
function Sidebar:resetSelection()
    self.activeCard = nil
    self.thrust = {direction = "F", power = 1}
    self.bodyRotation = {direction = "CW"}
    self.turretRotation = {direction = "CW"}
    self.shootPower = 1
    self.specialAction = false
    self.powerSlider.value = 1
    self.shootSlider.value = 1
end

return Sidebar
