local M = {}

local verbs, verbAliases = unpack(require("game.verbs.verbs"))

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

-- Returns objects and verb based on a raw input line.
local function tokenize(line)
    local line = trim(line or "")
    if line == "" then return end
    local lineSplit = words(line:lower())
    local verb = verbAliases[lineSplit[1]]
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

    if verb == "" then return { lines = { "I don't understand that." }, quit = quit } end
    if verbs[verb].resolve then entities = verbs[verb].resolve(world, state) end
    if verbs[verb].act then response = verbs[verb].act(entities or {}, object or "", world, state, verbs) end
    if verbs[verb].report then lines, quit = verbs[verb].report(response or "", world, state) end
    return { lines = lines, quit = quit }
end

function M.handle(line, world, state)
    -- Normalize and tokenize
    local tokens = tokenize(line)
    if not tokens then return { lines = { "What?" }, quit = false } end
    -- Short circuit verb processing if the game is done
    if state.flags.won then
        if tokens.verb == "quit" then return doVerb(tokens.verb, tokens.objects[1], world, state) end
        return { lines = { "It's over. Type 'quit'."}, quit = false }
    end
    return doVerb(tokens.verb or "", tokens.objects[1], world, state)
end

return M