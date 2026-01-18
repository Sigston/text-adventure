local M = { }

M.verbs = {
    look = {
        kind = "intrans",
        aliases = { "l", "look" },
    },
    go = {
        kind = "direct",
        aliases = { "go" },
    },
    quit = {
        kind = "intrans",
        aliases = { "exit", "q", "quit" },
    },
    help = {
        kind = "intrans",
        aliases = { "help", "h" },
    },
    inventory = {
        kind = "intrans",
        aliases = { "inventory", "i" },
    },
    take = {
        kind = "direct",
        aliases = { "t", "take", "pick up" },
    },
    drop = {
        kind = "direct",
        aliases = { "d", "drop" },
    },
    examine = {
        kind = "direct",
        aliases = { "x", "examine", "look at" },
    },
    open = {
        kind = "direct",
        aliases = { "o", "open" },
    },
    close = {
        kind = "direct",
        aliases = { "close" },
    },
    lock = {
        kind = "direct",
        aliases = { "lock" },
    },
    unlock = {
        kind = "direct",
        aliases = { "unlock" },
    },
}

-- Adds their functions to the table dynamically from the files.
for key, value in pairs(M.verbs) do
    local resolve = require("game.verbs." .. key).resolve
    if resolve then value.resolve = resolve end
    local act = require("game.verbs." .. key).act
    if act then value.act = act end
    local report = require("game.verbs." .. key).report
    if report then value.report = report end
    local doVerb = require("game.verbs." .. key).doVerb
    if doVerb then value.doVerb = doVerb end
end

-- Returns a structured list of corresponding verbs and aliases.
function M:generateAliases()
    local out = {}
    for verbName, verb in pairs(M.verbs) do
        for _, alias in pairs(verb.aliases) do
            out[alias] = verbName
        end
    end
    return out
end

function M:tokenize()
    local aliases = M:generateAliases()
    local out = { }

    local function split(s)
        local out = { }
        for word in s:gmatch("%S+") do
            table.insert(out, word)
        end
        return out
    end

    for key, value in pairs(aliases) do
        if out[value] then table.insert(out[value], split(key))
        else out[value] = {split(key)} end
    end
    return out
end

return M