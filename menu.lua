local Image = require "image"
local CanvasCache = require "canvasCache"
local CanvasStack = require "canvasStack"
local Misc = require "misc"
local Font = require "font"
local Controls = require "controls"
local Inventory = require "inventory"
local Tool = require "tool"
local Crew = require "crew"
local Text = require "text"
local Score = require "score"
local Player = require "player"

local Menu = {}

local function newCursor()
	local cursor = {image = Image.getImage("interface/menu/cursor"), lastX = 0, lastY = 0, angle = 0, sideways = true}
	return cursor
end

function Menu.new(backgroundDrawFunc)
	local menu = {screens = {}, canvas = nil, lastWidth = 0, lastHeight = 0, lastUpdate = 0, currentScreen = nil, takingKeyboardInput = nil, backgroundDrawFunc = backgroundDrawFunc, alpha = 1, lastMouseX = 0, lastMouseY = 0, lastTipX = nil, lastTipY = nil, currentlyInFocus = false, cursor = newCursor()}
	return menu
end

function Menu.addScreen(menu, screen)
	screen.parent = menu
	menu.screens[screen.identifier] = screen
	
	if not menu.currentScreen then
		Menu.switchScreen(menu, screen.identifier)
	end
	
	return menu
end

function Menu.switchScreen(menu, screenID, transitionTime)
	local switchFunc = function()
		if menu.screens[screenID] then
			if menu.currentScreen then
				menu.currentScreen.open = false
			end
			
			menu.currentScreen = menu.screens[screenID]
			menu.currentScreen.open = true
		else
			print("Menu lacks screen with ID: " .. screenID)
		end
	end
	
	if not transitionTime or transitionTime == 0 then
		switchFunc()
	else
		Game.loadCutscene(GlobalGame, Cutscene.stateTransition("menu", "menu", switchFunc, transitionTime))
	end
end

function Menu.click(menu, mouseX, mouseY, mouseButton)
	if menu.currentScreen then
		if menu.takingKeyboardInput then
			menu.takingKeyboardInput.textEntry(menu.takingKeyboardInput, "", true)
		else
			return Menu.screen.click(menu.currentScreen, mouseX, mouseY, mouseButton)
		end
	end
end

function Menu.release(menu, mouseX, mouseY, mouseButton)
	if menu.currentScreen then
		Menu.screen.release(menu.currentScreen, mouseX, mouseY, mouseButton)
	end
end

function Menu.mouseMove(menu, mouseX, mouseY, xChange, yChange)
	menu.lastMouseX = mouseX
	menu.lastMouseY = mouseY
	if menu.currentScreen then
		local mousedOverSomething = Menu.screen.mouseMove(menu.currentScreen, mouseX, mouseY, xChange, yChange)
		menu.cursor.sideways = not mousedOverSomething
	end
end

function Menu.keyInput(menu, key)
	if Controls.checkControl(key, "click") then
		local mX, mY = love.mouse.getPosition()
		Menu.click(menu, mX, mY, 1)
	elseif Controls.checkControlReleased(key, "click") then
		local mX, mY = love.mouse.getPosition()
		Menu.release(menu, mX, mY, 1)
	else
		if menu.currentScreen then
			--print("key: " .. key)
			if menu.takingKeyboardInput then
				menu.takingKeyboardInput.textEntry(menu.takingKeyboardInput, key)
			else
				if menu.currentScreen.keyInput and menu.currentScreen.keyInput(key) then
				elseif Controls.checkControl(key, "accept") then
					--print("yeah man")
					Menu.screen.click(menu.currentScreen, menu.lastMouseX, menu.lastMouseY, 1)
				elseif Controls.checkControl(key, "left") then
					local newX, newY = Menu.screen.moveCursor(menu.currentScreen, menu.lastMouseX, menu.lastMouseY, -1, 0)
					Menu.mouseMove(menu, newX, newY, newX - menu.lastMouseX, newY - menu.lastMouseY)
				elseif Controls.checkControl(key, "right") then
					local newX, newY = Menu.screen.moveCursor(menu.currentScreen, menu.lastMouseX, menu.lastMouseY, 1, 0)
					Menu.mouseMove(menu, newX, newY, newX - menu.lastMouseX, newY - menu.lastMouseY)
				elseif Controls.checkControl(key, "up") then
					local newX, newY = Menu.screen.moveCursor(menu.currentScreen, menu.lastMouseX, menu.lastMouseY, 0, -1)
					Menu.mouseMove(menu, newX, newY, newX - menu.lastMouseX, newY - menu.lastMouseY)
				elseif Controls.checkControl(key, "down") then
					local newX, newY = Menu.screen.moveCursor(menu.currentScreen, menu.lastMouseX, menu.lastMouseY, 0, 1)
					Menu.mouseMove(menu, newX, newY, newX - menu.lastMouseX, newY - menu.lastMouseY)
				elseif Controls.checkControlReleased(key, "accept") then
					Menu.screen.release(menu.currentScreen, menu.lastMouseX, menu.lastMouseY, 1)
				end
			end
		end
	end
end

--function Menu.keyReleaseInput(menu, key)
--	if menu.currentScreen then
--		if Controls.checkControl(key, "accept") then
--			Menu.screen.release(menu.currentScreen, menu.lastMouseX, menu.lastMouseY, 1)
--		end
--	end
--end

function Menu.mouseScroll(menu, wheelX, wheelY)
	if menu.currentScreen then
		if Controls.checkControlEnabled("scroll") then
			Menu.screen.scroll(menu.currentScreen, wheelX, wheelY)
		end
	end
end

function Menu.draw(menu, x, y, width, height)
	if menu.lastWidth ~= width or menu.lastHeight ~= height then
		if menu.canvas then
			CanvasCache.returnCanvas(menu.canvas)
		end
		menu.canvas = CanvasCache.getCanvas(width, height)
		menu.lastWidth = width
		menu.lastHeight = height
	end
	
	local timeChange = GLOBALAnimationClock - menu.lastUpdate
	if timeChange > 1 then
		timeChange = 0
	end
	menu.lastUpdate = GLOBALAnimationClock
	
	if menu.backgroundDrawFunc then
		menu.backgroundDrawFunc(x, y, width, height, timeChange)
	end
	
	if menu.currentScreen then
		local treeN = CanvasStack.add(menu.canvas)
		love.graphics.clear()
		Menu.screen.draw(menu.currentScreen, 0, 0, width, height, true, timeChange)
		CanvasStack.descend()
		
		love.graphics.setColor(1, 1, 1, menu.alpha)
		love.graphics.draw(menu.canvas, x, y)
	end
end

local debugElementDraw = false
function Menu.toggleDebugDraw()
	debugElementDraw = not debugElementDraw
end

