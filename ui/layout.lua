local M = {}

local Theme = require("ui.theme")

function M.new()
    local self = {
        headerHeight = 40, 
        inputHeight = 40, 
        padding = 12,
        lineHeight = 18,
        mapOpen = true,
        invOpen = true,
        mapChanging = false,
        invChanging = false,
        changeSpeed = 2500,
        tabOpenWidth = 300,
        tabClosedWidth = 20,
        mapWidth = 0,
        invWidth = 0,
        theme = Theme.new()
    }
    self.mapWidth = self.tabOpenWidth
    self.invWidth = self.tabOpenWidth

    self.cursors = {
        hand = love.mouse.getSystemCursor("hand"),
        arrow = love.mouse.getSystemCursor("arrow")
    }

    local function inRect(x, y, rect)
        if (x > rect.X and x < rect.X + rect.W) and (y > rect.Y and y < rect.Y + rect.H) then
            return true
        end
        return false
    end

    function self:animatePanel(widthKey, openKey, changingKey, dt)
        if not self[changingKey] then return end
        local open = self[openKey]
        local target = open and self.tabClosedWidth or self.tabOpenWidth
        local dir = open and -1 or  1
        local nextW = self[widthKey] + dir * self.changeSpeed * dt
        nextW = (dir < 0) and math.max(target, nextW) or math.min(target, nextW)
        self[widthKey] = nextW
        if nextW == target then
            self[openKey] = not open
            self[changingKey] = false
        end
        self:handleMouseMove(love.mouse.getPosition())
    end

    function self:update(dt)
        self:animatePanel("mapWidth", "mapOpen", "mapChanging", dt)
        self:animatePanel("invWidth", "invOpen", "invChanging", dt)
    end

    function self:rects()
        local w, h = love.graphics.getDimensions()

        local headerRect = { X = 0, Y = 0, W = w, H = self.headerHeight }
        local logRect = { X = self.mapWidth, Y = self.headerHeight, W = w - self.mapWidth - self.invWidth, H = h - self.headerHeight - self.inputHeight }
        local inputRect = { X = self.mapWidth, Y = h - self.inputHeight, W = w - self.mapWidth - self.invWidth, H = self.inputHeight }
        local mapRect = { X = 0, Y = self.headerHeight, W = self.mapWidth, H = h - self.headerHeight}
        local invRect = { X = w - self.invWidth, Y = self.headerHeight, W = self.invWidth, H = h - self.headerHeight }
        return headerRect, logRect, inputRect, mapRect, invRect
    end

    function self:drawBackground()
        self.theme:set("bg")
        local w, h = love.graphics.getDimensions()
        love.graphics.rectangle("fill", 0, 0, w, h)
    end

    function self:inner(rect)
        return { X = rect.X + self.padding, Y = rect.Y + self.padding, W = rect.W - self.padding * 2, H = rect.H - self.padding * 2}
    end

    function self:toggleMap()
        self.mapChanging = true
    end

    function self:toggleInv()
        self.invChanging = true
    end

    function self:handleClick(x, y, button)
        local _, _, _, mapRect, invRect = self:rects()
        if inRect(x, y, mapRect) then
            self.mapChanging = true
        elseif inRect(x, y, invRect) then
            self.invChanging = true
        end
    end

    function self:handleMouseMove(x, y)
        local _, _, _, mapRect, invRect = self:rects()
        if inRect(x, y, mapRect) then
            love.mouse.setCursor(self.cursors.hand)
        elseif inRect(x, y, invRect) then
            love.mouse.setCursor(self.cursors.hand)
        else
            love.mouse.setCursor(self.cursors.arrow)
        end
    end

    return self
end

return M