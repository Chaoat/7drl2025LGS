local Letter = require "letter"
local Camera = require "camera"
local Misc = require "misc"
local Particle = require "particle"

local Actor = {}

local deathFunctionQueue = {}

function Actor.getDeathFunctionQueue()
	print(#deathFunctionQueue)
	return deathFunctionQueue
end

local latestID = 0
function Actor.new(letter, solidity, health)
	local actor = {x = nil, y = nil, drawX = nil, drawY = nil, tile = nil, activatedTools = {}, velX = 0, velY = 0, momentX = 0, momentY = 0, stationary = false,
				   solidity = solidity, health = health, maxHealth = health, letter = letter, id = latestID, dead = false, destroy = false, parent = nil, indestructible = false, movementParticleFunc = nil, movementParticleFuncPeriod = 0, movementFuncTimer = 0}
	
	Actor.setMovementParticleFunc(actor, 
	function(actor, x, y)
		if not actor.dead then
			local angle1 = math.atan2(actor.y - actor.drawY, actor.x - actor.drawX) + math.pi/2
			local angle2 = math.atan2(actor.y - actor.drawY, actor.x - actor.drawX) - math.pi/2
			
			local v1X, v1Y = Misc.orthogPointFrom(0, 0, Actor.getSpeed(actor) + Actor.getMomentum(actor), angle1)
			local v2X, v2Y = Misc.orthogPointFrom(0, 0, Actor.getSpeed(actor) + Actor.getMomentum(actor), angle2)
			for i = 1, 4 do
				local mult = i/4
				Particle.queue(Particle.setVelocity(Particle.colourShiftBox(x, y, {mult, mult, mult, 0.4}, {0, 0, 0.5, 0}, 1), mult*v1X, mult*v1Y), "water")
				Particle.queue(Particle.setVelocity(Particle.colourShiftBox(x, y, {mult, mult, mult, 0.4}, {0, 0, 0.5, 0}, 1), mult*v2X, mult*v2Y), "water")
			end
		end
	end, 0.1)
   
	latestID = latestID + 1
	return actor
end

function Actor.setMovementParticleFunc(actor, func, period)
	--func(actor, x, y)
	actor.movementParticleFunc = func
	actor.movementParticleFuncPeriod = period
end

function Actor.changeMaxHealth(actor, change)
	Actor.damage(actor, -change)
	actor.maxHealth = actor.maxHealth + change
end

function Actor.damage(actor, damage)
	if actor.indestructible then
		return
	end
	
	if actor.parent == nil then
		for d = 1, damage do
			local n = 64
			print(actor.x .. ":" .. actor.drawX)
			print(actor.y .. ":" .. actor.drawY)
			for i = 1, n do
				local xVel = d*4*math.cos(2*math.pi*i/n)
				local yVel = d*4*math.sin(2*math.pi*i/n)
				Particle.queue(Particle.setVelocity(Particle.colourShiftBox(actor.x, actor.y, {1, 0, 0, 0.6}, {1, 0, 0, 0}, 2), xVel, yVel), "water")
			end
		end
	end
	
	if actor.dead == false then
		actor.health = math.max(actor.health - damage, 0)
		if actor.health <= 0 then
			Actor.kill(actor)
		end
	end
end

function Actor.fullHeal(actor)
	actor.health = actor.maxHealth
end

function Actor.Heal(actor, heal)
	actor.health = math.min(actor.health + heal, actor.maxHealth)
end

function Actor.toolEffectActive(actor, toolName)
	for i = #actor.activatedTools, 1, -1 do
		local tool = actor.activatedTools[i]
		
		if tool.complete then
			table.remove(actor.activatedTools, i)
		elseif tool.proto.name == toolName then
			return true
		end
	end
	return false
end

function Actor.kill(actor)
	if actor.dead == false then
		actor.dead = true
		actor.letter.tint = {0.1, 0.1, 0.1, 1}
		actor.solidity = 0
		
		if actor.parent and actor.parent.proto and actor.parent.proto.deathFunc then
			table.insert(deathFunctionQueue, actor.parent)
		end
	end
end

function Actor.destroy(actor)
	actor.dead = true
	actor.destroy = true
end

function Actor.update(actor, dt)
	if actor.drawX ~= actor.x or actor.drawY ~= actor.y then
		local angle = math.atan2(actor.y - actor.drawY, actor.x - actor.drawX)
		local dist = math.sqrt((actor.y - actor.drawY)^2 + (actor.x - actor.drawX)^2)
		local speed = math.max(math.sqrt(actor.velX^2 + actor.velY^2), dist)
		
		if dist > dt*speed then
			actor.drawX = actor.drawX + dt*speed*math.cos(angle)
			actor.drawY = actor.drawY + dt*speed*math.sin(angle)
			
			if actor.movementParticleFunc  then
				if actor.movementFuncTimer <= 0 then
					actor.movementParticleFunc(actor, actor.drawX, actor.drawY)
					actor.movementFuncTimer = actor.movementParticleFuncPeriod
				end
				actor.movementFuncTimer = actor.movementFuncTimer - dt
			end
		else
			actor.drawX = actor.x
			actor.drawY = actor.y
		end
	end
end

function Actor.getSpeed(actor)
	return Misc.orthogDistance(0, 0, actor.velX, actor.velY)
end

function Actor.getMomentum(actor)
	return Misc.orthogDistance(0, 0, actor.momentX, actor.momentY)
end

function Actor.predictPosition(actor, tilesAhead)
	tilesAhead = tilesAhead or 0
	
	local xAdd = 0
	local yAdd = 0
	if tilesAhead ~= 0 then
		local angle = math.atan2(actor.velY + actor.momentY, actor.velX + actor.momentX)
		xAdd, yAdd = Misc.orthogPointFrom(0, 0, tilesAhead, angle)
		xAdd = Misc.round(xAdd)
		yAdd = Misc.round(yAdd)
	end
	
	return Misc.round(actor.x + actor.velX + actor.momentX + xAdd), Misc.round(actor.y + actor.velY + actor.momentY + yAdd)
end

function Actor.changeSpeed(actor, val)
	local currentSpeed = Actor.getSpeed(actor)
	local newSpeed = math.max(currentSpeed + val, 0)
	actor.velX, actor.velY = Misc.orthogPointFrom(0, 0, newSpeed, math.atan2(actor.velY, actor.velX))
	actor.velX = Misc.round(actor.velX)
	actor.velY = Misc.round(actor.velY)
end

function Actor.restrictSpeed(actor, restriction)
	local speed = Actor.getSpeed(actor)
	if speed > restriction then
		Actor.changeSpeed(actor, restriction - speed)
	end
end

function Actor.impulseActor(actor, xMoment, yMoment)
	actor.momentX = actor.momentX + Misc.round(xMoment)
	actor.momentY = actor.momentY + Misc.round(yMoment)
end

function Actor.momentumDrag(actor, drag)
	local currentMoment = Misc.orthogDistance(0, 0, actor.momentX, actor.momentY)
	local newMoment = math.max(currentMoment - drag, 0)
	if newMoment > 0 then
		print(actor.momentX .. " : " .. actor.momentY)
	end
	actor.momentX, actor.momentY = Misc.orthogPointFrom(0, 0, newMoment, math.atan2(actor.momentY, actor.momentX))
	actor.momentX = Misc.round(actor.momentX)
	actor.momentY = Misc.round(actor.momentY)
	if newMoment > 0 then
		print(actor.momentX .. " - " .. actor.momentY)
	end
end

function Actor.draw(actor, camera)
	Camera.drawTo(actor.letter, actor.drawX, actor.drawY, camera, Letter.draw)
end

return Actor