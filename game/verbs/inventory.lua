local function listItems(keys, world)
    local out = { }
    for i = 1, #keys do
        table.insert(out, world:items()[keys[i]].name)
    end
    table.sort(out)
    return out
end

local function report(response, world, state)
    local lines = listItems(state:children(state.invID), world)
    return lines, false
end

return { report = report }