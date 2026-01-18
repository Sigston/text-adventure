local M = {}

local verbs, verbAliases = unpack(require("game.verbs.verbs"))
local Tokenizer = require("game.tokenizer")
local Parser = require ("game.parser")

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
    local tokens = Tokenizer.tokenize(line)
    local parsedTokens = Parser.parse(tokens, verbAliases)
    if not parsedTokens then return { lines = { "What?" }, quit = false } end
    -- Short circuit verb processing if the game is done
    if state.flags.won then
        if parsedTokens.verb == "quit" then return doVerb(parsedTokens.verb, parsedTokens.objects[1], world, state) end
        return { lines = { "It's over. Type 'quit'."}, quit = false }
    end
    return doVerb(parsedTokens.verb or "", parsedTokens.objects[1], world, state)
end

return M