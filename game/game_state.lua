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
             stepsRemaining = math.max(math.abs(momentum.x), math.abs(momentum.y)) }
end

-- Single-tile step vector for this tick (true 8-direction diagonal).
local function stepVector(obj)
    local d = Config.DIRECTIONS[obj.movement.direction]
    if not d then
        return { x = 0, y = 0 }
    end
    return { x = d.x, y = d.y }
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
-- Calculate minimum steps for a point to exit a rectangle along a direction vector.
-- Returns the minimum positive integer steps to exit, or nil if direction never exits.
-- @param px, py number - point position (ship)
-- @param rx, ry, rw, rh number - rectangle bounds (asteroid)
-- @param dx, dy number - step direction vector (-1, 0, or 1 each)
-- @return number|nil - minimum steps to exit, or nil if cannot exit in this direction
local function stepsToExitRect(px, py, rx, ry, rw, rh, dx, dy)
    local candidates = {}
    -- Exit right: px + n*dx >= rx + rw
    if dx > 0 then
        local n = math.ceil((rx + rw - px) / dx)
        if n > 0 then table.insert(candidates, n) end
    -- Exit left: px + n*dx < rx
    elseif dx < 0 then
        local n = math.ceil((px - rx + 1) / -dx)
        if n > 0 then table.insert(candidates, n) end
    end
    -- Exit bottom: py + n*dy >= ry + rh
    if dy > 0 then
        local n = math.ceil((ry + rh - py) / dy)
        if n > 0 then table.insert(candidates, n) end
    -- Exit top: py + n*dy < ry
    elseif dy < 0 then
        local n = math.ceil((py - ry + 1) / -dy)
        if n > 0 then table.insert(candidates, n) end
    end
    if #candidates == 0 then return nil end
    table.sort(candidates)
    return candidates[1]
end

local function handleObjectCollision(a, b, cor, events, damage, eventType)
    Collision.resolveObjectCollision(a, b, cor, events, damage, eventType)
    
    -- Rebuild movement from new momentum
    a.movement = buildMovement(a.momentum)
    b.movement = buildMovement(b.momentum)
    
    -- "Continue remaining movement" - move both objects by their NEW step vectors
    -- This separates them after collision (physics: momentum transferred, both continue)
    -- For ship-ship adjacency collisions (eventType nil or "shipCollision"), the burst
    -- is consumed and movement is cleared UNLESS the collision leaves them overlapping
    -- or still pushing into each other (in which case they grind like asteroids).
    -- For overlap collisions (asteroid-asteroid, ship-asteroid), they continue grinding
    -- so movement is NOT cleared.
    local consumeBurst = (eventType == nil or eventType == "shipCollision")
    
    -- Special handling for ship-asteroid collision: move ship completely out of asteroid
    local isShipAsteroid = (eventType == "shipAsteroidCollision")
    local ship, asteroid
    if isShipAsteroid then
        -- a is ship (has hp), b is asteroid (has w/h)
        if a.hp ~= nil then
            ship, asteroid = a, b
        else
            ship, asteroid = b, a
        end
    end
    
    if a.movement then
        local stepA = stepVector(a)
        local steps = a.movement.stepsRemaining
        if isShipAsteroid and a == ship then
            local aw, ah = asteroid.w or 1, asteroid.h or 1
            local exitSteps = stepsToExitRect(a.x, a.y, asteroid.x, asteroid.y, aw, ah, stepA.x, stepA.y)
            if exitSteps then
                steps = exitSteps
            else
                -- Try opposite direction
                exitSteps = stepsToExitRect(a.x, a.y, asteroid.x, asteroid.y, aw, ah, -stepA.x, -stepA.y)
                if exitSteps then
                    stepA = { x = -stepA.x, y = -stepA.y }
                    steps = exitSteps
                end
            end
        end
        a.x = a.x + stepA.x * steps
        a.y = a.y + stepA.y * steps
    end
    if b.movement then
        local stepB = stepVector(b)
        local steps = b.movement.stepsRemaining
        if isShipAsteroid and b == ship then
            local aw, ah = asteroid.w or 1, asteroid.h or 1
            local exitSteps = stepsToExitRect(b.x, b.y, asteroid.x, asteroid.y, aw, ah, stepB.x, stepB.y)
            if exitSteps then
                steps = exitSteps
            else
                -- Try opposite direction
                exitSteps = stepsToExitRect(b.x, b.y, asteroid.x, asteroid.y, aw, ah, -stepB.x, -stepB.y)
                if exitSteps then
                    stepB = { x = -stepB.x, y = -stepB.y }
                    steps = exitSteps
                end
            end
        end
        b.x = b.x + stepB.x * steps
        b.y = b.y + stepB.y * steps
    end
    
    -- After moving by new burst, check if objects are still colliding (same tile or
    -- adjacent and pushing). If so, don't clear movement - let them grind next tick.
    local stillColliding = false
    if consumeBurst then
        local sameTile = a.x == b.x and a.y == b.y
        local adjacent, axis = false, nil
        if a.x == b.x and math.abs(a.y - b.y) == 1 then
            adjacent, axis = true, "y"
        elseif a.y == b.y and math.abs(a.x - b.x) == 1 then
            adjacent, axis = true, "x"
        end
        local function pushesToward(mover, target, ax)
            local m = mover.momentum[ax]
            local delta = target[ax] - mover[ax]
            return (m > 0 and delta > 0) or (m < 0 and delta < 0)
        end
        if sameTile or (adjacent and (pushesToward(a, b, axis) or pushesToward(b, a, axis))) then
            stillColliding = true
        end
    end
    
    if consumeBurst and not stillColliding then
        if a.movement then a.movement = nil end
        if b.movement then b.movement = nil end
    end
    
    -- Clamp positions to bounds (like wall bounce does)
    local function clampPos(obj)
        obj.x = math.max(0, math.min(obj.x, Config.GRID_WIDTH - 1))
        obj.y = math.max(0, math.min(obj.y, Config.GRID_HEIGHT - 1))
    end
    clampPos(a)
    clampPos(b)
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
    if not newState.meta.eventLog then
        newState.meta.eventLog = {}
    end

    -- If in PLAN phase, first apply actions to ships (store pendingAction)
    if phase == "PLAN" then
        for _, action in ipairs(actions or {}) do
            local ship = findShip(newState, action.shipId)
            if ship then
                ship.pendingAction = deepCopy(action)
            end
        end
    end

    -- Call advanceTick repeatedly until phase changes
    local allEvents = {}
    local initialPhase = newState.meta.phase
    for _ = 1, 100000 do  -- safety cap
        local tickState, tickEvents = GameState.advanceTick(newState)
        newState = tickState
        for _, e in ipairs(tickEvents) do
            table.insert(allEvents, e)
        end
        if newState.meta.phase ~= initialPhase then
            break
        end
    end

    -- Append all events to eventLog
    for _, e in ipairs(allEvents) do
        table.insert(newState.meta.eventLog, e)
    end

    return newState
