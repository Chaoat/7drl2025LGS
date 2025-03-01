local Tile = require "tile"
local Map = require "map"
local Misc = require "misc"
local Actor = require "actor"
local Player = require "player"

local TurnCalculator = {}

function TurnCalculator.new(world, player)
	local turnCalculator = {world = world, player = player}
	
	return turnCalculator
end

function TurnCalculator.pass(turnCalculator)
	--Move Actors
	local comparator = function(a, b)
		if a.movesLeft > b.movesLeft then
			return -1
		elseif a.movesLeft < b.movesLeft then
			return 1
		else
			return 0
		end
	end
	local actorMoves = {}
	for i = 1, #turnCalculator.world.actors do
		local actor = turnCalculator.world.actors[i]
		local numMoves = math.floor(math.max(math.abs(actor.velX), math.abs(actor.velY)))
		
		if numMoves > 0 then
			local actorMove = {actor = actor, floatingX = actor.x, floatingY = actor.y, movesLeft = numMoves}
			Misc.binaryInsert(actorMoves, actorMove, comparator)
		end
	end
	
	while #actorMoves > 0 do
		local actorMove = actorMoves[1]
		local newX, newY = Misc.orthogPointFrom(actorMove.floatingX, actorMove.floatingY, 1, math.atan2(actorMove.actor.velY, actorMove.actor.velX))
		--print(newX .. " : " .. newY)
		local targetTile = Map.getTile(turnCalculator.world.map, Misc.round(newX), Misc.round(newY))
		if targetTile then
			if targetTile.solidity >= Actor.getSpeed(actorMove.actor) then
				if targetTile.x ~= actorMove.actor.x then
					actorMove.actor.velX = 0
					actorMove.movesLeft = actorMove.actor.velY
				else
					actorMove.actor.velY = 0
					actorMove.movesLeft = actorMove.actor.velX
				end
			elseif actorMove.actor.solidity < targetTile.solidity then
				Actor.kill(actorMove.actor)
			else
				if targetTile.solidity > 0 then
					Actor.changeSpeed(actorMove.actor, -targetTile.solidity)
					Tile.wreck(targetTile)
				end
				Tile.moveActor(targetTile, actorMove.actor)
				actorMove.floatingX = newX
				actorMove.floatingY = newY
			end
		end
		
		actorMove.movesLeft = actorMove.movesLeft - 1
		table.remove(actorMoves, 1)
		if actorMove.movesLeft > 0 then
			Misc.binaryInsert(actorMoves, actorMove, comparator)
		end
	end
	
	Player.forceUpdateHeading(turnCalculator.player)
	Player.calculatePredictedSquares(turnCalculator.player)
end

return TurnCalculator