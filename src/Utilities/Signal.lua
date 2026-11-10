
-- Suslib Signal
-- src/Utilities/Signal.lua

local Signal = {}
Signal.__index = Signal

function Signal.new()
    return setmetatable({
        _listeners = {},
        _destroyed = false
    }, Signal)
end

function Signal:Connect(callback)
    assert(type(callback) == "function", "Callback must be a function")
    assert(not self._destroyed, "Signal has been destroyed")

    local connection = {
        Connected = true,
        _signal = self,
        _callback = callback
    }

    function connection:Disconnect()
        if not self.Connected then return end
        self.Connected = false
        self._callback = nil

        local listeners = self._signal._listeners
        local index = table.find(listeners, self)

        if index then
            table.remove(listeners, index)
        end
    end

    table.insert(self._listeners, connection)
    return connection
end

function Signal:Once(callback)
    local connection

    connection = self:Connect(function(...)
        connection:Disconnect()
        callback(...)
    end)

    return connection
end

function Signal:Fire(...)
    if self._destroyed then return end

    local listeners = table.clone(self._listeners)

    for _, connection in ipairs(listeners) do
        if connection.Connected and connection._callback then
            task.spawn(connection._callback, ...)
        end
    end
end

function Signal:Wait()
    assert(not self._destroyed, "Signal has been destroyed")

    local thread = coroutine.running()
    local connection

    connection = self:Once(function(...)
        task.spawn(thread, ...)
    end)

    return coroutine.yield()
end

function Signal:Destroy()
    if self._destroyed then return end

    self._destroyed = true

    for _, connection in ipairs(self._listeners) do
        connection.Connected = false
        connection._callback = nil
    end

    table.clear(self._listeners)
end

return Signal
