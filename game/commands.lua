local M = {}

local Verb = require("game.verbs.verbs")
local Tokenizer = require("game.tokenizer")
local Parser = require ("game.parser")
local verbList = Verb.verbs

-- Does not check that the verb is a valid one.
local function doVerb(verb, object, world, state)
    local entities = { }
    local response = { }
    local lines = { }
    local quit = false

    if verb == "" then return { lines = { "I don't understand that." }, quit = quit } end
    if verbList[verb].resolve then entities = verbList[verb].resolve(world, state) end
    if verbList[verb].act then response = verbList[verb].act(entities or {}, object or "", world, state, verbList) end
    if response[1] == "duplicates" then return
    else
        if verbList[verb].report then lines, quit = verbList[verb].report(response or "", world, state) end
        return { lines = lines, quit = quit }
    end
end

function M.enterDisambig(world, state)

    return { lines = { "User input is ambiguous. Please enter..." }, quit = false }
end

function M.disambig(line, world, state)
    return { lines = { "Still not working for me, honey." }, quit = false }, false
end

function M.handle(line, world, state)
    -- Normalize and tokenize
    local tokens = Tokenizer.tokenize(line)
    local parsedTokens = Parser.parse(tokens, Verb)
    if not parsedTokens then return { lines = { "What?" }, quit = false } end
    -- Short circuit verb processing if the game is done
    if state.flags.won then
        if parsedTokens.verb == "quit" then return doVerb(parsedTokens.verb, parsedTokens.objects or "", world, state) end
        return { lines = { "It's over. Type 'quit'."}, quit = false }
    end
    return doVerb(parsedTokens.verb or "", parsedTokens.objects or "", world, state)
end

return M