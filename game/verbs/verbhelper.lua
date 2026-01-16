-- Gets entities within the supplied room which have listed=true
local function listedEntities(roomKey, world, state)
    -- Entities we don't consider: doors, rooms
    local out = { }
    -- Deal with items first, these can move, so location are in state.
    local items = state:children(roomKey)
    for i = 1, #items do
        if world.entities[items[i]].isListed then table.insert(out, items[i]) end
    end
    -- Then deal with scenery
    local scenery = { }
    for key, value in pairs(world:scenery()) do
        if value.loc == roomKey and value.isListed then table.insert(out, key) end
    end
    return out
end


-- Returns a string of the provided names formatted.
local function aLister(listNames)
    if #listNames == 0 then return 
    elseif #listNames == 1 then return " a " .. listNames[1] .. "." 
    elseif #listNames == 2 then return " a " .. listNames[1] .. " and a " .. listNames[2] .. "."
    else return " a " .. table.concat(listNames, ", a ", 1, #listNames - 1) .. " and a " .. listNames[#listNames] end
end

-- Prints entities within the current room which have listed=true
local function printEntities(roomKey, world, state)
    local entityKeys = listedEntities(roomKey, world, state)
    if #entityKeys == 0 then return end
    local entities = world:getNames(entityKeys)
    return "You see" .. aLister(entities)
end

local function printExits(roomExits)
    local dirs = {}
    local out = ""
    for dir in pairs(roomExits) do
        table.insert(dirs, dir)
    end
    table.sort(dirs)

    if #dirs == 0 then
        out = "There are no obvious exits."
    elseif #dirs == 1 then
        out = "There is an exit to the " .. dirs[1] .. "."
    elseif #dirs == 2 then
        out = "There are exits to the " .. dirs[1] .. " and " .. dirs[2] .. "."
    else
        local phrase = table.concat(dirs, ", ", 1, #dirs - 1) .. " and " .. dirs[#dirs]
        out = "There are exits to the " .. phrase .. "."
    end
    return out
end

local function xEntities(roomKey, world, state)
    -- Entities we don't consider: rooms
    local out = { }
    -- Deal with items first, these can move, so location are in state.
    local items = state:children(roomKey)
    for i = 1, #items do
        if world.entities[items[i]].isListed then table.insert(out, items[i]) end
    end
    -- Then deal with scenery
    for key, value in pairs(world:scenery()) do
        if value.loc == roomKey then table.insert(out, key) end
    end
    -- And then doors
    for key, value in pairs(world.entities[roomKey].exits) do
        if value.door then table.insert(out, value.door) end
    end
    -- And the inventory
    local inventory = state:invKeys()
    for i = 1, #inventory do
        table.insert(out, inventory[i])
    end
    return out
end

local helper = {
    listedEntities = listedEntities,
    printEntities = printEntities,
    printExits = printExits,
    xEntities = xEntities,
    aLister = aLister,
}

return helper