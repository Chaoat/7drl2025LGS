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
	local mapWidth = 600
	local mapHeight = 400
	
	local world = {map = Map.loadFromXP(XpInterpreter.load("7drlmap1", 600, 400)), weather = nil, actors = {}, enemies = {}, bunkers = {}, activeTools = {},
				   overActorParticles = {}}
	world.weather = Weather.new(world.map)
	
	World.addBunker(world, Bunker.new("GenesisName", "GenesisDescription", {1, 1, 0, 0.4}, {}, {}, 
	Map.getTileCoordsInSquare(map, 335, 282, 344, 287), Inventory.new(), nil, 200))

	--World.addBunker(world, Bunker.new("SouthStreetName", "SouthStreetDescription", {1, 1, 0, 0.4}, {"steel"}, {"food"}, 
	--Map.getTileCoordsInSquare(map, 23, 26, 27, 30), Inventory.addTool(Inventory.new(), "blink", 2), Crew.new("quarter master", "SouthStreetName"), 200))
	--
	--World.addBunker(world, Bunker.new("North West Cafe", "SouthStreetDescription", {1, 1, 0, 0.4}, {"steel"}, {"food"}, 
	--Map.getTileCoordsInSquare(map, 7, 70, 12, 77), Inventory.addTool(Inventory.new(), "blink", 2), Crew.new("Chef", "North West Cafe"), 200))
	--
	--World.addBunker(world, Bunker.new("Collapsed Trade Tower", "SouthStreetDescription", {1, 1, 0, 0.4}, {"steel"}, {"food"}, 
	--Map.getTileCoordsInSquare(map, 146, 18, 151, 27), Inventory.addTool(Inventory.new(), "blink", 2), Crew.new("quarter master", "Collapsed Trade Tower"), 200))
	--
	--World.addBunker(world, Bunker.new("Warehouse Depot", "SouthStreetDescription", {1, 1, 0, 0.4}, {"steel"}, {"food"}, 
	--Map.getTileCoordsInSquare(map, 349, 6, 357, 11), Inventory.addCrew(Inventory.addTool(Inventory.new(), "blink", 2), Crew.new("quarter master", "Warehouse Depot"), 200)))
	--
	--World.addBunker(world, Bunker.new("Destroyed Warehouse", "SouthStreetDescription", {1, 1, 0, 0.4}, {"steel"}, {"food"}, 
	--Map.getTileCoordsInSquare(map, 575, 178, 585, 183), Inventory.addTool(Inventory.new(), "blink", 2), Crew.new("quarter master", "Destroyed Warehouse"), 200))
	--
	--World.addBunker(world, Bunker.new("Mountain Cabin", "SouthStreetDescription", {1, 1, 0, 0.4}, {"steel"}, {"food"}, 
	--Map.getTileCoordsInSquare(map, 449, 270, 458, 275 ), Inventory.addTool(Inventory.new(), "blink", 2), Crew.new("quarter master", "Mountain Cabin"), 200))
	--
	--World.addBunker(world, Bunker.new("North Central Plaza", "SouthStreetDescription", {1, 1, 0, 0.4}, {"steel"}, {"food"}, 
	--Map.getTileCoordsInSquare(map, 222, 244, 230, 249), Inventory.addTool(Inventory.new(), "blink", 2), Crew.new("quarter master", "North Central Plaza"), 200))
	--
	--World.addBunker(world, Bunker.new("Central Offices", "SouthStreetDescription", {1, 1, 0, 0.4}, {"steel"}, {"food"}, 
	--Map.getTileCoordsInSquare(map, 160, 344, 168, 349), Inventory.addTool(Inventory.new(), "blink", 2), Crew.new("quarter master", "Central Offices"), 200))
	--
	--World.addBunker(world, Bunker.new("Mountain Hotel", "SouthStreetDescription", {1, 1, 0, 0.4}, {"steel"}, {"food"}, 
	--Map.getTileCoordsInSquare(map, 523, 329, 528, 339), Inventory.addTool(Inventory.new(), "blink", 2), Crew.new("quarter master", "Mountain Hotel"), 200))
	--
	--World.addBunker(world, Bunker.new("State Library", "SouthStreetDescription", {1, 1, 0, 0.4}, {"steel"}, {"food"}, 
	--Map.getTileCoordsInSquare(map, 358, 161, 366, 166),  Inventory.addTool(Inventory.new(), "blink", 2), Crew.new("quarter master", "State Library"), 200))
	--
	--World.addBunker(world, Bunker.new("Warehouse Gatehouse", "SouthStreetDescription", {1, 1, 0, 0.4}, {"steel"}, {"food"}, 
	--Map.getTileCoordsInSquare(map, 230, 119, 235, 128), Inventory.addTool(Inventory.new(), "blink", 2), Crew.new("quarter master", "Warehouse Gatehouse"), 200))
	--
	--World.addBunker(world, Bunker.new("Survivor Trade Hub", "SouthStreetDescription", {1, 1, 0, 0.4}, {"steel"}, {"food"}, 
	--Map.getTileCoordsInSquare(map, 437, 102, 445, 107), Inventory.addTool(Inventory.new(), "blink", 2), Crew.new("quarter master", "Survivor Trade Hub"), 200))
	--
	--World.addBunker(world, Bunker.new("Stadium", "SouthStreetDescription", {1, 1, 0, 0.4}, {"steel"}, {"food"}, 
	--Map.getTileCoordsInSquare(map, 75, 140, 80, 149), Inventory.addTool(Inventory.new(), "blink", 2), Crew.new("quarter master", "Stadium"), 200))
	--
	--World.addBunker(world, Bunker.new("North East Mall", "SouthStreetDescription", {1, 1, 0, 0.4}, {"steel"}, {"food"}, 
	--Map.getTileCoordsInSquare(map, 556, 37, 566, 42), Inventory.addTool(Inventory.new(), "blink", 2), Crew.new("quarter master", "North East Mall"), 200))
	--
	--World.addBunker(world, Bunker.new("Untouched Tower", "SouthStreetDescription", {1, 1, 0, 0.4}, {"steel"}, {"food"}, 
	--Map.getTileCoordsInSquare(map, 1, 382, 9, 387), Inventory.addTool(Inventory.new(), "blink", 2), Crew.new("quarter master", "Untouched Tower"), 200))
	--
	--World.addBunker(world, Bunker.new("Southern Hideout", "SouthStreetDescription", {1, 1, 0, 0.4}, {"steel"}, {"food"}, 
	--Map.getTileCoordsInSquare(map, 369, 391, 378, 398 ), Inventory.addCrew(Inventory.addTool(Inventory.new(), "blink", 2), Crew.new("quarter master", "Southern Hideout"), 200)))
	
	local innerBleed = 10
	DebrisGen.fillArea(world, 4, 20, {-50, -50}, {mapWidth + 50, innerBleed}) --top
	DebrisGen.fillArea(world, 4, 20, {mapWidth - innerBleed, -50}, {mapWidth + 50, mapHeight + 50}) --right
	DebrisGen.fillArea(world, 4, 20, {-50, mapHeight - innerBleed}, {mapWidth + 50, mapHeight + 50}) --bot
	DebrisGen.fillArea(world, 4, 20, {-50, -50}, {innerBleed, mapHeight + 50}) --left
	
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