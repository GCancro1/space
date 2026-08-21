# Agent Log — Space Strategy Board Game

> Quick-reference status tracker. Read at session start.

---

## Last Updated
2026-08-20 — Concise rewrite. State-based architecture ready for implementation.

---

## Project Stats
- **~2,655 Lua LOC** across 20+ files
- **Run:** `cd ~/Projects/space && love .`

---

## Current Status

| Component | Status | Notes |
|-----------|--------|-------|
| Environment (Love2D, LSP, lint, format) | ✅ Done | `~/dotfiles/scripts/install_love2d.sh` |
| Config / Boilerplate | ✅ Done | `config.lua`, `conf.lua`, responsive layout |
| Board / Grid (20×20, coords, bounds) | ✅ Done | `ai/lib/board.lua` |
| Ship Rendering (procedural, independent body/turret rotation) | ✅ Done | `ai/lib/ship.lua` |
| Ship Spawning (4 corners, facing center) | ✅ Done | `main.lua:spawnShips()` |
| Asteroid Rendering (sprite + fallback) | ✅ Done | `ai/lib/asteroid.lua` |
| Info Bar / Ship Panel (compass, HP, fuel, momentum) | ✅ Done | `ai/lib/ship_panel.lua` |
| Animation Libraries (flux, particles, movement) | ✅ Done | `ai/vendor/flux.lua`, `ai/lib/particles.lua` |
| Assets / Sprites (loaded, sliced, background) | ✅ Done | `assets.lua` |
| Directory Restructure (ai/ + game/) | ✅ Done | AI code isolated, game/ empty for user |
| **State I/O (`game/state_io.lua`)** | ❌ P0 | Load/save JSON via rxi/json.lua |
| **Game State Logic (`game/game_state.lua`)** | ❌ P0 | Pure functions: state → state |
| **State Renderer (`game/state_renderer.lua`)** | ❌ P0 | Reads state, draws everything |
| **Main Loop Integration** | ❌ P0 | Wire state system into Love2D callbacks |
| Movement Resolution (step-by-step, wall bounce) | ❌ P0 | Core physics |
| Ship Selection + Highlight | ❌ P0 | UI interaction |
| Turret Rotation (CALC phase) | ⏳ P1 | |
| Shot Firing (SHOOT phase, LOS, range) | ⏳ P1 | |
| Ship Destruction (HP ≤ 0) | ⏳ P1 | |
| Momentum Arrow on Board | ⏳ P2 | |
| Damage Flash / Shot Animation | ⏳ P2 | |

---

## Key File Map

| File | Purpose |
|------|---------|
| `main.lua` | Entry point with `═══ GAME LOGIC ═══` section markers |
| `config.lua` | All tunable values (grid, HP, fuel, ranges, costs) |
| `assets.lua` | Sprite loader + spritesheet slicing |
| `ai/lib/board.lua` | Grid rendering, screen↔grid coords |
| `ai/lib/ship.lua` | Procedural ship + turret rendering |
| `ai/lib/asteroid.lua` | Multi-tile asteroid rendering |
| `ai/lib/ship_panel.lua` | Bottom info bar (compass, HP, fuel) |
| `ai/lib/sidebar.lua` | Right sidebar (action cards, ship info) |
| `ai/lib/particles.lua` | Thruster + explosion particles |
| `ai/lib/movement_animator.lua` | Step-by-step movement animation |
| `game/` | **Empty — user writes game logic here** |

---

## What's Done vs Next

**✅ Done (Visual Foundation):** Board, ships, asteroids, UI panels, particles, assets, responsive layout, directory split.

**🔴 P0 — MVP Core (Start Here):**
1. `game/state_io.lua` — JSON load/save (rxi/json.lua)
2. `game/game_state.lua` — Pure state transition functions
3. `game/state_renderer.lua` — Draw from state
4. Wire into `main.lua` callbacks (init/update/draw/input)
5. Movement resolution with wall bounce
6. Ship selection + highlight

**🟡 P1 — Combat:** Turret rotation, shot firing (LOS/range), ship destruction.

**🟢 P2 — Polish:** Momentum arrows, damage flash, shot animations.

---

## Turn Flow Reference
```
PLAN → CALC → MOVE → COLLIDE → END_TURN
```
Config: Grid 20×20 | HP 5 | Fuel 20 | Turret Range 5 | Body Rotate 45°/turn | Fuel 1/power
Facing: 0°=N, 45°=NE, 90°=E... clockwise
Wall Bounce: Hit → 1 dmg → flip momentum perp → -1 from flipped → continue