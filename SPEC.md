# Space Strategy Board Game — Project Spec

> Living document. Add to this as decisions are made.

---

## V1 Scope

**Goal:** 4 players, 4 ships, full turn cycle playable (hot seat).
No AI, no UI polish — just the core loop working.

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
| Collision restitution | COR in meta.cor: 0 (stick) / 0.5 / 1 (elastic, default) | Locked  |
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

## Collision Resolution (COR)

COR (Coefficient of Restitution) is a game setting stored in `state.meta.cor`. Values: `0` (stick) / `0.5` / `1` (elastic, default). Clamped to `[0, 1]`. Read via `Collision.getCor(state)`.

**COR = 1 (elastic, default)** — original behavior:
- Wall: flip perpendicular component + subtract 1 (4 → -3)
- Ship-ship: opposing vectors swap / head-on reverse, complementary average, subtract 1 from each component, 1 damage
- Head-on momentum (4,0) vs (-4,0) → (-3,0) / (3,0)

**COR = 0 (stick):**
- Wall: perpendicular component zeroes — ship stops at wall, still takes 1 damage
- Ship-ship: both take the rounded average per axis → head-on (4,0) vs (-4,0) → (0,0) / (0,0) — objects lock together and travel at the shared velocity

**COR = 0.5 (between):**
- Wall: flip, scale magnitude ×0.5 (rounded), subtract 1, floor at 0 → momentum 4 → -1 (weak bounce); magnitude ≤2 dies out (sticks)
- Ship-ship head-on: interpolated exchange `a' = round(0.75·b + 0.25·a)`, `b' = round(0.75·a + 0.25·b)`, then −1 friction → (4,0) vs (-4,0) → (-1,0) / (1,0)

**Damage:** always 1 on wall hits regardless of COR (game rule unchanged). Ship collisions also deal 1 damage each (callers may pass 0 for e.g. asteroid-asteroid).

**Implementation:** `game/collision.lua` (pure Lua, no `love.*`):
- `resolveWallBounce(obj, axis, cor, events)`
- `resolveObjectCollision(a, b, cor, events, damage)`
- `resolveAxis(a1, b1, cor)`
- `getCor(state)` — `resolveShipCollision` is an alias

Works for ships AND asteroids (shared structure). Integration into game_state.lua is pending.

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

## State-Based Architecture (JSON-Driven)

The game is built around JSON-serialized state files and action files. State is the source of truth. The renderer reads state and draws everything. Logic produces new states.

### Game State Schema (`states/current.json`)

```json
{
  "meta": { "turn": 1, "phase": "PLAN", "currentPlayer": 1, "cor": 1 },
  "board": { "width": 20, "height": 20 },
  "ships": [
    {
      "id": 1, "x": 1, "y": 1,
      "facing": "NE", "turretFacing": "E",
      "hp": 5, "fuel": 20,
      "momentum": { "x": 0, "y": 0 },
      "movement": null
    }
  ],
  "asteroids": [
    {
      "id": 1, "x": 9, "y": 9, "w": 1, "h": 1,
      "facing": "N",
      "momentum": { "x": 0, "y": 0 },
      "movement": null
    }
  ]
}
```

**Key design decisions:**
- `movement` = `{ "direction": "NE", "stepsRemaining": 3 }` or `null` when not moving
- `cor` in `meta` is optional, defaults to 1 (elastic)
- Movement direction is INDEPENDENT of body/turret facing
- Both ships and asteroids have the same structure
- No hardcoded counts — arrays can be any length
- Actions are separate files, not embedded in state

### Action File Schema (`actions/p{player}_turn{N}.json`)

```json
{
  "playerId": 1, "turn": 1, "shipId": 1,
  "rotation": "CW",
  "thrust": { "dir": "F", "power": 3 },
  "turretRotation": "CCW",
  "shot": { "power": 2 }
}
```

All fields except `shipId` can be null. One file per player per turn.

### Phase Flow

```
PLAN → CALC → MOVE → SHOOT → END_TURN
```

