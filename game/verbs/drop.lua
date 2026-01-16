local helper = require("game.verbs.verbhelper")
local Inventory = require("game.inventory")

local function doDrop(key, state)
    return Inventory.remove(state, key, state.roomID)
end

local function resolve(world, state)
    return Inventory.list(state)
end

local function act(entities, object, world, state)
    local lines = {}
    if object == "" then return { "Drop what?" } end
    local worldKey = world:resolveAlias(object, state, entities)
    if worldKey then
        if doDrop(worldKey, state) == "success" then
            table.insert(lines, "You drop the " .. object .. ".")
        else table.insert(lines, "Something went wrong.") end
    else table.insert(lines, "You have no " .. object .. " to drop.") end
    return lines
end

local function report(response)
    return response, false
end

return { resolve = resolve, act = act, report = report, doVerb = doDrop }