local helper = require("game.verbs.verbhelper")

local function doClose(key, state)
    state.open[key] = false
end

local function resolve(world, state)
    return helper.xEntities(state.roomID, world, state)
end

local function act(entities, object, world, state)
    local lines = {}
    if object == "" then return { "Close what?" } end
    local key = world:resolveAlias(object, state, entities)
    if key then
        local entity = world.entities[key]
        if entity.kind == "item" then
            if entity.openable then
                if state.open[key] then
                    doClose(key, state)
                    table.insert(lines, "You close the " .. entity.name:lower() .. ".")
                else
                    table.insert(lines, "The " .. entity.name:lower() .. " is already closed.")
                end
            else table.insert(lines, "You can't close that.") end
        elseif entity.kind == "door" then
            print("HI")
        else table.insert(lines, "You can't close that.") end
    else table.insert(lines, "There is no " .. object .. " here.") end
    return lines
end

local function report(response)
    return response, false
end

return { resolve = resolve, act = act, report = report, doVerb = doClose }