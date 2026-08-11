# Agent Log — Space Strategy Board Game

> Track what's completed, in progress, and what's next.
> Read this at the start of any new session to pick up where the last agent left off.

---

## Last Updated
2026-08-10 — End of session: sprites, visuals, particles, animation system complete. No game logic yet.

---

## Project Stats
- **2,255 Lua LOC** across 17 files
- **Run with:** `cd ~/Projects/space && love .`

---

## File Map

| File | Lines | Purpose |
|------|-------|---------|
| `main.lua` | 217 | Entry point, game loop, spawns ships/asteroids, layout |
| `config.lua` | 67 | All tunable game values |
| `conf.lua` | 9 | Love2D window config |
| `assets.lua` | 70 | Sprite loading + spritesheet slicing |
| `lib/class.lua` | 18 | Base class (extend/new/init) |
| `lib/board.lua` | 58 | Grid rendering, coordinate math |
| `lib/ship.lua` | 139 | Ship body + turret rendering (procedural, clear indicators) |
| `lib/asteroid.lua` | 77 | Asteroid rendering (sprite-based + fallback) |
| `lib/ship_panel.lua` | 377 | Info bar: compass dials, HP/fuel bars, momentum display |
| `lib/particles.lua` | 75 | Thruster + explosion particle systems |
| `lib/flux.lua` | 224 | Tweening library (vendored) |
| `lib/anim8.lua` | 302 | Animation library (vendored) |
| `lib/tween_group.lua` | 122 | Tween group management |
| `lib/movement_animator.lua` | 137 | Step-by-step ship movement animation |
| `lib/moonshine/` | 279 | Post-processing (vignette, chromatic aberration) |

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
- [x] `lib/class.lua` — base class with extend/new/init
- [x] Responsive layout — detects screen, calculates tile size, handles resize

### 3. Board / Grid ✅
- [x] `lib/board.lua` — 20×20 grid with lines and border
- [x] `screenToGrid(mx, my)` — mouse click → tile coords
- [x] `gridToScreen(gx, gy)` — tile → screen pixel (center)
- [x] `inBounds(gx, gy)` — bounds checking

### 4. Ship Rendering ✅
- [x] `lib/ship.lua` — procedural rendering (NOT sprite-based, for clarity)
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

### 6. Asteroid Rendering ✅
- [x] `lib/asteroid.lua` — multi-tile asteroids (w×h in tiles)
- [x] Sprite-based from Lunar Lander pack
- [x] Fallback to brown rectangles if sprites fail

### 7. Info Bar / Ship Panel ✅
- [x] `lib/ship_panel.lua` — 4 panels in bottom bar
- [x] Compass dials: body facing + turret facing
- [x] Momentum compass + text
- [x] HP bar (segmented) + Fuel bar (continuous)

### 8. Visual / Animation Libraries ✅
- [x] `lib/flux.lua` — tweening
- [x] `lib/anim8.lua` — animation
- [x] `lib/moonshine/` — vignette + chromatic aberration
- [x] `lib/particles.lua` — thruster + explosion particles
- [x] `lib/movement_animator.lua` — step-by-step movement

### 9. Assets / Sprites ✅
- [x] `assets.lua` — sprite loader with sliceSheet helper
- [x] 200Starships: 844 ship sprites (4 styles)
- [x] Lunar Lander: turrets, guns, asteroids, effects, stars
- [x] Screaming Brain Studios: 32 seamless backgrounds
- [x] Blue nebula + star tiles background

---

## NOT Started — Game Logic

> **The user writes game logic.** Agents handle visuals when asked.
> See `TODO.md` for full prioritized task list.

### Critical for MVP
- Turn state machine (SELECT_PIECE → MOVE → SHOOT → END_TURN)
- Click to select ship
- Body rotation (45° per turn)
- Thrust application (F/B/L/R, costs 1 fuel)
- Momentum movement resolution (step-by-step, X then Y)
- Wall collision + bounce (1 damage, flip momentum)
- Turn switching (hot seat)

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

---

## Notes for Next Agent

- **User writes game logic.** You handle visuals when asked.
- **Config values live in `config.lua`.** Never hardcode elsewhere.
- **Ship rendering is procedural** (circles + arrows + turret). Do NOT use sprite images for ships.
- **Asteroids use sprites** from Lunar Lander pack, with fallback.
- **Background:** blue nebula + star tiles.
- **All rendering uses `tileSize`, `offsetX`, `offsetY`** computed at runtime.
- **Facing uses degrees** (0°=N, clockwise). Ships accept facing as string.
- **Run with:** `cd ~/Projects/space && love .`

---

## Asset Sources

| Source | License | What We Got |
|--------|---------|-------------|
| Wisedawn (OpenGameArt) | CC0 | 844 ship sprites |
| Screaming Brain Studios (OpenGameArt) | CC0 | 32 seamless backgrounds |
| Lunar Lander Upload (itch.io) | Free | Turrets, guns, asteroids, effects, stars |
