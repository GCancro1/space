local Class = require("ai.vendor.class")
local Config = require("config")
local MovementAnimator = Class:extend()

function MovementAnimator:init(fluxInstance)
    self.flux = fluxInstance
    self.objects = {}
    self.tileSize = 0
    self.offsetX = 0
    self.offsetY = 0
    self.collisionFn = nil
    self.activeCount = 0
end

function MovementAnimator:startMovement(objects, tileSize, offsetX, offsetY, collisionFn)
    self.tileSize = tileSize
    self.offsetX = offsetX
    self.offsetY = offsetY
    self.collisionFn = collisionFn
    self.objects = {}
    self.activeCount = 0

    for _, obj in ipairs(objects) do
        local mx = obj.momentum.x or 0
        local my = obj.momentum.y or 0
        if mx ~= 0 or my ~= 0 then
            local entry = {
                obj = obj,
                stepsX = {},
                stepsY = {},
                currentAxis = "x",
                stepIndex = 1,
                active = true,
            }

            for i = 1, math.abs(mx) do
                table.insert(entry.stepsX, mx > 0 and 1 or -1)
            end
            for i = 1, math.abs(my) do
                table.insert(entry.stepsY, my > 0 and 1 or -1)
            end

            if #entry.stepsX == 0 and #entry.stepsY == 0 then
                goto continue
            end

            self.objects[obj] = entry
            self.activeCount = self.activeCount + 1
            obj.tweenActive = true

            self:_startNextStep(entry)
            ::continue::
        end
    end
end

function MovementAnimator:_startNextStep(entry)
    local obj = entry.obj
    local dir = 0
    local axis = entry.currentAxis
    local steps

    if axis == "x" then
        steps = entry.stepsX
    else
        steps = entry.stepsY
    end

    if entry.stepIndex > #steps then
        if axis == "x" then
            entry.currentAxis = "y"
            entry.stepIndex = 1
            steps = entry.stepsY
            if #steps == 0 then
                self:_finish(entry)
                return
            end
            dir = steps[1]
        else
            self:_finish(entry)
            return
        end
    else
        dir = steps[entry.stepIndex]
    end

    local activeAxis = entry.currentAxis

    local newX, newY
    if activeAxis == "x" then
        newX = obj.x + dir
        newY = obj.y
    else
        newX = obj.x
        newY = obj.y + dir
    end

    if self.collisionFn then
        local ok = self.collisionFn(obj, newX, newY)
        if ok == false then
            self:_finish(entry)
            return
        end
    end

    obj.x = newX
    obj.y = newY

    local tweenTarget = {}
    if activeAxis == "x" then
        tweenTarget.drawX = newX
    else
        tweenTarget.drawY = newY
    end

    local t = self.flux:to(obj, Config.SHIP_ANIMATION_SPEED, tweenTarget)
    t:ease("quadout")
    t:oncomplete(function()
        entry.stepIndex = entry.stepIndex + 1
        self:_startNextStep(entry)
    end)
end

function MovementAnimator:_finish(entry)
    entry.active = false
    entry.obj.tweenActive = false
    self.activeCount = self.activeCount - 1
end

function MovementAnimator:update(dt)
end

function MovementAnimator:isDone()
    return self.activeCount == 0
end

return MovementAnimator
