local Map = require "map"
local Misc = require "misc"
local EnemyProto = require "enemyProto"

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

return RandomGen