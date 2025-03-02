local Enemy = {}

function Enemy.new(actor, proto)
	local enemy = {actor = actor, proto = proto, aiState = aiState}
	return enemy
end

return Enemy