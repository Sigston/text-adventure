local Inventory = require("game.inventory")
local helper = require("game.verbs.verbhelper")

local function doLock(key, state)
    state.locked[key] = true
end

local function resolve(world, state)
    return helper.xEntities(state.roomID, world, state)
end

local function act(entities, object, world, state)
    local lines = { }
    if object == "" then return { "Lock what?" } end
    local direct = world:resolveAlias(object.direct, state, entities)
    if direct then
        local entity = world.entities[direct]
        if entity.lockable then
            if state.locked[direct] then
                table.insert(lines, "The " .. entity.name:lower() .. " is already locked.")
            else
                local inventory = Inventory.list(state)
                for i = 1, #inventory do
                    if world.entities[direct].key == inventory[i] then doLock(direct, state) end
                end
                if state.locked[direct] then table.insert(lines, "You lock the " .. entity.name:lower() .. ".")
                else table.insert(lines, "You don't have the right key.") end
            end
        else table.insert(lines, "You can't lock that.") end
    else table.insert(lines, "There is no " .. object .. " here.") end
    return lines
end

local function report(response)
    return response, false
end

return { resolve = resolve, act = act, report = report, doVerb = doLock }