local Assets = {}

-- Helper: slice a spritesheet into quads
local function sliceSheet(img, frameW, frameH)
    local w = img:getWidth()
    local h = img:getHeight()
    local quads = {}
    for y = 0, h - frameH, frameH do
        for x = 0, w - frameW, frameW do
            table.insert(quads, love.graphics.newQuad(x, y, frameW, frameH, w, h))
        end
    end
    return quads
end

function Assets.load()
    -- Set default filter for pixel art
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- === SHIP SPRITES (200Starships Shaded style) ===
    Assets.ships = {
        love.graphics.newImage("assets/ships/200Starships/Shaded/ship_0.png"),
        love.graphics.newImage("assets/ships/200Starships/Shaded/ship_20.png"),
        love.graphics.newImage("assets/ships/200Starships/Shaded/ship_50.png"),
        love.graphics.newImage("assets/ships/200Starships/Shaded/ship_80.png"),
    }

    -- === LUNAR LANDER SHIP SHEET (320x192) ===
    Assets.lunarShipSheet = love.graphics.newImage("assets/ships/Spaceships.png")
    Assets.lunarShipQuads = sliceSheet(Assets.lunarShipSheet, 64, 64)

    -- === TURRETS (128x64, frames of 32x32) ===
    Assets.turretSheet = love.graphics.newImage("assets/ships/Turrets.png")
    Assets.turretQuads = sliceSheet(Assets.turretSheet, 32, 32)

    -- === GUNS (192x64, frames of 32x32) ===
    Assets.gunSheet = love.graphics.newImage("assets/ships/Guns.png")
    Assets.gunQuads = sliceSheet(Assets.gunSheet, 32, 32)

    -- === ASTEROIDS (256x64, frames of 64x64) ===
    Assets.asteroidSheet = love.graphics.newImage("assets/asteroids/Asteroids.png")
    Assets.asteroidQuads = sliceSheet(Assets.asteroidSheet, 64, 64)

    -- === ASTEROIDS FOREGROUND ===
    Assets.asteroidFgSheet = love.graphics.newImage("assets/asteroids/Asteroids_Foreground.png")
    Assets.asteroidFgQuads = sliceSheet(Assets.asteroidFgSheet, 64, 64)

    -- === DEBRIS ===
    Assets.debrisSheet = love.graphics.newImage("assets/asteroids/debris.png")
    Assets.debrisQuads = sliceSheet(Assets.debrisSheet, 64, 64)

    -- === SPACE BACKGROUND (512x512 nebula) ===
    Assets.background = love.graphics.newImage("assets/backgrounds/Small 512x512/Blue Nebula/blue_nebula_1.png")

    -- === STAR TILES (112x16, frames of 16x16) ===
    Assets.starSheet = love.graphics.newImage("assets/backgrounds/Star_Tiles.png")
    Assets.starQuads = sliceSheet(Assets.starSheet, 16, 16)

    -- === EXPLOSION EFFECT (256x32, frames of 32x32) ===
    Assets.explosionSheet = love.graphics.newImage("assets/effects/Explosion.png")
    Assets.explosionQuads = sliceSheet(Assets.explosionSheet, 32, 32)

    -- === THRUSTER EFFECTS ===
    Assets.thruster = {}
    for i = 1, 4 do
        Assets.thruster[i] = love.graphics.newImage("assets/effects/Thruster_0" .. i .. ".png")
    end
end

return Assets
