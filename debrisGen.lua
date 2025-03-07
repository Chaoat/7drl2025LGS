local XpInterpreter = require "xpInterpreter"
local Map = require "map"
local Tile = require "tile"
local Letter = require "letter"
local Misc = require "misc"

local DebrisGen = {}

local debrisMaps = {}
local function newDebrisMap(density, mapName)
	if debrisMaps[density] == nil then
		debrisMaps[density] = {}
	end
	table.insert(debrisMaps[density], XpInterpreter.load(mapName))
end
do
	newDebrisMap(1, "debris_light")
	newDebrisMap(2, "debris_mid")
	newDebrisMap(3, "densedebris")
end

local densityMapCoords = {800, 800}
local densityMapImage = nil
do
	local perlin = love.filesystem.read("shaders/perlin2d.glsl")
	
	local densityMapShader = love.graphics.newShader(perlin .. [[
		vec4 effect(vec4 colour, Image imageMap, vec2 texture_coords, vec2 pixel_coords)
		{
			vec2 period = vec2(800, 800);
			
			float noise = (1 + perlin2d_periodic(pixel_coords/5, period))/2;
			
			return vec4(noise, noise, noise, 1);
		}
	]])
	
	local densityMap = love.graphics.newCanvas(densityMapCoords[1], densityMapCoords[2])
	love.graphics.setShader(densityMapShader)
	love.graphics.setCanvas(densityMap)
	love.graphics.rectangle("fill", 0, 0, densityMapCoords[1], densityMapCoords[2])
	love.graphics.setCanvas()
	love.graphics.setShader()
	
	densityMapImage = densityMap:newImageData()
end

function DebrisGen.generateDebris(world, player, mapWidth, mapHeight)
	local cellsAcross = math.floor(mapWidth/world.map.cellWidth)
	local cellsDown = math.floor(mapHeight/world.map.cellHeight)
	
	local tileChoices = {}
	for x = 0, cellsAcross do
		for y = 0, cellsDown do
			local x1 = x*world.map.cellWidth
			local y1 = y*world.map.cellHeight
			local x2 = (x + 1)*world.map.cellWidth
			local y2 = (y + 1)*world.map.cellHeight
			
			if player.actor.x < x1 or player.actor.y < y1 or player.actor.x > x2 or player.actor.y > y2 then
				local bunkerBlocked = false
				
				for i = 1, #world.bunkers do
					local bunker = world.bunkers[i]
					if bunker.centerX >= x1 and bunker.centerY >= y1 and bunker.centerX <= x2 and bunker.centerY <= y2 then
						bunkerBlocked = true
						break
					end
				end
				
				if not bunkerBlocked then
					table.insert(tileChoices, {x1, y1, x2, y2})
				end
			end
		end
	end
	
	local area = (mapWidth*mapHeight)/(world.map.cellWidth*world.map.cellHeight)
	local densities = {math.floor(area/3), math.floor(area/12), math.floor(area/18)}
	
	local bleed = 10
	for d = 1, #densities do
		for n = 1, densities[d] do
			local tileChoice, tileI = Misc.randomFromList(tileChoices)
			table.remove(tileChoices, tileI)
			DebrisGen.fillArea(world, d, bleed, {tileChoice[1] - bleed, tileChoice[2] - bleed}, {tileChoice[3] + bleed, tileChoice[4] + bleed})
		end
	end
end

function DebrisGen.fillArea(world, density, edgeBleed, topCorn, botCorn)
	local x1 = topCorn[1]
	local y1 = topCorn[2]
	local x2 = botCorn[1]
	local y2 = botCorn[2]
	
	for x = x1, x2 do
		for y = y1, y2 do
			local edgeDist = math.min(math.min(math.abs(x - x1), math.abs(x2 - x)), math.min(math.abs(y - y1), math.abs(y2 - y)))
			local edgeMult = math.max(1 - edgeDist/edgeBleed, 0)
			
			local existingTile = Map.getTile(world.map, x, y)
			if existingTile == nil or existingTile.solidity == 0 then
				local pixX = x%densityMapCoords[1]
				local pixY = y%densityMapCoords[2]
				
				local r, g, b, a = densityMapImage:getPixel(pixX, pixY)
				
				local posDensity = math.min(math.ceil((density - 3*r) - edgeMult*density), #debrisMaps)
				
				if posDensity > 0 then
					local debrisMap = Misc.randomFromList(debrisMaps[posDensity])
					local mapX = x%debrisMap.properties.width
					local mapY = y%debrisMap.properties.height
					
					local debrisTile = Tile.fromXP(debrisMap.images[1][mapX][mapY])
					--local debrisTile = Tile.new(1, {}, Letter.newFromLetter(posDensity, {1, 0, 0, 1}))
					Map.setTile(world.map, x, y, debrisTile)
				end
			end
		end
	end
end

return DebrisGen