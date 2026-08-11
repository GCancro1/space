return {
    -- Board (counts only)
    GRID_WIDTH = 20,
    GRID_HEIGHT = 20,

    -- UI
    INFO_BAR_HEIGHT = 280,  -- pixels, bottom bar

    -- Ship
    SHIP_HP = 5,
    SHIP_FUEL = 20,

    -- Turret
    TURRET_RANGE = 5,
    TURRET_POWER_MAX = 4,
    TURRET_DAMAGE = 1,

    -- Fuel costs
    FUEL_COST_THRUST = 1,
    FUEL_COST_SHOT = 1,

    -- Rotation
    BODY_ROTATION_PER_TURN = 1,

    -- Colors
    GRID_LINE_COLOR = {0.2, 0.2, 0.2},
    GRID_BG_COLOR = {0.05, 0.05, 0.1},
    INFO_BAR_BG = {0.1, 0.1, 0.15},
    INFO_BAR_BORDER = {0.3, 0.3, 0.3},
    SHIP_COLOR = {0.2, 0.6, 1.0},
    TURRET_COLOR = {1.0, 0.8, 0.2},
    TEXT_COLOR = {0.8, 0.8, 0.8},

    -- Directions (8-way)
    DIRECTIONS = {
        N  = {x =  0, y = -1},
        NE = {x =  1, y = -1},
        E  = {x =  1, y =  0},
        SE = {x =  1, y =  1},
        S  = {x =  0, y =  1},
        SW = {x = -1, y =  1},
        W  = {x = -1, y =  0},
        NW = {x = -1, y = -1},
    },

    FACING_LIST = {"N", "NE", "E", "SE", "S", "SW", "W", "NW"},
}
