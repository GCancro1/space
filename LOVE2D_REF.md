# Love2D Quick Reference — Space Strategy Board Game

## Core Callbacks

| Callback                  | When it runs                  | You'll use it for                      |
| ------------------------- | ----------------------------- | -------------------------------------- |
| `love.load()`               | Once at startup               | Create board, ships, turn manager      |
| `love.draw()`               | Every frame (~60fps)          | Render grid, pieces, UI                |
| `love.mousepressed(x,y,b)`  | When mouse button is pressed  | Click tiles, select pieces, fire       |
| `love.mousereleased(x,y,b)` | When mouse button is released | (optional) drag-and-drop               |
| `love.keypressed(key)`      | When key is pressed           | End turn, cancel selection, debug      |
| `love.update(dt)`           | Every frame, before draw      | Animations only (movement tween, etc.) |

## Graphics (love.graphics)

### Drawing shapes:
```lua
love.graphics.rectangle(mode, x, y, width, height)
love.graphics.circle(mode, x, y, radius)
love.graphics.line(x1, y1, x2, y2)
love.graphics.polygon(mode, x1, y1, x2, y2, ...)
```
- `mode` = `"fill"` or `"line"`

### Color — set before drawing:
```lua
love.graphics.setColor(r, g, b, a)  -- 0 to 1 each
-- examples:
love.graphics.setColor(0.2, 0.6, 1.0)       -- blue
love.graphics.setColor(1, 0, 0, 0.5)        -- semi-transparent red
```

### Text:
```lua
love.graphics.print("Turn 1", x, y)
love.graphics.printf("Hello", x, y, limit, align)
```

### Reset color after drawing:
```lua
love.graphics.setColor(1, 1, 1)
```

## Input (love.mouse)

```lua
love.mouse.getPosition()          -- returns x, y
love.mouse.getX() / love.mouse.getY()
love.mouse.isDown(button)         -- 1=left, 2=right, 3=middle
```

## Input (love.keyboard)

```lua
love.keyboard.isDown("escape")    -- check if key is held
```

## Timer / Utility

```lua
love.timer.getDelta()             -- time since last frame (for animations)
love.timer.getTime()              -- seconds since app started
```

## Coordinate Conversion (you write these)

```lua
-- screen pixel → grid tile
function board:screenToGrid(mx, my)
    local gx = math.floor(mx / self.tileSize)
    local gy = math.floor(my / self.tileSize)
    return gx, gy
end

-- grid tile → screen pixel
function board:gridToScreen(gx, gy)
    return gx * self.tileSize, gy * self.tileSize
end
```

## Game Tick Flow

```
love.load()          →  set up everything
       ↓
love.update(dt)      →  animate things (only when transitioning)
       ↓
love.draw()          →  render everything
       ↓
love.mousepressed()  →  handle clicks → update game state
```

## Architecture

| Class       | Owns                          | Key methods                               |
| ----------- | ----------------------------- | ----------------------------------------- |
| **Board**       | 2D grid array, tile size      | `draw()`, `getTile(x,y)`, `screenToGrid(mx,my)` |
| **Ship**        | Position, HP, list of turrets | `draw()`, `moveTo(tx,ty)`, `takeDamage(n)`      |
| **Turret**      | Range, damage, parent ship    | `draw()`, `canFire(target)`, `fire(target)`     |
| **TurnManager** | Current phase, current player | `nextPhase()`, `isPhase(name)`, `endTurn()`     |

## Turn Phases

```
SELECT_PIECE → MOVE_PIECE → SELECT_TARGET → FIRE → END_TURN
```
