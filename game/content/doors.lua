-- Doors.
--
-- Referenced by rooms.lua exits using `door = "door_id"`.
-- Door state should live in `state.open[door_id]` / `state.locked[door_id]`.

return {
    cell_door = {
        kind = "door",
        name = "Cell Door",
        desc = "A heavy institutional door.",
        aliases = { "door", "cell door", "holding cell door" },
        openable = true,
        lockable = true,
        key = "iron_key",
        startsOpen = false,
        startsLocked = true,
    },

    outer_gate = {
        kind = "door",
        name = "Outer Gate",
        desc = "A gate.",
        aliases = { "gate", "outer gate" },
        openable = true,
        lockable = true,
        key = "exit_key",
        startsOpen = false,
        startsLocked = true,
    },
}