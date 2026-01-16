local function report()
    local lines = {
        "Possible commands:",
        "   quit",
        "   go",
        "   look",
        "   help"
    }
    return lines, false
end

return { report = report }