# Space Strategy Game

Turn-based space strategy game built with LÖVE (Love2D).

## What we should work on together:

1. `game/collision.lua` - you can see i have a generated file here... we will want to update this to test out different rules.
I didnt want to work too much on this since we really dont know what we are doing. This will likely be fully re-done
2. `game/game_state.lua` - this is where the real thinking goes down to figure out the state logic. This will also have to be thought about and changed. I think what ai/me got here is enough to see what my vision was for this file. We want to seperate the game into 2 things, a state machine and a render game/state_renderer.lua which can be run together or seperate (json only)

3. `config.lua` `conf.lua` main.lua - these are the main way we run the game. Please take a look at the config file to see the globals. the conf handles the love render window. the main is the ultimate entry point and calls the render and the Love2D methods to load, and render the game.



## What I want Dad to understand about the game and lua

1. Lua catch up: its simple, and doesnt have a lot of stuff. The main thing to understand is lua tables, which act like a better python dicts. The whole language is built around them, which makes it such a good configuration language. You may want to watch a quick vid on how lua tables work. We can use them to replicate class logic by using our files to return lua tables, which contain the class methods. 

Look at the bottom of `game_state.lua` for how we are exposing the class methods. Does this make sense? 

NOTE: We are not using lua tables for the state, instead i picked json since i think it makes more sense to serialize to files and from an io perspective. I already handled this in `game/state_io.lua` and this file should be final... just serialize to files and back

2. The player actions have not been handled yet... later problem. the idea is to hadle during the plan phase

3. Look at the what we should work on together section... it looks complicated but you really only need to work on those 2 main files for now!

4. We can mess with the ui stuff later... i really just wanted to be able to render the game quickly since that was kinda the whole point of the demo... also the workflow of visualizing the json is very nice to check if it makes sense





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
