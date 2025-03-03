local Camera = require "camera"
local Misc = require "misc"

local Letter = {}

local fontImage = love.graphics.newImage("fonts/font.png")
local quads = {}
local quadBank = {}
local letterTileWidth = 20
local letterTileHeight = 20

local function doFontPreProcessing()
	fontImage:setFilter("nearest", "nearest")
	
	local addQuadToBank = function(letter, charCode)
		quadBank[letter] = charCode
	end
	
	for i = 0, 15 do
		quads[i] = {}
		for j = 0, 15 do
			quads[i][j] = love.graphics.newQuad((letterTileWidth)*i, (letterTileHeight)*j, letterTileWidth, letterTileHeight, fontImage:getWidth(), fontImage:getHeight())
		end
	end
	
	for i = 0, 25 do
		addQuadToBank(string.char(65 + i), i%13, math.floor(i/13))
		addQuadToBank(string.char(97 + i), i%13, 2 + math.floor(i/13))
	end
	for i = 0, 9 do
		addQuadToBank(tostring(i), i, 6)
	end
	addQuadToBank("\\", 0, 4)
	addQuadToBank("|", 1, 4)
	addQuadToBank("/", 2, 4)
	addQuadToBank("-", 3, 4)
	addQuadToBank("+", 4, 4)
	addQuadToBank("||", 5, 4)
	addQuadToBank("=", 6, 4)
	
	addQuadToBank(";", 8, 4)
	addQuadToBank(",", 9, 4)
	addQuadToBank(".", 10, 4)
	addQuadToBank("~", 11, 4)
	addQuadToBank("'", 12, 4)
	
	addQuadToBank("@", 0, 5)
	addQuadToBank(" ", 1, 5)
	addQuadToBank("#", 2, 5)
	addQuadToBank(">>", 3, 5)
	addQuadToBank("%", 4, 5)
	addQuadToBank(":", 5, 5)
	addQuadToBank("*", 6, 5)
	addQuadToBank("\"", 7, 5)
	
	addQuadToBank("uA", 0, 7)
	addQuadToBank("urA", 1, 7)
	addQuadToBank("rA", 2, 7)
	addQuadToBank("drA", 3, 7)
	addQuadToBank("dA", 4, 7)
	addQuadToBank("dlA", 5, 7)
	addQuadToBank("lA", 6, 7)
	addQuadToBank("ulA", 7, 7)
end
doFontPreProcessing()

local function charCodeToQuad(charCode)
	local y = math.floor(charCode/16)
	local x = charCode - 16*y
	return quads[x][y]
end

function Letter.newFromLetter(letter, colour, backColour)
	local charCode = string.byte(letter)
	return Letter.new(charCode, colour, backColour)
end

function Letter.new(charCode, colour, backColour)
	if not backColour then
		backColour = {0, 0, 0, 0}
	end
	local letter = {charCode = charCode, colour = colour, backColour = backColour, tint = {1, 1, 1, 1}, facing = 0}
	return letter
end

function Letter.copy(letter)
	local newLetter = Letter.new(letter.letter, letter.colour)
	return newLetter
end

function Letter.draw(letter, drawX, drawY, tileWidth, tileHeight)
	if letter.colour == nil then
		error("Letter color: " .. letter.letter)
	else
		love.graphics.setColor(Misc.multiplyColours(letter.colour, letter.tint))
	end
	
	local y = math.floor(letter.charCode/16)
	local x = letter.charCode - 16*y
	local quad = quads[x][y]
	love.graphics.draw(fontImage, quad, drawX, drawY, letter.facing, tileWidth/letterTileWidth, tileHeight/letterTileHeight, letterTileWidth/2, letterTileHeight/2)
end

function Letter.drawBack(letter, x, y, camera)
	local drawX, drawY = getDrawPos(x, y, camera)
	
	if letter.momentaryInfluence > 0 then
		love.graphics.setColor(blendColours(letter.momentaryInfluenceColour, letter.backColour, letter.momentaryInfluence))
	else
		love.graphics.setColor(letter.backColour)
	end
	
	love.graphics.rectangle('fill', drawX, drawY, camera.tileWidth, camera.tileHeight)
end

return Letter