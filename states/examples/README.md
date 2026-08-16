# Example State Files — Full Phase Chain

Reference states showing one turn played end-to-end across every phase of the game loop.

## State Schema

Top-level keys:

| Key | Type | Description |
|-----|------|-------------|
| `meta` | object | `{ turn, phase, currentPlayer }` |
| `board` | object | `{ width, height }` — 20×20 |
| `ships` | array | Ship entries (see below) |
| `asteroids` | array | Asteroid entries (see below) |

Ship entry:

```json
{
  "id": 1, "x": 4, "y": 4,
  "facing": "E", "turretFacing": "E",
  "hp": 5, "fuel": 20,
  "momentum": { "x": 0, "y": 0 },
  "movement": null
}
```

Asteroid entry:

```json
{
  "id": 1, "x": 9, "y": 9, "w": 1, "h": 1,
  "facing": "N",
  "momentum": { "x": 2, "y": 1 },
  "movement": null
}
```

The `movement` field:

- `null` — not moving this phase
- `{ "direction": "E", "stepsRemaining": 1 }` — mid-travel; direction is a compass direction **independent of facing** (`ship.facing` / `ship.turretFacing`)
- `stepsRemaining` counts the remaining 8-directional steps of the momentum vector: one tile per tick in any of the 8 compass directions; diagonal moves take ONE tick per diagonal tile (not x-then-y), and `stepsRemaining = max(|x|, |y|)` of the momentum vector
- Both ships and asteroids use the same field — asteroids drift through it exactly like ships

## Files

| File | Phase | What it demonstrates |
|------|-------|----------------------|
| `01_plan.json` | PLAN | Cold-start state, turn 1, currentPlayer 1. Ships face off at (4,4)/(15,4)/(4,15)/(15,15), 20 fuel, 5 HP, zero momentum. Asteroid 1 at (9,9) already carries momentum {x:2, y:1} (drift carried in state); asteroids 2-4 stationary (1×1, 1×2, 2×2). All `movement: null` — nothing moving yet, actions not yet created. |
| `02_calc.json` | CALC | Actions applied: each ship thrust F (forward) power 3 → fuel 20→17, momentum becomes (3,0)/(−3,0)/(3,0)/(−3,0) in facing direction. Positions unchanged (movement hasn't started), `movement` still null. Asteroid state unchanged (asteroids don't take actions; momentum persists). |
| `03_move.json` | MOVE | 2 lockstep ticks elapsed (`movement` direction and `stepsRemaining` populated): ships 1 and 3 mid-flight east at (6,4) and (6,15); ships 2 and 4 mid-flight west at (13,4) and (13,15); each `movement: { direction: E or W, stepsRemaining: 1 }` (3 total steps). Asteroid 1 (drifting SE-ish, momentum {2,1}: SE then E path) finished at (11,10) — 8-directional stepping completes the 2-tick burst by tick 2 while ships 1-4 remain mid-flight. |
| `04_shoot.json` | SHOOT | Movement complete (all `movement: null`). Every ship fired a power-2 shot at exactly range 5 at its opponent (ship 1 at (7,4) ↔ ship 2 at (12,4); ship 3 at (7,15) ↔ ship 4 at (12,15)): HP 5→3, fuel 17→15 (shot fuel cost 1/power). Asteroid 1 finished drift at (11,10). |
| `05_end_turn.json` | END_TURN | Identical to 04 except `phase: "END_TURN"` — turn 1 settled (all HP 3, fuel 15), ready to advance currentPlayer / turn. |


## How to Read the Chain

1. Load `01_plan.json` — everything at rest, actions pending.
2. Advance the phase (Space key per SPEC advances a full phase) → `02_calc.json` — thrust applied to momentum, fuel deducted.
3. Advance to MOVE and step ticks (T key: one tick) → `03_move.json` — mid-flight with `movement` populated; one more tick finishes it.
4. Advance → `04_shoot.json` — movement null again, shots resolved, HP/fuel deducted.
5. Advance → `05_end_turn.json` — identical to 04 but phase `END_TURN`.

Each file is a valid standalone state for the game loop — you can load any of them directly and it renders/advances correctly.

## Implied Turn-1 Action Plan

(Reference only — action files live in `actions/`, one per player per turn.)

- Every ship: thrust `{ "dir": "F", "power": 3 }`
- Every ship: shot `{ "power": 2 }`
- No body or turret rotation: facings stay E/W, turrets keep aiming at the enemy

## Notes & Conventions

- Every example contains all 4 ships + all 4 asteroids (full-board fidelity; no objects dropped between phases).
- Asteroids can carry momentum at PLAN — drift is legal state, not something the game injects later.
- Shot fuel cost is applied when the shot resolves in SHOOT, not at PLAN/CALC.
- Momentum persists across turns (carryover, no cap — see SPEC "No momentum cap").
- Positions are integer tile coords on a 0-19 grid.
- Coordinates in these files avoid ship/asteroid overlap at every phase.

## Future Maintenance

If the schema evolves (e.g. asteroid HP, push/pull shot types, new fields), update these examples to stay canonical — they are the reference for the full phase chain and should always reflect the current schema.