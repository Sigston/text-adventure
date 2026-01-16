local helper = require("game.verbs.verbhelper")

local function report(response, world, state)
    -- The desc for the room.
    local lines = { world:rooms()[state.roomID].desc }
    -- Listed entities.
    local entityLines = helper.printEntities(state.roomID, world, state)
    -- Exits.
    local exitLines = helper.printExits(world:rooms()[state.roomID].exits)
    if entityLines then table.insert(lines, entityLines) end
    if exitLines then table.insert(lines, exitLines) end
    return lines, false
end

return { report = report }