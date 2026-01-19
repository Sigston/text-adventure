local M = {}

local Inventory = require("game.inventory")

function M.new(world, startRoomID)
    startRoomID = startRoomID or "cell"
    local state = {
        roomID = startRoomID,
        winRoomID = "gate",
        visited = { },
        revealMap = false,
        invID = "inv",
        flags = { won = false },
        inventory = { slots = { } },
        open = {},
        locked = {},
        parents = {},
        -- nil; or kind ("disambig", etc: reason for pending), slot (what part we're disambiguating, i.e., "directObj", "indirectObj"), 
        -- candidates (structured as candidates = { id = "blah" }, { id = "blah2" }), and verb
        pending = nil,
    }

    for entityID, entityTable in pairs(world.entities) do
        state.open[entityID] = entityTable.startsOpen
        state.locked[entityID] = entityTable.startsLocked
        state.parents[entityID] = entityTable.startsIn
    end

    Inventory.rebuild(state)

    function state:setPending(kind, slot, candidates, source, verb)
        local result = {
            kind = kind,
            slot = slot,
            candidates = candidates,
            source = source,
            verb = verb,
        }
        state.pending = result
    end

    -- Note: the action itself will have set state.pending: this function is called in main.lua
    -- to take care of any further actions and return string text to print to request user input.
    function state:changeState(world, from, to)
        local options = { }
        table.insert(options, "Which " .. state.pending.source .. "?")
        for i = 1, #state.pending.candidates do
            table.insert(options, i .. ". " .. world:getName(state.pending.candidates[i].id))
        end
        return options
    end

    function state:children(containerID)
        local children = {}
        for child, parent in pairs(state.parents) do
            if parent == containerID then table.insert(children, child) end
        end
        return children
    end

    function state:inRoom(entityID, roomID)
        return state:inContainer(entityID, roomID)
    end

    function state:inContainer(entityID, containerID)
        local entityParent = state.parents[entityID]
        if entityParent == containerID then return true
        else return false end
    end

    -- Is the passed argument currently visible?
    function state:isVisible(entityID, world)
        local roomItems = state:visibles(world)
        for i = 1, #roomItems do if roomItems[i] == entityID then return true end end
        return false
    end

    -- Returns all currently visible items. Containers should do their own reporting if open.
    function state:visibles(world)
        -- Get all the items in the room
        local out = self:children(state.roomID)
        -- And the doors
        for key, value in pairs(world:rooms()[state.roomID].exits) do
            if value.door then out[#out+1] = value.door end
        end
        return out
        -- Add some stuff here if we implement some items not being visible.
    end

    function state:move(entityID, newContainerID)
        local parent = state.parents[entityID]
        if parent then
            state.parents[entityID] = newContainerID
            return "success"
        else
            return "not_found"
        end
    end

    return state
end

return M