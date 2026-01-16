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
        entity = {},
        inventory = { slots = { } },
    }

    state.parents = {
        inv = "player",
        chest_cell = "cell",
        brass_key = "bag",
        note = "inv",
        bag = "cell"
    }
    state.open = {
        chest_cell = false,
        bag = false,
        cell_door = false,
    }
    state.locked = {
        chest_cell = true,
        bag = false,
        cell_door = true,
    }

    Inventory.rebuild(state)

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
            table.insert(out, value.door)
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