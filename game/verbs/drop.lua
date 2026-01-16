local helper = require("game.verbs.verbhelper")

local function doDrop(key, state)
    return state:move(key, state.roomID)
end

local function resolve(world, state)
    return state:invKeys()
end

local function act(entities, object, world, state)
    local lines = {}
    if object == "" then return { "Drop what?" } end
    local worldKey = world:resolveAlias(object, state, entities)
    if worldKey then
        if doDrop(worldKey, state) then
            table.insert(lines, "You drop the " .. object .. ".")
        else table.insert(lines, "Something went wrong.") end
    else table.insert(lines, "You have no " .. object .. " to drop.") end
    return lines
end

local function report(response)
    return response, false
end

return { resolve = resolve, act = act, report = report, doVerb = doDrop }