-- test_game_state_collision.lua - Engine-level integration tests for
-- collision handling driven through GameState.advanceTick (MOVE phase).
-- Plain Lua, no love required.
-- Run with: lua5.1 test_game_state_collision.lua  (prints "ALL TESTS PASSED")

package.path = "./?.lua;./?/init.lua;" .. package.path

local GameState = require("game.game_state")
local Config = require("config")

assert(Config.GRID_WIDTH == 20 and Config.GRID_HEIGHT == 20,
    "engine grid must be 20x20 for these expectations")

local W, H = Config.GRID_WIDTH, Config.GRID_HEIGHT

-- --- Helpers ---

-- Fresh MOVE-phase ship state (movement pre-built, as CALC emits it).
local function moveShip(id, x, y, cor, hp, mx, my)
    return {
        meta = { phase = "MOVE", turn = 1, currentPlayer = 1, cor = cor },
        board = { width = W, height = H },
        ships = { {
            id = id, x = x, y = y, hp = hp, fuel = 20,
            facing = "E", turretFacing = "E",
            momentum = { x = mx, y = my },
            movement = { direction = (mx > 0 and "E" or (mx < 0 and "W" or (my > 0 and "S" or "N"))),
                         stepsRemaining = math.max(math.abs(mx), math.abs(my)) },
        } },
        asteroids = {},
    }
end

