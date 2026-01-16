-- Rooms.
--   exits = {
--     south = { to = "room_id" },
--     north = { to = "room_id", door = "door_id" },
--   }

return {
    cell = {
        kind = "room",
        name = "Holding Cell",
        desc = "Cold concrete. A door with a small window. Your wrists ache.",
        firstTimeDesc = "You wake in a small concrete cell. You don't know why you've ended up here. " .. 
        "You imagine it might be a conceit of some kind. You decide not to worry too much about this.",
        pos = { x = 0, y = 0 },
        exits = {
            north = { to = "corridor_south", door = "cell_door" },
        },
    },

    corridor_south = {
        kind = "room",
        name = "South Corridor",
        desc = "A dim corridor. The air smells of bleach.",
        pos = { x = 0, y = 1 },
        exits = {
            south = { to = "cell", door = "cell_door" },
            north = { to = "corridor_mid" },
            west  = { to = "laundry" },
            east  = { to = "storage" },
        },
    },

    corridor_mid = {
        kind = "room",
        name = "Mid Corridor",
        desc = "Fluorescent lights buzz overhead.",
        pos = { x = 0, y = 2 },
        exits = {
            south = { to = "corridor_south" },
            north = { to = "corridor_north" },
            east  = { to = "security", door = "security_door" },
        },
    },

    corridor_north = {
        kind = "room",
        name = "North Corridor",
        desc = "The corridor widens near a stairwell.",
        pos = { x = 0, y = 3 },
        exits = {
            south = { to = "corridor_mid" },
            north = { to = "stairwell", door = "fire_door" },
            west  = { to = "kitchen", door = "kitchen_door" },
        },
    },

    stairwell = {
        kind = "room",
        name = "Stairwell",
        desc = "Concrete steps up and down. A heavy fire door rattles in a draft.",
        pos = { x = 0, y = 4 },
        exits = {
            south = { to = "corridor_north", door = "fire_door" },
            north = { to = "lobby" },
        },
    },

    lobby = {
        kind = "room",
        name = "Lobby",
        desc = "A reception desk. The outside world is *somewhere* beyond the glass.",
        pos = { x = 0, y = 5 },
        exits = {
            south = { to = "stairwell" },
            north = { to = "courtyard" },
            east  = { to = "office" },
        },
    },

    courtyard = {
        kind = "room",
        name = "Courtyard",
        desc = "Open air. Fences. Floodlights. Freedom is visible and still not yours.",
        pos = { x = 0, y = 6 },
        exits = {
            south = { to = "lobby" },
            north = { to = "gate" },
        },
    },

    gate = {
        kind = "room",
        name = "Outer Gate",
        desc = "A tall gate with an electronic lock. The kind that hates you personally.",
        pos = { x = 0, y = 7 },
        exits = {
            south = { to = "courtyard" },
        },
    },

    -- West branch
    laundry = {
        kind = "room",
        name = "Laundry Room",
        desc = "Industrial washers. A drain in the floor. A humming extractor fan.",
        pos = { x = -1, y = 1 },
        exits = {
            east  = { to = "corridor_south" },
            north = { to = "workshop" },
        },
    },

    workshop = {
        kind = "room",
        name = "Maintenance Workshop",
        desc = "Tools. Parts. A locked cabinet with a cheap padlock.",
        pos = { x = -1, y = 2 },
        exits = {
            south = { to = "laundry" },
        },
    },

    kitchen = {
        kind = "room",
        name = "Kitchen",
        desc = "A clean kitchen. There is a door to the east.",
        pos = { x = -1, y = 3 },
        exits = {
            east  = { to = "corridor_north", door = "kitchen_door" },
            north = { to = "pantry" },
        },
    },

    pantry = {
        kind = "room",
        name = "Pantry",
        desc = "Shelves of tins. A faint smell of vinegar. Something is hidden here.",
        pos = { x = -1, y = 4 },
        exits = {
            south = { to = "kitchen" },
        },
    },

    -- East branch
    storage = {
        kind = "room",
        name = "Storage",
        desc = "Crates and shrink-wrapped boxes. Labels peeled off.",
        pos = { x = 1, y = 1 },
        exits = {
            west  = { to = "corridor_south" },
            north = { to = "generator" },
        },
    },

    generator = {
        kind = "room",
        name = "Generator Room",
        desc = "A generator thumps steadily. Cables snake along the wall.",
        pos = { x = 1, y = 2 },
        exits = {
            south = { to = "storage" },
        },
    },

    security = {
        kind = "room",
        name = "Security Office",
        desc = "Monitors. A swivel chair. A keypad panel by the door.",
        pos = { x = 1, y = 3 },
        exits = {
            west  = { to = "corridor_mid", door = "security_door" },
            north = { to = "armory", door = "armory_door" },
        },
    },

    armory = {
        kind = "room",
        name = "Locked Cabinet Room",
        desc = "A locked cabinet and a notice board full of stale warnings.",
        pos = { x = 1, y = 4 },
        exits = {
            south = { to = "security", door = "armory_door" },
        },
    },

    office = {
        kind = "room",
        name = "Office",
        desc = "Paperwork. Keys. The smell of coffee that died hours ago.",
        pos = { x = 1, y = 5 },
        exits = {
            west = { to = "lobby" },
        },
    },
}