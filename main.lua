local Config = require("config")
local Board = require("lib.board")
local Ship = require("lib.ship")
local ShipPanel = require("lib.ship_panel")
local Asteroid = require("lib.asteroid")

local board
local ships
local asteroids
local panel

local PLAYER_COLORS = {
    {0.2, 0.6, 1.0},   -- blue
    {1.0, 0.3, 0.3},   -- red
    {0.3, 1.0, 0.4},   -- green
    {1.0, 0.4, 0.7},   -- pink
}

local function facingTowardCenter(x, y)
    local cx = Config.GRID_WIDTH / 2
    local cy = Config.GRID_HEIGHT / 2
    local dx = cx - x
    local dy = cy - y

    if math.abs(dx) < 2 and math.abs(dy) < 2 then
        return "S"
    end

    local angle = math.atan2(dy, dx)
    if angle > -math.pi / 4 and angle <= math.pi / 4 then
        return "E"
    elseif angle > math.pi / 4 and angle <= 3 * math.pi / 4 then
        return "S"
    elseif angle > -3 * math.pi / 4 and angle <= -math.pi / 4 then
        return "N"
    else
        return "W"
    end
end

local function recalcLayout()
    local w, h = love.graphics.getDimensions()
    local infoH = Config.INFO_BAR_HEIGHT
    local gridAreaH = h - infoH
    local gridAreaW = w

    local tileSizeX = math.floor(gridAreaW / Config.GRID_WIDTH)
    local tileSizeY = math.floor(gridAreaH / Config.GRID_HEIGHT)
    local tileSize = math.min(tileSizeX, tileSizeY)

    local gridPixelW = tileSize * Config.GRID_WIDTH
    local gridPixelH = tileSize * Config.GRID_HEIGHT
    local offsetX = math.floor((gridAreaW - gridPixelW) / 2)
    local offsetY = 0

    Config.TILE_SIZE = tileSize
    Config.SCREEN_WIDTH = w
    Config.SCREEN_HEIGHT = h
    Config.GRID_OFFSET_X = offsetX
    Config.GRID_OFFSET_Y = offsetY
    Config.INFO_BAR_Y = gridPixelH

    board = Board:new(Config)
end

function love.load()
    love.window.setMode(0, 0, { fullscreen = true })
    recalcLayout()

    -- Spawn 4 ships at corners, facing toward center
    local spawn = {
        { 1,  1},
        {18, 18},
        {18,  1},
        { 1, 18},
    }

    ships = {}
    for i, pos in ipairs(spawn) do
        local facing = facingTowardCenter(pos[1], pos[2])
        ships[i] = Ship:new(pos[1], pos[2], facing, PLAYER_COLORS[i])
    end

    -- Test values for panel display
    ships[1].hp = 4
    ships[1].fuel = 15
    ships[1].momentum = {x = 1, y = -1}

    ships[2].hp = 3
    ships[2].fuel = 10
    ships[2].momentum = {x = -2, y = 0}

    ships[3].hp = 5
    ships[3].fuel = 20
    ships[3].momentum = {x = 0, y = 3}

    ships[4].hp = 2
    ships[4].fuel = 8
    ships[4].momentum = {x = 1, y = 2}

    -- Spawn asteroids in center area
    asteroids = {
        Asteroid:new(9,  9, 1, 1),   -- 1x1
        Asteroid:new(11, 8, 2, 1),   -- 2x1
        Asteroid:new(8,  11, 2, 2),  -- 2x2
        Asteroid:new(10, 10, 3, 1),  -- 3x1
        Asteroid:new(13, 11, 3, 3),  -- 3x3
    }

    love.graphics.setBackgroundColor(Config.GRID_BG_COLOR)
    panel = ShipPanel:new()
end

function love.resize(w, h)
    recalcLayout()
end

function love.draw()
    board:draw()
    for _, asteroid in ipairs(asteroids) do
        asteroid:draw(Config.TILE_SIZE, Config.GRID_OFFSET_X, Config.GRID_OFFSET_Y)
    end
    for _, ship in ipairs(ships) do
        ship:draw(Config.TILE_SIZE, Config.GRID_OFFSET_X, Config.GRID_OFFSET_Y)
    end
    drawInfoBar()
end

function drawInfoBar()
    local y = Config.INFO_BAR_Y
    local h = Config.INFO_BAR_HEIGHT

    love.graphics.setColor(Config.INFO_BAR_BG)
    love.graphics.rectangle("fill", 0, y, Config.SCREEN_WIDTH, h)
    love.graphics.setColor(Config.INFO_BAR_BORDER)
    love.graphics.line(0, y, Config.SCREEN_WIDTH, y)

    if panel and ships then
        panel:drawAll(ships, y, h, Config.SCREEN_WIDTH)
    end
end

function love.mousepressed(mx, my, button)
    if button == 1 then
        local gx, gy = board:screenToGrid(mx, my)
        if board:inBounds(gx, gy) then
            print(string.format("Clicked tile: (%d, %d)", gx, gy))
        end
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end
