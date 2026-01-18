local M = { }

local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function words(s)
    local out = { }
    for w in s:gmatch("%S+") do
        table.insert(out, w)
    end
    return out
end

-- Returns objects and verb based on a raw input line.
function M.tokenize(line)
    local line = trim(line or "")
    if line == "" then return end
    return words(line:lower())
end

return M