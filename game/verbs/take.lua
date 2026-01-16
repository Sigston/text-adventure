local helper = require("game.verbs.verbhelper")

local function doTake(key, state)
    return state:move(key, state.invID)
end

local function resolve(world, state)
    -- You can take listed items, and anything inside listed items which are open.
    local entities = helper.xEntities(state.roomID, world, state)
    for i = 1, #entities do
        if world.entities[entities[i]].isContainer == true and state.open[entities[i]] then
            local contents = state:children(entities[i])
            for i = 1, #contents do table.insert(entities, contents[i]) end
        end
    end
    return entities
end

local function act(entities, object, world, state)
    local response = { }
    if object ~= "" then
        local key = world:resolveAlias(object, state, entities)
        if key then
            if world.entities[key].portable then
                local result = doTake(key, state)
                if result == "success" then
                    table.insert(response, "You take the " .. world:items()[key].name:lower() .. ".")
                else table.insert(response, "Something went wrong.") end
            else table.insert(response, "You can't take this.") end
        else table.insert(response, "There is no " .. object .. " here.") end
    else table.insert(response, "Take what?") end
    return response
end

local function report(response)
    return response, false
end

return { resolve = resolve, act = act, report = report, doVerb = doTake }