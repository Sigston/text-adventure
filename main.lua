local lldebugger
if arg and arg[2] == "debug" then
    lldebugger = require("lldebugger")
    lldebugger.start()
end

local Log = require("ui.log")
local Input = require("ui.input")
local Header = require("ui.header")
local World = require("game.world")
local State = require("game.state")
local Layout = require("ui.layout")
local Inventory = require("ui.inventory")
local Map = require("ui.map")
local Commands = require("game.commands")

local openingMessage = "***BREAKOUT***\n"

local logUI
local inputUI
local headerUI
local invUI
local mapUI
local layout
local world
local state
local monoFont 

function love.load()
    monoFont = love.graphics.newFont("assets/space-mono.ttf", 13)
    layout = Layout.new()
    world = World.new()
    state = State.new(world, "cell")
    logUI = Log.new(layout)
    inputUI = Input.new(layout)
    headerUI = Header.new(layout)
    invUI = Inventory.new(layout)
    mapUI = Map.new(layout)

    world:generateMapData(state)
    logUI:add(openingMessage)
    local result = Commands.handle("l", world, state)
    for _, line in ipairs(result.lines) do logUI:add(line) end
    state.visited[state.roomID] = true
end

function love.update(dt)
    layout:update(dt)
end

function love.textinput(t)
    inputUI:textinput(t)
end

function love.keypressed(key)
    local event, payload = inputUI:keypressed(key)
    if event == "submit" then
        logUI:add("> " .. payload)
        local result = Commands.handle(payload, world, state)
        for _, line in ipairs(result.lines) do logUI:add(line) end
        world:generateMapData(state)
        if result.quit then love.event.quit() end
        if (not state.won) and state.roomID == state.winRoomID then
            state.won = true
            logUI:add("")
            logUI:add("You step through the gate.")
            logUI:add("For a second, you expect an alarm. Nothing happens.")
            logUI:add("Air. Night. The world continues without permission.")
            logUI:add("")
            logUI:add("*** YOU WIN *** (type 'quit' to exit)")
        end
    elseif event == "scroll" then
        logUI:scroll(payload)
    elseif event == "quit" then
        love.event.quit()
    end
end

function love.wheelmoved(dx, dy)
    local scrollStep = 3
    logUI:scroll(dy * scrollStep)
end

function love.mousepressed(x, y, button)
    layout:handleClick(x, y, button)
end

function love.mousemoved(x, y)
    layout:handleMouseMove(x, y)
end

function love.draw()
    local headerRect, logRect, inputRect, mapRect, invRect = layout:rects()
    layout:drawBackground()
    logUI:draw(logRect, monoFont)
    inputUI:draw(inputRect, monoFont)
    headerUI:draw(headerRect, monoFont, world:rooms()[state.roomID].name)
    mapUI:draw(mapRect, monoFont, world.mapdata)
    invUI:draw(invRect)
end

local _love_errorhandler = love.errorhandler
function love.errorhandler(msg)
    if lldebugger then
        error(msg, 2)
    end
    return _love_errorhandler(msg)
end