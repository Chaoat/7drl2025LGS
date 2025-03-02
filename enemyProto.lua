local Actor = require "actor"
local World = require "world"
local Letter = require "letter"
local Misc = require "misc"
local Enemy = require "enemy"

local EnemyProto = {}

local protos = {}

function EnemyProto.spawn(protoName, world, x, y)
	local proto = protos[protoName]
	
	local chosenLetter = Misc.randomFromList(proto.letterOptions)
	local actor = Actor.new(chosenLetter, proto.solidity)
	if World.placeActor(world, actor, x, y) then
		table.insert(world.enemies, Enemy.new(actor, proto))
	end
end

function EnemyProto.new(name, nameTag, descriptionTag, letterOptions, solidity, movementFunc)
	local enemyProto = {name = name, nameTag = nameTag, descriptionTag = descriptionTag, letterOptions = letterOptions, solidity = solidity, movementFunc = movementFunc}
	protos[name] = enemyProto
	return enemyProto
end

do
	EnemyProto.new("debris", "debrisName", "debrisDescription", 
	{Letter.newFromLetter("O", {0.8, 1, 1, 1}, nil), 
	Letter.newFromLetter("O", {1, 0.8, 1, 1}, nil),
	Letter.newFromLetter("O", {1, 1, 0.8, 1}, nil)}
	, 6, nil)
end

return EnemyProto