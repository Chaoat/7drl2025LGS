local Tool = {}

local protos = {}
local function newEffectToolProto(name, nameTag, descriptionTag, colour, duration, activateFunc, deactivateFunc, animationEffect, tags)
	--activateFunc(tool, world, player)
	--deactivateFunc(tool, world, player)
	--animationEffect(tool, world, player, dt)
	protos[name] = {name = name, nameTag = nameTag, descriptionTag = descriptionTag, duration = duration, 
					activateFunc = activateFunc, deactivateFunc = deactivateFunc, animationEffect = animationEffect, tags = {}}
	
	for i = 1, #tags do
		protos[name].tags[tags[i]] = true
	end
end

do
	--tags
	--deactivateWithDeath - fire deactivate function when activatingActor dies
	--targetted - bring up the targetting interface when this is activated by the player
	--end tags
	
	newEffectToolProto("nitro", "nitroName", "nitroDescription", {0.6, 0.6, 0.6, 1}, 10,
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
	{"deactivateWithDeath"})
end

function Tool.protoHasTag(protoName, tagName)
	return protos[protoName].tags[tagName] == true
end

function Tool.activate(protoName, activatingActor, world, player, targetX, targetY)
	local tool = {state = {}, activatingActor = activatingActor, targetX = targetX, targetY = targetY, lifeTime = 0, complete = false, proto = protos[protoName]}
	if tool.proto.activateFunc then
		tool.proto.activateFunc(tool, world, player)
	end
	table.insert(world.activeTools, tool)
	return tool
end

function Tool.tick(tool, world, player)
	tool.lifeTime = tool.lifeTime + 1
	if tool.lifeTime > tool.proto.duration and tool.complete == false then
		tool.complete = true
		if tool.proto.deactivateFunc then
			tool.proto.deactivateFunc(tool, world, player)
		end
	end
end

return Tool