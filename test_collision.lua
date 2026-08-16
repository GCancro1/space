-- Plain-Lua test suite for game/collision.lua. No love required.
-- Run with: lua5.1 test_collision.lua  (prints "ALL TESTS PASSED" on success)

package.path = "./?.lua;./?/init.lua;" .. package.path

local Collision = require("game.collision")

-- --- Constants ---
assert(Collision.ELASTIC == 1, "ELASTIC should be 1")
assert(Collision.INELASTIC == 0, "INELASTIC should be 0")
assert(Collision.DEFAULT_COR == 1, "DEFAULT_COR should be 1")

-- --- round ---
assert(Collision.round(2.5) == 3, "round(2.5) should be 3")
assert(Collision.round(0.5) == 1, "round(0.5) should be 1")
assert(Collision.round(4 * 0.5) == 2, "round(4*0.5) should be 2")

-- --- clampCor / getCor ---
assert(Collision.clampCor(nil) == 1, "clampCor(nil) should default to 1")
assert(Collision.clampCor(2) == 1, "clampCor(2) should clamp to 1")
assert(Collision.clampCor(-1) == 0, "clampCor(-1) should clamp to 0")
assert(Collision.clampCor(0.7) == 0.7, "clampCor(0.7) should stay 0.7")
assert(Collision.clampCor(0) == 0, "clampCor(0) should stay 0")
assert(Collision.getCor({}) == 1, "getCor with no meta should default to 1")
assert(Collision.getCor({ meta = {} }) == 1, "getCor with empty meta should default to 1")
assert(Collision.getCor({ meta = { cor = 0 } }) == 0, "getCor cor=0 should return 0")
assert(Collision.getCor({ meta = { cor = 0.7 } }) == 0.7, "getCor cor=0.7 should return 0.7")
assert(Collision.getCor({ meta = { cor = 3 } }) == 1, "getCor cor=3 should clamp to 1")
assert(Collision.clampCor("0.5") == 1, "clampCor with a string should default to 1")
assert(Collision.getCor({ meta = { cor = "0.5" } }) == 1, "getCor with a string cor should default to 1")

-- --- resolveAxis (pure per-axis math) ---
local na, nb

na, nb = Collision.resolveAxis(0, 0, 1)
assert(na == 0 and nb == 0, "resolveAxis(0,0,1) should be (0,0)")

na, nb = Collision.resolveAxis(0, -4, 1)
assert(na == -1 and nb == -1, "resolveAxis(0,-4,1) should be (-1,-1) (complementary avg -2, friction -> -1,-1)")

na, nb = Collision.resolveAxis(4, -4, 1)
assert(na == -3 and nb == 3, "resolveAxis(4,-4,1) head-on elastic should be (-3,3)")

na, nb = Collision.resolveAxis(4, -4, 0)
assert(na == 0 and nb == 0, "resolveAxis(4,-4,0) head-on stick should be (0,0)")

na, nb = Collision.resolveAxis(4, -4, 0.5)
assert(na == -1 and nb == 1, "resolveAxis(4,-4,0.5) should be (-1,1)")

na, nb = Collision.resolveAxis(6, -2, 1)
assert(na == -1 and nb == 5, "resolveAxis(6,-2,1) asymmetric swap should be (-1,5)")

na, nb = Collision.resolveAxis(4, 2, 1)
assert(na == 2 and nb == 2, "resolveAxis(4,2,1) complementary should be (2,2)")

na, nb = Collision.resolveAxis(2, -2, 1)
assert(na == -1 and nb == 1, "resolveAxis(2,-2,1) should be (-1,1)")

na, nb = Collision.resolveAxis(4, -4, nil)
assert(na == -3 and nb == 3, "resolveAxis with nil cor should default to elastic (-3,3)")

-- --- resolveWallBounce ---
local obj, evs, e

obj = { id = "w1", momentum = { x = 4, y = 7 } }
evs = Collision.resolveWallBounce(obj, "x", 1)
assert(obj.momentum.x == -3, "wall cor=1: x 4 -> -3, got " .. obj.momentum.x)
assert(obj.momentum.y == 7, "wall: non-hit axis must be unchanged")
e = evs[1]
assert(e and e.type == "wallBounce" and e.objectId == "w1" and e.damage == 1 and e.axis == "x" and e.cor == 1,
    "wallBounce event should carry objectId/axis/cor/damage=1")

obj = { id = "w2", momentum = { x = 4, y = 0 } }
Collision.resolveWallBounce(obj, "x", 0)
assert(obj.momentum.x == 0, "wall cor=0: x 4 -> 0 (sticks), got " .. obj.momentum.x)

