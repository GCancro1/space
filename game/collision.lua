-- Pure-Lua collision resolution module. No love.* API, no requires: standalone
-- so it can be tested under plain lua5.1 (see test_collision.lua). Resolves
-- wall bounces and object-to-object collisions using a tunable Coefficient of
-- Restitution (COR) controlling bounciness. COR = 1 (ELASTIC) reproduces the
-- original SPEC.md "Collision Phase" behavior exactly; COR = 0 (INELASTIC)
-- makes colliding objects stick together on head-on impact.
--
-- COR lives in state.meta.cor (state JSON). When absent the module defaults
-- to Collision.DEFAULT_COR = 1, so existing state files behave exactly as
-- before.

local Collision = {}

Collision.ELASTIC = 1
Collision.INELASTIC = 0
Collision.DEFAULT_COR = 1

-- Round half up: math.floor(n + 0.5).
-- @param n number
-- @return number - n rounded to the nearest integer
local function round(n)
    return math.floor(n + 0.5)
end

-- Clamp a COR value to [0, 1]. nil (absent COR) or any non-number (e.g. a
-- malformed JSON string) becomes DEFAULT_COR (1).
-- @param cor number|nil - coefficient of restitution, 0..1
-- @return number - clamped cor in [0, 1]
local function clampCor(cor)
    if type(cor) ~= "number" then
        return Collision.DEFAULT_COR
    elseif cor < 0 then
        return 0
    elseif cor > 1 then
        return 1
    end
    return cor
end

-- Read the COR from a game state. Reads state.meta.cor, defaulting to
-- Collision.DEFAULT_COR (1) when absent or nil, clamped via clampCor.
-- @param state table - game state { meta = { cor = number } }
-- @return number - cor in [0, 1]
local function getCor(state)
    if state and state.meta then
        return clampCor(state.meta.cor)
    end
    return Collision.DEFAULT_COR
end

-- Sign of a number; sign(0) = 0.
-- @param n number
-- @return number - -1, 0 or 1
local function sign(n)
    if n > 0 then
        return 1
    elseif n < 0 then
        return -1
    end
    return 0
end

-- Resolve a wall bounce on one axis of an object's momentum.
-- Formula: m = obj.momentum[axis]; new m = -sign(m) * max(0, round(abs(m) * cor) - 1)
-- sign(0) = 0, so a stuck object stays at 0. At cor = 1 this reproduces the
-- original spec: momentum (4,0) hitting a wall -> (-3,0). Damage is always 1
-- regardless of cor (game rule, unchanged).
-- @param obj table - object with id and momentum { x, y }
-- @param axis string - "x" or "y" (which wall was hit)
-- @param cor number|nil - coefficient of restitution (defaults via clampCor)
-- @param events table|nil - array to append the event to (created when nil)
-- @return table - events array (always non-nil)
local function resolveWallBounce(obj, axis, cor, events)
    cor = clampCor(cor)
    if events == nil then
        events = {}
    end
    local m = obj.momentum[axis]
    obj.momentum[axis] = -sign(m) * math.max(0, round(math.abs(m) * cor) - 1)
    events[#events + 1] = {
        type = "wallBounce",
        objectId = obj.id,
        damage = 1,
        axis = axis,
        cor = cor,
    }
    return events
end

-- Per-axis collision math for two colliding objects. Generalized rule:
--   - Both zero          -> (0, 0)
--   - Opposing vectors   -> head-on: elastic swap at cor = 1 (equal-mass
--     elastic collision), stick (shared average velocity) at cor = 0,
--     interpolated bounce for 0 < cor < 1.
--   - Complementary      -> shared-direction average for ALL cor values
--     (matches old spec "shared direction averages"; at cor = 0 this is
--     identical to the stick result - consistent).
-- Friction (the old spec's "Subtract 1 from momentum") is applied after the
-- formula: each nonzero result is reduced by 1 toward zero, clamped so it
-- never crosses zero (e.g. -1 -> 0). Rounding is applied to formula outputs
-- before friction.
-- @param a1, b1 numbers - momentum component of each object on this axis
-- @param cor number|nil - coefficient of restitution (defaults via clampCor)
-- @return number na, number nb - new momentum components
local function resolveAxis(a1, b1, cor)
    cor = clampCor(cor)
    if a1 == 0 and b1 == 0 then
        return 0, 0
    end
    local na, nb
    if a1 * b1 < 0 then
        if cor == 1 then
            na, nb = b1, a1
        elseif cor == 0 then
            local avg = round((a1 + b1) / 2)
            na, nb = avg, avg
        else
            na = round(((1 + cor) / 2) * b1 + ((1 - cor) / 2) * a1)
            nb = round(((1 + cor) / 2) * a1 + ((1 - cor) / 2) * b1)
        end
    else
        local avg = round((a1 + b1) / 2)
        na, nb = avg, avg
    end
    if na ~= 0 then
        na = na - (na > 0 and 1 or -1)
    end
    if nb ~= 0 then
        nb = nb - (nb > 0 and 1 or -1)
    end
    return na, nb
end

-- Resolve a full collision between two objects (ships and/or asteroids; they
-- share the { id, hp, momentum } structure). Applies resolveAxis to both the
-- x and y momentum components, subtracts damage from both objects' hp, and
-- appends an event (default type 'shipCollision', overridable for
-- ship-asteroid / asteroid-asteroid integration labels). Destroyed objects
-- are NOT removed from any state tables -- that is the game_state integration
-- layer's job. Objects without an hp field (some asteroids) are left untouched.
-- @param a, b tables - colliding objects with id, hp and momentum { x, y }
-- @param cor number|nil - coefficient of restitution (defaults via clampCor)
-- @param events table|nil - array to append the event to (created when nil)
-- @param damage number|nil - damage dealt to both objects (default 1; callers
--        may pass 0 for e.g. asteroid-asteroid)
-- @param eventType string|nil - event type label (default 'shipCollision';
--        game_state passes 'shipAsteroidCollision' / 'asteroidCollision')
-- @return table - events array (always non-nil)
local function resolveObjectCollision(a, b, cor, events, damage, eventType)
    cor = clampCor(cor)
    damage = damage or 1
    if events == nil then
        events = {}
    end
    local ax, bx = resolveAxis(a.momentum.x, b.momentum.x, cor)
    local ay, by = resolveAxis(a.momentum.y, b.momentum.y, cor)
    a.momentum.x, b.momentum.x = ax, bx
    a.momentum.y, b.momentum.y = ay, by
    if a.hp ~= nil then
        a.hp = a.hp - damage
    end
    if b.hp ~= nil then
        b.hp = b.hp - damage
    end
    events[#events + 1] = {
        type = eventType or "shipCollision",
        a = a.id,
        b = b.id,
        damage = damage,
        cor = cor,
    }
    return events
end

Collision.round = round
Collision.clampCor = clampCor
Collision.getCor = getCor
Collision.resolveWallBounce = resolveWallBounce
Collision.resolveAxis = resolveAxis
Collision.resolveObjectCollision = resolveObjectCollision
-- Alias kept for integration familiarity.
Collision.resolveShipCollision = resolveObjectCollision

return Collision