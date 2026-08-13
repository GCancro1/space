# Agent Log — Space Strategy Board Game

> Track what's completed, in progress, and what's next.
> Read this at the start of any new session to pick up where the last agent left off.

---

## Last Updated
2026-08-11 — Visual blockers fixed. State-based architecture planned. SPEC.md updated.

---

## Project Stats
- **~2,655 Lua LOC** across 20+ files
- **Run with:** `cd ~/Projects/space && love .`

---

## Project Structure

```
space/
├── main.lua              # Entry point (restructured with AI/game logic sections)
├── config.lua            # All tunable game values
├── conf.lua              # Love2D window config
├── assets.lua            # Sprite loading + spritesheet slicing
├── test_data.lua         # Test ship data for development
│
├── ai/                   # ALL AI-generated code
│   ├── lib/              # Rendering modules
│   │   ├── board.lua         # Grid rendering, coordinate math
│   │   ├── ship.lua          # Ship body + turret rendering (procedural)
│   │   ├── asteroid.lua      # Asteroid rendering (sprite-based + fallback)
│   │   ├── ship_panel.lua    # Info bar: compass dials, HP/fuel bars
│   │   ├── sidebar.lua       # Right sidebar UI (action cards, ship info)
│   │   ├── particles.lua     # Thruster + explosion particle systems
│   │   ├── movement_animator.lua # Step-by-step ship movement animation
│   │   └── tween_group.lua   # Tween group management (unused)
│   └── vendor/           # Third-party libraries
│       ├── class.lua         # Base class (extend/new/init)
│       ├── flux.lua          # Tweening library
│       ├── anim8.lua         # Animation library (unused)
│       ├── suit/             # UI framework
│       └── moonshine/        # Post-processing (vignette)
│
├── game/                 # User's game logic (EMPTY - user writes this)
│
├── SPEC.md               # Game design spec
├── TODO.md               # Prioritized task list
├── AGENT_LOG.md          # This file
└── LOVE2D_REF.md         # Love2D API cheat sheet
```

---

## File Map

