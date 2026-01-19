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
        local result = nil
        if not state.pending then
            -- Result is nil iff duplicates in object resolution - DONT USE NIL
            result = Commands.handle(payload, world, state)
            if result.status ~= "ok" then result.lines = state:changeState(world, "ok", result.status) end
        else
            -- If the user's input means disambig is successful, then the flag is set,
            -- and the result is a workable payload for handle. Otherwise, result will be
            -- further options for the user.

            -- THIS DOESN'T HANDLE IOs
            if state.pending.kind == "disambig" then
                result = Commands.disambig(payload, world, state)
                if result.status == "ok" then 
                    result = Commands.handle(result.lines[1], world, state)
                elseif result.status == "quitting_disambig" then result.lines = { "Nevermind..." } end
            end
        end
        if result then
            for _, line in ipairs(result.lines) do logUI:add(line) end
            world:generateMapData(state)
            if result.quit then love.event.quit() end

            if (not state.flags.won) and state.roomID == state.winRoomID then
                state.flags.won = true
                logUI:add("")
                logUI:add("You step through the gate.")
                logUI:add("For a second, you expect an alarm. Nothing happens.")
                logUI:add("Air. Night. The world continues without permission.")
                logUI:add("")
                logUI:add("*** YOU WIN *** (type 'quit' to exit)")
            end
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
    invUI:draw(invRect, monoFont, world, state)
end

local _love_errorhandler = love.errorhandler
function love.errorhandler(msg)
    if lldebugger then
        error(msg, 2)
    end
    return _love_errorhandler(msg)
end