local Game = require "game"
local Controls = require "controls"
local Misc = require "misc"

GlobalDebugFlag = false
GLOBALAnimationClock = 0
GLOBALStallClock = false

local rootGame = nil
function love.load()
	math.randomseed(os.clock())
	rootGame = Game.new()
end

local doProfile = false
local profileTimer = 0
function love.update(dt)
	if GLOBALStallClock then
		dt = 0
		GLOBALStallClock = false
	end
	
	GLOBALAnimationClock = GLOBALAnimationClock + dt
	Game.update(rootGame, dt)
	
	if doProfile then
		if love.profiler == nil then
			love.profiler = require('profile')
		end
		
		if love.profiler.isRunning() == false then
			love.profiler.start()
		end
		
		print(profileTimer)
		profileTimer = profileTimer + 1
		if profileTimer > 60 then
			print(love.profiler.report(20))
			love.profiler.reset()
			profileTimer = 0
			doProfile = false
		end
	else
		if love.profiler then
			if love.profiler.isRunning() then
				love.profiler.stop()
			end
		end
	end
end

function love.keypressed(key)
	Game.keyInput(rootGame, key)
	
	if Controls.checkControl(key, "debug", false) then
		GlobalDebugFlag = not GlobalDebugFlag
	elseif Controls.checkControl(key, "profile", false) then
		doProfile = true
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

function love.resize(w, h)
	Game.resize(rootGame, w, h)
end

function love.draw()
	Game.draw(rootGame)
end