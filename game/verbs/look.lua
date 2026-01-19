local helper = require("game.verbs.verbhelper")

local function report(response, world, state)
    local lines = { world:getDesc(state.roomID, state) }
    local entityLines = helper.printEntities(state.roomID, world, state)
    local exitLines = helper.printExits(world:rooms()[state.roomID].exits)
    if entityLines then table.insert(lines, entityLines) end
    if exitLines then table.insert(lines, exitLines) end
    return lines, false
end

return { report = report }