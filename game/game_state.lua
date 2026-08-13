local GameState = {}

-- Deep copy a state table (no shared references)
-- @param state table
-- @return table - deep copy
local function deepCopy(state)
    -- TODO: implement recursive table copy
end

-- Convert compass direction to vector
-- @param dir string - "N", "NE", "E", "SE", "S", "SW", "W", "NW"
-- @return table - {x, y} vector
local function directionToVector(dir)
    -- TODO: implement
    -- N={0,-1}, NE={1,-1}, E={1,0}, SE={1,1}, S={0,1}, SW={-1,1}, W={-1,0}, NW={-1,-1}
end

-- Convert vector to compass direction (for momentum → movement.direction)
-- @param v table - {x, y}
-- @return string - closest compass direction
local function vectorToDirection(v)
    -- TODO: implement
end

-- Check if position is in bounds
-- @param x, y numbers
-- @return boolean
local function inBounds(x, y)
    -- TODO: use Config.GRID_WIDTH/HEIGHT
end

-- Resolve wall bounce for an object
-- @param obj table - ship or asteroid with momentum, x, y
-- @param axis string - "x" or "y" (which wall was hit)
-- @param events table - array to append events to
local function resolveWallBounce(obj, axis, events)
    -- TODO: implement per spec:
    -- 1. Damage = 1
    -- 2. Flip momentum component perpendicular to wall
    -- 3. Subtract 1 from flipped component (in new direction)
    -- 4. Rebuild movement.stepsRemaining from new momentum
    -- 5. Append {type="wallBounce", objectId=obj.id, damage=1, axis=axis} to events
end

-- Resolve ship-to-ship collision
-- @param a, b tables - two ships
-- @param events table - array to append events to
local function resolveShipCollision(a, b, events)
    -- TODO: implement per spec:
    -- 1. Both take 1 damage
    -- 2. Opposing vectors flip, complementary vectors average
    -- 3. Subtract 1 from applicable momentum components
    -- 4. Append {type="shipCollision", a=a.id, b=b.id, damage=1} to events
end

-- ============================================================
-- MAIN PUBLIC FUNCTIONS
-- ============================================================

-- Advance one full phase
-- @param state table - current game state
-- @param actions table - array of action objects from action files
-- @return table - new state
function GameState.advancePhase(state, actions)
    local phase = state.meta.phase
    local newState = deepCopy(state)
    
    if phase == "PLAN" then
        -- TODO: Store pending actions on ships, advance to CALC
        newState.meta.phase = "CALC"
        
    elseif phase == "CALC" then
        -- TODO: Apply rotations, thrust, fuel costs
        -- TODO: Apply turret rotations
        -- TODO: Fire shots (store for SHOOT phase)
        newState.meta.phase = "MOVE"
        
    elseif phase == "MOVE" then
        -- TODO: Run all movement ticks until complete
        -- Loop: call advanceTick internally until all movement done
        -- Then advance to SHOOT
        newState.meta.phase = "SHOOT"
        
    elseif phase == "SHOOT" then
        -- TODO: Resolve all stored shots
        -- TODO: Apply damage, remove destroyed ships
        newState.meta.phase = "END_TURN"
        
    elseif phase == "END_TURN" then
        -- TODO: Advance currentPlayer, increment turn if wrapped
        -- TODO: Reset phase to PLAN
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
    
    -- TODO: For each ship/asteroid with movement:
    -- 1. Get direction vector from movement.direction
    -- 2. Move 1 tile in that direction
    -- 3. Check wall collision
    -- 4. Check ship-ship collision
    -- 5. Check ship-asteroid collision
    -- 6. Decrement movement.stepsRemaining
    -- 7. If stepsRemaining == 0, clear movement
    -- 8. Append {type="movementStep", objectId=..., from={x,y}, to={x,y}, direction=...} to events
    -- 9. If all objects done moving, set phase = "SHOOT"
    
    return newState, events
end

return GameState