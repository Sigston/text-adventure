# Text Adventure Roadmap

---

## Smaller jobs checklist

### Word wrap.

**Word-wrap (recommended before real prose):**
- Option A (simple): when `add(line)`, wrap to multiple visual lines using `font:getWrap(line, width)`
- Store wrapped lines in the log (so scrolling counts *render lines*)
- Option B (later): cache wraps per width and recompute on resize.

**Acceptance:** long descriptions don’t smear across panels.

---

### Make input UTF-8 consistent (or declare ASCII-only)
**Current risk:** mixing byte offsets and character moves.
**Decision:**
- Either commit to UTF-8: caret stored as **byte index**, but updated using `utf8.offset`.
- Or explicitly treat input as ASCII for now and simplify (less code).

**UTF-8 algorithm:**
- Move left: `caretByte = utf8.offset(input, -1, caretByte) or caretByte`
- Move right: `caretByte = utf8.offset(input, 2, caretByte) or (len+1)`
- Insert text: splice at `caretByte`, then advance using `utf8.offset` based on inserted text.

**Acceptance:** multi-byte characters don’t corrupt caret behaviour.

---

### Layout interaction: tabs are the clickable region
**Problem:** currently clicking anywhere inside map/inv panel toggles.
**Better:** define tab rectangles:
- left tab: `{X=mapRect.X+..., W=tabClosedWidth, ...}`
- right tab: `{X=invRect.X+invRect.W-tabClosedWidth, ...}`
Only toggle when click hits tab rect; panel area is for interactions later (map hover, inventory click).

**Acceptance:** panel clicks don’t collapse it.

---

### World validation pass (fail loudly at load)
Add `validateWorld(world)` once, early:
- Every room has `pos` and `exits` table (or empty)
- Every exit points to an existing room id
- No duplicate ids
- No item references to missing ids (if you have initial placements)

**Acceptance:** bad content causes clear errors at startup, not odd runtime behaviour.

---

### Debug toggles and dev commands
Add a `debug` table or flags in state:
- `state.revealMap = true`
- `state.allVisited = true` (or command `reveal`)
- `teleport <roomid>`
- `dump` prints room id, inventory, flags

**Implementation:** treat these as commands gated behind a debug flag.

---

### Performance hygiene (low priority)
- Don’t recompute map data every frame unless state changed.
- Avoid temporary table allocations inside hot draw loops where easy.
- Cache fonts and layout inner rects where possible.

---

## Larger project plan (systems + suggested structures)

### A) Data model spine: Entities + State separation
**Goal:** keep `world` mostly static; keep all mutable facts in `state`.

**Suggested runtime structure:**
- `world.entities[id] = { kind="room"/"item", ... }`
- Rooms are containers by `kind=="room"`
- Containers-as-items: `kind="item", isContainer=true` (portable bags/chests possible)

**Mutable state (core):**
- `state.roomID` (current room)
- `state.visited[roomId]=true`
- `state.parent[entityId]=containerId` (unified containment)
- `state.flags[key]=true/number/string` (puzzle state)
- optional: `state.entity[entityId]={ open=true, locked=false, damaged=true }`

**Invariant:** every non-room entity has exactly one parent; rooms have no parent.

---

### B) Containment engine (small, but crucial)
This is the “unites inventory/rooms/chests” module.

**Essential helpers:**
- `isContainer(world, id)` → true if room or entity.isContainer
- `children(state, containerId)` → list of ids whose parent is containerId
- `move(state, id, newContainerId)` → update parent
- `topRoom(state, world, id)` → follow parents until a room id
- `isReachable(state, world, id)` → true if in current room or in open containers in current room

**Visibility rule (baseline):**
- A child is visible if:
  - its parent is the current room, OR
  - its parent is a container that is visible and open, recursively.

This gives “key in open chest in room” naturally.

---

### C) Command pipeline: parse → normalise → dispatch → result
Keep `commands.lua` clean by structuring:

1. **Normalisation**
   - trim + lower
   - alias resolution (`n` → `north`, `l` → `look`)
2. **Parsing**
   - `verb`, `directObject`, optional `preposition`, `indirectObject`
   - Start simple: `take X`, `put X in Y`, `use X on Y`
