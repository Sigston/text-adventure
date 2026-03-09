# CLAUDE.md — Text Adventure Engine

## Project Purpose

A parser-based text adventure (interactive fiction) engine built with **LÖVE2D** (love2d) in **Lua**. The current game is a minimal v1 prison-escape scenario: three rooms (Cell → Corridor → Courtyard), a handful of items, and a key-chain puzzle. The engine is the main focus; content is illustrative.

## How to Run

```bash
love .
```

From the project root. Requires LÖVE2D installed on the system.

**Debug mode** (VS Code + lldebugger):
```bash
love . debug
```

Window config is in `conf.lua`: 1200×800, resizable, titled "Text Adventure".

There are no tests, no build step, no package manager.

---

## Architecture

```
main.lua                    LÖVE2D entry point and event loop
conf.lua                    Window configuration
assets/loader.lua           Wires all modules together; returns the game object

game/
  commands.lua              Top-level command handler; disambig logic
  world.lua                 Static entity registry; alias resolution; map data
  state.lua                 All mutable game state
  inventory.lua             Inventory logic (9-slot fixed-size container)
  tokenizer.lua             Lowercases and splits raw input into word tokens
  parser.lua                Matches tokens to verb aliases; splits direct/indirect/prep

  verbs/
    verbs.lua               Verb registry; dynamically loads act/resolve/doVerb from files
    verbhelper.lua          Shared utilities: entity listing, exit listing, aLister
    look.lua                Room description
    go.lua                  Movement; calls look.act internally after moving
    take.lua                Pick up items
    drop.lua                Drop items
    examine.lua             Examine entities (shows open/closed/locked state)
    open.lua                Open containers and doors (implies unlock if key present)
    close.lua               Close containers and doors
    lock.lua                Lock with key from inventory
    unlock.lua              Unlock with key from inventory
    put.lua                 Put item in container (two-object verb)
    inventory.lua           List inventory
    help.lua                Hardcoded help text
    quit.lua                Exits the game

  content/
    rooms.lua               Room definitions
    doors.lua               Door definitions
    items.lua               Item definitions (including inventory container entity)
    scenery.lua             Scenery definitions

ui/
  layout.lua                Panel geometry, animation, mouse click/hover handling
  log.lua                   Scrollable text output panel
  input.lua                 Text input bar; emits "submit"/"scroll"/"quit" events
  header.lua                Current room name display
  map.lua                   Minimap (nodes + edges from world.mapdata)
  inventory.lua             Inventory panel (3×3 slot grid)
  theme.lua                 Colour theme
```

---

## Key Concepts and Conventions

### State vs World

- **`world`** is static: it holds entity definitions (`world.entities`) and pure query methods. Never mutated after load.
- **`state`** is the only mutable structure: room position, open/locked flags, item locations, inventory, pending disambig, visited rooms, win flag.

### Entity System

All entities (rooms, doors, items, scenery) are merged into a single flat `world.entities` table keyed by ID (snake_case string). The `kind` field (`"room"`, `"door"`, `"item"`, `"scenery"`) distinguishes them. Helper methods (`world:rooms()`, `world:items()`, etc.) filter by kind.

**Entity location** is tracked in `state.parents[entityID]` — every entity maps to its container's ID (a room ID, another item's ID, `"inv"` for inventory, or `"player"` as a sentinel for the inventory entity itself).

**Open/locked state** lives in `state.open[id]` and `state.locked[id]`, initialised at startup from `startsOpen`/`startsLocked` on the entity definition.

### Content Definition Formats

**Rooms:**
```lua
cell = {
    kind = "room", name = "Holding Cell",
    desc = "Short desc shown on revisit.",
    firstTimeDesc = "Long desc shown only first time.",  -- optional
    pos = { x = 0, y = 0 },                              -- for minimap
    exits = {
        north = { to = "corridor", door = "cell_door" }, -- door is optional
    },
}
```

**Doors:**
```lua
cell_door = {
    kind = "door", name = "Cell Door",
    desc = "A heavy institutional door.",
    aliases = { "door", "cell door" },
    openable = true, lockable = true, key = "iron_key",
    startsOpen = false, startsLocked = true,
}
```

**Items:**
```lua
brass_key = {
    kind = "item", name = "Brass Key",
    desc = "A worn brass key.",
    aliases = { "key", "brass key" },
    portable = true, isListed = true,
    icon = "key",                  -- used by inventory UI
    startsIn = "small_bag",        -- container ID or room ID
}
-- Container items also have:
--   isContainer = true, openable = true/false, lockable = true/false
--   key = "key_id", startsLocked = true/false
--   notPortable = "Message when player tries to take it"  (if portable = false)
```

