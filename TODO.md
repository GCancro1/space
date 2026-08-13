# TODO — MVP Demo Priorities

> Ordered by priority. P0 = must have, P1 = should have, P2 = nice to have.
> The user writes game logic in `game/` directory. Agents handle visuals when asked.

---

## P0 — State-Based Game Loop (Must Have)

These tasks form the minimum playable game using JSON state files.

### 1. JSON State I/O
**Status:** Not started
**What:** Load/save game state as JSON files
**Where:** New file `game/state_io.lua` + vendor `ai/vendor/json.lua` (rxi/json.lua)
**Details:**
- Vendor rxi/json.lua (~280 LOC, pure Lua, MIT) into `ai/vendor/json.lua`
- `StateIO.load(path)` → state table
- `StateIO.save(state, path)` → bool
- Uses `love.filesystem.read/write` for Love2D sandbox compatibility
- Test with 14 pre-made state files in `states/`

### 2. Game State Logic
**Status:** Not started
**What:** Pure functions that advance game state (state → state)
**Where:** New file `game/game_state.lua`
**Details:**
- `GameState.advancePhase(state, actions)` → newState
  - PLAN: store pending actions on ships
  - CALC: apply rotation, thrust, fuel costs
  - MOVE: run all ticks until movement complete
  - SHOOT: resolve shots, remove destroyed ships
  - END_TURN: advance currentPlayer, increment turn
- `GameState.advanceTick(state)` → newState, events
  - MOVE phase only: all objects move 1 tile in movement.direction
  - Returns events array for renderer: `{type="wallBounce", objectId=1, damage=1}`
- Pure functions: no side effects, no Love2D API calls

### 3. State Renderer
**Status:** Not started
**What:** Read game state and draw everything to screen
**Where:** New file `game/state_renderer.lua`
**Details:**
- `StateRenderer:draw(state)` — draw board, ships, asteroids, UI
- `StateRenderer:update(dt)` — advance tweens and effects
- `StateRenderer:setEvents(events)` — queue visual effects from logic
- Compares old/new positions, starts flux tweens for movement
- Shows phase indicator, current player, turn number
- Ships: triangle + turret + momentum arrow + HP bar
- Asteroids: sprites + momentum arrow
- Effects: damage flash, bounce ripple, shot lines

### 4. Main Loop Integration
**Status:** Not started
**What:** Wire state system into Love2D callbacks
**Where:** `main.lua` (modify existing)
**Details:**
- `love.load`: load initial state from JSON
- `love.keypressed`: Space=advance phase, T=advance tick, S=save, L=reload, 1-8=load test state
- `love.mousepressed`: click to select ship (for inspection)
- `love.draw`: delegate to StateRenderer
- `love.update`: delegate to StateRenderer:update

### 5. Movement Resolution (in GameState)
**Status:** Not started
**What:** Step-by-step movement with wall bounce
**Where:** Inside `game/game_state.lua` or helper module
**Details:**
- Momentum = `{x, y}`, persists across turns
- Movement direction = compass direction (N/NE/E/SE/S/SW/W/NW)
- Steps: X first, then Y. 1 tile per step.
- Wall bounce: flip direction, subtract 1 from momentum, damage, continue
- Ship collision: both take damage, momentum exchange
- Events emitted for each step, bounce, and collision

### 6. Ship Selection + Highlight
**Status:** Not started
**What:** Click ship to select, show visual highlight
**Where:** `main.lua` input + `game/state_renderer.lua` draw
**Details:**
- Click tile → find ship at that position → select it
- Draw yellow pulsing ring around selected ship
- Show ship info in sidebar (HP, fuel, facing, momentum)
- Tab key cycles through ships

---

## P1 — Combat & Economy (Should Have)

### 7. Turret Rotation
**Status:** Not started
**What:** Independent turret rotation during PLAN phase
**Where:** `game/game_state.lua` (CALC phase)
**Details:**
- Action file specifies `turretRotation: "CW"/"CCW"` or null
- Applied during CALC phase, independent of body rotation
- No fuel cost for turret rotation

### 8. Shot Firing
**Status:** Not started
**What:** Fire shot from turret in turret facing direction
**Where:** `game/game_state.lua` (SHOOT phase)
**Details:**
- Action file specifies `shot: { power: 1-4 }` or null
- Check range (5 tiles) in turret facing direction
- Line-of-sight check (no obstacles blocking)
- Damage = shot power
- Costs `FUEL_COST_SHOT` per power unit

### 9. Ship Destruction
**Status:** Not started
**What:** Remove ship when HP reaches 0
**Where:** `game/game_state.lua`
**Details:**
- Check HP after each damage event
- When HP ≤ 0: remove from ships array
- Emit destruction event for renderer (explosion effect)
- Check win condition (last ship standing)

---

## P2 — Visual Polish (Nice to Have)

### 10. Momentum Arrow on Board
**Status:** Not started
**What:** Show momentum direction and magnitude on each ship
**Where:** `game/state_renderer.lua`
**Details:**
- Dotted line from ship center in momentum direction
- Length proportional to |momentum|
- Color matches player color
- Arrow tip at end

### 11. Movement Direction Indicator
**Status:** Not started
**What:** Show active movement direction during MOVE phase
**Where:** `game/state_renderer.lua`
**Details:**
- Bright solid arrow in movement.direction during MOVE phase
- Steps remaining counter near ship
- Fades after movement completes

### 12. Damage Flash Effect
**Status:** Not started
**What:** Visual feedback when ship takes damage
**Where:** `game/state_renderer.lua`
**Details:**
- Red flash overlay on damaged ship (0.2s duration)
- Screen shake on wall bounce
- Damage number floating up from ship

### 13. Shot Animation
**Status:** Not started
**What:** Visual laser line when firing
**Where:** `game/state_renderer.lua`
**Details:**
- Draw line from turret to target
- Bright flash at impact point
- Use explosion particles on hit

---

## P3 — Polish (Post-MVP)

### 18. Multiple Ships Per Player
### 19. AI Opponent
### 20. Player Mat with Hidden Card Selection
### 21. Different Turret Types (push, pull, EMP, mine)
### 22. Ship Upgrades / Abilities
### 23. Multiple Board Layouts
### 24. Save/Load Game
### 25. Network Multiplayer

---

## File Dependencies

```
main.lua
├── config.lua
├── assets.lua
├── ai/lib/board.lua
├── ai/lib/ship.lua
├── ai/lib/asteroid.lua
├── ai/lib/ship_panel.lua
├── ai/lib/particles.lua
├── ai/lib/movement_animator.lua
├── ai/vendor/flux.lua
├── ai/vendor/json.lua        (NEW - rxi/json.lua)
├── ai/vendor/moonshine/
├── game/game_state.lua       (NEW - pure logic)
├── game/state_io.lua         (NEW - JSON load/save)
└── game/state_renderer.lua   (NEW - reads state, draws)
```
