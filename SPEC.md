# Space Strategy Board Game — Project Spec

> Living document. Add to this as decisions are made.

---

## V1 Scope

**Goal:** 1 player, 1 ship, full turn cycle playable.
No AI, no opponents, no UI polish — just the core loop working.

### V1 Checklist
- [ ] Empty grid renders on screen
- [ ] Click a tile → prints coordinates
- [ ] Place a ship on a tile → renders it
- [ ] Attach turrets to ship → renders them
- [ ] Implement momentum vector system
- [ ] Body rotation (45° per turn)
- [ ] Thrust (4 cardinal relative to body)
- [ ] Movement resolution (X then Y step-by-step)
- [ ] Wall collision + bounce
- [ ] Ship-to-ship collision + momentum exchange
- [ ] Turret rotation (independent of body)
- [ ] Shot hit detection (line of sight / range)
- [ ] Shot momentum effect on target (push/pull)
- [ ] Fuel system (thrust costs fuel, shots cost fuel)
- [ ] HP damage on collision
- [ ] Turn state machine (plan → calc → move → collide)
- [ ] End turn → next player

---

## Core Decisions

| Decision            | Choice                                              | Status  |
| ------------------- | --------------------------------------------------- | ------- |
| Grid                | Square                                              | Locked  |
| Players             | 4+ (start with 1, expand)                           | Locked  |
| Mode                | Hot seat                                            | Locked  |
| Win conditions      | Multiple (destroy + objectives)                     | Locked  |
| V1 scope            | 1 player, 1 ship, full turn cycle                   | Locked  |
| Momentum system     | Newtonian, no cap, carries over between turns       | Locked  |
| Thrust directions   | 4 cardinal relative to body (F/B/L/R)               | Locked  |
| Body rotation       | 45° per turn                                        | Locked  |
| Turret rotation     | Independent of body, unlimited                      | Locked  |
| Shot types          | Unlimited ammo, different effects                   | Locked  |
| Shot momentum       | Affects TARGET's momentum (push/pull)               | Locked  |
| Fuel model          | 1 fuel per power unit (thrust + shots)              | Locked  |
| Zero momentum       | Ship stops completely                               | Locked  |
| Turn order          | Simultaneous (all players plan, then all execute)   | Locked  |
| Position system     | Hybrid (tile coords, rendered centered)             | Locked  |
| Player planning     | Hidden card selection (TBD)                         | Draft   |
| Health              | TBD                                                 | TBD     |
| Fuel capacity       | TBD                                                 | TBD     |

---

## Configuration

```lua
-- Board
GRID_WIDTH  = 20
GRID_HEIGHT = 20
TILE_SIZE   = 64  -- pixels

-- Ship
SHIP_HP     = 5
SHIP_FUEL   = 20

-- Momentum
-- No cap. Vector {x, y} carries over every turn.
-- Ship stops completely when momentum reaches {0, 0}.

-- Rotation
BODY_ROTATION_PER_TURN = 1  -- 45° steps (1 = 45°)
TURRET_ROTATION_UNLIMITED = true

-- Turret
TURRET_RANGE  = 5  -- tiles
TURRET_POWER_MAX = 4  -- max shot power per turn
TURRET_DAMAGE = 1  -- V1: simple laser, 1 damage

-- Fuel costs
FUEL_COST_THRUST = 1  -- per unit of thrust power
FUEL_COST_SHOT   = 1  -- per unit of shot power

-- V1 Shot
-- Simple laser: 1 damage, no momentum effect
-- Push/pull shots added in future versions
```

---

## Turn Structure (Simultaneous Play)

All players act at the same time. Phases:

### 1. Plan Phase
Each player secretly determines:
- **Heading** — new body facing (45° rotation)
- **Thrust** — direction + power (0-4)
- **Turret turn** — new turret facing
- **Shot type** — push or pull
- **Shot power** — 0-4

Players lock in plans simultaneously (hidden selection).

### 2. Calc Phase
Resolve all calculations:
1. **Turn ship** — apply body rotation to each ship
2. **Apply thrust** — add thrust vector to momentum, pay fuel cost
3. **Turn turret** — apply turret rotation
4. **Fire shots** — check line of sight (range), apply momentum effect to target, pay fuel cost

