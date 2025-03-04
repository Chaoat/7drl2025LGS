local Map = require "map"
local XpInterpreter = require "xpInterpreter"
local Tile = require "tile"
local Actor = require "actor"
local Bunker = require "bunker"
local Inventory = require "inventory"
local Crew = require "crew"
local Weather = require "weather"
local Enemy = require "enemy"
local Particle = require "particle"
local DebrisGen = require "debrisGen"

local World = {}

function World.new()
	local world = {map = Map.loadFromXP(XpInterpreter.load("7drlmap1")), weather = nil, actors = {}, enemies = {}, bunkers = {}, activeTools = {},
				   overActorParticles = {}}
	world.weather = Weather.new(world.map)
	
	World.addBunker(world, Bunker.new("GenesisName", "GenesisDescription", {1, 1, 0, 0.4}, {"food"}, {"steel"}, 
	Map.getTileCoordsInSquare(map, 23, 6, 27, 10), Inventory.addCrew(Inventory.addTool(Inventory.new(), "nitro", 2), Crew.new("architect", "GenesisName"))))
	World.addBunker(world, Bunker.new("SouthStreetName", "SouthStreetDescription", {1, 1, 0, 0.4}, {"steel"}, {"food"}, 
	Map.getTileCoordsInSquare(map, 23, 26, 27, 30), Inventory.addCrew(Inventory.addTool(Inventory.new(), "blink", 2), Crew.new("quarter master", "SouthStreetName"))))
	
	DebrisGen.fillArea(world, 4, 5, {5, 5}, {200, 200})
	
	return world
end

function World.tickAllEnemies(world, player)
	for i = 1, #world.enemies do
		local enemy = world.enemies[i]
		if enemy.actor.dead == false then
			Enemy.tick(enemy, world, player)
		end
	end
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

function World.addBunker(world, bunker)
	table.insert(world.bunkers, bunker)
end

function World.update(world, dt)
	for i = #world.actors, 1, -1 do
		local actor = world.actors[i]
		Actor.update(actor, 4*dt)
	end
	
	Particle.updateCollection(world.overActorParticles, "overActor", dt)
end

function World.draw(world, camera)
	Weather.draw(world.weather, camera)
	Map.draw(world.map, camera)
	
	for i = 1, #world.bunkers do
		Bunker.drawRegion(world.bunkers[i], camera)
	end
	
	for i = 1, #world.actors do
		Actor.draw(world.actors[i], camera)
	end
	
	Particle.drawCollection(world.overActorParticles, camera)
end

return World