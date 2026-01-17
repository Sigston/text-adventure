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
        key = "brass_key",
        startsOpen = false,
        startsLocked = true,
    },

    fire_door = {
        kind = "door",
        name = "Fire Door",
        desc = "A heavy fire door that rattles in a draft.",
        aliases = { "fire door", "door" },
        openable = true,
        lockable = false,
        startsOpen = false,
        startsLocked = false,
    },

    security_door = {
        kind = "door",
        name = "Security Door",
        desc = "A reinforced door with a keypad panel beside it.",
        aliases = { "security door", "keypad", "door" },
        openable = true,
        lockable = false,
        startsOpen = false,
        startsLocked = false,
    },

    armory_door = {
        kind = "door",
        name = "Armory Door",
        desc = "A solid door with a stubborn-looking lock.",
        aliases = { "armory door", "cabinet room door", "door" },
        openable = true,
        lockable = true,
        key = "brass_key",
        startsOpen = false,
        startsLocked = true,
    },

    kitchen_door = {
        kind = "door",
        name = "Kitchen Door",
        desc = "A plain interior door, recently cleaned.",
        aliases = { "kitchen door", "door" },
        openable = true,
        lockable = false,
        startsOpen = true,
        startsLocked = false,
    },
}