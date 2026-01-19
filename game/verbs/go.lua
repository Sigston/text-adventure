local helper = require("game.verbs.verbhelper")

local function doGo(key, state)
    state.roomID = key
end

local function resolve(world, state)
    return world.dirAliases
end

local function act(entities, object, world, state, verbs)
    local lines = { }
    -- Resolve obj to an appropriate direction
    if object == "" then return { "Go where?" } end
    local dir = entities[object.direct]
    if dir == nil then return { "I don't recognise that direction." } end
    local roomExits = world:rooms()[state.roomID].exits
    if roomExits[dir] == nil then return { "There is no exit to the " .. dir .. "." } end
    local door = roomExits[dir].door
    if door then
        if state.open[door] == false then table.insert(lines, "The door to the " .. dir .. " is closed.") 
        else
            doGo(roomExits[dir].to, state)
            table.insert(lines, "You go " .. dir .. ".")
            local lookLines = verbs.look.report("", world, state)
            for i = 1, #lookLines do
                table.insert(lines, lookLines[i])
            end
            state.visited[roomExits[dir].to] = true
        end
    else
        doGo(roomExits[dir].to, state)
        table.insert(lines, "You go " .. dir .. ".")
        local lookLines = verbs.look.report("", world, state)
        for i = 1, #lookLines do
            table.insert(lines, lookLines[i])
        end
        state.visited[roomExits[dir].to] = true
    end
    return lines
end

local function report(response)
    return response, false
end

return { resolve = resolve, act = act, report = report, doVerb = doGo }