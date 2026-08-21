# Space Strategy Board Game — Design Spec

Living reference for core game rules and architecture. Implementation details live in code.

---

## V1 Scope

**Goal:** 4 players, 4 ships, full turn cycle playable (hot seat). No AI, no UI polish.

| Item | Status |
|------|--------|
| Grid renders | ✅ |
| Ship placement + turrets | ✅ |
| Momentum + thrust + rotation | ✅ |
| 8-direction diagonal movement | ✅ |
| Wall collision + bounce | ✅ |
| Ship-to-ship collision + momentum exchange | ✅ |
| Turret rotation + shot hit detection | ✅ |
| Fuel system (thrust + shots cost fuel) | ✅ |
| HP damage on collision | ✅ |
| Turn state machine (plan → calc → move → collide) | ✅ |

---

## Core Decisions

| Decision | Choice |
|----------|--------|
| Grid | Square (20×20) |
| Players | 4 (hot seat) |
| Turn order | Simultaneous (all plan, then all execute) |
| Momentum | Newtonian, no cap, carries between turns |
| Thrust | 4 cardinal directions relative to body (F/B/L/R) |
| Body rotation | 45° per turn (8 facings) |
| Turret rotation | Independent, unlimited |
| Shot types | Unlimited ammo, push/pull momentum effects |
| Fuel | 1 fuel per power unit (thrust + shots) |
| Position | Hybrid — integer tile coords, rendered centered |
| Collision restitution (COR) | Configurable: 0 (stick), 0.5, 1 (elastic, default) |

---

## Configuration Constants

```lua
GRID_WIDTH = 20
GRID_HEIGHT = 20
TILE_SIZE = 64

SHIP_HP = 5
SHIP_FUEL = 20

BODY_ROTATION_PER_TURN = 1      -- 45° steps
TURRET_ROTATION_UNLIMITED = true
TURRET_RANGE = 5                -- tiles
TURRET_POWER_MAX = 4
TURRET_DAMAGE = 1               -- V1: simple laser

FUEL_COST_THRUST = 1            -- per power unit
FUEL_COST_SHOT = 1              -- per power unit
```

---

## Turn Structure (Simultaneous Play)

```
PLAN → CALC → MOVE → COLLIDE → END_TURN
```

| Phase | Description |
|-------|-------------|
| **PLAN** | Each player secretly chooses: heading (body rotation), thrust (dir + power 0–4), turret facing, shot type (push/pull), shot power (0–4) |
| **CALC** | Apply body rotation → add thrust to momentum (pay fuel) → rotate turret → fire shots (check LOS/range, apply momentum effect to target, pay fuel) |
| **MOVE** | Step through time: all objects move 1 tile in 1 of 8 compass directions per tick. Direction = closest compass to momentum vector. Steps = Chebyshev distance `max(|x|, |y|)`. Check collisions at each step. |
| **COLLIDE** | Resolve wall hits (damage + bounce) and ship-to-ship hits (damage + momentum exchange). Continue remaining movement with new vectors. |
| **END_TURN** | Pass to next player/round |

---

## Momentum System (Core Mechanic)

- **Vector**: `{x, y}` — no cap, persists between turns
- **Stops** completely at `{0, 0}`
- **Thrust** adds to momentum in 1 of 4 relative directions (F/B/L/R) × power
- **Movement**: 8 compass directions (N, NE, E, SE, S, SW, W, NW), stepped tile-by-tile

```
Directions (x, y):
 NW  N  NE    (-1,-1) (0,-1) (1,-1)
  W  ·  E  →  (-1, 0) (0, 0) (1, 0)
 SW  S  SE    (-1, 1) (0, 1) (1, 1)
```

**Example**: Facing SW `(-1,-1)`, momentum `{3,3}` (NE), thrust Forward 4 → thrust vector `(-4,-4)` → new momentum `{-1,-1}` → moves 1 tile SW.

---

## Ship Anatomy

```
      [T]           ← Turret (independent rotation, independent shots)
    ┌─────┐
    │  ◆  │         ← Body (facing: 1 of 8 directions)
    └─────┘
      ↕              ← Thrust (1 of 4 relative: F/B/L/R)
```

- **Body**: position, facing, momentum, HP, fuel
- **Turret**: offset from body, facing, shots available
- Shots unlimited but cost fuel; effects: push, pull, damage

---

## Collision Rules

### Wall Collision
1. Take 1 damage
2. Flip momentum component perpendicular to wall
3. Subtract 1 from flipped component
4. Continue remaining movement with new momentum

