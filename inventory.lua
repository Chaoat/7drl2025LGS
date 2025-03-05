local Letter = require "letter"
local Misc = require "misc"

local Inventory = {}

local cargoDefinitions = {}
do
	local function newCargoDefinition(name, letter)
		local definition = {name = name, letter = letter}
		cargoDefinitions[name] = definition
	end
	
	newCargoDefinition("Steel", Letter.newFromLetter("S", {1, 0, 0, 1}, {0.5, 0.3, 0, 1}))
	newCargoDefinition("Medicine", Letter.newFromLetter("M", {1, 0.5, 0.5, 1}, {0.5, 0, 0.5, 1}))
	newCargoDefinition("Electronics", Letter.newFromLetter("E", {1, 1, 0.5, 1}, {0.4, 0.4, 0.4, 1}))
	newCargoDefinition("Gasoline", Letter.newFromLetter("G", {0.3, 0.3, 0, 1}, {0.7, 0.7, 0.7, 1}))
	newCargoDefinition("Purifiers", Letter.newFromLetter("P", {0.5, 0.7, 0.7, 1}, {0.3, 0.5, 0.3, 1}))
	newCargoDefinition("Roots", Letter.newFromLetter("R", {0.3, 0.6, 0.3, 1}, {0.4, 0.2, 0.1, 1}))
	newCargoDefinition("Volatiles", Letter.newFromLetter("V", {0.3, 0.3, 0.6, 1}, {0.6, 0, 0, 1}))
	
	newCargoDefinition("Weapons", Letter.newFromLetter("W", {1, 1, 1, 1}, {0, 0, 0, 1}))
	newCargoDefinition("Clothes", Letter.newFromLetter("C", {1, 1, 1, 1}, {0, 0, 0, 1}))
	newCargoDefinition("Food", Letter.newFromLetter("F", {1, 1, 1, 1}, {0, 0, 0, 1}))
	newCargoDefinition("Tools", Letter.newFromLetter("T", {1, 1, 1, 1}, {0, 0, 0, 1}))
end

function Inventory.getCargoLetter(cargoName)
	return cargoDefinitions[cargoName].letter
end

function Inventory.drawCargoSymbol(cargoName, x, y, tileWidth, tileHeight)
	local letter = Inventory.getCargoLetter(cargoName)
	Letter.drawBack(letter, x, y, tileWidth, tileHeight)
	Letter.draw(letter, x, y, tileWidth, tileHeight)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.rectangle("line", Misc.round(x - tileWidth/2), Misc.round(y - tileHeight/2), tileWidth, tileHeight)
end

function Inventory.new()
	local inventory = {cargo = {}, tools = {}, crew = {}, cargoLimit = 2}
	
	return inventory
end

function Inventory.transferTo(inventoryTo, inventoryFrom)
	for i = 1, #inventoryFrom.cargo do
		local name = inventoryFrom.cargo[i].cargoName
		local count = inventoryFrom.cargo[i].count
		Inventory.addCargo(inventoryTo, name, count)
		Inventory.removeCargo(inventoryFrom, name, count)
	end
	
	for i = 1, #inventoryFrom.tools do
		local name = inventoryFrom.tools[i].toolName
		local count = inventoryFrom.tools[i].count
		Inventory.addTool(inventoryTo, name, count)
		Inventory.removeTool(inventoryFrom, name, count)
	end
	
	for i = 1, #inventoryFrom.crew do
		Inventory.addCrew(inventoryTo, inventoryFrom.crew[i])
		Inventory.removeCrew(inventoryFrom, inventoryFrom.crew[i])
	end
end

function Inventory.getfullContentsString(inventory)
	local text = ""
	local firstAdded = false
	local function addItem(name, count)
		if firstAdded then
			text = text .. ", "
		else
			firstAdded = true
		end
		
		if count > 1 then
			text = text .. count .. "x " .. name
		else
			text = text .. name
		end
	end
	for i = 1, #inventory.cargo do
		addItem(inventory.cargo[i].cargoName, inventory.cargo[i].count)
	end
	for i = 1, #inventory.tools do
		addItem(inventory.tools[i].toolName, inventory.tools[i].count)
	end
	for i = 1, #inventory.crew do
		addItem(inventory.crew[i].class .. " from " .. inventory.crew[i].origin, 1)
	end
	return text
end


function Inventory.addTool(inventory, toolName, count)
	local alreadyPresent = false
	for i = 1, #inventory.tools do
		local tool = inventory.tools[i]
		if tool.toolName == toolName then
			tool.count = tool.count + count
			alreadyPresent = true
			break
		end
	end
	
	if alreadyPresent == false then
		table.insert(inventory.tools, {toolName = toolName, count = count})
	end
	return inventory
end

function Inventory.removeTool(inventory, toolName, count)
	for i = 1, #inventory.tools do
		local tool = inventory.tools[i]
		if tool.toolName == toolName then
			tool.count = tool.count - count
			
			if tool.count <= 0 then
				table.remove(inventory.tools, i)
			end
			break
		end
	end
end

function Inventory.containsTool(inventory, toolName, count)
	for i = 1, #inventory.tools do
		local tool = inventory.tools[i]
		if tool.toolName == toolName then
			return tool.count >= count
		end
	end
	return false
end

function Inventory.getToolCount(inventory, toolName)
	for i = 1, #inventory.tools do
		local tool = inventory.tools[i]
		if tool.toolName == toolName then
			return tool.count
		end
	end
	return c0
end


function Inventory.addCargo(inventory, cargoName, count)
	local alreadyPresent = false
	for i = 1, #inventory.cargo do
		local cargo = inventory.cargo
		if cargo.cargoName == cargoName then
			cargo.count = cargo.count + count
			alreadyPresent = true
			break
		end
	end
	
	if alreadyPresent == false then
		table.insert(inventory.cargo, {cargoName = cargoName, count = count})
	end
	return inventory
end

function Inventory.removeCargo(inventory, cargoName, count)
	local alreadyPresent = false
	for i = 1, #inventory.cargo do
		local cargo = inventory.cargo[i]
		if cargo.cargoName == cargoName then
			cargo.count = cargo.count - count
			
			if cargo.count <= 0 then
				table.remove(inventory.cargo, i)
			end
			break
		end
	end
end

function Inventory.hasCargo(inventory, cargoName)
	local count = 0
	for i = 1, #inventory.cargo do
		local cargo = inventory.cargo[i]
		if cargo.cargoName == cargoName then
			count = count + cargo.count
		end
	end
	return count
end

function Inventory.cargoCount(inventory)
	local count = 0
	for i = 1, #inventory.cargo do
		local cargo = inventory.cargo[i]
		count = count + cargo.count
	end
	return count
end

function Inventory.getCargoLedger(inventory)
	local ledger = "CargoHold: " .. Inventory.cargoCount(inventory) .. "/" .. inventory.cargoLimit
	for i = 1, #inventory.cargo do
		ledger = ledger .. "\n"
		local cargo = inventory.cargo[i]
		ledger = ledger .. cargo.cargoName
		if cargo.count > 1 then
			ledger = ledger .. " x" .. cargo.count
		end
	end
	return ledger
end


function Inventory.addCrew(inventory, crew)
	table.insert(inventory.crew, crew)
	return inventory
end

function Inventory.removeCrew(inventory, crew)
	for i = 1, #inventory.crew do
		local compareCrew = inventory.crew[i]
		if compareCrew.class == crew.class and compareCrew.origin == crew.origin then
			table.remove(inventory.crew, i)
		end
	end
end

return Inventory