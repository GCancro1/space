-- ═══════════════════════════════════════════════════════════════════
-- tools/play.lua — headless "play the game in JSON" driver.
-- Plays one full turn PLAN→CALC→MOVE→SHOOT→END_TURN→PLAN without LÖVE,
-- saving each phase transition as a step file in states/play/.
--
-- Usage: lua5.1 tools/play.lua [statePath] [bundlePath]
--   statePath  default "states/new_game.json"
--   bundlePath default "actions/turn{state.meta.turn}_plan.json";
--              if missing, advances with empty actions
-- ═══════════════════════════════════════════════════════════════════
package.path = "./?.lua;./ai/vendor/?.lua;" .. package.path

local Config = require("config")
local GameState = require("game.game_state")
local json = require("ai.vendor.json")

-- ───────────────────────────────────────────────────────────────────
-- HELPERS
-- ───────────────────────────────────────────────────────────────────
local function readFile(path)
    local f = io.open(path, "rb")
    if not f then
        return nil
    end
    local content = f:read("*a")
    f:close()
    return content
end

local function loadState(path)
    local content = readFile(path)
    if not content then
        io.stderr:write("no state file: " .. tostring(path) .. "\n")
        os.exit(1)
    end
    local ok, state = pcall(json.decode, content)
    if not ok then
        io.stderr:write("invalid JSON in " .. tostring(path) .. ": " .. tostring(state) .. "\n")
        os.exit(1)
    end
    return state
end

local function loadBundle(path)
    local content = readFile(path)
    if not content then
        return nil
    end
    local ok, actions = pcall(json.decode, content)
    if not ok or type(actions) ~= "table" then
        io.stderr:write("bad bundle " .. tostring(path) .. ": " .. tostring(actions) .. "\n")
        return nil
    end
    return actions
end

-- Save a step file. In-process counter (one turn per run), so no directory
-- scan needed; mkdir -p keeps the target dir existing.
local seq = 0
local function saveStep(state)
    local path = string.format("states/play/%03d_%s.json", seq, state.meta.phase)
    os.execute("mkdir -p states/play")
    local ok, encoded = pcall(json.encode, state)
    if not ok then
        io.stderr:write("encode failed for step: " .. tostring(encoded) .. "\n")
        os.exit(1)
    end
    local f = io.open(path, "w")
    if not f then
        io.stderr:write("cannot write " .. tostring(path) .. "\n")
        os.exit(1)
    end
    f:write(encoded)
    f:close()
    return path
end

-- ───────────────────────────────────────────────────────────────────
-- MAIN
-- ───────────────────────────────────────────────────────────────────
local state = loadState(arg[1] or "states/new_game.json")

local actions = {}
if state.meta.phase == "PLAN" then
    local bundlePath = arg[2] or ("actions/turn" .. tostring(state.meta.turn) .. "_plan.json")
    local bundle = loadBundle(bundlePath)
    if bundle then
        actions = bundle
    else
        print("no action bundle at " .. tostring(bundlePath) .. " — advancing with empty actions")
    end
end

-- Advance until we return to PLAN (turn complete). Max 8 iterations is a
-- safety cap: a normal turn is 5 phase transitions (PLAN→CALC→MOVE→
-- SHOOT→END_TURN→PLAN).
for _ = 1, 8 do
    local from = state.meta.phase
    local turn = state.meta.turn
    local ok, newState = pcall(GameState.advancePhase, state, actions)
    if not ok then
        io.stderr:write("advancePhase error at " .. tostring(from) .. ": " .. tostring(newState) .. "\n")
        os.exit(1)
    end
    state = newState
    actions = {}  -- the bundle applies to the initial PLAN transition only
    local path = saveStep(state)
    print(string.format("step %d: %s -> %s  turn %d  saved %s", seq, from, state.meta.phase, turn, path))
    seq = seq + 1
    if state.meta.phase == "PLAN" then
        break
    end
end

if state.meta.phase ~= "PLAN" then
    io.stderr:write("did not return to PLAN after 8 steps; last phase: " .. tostring(state.meta.phase) .. "\n")
    os.exit(1)
end

local ships = state.ships or {}
local asteroids = state.asteroids or {}
print(string.format("turn %d complete: %d ships remaining, %d asteroids", state.meta.turn, #ships, #asteroids))
os.exit(0)