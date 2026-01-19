local M = { }

local STOP = {
    ["the"] = true, ["a"] = true, ["an"] = true,
}

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
        if not STOP[tokens[i]] then table.insert(newTokens, tokens[i]) end
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