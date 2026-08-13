local Class = require("ai.vendor.class")
local TweenGroup = Class:extend()

function TweenGroup:init(fluxInstance)
    self.flux = fluxInstance
    self.steps = {}
    self.currentStep = 1
    self.currentTween = nil
    self.waitTimer = 0
    self.done = true
    self.completeCallback = nil
    self.stepCompleteCallback = nil
end

function TweenGroup:tween(obj, duration, properties, easing)
    self.done = false
    table.insert(self.steps, {
        type = "tween",
        obj = obj,
        duration = duration,
        properties = properties,
        easing = easing or "quadout",
    })
    return self
end

function TweenGroup:wait(duration)
    self.done = false
    table.insert(self.steps, {
        type = "wait",
        duration = duration,
    })
    return self
end

function TweenGroup:onComplete(fn)
    self.completeCallback = fn
    return self
end

function TweenGroup:onStepComplete(fn)
    self.stepCompleteCallback = fn
    return self
end

function TweenGroup:isDone()
    return self.done
end

function TweenGroup:reset()
    if self.currentTween then
        self.currentTween:stop()
        self.currentTween = nil
    end
    self.currentStep = 1
    self.waitTimer = 0
    self.done = #self.steps == 0
end

function TweenGroup:advance()
    if self.stepCompleteCallback then
        self.stepCompleteCallback(self.currentStep)
    end

    self.currentStep = self.currentStep + 1

    if self.currentStep > #self.steps then
        self.done = true
        if self.completeCallback then
            self.completeCallback()
        end
        return
    end

    self:startStep(self.currentStep)
end

function TweenGroup:startStep(index)
    local step = self.steps[index]
    if not step then
        self.done = true
        if self.completeCallback then
            self.completeCallback()
        end
        return
    end

    if step.type == "tween" then
        local t = self.flux:to(step.obj, step.duration, step.properties)
        t:ease(step.easing)
        t:oncomplete(function()
            self.currentTween = nil
            self:advance()
        end)
        self.currentTween = t
    elseif step.type == "wait" then
        self.waitTimer = step.duration
    end
end

function TweenGroup:update(dt)
    if self.done then return end

    if self.currentStep > #self.steps then
        self.done = true
        if self.completeCallback then
            self.completeCallback()
        end
        return
    end

    local step = self.steps[self.currentStep]

    if step.type == "wait" then
        self.waitTimer = self.waitTimer - dt
        if self.waitTimer <= 0 then
            self:advance()
        end
    end
end

return TweenGroup
