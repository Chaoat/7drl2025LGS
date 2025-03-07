local Actor = require "actor"
local World = require "world"
local Letter = require "letter"
local Misc = require "misc"
local Enemy = require "enemy"
local Tool = require "tool"
local Player = require "player"
local Map = require "map"
local Tile = require "tile"

local EnemyProto = {}

local protos = {}

function EnemyProto.spawn(protoName, world, x, y)
	local proto = protos[protoName]
	
	local chosenLetter = Misc.randomFromList(proto.letterOptions)
	local actor = Actor.new(Letter.copy(chosenLetter), proto.solidity, proto.health)
	if World.placeActor(world, actor, x, y) then
		local enemy = Enemy.new(actor, proto)
		if proto.creationFunction then
			proto.creationFunction(enemy, world)
		end
		table.insert(world.enemies, enemy)
	end
end

function EnemyProto.new(name, nameTag, descriptionTag, letterOptions, solidity, health, tickFunc, postTickFunc, deathFunc, startingState)
	--tickFunc(enemy, world, player)
	--postTickFunc(enemy, world, player)
	--deathFunc(enemy, world, player)
	local enemyProto = {name = name, nameTag = nameTag, descriptionTag = descriptionTag, letterOptions = letterOptions, solidity = solidity, health = health, tickFunc = tickFunc, postTickFunc = postTickFunc, deathFunc = deathFunc, startingState = startingState}
	protos[name] = enemyProto
	return enemyProto
end

local function addCreationFunction(func, enemyProto)
	--creationFunction(enemy, world)
	enemyProto.creationFunction = func
	return enemyProto
end

local function addStepFunction(func, enemyProto)
	--stepFunction(enemy, world, player, lastX, lastY)
	enemyProto.stepFunction = func
	return enemyProto
end

do
	--debris
	EnemyProto.new("debris", "debrisName", "debrisDescription", 
	{Letter.newFromLetter("O", {0.8, 1, 1, 1}, nil), 
	Letter.newFromLetter("O", {1, 0.8, 1, 1}, nil),
	Letter.newFromLetter("O", {1, 1, 0.8, 1}, nil)}
	, 6, 1, nil, nil, nil, {})
	
	--blowfish
	EnemyProto.new("blowFish", "debrisName", "debrisDescription", 
	{Letter.newFromLetter("X", {1, 0, 0, 1}, nil)}
	, 2, 1, 
	nil,
	function(enemy, world, player)
		--print(Misc.orthogDistance(enemy.actor.x, enemy.actor.y, player.actor.x, player.actor.y))
		--print(player.actor.x)
		--print(enemy.actor.x .. ":" .. enemy.actor.y .. ":" .. player.actor.x .. ":" .. player.actor.y .. ":" .. Misc.orthogDistance(enemy.actor.x, enemy.actor.y, player.actor.x, player.actor.y))
		if Misc.orthogDistance(enemy.actor.x, enemy.actor.y, player.actor.x, player.actor.y) <= 3 then
			Actor.kill(enemy.actor)
		end
	end, 
	function(enemy, world, player)
		Tool.activate("impulseExplosion", enemy.actor, world, player, enemy.actor.x, enemy.actor.y)
	end, {})
	
	--tower
	addCreationFunction(
	function(enemy, world)
		enemy.actor.stationary = true
	end,
	EnemyProto.new("tower", "towerName", "towerDescription", 
	{Letter.newFromLetter("T", {1, 0, 0, 1}, nil)}
	, 5, 1, 
	nil,
	function(enemy, world, player)
		enemy.aiState.reload = enemy.aiState.reload - 1
		if enemy.aiState.reload == 0 then
			Tool.activate("towerBlast", enemy.actor, world, player, enemy.targettingTile[1], enemy.targettingTile[2])
			enemy.aiState.reload = 2
			enemy.targettingTile = nil
		elseif Misc.orthogDistance(enemy.actor.x, enemy.actor.y, player.actor.x, player.actor.y) <= 20 and enemy.aiState.reload == 1 then
			local tX, tY = Actor.predictPosition(player.actor)
			enemy.targettingTile = {tX, tY}
		else
			enemy.aiState.reload = 2
			enemy.targettingTile = nil
		end
	end, nil, {reload = 2}))
	
	--rocket
	EnemyProto.new("rocket", "rocketName", "rocketDescription", 
	{Letter.newFromLetter("A", {1, 0, 0, 1}, nil)}
	, 10, 2, 
	function(enemy, world, player)
		if enemy.aiState.charging == 0 then
			local xChange, yChange = Misc.orthogPointFrom(0, 0, 2, enemy.aiState.angle)
			xChange = Misc.round(xChange)
			yChange = Misc.round(yChange)
			enemy.actor.velX = enemy.actor.velX + xChange
			enemy.actor.velY = enemy.actor.velY + yChange
		end
	end,
	function(enemy, world, player)
		if enemy.aiState.charging < 3 or (Misc.orthogDistance(enemy.actor.x, enemy.actor.y, player.actor.x, player.actor.y) <= 16 and Map.isLineClear(world.map, enemy.actor.x, enemy.actor.y, player.actor.x, player.actor.y)) then
			enemy.aiState.charging = math.max(enemy.aiState.charging - 1, 0)
			
			local tX, tY = Actor.predictPosition(player.actor)
			enemy.aiState.angle = math.atan2(tY - enemy.actor.y, tX - enemy.actor.x)
		end
	end, 
	function(enemy, world, player)
		Tool.activate("rocketExplosion", enemy.actor, world, player, enemy.actor.x, enemy.actor.y)
	end, 
	{charging = 3, angle = 0})

	--spider
	addCreationFunction(
	function(enemy, world)
		enemy.actor.bouncy = true
	end,
	addStepFunction(
	function(enemy, world, player, lastX, lastY)
		Map.setTile(world.map, lastX, lastY, Tile.new(1, {}, Letter.newFromLetter("#", {1, 1, 1, 1}, nil)))
	end,
	EnemyProto.new("spider", "spiderName", "spiderDescription", 
	{Letter.newFromLetter("M", {1, 0, 0, 1}, nil)}
	, 10, 4, 
	function(enemy, world, player)
		if Misc.orthogDistance(enemy.actor.x, enemy.actor.y, player.actor.x, player.actor.y) <= 20 then
			local tX, tY = Actor.predictPosition(player.actor, 5)
			local xChange, yChange = Misc.orthogPointFrom(0, 0, 5, math.atan2(tY - enemy.actor.y, tX - enemy.actor.x))
			xChange = Misc.round(xChange)
			yChange = Misc.round(yChange)
			enemy.actor.velX = enemy.actor.velX + xChange
			enemy.actor.velY = enemy.actor.velY + yChange
			
			Actor.restrictSpeed(enemy.actor, 8)
		end
	end,
	function(enemy, world, player)
	end, 
	nil, 
	{charging = 3})))
end

return EnemyProto