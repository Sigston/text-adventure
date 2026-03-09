# Text Adventure

A parser-based text adventure engine written in Lua, built on [LÖVE2D](https://love2d.org/). Long-term goal is a feature set approaching TADS — a full interactive fiction authoring system with a clean separation between engine and content.

## Status

Early development. The engine is functional and the first complete puzzle is playable.

## Running

Requires [LÖVE2D](https://love2d.org/) installed.

```bash
love .
```

## Features

- Natural language parser with multi-word verb and alias support
- Disambiguation system for ambiguous noun references
- Container hierarchy — items can be inside other items, inside rooms
- Lockable/openable containers and doors with key items
- Scrollable text log, minimap, and inventory panel UI
- Collapsible side panels

## Project Structure

```
game/        Engine: parser, world, state, verb handlers
ui/          LÖVE2D rendering layer
assets/      Fonts, icons, loader
content/     Rooms, doors, items, scenery (game data)
```
