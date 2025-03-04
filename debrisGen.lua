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
	newDebrisMap(1, "densedebris")
	newDebrisMap(2, "densedebris")
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

function DebrisGen.fillArea(world, density, edgeBleed, topCorn, botCorn)
	local x1 = topCorn[1]
	local y1 = topCorn[2]
	local x2 = botCorn[1]
	local y2 = botCorn[2]
	
	for x = x1, x2 do
		for y = y1, y2 do
			local edgeDist = math.min(math.min(math.abs(x - x1, x2 - x)), math.min(math.abs(y - y1, y2 - y)))
			local edgeMult = math.max(1 - edgeDist/edgeBleed, 0)
			
			local existingTile = Map.getTile(world.map, x, y)
			if existingTile and existingTile.solidity == 0 then
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