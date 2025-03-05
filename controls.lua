local Controls = {}

local controlsEnabled = {}
local controlTable = {}
local inverseControlTable = {}
local controlOrder = {}
local function addControl(key, control, skipRelease)
	if key then
		if not controlTable[key] then
			controlTable[key] = {}
		end
		controlTable[key][control] = true
	end
	
	if not controlsEnabled[control] then
		controlsEnabled[control] = true
	end
	
	if not inverseControlTable[control] then
		inverseControlTable[control] = {}
		table.insert(controlOrder, control)
	end
	table.insert(inverseControlTable[control], key)
end

local function addControls(control, keys)
	if #keys == 0 then
		addControl(nil, control)
	else
		for i = 1, #keys do
			addControl(keys[i], control)
		end
	end
end

local function resetControl(control)
	inverseControlTable[control] = {}
	for key, controlList in pairs(controlTable) do
		for i = 1, #controlList do
			if controlList[i] == control then
				table.remove(controlList, i)
				break
			end
		end
	end
end

local function resetControls()
	controlsEnabled = {}
	controlTable = {}
	inverseControlTable = {}
	controlOrder = {}
end

local function unbindKey(key)
	controlTable[key] = {}
	for control, keys in pairs(inverseControlTable) do
		for i = 1, #keys do
			if keys[i] == key then
				table.remove(keys, i)
				break
			end
		end
	end
end

function Controls.loadDefaultControls()
	resetControls()
	
	addControls("botLeft", 	{"kp1"})
	addControls("bot", 		{"kp2"})
	addControls("botRight", {"kp3"})
	addControls("left", 	{"kp4"})
	addControls("skip", 	{"kp5"})
	addControls("right", 	{"kp6"})
	addControls("topLeft", 	{"kp7"})
	addControls("top", 		{"kp8"})
	addControls("topRight", {"kp9"})
	
	addControls("startLooking", {"l"})
	
	addControls("activateNitro", {"n"})
	addControls("activateBlink", {"b"})
	addControls("activateTargettedTool", {"kpenter", "space", "return"})
	
	addControls("tradeOption1", {"1"})
	addControls("tradeOption2", {"2"})
	addControls("tradeOption3", {"3"})
	addControls("tradeOption4", {"4"})
	addControls("tradeOption5", {"5"})
	addControls("tradeOption6", {"6"})
	
	addControls("accelerate", {"kp+", "=", "wheelUp"})
	addControls("decelerate", {"kp-", "-", "wheelDown"})
	
	addControls("openMap", {"m"})
	
	addControls("back", {"escape"})
	
	--addControls("examine", {"l"})
	--addControls("selectTarget", {"return"})
	--addControls("cancelTargetting", {"escape"})
	--addControls("restart", {"r"})
	
	addControls("debug", {"f6"})
	addControls("profile", {"f7"})
	
	--addControls("useStaircase", {"return"})
end

local buttonNumbers = {"leftMouse", "rightMouse", "middleMouse"}
function Controls.mouseButtonNumberToControl(buttonNumber)
	if buttonNumbers[buttonNumber] then
		return buttonNumbers[buttonNumber]
	else
		return "none"
	end
end

function Controls.mousewheelToControl(wheelVel)
	if wheelVel < 0 then
		return "wheelDown"
	elseif wheelVel > 0 then
		return "wheelUp"
	else
		return nil
	end
end

--local releaseButtonNumbers = {}
--for i = 1, #buttonNumbers do
--	releaseButtonNumbers[i] = buttonNumbers[i] .. "Released"
--	--print("button " .. i .. " yyhh " .. releaseButtonNumbers[i])
--end
--function Controls.mouseReleaseButtonNumberToControl(buttonNumber)
--	return releaseButtonNumbers[buttonNumber]
--end

function Controls.keyToControls(key)
	--Returns the controls attached to a certain key
	local list = {}
	if controlTable[key] then
		for control, value in pairs(controlTable[key]) do
			if controlsEnabled[control] then
				list[control] = true
			end
		end
	end
	return list
end

function Controls.checkControl(key, control, release)
	--release - true if to check if released instead of if pressed. If it's to be released, then the key will have an R at the end
	local lkey = key
	if release then
		lkey = string.sub(key, 1, string.len(key) - 1)
	end
	--Checks whether a certain key activates a certain control
	if not controlsEnabled[control] then
		return false
	end
	
	local list = {}
	if controlTable[lkey] then
		list = controlTable[lkey]
	end
	return list[control]