| Phase    | What happens                                      |
| -------- | ------------------------------------------------- |
| PLAN     | Players create action files                       |
| CALC     | Load actions, apply rotation/thrust/fuel          |
| MOVE     | Step-by-step: all objects move 1 tile per tick    |
| SHOOT    | Resolve shots after movement complete             |
| END_TURN | Advance currentPlayer, increment turn if needed   |

### Game Loop Architecture (3 Layers)

1. **State I/O** (`lib/state_io.lua`) — JSON load/save via vendored rxi/json.lua
2. **Game Logic** (`lib/game_state.lua`) — pure functions: state → state
   - `GameState.advancePhase(state, actions)` → newState
   - `GameState.advanceTick(state)` → newState, events
3. **Renderer** (`lib/state_renderer.lua`) — reads state, draws everything

Events bridge logic and rendering:
```lua
{ type = "wallBounce", objectId = 1, damage = 1, cor = 1 }
{ type = "movementStep", from = {x=5,y=10}, to = {x=6,y=10} }
{ type = "shipCollision", a = 1, b = 2, damage = 1, cor = 1 }
```

### Key Controls

| Key    | Action                                            |
| ------ | ------------------------------------------------- |
| Space  | Advance full phase                                |
| T      | Advance one tick (MOVE phase only)                |
| S      | Save current state to file                        |
| L      | Reload state from file                            |
| 1-8    | Load test state files                             |
| Tab    | Cycle selected ship                               |

### Project Structure
```
space/
├── main.lua              -- entry + game loop
├── conf.lua              -- window config
├── config.lua            -- all tunable values
├── assets.lua            -- sprite loading
│
├── ai/                   -- AI-generated rendering code
│   ├── lib/
│   │   ├── board.lua         -- Grid rendering, coord math
│   │   ├── ship.lua          -- Ship rendering (procedural)
│   │   ├── asteroid.lua      -- Asteroid rendering (sprite + fallback)
│   │   ├── ship_panel.lua    -- Info bar (compass, HP/fuel)
│   │   ├── sidebar.lua       -- Sidebar UI (action cards)
│   │   ├── particles.lua     -- Particle systems
│   │   └── movement_animator.lua -- Step-by-step animation
│   └── vendor/
│       ├── class.lua         -- Base class
│       ├── flux.lua          -- Tweening library
│       ├── json.lua          -- JSON encode/decode (rxi)
│       ├── suit/             -- UI framework
│       └── moonshine/        -- Post-processing shaders
│
├── game/                 -- Game logic (user writes this)
│   ├── collision.lua     -- Pure collision resolution (COR)
│   ├── game_state.lua    -- Pure logic: state → state
│   ├── state_io.lua      -- JSON load/save
│   └── state_renderer.lua -- Reads state, draws everything
│
├── states/               -- JSON state files
│   ├── new_game.json     -- Default starting state
│   ├── wall_bounce_*.json -- Wall collision tests
│   ├── ship_collision.json -- Ship collision test
│   └── ...               -- 14 test states total
│
├── actions/              -- JSON action files
│   ├── p1_turn1.json     -- Player 1 actions
│   └── p2_turn1.json     -- Player 2 actions
│
├── LOVE2D_REF.md         -- Love2D API cheat sheet
├── SPEC.md               -- This file
├── TODO.md               -- Prioritized task list
└── AGENT_LOG.md          -- Progress tracker
```

### Class Overview

