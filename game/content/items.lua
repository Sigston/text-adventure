return {
    note = {
        kind = "item",
        name = "Note",
        desc = "A crumpled note: 'DON'T TRUST THE DOOR.'",
        aliases = { "note", "paper" },
        portable = true,
        isListed = true,
        icon = "note",
        startsIn = "chest_cell"
    },
    brass_key = {
        kind = "item",
        name = "Brass Key",
        desc = "A worn brass key.",
        aliases = { "key", "brass key" },
        portable = true,
        isListed = true,
        icon = "key",
        startsIn = "bag"
    },
    iron_key = {
        kind = "item",
        name = "Iron Key",
        desc = "A worn iron key.",
        aliases = { "key", "iron key" },
        portable = true,
        isListed = true,
        icon = "key",
        startsIn = "bag"
    },
    inv = {
        kind = "item",
        name = "Inventory",
        desc = "Your pockets, such as they are.",
        isContainer = true,
        isListed = false,
        startsIn = "player"
    },
    chest_cell = {
        kind = "item",
        name = "Chest",
        desc = "A battered metal chest.",
        aliases = { "chest", "box" },
        isContainer = true,
        openable = true,
        lockable = true,
        portable = false,
        notPortable = "This is too heavy to carry.",
        isListed = true,
        key = "brass_key",
        icon = "chest",
        startsLocked = true,
        startsIn = "cell",
    },
    bag = {
        kind = "item",
        name = "Bag",
        desc = "A hessian bag.",
        aliases = { "bag", "sack" },
        isContainer = true,
        openable = true,
        lockable = false,
        portable = false,
        isListed = true,
        icon = "bag",
        startsIn = "cell"
    }
}