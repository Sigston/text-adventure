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
    x = "examine", examine = "examine",
    o = "open", open = "open",
    close = "close", unlock = "unlock", lock = "lock",
}

local verbs = require("game.verbs.verbs")

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
    -- And the inventory
    local inventory = state:invKeys()
    for i = 1, #inventory do
        table.insert(out, inventory[i])
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

local function goDir(dir, roomKey, world, state)
    local lines = { }
    -- Changes to state - this moves the player.
    state.roomID = roomKey
    state.visited[roomKey] = true

    -- Report results
    table.insert(lines, "You go " .. dir .. ".")
    local lookLines = verbLook(world, state).lines
    for i = 1, #lookLines do
        table.insert(lines, lookLines[i])
    end
    return lines
end

-- Handles GO - resolves the obj, moves the player and reports back. Calls verbLook() as part of the report.
local function verbGo(obj, world, state)
    local lines = { }
    -- Resolve obj to an appropriate direction
    if obj == "" then return { lines = { "Go where?" }, quit = false } end
    local dir = DIR_ALIASES[obj]
    if dir == nil then return { lines = { "I don't recognise that direction" }, quit = false } end
    local roomExits = world:rooms()[state.roomID].exits
    if roomExits[dir] == nil then return { lines = { "There is no exit to the " .. dir .. "." }, quit = false} end
    local door = roomExits[dir].door
    if door then
        if state.open[door] == false then table.insert(lines, "The door to the " .. dir .. " is closed.") 
        else lines = goDir(dir, roomExits[dir].to, world, state) end
    else lines = goDir(dir, roomExits[dir].to, world, state) end
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
    -- Get list of entities for the room, including items in open containers
    local entities = listedEntities(state.roomID, world, state)
    for i = 1, #entities do
        if world.entities[entities[i]].isContainer == true and state.open[entities[i]] then
            local contents = state:children(entities[i])
            for i = 1, #contents do table.insert(entities, contents[i]) end
        end
    end
    -- Resolve the obj as an alias for the found group of entities
    local key = world:resolveAlias(obj, state, entities)
    if key then
        if world.entities[key].portable then
            local result = state:move(key, state.invID)
            if result == "success" then
                table.insert(lines, "You take the " .. world:items()[key].name:lower() .. ".")
            else table.insert(lines, "Something went wrong.") end
        else table.insert(lines, "You can't take this.") end
    else table.insert(lines, "There is no " .. obj .. " here.") end
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
        else table.insert(lines, "Something went wrong.") end
    else table.insert(lines, "You have no " .. obj .. " to drop.") end
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
    if key then
        local desc = world.entities[key].desc
        if world.entities[key].isContainer or world.entities[key].kind == "door" then
            if state.open[key] then
                local contents = world:getNames(state:children(key))
                if #contents > 0 then
                    desc = desc .. " It is open. Inside you see" .. aLister(contents)
                else
                    desc = desc .. " It is open."
                end
            else
                if state.locked[key] then
                    desc = desc .. " It is closed and locked."
                else
                    desc = desc .. " It is closed."
                end
            end
        end
        table.insert(lines, desc)
    else table.insert(lines, "There is no " .. obj .. " here.") end

    return {
        lines = lines,
        quit = false
    }
end

local function verbOpen(obj, world, state)
    local lines = {}
    if obj == "" then return { lines = { "Open what?" }, quit = false } end
    -- Get list of examinable entities (not listed, as includes scenery, etc)
    local entities = xEntities(state.roomID, world, state)
    -- Resolve obj as an alias of any of the entities
    local key = world:resolveAlias(obj, state, entities)
    if key then
        local entity = world.entities[key]
        if entity.openable then
            if state.open[key] then table.insert(lines, "The " .. entity.name:lower() .. " is already open.")
            else
                if state.locked[key] then
                    local inventory = state:invKeys()
                    for i = 1, #inventory do
                        if world.entities[key].key == inventory[i] then state.locked[key] = false end
                    end
                    if state.locked[key] == false then 
                        table.insert(lines, "You unlock the " .. entity.name:lower() .. " with the " .. world.entities[world.entities[key].key].name:lower() .. ".")
                        state.open[key] = true
                        local response = "You open the " .. entity.name:lower() .. "."
                        local contents = state:children(key)
                        if #contents > 0 then
                            response = response .. " Inside you see" .. aLister(world:getNames(contents))
                        end
                        table.insert(lines, response)
                    else
                        table.insert(lines, "The " .. entity.name:lower() .. " is locked.")
                    end
                else
                    state.open[key] = true
                    local response = "You open the " .. entity.name:lower() .. "."
                    local contents = state:children(key)
                    if #contents > 0 then
                        response = response .. " Inside you see" .. aLister(world:getNames(contents))
                    end
                    table.insert(lines, response)
                end
            end
        else table.insert(lines, "You can't open that.") end
    else table.insert(lines, "There is no " .. obj .. " here.") end
    return {
        lines = lines,
        quit = false
    }
end