end

function Controls.getKeyForControl(control, keyI)
	local keyTable = inverseControlTable[control]
	keyI = math.min(keyI, #keyTable)
	
	return keyTable[keyI]
end

function Controls.checkControlReleased(key, control)
	return Controls.checkControl(key, control, true)
end

function Controls.enableControl(control, enabled)
	controlsEnabled[control] = enabled
end

function Controls.checkControlEnabled(control)
	return controlsEnabled[control]
end

function Controls.enableAllControls(enabled)
	print("controls enabled: " .. tostring(enabled))
	for control, _ in pairs(controlsEnabled) do
		controlsEnabled[control] = enabled
	end
end

function Controls.letterToIndex(letter)
	if string.len(letter) > 1 then
		return false
	end
	
	local index = string.byte(letter)
	if index >= 97 and index <= 122 then
		return index - 96
	end
	return false
end

function Controls.indexToLetter(index)
	local letter = string.char(96 + index)
	return letter
end


local function buttonMousedOver(bX, bY, bWidth, bHeight)
	local mouseX = love.mouse.getX()
	local mouseY = love.mouse.getY()
	return math.abs(mouseX - bX)/2 < bWidth/2 and math.abs(mouseY - bY)/2 < bHeight/2
end

local lastClickedTime = false
function Controls.clickKey(key, bX, bY, bWidth, bHeight)
	--bX, bY - center coords of button
	--bWidth, bHeight - dimensions of button
	
	if love.mouse.isDown(1) then
		if not lastClickedTime or lastClickedTime == GlobalClock then
			lastClickedTime = GlobalClock
			
			if buttonMousedOver(bX, bY, bWidth, bHeight) then
				Game.generalInput(GlobalGame, nil, key)
				return true
			end
		end
	else
		lastClickedTime = false
	end
		
	return false
end

function Controls.drawButton(x, y, control, availableFunction)
	local key = inverseControlTable[control][1]
	
	local pressed = love.keyboard.isDown(key) or Controls.clickKey(key, x, y, 20, 20)
	local unAvailable = not Controls.checkControlEnabled(control)
	if availableFunction then
		unAvailable = unAvailable or not availableFunction()
	end
	
	local keyImage = Image.getImage("interface/buttons/letters/" .. key)
	
	local yPos = y - 2
	if pressed then
		yPos = y + 1
	end
	love.graphics.draw(keyImage.image, x, yPos, 0, 1, 1, keyImage.width/2, keyImage.height/2)
	if buttonMousedOver(x, y, 20, 20) then
		Shader.setFuncs.glow(Misc.animateBetweenPoints(3, 6, 1, 0), {0, 0, 0, 0.8}, {0, 0, 0, 0}, {0, 0, 0, 0}, 0, {keyImage.width, keyImage.height})
		Image.drawImageScreenSpace(keyImage, x, yPos, 0, 0.5, 0.5, 1, 1)
		love.graphics.setShader()
	end
	
	local buttonImage = Image.getImage("interface/buttons/unPressed")
	if pressed and unAvailable then
		buttonImage = Image.getImage("interface/buttons/pressedUnAvailable")
	elseif pressed then
		buttonImage = Image.getImage("interface/buttons/pressed")
	elseif unAvailable then
		buttonImage = Image.getImage("interface/buttons/unAvailable")
	end
	love.graphics.draw(buttonImage.image, x, y, 0, 1, 1, buttonImage.width/2, buttonImage.height/2)
end

function Controls.loadFromFile()
	if love.filesystem.getInfo("controls") then
		resetControls()
		local file = love.filesystem.newFile("controls")
		file:open("r")
		
		for line in file:lines() do
			local control = nil
			local keys = {}
			for entry in line:gmatch("[^|]+") do
				if not control then
					control = entry
				else
					table.insert(keys, entry)
				end
			end
			addControls(control, keys)
		end
		
		file:close()
		return true
	end
	return false
end

function Controls.saveToFile()
	local file = love.filesystem.newFile("controls")
	file:open("w")
	file:seek(0)
	
	for c = 1, #controlOrder do
		local control = controlOrder[c]
		file:write(control)
		for i = 1, #inverseControlTable[control] do
			file:write("|" .. inverseControlTable[control][i])
		end
		file:write("\n")
	end
	
	file:close()
end

function Controls.scrollSpeed()
	return 30
end

local unsettableControls = {click = true, scroll = true, mouseMove = true, accept = true}
local function blackBack(alpha)
	return function(x, y, width, height)
		love.graphics.setColor(0, 0, 0, alpha)
		love.graphics.rectangle("fill", x, y, width, height)
	end
end
local function controlSetElement(posFunc, control, index, nextElement)
	local textEntering = false
	local function drawFunc(element)
		if element.mouseOver then
			love.graphics.setColor({0.5, 0.5, 0.5, 1})
		else
			love.graphics.setColor({0, 0, 0, 1})
		end
		love.graphics.setLineWidth(2)
		love.graphics.rectangle("line", element.x1, element.y1, element.width(), element.height())
		
		local font = Font.getFont("KOMIKZBA", 26)
		local text = inverseControlTable[control][index]
		if textEntering then
			font = Font.getFont("KOMIKZBA", 14)
			text = "press any key\nbackspace to unbind"
		end
		if text then
			love.graphics.setFont(font)
			love.graphics.setColor({1, 1, 1, 1})
			love.graphics.printf(text, element.x1 + 2, math.floor(element.y1), element.width() - 4, "right")
		end
		
		if index > 1 and not inverseControlTable[control][index - 1] then
			element.active = false
		end
		if inverseControlTable[control][index] and nextElement then
			nextElement.active = true
		end
	end
	
	local element = Menu.element.new(posFunc, drawFunc)
	
	element.clickFunc = function(element, mouseX, mouseY)
		textEntering = true
		local menu = element.getMenu()
		menu.takingKeyboardInput = element
	end
	
	element.textEntry = function(element, key, cancelled)
		local keyRepeat = false
		for i = 1, #inverseControlTable[control] do
			if inverseControlTable[control][i] == key then
				keyRepeat = true
				break
			end
		end
		if key == "backspace" or cancelled then-- or keyRepeat then
			local lastKeys = inverseControlTable[control]
			resetControl(control)
			table.remove(lastKeys, index)
			addControls(control, lastKeys)
			element.recursiveBoxHide()
		else
			unbindKey(key)
			local lastKeys = inverseControlTable[control]
			resetControl(control)
			lastKeys[index] = key
			addControls(control, lastKeys)
			if nextElement then
				nextElement.active = true
			end
		end
		element.getMenu().takingKeyboardInput = nil
		textEntering = nil
	end
	
	element.recursiveBoxHide = function()
		if inverseControlTable[control][index] then
			element.active = true
			if nextElement then
				nextElement.recursiveBoxHide()
			end
		elseif nextElement then
			nextElement.active = false
		end
	end
	
	element.active = true
	if not inverseControlTable[control][index] and nextElement then
		nextElement.active = false
	end
	
	return element
end
function Controls.generateControlScreen(posFunc)
	local controlElements = {}
	for c = 1, #controlOrder do
		local control = controlOrder[c]
		if not unsettableControls[control] then
			local screen = Menu.screen.new("control", blackBack(0.5))
			
			Menu.screen.addElement(screen, Menu.element.text(Menu.position.dynamicSize(5, 5, 0.16, -5), control .. ": ", {1, 1, 1, 1}, Font.getFont("KOMIKZBA", 26), "right"))
			local controlSetters = {}
			for i = 4, 1, -1 do
				local nextElement = nil
				if i < 4 then
					nextElement = controlSetters[1]
				end
				table.insert(controlSetters, 1, controlSetElement(Menu.position.dynamicSize(i*0.2 - 0.02, 5, (i + 1)*0.2 - 0.04, -5), control, i, nextElement))
			end
			
			Menu.screen.addElements(screen, controlSetters)
			
			table.insert(controlElements, Menu.element.screen(Menu.position.dynamicSize(5, 0, -5, 45), true, screen))
		end
	end
	local screen = Menu.element.verticalList(posFunc, true, nil, 2, true, controlElements, {}, false)
	
	return screen
end


if not Controls.loadFromFile() then
	Controls.loadDefaultControls()
end

return Controls