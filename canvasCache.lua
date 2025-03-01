local CanvasStack = require "canvasStack"

local CanvasCache = {}

local canvases = {}
local canvasCounts = {}
local maxHeight = 10000
local function getKey(width, height)
	return maxHeight*width + height
end

function CanvasCache.getCanvas(width, height)
	if height > maxHeight then
		error("Canvas max height exceeded: " .. height)
	end
	
	width = math.ceil(width)
	height = math.ceil(height)
	--Gets a canvas from the canvas cache. Remember to return after use.
	local key = getKey(width, height)
	--if canvasCounts[key] and canvasCounts[key] > 0 then
	--	local canvas = canvases[key][canvasCounts[key]]
	--	table.remove(canvases[key], canvasCounts[key])
	--	canvasCounts[key] = canvasCounts[key] - 1
	--	
	--	CanvasStack.set(canvas)
	--	love.graphics.clear()
	--	CanvasStack.reset()
	--	
	--	return canvas
	--else
	--	if love.keyboard.isDown("f9") then
	--		print("new canvas dims: " .. key)
	--		print(debug.traceback())
	--	end
	--	local canvas = love.graphics.newCanvas(width, height)
	--	canvas:setFilter('nearest', 'nearest')
	--	return canvas
	--end
	
	local canvas
	if not canvasCounts[key] or canvasCounts[key] == 0 then
		--print("new one: " .. key .. " yeah " .. tostring(canvasCounts[key]))
		--Debug.printTraceback()
		
		canvas = love.graphics.newCanvas(width, height)
		canvas:setFilter('nearest', 'nearest')
		
		return canvas
	end
	
	canvas = canvases[key][canvasCounts[key]]
	table.remove(canvases[key], canvasCounts[key])
	canvasCounts[key] = canvasCounts[key] - 1
	
	CanvasStack.add(canvas)
	love.graphics.clear()
	CanvasStack.descend()
	
	return canvas
end

local function checkCanvasPresent(canvases, canvas)
	local oldCanvas = love.graphics.getCanvas()
	for i = 1, #canvases do
		CanvasStack.set(canvases[i])
		love.graphics.draw(canvas)
	end
	CanvasStack.set(oldCanvas)
end

function CanvasCache.returnCanvas(canvas)
	--Returns a canvas to the canvas bank. Technically this doesn't even have to be a canvas gotten from the canvas cache.
	if canvas == nil then
		return
	end
	
	local key = getKey(canvas:getWidth(), canvas:getHeight())
	
	if not canvases[key] then
		canvases[key] = {}
		canvasCounts[key] = 0
	end
	--checkCanvasPresent(canvases[key], canvas)
	table.insert(canvases[key], canvas)
	canvasCounts[key] = canvasCounts[key] + 1
end

function CanvasCache.getContentsString()
	--Gets the contents of the canvas cache as a string, useful for debug.
	local returnString = ""
	for key, value in pairs(canvasCounts) do
		returnString = returnString .. key .. ": " .. tostring(value) .. "\n"
	end
	return returnString
end

return CanvasCache