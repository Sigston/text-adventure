local function doUnlock(key, state)
    state.locked[key] = false
end

local helper = require("game.verbs.verbhelper")
local Inventory = require("game.inventory")

local function resolve(world, state)
    return helper.xEntities(state.roomID, world, state)
end

local function act(entities, object, world, state)
    local lines = { }
    if object == "" then return { lines = { "Lock what?" }, quit = false } end
    local key = world:resolveAlias(object, state, entities)
    if key then
        local entity = world.entities[key]
        if entity.lockable then
            if state.locked[key] then
                local inventory = Inventory.list(state)
                for i = 1, #inventory do
                    if world.entities[key].key == inventory[i] then doUnlock(key, state) end
                end
                if state.locked[key] then table.insert(lines, "You don't have the correct key.")
                else table.insert(lines, "You unlock the " .. entity.name:lower() .. ".") end
            else
                table.insert(lines, "The " .. entity.name:lower() .. " is already unlocked.")
            end
        else table.insert(lines, "You can't unlock that.") end
    else table.insert(lines, "There is no " .. object .. " here.") end
    return lines
end

local function report(response)
    return response, false
end

return { resolve = resolve, act = act, report = report, doVerb = doUnlock }