obj = { id = "w3", momentum = { x = 4, y = 0 } }
Collision.resolveWallBounce(obj, "x", 0.5)
assert(obj.momentum.x == -1, "wall cor=0.5: x 4 -> -1, got " .. obj.momentum.x)

obj = { id = "w4", momentum = { x = 1, y = 0 } }
Collision.resolveWallBounce(obj, "x", 1)
assert(obj.momentum.x == 0, "wall cor=1: x 1 -> 0 (weak bounce dies), got " .. obj.momentum.x)

obj = { id = "w5", momentum = { x = 2, y = 0 } }
Collision.resolveWallBounce(obj, "x", 0.5)
assert(obj.momentum.x == 0, "wall cor=0.5: x 2 -> 0, got " .. obj.momentum.x)

obj = { id = "w6", momentum = { x = 0, y = 3 } }
Collision.resolveWallBounce(obj, "y", 0)
assert(obj.momentum.y == 0, "wall Y cor=0: y 3 -> 0, got " .. obj.momentum.y)

obj = { id = "w7", momentum = { x = 0, y = 4 } }
Collision.resolveWallBounce(obj, "y", 0.5)
assert(obj.momentum.y == -1, "wall Y cor=0.5: y 4 -> -1, got " .. obj.momentum.y)

obj = { id = "w8", momentum = { x = 0, y = -4 } }
Collision.resolveWallBounce(obj, "y", 1)
assert(obj.momentum.y == 3, "wall Y cor=1: y -4 -> 3, got " .. obj.momentum.y)

