local M = {
    Log = require("ui.log"),
    Input = require("ui.input"),
    Header = require("ui.header"),
    World = require("game.world"),
    State = require("game.state"),
    Layout = require("ui.layout"),
    Inventory = require("ui.inventory"),
    Map = require("ui.map"),
    Commands = require("game.commands"),
}

function M.load()
    local layout = M.Layout.new()
    local world = M.World.new()
    local state = M.State.new(world)
    local logUI = M.Log.new(layout)
    local inputUI = M.Input.new(layout)
    local headerUI = M.Header.new(layout)
    local invUI = M.Inventory.new(layout)
    local mapUI = M.Map.new(layout)
    world:generateMapData(state)
    local loader = {
        layout = layout, world = world, state = state,
        logUI = logUI, inputUI = inputUI, headerUI = headerUI,
        invUI = invUI, mapUI = mapUI,
    }
    return loader
end

return M