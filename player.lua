local Actor = require "actor"
local Letter = require "letter"
local Controls = require "controls"
local Misc = require "misc"
local Camera = require "camera"
local Image = require "image"
local Inventory = require "inventory"
local Tool = require "tool"
local Bunker = require "bunker"
local Crew = require "crew"
local Particle = require "particle"

local Player = {}

function Player.generatePlayerActor(actor)
	return Actor.new(Letter.newFromLetter("@", {1, 1, 1, 1}, nil), 99, 10)
end

function Player.new(actor)
	local player = {actor = actor, controlMode = "movement", lookCursorX = 0, lookCursorY = 0, targettingTool = nil, readingTextID = "", gameOver = false,
	heading = 0, speed = 0, targetSpeed = 0, minSpeed = 0, maxSpeed = 10, turnRate = 2, acceleration = 1, deceleration = 1, 
	predictedSquares = {}, activeTools = {}, inventory = Inventory.new(), fuel = 100, maxFuel = 100, parkedBunker = nil, indestructible = false}
	
	Inventory.addTool(player.inventory, "indestructibility", 2)
	Inventory.addTool(player.inventory, "blink", 1)
	Inventory.addTool(player.inventory, "cannon", 3)
	
	--Inventory.addCargo(player.inventory, "food", 1)
	--Inventory.addCargo(player.inventory, "fresh water", 1)
	
	return player
end

local function getNewHeadingForTargetHeading(player, targetHeading)
	local headingDifference = Misc.differenceBetweenAngles(player.heading, targetHeading)
	
	--local turnMod = 0.5
	--if math.abs(headingDifference) > 3*math.pi/4 then
	--	turnMod = 2
	--elseif math.abs(headingDifference) > math.pi/2 then
	--	turnMod = 1.5
	--elseif math.abs(headingDifference) > math.pi/4 then
	--	turnMod = 1
	--end
	local turnMod = 1
	if math.abs(headingDifference) > math.pi/4 then
		turnMod = 2
	end
	
	local angularTurning = turnMod*player.turnRate*math.pi/(3*Actor.getSpeed(player.actor))
	if math.abs(headingDifference) <= angularTurning then
		return targetHeading
	else
		local turnDirection = headingDifference/math.abs(headingDifference)
		return player.heading + turnDirection*angularTurning
	end
end
local function executePlayerAcceleration(player, targetHeading)
	player.speed = Misc.moveTowardsNumber(player.speed, player.targetSpeed, -player.deceleration, player.acceleration)
	player.heading = getNewHeadingForTargetHeading(player, targetHeading)
	local velX, velY = Misc.orthogPointFrom(0, 0, player.speed, player.heading)
	player.actor.velX = Misc.round(velX)
	player.actor.velY = Misc.round(velY)
end

local function useNamedTool(player, world, toolName)
	if Inventory.containsTool(player.inventory, toolName, 1) then
		if not Tool.protoHasTag(toolName, "targetted") then
			if Tool.canActivateProto(toolName, world, player, nil, nil) then
				local tool = Tool.activate(toolName, player.actor, world, player, player.actor.x, player.actor.y)
				Inventory.removeTool(player.inventory, toolName, 1)
				table.insert(player.activeTools, tool)
				Player.calculatePredictedSquares(player)
				return false
			end
		else
			player.controlMode = "targetting"
			player.lookCursorX = player.actor.x
			player.lookCursorY = player.actor.y
			player.targettingTool = toolName
		end
	end
	return false
end
local function executeNthTrade(player, tradeN)
	if player.parkedBunker then
		local trade = player.parkedBunker.validTrades[tradeN]
		if trade and trade.canExecuteFunction(player, player.parkedBunker) then
			trade.executeFunction(player, player.parkedBunker)
		end
	end
end

