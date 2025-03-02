local Inventory = {}

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