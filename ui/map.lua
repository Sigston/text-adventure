local M = { }

function M.new(layout)
    local self = {
        layout = layout,
        nodeRectSize = 10,
        nodeLinkLength = 4,
        nodeLinkWidth = 1,
        canvas = love.graphics.newCanvas()
    }

    self.canvas:setFilter("nearest", "nearest")

    -- Transforms node coords to canvas coords
    local function nodeToCanvasXY(bounds, nx, ny)
        -- cy is flipped as everything up to this point is drawn with the axis in the top left
        local cx = (nx - bounds.minX) * (self.nodeRectSize + self.nodeLinkLength)
        local cy = (bounds.maxY - ny) * (self.nodeRectSize + self.nodeLinkLength)
        return cx, cy
    end

    local function drawEdges(mapData, byID)
        for _, e in ipairs(mapData.edges) do
            local a = byID[e.a]
            local b = byID[e.b]
            if (a.visited or a.current) and (b.visited or b.current) then
                local ax, ay = nodeToCanvasXY(mapData.bounds, a.x, a.y)
                local bx, by = nodeToCanvasXY(mapData.bounds, b.x, b.y)
                local acx, acy = ax + self.nodeRectSize/2, ay + self.nodeRectSize/2
                local bcx, bcy = bx + self.nodeRectSize/2, by + self.nodeRectSize/2
                local dx = bcx - acx
                local dy = bcy - acy

                if a.visited and b.visited then
                    layout.theme:set("mapNodeVisited")
                else
                    layout.theme:set("mapNodeHidden")
                end

                if math.abs(dx) >= math.abs(dy) then
                    -- horizontal link
                    local x = math.min(acx, bcx)
                    local y = acy - self.nodeLinkWidth/2
                    love.graphics.rectangle("fill", x, y, math.abs(dx), self.nodeLinkWidth)
                else
                    -- vertical link
                    local x = acx - self.nodeLinkWidth/2
                    local y = math.min(acy, bcy)
                    love.graphics.rectangle("fill", x, y, self.nodeLinkWidth, math.abs(dy))
                end
            end
        end
    end

    local function drawNodes(mapData)
        for _, n in ipairs(mapData.nodes) do
            if n.visited or n.current then
                local px, py = nodeToCanvasXY(mapData.bounds, n.x, n.y)

                if n.current then
                    layout.theme:set("mapNodeCurrent")
                elseif n.visited then
                    layout.theme:set("mapNodeVisited")
                else
                    layout.theme:set("mapNodeHidden")
                end

                love.graphics.rectangle("fill", px, py, self.nodeRectSize, self.nodeRectSize)
                love.graphics.setColor(0, 0, 0, 0.6)
                love.graphics.rectangle("line", px + 0.5, py + 0.5, self.nodeRectSize - 1, self.nodeRectSize - 1)
            end
        end
    end

    function self:draw(mapRect, font, mapData)
        -- Draw the background
        layout.theme:set("panel")
        love.graphics.rectangle("fill", mapRect.X, mapRect.Y, mapRect.W, mapRect.H)

        -- Get the inner rect (with padding)
        local inner = self.layout:inner(mapRect)
        if inner.W <= 0 or inner.H <=0 then return end

        -- Structure data a little so we can lookup
        local byID = {}
        for _, n in ipairs(mapData.nodes) do
            byID[n.id] = n
        end

        -- Get spans for working with: +1, as the bounds are 0 indexed.
        local spanX = (mapData.bounds.maxX - mapData.bounds.minX + 1)
        local spanY = (mapData.bounds.maxY - mapData.bounds.minY + 1)
        if spanX <= 0 or spanY <= 0 then return end

        -- Draw the edges and the nodes
        love.graphics.setCanvas(self.canvas)
        love.graphics.clear(0, 0, 0, 0)
        drawEdges(mapData, byID)
        drawNodes(mapData)
        love.graphics.setCanvas()

        local canvasW = spanX * self.nodeRectSize + (spanX - 1) * self.nodeLinkLength
        local canvasH = spanY * self.nodeRectSize + (spanY - 1) * self.nodeLinkLength
        local scale = math.min(inner.W / canvasW, inner.H / canvasH)
        local drawX = inner.X + (inner.W - canvasW * scale) / 2
        local drawY = inner.Y + (inner.H - canvasH * scale) / 2
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self.canvas, math.floor(drawX + 0.5), math.floor(drawY + 0.5), 0, scale, scale)
    end

    return self
end

return M