do --screen
	Menu.screen = {}
	
	function Menu.screen.addScrollBar(screen, posFunc, scrollBuffer)
		--This should be called after all the other elements. Position of posFunc is important, and it alters all the other draw functions so the other elements must be present
		--scrollBuffer - extra added space at the bottom of the screen that can be scrolled to
		local scrollRange = {0, 0}
		screen.vertScroll = 0
		
		local augPosFunc = function(element, parX, parY, parWidth, parHeight)
			local x1, y1, x2, y2 = posFunc(element, parX, parY, parWidth, parHeight)
			
			element.y2 = nil
			scrollRange[2] = -parHeight + scrollBuffer + screen.parent.minDims(screen.parent)[2]
			
			for i = 1, #element.parent.elements do
				local neighbour = element.parent.elements[i]
				if neighbour.y2 then
					--scrollRange[2] = scrollRange[2] + neighbour.height()
					
					neighbour.y1 = neighbour.y1 - screen.vertScroll
					neighbour.y2 = neighbour.y2 - screen.vertScroll
				end
			end
			
			--I FORGET WHY I ADDED THIS, IT MIGHT BE IMPORTANT, BUT IT BREAKS THE LIBRARY--
			
			--if screen.vertScroll > math.max(scrollRange[2], scrollRange[1]) then
			--	local previousScroll = screen.vertScroll
			--	screen.vertScroll = math.max(scrollRange[2], scrollRange[1])
			--	
			--	for i = 1, #element.parent.elements do
			--		local neighbour = element.parent.elements[i]
			--		if neighbour.y2 then
			--			neighbour.y1 = neighbour.y1 + previousScroll - screen.vertScroll
			--			neighbour.y2 = neighbour.y2 + previousScroll - screen.vertScroll
			--		end
			--	end
			--end
			
			return x1, y1, x2, y2
		end
		
		local scrollBar = Menu.element.vertSlider(augPosFunc, screen, "vertScroll", function()
			screen.forceReposition = true
		end, scrollRange, 0.1)
		scrollBar.ignoreOverlap = true
		
		screen.scrollFunc = function(element, wheelX, wheelY)
			if scrollRange[2] > scrollRange[1] then
				screen.vertScroll = math.min(math.max(screen.vertScroll - Controls.scrollSpeed()*wheelY, scrollRange[1]), scrollRange[2])
				screen.forceReposition = true
			end
		end
		
		Menu.screen.addElement(screen, scrollBar)
		return scrollBar
	end
	
	
	function Menu.screen.setClearColour(clearColour, screen)
		screen.clearColour = clearColour
		return screen
	end
	
	function Menu.screen.new(identifier, backDrawFunc)
		--identifier - string to identify the screen by
		--backDrawFunc - (x, y, width, height), draw function for the background
		
		local screenConstrictShader = love.graphics.newShader([[
			extern vec4 pixelBounds;
			//x1, y1, x2, y2
			
			vec4 effect(vec4 colour, Image image, vec2 texture_coords, vec2 pixel_coords)
			{
				vec4 iPixel = Texel(image, texture_coords);
				if (pixel_coords[0] >= pixelBounds[0] && pixel_coords[0] <= pixelBounds[2] && pixel_coords[1] >= pixelBounds[1] && pixel_coords[1] <= pixelBounds[3]) {
					return colour*iPixel;
				} else {
					return vec4(0, 0, 0, 0);
				}
			}
		]])
		
		local screen = {canvas = nil, constrictShader = screenConstrictShader, identifier = identifier, elements = {}, backDrawFunc = backDrawFunc, parent = nil, lx = nil, ly = nil, lwidth = nil, lheight = nil, canvasWidth = nil, canvasHeight = nil, forceReposition = false, clearColour = {0, 0, 0, 0}}
		return screen
	end
	
	local deleteElements
	function deleteElements(elements)
		for i = 1, #elements do
			local element = elements[i]
			if element.delete then
				element.delete()
			end
		end
	end
	function Menu.screen.delete(screen)
		CanvasCache.returnCanvas(screen.canvas)
		screen.canvas = nil
		deleteElements(screen.elements)
	end
	
	function Menu.screen.addElement(screen, element)
		if not screen.parent then
			table.insert(screen.elements, element)
			element.parent = screen
			
			if element.clickFunc or element.releaseFunc then
				element.selectable = true
			end
		else
			print("Screen " .. screen.identifier .. " can not have an element added, as it is already initiated")
		end
		
		return screen
	end
	
	function Menu.screen.addElements(screen, elements)
		for i = 1, #elements do
			Menu.screen.addElement(screen, elements[i])
		end
		
		return screen
	end
	
	function Menu.screen.setKeyInput(screen, keyInputFunc)
		--keyInputFunc(key) - returns true if they key is used, false otherwise
		
		screen.keyInput = keyInputFunc
	end
	
	local checkElementListClicked
	local function checkElementListClicked(elements, mouseX, mouseY, mouseButton)
		for i = #elements, 1, -1 do
			local element = elements[i]
			if element.mouseOver then
				if element.getChildren and checkElementListClicked(element.getChildren(), mouseX, mouseY, mouseButton) then
					return true
				end
				
				if element.selectable then
					element.clicked = mouseButton
					if element.clickFunc then
						element.clickFunc(element, mouseX, mouseY, mouseButton)
						return true
					elseif element.releaseFunc then
						return true
					end
				end
			end
		end
		return false
	end
	function Menu.screen.click(screen, mouseX, mouseY, mouseButton)
		return checkElementListClicked(screen.elements, mouseX, mouseY, mouseButton)
	end
	
	local checkElementListMouseover
	local function checkElementListMouseover(elements, mouseX, mouseY, xChange, yChange)
		local mousedOver = false
		for i = 1, #elements do
			local element = elements[i]
			
			if element.active and element.getChildren then
				mousedOver = checkElementListMouseover(element.getChildren(), mouseX, mouseY, xChange, yChange) or mousedOver
			end
			
			if element.active and element.x1 and mouseX > element.x1 and mouseY > element.y1 and mouseX < element.x2 and mouseY < element.y2 and (element.mouseOverBounds == nil or element.mouseOverBounds(element, mouseX, mouseY)) then
				if element.mouseOver == false then
					element.mouseOverTime = GLOBALAnimationClock
				end
				element.mouseOver = true
				mousedOver = element.clickFunc or element.releaseFunc or mousedOver
			elseif not element.stickyClick or not element.clicked then
				element.clicked = false
				element.mouseOver = false
			end
		end
		return mousedOver
	end
	function Menu.screen.mouseMove(screen, mouseX, mouseY, xChange, yChange)
		return checkElementListMouseover(screen.elements, mouseX, mouseY, xChange, yChange)
	end
	
	local checkElementListRelease
	local function checkElementListRelease(elements, mouseX, mouseY, mouseButton)
		for i = #elements, 1, -1 do
			local element = elements[i]
			--if element.mouseOver then
				if element.getChildren then
					checkElementListRelease(element.getChildren(), mouseX, mouseY, mouseButton)
				end
				
				if element.selectable then
					if element.clicked == mouseButton then
						element.clicked = false
						if element.releaseFunc then
							element.releaseFunc(element, mouseX, mouseY, mouseButton)
						end
					end
				end
				--return true
			--end
		end
		return false
	end
	function Menu.screen.release(screen, mouseX, mouseY, mouseButton)
		checkElementListRelease(screen.elements, mouseX, mouseY, mouseButton)
	end
	
	local checkElementListScroll
	local function checkElementListScroll(elements, wheelX, wheelY)
		for i = #elements, 1, -1 do
			local element = elements[i]
			if element.mouseOver then
				if element.getChildren and checkElementListScroll(element.getChildren(), wheelX, wheelY) then
					return true
				end
				
				--print("scrollFunc: " .. tostring(element.scrollFunc))
				if element.scrollFunc then
					element.scrollFunc(element, wheelX, wheelY)
					return true
				end
			end
		end
		return false
	end
	function Menu.screen.scroll(screen, wheelX, wheelY)
		--print("it's happening")
		checkElementListScroll(screen.elements, wheelX, wheelY)
	end
	
	local function getElementCenter(element)
		return (element.x1 + element.x2)/2, (element.y1 + element.y2)/2
	end
	
	function Menu.screen.moveCursor(screen, lastX, lastY, xDirection, yDirection)
		--Need to figure out a way to not count covered elements.
		--This should be as easy as having the elements determine whether they're covered in the resolveOverlap function, take a list of things overlapping and see if they're active.
		
		local selectables = {}
		local findSelectables
		findSelectables = function(elementList)
			for i = 1, #elementList do
				local element = elementList[i]
				if element.active and element.inView then
					if element.selectable and not element.mouseOver then
						table.insert(selectables, element)
					end
					if element.getChildren then
						findSelectables(element.getChildren())
					end
				end
			end
		end
		findSelectables(screen.elements)
		
		local minDist = math.huge
		local minDistElement = false
		local oppDist = 0
		local oppDistElement = false
		local angleAnchor = math.atan2(yDirection, xDirection)
		for i = 1, #selectables do
			local element = selectables[i]
			local xCenter, yCenter = getElementCenter(element)
			--local xDiff = xCenter - lastX
			--local yDiff = yCenter - lastY
			--
			--local mainDist = math.max(xDirection*xDiff, 0) + math.max(yDirection*yDiff, 0)
			--local offDist = xDiff*((xDirection + 1)%2) + yDiff*((yDirection + 1)%2)
			--local dist = mainDist + 4*offDist
			--
			--if dist < minDist then
			--	minDist = dist
			--	minDistElement = element
			--end
			
			local topDist = yCenter - lastY
			local botDist = lastY - yCenter
			local leftDist = xCenter - lastX
			local rightDist = lastX - xCenter
			
			local angleDist = Misc.distanceBetweenAngles(math.atan2(topDist, leftDist), angleAnchor)
			if angleDist <= math.pi/3 then
				local dist = math.max(topDist*yDirection, 0) + math.max(botDist*yDirection, 0) + math.max(leftDist*xDirection, 0) + math.max(rightDist*xDirection, 0)
				if dist < minDist then
					minDist = dist
					minDistElement = element
				end
			elseif angleDist >= 2*math.pi/3 then
				local oppositeDist = math.max(-topDist*yDirection, 0) + math.max(-botDist*yDirection, 0) + math.max(-leftDist*xDirection, 0) + math.max(-rightDist*xDirection, 0)
				if oppositeDist > oppDist then
					oppDist = oppositeDist
					oppDistElement = element
				end
			end
		end
		
		if minDistElement then
			local xCenter, yCenter = getElementCenter(minDistElement)
			return xCenter, yCenter
		elseif oppDistElement then
			local xCenter, yCenter = getElementCenter(oppDistElement)
			return xCenter, yCenter
		end
		print("darn missed")
		return lastX, lastY
	end
	
	local function shiftElement(element, xShift, yShift)
		element.x1 = element.x1 + xShift
		element.x2 = element.x2 + xShift
		element.y1 = element.y1 + yShift
		element.y2 = element.y2 + yShift
	end
	
	local function resolveOverlap(screen)
		local overlapping = true
		while overlapping do
			overlapping = false
			
			for i = 1, #screen.elements do
				screen.elements[i].overlapping = {}
			end
			
			for i = 1, #screen.elements do
				local element = screen.elements[i]
				if element.active then
					local eXCenter, eYCenter = getElementCenter(element)
					for j = i + 1, #screen.elements do
						local neighbour = screen.elements[j]
						if neighbour.active then
							local nXCenter, nYCenter = getElementCenter(neighbour)
							
							local xSeperation = math.abs(eXCenter - nXCenter) - (element.x2 - element.x1)/2 - (neighbour.x2 - neighbour.x1)/2
							local ySeperation = math.abs(eYCenter - nYCenter) - (element.y2 - element.y1)/2 - (neighbour.y2 - neighbour.y1)/2
							
							--print("xSeperation: " .. xSeperation .. " ySeperation: " .. ySeperation)
							
							if math.ceil(xSeperation) < 0 and math.ceil(ySeperation) < 0 then
								if not neighbour.ignoreOverlap and not element.ignoreOverlap then
									if xSeperation > ySeperation then
										if eXCenter < nXCenter then
											shiftElement(element, xSeperation/2, 0)
											shiftElement(neighbour, -xSeperation/2, 0)
										else
											shiftElement(element, -xSeperation/2, 0)
											shiftElement(neighbour, xSeperation/2, 0)
										end
									else
										if eYCenter < nYCenter then
											shiftElement(element, 0, ySeperation/2)
											shiftElement(neighbour, 0, -ySeperation/2)
										else
											shiftElement(element, 0, -ySeperation/2)
											shiftElement(neighbour, 0, ySeperation/2)
										end
									end
									
									overlapping = true
								else
									table.insert(neighbour.overlapping, element)
									table.insert(element.overlapping, neighbour)
								end
							end
						end
					end
				end
			end
		end
	end
	
	function Menu.screen.decidePositions(screen, x, y, width, height)
		if x ~= screen.lx or y ~= screen.ly or width ~= screen.lwidth or height ~= screen.lheight or screen.forceReposition then
			screen.forceReposition = false
			screen.constrictShader:send("pixelBounds", {x, y, x + width, y + height})
			
			for i = 1, #screen.elements do
				local element = screen.elements[i]
				if element.active then
					local x1, y1, x2, y2 = screen.elements[i].posFunc(element, x, y, width, height)
					element.x1 = x1
					element.y1 = y1
					element.x2 = x2
					element.y2 = y2
					
					if element.screen then
						element.screen.forceReposition = true
						Menu.screen.decidePositions(element.screen, element.x1, element.y1, element.x2 - element.x1, element.y2 - element.y1)
					end
				end
			end
			
			resolveOverlap(screen)
			
			screen.lx = x
			screen.ly = y
			screen.lwidth = width
			screen.lheight = height
			
			if screen.forceReposition then
				Menu.screen.decidePositions(screen, x, y, width, height)
			end
		end
	end
	
	function Menu.screen.draw(screen, x, y, width, height, screenVisible, timeChange, doNotDraw)
		--screenVisible is deprecated, used to be that screens not visible would still draw to figure out positions, no longer the case
		
		local screenWidth,screenHeight,_ = love.window.getMode();
		
		if screenWidth ~= screen.canvasWidth or screenHeight ~= screen.canvasHeight then
			screen.canvasWidth = screenWidth
			screen.canvasHeight = screenHeight
			if screen.canvas then
				CanvasCache.returnCanvas(screen.canvas)
			end
			screen.canvas = CanvasCache.getCanvas(screenWidth, screenHeight)
		end
		
		if screen.backDrawFunc then
			screen.backDrawFunc(x, y, width, height)
		end
		
		CanvasStack.add(screen.canvas)
		love.graphics.clear(screen.clearColour)
		
		Menu.screen.decidePositions(screen, x, y, width, height)
		
		for i = 1, #screen.elements do
			local element = screen.elements[i]
			--if element.active and not element.x1 then
			--	screen.forceReposition = true
			--	Menu.screen.decidePositions(screen, x, y, width, height)
			--end
			
			local withinScreen = element.active and ((element.x1 >= x and element.x1 <= x + width) or (element.x2 >= x and element.x2 <= x + width) or (element.x1 < x and element.x2 > x + width)) and ((element.y1 >= y and element.y1 <= y + height) or (element.y2 >= y and element.y2 <= y + height) or (element.y1 < y and element.y2 > y + height))
			element.inView = withinScreen
			
			--print("screen: " .. screen.identifier .. " element: " .. i .. " x1: " .. screen.elements[i].x1 .. " x2: " .. screen.elements[i].x2 .. " y1: " .. screen.elements[i].y1 .. " y2: " .. screen.elements[i].y2 .. " withinScreen: " .. tostring(withinScreen))
			
			if element.active and element.width() > 0 and element.height() > 0 and withinScreen and not element.hidden then
				element.drawFunc(element, timeChange)
			end
			
			if debugElementDraw and element.x1 and element.x2 and element.y1 and element.y2 then
				love.graphics.setColor(1, 0, 0, 1)
				love.graphics.rectangle('line', element.x1, element.y1, element.x2 - element.x1, element.y2 - element.y1)
				love.graphics.circle("fill", element.x1, element.y1, 3)
				love.graphics.circle("fill", element.x2, element.y2, 3)
				Font.setFont("SQUARE", 8)
				love.graphics.print(element.minDims(element)[1] .. " : " .. element.minDims(element)[2], element.x1 + 5, element.y1 + 5)
			end
		end
		
		CanvasStack.descend()
		if not doNotDraw then
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.setShader(screen.constrictShader)
			love.graphics.setBlendMode("alpha", "premultiplied")
			love.graphics.draw(screen.canvas, 0, 0)
			love.graphics.setShader()
			love.graphics.setBlendMode("alpha")
		end
	end
