local Actor = require "actor"
local Tile = require "tile"
local Map = require "map"
local Misc = require "misc"
local Particle = require "particle"

local Tool = {}

local protos = {}
local function newEffectToolProto(name, nameTag, descriptionTag, colour, duration, range, activateFunc, deactivateFunc, animationEffect, canActivateFunc, tags)
	--activateFunc(tool, world, player)
	--deactivateFunc(tool, world, player)
	--animationEffect(tool, world, player, dt)
	--canActivateFunc(world, player, targetX, targetY) if checking for press activation, targetX and targetY will be nil
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
	
	--PLAYER TOOLS
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
		if targetX == nil or targetY == nil then
			return true
		end
		local tile = Map.getTile(world.map, targetX, targetY)
		return tile ~= nil and tile.solidity == 0 and #tile.actors == 0
	end,
	{"targetted"})

	newEffectToolProto("cannon", "cannonName", "cannonDescription", {0.6, 0.6, 0.6, 1}, 0, 15,
	function(tool, world, player)
		local tile = Map.getTile(world.map, tool.targetX, tool.targetY)
		local radius = 3
		for xOff = -radius, radius do
			for yOff = -radius, radius do
				local x = tool.targetX + xOff
				local y = tool.targetY + yOff
				local tile = Map.getTile(world.map, x, y)
				
				if tile then
					Tile.wreck(tile)
					for i = 1, #tile.actors do
						Actor.kill(tile.actors[i]))
					end
					
					Particle.queue(Particle.colourShiftBox(x, y, {1, 1, 1, 1}, {0.6, 0.4, 0, 0}, 0.4), "overActor")
				end
			end
		end
	end, 
	nil,
	nil,
	function(world, player, targetX, targetY)
		if targetX == nil or targetY == nil then
			return true
		end
		local tile = Map.getTile(world.map, targetX, targetY)
		return tile ~= nil
	end,
	{"targetted"})

	newEffectToolProto("drill", "drillName", "drillDescription", {0.6, 0.6, 0.6, 1}, 0, 30,
	function(tool, world, player)
		local tile = Map.getTile(world.map, tool.targetX, tool.targetY)
		local tiles = Map.shape.line(world.Map, tool.targetX, tool.targetY, player.actor.x, player.actor.y)
		for i= 1, #tiles do 
			Tile.wreck(tiles[i])
		end
	end, 
	nil,
	nil,
	function(world, player, targetX, targetY)
		if targetX == nil or targetY == nil then
			return true
		end
		local tile = Map.getTile(world.map, targetX, targetY)
		return tile ~= nil
	end,
	{"targetted"})

	--TODO make indestructible work with damage system
	newEffectToolProto("indestructibility", "indestructibilityName", "indestructibilityDescription", {0.6, 0.6, 0.6, 1}, 10, 0,
	function(tool, world, player)
		player.indestructible = true
	end, 
	function(tool, world, player)
		player.indestructible = false
	end,
	nil,
	function(world, player, targetX, targetY)
		return Actor.toolEffectActive(player.actor, "indestructible") == false
	end,
	{"deactivateWithDeath"})

	newEffectToolProto("Drift", "driftName", "driftDescription", {0.6, 0.6, 0.6, 1}, 10, 0,
	function(tool, world, player)
		player.minSpeed = player.turnSpeed + 3
	end, 
	function(tool, world, player)
		player.minSpeed = player.turnSpeed - 3
	end,
	nil,
	function(world, player, targetX, targetY)
		return Actor.toolEffectActive(player.actor, "drift") == false
	end,
	{"deactivateWithDeath"})
	
	--ENEMY TOOLS
	newEffectToolProto("impulseExplosion", "impulseExplosionName", "impulseExplosionDescription", {1, 1, 1, 1}, 0, 5,
	function(tool, world, player)
		local radius = 6
		for xOff = -radius, radius do
			for yOff = -radius, radius do
				local x = tool.targetX + xOff
				local y = tool.targetY + yOff
				local tile = Map.getTile(world.map, x, y)
				
				if tile and Map.isLineClear(world.map, tool.targetX, tool.targetY, x, y) then
					local angle = math.atan2(yOff, xOff)
					local xMoment, yMoment = Misc.orthogPointFrom(0, 0, 5, angle)
					for i = 1, #tile.actors do
						Actor.impulseActor(tile.actors[i], xMoment, yMoment)
					end
					
					Particle.queue(Particle.colourShiftBox(x, y, {1, 1, 1, 1}, {0.6, 0.4, 0, 0}, 0.4), "overActor")
				end
			end
		end
	end, 
	nil,
	nil,
	nil,
	{})
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