evs = {}
local ret = Collision.resolveWallBounce(obj, "x", 1, evs)
assert(ret == evs and #evs == 1, "wallBounce should append to a provided events table and return it")

-- --- resolveObjectCollision / resolveShipCollision ---
local a, b

-- Ship head-on, cor 1 (elastic): (4,0) vs (-4,0) -> (-3,0) and (3,0)
a = { id = "a", hp = 5, momentum = { x = 4, y = 0 } }
b = { id = "b", hp = 5, momentum = { x = -4, y = 0 } }
evs = Collision.resolveObjectCollision(a, b, 1)
assert(a.momentum.x == -3 and a.momentum.y == 0,
    "a head-on cor=1 should end (-3,0), got (" .. a.momentum.x .. "," .. a.momentum.y .. ")")
assert(b.momentum.x == 3 and b.momentum.y == 0,
    "b head-on cor=1 should end (3,0), got (" .. b.momentum.x .. "," .. b.momentum.y .. ")")
assert(a.hp == 4 and b.hp == 4, "both objects should take 1 damage (hp 5 -> 4)")
e = evs[1]
assert(e and e.type == "shipCollision" and e.a == "a" and e.b == "b" and e.damage == 1 and e.cor == 1,
    "shipCollision event should carry a/b/damage=1/cor=1")

-- Ship head-on, cor 0 (stick): both stop
a = { id = "a", hp = 5, momentum = { x = 4, y = 0 } }
b = { id = "b", hp = 5, momentum = { x = -4, y = 0 } }
Collision.resolveShipCollision(a, b, 0)
assert(a.momentum.x == 0 and b.momentum.x == 0, "head-on cor=0 should stick at (0,0)")
assert(a.hp == 4 and b.hp == 4, "alias should still deal damage")

-- Ship head-on, cor 0.5: (-1,0) and (1,0)
a = { id = "a", hp = 5, momentum = { x = 4, y = 0 } }
b = { id = "b", hp = 5, momentum = { x = -4, y = 0 } }
Collision.resolveObjectCollision(a, b, 0.5)
assert(a.momentum.x == -1 and b.momentum.x == 1, "head-on cor=0.5 should be (-1,0)/(1,0)")

-- Ship asymmetric head-on, cor 1: swap then friction
a = { id = "a", hp = 5, momentum = { x = 6, y = 0 } }
b = { id = "b", hp = 5, momentum = { x = -2, y = 0 } }
Collision.resolveObjectCollision(a, b, 1)
assert(a.momentum.x == -1 and b.momentum.x == 5, "asymmetric head-on cor=1 should be (-1,0)/(5,0)")

-- Ship complementary, cor 1: avg then friction
a = { id = "a", hp = 5, momentum = { x = 4, y = 0 } }
b = { id = "b", hp = 5, momentum = { x = 2, y = 0 } }
Collision.resolveObjectCollision(a, b, 1)
assert(a.momentum.x == 2 and b.momentum.x == 2, "complementary cor=1 should be (2,0)/(2,0)")

-- Ship Y-axis opposing, cor 1
a = { id = "a", hp = 5, momentum = { x = 0, y = 2 } }
b = { id = "b", hp = 5, momentum = { x = 0, y = -2 } }
Collision.resolveObjectCollision(a, b, 1)
assert(a.momentum.y == -1 and b.momentum.y == 1, "Y-axis opposing cor=1 should be (0,-1)/(0,1)")
assert(a.momentum.x == 0 and b.momentum.x == 0, "Y-axis collision must not touch x momentum")

-- Both axes: a=(3,4) vs b=(-4,-4) cor 1 -> swap both axes, then friction
a = { id = "a", hp = 5, momentum = { x = 3, y = 4 } }
b = { id = "b", hp = 5, momentum = { x = -4, y = -4 } }
Collision.resolveObjectCollision(a, b, 1)
assert(a.momentum.x == -3 and a.momentum.y == -3,
    "dual-axis a should be (-3,-3), got (" .. a.momentum.x .. "," .. a.momentum.y .. ")")
assert(b.momentum.x == 2 and b.momentum.y == 3,
    "dual-axis b should be (2,3), got (" .. b.momentum.x .. "," .. b.momentum.y .. ")")

-- damage = 0 parameter: hp unchanged
a = { id = "a", hp = 5, momentum = { x = 1, y = 0 } }
b = { id = "b", hp = 5, momentum = { x = 1, y = 0 } }
evs = Collision.resolveObjectCollision(a, b, 1, nil, 0)
assert(a.hp == 5 and b.hp == 5, "damage=0 should leave hp unchanged")
assert(evs[1].damage == 0, "event should record damage=0")

-- Objects without hp (asteroid-asteroid): must not error, hp stays nil
a = { id = "rock1", momentum = { x = 1, y = 0 } }
b = { id = "rock2", momentum = { x = 1, y = 0 } }
Collision.resolveObjectCollision(a, b, 1)
assert(a.hp == nil and b.hp == nil, "objects without hp should be left untouched")

-- Ship collision with an asteroid (ship has hp, asteroid does not)
a = { id = "ship", hp = 5, momentum = { x = 2, y = 0 } }
b = { id = "rock", momentum = { x = 2, y = 0 } }
Collision.resolveObjectCollision(a, b, 1)
assert(a.hp == 4, "ship should take damage vs asteroid")
assert(b.hp == nil, "asteroid without hp should be untouched")

-- Provided events table is reused and returned
a = { id = "a", hp = 5, momentum = { x = 1, y = 0 } }
b = { id = "b", hp = 5, momentum = { x = 1, y = 0 } }
evs = {}
ret = Collision.resolveObjectCollision(a, b, 0.7, evs)
assert(ret == evs and #evs == 1, "shipCollision should append to a provided events table and return it")
assert(evs[1].cor == 0.7, "event should record cor=0.7")

-- eventType override: default stays 'shipCollision', custom labels respected
-- and the event keeps the standard { a, b, damage, cor } fields.
a = { id = "shipX", hp = 5, momentum = { x = 2, y = 0 } }
b = { id = "rockX", momentum = { x = 2, y = 0 } }
evs = Collision.resolveObjectCollision(a, b, 1, nil, 1, "shipAsteroidCollision")
e = evs[1]
assert(e and e.type == "shipAsteroidCollision" and e.a == "shipX" and e.b == "rockX"
    and e.damage == 1 and e.cor == 1,
    "eventType override should relabel event but keep a/b/damage/cor")

a = { id = "rock1", momentum = { x = 1, y = 0 } }
b = { id = "rock2", momentum = { x = 1, y = 0 } }
evs = Collision.resolveObjectCollision(a, b, 1, nil, 0, "asteroidCollision")
e = evs[1]
assert(e and e.type == "asteroidCollision" and e.a == "rock1" and e.b == "rock2"
    and e.damage == 0 and e.cor == 1,
    "asteroid-asteroid should carry type 'asteroidCollision' and damage=0")

a = { id = "a", hp = 5, momentum = { x = 2, y = 0 } }
b = { id = "b", hp = 5, momentum = { x = 2, y = 0 } }
evs = Collision.resolveObjectCollision(a, b, 1)
e = evs[1]
assert(e and e.type == "shipCollision", "default eventType should remain 'shipCollision'")

-- resolveShipCollision alias exposes the same eventType parameter
a = { id = "a", hp = 5, momentum = { x = 2, y = 0 } }
b = { id = "b", hp = 5, momentum = { x = 2, y = 0 } }
evs = Collision.resolveShipCollision(a, b, 1, nil, 1, "asteroidCollision")
assert(evs[1].type == "asteroidCollision", "resolveShipCollision alias should pass through eventType")

-- ============================================================================
-- EXHAUSTIVE COR MATRIX: every collision type x COR in {1, 0.5, 0}.
-- Expected values below were hand-derived from the formula in collision.lua
-- (round = floor(n + 0.5); friction subtracts 1 toward zero, skipped at 0)
-- and cross-checked against the module output for the whole sweep.
-- ============================================================================

local matrixAsserts = 0
local function check(cond, msg)
    assert(cond, msg)
    matrixAsserts = matrixAsserts + 1
end

-- --- Wall bounce matrix ---
-- WALL_EXPECTED[ci][m] = new momentum component for input +m with
-- cor = WALL_CORS[ci]; negative m mirrors (m' = -sign(m) * |expected|).
-- Contract (cor=1): m -> -max(0, round(m*cor) - 1), damage always 1.
local WALL_CORS = { 1, 0.5, 0 }
local WALL_EXPECTED = {
    { 0, -1, -2, -3, -4, -5, -6, -7 }, -- cor 1
    { 0, 0, -1, -1, -2, -2, -3, -3 },  -- cor 0.5
    { 0, 0, 0, 0, 0, 0, 0, 0 },        -- cor 0
}
for wi = 1, 3 do
    for m = 1, 8 do
        for _, axis in ipairs({ "x", "y" }) do
            for _, s in ipairs({ 1, -1 }) do
                local other = axis == "x" and "y" or "x"
                obj = { id = "wm" .. m .. axis .. s, momentum = { x = 0, y = 0 } }
                obj.momentum[axis] = s * m
                obj.momentum[other] = 13
                evs = Collision.resolveWallBounce(obj, axis, WALL_CORS[wi])
                local want = s * WALL_EXPECTED[wi][m]
                local msg = string.format("wall (%d via %s, cor=%s) -> %d, got %d",
                    s * m, axis, WALL_CORS[wi], want, obj.momentum[axis])
                check(obj.momentum[axis] == want, msg)
                check(obj.momentum[other] == 13, "wall: non-hit axis must be untouched (cor=" .. WALL_CORS[wi] .. ")")
                e = evs[1]
                check(e and #evs == 1 and e.type == "wallBounce" and e.objectId == obj.id
                    and e.damage == 1 and e.axis == axis and e.cor == WALL_CORS[wi],
                    "wallBounce event should carry objectId/axis/cor/damage=1 (cor=" .. WALL_CORS[wi] .. ")")
            end
        end
    end
end

-- --- resolveAxis matrix ---
-- Row: { a1, b1, cor1={na,nb}, cor0.5={na,nb}, cor0={na,nb} } (friction applied).
-- NOTE (-2,4) cor1: swap -> (4,-2), friction -> (3,-1). The value (1,-3)
-- quoted in the verification brief belongs to pair (-4,2), not (-2,4).
-- Complementary rows (avg then friction) and (0,0) are cor-independent.
local AXIS_EXPECTED = {
    { 4, -4, -3, 3, -1, 1, 0, 0 },
    { 6, -2, -1, 5, 0, 3, 1, 1 },
    { 3, -4, -3, 2, -1, 0, 0, 0 },
    { 2, -2, -1, 1, 0, 0, 0, 0 },
    { 1, -1, 0, 0, 0, 0, 0, 0 },
    { -2, 4, 3, -1, 2, 0, 0, 0 },
    { 4, 2, 2, 2, 2, 2, 2, 2 },
    { 2, 0, 0, 0, 0, 0, 0, 0 },
    { 0, -4, -1, -1, -1, -1, -1, -1 },
    { 4, 0, 1, 1, 1, 1, 1, 1 },
    { 1, 1, 0, 0, 0, 0, 0, 0 },
    { 2, -1, 0, 1, 0, 0, 0, 0 },
    { -1, 2, 1, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 2, 0, 0, 0, 0, 0, 0 },
    { 5, -1, 0, 4, 0, 3, 1, 1 },
}
for _, row in ipairs(AXIS_EXPECTED) do
    for wi = 1, 3 do
        na, nb = Collision.resolveAxis(row[1], row[2], WALL_CORS[wi])
        local ex, ey = row[3 + (wi - 1) * 2], row[4 + (wi - 1) * 2]
        local msg = string.format("resolveAxis(%d,%d,cor=%s) -> (%d,%d), got (%d,%d)",
            row[1], row[2], WALL_CORS[wi], ex, ey, na, nb)
        check(na == ex and nb == ey, msg)
    end
end

-- --- Invariant sweep: all (a1,b1) in -6..6, all 3 cors ---
-- Recomputes the pre-friction formula value (same branches as collision.lua)
-- to check friction only shrinks momentum and never flips signs.
local function preFriction(a1, b1, cor)
    if a1 == 0 and b1 == 0 then
        return 0, 0
    end
    local pna, pnb
    if a1 * b1 < 0 then
        if cor == 1 then
            pna, pnb = b1, a1
        elseif cor == 0 then
            local avg = Collision.round((a1 + b1) / 2)
            pna, pnb = avg, avg
        else
            pna = Collision.round(((1 + cor) / 2) * b1 + ((1 - cor) / 2) * a1)
            pnb = Collision.round(((1 + cor) / 2) * a1 + ((1 - cor) / 2) * b1)
        end
    else
        local avg = Collision.round((a1 + b1) / 2)
        pna, pnb = avg, avg
    end
    return pna, pnb
end

for a1 = -6, 6 do
    for b1 = -6, 6 do
        for wi = 1, 3 do
            local cor = WALL_CORS[wi]
            na, nb = Collision.resolveAxis(a1, b1, cor)
            local pna, pnb = preFriction(a1, b1, cor)
            local M = math.max(math.abs(a1), math.abs(b1))
            local tag = string.format("sweep(%d,%d,cor=%s)", a1, b1, cor)
            check(na == math.floor(na) and nb == math.floor(nb), tag .. ": results must be integers")
            check(math.abs(na) <= M + 1 and math.abs(nb) <= M + 1,
                tag .. ": momentum amplified beyond max(input)+1")
            check(math.abs(pna) <= M and math.abs(pnb) <= M,
                tag .. ": pre-friction value exceeds max(input)")
            check(math.abs(na) <= math.abs(pna) and math.abs(nb) <= math.abs(pnb),
                tag .. ": friction must not grow momentum")
            check((na == 0 or na * pna > 0) and (nb == 0 or nb * pnb > 0),
                tag .. ": friction must never flip a sign")
            check(math.abs((pna + pnb) - (a1 + b1)) <= 1,
                tag .. ": pre-friction sum deviates from a1+b1 by more than 1")
            if cor == 1 and a1 * b1 < 0 then
                check(pna + pnb == a1 + b1, tag .. ": cor=1 opposing swap must conserve momentum exactly")
            end
            check(math.abs((na + nb) - (a1 + b1)) <= 3,
                tag .. ": post-friction sum deviates from a1+b1 by more than 3")
        end
    end
end

-- --- Full dual-axis collisions (both axes nonzero, all 3 cors) ---
-- Each axis must match resolveAxis applied independently; hp damage only
-- applies to objects that have hp (b is an asteroid without hp).
for wi = 1, 3 do
    local cor = WALL_CORS[wi]
    a = { id = "duala" .. wi, hp = 5, momentum = { x = 3, y = -2 } }
    b = { id = "dualb" .. wi, momentum = { x = -4, y = 5 } }
    local ax, bx = Collision.resolveAxis(3, -4, cor)
    local ay, by = Collision.resolveAxis(-2, 5, cor)
    evs = Collision.resolveObjectCollision(a, b, cor)
    local msg = string.format("dual-axis cor=%s: a=(%d,%d) b=(%d,%d)",
        cor, a.momentum.x, a.momentum.y, b.momentum.x, b.momentum.y)
    check(a.momentum.x == ax and a.momentum.y == ay and b.momentum.x == bx and b.momentum.y == by,
        msg .. " must match independent resolveAxis results")
    check(a.hp == 4, "dual-axis cor=" .. cor .. ": hp object should take 1 damage")
    check(b.hp == nil, "dual-axis cor=" .. cor .. ": object without hp must be untouched")
    e = evs[1]
    check(e and e.type == "shipCollision" and e.a == a.id and e.b == b.id and e.damage == 1 and e.cor == cor,
        "shipCollision event should carry a/b/damage=1/cor=" .. cor)
end

print(string.format("EXHAUSTIVE COR MATRIX ASSERTS: %d (wall 288 + axis 48 + sweep 3621 + dual-axis 12)",
    matrixAsserts))
print("ALL TESTS PASSED")