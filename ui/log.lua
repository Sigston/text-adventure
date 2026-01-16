local M = { }

local function _clamp(x, lo, hi)
    if x < lo then return lo end
    if x > hi then return hi end
    return x
end

local function splitParas(s)
    local out = {}
    s = (s or ""):gsub("\r\n", "\n")
    for line in (s.. "\n"):gmatch("(.-)\n") do
        out[#out+1] = line
    end
    return out
end


function M.new(layout)
    local self = {
        layout = layout,
        entries = { },
        lines = { },
        start = 1,
        capacity = 5,
        wrapW = nil,
        wrapFont = nil,
    }

    function self:setCapacity(logRect)
        local textRect = self.layout:inner(logRect)
        self.capacity = math.max(1, math.floor(textRect.H / self.layout.lineHeight))
    end

    function self:add(text)
        local paras = splitParas(text)
        for _, p in ipairs(paras) do
            self.entries[#self.entries+1] = p
        end
        self.wrapW = nil
    end

    function self:rewrap(font, wrapW)
        self.lines = {}
        for _, p in ipairs(self.entries) do
            if p == "" then
                self.lines[#self.lines+1] = ""
            else
                local _, wrapped = font:getWrap(p, wrapW)
                for _, wline in ipairs(wrapped) do
                    self.lines[#self.lines+1] = wline
                end
            end
        end
        self.wrapW = wrapW
        self.wrapFont = font
        self.start = math.max(1, #self.lines - self.capacity + 1)
    end

    function self:scroll(dLines)
        local maxStart = math.max(1, #self.lines - self.capacity + 1)
        self.start = _clamp(self.start  - dLines, 1, maxStart)
    end

    function self:draw(logRect, font)
        self:setCapacity(logRect)
        local textRect = self.layout:inner(logRect)

        if self.wrapW ~= textRect.W or self.wrapFont ~= font then
            self:rewrap(font, textRect.W)
        end

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