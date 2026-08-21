# Game States

This directory contains initial game state JSON files for testing different scenarios. Each file follows the game state schema and can be loaded to test specific game mechanics.

## State Files

### high_speed_crash.json
**Tests:** Wall bounce physics at high velocity
**Setup:** Single ship at (2,10) with momentum (8,0) heading east toward wall
**Run:** Load state and execute turn - ship should bounce off east wall with inverted X momentum

### surrounded.json
**Tests:** Movement constraints when completely surrounded
**Setup:** Ship at (10,10) completely enclosed by 8 asteroids in a 3x3 grid
**Run:** Load state and attempt movement - ship should be unable to move in any direction

### fuel_crisis.json
**Tests:** Fuel management with critical fuel level
**Setup:** Player 1 ship at (10,10) with only 1 fuel remaining and momentum (2,1)
**Run:** Load state - any movement action should fail or consume last fuel, testing fuel validation

### turret_duel.json
**Tests:** Turret combat mechanics between opposing ships
**Setup:** Two ships at (3,10) and (17,10) facing each other with turrets aimed directly at opponent
**Run:** Load state and enter SHOOT phase - both ships have clear line of fire for turret combat

### multi_ship_race.json
**Tests:** Multi-ship physics with varying momentums and obstacle avoidance
**Setup:** Four ships at x=1 with different Y positions and momentums:
- Ship 1: (1,2) momentum (5,0) - fast straight
- Ship 2: (1,6) momentum (3,-2) - diagonal up
- Ship 3: (1,10) momentum (2,0) - slow straight
- Ship 4: (1,14) momentum (4,1) - diagonal down
Two asteroids placed as obstacles in their paths

## How to Run

```bash
# Load a specific state file
love . states/high_speed_crash.json

# Load from states/examples/ (if file exists there)
love . --example=high_speed_crash

# List all example states
love . --list
```

## Keyboard Controls

| Key | Action |
|-----|--------|
| Space | Execute turn / advance phase |
| T | Toggle trajectory preview |
| S | Save current state |
| L | Load state |
| 1-8 | Load test state 1-8 |
| Tab | Switch active ship |

## Schema Reference

All state files follow this structure:
```json
{
  "meta": { "turn": 1, "phase": "PLAN", "currentPlayer": 1 },
  "board": { "width": 20, "height": 20 },
  "ships": [...],
  "asteroids": [...]
}
```

Ships require: id, x, y, facing, turretFacing, hp, fuel, momentum, movement
Asteroids require: id, x, y, w, h, facing, momentum, movement