local Inventory = require("game.inventory")

local function listItems(keys, world)
    local out = { }
    for i = 1, #keys do
        table.insert(out, world:items()[keys[i]].name)
    end
    table.sort(out)
    return out
end

local function act(entities, object, world, state, verbs)
    local lines = listItems(Inventory.list(state), world)
    if #lines < 1 then lines = { "There is nothing in your inventory." } end
    return lines
end

return { act = act }