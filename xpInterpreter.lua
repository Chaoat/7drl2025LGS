local XpInterpreter = {}

function XpInterpreter.load(fileName, overrideWidth, overrideHeight)
	--local basePath = love.filesystem.getSource()
	--
	--local dirs = love.filesystem.getDirectoryItems("xpFiles")
	--for i = 1, #dirs do
	--	print(dirs[i])
	--end
	
	local compressedString = love.filesystem.read("xpFiles/" .. fileName .. ".xp")
	--print(compressedString)
	local decompressed = love.data.decompress("string", "gzip", compressedString)
	--print(decompressed)
	
	local byteOffset = 1
	local readBytes = function(nBytes) 
		local data = decompressed:byte(byteOffset, byteOffset + nBytes - 1)
		byteOffset = byteOffset + nBytes
		
		return data
	end
	local properties = {version = readBytes(4), layers = readBytes(4), width = readBytes(4), height = readBytes(4)}
	--print(properties.version)
	--print(properties.layers)
	--print(properties.width)
	--print(properties.height)
	
	if overrideWidth then
		properties.width = overrideWidth
	end
	if overrideHeight then
		properties.height = overrideHeight
	end
	
	local images = {}
	for k = 1, properties.layers do
		if k > 1 then
			readBytes(8)
		end
		
		local image = {}
		for i = 0, properties.width - 1 do
			image[i] = {}
			for j = 0, properties.height - 1 do
				local charCode = readBytes(4)
				--print(charCode)
				local fCol = {readBytes(1)/255, readBytes(1)/255, readBytes(1)/255, 1}
				local bCol = {readBytes(1)/255, readBytes(1)/255, readBytes(1)/255, 1}
				image[i][j] = {character = string.char(charCode), charCode = charCode, fCol = fCol, bCol = bCol}
			end
		end
		
		table.insert(images, image)
	end
	
	return {images = images, properties = properties}
end

return XpInterpreter