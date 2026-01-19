local function doUnlock(key, state)
    state.locked[key] = false
end

local helper = require("game.verbs.verbhelper")
local Inventory = require("game.inventory")

local function resolve(world, state)
    return helper.xEntities(state.roomID, world, state)
end

local function act(entities, object, world, state)
    if object == "" then return { "Unlock what?" } end
    local direct, result = world:resolveAlias(object.direct, state, entities)
    if not direct then
        if result == "not_found" then return { "There is no " .. world:getName(direct):lower() .. " here."}
        elseif result == "disambig" then return { result }
        else return end
    end
    local entity = world.entities[direct]
    if not entity.lockable then return { "You can't unlock that." } end
    if state.locked[direct] then
        local inventory = Inventory.list(state)
        for i = 1, #inventory do
            if world.entities[direct].key == inventory[i] then doUnlock(direct, state) end
        end
        if state.locked[direct] then return { "You don't have the correct key." }
        else return { "You unlock the " .. entity.name:lower() .. "." } end
    else
        return { "The " .. entity.name:lower() .. " is already unlocked." }
    end
end

local function report(response)
    return response, false
end

return { resolve = resolve, act = act, report = report, doVerb = doUnlock }