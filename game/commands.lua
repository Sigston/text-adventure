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

-- Gets visible items from state and prints them.
local function printRoomItems(roomKey, world, state)
    local roomItems = state:visibleItems()
    if #roomItems == 0 then return
    elseif #roomItems == 1 then return "You see a " .. world.items[roomItems[1]].name .. "."
    elseif #roomItems == 2 then return "You see a " .. world.items[roomItems[1]].name:lower() .. " and a " .. world.items[roomItems[2]].name:lower() .. "."
    else 
        local phrase = table.concat(roomItems, ", ", 1, #roomItems - 1) .. " and " .. roomItems[#roomItems]
        return "You see " .. phrase .. "."
    end
end

local function printItemList(keys, world)
    local out = { }
    for i = 1, #keys do
        table.insert(out, world.items[keys[i]].name)
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
    local lines = { world.rooms[state.roomID].desc }
    local itemLines = printRoomItems(state.roomID, world, state)
    local exitLines = printExits(world.rooms[state.roomID].exits)
    if itemLines then table.insert(lines, itemLines) end
    if exitLines then table.insert(lines, exitLines) end
    return { lines = lines, quit = false }
end

-- Handles GO - resolves the obj, moves the player and reports back. Calls verbLook() as part of the report.
local function verbGo(obj, world, state)
    -- Resolve obj to an appropriate direction
    if obj == "" then return { lines = { "Go where?" }, quit = false } end
    local dir = DIR_ALIASES[obj]
    if dir == nil then return { lines = { "I don't recognise that direction" }, quit = false } end
    local roomDest = world.rooms[state.roomID].exits[dir].to
    if roomDest == nil then return { lines = { "There is no exit to the " .. dir .. "." }, quit = false} end
    
    -- Changes to state - this moves the player.
    state.roomID = roomDest
    state.visited[roomDest] = true

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
        lines = printItemList(state:children(state.invID), world),
        quit = false
    }
end

-- Resolves TAKE - deals with aliases, checks if visible, moves (or otherwise) and reports.
local function verbTake(obj, world, state)
    local lines = { }
    if obj == "" then return { lines = { "Take what?" }, quit = false } end
    local worldKey = world:resolveAlias(obj)
    if state:isVisible(worldKey) then
        local result = state:move(worldKey, state.invID)
        if result == "success" then
            table.insert(lines, "You take the " .. world.items[worldKey].name:lower() .. ".")
        else
            table.insert(lines, "Something went wrong.")
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
    local worldKey = world:resolveAlias(obj)
    if state:inContainer(worldKey, state.invID) then
        local result = state:move(worldKey, state.roomID)
        if result == "success" then
            table.insert(lines, "You drop the " .. world.items[worldKey].name:lower() .. ".")
        else
            table.insert(lines, "Something went wrong.")
        end
    else
        table.insert(lines, "There is no " .. obj .. " to drop.")
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
    local worldKey = world:resolveAlias(obj)
    if state:isVisible(worldKey) then
        table.insert(lines, world.items[worldKey].desc)
    else
        table.insert(lines, "There is no " .. obj .. ".")
    end
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