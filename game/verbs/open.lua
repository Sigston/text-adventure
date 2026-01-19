local helper = require("game.verbs.verbhelper")
local Inventory = require("game.inventory")

local function doOpen(key, state)
    state.open[key] = true
end

local function resolve(world, state)
    return helper.xEntities(state.roomID, world, state)
end

local function act(entities, object, world, state)
    local lines = {}
    if object == "" then return { "Open what?" } end
    local key = world:resolveAlias(object.direct, state, entities)
    if key then
        local entity = world.entities[key]
        if entity.openable then
            if state.open[key] then table.insert(lines, "The " .. entity.name:lower() .. " is already open.")
            else
                if state.locked[key] then
                    local inventory = Inventory.list(state)
                    for i = 1, #inventory do
                        if world.entities[key].key == inventory[i] then state.locked[key] = false end
                    end
                    if state.locked[key] == false then 
                        table.insert(lines, "You unlock the " .. entity.name:lower() .. " with the " .. world.entities[world.entities[key].key].name:lower() .. ".")
                        doOpen(key, state)
                        local response = "You open the " .. entity.name:lower() .. "."
                        local contents = state:children(key)
                        if #contents > 0 then
                            response = response .. " Inside you see" .. helper.aLister(world:getNames(contents))
                        end
                        table.insert(lines, response)
                    else
                        table.insert(lines, "The " .. entity.name:lower() .. " is locked.")
                    end
                else
                    doOpen(key, state)
                    local response = "You open the " .. entity.name:lower() .. "."
                    local contents = state:children(key)
                    if #contents > 0 then
                        response = response .. " Inside you see" .. helper.aLister(world:getNames(contents))
                    end
                    table.insert(lines, response)
                end
            end
        else table.insert(lines, "You can't open that.") end
    else table.insert(lines, "There is no " .. object.direct .. " here.") end
    return lines
end

local function report(response)
    return response, false
end

return { resolve = resolve, act = act, report = report }