local Class = require("ai.vendor.class")
local Board = Class:extend()

function Board:init(config)
    self.config = config
    self.width = config.GRID_WIDTH
    self.height = config.GRID_HEIGHT
    self.tileSize = config.TILE_SIZE
    self.offsetX = config.GRID_OFFSET_X or 0
    self.offsetY = config.GRID_OFFSET_Y or 0
end

function Board:draw()
    local ts = self.tileSize

    -- Grid background (semi-transparent so space bg shows through)
    love.graphics.setColor(0.02, 0.02, 0.06, 0.55)
    love.graphics.rectangle("fill",
        self.offsetX, self.offsetY,
        self.width * ts, self.height * ts)

    -- Grid lines (brighter, semi-transparent)
    love.graphics.setColor(0.2, 0.25, 0.35, 0.5)
    for x = 0, self.width do
        love.graphics.line(
            self.offsetX + x * ts, self.offsetY,
            self.offsetX + x * ts, self.offsetY + self.height * ts)
    end
    for y = 0, self.height do
        love.graphics.line(
            self.offsetX, self.offsetY + y * ts,
            self.offsetX + self.width * ts, self.offsetY + y * ts)
    end

    -- Border (brighter)
    love.graphics.setColor(0.5, 0.55, 0.65)
    love.graphics.rectangle("line",
        self.offsetX, self.offsetY,
        self.width * ts, self.height * ts)
end

function Board:screenToGrid(mx, my)
    local gx = math.floor((mx - self.offsetX) / self.tileSize)
    local gy = math.floor((my - self.offsetY) / self.tileSize)
    return gx, gy
end

function Board:gridToScreen(gx, gy)
    local sx = self.offsetX + gx * self.tileSize + self.tileSize / 2
    local sy = self.offsetY + gy * self.tileSize + self.tileSize / 2
    return sx, sy
end

function Board:inBounds(gx, gy)
    return gx >= 0 and gx < self.width and gy >= 0 and gy < self.height
end

return Board
