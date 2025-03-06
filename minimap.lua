local Map = require "map"
local Inventory = require "inventory"
local Letter = require "letter"
local Crew = require "crew"
local Font = require "font"

local Minimap = {}

function Minimap.new(world)
	local margin = 15
	local scale = 1
	
	local mapWidth, mapHeight = Map.getSize(world.map)
	local canvas = love.graphics.newCanvas(scale*mapWidth + 2*margin, scale*mapHeight + 2*margin)
	local drawCanvas = love.graphics.newCanvas(scale*mapWidth + 2*margin, scale*mapHeight + 2*margin)
	
	local minimap = {world = world, canvas = canvas, drawCanvas = drawCanvas, scale = scale, margin = margin}
	Minimap.redraw(minimap)
	
	return minimap
end

function Minimap.worldToMap(minimap, worldX, worldY)
	return minimap.scale*(worldX - minimap.world.map.bounds[1]) + minimap.margin, minimap.scale*(worldY - minimap.world.map.bounds[2]) + minimap.margin
end

function Minimap.redraw(minimap)
	love.graphics.setCanvas(minimap.canvas)
	love.graphics.clear()
	
	local map = minimap.world.map
	for x = map.bounds[1] + 20, map.bounds[3] - 20 do
		for y = map.bounds[2] + 20, map.bounds[4] - 20 do
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
		
		local minimumYellowTime = 500
		if bunker.isEndBunker then
			love.graphics.setColor(1, 0.7, 1, 1)
		elseif bunker.timeTillDeath > minimumYellowTime then
			love.graphics.setColor(0, 0.7, 0, 1)
		elseif bunker.timeTillDeath > 0 then
			local green = 0.2 + 0.5*(bunker.timeTillDeath/minimumYellowTime)
			love.graphics.setColor(0.4, green, 0, 1)
		else
			love.graphics.setColor(0.7, 0, 0, 1)
		end
		love.graphics.circle("fill", mapX, mapY, 12)
		
		if bunker.isEndBunker then
			Font.setFont("clacon", 24)
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.printf("HOME BASE", mapX - 100, mapY - 35, 200, "center")
		end
		
		for j = 1, #bunker.goodsNeeded do
			local goodName = bunker.goodsNeeded[j]
			
			local x = mapX - 22
			local y = mapY + (j - 0.5 - #bunker.goodsNeeded/2)*25
			Inventory.drawCargoSymbol(goodName, x, y, 20, 20)
		end
		
		for j = 1, #bunker.goodsToGive do
			local goodName = bunker.goodsToGive[j]
			
			local x = mapX + 22
			local y = mapY + (j - 0.5 - #bunker.goodsToGive/2)*25
			Inventory.drawCargoSymbol(goodName, x, y, 20, 20)
		end
		
		if bunker.passenger ~= nil then
			Crew.drawSymbol(bunker.passenger, mapX, mapY, 20, 20)
		end
	end
	
	love.graphics.setLineWidth(2)
	love.graphics.setLineStyle("rough")
	for i = 1, #minimap.world.bunkers do
		local bunker = minimap.world.bunkers[i]
		local mapX, mapY = Minimap.worldToMap(minimap, bunker.centerX, bunker.centerY)
		if bunker.receivedFrom then
			local receivedFrom = bunker.receivedFrom
			local receivedX, receivedY = Minimap.worldToMap(minimap, receivedFrom.centerX, receivedFrom.centerY)
			
			local angle = math.atan2(mapY - receivedY, mapX - receivedX)
			local dist = math.sqrt((receivedY - mapY)^2 + (receivedX - mapX)^2)
			
			local endX = mapX - 20*math.cos(angle)
			local endY = mapY - 20*math.sin(angle)
			
			local arrowHeadLength = 15
			local arrowHeadAngle = 3*math.pi/4
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.line(receivedX + 20*math.cos(angle), receivedY + 20*math.sin(angle), endX, endY)
			love.graphics.line(endX, endY, endX + arrowHeadLength*math.cos(angle + arrowHeadAngle), endY + arrowHeadLength*math.sin(angle + arrowHeadAngle))
			love.graphics.line(endX, endY, endX + arrowHeadLength*math.cos(angle - arrowHeadAngle), endY + arrowHeadLength*math.sin(angle - arrowHeadAngle))
		end
	end
	
	love.graphics.setCanvas()
end

return Minimap