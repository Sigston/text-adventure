local Inventory = require("game.inventory")
local helper = require("game.verbs.verbhelper")

local function doLock(key, state)
    state.locked[key] = true
end

local function resolve(world, state)
    return helper.xEntities(state.roomID, world, state)
end

local function act(entities, object, world, state)
    if object == "" then return { "Lock what?" } end
    local direct, result = world:resolveAlias(object.direct, state, entities)
    if not direct then
        if result == "not_found" then return { "There is no " .. world:getName(direct):lower() .. " here."}
        elseif result == "disambig" then return { result }
        else return end
    end
    local entity = world.entities[direct]
    if not entity.lockable then return { "You can't lock that." } end
    if state.locked[direct] then
        return { "The " .. world:getName(direct):lower() .. " is already locked." }
    else
        local inventory = Inventory.list(state)
        for i = 1, #inventory do
            if world.entities[direct].key == inventory[i] then doLock(direct, state) end
        end
        if state.locked[direct] then return { "You lock the " .. world:getName(direct):lower() .. "." }
        else return { "You don't have the right key." } end
    end
end

local function report(response)
    return response, false
end

return { resolve = resolve, act = act, report = report, doVerb = doLock }