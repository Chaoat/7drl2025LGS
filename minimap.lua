local Map = require "map"

local Minimap = {}

function Minimap.new(world)
	local margin = 15
	local scale = 1
	
	local mapWidth, mapHeight = Map.getSize(world.map)
	local canvas = love.graphics.newCanvas(scale*mapWidth + 2*margin, scale*mapHeight + 2*margin)
	
	local minimap = {world = world, canvas = canvas, scale = scale, margin = margin}
	Minimap.redraw(minimap)
	
	return minimap
end

function Minimap.worldToMap(minimap, worldX, worldY)
	return minimap.scale*worldX + minimap.margin, minimap.scale*worldY + minimap.margin
end

function Minimap.redraw(minimap)
	love.graphics.setCanvas(minimap.canvas)
	love.graphics.clear()
	
	local map = minimap.world.map
	for x = map.bounds[1], map.bounds[3] do
		for y = map.bounds[2], map.bounds[4] do
			local tile = Map.getTile(map, x, y)
			if tile.solidity > 0 then
				love.graphics.setColor(0.6, 0.6, 0.6, 1)
				
				local x1, y1 = Minimap.worldToMap(minimap, tile.x - 0.5, tile.y - 0.5)
				local x2, y2 = Minimap.worldToMap(minimap, tile.x + 0.5, tile.y + 0.5)
				love.graphics.rectangle("fill", x1, y1, x2 - x1, y2 - y1)
			end
		end
	end
	
	for i = 1, #minimap.world.bunkers do
		local bunker = minimap.world.bunkers[i]
		local mapX, mapY = Minimap.worldToMap(minimap, bunker.centerX, bunker.centerY)
		
		if bunker.timeTillDeath > 100 then
			love.graphics.setColor(0, 1, 0, 1)
		elseif bunker.timeTillDeath > 0 then
			love.graphics.setColor(1, 1, 0, 1)
		else
			love.graphics.setColor(1, 0, 0, 1)
		end
		love.graphics.circle("fill", mapX, mapY, 4)
	end
	
	love.graphics.setCanvas()
end

return Minimap