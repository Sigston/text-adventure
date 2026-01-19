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
    local direct, dResult = world:resolveAlias(object.direct, state, Inventory.list(state))
    if not direct then
        if dResult == "not_found" then return { "You have no " .. world:getName(direct):lower() .. "."}
        elseif dResult == "disambig" then
            state.pending.slot = "directObj"
            state.pending.prep = object.prep
            state.pending.indirect = object.indirect
            return { dResult }
        else return end
    end
    local indirect, iResult = world:resolveAlias(object.indirect, state, entities)
    if not indirect then
        if iResult == "not_found" then return { "There is no " .. world:getName(indirect):lower() .. " here."}
        elseif iResult == "disambig" then 
            state.pending.slot = "indirectObj"
            state.pending.prep = object.prep
            state.pending.direct = object.direct
            return { iResult }
        else return end
    end
    if world.entities[indirect].isContainer then
        if state.open[indirect] then
            if doPut(direct, indirect, object.prep, state) == "success" then
                table.insert(lines, "You put the " .. world:getName(direct):lower() .. " " .. object.prep .. " the " .. world:getName(indirect):lower() .. ".")
            else table.insert(lines, "Something went wrong.") end
        else table.insert(lines, "The " .. world:getName(indirect):lower() .. " is not open.") end
    else table.insert(lines, "You can't put anything " .. object.prep .. " the " .. world:getName(indirect):lower() .. ".") end
    return lines
end

local function report(response)
    return response, false
end

return { resolve = resolve, act = act, report = report, doVerb = doPut }