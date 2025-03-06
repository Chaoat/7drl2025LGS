local Map = require "map"
local Misc = require "misc"
local EnemyProto = require "enemyProto"
local World = require "world"
local Bunker = require "bunker"
local Inventory = require "inventory"
local Crew = require "crew"

local RandomGen = {}

local enemyTable = {
	{"debris", 1},
	{"blowFish", 1}
}

function RandomGen.fillAreaWithEnemies(world, difficulty, x1, y1, x2, y2)
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
	
	local validEnemies = {}
	for i = 1, #enemyTable do
		local enemy = enemyTable[i]
		
		if enemy[2] <= difficulty then
			table.insert(validEnemies, enemy)
		end
	end
	
	local area = (x2 - x1)*(y2 - y1)
	enemyDensity = 70
	
	for i = 1, math.ceil(area/enemyDensity) do
		local choice, index = Misc.randomFromList(validTiles)
		table.remove(validTiles, index)
		
		local enemyChoice = Misc.randomFromList(validEnemies)
		EnemyProto.spawn(enemyChoice[1], world, choice.x, choice.y)
		
		if #validTiles <= 0 then
			return
		end
	end
end

--17 bunkers

--"Steel"
--"Medicine"
--"Electronics"
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
	local minTime = 300
	local increment = 50
	local timers = {}
	for i = 1, nBunkers do
		table.insert(timers, minTime + i*increment)
	end
	
	return timers
end

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
		
		World.addBunker(world, Bunker.new(location[5], "SouthStreetDescription", {1, 1, 0, 0.4}, chosenTrade[1], chosenTrade[2], 
		Map.getTileCoordsInSquare(map, location[1], location[2], location[3], location[4]), Inventory.addTool(Inventory.new(), "blink", 2), crew, chosenTimer))
	end
end

return RandomGen