local Misc = require "misc"

local Camera = {}

function Camera.new()
	local camera = {worldX = 0, worldY = 0, screenX = 0, screenY = 0, cameraWidth = love.graphics.getWidth(), cameraHeight = love.graphics.getHeight(), tileWidth = 20, tileHeight = 20}
	
	camera.canvas = love.graphics.newCanvas(camera.cameraWidth, camera.cameraHeight)
	
	return camera
end

function Camera.move(camera, x, y)
	camera.worldX = x
	camera.worldY = y
end

function Camera.trackPlayer(camera, player)
	if player.controlMode == "movement" then
		Camera.move(camera, player.actor.drawX, player.actor.drawY)
	elseif player.controlMode == "freeLook" then
		Camera.move(camera, player.lookCursorX, player.lookCursorY)
	end
end

function Camera.resize(camera, width, height)
	camera.cameraWidth = width
	camera.cameraHeight = height
	camera.canvas = love.graphics.newCanvas(camera.cameraWidth, camera.cameraHeight)
end

function Camera.screenToTileCoords(camera, screenx, screeny)
	local centerX = camera.screenX + camera.cameraWidth/2
	local centerY = camera.screenY + camera.cameraHeight/2
	
	return Misc.round(camera.worldX + (screenx - centerX)/camera.tileWidth), Misc.round(camera.worldY + (screeny - centerY)/camera.tileHeight)
end

function Camera.worldToDrawCoords(worldX, worldY, camera)
	local drawX = (worldX - camera.worldX)*camera.tileWidth + camera.cameraWidth/2
	local drawY = (worldY - camera.worldY)*camera.tileHeight + camera.cameraHeight/2
	return drawX, drawY
end

function Camera.drawTo(object, worldX, worldY, camera, drawFunc)
	--drawFunc(object, drawX, drawY, tileWidth, tileHeight)
	local lastCanvas = love.graphics.getCanvas()
	
	local drawX, drawY = Camera.worldToDrawCoords(worldX, worldY, camera)
	
	if drawX >= -camera.tileWidth/2 and drawX <= camera.cameraWidth + camera.tileWidth/2 and drawY >= -camera.tileHeight/2 and drawY <= camera.cameraHeight + camera.tileHeight/2 then
		love.graphics.setCanvas(camera.canvas)
		drawFunc(object, Misc.round(drawX), Misc.round(drawY), camera.tileWidth, camera.tileHeight)
		love.graphics.setCanvas(lastCanvas)
		return true
	end
	return false
end

function Camera.draw(screenX, screenY, camera)
	camera.screenX = screenX
	camera.screenY = screenY
	
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(camera.canvas, screenX, screenY)
end

function Camera.clear(camera)
	local lastCanvas = love.graphics.getCanvas()
	love.graphics.setCanvas(camera.canvas)
	love.graphics.clear()
	love.graphics.setCanvas(lastCanvas)
end

return Camera