function Player.keyInput(player, world, key)
	local executeTurn = false
	local playerSpeed = Actor.getSpeed(player.actor)
	local targetHeading = player.heading
	if player.controlMode == "movement" then
		if Controls.checkControl(key, "botLeft", false) then
			executeTurn = true
			targetHeading = 3*math.pi/4
		elseif Controls.checkControl(key, "bot", false) then
			executeTurn = true
			targetHeading = math.pi/2
		elseif Controls.checkControl(key, "botRight", false) then
			executeTurn = true
			targetHeading = math.pi/4
		elseif Controls.checkControl(key, "left", false) then
			executeTurn = true
			targetHeading = math.pi
		elseif Controls.checkControl(key, "skip", false) then
			executeTurn = true
		elseif Controls.checkControl(key, "right", false) then
			executeTurn = true
			targetHeading = 0
		elseif Controls.checkControl(key, "topLeft", false) then
			executeTurn = true
			targetHeading = -3*math.pi/4
		elseif Controls.checkControl(key, "top", false) then
			executeTurn = true
			targetHeading = -math.pi/2
		elseif Controls.checkControl(key, "topRight", false) then
			executeTurn = true
			targetHeading = -math.pi/4
		elseif Controls.checkControl(key, "accelerate", false) then
			player.targetSpeed = math.min(player.targetSpeed + 1, Player.getMaxSpeed(player))
			Player.calculatePredictedSquares(player)
		elseif Controls.checkControl(key, "decelerate", false) then
			player.targetSpeed = math.max(player.targetSpeed - 1, math.max(player.minSpeed, 0))
			Player.calculatePredictedSquares(player)
		elseif Controls.checkControl(key, "startLooking", false) then
			player.controlMode = "freeLook"
			player.lookCursorX = player.actor.x
			player.lookCursorY = player.actor.y
		elseif Controls.checkControl(key, "activateDrift", false) then
			executeTurn = useNamedTool(player, world, "drift")
		elseif Controls.checkControl(key, "activateCannon", false) then
			executeTurn = useNamedTool(player, world, "cannon")
		elseif Controls.checkControl(key, "activateIndestructibility", false) then
			executeTurn = useNamedTool(player, world, "indestructibility")
		elseif Controls.checkControl(key, "activateNitro", false) then
			executeTurn = useNamedTool(player, world, "nitro")
		elseif Controls.checkControl(key, "activateBlink", false) then
			executeTurn = useNamedTool(player, world, "blink")
		elseif Controls.checkControl(key, "activateDrill", false) then
			executeTurn = useNamedTool(player, world, "drill")
		elseif Controls.checkControl(key, "tradeOption1", false) then
			executeNthTrade(player, 1)
		elseif Controls.checkControl(key, "tradeOption2", false) then
			executeNthTrade(player, 2)
		elseif Controls.checkControl(key, "tradeOption3", false) then
			executeNthTrade(player, 3)
		elseif Controls.checkControl(key, "tradeOption4", false) then
			executeNthTrade(player, 4)
		elseif Controls.checkControl(key, "tradeOption5", false) then
			executeNthTrade(player, 5)
		elseif Controls.checkControl(key, "tradeOption6", false) then
			executeNthTrade(player, 6)
		end
	elseif player.controlMode == "freeLook" then
		if Controls.checkControl(key, "botLeft", false) then
			player.lookCursorX = player.lookCursorX - 1
			player.lookCursorY = player.lookCursorY + 1
		elseif Controls.checkControl(key, "bot", false) then
			player.lookCursorY = player.lookCursorY + 1
		elseif Controls.checkControl(key, "botRight", false) then
			player.lookCursorX = player.lookCursorX + 1
			player.lookCursorY = player.lookCursorY + 1
		elseif Controls.checkControl(key, "left", false) then
			player.lookCursorX = player.lookCursorX - 1
		elseif Controls.checkControl(key, "right", false) then
			player.lookCursorX = player.lookCursorX + 1
		elseif Controls.checkControl(key, "topLeft", false) then
			player.lookCursorX = player.lookCursorX - 1
			player.lookCursorY = player.lookCursorY - 1
		elseif Controls.checkControl(key, "top", false) then
			player.lookCursorY = player.lookCursorY - 1
		elseif Controls.checkControl(key, "topRight", false) then
			player.lookCursorX = player.lookCursorX + 1
			player.lookCursorY = player.lookCursorY - 1
		elseif Controls.checkControl(key, "back", false) then
			player.controlMode = "movement"
		end
	elseif player.controlMode == "targetting" then
		local newCursorX = player.lookCursorX
		local newCursorY = player.lookCursorY
		if Controls.checkControl(key, "botLeft", false) then
			newCursorX = newCursorX - 1
			newCursorY = newCursorY + 1
		elseif Controls.checkControl(key, "bot", false) then
			newCursorY = newCursorY + 1
		elseif Controls.checkControl(key, "botRight", false) then
			newCursorX = newCursorX + 1
			newCursorY = newCursorY + 1
		elseif Controls.checkControl(key, "left", false) then
			newCursorX = newCursorX - 1
		elseif Controls.checkControl(key, "right", false) then
			newCursorX = newCursorX + 1
		elseif Controls.checkControl(key, "topLeft", false) then
			newCursorX = newCursorX - 1
			newCursorY = newCursorY - 1
		elseif Controls.checkControl(key, "top", false) then
			newCursorY = newCursorY - 1
		elseif Controls.checkControl(key, "topRight", false) then
			newCursorX = newCursorX + 1
			newCursorY = newCursorY - 1
		elseif Controls.checkControl(key, "activateTargettedTool", false) and player.controlMode == "targetting" then
			if Tool.canActivateProto(player.targettingTool, world, player, player.lookCursorX, player.lookCursorY) then
				local tool = Tool.activate(player.targettingTool, player.actor, world, player, player.lookCursorX, player.lookCursorY)
				table.insert(player.activeTools, tool)
				Inventory.removeTool(player.inventory, player.targettingTool, 1)
				player.controlMode = "movement"
				Player.calculatePredictedSquares(player)
			end
		elseif Controls.checkControl(key, "back", false) then
			player.controlMode = "movement"
		end
		
		if Misc.orthogDistance(player.actor.x, player.actor.y, newCursorX, newCursorY) <= Tool.getProtoRange(player.targettingTool) then
			player.lookCursorX = newCursorX
			player.lookCursorY = newCursorY
		end
	elseif player.controlMode == "reading" then
		if player.gameOver == false and Controls.checkControl(key, "back", false) then
			player.controlMode = "movement"
			player.readingTextID = ""
		end
	end
	
	if executeTurn then
		executePlayerAcceleration(player, targetHeading)
		return true
	end
	return false
