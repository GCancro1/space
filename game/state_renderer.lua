local Board = require("ai.lib.board")
local Config = require("config")

local StateRenderer = {}
StateRenderer.__index = StateRenderer

local PLAYER_COLORS = {
    {0.2, 0.6, 1.0},   -- blue
    {1.0, 0.3, 0.3},   -- red
    {0.3, 1.0, 0.4},   -- green
    {1.0, 0.4, 0.7},   -- pink
}

-- Map a compass facing to FACING_LIST index (1 = N, clockwise in y-down
-- screen coords, matching Config.DIRECTIONS).
local function facingIndex(facing)
    for i, f in ipairs(Config.FACING_LIST) do
        if f == facing then
            return i
        end
    end
    return nil
end

-- Pick the first variant that fits within maxW; falls back to the shortest.
local function fitText(font, maxW, ...)
    local variants = { ... }
    for _, v in ipairs(variants) do
        if font:getWidth(v) <= maxW then
            return v
        end
    end
    return variants[#variants]
end

function StateRenderer:new()
    local self = setmetatable({
        board = nil, -- created lazily on first draw
        selectedShipId = nil,
    }, StateRenderer)
    return self
end

-- Select a ship by id (nil deselects)
function StateRenderer:selectShip(id)
    self.selectedShipId = id
end

-- Return the ship table matching the current selection, or nil
function StateRenderer:getSelected(state)
    if self.selectedShipId == nil then
        return nil
    end
    for _, ship in ipairs(state.ships or {}) do
        if ship.id == self.selectedShipId then
            return ship
        end
    end
    return nil
end

-- Create (or refresh on resize) the board object
function StateRenderer:_initObjects()
    if not self.board or self.board.tileSize ~= Config.TILE_SIZE then
        self.board = Board:new(Config)
    end
end

-- Main draw function - reads state and renders everything
-- @param state table|nil - current game state
function StateRenderer:draw(state)
    love.graphics.clear(0.03, 0.03, 0.08)

    if state == nil then
        local w, h = love.graphics.getDimensions()
        local fh = love.graphics.getFont():getHeight()
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("NO STATE LOADED", 0, h * 0.4, w, "center")
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.printf("run: love . states/new_game.json", 0, h * 0.4 + fh + 8, w, "center")
        return
    end

    self:_initObjects()

    local ts = Config.TILE_SIZE
    local ox = Config.GRID_OFFSET_X
    local oy = Config.GRID_OFFSET_Y

    self.board:draw()

    -- Asteroids
    for _, ast in ipairs(state.asteroids or {}) do
        local ax = ox + ast.x * ts
        local ay = oy + ast.y * ts
        local aw = ast.w * ts
        local ah = ast.h * ts
        love.graphics.setColor(0.55, 0.42, 0.3)
        love.graphics.rectangle("fill", ax, ay, aw, ah)
        love.graphics.setColor(0.32, 0.24, 0.17)
        love.graphics.rectangle("line", ax + 0.5, ay + 0.5, aw - 1, ah - 1)
    end

    -- Ships
    for _, ship in ipairs(state.ships or {}) do
        self:_drawShip(ship, ts)
    end

    -- Sidebar + info bar drawn AFTER grid so they cover any leftover margin
    self:_drawSidebar(state)
    self:_drawInfoBar(state)

    -- HUD
    self:_drawHud(state)
end

function StateRenderer:_drawShip(ship, ts)
    local cx, cy = self.board:gridToScreen(ship.x, ship.y)
    local r = ts * 0.35
    local color = PLAYER_COLORS[((ship.id - 1) % 4) + 1]

    -- Body
    love.graphics.setColor(color)
    love.graphics.circle("fill", cx, cy, r)
    love.graphics.setColor(color[1] * 0.5, color[2] * 0.5, color[3] * 0.5)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", cx, cy, r + 2)
    love.graphics.setLineWidth(1)

    -- Facing triangle drawn apex-up; rotate by index*45° (positive = clockwise
    -- on screen, so N(1)→0°, NE(2)→45°, E(3)→90°, ...)
    local idx = facingIndex(ship.facing)
    if idx then
        love.graphics.push()
        love.graphics.translate(cx, cy)
        love.graphics.rotate((idx - 1) * math.pi / 4)
        love.graphics.setColor(0.95, 0.95, 0.95)
        love.graphics.polygon("fill", -r * 0.65, 0, r * 0.65, 0, 0, -r * 1.5)
        love.graphics.pop()
    end

    -- Momentum arrow (game coords y-down matches screen, no flip). Drawn
    -- before the turret barrel and semi-transparent so it reads as a vector
    -- trail, not part of the ship.
    if ship.momentum and (ship.momentum.x ~= 0 or ship.momentum.y ~= 0) then
        love.graphics.setColor(0.3, 1.0, 1.0, 0.7)
        love.graphics.setLineWidth(2)
        love.graphics.line(cx, cy, cx + ship.momentum.x * ts * 0.5, cy + ship.momentum.y * ts * 0.5)
        love.graphics.setLineWidth(1)
    end

    -- Turret barrel: thick gold line from center toward turretFacing with a
    -- filled tip. Drawn LAST so it's never hidden behind the momentum arrow.
    local td = Config.DIRECTIONS[ship.turretFacing or ship.facing]
    if td then
        local tl = ts * 0.45
        local tw = math.max(3, ts * 0.09)
        love.graphics.setColor(Config.TURRET_COLOR)
        love.graphics.setLineWidth(tw)
        love.graphics.line(cx, cy, cx + td.x * tl, cy + td.y * tl)
        love.graphics.setLineWidth(1)
        love.graphics.circle("fill", cx + td.x * tl, cy + td.y * tl, tw)
    end

    -- Id label
    local font = love.graphics.getFont()
    local label = tostring(ship.id)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(label, cx - font:getWidth(label) / 2, cy - font:getHeight() / 2)

    -- Info text (stacked with font height spacing)
    local ty = cy + ts * 0.7
    love.graphics.setColor(0.85, 0.85, 0.85)
    love.graphics.print(("HP %d  FUEL %d"):format(ship.hp, ship.fuel), cx - ts * 0.5, ty)
    if ship.momentum and (ship.momentum.x ~= 0 or ship.momentum.y ~= 0) then
        love.graphics.print(("M(%d,%d)"):format(ship.momentum.x, ship.momentum.y), cx - ts * 0.5, ty + font:getHeight() + 4)
    end

    -- Movement marker (during MOVE phase)
    if ship.movement then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(("-> %s x%d"):format(ship.movement.direction, ship.movement.stepsRemaining), cx + ts * 0.4, cy - ts * 0.9)
    end
end

function StateRenderer:_drawSidebar(state)
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    local sw = Config.SIDEBAR_WIDTH
    local sx = w - sw
    local sy = 0
    local sh = h - Config.INFO_BAR_HEIGHT
    local font = love.graphics.getFont()
    local fh = font:getHeight()

    -- Panel background + border
    love.graphics.setColor(Config.SIDEBAR_BG)
    love.graphics.rectangle("fill", sx, sy, sw, sh)
    love.graphics.setColor(Config.SIDEBAR_BORDER)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", sx + 1, sy + 1, sw - 2, sh - 2)
    love.graphics.setLineWidth(1)

    -- Header section (scaled to the 3x font). The old right-aligned hint
    -- "click a ship to select" no longer fits beside "SHIPS" at this size,
    -- so it's dropped.
    local headerH = fh + 24
    love.graphics.setColor(Config.SIDEBAR_SECTION_BG)
    love.graphics.rectangle("fill", sx, sy, sw, headerH)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("SHIPS", sx + 12, sy + 12)

    -- Ship cards, sized from font height so nothing overlaps at 3x
    local cardH = fh * 4 + 16 -- swatch row + 3 text lines
    local pad = 8
    local x0 = sx + 12
    local y = sy + headerH + 12
    local cw = sw - 20 - pad * 2 -- usable text width inside a card
    for _, ship in ipairs(state.ships or {}) do
        local selected = self.selectedShipId == ship.id
        if selected then
            love.graphics.setColor(Config.CARD_SELECTED_BG)
        else
            love.graphics.setColor(Config.SIDEBAR_SECTION_BG)
        end
        love.graphics.rectangle("fill", x0, y, sw - 20, cardH)
        if selected then
            love.graphics.setColor(Config.CARD_SELECTED_BORDER)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", x0, y, sw - 20, cardH)
            love.graphics.setLineWidth(1)
        end

        -- Color swatch + heading
        local color = PLAYER_COLORS[((ship.id - 1) % 4) + 1]
        love.graphics.setColor(color)
        love.graphics.rectangle("fill", x0 + pad, y + pad, 30, 30)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(("SHIP %d"):format(ship.id), x0 + pad + 40, y + pad)

        -- HP/FUEL + FACING/MOM lines (abbreviated when the card is narrow)
        local mom = ship.momentum or { x = 0, y = 0 }
        local fac = ship.facing or "?"
        local hpF = ("HP %d/%d"):format(ship.hp, Config.SHIP_HP)
        local fuelF = ("FUEL %d/%d"):format(ship.fuel, Config.SHIP_FUEL)
        local line1 = fitText(font, cw, ("%s  %s"):format(hpF, fuelF), ("%s %s"):format(hpF, fuelF))
        local line2 = fitText(font, cw,
            ("FACING %s  MOM (%d,%d)"):format(fac, mom.x, mom.y),
            ("FAC %s  MOM (%d,%d)"):format(fac, mom.x, mom.y),
            ("FAC %s MOM %d,%d"):format(fac, mom.x, mom.y))
        love.graphics.setColor(0.85, 0.85, 0.85)
        love.graphics.print(line1, x0 + pad, y + pad + fh)
        love.graphics.print(line2, x0 + pad, y + pad + 2 * fh)
        if ship.movement then
            love.graphics.print(("-> %s x%d"):format(ship.movement.direction, ship.movement.stepsRemaining), x0 + pad, y + pad + 3 * fh)
        end
        y = y + cardH + 8
    end
end

function StateRenderer:_drawInfoBar(state)
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    local bh = Config.INFO_BAR_HEIGHT
    local by = h - bh
    local font = love.graphics.getFont()
    local fh = font:getHeight()

    -- Bar background + top border
    love.graphics.setColor(Config.INFO_BAR_BG)
    love.graphics.rectangle("fill", 0, by, w, bh)
    love.graphics.setColor(Config.INFO_BAR_BORDER)
    love.graphics.setLineWidth(2)
    love.graphics.line(0, by + 1, w, by + 1)
    love.graphics.setLineWidth(1)

    -- Top row: turn/phase/player box (top-left)
    local meta = state.meta or {}
    local metaText = ("TURN %d | PHASE %s | PLAYER %d"):format(meta.turn or 0, meta.phase or "?", meta.currentPlayer or 0)
    local metaW = font:getWidth(metaText) + 24
    local metaH = fh + 28
    love.graphics.setColor(Config.SIDEBAR_SECTION_BG)
    love.graphics.rectangle("fill", 10, by + 10, metaW, metaH)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(metaText, 10 + 12, by + 10 + 12)

    -- Top row: controls legend (right-aligned, stacked with font spacing)
    local lines = {
        "SPACE phase+save",
        "T tick",
        "L reload",
        "S save",
        "CLICK select",
        "ESC quit",
    }
    local legendMaxW = 0
    for _, line in ipairs(lines) do
        legendMaxW = math.max(legendMaxW, font:getWidth(line))
    end
    local ry = by + 10 + 12
    for _, line in ipairs(lines) do
        love.graphics.setColor(0.8, 0.8, 0.85)
        love.graphics.print(line, w - 30 - font:getWidth(line), ry)
        ry = ry + fh + 8
    end

    -- Ship panels: ALL ships shown at once, laid out horizontally between
    -- the meta box and the legend. Selected ship gets the highlight border.
    local ships = state.ships or {}
    if #ships > 0 then
        local panelX0 = 10 + metaW + 24
        local panelX1 = w - 30 - legendMaxW - 24
        local n = #ships
        local gap = 12
        local panelW = math.max(80, math.floor((panelX1 - panelX0 - (n - 1) * gap) / n))
        local panelH = fh * 6 + 20 -- heading + 3 lines + 2 bar rows, all at fh
        local pad = 8
        local panelY = by + 10 + metaH + 14
        local cw = panelW - pad * 2
        local barH = math.min(18, math.max(14, math.floor(fh * 0.45)))

        local px = panelX0
        for _, ship in ipairs(ships) do
            local selected = self.selectedShipId == ship.id
            if selected then
                love.graphics.setColor(Config.CARD_SELECTED_BG)
            else
                love.graphics.setColor(Config.SIDEBAR_SECTION_BG)
            end
            love.graphics.rectangle("fill", px, panelY, panelW, panelH)
            if selected then
                love.graphics.setColor(Config.CARD_SELECTED_BORDER)
                love.graphics.setLineWidth(2)
                love.graphics.rectangle("line", px + 1, panelY + 1, panelW - 2, panelH - 2)
                love.graphics.setLineWidth(1)
            end

            -- Heading: color swatch + SHIP N
            local color = PLAYER_COLORS[((ship.id - 1) % 4) + 1]
            love.graphics.setColor(color)
            love.graphics.rectangle("fill", px + pad, panelY + pad, 28, 28)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(("SHIP %d"):format(ship.id), px + pad + 36, panelY + pad)

            -- POS / FAC+TUR / MOM lines (abbreviated when the panel is narrow)
            local pos = fitText(font, cw,
                ("POS (%d,%d)"):format(ship.x, ship.y),
                ("(%d,%d)"):format(ship.x, ship.y),
                ("%d,%d"):format(ship.x, ship.y))
            local fac = ship.facing or "?"
            local tur = ship.turretFacing or "?"
            local facLine = fitText(font, cw,
                ("FAC %s  TUR %s"):format(fac, tur),
                ("F %s T %s"):format(fac, tur),
                ("%s/%s"):format(fac, tur))
            local mom = ship.momentum or { x = 0, y = 0 }
            local momLine = fitText(font, cw,
                ("MOM (%d,%d)"):format(mom.x, mom.y),
                ("M(%d,%d)"):format(mom.x, mom.y),
                ("M %d,%d"):format(mom.x, mom.y))
            love.graphics.setColor(0.85, 0.85, 0.85)
            love.graphics.print(pos, px + pad, panelY + pad + fh)
            love.graphics.print(facLine, px + pad, panelY + pad + 2 * fh)
            love.graphics.print(momLine, px + pad, panelY + pad + 3 * fh)

            -- HP bar and FUEL bar: label inline left, bar right
            local lines2 = {
                { ("HP %d/%d"):format(ship.hp, Config.SHIP_HP), ship.hp, Config.SHIP_HP, ship.hp <= 2 and {0.9, 0.2, 0.2} or {0.3, 0.9, 0.3} },
                { ("FUEL %d/%d"):format(ship.fuel, Config.SHIP_FUEL), ship.fuel, Config.SHIP_FUEL, {0.3, 0.6, 1.0} },
            }
            for i, barDef in ipairs(lines2) do
                local label, val, max, barColor = barDef[1], barDef[2], barDef[3], barDef[4]
                local rowY = panelY + pad + (3 + i) * fh
                love.graphics.setColor(1, 1, 1)
                love.graphics.print(label, px + pad, rowY)
                local labelW = font:getWidth(label)
                local barX = px + pad + labelW + 8
                local barW = cw - labelW - 8
                local barY = rowY + (fh - barH) / 2
                love.graphics.setColor(0.15, 0.15, 0.2)
                love.graphics.rectangle("fill", barX, barY, barW, barH)
                if val > 0 then
                    love.graphics.setColor(barColor)
                    love.graphics.rectangle("fill", barX, barY, barW * (val / max), barH)
                end
            end

            px = px + panelW + gap
        end
    end
end

function StateRenderer:_drawHud(state)
    local meta = state.meta or {}
    local font = love.graphics.getFont()
    local fh = font:getHeight()
    local line1 = ("TURN %d  |  PHASE %s  |  PLAYER %d"):format(meta.turn or 0, meta.phase or "?", meta.currentPlayer or 0)
    local w = font:getWidth(line1) + 18
    local boxH = fh + 18

    love.graphics.setColor(0.05, 0.05, 0.1, 0.75)
    love.graphics.rectangle("fill", 8, 8, w, boxH)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(line1, 17, 8 + (boxH - fh) / 2)
end

-- Update animations and effects
-- @param dt number - delta time
function StateRenderer:update(dt)
    -- animations/TODO (other workers)
end

-- Queue visual effects from logic events
-- @param events table - array of event objects from GameState.advanceTick/advancePhase
function StateRenderer:setEvents(events)
    -- effects/animations from logic events (other workers)
end

return StateRenderer