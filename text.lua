local Font = require "font"
local Misc = require "misc"

local Text = {}

local textEntries = {}
do
	textEntries["deathText"] = "It was a good run. The wind in your hair, the ice water around your hull, and your hold brimming with irreplaceable goods, no trader could ask for anything better. Now it lies at the bottom, another wreck in a garden of ruins."
	textEntries["badEndText"] = "'You did the best you could' your overseer says to you, in a tone that suggests you'll never be behind a wheel again for the rest of your life, or at least your overseer's. You imagine you'll be serving as a deck hand from now on, but hey, at least you're not being served as the main course for some abyssal sea monster."
end

function Text.get(entryName)
	return textEntries[entryName]
end

function Text.print(text, numChars, fontSize, x, y, limit, align)
	local textLength = string.len(text)
	
	local colouredText = {}
	colouredText[1] = {1, 1, 1, 1}
	colouredText[2] = string.sub(text, 1, math.floor(numChars))
	if numChars < textLength then
		colouredText[3] = {1, 1, 1, numChars - math.floor(numChars)}
		colouredText[4] = string.sub(text, math.floor(numChars) + 1, math.floor(numChars) + 1)
		if numChars < textLength - 1 then
			colouredText[5] = {1, 1, 1, 0}
			colouredText[6] = string.sub(text, math.floor(numChars) + 2, textLength)
		end
	end
	
	Font.setFont("clacon", fontSize)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf(colouredText, Misc.round(x), Misc.round(y), limit, align)
end

return Text