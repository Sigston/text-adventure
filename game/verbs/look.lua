local helper = require("game.verbs.verbhelper")

local function act(entities, object, world, state)
    local lines = { world:getDesc(state.roomID, state) }
    local entityLines = helper.printEntities(state.roomID, world, state)
    local exitLines = helper.printExits(world:rooms()[state.roomID].exits)
    if entityLines then table.insert(lines, entityLines) end
    if exitLines then table.insert(lines, exitLines) end
    return lines
end

return { act = act }