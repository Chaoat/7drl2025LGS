local Camera = require("camera")
local Tile = require("tile")

local Map = {}

--bounds indices
local xMin = 1
local yMin = 2
local xMax = 3
local yMax = 4
function Map.new()
	local map = {bounds = {0, 0, 0, 0}, tiles = {{}}, upStairs = {}, downStairs = {}}
	
	map.tiles[0] = {}
	local originTile = Tile.library.newEmpty()
	map.tiles[0][0] = originTile
	Tile.setPos(0, 0, originTile)
	
	--Map.setTile(map, -3, -5, Tile.library.newWall())
	--Map.setTile(map, 3, 5, Tile.library.newFloor())
	
	return map
end

local imageLayer = 1
function Map.loadFromXP(xpImage)
	local map = Map.new()
	
	for i = 0, xpImage.properties.width - 1 do
		for j = 0, xpImage.properties.height - 1 do
			local tile = Tile.fromXP(xpImage.images[imageLayer][i][j])
			Map.setTile(map, i, j, tile)
		end
	end
	
	return map
end

function Map.getTile(map, x, y)
	if x >= map.bounds[xMin] and x <= map.bounds[xMax] and y >= map.bounds[yMin] and y <= map.bounds[yMax] then
		return map.tiles[x][y]
	end
	return nil
end

local function posToIndex(map, x, y)
	return (map.bounds[xMax] - map.bounds[xMin])*y + x
end
function Map.findNearestFreeTile(map, x, y, objectSpaceName)
	local tilesToCheck = {{x, y}}
	local tilesAlreadyChecked = {}
	
	while #tilesToCheck > 0 do
		local tilePos = tilesToCheck[1]
		tilesAlreadyChecked[posToIndex(map, tilePos[1], tilePos[2])] = true
		table.remove(tilesToCheck, 1)
		
		local tile = Map.getTile(map, tilePos[1], tilePos[2])
		
		if Tile.hasTag(tile, "floor") then
			if tile[objectSpaceName] == nil then
				return tile
			else
				local directions = {Misc.left(), Misc.right(), Misc.top(), Misc.down()}
				
				for i = 1, #directions do
					local newX = tilePos[1] + directions[i][1]
					local newY = tilePos[2] + directions[i][2]
					
					if not tilesAlreadyChecked[posToIndex(map, newX, newY)] then
						table.insert(tilesToCheck, {newX, newY})
					end
				end
			end
		end
	end
	return false
end

function Map.spaceFree(map, x, y, character)
	local tile = Map.getTile(map, x, y)
	if tile and Tile.hasTag(tile, "blockMove") == false and tile.character == nil then
		return true
	end
	return false
end

function Map.setTile(map, x, y, tile)
	if x < map.bounds[xMin] then
		for i = x, map.bounds[xMin] - 1 do
			map.tiles[i] = {}
			for j = map.bounds[yMin], map.bounds[yMax] do
				local tile = Tile.library.newEmpty()
				if map.tiles[i][j] ~= nil then
					print("fuck1")
				end
				map.tiles[i][j] = tile
				Tile.setPos(i, j, tile)
			end
		end
		map.bounds[xMin] = x
 	elseif x > map.bounds[xMax] then
		for i = map.bounds[xMax] + 1, x do
			map.tiles[i] = {}
			for j = map.bounds[yMin], map.bounds[yMax] do
				local tile = Tile.library.newEmpty()
				if map.tiles[i][j] ~= nil then
					print("fuck2")
				end
				map.tiles[i][j] = tile
				Tile.setPos(i, j, tile)
			end
		end
		map.bounds[xMax] = x
 	end
	
	if y < map.bounds[yMin] then
		for i = map.bounds[xMin], map.bounds[xMax] do
			for j = y, map.bounds[yMin] - 1 do
				local tile = Tile.library.newEmpty()
				if map.tiles[i][j] ~= nil then
					print("fuck3")
				end
				map.tiles[i][j] = tile
				Tile.setPos(i, j, tile)
			end
		end
		map.bounds[yMin] = y
 	elseif y > map.bounds[yMax] then
		for i = map.bounds[xMin], map.bounds[xMax] do
			for j = map.bounds[yMax] + 1, y do
				local tile = Tile.library.newEmpty()
				if map.tiles[i][j] ~= nil then
					print("fuck4 " .. i .. " " .. j)
				end
				map.tiles[i][j] = tile
				Tile.setPos(i, j, tile)
			end
		end
		map.bounds[yMax] = y
 	end
	
	map.tiles[x][y] = tile
	Tile.setPos(x, y, tile)
end

Map.shapes = {}
do --shapes
	function Map.shapes.circle(map, centerX, centerY, radius)
		local tiles = {}
		for x = centerX - radius, centerX + radius do
			for y = centerY - radius, centerY + radius do
				local tile = Map.getTile(map, x, y)
				if tile then
					table.insert(tiles, tile)
				end
			end
		end
		return tiles
	end
	
	function Map.shapes.line(map, x1, y1, x2, y2)
		local tiles = {}
		local coords = Misc.plotLine(x1, y1, x2, y2)
		
		for i = 1, #coords do
			table.insert(tiles, Map.getTile(map, coords[i][1], coords[i][2]))
		end
		
		return tiles
	end
end

function Map.draw(map, camera)
	for i = map.bounds[xMin], map.bounds[xMax] do
		for j = map.bounds[yMin], map.bounds[yMax] do
			if map.tiles[i][j] == nil then
				print(i .. " " .. j)
			end
			Tile.draw(map.tiles[i][j], camera)
		end
	end
end

return Map