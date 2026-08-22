-- ==============================================================================
-- HoshiUI — Flipper High-Performance Spring Physics Engine
-- Replaces heavy TweenService with 60+ FPS mathematical spring simulation
-- ==============================================================================

local RunService = game:GetService("RunService")
local Signal = loadstring and nil -- will be injected or required

local Flipper = {}

-- Spring Goal Generator
local Spring = {}
Spring.__index = Spring

function Spring.new(targetValue, options)
    options = options or {}
    return setmetatable({
        _targetValue = targetValue,
        _frequency = options.frequency or 4,
        _dampingRatio = options.dampingRatio or 1,
    }, Spring)
end

function Spring:step(state, dt)
    local d = self._dampingRatio
    local f = self._frequency * 2 * math.pi
    local g = self._targetValue
    local p0 = state.position
    local v0 = state.velocity

    local offset = p0 - g
    local decay = math.exp(-d * f * dt)

    local p1, v1
    if d == 1 then
        p1 = (offset * (1 + f * dt) + v0 * dt) * decay + g
        v1 = (v0 * (1 - f * dt) - offset * (f * f * dt)) * decay
    elseif d < 1 then
        local c = math.sqrt(1 - d * d)
        local i = math.cos(f * c * dt)
        local j = math.sin(f * c * dt)
        local z = (v0 + offset * (d * f)) / (f * c)
        p1 = (offset * i + z * j) * decay + g
        v1 = (v0 * (i - d * f * dt) - (offset * (f * c) + z * (d * f)) * j) * decay
    else
        local c = math.sqrt(d * d - 1)
        local r1 = -f * (d - c)
        local r2 = -f * (d + c)
        local co2 = (v0 - offset * r1) / (2 * f * c)
        local co1 = offset - co2
        local e1 = math.exp(r1 * dt)
        local e2 = math.exp(r2 * dt)
        p1 = co1 * e1 + co2 * e2 + g
        v1 = co1 * r1 * e1 + co2 * r2 * e2
    end

    local complete = math.abs(v1) < 0.001 and math.abs(p1 - g) < 0.001
    if complete then
        p1 = g
        v1 = 0
    end

    return {
        position = p1,
        velocity = v1,
        complete = complete,
    }
end

-- Instant Goal Generator
local Instant = {}
Instant.__index = Instant

function Instant.new(targetValue)
    return setmetatable({ _targetValue = targetValue }, Instant)
end

function Instant:step()
    return {
        position = self._targetValue,
        velocity = 0,
        complete = true,
    }
end

-- Linear Goal Generator
local Linear = {}
Linear.__index = Linear

function Linear.new(targetValue, options)
    options = options or {}
    return setmetatable({
        _targetValue = targetValue,
        _velocity = options.velocity or 1,
    }, Linear)
end

function Linear:step(state, dt)
    local target = self._targetValue
    local current = state.position
    local speed = self._velocity * dt

    local delta = target - current
    local sign = math.sign(delta)
    local stepAmount = sign * math.min(math.abs(delta), speed)
    local nextPos = current + stepAmount
    local complete = math.abs(nextPos - target) < 0.0001

    return {
        position = complete and target or nextPos,
        velocity = complete and 0 or (self._velocity * sign),
        complete = complete,
    }
end

-- Single Motor
local SingleMotor = {}
SingleMotor.__index = SingleMotor

function SingleMotor.new(initialValue)
    local self = setmetatable({
        _state = { position = initialValue or 0, velocity = 0, complete = true },
        _goal = nil,
        _connections = {},
        _running = false,
        _connection = nil,
    }, SingleMotor)
    return self
end

function SingleMotor:onStep(fn)
    table.insert(self._connections, fn)
    fn(self._state.position)
    return {
        Disconnect = function()
            local idx = table.find(self._connections, fn)
            if idx then table.remove(self._connections, idx) end
        end
    }
end

function SingleMotor:setGoal(goal)
    self._goal = goal
    self._state.complete = false
    if not self._running then
        self._running = true
        self._connection = RunService.RenderStepped:Connect(function(dt)
            if not self._goal then
                self:stop()
                return
            end
            local newState = self._goal:step(self._state, dt)
            self._state = newState
            for _, fn in ipairs(self._connections) do
                fn(newState.position)
            end
            if newState.complete then
                self:stop()
            end
        end)
    end
end

function SingleMotor:getValue()
    return self._state.position
end

function SingleMotor:stop()
    if self._connection then
        self._connection:Disconnect()
        self._connection = nil
    end
    self._running = false
end

function SingleMotor:destroy()
    self:stop()
    self._connections = {}
end

-- Group Motor
local GroupMotor = {}
GroupMotor.__index = GroupMotor

function GroupMotor.new(initialValues)
    local states = {}
    for k, v in pairs(initialValues) do
        states[k] = { position = v, velocity = 0, complete = true }
    end
    return setmetatable({
        _states = states,
        _goals = {},
        _connections = {},
        _running = false,
        _connection = nil,
    }, GroupMotor)
end

function GroupMotor:onStep(fn)
    table.insert(self._connections, fn)
    local pos = {}
    for k, v in pairs(self._states) do pos[k] = v.position end
    fn(pos)
    return {
        Disconnect = function()
            local idx = table.find(self._connections, fn)
            if idx then table.remove(self._connections, idx) end
        end
    }
end

function GroupMotor:setGoal(goals)
    self._goals = goals
    for k in pairs(goals) do
        if self._states[k] then
            self._states[k].complete = false
        end
    end
    if not self._running then
        self._running = true
        self._connection = RunService.RenderStepped:Connect(function(dt)
            local allComplete = true
            local currentPositions = {}

            for k, goal in pairs(self._goals) do
                local st = self._states[k]
                if st and not st.complete then
                    local newSt = goal:step(st, dt)
                    self._states[k] = newSt
                    if not newSt.complete then
                        allComplete = false
                    end
                end
                if self._states[k] then
                    currentPositions[k] = self._states[k].position
                end
            end

            for _, fn in ipairs(self._connections) do
                fn(currentPositions)
            end

            if allComplete then
                self:stop()
            end
        end)
    end
end

function GroupMotor:stop()
    if self._connection then
        self._connection:Disconnect()
        self._connection = nil
    end
    self._running = false
end

function GroupMotor:destroy()
    self:stop()
    self._connections = {}
end

Flipper.Spring = Spring
Flipper.Instant = Instant
Flipper.Linear = Linear
Flipper.SingleMotor = SingleMotor
Flipper.GroupMotor = GroupMotor

return Flipper