3. **Dispatch**
   - `handlers[verb](cmd, world, state) -> result`
4. **Result**
   - `{ lines = {...}, quit=false }`

**Tip:** always return the same shape. Never return raw lists sometimes and tables other times.

---

### D) Descriptions: a single “describe” layer
Avoid embedding prose logic in command handlers.

Create `game/describe.lua`:
- `describeRoom(world, state, roomId)` returns array of lines:
  - room.desc
  - visible items summary
  - exits summary
- `describeEntity(world, state, id)` returns name/desc based on template + state overrides.

**Algorithmic benefit:** you can call this after `go`, `look`, even after puzzle events.

---

### E) Items: resolution + verbs
**Core verbs:**
- `take`, `drop`, `inventory`, `examine`

**Resolution algorithm (important):**
- Build a list of *candidate entity ids* (visible/reachable scope)
- Match user text against:
  - entity.name (lowercased)
  - `entity.aliases[]`
- If multiple matches:
  - disambiguate (“Which key: brass key / rusty key?”)
- Return entity id.

**Data fields to add:**
- `aliases = {...}`
- `portable = true/false`

---

### F) Containers and doors (first real puzzles)
Model “door” as either:
- an exit property: `exits.north = { to="hall", door="door_cell" }`
- or as a container-like entity with `locked/open`.

**State additions:**
- `state.entity[doorId].locked = true`
- `state.entity[chestId].open = false`

**Rules:**
- movement checks door state before allowing `go`
- contents visibility checks container open state
- `unlock` checks for required key in inventory

**Minimal puzzle loop:** find key → unlock door → escape corridor.

---

### G) Map generation from entities + visited state
**Input:** `world.entities`, `state.visited`, `state.roomID`
**Output:** `{ nodes, edges, bounds }`
- Nodes: only rooms (always), but renderer decides whether to draw based on visited/current.
- Edges: derived from room exits; dedupe via canonical pair `(min,max)`.

**Fog-of-war drawing rule:**
- draw node if visited or current or debug reveal
- draw edge if both endpoints drawn (or “discovered” rule if you add it)

**Keep bounds stable:** compute bounds from *all rooms*, not only visited.

---

### H) Inventory UI (make it do something)
Minimum:
- render inventory as a grid/list from `children(state, "inv")`
- hover shows name
- click selects item; show details panel inside inventory panel area

Later:
- drag/drop to containers
- hotkeys 1–9 for quick use

---

### I) Text UI polish (log + prompt feel)
- Word-wrap
- scrollback pinned behaviour
- input editing robust
- “command echo” styling (dim user input vs game output)
- optional: hyperlink-like highlight of exits/items (clickable tokens)

---

### J) Puzzle framework (flags + conditional descriptions)
Start small with:
- `state.flags.powerOff = true`
- `room.desc` can be a function(world,state) for conditional text, or keep templates + describe() overlays.
- scripted events can be triggered on entering rooms (`onEnter` callbacks).

Keep it data-driven:
- puzzles are conditions + actions:
  - condition: has key, door locked
  - action: unlock door, add log line, set flag

---

### K) Content organisation (type-based files) + validation
Split by entity type:
- `game/content/rooms.lua`
- `game/content/items.lua`
- `game/content/npcs.lua` (empty until needed)

`world.lua` merges and validates.

**Flexibility tip:** you can later split each type into multiple files without changing the runtime model.

---

### L) Save/load (when you’ve got gameplay)
**Save only state.**
- `roomID`, `visited`, `parent`, `flags`, `entity` (open/locked/damaged), etc.
- World is loaded from content files.

Start with a debug “dump state to console”; later serialize to JSON or Lua table.

---

## Suggested “definition of done” for Project 1 (minimal game)
- You can move around all rooms with `go`/directions
- `look` shows description + visible items + exits reliably
- `take/drop/inventory/examine` works with aliases + disambiguation
- At least one container + one locked door puzzle
- Map shows visited rooms, current room, and discovered connections
- Inventory panel shows items with icons/labels
- Game ends with a win condition at the gate

---
