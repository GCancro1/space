local Class = require("lib.class")
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

    -- Grid background
    love.graphics.setColor(self.config.GRID_BG_COLOR)
    love.graphics.rectangle("fill",
        self.offsetX, self.offsetY,
        self.width * ts, self.height * ts)

    -- Grid lines
    love.graphics.setColor(self.config.GRID_LINE_COLOR)
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

    -- Border
    love.graphics.setColor(0.4, 0.4, 0.4)
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
