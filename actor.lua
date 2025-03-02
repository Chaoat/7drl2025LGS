local Letter = require "letter"
local Camera = require "camera"
local Misc = require "misc"

local Actor = {}

local latestID = 0
function Actor.new(letter, solidity)
	local actor = {x = nil, y = nil, drawX = nil, drawY = nil, tile = nil, activatedTools = {}, velX = 0, velY = 0, momentX = 0, momentY = 0, solidity = solidity, letter = letter, id = latestID}
	latestID = latestID + 1
	return actor
end

function Actor.toolEffectActive(actor, toolName)
	for i = #actor.activatedTools, 1, -1 do
		print(1)
		local tool = actor.activatedTools[i]
		
		if tool.complete then
			table.remove(actor.activatedTools, i)
		elseif tool.proto.name == toolName then
			return true
		end
	end
	return false
end

function Actor.kill(actor)
	actor.dead = true
	actor.letter.tint = {0.1, 0.1, 0.1, 1}
	actor.solidity = 0
end

function Actor.update(actor, dt)
	if actor.drawX ~= actor.x or actor.drawY ~= actor.y then
		local angle = math.atan2(actor.y - actor.drawY, actor.x - actor.drawX)
		local dist = math.sqrt((actor.y - actor.drawY)^2 + (actor.x - actor.drawX)^2)
		local speed = math.max(math.sqrt(actor.velX^2 + actor.velY^2), dist)
		
		if dist > dt*speed then
			actor.drawX = actor.drawX + dt*speed*math.cos(angle)
			actor.drawY = actor.drawY + dt*speed*math.sin(angle)
		else
			actor.drawX = actor.x
			actor.drawY = actor.y
		end
	end
end

function Actor.getSpeed(actor)
	return Misc.orthogDistance(0, 0, actor.velX, actor.velY)
end

function Actor.changeSpeed(actor, val)
	local currentSpeed = Actor.getSpeed(actor)
	local newSpeed = math.max(currentSpeed + val, 0)
	actor.velX, actor.velY = Misc.orthogPointFrom(0, 0, newSpeed, math.atan2(actor.velY, actor.velX))
end

function Actor.draw(actor, camera)
	Camera.drawTo(actor.letter, actor.drawX, actor.drawY, camera, Letter.draw)
end

return Actor