### 3. Move Phase
For each moment in space-time (step through movement):
- Move all objects **1 tile in X**, then **1 tile in Y**
- Check for collisions at each step
- Repeat until all movement is exhausted

This ensures fair collision detection — no object moves past another in the same tick.

### 4. Collision Phase
For each collision detected:

**Wall collision:**
1. Take 1 damage
2. Flip the momentum component perpendicular to the wall
   - Hit wall at X boundary: `(-momentum.x, momentum.y)`
   - Hit wall at Y boundary: `(momentum.x, -momentum.y)`
3. Subtract 1 from momentum in the flipped direction
4. Continue remaining movement in the new direction

**Ship-to-ship collision:**
1. Take 1 damage
2. **Opposing vectors flip** (head-on: both reverse)
3. **Complementary vectors average** (side swipe: shared direction averages)
4. Subtract 1 from momentum in applicable directions
5. Continue remaining movement

**Example — wall bounce:**
```
Momentum:    (4, 2)
Moves 2 tiles in X, hits wall at X=2
Remaining X movement: 2
New momentum X: -4 (flipped) → -3 (subtract 1)
Ship bounces back 2 tiles with momentum (-3, 2)
```

---

## Momentum System (Core Mechanic)

### How it works
1. Ship has a momentum vector: `{x = 0, y = 0}`
2. Each turn, player chooses **thrust direction** (one of 4, relative to body facing)
3. Thrust is applied to momentum (additive)
4. Ship moves by its new momentum vector
5. Momentum persists to next turn
6. **Ship stops completely when momentum reaches {0, 0}**

### Directions
8 compass directions on the grid:
```
 NW  N  NE        (-1,-1) (0,-1) (1,-1)
  W  ·  E   →     (-1, 0) (0, 0) (1, 0)
 SW  S  SE        (-1, 1) (0, 1) (1, 1)
```

### Thrust (relative to body facing)
Body faces one of 8 directions. Thrust is always one of 4 relative directions:
- **Forward (F)** — push in facing direction
- **Backward (B)** — push opposite to facing
- **Left (L)** — push 90° left of facing
- **Right (R)** — push 90° right of facing

Thrust value is added to the momentum vector for each unit of thrust power.

### Example
```
Ship facing:    SW (-1, -1)
Momentum:       {x=3, y=3}  (moving NE)
Thrust:         Forward, power 4
Thrust vector:  (-4, -4)    (SW direction × 4)
New momentum:   {x=3+(-4), y=3+(-4)} = {x=-1, y=-1}
Ship moves:     1 tile SW
```

### No momentum cap
Ships can reach arbitrarily high speeds. This is intentional — managing momentum is the core challenge. A ship going too fast is hard to turn and easy to crash into asteroids.

---

## Ship Anatomy

```
         [T]        ← Turret (independent rotation, independent shots)
       ┌─────┐
       │  ◆  │      ← Body (has facing: one of 8 directions)
       └─────┘
         ↕          ← Thrust vector (one of 4 relative directions)
```

- **Body**: Has position, facing, momentum, HP, fuel
- **Turret**: Has offset from body, facing, shots available
- **Turret rotates independently** — can aim at enemies while body faces another way
- **Shots are unlimited** but cost fuel. Different effects (push, pull, etc.)

---

## Turn Phases (Detailed)

```
PLAN → CALC → MOVE → COLLIDE → END_TURN
```

| Phase    | What happens                                      |
| -------- | ------------------------------------------------- |
| PLAN     | All players secretly choose heading, thrust, shot |
| CALC     | Apply rotations, thrust, shots, check ranges      |
| MOVE     | Step through movement 1 tile at a time (X then Y)|
| COLLIDE  | Resolve wall/ship hits, damage, momentum bounce   |
| END_TURN | Pass to next round                                |

---

## Architecture

