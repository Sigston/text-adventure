local utf8 = require("utf8")

local M = { }

function M.new(layout)
    local self = {
        layout = layout,
        input = "",
        draftInput = "",
        history = { },
        historyPointer = 0,
        caretByte = 1,
        prefix = "> "
    }

    local function resetCaret()
        self.caretByte = #self.input + 1
    end

    local function insertAt(s, bytePos, ins)
        return s:sub(1, bytePos - 1) .. ins .. s:sub(bytePos)
    end

    function self:addHistory(line)
        table.insert(self.history, line)
        self.historyPointer = 0
        self.draftInput = ""
    end

    function self:textinput(t)
        self.input = insertAt(self.input, self.caretByte, t)
        self.caretByte = self.caretByte + utf8.len(t)
    end

    function self:keypressed(key)
        if key == "backspace" then
            if self.caretByte <= 1 then return end
            local prev = utf8.offset(self.input, -1, self.caretByte)
            if prev then
                self.input = self.input:sub(1, prev - 1) .. self.input:sub(self.caretByte)
                self.caretByte = prev
            end
        elseif key == "return" then
            self:addHistory(self.input)
            local returnInput = self.input
            self.input = ""
            resetCaret()
            return "submit", returnInput
        elseif key == "escape" then
            return "quit"
        elseif key == "pageup" then
            return "scroll", 3
        elseif key == "pagedown" then
            return "scroll", -3
        elseif key == "left" then
            local prev = utf8.offset(self.input, -1, self.caretByte)
            if prev then self.caretByte = prev end
        elseif key == "right" then
            local prev = utf8.offset(self.input, 2, self.caretByte)
            if prev then self.caretByte = prev end
        elseif key == "up" then
            if #self.history == 0 then return end
            if self.historyPointer == 0 then
                self.draftInput = self.input
            end
            self.historyPointer = math.min(self.historyPointer + 1, #self.history)
            self.input = self.history[#self.history - self.historyPointer + 1]
            resetCaret()
        elseif key == "down" then
            if #self.history == 0 then return end
            if self.historyPointer == 0 then return end
            self.historyPointer = self.historyPointer - 1
            if self.historyPointer == 0 then
                self.input = self.draftInput
            else
                self.input = self.history[#self.history - self.historyPointer + 1]
            end
            resetCaret()
        elseif key == "m" and love.keyboard.isDown("lctrl") then
            self.layout:toggleMap()
        elseif key == "i" and love.keyboard.isDown("lctrl") then
            self.layout:toggleInv()
        elseif key == "u" and love.keyboard.isDown("lctrl") then
            self.input = ""
            resetCaret()
        end
    end

    function self:draw(inputRect, font)
        local textRect = self.layout:inner(inputRect)
        love.graphics.setFont(font)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", inputRect.X, inputRect.Y, inputRect.W, inputRect.H)
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(self.prefix .. self.input, textRect.X, textRect.Y)

        local leftBytes = self.input:sub(1, self.caretByte - 1)
        local caretX = textRect.X + font:getWidth(self.prefix .. leftBytes)
        local caretY = textRect.Y
        local caretH = font:getHeight()
        local cellW = font:getWidth(" ")
        local nextByte = utf8.offset(self.input, 2, self.caretByte) or (#self.input + 2)
        local ch = self.input:sub(self.caretByte, nextByte - 1)
        if ch == "" then ch = " " end

        self.layout.theme:set("caretFill")
        love.graphics.rectangle("fill", caretX, caretY, cellW, caretH)
        self.layout.theme:set("caretText")
        love.graphics.print(ch, caretX, caretY)
    end

    return self
end

return M