local Inventory = require("game.inventory")
local helper = require("game.verbs.verbhelper")

local PUT_PREPS = { ["in"] = true }

local function inPreps(s)
    for key, value in pairs(PUT_PREPS) do
        if s == key then return true end
    end
    return false
end

local function doPut(direct, indirect, prep, state)
    return Inventory.remove(state, direct, indirect)
end

local function resolve(world, state)
    return helper.xEntities(state.roomID, world, state)
end

local function act(entities, object, world, state)
    local lines = {}
    if not object.direct then return { "Put what?" } end
    if not object.prep then return { "I don't understand." } end
    if not inPreps(object.prep) then return { "I don't understand put " .. object.prep .. "." } end
    if object.indirect == "" then return { "Put " .. object.prep .. " what?" } end

    -- Check direct - has to be in the inventory
    local direct = world:resolveAlias(object.direct, state, Inventory.list(state))
    local indirect = world:resolveAlias(object.indirect, state, entities)
    if direct then
        if indirect then
            if doPut(direct, indirect, object.prep, state) == "success" then
                table.insert(lines, "You put the " .. object.direct .. " " .. object.prep .. " the " .. object.indirect .. ".")
            else table.insert(lines, "Something went wrong.") end
        else table.insert(lines, "There is no " .. object.indirect .. " to put the " .. object.direct .. " " .. object.prep .. ".") end
    else table.insert(lines, "You have no " .. object.direct .. ".") end
    return lines
end

local function report(response)
    return response, false
end

return { resolve = resolve, act = act, report = report, doVerb = doPut }