local Config = require("config")
local Collision = require("game.collision")

local GameState = {}

-- Recursive deep copy of tables (arrays + maps, keys preserved).
-- Non-table values are returned as-is.
-- @param state any value
-- @return deep copy of the value
local function deepCopy(state)
    if type(state) ~= "table" then
        return state
    end
    local copy = {}
    for k, v in pairs(state) do
        copy[k] = deepCopy(v)
    end
    return copy
end

-- Convert compass direction to vector
-- @param dir string - "N", "NE", "E", "SE", "S", "SW", "W", "NW"
-- @return table - {x, y} vector (fresh copy, nil for unknown input)
local function directionToVector(dir)
    local v = Config.DIRECTIONS[dir]
    if not v then
        return nil
    end
    return { x = v.x, y = v.y }
end

-- Convert vector to compass direction (for momentum → movement.direction)
-- Compares against the 8 unit vectors from Config.DIRECTIONS and returns the
-- one minimizing manhattan distance (best sign-aligned match on both axes;
-- breaks dot-product ties correctly, e.g. {1,0} → E, not NE/SE).
-- @param v table - {x, y}
-- @return string - closest compass direction, nil for a zero vector
local function vectorToDirection(v)
    if not v or (v.x == 0 and v.y == 0) then
        return nil
    end
    local bestDir, bestDist = nil, math.huge
    for dir, d in pairs(Config.DIRECTIONS) do
        local dist = math.abs(v.x - d.x) + math.abs(v.y - d.y)
        if dist < bestDist then
            bestDist = dist
            bestDir = dir
        end
    end
    return bestDir
end

-- Resolve a relative thrust direction ("F"/"B"/"L"/"R") against a facing
-- string into an absolute compass direction. FACING_LIST is ordered clockwise,
-- so R = index + 2, L = index - 2, B = index + 4 (wrapping modulo 8).
-- @param relDir string - "F", "B", "L" or "R"
-- @param facing string - current absolute facing
-- @return string, nil for invalid input
local function resolveThrustDir(relDir, facing)
    local step
    if relDir == "F" then
        step = 0
    elseif relDir == "B" then
        step = 4
    elseif relDir == "R" then
        step = 2
    elseif relDir == "L" then
        step = -2
    else
        return nil
    end
    for i, f in ipairs(Config.FACING_LIST) do
        if f == facing then
            return Config.FACING_LIST[((i - 1 + step) % 8) + 1]
        end
    end
    return nil
end

local DIAGONAL_SCALE = 0.7071

-- Convert a relative thrust (dir + power) into an absolute momentum vector.
-- Cardinal: power straight on one axis. Diagonal: per-axis component rounds
-- power * 0.7071 (power 2 → 1, 3 → 2, 4 → 3). Power-1 diagonal collapses to a
-- single step on the x-axis only (CSV "0/1,1/0" ambiguity; x chosen).
-- @param relDir string - "F", "B", "L" or "R"
-- @param facing string - current absolute facing
-- @param power number - 1..4
-- @return table {x, y} or nil for invalid input
local function thrustToVector(relDir, facing, power)
    local dir = resolveThrustDir(relDir, facing)
    if not dir then
        return nil
    end
    local d = Config.DIRECTIONS[dir]
    if d.x ~= 0 and d.y ~= 0 then
        local comp = power == 1 and 0 or math.floor(power * DIAGONAL_SCALE + 0.5)
        return { x = d.x * (power == 1 and 1 or comp), y = d.y * comp }
    end
    return { x = d.x * power, y = d.y * power }
end

-- Check if position is in bounds
-- @param x, y numbers
-- @return boolean
local function inBounds(x, y)
    return x >= 0 and x < Config.GRID_WIDTH and y >= 0 and y < Config.GRID_HEIGHT
end

-- Sign of a number: -1, 0 or 1
local function sign(n) return n > 0 and 1 or (n < 0 and -1 or 0) end

-- Build a movement entry from a momentum vector. nil if momentum is zero.
local function buildMovement(momentum)
    if momentum.x == 0 and momentum.y == 0 then
        return nil
    end
    return { direction = vectorToDirection(momentum),
             stepsRemaining = math.abs(momentum.x) + math.abs(momentum.y) }
end

