# Agent Log — Space Strategy Board Game

> This file tracks what has been completed, what's in progress, and what's next.
> Read this at the start of any new session to pick up where the last agent left off.

---

## Last Updated
Session ended after: info bar redesign — single momentum compass, horizontal layout

---

## Environment Setup

### Install Script
- **File:** `~/dotfiles/scripts/install_love2d.sh`
- **Status:** Complete
- **Installs:** `love`, `luarocks`, `lua51`, `stylua`, `luacheck` (via pacman)
- **Note:** `lua-language-server` is managed by Mason in Neovim, not pacman

### Neovim Config Changes
- **`~/.config/nvim/lua/plugins/blink.lua`** — Updated lua_ls config with Love2D support:
  - Auto-detects Love2D install path (`/usr/share/love`, `/usr/lib/love`, `/usr/local/share/love`)
  - Added `love` to diagnostics globals
  - Added Love2D library to workspace for autocomplete
- **`~/.config/nvim/lua/plugins/mason.lua`** — Added `luacheck` to `ensure_installed`
- **Formatter:** `stylua` already configured in `conform.lua` for lua filetype
- **LSP:** `lua_ls` configured with Love2D globals + library paths

### Reference Docs
- **`/home/g/Projects/space/LOVE2D_REF.md`** — Love2D API cheat sheet (callbacks, graphics, input, coordinate math)
- **`/home/g/Projects/space/SPEC.md`** — Full game design spec (mechanics, classes, turn flow, config values)
- **`/home/g/Projects/space/AGENT_LOG.md`** — This file

---

## Project Structure

```
space/
├── main.lua              -- entry point, game loop, spawns ships/asteroids
├── conf.lua              -- window config (no hardcoded size, resizable)
├── config.lua            -- all game values (grid, ship, turret, colors, directions)
├── lib/
│   ├── class.lua         -- base class (extend, new, init)
│   ├── board.lua         -- grid rendering, coordinate math, bounds checking
│   ├── ship.lua          -- ship body + turret rendering (independent rotation)
│   ├── asteroid.lua      -- asteroid rendering (multi-tile, crack details)
│   └── ship_panel.lua    -- info bar: compass dials, HP/fuel bars, momentum display
├── LOVE2D_REF.md         -- API reference
├── SPEC.md               -- game design spec
└── AGENT_LOG.md          -- this file
```

---

## Completed Work

### 1. Boilerplate / Infrastructure ✅
- [x] Created `conf.lua` — no hardcoded resolution, fullscreen on launch
- [x] Created `config.lua` — all tunable values in one place
- [x] Created `lib/class.lua` — base class with extend/new/init
- [x] Created `main.lua` — entry point with love.load/draw/mousepressed/keypressed
- [x] Responsive layout — detects screen size, calculates tile size, handles resize

### 2. Board / Grid ✅
- [x] Created `lib/board.lua`
- [x] Draws 20×20 grid with lines and border
- [x] `screenToGrid(mx, my)` — converts mouse click to tile coords
- [x] `gridToScreen(gx, gy)` — converts tile to screen pixel (center of tile)
- [x] `inBounds(gx, gy)` — checks if tile is inside grid
- [x] Grid centers horizontally, info bar at bottom

### 3. Ship Rendering ✅
- [x] Created `lib/ship.lua`
- [x] Body: colored circle (sphere) + arrow triangle showing facing direction
- [x] Turret: yellow circle (sphere) + grey rectangle (gun barrel)
- [x] Body and turret rotate independently
- [x] Arrow color matches ship color (lighter tint)
- [x] Facing uses simplified degrees: 0°=N, 45°=NE, 90°=E, etc.
- [x] `toRad()` converts game degrees to Love2D radians internally
- [x] Sizes scale with tile size (body=30%, turret=15%)

### 4. Ship Spawning ✅
- [x] 4 ships spawned at corners
- [x] Each faces toward center of grid
- [x] Player colors: blue (1,1), red (18,18), green (18,1), pink (1,18)

### 5. Asteroid Rendering ✅
- [x] Created `lib/asteroid.lua`
- [x] Multi-tile asteroids (w × h in tiles)
- [x] Rocky brown fill with darker edge, crack-line highlights
- [x] 5 test asteroids placed in center area:
  - 1×1 at (9,9)
  - 2×1 at (11,8)
  - 2×2 at (8,11)
  - 3×1 at (10,10)
  - 3×3 at (13,11)
- [x] Asteroids render behind ships

### 6. Info Bar / Ship Panel ✅
- [x] Created `lib/ship_panel.lua`
- [x] Draws 4 panels (one per ship) in bottom bar, divided by vertical lines
- [x] INFO_BAR_HEIGHT set to 280px in config.lua
- [x] Font: 42px (3x default) for all info bar text, with save/restore
- [x] Each panel has a **horizontal layout**: compass on left, stats on right
- [x] **Single momentum compass** (radius 80px) on left side of each panel
  - Arrow length: radius * 0.8, half-width: radius * 0.15
  - Arrow color matches ship color
  - Cardinal tick marks (longer) + diagonal tick marks (shorter)
  - N/S/E/W labels outside the compass
  - Center dot when momentum is zero
