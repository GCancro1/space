local Board = require("ai.lib.board")
local Ship = require("ai.lib.ship")
local Asteroid = require("ai.lib.asteroid")
local Particles = require("ai.lib.particles")
local ShipPanel = require("ai.lib.ship_panel")
local Sidebar = require("ai.lib.sidebar")
local flux = require("ai.vendor.flux")
local Config = require("config")

local StateRenderer = {}
StateRenderer.__index = StateRenderer

function StateRenderer:new()
    local self = setmetatable({
        -- Animation state
        tweens = {},           -- active flux tweens {obj=ship, property="drawX", tween=...}
        prevPositions = {},    -- { [objId] = {x=..., y=...} } for tween comparison
        
        -- Visual effects from events
        effects = {},          -- { {type="damageFlash", obj=ship, timer=0.2, ...}, ... }
        
        -- Selection
        selectedShip = 1,      -- ship index (1-based)
        
        -- Reusable objects (created on first draw)
        board = nil,
        particles = nil,
        panel = nil,
        sidebar = nil,
    }, StateRenderer)
    return self
end

-- Initialize reusable render objects (call once or lazily in draw)
function StateRenderer:_initObjects()
    if not self.board then
        self.board = Board:new(Config)
        self.particles = Particles:new()
        self.panel = ShipPanel:new()
        self.sidebar = Sidebar:new()
    end
end

-- Main draw function - reads state and renders everything
-- @param state table - current game state
function StateRenderer:draw(state)
    self:_initObjects()
    
    local tileSize = Config.TILE_SIZE
    local offsetX = Config.GRID_OFFSET_X
    local offsetY = Config.GRID_OFFSET_Y
    
    -- TODO: 1. Draw board (grid, background)
    -- self.board:draw()
    
    -- TODO: 2. Draw background (if enabled)
    -- if Config.ENABLE_BACKGROUND then ... end
    
    -- TODO: 3. Draw asteroids
    -- for _, ast in ipairs(state.asteroids) do
    --     ast:draw(tileSize, offsetX, offsetY)
    --     -- Draw momentum arrow if ast.momentum != {0,0}
    -- end
    
    -- TODO: 4. Draw ships
    -- for _, ship in ipairs(state.ships) do
    --     ship:draw(tileSize, offsetX, offsetY)
    --     -- Draw momentum arrow (dotted line)
    --     -- Draw movement.direction arrow during MOVE phase
    --     -- Draw selection highlight if ship.id == self.selectedShip
    -- end
    
    -- TODO: 5. Draw particles
    -- self.particles:draw()
    
    -- TODO: 6. Draw visual effects (damage flashes, bounce ripples)
    -- for _, effect in ipairs(self.effects) do ... end
    
    -- TODO: 7. Draw info bar (bottom)
    -- self.panel:drawAll(state.ships, Config.INFO_BAR_Y, Config.INFO_BAR_HEIGHT, Config.SCREEN_WIDTH - Config.SIDEBAR_WIDTH)
    -- -- Add phase indicator, turn number, current player
    
    -- TODO: 8. Draw sidebar
    -- self.sidebar:draw()
    -- -- Update sidebar with current state info
end

-- Update animations and effects
-- @param dt number - delta time
function StateRenderer:update(dt)
    -- TODO: 1. flux.update(dt)
    -- TODO: 2. Update effect timers, remove expired
    -- for i = #self.effects, 1, -1 do
    --     effect.timer = effect.timer - dt
    --     if effect.timer <= 0 then table.remove(self.effects, i) end
    -- end
    -- TODO: 3. Update particles
    -- if self.particles then self.particles:update(dt) end
end

-- Queue visual effects from logic events
-- @param events table - array of event objects from GameState.advanceTick/advancePhase
function StateRenderer:setEvents(events)
    for _, event in ipairs(events) do
        if event.type == "movementStep" then
            -- TODO: Start flux tween from event.from to event.to for the object
            -- Store old position in self.prevPositions
        elseif event.type == "wallBounce" then
            -- TODO: Add damage flash effect + wall ripple
            -- table.insert(self.effects, {type="damageFlash", objectId=event.objectId, timer=0.2, ...})
            -- table.insert(self.effects, {type="wallRipple", x=event.x, y=event.y, timer=0.3, ...})
        elseif event.type == "shipCollision" then
            -- TODO: Add damage flash on both ships
            -- table.insert(self.effects, {type="damageFlash", objectId=event.a, timer=0.2, ...})
            -- table.insert(self.effects, {type="damageFlash", objectId=event.b, timer=0.2, ...})
        elseif event.type == "shotFired" then
            -- TODO: Add shot line effect
        elseif event.type == "shipDestroyed" then
            -- TODO: Add explosion effect
            -- self.particles:createExplosion(x, y, color)
        end
    end
end

-- Handle ship selection (click or Tab key)
-- @param shipId number - ship ID to select
function StateRenderer:selectShip(shipId)
    self.selectedShip = shipId
end

-- Cycle selection to next ship
function StateRenderer:cycleSelection()
    -- TODO: implement
end

return StateRenderer