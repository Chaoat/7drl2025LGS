local Actor = require "actor"
local Letter = require "letter"
local Controls = require "controls"
local Misc = require "misc"
local Camera = require "camera"
local Image = require "image"
local Inventory = require "inventory"
local Tool = require "tool"

local Player = {}

function Player.generatePlayerActor(actor)
	return Actor.new(Letter.newFromLetter("@", {1, 1, 1, 1}, nil), 99)
end

function Player.new(actor)
	local player = {actor = actor, heading = 0, speed = 0, targetSpeed = 0, minSpeed = 0, maxSpeed = 10, turnRate = 2, acceleration = 3, deceleration = 3, predictedSquares = {}, activeTools = {}, inventory = Inventory.new()}
	
	Inventory.addTool(player.inventory, "nitro", 2)
	
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
			local tool = Tool.activate(toolName, player.actor, world, player, player.actor.x, player.actor.y)
			table.insert(player.activeTools, tool)
			return true
		end
	end
end

function Player.keyInput(player, world, key)
	local targetHeading = 0
	local executeTurn = false
	local playerSpeed = Actor.getSpeed(player.actor)
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
		targetHeading = player.heading
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
		player.targetSpeed = math.min(player.targetSpeed + 1, player.maxSpeed)
		Player.calculatePredictedSquares(player)
	elseif Controls.checkControl(key, "decelerate", false) then
		player.targetSpeed = math.max(player.targetSpeed - 1, math.max(player.minSpeed, 0))
		Player.calculatePredictedSquares(player)
	elseif Controls.checkControl(key, "activateNitro", false) then
		executeTurn = useNamedTool(player, world, "nitro")
	end
	
	if executeTurn then
		executePlayerAcceleration(player, targetHeading)
		return true
	end
	return false
end

function Player.clickInput(player, tilex, tiley, button)
	for i = 1, #player.predictedSquares do
		local predSquare = player.predictedSquares[i]
		if predSquare.clickable and predSquare.x == tilex and predSquare.y == tiley then
			executePlayerAcceleration(player, predSquare.targetHeading)
			return true
		end
	end
	return false
end

function Player.forceUpdateHeading(player)
	player.heading = math.atan2(player.actor.velY, player.actor.velX)
	player.speed = math.max(player.minSpeed, math.min(Misc.round(Misc.orthogDistance(0, 0, player.actor.velX, player.actor.velY)), player.maxSpeed))
end

function Player.calculatePredictedSquares(player)
	player.predictedSquares = {}
	local function addPredictedSquare(arrowImage, arrowAngle, arrowTint, x, y, priority, targetHeading, clickable)
		local predictedSquare = {arrowImage = arrowImage, arrowAngle = arrowAngle, arrowTint = arrowTint, x = x, y = y, priority = priority, targetHeading = targetHeading, clickable = true}
		
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
			
			addPredictedSquare(arrowImage, arrowAngle, {1, 1, 1, 1}, arrowX, arrowY, priority, targetHeading, clickable)
		end
	end
	
	local speedX, speedY = Misc.orthogPointFrom(player.actor.x, player.actor.y, player.targetSpeed, player.heading)
	speedX = Misc.round(speedX)
	speedY = Misc.round(speedY)
	addPredictedSquare(Image.getImage("dot"), 0, {1, 1, 0, 1}, speedX, speedY, 3*math.pi, player.heading, false)
end

function Player.drawMovementPrediction(player, camera)
	for i = 1, #player.predictedSquares do
		local predictedSquare = player.predictedSquares[i]
		Camera.drawTo({image = predictedSquare.arrowImage, angle = predictedSquare.arrowAngle, tint = predictedSquare.arrowTint}, predictedSquare.x, predictedSquare.y, camera, 
		function(arrow, drawX, drawY, tileWidth, tileHeight)
			love.graphics.setColor(arrow.tint)
			Image.drawImageScreenSpace(arrow.image, drawX, drawY, arrow.angle, 0.5, 0.5, tileWidth/arrow.image.width, tileHeight/arrow.image.height)
		end)
	end
end

return Player