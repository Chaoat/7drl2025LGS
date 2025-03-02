local Inventory = {}

function Inventory.new()
	local inventory = {cargo = {}, tools = {}, crew = {}}
	
	return inventory
end

function Inventory.addTool(inventory, toolName, count)
	local alreadyPresent = false
	for i = 1, #inventory.tools do
		local tool = inventory.tools
		if tool.toolName == toolName then
			tool.count = tool.count + count
			alreadyPresent = true
			break
		end
	end
	
	if alreadyPresent == false then
		table.insert(inventory.tools, {toolName = toolName, count = count})
	end
end

function Inventory.containsTool(inventory, toolName, count)
	print("111")
	for i = 1, #inventory.tools do
		local tool = inventory.tools[i]
		print("222" .. tool.count)
		if tool.toolName == toolName then
			return tool.count >= count
		end
	end
	return false
end

function Inventory.removeTool(inventory, toolName, count)
	for i = 1, #inventory.tools do
		local tool = inventory.tools
		if tool.toolName == toolName then
			tool.count = tool.count - count
			break
		end
	end
end

return Inventory