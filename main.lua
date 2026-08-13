local Config = require("config")

-- ═══════════════════════════════════════════════════════════════════
-- AI-GENERATED RENDERING MODULES
-- ═══════════════════════════════════════════════════════════════════
local Board = require("ai.lib.board")
local Ship = require("ai.lib.ship")
local ShipPanel = require("ai.lib.ship_panel")
local Asteroid = require("ai.lib.asteroid")
local Assets = require("assets")
local Particles = require("ai.lib.particles")
local flux = require("ai.vendor.flux")
local MovementAnimator = require("ai.lib.movement_animator")
local Sidebar = require("ai.lib.sidebar")

local moonshine_ok, moonshine
if Config.ENABLE_VIGNETTE then
    moonshine_ok, moonshine = pcall(require, "ai.vendor.moonshine")
end

-- ═══════════════════════════════════════════════════════════════════
-- GAME LOGIC MODULES (add your imports here)
-- ═══════════════════════════════════════════════════════════════════
-- local GameState = require("game.state")

-- ═══════════════════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════════════════
local board
local ships
local asteroids
local panel
local particles
local effect
local sidebar
local movementAnimator

local PLAYER_COLORS = {
    {0.2, 0.6, 1.0},   -- blue
    {1.0, 0.3, 0.3},   -- red
    {0.3, 1.0, 0.4},   -- green
    {1.0, 0.4, 0.7},   -- pink
}

-- ═══════════════════════════════════════════════════════════════════
-- AI-GENERATED HELPERS
-- ═══════════════════════════════════════════════════════════════════
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
    local boardH = h - Config.INFO_BAR_HEIGHT

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

-- ═══════════════════════════════════════════════════════════════════
-- GAME LOGIC HELPERS (add your helpers here)
-- ═══════════════════════════════════════════════════════════════════
local function spawnShips()
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

    return ships
end

local function spawnAsteroids()
    asteroids = {
        Asteroid:new(9,  9, 1, 1),
        Asteroid:new(11, 8, 2, 1),
        Asteroid:new(8,  11, 2, 2),
        Asteroid:new(10, 10, 3, 1),
        Asteroid:new(13, 11, 3, 3),
    }

    for _, a in ipairs(asteroids) do
        a:setFlux(flux)
    end

    return asteroids
end

-- ═══════════════════════════════════════════════════════════════════
-- LOVE CALLBACKS
-- ═══════════════════════════════════════════════════════════════════
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

    -- ═══════════════════════════════════════════════════════════════
    -- GAME LOGIC INITIALIZATION (add your code here)
    -- ═══════════════════════════════════════════════════════════════
    ships = spawnShips()
    asteroids = spawnAsteroids()

    love.graphics.setBackgroundColor(Config.BACKGROUND_COLOR)
    panel = ShipPanel:new()
    sidebar = Sidebar:new()
end

function love.update(dt)
    flux.update(dt)
    if movementAnimator then movementAnimator:update(dt) end
    particles:update(dt)

    -- ═══════════════════════════════════════════════════════════════
    -- GAME LOGIC UPDATE (add your code here)
    -- ═══════════════════════════════════════════════════════════════

    if sidebar then sidebar:update(dt, ships, 1, 1) end
end

function love.resize(w, h)
    recalcLayout()
    if effect then
        effect:resize(w, h)
    end
end

function love.draw()
    local drawScene = function()
        -- Draw space background (tileable)
        if Config.ENABLE_BACKGROUND then
            local bgW = Assets.background:getWidth()
            local bgH = Assets.background:getHeight()
            love.graphics.setColor(1, 1, 1)
            for x = 0, Config.SCREEN_WIDTH, bgW do
                for y = 0, Config.SCREEN_HEIGHT, bgH do
                    love.graphics.draw(Assets.background, x, y)
                end
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
        drawInfoBar()
    end

    if effect then
        effect(drawScene)
    else
        drawScene()
    end

    if sidebar then sidebar:draw() end
end

function drawInfoBar()
    local y = Config.INFO_BAR_Y
    local h = Config.INFO_BAR_HEIGHT

    love.graphics.setColor(Config.INFO_BAR_BG)
    love.graphics.rectangle("fill", 0, y, Config.SCREEN_WIDTH - Config.SIDEBAR_WIDTH, h)

    love.graphics.setColor(0.5, 0.7, 1.0, 0.95)
    love.graphics.setLineWidth(2)
    love.graphics.line(0, y, Config.SCREEN_WIDTH - Config.SIDEBAR_WIDTH, y)
    love.graphics.setLineWidth(1)
    for i = 1, 5 do
        local alpha = 0.35 / i
        local spread = i * 3
        love.graphics.setColor(0.4, 0.6, 1.0, alpha)
        love.graphics.rectangle("fill", 0, y + spread, Config.SCREEN_WIDTH - Config.SIDEBAR_WIDTH, 1)
    end

    if panel and ships then
        panel:drawAll(ships, y, h, Config.SCREEN_WIDTH - Config.SIDEBAR_WIDTH)
    end
end

function love.mousepressed(mx, my, button)
    if button == 1 then
        if mx >= Config.SCREEN_WIDTH - Config.SIDEBAR_WIDTH then
            return
        end

        -- ═══════════════════════════════════════════════════════════
        -- GAME LOGIC INPUT (add your code here)
        -- ═══════════════════════════════════════════════════════════
        local gx, gy = board:screenToGrid(mx, my)
        if board:inBounds(gx, gy) then
            -- GameState.handleClick(gx, gy)
        end
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end

    -- ═══════════════════════════════════════════════════════════════
    -- GAME LOGIC KEYBOARD (add your code here)
    -- ═══════════════════════════════════════════════════════════════

    if sidebar and sidebar.suit then
        sidebar.suit:keypressed(key)
    end
end

function love.textinput(t)
    if sidebar and sidebar.suit then
        sidebar.suit:textinput(t)
    end
end
