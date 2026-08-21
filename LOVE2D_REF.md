# Love2D Quick Reference — Space Strategy Board Game

## Core Callbacks
| Callback | Use |
|----------|-----|
| `love.load()` | Create board, ships, TurnManager |
| `love.draw()` | Render grid, pieces, UI |
| `love.mousepressed(x,y,b)` | Click tiles, select pieces, fire |
| `love.keypressed(key)` | End turn, cancel selection |
| `love.update(dt)` | Animations only (movement tween) |

## Graphics (love.graphics)
```lua
love.graphics.rectangle("fill"|"line", x, y, w, h)
love.graphics.circle("fill"|"line", x, y, r)
love.graphics.line(x1, y1, x2, y2)
love.graphics.polygon("fill"|"line", x1,y1, x2,y2, ...)
love.graphics.setColor(r, g, b, a)  -- 0-1
love.graphics.print("text", x, y)
love.graphics.setColor(1, 1, 1)     -- reset
```

## Input
```lua
love.mouse.getPosition()  -- x, y
love.mouse.isDown(1)      -- left click held
love.keyboard.isDown("escape")
```

## Coordinate Conversion
```lua
function Board:screenToGrid(mx, my)
    return math.floor(mx / self.tileSize), math.floor(my / self.tileSize)
end
function Board:gridToScreen(gx, gy)
    return gx * self.tileSize, gy * self.tileSize
end
```

## Architecture
| Class | Key Methods |
|-------|-------------|
| **Board** | `draw()`, `screenToGrid()`, `inBounds()`, `tileSize` |
| **Ship** | `draw()`, `moveTo()`, `rotateTo()`, `facing`, `momentum` |
| **Asteroid** | `draw()`, `occupies(gx,gy)`, `size` |
| **ShipPanel** | `drawAll(ships, y, h, width)` |
| **Sidebar** | `update()`, `draw()`, `getSelectedAction()` |
| **TurnManager** | `nextPhase()`, `isPhase(name)`, `endTurn()`, `phase` |

## Turn Phases
`PLAN → CALC → MOVE → COLLIDE → END_TURN`