# TODO — MVP Demo Priorities

> P0 = must have, P1 = should have, P2 = nice to have, P3 = post-MVP

---

## P0 — State-Based Game Loop (Must Have)

- [ ] JSON State I/O — load/save game state as JSON files (`game/state_io.lua`)
- [ ] Game State Logic — pure functions advancing state (phase/tick) (`game/game_state.lua`)
- [ ] State Renderer — read state, draw board/ships/UI/effects (`game/state_renderer.lua`)
- [ ] Main Loop Integration — wire state system into Love2D callbacks (`main.lua`)
- [ ] Movement Resolution — step-by-step movement with wall bounce & collision events
- [ ] Ship Selection + Highlight — click to select, show info sidebar, Tab to cycle

---

## P1 — Combat & Economy (Should Have)

- [ ] Turret Rotation — independent turret rotation during PLAN phase
- [ ] Shot Firing — fire from turret facing direction, range/LoS checks, fuel cost
- [ ] Ship Destruction — remove at 0 HP, check win condition

---

## P2 — Visual Polish (Nice to Have)

- [ ] Momentum Arrow — show direction/magnitude on each ship
- [ ] Movement Direction Indicator — arrow + steps remaining during MOVE phase
- [ ] Damage Flash Effect — red flash, screen shake, floating damage numbers
- [ ] Shot Animation — laser line, impact flash, explosion particles

---

## P3 — Post-MVP

- [ ] Multiple Ships Per Player
- [ ] AI Opponent
- [ ] Player Mat with Hidden Card Selection
- [ ] Different Turret Types (push, pull, EMP, mine)
- [ ] Ship Upgrades / Abilities
- [ ] Multiple Board Layouts
- [ ] Save/Load Game
- [ ] Network Multiplayer