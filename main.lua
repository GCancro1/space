local Config = require("config")
local Board = require("ai.lib.board")
local Assets = require("assets")

local GameState = require("game.game_state")
local StateIO = require("game.state_io")
local StateRenderer = require("game.state_renderer")

-- ═══════════════════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════════════════
local state = nil
local renderer = nil
local board = nil
local statePath = nil

-- ═══════════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════
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

local function loadState(path)
    local ok, result = pcall(StateIO.load, path)
    if not ok then
        print("Failed to load state: " .. tostring(result))
        return nil
    elseif not result then
        print("Failed to load state: " .. tostring(path))
        return nil
    end
    return result
end

-- Load the single action bundle for a turn ("actions/turnN_plan.json").
-- Returns an empty array on any failure (missing file, bad JSON) and prints
-- a notice, so gameplay can proceed with no actions.
local function loadActionsForTurn(turn)
    local path = "actions/turn" .. tostring(turn) .. "_plan.json"
    local ok, result = pcall(StateIO.load, path)
    if not ok or not result then
        print("no action bundle for turn " .. tostring(turn) .. ": " .. tostring(result or path) .. " — proceeding with empty actions")
        return {}
    end
    return result
end

-- Next sequence number for the step-file chain: 1 + max numeric prefix
-- across states/play/*. pcall-guarded: a missing dir yields 0 → seq starts 0.
local function nextChainSeq()
    local seq = 0
    local ok, items = pcall(love.filesystem.getDirectoryItems, "states/play")
    if ok and items then
        for _, name in ipairs(items) do
            local n = tonumber(string.match(name, "^(%d+)"))
            if n and n > seq then
                seq = n
            end
        end
    end
    return seq + 1
end

-- ═══════════════════════════════════════════════════════════════════
-- LOVE CALLBACKS
-- ═══════════════════════════════════════════════════════════════════
function love.load(args)
    love.window.setMode(0, 0, { fullscreen = true })
    Assets.load()
    -- Fixed 24px font; every love.graphics.print uses this font
    Config.FONT_SIZE = 24
    love.graphics.setFont(love.graphics.newFont(Config.FONT_SIZE))
    recalcLayout()
    renderer = StateRenderer:new()

    statePath = args[1] or "states/new_game.json"
    state = loadState(statePath)
    if not state then
        state = loadState("states/new_game.json")
    end
end

function love.update(dt)
    renderer:update(dt)
end

function love.draw()
    renderer:draw(state)
end

function love.resize(w, h)
    recalcLayout()
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "space" then
        if state then
            local oldPhase = state.meta.phase
            local actions = {}
            if oldPhase == "PLAN" then
                actions = loadActionsForTurn(state.meta.turn)
            end
            state = GameState.advancePhase(state, actions)
            local savePath = "states/play/" .. string.format("%03d", nextChainSeq()) .. "_" .. state.meta.phase .. ".json"
            local ok, err = StateIO.saveFs(state, savePath)
            if ok then
                print("PHASE " .. oldPhase .. " -> " .. state.meta.phase .. "  saved: " .. savePath)
            else
                print("PHASE " .. oldPhase .. " -> " .. state.meta.phase .. "  save failed: " .. tostring(err))
            end
        end
    elseif key == "t" then
        if state then
            local newState, events = GameState.advanceTick(state)
            state = newState
            if events and #events > 0 then
                renderer:setEvents(events)
            end
        end
    elseif key == "l" then
        state = loadState(statePath)
        if not state then
            state = loadState("states/new_game.json")
        end
    elseif key == "s" then
        if state then
            -- Plain-io save: lands in the repo (CWD-relative), not the LÖVE save dir
            local ok, result = pcall(StateIO.saveFs, state, statePath)
            if ok and result ~= false then
                print("saved: " .. tostring(statePath))
            else
                print("save failed: " .. tostring(result))
            end
        end
    end
end

function love.mousepressed(mx, my, button)
    -- GAME LOGIC INPUT (other workers)
    if button ~= 1 or not board or not state then return end
    local gx, gy = board:screenToGrid(mx, my)
    if not board:inBounds(gx, gy) then
        renderer:selectShip(nil)
        return
    end
    for _, ship in ipairs(state.ships or {}) do
        if ship.x == gx and ship.y == gy then
            renderer:selectShip(ship.id)
            return
        end
    end
    renderer:selectShip(nil)
end
