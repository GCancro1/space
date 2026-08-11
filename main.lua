local Config = require("config")
local Board = require("lib.board")
local Ship = require("lib.ship")
local ShipPanel = require("lib.ship_panel")
local Asteroid = require("lib.asteroid")
local Assets = require("assets")
local Particles = require("lib.particles")
local flux = require("lib.flux")
local MovementAnimator = require("lib.movement_animator")
local Sidebar = require("lib.sidebar")

local moonshine_ok, moonshine
if Config.ENABLE_VIGNETTE then
    moonshine_ok, moonshine = pcall(require, "lib.moonshine")
end

local board
local ships
local asteroids
local panel
local particles
local effect
local sidebar

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
    local sidebarW = Config.SIDEBAR_WIDTH
    local boardW = w - sidebarW
    local boardH = h

    local tileSizeX = math.floor(boardW / Config.GRID_WIDTH)
    local tileSizeY = math.floor(boardH / Config.GRID_HEIGHT)
    local tileSize = math.min(tileSizeX, tileSizeY)

    local gridPixelW = tileSize * Config.GRID_WIDTH
    local gridPixelH = tileSize * Config.GRID_HEIGHT
    local offsetX = 0
    local offsetY = 0

    Config.TILE_SIZE = tileSize
    Config.SCREEN_WIDTH = w
    Config.SCREEN_HEIGHT = h
    Config.GRID_OFFSET_X = offsetX
    Config.GRID_OFFSET_Y = offsetY
    Config.BOARD_WIDTH = boardW
    Config.BOARD_HEIGHT = boardH
    Config.INFO_BAR_Y = gridPixelH

    board = Board:new(Config)
end

function love.load()
    love.window.setMode(0, 0, { fullscreen = true })
    Assets.load()
    recalcLayout()
    particles = Particles:new()
    movementAnimator = MovementAnimator:new(flux)

    if moonshine_ok and Config.ENABLE_VIGNETTE then
        effect = moonshine(moonshine.effects.vignette)
        effect.vignette.softness = Config.VIGNETTE_SOFTNESS
    end

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
        ships[i] = Ship:new(pos[1], pos[2], facing, PLAYER_COLORS[i], i)
        ships[i]:setFlux(flux)
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
        Asteroid:new(9,  9, 1, 1),
        Asteroid:new(11, 8, 2, 1),
        Asteroid:new(8,  11, 2, 2),
        Asteroid:new(10, 10, 3, 1),
        Asteroid:new(13, 11, 3, 3),
    }

    for _, asteroid in ipairs(asteroids) do
        asteroid:setFlux(flux)
    end

    love.graphics.setBackgroundColor(Config.GRID_BG_COLOR)
    panel = ShipPanel:new()
    sidebar = Sidebar:new()
end

function love.update(dt)
    flux.update(dt)
    if movementAnimator then movementAnimator:update(dt) end
    particles:update(dt)
    if sidebar then sidebar:update(dt, ships, 1, 1) end
end

function love.resize(w, h)
    recalcLayout()
end

function love.draw()
    local drawScene = function()
        -- Draw space background (tileable)
        local bgW = Assets.background:getWidth()
        local bgH = Assets.background:getHeight()
        love.graphics.setColor(1, 1, 1)
        for x = 0, Config.SCREEN_WIDTH, bgW do
            for y = 0, Config.SCREEN_HEIGHT, bgH do
                love.graphics.draw(Assets.background, x, y)
            end
        end

        board:draw()
        for _, asteroid in ipairs(asteroids) do
            asteroid:draw(Config.TILE_SIZE, Config.GRID_OFFSET_X, Config.GRID_OFFSET_Y)
        end
        for _, ship in ipairs(ships) do
            ship:draw(Config.TILE_SIZE, Config.GRID_OFFSET_X, Config.GRID_OFFSET_Y)
        end
        particles:draw()
        -- drawInfoBar() removed, using sidebar instead
    end

    if effect then
        effect(drawScene)
    else
        drawScene()
    end

    -- Draw sidebar on top of the game scene
    if sidebar then sidebar:draw() end
end

function drawInfoBar()
    local y = Config.INFO_BAR_Y
    local h = Config.INFO_BAR_HEIGHT

    -- Info bar background
    love.graphics.setColor(Config.INFO_BAR_BG)
    love.graphics.rectangle("fill", 0, y, Config.SCREEN_WIDTH, h)

    -- Glowing top border
    love.graphics.setColor(0.4, 0.6, 1.0, 0.9)
    love.graphics.setLineWidth(2)
    love.graphics.line(0, y, Config.SCREEN_WIDTH, y)
    love.graphics.setLineWidth(1)
    -- Glow passes
    for i = 1, 4 do
        local alpha = 0.25 / i
        local spread = i * 3
        love.graphics.setColor(0.3, 0.5, 1.0, alpha)
        love.graphics.rectangle("fill", 0, y + spread, Config.SCREEN_WIDTH, 1)
    end

    if panel and ships then
        panel:drawAll(ships, y, h, Config.SCREEN_WIDTH)
    end
end

function love.mousepressed(mx, my, button)
    if button == 1 then
        -- Don't handle clicks on the sidebar
        if mx >= Config.SCREEN_WIDTH - Config.SIDEBAR_WIDTH then
            return
        end
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
    -- Forward keys to SUIT
    if sidebar and sidebar.suit then
        sidebar.suit:keypressed(key)
    end
end

function love.textinput(t)
    if sidebar and sidebar.suit then
        sidebar.suit:textinput(t)
    end
end
