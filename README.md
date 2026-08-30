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

### Getting started windows
1) Install LOVE   (https://love2d.org/#download)
2) Set up a tasks file for vscode by creating a file .vscode/tasks.json.  Copy the following into it.

```
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Run LOVE Game",
            "type": "shell",
            "command": "C:\\Program Files\\LOVE\\love.exe",
            "args": [
                "${workspaceFolder}"
            ],
            "group": {
                "kind": "build",
                "isDefault": true
            },
            "problemMatcher": []
        }
    ]
}

```

Run love with Ctrl + Shift + B

3) Alternative way to run love is from the powershell command line

```
....\space> & 'C:\Program Files\LOVE\love.exe' . --console
```

**NOTE** - the '--console'  allows print statements to work in powershell

### Getting Started Linux
1) Install Love
```
sudo apt update && sudo apt install love
```

2) Run Love

```
love .
```

3) To get x11 to display back (if running vscode on windows remote to linux)

    - Install vcxsrv (https://sourceforge.net/projects/vcxsrv/)
    - Set up host file like this...

    ```
    Host BasementUbuntu
        HostName 10.0.0.86
        User george
        ForwardAgent yes
        ForwardX11 yes
        ForwardX11Trusted yes
    ```
    - Start VcXsrv using XLaunch desktop icon (to know if its running, check system tray...double click to close it)
    - Connect to remote in vscode

    **NOTE** This failed with response "X connection to localhost:10.0 broken (explicit kill or server shutdown)" when running    $ love .
