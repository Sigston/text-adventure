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

    Do until break:
        loop verbs and check each alias: if alias[1] == tokens[1], add the whole verb to the matchList.
        if the current alias[1] is only [1] long, create preferredMatch.

        Go through the matchList again, with [2] and [2]. Keep doing this until we exhaust the number of words
        in the longest alias or the number of words in tokens.

There is ambiguity here: if there was "pick" and "pick up" and something called "up bag", you
would never be able to "pick" the "up bag", only "pick up" the "bag" - but this is likely
never going to happen!

--]]

local function noOfLongest(verbs)
    local number = 0
    for _, verbTable in pairs(verbs) do
        for _, alias in pairs(verbTable) do
            if #alias > number then number = #alias end
        end
    end
    return number
end

local function addAlias(verbTable, verbID, alias)
    local bucket = verbTable[verbID]
    if not bucket then verbTable[verbID] = { alias }
    else bucket[#bucket+1] = alias end
end

-- WARNING: no ambiguity handling
local function processVerb(tokens, verbs)
    local tempTable = { }
    local checkTable = verbs
    local preferredMatch = nil
    local ingested = 0

    for i = 1, math.min(#tokens, noOfLongest(verbs)) do
        for verbID, verbTable in pairs(checkTable) do
            for _, alias in ipairs(verbTable) do
                if tokens[i] == alias[i] then
                    addAlias(tempTable, verbID, alias)
                    if #alias == i then
                        preferredMatch = verbID
                        ingested = i
                    end
                end
            end
        end
        checkTable = tempTable
        tempTable = { }
    end

    local objects = { }
    for i = ingested + 1, #tokens do
        table.insert(objects, tokens[i])
    end
    return preferredMatch, objects
end

local function removeStop(tokens)
    local newTokens = { }
    for i = 1, #tokens do
        local found = false
        for word, _ in pairs(STOP) do
            if tokens[i] == word then found = true end
        end
        if not found then table.insert(newTokens, tokens[i]) end
    end
    return newTokens
end

local function prepLoc(tokens, prepList)
    for i = 1, #tokens do
        for j = 1, #prepList do
            if tokens[i] == prepList[j] then return i end
        end
    end
    return 0
end

-- First argument is direct object, second and third are indirect and prep
local function splitObjects(tokens, prepList)
    if #tokens < 1 then return end
    if #tokens == 1 then return tokens[1] end
    if prepList then
        local loc = prepLoc(tokens, prepList)
        if loc == 0 then return table.concat(tokens, " ") end
        local direct, indirect, prep = "", "", ""
        for i = 1, #tokens do
            if i == loc then prep = tokens[i]
            elseif i < loc then direct = direct .. " " .. tokens[i]
            else indirect = indirect .. " " .. tokens[i] end
        end
        return direct:match("^%s*(.-)%s*$"), indirect:match("^%s*(.-)%s*$"), prep
    else
        return table.concat(tokens, " ")
    end
end

-- Removes STOP from tokens, and returns direct, indirect, and prep
local function processObjects(tokens, prepList)
    local tokens = tokens or { }
    if #tokens < 1 then return end
    tokens = removeStop(tokens)
    local direct, indirect, prep = splitObjects(tokens, prepList)
    return { direct = direct, indirect = indirect, prep = prep }
end

function M.parse(tokens, Verb)
    local verbs = Verb.tokenize()
    if not verbs then return end
    local verb, newTokens = processVerb(tokens, verbs)
    if not verb then return end
    local objects = processObjects(newTokens, Verb:prepList(verb))
    return { objects = objects, verb = verb }
end

return M