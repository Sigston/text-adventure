return {
    cell = {
        kind = "room",
        name = "Holding Cell",
        desc = "Cold concrete. A door with a small window. Your wrists ache.",
        pos = { x = 0, y = 0 },
        exits = { north = "corridor_south" }
    },

    corridor_south = {
        kind = "room",
        name = "South Corridor",
        desc = "A dim corridor. The air smells of bleach.",
        pos = { x = 0, y = 1 },
        exits = { south = "cell", north = "corridor_mid", west = "laundry", east = "storage" }
    },

    corridor_mid = {
        kind = "room",
        name = "Mid Corridor",
        desc = "Fluorescent lights buzz overhead.",
        pos = { x = 0, y = 2 },
        exits = { south = "corridor_south", north = "corridor_north", east = "security" }
    },

    corridor_north = {
        kind = "room",
        name = "North Corridor",
        desc = "The corridor widens near a stairwell.",
        pos = { x = 0, y = 3 },
        exits = { south = "corridor_mid", north = "stairwell", west = "kitchen" }
    },

    stairwell = {
        kind = "room",
        name = "Stairwell",
        desc = "Concrete steps up and down. A heavy fire door rattles in a draft.",
        pos = { x = 0, y = 4 },
        exits = { south = "corridor_north", north = "lobby" }
    },

    lobby = {
        kind = "room",
        name = "Lobby",
        desc = "A reception desk. The outside world is *somewhere* beyond the glass.",
        pos = { x = 0, y = 5 },
        exits = { south = "stairwell", north = "courtyard", east = "office" }
    },

    courtyard = {
        kind = "room",
        name = "Courtyard",
        desc = "Open air. Fences. Floodlights. Freedom is visible and still not yours.",
        pos = { x = 0, y = 6 },
        exits = { south = "lobby", north = "gate" }
    },

    gate = {
        kind = "room",
        name = "Outer Gate",
        desc = "A tall gate with an electronic lock. The kind that hates you personally.",
        pos = { x = 0, y = 7 },
        exits = { south = "courtyard" }
    },

    -- West branch
    laundry = {
        kind = "room",
        name = "Laundry Room",
        desc = "Industrial washers. A drain in the floor. A humming extractor fan.",
        pos = { x = -1, y = 1 },
        exits = { east = "corridor_south", north = "workshop" }
    },

    workshop = {
        kind = "room",
        name = "Maintenance Workshop",
        desc = "Tools. Parts. A locked cabinet with a cheap padlock.",
        pos = { x = -1, y = 2 },
        exits = { south = "laundry" }
    },

    kitchen = {
        kind = "room",
        name = "Kitchen",
        desc = "A clean kitchen. There is a door to the east.",
        pos = { x = -1, y = 3 },
        exits = { east = "corridor_north", north = "pantry" }
    },

    pantry = {
        kind = "room",
        name = "Pantry",
        desc = "Shelves of tins. A faint smell of vinegar. Something is hidden here.",
        pos = { x = -1, y = 4 },
        exits = { south = "kitchen" }
    },

    -- East branch
    storage = {
        kind = "room",
        name = "Storage",
        desc = "Crates and shrink-wrapped boxes. Labels peeled off.",
        pos = { x = 1, y = 1 },
        exits = { west = "corridor_south", north = "generator" }
    },

    generator = {
        kind = "room",
        name = "Generator Room",
        desc = "A generator thumps steadily. Cables snake along the wall.",
        pos = { x = 1, y = 2 },
        exits = { south = "storage" }
    },

    security = {
        kind = "room",
        name = "Security Office",
        desc = "Monitors. A swivel chair. A keypad panel by the door.",
        pos = { x = 1, y = 3 },
        exits = { west = "corridor_mid", north = "armory" }
    },

    armory = {
        kind = "room",
        name = "Locked Cabinet Room",
        desc = "A locked cabinet and a notice board full of stale warnings.",
        pos = { x = 1, y = 4 },
        exits = { south = "security" }
    },

    office = {
        kind = "room",
        name = "Office",
        desc = "Paperwork. Keys. The smell of coffee that died hours ago.",
        pos = { x = 1, y = 5 },
        exits = { west = "lobby" }
    },
}