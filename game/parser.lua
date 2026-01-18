local M = { }

local STOP = {
    ["the"] = true, ["a"] = true, ["an"] = true,
}

--[[

tokens: { "look", "at", "the", "bag" }
verbs: { "verb" = { {"alias"}, {"alias", "with", "words"} }

aim: to get the best match from the strings at the beginning of tokens.

there'll be n matches after checking the first words of all the aliases, then after
checking all subsequent words, there'll be 1 match or >1 or 0. The last two are errors.

    loop verbs and check first word of alias. If matches first word of tokens, add to matchList.
    Is there one match or have we exhausted the longest alias? 
    If more than one, go again, looking at the next word.

There is ambiguity here: if there was "pick" and "pick up" and something called "up bag", you
would never be able to "pick" the "up bag", only "pick up" the "bag" - but this is likely
never going to happen!

--]]

-- Identifies the best verb match at the head of the tokens.
local function processVerb(tokens, verbs)
    local function count(dict)
        local count = 0
        for key, value in pairs(dict) do
            count = count + 1
        end
        return count
    end

    -- Reduce verbs to those where there's a first word match.
    local verbMatches = {}
    for verb, verbTable in pairs(verbs) do
        for _, alias in ipairs(verbTable) do
            if tokens[1] == alias[1] then
                verbMatches[verb] = verbTable
                break
            end
        end
    end

    if count(verbMatches) == 1 then
        local objects = { }
        for i = 2, #tokens do
            table.insert(objects, tokens[i])
        end
        local verb = ""
        for v, _ in pairs(verbMatches) do verb = v end
        return verb, objects
    end

    local nextMatches = {}
    for verb, verbTable in pairs(verbMatches) do
        for _, alias in ipairs(verbTable) do
            if #alias > 1 then
                if tokens[2] == alias[2] then
                    nextMatches[verb] = verbTable
                    break
                end
            end
        end
    end

    if count(nextMatches) == 1 then
        local objects = { }
        for i = 3, #tokens do
            table.insert(objects, tokens[i])
        end
        local verb = ""
        for v, _ in pairs(nextMatches) do verb = v end
        return verb, objects
    end
end

-- Removes STOP from tokens, and returns an object string
local function processObjects(tokens)
    if #tokens < 1 then return end
    local newTokens = { }
    for i = 1, #tokens do
        local found = false
        for word, value in pairs(STOP) do
            if tokens[i] == word then found = true end
        end
        if not found then table.insert(newTokens, tokens[i]) end
    end
    local out = table.concat(newTokens, " ")
    return out
end

function M.parse(tokens, Verb)
    local verbs = Verb.tokenize()
    if not verbs then return end
    local verb, newTokens = processVerb(tokens, verbs)
    if not verb then return end
    local objects = processObjects(newTokens)
    return { objects = objects, verb = verb }
end

return M