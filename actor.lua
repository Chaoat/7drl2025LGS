local Letter = require "letter"
local Camera = require "camera"
local Misc = require "misc"

local Actor = {}

local latestID = 0
function Actor.new(letter)
	local actor = {x = nil, y = nil, drawX = nil, drawY = nil, tile = nil, velX = 3, velY = 1, letter = letter, id = latestID}
	latestID = latestID + 1
	return actor
end

function Actor.update(actor, dt)
	if actor.drawX ~= actor.x or actor.drawY ~= actor.y then
		local angle = math.atan2(actor.y - actor.drawY, actor.x - actor.drawX)
		local dist = math.sqrt((actor.y - actor.drawY)^2 + (actor.x - actor.drawX)^2)
		local speed = math.sqrt(actor.velX^2 + actor.velY^2)
		
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

function Actor.draw(actor, camera)
	Camera.drawTo(actor.letter, actor.drawX, actor.drawY, camera, Letter.draw)
end

return Actor