local Letter = require "letter"
local Camera = require "camera"

local Tile = {}

local solidityTiers = {2, 4, 6, 8, 10}
function Tile.fromXP(xpCharacter, solidityCharacter)
	local charCode = xpCharacter.charCode
	local fCol = xpCharacter.fCol
	local bCol = xpCharacter.bCol
	
	local solidityTier = math.max(solidityCharacter.charCode - 48, 0)
	local solidity = 0
	if solidityTier > 0 then
		solidity = solidityTiers[solidityTier]
	end
	
	local tags = {}
	local tile = Tile.new(solidity, tags, Letter.new(charCode, fCol, bCol))
	
	return tile
end

function Tile.new(solidity, tags, letter)
	local tile = {drawX = 0, drawY = 0, x = 0, y = 0, actors = {}, letter = letter, solidity = solidity, tags = {}}
	
	for i = 1, #tags do
		tile.tags[tags[i]] = true
	end
	
	return tile
end

function Tile.wreck(tile)
	tile.solidity = 0
	tile.letter.charCode = string.byte(";")
end

function Tile.moveActor(tile, actor)
	if actor.tile then
		local oldTile = actor.tile
		for i = #oldTile.actors, 1, -1 do
			if oldTile.actors[i].id == actor.id then
				table.remove(oldTile.actors, i)
				break
			end
		end
	end
	
	table.insert(tile.actors, actor)
	actor.x = tile.x
	actor.y = tile.y
	actor.tile = tile
	
	if actor.drawX == nil or actor.drawY == nil then
		actor.drawX = tile.x
		actor.drawY = tile.y
	end
end

Tile.library = {}
do
	function Tile.library.newEmpty()
		return Tile.new(0, {"empty"}, Letter.new(0, {0, 0, 0, 0}, nil))
	end
end

function Tile.setPos(x, y, tile)
	tile.drawX = x
	tile.drawY = y
	tile.x = x
	tile.y = y
end

function Tile.hasTags(tile, tagList)
	for i = 1, #tagList do
		if not tile.tags[tagList[i]] then
			return false
		end
	end
	return true
end

function Tile.hasAnyTags(tile, tagList)
	for i = 1, #tagList do
		if tile.tags[tagList[i]] then
			return true
		end
	end
	return false
end

function Tile.hasTag(tile, tag)
	return Tile.hasTags(tile, {tag})
end

function Tile.draw(tile, camera)
	Camera.drawTo(tile.letter, tile.drawX, tile.drawY, camera, Letter.draw)
end

return Tile