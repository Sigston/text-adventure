local M = {}

local DIR_ALIASES = {
    n = "north", s = "south", e = "east", w = "west",
    u = "up", d = "down",
    north = "north", south = "south", east = "east", west = "west",
    up = "up", down = "down"
}

local VERB_ALIASES = {
    l = "look", look = "look", go = "go",
    exit = "quit", q = "quit", quit = "quit",
    help = "help", h = "help",
    inventory =  "inventory", i = "inventory",
    t = "take", take = "take",
    d = "drop", drop = "drop",
    x = "examine", examine = "examine"
}

local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function words(s)
    local out = { }
    for w in s:gmatch("%S+") do
        table.insert(out, w)
    end
    return out
end

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
    return out
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

-- Prints entities within the current room which have listed=true
local function printEntities(roomKey, world, state)
    local entityKeys = listedEntities(roomKey, world, state)
    if #entityKeys == 0 then return end
    local entities = world:getNames(entityKeys)
    if #entities == 1 then return "You see a " .. entities[1] .. "."
    elseif #entities == 2 then return "You see a " .. entities[1] .. " and a " .. entities[2] .. "."
    else 
        local phrase = table.concat(entities, ", a ", 1, #entities - 1) .. " and a " .. entities[#entities]
        return "You see a " .. phrase .. "."
    end
end

local function listItems(keys, world)
    local out = { }
    for i = 1, #keys do
        table.insert(out, world:items()[keys[i]].name)
    end
    table.sort(out)
    return out
end

-- Handles QUIT - passes back quit = true
local function verbQuit(world, state)
    return { lines = {}, quit = true }
end

-- Handles LOOK - returns a desc of the room, visible items and visible exits. Calls
-- printRoomItems() and printExits().
local function verbLook(world, state)
    -- The desc for the room.
    local lines = { world:rooms()[state.roomID].desc }
    -- Listed entities.
    local entityLines = printEntities(state.roomID, world, state)
    -- Exits.
    local exitLines = printExits(world:rooms()[state.roomID].exits)
    if entityLines then table.insert(lines, entityLines) end
    if exitLines then table.insert(lines, exitLines) end
    return { lines = lines, quit = false }
end

-- Handles GO - resolves the obj, moves the player and reports back. Calls verbLook() as part of the report.
local function verbGo(obj, world, state)
    -- Resolve obj to an appropriate direction
    if obj == "" then return { lines = { "Go where?" }, quit = false } end
    local dir = DIR_ALIASES[obj]
    if dir == nil then return { lines = { "I don't recognise that direction" }, quit = false } end
    local roomDest = world:rooms()[state.roomID].exits[dir]
    if roomDest == nil then return { lines = { "There is no exit to the " .. dir .. "." }, quit = false} end
    
    -- Changes to state - this moves the player.
    state.roomID = roomDest.to
    state.visited[roomDest.to] = true

    -- Report results
    local lines = {"You go " .. dir .. "."}
    local lookLines = verbLook(world, state).lines
    for i = 1, #lookLines do
        table.insert(lines, lookLines[i])
    end
    return { lines = lines, quit = false }
end

-- Resolves HELP - prints the help text.
local function verbHelp(world, state)
    return { 
        lines = {
            "Possible commands:",
            "   quit",
            "   go",
            "   look",
            "   help"
        }, 
        quit = false
    }
end

-- Resolves INVENTORY - calls printItemList of the children of the inventory entity.
local function verbInv(world, state)
    return {
        lines = listItems(state:children(state.invID), world),
        quit = false
    }
end

-- Resolves TAKE - deals with aliases, checks if visible, moves (or otherwise) and reports.
local function verbTake(obj, world, state)
    local lines = { }
    if obj == "" then return { lines = { "Take what?" }, quit = false } end
    -- Create list of possibles.
    -- Get list of entities for the room
    local entities = listedEntities(state.roomID, world, state)
    -- Resolve the obj as an alias for the found group of entities
    local key = world:resolveAlias(obj, state, entities)
    if key then
        if world.entities[key].portable then
            local result = state:move(key, state.invID)
            if result == "success" then
                table.insert(lines, "You take the " .. world:items()[key].name:lower() .. ".")
            else
                table.insert(lines, "Something went wrong.")
            end
        else
            table.insert(lines, "You can't take this.")
        end
    else
        table.insert(lines, "There is no " .. obj .. " here.")
    end

    return {
        lines = lines,
        quit = false
    }
end

-- Resolves DROP - deals with aliases, checks if in inventory, moves to room and reports.
local function verbDrop(obj, world, state)
    local lines = {}
    if obj == "" then return { lines = { "Drop what?" }, quit = false } end
    local worldKey = world:resolveAlias(obj, state, state:invKeys())
    if worldKey then
        local result = state:move(worldKey, state.roomID)
        if result == "success" then
            table.insert(lines, "You drop the " .. world:items()[worldKey].name:lower() .. ".")
        else
            table.insert(lines, "Something went wrong.")
        end
    else
        table.insert(lines, "You have no " .. obj .. " to drop.")
    end
    return {
        lines = lines,
        quit = false
    }
end

-- Resolves EXAMINE - deals with aliases, checks if visible and prints desc.
local function verbExamine(obj, world, state)
    local lines = {}
    if obj == "" then return { lines = { "Examine what?" }, quit = false } end
    -- Get list of examinable entities (not listed, as includes scenery, etc)
    local entities = xEntities(state.roomID, world, state)
    -- Resolve obj as an alias of any of the entities
    local key = world:resolveAlias(obj, state, entities)
    if key then table.insert(lines, world.entities[key].desc)
    else table.insert(lines, "There is no " .. obj .. " here.") end

    return {
        lines = lines,
        quit = false
    }
end

function M.handle(line, world, state)
    local out = { lines = {}, quit = false }

    -- Normalize and tokenize
    line = trim(line or "")
    if line == "" then return out end
    local ws = words(line:lower())
    local verb = VERB_ALIASES[ws[1]] or DIR_ALIASES[ws[1]]
    -- Short circuit verb processing if the game is done
    if state.flags.won then
        if verb == "quit" then return verbQuit(world, state) end
        return { lines = { "It's over. Type 'quit'."}, quit = false }
    end
    -- Resolve verb
    if verb == "quit" then
        out = verbQuit(world, state)
    elseif verb == "go" then
        out = verbGo(ws[2] or "", world, state)
    elseif DIR_ALIASES[verb] then
        out = verbGo(ws[1], world, state)
    elseif verb == "look" then
        out = verbLook(world, state)
    elseif verb == "help" then
        out = verbHelp(world, state)
    elseif verb == "inventory" then
        out = verbInv(world, state)
    elseif verb == "take" then
        out = verbTake(ws[2] or "", world, state)
    elseif verb == "drop" then
        out = verbDrop(ws[2] or "", world, state)
    elseif verb == "examine" then
        out = verbExamine(ws[2] or "", world, state)
    else
        out.lines = { "I don't understand that."}
    end
    return out
end

return M