-- Single-tile step vector for this tick, X steps first then Y steps.
-- xLeft = stepsRemaining - |momentum.y| tells us if we're still in the X segment.
local function stepVector(obj)
    local m = obj.momentum
    local rem = obj.movement.stepsRemaining
    if rem - math.abs(m.y) > 0 then
        return { x = sign(m.x), y = 0 }
    end
    return { x = 0, y = sign(m.y) }
end

-- Wall bounce via the collision module. The module flips the hit axis and
-- records damage=1 on the event but does NOT touch hp; the integration layer
-- applies the 1-damage to objects that carry hp (asteroids have none). The
-- object's position is hard-clamped into bounds so it can never sit off-board.
-- Movement is fully rebuilt from the new momentum (spec: "continue remaining
-- movement"), so the bounce consumes the tick and the object stays put.
-- @param obj table - ship or asteroid with momentum, x, y
-- @param axis string - "x" or "y" (which wall was hit)
-- @param cor number|nil - coefficient of restitution
-- @param events table - array to append events to
local function handleWallBounce(obj, axis, cor, events)
    Collision.resolveWallBounce(obj, axis, cor, events)
    if obj.hp ~= nil then
        obj.hp = obj.hp - 1
    end
    obj.x = math.max(0, math.min(obj.x, Config.GRID_WIDTH - 1))
    obj.y = math.max(0, math.min(obj.y, Config.GRID_HEIGHT - 1))
    obj.movement = buildMovement(obj.momentum)
end

-- Object-object collision through the collision module. Rebuilds BOTH objects'
-- movement from the new momentum (same full-rebuild design as wall bounces),
-- so a hit object carries its new momentum as a fresh burst — a collision
-- consumes the tick and both objects stay put. This is what lets an asteroid
-- recoil against a ship instead of being static rock.
-- @param a, b tables - colliding objects (ships and/or asteroids)
-- @param cor number|nil - coefficient of restitution
-- @param events table - array to append events to
-- @param damage number|nil - damage dealt to hp-bearing objects (default 1)
-- @param eventType string|nil - event type label (default 'shipCollision')
local function handleObjectCollision(a, b, cor, events, damage, eventType)
    Collision.resolveObjectCollision(a, b, cor, events, damage, eventType)
    a.movement = buildMovement(a.momentum)
    b.movement = buildMovement(b.momentum)
end

-- ============================================================
-- MAIN PUBLIC FUNCTIONS
-- ============================================================

-- Find a ship in state.ships by id. Ships may be stored as an array indexed
-- by id (id == array index) or carry an explicit id field.
local function findShip(state, shipId)
    local ship = state.ships[shipId]
    if ship then
        return ship
    end
    for _, s in ipairs(state.ships) do
        if s.id == shipId then
            return s
        end
    end
    return nil
end

-- Rotate a facing string by a relative turn: "CW" = +1 step (45° clockwise),
-- "CCW" = -1 step, wrapping modulo 8. Returns facing unchanged for nil input.
local function rotateFacing(facing, dir)
    local step = dir == "CW" and 1 or (dir == "CCW" and -1 or nil)
    if step == nil then
        return facing
    end
    for i, f in ipairs(Config.FACING_LIST) do
        if f == facing then
            return Config.FACING_LIST[((i - 1 + step) % 8) + 1]
        end
    end
    return facing
end

-- Advance one full phase
-- @param state table - current game state
-- @param actions table - array of action objects from action files
-- @return table - new state
function GameState.advancePhase(state, actions)
    local phase = state.meta.phase
    local newState = deepCopy(state)

    if phase == "PLAN" then
        -- Store pending actions on ships, advance to CALC.
        -- pendingAction holds the player's plan: thrust (dir+power),
        -- rotation (body turn), turretRotation (turret turn), shot
        -- (turret shoot power). Kept on the ship until CALC resolves it.
        for _, action in ipairs(actions or {}) do
            local ship = findShip(newState, action.shipId)
            if ship then
                ship.pendingAction = deepCopy(action)
            end
        end
        newState.meta.phase = "CALC"

    elseif phase == "CALC" then
        -- Apply rotations, thrust, fuel costs. Shots are NOT resolved here:
        -- they are deferred to the SHOOT phase (pendingShot is stored so
        -- that branch can resolve them later without re-reading action files).
        for _, ship in ipairs(newState.ships) do
            local action = ship.pendingAction
            if action then
                if action.rotation then
                    ship.facing = rotateFacing(ship.facing, action.rotation)
                end
                if action.turretRotation then
                    ship.turretFacing = rotateFacing(ship.turretFacing, action.turretRotation)
                end
                local t = action.thrust
                if t and t.dir and t.power and t.power > 0 then
                    -- Fuel costs FUEL_COST_THRUST per power unit. If fuel is
                    -- insufficient, apply only as much power as fuel allows.
                    local power = math.min(t.power, math.floor(ship.fuel / Config.FUEL_COST_THRUST))
                    if power > 0 then
                        local v = thrustToVector(t.dir, ship.facing, power)
                        ship.momentum.x = ship.momentum.x + v.x
                        ship.momentum.y = ship.momentum.y + v.y
                        ship.fuel = ship.fuel - power * Config.FUEL_COST_THRUST
                    end
                end
                -- Shots are deferred: stash the plan for the SHOOT phase.
                ship.pendingShot = deepCopy(action.shot)
                ship.pendingAction = nil
            end
        end
        -- Pre-build movement for every object carrying momentum (ships that
        -- just thrust AND asteroids that carry drift from PLAN). This runs
        -- exactly once per MOVE phase: advanceTick only consumes steps, so
        -- each object executes ONE burst of its momentum per turn (the
        -- canonical chain: asteroids "finished drift at (11,10)" after a
        -- single E,E,S). Rebuilding on every tick would make objects drift
        -- their momentum repeatedly whenever bursts of different lengths
        -- overlap, which also means extra wall-bounce damage.
        for _, obj in ipairs(newState.ships) do
            if obj.movement == nil and (obj.momentum.x ~= 0 or obj.momentum.y ~= 0) then
                obj.movement = buildMovement(obj.momentum)
            end
        end
        for _, obj in ipairs(newState.asteroids or {}) do
            if obj.movement == nil and (obj.momentum.x ~= 0 or obj.momentum.y ~= 0) then
                obj.movement = buildMovement(obj.momentum)
            end
        end
        newState.meta.phase = "MOVE"

    elseif phase == "MOVE" then
        -- Run all ticks until every object has finished moving.
        -- advanceTick() moves every object one tile and flips the phase to
        -- "SHOOT" as soon as nothing is moving anymore.
        -- Safety cap. Movement always terminates because every tick either
        -- consumes >=1 step or causes >=1 bounce, and each wall bounce reduces
        -- the momentum component by >=1 (COR = 1: M -> M-1 -> M-2 -> ...).
        -- A single burst of length M thus costs sum(M..1) ticks plus one
        -- tick per bounce, which spans thousands of ticks for large M (e.g.
        -- M=60 costs ~1830 ticks), so the cap is set well above that.
        for _ = 1, 100000 do  -- safety cap; movement always terminates
            if newState.meta.phase ~= "MOVE" then
                break
            end
            newState = GameState.advanceTick(newState)
        end
        -- Events from internal ticks are dropped: advancePhase returns
        -- only the state, per its existing signature.

    elseif phase == "SHOOT" then
        -- Resolve shots deferred from CALC (pendingShot on each ship, no
        -- re-reading of action files). Damage equals shot power per the
        -- project plan; TURRET_DAMAGE is not applied for now.
        local events = {}
        -- Walk the turret's line of fire outward from the ship. The first
        -- obstacle in LOS stops the beam: an asteroid absorbs it (solid
        -- rock), the first ship on a tile takes full damage (no penetration).
        local function resolveShot(ship)
            local shot = ship.pendingShot
            if not shot or not shot.power then
                return
            end
            local power = math.min(shot.power, math.floor((ship.fuel or 0) / Config.FUEL_COST_SHOT))
            if power <= 0 then
                return
            end
            ship.fuel = ship.fuel - power * Config.FUEL_COST_SHOT
            local dir = Config.DIRECTIONS[ship.turretFacing]
            if not dir then
                return
            end
            local tx, ty = ship.x, ship.y
            for _ = 1, Config.TURRET_RANGE do
                tx = tx + dir.x
                ty = ty + dir.y
                for _, ast in ipairs(newState.asteroids or {}) do
                    local inside = tx >= ast.x and tx < ast.x + (ast.w or 1)
                               and ty >= ast.y and ty < ast.y + (ast.h or 1)
                    if inside then
                        table.insert(events, { type = "shotBlocked", shipId = ship.id, x = tx, y = ty })
                        return
                    end
                end
                for _, target in ipairs(newState.ships) do
                    if target.id ~= ship.id and target.x == tx and target.y == ty then
                        target.hp = target.hp - power
                        table.insert(events, { type = "shot", shipId = ship.id,
                                               targetId = target.id, x = tx, y = ty, damage = power })
                        return
                    end
                end
            end
        end
        for _, ship in ipairs(newState.ships) do
            resolveShot(ship)
        end
        -- Remove destroyed ships (reverse loop, like advanceTick does).
        -- Shots resolve in a fixed order; survivors keep what hp they have.
        local ships = newState.ships
        for i = #ships, 1, -1 do
            if ships[i].hp and ships[i].hp <= 0 then
                table.insert(events, { type = "shipDestroyed", objectId = ships[i].id,
                                       x = ships[i].x, y = ships[i].y })
                table.remove(ships, i)
            end
        end
        -- Events from the shootout are dropped: advancePhase returns only
        -- the state, per its existing signature.
        newState.meta.phase = "END_TURN"

    elseif phase == "END_TURN" then
        -- Shots were for this turn only
        for _, ship in ipairs(newState.ships) do
            ship.pendingShot = nil
        end
        -- Advance the planning cursor; wrap around to turn N+1 after the last player
        local numPlayers = newState.meta.players or Config.PLAYERS
        newState.meta.currentPlayer = newState.meta.currentPlayer + 1
        if newState.meta.currentPlayer > numPlayers then
            newState.meta.currentPlayer = 1
            newState.meta.turn = newState.meta.turn + 1
        end
        newState.meta.phase = "PLAN"
    end

    return newState
end

-- Advance one tick (MOVE phase only)
-- @param state table - current game state
-- @return table newState, table events
function GameState.advanceTick(state)
    if state.meta.phase ~= "MOVE" then
        return state, {}
    end

    local newState = deepCopy(state)
    local events = {}
    local cor = Collision.getCor(newState)

    -- Movement was pre-built at CALC→MOVE entry (one burst per phase), so
    -- this tick only consumes steps. States loaded directly at MOVE carry
    -- their movement already; stopping is per-object via stepsRemaining.

    -- 2. Lockstep: every moving object steps exactly 1 tile (walls checked
    --    here — a bounce also consumes the tick, so the object stays put).
    for _, obj in ipairs(newState.ships) do
        if obj.movement then
            local step = stepVector(obj)
            local nx, ny = obj.x + step.x, obj.y + step.y
            if not inBounds(nx, ny) then
                -- Diagonal corner out-of-bounds resolves on x first
                -- (wall-bounce worker owns this policy).
                handleWallBounce(obj, step.x ~= 0 and "x" or "y", cor, events)
            else
                local from = { x = obj.x, y = obj.y }
                obj.x, obj.y = nx, ny
                local stepDir = vectorToDirection(step)
                obj.movement.direction = stepDir
                obj.movement.stepsRemaining = obj.movement.stepsRemaining - 1
                if obj.movement.stepsRemaining <= 0 then obj.movement = nil end
                table.insert(events, { type = "movementStep", objectId = obj.id,
                                       from = from, to = { x = nx, y = ny },
                                       direction = stepDir })
            end
        end
    end
    for _, obj in ipairs(newState.asteroids or {}) do
        if obj.movement then
            local step = stepVector(obj)
            local nx, ny = obj.x + step.x, obj.y + step.y
            if not inBounds(nx, ny) then
                -- Diagonal corner out-of-bounds resolves on x first
                -- (wall-bounce worker owns this policy).
                handleWallBounce(obj, step.x ~= 0 and "x" or "y", cor, events)
            else
                local from = { x = obj.x, y = obj.y }
                obj.x, obj.y = nx, ny
                local stepDir = vectorToDirection(step)
                obj.movement.direction = stepDir
                obj.movement.stepsRemaining = obj.movement.stepsRemaining - 1
                if obj.movement.stepsRemaining <= 0 then obj.movement = nil end
                table.insert(events, { type = "movementStep", objectId = obj.id,
                                       from = from, to = { x = nx, y = ny },
                                       direction = stepDir })
            end
        end
    end

    -- pushingToward: momentum on that axis points at the other ship
    local function pushesToward(mover, target, ax)
        local m = mover.momentum[ax]
        local delta = target[ax] - mover[ax]
        return (m > 0 and delta > 0) or (m < 0 and delta < 0)
    end

    -- 3. Ship-ship collisions. A crash happens when two ships either share
    --    a tile OR are adjacent on one axis with at least one pushing into
    --    the other (catches head-on swaps that never occupy the same tile,
    --    e.g. ships 9 tiles apart each moving 4 — they end 1 apart at tick
    --    4 and must crash).
    local ships = newState.ships
    for i = 1, #ships do
        for j = i + 1, #ships do
            local a, b = ships[i], ships[j]
            if not (a.hp and a.hp <= 0 or b.hp and b.hp <= 0) then
                local sameTile = a.x == b.x and a.y == b.y
                local adjacent, axis = false, nil
                if a.x == b.x and math.abs(a.y - b.y) == 1 then
                    adjacent, axis = true, "y"
                elseif a.y == b.y and math.abs(a.x - b.x) == 1 then
                    adjacent, axis = true, "x"
                end
                if sameTile or (adjacent and (pushesToward(a, b, axis) or pushesToward(b, a, axis))) then
                    handleObjectCollision(a, b, cor, events, 1)
                end
            end
        end
    end

    -- 4. Ship-asteroid collisions: a ship whose tile is inside an asteroid's
    --    rect resolves an object collision through the module. The ship takes
    --    1 damage (only objects with hp are damaged), and the asteroid recoils
    --    / swaps momentum per COR — so the rock is no longer static. The
    --    asteroid-rect `inside` check is unchanged.
    for _, ship in ipairs(newState.ships) do
        if ship.hp and ship.hp > 0 then
            for _, ast in ipairs(newState.asteroids or {}) do
                local inside = ship.x >= ast.x and ship.x < ast.x + (ast.w or 1)
                           and ship.y >= ast.y and ship.y < ast.y + (ast.h or 1)
                if inside then
                    handleObjectCollision(ship, ast, cor, events, 1, "shipAsteroidCollision")
                end
            end
        end
    end

    -- 5. Asteroid-asteroid collisions: rect-overlap; rocks grind with no
    --    damage (no hp anyway). Momentum resolves per COR on both axes.
    local asteroids = newState.asteroids
    if asteroids then
        for i = 1, #asteroids do
            for j = i + 1, #asteroids do
                local astA, astB = asteroids[i], asteroids[j]
                local aw, ah = astA.w or 1, astA.h or 1
                local bw, bh = astB.w or 1, astB.h or 1
                local ax1, ay1 = astA.x, astA.y
                local ax2, ay2 = astA.x + aw, astA.y + ah
                local bx1, by1 = astB.x, astB.y
                local bx2, by2 = astB.x + bw, astB.y + bh
                if ax1 < bx2 and bx1 < ax2 and ay1 < by2 and by1 < ay2 then
                    handleObjectCollision(astA, astB, cor, events, 0, "asteroidCollision")
                end
            end
        end
    end

    -- 6. Remove destroyed ships at the END of the tick (after all pair checks).
    for i = #ships, 1, -1 do
        if ships[i].hp and ships[i].hp <= 0 then
            table.insert(events, { type = "shipDestroyed", shipId = ships[i].id,
                                   x = ships[i].x, y = ships[i].y })
            table.remove(ships, i)
        end
    end

    -- 7. If nothing is moving anymore, movement is done → SHOOT phase.
    local anyMoving = false
    for _, obj in ipairs(newState.ships) do
        if obj.movement then anyMoving = true end
    end
    for _, obj in ipairs(newState.asteroids or {}) do
        if obj.movement then anyMoving = true end
    end
    if not anyMoving then
        newState.meta.phase = "SHOOT"
    end

    return newState, events
end

-- Expose helpers for testing under plain Lua (module stays pure; no love.* API)
GameState.deepCopy = deepCopy
GameState.directionToVector = directionToVector
GameState.vectorToDirection = vectorToDirection
GameState.resolveThrustDir = resolveThrustDir
GameState.thrustToVector = thrustToVector

return GameState