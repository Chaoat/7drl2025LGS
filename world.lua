local Map = require "map"
local XpInterpreter = require "xpInterpreter"
local Tile = require "tile"
local Actor = require "actor"

local World = {}

function World.new()
	local world = {map = Map.loadFromXP(XpInterpreter.load("7drl2020CityBlockTest")), actors = {}, enemies = {}}
	return world
end

function World.placeActor(world, actor, x, y)
	local tile = Map.getTile(world.map, x, y)
	if tile then
		Tile.moveActor(tile, actor)
		table.insert(world.actors, actor)
		return actor
	end
	return false
end

function World.update(world, dt)
	for i = #world.actors, 1, -1 do
		local actor = world.actors[i]
		Actor.update(actor, 4*dt)
	end
end

function World.draw(world, camera)
	Map.draw(world.map, camera)
	
	for i = 1, #world.actors do
		Actor.draw(world.actors[i], camera)
	end
end

return World