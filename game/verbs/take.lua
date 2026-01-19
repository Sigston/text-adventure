local helper = require("game.verbs.verbhelper")
local Inventory = require("game.inventory")

local function doTake(key, state)
    return Inventory.add(state, key)
end

local function resolve(world, state)
    -- You can take listed items, and anything inside listed items which are open.
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
    if object == "" then return { "Take what?" } end
    local direct, result = world:resolveAlias(object.direct, state, entities)
    if not direct then
        if result == "not_found" then return { "There is no " .. object.direct .. " here."}
        elseif result == "disambig" then return { result }
        else return end
    end
    if not world.entities[direct].portable then
        local response = world.entities[direct].notPortable
        if response then return { response } else return {"You can't take this."} end
    end
    local result = doTake(direct, state)
    if result == "success" then return { "You take the " .. world:getName(direct):lower() .. "." }
    elseif result == "already" then return { "You already have the " .. world:getName(direct):lower() .. "." }
    elseif result == "full" then return { "You have no more room in your inventory." }
    else return { "Something went wrong." } end
end

local function report(response)
    return response, false
end

return { resolve = resolve, act = act, report = report, doVerb = doTake }