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
    if response[1] == "disambig" then state.pending.verb = verb; return { status = response[1] }
    else
        if verbList[verb].report then lines, quit = verbList[verb].report(response or "", world, state) end
        return { status = "ok", lines = lines, quit = quit }
    end
end

local function buildResponse(state, candidateNo)
    local verb = state.pending.verb
    local direct = ""
    if not state.pending.slot or state.pending.slot == "directObj" then
        direct = state.pending.candidates[candidateNo].id
    else
        direct = state.pending.direct
    end
    local prep = state.pending.prep
    local indirect = ""
    if state.pending.slot == "indirectObj" then
        indirect = state.pending.candidates[candidateNo].indirect
    else
        indirect = state.pending.indirect
    end

    return { status = "ok", lines = { verb .. " " .. direct .. " " .. (prep or "") .. " " .. (indirect or "")}, quit = false }
end

function M.disambig(line, world, state)
    local tokens = Tokenizer.tokenize(line)
    if tokens then
        for _, verbAlias in ipairs(verbList.quit.aliases) do
            if verbAlias == tokens[1] then
                state.pending = nil
                return { status = "quitting_disambig" }
            end
        end
        local i = tonumber(tokens[1])
        if i then
            for index, _ in ipairs(state.pending.candidates) do
                if index == i then
                    local out = buildResponse(state, i)
                    state.pending = nil
                    return  out
                end
            end
        end
    end
    return { status = "disambig", lines = { "Please select a listed item number, or quit." }, quit = false }
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