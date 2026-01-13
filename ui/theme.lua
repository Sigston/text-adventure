local M = {}

function M.new()
    local self = {
        c = {
            bg         = { 0.000, 0.169, 0.212, 1.0 }, -- base03  #002b36
            panel      = { 0.027, 0.212, 0.259, 1.0 }, -- base02  #073642
            headerBg   = { 0.149, 0.545, 0.824, 1.0 }, -- blue    #268bd2
            headerText = { 0.000, 0.169, 0.212, 1.0 }, -- base03  #002b36 (dark text)
            border     = { 0.345, 0.431, 0.459, 1.0 }, -- base01  #586e75
            text       = { 0.513, 0.580, 0.588, 1.0 }, -- base0   #839496
            textHi     = { 0.933, 0.910, 0.835, 1.0 }, -- base2   #eee8d5

            -- Accents
            accent  = { 0.149, 0.545, 0.824, 1.0 }, -- blue    #268bd2
            warn    = { 0.796, 0.294, 0.086, 1.0 }, -- orange  #cb4b16
            good    = { 0.522, 0.600, 0.000, 1.0 }, -- green   #859900

            -- Map
            mapNodeVisited = { 0.513, 0.580, 0.588, 1.0 }, -- base0
            mapNodeCurrent = { 0.710, 0.537, 0.000, 1.0 }, -- yellow  #b58900
            mapNodeHidden  = { 0.231, 0.259, 0.278, 1.0 }, -- darker grey
            mapEdgeVisited = { 0.345, 0.431, 0.459, 1.0 }, -- base01
            mapEdgeFaint   = { 0.231, 0.259, 0.278, 1.0 }, -- faint

            -- Input caret
            caretFill = { 0.000, 0.000, 0.000, 1.0 },
            caretText = { 0.933, 0.910, 0.835, 1.0 },
        }
    }

    function self:get(name)
        return self.c[name]
    end

    function self:set(name)
        local col = self.c[name]
        love.graphics.setColor(col[1], col[2], col[3], col[4] or 1)
    end

    return self
end

return M