local M = {}

function M.new(layout)
    local self = {
        layout = layout
    }
    
    function self:draw(headerRect, font, roomName)
        local textRect = self.layout:inner(headerRect)
        love.graphics.setFont(font)
        self.layout.theme:set("headerBg")
        love.graphics.rectangle("fill", headerRect.X, headerRect.Y, headerRect.W, headerRect.H)
        self.layout.theme:set("headerText")
        love.graphics.print(roomName, textRect.X, textRect.Y)
    end

    return self
end

return M