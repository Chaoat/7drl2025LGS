local Camera = require "camera"
local Misc = require "misc"

local Particle = {}

local particleQueues = {}
function Particle.queue(particle, layer)
	if particleQueues[layer] == nil then
		particleQueues[layer] = {}
	end
	table.insert(particleQueues[layer], particle)
end

function Particle.collectFromQueue(collection, layer)
	if particleQueues[layer] ~= nil then
		for i = 1, #particleQueues[layer] do
			table.insert(collection, particleQueues[layer][i])
		end
		particleQueues[layer] = {}
	end
end

function Particle.new(x, y, drawFunc)
	--drawFunc(particle, drawX, drawY, tileWidth, tileHeight)
	local roundedX = Misc.round(x)
	local roundedY = Misc.round(y)
	
	local particle = {x = roundedX, y = roundedY, floatingX = x - roundedX, floatingY = y - roundedY, dead = false, drawFunc = drawFunc}
	return particle
end

function Particle.update(particle, dt)
	if particle.velX then
		particle.floatingX = particle.floatingX + particle.velX*dt
		if particle.floatingX ~= 0 then
			local moves = math.floor(math.abs(particle.floatingX))
			local diff = moves*(particle.floatingX/math.abs(particle.floatingX))
			particle.floatingX = particle.floatingX - diff
			particle.x = particle.x + diff
		end
	end
	
	if particle.velY then
		particle.floatingY = particle.floatingY + particle.velY*dt
		if particle.floatingX ~= 0 then
			local moves = math.floor(math.abs(particle.floatingY))
			local diff = moves*(particle.floatingY/math.abs(particle.floatingY))
			particle.floatingY = particle.floatingY - diff
			particle.y = particle.y + diff
		end
	end
	
	if particle.timeLeft then
		particle.timeLeft = particle.timeLeft - dt
		
		if particle.timeLeft <= 0 then
			particle.dead = true
		end
	end
end

function Particle.updateCollection(collection, layer, dt)
	Particle.collectFromQueue(collection, layer)
	for i = #collection, 1, -1 do
		Particle.update(collection[i], dt)
		
		if collection[i].dead then
			table.remove(collection, i)
		end
	end
end

function Particle.setVelocity(particle, velX, velY)
	particle.velX = velX
	particle.velY = velY
	return particle
end

function Particle.draw(particle, camera)
	Camera.drawTo(particle, particle.x, particle.y, camera, particle.drawFunc)
end

function Particle.drawCollection(collection, camera)
	for i = 1, #collection do
		Particle.draw(collection[i], camera)
	end
end

do --particle library
	function Particle.colourShiftBox(x, y, colour1, colour2, duration)
		local drawFunc = function(particle, drawX, drawY, tileWidth, tileHeight)
			local progress = particle.timeLeft/particle.duration
			local col1Factor = {progress, progress, progress, progress}
			local col2Factor = {1 - progress, 1 - progress, 1 - progress, 1 - progress}
			
			love.graphics.setColor(Misc.addColours(
								Misc.multiplyColours(col1Factor, particle.colour1), 
								Misc.multiplyColours(col2Factor, particle.colour2)))
			
			love.graphics.rectangle("fill", drawX - tileWidth/2, drawY - tileHeight/2, tileWidth, tileHeight)
		end
		local particle = Particle.new(x, y, drawFunc)
		
		particle.colour1 = colour1
		particle.colour2 = colour2
		
		particle.timeLeft = duration
		particle.duration = duration
		
		return particle
	end
end

return Particle