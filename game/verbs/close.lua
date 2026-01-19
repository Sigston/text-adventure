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
    local direct, result = world:resolveAlias(object.direct, state, entities)
    if not direct then
        if result == "not_found" then return { "There is no " .. world:getName(direct):lower() .. " here."}
        elseif result == "disambig" then return { result }
        else return end
    end
    local entity = world.entities[direct]
    if entity.openable then
        if state.open[direct] then
            doClose(direct, state)
            table.insert(lines, "You close the " .. entity.name:lower() .. ".")
        else
            table.insert(lines, "The " .. entity.name:lower() .. " is already closed.")
        end
    else table.insert(lines, "You can't close that.") end
    return lines
end

local function report(response)
    return response, false
end

return { resolve = resolve, act = act, report = report, doVerb = doClose }