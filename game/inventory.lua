-- game/inventory.lua
--
-- Inventory rules live here (not in UI, not in commands).
-- The inventory is a fixed-size container with stable slot ordering.

local M = {}

M.MAX_SLOTS = 9

local function ensure(state)
    state.inventory = state.inventory or { slots = {} }
    state.inventory.slots = state.inventory.slots or {}
    return state.inventory
end

local function indexOf(slots, entityID)
    for i = 1, #slots do
        if slots[i] == entityID then return i end
    end
    return nil
end

-- Build slots from current parent relationships.
-- Used at game start, and as a safety net.
function M.rebuild(state)
    local inv = ensure(state)
    local slots = {}
    local invID = state.invID
    for child, parent in pairs(state.parents or {}) do
        if parent == invID then
            slots[#slots + 1] = child
        end
    end
    table.sort(slots) -- deterministic seed order
    if #slots > M.MAX_SLOTS then
        error(("Inventory overflow: %d items in '%s' (max %d)"):format(#slots, tostring(invID), M.MAX_SLOTS), 2)
    end
    inv.slots = slots
    return inv.slots
end

function M.list(state)
    local inv = ensure(state)
    if not inv.slots or #inv.slots == 0 then
        -- If parents says we have items but slots aren't initialised, rebuild.
        -- (This keeps the module tolerant of older save/state shapes.)
        if state.parents and state.invID then
            return M.rebuild(state)
        end
    end
    return inv.slots
end

function M.count(state)
    return #M.list(state)
end

function M.isFull(state)
    return M.count(state) >= M.MAX_SLOTS
end

function M.has(state, entityID)
    return indexOf(M.list(state), entityID) ~= nil
end

-- Attempt to add an item to inventory (which currently exists).
-- NOTE: this function *does* update containment (state.parents) on success.
--
-- Returns one of:
--   "success" | "full" | "already" | "not_found"
function M.add(state, entityID)
    local slots = M.list(state)
    if indexOf(slots, entityID) then return "already" end
    if #slots >= M.MAX_SLOTS then return "full" end

    -- Update containment
    local ok = (state.parents and state.parents[entityID] ~= nil)
    if not ok then return "not_found" end
    state.parents[entityID] = state.invID

    slots[#slots + 1] = entityID
    return "success"
end

-- Attempt to remove an item from inventory.
-- If destContainerID is provided, containment is updated to that container.
--
-- Returns one of:
--   "success" | "not_in_inventory" | "not_found"
function M.remove(state, entityID, destContainerID)
    local slots = M.list(state)
    local idx = indexOf(slots, entityID)
    if not idx then
        if state.parents and state.parents[entityID] == nil then
            return "not_found"
        end
        return "not_in_inventory"
    end

    table.remove(slots, idx)
    if destContainerID then
        state.parents[entityID] = destContainerID
    end
    return "success"
end

-- Return a 1..MAX_SLOTS array of slot contents (ids or nil).
-- Useful for a 3x3 UI without the UI needing to know about ordering details.
function M.slotGrid(state)
    local slots = M.list(state)
    local grid = {}
    for i = 1, M.MAX_SLOTS do
        grid[i] = slots[i] -- may be nil when fewer than 9 items
    end
    return grid
end

return M
