local M = {}

local function mergeInto(dst, src, srcName)
    for id, ent in pairs(src or {}) do
        if dst[id] ~= nil then
            error(("Duplicate entity id '%s' (from %s)"):format(id, srcName or "unknown"), 2)
        end
        dst[id] = ent
    end
end

function M.new()
    local world = { entities = {} }
    mergeInto(world.entities, require("game.content.rooms"), "rooms")
    mergeInto(world.entities, require("game.content.items"), "items")
    mergeInto(world.entities, require("game.content.doors"), "doors")
    world.rooms = {}
    world.items = {}
    world.doors = {}
    world.mapdata = {}

    for id, ent in pairs(world.entities) do
        if ent.kind == "room" then world.rooms[id] = ent
        elseif ent.kind == "item" then world.items[id] = ent 
        elseif ent.kind == "door" then world.doors[id] = ent end
    end

    -- For any string, returns the key of the first item found with that alias 
    function world:resolveAlias(obj)
        for index, value in pairs(world.entities) do
            local aliases = value.aliases
            if aliases then 
                for i = 1, #aliases do
                    if obj == aliases[i] then return index end
                end
            end
        end
    end

    function world:generateMapData(state)
        state = state or {}
        local nodes, edges = {}, {}
        local seenEdge = {}
        local minX, maxX = math.huge, -math.huge
        local minY, maxY = math.huge, -math.huge

        for id, r in pairs(self.rooms) do
            minX = math.min(minX, r.pos.x); maxX = math.max(maxX, r.pos.x)
            minY = math.min(minY, r.pos.y); maxY = math.max(maxY, r.pos.y)
            local visited
            if state.revealMap then
                visited = true
            elseif state.visited then
                visited = state.visited[id] == true
            else
                visited = true
            end
            table.insert(nodes, { id = id, name = r.name, x = r.pos.x, y = r.pos.y, visited = visited, current = (state.roomID == id)})
        end

        for a, r in pairs(self.rooms) do
            for _, b in pairs(r.exits) do
                if self.rooms[b.to] then
                    local u, v = a, b.to
                    if u > v then u, v = v, u end
                    local key = u .. "|" .. v
                    if not seenEdge[key] then
                        seenEdge[key] = true
                        table.insert(edges, { a = u, b = v })
                    end
                end
            end
        end
        self.mapdata = {
            nodes = nodes, edges = edges,
            bounds = { minX = minX, maxX = maxX, minY = minY, maxY = maxY }
        }
    end
    return world
end

return M