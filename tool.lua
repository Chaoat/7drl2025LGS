local Actor = require "actor"
local Tile = require "tile"
local Map = require "map"

local Tool = {}

local protos = {}
local function newEffectToolProto(name, nameTag, descriptionTag, colour, duration, range, activateFunc, deactivateFunc, animationEffect, canActivateFunc, tags)
	--activateFunc(tool, world, player)
	--deactivateFunc(tool, world, player)
	--animationEffect(tool, world, player, dt)
	--canActivateFunc(world, player, targetX, targetY)
	protos[name] = {name = name, nameTag = nameTag, descriptionTag = descriptionTag, duration = duration, range = range, 
					activateFunc = activateFunc, deactivateFunc = deactivateFunc, animationEffect = animationEffect, canActivateFunc = canActivateFunc,
					tags = {}}
	
	for i = 1, #tags do
		protos[name].tags[tags[i]] = true
	end
end

do
	--tags
	--
	--deactivateWithDeath - fire deactivate function when activatingActor dies
	--targetted - bring up the targetting interface when this is activated by the player
	--
	--tags
	
	newEffectToolProto("nitro", "nitroName", "nitroDescription", {0.6, 0.6, 0.6, 1}, 10, 0,
	function(tool, world, player)
		player.minSpeed = player.minSpeed + 10
		player.maxSpeed = player.maxSpeed + 10
		player.targetSpeed = player.targetSpeed + 10
		player.speed = player.speed + 10
	end, 
	function(tool, world, player)
		player.minSpeed = player.minSpeed - 10
		player.maxSpeed = player.maxSpeed - 10
		player.targetSpeed = player.targetSpeed - 10
	end,
	nil,
	function(world, player, targetX, targetY)
		return Actor.toolEffectActive(player.actor, "nitro") == false
	end,
	{"deactivateWithDeath"})
	
	newEffectToolProto("blink", "blinkName", "blinkDescription", {0.6, 0.6, 0.6, 1}, 0, 5,
	function(tool, world, player)
		local tile = Map.getTile(world.map, tool.targetX, tool.targetY)
		Tile.moveActor(tile, player.actor, true)
	end, 
	nil,
	nil,
	function(world, player, targetX, targetY)
		local tile = Map.getTile(world.map, targetX, targetY)
		return tile ~= nil and tile.solidity == 0 and #tile.actors == 0
	end,
	{"targetted"})
end

function Tool.protoHasTag(protoName, tagName)
	return protos[protoName].tags[tagName] == true
end

function Tool.canActivateProto(protoName, world, player, targetX, targetY)
	local proto = protos[protoName]
	if proto.canActivateFunc and proto.canActivateFunc(world, player, targetX, targetY) == false then
		return false
	end
	return true
end

function Tool.getProtoRange(protoName)
	return protos[protoName].range
end

function Tool.activate(protoName, activatingActor, world, player, targetX, targetY)
	local tool = {state = {}, activatingActor = activatingActor, targetX = targetX, targetY = targetY, lifeTime = 0, complete = false, proto = protos[protoName]}
	table.insert(activatingActor.activatedTools, tool)
	if tool.proto.activateFunc then
		tool.proto.activateFunc(tool, world, player)
	end
	table.insert(world.activeTools, tool)
	return tool
end

function Tool.tick(tool, world, player)
	tool.lifeTime = tool.lifeTime + 1
	
	if tool.proto.tags.deactivateWithDeath and tool.activatingActor and tool.activatingActor.dead then
		tool.lifeTime = tool.proto.duration + 1
	end
	
	if tool.lifeTime > tool.proto.duration and tool.complete == false then
		tool.complete = true
		if tool.proto.deactivateFunc then
			tool.proto.deactivateFunc(tool, world, player)
		end
	end
end

return Tool