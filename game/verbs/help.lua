local function act(entities, object, world, state, verbs)
    local lines = {
        "Possible commands:",
        "   quit",
        "   go",
        "   look",
        "   help"
    }

    return lines
end

return { act = act }