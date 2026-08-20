-- test_shoot.lua - Engine-level integration tests for the SHOOT phase:
-- simultaneous fire, closest ship-or-asteroid target selection, TURRET_RANGE
-- boundary, TURRET_DAMAGE = 1 (power only gates + costs fuel), asteroid HP and
-- destruction. Plain Lua, no love required.
-- Run with: lua5.1 test_shoot.lua  (prints "ALL TESTS PASSED")

package.path = "./?.lua;./?/init.lua;" .. package.path

local GameState = require("game.game_state")
local Config = require("config")

assert(Config.GRID_WIDTH == 20 and Config.GRID_HEIGHT == 20,
    "engine grid must be 20x20 for these expectations")
assert(Config.TURRET_RANGE == 10,
    "shoot tests expect TURRET_RANGE 10, got " .. Config.TURRET_RANGE)
assert(Config.TURRET_DAMAGE == 1,
    "shoot tests expect TURRET_DAMAGE 1, got " .. Config.TURRET_DAMAGE)
assert(Config.ASTEROID_HP == 2,
    "shoot tests expect ASTEROID_HP 2, got " .. Config.ASTEROID_HP)

local W, H = Config.GRID_WIDTH, Config.GRID_HEIGHT

-- --- Helpers ---

-- A SHOOT-phase state: ships fire their pendingShot immediately when
-- advancePhase is called (the SHOOT branch resolves pendingShot directly).
local function shootState(ships, asteroids)
    return {
        meta = { phase = "SHOOT", turn = 1, currentPlayer = 1, cor = 1 },
        board = { width = W, height = H },
        ships = ships,
        asteroids = asteroids or {},
    }
end

-- Ship factory: default hp 5, fuel 20, facing + turret E, no pendingShot.
local function makeShip(id, x, y, overrides)
    local s = { id = id, x = x, y = y, hp = 5, fuel = 20, facing = "E",
                turretFacing = "E", momentum = { x = 0, y = 0 } }
    for k, v in pairs(overrides or {}) do
        s[k] = v
    end
    return s
end

-- Resolve pending shots through advancePhase (SHOOT -> END_TURN).
local function resolveShots(state)
    return GameState.advancePhase(state, {})
end

local function findShipById(state, id)
    for _, s in ipairs(state.ships) do
        if s.id == id then
            return s
        end
    end
    return nil
end

local function countLog(state, etype)
    local n = 0
    for _, e in ipairs(state.meta.eventLog or {}) do
        if e.type == etype then
            n = n + 1
        end
    end
    return n
end

-- Count "destroyed" log entries whose text names the given object type
-- ("ship"/"asteroid"). The event type inside advancePhase is
-- shipDestroyed/asteroidDestroyed, but logEvent folds both into type
-- "destroyed" (the renderer colorizes them red).
local function countDestroyedLog(state, what)
    local n = 0
    for _, e in ipairs(state.meta.eventLog or {}) do
        if e.type == "destroyed" and string.find(e.text, what .. " %d+ destroyed") then
            n = n + 1
        end
    end
    return n
end

-- Parse the SHOOT log's shot lines into {shipId, kind, targetId, damage, x, y}.
local function logShots(state)
    local shots = {}
    for _, e in ipairs(state.meta.eventLog or {}) do
        if e.type == "shot" then
            local sid, kind, tid, dmg, x, y = string.match(e.text,
                "^ship (%d+) hit (%a+) (%d+) for (%d+) at %((%d+),(%d+)%)")
            assert(sid, "unparseable shot line: " .. tostring(e.text))
            shots[#shots + 1] = { shipId = tonumber(sid), kind = kind,
                                  targetId = tonumber(tid), damage = tonumber(dmg),
                                  x = tonumber(x), y = tonumber(y) }
        end
    end
    return shots
end