end

function Player.clickInput(player, tilex, tiley, button)
	if player.controlMode == "movement" then
		if button == 1 then
			for i = 1, #player.predictedSquares do
				local predSquare = player.predictedSquares[i]
				if predSquare.clickable and predSquare.x == tilex and predSquare.y == tiley then
					executePlayerAcceleration(player, predSquare.targetHeading)
					return true
				end
			end
		elseif button == 2 then
			player.controlMode = "freeLook"
			player.lookCursorX = tilex
			player.lookCursorY = tiley
		end
	elseif player.controlMode == "freeLook" then
		player.lookCursorX = tilex
		player.lookCursorY = tiley
	elseif player.controlMode == "targetting" then
		if Misc.orthogDistance(player.actor.x, player.actor.y, tilex, tiley) <= Tool.getProtoRange(player.targettingTool) then
			player.lookCursorX = tilex
			player.lookCursorY = tiley
		end
	end
	return false
end

function Player.update(player, dt)
	if player.parkedBunker then
		player.parkedBunker.parkRealTime = player.parkedBunker.parkRealTime + dt
	end

	if player.actor.indestructible then
		Particle.queue(Particle.colourShiftBox(player.actor.x, player.actor.y, {1, 1, 1, 1}, {0.6, 0.4, 0, 0}, 0.2), "overActor")
    end
end

function Player.postTurnUpdate(player, world)
	player.heading = math.atan2(player.actor.velY, player.actor.velX)
	player.speed = math.max(player.minSpeed, math.min(Misc.round(Misc.orthogDistance(0, 0, player.actor.velX, player.actor.velY)), Player.getMaxSpeed(player)))
	
	player.parkedBunker = Bunker.getBunkerOnTile(world.bunkers, player.actor.tile)
	if player.parkedBunker then
		if not player.parkedBunker.dead then
			player.fuel = player.maxFuel
			Actor.Heal(player.actor, 3)
		end
	else
		player.fuel = math.max(player.fuel - 1, 0)
	end
	
	for i = 1, #player.inventory.crew do
		Crew.tick(player.inventory.crew[i], player)
	end
	
	if player.actor.dead and player.gameOver == false then
		player.readingTextID = "deathText"
		player.controlMode = "reading"
		player.gameOver = true
	end
end

