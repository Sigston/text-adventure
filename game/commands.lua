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

local function printRoomItems(roomKey, world, state)
    local roomItems = {}
    for item, parent in pairs(state.parents) do
        if parent == roomKey then
            table.insert(roomItems, world.entities[item].name:lower())
        end
    end
    if #roomItems == 0 then return end
    if #roomItems == 1 then return "You see a " .. roomItems[1] .. "." end
    if #roomItems == 2 then return "You see a " .. roomItems[1] .. " and a " .. roomItems[2] .. "." end
    return ""
end

local function printItemList(keys, world)
    local out = { }
    for i = 1, #keys do
        table.insert(out, world.items[keys[i]].name)
    end
    return out
end

local function verbQuit(obj, world, state)
    return { lines = {}, quit = true }
end

local function verbLook(obj, world, state)
    local lines = { world.rooms[state.roomID].desc }
    local itemLines = printRoomItems(state.roomID, world, state)
    local exitLines = printExits(world.rooms[state.roomID].exits)
    if itemLines then table.insert(lines, itemLines) end
    if exitLines then table.insert(lines, exitLines) end
    return { lines = lines, quit = false }
end

local function verbGo(obj, world, state)
    if obj == "" then return { lines = { "Go where?" }, quit = false } end
    local dir = DIR_ALIASES[obj]
    if dir == nil then return { lines = { "I don't recognise that direction" }, quit = false } end
    local roomDest = world.rooms[state.roomID].exits[dir].to
    if roomDest == nil then return { lines = { "There is no exit to the " .. dir .. "." }, quit = false} end
    state.roomID = roomDest
    state.visited[roomDest] = true

    local lines = {"You go " .. dir .. "."}
    local lookLines = verbLook(obj, world, state).lines
    for i = 1, #lookLines do
        table.insert(lines, lookLines[i])
    end
    return { lines = lines, quit = false }
end

local function verbHelp(obj, world, state)
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

local function verbInv(obj, world, state)
    return {
        lines = printItemList(state:children(state.invID), world),
        quit = false
    }
end

local function verbTake(obj, world, state)
    local lines = { }
    if obj == "" then return { lines = { "Take what?" }, quit = false } end
    if state:inRoom(obj, state.roomID) then
        local result = state:move(obj, state.invID)
        if result == "success" then
            table.insert(lines, "You take the " .. obj .. ".")
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

local function verbDrop(obj, world, state)
    local lines = {}
    if obj == "" then return { lines = { "Drop what?" }, quit = false } end
    if state:inContainer(obj, state.invID) then
        local result = state:move(obj, state.roomID)
        if result == "success" then
            table.insert(lines, "You drop the " .. obj .. ".")
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

local function verbExamine(obj, world, state)
    local lines = {}
    if obj == "" then return { lines = { "Examine what?" }, quit = false } end
    if state:inContainer(obj, state.invID) then
        table.insert(lines, world.items[obj].desc)
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

    line = trim(line or "")
    if line == "" then return out end

    local ws = words(line:lower())
    local verb = VERB_ALIASES[ws[1]] or DIR_ALIASES[ws[1]]
    if state.won then
        if verb == "quit" then return verbQuit("", world, state) end
        return { lines = { "It's over. Type 'quit'."}, quit = false }
    end
    if verb == "quit" then
        out = verbQuit("", world, state)
    elseif verb == "go" then
        out = verbGo(ws[2] or "", world, state)
    elseif DIR_ALIASES[verb] then
        out = verbGo(ws[1], world, state)
    elseif verb == "look" then
        out = verbLook("", world, state)
    elseif verb == "help" then
        out = verbHelp("", world, state)
    elseif verb == "inventory" then
        out = verbInv("", world, state)
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