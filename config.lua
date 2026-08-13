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

    -- Particles
    THRUSTER_LIFETIME = 0.5,
    THRUSTER_SPEED_MIN = 50,
    THRUSTER_SPEED_MAX = 100,
    THRUSTER_SIZE_MIN = 2,
    THRUSTER_SIZE_MAX = 5,
    EXPLOSION_LIFETIME = 0.8,
    EXPLOSION_PARTICLE_COUNT = 30,

    -- Animation
    SHIP_ANIMATION_SPEED = 0.15,
    -- Movement animation
    MOVE_STEP_SPEED = 0.15,       -- seconds per tile step
    ROTATE_DURATION = 0.25,       -- seconds for body rotation (45 deg)
    TURRET_ROTATE_DURATION = 0.2, -- seconds for turret rotation

    -- Background
    ENABLE_BACKGROUND = false,
    BACKGROUND_COLOR = {1, 1, 1},  -- used when ENABLE_BACKGROUND is false

    -- Post-processing
    ENABLE_VIGNETTE = false,
    VIGNETTE_SOFTNESS = 0.4,

    -- Colors
    GRID_LINE_COLOR = {0.18, 0.22, 0.3},
    GRID_BG_COLOR = {0.03, 0.03, 0.08},
    INFO_BAR_BG = {0.1, 0.12, 0.18},
    INFO_BAR_BORDER = {0.4, 0.45, 0.5},
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

    -- Sidebar
    SIDEBAR_WIDTH = 400,
    SIDEBAR_BG = {0.1, 0.1, 0.15},
    SIDEBAR_BORDER = {0.25, 0.25, 0.3},
    SIDEBAR_SECTION_BG = {0.15, 0.15, 0.2},
    SIDEBAR_SECTION_BORDER = {0.2, 0.2, 0.25},
    SIDEBAR_CARD_RADIUS = 8,
    -- Card colors (action types)
    CARD_THRUST_BG = {0.15, 0.2, 0.35},
    CARD_THRUST_HOVER = {0.2, 0.25, 0.4},
    CARD_ROTATE_BG = {0.15, 0.3, 0.15},
    CARD_ROTATE_HOVER = {0.2, 0.35, 0.2},
    CARD_TURRET_BG = {0.3, 0.25, 0.1},
    CARD_TURRET_HOVER = {0.35, 0.3, 0.15},
    CARD_SHOOT_BG = {0.3, 0.1, 0.1},
    CARD_SHOOT_HOVER = {0.35, 0.15, 0.15},
    CARD_SPECIAL_BG = {0.25, 0.1, 0.3},
    CARD_SPECIAL_HOVER = {0.3, 0.15, 0.35},
    -- Card selected state
    CARD_SELECTED_BG = {0.3, 0.35, 0.45},
    CARD_SELECTED_BORDER = {0.5, 0.6, 0.8},
    -- Button colors
    SIDEBAR_BTN_BG = {0.2, 0.25, 0.3},
    SIDEBAR_BTN_HOVER = {0.3, 0.35, 0.45},
    SIDEBAR_BTN_ACTIVE = {0.4, 0.5, 0.6},
}