**Scenery:**
```lua
cell_window = {
    kind = "scenery",
    aliases = { "window" },
    desc = "A small window high up on the wall.",
    loc = "cell",                  -- room ID (fixed; scenery doesn't move)
    isPortable = false, isListed = false,
}
```

### Alias Resolution and Disambiguation

`world:resolveAlias(alias, state, entities)` searches `entities` (a list of IDs) for a match against each entity's `aliases` array. Returns `id, "found"` | `nil, "not_found"` | `nil, "disambig"`.

On `"disambig"`, it calls `state:setPending("disambig", candidates, source)` and the caller returns `{ "disambig" }` from `act`. `commands.lua` catches this, stores the verb, and prompts the user to pick a number. The resolved ID is then fed back through `commands.handle` as a raw ID string (bypassing alias lookup via the ID-first check in `resolveAlias`).

**Important:** If an item's ID exactly matches one of its aliases, it will always win disambiguation — `resolveAlias` checks for an ID match first. This is intentional (allows internal calls with IDs to always resolve cleanly).

### Verb Pipeline

```
tokenizer.tokenize(line)        → tokens (lowercase words)
parser.parse(tokens, Verb)      → { verb = "open", objects = { direct = "chest", ... } }
commands.doVerb(verb, objects)
  → verbList[verb].resolve(world, state)           → entities (scope)
  → verbList[verb].act(entities, objects, world, state, verbList)  → lines, quit
  → return { status, lines, quit }
```

- `resolve` returns the list of entity IDs the verb can operate on (its scope). Most verbs use `helper.xEntities` (room items + scenery + doors + inventory). `drop` resolves only inventory. `go` resolves `world.dirAliases`.
- `act` does all the logic and returns `lines` (table of strings) and optionally `quit` (bool, default nil/false). **`report` functions no longer exist** — `act` is the terminal step.
- `doVerb` (where present) is the raw state mutation function, used for internal calls between verbs.
- `go.act` calls `verbs.look.act("", "", world, state)` internally after moving to print the new room description.

### Verb File Structure

Each verb file exports some of: `resolve`, `act`, `doVerb`. `verbs.lua` dynamically loads these into the verb registry. Files that don't need a function simply don't export it.

### Inventory

`game/inventory.lua` manages a 9-slot fixed-size inventory. The inventory is itself an entity (`inv`) in `items.lua` with `startsIn = "player"` (sentinel). `Inventory.add/remove` update both `state.parents` and `state.inventory.slots`. The UI uses `Inventory.slotGrid` for the 3×3 display.

---

## Non-Obvious Decisions

- **`state.parents` is the source of truth for location** — the inventory slots table is derived from it and is kept in sync by `Inventory.add/remove`. `Inventory.rebuild` can resync slots from parents if needed.
- **`open.act` implies unlock** — if a player tries to `open` a locked container and has the correct key, it automatically unlocks first before opening. This is a usability convenience.
- **`state.pending` is nil when not disambiguating** — `main.lua` branches on `game.state.pending` to route input to either `Commands.handle` or `Commands.disambig`.
- **`help.lua` is hardcoded** — it does not derive its list from `verbs.lua`. This is a known gap.
- **Rooms have `pos` for the minimap** — `world:generateMapData` uses these to lay out nodes and edges. Call this after any state change that affects visited rooms.
- **`lldebugger`** is a VS Code Lua debugger adapter. The `love . debug` argument activates it; errors are re-thrown so the debugger catches them rather than the LÖVE error screen.

---

## Current Development State

**v1 is complete and playable.** The puzzle:
1. `open small bag` → `take brass key`
2. `unlock chest` → `open chest` → `take note` (hint: gate key is on the desk)
3. `open big bag` → `take iron key`
4. `unlock door` → `open door` → `go north`
5. `open desk` → `take gate key`
6. `unlock gate` → `open gate` → `go north` → **win**

**Refactor in progress** (do not start until asked):

| Step | Status | Description |
|------|--------|-------------|
| 1. Remove `report` functions | **Done** | `act` is now terminal; `commands.lua` captures `lines, quit` directly |
| 2. Extract `act` preamble | **TODO** | Add `helper.resolveObject(...)` to `verbhelper.lua`; simplify open, close, lock, unlock, take, examine, drop |
| 3. Data-driven open/close/lock/unlock | **TODO** | Collapse four verb files into config tables in `verbs.lua` + one shared handler |

**Known issues:**
- `world:resolveAlias` has a noted bug (line 49 in `world.lua`): the ipairs pass over `entities` assumes it is a sequential array, but it can receive a keyed table in some code paths.
- `go.lua` has duplicated move+look logic for the door vs. no-door cases; minor cleanup opportunity.
- `state.pending` disambig does not fully handle indirect objects (`-- THIS DOESN'T HANDLE IOs` comment in `main.lua:45`).