local M = { }

function M.parse(tokens, verbAliases)
    local verb = verbAliases[tokens[1]]
    local objects = { }
    for i = 1, #tokens - 1 do
        table.insert(objects, tokens[i + 1])
    end
    return { objects = objects, verb = verb }
end

return M