function Player.calculatePredictedSquares(player)
	player.predictedSquares = {}
	local function addPredictedSquare(arrowImage, arrowAngle, arrowTint, x, y, priority, targetHeading, clickable)
		x = x + player.actor.momentX
		y = y + player.actor.momentY
		local predictedSquare = {arrowImage = arrowImage, arrowAngle = arrowAngle, arrowTint = arrowTint, x = x, y = y, priority = priority, targetHeading = targetHeading, clickable = clickable}
		
		local discard = false
		for i = 1, #player.predictedSquares do
			local predSquare = player.predictedSquares[i]
			if predSquare.x == x and predSquare.y == y then
				if predSquare.priority < priority then
					discard = true
				else
					table.remove(player.predictedSquares, i)
				end
				break
			end
		end
		
		if discard == false then
			table.insert(player.predictedSquares, predictedSquare)
		end
	end
	
	local speed = Misc.moveTowardsNumber(player.speed, player.targetSpeed, -player.deceleration, player.acceleration)
	--print(player.targetSpeed .. " : " .. speed)
	for x = -1, 1 do
		for y = -1, 1 do
			local arrowImage = Image.getImage("dot")
			local arrowAngle = 0
			if math.abs(x) + math.abs(y) == 2 then
				arrowImage = Image.getImage("diagArrow")
				arrowAngle = -math.pi/4
			elseif math.abs(x) + math.abs(y) == 1 then
				arrowImage = Image.getImage("arrow")
			end
			
			local targetHeading = math.atan2(y, x)
			arrowAngle = arrowAngle + targetHeading
			
			local movementHeading = player.heading
			local priority = math.abs(Misc.differenceBetweenAngles(player.heading, targetHeading))
			if x ~= 0 or y ~= 0 then
				movementHeading = getNewHeadingForTargetHeading(player, targetHeading)
			else
				priority = 2*math.pi
			end
			
			local arrowX, arrowY = Misc.orthogPointFrom(player.actor.x, player.actor.y, speed, movementHeading)
			arrowX = Misc.round(arrowX)
			arrowY = Misc.round(arrowY)
			
			addPredictedSquare(arrowImage, arrowAngle, {1, 1, 1, 1}, arrowX, arrowY, priority, targetHeading, true)
		end
	end
	
	local speedX, speedY = Misc.orthogPointFrom(player.actor.x, player.actor.y, player.targetSpeed, player.heading)
	speedX = Misc.round(speedX)
	speedY = Misc.round(speedY)
	addPredictedSquare(Image.getImage("dot"), 0, {1, 1, 0, 1}, speedX, speedY, 3*math.pi, player.heading, false)
end

function Player.getMaxSpeed(player)
	if player.fuel > 0 then
		return player.maxSpeed
	else
		return 3
	end
end

function Player.drawMovementPrediction(player, camera)
	if player.actor.momentX ~= 0 or player.actor.momentY ~= 0 then
		local coords = Misc.orthogLineBetween(player.actor.x, player.actor.y, player.actor.x + player.actor.momentX, player.actor.y + player.actor.momentY)
		for i = 1, #coords do
			Camera.drawTo(player, coords[i][1], coords[i][2], camera, 
			function(player, drawX, drawY, tileWidth, tileHeight)
				local bright = math.sin(7*GLOBALAnimationClock - i)
				love.graphics.setColor(1, 1, bright, 0.6)
				love.graphics.rectangle("fill", drawX - tileWidth/2, drawY - tileHeight/2, tileWidth, tileHeight)
			end)
		end
		
		Camera.drawTo({}, player.actor.x + player.actor.momentX, player.actor.y + player.actor.momentY, camera, 
		function(square, drawX, drawY, tileWidth, tileHeight)
			Letter.draw(Letter.newFromLetter("@", {1, 1, 0, 1}), drawX, drawY, tileWidth, tileHeight)
		end)
	end
	
	for i = 1, #player.predictedSquares do
		local predictedSquare = player.predictedSquares[i]
		Camera.drawTo({image = predictedSquare.arrowImage, angle = predictedSquare.arrowAngle, tint = predictedSquare.arrowTint, clickable = predictedSquare.clickable}, predictedSquare.x, predictedSquare.y, camera, 
		function(arrow, drawX, drawY, tileWidth, tileHeight)
			local bright = math.abs(math.sin(7*GLOBALAnimationClock - i))
			if arrow.clickable then
				love.graphics.setColor(bright, 1, bright, 0.6)
				love.graphics.rectangle("fill", drawX - tileWidth/2, drawY - tileHeight/2, tileWidth, tileHeight)
			end
			love.graphics.setColor(arrow.tint)
			Image.drawImageScreenSpace(arrow.image, drawX, drawY, arrow.angle, 0.5, 0.5, tileWidth/arrow.image.width, tileHeight/arrow.image.height)
		end)
	end
end

function Player.drawCursor(player, camera)
	if player.controlMode == "freeLook" or player.controlMode == "targetting" then
		Camera.drawTo({}, player.lookCursorX, player.lookCursorY, camera, 
		function(cursor, drawX, drawY, tileWidth, tileHeight)
			love.graphics.setColor(1, 0, 0, 1)
			love.graphics.rectangle("line", drawX - tileWidth/2, drawY - tileHeight/2, tileWidth, tileHeight)
		end)
		
		if player.controlMode == "targetting" then
			Camera.drawTo({radius = Tool.getProtoRange(player.targettingTool)}, player.actor.x, player.actor.y, camera, 
			function(cursor, drawX, drawY, tileWidth, tileHeight)
				love.graphics.setColor(1, 0, 0, 1)
				love.graphics.rectangle("line", drawX - (cursor.radius + 0.5)*tileWidth, drawY - (cursor.radius + 0.5)*tileHeight, (2*cursor.radius + 1)*tileWidth, (2*cursor.radius + 1)*tileHeight)
			end)
		end
	end
end

return Player