### Ship-to-Ship Collision
1. Both take 1 damage
2. **Opposing vectors** (head-on): reverse directions
3. **Complementary vectors** (side-swipe): average per axis
4. Subtract 1 from applicable components
5. Continue remaining movement

### Coefficient of Restitution (COR)
Game setting in `meta.cor` (default 1, range 0–1):

| COR | Wall | Ship-to-Ship (head-on 4 vs -4) |
|-----|------|--------------------------------|
| 1.0 (elastic) | Flip + subtract 1 → -3 | Swap → -3 / 3 |
| 0.5 | Flip ×0.5, floor, subtract 1 → -1 | Interpolated → -1 / 1 |
| 0 (stick) | Zero perpendicular → stop | Average → 0 / 0 (lock together) |

Damage always 1 on wall hits. Ship collisions deal 1 damage each.

---

## Architecture Overview

**State-Based, JSON-Driven**: State is source of truth. Renderer reads state. Logic produces new states.

### Game State Schema (`states/current.json`)
```json
{
  "meta": { "turn": 1, "phase": "PLAN", "currentPlayer": 1, "cor": 1 },
  "board": { "width": 20, "height": 20 },
  "ships": [{
    "id": 1, "x": 1, "y": 1,
    "facing": "NE", "turretFacing": "E",
    "hp": 5, "fuel": 20,
    "momentum": { "x": 0, "y": 0 },
    "movement": null
  }],
  "asteroids": [{
    "id": 1, "x": 9, "y": 9, "w": 1, "h": 1,
    "facing": "N",
    "momentum": { "x": 0, "y": 0 },
    "movement": null
  }]
}
```
- `movement`: `{ "direction": "NE", "stepsRemaining": 3 }` or `null`
- `cor` optional, defaults to 1
- Movement direction independent of body/turret facing
- Ships and asteroids share structure; arrays are dynamic

### Action Schema (`actions/p{player}_turn{N}.json`)
```json
{
  "playerId": 1, "turn": 1, "shipId": 1,
  "rotation": "CW",
  "thrust": { "dir": "F", "power": 3 },
  "turretRotation": "CCW",
  "shot": { "power": 2 }
}
```
All fields except `shipId` optional. One file per player per turn.

### Three-Layer Architecture
| Layer | Module | Responsibility |
|-------|--------|----------------|
| State I/O | `lib/state_io.lua` | JSON load/save (vendored rxi/json.lua) |
| Game Logic | `lib/game_state.lua` | Pure functions: `advancePhase(state, actions) → newState`, `advanceTick(state) → newState, events` |
| Renderer | `lib/state_renderer.lua` | Reads state, draws everything |

**Events** bridge logic and rendering:
```lua
{ type = "wallBounce", objectId = 1, damage = 1, cor = 1 }
{ type = "movementStep", from = {x=5,y=10}, to = {x=6,y=10} }
{ type = "shipCollision", a = 1, b = 2, damage = 1, cor = 1 }
```

### Key Rules
- **Decouple rendering from logic** — logic changes data only; renderer reads only
- **Config in `config.lua`** — no scattered constants
- **Board owns coordinate math** — `screenToGrid`/`gridToScreen`
- **Step-by-step movement** — true 8-direction diagonal (Chebyshev), collisions checked per tile
- **JSON is source of truth** — state lives in JSON files

---

## Grid & Position System

- **Visual only** — grid stores no object data
- **Board** renders lines, knows boundaries (0 to W-1, 0 to H-1)
- **Objects** track own tile position `{x, y}` and momentum `{x, y}`
- **Hybrid storage**: integer tile coords, render centered (`x * TILE_SIZE + TILE_SIZE/2`)

---

## Controls (Dev)

| Key | Action |
|-----|--------|
| Space | Advance full phase |
| T | Advance one tick (MOVE only) |
| S | Save state |
| L | Reload state |
| 1–8 | Load test states |
| Tab | Cycle selected ship |

---

## Project Structure

```
space/
├── main.lua, conf.lua, config.lua, assets.lua
├── ai/lib/           -- AI-generated rendering (Board, Ship, Asteroid, UI, Particles, Anim)
├── game/             -- User-written game logic
│   ├── collision.lua      -- Pure collision resolution (COR)
│   ├── game_state.lua     -- Pure state transitions
│   ├── state_io.lua       -- JSON load/save
│   └── state_renderer.lua -- Draws from state
├── states/           -- JSON state files (14 test states)
├── actions/          -- JSON action files
└── SPEC.md, TODO.md, AGENT_LOG.md
```