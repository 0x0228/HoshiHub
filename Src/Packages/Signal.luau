-- ==============================================================================
-- HoshiUI — Fast Pure Luau Linked-List Signal
-- Zero BindableEvent overhead • Instant O(1) Disconnect • Zero Memory Leaks
-- ==============================================================================

local Signal = {}
Signal.__index = Signal

local Connection = {}
Connection.__index = Connection

function Connection.new(signal, fn)
    return setmetatable({
        _signal = signal,
        _fn = fn,
        _next = nil,
        _prev = nil,
        Connected = true,
    }, Connection)
end

function Connection:Disconnect()
    if not self.Connected then return end
    self.Connected = false

    if self._signal._head == self then
        self._signal._head = self._next
    end
    if self._signal._tail == self then
        self._signal._tail = self._prev
    end
    if self._prev then
        self._prev._next = self._next
    end
    if self._next then
        self._next._prev = self._prev
    end

    self._signal = nil
    self._fn = nil
    self._next = nil
    self._prev = nil
end

function Connection:Destroy()
    self:Disconnect()
end

function Signal.new()
    return setmetatable({
        _head = nil,
        _tail = nil,
    }, Signal)
end

function Signal:Connect(fn)
    assert(type(fn) == "function", "Signal:Connect expects a function")
    local conn = Connection.new(self, fn)
    if not self._head then
        self._head = conn
        self._tail = conn
    else
        conn._prev = self._tail
        self._tail._next = conn
        self._tail = conn
    end
    return conn
end

function Signal:Once(fn)
    local conn
    conn = self:Connect(function(...)
        conn:Disconnect()
        fn(...)
    end)
    return conn
end

function Signal:Fire(...)
    local node = self._head
    while node do
        local nextNode = node._next
        if node.Connected and node._fn then
            task.spawn(node._fn, ...)
        end
        node = nextNode
    end
end

function Signal:Wait()
    local thread = coroutine.running()
    local conn
    conn = self:Connect(function(...)
        conn:Disconnect()
        task.spawn(thread, ...)
    end)
    return coroutine.yield()
end

function Signal:Destroy()
    local node = self._head
    while node do
        local nextNode = node._next
        node.Connected = false
        node._signal = nil
        node._fn = nil
        node._next = nil
        node._prev = nil
        node = nextNode
    end
    self._head = nil
    self._tail = nil
end

return Signal
