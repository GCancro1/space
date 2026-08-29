# Space Strategy Game

Turn-based space strategy game built with LÖVE (Love2D).

## Quick Start

```bash
# Arch Linux
./setup-arch.sh

# Ubuntu/Debian
./setup-ubuntu.sh

# Run the game from root of project
love .

# Run the game from state
love . states/<state.json>
```

## What's Implemented

Turn-based space strategy with phase system:
- **PLAN** → **CALC** → **MOVE** → **COLLIDE** → **END_TURN**

## File Structure

```
.
├── main.lua          # Entry point
├── conf.lua          # LÖVE configuration
├── config.lua        # Game constants
├── assets.lua        # Asset loading
├── game/             # Core game logic
├── ai/               # AI modules
└── states/           # Game state management
```

## Key Controls

| Key | Action |
|-----|--------|
| SPACE | Advance phase |
| T | Advance tick |
| L | Reload state |
| S | Save state |
| ESC | Quit |
| Click | Select ship |

## Setup Scripts

- `setup-arch.sh` - Installs LÖVE and dependencies on Arch
- `setup-ubuntu.sh` - Installs LÖVE and dependencies on Ubuntu/Debian