end

do --element
	Menu.element = {}
	
	local function getMenuCurried(element)
		return function()
			local parent = element.parent
			while parent.parent do
				parent = parent.parent
			end
			return parent
		end
	end
	
	local function defaultMinDims(element)
		if not element.storedMinDims then
			element.storedMinDims = {0, 0}
		end
		return {0, 0}
	end
	
	function Menu.element.new(posFunc, drawFunc)
		--posFunc - (element, parX, parY, parWidth, parHeight) returns x1, y1, x2, y2, defining draw position of the element
		--drawFunc - (element, timeChange), draws the element based on the above decided position
		local element = {x1 = nil, y1 = nil, x2 = nil, y2 = nil, ignoreOverlap = true, posFunc = posFunc, drawFunc = drawFunc, parent = nil, active = true, hidden = false, inView = false, mouseOver = false, mouseOverTime = 0, clicked = false, selectable = false, overlapping = {}, storedMinDims = nil, minDims = defaultMinDims}
		--selectable - boolean that determines whether an element can be clicked. Auto set when added to a screen, but can be fiddled with however you want.
		
		--clickFunc(element, mouseX, mouseY)
		--releaseFunc(element, mouseX, mouseY)
		--textEntry(element, key)
		--mouseOverBounds(element, mouseX, mouseY)
		
		element.center = function()
			return (element.x1 + element.x2)/2, (element.y1 + element.y2)/2
		end
		element.width = function()
			return element.x2 - element.x1
		end
		element.height = function()
			return element.y2 - element.y1
		end
		element.getMenu = getMenuCurried(element)
		
		return element
	end
	
	function Menu.element.recursiveForceReposition(element)
		local screen = element.parent
		while screen do
			screen.forceReposition = true
			
			if screen.parent then
				screen = screen.parent.parent
			end
		end
	end
	
	function Menu.element.reposition(element, newPosFunc)
		element.posFunc = newPosFunc
		element.storedMinDims = nil
		element.parent.forceReposition = true
		
		Menu.element.recursiveForceReposition(element)
		
		return element
	end
	
	
	function Menu.element.poetryDisplay(posFunc, poetryDisplay)
		local function drawFunc(element, timeChange)
			PoetryDisplay.update(element.poetryDisplay, timeChange)
			PoetryDisplay.draw(element.poetryDisplay, element.x1, element.y1, 0, 0)
			PoetryDisplay.finalDrawPass()
		end
		
		local element = Menu.element.new(posFunc, drawFunc)
		element.poetryDisplay = poetryDisplay
		
		return element
	end
	
	function Menu.element.image(posFunc, image, colour)
		if not colour then
			colour = {1, 1, 1, 1}
		end
		local function drawFunc(element, timeChange)
			love.graphics.setColor(colour)
			Image.drawImageOverArea(image, element.x1, element.y1, element.x2, element.y2)
		end
		
		return Menu.element.new(posFunc, drawFunc)
	end
	
	function Menu.element.shadedImage(posFunc, image, shader, updateFunc, unshadedDraw)
		--updateFunc() - sets shader variables, and I guess can do other stuff like set colour
		--unshadedDraw - if true, predraw with no shader
		local function drawFunc(element, timeChange)
			updateFunc()
			if unshadedDraw then
				Image.drawImageOverArea(image, element.x1, element.y1, element.x2, element.y2)
			end
			love.graphics.setShader(shader)
			Image.drawImageOverArea(image, element.x1, element.y1, element.x2, element.y2)
			love.graphics.setShader()
			love.graphics.setBlendMode("alpha", "alphamultiply")
		end
		
		return Menu.element.new(posFunc, drawFunc)
	end
	
	function Menu.element.fittedImageSet(basePosFunc, image, segmentSize, leftSide, rightSide, colour)
		local segmentLimits = Image.getPixelLimits(image, segmentSize)
		local segments = {}
		for i = 1, #segmentLimits do
			local limit = segmentLimits[i]
			local posFunc = function(element, parX, parY, parWidth, parHeight)
				local x1, y1, x2, y2 = basePosFunc(element, parX, parY, parWidth, parHeight)
				
				local width = x2 - x1
				if rightSide then
					x2 = x1 + limit.xMax*width
				end
				if leftSide then
					x1 = x1 + limit.xMin*width
				end
				y2 = math.min(y1 + i*segmentSize, y2)
				y1 = y1 + (i - 1)*segmentSize
				
				return x1, y1, x2, y2
			end
			
			local function drawFunc(element, timeChange)
				
			end
			local element = Menu.element.new(posFunc, drawFunc)
			table.insert(segments, element)
		end
		
		local image = Menu.element.image(basePosFunc, image, colour)
		image.ignoreOverlap = true
		table.insert(segments, image)
		
		return segments
	end
	
	local function textMinDims(element)
		if element.x1 == nil then
			return {0, 0}
		end
		
		if not element.storedMinDims then
			local _, textLines = element.font:getWrap(element.textString, element.x2 - element.x1)
			local height = math.max(#textLines*element.font:getHeight(), element.y2 - element.y1)
			
			element.storedMinDims = {element.x2 - element.x1, height}
		end
		return element.storedMinDims
	end
	function Menu.element.text(posFunc, textString, colour, font, align)
		local function drawFunc(element)
			local colourMod = 1
			if (element.clickFunc or element.releaseFunc) and element.mouseOver then
				colourMod = 0.6
			end
			love.graphics.setColor(colourMod*colour[1], colourMod*colour[2], colourMod*colour[3], colour[4])
			love.graphics.setFont(font)
			--Shader.pixelateTextShader:send("threshold", 0.3)
			--love.graphics.setShader(Shader.pixelateTextShader)
			love.graphics.printf(element.textString, math.ceil(element.x1) + element.textOffsetX, math.ceil(element.y1), element.x2 - element.x1, align, 0, 1, 1)
			--love.graphics.setShader()
		end
		
		--local augPosFunc = function(element, parX, parY, parWidth, parHeight)
		--	local x1, y1, x2, y2 = posFunc(element, parX, parY, parWidth, parHeight)
		--	
		--	local _, textLines = font:getWrap(textString, x2 - x1)
		--	local height = math.max(#textLines*font:getHeight(), y2 - y1)
		--	
		--	y2 = y1 + height
		--	
		--	return x1, y1, x2, y2
		--end
		
		local element = Menu.element.new(posFunc, drawFunc)
		element.textOffsetX = 0
		element.font = font
		element.textString = textString
		
		element.minDims = textMinDims
		
		element.changeString = function(newString)
			element.textString = newString
		end
		element.changeColour = function(newColour)
			colour = newColour
		end
		
		return element
	end
	
	function Menu.element.dynamicText(posFunc, textFunc, colour, font, align)
		local text = Menu.element.text(posFunc, "", colour, font, align)
		
		local oldDrawFunc = text.drawFunc
		text.drawFunc = function(element)
			element.textString = textFunc()
			oldDrawFunc(element)
		end
		
		return text
	end
	
	function Menu.element.button(posFunc, clickFunc, label, font, align)
		local function drawFunc(element)
			love.graphics.setColor(0, 0, 0, 0.25)
			if element.clicked then
				love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
			elseif element.mouseOver then
				love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
			end
			love.graphics.rectangle("fill", element.x1, element.y1, element.x2 - element.x1, element.y2 - element.y1)
			love.graphics.setColor(0, 0, 0, 1)
			love.graphics.setLineWidth(4)
			love.graphics.rectangle("line", element.x1, element.y1, element.x2 - element.x1, element.y2 - element.y1)
			
			love.graphics.setFont(font)
			local _, centerY = element.center()
			local _, labelLines = font:getWrap(label, element.width() - 10)
			local nLines = #labelLines
			
			love.graphics.setColor(0, 0, 0, 1)
			love.graphics.printf(element.label, element.x1 + 5, centerY - 0.5*nLines*font:getHeight(), element.width() - 10, align)
		end
		
		local element = Menu.element.new(posFunc, drawFunc)
		element.clickFunc = clickFunc
		element.label = label
		
		return element
	end
	
	function Menu.element.holdButton(posFunc, activateFunc, label, font, align, holdTime)
		local timePressed = 0
		local pressed = false
		local clickFunc = function()
			timePressed = GlobalClock
			pressed = true
		end
		
		local releaseFunc = function()
			if GlobalClock - timePressed >= holdTime then
				activateFunc()
			end
			pressed = false
		end
		local button = Menu.element.button(posFunc, clickFunc, label, font, align)
		button.releaseFunc = releaseFunc
		
		local oldDrawFunc = button.drawFunc
		button.drawFunc = function(element)
			if pressed and button.mouseOver then
				local timeLeftText = math.max(math.ceil(timePressed - GlobalClock + holdTime), 0)
				if timeLeftText == 0 then
					timeLeftText = "RELEASE"
				end
				element.label = "Are you sure?\n" .. timeLeftText
			else
				element.label = label
			end
			oldDrawFunc(element)
		end
		
		return button
	end
	
	function Menu.element.warningButton(posFunc, warningText, activateFunc)
		local borderSize = 3
		local function drawFunc(element, timeChange)
			if element.mouseOver then
				love.graphics.setColor(1, 1, 1, 0.6)
			else
				love.graphics.setColor(0, 0, 0, 0.6)
			end
			love.graphics.rectangle("fill", element.x1 + borderSize, element.y1 + borderSize, element.x2 - element.x1 - 2*borderSize - 1, element.y2 - element.y1 - 2*borderSize - 1)
			love.graphics.setColor(0, 0, 0, 1)
			love.graphics.setLineWidth(borderSize)
			love.graphics.rectangle("line", element.x1, element.y1, element.x2 - element.x1, element.y2 - element.y1)
		end
		
		local element = Menu.element.new(posFunc, drawFunc)
		
		element.clickFunc = function()
			Game.loadCutscene(GlobalGame, Cutscene.warningScreen(warningText, activateFunc))
		end
		
		return element
	end
	
	function Menu.element.imageButton(posFunc, activateFunc, image, text, font, colour)
		colour = colour or {0.1, 0.1, 0.1, 1}
		local fadeIn = 0
		
		local function drawFunc(element, timeChange)
			--if element.clicked then
			--	love.graphics.setColor(0, 0, 0, 1)
			--else
			--	love.graphics.setColor(colour)
			--end
			
			love.graphics.setColor(colour)
			Image.drawImageOverArea(image, element.x1, element.y1, element.x2, element.y2)
			
			love.graphics.setFont(font)
			love.graphics.setColor({0, 0, 0, 1})
			love.graphics.printf(text, element.x1, (element.y1 + element.y2)/2 - font:getHeight()/2, element.x2 - element.x1, "center", 0, 1, 1)
		end
		
		local element = Menu.element.new(posFunc, drawFunc)
		element.releaseFunc = activateFunc
		element.shineSize = 10
		return element
	end
	
	function Menu.element.screenToggler(posFunc, screenID)
		local function clickFunc(element)
			for i = 1, #element.parent.elements do
				local neighbour = element.parent.elements[i]
				
				--print("screenIDLookking: " .. screenID)
				Debug.safePrint("Neighbour: ", neighbour, "screen", "identifier")
				if neighbour.screen and screenID == neighbour.screen.identifier then
					--print("looking: " .. screenID .. " neighbour: " .. neighbour.screen.identifier)
					--print("equality: " .. tostring(screenID == neighbour.screen.identifier))
					neighbour.active = not neighbour.active
				end
			end
		end
		
		local element = Menu.element.button(posFunc, clickFunc)
		
		return element
	end
	
	function Menu.element.checkBox(posFunc, togglingTable, togglingElement)
		--togglingTable - table with the element
		--togglingElement - element to toggle
		
		local function drawFunc(element)
			love.graphics.setColor(0, 0, 0, 1)
			love.graphics.setLineWidth(2)
			love.graphics.rectangle("line", element.x1, element.y1, element.x2 - element.x1, element.y2 - element.y1)
			
			if togglingTable[togglingElement] then
				love.graphics.rectangle("fill", element.x1 + 2, element.y1 + 2, element.x2 - element.x1 - 4, element.y2 - element.y1 - 4)
			elseif element.mouseOver then
				love.graphics.setColor(0, 0, 0, 0.5)
				love.graphics.rectangle("fill", element.x1 + 2, element.y1 + 2, element.x2 - element.x1 - 4, element.y2 - element.y1 - 4)
			end
		end
		
		local element = Menu.element.new(posFunc, drawFunc)
		
		element.releaseFunc = function()
			togglingTable[togglingElement] = not togglingTable[togglingElement]
		end
		
		return element
	end
	
	local screenMinDims = function(element)
		element.storedMinDims = {0, 0}
		local x1 = nil
		local y1 = nil
		local x2 = nil
		local y2 = nil
		for i = 1, #element.screen.elements do
			local childElement = element.screen.elements[i]
			
			if childElement.x1 and childElement.x2 and childElement.y1 and childElement.y2 then
				if x1 == nil then
					x1 = childElement.x1
				else
					x1 = math.min(x1, childElement.x1)
				end
				if y1 == nil then
					y1 = childElement.y1
				else
					y1 = math.min(y1, childElement.y1)
				end
				
				if x2 == nil then
					x2 = childElement.x2
				else
					x2 = math.max(x2, childElement.x2)
				end
				if y2 == nil then
					y2 = childElement.y2
				else
					y2 = math.max(y2, childElement.y2)
				end
			end
		end
		
		if x1 then
			element.storedMinDims = {x2 - x1, y2 - y1}
		end
		
		return element.storedMinDims
	end
	function Menu.element.screen(posFunc, open, screen)
		screen.open = open
		
		local function drawFunc(element, timeChange)
			Menu.screen.draw(element.screen, element.x1, element.y1, element.x2 - element.x1, element.y2 - element.y1, element.inView, timeChange)
		end
		
		local function getChildren()
			return screen.elements
		end
		
		local element = Menu.element.new(posFunc, drawFunc)
		element.getChildren = getChildren
		screen.parent = element
		element.active = open
		element.screen = screen
		element.ignoreOverlap = true
		
		element.minDims = screenMinDims
		
		
		element.delete = function()
			Menu.screen.delete(screen)
		end
		
		element.changeScreen = function(newScreen)
			newScreen.open = open
			
			--element.drawFunc = function(element, timeChange)
			--	Menu.screen.draw(newScreen, element.x1, element.y1, element.x2 - element.x1, element.y2 - element.y1, timeChange)
			--end
			
			element.getChildren = function()
				return newScreen.elements
			end
			
			newScreen.parent = element
			element.screen = newScreen
			
			if newScreen.scrollFunc then
				element.scrollFunc = newScreen.scrollFunc
			end
		end
		
		if screen.scrollFunc then
			element.scrollFunc = screen.scrollFunc
		end
		
		return element
	end
	
	function Menu.element.shadedScreen(posFunc, open, shader, shaderUpdate, screen)
		local element = Menu.element.screen(posFunc, open, screen)
		
		element.drawFunc = function(element, timeChange)
			Menu.screen.draw(element.screen, element.x1, element.y1, element.x2 - element.x1, element.y2 - element.y1, element.inView, timeChange, true)
			
			shaderUpdate(timeChange)
			
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.setShader(shader)
			love.graphics.setBlendMode("alpha", "premultiplied")
			love.graphics.draw(screen.canvas, 0, 0)
			love.graphics.setShader()
			love.graphics.setBlendMode("alpha")
		end
		
		return element
	end
	
	function Menu.element.delayedLoadScreen(posFunc, open, screenGenFunction)
		--screenGenFunction(element)
		local function drawFunc(element, timeChange)
			if not element.screen then
				local screen = screenGenFunction(element)
			
				screen.open = open
				screen.parent = element
				
				element.screen = screen
				
				element.minDims = screenMinDims
				
				if screen.scrollFunc then
					element.scrollFunc = screen.scrollFunc
				end
			end
				
			Menu.screen.draw(element.screen, element.x1, element.y1, element.x2 - element.x1, element.y2 - element.y1, element.inView, timeChange)
		end
		
		local element = Menu.element.new(posFunc, drawFunc)
		
		local function getChildren()
			if element.screen then
				return element.screen.elements
			else
				return {}
			end
		end
		
		element.getChildren = getChildren
		element.active = open
		element.ignoreOverlap = true
		
		
		element.delete = function()
			if element.screen then
				Menu.screen.delete(element.screen)
			end
		end
		
		element.changeScreen = function(newScreen)
			newScreen.open = open
			
			--element.drawFunc = function(element, timeChange)
			--	Menu.screen.draw(newScreen, element.x1, element.y1, element.x2 - element.x1, element.y2 - element.y1, timeChange)
			--end
			
			element.getChildren = function()
				return newScreen.elements
			end
			
			newScreen.parent = element
			element.screen = newScreen
			
			if newScreen.scrollFunc then
				element.scrollFunc = newScreen.scrollFunc
			end
		end
		
		return element
	end
	
	function Menu.element.slider(posFunc, slidingTable, slidingVal, slideFunc, slidingRange, sliderSize, getSliderX, getSliderY, calcClickPercent)
		--isY - true if slides over y, false if slides over x
		--slideFunc(newValue) - function called when slider moved, passes in the new value decided by the slider
		--slidingTable/slidingVal - hooks into value being altered. If slidingTable is nil, then the element's parent element is used
		--slidingRange[2] - min and max of the sliding
		--sliderSize - size of the slider as percentage of the bar
		--getSliderX(element, slideVal, slidingRange, sliderSize)
		--getSliderY(element, slideVal, slidingRange, sliderSize)
		--calcClickPercent(element, sliderSize, mouseX, mouseY) - returns the percent down the slider that has been clicked
		
		local drawFunc = function(element, timeChange)
			if element.mouseOver and element.clicked then
				element.clickFunc(element, love.mouse.getX(), love.mouse.getY())
			end
			
			if slidingRange[2] > slidingRange[1] then
				love.graphics.setColor(0, 0, 0, 0.5)
				love.graphics.rectangle("fill", element.x1, element.y1, element.width(), element.height())
				if not slidingTable then
					slidingTable = element.parent.parent
				end
				
				if element.mouseOver then
					love.graphics.setColor(0.5, 0.5, 0.5, 1)
				else
					love.graphics.setColor(1, 1, 1, 1)
				end
				
				local x1, x2 = getSliderX(element, slidingTable[slidingVal], slidingRange, sliderSize)
				local y1, y2 = getSliderY(element, slidingTable[slidingVal], slidingRange, sliderSize)
				love.graphics.rectangle("fill", x1, y1, x2 - x1, y2 - y1)
			end
		end
		
		local element = Menu.element.new(posFunc, drawFunc)
		
		element.clickFunc = function(element, mouseX, mouseY)
			if slidingRange[2] > slidingRange[1] then
				local clickPercent = calcClickPercent(element, sliderSize, mouseX, mouseY)
				
				slidingTable[slidingVal] = slidingRange[1] + clickPercent*slidingRange[2]
				slideFunc(slidingRange[1] + clickPercent*slidingRange[2])
			end
		end
		element.stickyClick = true
		
		element.slidingTable = slidingTable
		element.slidingVal = slidingVal
		element.slidingRange = slidingRange
		element.slideFunc = slideFunc
		element.sliderSize = sliderSize
		
		return element
	end
	
	function Menu.element.vertSlider(posFunc, slidingTable, slidingVal, slideFunc, slidingRange, sliderSize)
		return Menu.element.slider(posFunc, slidingTable, slidingVal, slideFunc, slidingRange, sliderSize, 
		function(element, slideVal, slidingRange, sliderSize)
			return element.x1, element.x2
		end,
		function(element, slideVal, slidingRange, sliderSize)
			--print("slideVal: " .. slideVal)
			local slidePercent = (slideVal - slidingRange[1])/slidingRange[2]
			
			local size = element.height()*sliderSize
			local top = element.y1 + slidePercent*(element.height() - size)
			return top, top + size
		end,
		function(element, sliderSize, mouseX, mouseY)
			local sliderHeight = element.height()*sliderSize
			local top = element.y1 + sliderHeight/2
			local bot = element.y2 - sliderHeight/2
			
			--print("clickPercent: " .. (mouseY - top)/(bot - top))
			return math.max(math.min((mouseY - top)/(bot - top), 1), 0)
		end)
	end
	
	function Menu.element.horizSlider(posFunc, slidingTable, slidingVal, slideFunc, slidingRange, sliderSize)
		return Menu.element.slider(posFunc, slidingTable, slidingVal, slideFunc, slidingRange, sliderSize, 
		function(element, slideVal, slidingRange, sliderSize)
			local slidePercent = (slideVal - slidingRange[1])/slidingRange[2]
			
			local size = element.width()*sliderSize
			local left = element.x1 + slidePercent*(element.width() - size)
			return left, left + size
		end,
		function(element, slideVal, slidingRange, sliderSize)
			return element.y1, element.y2
		end,
		function(element, sliderSize, mouseX, mouseY)
			local sliderWidth = element.width()*sliderSize
			local left = element.x1 + sliderWidth/2
			local right = element.x2 - sliderWidth/2
			
			return math.max(math.min((mouseX - left)/(right - left), 1), 0)
		end)
	end
	
	function Menu.element.verticalList(posFunc, open, backFunction, elementSeperation, scrollEnabled, elementsInList, elementsOutsideList, allowAcross)
		local screen = Menu.screen.new("vertList", backFunction)
		
		for i = 1, #elementsInList do
			local element = elementsInList[i]
			--element.active = false
			Menu.screen.addElement(screen, element)
		end
		
		if elementsOutsideList then
			for i = 1, #elementsOutsideList do
				local element = elementsOutsideList[i]
				Menu.screen.addElement(screen, element)
			end
		end
		
		if scrollEnabled then
			local scrollBar = Menu.screen.addScrollBar(screen, Menu.position.dynamicSize(-20, 0, 1, 1), 2*elementSeperation)
			table.insert(elementsOutsideList, 1, scrollBar)
		end
		
		local screenElement = Menu.element.screen(posFunc, open, screen)
		
		for i = 1, #elementsInList do
			local element = elementsInList[i]
			element.posFunc = Menu.position.fromList(element.posFunc, screenElement)
		end
		
		local oldPosFunc = screenElement.posFunc
		screenElement.posFunc = function(element, parX, parY, parWidth, parHeight)
			local x1, y1, x2, y2 = oldPosFunc(element, parX, parY, parWidth, parHeight)
			
			element.nextX = elementSeperation
			element.nextY = elementSeperation
			element.largestRowHeight = 0
			
			for i = 1, #elementsInList do
				elementsInList[i].listPositionDecided = nil
			end
			
			return x1, y1, x2, y2
		end
		
		screenElement.nextX = elementSeperation
		screenElement.nextY = elementSeperation
		screenElement.allowAcross = allowAcross
		screenElement.elementSeperation = elementSeperation
		screenElement.largestRowHeight = 0
		
		--screenElement.currentScroll = 0
		--screenElement.establishedHeight = 0
		--screenElement.currentHeight = 0
		--screenElement.currentWidth = 0
		--screenElement.maxHeight = 0
		--screenElement.elementSeperation = elementSeperation
		--screenElement.allowAcross = allowAcross
		--screenElement.scrollEnabled = scrollEnabled
		
		--local oldFunc = screenElement.drawFunc
		--screenElement.drawFunc = function(element, timeChange)
		--	if screen.forceReposition then
		--		element.establishedHeight = 0
		--	end
		--	element.currentHeight = 0
		--	element.currentWidth = 0
		--	element.maxHeight = 0
		--	
		--	oldFunc(element, timeChange)
		--	
		--	if debugElementDraw then
		--		love.graphics.setColor(1, 0, 0, 1)
		--		love.graphics.print(element.y2, element.x1 + 5, element.y1 + 5)
		--	end
		--end
		
		screenElement.sortList = function(comparitor, descending)
			--comparitor(element) - returns some number
			screen.elements = {}
			
			for i = 1, #elementsInList do
				local element = elementsInList[i]
				element.sortValue = comparitor(element)
				Misc.binaryInsert(screen.elements, element, "sortValue", descending)
				
				element.listPositionDecided = nil
			end
			
			local lastSortValue = nil
			local currentSortIndex = 0
			for i = 1, #screen.elements do
				local element = screen.elements[i]
				
				if not lastSortValue or lastSortValue ~= element.sortValue then
					lastSortValue = element.sortValue
					currentSortIndex = currentSortIndex + 1
				end
				
				element.sortIndex = currentSortIndex
			end
			
			for i = 1, #elementsOutsideList do
				table.insert(screen.elements, elementsOutsideList[i])
			end
			
			screenElement.nextX = elementSeperation
			screenElement.nextY = elementSeperation
			screenElement.largestRowHeight = 0
			
			screen.forceReposition = true
		end
		
		return screenElement
	end
	
	function Menu.element.strictVerticalList(posFunc, open, backFunction, elementSeperation, defaultElementHeight, elementsInList, elementsOutsideList)
		--Vertical list that makes assumptions about the size of its entries and only draws the ones currently on screen.
		--CURRENTLY NOT USED, MAY COME INTO USE IF LOTS OF LAG ON MORGUE AGAIN
		
		local scrollEnabled = true
		local allowAcross = false
		
		local screen = Menu.screen.new("strictVertList", backFunction)
		
		for i = 1, #elementsInList do
			local element = elementsInList[i]
			--element.active = false
			Menu.screen.addElement(screen, element)
		end
		
		if elementsOutsideList then
			for i = 1, #elementsOutsideList do
				local element = elementsOutsideList[i]
				Menu.screen.addElement(screen, element)
			end
		end
		
		if scrollEnabled then
			local scrollBar = Menu.screen.addScrollBar(screen, Menu.position.dynamicSize(-20, 0, 1, 1), 0)
			table.insert(elementsOutsideList, 1, scrollBar)
		end
		
		local screenElement = Menu.element.screen(posFunc, open, screen)
		
		for i = 1, #elementsInList do
			local element = elementsInList[i]
			element.posFunc = Menu.position.fromList(element.posFunc, screenElement)
		end
		
		local oldPosFunc = screenElement.posFunc
		screenElement.posFunc = function(element, parX, parY, parWidth, parHeight)
			local x1, y1, x2, y2 = oldPosFunc(element, parX, parY, parWidth, parHeight)
			
			if not scrollEnabled and not element.keepGivenSize then
				element.currentHeight = 0
				element.currentWidth = 0
				element.maxHeight = 0
				if not allowAcross then
					element.establishedHeight = 0
				end
				Menu.screen.decidePositions(screen, x1, y1, x2, y2)
				y2 = y1 + element.establishedHeight
				element.currentHeight = 0
				element.currentWidth = 0
				element.maxHeight = 0
			elseif scrollEnabled then
				
			end
			
			return x1, y1, x2, y2
		end
		
		screenElement.currentScroll = 0
		screenElement.establishedHeight = 0
		screenElement.currentHeight = 0
		screenElement.currentWidth = 0
		screenElement.maxHeight = 0
		screenElement.elementSeperation = elementSeperation
		screenElement.allowAcross = allowAcross
		screenElement.scrollEnabled = scrollEnabled
		screenElement.visualRange = {1, #elementsInList}
		
		local oldFunc = screenElement.drawFunc
		screenElement.drawFunc = function(element, timeChange)
			if screen.forceReposition then
				element.establishedHeight = 0
			end
			element.currentHeight = 0
			element.currentWidth = 0
			element.maxHeight = 0
			oldFunc(element, timeChange)
		end
		
		screenElement.sortList = function(comparitor, descending)
			--comparitor(element) - returns some number
			screen.elements = {}
			
			for i = 1, #elementsInList do
				local element = elementsInList[i]
				element.sortValue = comparitor(element)
				Misc.binaryInsert(screen.elements, element, "sortValue", descending)
			end
			
			for i = 1, #elementsOutsideList do
				table.insert(screen.elements, elementsOutsideList[i])
			end
			
			screen.forceReposition = true
		end
		
		return screenElement
	end
	
	function Menu.element.textEntry(posFunc, entryTable, entryVal, entryFunc, characterRange, colour, font, align)
		local textEntering = nil
		
		local function drawFunc(element)
			love.graphics.setColor(colour)
			love.graphics.setLineWidth(2)
			love.graphics.rectangle("line", element.x1, element.y1, element.width(), element.height())
			
			love.graphics.setFont(font)
			local text = entryTable[entryVal]
			if textEntering then
				if GlobalClock%1 < 0.5 then
					text = textEntering .. " "
				else
					text = textEntering .. "|"
				end
			else
				local _, wrapText = font:getWrap(text, element.width() - 4)
				text = wrapText[1]
			end
			love.graphics.printf(text, element.x1 + 4, math.floor(element.y1 + element.height()/2 - font:getHeight()/2), element.width() - 8, align)
		end
		
		local element = Menu.element.new(posFunc, drawFunc)
		
		element.clickFunc = function(element, mouseX, mouseY)
			textEntering = ""
			local menu = element.getMenu()
			menu.takingKeyboardInput = element
		end
		
		element.textEntry = function(element, key, cancelled)
			if Controls.checkControl(key, "accept") or cancelled then
				local menu = element.getMenu()
				menu.takingKeyboardInput = nil
				entryFunc(textEntering)
				textEntering = nil
			elseif characterRange(key) then
				textEntering = textEntering .. key
			end
		end
		
		return element
	end
	
	function Menu.element.spacer(posFunc)
		return Menu.element.new(posFunc, function() end)
	end
	
	function Menu.element.box(posFunc, colour, fill, lineWidth)
		if fill then
			fill = "fill"
		else
			fill = "line"
		end
		
		return Menu.element.new(posFunc, function(element)
			love.graphics.setColor(colour)
			if lineWidth then
				love.graphics.setLineWidth(lineWidth)
			end
			
			love.graphics.rectangle(fill, element.x1, element.y1, element.x2 - element.x1, element.y2 - element.y1)
		end)
	end
	
	function Menu.element.toolView(posFunc, player, world, toolName, toolControlName)
		return Menu.element.new(posFunc, function(element)
			local count = Inventory.getToolCount(player.inventory, toolName)
			
			if count > 0 then
				love.graphics.setColor(0, 0, 0, 0.5)
				love.graphics.rectangle("fill", element.x1, element.y1, element.x2 - element.x1, element.y2 - element.y1)
				
				local activatingKey = Controls.getKeyForControl(toolControlName, 1)
				local text = activatingKey .. ": " .. toolName .. " - " .. count
				
				love.graphics.setColor(0.7, 0.7, 0.7, 1)
				if Tool.canActivateProto(toolName, world, player, nil, nil) then
					love.graphics.setColor(1, 1, 1, 1)
				end
				Font.setFont("clacon", 24)
				love.graphics.printf(text, element.x1 + 2, element.y1 + 2, element.x2 - element.x1)
			end
		end)
	end
	
	function Menu.element.cargoHold(posFunc, player)
		return Menu.element.new(posFunc, function(element)
			Font.setFont("clacon", 24)
			love.graphics.setColor(1, 1, 1, 1)
			local ledgerText = Inventory.getCargoLedger(player.inventory)
			love.graphics.printf(ledgerText, element.x1 + 2, element.y1 + 2, element.x2 - element.x1)
		end)
	end
	
	function Menu.element.crewHold(posFunc, player)
		return Menu.element.new(posFunc, function(element)
			love.graphics.setColor(0, 0, 0, 0.8)
			love.graphics.rectangle("fill", element.x1, element.y1, element.x2 - element.x1, element.y2 - element.y1)
			
			Font.setFont("clacon", 26)
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.printf("Crew: ", element.x1 + 2, element.y1 + 2, element.x2 - element.x1)
			Font.setFont("clacon", 24)
			local textWidth = (element.x2 - element.x1)/2 - 5
			for i = 1, #player.inventory.crew do
				local crew = player.inventory.crew[i]
				if crew.happiness == -1 then
					love.graphics.setColor(1, 0, 0, 1)
					love.graphics.printf(crew.class .. "\n" .. crew.origin, element.x1 + 2, element.y1 + 18 + 32*(i - 1), textWidth)
					love.graphics.printf(crew.crewDef.negEffectDescription, element.x1 + 2 + textWidth + 10, element.y1 + 18 + 32*(i - 1), textWidth)
				elseif crew.happiness == 1 then
					love.graphics.setColor(0, 1, 0, 1)
					love.graphics.printf(crew.class .. "\n" .. crew.origin, element.x1 + 2, element.y1 + 18 + 32*(i - 1), textWidth)
					love.graphics.printf(crew.crewDef.posEffectDescription, element.x1 + 2 + textWidth + 10, element.y1 + 18 + 32*(i - 1), textWidth)
				else
					love.graphics.setColor(1, 1, 1, 1)
					love.graphics.printf(crew.class .. "\n" .. crew.origin, element.x1 + 2, element.y1 + 18 + 32*(i - 1), textWidth)
					love.graphics.setColor(0.5, 0.5, 0.5, 1)
					love.graphics.printf(crew.crewDef.posEffectDescription, element.x1 + 2 + textWidth + 10, element.y1 + 18 + 32*(i - 1), textWidth)
				end
			end
		end)
	end
	
	function Menu.element.bunkerView(posFunc, player, camera)
		return Menu.element.new(posFunc, function(element)
			if player.parkedBunker then
				local bunker = player.parkedBunker
				love.graphics.setColor(0, 0, 0, 0.8)
				love.graphics.rectangle("fill", element.x1, element.y1, element.x2 - element.x1, element.y2 - element.y1)
				
				Font.setFont("clacon", 24)
				local doomTextX = Misc.round(element.x1 + 0.5*(element.x2 - element.x1))
				local doomTextY = Misc.round(element.y1 + 0.76*(element.y2 - element.y1))
				love.graphics.setColor(1, 1, 1, 1)
				if bunker.dead then
					love.graphics.printf("This bunker has collapsed", doomTextX, doomTextY, element.x2 - element.x1 - doomTextX - 5)
				else
					if bunker.hasReceived == false then
						love.graphics.printf("This bunker will collapse in " .. bunker.timeTillDeath .. " turns", doomTextX, doomTextY, element.x2 - element.x1 - doomTextX - 5)
					else
						love.graphics.printf("This bunker is saved", doomTextX, doomTextY, element.x2 - element.x1 - doomTextX - 5)
					end
					
					local tradeTextX = Misc.round(element.x1 + 10)
					local tradeTextY = Misc.round(element.y1 + 0.8*(element.y2 - element.y1))
					love.graphics.setColor(1, 1, 1, 1)
					love.graphics.printf("Trade Options: ", tradeTextX, tradeTextY, 150)
					for i = 1, #bunker.validTrades do
						local trade = bunker.validTrades[i]
						
						if trade.canExecuteFunction(player, bunker) then
							love.graphics.setColor(1, 1, 1, 1)
						else
							love.graphics.setColor(0.5, 0.5, 0.5, 1)
						end
						
						local text = i .. ": " .. trade.displayText
						if trade.give and bunker.passenger then
							text = text .. " and " .. bunker.passenger.class
						elseif trade.receive then
							text = text .. " - receive " .. Inventory.getfullContentsString(bunker.rewardInventory)
						elseif trade.win then
							text = text .. " - final score " .. Score.get()
						end
						love.graphics.printf(text, tradeTextX, tradeTextY + 20*i, element.x2 - element.x1 - tradeTextX - 5)
					end
				end
				
				local name = Text.get(player.parkedBunker.nameTag)
				local description = Text.get(player.parkedBunker.descriptionTag)
				
				Font.setFont("clacon", 30)
				love.graphics.setColor(1, 1, 1, 1)
				love.graphics.printf(name, element.x1 + 20, element.y1 + 20, 400, "left")
				
				Text.print(description, 40*player.parkedBunker.parkRealTime, 24, element.x1 + 10, element.y1 + 55, element.x2 - element.x1 - 20, "left")
			end
		end)
	end
	
	function Menu.element.actorHealth(posFunc, actor)
		return Menu.element.new(posFunc, function(element)
			love.graphics.setColor(0, 0, 0, 1)
			love.graphics.rectangle("fill", element.x1, element.y1, element.x2 - element.x1, element.y2 - element.y1)
			
			local width = (actor.health/actor.maxHealth)*(element.x2 - element.x1)
			love.graphics.setColor(1, 0, 0, 1)
			love.graphics.rectangle("fill", element.x1, element.y1, width, element.y2 - element.y1)
			
			Font.setFont("clacon", 24)
			love.graphics.setColor(1, 1, 1, 1)
			local healthText = actor.health .. "/" .. actor.maxHealth
			love.graphics.printf(healthText, element.x1, element.y1 - 3, element.x2 - element.x1, "center")
		end)
	end
	
	function Menu.element.playerFuel(posFunc, player)
		return Menu.element.new(posFunc, function(element)
			love.graphics.setColor(0, 0, 0, 1)
			love.graphics.rectangle("fill", element.x1, element.y1, element.x2 - element.x1, element.y2 - element.y1)
			
			local width = (player.fuel/player.maxFuel)*(element.x2 - element.x1)
			love.graphics.setColor(0.5, 0.3, 0, 1)
			love.graphics.rectangle("fill", element.x1, element.y1, width, element.y2 - element.y1)
			
			Font.setFont("clacon", 24)
			love.graphics.setColor(1, 1, 1, 1)
			local fuelText = player.fuel .. "/" .. player.maxFuel
			if player.fuel == 0 then
				fuelText = "OUT OF FUEL - MAX SPEED REDUCED"
			end
			love.graphics.printf(fuelText, element.x1, element.y1 - 3, element.x2 - element.x1, "center")
		end)
	end
	
	function Menu.element.playerStats(posFunc, player)
		return Menu.element.new(posFunc, function(element)
			Font.setFont("clacon", 24)
			love.graphics.setColor(1, 1, 1, 1)
			local statsText = 				 "Max Speed:    " .. Player.getMaxSpeed(player)
			statsText = statsText .. "\n" .. "Turning Rate: " .. player.turnRate
			statsText = statsText .. "\n" .. "Acceleration: " .. player.acceleration
			statsText = statsText .. "\n" .. "Deceleration: " .. player.deceleration
			love.graphics.printf(statsText, element.x1, element.y1, element.x2 - element.x1, "left")
		end)
	end
	
	function Menu.element.controlsHelp(posFunc, player)
		return Menu.element.new(posFunc, function(element)
			Font.setFont("clacon", 24)
			love.graphics.setColor(1, 1, 1, 1)
			local controlsText = 				   "m: Open Map"
			controlsText = controlsText .. "\n" .. "h: View Crew"
			controlsText = controlsText .. "\n" .. "l or RMB: Free Look"
			controlsText = controlsText .. "\n" .. "? or /  : Open Help Screen"
			love.graphics.printf(controlsText, element.x1, element.y1, element.x2 - element.x1, "left")
		end)
	end
	
	function Menu.element.helpScreen(posFunc, player)
		return Menu.element.new(posFunc, function(element)
			love.graphics.setColor(0, 0, 0, 0.9)
			love.graphics.rectangle("fill", element.x1, element.y1, element.x2 - element.x1, element.y2 - element.y1)
			
			local textWidth = (element.x2 - element.x1 - 20)/2
			Font.setFont("clacon", 24)
			love.graphics.setColor(1, 1, 1, 1)
			local leftSideText = "Introduction:\nYou are a courier boat navigating a post-apocalyptic flooded city filled with monsters and dangerous debris. Your mission is to complete as many trade routes as possible between the various Bunker communities before returning to your starting base.\nYour boat accelerates as it moves, but be careful—you must slow down to avoid crashing into destructible terrain, which will cause damage. Enemies lurk in the waters, seeking to ensnare or destroy your ship. If your boat sinks, the game is over."
			leftSideText = leftSideText .. "\n\nControls:\nKeypad / Click Direction Arrows – Move the boat\n+/- or Mouse Wheel – Accelerate / Decelerate\nM – View the Map\nL / Right Mouse Button – Free Look\nH - View Crew Hold\nN, B, V, C, X – Use various tools"
			love.graphics.printf(leftSideText, element.x1 + 10, element.y1 + 10, textWidth, "left")
			
			local rightSideText = "Tools:\nNitro – Boosts speed beyond normal limits.\nDrill Beam – Destroys all terrain between the boat and the target.\nCannon – Blasts terrain and enemies in an area.\nBlink Teleporter – Instantly teleports the boat to the target location.\nIndestructibility – Temporarily makes the boat immune to damage."
			rightSideText = rightSideText .. "\n\nTrade Goods:\nM = Medicine\nG = Gasoline\nP = Purifiers\nR = Roots\nV = Volatiles"
			rightSideText = rightSideText .. "\n\nCrew Members:\nT (Trucker) – +1 Turn Speed\nE (Engineer) – +1 Acceleration\nM (Mathematician) – +1 Deceleration\nC (Carpenter) – +5 Max Health\nS (Stocker) – +1 Cargo Limit\nB (Brewer) – +20 Max Fuel\nN (Novelist) – No effect"
			love.graphics.printf(rightSideText, element.x1 + 20 + textWidth, element.y1 + 10, textWidth, "left")
		end)
	end
	
	function Menu.element.minimap(posFunc, minimap)
		return Menu.element.new(posFunc, function(element)
			love.graphics.setColor(0, 0, 0, 1)
			love.graphics.rectangle("fill", element.x1, element.y1, element.x2 - element.x1, element.y2 - element.y1)
			
			local width = minimap.canvas:getWidth()
			local height = minimap.canvas:getHeight()
			
			--print((element.x2 - element.x1) .. ":" .. width)
			--print((element.y2 - element.y1) .. ":" .. height)
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.draw(minimap.canvas, element.x1, element.y1, 0)
			love.graphics.draw(minimap.overlayCanvas, element.x1, element.y1, 0)
		end)
	end
	
	function Menu.element.textScreen(posFunc)
		local element = Menu.element.new(posFunc, function(element)
			love.graphics.setColor(0, 0, 0, 0.9)
			love.graphics.rectangle("fill", element.x1, element.y1, element.x2 - element.x1, element.y2 - element.y1)
			
			Text.print(element.text, element.textProgress, 24, element.x1 + 20, element.y1 + 70, element.x2 - element.x1 - 40, "center")
			
			if element.showScore then
				love.graphics.printf("Final Score: " .. Score.get(), element.x1, element.y2 - 100, element.x2 - element.x1, "center")
			end
		end)
		
		element.text = ""
		element.textProgress = 0
		element.textLength = 0
		element.showScore = false
		element.changeText = function(newText)
			element.text = newText
			element.textProgress = 0
			element.textLength = string.len(newText)
		end
		
		element.update = function(dt)
			if element.textLength > 0 then
				element.textProgress = math.min(element.textProgress + 40*dt, element.textLength)
			end
		end
		
		return element
	end
end

do --position
	--(element, parX, parY, parWidth, parHeight)
	Menu.position = {}
	
	local function processDynamicPos(pos, pSize, ignoreNegative)
		local rpos = pos
		if math.abs(pos) <= 1 then
			rpos = rpos*pSize
		end
		if pos < 0 and not ignoreNegative then
			rpos = pSize + rpos
		end
		return rpos
	end
	
	function Menu.position.fromListDEPRECATED(sizeFunc, list)
		return function(element, parX, parY, parWidth, parHeight)
			local x1, y1, x2, y2 = sizeFunc(element, parX, parY, parWidth, parHeight)
			
			local width = x2 - x1
			local height = y2 - y1
			
			--if list.allowAcross then
				if not list.allowAcross or list.currentWidth + width > parWidth then
					list.currentWidth = 0
					list.currentHeight = list.currentHeight + list.maxHeight + list.elementSeperation
					list.maxHeight = height
				else
					list.maxHeight = math.max(list.maxHeight, height)
				end
				
				y1 = parY + list.currentHeight - list.currentScroll
				if list.allowAcross then
					x1 = parX + list.currentWidth
				end
				list.currentWidth = list.currentWidth + width + list.elementSeperation
			--else
			--	list.currentHeight = list.currentHeight + list.maxHeight + list.elementSeperation
			--	y1 = parY + list.currentHeight - list.currentScroll
			--	list.maxHeight = height
			--end
			
			y2 = y1 + height
			x2 = x1 + width
			--print("established: " .. list.establishedHeight .. " current: " .. list.currentHeight)
			
			list.establishedHeight = math.max(list.establishedHeight, list.currentHeight + list.maxHeight)
			
			return x1, y1, x2, y2
		end
	end
	
	function Menu.position.fromList(sizeFunc, list)
		return function(element, parX, parY, parWidth, parHeight)
			local x1, y1, x2, y2 = sizeFunc(element, parX, parY, parWidth, parHeight)
			
			local oldX1 = x1
			
			local width = x2 - x1
			local height = y2 - y1
			
			if not element.listPositionDecided then
				--if list.allowAcross then
				--	print("nextX: " .. list.nextX + width)
				--	print("maxX: " .. parX + parWidth - list.elementSeperation)
				--	print("largestHeight: " .. list.largestRowHeight)
				--end
				
				if not list.allowAcross or list.nextX + width > parWidth - list.elementSeperation then
					list.nextY = list.nextY + list.largestRowHeight + list.elementSeperation
					list.nextX = list.elementSeperation
					list.largestRowHeight = height
				else
					list.largestRowHeight = math.max(list.largestRowHeight, height)
				end
				
				x1 = parX + list.nextX
				y1 = parY + list.nextY
				
				element.listPositionDecided = {list.nextX, list.nextY}
				
				list.nextX = list.nextX + list.elementSeperation + width
			else
				x1 = parX + element.listPositionDecided[1]
				y1 = parY + element.listPositionDecided[2]
			end
			
			if not list.allowAcross then
				x1 = oldX1
			end
			
			y2 = y1 + height
			x2 = x1 + width
			--print("established: " .. list.establishedHeight .. " current: " .. list.currentHeight)
			
			return x1, y1, x2, y2
		end
	end
	
	function Menu.position.static(x, y, width, height)
		return function(element, parX, parY, parWidth, parHeight)
			return parX + x, parY + y, parX + x + width, parY + y + height
		end
	end
	
	function Menu.position.dynamicCenter(cX, cY, width, height)
		--cX, cY - from 0 to 1, where to position in the frame
		return function(element, parX, parY, parWidth, parHeight)
			local rX = processDynamicPos(cX, parWidth)
			local rY = processDynamicPos(cY, parHeight)
			local rWidth = processDynamicPos(width, parWidth)
			local rHeight = processDynamicPos(height, parHeight)
			
			return parX + rX - rWidth/2, parY + rY - rHeight/2, parX + rX + rWidth/2, parY + rY + rHeight/2
		end
	end
	
	function Menu.position.dynamicCenterFromImage(cX, cY, image)
		return Menu.position.dynamicCenter(cX, cY, image.width, image.height)
	end
	
	function Menu.position.centerImage(cX, cY, image)
		return function(element, parX, parY, parWidth, parHeight)
			local rX = processDynamicPos(cX, parWidth)
			local rY = processDynamicPos(cY, parHeight)
			return parX + rX - image.width/2, parY + rY - image.height/2, parX + rX + image.width/2, parY + rY + image.height/2
		end
	end
	
	function Menu.position.attached(element, xOff, yOff, width, height)
		--attaches to the center of another element. Important that the element is intialised AFTER the one it's attached to, otherwise it won't work well
		return function(_, parX, parY, parWidth, parHeight)
			local pcX, pcY = element.center()
			local cX = pcX + processDynamicPos(xOff, parWidth, true)
			local cY = pcY + processDynamicPos(yOff, parHeight, true)
			local rWidth = processDynamicPos(width, parWidth)
			local rHeight = processDynamicPos(height, parHeight)
			return cX - rWidth/2, cY - rHeight/2, cX + rWidth/2, cY + rHeight/2
		end
	end
	
	function Menu.position.attachedFromAnchor(element, anchorX, anchorY, xOff, yOff, width, height)
		--attaches to an anchor (0 - top left, 1 - bottom right) of another element. Important that the element is intialised AFTER the one it's attached to, otherwise it won't work well
		return function(_, parX, parY, parWidth, parHeight)
			local pcX = element.x1 + anchorX*element.x2
			local pcY = element.y1 + anchorY*element.y2
			local cX = pcX + processDynamicPos(xOff, parWidth, true)
			local cY = pcY + processDynamicPos(yOff, parHeight, true)
			local rWidth = processDynamicPos(width, parWidth)
			local rHeight = processDynamicPos(height, parHeight)
			return cX - rWidth/2, cY - rHeight/2, cX + rWidth/2, cY + rHeight/2
		end
	end
	
	function Menu.position.centerFromAnchor(anchorX, anchorY, x, y, width, height)
		return function(element, parX, parY, parWidth, parHeight)
			local rX = processDynamicPos(anchorX, parWidth)
			local rY = processDynamicPos(anchorY, parHeight)
			
			local rWidth = processDynamicPos(width, parWidth)
			local rHeight = processDynamicPos(height, parWidth)
			
			return parX + rX + x - rWidth/2, parY + rY + y - rHeight/2, parX + rX + x + rWidth/2, parY + rY + y + rHeight/2
		end
	end
	
	function Menu.position.dynamicSize(x1, y1, x2, y2)
		return function(element, parX, parY, parWidth, parHeight)
			local rx1 = processDynamicPos(x1, parWidth)
			local ry1 = processDynamicPos(y1, parHeight)
			local rx2 = processDynamicPos(x2, parWidth)
			local ry2 = processDynamicPos(y2, parHeight)
			print(rx1)
			return parX + rx1, parY + ry1, parX + rx2, parY + ry2
		end
	end

	function Menu.position.addBuffer(posFunc, leftBuffer, topBuffer, rightBuffer, botBuffer)
		return function(element, parX, parY, parWidth, parHeight)
			local x1, y1, x2, y2 = posFunc(element, parX, parY, parWidth, parHeight)
			return x1 - leftBuffer, y1 - topBuffer, x2 + rightBuffer, y2 + botBuffer
		end
	end

	function Menu.position.expandToMinDims(posFunc, expandFrom, buffer)
		--expandFrom[2] - x and y percentage to start the expansion from. 0 is take x1/y1 and add width/height, 1 is take x2/y2 and minus width/height
		--nil values indicate don't expand in that direction
		--buffer - amount to buff each side by, x1, y1, x2, y2
		
		buffer = buffer or {0, 0, 0, 0}
		
		return function(element, parX, parY, parWidth, parHeight)
			local x1, y1, x2, y2 = posFunc(element, parX, parY, parWidth, parHeight)
			if element.screen then
				Menu.screen.decidePositions(element.screen, x1, y1, x2 - x1, y2 - y1)
			end
			
			local minDims = element.minDims(element)
			
			local nx1 = x1
			local ny1 = y1
			local nx2 = x2
			local ny2 = y2
			
			if expandFrom[1] then
				local width = math.max(x2 - x1, minDims[1])
				nx1 = (1 - expandFrom[1])*x1 + expandFrom[1]*x2 - expandFrom[1]*width
				nx2 = (1 - expandFrom[1])*x1 + expandFrom[1]*x2 + (1 - expandFrom[1])*width
			end
			
			if expandFrom[2] then
				local height = math.max(y2 - y1, minDims[2])
				ny1 = (1 - expandFrom[2])*y1 + expandFrom[2]*y2 - expandFrom[2]*height
				ny2 = (1 - expandFrom[2])*y1 + expandFrom[2]*y2 + (1 - expandFrom[2])*height
			end
			
			return nx1 + buffer[1], ny1 + buffer[2], nx2 + buffer[3], ny2 + buffer[4]
		end
	end
end

return Menu