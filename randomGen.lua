local Map = require "map"
local Misc = require "misc"
local EnemyProto = require "enemyProto"
local World = require "world"
local Bunker = require "bunker"
local Inventory = require "inventory"
local Crew = require "crew"

local RandomGen = {}

local mobTemplates = {}
do
	local function newMobTemplate(difficulty, mobs)
		if mobTemplates[difficulty] == nil then
			mobTemplates[difficulty] = {}
		end
		table.insert(mobTemplates[difficulty], mobs)
	end
	
	newMobTemplate(0, {
	{"debris", 1}})
	
	newMobTemplate(1, {
	{"debris", 3}})

	newMobTemplate(2, {
	{"debris", 5}})
	
	newMobTemplate(2, {
	{"blowFish", 1}})

	newMobTemplate(2, {
	{"rocket", 1}})
	
	newMobTemplate(3, {
	{"blowFish", 3}})
	
	newMobTemplate(3, {
	{"tower", 1}})

	newMobTemplate(3, {
	{"rocket", 2}})

	newMobTemplate(4, {
	{"blowFish", 2},
	{"rocket", 2}})

	newMobTemplate(4, {
	{"tower", 1},
	{"rocket", 2}})

	newMobTemplate(4, {
	{"tower", 1},
	{"debris", 6}})
	
	newMobTemplate(4, {
	{"spider", 1}})

	newMobTemplate(5, {
	{"spider", 2},
	{"rocket", 1}})

	newMobTemplate(5, {
	{"tower", 2}})

	newMobTemplate(5, {
	{"tower", 1},
	{"blowFish", 3}})
	
	newMobTemplate(6, {
	{"rocket", 5}})

	newMobTemplate(6, {
	{"tower", 2},
	{"spider", 1}})

	newMobTemplate(7, {
	{"rocket", 8}})
	
	newMobTemplate(7, {
	{"blowFish", 9}})
	
	newMobTemplate(8, {
	{"spider", 2}})
	
	newMobTemplate(8, {
	{"tower", 4},
	{"debris", 10}})
	
	newMobTemplate(9, {
	{"spider", 2},
	{"rocket", 3}})
	
	newMobTemplate(10, {
	{"spider", 5},
	{"rocket", 5}})
end

function RandomGen.generateEnemiesForArea(world, difficulty, x1, y1, x2, y2)
	local validTiles = {}
	for x = x1, x2 do
		for y = y1, y2 do
			local tile = Map.getTile(world.map, x, y)
			
			if tile and tile.solidity == 0 then
				table.insert(validTiles, tile)
			end
		end
	end
	
	if #validTiles == 0 then
		return
	end
	
	local validMobs = {}
	local difficultyMin = math.floor(difficulty/2)
	for i = difficultyMin, difficulty do
		if mobTemplates[i] then
			for j = 1, #mobTemplates[i] do
				table.insert(validMobs, mobTemplates[i][j])
			end
		end
	end
	
	if #validMobs == 0 then
		return
	end
	
	local area = (x2 - x1)*(y2 - y1)
	local nMobs = math.ceil(area/2500)
	
	local spawnArea = 5
	for i = 1, nMobs do
		local chosenTile, index = Misc.randomFromList(validTiles)
		table.remove(validTiles, index)
		
		local mx1 = chosenTile.x - spawnArea
		local my1 = chosenTile.y - spawnArea
		local mx2 = chosenTile.x + spawnArea
		local my2 = chosenTile.y + spawnArea
		
		local mobChoice = Misc.randomFromList(validMobs)
		RandomGen.fillAreaWithEnemies(world, mobChoice, mx1, my1, mx2, my2)
		
		if #validTiles <= 0 then
			return
		end
	end
end

function RandomGen.fillAreaWithEnemies(world, mob, x1, y1, x2, y2)
	local validTiles = {}
	for x = x1, x2 do
		for y = y1, y2 do
			local tile = Map.getTile(world.map, x, y)
			
			if tile and tile.solidity == 0 then
				table.insert(validTiles, tile)
			end
		end
	end
	
	for i = 1, #mob do
		for j = 1, mob[i][2] do
			local choice, index = Misc.randomFromList(validTiles)
			table.remove(validTiles, index)
			EnemyProto.spawn(mob[i][1], world, choice.x, choice.y)
			
			if #validTiles <= 0 then
				return
			end
		end
	end
