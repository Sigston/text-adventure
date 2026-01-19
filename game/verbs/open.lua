local helper = require("game.verbs.verbhelper")
local Inventory = require("game.inventory")

local function doOpen(key, state)
    state.open[key] = true
end

local function resolve(world, state)
    return helper.xEntities(state.roomID, world, state)
end

local function act(entities, object, world, state)
    if object == "" then return { "Open what?" } end
    local direct, result = world:resolveAlias(object.direct, state, entities)
    if not direct then
        if result == "not_found" then return { "There is no " .. world:getName(direct):lower() .. " here."}
        elseif result == "disambig" then return { result }
        else return end
    end
    local entity = world.entities[direct]
    if not entity.openable then return { "you can't open that." } end
    if state.open[direct] then return { "The " .. world:getName(direct):lower() .. " is already open." } end
    -- Allow implied unlocking of containers/doors when opening attempted.
    if state.locked[direct] then
        local inventory = Inventory.list(state)
        for i = 1, #inventory do
            if world.entities[direct].key == inventory[i] then state.locked[direct] = false end
        end
        if state.locked[direct] == false then
            local response = { "You unlock the " .. world:getName(direct):lower() .. " with the " .. world.entities[world.entities[direct].key].name:lower() .. "." }
            doOpen(direct, state)
            table.insert(response, "You open the " .. world:getName(direct):lower() .. ".")
            local contents = state:children(direct)
            if #contents > 0 then
                table.insert(response, "Inside you see" .. helper.aLister(world:getNames(contents)))
            end
            return response
        else
            return { "The " .. world:getName(direct):lower() .. " is locked." }
        end
    else
        doOpen(direct, state)
        local response = "You open the " .. world:getName(direct):lower() .. "."
        local contents = state:children(direct)
        if #contents > 0 then
            response = response .. " Inside you see" .. helper.aLister(world:getNames(contents))
        end
        return { response }
    end
end

local function report(response)
    return response, false
end

return { resolve = resolve, act = act, report = report }