### Project Structure
```
space/
├── main.lua          -- entry + game loop
├── conf.lua          -- window config
├── config.lua        -- all tunable values
├── lib/
│   ├── class.lua     -- base class (metatable boilerplate)
│   ├── board.lua     -- Board class
│   ├── ship.lua      -- Ship class (body + momentum)
│   ├── turret.lua    -- Turret class
│   ├── turn.lua      -- TurnManager class
│   ├── collision.lua -- Collision detection + resolution
│   └── vector.lua    -- Vector math helpers
├── assets/           -- sprites (later)
├── LOVE2D_REF.md     -- Love2D quick reference
└── SPEC.md           -- this file
```

### Class Overview

| Class        | Owns                                                    | Key Methods                                                    |
| ------------ | ------------------------------------------------------- | -------------------------------------------------------------- |
| **Board**        | Grid boundaries, tile size, visual rendering only       | `draw()`, `screenToGrid(mx,my)`, `gridToScreen(gx,gy)`, `inBounds(x,y)` |
| **Ship**         | Position, facing, momentum, HP, fuel, list of turrets   | `draw()`, `applyThrust(dir,power)`, `takeDamage(n)`, `useFuel(n)` |
| **Turret**       | Offset from body, facing, range                         | `draw()`, `canFire(target,lineOfSight)`, `fire(target,type,power)` |
| **TurnManager**  | Current phase, current player, all players' plans       | `nextPhase()`, `isPhase(name)`, `handleClick()`                     |
| **Collision**    | (utility) collision detection + resolution              | `checkWallCollisions()`, `checkShipCollisions()`, `resolve()`      |
| **Vector**       | (utility) vector math                                   | `add(a,b)`, `scale(v,n)`, `flip(v,axis)`, `average(a,b)`          |

### Rules
- **Decouple rendering from logic.** Ship:applyThrust() only changes data. Ship:draw() only renders.
- **Config values go in config.lua**, not scattered through code.
- **Board owns coordinate math.** screenToGrid/gridToScreen live on Board.
- **Movement is step-by-step.** Always X first, then Y. Check collisions at each tile.

### Grid Architecture

The grid is **visual only**. It does not store what's on each tile.

- **Board** — renders grid lines, knows boundaries (0 to GRID_WIDTH-1, 0 to GRID_HEIGHT-1)
- **Ship** — tracks own position `{x, y}` in tile coordinates, own momentum `{x, y}`
- **Turret** — tracks offset from parent ship, own facing

**Position system (hybrid):**
- Store position as integer tile coords: `{x=5, y=12}` = tile (5, 12)
- Render centered on that tile: `x * TILE_SIZE + TILE_SIZE/2`
- Movement logic uses tile math, rendering converts to pixels

**Collision = borders only (V1):**
- No ship-to-ship collisions yet (added in future versions)
- Wall bounce: damage + flip momentum component + subtract 1 + continue
- Movement is step-by-step: resolve X first, then Y

---

## Physical Prototype Notes

This game was prototyped as a physical board game:
- **Cardboard lines** denoted shot ranges (line of sight from turret)
- **Colored dice** planned turns: 1 for thrust, 1 for body turn, 1 for turret turn, 1 for shot power
- **Push/pull** shot types affected target momentum on the board

The digital version preserves these mechanics but adds:
- No manual momentum tracking (computer handles it)
- Collision resolution (too complex for physical)
- Animations for movement and impacts

---

## Future Versions (not V1)

- [ ] 2+ players (hot seat)
- [ ] Multiple ships per player
- [ ] AI opponent
- [ ] Player mat with hidden card selection
- [ ] Asteroids (obstacles)
- [ ] Different turret types / shot effects (push, pull, EMP, mine)
- [ ] Ship upgrades / abilities
- [ ] Multiple board layouts
- [ ] Save/load game
- [ ] Network multiplayer

---

## Open Questions

- [x] Grid architecture → Visual-only grid, hybrid position system (tile coords), wall bounce only
- [x] How much health per ship? → 5 HP
- [x] How much fuel per ship? → 20 fuel
- [ ] Do we want cards / ship configuration system?
- [x] What are all the shot types and their effects? → V1: simple laser (1 damage, no momentum)
- [x] How big should the grid be for 4 players? → 20x20
- [ ] What are the win conditions exactly?
