local Misc = require "misc"
local Camera = require "camera"

local Enemy = {}

function Enemy.new(actor, proto)
	local enemy = {actor = actor, proto = proto, aiState = {}, targettingTile = nil}
	
	for key, value in pairs(proto.startingState) do
		enemy.aiState[key] = value
	end
	
	actor.parent = enemy
	
	return enemy
end

function Enemy.tick(enemy, world, player)
	if enemy.proto.tickFunc then
		enemy.proto.tickFunc(enemy, world, player)
	end
end

function Enemy.postTick(enemy, world, player)
	if enemy.proto.postTickFunc then
		enemy.proto.postTickFunc(enemy, world, player)
	end
end

function Enemy.drawIndicators(enemy, camera)
	if enemy.targettingTile then
		local coords = Misc.orthogLineBetween(enemy.actor.x, enemy.actor.y, enemy.targettingTile[1], enemy.targettingTile[2])
		for i = 1, #coords do
			Camera.drawTo(enemy, coords[i][1], coords[i][2], camera, 
			function(enemy, drawX, drawY, tileWidth, tileHeight)
				love.graphics.setColor(1, 0, 0, 0.6)
				love.graphics.rectangle("fill", drawX - tileWidth/2, drawY - tileHeight/2, tileWidth, tileHeight)
			end)
		end
		Camera.drawTo(enemy, enemy.targettingTile[1], enemy.targettingTile[2], camera, 
		function(enemy, drawX, drawY, tileWidth, tileHeight)
			love.graphics.setColor(1, 0, 0, 0.8 + math.cos(2*GLOBALAnimationClock)/2)
			love.graphics.rectangle("fill", drawX - tileWidth/2, drawY - tileHeight/2, tileWidth, tileHeight)
		end)
	end
end

return Enemy