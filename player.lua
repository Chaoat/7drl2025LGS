local Actor = require "actor"
local Letter = require "letter"
local Controls = require "controls"

local Player = {}

function Player.generatePlayerActor(actor)
	return Actor.new(Letter.newFromLetter("@", {1, 1, 1, 1}, nil))
end

function Player.new(actor)
	local player = {actor = actor}
	return player
end

function Player.keyInput(player, key)
	return true
end

return Player