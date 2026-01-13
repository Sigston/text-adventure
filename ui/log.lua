local M = { }

local function _clamp(x, lo, hi)
    if x < lo then return lo end
    if x > hi then return hi end
    return x
end

function M.new(layout)
    local self = {
        layout = layout,
        lines = { },
        start = 1,
        capacity = 5
    }

    function self:setCapacity(logRect)
        local textRect = self.layout:inner(logRect)
        self.capacity = math.max(1, math.floor(textRect.H / self.layout.lineHeight))
    end

    function self:add(line)
        table.insert(self.lines, line)
        if (#self.lines - self.start + 1) > self.capacity then
            self.start = math.max(1, #self.lines - self.capacity + 1) -- this is wrong
        end
    end

    function self:scroll(dLines)
        local maxStart = math.max(1, #self.lines - self.capacity + 1)
        self.start = _clamp(self.start  - dLines, 1, maxStart)
    end

    function self:draw(logRect, font)
        self:setCapacity(logRect)
        local textRect = self.layout:inner(logRect)
        love.graphics.setFont(font)
        layout.theme:set("bg")
        love.graphics.rectangle("fill", logRect.X, logRect.Y, logRect.W, logRect.H)
        layout.theme:set("text")
        for i = 0, math.min(self.capacity, #self.lines) - 1 do
            local idx = self.start + i
            local line = self.lines[idx]
            if line then
                love.graphics.print(line, textRect.X, textRect.Y + i * self.layout.lineHeight)
            end
        end
    end

    return self
end

return M