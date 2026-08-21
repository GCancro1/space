# Space Strategy Board Game — Project Overview

> A turn-based space strategy board game built with Lua/LÖVE2D. This document helps new developers understand the codebase quickly.

---

## What is this project?

A **turn-based space strategy board game** for 4 players (hot-seat). Each player controls ships with:
- **Newtonian momentum** — velocity carries over between turns
- **Body + turret** — independent rotation and firing
- **Fuel economy** — every action costs fuel
- **Collision physics** — wall bounces, ship impacts with configurable restitution

Think: *Space combat meets billiards on a grid.*

---

## Current Status

| Area | Status | Notes |
|------|--------|-------|
| **Rendering** | ✅ Working | Board, ships, asteroids, sidebar, particles, animations |
| **State I/O** | ✅ Working | JSON load/save with 14 test states |
| **Game Logic** | ✅ Working | Full phase machine (PLAN→CALC→MOVE→SHOOT→END_TURN) |
| **Movement** | ✅ Working | 8-direction diagonal stepping, Chebyshev distance |
| **Collision** | ✅ Working | Wall bounce, ship-ship, ship-asteroid, asteroid-asteroid |
| **Combat** | ✅ Working | Turret shots, line-of-sight, damage, ship destruction |
| **Turn System** | ✅ Working | 4-player hot seat with turn advancement |
| **AI Opponent** | ❌ Not started | P3 scope |
| **Multiplayer** | ❌ Not started | P3 scope |
| **UI Polish** | 🟡 Partial | Core UI works, needs visual feedback (damage flash, etc.) |

**What works now:** Load a state → press Space to advance phases → T for single tick → S to save → L to reload → click ships to select.

---

## How to Run It

### Requirements
- **LÖVE 11.4+** (Lua 5.1)

### Quick Start
```bash
# Install LÖVE (Arch)
sudo pacman -S love

# Run the game
love .
```

### Command Line Options
```bash
love . --help              # Show usage
love . --list              # List all example states
love . --example=NAME      # Load example (e.g., chain_collision)
love . states/examples/edge/triple_ship.json  # Load specific file
```

### Controls
| Key | Action |
|-----|--------|
| `Space` | Advance full phase |
| `T` | Advance one tick (MOVE phase) |
| `S` | Save current state |
| `L` | Reload state from file |
| `1-8` | Load test states 1-8 |
| `Tab` | Cycle selected ship |
| `Click` | Select ship at tile |
| `Scroll` | Zoom sidebar |

---

## Key Concepts

### Momentum System (Core Mechanic)
- Ships have a persistent momentum vector `{x, y}` — **no cap**
- Thrust adds to momentum (relative to body facing: Forward/Back/Left/Right)
- Movement = Chebyshev distance `max(|x|, |y|)` in 8 compass directions
- **Ship stops only when momentum reaches {0, 0}**
- High speed = hard to turn, easy to crash

### Turn Phases (Simultaneous Play)
```
PLAN → CALC → MOVE → SHOOT → END_TURN → PLAN (next player)
```
| Phase | What Happens |
|-------|--------------|
| **PLAN** | Players secretly choose: body rotation, thrust, turret rotation, shot |
| **CALC** | Apply rotations, add thrust to momentum, pay fuel, store shots |
| **MOVE** | Step-by-step: all objects move 1 tile/tick, resolve collisions at each step |
| **SHOOT** | Resolve turret shots (range 5, line-of-sight), apply damage |
| **END_TURN** | Advance currentPlayer, wrap to next turn |

### State-Based Architecture (JSON-Driven)
- **Source of truth**: JSON files in `states/` and `actions/`
- **Three pure layers**:
  1. **StateIO** (`game/state_io.lua`) — load/save JSON
  2. **GameState** (`game/game_state.lua`) — pure functions: `state → newState`
  3. **StateRenderer** (`game/state_renderer.lua`) — reads state, draws everything
- **Events** bridge logic ↔ renderer:
  ```lua
  { type = "wallBounce", objectId = 1, damage = 1 }
  { type = "movementStep", from = {x=5,y=10}, to = {x=6,y=10} }
  { type = "shot", shipId = 1, targetId = 2, damage = 3 }
  ```

### Collision Physics (COR)
Coefficient of Restitution in `state.meta.cor`:
- **1.0 (elastic, default)** — full bounce with -1 momentum
- **0.5** — damped bounce
- **0.0 (stick)** — objects lock together, zero momentum

---

## Project Structure

