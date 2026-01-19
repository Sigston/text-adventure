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
    if object == "" then return { "Examine what?" } end
    local direct, result = world:resolveAlias(object.direct, state, entities)
    if not direct then
        if result == "not_found" then return { "There is no " .. world:getName(direct):lower() .. " here."}
        elseif result == "disambig" then return { result }
        else return end
    end
    local lines = { }
    local desc = world.entities[direct].desc
    if world.entities[direct].isContainer or world.entities[direct].kind == "door" then
        if state.open[direct] then
            local contents = world:getNames(state:children(direct))
            if #contents > 0 then
                desc = desc .. " It is open. Inside you see" .. helper.aLister(contents)
            else
                desc = desc .. " It is open."
            end
        else
            if state.locked[direct] then
                desc = desc .. " It is closed and locked."
            else
                desc = desc .. " It is closed."
            end
        end
    end
    table.insert(lines, desc)
    return lines
end

local function report(response)
    return response, false
end

return { resolve = resolve, act = act, report = report }