local function verbClose(obj, world, state)
    local lines = {}
    if obj == "" then return { lines = { "Close what?" }, quit = false } end
    -- Get list of examinable entities (not listed, as includes scenery, etc)
    local entities = xEntities(state.roomID, world, state)
    -- Resolve obj as an alias of any of the entities
    local key = world:resolveAlias(obj, state, entities)
    if key then
        local entity = world.entities[key]
        if entity.kind == "item" then
            if entity.openable then
                if state.open[key] then
                    state.open[key] = false
                    table.insert(lines, "You close the " .. entity.name:lower() .. ".")
                else
                    table.insert(lines, "The " .. entity.name:lower() .. " is already closed.")
                end
            else table.insert(lines, "You can't close that.") end
        elseif entity.kind == "door" then
            print("HI")
        else table.insert(lines, "You can't close that.") end
    else table.insert(lines, "There is no " .. obj .. " here.") end
    return {
        lines = lines,
        quit = false
    }
end

local function verbUnlock(obj, world, state)
    local lines = {}
    if obj == "" then return { lines = { "Unlock what?" }, quit = false } end
    -- Get list of examinable entities (not listed, as includes scenery, etc)
    local entities = xEntities(state.roomID, world, state)
    -- Resolve obj as an alias of any of the entities
    local key = world:resolveAlias(obj, state, entities)
    if key then
        local entity = world.entities[key]
        if entity.lockable then
            if state.locked[key] then
                local inventory = state:invKeys()
                for i = 1, #inventory do
                    if world.entities[key].key == inventory[i] then state.locked[key] = false end
                end
                if state.locked[key] then table.insert(lines, "You don't have the correct key.")
                else table.insert(lines, "You unlock the " .. entity.name:lower() .. ".") end
            else
                table.insert(lines, "The " .. entity.name:lower() .. " is already unlocked.")
            end
        else table.insert(lines, "You can't unlock that.") end
    else table.insert(lines, "There is no " .. obj .. " here.") end
    return {
        lines = lines,
        quit = false
    }
end

local function verbLock(obj, world, state)
    local lines = {}
    if obj == "" then return { lines = { "Lock what?" }, quit = false } end
    -- Get list of examinable entities (not listed, as includes scenery, etc)
    local entities = xEntities(state.roomID, world, state)
    -- Resolve obj as an alias of any of the entities
    local key = world:resolveAlias(obj, state, entities)
    if key then
        local entity = world.entities[key]
        if entity.lockable then
            if state.locked[key] then
                table.insert(lines, "The " .. entity.name:lower() .. " is already locked.")
            else
                local inventory = state:invKeys()
                for i = 1, #inventory do
                    if world.entities[key].key == inventory[i] then state.locked[key] = true end
                end
                if state.locked[key] then table.insert(lines, "You lock the " .. entity.name:lower() .. ".")
                else table.insert(lines, "You don't have the right key.") end
            end
        else table.insert(lines, "You can't lock that.") end
    else table.insert(lines, "There is no " .. obj .. " here.") end
    return {
        lines = lines,
        quit = false
    }
end

-- Returns objects and verb based on a raw input line.
local function tokenize(line)
    local line = trim(line or "")
    if line == "" then return end
    local lineSplit = words(line:lower())
    local verb = VERB_ALIASES[lineSplit[1]] or DIR_ALIASES[lineSplit[1]]
    local objects = { }
    for i = 1, #lineSplit - 1 do
        table.insert(objects, lineSplit[i + 1])
    end
    return { objects = objects, verb = verb }
end

-- Does not check that the verb is a valid one.
local function doVerb(verb, object, world, state)
    local entities = { }
    local response = { }
    local lines = { }
    local quit = false

    if verbs[verb].resolve then entities = verbs[verb].resolve(object or "", world, state) end
    if verbs[verb].act then response = verbs[verb].act(entities or {}, object or "", world, state) end
    if verbs[verb].report then lines, quit = verbs[verb].report(response or "", world, state) end
    return { lines = lines, quit = quit }
end

function M.handle(line, world, state)
    local out = { lines = {}, quit = false }

    -- Normalize and tokenize
    local tokens = tokenize(line)
    if not tokens then return out end
    -- Short circuit verb processing if the game is done
    if state.flags.won then
        if tokens.verb == "quit" then return verbQuit(world, state) end
        return { lines = { "It's over. Type 'quit'."}, quit = false }
    end
    -- Resolve verb
    out = doVerb(tokens.verb, tokens.objects[1], world, state)

    --[[
    if verb == "quit" then
        out = verbQuit(world, state)
    elseif verb == "go" then
        out = verbGo(ws[2] or "", world, state)
    elseif DIR_ALIASES[verb] then
        out = verbGo(ws[1], world, state)
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
    elseif verb == "open" then
        out = verbOpen(ws[2] or "", world, state)
    elseif verb == "close" then
        out = verbClose(ws[2] or "", world, state)
    elseif verb == "unlock" then
        out = verbUnlock(ws[2] or "", world, state)
    elseif verb == "lock" then
        out = verbLock(ws[2] or "", world, state)
    else
        out.lines = { "I don't understand that."}
    end--]]
    return out
end

return M