-- ============================================================================
-- T1. Closest ship wins: ship 1 at (5,5) fires E; ships 2 (7,5) and 3 (9,5)
--     stand in the column. Exactly one shot, targeting the nearest ship,
--     damage 1, fuel 20 -> 19.
-- ============================================================================
local function testT1ClosestShipWins()
    local state = resolveShots(shootState({
        makeShip(1, 5, 5, { pendingShot = { power = 1 } }),
        makeShip(2, 7, 5),
        makeShip(3, 9, 5),
    }))
    local a = findShipById(state, 1)
    assert(a.fuel == 19, "T1: ship 1 fuel 20 -> 19, got " .. a.fuel)
    assert(findShipById(state, 2).hp == 4, "T1: ship 2 hp 5 -> 4, got " .. findShipById(state, 2).hp)
    assert(findShipById(state, 3).hp == 5, "T1: ship 3 (farther) must be untouched")
    local shots = logShots(state)
    assert(#shots == 1, "T1: exactly one shot event expected, got " .. #shots)
    assert(shots[1].shipId == 1 and shots[1].kind == "ship" and shots[1].targetId == 2,
        "T1: shot must target the closest ship (id 2)")
    assert(shots[1].damage == 1, "T1: shot damage must be TURRET_DAMAGE 1")
    assert(shots[1].x == 7 and shots[1].y == 5, "T1: impact must be at ship 2's tile")
    assert(state.meta.phase == "END_TURN", "T1: SHOOT should advance to END_TURN")
    print("T1 PASSED (closest ship takes 1 damage)")
end

-- ============================================================================
-- T2. Closest asteroid beats a farther ship: the rock at (6,5) absorbs the
--     shot (hp 2 -> 1) and the ship at (8,5) is untouched.
-- ============================================================================
local function testT2AsteroidFirst()
    local state = resolveShots(shootState({
        makeShip(1, 5, 5, { pendingShot = { power = 1 } }),
        makeShip(2, 8, 5),
    }, {
        { id = 30, x = 6, y = 5, w = 1, h = 1 },
    }))
    assert(state.asteroids[1].hp == 1, "T2: asteroid hp 2 -> 1, got " .. state.asteroids[1].hp)
    assert(findShipById(state, 2).hp == 5, "T2: ship beyond the asteroid must be untouched")
    local shots = logShots(state)
    assert(#shots == 1, "T2: exactly one shot event expected, got " .. #shots)
    assert(shots[1].kind == "asteroid" and shots[1].targetId == 30,
        "T2: shot must target the asteroid (id 30)")
    assert(shots[1].damage == 1, "T2: shot damage must be 1")
    print("T2 PASSED (asteroid block-and-damage beats farther ship)")
end

-- ============================================================================
-- T3. Asteroid destroyed by two simultaneous shots + simultaneity/damage
--     check: ships (5,5) E and (8,5) W bracket a hp-2 asteroid at (6,5) in a
--     1-wide row. Power-2 shots each deal exactly 1 (not power), the rock
--     drops to 0 hp, is removed, and emits one asteroidDestroyed event.
-- ============================================================================
local function testT3DoubleHitDestroysAsteroid()
    local state = resolveShots(shootState({
        makeShip(1, 5, 5, { pendingShot = { power = 2 } }),
        makeShip(2, 8, 5, { facing = "W", turretFacing = "W", pendingShot = { power = 2 } }),
    }, {
        { id = 30, x = 6, y = 5, w = 1, h = 1 },
    }))
    assert(#state.asteroids == 0, "T3: asteroid at hp 0 must be removed from the state")
    assert(findShipById(state, 1).fuel == 18, "T3: ship 1 fuel 20 - 2 power = 18")
    assert(findShipById(state, 2).fuel == 18, "T3: ship 2 fuel 20 - 2 power = 18")
    local shots = logShots(state)
    assert(#shots == 2, "T3: two shot events expected, got " .. #shots)
    for _, s in ipairs(shots) do
        assert(s.kind == "asteroid" and s.targetId == 30,
            "T3: both shots must target the asteroid (id 30)")
        assert(s.damage == 1, "T3: each shot deals exactly 1, not the shot power")
    end
    assert(countDestroyedLog(state, "asteroid") == 1,
        "T3: exactly one asteroidDestroyed event expected")
    print("T3 PASSED (double-shot asteroid destruction; damage 1 each, not power)")
end

-- ============================================================================
-- T4. Simultaneity vs a dying target: A (5,5) E and B (7,5) hp 1 both fire.
--     A kills B, but B's shot is resolved from the pre-SHOOT state too, so
--     A still takes 1 (hp 5 -> 4). Both shots logged, B removed + destroyed.
-- ============================================================================
local function testT4SimultaneousDuel()
    local state = resolveShots(shootState({
        makeShip(1, 5, 5, { pendingShot = { power = 1 } }),
        makeShip(2, 7, 5, { hp = 1, facing = "W", turretFacing = "W", pendingShot = { power = 1 } }),
    }))
    assert(findShipById(state, 1).hp == 4, "T4: A hp 5 -> 4 from B's simultaneous shot")
    assert(#state.ships == 1 and state.ships[1].id == 1, "T4: only ship A must remain (B destroyed)")
    local shots = logShots(state)
    assert(#shots == 2, "T4: both shots must be recorded, got " .. #shots)
    assert(shots[1].shipId == 1 and shots[1].targetId == 2, "T4: ship 1 must hit ship 2")
    assert(shots[2].shipId == 2 and shots[2].targetId == 1, "T4: ship 2 must fire back at ship 1")
    assert(countDestroyedLog(state, "ship") == 1, "T4: B destroyed -> one shipDestroyed event")
    print("T4 PASSED (dead ship still fires back — simultaneous resolution)")
end

-- ============================================================================
-- T5. Range boundary: ship 2 at exactly TURRET_RANGE (10) tiles is hit; ship
--     3 at 11 tiles is out of range. A shot into an empty row (ship 4) still
--     spends the fuel.
-- ============================================================================
local function testT5RangeBoundary()
    local state = resolveShots(shootState({
        makeShip(1, 5, 5, { pendingShot = { power = 1 } }),
        makeShip(2, 15, 5),
        makeShip(3, 16, 5),
        makeShip(4, 5, 6, { pendingShot = { power = 1 } }),
    }))
    assert(findShipById(state, 2).hp == 4, "T5: ship exactly 10 tiles away must be hit")
    assert(findShipById(state, 3).hp == 5, "T5: ship at 11 tiles must be out of range")
    assert(findShipById(state, 4).fuel == 19, "T5: miss still deducts fuel (20 -> 19)")
    local shots = logShots(state)
    assert(#shots == 1, "T5: only the in-range hit produces a shot event, got " .. #shots)
    assert(shots[1].shipId == 1 and shots[1].targetId == 2 and shots[1].x == 15,
        "T5: the hit must land at (15,5)")
    print("T5 PASSED (range boundary at exactly 10 tiles; miss still costs fuel)")
end

-- ============================================================================
-- T6. No fuel, no shot: a ship with pendingShot but zero fuel must not fire
--     (power gates on fuel, exactly like the current CALC gating).
-- ============================================================================
local function testT6NoFuelNoShot()
    local state = resolveShots(shootState({
        makeShip(1, 5, 5, { fuel = 0, pendingShot = { power = 1 } }),
        makeShip(2, 7, 5),
    }))
    assert(findShipById(state, 2).hp == 5, "T6: no fuel -> no damage")
    assert(findShipById(state, 1).fuel == 0, "T6: fuel must stay 0")
    assert(countLog(state, "shot") == 0, "T6: no shot event without fuel")
    print("T6 PASSED (fuel 0 gates the shot)")
end

-- ============================================================================
-- T7. No pendingShot: a ship that planned no shot must not fire. The phase
--     still advances SHOOT -> END_TURN.
-- ============================================================================
local function testT7NoPendingShot()
    local state = resolveShots(shootState({
        makeShip(1, 5, 5),
        makeShip(2, 7, 5),
    }))
    assert(findShipById(state, 2).hp == 5, "T7: no pendingShot -> no damage")
    assert(countLog(state, "shot") == 0, "T7: no shot event without pendingShot")
    assert(state.meta.phase == "END_TURN", "T7: SHOOT should advance to END_TURN")
    print("T7 PASSED (no pendingShot, no shot)")
end

-- --- Run everything ---
testT1ClosestShipWins()
testT2AsteroidFirst()
testT3DoubleHitDestroysAsteroid()
testT4SimultaneousDuel()
testT5RangeBoundary()
testT6NoFuelNoShot()
testT7NoPendingShot()
print("ALL TESTS PASSED")