| Class        | Owns                                                    | Key Methods                                                    | Status |
| ------------ | ------------------------------------------------------- | -------------------------------------------------------------- | ------ |
| **Board**        | Grid boundaries, tile size, visual rendering only       | `draw()`, `screenToGrid(mx,my)`, `gridToScreen(gx,gy)`, `inBounds(x,y)` | ✅ Done |
| **Ship**         | Position, facing, momentum, HP, fuel, turret facing    | `draw()`, `moveTo()`, `rotateTo()`, `setFlux()`               | ✅ Done |
| **Asteroid**     | Position, size (w×h tiles), sprite                     | `draw()`, `occupies(gx,gy)`, `moveTo()`                       | ✅ Done |
| **ShipPanel**    | Bottom info bar, compass dials, HP/fuel bars            | `drawAll(ships, y, h, width)`                                 | ✅ Done |
| **Sidebar**      | Right sidebar UI, action cards, player info             | `update()`, `draw()`, `getSelectedAction()`                   | ✅ Done |
| **Particles**    | Thruster + explosion effects                            | `createThruster()`, `createExplosion()`, `update()`, `draw()` | ✅ Done |
| **MovementAnim** | Step-by-step movement animation                         | `startMovement()`, `isDone()`, `update()`                     | ✅ Done |
| **GameState**    | Pure logic: state transitions                           | `advancePhase()`, `advanceTick()`                              | 🔲 Not started |
| **StateIO**      | JSON load/save                                          | `load(path)`, `save(state, path)`                             | 🔲 Not started |
| **StateRenderer**| Reads state, draws everything                           | `draw(state)`, `update(dt)`                                   | 🔲 Not started |

### Rules
- **Decouple rendering from logic.** Ship:applyThrust() only changes data. Ship:draw() only renders.
- **Config values go in config.lua**, not scattered through code.
- **Board owns coordinate math.** screenToGrid/gridToScreen live on Board.
- **Movement is step-by-step.** Always X first, then Y. Check collisions at each tile.
- **AI code in `ai/`, game logic in `game/`.** Don't mix them.
- **JSON is the source of truth.** Game state lives in JSON files. Logic reads/writes JSON.

### Grid Architecture

The grid is **visual only**. It does not store what's on each tile.

- **Board** — renders grid lines, knows boundaries (0 to GRID_WIDTH-1, 0 to GRID_HEIGHT-1)
- **Ship** — tracks own position `{x, y}` in tile coordinates, own momentum `{x, y}`
- **Asteroid** — tracks own position and size, checks tile occupancy

**Position system (hybrid):**
- Store position as integer tile coords: `{x=5, y=12}` = tile (5, 12)
- Render centered on that tile: `x * TILE_SIZE + TILE_SIZE/2`
- Movement logic uses tile math, rendering converts to pixels

**Collision system:**
- Wall bounce: damage + flip momentum + subtract 1 + continue
- Ship-to-ship: both take damage, momentum exchange
- Movement is step-by-step: resolve X first, then Y
- All objects move in lockstep (fair collision detection)

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
- [x] How to separate AI code from game logic? → Directory structure: `ai/` for AI, `game/` for user
- [ ] Do we want cards / ship configuration system?
- [x] What are all the shot types and their effects? → V1: simple laser (1 damage, no momentum)
- [x] How big should the grid be for 4 players? → 20x20
- [ ] What are the win conditions exactly?

---

## Test State Files

14 JSON state files in `states/` for testing:

| File | Phase | Purpose |
|------|-------|---------|
| `new_game.json` | PLAN | Default start, 4 ships, 3 asteroids |
| `wall_bounce_east.json` | PLAN | Ship hitting right wall |
| `wall_bounce_north.json` | PLAN | Ship hitting top wall |
| `corner_bounce.json` | PLAN | Double wall bounce |
| `ship_collision.json` | PLAN | Two ships head-on |
| `diagonal_movement.json` | PLAN | Compass direction stepping |
| `asteroid_drift.json` | PLAN | Asteroids with momentum |
| `low_hp.json` | PLAN | Destruction test (1 HP) |
| `mid_move.json` | MOVE | Mid-movement state |
| `mid_move_bounce.json` | MOVE | Post-bounce mid-move |
| `calc_applied.json` | CALC | Actions resolved |
| `shoot_phase.json` | SHOOT | Shots resolved |
| `end_turn.json` | END_TURN | Turn about to advance |
| `multi_object.json` | PLAN | All objects moving |

3 action files in `actions/`:

| File | Description |
|------|-------------|
| `p1_turn1.json` | Forward thrust 3 |
| `p2_turn1.json` | Backward 2 + CW rotate + CCW turret |
| `p1_turn1_shot.json` | Rotate + thrust + shot power 3 |
