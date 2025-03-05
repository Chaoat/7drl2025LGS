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
	Map.getTileCoordsInSquare(map, 335, 282, 344, 2 87), Inventory.addCrew(Inventory.addTool(Inventory.new(), "nitro", 2), Crew.new("architect", "GenesisName"))))

	World.addBunker(world, Bunker.new("SouthStreetName", "SouthStreetDescription", {1, 1, 0, 0.4}, {"steel"}, {"food"}, 
	Map.getTileCoordsInSquare(map, 23, 26, 27, 30), Inventory.addCrew(Inventory.addTool(Inventory.new(), "blink", 2), Crew.new("quarter master", "SouthStreetName"))))

	World.addBunker(world, Bunker.new("North West Cafe", "SouthStreetDescription", {1, 1, 0, 0.4}, {"steel"}, {"food"}, 
	Map.getTileCoordsInSquare(map, 7, 70, 12, 77), Inventory.addCrew(Inventory.addTool(Inventory.new(), "blink", 2), Crew.new("Chef", "North West Cafe"))))

	World.addBunker(world, Bunker.new("Collapsed Trade Tower", "SouthStreetDescription", {1, 1, 0, 0.4}, {"steel"}, {"food"}, 
	Map.getTileCoordsInSquare(map, 146, 18, 151, 27), Inventory.addCrew(Inventory.addTool(Inventory.new(), "blink", 2), Crew.new("quarter master", "Collapsed Trade Tower"))))

	World.addBunker(world, Bunker.new("Warehouse Depot", "SouthStreetDescription", {1, 1, 0, 0.4}, {"steel"}, {"food"}, 
	Map.getTileCoordsInSquare(map, 349, 6, 357, 11), Inventory.addCrew(Inventory.addTool(Inventory.new(), "blink", 2), Crew.new("quarter master", "Warehouse Depot"))))

	World.addBunker(world, Bunker.new("Destroyed Warehouse", "SouthStreetDescription", {1, 1, 0, 0.4}, {"steel"}, {"food"}, 
	Map.getTileCoordsInSquare(map, 575, 178, 585, 183), Inventory.addCrew(Inventory.addTool(Inventory.new(), "blink", 2), Crew.new("quarter master", "Destroyed Warehouse"))))

	World.addBunker(world, Bunker.new("Mountain Cabin", "SouthStreetDescription", {1, 1, 0, 0.4}, {"steel"}, {"food"}, 
	Map.getTileCoordsInSquare(map, 449, 270, 458, 275 ), Inventory.addCrew(Inventory.addTool(Inventory.new(), "blink", 2), Crew.new("quarter master", "Mountain Cabin"))))

	World.addBunker(world, Bunker.new("North Central Plaza", "SouthStreetDescription", {1, 1, 0, 0.4}, {"steel"}, {"food"}, 
	Map.getTileCoordsInSquare(map, 222, 244, 230, 249), Inventory.addCrew(Inventory.addTool(Inventory.new(), "blink", 2), Crew.new("quarter master", "North Central Plaza"))))
	 
	World.addBunker(world, Bunker.new("Central Offices", "SouthStreetDescription", {1, 1, 0, 0.4}, {"steel"}, {"food"}, 
	Map.getTileCoordsInSquare(map, 160, 344, 168, 349), Inventory.addCrew(Inventory.addTool(Inventory.new(), "blink", 2), Crew.new("quarter master", "Central Offices"))))

	World.addBunker(world, Bunker.new("Mountain Hotel", "SouthStreetDescription", {1, 1, 0, 0.4}, {"steel"}, {"food"}, 
	Map.getTileCoordsInSquare(map, 523, 329, 528, 339), Inventory.addCrew(Inventory.addTool(Inventory.new(), "blink", 2), Crew.new("quarter master", "Mountain Hotel"))))

	World.addBunker(world, Bunker.new("State Library", "SouthStreetDescription", {1, 1, 0, 0.4}, {"steel"}, {"food"}, 
	Map.getTileCoordsInSquare(map, 358, 161, 366, 166),  Inventory.addCrew(Inventory.addTool(Inventory.new(), "blink", 2), Crew.new("quarter master", "State Library"))))

	World.addBunker(world, Bunker.new("Warehouse Gatehouse", "SouthStreetDescription", {1, 1, 0, 0.4}, {"steel"}, {"food"}, 
	Map.getTileCoordsInSquare(map, 230, 119, 235, 128), Inventory.addCrew(Inventory.addTool(Inventory.new(), "blink", 2), Crew.new("quarter master", "Warehouse Gatehouse"))))

	World.addBunker(world, Bunker.new("Survivor Trade Hub", "SouthStreetDescription", {1, 1, 0, 0.4}, {"steel"}, {"food"}, 
	Map.getTileCoordsInSquare(map, 437, 102, 445, 107), Inventory.addCrew(Inventory.addTool(Inventory.new(), "blink", 2), Crew.new("quarter master", "Survivor Trade Hub"))))

	World.addBunker(world, Bunker.new("Stadium", "SouthStreetDescription", {1, 1, 0, 0.4}, {"steel"}, {"food"}, 
	Map.getTileCoordsInSquare(map, 75, 140, 80, 149), Inventory.addCrew(Inventory.addTool(Inventory.new(), "blink", 2), Crew.new("quarter master", "Stadium"))))

	World.addBunker(world, Bunker.new("North East Mall", "SouthStreetDescription", {1, 1, 0, 0.4}, {"steel"}, {"food"}, 
	Map.getTileCoordsInSquare(map, 556, 37, 566, 42), Inventory.addCrew(Inventory.addTool(Inventory.new(), "blink", 2), Crew.new("quarter master", "North East Mall"))))

	World.addBunker(world, Bunker.new("Untouched Tower", "SouthStreetDescription", {1, 1, 0, 0.4}, {"steel"}, {"food"}, 
	Map.getTileCoordsInSquare(map, 1, 382, 9, 387), Inventory.addCrew(Inventory.addTool(Inventory.new(), "blink", 2), Crew.new("quarter master", "Untouched Tower"))))

	World.addBunker(world, Bunker.new("Southern Hideout", "SouthStreetDescription", {1, 1, 0, 0.4}, {"steel"}, {"food"}, 
	Map.getTileCoordsInSquare(map, 369, 391, 378, 398 ), Inventory.addCrew(Inventory.addTool(Inventory.new(), "blink", 2), Crew.new("quarter master", "Southern Hideout"))))
	
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