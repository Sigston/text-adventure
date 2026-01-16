local verbs = {
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
        aliases = { "t", "take" },
    },
    drop = {
        kind = "direct",
        aliases = { "d", "drop" },
    },
    examine = {
        kind = "direct",
        aliases = { "x", "examine" },
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

for key, value in pairs(verbs) do
    local resolve = require("game.verbs." .. key).resolve
    if resolve then value.resolve = resolve end
    local act = require("game.verbs." .. key).act
    if act then value.act = act end
    local report = require("game.verbs." .. key).report
    if report then value.report = report end
    local doVerb = require("game.verbs." .. key).doVerb
    if doVerb then value.doVerb = doVerb end
end

local function generateAliases(verbs)
    local out = {}
    for verbName, verb in pairs(verbs) do
        for _, alias in pairs(verb.aliases) do
            out[alias] = verbName
        end
    end
    return out
end

return {verbs, generateAliases(verbs)}