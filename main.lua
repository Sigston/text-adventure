local lldebugger
if arg and arg[2] == "debug" then
    lldebugger = require("lldebugger")
    lldebugger.start()
end

local Modules = require("assets.loader")
local monoFont
local game

local function initialCommand()
    local result = Modules.Commands.handle("l", game.world, game.state)
    for _, line in ipairs(result.lines) do game.logUI:add(line) end
    game.state.visited[game.state.roomID] = true
end

function love.load()
    game = Modules.load()
    monoFont = love.graphics.newFont("assets/space-mono.ttf", 13)
    initialCommand()
end

function love.update(dt)
    game.layout:update(dt)
end

function love.textinput(t)
    game.inputUI:textinput(t)
end

function love.keypressed(key)
    local event, payload = game.inputUI:keypressed(key)
    if event == "submit" then
        game.logUI:add("> " .. payload)
        local result = nil
        if not game.state.pending then
            -- Result is nil iff duplicates in object resolution - DONT USE NIL
            result = Modules.Commands.handle(payload, game.world, game.state)
            if result.status ~= "ok" then result.lines = game.state:changeState(game.world, "ok", result.status) end
        else
            -- If the user's input means disambig is successful, then the flag is set,
            -- and the result is a workable payload for handle. Otherwise, result will be
            -- further options for the user.

            -- THIS DOESN'T HANDLE IOs
            if game.state.pending.kind == "disambig" then
                result = Modules.Commands.disambig(payload, game.world, game.state)
                if result.status == "ok" then 
                    result = Modules.Commands.handle(result.lines[1], game.world, game.state)
                elseif result.status == "quitting_disambig" then result.lines = { "Nevermind..." } end
            end
        end
        if result then
            for _, line in ipairs(result.lines) do game.logUI:add(line) end
            game.world:generateMapData(game.state)
            if result.quit then love.event.quit() end

            if (not game.state.flags.won) and game.state.roomID == game.state.winRoomID then
                game.state.flags.won = true
                game.logUI:add("")
                game.logUI:add("You step through the gate.")
                game.logUI:add("For a second, you expect an alarm. Nothing happens.")
                game.logUI:add("Air. Night. The world continues without permission.")
                game.logUI:add("")
                game.logUI:add("*** YOU WIN *** (type 'quit' to exit)")
            end
        end
    elseif event == "scroll" then
        game.logUI:scroll(payload)
    elseif event == "quit" then
        love.event.quit()
    end
end

function love.wheelmoved(dx, dy)
    local scrollStep = 3
    game.logUI:scroll(dy * scrollStep)
end

function love.mousepressed(x, y, button)
    game.layout:handleClick(x, y, button)
end

function love.mousemoved(x, y)
    game.layout:handleMouseMove(x, y)
end

function love.draw()
    local headerRect, logRect, inputRect, mapRect, invRect = game.layout:rects()
    game.layout:drawBackground()
    game.logUI:draw(logRect, monoFont)
    game.inputUI:draw(inputRect, monoFont)
    game.headerUI:draw(headerRect, monoFont, game.world:rooms()[game.state.roomID].name)
    game.mapUI:draw(mapRect, monoFont, game.world.mapdata)
    game.invUI:draw(invRect, monoFont, game.world, game.state)
end

local _love_errorhandler = love.errorhandler
function love.errorhandler(msg)
    if lldebugger then
        error(msg, 2)
    end
    return _love_errorhandler(msg)
end