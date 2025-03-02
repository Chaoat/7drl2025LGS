local Game = require "game"
local Controls = require "controls"
local Misc = require "misc"

GlobalDebugFlag = false

local rootGame = nil
function love.load()
	rootGame = Game.new()
end

function love.update(dt)
	Game.update(rootGame, dt)
end

function love.keypressed(key)
	Game.keyInput(rootGame, key)
	
	if Controls.checkControl(key, "debug", false) then
		GlobalDebugFlag = not GlobalDebugFlag
	end
end

function love.mousepressed(screenx, screeny, button)
	Game.mouseInput(rootGame, screenx, screeny, button)
end

function love.wheelmoved(x, y)
	local wheelControl = Controls.mousewheelToControl(y)
	if wheelControl then
		Game.keyInput(rootGame, wheelControl)
	end
end

function love.draw()
	Game.draw(rootGame)
end