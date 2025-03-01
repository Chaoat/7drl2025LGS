local CanvasStack = require "canvasStack"
local CanvasCache = require "canvasCache"
local Misc = require "misc"

local Image = {}

local images = {}
local multiTileImages = {}
local multiTileImageQuads = {}

local function loadImage(dir)
	if not images[dir] then
		local path = "images/" .. dir .. ".png"
		if love.filesystem.getInfo(path) == nil then
			return nil
		end
	
		local image = {dir = path, pixelLimits = {}}
		image.image = love.graphics.newImage(path)
		image.width = image.image:getWidth()
		image.height = image.image:getHeight()
		
		image.image:setFilter('linear', 'nearest')
		
		images[dir] = image
	end
end

function Image.getImage(dir)
	loadImage(dir)
	
	return images[dir]
end

local multiTileImageWidth = 20
local multiTileImageHeight = 20
local multiTileImageWidthPlusOne = multiTileImageWidth + 1
local multiTileImageHeightPlusOne = multiTileImageHeight + 1
local function multiImageKey(width, height)
	return width .. ":" .. height
end
local function loadMultiImage(dir)
	if not multiTileImages[dir] then
		local path = "images/" .. dir .. ".png"
		if love.filesystem.getInfo(path) == nil then
			return nil
		end
		local image = love.graphics.newImage(path)
		
		local iWidth = image:getWidth()
		local iHeight = image:getHeight()
		
		local xAcross = math.ceil(iWidth/multiTileImageWidthPlusOne)
		local yAcross = math.ceil(iHeight/multiTileImageHeightPlusOne)
		
		local key = multiImageKey(iWidth, iHeight)
		if not multiTileImageQuads[key] then
			multiTileImageQuads[key] = {}
			for i = 1, xAcross do
				multiTileImageQuads[key][i] = {}
				for j = 1, yAcross do
					multiTileImageQuads[key][i][j] = love.graphics.newQuad((i - 1)*multiTileImageWidthPlusOne, (j - 1)*multiTileImageHeightPlusOne, 30, 30, iWidth, iHeight)
				end
			end
		end
		
		local images = {}
		for i = 1, xAcross do
			images[i] = {}
			for j = 1, yAcross do
				local newCanvas = CanvasCache.getCanvas(multiTileImageWidth, multiTileImageHeight)
				CanvasStack.add(newCanvas)
				love.graphics.setColor(1, 1, 1, 1)
				love.graphics.draw(image, multiTileImageQuads[key][i][j])
				CanvasStack.descend(1)
				images[i][j] = {image = newCanvas, width = multiTileImageWidth, height = multiTileImageHeight}
			end
		end
		
		local multiImage = {images = images, xAcross = xAcross, yAcross = yAcross}
		
		multiTileImages[dir] = multiImage
	end
end

function Image.getMultiTileImage(dir)
	loadMultiImage(dir)
	
	return multiTileImages[dir]
end


function Image.getPixelLimits(image, segmentSize)
	if not image.pixelLimits[segmentSize] then
		local imageData = love.image.newImageData(image.dir)
		local pixelLimits = {}
		
		local nSegments = math.ceil(image.height/segmentSize)
		local yStart = 0
		local yEnd = segmentSize - 1
		for i = 1, nSegments do
			local xMin = image.width
			local xMax = 0
			for y = yStart, yEnd do
				for x = 0, image.width - 1 do
					local r, g, b, a = imageData:getPixel(x, y)
					if a > 0 then
						xMin = math.min(xMin, x)
						xMax = math.max(xMax, x)
					end
				end
			end
			yStart = yStart + segmentSize
			yEnd = math.min(yEnd + segmentSize, image.height - 1)
			
			table.insert(pixelLimits, {xMin = xMin/image.width, xMax = xMax/image.width, yMin = yStart/image.height, yBax = yEnd/image.height})
		end
		
		image.pixelLimits[segmentSize] = pixelLimits
	end
	return image.pixelLimits[segmentSize]
end

function Image.cleanUpImage(image)
	CanvasCache.returnCanvas(image.image)
end

function Image.canvasToImageLightWeight(canvas)
	--no duplication, just uses the canvas
	local width = canvas:getWidth()
	local height = canvas:getHeight()
	return {image = canvas, width = width, height = height}
end

function Image.canvasToImage(canvas)
	local width = canvas:getWidth()
	local height = canvas:getHeight()
	local newCanvas = CanvasCache.getCanvas(width, height)
	CanvasStack.add(newCanvas)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(canvas)
	CanvasStack.descend()
	return {image = newCanvas, width = width, height = height}
end

function Image.duplicate(image)
	local newCanvas = CanvasCache.getCanvas(image.width, image.height)
	CanvasStack.set(newCanvas)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(image.image)
	CanvasStack.reset()
	return {image = newCanvas, width = image.width, height = image.height}
end

function Image.drawImage(image, camera, x, y, r, ox, oy, sx, sy)
	if not sx then
		sx = 1
		sy = 1
	end
	Image.drawOutsideMap(image, camera, x, y, r, ox, oy, sx, sy)
end

function Image.drawOutsideMap(image, camera, x, y, r, ox, oy, sx, sy)
	if not sx then
		sx = 1
		sy = 1
	end
	
	local drawX, drawY = Camera.findDrawPos(x, y, camera)
	
	ox = image.width*ox
	oy = image.height*oy
	
	love.graphics.draw(image.image, Misc.round(drawX), Misc.round(drawY), r, sx, sy, ox, oy)
end

function Image.drawImageScreenSpace(image, x, y, r, ox, oy, sx, sy)
	if not sx then
		sx = 1
		sy = 1
	end
	
	ox = image.width*ox
	oy = image.height*oy
	
	love.graphics.draw(image.image, Misc.round(x), Misc.round(y), r, sx, sy, ox, oy)
end

function Image.drawImageOverArea(image, x1, y1, x2, y2)
	local sx = (x2 - x1)/image.width
	local sy = (y2 - y1)/image.height
	
	love.graphics.draw(image.image, Misc.round(x1), Misc.round(y1), 0, sx, sy, 0, 0)
end

Image.outWorldCamera = {tileX = 30, tileY = 30}

return Image