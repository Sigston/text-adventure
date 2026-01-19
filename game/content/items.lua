return {
    -- NOTE: if an item has the same ID as its alias, it will always be resolved if that word
    -- is at issue: two bags, one called "bag" the other "big_bag" and both with the alias "bag"
    -- will always result in the "bag" being selected, as we check for use of the ID first before
    -- looking at aliases - this is to ensure that the disambiguation system is allowed to call
    -- the verb handling system with the ID to have a final say, as it were.
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
        startsIn = "small_bag"
    },
    iron_key = {
        kind = "item",
        name = "Iron Key",
        desc = "A worn iron key.",
        aliases = { "key", "iron key" },
        portable = true,
        isListed = true,
        icon = "key",
        startsIn = "big_bag"
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
    small_bag = {
        kind = "item",
        name = "Small Bag",
        desc = "A hessian bag.",
        aliases = { "bag", "sack", "small bag" },
        isContainer = true,
        openable = true,
        lockable = false,
        portable = false,
        isListed = true,
        icon = "bag",
        startsIn = "cell"
    },
    big_bag = {
        kind = "item",
        name = "Big Bag",
        desc = "A big hessian bag.",
        aliases = { "big bag", "bag", "sack" },
        isContainer = true,
        openable = true,
        lockable = false,
        portable = false,
        isListed = true,
        icon = "bag",
        startsIn = "cell"
    },
}