end

--17 bunkers

--"Medicine"
--"Gasoline"
--"Purifiers"
--"Roots"
--"Volatiles"

local function generatePossibleGives()
	return {
		{"Medicine", "Roots"},
		{"Medicine", "Volatiles"},
		{"Medicine"},
		{"Medicine"},
		{"Gasoline", "Roots"},
		{"Gasoline", "Volatiles"},
		{"Gasoline"},
		{"Gasoline"},
		{"Volatiles", "Purifiers"},
		{"Volatiles", "Roots"},
		{"Volatiles"},
		{"Volatiles"},
		{"Purifiers", "Roots"},
		{"Purifiers"},
		{"Purifiers"},
		{"Purifiers"},
		{"Roots"},
	}
end

local function generatePossibleReceives()
	return {
		{"Medicine", "Roots"},
		{"Medicine", "Volatiles"},
		{"Medicine"},
		{"Medicine"},
		{"Gasoline", "Roots"},
		{"Gasoline", "Volatiles"},
		{"Gasoline"},
		{"Gasoline"},
		{"Volatiles", "Purifiers"},
		{"Volatiles", "Roots"},
		{"Volatiles"},
		{"Volatiles"},
		{"Purifiers", "Roots"},
		{"Purifiers"},
		{"Purifiers"},
		{"Purifiers"},
		{"Roots"},
	}
end

--"Trucker"
--"Engineer"
--"Mathematician"
--"Carpenter"
--"Stocker"
--"Brewer"
--"Novelist"

local function generatePossibleCrew()
	return {
		"Engineer",
		"Engineer",
		"Engineer",
		"Trucker",
		"Trucker",
		"Trucker",
		"Mathematician",
		"Mathematician",
		"Carpenter",
		"Carpenter",
		"Stocker",
		"Stocker",
		"Brewer",
		"Brewer",
		"Brewer",
		"Novelist",
		"Novelist",
	}
end

local function generatePossibleTimers(nBunkers)
	local minTime = 100
	local increment = 60
	local timers = {}
	for i = 1, nBunkers do
		table.insert(timers, minTime + i*increment)
	end
	
	return timers
end

local toolChoices = {
	{"nitro", 2},
	{"blink", 1},
	{"cannon", 2},
	{"drill", 2},
	{"indestructibility", 2},
	{"drift", 2},
}

function RandomGen.placeBunkers(world, locations)
	local tradeCombos = {}
	local valid = false
	while valid == false do
		valid = true
		local gives = generatePossibleGives()
		local receives = generatePossibleReceives()
		
		while #gives > 0 do
			local give = gives[1]
			
			local chosenReceive, i = Misc.randomFromList(receives)
			local startingI = i
			local validChoice = false
			while validChoice == false do
				validChoice = true
				local receive = receives[i]
				
				for j = 1, #give do
					for k = 1, #receive do
						if give[j] == receive[k] then
							validChoice = false
						end
					end
				end
				
				if validChoice then
					table.remove(gives, 1)
					table.remove(receives, i)
					table.insert(tradeCombos, {give, receive})
				else
					i = 1 + i%#receives
					if i == startingI then
						valid = false
						break
					end
				end
			end
			
			if valid == false then
				break
			end
		end
	end
	
	local crewChoices = generatePossibleCrew()
	local timerChoices = generatePossibleTimers(#locations)
	
	for i = 1, #locations do
		local location = locations[i]
		local chosenTrade, tradeI = Misc.randomFromList(tradeCombos)
		table.remove(tradeCombos, tradeI)
		local chosenCrew, crewI = Misc.randomFromList(crewChoices)
		table.remove(crewChoices, crewI)
		local chosenTimer, timerI = Misc.randomFromList(timerChoices)
		table.remove(timerChoices, timerI)
		
		local crew = nil
		if chosenCrew ~= "None" then
			crew = Crew.new(chosenCrew, location[5])
		end
		
		local chosenTool = Misc.randomFromList(toolChoices)
		
		World.addBunker(world, Bunker.new(location[5], location[5] .. "description", {1, 1, 0, 0.4}, chosenTrade[1], chosenTrade[2], 
		Map.getTileCoordsInSquare(map, location[1], location[2], location[3], location[4]), Inventory.addTool(Inventory.new(), chosenTool[1], chosenTool[2]), crew, chosenTimer))
	end
end

return RandomGen