```
space/
├── main.lua              -- Entry point, Love2D callbacks, arg parsing
├── conf.lua              -- Window config (1280x720, resizable)
├── config.lua            -- ALL tunable constants (grid, physics, UI, colors)
├── assets.lua            -- Sprite loading
├── SPEC.md               -- Full design spec (living document)
├── TODO.md               -- Prioritized task list (P0-P3)
├── AGENT_LOG.md          -- Progress tracker
├── STATE.md              -- This file
│
├── game/                 -- GAME LOGIC (you write this)
│   ├── collision.lua     -- Pure collision resolution (COR physics)
│   ├── game_state.lua    -- Phase machine, state transitions
│   ├── state_io.lua      -- JSON load/save (rxi/json.lua)
│   └── state_renderer.lua -- Reads state, draws everything
│
├── ai/                   -- AI-GENERATED RENDERING CODE
│   ├── lib/
│   │   ├── board.lua         -- Grid rendering, coord math
│   │   ├── ship.lua          -- Procedural ship drawing
│   │   ├── asteroid.lua      -- Sprite + fallback rendering
│   │   ├── ship_panel.lua    -- Bottom info bar (compass, HP, fuel)
│   │   ├── sidebar.lua       -- Right sidebar (action cards)
│   │   ├── particles.lua     -- Thruster/explosion effects
│   │   └── movement_animator.lua -- Step animation
│   └── vendor/
│       ├── class.lua         -- Base class
│       ├── flux.lua          -- Tweening
│       ├── json.lua          -- JSON (rxi)
│       ├── suit/             -- UI framework
│       └── moonshine/        -- Post-processing shaders
│
├── states/                 -- JSON state files (14 test states + examples)
│   ├── new_game.json       -- Default start (4 ships, 3 asteroids)
│   ├── wall_bounce_*.json  -- Wall collision tests
│   ├── ship_collision.json -- Head-on ship test
│   └── examples/           -- Phase-by-phase tutorial states
│
├── actions/                -- JSON action files (per player per turn)
│   ├── p1_turn1.json
│   └── p2_turn1.json
│
└── assets/                 -- Sprites (ships, asteroids, effects, backgrounds)
```

---

## Where to Start Reading

### For Understanding the Game Loop
1. **`main.lua`** — Entry point, keyboard controls, state loading
2. **`game/game_state.lua`** — Pure logic: `advancePhase()`, `advanceTick()`
3. **`game/state_renderer.lua`** — How state becomes pixels

### For Understanding Physics
1. **`game/collision.lua`** — Wall bounce, object collision, COR resolution
2. **`config.lua`** — All constants (grid size, fuel costs, rotation limits)

### For Understanding Rendering
1. **`ai/lib/board.lua`** — Grid drawing, screen↔grid conversion
2. **`ai/lib/ship.lua`** — Procedural ship (triangle + turret + thrust)
3. **`ai/lib/movement_animator.lua`** — Step-by-step movement tweening

### For Understanding Data Flow
1. **`states/new_game.json`** — Canonical state schema
2. **`actions/p1_turn1.json`** — Action file schema
3. **`game/state_io.lua`** — JSON load/save implementation

---

## Test States (Good for Debugging)

| File | Phase | Tests |
|------|-------|-------|
| `new_game.json` | PLAN | Default start |
| `wall_bounce_east.json` | PLAN | Right wall hit |
| `corner_bounce.json` | PLAN | Double wall bounce |
| `ship_collision.json` | PLAN | Head-on ship collision |
| `diagonal_movement.json` | PLAN | 8-direction diagonal stepping |
| `asteroid_drift.json` | PLAN | Asteroids with momentum |
| `mid_move.json` | MOVE | Mid-movement state |
| `calc_applied.json` | CALC | Post-thrust/rotation |
| `shoot_phase.json` | SHOOT | Shots resolved |
| `end_turn.json` | END_TURN | Turn advancement |

Run with: `love . states/wall_bounce_east.json`

---

## Development Workflow

1. **Edit game logic** in `game/` (pure Lua, no Love2D calls)
2. **Test with states** — load specific JSON files
3. **Add test states** to `states/` for new scenarios
4. **Run** `love .` and use Space/T to step through
5. **Visuals** — ask agents to update `ai/lib/` rendering code

---

## Philosophy

- **Decouple rendering from logic** — `Ship:applyThrust()` only changes data; `Ship:draw()` only renders
- **Config in `config.lua`** — never hardcode magic numbers
- **Board owns coordinate math** — `screenToGrid()` / `gridToScreen()` live on Board
- **Movement is step-by-step** — true 8-direction diagonal, check collisions per tile
- **AI code in `ai/`, game logic in `game/`** — don't mix them
- **JSON is the source of truth** — state lives in files, logic reads/writes JSON

---

## Next Steps for Contributors

1. Read `SPEC.md` for full design details
2. Check `TODO.md` for P0 tasks (currently all done for MVP)
3. Load `states/examples/01_plan.json` through `05_end_turn.json` to see phase flow
4. Try the edge cases in `states/examples/edge/`

Welcome to the project! 🚀