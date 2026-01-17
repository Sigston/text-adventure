local M = { }

local InvSys = require("game.inventory")

local function inRect(x, y, rect)
    return (x >= rect.X and x <= rect.X + rect.W) and (y >= rect.Y and y <= rect.Y + rect.H)
end

local function drawVerticalTab(layout, tabRect, title, hovered)
    if tabRect.W <= 0 or tabRect.H <= 0 then return end

    if hovered then
        layout.theme:set("accent")
    else
        layout.theme:set("panel")
    end
    love.graphics.rectangle("fill", tabRect.X, tabRect.Y, tabRect.W, tabRect.H)

    layout.theme:set("border")
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", tabRect.X + 0.5, tabRect.Y + 0.5, tabRect.W - 1, tabRect.H - 1)

    layout.theme:set(hovered and "headerText" or "textHi")
    love.graphics.push()
    love.graphics.translate(tabRect.X + tabRect.W / 2, tabRect.Y + tabRect.H / 2)
    love.graphics.rotate(math.pi / 2)
    love.graphics.printf(title, -tabRect.H / 2, -layout.lineHeight / 2, tabRect.H, "center")
    love.graphics.pop()
end


function M.new(layout)
    local self = {
        layout = layout
    }

    local function gridGeometry(contentRect)
        local inner = layout:inner(contentRect)

        local titleH = layout.lineHeight + 6
        local footerH = layout.lineHeight + 2

        local gridRect = {
            X = inner.X,
            Y = inner.Y + titleH,
            W = inner.W,
            H = math.max(0, inner.H - titleH - footerH),
        }

        local gap = 10
        local cellW = (gridRect.W - gap * 2) / 3
        local cellH = (gridRect.H - gap * 2) / 3
        local cell = math.floor(math.max(12, math.min(cellW, cellH)))

        local totalW = cell * 3 + gap * 2
        local totalH = cell * 3 + gap * 2
        local startX = gridRect.X + math.floor((gridRect.W - totalW) / 2)
        local startY = gridRect.Y + math.floor((gridRect.H - totalH) / 2)

        return {
            inner = inner,
            titleH = titleH,
            footerH = footerH,
            startX = startX,
            startY = startY,
            cell = cell,
            gap = gap,
        }
    end

    local function hitTest(contentRect, mx, my)
        local g = gridGeometry(contentRect)
        for i = 1, InvSys.MAX_SLOTS do
            local row = math.floor((i - 1) / 3)
            local col = (i - 1) % 3
            local x = g.startX + col * (g.cell + g.gap)
            local y = g.startY + row * (g.cell + g.gap)
            if mx >= x and mx <= x + g.cell and my >= y and my <= y + g.cell then
                return i
            end
        end
        return nil
    end

    function self:draw(invRect, font, world, state)
        layout.theme:set("panel")
        love.graphics.rectangle("fill", invRect.X, invRect.Y, invRect.W, invRect.H)

        -- Tab lives on the *inner* edge (left side for the inventory)
        local tabW = layout.tabClosedWidth
        local tabRect = {
            X = invRect.X,
            Y = invRect.Y,
            W = math.min(tabW, invRect.W),
            H = invRect.H,
        }

        local mx, my = love.mouse.getPosition()
        drawVerticalTab(layout, tabRect, "Inventory", inRect(mx, my, tabRect))
        
        -- If collapsed, show only the tab.
        if invRect.W <= tabW + 5 then
            return
        end

        -- "Wipe" animation: keep content laid out at full open width, and clip to the
        -- currently visible area. This avoids the grid shrinking as the panel animates.
        local fullPanelW = layout.tabOpenWidth
        local fullContentRect = {
            X = invRect.X + tabW,
            Y = invRect.Y,
            W = fullPanelW - tabW,
            H = invRect.H,
        }

        local visibleContentRect = {
            X = invRect.X + tabW,
            Y = invRect.Y,
            W = math.max(0, invRect.W - tabW),
            H = invRect.H,
        }

        -- Clip to the visible content area.
        love.graphics.setScissor(visibleContentRect.X, visibleContentRect.Y, visibleContentRect.W, visibleContentRect.H)

        local g = gridGeometry(fullContentRect)
        love.graphics.setFont(font)

        -- Footer count
        local count = InvSys.count(state)
        layout.theme:set("text")
        love.graphics.printf(
            ("%d/%d"):format(count, InvSys.MAX_SLOTS),
            g.inner.X,
            g.inner.Y + g.inner.H - g.footerH + 2,
            g.inner.W,
            "right"
        )

        local grid = InvSys.slotGrid(state)
        local hover = nil
        if visibleContentRect.W > 0 and inRect(mx, my, visibleContentRect) then
            hover = hitTest(fullContentRect, mx, my)
        end

        for i = 1, InvSys.MAX_SLOTS do
            local row = math.floor((i - 1) / 3)
            local col = (i - 1) % 3
            local x = g.startX + col * (g.cell + g.gap)
            local y = g.startY + row * (g.cell + g.gap)

            local id = grid[i]
            local isHover = (hover == i)

            -- Card background
            if isHover then
                layout.theme:set("bg")
            else
                layout.theme:set("panel")
            end
            love.graphics.rectangle("fill", x, y, g.cell, g.cell, 6, 6)

            -- Border
            if isHover then
                layout.theme:set("accent")
            else
                layout.theme:set("border")
            end
            love.graphics.setLineWidth(1)
            love.graphics.rectangle("line", x, y, g.cell, g.cell, 6, 6)

            -- Text
            local label
            if id then
                local ent = (world and world.entities) and world.entities[id] or nil
                label = (ent and ent.name) and ent.name or id
                layout.theme:set("textHi")
            else
                label = ""
                layout.theme:set("text")
            end

            local pad = 6
            love.graphics.printf(
                label,
                x + pad,
                y + math.floor(g.cell / 2) - math.floor(layout.lineHeight / 2),
                g.cell - pad * 2,
                "center"
            )
        end
        
        -- Clear clip.
        love.graphics.setScissor()
    end

    return self
end

return M