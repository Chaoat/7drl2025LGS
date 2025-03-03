local Enemy = {}

function Enemy.new(actor, proto)
	local enemy = {actor = actor, proto = proto, aiState = aiState}
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

return Enemy