# Example State Files — Phase Chain Reference

## State Schema (Key Fields)

| Key | Type | Description |
|-----|------|-------------|
| `meta` | object | `{ turn, phase, currentPlayer }` |
| `board` | object | `{ width: 20, height: 20 }` |
| `ships` | array | `{ id, x, y, facing, turretFacing, hp, fuel, momentum: {x,y}, movement }` |
| `asteroids` | array | `{ id, x, y, w, h, facing, momentum: {x,y}, movement }` |

**`movement`**: `null` (idle) or `{ direction, stepsRemaining }` — 8-directional tick progress, diagonal = 1 tick/tile. Used by both ships and asteroids.

## Phase Chain Files (Turn 1)

| File | Phase | Description |
|------|-------|-------------|
| `01_plan.json` | PLAN | Cold start: 4 ships at corners, 4 asteroids (one drifting), all `movement: null` |
| `02_calc.json` | CALC | Thrust applied (fuel 20→17, momentum set), positions unchanged |
| `03_move.json` | MOVE | 2 lockstep ticks elapsed: ships mid-flight, asteroid 1 drift completes |
| `04_shoot.json` | SHOOT | Movement done, shots resolve (HP 5→3, fuel 17→15) |
| `05_end_turn.json` | END_TURN | Identical to 04, phase advanced |

## Stepping Through

- **Space** — advance full phase (PLAN → CALC → MOVE → SHOOT → END_TURN)
- **T** — single tick within MOVE phase

## Key Notes

- Momentum persists across turns (no cap, carryover)
- Asteroids can carry momentum at PLAN — drift is valid state
- Shot fuel cost applied at SHOOT resolution
- All files are valid standalone states — load any directly