| File | Lines | Purpose |
|------|-------|---------|
| `main.lua` | 266 | Entry point, restructured with clear AI/game logic sections |
| `config.lua` | 97 | All tunable game values |
| `conf.lua` | 9 | Love2D window config |
| `assets.lua` | 70 | Sprite loading + spritesheet slicing |
| `test_data.lua` | 10 | Test ship data for development |
| **ai/lib/** | | **AI-generated rendering modules** |
| `ai/lib/board.lua` | 58 | Grid rendering, coordinate math |
| `ai/lib/ship.lua` | 139 | Ship body + turret rendering (procedural) |
| `ai/lib/asteroid.lua` | 77 | Asteroid rendering (sprite-based + fallback) |
| `ai/lib/ship_panel.lua` | 377 | Info bar: compass dials, HP/fuel bars |
| `ai/lib/sidebar.lua` | 714 | Right sidebar UI (action cards, ship info) |
| `ai/lib/particles.lua` | 75 | Thruster + explosion particle systems |
| `ai/lib/movement_animator.lua` | 137 | Step-by-step ship movement animation |
| `ai/lib/tween_group.lua` | 122 | Tween group management (unused) |
| **ai/vendor/** | | **Third-party libraries** |
| `ai/vendor/class.lua` | 18 | Base class (extend/new/init) |
| `ai/vendor/flux.lua` | 224 | Tweening library |
| `ai/vendor/anim8.lua` | 302 | Animation library (unused) |
| `ai/vendor/suit/` | | UI framework |
| `ai/vendor/moonshine/` | 279 | Post-processing (vignette) |
| **game/** | | **User's game logic (empty for now)** |

---

## Completed Work

### 1. Environment Setup ✅
- [x] Install script: `~/dotfiles/scripts/install_love2d.sh` (love, luarocks, lua51, stylua, luacheck)
- [x] Neovim LSP: lua_ls with Love2D globals + library paths (`blink.lua`)
- [x] Mason: luacheck added (`mason.lua`)
- [x] Formatter: stylua configured (`conform.lua`)

### 2. Boilerplate / Infrastructure ✅
- [x] `conf.lua` — no hardcoded resolution, fullscreen, resizable
- [x] `config.lua` — all game values in one place
- [x] `ai/vendor/class.lua` — base class with extend/new/init
- [x] Responsive layout — detects screen, calculates tile size, handles resize

### 3. Board / Grid ✅
- [x] `ai/lib/board.lua` — 20×20 grid with lines and border
- [x] `screenToGrid(mx, my)` — mouse click → tile coords
- [x] `gridToScreen(gx, gy)` — tile → screen pixel (center)
- [x] `inBounds(gx, gy)` — bounds checking

### 4. Ship Rendering ✅
- [x] `ai/lib/ship.lua` — procedural rendering (NOT sprite-based, for clarity)
- [x] Glow circle (player color, 25% opacity) for visibility
- [x] Solid body circle (player color, 90% opacity)
- [x] White body direction arrow (big, clear triangle)
- [x] Yellow/orange turret circle (offset from body center)
- [x] Grey gun barrel extending from turret
- [x] Player number label
- [x] Facing uses degrees: 0°=N, 45°=NE, 90°=E, etc.
- [x] Body and turret rotate independently

### 5. Ship Spawning ✅
- [x] 4 ships at corners facing center
- [x] Colors: blue (1,1), red (18,18), green (18,1), pink (1,18)
- [x] Extracted to `spawnShips()` helper function

### 6. Asteroid Rendering ✅
- [x] `ai/lib/asteroid.lua` — multi-tile asteroids (w×h in tiles)
- [x] Sprite-based from Lunar Lander pack
- [x] Fallback to brown rectangles if sprites fail
- [x] Extracted to `spawnAsteroids()` helper function

### 7. Info Bar / Ship Panel ✅
- [x] `ai/lib/ship_panel.lua` — 4 panels in bottom bar
- [x] Compass dials: body facing + turret facing
- [x] Momentum compass + text
- [x] HP bar (segmented) + Fuel bar (continuous)

### 8. Visual / Animation Libraries ✅
- [x] `ai/vendor/flux.lua` — tweening
- [x] `ai/vendor/anim8.lua` — animation (loaded but unused)
- [x] `ai/vendor/moonshine/` — vignette effect
- [x] `ai/lib/particles.lua` — thruster + explosion particles
- [x] `ai/lib/movement_animator.lua` — step-by-step movement

### 9. Assets / Sprites ✅
- [x] `assets.lua` — sprite loader with sliceSheet helper
- [x] 200Starships: 844 ship sprites (4 styles)
- [x] Lunar Lander: turrets, guns, asteroids, effects, stars
- [x] Screaming Brain Studios: 32 seamless backgrounds
- [x] Blue nebula + star tiles background

### 10. Directory Restructure ✅
- [x] Moved all AI code from `lib/` to `ai/lib/` and `ai/vendor/`
- [x] Created empty `game/` directory for user's game logic
- [x] Updated all require paths (e.g., `lib.ship` → `ai.lib.ship`)
- [x] Restructured `main.lua` with clear section markers:
  - `═══ AI-GENERATED RENDERING MODULES ═══`
  - `═══ GAME LOGIC MODULES (add your imports here) ═══`
  - `═══ GAME LOGIC INITIALIZATION (add your code here) ═══`
  - `═══ GAME LOGIC UPDATE (add your code here) ═══`
  - `═══ GAME LOGIC INPUT (add your code here) ═══`
  - `═══ GAME LOGIC KEYBOARD (add your code here) ═══`
- [x] Extracted spawning to `spawnShips()` and `spawnAsteroids()` helpers
- [x] Moved test data to `test_data.lua`
- [x] Removed debug print from mousepressed

### 11. Bug Fixes ✅
- [x] Fixed ship.lua font leak — added module-level font cache
- [x] Fixed particles.lua setParticleSize → setSize (invalid API)
- [x] Fixed asteroid.lua fallback centering for multi-tile asteroids
- [x] Fixed moonshine canvas resize in love.resize
- [x] Fixed movementAnimator global leak in main.lua

### 12. State-Based Architecture Planning ✅
- [x] JSON state schema designed (ships, asteroids, movement, meta)
- [x] Action file schema designed (rotation, thrust, turret, shot)
- [x] Phase flow defined: PLAN → CALC → MOVE → SHOOT → END_TURN
- [x] 3-layer architecture: StateIO → GameState → StateRenderer
- [x] 14 test state files created in states/
- [x] 3 action files created in actions/
- [x] rxi/json.lua selected as JSON library (~280 LOC, pure Lua, MIT)
- [x] SPEC.md updated with full state-based architecture docs

---

## NOT Started — Game Logic

> **The user writes game logic in `game/` directory.** Agents handle visuals when asked.
> See `TODO.md` for full prioritized task list.

### Critical for MVP (P0)
- JSON State I/O (`game/state_io.lua`) — load/save JSON via rxi/json.lua
- Game State Logic (`game/game_state.lua`) — pure functions: state → state
- State Renderer (`game/state_renderer.lua`) — reads state, draws everything
- Main loop integration — wire state system into Love2D callbacks
- Movement resolution — step-by-step with wall bounce
- Ship selection + highlight

### Should Have (P1)
- Turret rotation (CALC phase)
- Shot firing (SHOOT phase, line of sight, range check)
- Ship destruction (HP ≤ 0)

### Nice to Have (P2)
- Momentum arrow on board
- Movement direction indicator during MOVE phase
- Damage flash effect
- Shot animation

---

## Game Design Quick Reference

### Turn Flow
```
PLAN → CALC → MOVE → COLLIDE → END_TURN
```

### Config Values
```
Grid: 20×20 | HP: 5 | Fuel: 20 | Turret Range: 5 | Body Rotate: 45°/turn | Fuel Cost: 1/power
```

### Facing (Degrees, 0°=N, Clockwise)
```
N=0  NE=45  E=90  SE=135  S=180  SW=225  W=270  NW=315
```

### Wall Bounce
1. Hit wall → 1 damage
2. Flip momentum perpendicular to wall
3. Subtract 1 from flipped component
4. Continue remaining movement

### State Architecture
```
State (JSON) → Logic (pure functions) → Events → Renderer (draws)
Action files in actions/ → Logic reads during PLAN/CALC → State updated
14 test states in states/ → Press 1-8 to load during testing
```

---

## Notes for Next Agent

- **User writes game logic in `game/` directory.** You handle visuals when asked.
- **Directory structure:** AI code in `ai/`, game logic in `game/`, shared config at root.
- **Import paths:** Use `require("ai.lib.ship")` for AI modules, `require("game.turn")` for game logic.
- **Config values live in `config.lua`.** Never hardcode elsewhere.
- **Ship rendering is procedural** (circles + arrows + turret). Do NOT use sprite images for ships.
- **Asteroids use sprites** from Lunar Lander pack, with fallback.
- **Background:** blue nebula + star tiles.
- **All rendering uses `tileSize`, `offsetX`, `offsetY`** computed at runtime.
- **Facing uses degrees** (0°=N, clockwise). Ships accept facing as string.
- **Run with:** `cd ~/Projects/space && love .`
- **main.lua has section markers** — look for `═══ GAME LOGIC` comments to find where to add game logic.

---

## Asset Sources

| Source | License | What We Got |
|--------|---------|-------------|
| Wisedawn (OpenGameArt) | CC0 | 844 ship sprites |
| Screaming Brain Studios (OpenGameArt) | CC0 | 32 seamless backgrounds |
| Lunar Lander Upload (itch.io) | Free | Turrets, guns, asteroids, effects, stars |
