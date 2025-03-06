local Camera = require "camera"
local Inventory = require "inventory"
local Crew = require "crew"

local Bunker = {}

local function newGiveTrade(good)
	local trade = {give = true, displayText = "take " .. good, 
	canExecuteFunction = function(player, bunker)
		return bunker.hasGiven == false and Inventory.cargoCount(player.inventory) < player.inventory.cargoLimit
	end,
	executeFunction = function(player, bunker)
		Inventory.addCargo(player.inventory, good, 1, bunker)
		bunker.passenger.letter.tint = {0.2, 0.2, 0.2, 1}
		Inventory.addCrew(player.inventory, bunker.passenger)
		bunker.hasGiven = true
		bunker.affectWorldDifficultyThisTurn = true
		
		Crew.tick(bunker.passenger, player)
	end}
	return trade
end

local function newReceiveTrade(good)
	local trade = {receive = true, displayText = "give " .. good, 
	canExecuteFunction = function(player, bunker)
		return bunker.hasReceived == false and Inventory.hasCargo(player.inventory, good) > 0
	end,
	executeFunction = function(player, bunker)
		bunker.receivedFrom = Inventory.removeCargo(player.inventory, good, 1)
		Inventory.transferTo(player.inventory, bunker.rewardInventory)
		bunker.hasReceived = true
	end}
	return trade
end

function Bunker.new(nameTag, descriptionTag, colour, goodsNeeded, goodsToGive, tileCoords, rewardInventory, passenger, doomsdayClock)
	doomsdayClock = doomsdayClock or 0
	
	local centerX = 0
	local centerY = 0
	for i = 1, #tileCoords do
		centerX = centerX + tileCoords[i][1]
		centerY = centerY + tileCoords[i][2]
	end
	centerX = centerX/#tileCoords
	centerY = centerY/#tileCoords
	
	local validTrades = {}
	for i = 1, #goodsToGive do
		table.insert(validTrades, newGiveTrade(goodsToGive[i]))
	end
	for i = 1, #goodsNeeded do
		table.insert(validTrades, newReceiveTrade(goodsNeeded[i]))
	end
	
	local bunker = {nameTag = nameTag, descriptionTag = descriptionTag, colour = colour, goodsNeeded = goodsNeeded, goodsToGive = goodsToGive, validTrades = validTrades, rewardInventory = rewardInventory, passenger = passenger, 
					timeTillDeath = doomsdayClock, dead = false, tileCoords = tileCoords, centerX = centerX, centerY = centerY, hasGiven = false, hasReceived = false, receivedFrom = nil, affectWorldDifficultyThisTurn = false}
	
	if passenger then
		bunker.passenger.originLink = bunker
	end
	
	return bunker
end

function Bunker.tick(bunker)
	if bunker.dead == false and bunker.hasReceived == false then
		bunker.timeTillDeath = bunker.timeTillDeath - 1
		if bunker.timeTillDeath <= 0 then
			bunker.dead = true
			bunker.affectWorldDifficultyThisTurn = true
		end
	end
end

function Bunker.getBunkerOnTile(bunkerList, tile)
	for i = 1, #bunkerList do
		local bunker = bunkerList[i]
		
		for j = 1, #bunker.tileCoords do
			local coords = bunker.tileCoords[j]
			if coords[1] == tile.x and coords[2] == tile.y then
				return bunker
			end
		end
	end
	return nil
end

function Bunker.drawRegion(bunker, camera)
	for i = 1, #bunker.tileCoords do
		local tileCoord = bunker.tileCoords[i]
		Camera.drawTo(bunker.colour, tileCoord[1], tileCoord[2], camera, 
		function(colour, drawX, drawY, tileWidth, tileHeight)
			love.graphics.setColor(colour)
			love.graphics.rectangle("fill", drawX - tileWidth/2, drawY - tileHeight/2, tileWidth, tileHeight)
		end)
	end
end

return Bunker