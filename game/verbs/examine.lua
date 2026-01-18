local helper = require("game.verbs.verbhelper")

local function resolve(world, state)
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
    local lines = { }
    if object ~= "" then
        local key = world:resolveAlias(object, state, entities)
        if key then
            local desc = world.entities[key].desc
            if world.entities[key].isContainer or world.entities[key].kind == "door" then
                if state.open[key] then
                    local contents = world:getNames(state:children(key))
                    if #contents > 0 then
                        desc = desc .. " It is open. Inside you see" .. helper.aLister(contents)
                    else
                        desc = desc .. " It is open."
                    end
                else
                    if state.locked[key] then
                        desc = desc .. " It is closed and locked."
                    else
                        desc = desc .. " It is closed."
                    end
                end
            end
            table.insert(lines, desc)
        else table.insert(lines, "There is no " .. object .. " here.") end
    else table.insert(lines, "Examine what?") end
    return lines
end

local function report(response)
    return response, false
end

return { resolve = resolve, act = act, report = report }