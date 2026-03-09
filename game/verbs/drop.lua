local helper = require("game.verbs.verbhelper")
local Inventory = require("game.inventory")

local function doDrop(key, state)
    return Inventory.remove(state, key, state.roomID)
end

local function resolve(world, state)
    return Inventory.list(state)
end

local function act(entities, object, world, state)
    if object == "" then return { "Drop what?" } end
    local direct, result = world:resolveAlias(object.direct, state, entities)
    if not direct then
        if result == "not_found" then return { "You have no " .. object.direct .. " to drop."}
        elseif result == "disambig" then return { result }
        else return end
    end
    if doDrop(direct, state) == "success" then
        return { "You drop the " .. world:getName(direct):lower() .. "." }
    else return { "Something went wrong." } end
end

return { resolve = resolve, act = act, doVerb = doDrop }