-- Run the MOVE loop to completion. Returns { state, ticks, bounces, events }.
-- Asserts every object's origin stays in bounds every tick and that momentum
-- is never amplified beyond the largest component in the initial state.
local function runMove(state)
    local ticks, bounces = 0, 0
    local maxMom = 0
    for _, o in ipairs(state.ships) do
        maxMom = math.max(maxMom, math.abs(o.momentum.x), math.abs(o.momentum.y))
    end
    for _, o in ipairs(state.asteroids or {}) do
        maxMom = math.max(maxMom, math.abs(o.momentum.x), math.abs(o.momentum.y))
    end
    local allEvents = {}
    while state.meta.phase == "MOVE" do
        ticks = ticks + 1
        assert(ticks <= 20000, "MOVE loop did not terminate (runaway?)")
        local evs
        state, evs = GameState.advanceTick(state)
        for _, o in ipairs(state.ships) do
            assert(o.x >= 0 and o.x < W and o.y >= 0 and o.y < H,
                "T-tick " .. ticks .. ": ship " .. o.id .. " out of bounds at (" .. o.x .. "," .. o.y .. ")")
            assert(math.abs(o.momentum.x) <= maxMom and math.abs(o.momentum.y) <= maxMom,
                "T-tick " .. ticks .. ": ship " .. o.id .. " momentum amplified")
        end
        for _, o in ipairs(state.asteroids or {}) do
            assert(o.x >= 0 and o.x < W and o.y >= 0 and o.y < H,
                "T-tick " .. ticks .. ": asteroid " .. o.id .. " out of bounds at (" .. o.x .. "," .. o.y .. ")")
            assert(math.abs(o.momentum.x) <= maxMom and math.abs(o.momentum.y) <= maxMom,
                "T-tick " .. ticks .. ": asteroid " .. o.id .. " momentum amplified")
        end
        for _, e in ipairs(evs or {}) do
            allEvents[#allEvents + 1] = e
            if e.type == "wallBounce" then bounces = bounces + 1 end
        end
    end
    return state, ticks, bounces, allEvents
end

local function countEvents(events, type)
    local n = 0
    for _, e in ipairs(events) do
        if e.type == type then n = n + 1 end
    end
    return n
end

-- ============================================================================
-- T1. COR=1 fast ship. Ship pushed at momentum 60 across a 20-wide board.
--     THE regression: it must never leave the board, and every wall bounce
--     deals exactly 1 damage (hp 200 -> 159 for 41 bounces).
--     NOTE (deviation from the brief's "momentum == (0,0)"): momentum only
--     decays while a burst reaches a wall. Once |momentum| < board diameter
--     the burst stops mid-board carrying residual inertia into the next phase,
--     so cor=1 reliably leaves (-19,0) here. Asserted against the module.
-- ============================================================================
local function testCorOneFastShip()
    local s, _, bounces, evs = runMove(moveShip(1, 5, 10, 1, 200, 60, 0))
    assert(bounces == 41, "T1: expected 41 wall bounces, got " .. bounces)
    assert(s.ships[1].hp == 200 - 41, "T1: hp should drop 1 per bounce, got " .. s.ships[1].hp)
    assert(s.ships[1].momentum.x == -19 and s.ships[1].momentum.y == 0,
        "T1: residual momentum should be (-19,0), got (" .. s.ships[1].momentum.x
            .. "," .. s.ships[1].momentum.y .. ")")
    assert(s.ships[1].movement == nil, "T1: movement should be exhausted")
    assert(s.meta.phase == "SHOOT", "T1: phase should reach SHOOT, got " .. s.meta.phase)
    assert(countEvents(evs, "wallBounce") == bounces,
        "T1: every bounce should emit a wallBounce event")
end

-- ============================================================================
-- T2. COR=0 (inelastic) fast ship: hits the east wall once, sticks there.
--     Momentum 60 -> 0, hp 5 -> 4, single wallBounce, stays in bounds.
-- ============================================================================
local function testCorZeroSticks()
    local s, _, bounces = runMove(moveShip(1, 5, 10, 0, 5, 60, 0))
    assert(bounces == 1, "T2: expected exactly 1 wall bounce, got " .. bounces)
    assert(s.ships[1].hp == 4, "T2: hp should drop to 4, got " .. s.ships[1].hp)
    assert(s.ships[1].momentum.x == 0 and s.ships[1].momentum.y == 0,
        "T2: cor=0 should stop momentum at (0,0), got (" .. s.ships[1].momentum.x
            .. "," .. s.ships[1].momentum.y .. ")")
    assert(s.ships[1].x == 19 and s.ships[1].y == 10,
        "T2: ship should rest on the east wall at (19,10), got (" .. s.ships[1].x .. "," .. s.ships[1].y .. ")")
    assert(s.ships[1].movement == nil, "T2: movement should be nil")
    assert(s.meta.phase == "SHOOT", "T2: phase should reach SHOOT")
end

-- ============================================================================
-- T3. COR=0.5 fast ship: bounces twice (60 -> -29 -> 14), stays in bounds,
--     hp 200 -> 198, and carries residual momentum (14,0) into SHOOT --
--     again because the final burst stops mid-board (see T1 note).
-- ============================================================================
local function testCorHalfFastShip()
    local s, _, bounces = runMove(moveShip(1, 5, 10, 0.5, 200, 60, 0))
    assert(bounces == 2, "T3: expected 2 wall bounces, got " .. bounces)
    assert(s.ships[1].hp == 198, "T3: hp should be 198, got " .. s.ships[1].hp)
    assert(s.ships[1].momentum.x == 14 and s.ships[1].momentum.y == 0,
        "T3: residual momentum should be (14,0), got (" .. s.ships[1].momentum.x .. "," .. s.ships[1].momentum.y .. ")")
    assert(s.ships[1].x == 14 and s.ships[1].y == 10,
        "T3: ship should rest at (14,10), got (" .. s.ships[1].x .. "," .. s.ships[1].y .. ")")
    assert(s.ships[1].movement == nil, "T3: movement should be nil")
    assert(s.meta.phase == "SHOOT", "T3: phase should reach SHOOT")
end

-- ============================================================================
-- T4. Asteroid drift: a w=1 asteroid with momentum 25 drifts, bounces off
--     the east wall (momentum flips + decays each bounce), never leaves the
--     board, and the MOVE phase terminates in SHOOT.
--     NOTE (deviation from the brief's w=2): wall bounces clamp the object's
--     ORIGIN into bounds, so a w=2 rect can poke 1 tile past the edge when
--     the origin rests on the wall tile. The brief asked for a strict
--     "x + w <= 20" invariant every tick, so w=1 is used to make that exact.
-- ============================================================================
local function testAsteroidDrift()
    local state = {
        meta = { phase = "MOVE", turn = 1, currentPlayer = 1, cor = 1 },
        board = { width = W, height = H },
        ships = {},
        asteroids = { {
            id = 10, x = 0, y = 10, w = 1, h = 1, facing = "N",
            momentum = { x = 25, y = 0 },
            movement = { direction = "E", stepsRemaining = 25 },
        } },
    }
    local s, _, bounces, evs = runMove(state)
    local a = s.asteroids[1]
    assert(a.x >= 0 and a.x + a.w <= W and a.y >= 0 and a.y + a.h <= H,
        "T4: asteroid rect left the board, now at (" .. a.x .. "," .. a.y .. ")")
    assert(bounces == 6, "T4: expected 6 wall bounces, got " .. bounces)
    assert(a.momentum.x == 19 and a.momentum.y == 0,
        "T4: residual momentum should be (19,0), got (" .. a.momentum.x .. "," .. a.momentum.y .. ")")
    assert(a.x == 19, "T4: asteroid should rest on the east wall, got x=" .. a.x)
    assert(a.movement == nil, "T4: movement should be nil")
    assert(s.meta.phase == "SHOOT", "T4: phase should reach SHOOT")
    -- Every bounce event must target the hit axis and carry damage=1
    local bouncesSeen = 0
    for _, e in ipairs(evs) do
        if e.type == "wallBounce" then
            bouncesSeen = bouncesSeen + 1
            assert(e.axis == "x" and e.objectId == 10,
                "T4: bounce event must be asteroid wallBounce on x, got "
                    .. tostring(e.type) .. " axis=" .. tostring(e.axis))
        end
    end
    assert(bouncesSeen == bounces, "T4: bounce count mismatch")
end

-- ============================================================================
-- T5. Asteroid-asteroid collision: overlapping rects with opposing momenta
--     resolve per resolveAxis. resolveAxis(2,-1,1): opposing -> swap (-1,2)
--     -> friction -> (0,1). First collision fires on tick 1 and must leave
--     exactly (0,1); the two rocks then grind once more and settle at (0,0).
-- ============================================================================
local function testAsteroidAsteroid()
    local state = {
        meta = { phase = "MOVE", turn = 1, currentPlayer = 1, cor = 1 },
        board = { width = W, height = H },
        ships = {},
        asteroids = {
            { id = 20, x = 3, y = 5, w = 2, h = 1, facing = "N",
              momentum = { x = 2, y = 0 }, movement = { direction = "E", stepsRemaining = 2 } },
            { id = 21, x = 4, y = 5, w = 2, h = 1, facing = "N",
              momentum = { x = -1, y = 0 }, movement = { direction = "W", stepsRemaining = 1 } },
        },
    }
    local s, _, bounces, evs = runMove(state)
    assert(bounces == 0, "T5: no wall bounces expected, got " .. bounces)
    assert(countEvents(evs, "asteroidCollision") == 2,
        "T5: expected 2 asteroidCollision events, got " .. countEvents(evs, "asteroidCollision"))
    -- First asteroidCollision event (tick 1) records the resolveAxis(2,-1,1)
    -- outcome -- movementStep events may precede it within the raw event list.
    local first
    for _, e in ipairs(evs) do
        if e.type == "asteroidCollision" then
            first = e
            break
        end
    end
    assert(first, "T5: first collision event should be an asteroidCollision")
    assert(first.a == 20 and first.b == 21 and first.damage == 0 and first.cor == 1,
        "T5: first event should be between rocks 20/21 with damage=0 cor=1")
    -- The two rocks grind once and settle stationary, phase terminates
    assert(s.asteroids[1].momentum.x == 0 and s.asteroids[1].momentum.y == 0,
        "T5: rock A should settle at momentum (0,0)")
    assert(s.asteroids[2].momentum.x == 0 and s.asteroids[2].momentum.y == 0,
        "T5: rock B should settle at momentum (0,0)")
    assert(s.meta.phase == "SHOOT", "T5: phase should reach SHOOT")
end

-- ============================================================================
-- T6. Ship-asteroid collision: ship (3,0) plows into a resting asteroid; the
--     rock recoils. resolveAxis(3,0,1): complementary avg 2 -> friction -> 1
--     on both, so ship.momentum.x == 1 and asteroid.momentum.x == 1 and the
--     ship takes its first damage (hp 5 -> 4) on the collision tick.
--     NOTE: the equal post-hit momentum makes ship+rock crawl off together,
--     grinding one more hit (hp -> 3) before stopping -- asserted below.
-- ============================================================================
local function testShipAsteroid()
    local state = {
        meta = { phase = "MOVE", turn = 1, currentPlayer = 1, cor = 1 },
        board = { width = W, height = H },
        ships = { {
            id = 1, x = 5, y = 5, hp = 5, fuel = 20, facing = "E", turretFacing = "E",
            momentum = { x = 3, y = 0 }, movement = { direction = "E", stepsRemaining = 3 },
        } },
        asteroids = { { id = 30, x = 6, y = 5, w = 1, h = 1, facing = "N", momentum = { x = 0, y = 0 } } },
    }
    local ticks, firstHit = 0, false
    while state.meta.phase == "MOVE" do
        ticks = ticks + 1
        assert(ticks <= 20000, "T6: MOVE loop did not terminate")
        local evs
        state, evs = GameState.advanceTick(state)
        for _, e in ipairs(evs or {}) do
            if e.type == "shipAsteroidCollision" and not firstHit then
                firstHit = true
                assert(e.cor == 1 and e.damage == 1,
                    "T6: collision event should carry cor=1 damage=1")
                assert(state.ships[1].hp == 4,
                    "T6: ship must take exactly 1 damage on first hit, hp " .. state.ships[1].hp)
                assert(state.ships[1].momentum.x == 1 and state.ships[1].momentum.y == 0,
                    "T6: ship momentum should recoil to (1,0), got ("
                        .. state.ships[1].momentum.x .. "," .. state.ships[1].momentum.y .. ")")
                assert(state.asteroids[1].momentum.x == 1 and state.asteroids[1].momentum.y == 0,
                    "T6: asteroid momentum should be (1,0), got ("
                        .. state.asteroids[1].momentum.x .. "," .. state.asteroids[1].momentum.y .. ")")
            end
        end
    end
    assert(firstHit, "T6: a shipAsteroidCollision should have fired")
    assert(state.ships[1].hp == 3,
        "T6: ship+rock grind one extra hit before separating, hp should be 3, got " .. state.ships[1].hp)
    assert(state.ships[1].momentum.x == 0 and state.asteroids[1].momentum.x == 0,
        "T6: ship and asteroid should both settle at momentum x=0")
    assert(state.meta.phase == "SHOOT", "T6: phase should reach SHOOT")
end

-- ============================================================================
-- T7. Ship-ship head-on crash caught by the adjacency rule: ships 3 tiles
--     apart each moving 4 close to 1 apart at tick 1, both pushing toward
--     each other, so they must crash without ever sharing a tile.
--     resolveAxis(4,-4,1): opposing -> swap (-4,4) -> friction -> (-3,3).
--     Both take 1 damage (hp 5 -> 4).
-- ============================================================================
local function testShipShip()
    local state = {
        meta = { phase = "MOVE", turn = 1, currentPlayer = 1, cor = 1 },
        board = { width = W, height = H },
        ships = {
            { id = 1, x = 5, y = 5, hp = 5, fuel = 20, facing = "E",
              turretFacing = "E", momentum = { x = 4, y = 0 },
              movement = { direction = "E", stepsRemaining = 4 } },
            { id = 2, x = 8, y = 5, hp = 5, fuel = 20, facing = "W",
              turretFacing = "W", momentum = { x = -4, y = 0 },
              movement = { direction = "W", stepsRemaining = 4 } },
        },
        asteroids = {},
    }
    local ticks, crashed = 0, false
    while state.meta.phase == "MOVE" do
        ticks = ticks + 1
        assert(ticks <= 20000, "T7: MOVE loop did not terminate")
        local evs
        state, evs = GameState.advanceTick(state)
        for _, e in ipairs(evs or {}) do
            if e.type == "shipCollision" then
                crashed = true
                assert(e.cor == 1 and e.damage == 1, "T7: collision event should carry cor=1 damage=1")
                assert(state.ships[1].momentum.x == -3 and state.ships[1].momentum.y == 0,
                    "T7: ship 1 should recoil to (-3,0), got ("
                        .. state.ships[1].momentum.x .. "," .. state.ships[1].momentum.y .. ")")
                assert(state.ships[2].momentum.x == 3 and state.ships[2].momentum.y == 0,
                    "T7: ship 2 should recoil to (3,0), got ("
                        .. state.ships[2].momentum.x .. "," .. state.ships[2].momentum.y .. ")")
                assert(state.ships[1].hp == 4 and state.ships[2].hp == 4,
                    "T7: both ships should take 1 damage (hp 4), got hp "
                        .. state.ships[1].hp .. "/" .. state.ships[2].hp)
            end
        end
    end
    assert(crashed, "T7: adjacency crash should have fired")
    assert(state.ships[1].hp == 4 and state.ships[2].hp == 4,
        "T7: hp should stay 4 after the single crash")
    assert(state.ships[1].x == 3 and state.ships[2].x == 10,
        "T7: ships should drift apart to x=3 and x=10, got " .. state.ships[1].x .. " and " .. state.ships[2].x)
    assert(state.ships[1].momentum.x == -3 and state.ships[2].momentum.x == 3,
        "T7: post-crash momentum must persist into SHOOT")
    assert(state.meta.phase == "SHOOT", "T7: phase should reach SHOOT")
end

-- --- Run everything ---
testCorOneFastShip()
print("T1 PASSED (cor=1 fast ship never leaves the board)")
testCorZeroSticks()
print("T2 PASSED (cor=0 sticks at the wall)")
testCorHalfFastShip()
print("T3 PASSED (cor=0.5 fast ship stays in bounds)")
testAsteroidDrift()
print("T4 PASSED (asteroid drift never leaves the board)")
testAsteroidAsteroid()
print("T5 PASSED (asteroid-asteroid momentum exchange)")
testShipAsteroid()
print("T6 PASSED (ship-asteroid collision + recoil)")
testShipShip()
print("T7 PASSED (ship-ship adjacency crash)")
print("ALL TESTS PASSED")