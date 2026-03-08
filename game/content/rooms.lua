-- Rooms.
--   exits = {
--     south = { to = "room_id" },
--     north = { to = "room_id", door = "door_id" },
--   }

return {
    cell = {
        kind = "room",
        name = "Holding Cell",
        desc = "Cold concrete. A small window. A door to the north.",
        firstTimeDesc = "You wake in a small concrete cell. You don't know why you've ended up here. " .. 
        "You imagine it might be a conceit of some kind. You decide not to worry too much about this. " ..
        "There is a small window high up on the wall to the south, and a heavy door to the north. ",
        pos = { x = 0, y = 0 },
        exits = {
            north = { to = "corridor", door = "cell_door" },
        },
    },

    corridor = {
        kind = "room",
        name = "Corridor",
        desc = "A dim corridor. The air smells of bleach.",
        pos = { x = 0, y = 1 },
        exits = {
            south = { to = "cell", door = "cell_door" },
            north = { to = "courtyard", door = "outer_gate" },
        },
    },

    courtyard = {
        kind = "room",
        name = "Courtyard",
        desc = "Open air. Fences. Floodlights. Freedom is visible and still not yours.",
        pos = { x = 0, y = 2 },
        exits = {
            south = { to = "corridor" },
        },
    },
}