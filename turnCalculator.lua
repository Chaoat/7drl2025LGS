local Tile = require "tile"
local Map = require "map"
local Misc = require "misc"
local Actor = require "actor"
local Player = require "player"
local Tool = require "tool"
local World = require "world"
local Enemy = require "enemy"

local TurnCalculator = {}

function TurnCalculator.new(world, player)
	local turnCalculator = {world = world, player = player}
	
	return turnCalculator
end

function TurnCalculator.pass(turnCalculator)
	World.tickAllEnemies(turnCalculator.world, turnCalculator.player)
	
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
		actor.velX = actor.velX + actor.momentX
		actor.velY = actor.velY + actor.momentX
		local numMoves = math.floor(math.max(math.abs(actor.velX), math.abs(actor.velY)))
		
		if numMoves > 0 then
			local actorMove = {actor = actor, floatingX = actor.x, floatingY = actor.y, movesLeft = numMoves}
			Misc.binaryInsert(actorMoves, actorMove, comparator)
		end
	end
	
	local function reorderActorMove(actor)
		for i = 1, #actorMoves do
			local actorMove = actorMoves[i]
			if actorMove.actor.id == actor.id then
				table.remove(actorMoves, i)
				actorMove.movesLeft = math.floor(math.max(math.abs(actor.velX), math.abs(actor.velY)))
				Misc.binaryInsert(actorMoves, actorMove, comparator)
				break
			end
		end
	end
	
	local function addMomentum(actor, momentX, momentY)
		actor.velX = actor.velX + momentX
		actor.velY = actor.velY + momentY
		actor.momentX = actor.momentX + momentX
		actor.momentY = actor.momentY + momentY
		
		reorderActorMove(actor)
	end
	
	while #actorMoves > 0 do
		local actorMove = actorMoves[1]
		table.remove(actorMoves, 1)
		
		local newX, newY = Misc.orthogPointFrom(actorMove.floatingX, actorMove.floatingY, 1, math.atan2(actorMove.actor.velY, actorMove.actor.velX))
		--print(newX .. " : " .. newY)
		local targetTile = Map.getTile(turnCalculator.world.map, Misc.round(newX), Misc.round(newY))
		if targetTile then
			--Collision
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
				
				--Actor collision
				local collidingActor = nil
				if actorMove.actor.solidity > 0 then
					for i = 1, #targetTile.actors do
						if targetTile.actors[i].solidity > 0 then
							collidingActor = targetTile.actors[i]
							break
						end
					end
				end
				
				if collidingActor and collidingActor.solidity >= Actor.getSpeed(actorMove.actor) and actorMove.actor.solidity >= Actor.getSpeed(collidingActor) then
					if targetTile.x ~= actorMove.actor.x then
						addMomentum(collidingActor, actorMove.actor.velX, 0)
						
						actorMove.actor.velX = 0
						actorMove.movesLeft = actorMove.actor.velY
					else
						addMomentum(collidingActor, 0, actorMove.actor.velY)
						
						actorMove.actor.velY = 0
						actorMove.movesLeft = actorMove.actor.velX
					end
				elseif collidingActor and actorMove.actor.solidity < Actor.getSpeed(collidingActor) then
					Actor.changeSpeed(collidingActor, -actorMove.actor.solidity)
					reorderActorMove(collidingActor)
					Actor.kill(actorMove.actor)
				else
					if collidingActor and collidingActor.solidity < Actor.getSpeed(actorMove.actor) then
						Actor.changeSpeed(actorMove.actor, -collidingActor.solidity)
						Actor.kill(collidingActor)
					end
					Tile.moveActor(targetTile, actorMove.actor)
					actorMove.floatingX = newX
					actorMove.floatingY = newY
				end
			end
		end
		
		actorMove.movesLeft = actorMove.movesLeft - 1
		if actorMove.movesLeft > 0 then
			Misc.binaryInsert(actorMoves, actorMove, comparator)
		end
	end
	
	for i = 1, #turnCalculator.world.actors do
		local actor = turnCalculator.world.actors[i]
		actor.velX = actor.velX - actor.momentX
		actor.velY = actor.velY - actor.momentX
		
		Actor.momentumDrag(actor, 1)
	end
	
	for i = #turnCalculator.world.activeTools, 1, -1 do
		local tool = turnCalculator.world.activeTools[i]
		Tool.tick(tool, turnCalculator.world, turnCalculator.player)
		if tool.complete then
			table.remove(turnCalculator.world.activeTools, i)
		end
	end
	
	for i = 1, #turnCalculator.world.enemies do
		local enemy = turnCalculator.world.enemies[i]
		if enemy.actor.dead == false then
			Enemy.postTick(enemy, turnCalculator.world, turnCalculator.player)
		end
	end
	
	Map.redrawCells(turnCalculator.world.map, turnCalculator.player.actor.x, turnCalculator.player.actor.y)
	Player.postTurnUpdate(turnCalculator.player, turnCalculator.world)
	Player.calculatePredictedSquares(turnCalculator.player)
end

return TurnCalculator