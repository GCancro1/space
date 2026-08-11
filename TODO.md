# TODO — MVP Demo Priorities

> Ordered by priority. P0 = must have, P1 = should have, P2 = nice to have.
> The user writes game logic. Agents handle visuals when asked.

---

## P0 — Core Game Loop (Must Have)

These tasks form the minimum playable game. Nothing happens when you click without them.

### 1. Turn State Machine
**Status:** Not started  
**What:** Create a state machine that cycles through: `SELECT_PIECE → MOVE → SHOOT → END_TURN`  
**Where:** New file `lib/turn.lua` or in `main.lua`  
**Details:**
- Track current phase and active player
- `SELECT_PIECE`: wait for player to click a ship
- `MOVE`: let player rotate body and apply thrust
- `SHOOT`: let player rotate turret and fire
- `END_TURN`: switch to next player, repeat

### 2. Click to Select Ship
**Status:** Not started  
**What:** Click on a tile → check if a ship is there → select it  
**Where:** `main.lua` `love.mousepressed()`  
**Details:**
- Convert mouse click to grid coords (use `board:screenToGrid()`)
- Check if any ship occupies that tile
- Store selected ship index
- Draw selection highlight (yellow ring or pulsing outline)

### 3. Body Rotation
**Status:** Not started  
**What:** Keyboard input to rotate ship body 45° per turn  
**Where:** `main.lua` `love.keypressed()`  
**Details:**
- `Q` = rotate left (counter-clockwise 45°)
- `E` = rotate right (clockwise 45°)
- Update `ship.facing` to next direction in FACING_LIST
- Only during MOVE phase, only for selected ship

### 4. Thrust Application
**Status:** Not started  
**What:** Keyboard input to apply thrust in a direction relative to body facing  
**Where:** `main.lua` `love.keypressed()`  
**Details:**
- `W` = forward (add momentum in facing direction)
- `S` = backward (add momentum opposite to facing)
- `A` = left strafe
- `D` = right strafe
- Each thrust costs 1 fuel
- Check `ship.fuel > 0` before applying

### 5. Momentum Movement Resolution
**Status:** Not started  
**What:** After all inputs locked, move ships step-by-step based on momentum  
**Where:** New function in `main.lua` or `lib/movement.lua`  
**Details:**
- X movement first (1 tile at a time in momentum.x direction)
- Then Y movement (1 tile at a time in momentum.y direction)
- After all movement: check wall collisions
- Update `ship.x`, `ship.y`

### 6. Wall Collision + Bounce
**Status:** Not started  
**What:** When ship hits grid boundary, apply damage and bounce  
**Where:** Inside movement resolution  
**Details:**
- If ship goes off grid → 1 HP damage
- Flip momentum component perpendicular to wall
- Subtract 1 from flipped component
- Continue remaining movement in new direction
- If HP reaches 0 → ship destroyed

### 7. Turn Switching (Hot Seat)
**Status:** Not started  
**What:** After END_TURN, pass to next player  
**Where:** `main.lua`  
**Details:**
- Track `currentPlayer` index (1-4)
- After END_TURN: `currentPlayer = currentPlayer % 4 + 1`
- Reset phase to SELECT_PIECE
- Show which player's turn it is

---

## P1 — Combat & Economy (Should Have)

These make the game actually strategic.

### 8. Turret Rotation
**Status:** Not started  
**What:** Independent turret rotation during SHOOT phase  
**Where:** `main.lua` `love.keypressed()`  
**Details:**
- Arrow keys or custom keys during SHOOT phase
- Rotates `ship.turretFacing` independently
- Unlimited rotation (not 45° steps)

### 9. Shot Firing
**Status:** Not started  
**What:** Fire a shot from turret in turret facing direction  
**Where:** `main.lua` or new `lib/combat.lua`  
**Details:**
- Check turret range (5 tiles)
- Trace line from turret to target tile
- If ship is in the line → 1 damage
- Costs 1 fuel per shot

### 10. Fuel Cost Deduction
**Status:** Not started  
**What:** Deduct fuel for each action  
**Where:** After each action in MOVE/SHOOT phases  
**Details:**
- Thrust = 1 fuel per power unit
- Shot = 1 fuel per shot
- Check fuel before allowing action
- Visual: update fuel bar in ship_panel

### 11. Ship Destruction
**Status:** Not started  
**What:** Remove ship when HP reaches 0  
**Where:** Movement/combat resolution  
**Details:**
- When HP ≤ 0: remove from ships table
- Play explosion effect
- Check win condition

---

## P2 — Visual Feedback (Nice to Have)

These make the game feel polished.

### 12. Selection Highlight
**Status:** Not started  
**What:** Visual indicator on selected ship  
**Where:** `lib/ship.lua` `draw()`  
**Details:**
- Yellow pulsing ring around selected ship
- Or bright outline that fades in/out

### 13. Movement Range Indicator
**Status:** Not started  
**What:** Show where ship can move  
**Where:** `main.lua` `love.draw()`  
**Details:**
- Highlight tiles the ship can reach based on current momentum
- Show predicted path

### 14. Turret Range Indicator
**Status:** Not started  
**What:** Show turret range from selected ship  
**Where:** `main.lua` `love.draw()`  
**Details:**
- Highlight tiles within 5-tile range
- Show cone or circle in turret facing direction

### 15. Shot Animation
**Status:** Not started  
**What:** Visual laser line when firing  
**Where:** New `lib/shot_effect.lua` or in `main.lua`  
**Details:**
- Draw line from turret to target
- Flash effect
- Use explosion particles on hit

### 16. Turn Phase Display
**Status:** Not started  
**What:** Show current phase and active player in info bar  
**Where:** `lib/ship_panel.lua`  
**Details:**
- Display "Phase: MOVE" or "Phase: SHOOT"
- Highlight active player's panel
- Grey out other players' panels

### 17. Momentum Trail
**Status:** Not started  
**What:** Show ship's momentum as a dotted line or arrow  
**Where:** `lib/ship.lua` `draw()`  
**Details:**
- Draw dotted line in momentum direction
- Length proportional to momentum magnitude
- Color matches player color

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
├── lib/board.lua
├── lib/ship.lua
├── lib/asteroid.lua
├── lib/ship_panel.lua
├── lib/particles.lua
├── lib/movement_animator.lua
├── lib/flux.lua
├── lib/anim8.lua
└── lib/moonshine/

New files needed for MVP:
├── lib/turn.lua        (turn state machine)
├── lib/combat.lua      (shot firing + damage)
└── lib/movement.lua    (momentum resolution + wall bounce)
```
