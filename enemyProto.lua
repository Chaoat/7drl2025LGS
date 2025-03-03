local Actor = require "actor"
local World = require "world"
local Letter = require "letter"
local Misc = require "misc"
local Enemy = require "enemy"
local Tool = require "tool"

local EnemyProto = {}

local protos = {}

function EnemyProto.spawn(protoName, world, x, y)
	local proto = protos[protoName]
	
	local chosenLetter = Misc.randomFromList(proto.letterOptions)
	local actor = Actor.new(Letter.copy(chosenLetter), proto.solidity, proto.health)
	if World.placeActor(world, actor, x, y) then
		table.insert(world.enemies, Enemy.new(actor, proto))
	end
end

function EnemyProto.new(name, nameTag, descriptionTag, letterOptions, solidity, health, tickFunc, postTickFunc, deathFunc)
	--tickFunc(enemy, world, player)
	local enemyProto = {name = name, nameTag = nameTag, descriptionTag = descriptionTag, letterOptions = letterOptions, solidity = solidity, health = health, tickFunc = tickFunc, postTickFunc = postTickFunc, deathFunc = deathFunc}
	protos[name] = enemyProto
	return enemyProto
end

do
	EnemyProto.new("debris", "debrisName", "debrisDescription", 
	{Letter.newFromLetter("O", {0.8, 1, 1, 1}, nil), 
	Letter.newFromLetter("O", {1, 0.8, 1, 1}, nil),
	Letter.newFromLetter("O", {1, 1, 0.8, 1}, nil)}
	, 6, 1, nil, nil, nil)
	
	EnemyProto.new("blowFish", "debrisName", "debrisDescription", 
	{Letter.newFromLetter("x", {1, 0, 0, 1}, nil), 
	Letter.newFromLetter("x", {1, 0.2, 0, 1}, nil),
	Letter.newFromLetter("x", {0.8, 0.4, 0, 1}, nil)}
	, 2, 1, 
	nil,
	function(enemy, world, player)
		if Misc.orthogDistance(enemy.actor.x, enemy.actor.y, player.actor.x, player.actor.y) <= 3 then
			Tool.activate("impulseExplosion", enemy.actor, world, player, enemy.actor.x, enemy.actor.y)
			Actor.kill(enemy.actor)
		end
	end, nil)
end

return EnemyProto