end

-- Advance one tick (handles ALL phases: PLAN, CALC, MOVE, SHOOT, END_TURN)
-- @param state table - current game state
-- @return table newState, table events
function GameState.advanceTick(state)
    local newState = deepCopy(state)
    if not newState.meta.eventLog then
        newState.meta.eventLog = {}
    end
    local events = {}
    local phase = newState.meta.phase
    local cor = Collision.getCor(newState)

    if phase == "PLAN" then
        -- PLAN → CALC (no actions applied here; actions are stored in advancePhase)
        newState.meta.phase = "CALC"
        table.insert(events, { type = "-- Phase Change to CALC --", phase = "CALC", from = "PLAN" })

    elseif phase == "CALC" then
        -- Apply rotations, thrust, fuel costs. Shots deferred to SHOOT.
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
                    local power = math.min(t.power, math.floor(ship.fuel / Config.FUEL_COST_THRUST))
                    if power > 0 then
                        local v = thrustToVector(t.dir, ship.facing, power)
                        ship.momentum.x = ship.momentum.x + v.x
                        ship.momentum.y = ship.momentum.y + v.y
                        ship.fuel = ship.fuel - power * Config.FUEL_COST_THRUST
                    end
                end
                -- Shots deferred: stash for SHOOT phase
                ship.pendingShot = deepCopy(action.shot)
                ship.pendingAction = nil
            end
        end
        -- Pre-build movement for objects with momentum
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
        table.insert(events, { type = "-- Phase Change to MOVE --", phase = "MOVE", from = "CALC" })

    elseif phase == "MOVE" then
        -- Lockstep: every moving object steps exactly 1 tile
        for _, obj in ipairs(newState.ships) do
            if obj.movement then
                local step = stepVector(obj)
                local nx, ny = obj.x + step.x, obj.y + step.y
                if not inBounds(nx, ny) then
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

        -- pushingToward helper
        local function pushesToward(mover, target, ax)
            local m = mover.momentum[ax]
            local delta = target[ax] - mover[ax]
            return (m > 0 and delta > 0) or (m < 0 and delta < 0)
        end

        -- Ship-ship collisions
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

        -- Ship-asteroid collisions
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

        -- Asteroid-asteroid collisions
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

        -- Remove destroyed ships
        for i = #ships, 1, -1 do
            if ships[i].hp and ships[i].hp <= 0 then
                table.insert(events, { type = "shipDestroyed", shipId = ships[i].id,
                                       x = ships[i].x, y = ships[i].y })
                table.remove(ships, i)
            end
        end

        -- If nothing moving, advance to SHOOT
        local anyMoving = false
        for _, obj in ipairs(newState.ships) do
            if obj.movement then anyMoving = true end
        end
        for _, obj in ipairs(newState.asteroids or {}) do
            if obj.movement then anyMoving = true end
        end
        if not anyMoving then
            newState.meta.phase = "SHOOT"
            table.insert(events, { type = "-- Phase Change to  SHOOT--", phase = "SHOOT", from = "MOVE" })
        end

    elseif phase == "SHOOT" then
        -- Resolve shots deferred from CALC
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
        -- Remove destroyed ships
        local ships = newState.ships
        for i = #ships, 1, -1 do
            if ships[i].hp and ships[i].hp <= 0 then
                table.insert(events, { type = "shipDestroyed", objectId = ships[i].id,
                                       x = ships[i].x, y = ships[i].y })
                table.remove(ships, i)
            end
        end
        newState.meta.phase = "END_TURN"
        table.insert(events, { type = "-- Phase Change to  END_TURN--", phase = "END_TURN", from = "SHOOT" })

    elseif phase == "END_TURN" then
        -- Clear pending shots
        for _, ship in ipairs(newState.ships) do
            ship.pendingShot = nil
        end
        -- Advance player/turn
        local numPlayers = newState.meta.players or Config.PLAYERS
        newState.meta.currentPlayer = newState.meta.currentPlayer + 1
        if newState.meta.currentPlayer > numPlayers then
            newState.meta.currentPlayer = 1
            newState.meta.turn = newState.meta.turn + 1
        end
        newState.meta.phase = "PLAN"
        table.insert(events, { type = "-- Phase Change to  PLAN--", phase = "PLAN", from = "END_TURN" })
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
