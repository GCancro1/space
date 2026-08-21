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
    
    -- Sidebar: 30-35% of window width, clamped to reasonable range
    local sidebarW = math.min(math.max(math.floor(w * 0.33), 320), 600)
    
    -- Info bar: proportional to window height, clamped
    local infoBarH = math.min(math.max(math.floor(h * 0.22), 180), 320)
    
    local boardW = w - sidebarW
    local boardH = h - infoBarH

    local tileSizeX = math.floor(boardW / Config.GRID_WIDTH)
    local tileSizeY = math.floor(boardH / Config.GRID_HEIGHT)
    local tileSize = math.min(tileSizeX, tileSizeY)

    -- Cap tile size to prevent oversized tiles on large screens
    local maxTileSize = math.floor(math.min(w, h) / 20)
    if tileSize > maxTileSize then
        tileSize = maxTileSize
    end

    local gridPixelW = tileSize * Config.GRID_WIDTH
    local gridPixelH = tileSize * Config.GRID_HEIGHT
    local offsetX = math.floor((boardW - gridPixelW) / 2)
    local offsetY = math.floor((boardH - gridPixelH) / 2)

    Config.TILE_SIZE = tileSize
    Config.SCREEN_WIDTH = w
    Config.SCREEN_HEIGHT = h
    Config.GRID_OFFSET_X = offsetX
    Config.GRID_OFFSET_Y = offsetY
    Config.BOARD_WIDTH = boardW
    Config.BOARD_HEIGHT = boardH
    Config.INFO_BAR_HEIGHT = infoBarH
    Config.INFO_BAR_Y = gridPixelH + offsetY
    Config.SIDEBAR_WIDTH = sidebarW

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
        local msg = result or path
        print("no action bundle for turn " .. tostring(turn) .. ": " .. tostring(msg)
            .. " — proceeding with empty actions")
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
-- CLI ARGUMENT HANDLING
-- ═══════════════════════════════════════════════════════════════════

local function printUsage()
    print("Usage: love . [OPTIONS] [STATE_FILE]")
    print("")
    print("Options:")
    print("  --help              Show this help message and quit")
    print("  --list              List all .json files under states/examples/ and quit")
    print("  --example=NAME      Load an example state from states/examples/")
    print("                      If NAME contains '/', uses")
    print("                      states/examples/NAME.json")
    print("                      Else tries states/examples/NAME.json")
    print("                      Else falls back to states/examples/edge/NAME.json")
    print("")
    print("Positional:")
    print("  STATE_FILE          Path to a state .json file (default: states/new_game.json)")
    print("")
    print("Examples:")
    print("  love . --example=chain_collision")
    print("  love . states/examples/edge/triple_ship.json")
    print("  love . --list")
    print("  love . --help")
end

local function listExampleStates()
    local function walk(dir, results)
        local items = love.filesystem.getDirectoryItems(dir)
        if not items then return end
        for _, name in ipairs(items) do
            local path = dir .. "/" .. name
            local info = love.filesystem.getInfo(path)
            if info and info.type == "directory" then
                walk(path, results)
            elseif info and info.type == "file" and name:match("%.json$") then
                results[#results + 1] = path
            end
        end
    end
    local results = {}
    walk("states/examples", results)
    table.sort(results)
    for _, path in ipairs(results) do
        print(path)
    end
end

local function resolveExamplePath(name)
    local path
    if name:find("/") then
        path = "states/examples/" .. name .. ".json"
    else
        path = "states/examples/" .. name .. ".json"
        local info = love.filesystem.getInfo(path)
        if not info then
            path = "states/examples/edge/" .. name .. ".json"
        end
    end
    return path
end

local function processArgs(args)
    -- Check for --help first
    for _, arg in ipairs(args) do
        if arg == "--help" then
            printUsage()
            love.event.quit()
            return nil, true
        end
    end

    -- Check for --list
    for _, arg in ipairs(args) do
        if arg == "--list" then
            listExampleStates()
            love.event.quit()
            return nil, true
        end
    end

    -- Check for --example=NAME
    for _, arg in ipairs(args) do
        local name = arg:match("^%-%-example=(.+)$")
        if name then
            local path = resolveExamplePath(name)
            return path, false
        end
    end

    -- Check for unknown flags
    for _, arg in ipairs(args) do
        if arg:match("^%-%-") then
            print("Unknown option: " .. arg .. " (ignored, using default)")
            return "states/new_game.json", false
        end
    end

    -- Positional argument (first non-flag)
    for _, arg in ipairs(args) do
        if not arg:match("^%-%-") then
            return arg, false
        end
    end

    return "states/new_game.json", false
end

-- ═══════════════════════════════════════════════════════════════════
-- LOVE CALLBACKS
-- ═══════════════════════════════════════════════════════════════════
function love.load(args)
    Assets.load()
    -- Base font size; will scale with window height
    local w, h = love.graphics.getDimensions()
    Config.FONT_SIZE = math.max(18, math.min(28, math.floor(h / 45)))
    love.graphics.setFont(love.graphics.newFont(Config.FONT_SIZE))
    recalcLayout()
    renderer = StateRenderer:new()

    local statePath, shouldQuit = processArgs(args)
    if shouldQuit then
        return
    end
    state = loadState(statePath)
    if not state then
        print("Failed to load state: " .. tostring(statePath) .. ", falling back to default")
        statePath = "states/new_game.json"
        state = loadState(statePath)
    end
    if state then
        local ph = state.meta and state.meta.phase or "?"
        local tn = state.meta and state.meta.turn or "?"
        print("loaded state: " .. statePath .. " (phase " .. ph .. ", turn " .. tn .. ")")
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
            local seq = nextChainSeq()
            local savePath = "states/play/" .. string.format("%03d", seq)
                .. "_" .. state.meta.phase .. ".json"
            local ok, err = StateIO.saveFs(state, savePath)
            if ok then
                print("PHASE " .. oldPhase .. " -> " .. state.meta.phase
                    .. "  saved: " .. savePath)
            else
                print("PHASE " .. oldPhase .. " -> " .. state.meta.phase
                    .. "  save failed: " .. tostring(err))
            end
        end
    elseif key == "t" then
        if state then
            local newState, events = GameState.advanceTick(state)
            state = newState
            if events and #events > 0 then
                renderer:setEvents(events, state)
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

function love.wheelmoved(x, y)
    if renderer and state then
        renderer:onWheelMoved(y, state)
    end
end