- [x] **Momentum text** above HP/fuel, shows N/S/E/W components (e.g. "N1 E1")
- [x] **HP bar** — segmented (5 segments), filled = ship color, empty = dim outline
- [x] **Fuel bar** — proportional fill, width clamped to fit column
- [x] All colors match PLAYER_COLORS (blue, red, green, pink)
- [x] Vertical divider lines between ship panels
- [x] Test values: all 4 ships have varied HP, fuel, and momentum

---

## Game Design (from SPEC.md)

### Core Mechanics
- **Momentum system:** Newtonian, no cap, carries over between turns
- **Thrust:** 4 cardinal directions relative to body (F/B/L/R)
- **Body rotation:** 45° per turn
- **Turret rotation:** Independent of body, unlimited
- **Shots:** Unlimited ammo, different effects (V1: simple laser, 1 damage)
- **Fuel:** 1 fuel per power unit (thrust + shots)
- **Zero momentum:** Ship stops completely

### Turn Flow (Simultaneous)
```
PLAN → CALC → MOVE → COLLIDE → END_TURN
```

1. **PLAN** — All players secretly choose heading, thrust, shot
2. **CALC** — Apply rotations, thrust, shots, check ranges
3. **MOVE** — Step through movement 1 tile at a time (X then Y)
4. **COLLIDE** — Resolve wall/ship hits, damage, momentum bounce
5. **END_TURN** — Pass to next round

### V1 Config Values
```
Grid:        20×20
Ship HP:     5
Ship Fuel:   20
Turret Range: 5 tiles
Turret Power: 0-4
Body Rotate: 45°/turn
Fuel Cost:   1 per power unit
```

### Wall Bounce Rules
1. Hit wall → 1 damage
2. Flip momentum component perpendicular to wall
3. Subtract 1 from flipped component
4. Continue remaining movement in new direction

---

## NOT Started / TODO

### Game Logic (user handles)
- [ ] Turn state machine (SELECT_PIECE → MOVE → SHOOT → END_TURN)
- [ ] Click to select a ship
- [ ] Body rotation (45° per turn, keyboard or click)
- [ ] Thrust application (F/B/L/R relative to facing)
- [ ] Momentum movement resolution
- [ ] Wall collision + bounce
- [ ] Turret rotation (independent)
- [ ] Shot firing + range check
- [ ] Shot damage to target
- [ ] Fuel cost deduction
- [ ] HP damage on collision
- [ ] Turn switching between players

### Visuals (agent handles when asked)
- [ ] Selection highlight on selected ship
- [ ] Movement range indicator
- [ ] Turret range indicator
- [ ] Shot animation (laser line)
- [ ] Collision/impact animation
- [ ] Turn phase display in info bar
- [ ] Active player highlight
- [ ] Death/explosion effect

### Future Versions
- [ ] Multiple ships per player
- [ ] AI opponent
- [ ] Player mat with hidden card selection
- [ ] Different turret types (push, pull, EMP, mine)
- [ ] Ship upgrades / abilities
- [ ] Multiple board layouts
- [ ] Save/load game
- [ ] Network multiplayer

---

## Key Files Reference

| File | Lines | Purpose |
|------|-------|---------|
| `main.lua` | ~156 | Entry point, spawns everything, game loop |
| `config.lua` | ~50 | All tunable values |
| `lib/board.lua` | ~70 | Grid rendering + coordinate math |
| `lib/ship.lua` | ~90 | Ship body + turret drawing |
| `lib/asteroid.lua` | ~43 | Asteroid rendering |
| `lib/ship_panel.lua` | ~199 | Info bar: momentum compass + HP/fuel per ship |
| `lib/class.lua` | ~20 | Base class boilerplate |

---

## Notes for Next Agent

- **The user writes game logic.** You handle visuals/rendering when asked.
- **Config values live in `config.lua`.** Never hardcode values in other files.
- **All rendering uses `tileSize`, `offsetX`, `offsetY` passed from main.lua.** These are computed at runtime from screen size.
- **Ship facing uses degrees internally** (0°=N, clockwise). `toRad()` converts to Love2D radians. Ships accept facing as string ("N", "SE", etc.).
- **Asteroids are multi-tile.** `Asteroid:new(x, y, w, h)` where x,y is top-left tile and w,h are dimensions in tiles.
- **The info bar is `ShipPanel`.** It draws 4 columns separated by dividers. Each column has: big momentum compass (radius 80, left side), momentum text in N/S/E/W format, HP segmented bar, fuel proportional bar (right side). Font is 42px. Uses `drawAll(ships, infoBarY, infoBarHeight, screenWidth)`.
- **Run with `cd ~/Projects/space && love .`** — starts fullscreen.
