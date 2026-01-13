local M = { }

function M.new(layout)
    local self = {
        layout = layout
    }

    function self:draw(invRect)
        layout.theme:set("panel")
        love.graphics.rectangle("fill", invRect.X, invRect.Y, invRect.W, invRect.H)
    end

    return self
end

return M