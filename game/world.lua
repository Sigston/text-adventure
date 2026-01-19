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
    world.mapdata = {}
    world.dirAliases = {
        n = "north", s = "south", e = "east", w = "west",
        u = "up", d = "down",
        north = "north", south = "south", east = "east", west = "west",
        up = "up", down = "down",
    }
    mergeInto(world.entities, require("game.content.doors"), "doors")
    mergeInto(world.entities, require("game.content.items"), "items")
    mergeInto(world.entities, require("game.content.rooms"), "rooms")
    mergeInto(world.entities, require("game.content.scenery"), "scenery")

    local function entitySubset(kind)
        local out = { }
        for key, value in pairs(world.entities) do
            if value.kind == kind then out[key] = value end
        end
        return out
    end

    function world:doors() return entitySubset("door") end
    function world:items() return entitySubset("item") end
    function world:rooms() return entitySubset("room") end
    function world:scenery() return entitySubset("scenery") end

    -- For any string, returns the key of the first visible item found with that alias,
    -- and an outcome string ("found", "not_found", "duplicates")
    function world:resolveAlias(alias, state, entities)
        local matchList = { }
        entities = entities or world.entities
        -- Check if the user entered an ID rather than an alias - useful for when the handle() is
        -- triggered internally with a unique ID.
        for _, value in pairs(entities) do
            if value == alias then return alias, "found" end
        end
        for i, _ in ipairs(entities) do
            local entity = world.entities[entities[i]]
            for _, value in ipairs(entity.aliases) do
                if alias == value then table.insert(matchList, entities[i]) end
            end
        end
        if #matchList == 1 then return matchList[1], "found"
        elseif #matchList == 0 then return nil, "not_found"
        else
            table.sort(matchList)
            local returnList = { }
            for i = 1, #matchList do
                returnList[i] = { id = matchList[i] }
            end
            state:setPending("disambig", returnList, alias)
            return nil, "disambig"
        end
    end

    function world:getNames(keyList)
        local out = {}
        for key, value in pairs(world.entities) do
            for i = 1, #keyList do
                if keyList[i] == key then table.insert(out, value.name:lower()) end                
            end
        end
        return out
    end

    function world:getAliases(key)
        return world.entities[key].aliases
    end

    function world:getName(key)
        return world.entities[key].name
    end

    function world:getDesc(roomID, state)
        local room = world:rooms()[roomID]
        if room then
            if state.visited[roomID] then return room.desc
            else return room.firstTimeDesc or room.desc end
        else return end
    end

    function world:generateMapData(state)
        state = state or {}
        local nodes, edges = {}, {}
        local seenEdge = {}
        local minX, maxX = math.huge, -math.huge
        local minY, maxY = math.huge, -math.huge

        local rooms = self:rooms()
        for id, r in pairs(rooms) do
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

        for a, r in pairs(rooms) do
            for _, b in pairs(r.exits) do
                if rooms[b.to] then
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